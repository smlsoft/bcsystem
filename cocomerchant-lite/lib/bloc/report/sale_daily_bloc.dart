import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:cocomerchant_lite/model/shop_model.dart';
import 'package:cocomerchant_lite/model/user_login_model.dart';
import 'package:cocomerchant_lite/api/click_house_api.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/sale_daily_model.dart';
import 'package:intl/intl.dart';
import 'package:cocomerchant_lite/global.dart' as global;

abstract class SaleDailyEvent {}

abstract class SaleDailyState {}

class SaleDailyStateInitialized extends SaleDailyState {}

class SaleDailyLoadStart extends SaleDailyEvent {
  DateTime startDateTime;
  DateTime endDateTime;

  SaleDailyLoadStart({
    required this.startDateTime,
    required this.endDateTime,
  });
}

class SaleDailyLoadInProgress extends SaleDailyState {}

class SaleDailyLoadSuccess extends SaleDailyState {
  List<SaleDailyModel> data;
  SaleDailyLoadSuccess({required this.data});
}

class SaleDailyLoadFail extends SaleDailyState {
  String message;
  SaleDailyLoadFail({required this.message});
}

class SaleDailyMachineCountSuccess extends SaleDailyState {
  int count;
  SaleDailyMachineCountSuccess({required this.count});
}

class SaleDailyBloc extends Bloc<SaleDailyEvent, SaleDailyState> {
  SaleDailyBloc() : super(SaleDailyStateInitialized()) {
    on<SaleDailyLoadStart>(_saledailyLoadStart);
    on<SaleDailyLoadFinish>(_saledailyLoadFinish);
  }

  void _saledailyLoadStart(SaleDailyLoadStart event, Emitter<SaleDailyState> emit) async {
    emit(SaleDailyLoadInProgress());
    try {
      List<SaleDailyModel> saleDailyDatas = [];
      // ดึงเวลาท้องถิ่น และคำนวณ UTC จากเวลาท้องถิ่น ไปเป็น UTC ก่อน format (yyyy-MM-dd HH:mm:ss)
      String startDateTimeQuery = DateFormat('yyyy-MM-dd HH:mm:ss').format(event.startDateTime.toUtc());
      String endDateTimeQuery = DateFormat('yyyy-MM-dd HH:mm:ss').format(event.endDateTime.toUtc());

      String shopIdListString = global.appConfig.read("shopid");

      String query = '''
      SELECT 
        d.shopid, 
        d.branchid,
        d.totalamount,
        ((d.totalpaycashamount - d.totalroundamount) + dp.totalpaymentlist) as totalpayamount,
        d.totalpaycashamount as totalpaycashamount,
        d.totalpaycashchange,
        d.totalroundamount,
        dp.paymentlist,
        d.doccount,
         toFloat64(dp.totalpaymentlist) as totalpaymentlist
      FROM (
        SELECT 
          shopid, 
          branchid,
          sum(totalamount) as totalamount,
          sum(paycashamount) as totalpaycashamount,
          sum(paycashchange) as totalpaycashchange,
          sum(roundamount) as totalroundamount,
          count(docno) as doccount
        FROM 
          dedebi.doc 
        WHERE 
          perioddatetime >= toDateTime('$startDateTimeQuery') 
          AND perioddatetime <= toDateTime('$endDateTimeQuery') 
          AND shopid = '$shopIdListString'
        GROUP BY 
          shopid, 
          branchid
      ) AS d
      LEFT JOIN (
        SELECT 
          shopid, 
          branchid,
          '[' || arrayStringConcat(groupArray(
            concat(
              '{"description":"', description, '","totalamount":', toString(totalAmount), '}'
            )), ',') || ']' as paymentlist,
          sum(totalAmount) as totalpaymentlist
        FROM (
          SELECT 
            shopid, 
            branchid, 
            description, 
            sum(amount) as totalAmount
          FROM 
            dedebi.docpayment 
          WHERE 
            perioddatetime >= toDateTime('$startDateTimeQuery') 
            AND perioddatetime <= toDateTime('$endDateTimeQuery')
            AND shopid = '$shopIdListString'
          GROUP BY
            shopid, 
            branchid, 
            description
        ) AS subquery
        GROUP BY
          shopid, 
          branchid
      ) AS dp
      ON d.shopid = dp.shopid AND d.branchid = dp.branchid
      ORDER BY 
        d.shopid, 
        d.branchid;
      ''';

      var value = await clickHouseSelect(query);
      ResponseDataModel responseData = ResponseDataModel.fromJson(value);

      for (var item in responseData.data) {
        try {
          item['paymentlist'] = jsonDecode(item['paymentlist']);
        } catch (e) {
          item['paymentlist'] = [];
        }
        SaleDailyModel saleDaily = SaleDailyModel.fromJson(item);
        saleDailyDatas.add(saleDaily);
      }

      if (saleDailyDatas.isEmpty) {
        saleDailyDatas.add(SaleDailyModel(
            shopid: '',
            branchid: '',
            totalamount: 0,
            totalpayamount: 0,
            totalpaycashamount: 0,
            totalpaycashchange: 0,
            totalroundamount: 0,
            paymentlist: [],
            totalpaymentlist: 0,
            doccount: 0));
      }

      emit(SaleDailyLoadSuccess(data: saleDailyDatas));
    } catch (e) {
      print("error $e");
      emit(SaleDailyLoadFail(message: "Error SaleDailyBloc _saledailyLoadStart() $e"));
    }
  }

  void _saledailyLoadFinish(SaleDailyLoadFinish event, Emitter<SaleDailyState> emit) async {
    emit(SaleDailyLoadStop());
  }
}

class SaleDailyLoadStop extends SaleDailyState {}

class SaleDailyLoadFinish extends SaleDailyEvent {}

class SaleDailyLoading extends SaleDailyState {}
