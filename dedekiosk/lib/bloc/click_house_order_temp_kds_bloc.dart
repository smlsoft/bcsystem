import 'dart:convert';
import 'package:dedekiosk/model/global_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/global.dart' as global;

abstract class ClickHouseOrderTempKdsEvent {}

abstract class ClickHouseOrderTempKdsState {
  //ClickHouseOrderTempKdsModel result = ClickHouseOrderTempKdsModel();
}

class ClickHouseOrderTempKdsStateInitialized extends ClickHouseOrderTempKdsState {}

class ClickHouseOrderTempKdsLoadStart extends ClickHouseOrderTempKdsEvent {
  ClickHouseOrderTempKdsLoadStart();
}

class ClickHouseOrderTempKdsLoadAllStart extends ClickHouseOrderTempKdsEvent {
  ClickHouseOrderTempKdsLoadAllStart();
}

class ClickHouseOrderTempKdsLoadSuccess extends ClickHouseOrderTempKdsState {
  List<OrderTempDocModel> clickHouseOrderTempKds;
  ClickHouseOrderTempKdsLoadSuccess({required this.clickHouseOrderTempKds});
}

class ClickHouseOrderTempKdsBloc extends Bloc<ClickHouseOrderTempKdsEvent, ClickHouseOrderTempKdsState> {
  ClickHouseOrderTempKdsBloc() : super(ClickHouseOrderTempKdsStateInitialized()) {
    on<ClickHouseOrderTempKdsLoadStart>(_clickHouseOrderTempKdsLoadStart);
    on<ClickHouseOrderTempKdsLoadFinish>(_clickHouseOrderTempKdsLoadFinish);
  }

  void _clickHouseOrderTempKdsLoadStart(ClickHouseOrderTempKdsLoadStart event, Emitter<ClickHouseOrderTempKdsState> emit) async {
    emit(ClickHouseOrderTempKdsLoading());
    List<OrderTempDocModel> orderDocList = [];
    try {
      String query =
          "SELECT * FROM ${global.orderTempDocTableName()} WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderdatetime > now() - INTERVAL 1 HOUR order by kitchensuccess,orderdatetime";
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
            queuenumber: (int.tryParse(responseData.data[i]['queuenumber'].toString())) ?? 0,
            ordertype: (int.tryParse(responseData.data[i]['ordertype'].toString())) ?? 0,
            istakeaway: (int.tryParse(responseData.data[i]['istakeaway'].toString())) ?? 0,
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
            "SELECT * FROM ${global.orderTempTableName()} WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderid in ($orderIdList) order by orderdatetime,linenumber";
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
      if (orderDocList[i].order.kitchensuccess) {
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

    emit(ClickHouseOrderTempKdsLoadSuccess(clickHouseOrderTempKds: orderDocListSorted));
  }

  void _clickHouseOrderTempKdsLoadFinish(ClickHouseOrderTempKdsLoadFinish event, Emitter<ClickHouseOrderTempKdsState> emit) async {
    emit(ClickHouseOrderTempKdsLoadStop());
  }
}

class ClickHouseOrderTempKdsLoadStop extends ClickHouseOrderTempKdsState {}

class ClickHouseOrderTempKdsLoadFinish extends ClickHouseOrderTempKdsEvent {}

class ClickHouseOrderTempKdsLoading extends ClickHouseOrderTempKdsState {}
