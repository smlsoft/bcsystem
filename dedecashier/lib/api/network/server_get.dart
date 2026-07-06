/// ⚠️ DEPRECATED: HTTP Server GET Handler
///
/// ❌ This file is DEPRECATED and will be removed in next version.
/// ✅ Use WebSocket Server instead: lib/api/network/websocket_server.dart
///
/// Migration guide:
/// - Replace HTTP GET with WebSocket sendCommand()
/// - Use message handlers in websocket_bootstrap.dart
/// - See websocket_example.dart for usage examples

@Deprecated('Use WebSocket Server instead. See lib/api/network/websocket_server.dart')
library;

import 'package:decimal/decimal.dart';
import 'package:dedecashier/api/sync/model/sync_model.dart';
import 'package:dedecashier/db/pos_log_helper.dart';
import 'package:dedecashier/db/product_barcode_status_helper.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/json/pos_process_model.dart';
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/model/objectbox/buffet_mode_struct.dart';
import 'package:dedecashier/model/objectbox/employees_struct.dart';
import 'package:dedecashier/model/objectbox/kitchen_struct.dart';
import 'package:dedecashier/model/objectbox/order_temp_struct.dart';
import 'package:dedecashier/model/objectbox/pos_log_struct.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:dedecashier/model/objectbox/product_category_struct.dart';
import 'package:dedecashier/model/objectbox/staff_client_struct.dart';
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:dedecashier/model/staff/staff_model.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_process.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dedecashier/db/product_barcode_helper.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kapi/models/qr_generate_response.dart';
import 'package:kapi/smlkapi.dart';
import 'package:uuid/uuid.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

/// Handle GET requests from HttpGetDataModel (used by WebSocket server for HTTP compatibility)
Future<void> serverGetByData(HttpGetDataModel httpGetData, HttpResponse response) async {
  try {
    await _processGetCommand(httpGetData, response);
  } catch (e, stackTrace) {
    AppLogger.error('[ServerGet] Error: $e\n$stackTrace');
    response.write('');
  }
  await response.close();
}

Future<void> serverGet(HttpRequest request, HttpResponse response) async {
  if (request.uri.path == '/scan') {
    bool isTerminal = (global.appMode == global.AppModeEnum.posTerminal);
    bool isClient = (global.appMode == global.AppModeEnum.posRemote);
    SyncDeviceModel resultData = SyncDeviceModel(
      deviceId: global.deviceId,
      deviceName: global.deviceName,
      ip: global.ipAddress,
      connected: true,
      isCashierTerminal: isTerminal,
      holdCodeActive: "",
      docModeActive: 0,
      isClient: isClient,
    );
    response.write(jsonEncode(resultData.toJson()));
  } else {
    try {
      String json = request.uri.query.split("json=")[1];
      HttpGetDataModel httpGetData = HttpGetDataModel.fromJson(await jsonDecode(utf8.decode(base64Decode(json))));
      try {
        await _processGetCommand(httpGetData, response);
      } catch (e, stackTrace) {
        AppLogger.error('[ServerGet] Command error: $e\n$stackTrace');
        response.write('');
      }
    } catch (e, stackTrace) {
      AppLogger.error('[ServerGet] Parse error: $e\n$stackTrace');
      response.write('');
    }
  }
  await response.close();
}

/// Process GET commands
Future<void> _processGetCommand(HttpGetDataModel httpGetData, HttpResponse response) async {
  try {
    switch (httpGetData.code) {
      case "get_connect":
        SyncStaffDeviceModel device = SyncStaffDeviceModel.fromJson(await jsonDecode(httpGetData.json));
        // ลบ ip ซ้ำออก
        global.staffClientList.removeWhere((element) => element.client_ip == device.clientIp);
        // ค้นหาว่า Guid มีการลงทะเบียนหรีือยัง ถ้ามีแล้ว ถือว่าผ่าน
        bool found = false;
        for (int index = 0; index < global.staffClientList.length; index++) {
          if (global.staffClientList[index].client_guid == device.clientGuid) {
            found = true;
            break;
          }
        }
        if (found == false) {
          // ถ้ารหัสตรง ให้เพิ่มเครื่องลูก
          global.staffClientList.add(StaffClientObjectBoxStruct(client_guid: device.clientGuid, client_name: device.clientName, client_ip: device.clientIp));
        }
        response.write("connected");
        break;
      case "get_pay_slip":
        var docNumber = httpGetData.json;
        var bill = global.objectBoxStore.box<BillObjectBoxStruct>().query(BillObjectBoxStruct_.doc_number.equals(docNumber)).build().findFirst();
        if (bill != null) {
          Directory dir = await global.createPath("posbill", bill.date_time);
          File file = File("${dir.path}/${bill.doc_number}.jpg");
          if (file.existsSync()) {
            Uint8List bytes = file.readAsBytesSync();
            response.headers.contentType = ContentType("image", "jpeg");
            String base64 = base64Encode(bytes);
            response.write(base64);
          } else {
            response.write("");
          }
        } else {
          response.write("");
        }
        break;
      case "pos_information":
        PosInformationModel data = PosInformationModel(
          shop_id: global.shopId,
          shop_name: global.getNameFromLanguage(global.profileSetting.company.names, global.userScreenLanguage),
        );
        response.write(jsonEncode(data.toJson()));
        break;
      case "staff.get_product_barcode_status":
        response.write(jsonEncode(ProductBarcodeStatusHelper().getAll()));
        break;
      case "staff.get_staff":
        List<StaffModel> staffData = [];
        final box = global.objectBoxStore.box<EmployeeObjectBoxStruct>();
        final result = box.query().build().find();
        for (var staff in result) {
          // print("Staff: ${staff.name}, Enabled: ${staff.is_enabled}");
          if (staff.is_enabled) {
            staffData.add(StaffModel(code: staff.code, name: staff.name));
          }
        }
        response.write(jsonEncode(staffData.map((e) => e.toJson()).toList()));
        break;
      case "kds.order_temp_get_data_from_kitchen":
        var jsonData = await jsonDecode(httpGetData.json);
        String kitchenId = jsonData["kitchenId"];
        final box = global.objectBoxStore.box<OrderTempObjectBoxStruct>();
        int duration = DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch;
        final result = box
            .query(
              OrderTempObjectBoxStruct_.kdsId
                  .equals(kitchenId)
                  .and(OrderTempObjectBoxStruct_.isOrder.equals(false))
                  .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                  .and((OrderTempObjectBoxStruct_.isOrderSendKdsSuccess.equals(true)))
                  .and((OrderTempObjectBoxStruct_.kdsSuccess.equals(false)).or(OrderTempObjectBoxStruct_.kdsSuccessTime.greaterThan(duration))),
            )
            .order(OrderTempObjectBoxStruct_.kdsSuccess)
            .order(OrderTempObjectBoxStruct_.orderDateTime)
            .build()
            .find();
        response.write(jsonEncode(result.map((e) => e.toJson()).toList()));
        break;
      case "staff.order_temp_get_data_checker":
        // ดึงข้อมูล Order ที่ยังไม่เสริฟท์
        List<OrderTempObjectBoxStruct> result = global.objectBoxStore
            .box<OrderTempObjectBoxStruct>()
            .query(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
            .order(OrderTempObjectBoxStruct_.orderDateTime)
            .build()
            .find();
        response.write(jsonEncode(result.map((e) => e.toJson()).toList()));
        break;
      case "staff.order_temp_get_data_from_orderid_and_barcode":
        var jsonData = await jsonDecode(httpGetData.json);
        String orderId = jsonData["orderId"];
        String barcode = jsonData["barcode"];
        bool isOrder = jsonData["isOrder"];
        String machineId = jsonData["machineId"];
        final result = (machineId.isEmpty)
            ? (barcode.isNotEmpty)
                  ? global.objectBoxStore
                        .box<OrderTempObjectBoxStruct>()
                        .query(
                          OrderTempObjectBoxStruct_.orderId
                              .equals(orderId)
                              .and(
                                OrderTempObjectBoxStruct_.barcode
                                    .equals(barcode)
                                    .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                                    .and(OrderTempObjectBoxStruct_.isOrder.equals(isOrder)),
                              ),
                        )
                        .build()
                        .find()
                  : global.objectBoxStore
                        .box<OrderTempObjectBoxStruct>()
                        .query(
                          OrderTempObjectBoxStruct_.orderId
                              .equals(orderId)
                              .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                              .and(OrderTempObjectBoxStruct_.isOrder.equals(isOrder)),
                        )
                        .build()
                        .find()
            : (barcode.isNotEmpty)
            ? global.objectBoxStore
                  .box<OrderTempObjectBoxStruct>()
                  .query(
                    OrderTempObjectBoxStruct_.orderId
                        .equals(orderId)
                        .and(
                          OrderTempObjectBoxStruct_.barcode
                              .equals(barcode)
                              .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                              .and(OrderTempObjectBoxStruct_.machineId.equals(machineId))
                              .and(OrderTempObjectBoxStruct_.isOrder.equals(isOrder)),
                        ),
                  )
                  .build()
                  .find()
            : global.objectBoxStore
                  .box<OrderTempObjectBoxStruct>()
                  .query(
                    OrderTempObjectBoxStruct_.orderId
                        .equals(orderId)
                        .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                        .and(OrderTempObjectBoxStruct_.machineId.equals(machineId))
                        .and(OrderTempObjectBoxStruct_.isOrder.equals(isOrder)),
                  )
                  .build()
                  .find();
        // Response
        response.write(jsonEncode(result.map((e) => e.toJson()).toList()));
        break;
      case "staff.order_temp_get_data_from_orderid":
        var jsonData = await jsonDecode(httpGetData.json);
        String orderId = jsonData["orderId"];
        bool isOrder = jsonData["isOrder"];
        String machineId = jsonData["machineId"];
        final result = (machineId.isEmpty)
            ? global.objectBoxStore
                  .box<OrderTempObjectBoxStruct>()
                  .query(
                    OrderTempObjectBoxStruct_.orderId
                        .equals(orderId)
                        .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                        .and(OrderTempObjectBoxStruct_.isOrder.equals(isOrder)),
                  )
                  .build()
                  .find()
            : global.objectBoxStore
                  .box<OrderTempObjectBoxStruct>()
                  .query(
                    OrderTempObjectBoxStruct_.orderId
                        .equals(orderId)
                        .and(OrderTempObjectBoxStruct_.machineId.equals(machineId))
                        .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                        .and(OrderTempObjectBoxStruct_.isOrder.equals(isOrder)),
                  )
                  .build()
                  .find();
        double orderQty = 0;
        for (var item in result) {
          orderQty += (item.orderQty - item.cancelQty);
        }
        OrderTempStruct orderTemp = OrderTempStruct(orderQty: orderQty, orderTemp: result);
        response.write(jsonEncode(orderTemp.toJson()));
        break;
      case "staff.order_temp_get_data_from_order_main_id":
        var jsonData = await jsonDecode(httpGetData.json);
        String orderMainId = jsonData["orderMainId"];
        bool isOrder = jsonData["isOrder"];
        String machineId = jsonData["machineId"];
        final result = (machineId.isEmpty)
            ? global.objectBoxStore
                  .box<OrderTempObjectBoxStruct>()
                  .query(
                    OrderTempObjectBoxStruct_.orderIdMain
                        .equals(orderMainId)
                        .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                        .and(OrderTempObjectBoxStruct_.isOrder.equals(isOrder)),
                  )
                  .build()
                  .find()
            : global.objectBoxStore
                  .box<OrderTempObjectBoxStruct>()
                  .query(
                    OrderTempObjectBoxStruct_.orderIdMain
                        .equals(orderMainId)
                        .and(OrderTempObjectBoxStruct_.machineId.equals(machineId))
                        .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                        .and(OrderTempObjectBoxStruct_.isOrder.equals(isOrder)),
                  )
                  .build()
                  .find();
        double orderQty = 0;
        for (var item in result) {
          orderQty += (item.orderQty - item.cancelQty);
        }
        OrderTempStruct orderTemp = OrderTempStruct(orderQty: orderQty, orderTemp: result);
        response.write(jsonEncode(orderTemp.toJson()));
        break;
      case "staff.order_temp_get_data_from_order_guid":
        String orderGuid = httpGetData.json;
        final result = global.objectBoxStore.box<OrderTempObjectBoxStruct>().query(OrderTempObjectBoxStruct_.orderGuid.equals(orderGuid)).build().findFirst();
        if (result != null) {
          response.write(jsonEncode(result.toJson()));
        } else {
          response.write(jsonEncode({}));
        }
        break;
      case "staff.get_all_delivery_ticket":
        var jsonData = await jsonDecode(httpGetData.json);
        bool sendSuccess = jsonData["sendSuccess"];
        AppLogger.debug("sendSuccess : $sendSuccess");
        List<TableProcessObjectBoxStruct> boxData = global.objectBoxStore
            .box<TableProcessObjectBoxStruct>()
            .query(TableProcessObjectBoxStruct_.is_delivery.equals(true).and(TableProcessObjectBoxStruct_.delivery_send_success.equals(sendSuccess)))
            .order(TableProcessObjectBoxStruct_.table_open_datetime, flags: Order.descending)
            .build()
            .find();
        response.write(jsonEncode(boxData.map((e) => e.toJson()).toList()));
        break;
      case "get_all_buffet_mode":
        List<BuffetModeObjectBoxStruct> boxData = global.objectBoxStore.box<BuffetModeObjectBoxStruct>().getAll();
        response.write(jsonEncode(boxData.map((e) => e.toJson()).toList()));
        break;
      case "get_table":
        var jsonData = await jsonDecode(httpGetData.json);
        String mainNumber = jsonData["mainNumber"];
        String tableNumber = jsonData["number"];
        TableProcessObjectBoxStruct? tableData = global.objectBoxStore
            .box<TableProcessObjectBoxStruct>()
            .query(TableProcessObjectBoxStruct_.number.equals(tableNumber).and(TableProcessObjectBoxStruct_.is_delivery.equals(false)))
            .build()
            .findFirst();
        if (tableData == null) {
          // เพิ่มโต๊ะ
          final findSourceTableResult = global.objectBoxStore.box<TableProcessObjectBoxStruct>().query(TableProcessObjectBoxStruct_.number.equals(mainNumber)).build().findFirst();
          final newTable = TableProcessObjectBoxStruct(
            number: tableNumber,
            guidfixed: const Uuid().v4(),
            number_main: findSourceTableResult!.number,
            names: findSourceTableResult.names,
            zone: findSourceTableResult.zone,
            table_child_count: 0,
            table_al_la_crate_mode: findSourceTableResult.table_al_la_crate_mode,
            table_open_datetime: findSourceTableResult.table_open_datetime,
            table_status: findSourceTableResult.table_status,
            delivery_ticket_number: findSourceTableResult.delivery_ticket_number,
            remark: findSourceTableResult.remark,
            order_count: findSourceTableResult.order_count,
            order_cancel_count: findSourceTableResult.order_cancel_count,
            order_served_count: findSourceTableResult.order_served_count,
            amount: findSourceTableResult.amount,
            order_success: findSourceTableResult.order_success,
            qr_code: const Uuid().v4().replaceAll("-", ""),
            man_count: findSourceTableResult.man_count,
            woman_count: findSourceTableResult.woman_count,
            child_count: findSourceTableResult.child_count,
            buffet_code: findSourceTableResult.buffet_code,
            customer_address: findSourceTableResult.customer_address,
            customer_code_or_telephone: findSourceTableResult.customer_code_or_telephone,
            customer_name: findSourceTableResult.customer_name,
            delivery_cook_success: findSourceTableResult.delivery_cook_success,
            delivery_cook_success_datetime: findSourceTableResult.delivery_cook_success_datetime,
            delivery_code: findSourceTableResult.delivery_code,
            delivery_number: findSourceTableResult.delivery_number,
            delivery_status: findSourceTableResult.delivery_status,
            delivery_send_success: findSourceTableResult.delivery_send_success,
            delivery_send_success_datetime: findSourceTableResult.delivery_send_success_datetime,
            is_delivery: findSourceTableResult.is_delivery,
            open_by_staff_code: findSourceTableResult.open_by_staff_code,
            make_food_immediately: findSourceTableResult.make_food_immediately,
            detail_discount_formula: findSourceTableResult.detail_discount_formula,
            customer_nationality_code: findSourceTableResult.customer_nationality_code,
          );
          global.objectBoxStore.box<TableProcessObjectBoxStruct>().put(newTable, mode: PutMode.insert);
          // print("เพิ่มโต๊ะลูก: ${newTable.toJson()}");
          response.write(jsonEncode(newTable.toJson()));
        } else {
          // print("โต๊ะลูกมีอยู่แล้ว: ${tableData.toJson()}");
          response.write(jsonEncode(tableData.toJson()));
        }
        break;
      case "get_all_table":
        List<TableProcessObjectBoxStruct> tableData = global.objectBoxStore
            .box<TableProcessObjectBoxStruct>()
            .query(TableProcessObjectBoxStruct_.is_delivery.equals(false))
            .build()
            .find();
        // หาโต๊ะลูก
        for (var table in tableData) {
          table.table_child_count = 0;
          var data = global.objectBoxStore.box<TableProcessObjectBoxStruct>().query(TableProcessObjectBoxStruct_.number_main.equals(table.number)).build().find();
          for (var item in data) {
            if (item.number.contains("#")) {
              table.table_child_count++;
            }
          }
        }
        // print("โต๊ะทั้งหมด: ${tableData.length} โต๊ะ");
        response.write(jsonEncode(tableData.map((e) => e.toJson()).toList()));
        break;
      case "get_all_category":
        List<ProductCategoryObjectBoxStruct> boxData = global.objectBoxStore.box<ProductCategoryObjectBoxStruct>().getAll();
        response.write(jsonEncode(boxData.map((e) => e.toJson()).toList()));
        break;
      case "get_all_kitchen":
        List<KitchenObjectBoxStruct> boxData = global.objectBoxStore.box<KitchenObjectBoxStruct>().getAll();
        response.write(jsonEncode(boxData.map((e) => e.toJson()).toList()));
        break;
      case "get_all_barcode":
        List<ProductBarcodeObjectBoxStruct> boxData = global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().getAll();
        response.write(jsonEncode(boxData.map((e) => e.toJson()).toList()));
        break;
      case "PosLogHelper.selectByGuidFixed":
        final box = global.objectBoxStore.box<PosLogObjectBoxStruct>();
        HttpParameterModel jsonCategory = HttpParameterModel.fromJson(await jsonDecode(httpGetData.json));
        List<PosLogObjectBoxStruct> boxData = (box.query(
          PosLogObjectBoxStruct_.guid_auto_fixed.equals(jsonCategory.guid),
        )..order(PosLogObjectBoxStruct_.log_date_time)).build().find();
        response.write(jsonEncode(boxData.map((e) => e.toJson()).toList()));
        break;
      case "get_process":
        var json = await jsonDecode(httpGetData.json);
        String holdCode = json["holdCode"];
        int docMode = json["docMode"];
        String discountFormula = json["discountFormula"] ?? "";
        String detailDiscountFormula = json["detailDiscountFormula"] ?? "";
        bool cashRoundAmount = json["cashRoundAmount"] ?? false;
        bool discountFoodOnly = json["discountFoodOnly"] ?? false;
        PosProcessModel posProcess = await PosProcess().process(
          holdCode: holdCode,
          docMode: docMode,
          detailDiscountFormula: detailDiscountFormula,
          discountFormula: discountFormula,
          cashRoundAmount: cashRoundAmount,
          discountFoodOnly: discountFoodOnly,
        );
        response.write(jsonEncode(posProcess.toJson()));
        break;
      case "PosLogHelper.holdCount":
        HttpParameterModel jsonCategory = HttpParameterModel.fromJson(await jsonDecode(httpGetData.json));
        int result = await PosLogHelper().holdCount(jsonCategory.holdCode);
        response.write(result.toString());
        break;
      case "selectByBarcodeFirst":
        HttpParameterModel jsonCategory = HttpParameterModel.fromJson(await jsonDecode(httpGetData.json));
        ProductBarcodeObjectBoxStruct? result = await ProductBarcodeHelper().selectByBarcodeFirst(jsonCategory.barcode);
        response.write(jsonEncode(result?.toJson()));
        break;
      case "selectByBarcodeList":
        HttpParameterModel jsonCategory = HttpParameterModel.fromJson(await jsonDecode(httpGetData.json));
        List<String> barcodeList = jsonCategory.barcode.split(",");
        List<ProductBarcodeObjectBoxStruct> result = await ProductBarcodeHelper().selectByBarcodeList(barcodeList);
        response.write(jsonEncode(result.map((e) => e.toJson()).toList()));
        break;
      case "selectByCategoryParentGuid":
        HttpParameterModel jsonCategory = HttpParameterModel.fromJson(await jsonDecode(httpGetData.json));
        String parentGuid = jsonCategory.parentGuid;
        final box = global.objectBoxStore.box<ProductCategoryObjectBoxStruct>();
        final result = box.query(ProductCategoryObjectBoxStruct_.parent_guid_fixed.equals(parentGuid)).order(ProductCategoryObjectBoxStruct_.xorder).build().find();
        response.write(jsonEncode(result.map((e) => e.toJson()).toList()));
        break;
      case "selectByParentCategoryGuidOrderByXorder":
        HttpParameterModel jsonCategory = HttpParameterModel.fromJson(await jsonDecode(httpGetData.json));
        String parentGuid = jsonCategory.parentGuid;
        final box = global.objectBoxStore.box<ProductCategoryObjectBoxStruct>();
        final result = (box.query(ProductCategoryObjectBoxStruct_.parent_guid_fixed.equals(parentGuid))..order(ProductCategoryObjectBoxStruct_.xorder)).build().find();
        response.write(jsonEncode(result.map((e) => e.toJson()).toList()));
        break;
      case "selectByCategoryGuidFindFirst":
        HttpParameterModel jsonCategory = HttpParameterModel.fromJson(await jsonDecode(httpGetData.json));
        String guid = jsonCategory.guid;
        final box = global.objectBoxStore.box<ProductCategoryObjectBoxStruct>();
        ProductCategoryObjectBoxStruct? result = box.query(ProductCategoryObjectBoxStruct_.guid_fixed.equals(guid)).build().findFirst();
        response.write(jsonEncode(result?.toJson()));
        break;
      case "get_sml_qr_list":
        List<ProfileQrPaymentModel> providerList = [];
        global.posConfig.qrcodes!.forEach((element) {
          providerList.add(element);
        });
        response.write(jsonEncode(providerList.map((e) => e.toJson()).toList()));
        break;
      case "checkqrpay":
        var jsondata = await jsonDecode(httpGetData.json);
        AppLogger.debug(jsondata);
        SMLKBankConnector smlKApiConnector = SMLKBankConnector(apiKey: jsondata['apikey'], uatMode: false);

        var res = await smlKApiConnector.CheckPayment(jsondata['transactionId']);

        if (res.txnStatus == "PAID") {
          var result = {"transactionId": res.txnUid, "status": 'success'};
          response.write(jsonEncode(result));
        } else {
          var result = {"transactionId": res.txnUid, "status": 'wait'};
          response.write(jsonEncode(result));
        }
        break;
      case "smlqrpay":
        var jsondata = await jsonDecode(httpGetData.json);
        AppLogger.debug(jsondata);
        await qrSMLPromptPay(jsondata['apikey'], jsondata['amount']).then((qrPayment) async {
          if (qrPayment.statusCode == "00") {
            if (qrPayment.qrCode.isNotEmpty) {
              var result = {"transactionId": qrPayment.txnUid, "qrCodePayDataString": qrPayment.qrCode};
              response.write(jsonEncode(result));
            }
          }
        });
        break;
    }
  } catch (e, stackTrace) {
    response.write("error");
    global.sendErrorToDevTeam("serverGet:${httpGetData.code}", "$e\n$stackTrace");
  }
}

Future<QRGenerateResponse> qrSMLPromptPay(String apikey, String amount) async {
  SMLKBankConnector smlKApiConnector = SMLKBankConnector(apiKey: apikey, uatMode: false);

  String key = global.generateRandomString(5);
  String refCode = smlKApiConnector.genRefUnixTimeNow(key);
  String refCode2 = smlKApiConnector.genRefUnixTimeNow(key);
  String refCode3 = smlKApiConnector.genRefUnixTimeNow(key);
  String refCode4 = smlKApiConnector.genRefUnixTimeNow(key);

  QRGenerateResponse qrGenerateResponse = await smlKApiConnector.CreateQRPromptPayTransaction(Decimal.parse(amount.toString()), refCode, refCode2, refCode3, refCode4);

  return qrGenerateResponse;
}
