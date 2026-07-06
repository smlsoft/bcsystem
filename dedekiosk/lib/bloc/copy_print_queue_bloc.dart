import 'dart:convert';
import 'package:dedekiosk/model/global_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/global.dart' as global;

// Events
abstract class CopyPrintQueueEvent {}

class CopyPrintQueueLoadStart extends CopyPrintQueueEvent {}

class CopyPrintQueueLoadFinish extends CopyPrintQueueEvent {}

class CopyPrintQueueMarkAllPrinted extends CopyPrintQueueEvent {}

class CopyPrintQueueMarkOnePrinted extends CopyPrintQueueEvent {
  final String orderId;
  final String orderNumber;
  CopyPrintQueueMarkOnePrinted({required this.orderId, required this.orderNumber});
}

// States
abstract class CopyPrintQueueState {}

class CopyPrintQueueInitialized extends CopyPrintQueueState {}

class CopyPrintQueueLoading extends CopyPrintQueueState {}

class CopyPrintQueueLoadSuccess extends CopyPrintQueueState {
  final List<OrderTempModel> copyPrintQueue;
  CopyPrintQueueLoadSuccess({required this.copyPrintQueue});
}

class CopyPrintQueueLoadError extends CopyPrintQueueState {
  final String message;
  CopyPrintQueueLoadError({required this.message});
}

class CopyPrintQueueMarkAllSuccess extends CopyPrintQueueState {}

class CopyPrintQueueMarkAllError extends CopyPrintQueueState {
  final String message;
  CopyPrintQueueMarkAllError({required this.message});
}

// Bloc
class CopyPrintQueueBloc extends Bloc<CopyPrintQueueEvent, CopyPrintQueueState> {
  CopyPrintQueueBloc() : super(CopyPrintQueueInitialized()) {
    on<CopyPrintQueueLoadStart>(_onLoadStart);
    on<CopyPrintQueueLoadFinish>(_onLoadFinish);
    on<CopyPrintQueueMarkAllPrinted>(_onMarkAllPrinted);
    on<CopyPrintQueueMarkOnePrinted>(_onMarkOnePrinted);
  }

  Future<void> _onLoadStart(CopyPrintQueueLoadStart event, Emitter<CopyPrintQueueState> emit) async {
    emit(CopyPrintQueueLoading());
    try {
      List<OrderTempModel> copyPrintQueue = await _loadCopyPrintQueue();
      emit(CopyPrintQueueLoadSuccess(copyPrintQueue: copyPrintQueue));
    } catch (e, s) {
      if (kDebugMode) {
        print('CopyPrintQueueBloc error: $e');
        print(s);
      }
      emit(CopyPrintQueueLoadError(message: e.toString()));
    }
  }

  void _onLoadFinish(CopyPrintQueueLoadFinish event, Emitter<CopyPrintQueueState> emit) {
    // Do nothing, just finish loading state
  }

  Future<void> _onMarkAllPrinted(CopyPrintQueueMarkAllPrinted event, Emitter<CopyPrintQueueState> emit) async {
    emit(CopyPrintQueueLoading());
    try {
      await _markAllCopyPrintSuccess();
      emit(CopyPrintQueueMarkAllSuccess());
      // Reload the queue
      List<OrderTempModel> copyPrintQueue = await _loadCopyPrintQueue();
      emit(CopyPrintQueueLoadSuccess(copyPrintQueue: copyPrintQueue));
    } catch (e, s) {
      if (kDebugMode) {
        print('CopyPrintQueueBloc markAll error: $e');
        print(s);
      }
      emit(CopyPrintQueueMarkAllError(message: e.toString()));
    }
  }

  Future<void> _onMarkOnePrinted(CopyPrintQueueMarkOnePrinted event, Emitter<CopyPrintQueueState> emit) async {
    emit(CopyPrintQueueLoading());
    try {
      await _markOneCopyPrintSuccess(event.orderId, event.orderNumber);
      // Reload the queue
      List<OrderTempModel> copyPrintQueue = await _loadCopyPrintQueue();
      emit(CopyPrintQueueLoadSuccess(copyPrintQueue: copyPrintQueue));
    } catch (e, s) {
      if (kDebugMode) {
        print('CopyPrintQueueBloc markOne error: $e');
        print(s);
      }
      emit(CopyPrintQueueLoadError(message: e.toString()));
    }
  }

  /// โหลดรายการที่ยังไม่พิมพ์สำเนา (copyprintsuccess=0)
  Future<List<OrderTempModel>> _loadCopyPrintQueue() async {
    String tableName = "${global.clickHouseDatabaseName}.ordertempdoc";
    String where = "where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}'";
    where += " and (detailsuccess=1 and isclose=1 and copyprintsuccess=0)";

    List<OrderTempModel> orderTempDocList = [];
    String selectQuery =
        "select orderid, ordernumber, orderdatetime, phonenumber, tablenumber, queuenumber, ordertype, ordertagnumber, paycondition, discountword, discountamount, diffamount, totalamount, vatamount, saveamount, beforvat, vatrate, exceptvat, istakeaway, aftervat, salechannelcode, orderpaysuccess, copyprintsuccess from $tableName $where order by orderdatetime";

    var value = await api.clickHouseSelect(selectQuery);
    ResponseDataModel responseData = ResponseDataModel.fromJson(value);

    for (var order in responseData.data) {
      PayResultModel payResult = PayResultModel();
      payResult.discountWord = order["discountword"];
      payResult.discountAmount = double.tryParse(order["discountamount"].toString()) ?? 0;
      payResult.diffAmount = double.tryParse(order["diffamount"].toString()) ?? 0;
      payResult.totalAmount = double.tryParse(order["totalamount"].toString()) ?? 0;
      payResult.vatAmount = double.tryParse(order["vatamount"].toString()) ?? 0;
      payResult.saveAmount = double.tryParse(order["saveamount"].toString()) ?? 0;
      payResult.vatrate = double.tryParse(order["vatrate"].toString()) ?? 0;
      payResult.totalAmountExceptVat = double.tryParse(order["exceptvat"].toString()) ?? 0;
      payResult.totalAmountAfterVat = double.tryParse(order["aftervat"].toString()) ?? 0;
      payResult.totalAmountBeforeVat = double.tryParse(order["beforvat"].toString()) ?? 0;

      if (order["paycondition"].toString().isNotEmpty) {
        payResult.payCondition = (jsonDecode(order["paycondition"]) as List).map((e) => PayConditionModel.fromJson(e)).toList();
      }

      orderTempDocList.add(
        OrderTempModel(
          ordertagnumber: order["ordertagnumber"],
          orderid: order["orderid"],
          ordertype: order["ordertype"],
          istakeaway: order["istakeaway"],
          phonenumber: order["phonenumber"],
          tablenumber: order["tablenumber"],
          queuenumber: int.tryParse(order["queuenumber"].toString()) ?? 0,
          ordernumber: order["ordernumber"],
          payresult: payResult,
          salechannelcode: order["salechannelcode"],
          orderdatetime: DateTime.tryParse(order["orderdatetime"]) ?? DateTime.now(),
          kitchensuccess: false,
          servedsuccess: false,
          orderpaysuccess: (int.tryParse(order["orderpaysuccess"].toString())) ?? 0,
          copyprintsuccess: (int.tryParse(order["copyprintsuccess"].toString())) ?? 0,
        ),
      );
    }
    return orderTempDocList;
  }

  /// อัพเดทสถานะสำเนาทั้งหมดเป็นพิมพ์แล้ว
  Future<void> _markAllCopyPrintSuccess() async {
    String query =
        "alter table ${global.clickHouseDatabaseName}.ordertempdoc update copyprintsuccess=1 where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and copyprintsuccess=0 and detailsuccess=1 and isclose=1";
    await api.clickHouseExecute(query);
  }

  /// อัพเดทสถานะสำเนา 1 รายการเป็นพิมพ์แล้ว
  Future<void> _markOneCopyPrintSuccess(String orderId, String orderNumber) async {
    String query =
        "alter table ${global.clickHouseDatabaseName}.ordertempdoc update copyprintsuccess=1 where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and copyprintsuccess=0 and orderid='$orderId' and ordernumber='$orderNumber'";
    await api.clickHouseExecute(query);
  }
}
