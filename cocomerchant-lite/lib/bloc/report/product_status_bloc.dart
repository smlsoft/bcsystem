import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:cocomerchant_lite/model/product_status_model.dart';
import 'package:cocomerchant_lite/api/click_house_api.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:intl/intl.dart';
import 'package:cocomerchant_lite/global.dart' as global;

abstract class ProductStatusEvent {}

abstract class ProductStatusState {}

class ProductStatusStateInitialized extends ProductStatusState {}

class ProductStatusLoadStart extends ProductStatusEvent {
  int mode;
  DateTime startDateTime;
  DateTime endDateTime;

  ProductStatusLoadStart({required this.mode, required this.startDateTime, required this.endDateTime});
}

class ProductStatusLoadSuccess extends ProductStatusState {
  List<ProductStatusModel> data;
  ProductStatusLoadSuccess({required this.data});
}

class ProductStatusMachineCountSuccess extends ProductStatusState {
  int count;
  ProductStatusMachineCountSuccess({required this.count});
}

class ProductStatusBloc extends Bloc<ProductStatusEvent, ProductStatusState> {
  ProductStatusBloc() : super(ProductStatusStateInitialized()) {
    on<ProductStatusLoadStart>(_productStatusLoadStart);
    on<ProductStatusLoadFinish>(_productStatusLoadFinish);
  }

  void _productStatusLoadStart(ProductStatusLoadStart event, Emitter<ProductStatusState> emit) async {
    emit(ProductStatusLoading());
    try {
      List<ProductStatusModel> productStatusDataList = [];
      if (event.mode == 0) {
        // รวมวัน 7 วัน ย้อนหลัง
        // ดึงเวลาท้องถิ่น และคำนวณ UTC จากเวลาท้องถิ่น ไปเป็น UTC ก่อน format (yyyy-MM-dd HH:mm:ss)
        String shopIdListString = global.appConfig.read("shopid");

        String startDateTimeQuery = DateFormat('yyyy-MM-dd HH:mm:ss').format(event.startDateTime.toUtc());
        String endDateTimeQuery = DateFormat('yyyy-MM-dd HH:mm:ss').format(event.endDateTime.toUtc());
        String query = '''
          SELECT 
              d.*,
              p.name0 AS productname
          FROM (
              SELECT 
                  shopid,
                  barcode,
                  unitcode,
                  sum(qty) AS totalquantity,
                  sum(sumamount) AS totalamount 
              FROM dedebi.docdetail 
              WHERE perioddatetime >= toDateTime('$startDateTimeQuery') 
              AND perioddatetime <= toDateTime('$endDateTimeQuery') 
              AND shopid = '${shopIdListString}'
              GROUP BY shopid,barcode, unitcode
          ) AS d
          LEFT JOIN dedebi.productbarcode AS p
          ON d.barcode = p.barcode  AND d.shopid = p.shopid''';
        var value = await clickHouseSelect(query);
        ResponseDataModel responseData = ResponseDataModel.fromJson(value);
        for (var item in responseData.data) {
          productStatusDataList.add(ProductStatusModel.fromJson(item));
        }
      }

      emit(ProductStatusLoadSuccess(data: productStatusDataList));
    } catch (e) {
      print("error $e");
      emit(ProductStatusLoadFail(message: e.toString()));
    }
  }

  void _productStatusLoadFinish(ProductStatusLoadFinish event, Emitter<ProductStatusState> emit) async {
    emit(ProductStatusLoadStop());
  }
}

class ProductStatusLoadFail extends ProductStatusState {
  String message;
  ProductStatusLoadFail({required this.message});
}

class ProductStatusLoadStop extends ProductStatusState {}

class ProductStatusLoadFinish extends ProductStatusEvent {}

class ProductStatusLoading extends ProductStatusState {}
