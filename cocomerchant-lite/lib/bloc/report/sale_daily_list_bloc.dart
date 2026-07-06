import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:cocomerchant_lite/model/sale_daily_list_model.dart';
import 'package:cocomerchant_lite/api/click_house_api.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:intl/intl.dart';
import 'package:cocomerchant_lite/global.dart' as global;

abstract class SaleDailyListEvent {}

abstract class SaleDailyListState {}

class SaleDailyListStateInitialized extends SaleDailyListState {}

class SaleDailyListLoadStart extends SaleDailyListEvent {
  DateTime startDateTime;
  DateTime endDateTime;
  int page;
  int pageSize;
  String searchQuery;

  SaleDailyListLoadStart({
    required this.startDateTime,
    required this.endDateTime,
    required this.page,
    required this.pageSize,
    required this.searchQuery,
  });
}

class SaleDailyListLoadSuccess extends SaleDailyListState {
  List<SaleDailyListModel> data;
  SaleDailyListLoadSuccess({required this.data});
}

class SaleDailyListLoadFail extends SaleDailyListState {
  String message;
  SaleDailyListLoadFail({required this.message});
}

class SaleDailyListMachineCountSuccess extends SaleDailyListState {
  int count;
  SaleDailyListMachineCountSuccess({required this.count});
}

class SaleDailyListBloc extends Bloc<SaleDailyListEvent, SaleDailyListState> {
  SaleDailyListBloc() : super(SaleDailyListStateInitialized()) {
    on<SaleDailyListLoadStart>(_saledailyLoadStart);
    on<SaleDailyListLoadFinish>(_saledailyLoadFinish);
  }

  void _saledailyLoadStart(SaleDailyListLoadStart event, Emitter<SaleDailyListState> emit) async {
    emit(SaleDailyListLoading());
    try {
      List<SaleDailyListModel> saleDailyDatas = [];
      String startDateTimeQuery = DateFormat('yyyy-MM-dd HH:mm:ss').format(event.startDateTime.toUtc());
      String endDateTimeQuery = DateFormat('yyyy-MM-dd HH:mm:ss').format(event.endDateTime.toUtc());

      String shopIdString = global.appConfig.read("shopid");
      int offset = event.page * event.pageSize;
      String searchQuery = event.searchQuery;

      String query = '''
    SELECT 
      d.shopid, 
      d.branchid,
      d.docdatetime,
      d.docno,
      d.totalamount,
      (((d.paycashamount - d.paycashchange) - d.roundamount) + dp.totalpaymentlist) as sumpayamount,
      d.paycashamount - d.paycashchange as paycashamount,
      d.paycashchange,
      d.roundamount,
      dp.paymentlist,
      toFloat64(dp.totalpaymentlist) as sumpaymentlist
    FROM (
      SELECT 
        shopid, 
        branchid,
        docdatetime,
        docno,
        totalamount,
        paycashamount,
        paycashchange,
        roundamount
      FROM 
        dedebi.doc 
      WHERE 
        shopid = '$shopIdString'
        AND perioddatetime >= toDateTime('$startDateTimeQuery') 
        AND perioddatetime <= toDateTime('$endDateTimeQuery')
        ${searchQuery.isNotEmpty ? "AND docno LIKE '%$searchQuery%'" : ""}
      ORDER BY docdatetime DESC 
      LIMIT ${event.pageSize} OFFSET $offset
    ) AS d
    LEFT JOIN (
      SELECT 
        shopid, 
        branchid,
        docno,
        '[' || arrayStringConcat(groupArray(
          concat(
            '{"description":"', description, '","totalamount":', toString(totalAmount), '}'
          )), ',') || ']' as paymentlist,
        sum(totalAmount) as totalpaymentlist
      FROM (
        SELECT 
          shopid, 
          branchid, 
          docno,
          description, 
          sum(amount) as totalAmount
        FROM 
          dedebi.docpayment 
        WHERE           
          shopid = '$shopIdString'
          AND perioddatetime >= toDateTime('$startDateTimeQuery') AND 
          perioddatetime <= toDateTime('$endDateTimeQuery')
        GROUP BY
          shopid, 
          branchid,
          docno,
          description
      ) AS subquery
      GROUP BY
        shopid, 
        branchid,
        docno
    ) AS dp
    ON d.shopid = dp.shopid AND d.branchid = dp.branchid AND d.docno = dp.docno
    ORDER BY docdatetime DESC 
    ''';

      var value = await clickHouseSelect(query);
      ResponseDataModel responseData = ResponseDataModel.fromJson(value);

      for (var item in responseData.data) {
        // Convert paymentlist string to JSON array
        try {
          item['paymentlist'] = jsonDecode(item['paymentlist']);
        } catch (e) {
          item['paymentlist'] = [];
        }
        SaleDailyListModel saleDaily = SaleDailyListModel.fromJson(item);
        saleDailyDatas.add(saleDaily);
      }

      emit(SaleDailyListLoadSuccess(data: saleDailyDatas));
    } catch (e) {
      emit(SaleDailyListLoadFail(message: e.toString()));
    }
  }

  void _saledailyLoadFinish(SaleDailyListLoadFinish event, Emitter<SaleDailyListState> emit) async {
    emit(SaleDailyListLoadStop());
  }
}

class SaleDailyListLoadStop extends SaleDailyListState {}

class SaleDailyListLoadFinish extends SaleDailyListEvent {}

class SaleDailyListLoading extends SaleDailyListState {}
