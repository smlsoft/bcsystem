import 'dart:convert';
import 'package:dedekiosk/model/global_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/global.dart' as global;

abstract class ClickHouseOrderTempEvent {}

abstract class ClickHouseOrderTempState {
  //ClickHouseOrderTempModel result = ClickHouseOrderTempModel();
}

class ClickHouseOrderTempStateInitialized extends ClickHouseOrderTempState {}

class ClickHouseOrderTempLoadStart extends ClickHouseOrderTempEvent {
  final String tableNumber;

  ClickHouseOrderTempLoadStart({required this.tableNumber});
}

class ClickHouseOrderTempLoadAllStart extends ClickHouseOrderTempEvent {
  ClickHouseOrderTempLoadAllStart();
}

class ClickHouseOrderTempLoadSuccess extends ClickHouseOrderTempState {
  List<OrderTempDocModel> clickHouseOrderTemp;
  ClickHouseOrderTempLoadSuccess({required this.clickHouseOrderTemp});
}

class ClickHouseOrderTempBloc
    extends Bloc<ClickHouseOrderTempEvent, ClickHouseOrderTempState> {
  ClickHouseOrderTempBloc() : super(ClickHouseOrderTempStateInitialized()) {
    on<ClickHouseOrderTempLoadStart>(_clickHouseOrderTempLoadStart);
    on<ClickHouseOrderTempLoadFinish>(_clickHouseOrderTempLoadFinish);
  }

  void _clickHouseOrderTempLoadStart(ClickHouseOrderTempLoadStart event,
      Emitter<ClickHouseOrderTempState> emit) async {
    emit(ClickHouseOrderTempLoading());
    List<OrderTempDocModel> orderDocList = [];
    try {
      // ดึงเอกสารที่ยังไม่ได้เสิร์ฟ
      String query =
          "SELECT * FROM ${global.orderTempDocTableName()} WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and ordertagnumber='${event.tableNumber}' and orderpaysuccess=0 order by orderdatetime";
      var result = await api.clickHouseSelect(query);
      List<String> orderDocIdList = [];
      ResponseDataModel responseData = ResponseDataModel.fromJson(result);
      for (int i = 0; i < responseData.data.length; i++) {
        orderDocIdList.add(responseData.data[i]['orderid']);
        // จ่าย
        var pay = PayResultModel();
        var payCondition = responseData.data[i]['paycondition'];
        var json = jsonDecode(payCondition);
        pay.payCondition = [];
        for (int i = 0; i < json.length; i++) {
          pay.payCondition.add(PayConditionModel.fromJson(json[i]));
        }

        orderDocList.add(OrderTempDocModel(
          order: OrderTempModel(
            orderdatetime:
                DateTime.parse(responseData.data[i]['orderdatetime']),
            ordertagnumber: responseData.data[i]['ordertagnumber'],
            orderid: responseData.data[i]['orderid'],
            phonenumber: responseData.data[i]['phonenumber'],
            tablenumber: responseData.data[i]['tablenumber'],
            ordernumber: responseData.data[i]['ordernumber'],
            queuenumber: responseData.data[i]['queuenumber'],
            ordertype: responseData.data[i]['ordertype'],
            istakeaway: responseData.data[i]['istakeaway'],
            salechannelcode: responseData.data[i]['salechannelcode'],
            payresult: pay,
            kitchensuccess: (int.tryParse(
                    responseData.data[i]['kitchensuccess'].toString()) ==
                1),
            servedsuccess: (int.tryParse(
                    responseData.data[i]['servedsuccess'].toString()) ==
                1),
            orderpaysuccess: (int.tryParse(
                    responseData.data[i]['orderpaysuccess'].toString())) ??
                0,
                copyprintsuccess:  (int.tryParse(
                    responseData.data[i]['copyprintsuccess'].toString())) ?? 0,
          ),
          orderDetails: [],
        ));
      }

      // ดึงรายการย่อย ตามเอกสาร orderDocIdList
      String orderIdList = "";
      for (int i = 0; i < orderDocIdList.length; i++) {
        orderIdList += "'${orderDocIdList[i]}'";
        if (i < orderDocIdList.length - 1) {
          orderIdList += ",";
        }
      }
      if (orderIdList.isNotEmpty) {
        query =
            "SELECT * FROM ${global.orderTempTableName()} WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderid in ($orderIdList) and orderpaysuccess=0 order by orderdatetime,linenumber";
        var orderDetailResult = await api.clickHouseSelect(query);
        ResponseDataModel orderDetailResponseData =
            ResponseDataModel.fromJson(orderDetailResult);
        for (int i = 0; i < orderDetailResponseData.data.length; i++) {
          for (int j = 0; j < orderDocList.length; j++) {
            if (orderDetailResponseData.data[i]['orderid'] ==
                orderDocList[j].order.orderid) {
              orderDocList[j].orderDetails.add(OrderTempDetailModel.fromJson(
                  orderDetailResponseData.data[i]));
            }
          }
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
    emit(ClickHouseOrderTempLoadSuccess(clickHouseOrderTemp: orderDocList));
  }

  void _clickHouseOrderTempLoadFinish(ClickHouseOrderTempLoadFinish event,
      Emitter<ClickHouseOrderTempState> emit) async {
    emit(ClickHouseOrderTempLoadStop());
  }
}

class ClickHouseOrderTempLoadStop extends ClickHouseOrderTempState {}

class ClickHouseOrderTempLoadFinish extends ClickHouseOrderTempEvent {}

class ClickHouseOrderTempLoading extends ClickHouseOrderTempState {}
