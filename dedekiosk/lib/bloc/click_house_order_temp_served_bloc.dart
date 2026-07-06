import 'dart:convert';
import 'package:dedekiosk/model/global_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/global.dart' as global;

abstract class ClickHouseOrderTempServedEvent {}

abstract class ClickHouseOrderTempServedState {
  //ClickHouseOrderTempServedModel result = ClickHouseOrderTempServedModel();
}

class ClickHouseOrderTempServedStateInitialized extends ClickHouseOrderTempServedState {}

class ClickHouseOrderTempServedLoadStart extends ClickHouseOrderTempServedEvent {
  ClickHouseOrderTempServedLoadStart();
}

class ClickHouseOrderTempServedLoadAllStart extends ClickHouseOrderTempServedEvent {
  ClickHouseOrderTempServedLoadAllStart();
}

class ClickHouseOrderTempServedLoadSuccess extends ClickHouseOrderTempServedState {
  List<OrderTempDocModel> clickHouseOrderTempServed;
  ClickHouseOrderTempServedLoadSuccess({required this.clickHouseOrderTempServed});
}

class ClickHouseOrderTempServedBloc extends Bloc<ClickHouseOrderTempServedEvent, ClickHouseOrderTempServedState> {
  ClickHouseOrderTempServedBloc() : super(ClickHouseOrderTempServedStateInitialized()) {
    on<ClickHouseOrderTempServedLoadStart>(_clickHouseOrderTempServedLoadStart);
    on<ClickHouseOrderTempServedLoadFinish>(_clickHouseOrderTempServedLoadFinish);
  }

  void _clickHouseOrderTempServedLoadStart(ClickHouseOrderTempServedLoadStart event, Emitter<ClickHouseOrderTempServedState> emit) async {
    emit(ClickHouseOrderTempServedLoading());
    List<OrderTempDocModel> orderDocList = [];
    try {
      String tableTempNameDoc = (global.deviceConfig.systemCondition != 1) ? "ordertempdoc" : "ordertempdocpaylater";
      String tableTempName = (global.deviceConfig.systemCondition != 1) ? "ordertemp" : "ordertemppaylater";

      String query =
          "SELECT * FROM ${global.clickHouseDatabaseName}.$tableTempNameDoc WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderdatetime > now() - INTERVAL 1 HOUR order by servedsuccess,orderdatetime";
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
            orderdatetime: DateTime.parse(responseData.data[i]['orderdatetime']),
            ordertagnumber: responseData.data[i]['ordertagnumber'],
            orderid: responseData.data[i]['orderid'],
            phonenumber: responseData.data[i]['phonenumber'],
            tablenumber: responseData.data[i]['tablenumber'],
            ordernumber: responseData.data[i]['ordernumber'],
            queuenumber: int.parse(responseData.data[i]['queuenumber'].toString()),
            ordertype: responseData.data[i]['ordertype'],
            istakeaway: responseData.data[i]['istakeaway'],
            salechannelcode: responseData.data[i]['salechannelcode'],
            kitchensuccess: (int.tryParse(responseData.data[i]['kitchensuccess'].toString()) == 1) ? true : false,
            servedsuccess: responseData.data[i]['servedsuccess'],
            orderpaysuccess: (int.tryParse(responseData.data[i]['orderpaysuccess'].toString())) ?? 0,
            copyprintsuccess: (int.tryParse(responseData.data[i]['copyprintsuccess'].toString())) ?? 0,
            payresult: pay,
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
            "SELECT * FROM ${global.clickHouseDatabaseName}.$tableTempName WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderid in ($orderIdList) order by orderdatetime,linenumber";
        var orderDetailResult = await api.clickHouseSelect(query);
        ResponseDataModel orderDetailResponseData = ResponseDataModel.fromJson(orderDetailResult);
        for (int i = 0; i < orderDetailResponseData.data.length; i++) {
          for (int j = 0; j < orderDocList.length; j++) {
            if (orderDetailResponseData.data[i]['orderid'] == orderDocList[j].order.orderid) {
              orderDocList[j].orderDetails.add(OrderTempDetailModel.fromJson(orderDetailResponseData.data[i]));
            }
          }
        }

        for (int j = 0; j < orderDocList.length; j++) {
          double qty = 0;
          double cookedqty = 0;
          double servedqty = 0;
          for (int i = 0; i < orderDocList[j].orderDetails.length; i++) {
            qty += orderDocList[j].orderDetails[i].qty;
            cookedqty += orderDocList[j].orderDetails[i].iscooked;
            servedqty += orderDocList[j].orderDetails[i].isserved;
          }
          if (cookedqty >= qty) {
            orderDocList[j].order.kitchensuccess = true;
          }
          if (servedqty >= qty) {
            orderDocList[j].order.servedsuccess = true;
          }
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
    // เรียงใหม่ กรณี ยังไม่เสร็จ ให้เรียงเวลา จากน้อยไปมาก กรณีเสร็จแล้ว ให้เรียงเวลา จากมากไปน้อย
    List<OrderTempDocModel> orderDocWaitForCookList = [];
    List<OrderTempDocModel> orderDocCookedList = [];
    for (int i = 0; i < orderDocList.length; i++) {
      if (orderDocList[i].order.servedsuccess) {
        orderDocCookedList.add(orderDocList[i]);
      } else {
        orderDocWaitForCookList.add(orderDocList[i]);
      }
    }
    orderDocWaitForCookList.sort((a, b) => a.order.orderdatetime.compareTo(a.order.orderdatetime));
    orderDocCookedList.sort((a, b) => b.order.orderdatetime.compareTo(a.order.orderdatetime));
    List<OrderTempDocModel> orderDocListSorted = [];
    orderDocListSorted.addAll(orderDocWaitForCookList);
    orderDocListSorted.addAll(orderDocCookedList);

    emit(ClickHouseOrderTempServedLoadSuccess(clickHouseOrderTempServed: orderDocListSorted));
  }

  void _clickHouseOrderTempServedLoadFinish(ClickHouseOrderTempServedLoadFinish event, Emitter<ClickHouseOrderTempServedState> emit) async {
    emit(ClickHouseOrderTempServedLoadStop());
  }
}

class ClickHouseOrderTempServedLoadStop extends ClickHouseOrderTempServedState {}

class ClickHouseOrderTempServedLoadFinish extends ClickHouseOrderTempServedEvent {}

class ClickHouseOrderTempServedLoading extends ClickHouseOrderTempServedState {}
