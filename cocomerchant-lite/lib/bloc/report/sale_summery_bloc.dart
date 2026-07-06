import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:cocomerchant_lite/model/sale_summery_model.dart';
import 'package:cocomerchant_lite/api/click_house_api.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:intl/intl.dart';
import 'package:cocomerchant_lite/global.dart' as global;

abstract class SaleSummeryEvent {}

abstract class SaleSummeryState {}

class SaleSummeryStateInitialized extends SaleSummeryState {}

class SaleSummeryLoadStart extends SaleSummeryEvent {
  // 0 = รายวัน, 1 = รายเดือน
  int mode;
  DateTime startDateTime;
  DateTime endDateTime;
  String shopIdList;

  SaleSummeryLoadStart({required this.mode, required this.startDateTime, required this.endDateTime, required this.shopIdList});
}

class SaleSummeryLoadSuccess extends SaleSummeryState {
  List<SaleSummeryModel> data;
  SaleSummeryLoadSuccess({required this.data});
}

class SaleSummeryMachineCountSuccess extends SaleSummeryState {
  int count;
  SaleSummeryMachineCountSuccess({required this.count});
}

class SaleSummeryBloc extends Bloc<SaleSummeryEvent, SaleSummeryState> {
  SaleSummeryBloc() : super(SaleSummeryStateInitialized()) {
    on<SaleSummeryLoadStart>(_saleSummeryLoadStart);
    on<SaleSummeryLoadFinish>(_saleSummeryLoadFinish);
  }

  void _saleSummeryLoadStart(SaleSummeryLoadStart event, Emitter<SaleSummeryState> emit) async {
    emit(SaleSummeryLoading());
    try {
      List<SaleSummeryModel> saleSummeryDataList = [];
      if (event.mode == 0) {
        // รวมวัน 7 วัน ย้อนหลัง
        // ดึงเวลาท้องถิ่น และคำนวณ UTC จากเวลาท้องถิ่น ไปเป็น UTC ก่อน format (yyyy-MM-dd HH:mm:ss)
        String startDateTimeQuery = DateFormat('yyyy-MM-dd HH:mm:ss').format(event.startDateTime.toUtc());
        String endDateTimeQuery = DateFormat('yyyy-MM-dd HH:mm:ss').format(event.endDateTime.toUtc());

        String shopIdListString = event.shopIdList;

        String query = '''
          SELECT shopid,toDate(perioddatetime) AS docdate,sum(totalamount) as totalamount FROM dedebi.doc 
          WHERE perioddatetime >= toDateTime('$startDateTimeQuery') 
          AND perioddatetime <= toDateTime('$endDateTimeQuery') 
          AND shopid = '$shopIdListString' 
          GROUP BY shopid,toDate(perioddatetime) ORDER BY shopid,docdate;
        ''';

        var value = await clickHouseSelect(query);
        ResponseDataModel responseData = ResponseDataModel.fromJson(value);
        for (var item in responseData.data) {
          saleSummeryDataList.add(SaleSummeryModel.fromJson(item));
        }
      }

      emit(SaleSummeryLoadSuccess(data: saleSummeryDataList));
    } catch (e) {
      print("error $e");
    }
  }

  void _saleSummeryLoadFinish(SaleSummeryLoadFinish event, Emitter<SaleSummeryState> emit) async {
    emit(SaleSummeryLoadStop());
  }
}

class SaleSummeryLoadStop extends SaleSummeryState {}

class SaleSummeryLoadFinish extends SaleSummeryEvent {}

class SaleSummeryLoading extends SaleSummeryState {}
