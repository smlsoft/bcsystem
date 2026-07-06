/// ⚠️ DEPRECATED: HTTP Server POST Handler
///
/// ❌ This file is DEPRECATED and will be removed in next version.
/// ✅ Use WebSocket Server instead: lib/api/network/websocket_server.dart
///
/// Migration guide:
/// - Replace HTTP POST with WebSocket send()
/// - Implement handlers in websocket_server.dart
/// - Use message handlers in websocket_bootstrap.dart
/// - See websocket_example.dart for usage examples

@Deprecated('Use WebSocket Server instead. See lib/api/network/websocket_server.dart')
library;

import 'package:dedecashier/api/clickhouse/clickhouse_api.dart';
import 'package:dedecashier/api/sync/model/sync_model.dart';
import 'package:dedecashier/core/core.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/db/pos_log_helper.dart';
import 'package:dedecashier/db/product_barcode_helper.dart';
import 'package:dedecashier/db/product_barcode_status_helper.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_print.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_util.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/order_temp_struct.dart';
import 'package:dedecashier/model/objectbox/pos_log_struct.dart';
import 'package:dedecashier/model/objectbox/product_barcode_status_struct.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:dedecashier/model/objectbox/staff_client_struct.dart';
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:dedecashier/model/system/pos_pay_model.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_process.dart';
import 'package:dedecashier/util/pos_compile_process.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/util/print_kitchen.dart';
import 'package:dedecashier/util/print_order_summery.dart';
import 'package:dedecashier/util/printer.dart' as printer;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

Future<double> orderCalcSumAmount(OrderTempObjectBoxStruct order) async {
  double orderQty = order.orderQty - order.cancelQty;
  double amount = orderQty * order.price;
  if (order.optionSelected.isNotEmpty) {
    List<OrderProductOptionModel> options = await jsonDecode(order.optionSelected).map<OrderProductOptionModel>((e) => OrderProductOptionModel.fromJson(e)).toList();
    for (OrderProductOptionModel option in options) {
      for (OrderProductOptionChoiceModel choice in option.choices) {
        if (choice.selected) {
          amount += (orderQty * choice.priceValue);
        }
      }
    }
  }
  return amount;
}

Future<void> rebuildOrderToHoldBill(String holdCode, String tableNumber) async {
  // ✅ สร้าง/อัพเดท posHoldProcessResult entry ก่อน
  await global.orderSumAndUpdateTable(tableNumber);

  List<PosLogObjectBoxStruct> posLogData = global.objectBoxStore.box<PosLogObjectBoxStruct>().query(PosLogObjectBoxStruct_.hold_code.equals("T-$holdCode")).build().find();
  if (posLogData.isNotEmpty) {
    for (PosLogObjectBoxStruct posLog in posLogData) {
      global.objectBoxStore.box<PosLogObjectBoxStruct>().remove(posLog.id);
    }
  }

  // ดึงรายการที่สั่งไปแล้ว มาสร้างรายการ Hold Bill
  var dataTemp = global.objectBoxStore
      .box<OrderTempObjectBoxStruct>()
      .query(OrderTempObjectBoxStruct_.orderId.equals(tableNumber).and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false)))
      .build()
      .find();
  if (dataTemp.isNotEmpty) {
    await saveOrderToHoldBill([holdCode]);
  }
}

Future<void> saveOrderToHoldBill(List<String> holdCodeList) async {
  if (holdCodeList.isEmpty) {
    return;
  }
  // delete รายการเก่า
  for (var holdCode in holdCodeList) {
    global.objectBoxStore.box<PosLogObjectBoxStruct>().removeMany(
      global.objectBoxStore.box<PosLogObjectBoxStruct>().query(PosLogObjectBoxStruct_.hold_code.equals("T-$holdCode")).build().find().map((e) => e.id).toList(),
    );

    List<OrderTempObjectBoxStruct> orders = global.objectBoxStore
        .box<OrderTempObjectBoxStruct>()
        .query(OrderTempObjectBoxStruct_.orderId.equals(holdCode).and(OrderTempObjectBoxStruct_.isOrder.equals(false)).and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false)))
        .build()
        .find();

    // สร้างรายการใหม่
    for (var order in orders) {
      ProductBarcodeObjectBoxStruct? productSelect = await ProductBarcodeHelper().selectByBarcodeFirst(order.barcode);
      if (productSelect != null) {
        String holdCode = "T-${order.orderId}";
        double price = global.getProductPrice(productSelect.prices, 1);
        PosLogObjectBoxStruct data = PosLogObjectBoxStruct(
          log_date_time: DateTime.now(),
          doc_mode: global.posScreenToInt(global.PosScreenModeEnum.posSale),
          hold_code: holdCode,
          command_code: 1,
          barcode: order.barcode,
          name: productSelect.names,
          unit_code: productSelect.unit_code,
          unit_name: productSelect.unit_names,
          remark: order.remark,
          qty: (order.orderQty - order.cancelQty),
          price: price,
        );
        String insertGuid = data.guid_auto_fixed;
        await PosLogHelper().insert(data);
        // เพิ่มส่วนขยาย (option)
        if (order.optionSelected.isNotEmpty) {
          List<OrderProductOptionModel> options = await jsonDecode(order.optionSelected).map<OrderProductOptionModel>((e) => OrderProductOptionModel.fromJson(e)).toList();
          for (var option in options) {
            for (var choice in option.choices) {
              if (choice.selected) {
                List<PosLogObjectBoxStruct> posLogSelect = await PosLogHelper().selectByGuidFixed(insertGuid);
                if (posLogSelect.isNotEmpty) {
                  await PosLogHelper().insert(
                    PosLogObjectBoxStruct(
                      guid_code_ref: "",
                      doc_mode: global.posScreenToInt(global.PosScreenModeEnum.posSale),
                      guid_ref: insertGuid,
                      log_date_time: DateTime.now(),
                      hold_code: holdCode,
                      command_code: 101,
                      extra_code: "",
                      code: choice.guid,
                      price: choice.priceValue,
                      name: jsonEncode(choice.names),
                      qty_fixed: choice.qty,
                      qty: choice.qty,
                      selected: true,
                    ),
                  );
                }
              }
            }
          }
        }
      }
    }
  }
}

Future<void> serverPost(HttpPost httpPost, HttpResponse response) async {
  try {
    switch (httpPost.command) {
      case "register_staff_device":
        // ลงทะเบียนเครื่องลูก
        String result = "";
        SyncStaffDeviceModel device = SyncStaffDeviceModel.fromJson(await jsonDecode(httpPost.data));
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
          // ถ้าไม่พบ ให้ตรวจ รหัส
          if (device.securityCode == global.connectSecureCode) {
            // ถ้ารหัสตรง ให้เพิ่มเครื่องลูก
            global.staffClientList.add(StaffClientObjectBoxStruct(client_guid: device.clientGuid, client_name: device.clientName, client_ip: device.clientIp));
            result = global.getNameFromLanguage(global.profileSetting.company.names, global.userScreenLanguage);
          }
        }
        response.write(result);
        break;
      case "staff.print_order_summery":
        // พิมพ์สรุปรายการที่สั่ง
        var jsonObject = await jsonDecode(httpPost.data);
        String orderId = jsonObject["orderid"];
        final result = global.objectBoxStore
            .box<OrderTempObjectBoxStruct>()
            .query(OrderTempObjectBoxStruct_.orderId.equals(orderId).and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false)))
            .build()
            .find();
        if (result.isNotEmpty) {
          List<OrderTempDataModel> orderSummeryTemp = [];
          for (var data in result) {
            var xdata = OrderTempDataModel(
              orderGuid: data.orderGuid,
              barcode: data.barcode,
              qty: (data.orderQty - data.cancelQty),
              qtyLastCancel: data.qtyLastCancel,
              optionSelected: data.optionSelected,
              remark: data.remark,
              remarkForCancel: data.remarkForCancel,
              orderId: data.orderId,
              orderDateTime: data.orderDateTime,
              price: data.price,
              amount: data.amount,
              orderType: data.orderType,
              orderEmployeeCode: data.orderEmployeeCode,
              orderEmployeeDetail: data.orderEmployeeDetail,
              isTakeAway: (data.takeAway) ? 1 : 0,
            );
            orderSummeryTemp.add(xdata);
          }
          await printOrderSummery(orderId: orderId, orderList: orderSummeryTemp, bottomWord: "หน้าร้าน", printerIndex: -1);
        }
        break;
      case "staff.print_table_and_qrcode":
        var jsonObject = await jsonDecode(httpPost.data);
        String tableNumber = jsonObject["number"];
        final result = global.objectBoxStore.box<TableProcessObjectBoxStruct>().query(TableProcessObjectBoxStruct_.number.equals(tableNumber)).build().findFirst();
        if (result != null) {
          printer.printTableInformationAndQrCode(
            fullDetail: false,
            tableManagerMode: global.TableManagerEnum.openTable,
            table: result,
            qrCode: global.qrCodeOrderOnline(result.qr_code),
          );
        }
        break;
      case "staff.set_kds_start_cooking":
        // เริ่มทำอาหารได้
        var jsonData = await jsonDecode(httpPost.data);
        String orderNumber = jsonData["orderNumber"];

        // update Ticket ให้เป็น ทำอาหารทันที
        var dataTicket = global.objectBoxStore.box<TableProcessObjectBoxStruct>().query(TableProcessObjectBoxStruct_.delivery_number.equals(orderNumber)).build().findFirst();
        if (dataTicket != null) {
          dataTicket.make_food_immediately = true;
          global.objectBoxStore.box<TableProcessObjectBoxStruct>().put(dataTicket, mode: PutMode.update);
          // update สถานะ รายการย่อย ให้พร้อมส่งเข้าครัว
          var dataTicketDetail = global.objectBoxStore
              .box<OrderTempObjectBoxStruct>()
              .query(
                OrderTempObjectBoxStruct_.orderId
                    .equals(dataTicket.number)
                    .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                    .and(OrderTempObjectBoxStruct_.isOrderReadySendKds.equals(false)),
              )
              .build()
              .find();
          for (var i = 0; i < dataTicketDetail.length; i++) {
            dataTicketDetail[i].isOrderReadySendKds = true;
          }
          global.objectBoxStore.box<OrderTempObjectBoxStruct>().putMany(dataTicketDetail, mode: PutMode.update);
        }
        response.write(true);
        break;
      case "staff.insert_delivery_ticket":
        late int runningNo;
        String runningStart = DateFormat("yyMMdd").format(DateTime.now());
        var dataRunning = global.objectBoxStore
            .box<TableProcessObjectBoxStruct>()
            .query(TableProcessObjectBoxStruct_.delivery_number.notEquals("").and(TableProcessObjectBoxStruct_.delivery_number.lessThan("$runningStart-9999")))
            .order(TableProcessObjectBoxStruct_.delivery_number, flags: Order.descending)
            .build()
            .findFirst();
        if (dataRunning != null) {
          runningNo = int.parse(dataRunning.delivery_number.substring(runningStart.length + 1)) + 1;
        } else {
          runningNo = 1;
        }
        String runningNumber = "$runningStart-${runningNo.toString().padLeft(4, "0")}";
        // สร้าง Ticket Delivery ใหม่
        var data = TableProcessObjectBoxStruct.fromJson(await jsonDecode(httpPost.data));
        data.delivery_number = runningNumber;
        global.objectBoxStore.box<TableProcessObjectBoxStruct>().put(data, mode: PutMode.insert);
        response.write(runningNumber);
        break;
      case "staff.update_product_barcode_status_qty":
        var jsonData = await jsonDecode(httpPost.data);
        String barcode = jsonData["barcode"];
        double qty = jsonData["qty"];
        var productStatus = global.objectBoxStore
            .box<ProductBarcodeStatusObjectBoxStruct>()
            .query(ProductBarcodeStatusObjectBoxStruct_.barcode.equals(barcode))
            .build()
            .findFirst();
        if (productStatus != null) {
          productStatus.qtyBalance += qty;
          global.objectBoxStore.box<ProductBarcodeStatusObjectBoxStruct>().put(productStatus, mode: PutMode.update);
        }
        break;
      case "kds.order_temp_update_kds_success_status":
        var jsonData = await jsonDecode(httpPost.data);
        String guid = jsonData["guid"];
        var order = global.objectBoxStore.box<OrderTempObjectBoxStruct>().query(OrderTempObjectBoxStruct_.orderGuid.equals(guid)).build().findFirst();
        if (order != null) {
          order.kdsSuccess = !order.kdsSuccess;
          order.kdsSuccessTime = DateTime.now();
          global.objectBoxStore.box<OrderTempObjectBoxStruct>().put(order, mode: PutMode.update);
        }
        break;
      case "staff.product_barcode_status_update":
        var data = ProductBarcodeStatusObjectBoxStruct.fromJson(await jsonDecode(httpPost.data));
        var productBarcode = global.objectBoxStore
            .box<ProductBarcodeStatusObjectBoxStruct>()
            .query(ProductBarcodeStatusObjectBoxStruct_.barcode.equals(data.barcode))
            .build()
            .findFirst();
        if (productBarcode != null) {
          global.objectBoxStore.box<ProductBarcodeStatusObjectBoxStruct>().put(data, mode: PutMode.update);
        }
        break;
      case "staff.order_temp_cancel_by_guid":
        // ยกเลิก Order
        var jsonData = await jsonDecode(httpPost.data);
        String guid = jsonData["guid"];
        double qty = jsonData["qty"];
        String remark = jsonData["remark"];
        var oldOrder = global.objectBoxStore.box<OrderTempObjectBoxStruct>().query(OrderTempObjectBoxStruct_.orderGuid.equals(guid)).build().findFirst();
        if (oldOrder != null) {
          List<OrderTempDataModel> printOrderList = [];
          printOrderList.add(
            OrderTempDataModel(
              orderGuid: oldOrder.orderGuid,
              barcode: oldOrder.barcode,
              qty: (oldOrder.orderQty - oldOrder.cancelQty),
              optionSelected: oldOrder.optionSelected,
              remark: oldOrder.remark,
              remarkForCancel: remark,
              orderId: oldOrder.orderId,
              orderDateTime: oldOrder.orderDateTime,
              price: oldOrder.price,
              amount: oldOrder.amount,
              orderType: oldOrder.orderType,
              orderEmployeeCode: oldOrder.orderEmployeeCode,
              orderEmployeeDetail: oldOrder.orderEmployeeDetail,
              isTakeAway: (oldOrder.takeAway) ? 1 : 0,
              qtyLastCancel: qty,
            ),
          );
          if ((oldOrder.orderQty - oldOrder.cancelQty) - qty >= 0) {
            oldOrder.cancelQty = oldOrder.cancelQty + qty;
            oldOrder.lastUpdateDateTime = DateTime.now();
            oldOrder.qtyLastCancel = qty;
            if ((oldOrder.orderQty - oldOrder.cancelQty) == 0) {
              oldOrder.kdsSuccess = true;
              oldOrder.kdsSuccessTime = DateTime.now(); // ✅ ตั้งเวลายกเลิก เพื่อให้ KDS แสดงรายการอีก 5 นาที
            }
            // บันทึกประวัติยกเลิก
            var cancelHistory = OrderCancelHistoryModel(cancelDateTime: DateTime.now(), cancelQty: qty);
            if (oldOrder.cancelHistory.isEmpty) {
              oldOrder.cancelHistory = jsonEncode([cancelHistory]);
            } else {
              // เพิ่มประวัติยกเลิก
              List<OrderCancelHistoryModel> cancelHistoryList = (await jsonDecode(oldOrder.cancelHistory) as List).map((e) => OrderCancelHistoryModel.fromJson(e)).toList();
              cancelHistoryList.add(cancelHistory);
              oldOrder.cancelHistory = jsonEncode(cancelHistoryList);
            }
            // update
            global.objectBoxStore.box<OrderTempObjectBoxStruct>().put(oldOrder, mode: PutMode.update);
            // ลบ Hold แล้วสร้างใหม่
            /*String holdId = "T-${oldOrder.orderId}";
          global.objectBoxStore
              .box<PosLogObjectBoxStruct>()
              .query(PosLogObjectBoxStruct_.hold_code.equals(holdId))
              .build()
              .remove();
          var orderList = global.objectBoxStore
              .box<OrderTempObjectBoxStruct>()
              .query(OrderTempObjectBoxStruct_.orderId
                  .equals(oldOrder.orderId)
                  .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false)))
              .build()
              .find();
          if (orderList.isNotEmpty) {
            for (var order in orderList) {
              // เพิ่มรายการ
              PosLogObjectBoxStruct dataPosLog = PosLogObjectBoxStruct(
                  log_date_time: DateTime.now(),
                  doc_mode: 1,
                  hold_code: holdId,
                  command_code: 1,
                  barcode: order.barcode,
                  name: order.names,
                  unit_code: order.unitCode,
                  unit_name: order.unitName,
                  qty: order.qty,
                  price: order.price);
              await PosLogHelper().insert(dataPosLog);
              if (order.optionSelected.isNotEmpty) {
                var optionJson =await jsonDecode(order.optionSelected);
                List<ProductOptionModel> optionList = (optionJson as List)
                    .map((e) => ProductOptionModel.fromJson(e))
                    .toList();
                for (var option in optionList) {
                  for (var choice in option.choices) {
                    if (choice.selected == true) {
                      // เพิ่มรายการ
                      PosLogObjectBoxStruct data = PosLogObjectBoxStruct(
                          log_date_time: DateTime.now(),
                          guid_ref: dataPosLog.guid_auto_fixed,
                          doc_mode: 1,
                          hold_code: holdId,
                          command_code: 101,
                          barcode: choice.refbarcode ?? "",
                          name: jsonEncode(choice.names),
                          unit_code: choice.refunitcode ?? "",
                          unit_name: "",
                          qty: choice.qty,
                          price: double.tryParse(choice.price) ?? 0);
                      await PosLogHelper().insert(data);
                    }
                  }
                }
              }
            }
          }*/
            await global.orderSumAndUpdateTable(oldOrder.orderId);
            // Build
            await rebuildOrderToHoldBill(oldOrder.orderId, oldOrder.orderId);
            // ส่งขึ้น server
            await global.sendProcessToServer(oldOrder.orderId);
            // ส่งไปที่ครัว
            try {
              sendOrderCancelToKitchen(orderId: oldOrder.orderId, orderList: printOrderList);
            } catch (e, stackTrace) {
              global.sendErrorToDevTeam("server_post.dart->staff.order_temp_cancel_by_guid", "Server POST ${httpPost.command} : $e ${stackTrace.toString()}");
            }
          }
        }
        break;
      case "staff.order_temp_delete_by_barcode":
        var jsonData = await jsonDecode(httpPost.data);
        String orderId = jsonData["orderId"];
        String barcode = jsonData["barcode"];
        //String orderGuid = jsonData["orderguid"];
        // กรณีมีการคุมสต๊อก คืนค่าสต๊อก
        var productBarcodeStatus = await ProductBarcodeStatusHelper().selectByBarcodeFirst(barcode);
        if (productBarcodeStatus != null && productBarcodeStatus.orderAutoStock) {
          var orderTemp = global.objectBoxStore
              .box<OrderTempObjectBoxStruct>()
              .query(OrderTempObjectBoxStruct_.orderId.equals(orderId).and(OrderTempObjectBoxStruct_.isOrder.equals(true)).and(OrderTempObjectBoxStruct_.barcode.equals(barcode)))
              .build()
              .find();
          if (orderTemp.isNotEmpty) {
            for (var order in orderTemp) {
              productBarcodeStatus.qtyBalance += (order.orderQty - order.cancelQty);
            }
            global.objectBoxStore.box<ProductBarcodeStatusObjectBoxStruct>().put(productBarcodeStatus, mode: PutMode.update);
          }
        }
        // ลบรายการ
        global.objectBoxStore
            .box<OrderTempObjectBoxStruct>()
            .query(
              OrderTempObjectBoxStruct_.orderId
                  .equals(orderId)
                  .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                  .and(OrderTempObjectBoxStruct_.isOrder.equals(true))
                  .and(OrderTempObjectBoxStruct_.barcode.equals(barcode)),
            )
            .build()
            .remove();
        // ลบยอดคงเหลือ
        await global.orderSumAndUpdateTable(orderId);
        break;
      case "staff.order_temp_send_order_by_orderid":
        // ส่ง Order ไปที่ครัว และ Cashier
        String jsonParameter = httpPost.data;
        var jsonData = await jsonDecode(jsonParameter);
        String orderId = jsonData["orderId"];
        String machineId = jsonData["machineId"];
        final box = global.objectBoxStore.box<OrderTempObjectBoxStruct>();
        final result = box
            .query(
              OrderTempObjectBoxStruct_.orderId
                  .equals(orderId)
                  .and(OrderTempObjectBoxStruct_.machineId.equals(machineId))
                  .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                  .and(OrderTempObjectBoxStruct_.isOrder.equals(true)),
            )
            .build()
            .find();
        for (int i = 0; i < result.length; i++) {
          // ปรับปรุงว่าส่ง Order ได้
          result[i].isOrder = false;
          // ✅ ตั้งค่าให้พร้อมส่งครัวทันที (เมื่อกดส่งรายการ)
          result[i].isOrderReadySendKds = true;
          // history order
          List<OrderHistoryModel> orderHistoryList = [];
          if (result[i].orderHistory.isNotEmpty) {
            orderHistoryList = (await jsonDecode(result[i].orderHistory) as List).map((e) => OrderHistoryModel.fromJson(e)).toList();
          }
          orderHistoryList.add(OrderHistoryModel(orderDateTime: result[i].orderDateTime, orderQty: result[i].orderQty));
          result[i].orderHistory = jsonEncode(orderHistoryList);
        }
        box.putMany(result, mode: PutMode.update);
        // ส่งรายการ
        await global.checkOrderFromStaff();
        // ✅ พิมพ์ครัวทันที
        await global.checkKitchenOrder();
        // ส่งไปที่ server
        await global.sendProcessToServer(orderId);
        break;
      case "staff.order_temp_delete_by_guid":
        // ลบเฉพาะกรณียังไม่ส่ง Order
        var jsonData = await jsonDecode(httpPost.data);
        String orderId = jsonData["orderId"];
        String orderGuid = jsonData["guid"];
        // กรณีมีการคุมสต๊อก คืนค่าสต๊อก
        var orderTempOld = global.objectBoxStore
            .box<OrderTempObjectBoxStruct>()
            .query(
              OrderTempObjectBoxStruct_.orderId
                  .equals(orderId)
                  .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                  .and(OrderTempObjectBoxStruct_.isOrder.equals(true))
                  .and(OrderTempObjectBoxStruct_.orderGuid.equals(orderGuid)),
            )
            .build()
            .findFirst();
        if (orderTempOld != null) {
          var productBarcodeStatus = await ProductBarcodeStatusHelper().selectByBarcodeFirst(orderTempOld.barcode);
          if (productBarcodeStatus != null && productBarcodeStatus.orderAutoStock) {
            productBarcodeStatus.qtyBalance += (orderTempOld.orderQty - orderTempOld.cancelQty);
            global.objectBoxStore.box<ProductBarcodeStatusObjectBoxStruct>().put(productBarcodeStatus, mode: PutMode.update);
          }
        }
        global.objectBoxStore
            .box<OrderTempObjectBoxStruct>()
            .query(
              OrderTempObjectBoxStruct_.orderId
                  .equals(orderId)
                  .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                  .and(OrderTempObjectBoxStruct_.isOrder.equals(true))
                  .and(OrderTempObjectBoxStruct_.orderGuid.equals(orderGuid)),
            )
            .build()
            .remove();
        await global.orderSumAndUpdateTable(orderId);
        break;
      case "staff.order_temp_insert":
        // เพิ่มรายการ (orderTemp) ยังไม่ส่ง Order
        int result = 0;
        try {
          bool isInsertOrUpdate = false;
          OrderTempObjectBoxStruct orderTempObjectBoxFromJsonData = OrderTempObjectBoxStruct.fromJson(await jsonDecode(httpPost.data));
          // ตรวจสอบยอดคงเหลือ (กรณีสินค้าคุมยอดคงเหลือ)
          var productBarcodeStatus = await ProductBarcodeStatusHelper().selectByBarcodeFirst(orderTempObjectBoxFromJsonData.barcode);
          if (productBarcodeStatus != null && productBarcodeStatus.orderAutoStock) {
            if (productBarcodeStatus.qtyBalance - (orderTempObjectBoxFromJsonData.orderQty - orderTempObjectBoxFromJsonData.cancelQty) < 0) {
              // สินค้าคุมยอดคงเหลือ และ ยอดคงเหลือไม่พอ
              result = 1;
              isInsertOrUpdate = false;
            } else {
              productBarcodeStatus.qtyBalance -= (orderTempObjectBoxFromJsonData.orderQty - orderTempObjectBoxFromJsonData.cancelQty);
              global.objectBoxStore.box<ProductBarcodeStatusObjectBoxStruct>().put(productBarcodeStatus, mode: PutMode.update);
              result = 0;
              isInsertOrUpdate = true;
            }
          } else {
            result = 0;
            isInsertOrUpdate = true;
          }
          if (isInsertOrUpdate) {
            final box = global.objectBoxStore.box<OrderTempObjectBoxStruct>();
            // ตรวจสอบว่าไม่มี Option และเคยสั่งไปแล้ว จะได้เพิ่ม Qty
            final findResult = box
                .query(
                  OrderTempObjectBoxStruct_.orderId
                      .equals(orderTempObjectBoxFromJsonData.orderId)
                      .and(
                        OrderTempObjectBoxStruct_.barcode
                            .equals(orderTempObjectBoxFromJsonData.barcode)
                            .and(
                              OrderTempObjectBoxStruct_.remark
                                  .equals(orderTempObjectBoxFromJsonData.remark)
                                  .and(OrderTempObjectBoxStruct_.optionSelected.equals(orderTempObjectBoxFromJsonData.optionSelected)),
                            ),
                      )
                      .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                      .and(OrderTempObjectBoxStruct_.isOrder.equals(true).and(OrderTempObjectBoxStruct_.takeAway.equals(orderTempObjectBoxFromJsonData.takeAway))),
                )
                .build()
                .findFirst();
            if (findResult != null) {
              // พบรายการเดิม ให้ update
              findResult.orderQty += orderTempObjectBoxFromJsonData.orderQty;
              findResult.amount = await orderCalcSumAmount(findResult);
              // update
              box.put(findResult, mode: PutMode.update);
            } else {
              // ไม่พบรายการเดิม ให้ insert
              orderTempObjectBoxFromJsonData.amount = await orderCalcSumAmount(orderTempObjectBoxFromJsonData);
              box.put(orderTempObjectBoxFromJsonData, mode: PutMode.insert);
            }
            await global.orderSumAndUpdateTable(orderTempObjectBoxFromJsonData.orderId);
          }
        } catch (e, stackTrace) {
          global.sendErrorToDevTeam("server_post.dart->staff.order_temp_insert", "Server POST ${httpPost.command} : $e ${stackTrace.toString()}");
          result = 999;
        }
        response.write(result);
        break;
      case "staff.order_temp_update_for_split":
        bool insertNewOrderData = true;
        // 0=ต้นทาง, 1=ปลายทางม ,2=orderGuid (ได้ครั้งละ 1 qty)
        OrderTempUpdateForSplitModel jsonData = OrderTempUpdateForSplitModel.fromJson(await jsonDecode(httpPost.data));
        // รายการเดิม ถ้ามีให้ update ถ้าไม่มีให้เพิ่ม
        AppLogger.debug("ย้ายจาก ${jsonData.sourceTable} ไป ${jsonData.targetTable}");
        final findSourceTempResult = global.objectBoxStore
            .box<OrderTempObjectBoxStruct>()
            .query(
              OrderTempObjectBoxStruct_.orderId
                  .equals(jsonData.sourceTable)
                  .and(OrderTempObjectBoxStruct_.orderGuid.equals(jsonData.sourceGuid).and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))),
            )
            .build()
            .findFirst();
        final findTargetTempResult = global.objectBoxStore
            .box<OrderTempObjectBoxStruct>()
            .query(OrderTempObjectBoxStruct_.orderId.equals(jsonData.targetTable).and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false)))
            .build()
            .find();
        if (findSourceTempResult != null && findSourceTempResult.orderQty - findSourceTempResult.cancelQty > 0) {
          for (var target in findTargetTempResult) {
            if (target.barcode == findSourceTempResult.barcode && target.remark == findSourceTempResult.remark && target.optionSelected == findSourceTempResult.optionSelected) {
              // กรณีพบข้อมูลเดิมในโต๊ะปลายทาง
              target.orderQty += 1;
              target.amount = await orderCalcSumAmount(target);
              global.objectBoxStore.box<OrderTempObjectBoxStruct>().put(target, mode: PutMode.update);
              findSourceTempResult.orderQty -= 1;
              findSourceTempResult.amount = await orderCalcSumAmount(findSourceTempResult);
              global.objectBoxStore.box<OrderTempObjectBoxStruct>().put(findSourceTempResult, mode: PutMode.update);
              insertNewOrderData = false;
              break;
            }
          }
          if (insertNewOrderData) {
            // กรณีไม่พบข้อมูลเดิมในโต๊ะปลายทาง
            // ลดจำนวนของเก่า
            findSourceTempResult.orderQty -= 1;
            findSourceTempResult.amount = await orderCalcSumAmount(findSourceTempResult);
            global.objectBoxStore.box<OrderTempObjectBoxStruct>().put(findSourceTempResult, mode: PutMode.update);
            // เพิ่มข้อมูลใหม่
            final newOrderTemp = OrderTempObjectBoxStruct(
              id: 0,
              guidPos: findSourceTempResult.guidPos,
              orderId: jsonData.targetTable,
              orderIdMain: findSourceTempResult.orderIdMain,
              orderGuid: const Uuid().v4(),
              docNo: findSourceTempResult.docNo,
              machineId: findSourceTempResult.machineId,
              orderDateTime: findSourceTempResult.orderDateTime,
              barcode: findSourceTempResult.barcode,
              price: findSourceTempResult.price,
              amount: 0,
              isOrder: findSourceTempResult.isOrder,
              isPaySuccess: findSourceTempResult.isPaySuccess,
              optionSelected: findSourceTempResult.optionSelected,
              remark: findSourceTempResult.remark,
              remarkForCancel: findSourceTempResult.remarkForCancel,
              names: findSourceTempResult.names,
              takeAway: findSourceTempResult.takeAway,
              unitCode: findSourceTempResult.unitCode,
              unitName: findSourceTempResult.unitName,
              imageUri: findSourceTempResult.imageUri,
              kdsSuccessTime: findSourceTempResult.kdsSuccessTime,
              kdsSuccess: findSourceTempResult.kdsSuccess,
              isOrderSuccess: findSourceTempResult.isOrderSuccess,
              isOrderSendKdsSuccess: findSourceTempResult.isOrderSendKdsSuccess,
              kdsId: findSourceTempResult.kdsId,
              cancelQty: findSourceTempResult.cancelQty,
              cancelHistory: findSourceTempResult.cancelHistory,
              qtyLastCancel: findSourceTempResult.qtyLastCancel,
              orderQty: 1,
              deliveryNumber: findSourceTempResult.deliveryNumber,
              deliveryCode: findSourceTempResult.deliveryCode,
              isOrderReadySendKds: findSourceTempResult.isOrderReadySendKds,
              deliveryName: findSourceTempResult.deliveryName,
              lastUpdateDateTime: findSourceTempResult.lastUpdateDateTime,
              servedSuccess: findSourceTempResult.servedSuccess,
              servedQty: findSourceTempResult.servedQty,
              servedTime: findSourceTempResult.servedTime,
              servedHistory: findSourceTempResult.servedHistory,
              orderHistory: findSourceTempResult.orderHistory,
              orderType: findSourceTempResult.orderType,
              orderEmployeeCode: findSourceTempResult.orderEmployeeCode,
              orderEmployeeDetail: findSourceTempResult.orderEmployeeDetail,
              isOrderSendDedeTempSuccess: findSourceTempResult.isOrderSendDedeTempSuccess,
            );
            // คำนวณมูลค่าใหม่
            newOrderTemp.amount = await orderCalcSumAmount(newOrderTemp);
            //
            global.objectBoxStore.box<OrderTempObjectBoxStruct>().put(newOrderTemp, mode: PutMode.insert);
          }
          {
            // เพิ่มโต๊ะปลายทาง
            final findSourceTableResult = global.objectBoxStore
                .box<TableProcessObjectBoxStruct>()
                .query(TableProcessObjectBoxStruct_.number.equals(jsonData.sourceTable))
                .build()
                .findFirst();
            final findTargetTableResult = global.objectBoxStore
                .box<TableProcessObjectBoxStruct>()
                .query(TableProcessObjectBoxStruct_.number.equals(jsonData.targetTable))
                .build()
                .findFirst();
            if (findTargetTableResult == null) {
              final newTable = TableProcessObjectBoxStruct(
                number: jsonData.targetTable,
                guidfixed: const Uuid().v4(),
                number_main: findSourceTableResult!.number_main,
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
                qr_code: findSourceTableResult.qr_code,
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
            }
          }
        }
        {
          // ลบรายการ Qty = 0 ออก
          final findSourceTempResultDelete = global.objectBoxStore
              .box<OrderTempObjectBoxStruct>()
              .query(OrderTempObjectBoxStruct_.orderId.equals(jsonData.sourceTable).or(OrderTempObjectBoxStruct_.orderId.equals(jsonData.targetTable)))
              .build()
              .find();
          for (var item in findSourceTempResultDelete) {
            if (item.orderQty == 0) {
              global.objectBoxStore.box<OrderTempObjectBoxStruct>().remove(item.id);
            }
          }
        }
        // สร้างใหม่ (Hold)
        await rebuildOrderToHoldBill(jsonData.sourceTable, jsonData.sourceTable);
        await rebuildOrderToHoldBill(jsonData.targetTable, jsonData.targetTable);
        // คำนวณใหม่
        await global.orderSumAndUpdateTable(jsonData.sourceTable);
        await global.orderSumAndUpdateTable(jsonData.targetTable);
        response.write(true);
        break;
      case "staff.order_temp_served_status_by_guid":
        // ส่งอาหารเสร็จแล้ว
        var jsonData = await jsonDecode(httpPost.data);
        String guid = jsonData["guid"];
        bool status = false;
        double servedQty = jsonData["served_qty"];
        String orderId = "";
        var order = global.objectBoxStore.box<OrderTempObjectBoxStruct>().query(OrderTempObjectBoxStruct_.orderGuid.equals(guid)).build().findFirst();
        if (order != null) {
          orderId = order.orderId;
          double qtyBalance = order.orderQty - order.cancelQty;
          if (order.servedQty + servedQty <= qtyBalance) {
            order.servedQty += servedQty;
            status = order.servedQty >= (order.orderQty - order.cancelQty);
            order.servedSuccess = status;
            order.servedTime = DateTime.now();
            // ประวัติการเสิร์ฟ (update)
            var servedHistory = OrderServedHistoryModel(servedDateTime: DateTime.now(), servedQty: servedQty);
            if (order.servedHistory.isEmpty) {
              order.servedHistory = jsonEncode([servedHistory]);
            } else {
              // เพิ่มประวัติการเสิร์ฟ
              List<OrderServedHistoryModel> servedHistoryList = (await jsonDecode(order.servedHistory) as List).map((e) => OrderServedHistoryModel.fromJson(e)).toList();
              servedHistoryList.add(servedHistory);
              order.servedHistory = jsonEncode(servedHistoryList);
            }
            // kds สำเร็จ
            order.kdsSuccess = status;
            order.kdsSuccessTime = DateTime.now();
            // update
            global.objectBoxStore.box<OrderTempObjectBoxStruct>().put(order, mode: PutMode.update);
          }
        }
        if (orderId.isNotEmpty) {
          // คำนวณใหม่
          await global.orderSumAndUpdateTable(orderId);
        }
        response.write(true);
        break;
      case "staff.order_temp_update":
        try {
          int result = 0;
          bool isUpdate = false;
          OrderTempObjectBoxStruct jsonData = OrderTempObjectBoxStruct.fromJson(await jsonDecode(httpPost.data));
          // รายการเดิม
          final findOldTempResult = global.objectBoxStore
              .box<OrderTempObjectBoxStruct>()
              .query(
                OrderTempObjectBoxStruct_.orderId
                    .equals(jsonData.orderId)
                    .and(OrderTempObjectBoxStruct_.orderGuid.equals(jsonData.orderGuid))
                    .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                    .and(OrderTempObjectBoxStruct_.isOrder.equals(true)),
              )
              .build()
              .findFirst();
          // ตรวจสอบยอดคงเหลือ (กรณีสินค้าคุมยอดคงเหลือ)
          var productBarcodeStatus = await ProductBarcodeStatusHelper().selectByBarcodeFirst(jsonData.barcode);
          if (productBarcodeStatus != null && productBarcodeStatus.orderAutoStock) {
            if (productBarcodeStatus.qtyBalance - ((jsonData.orderQty - jsonData.cancelQty) - (findOldTempResult!.orderQty - findOldTempResult.cancelQty)) < 0) {
              // สินค้าคุมยอดคงเหลือ และ ยอดคงเหลือไม่พอ
              result = 1;
            } else {
              isUpdate = true;
              productBarcodeStatus.qtyBalance -= ((jsonData.orderQty - jsonData.cancelQty) - (findOldTempResult.orderQty - findOldTempResult.cancelQty));
              global.objectBoxStore.box<ProductBarcodeStatusObjectBoxStruct>().put(productBarcodeStatus, mode: PutMode.update);
              result = 0;
            }
          } else {
            isUpdate = true;
          }
          if (isUpdate == true) {
            if (findOldTempResult != null) {
              jsonData.amount = await orderCalcSumAmount(jsonData);
              global.objectBoxStore.box<OrderTempObjectBoxStruct>().put(jsonData, mode: PutMode.update);
              result = 0;
            } else {
              result = 2;
            }
            await global.orderSumAndUpdateTable(jsonData.orderId);
          }
          response.write(result);
        } catch (e, stackTrace) {
          global.sendErrorToDevTeam("staff.order_temp_update", "staff.order_temp_update:${e.toString()} ${stackTrace.toString()}");
        }
        break;
      case "staff.close_table":
        try {
          print('[SERVER] ========== staff.close_table START ==========');
          String docNumber = "";

          // ✅ เพิ่ม try-catch รอบ JSON parsing เพื่อ debug
          late CloseTableModel closeData;
          late String holdNumber;
          try {
            print('[SERVER] Parsing JSON data...');
            var jsonObject = await jsonDecode(httpPost.data);
            print('[SERVER] JSON decoded, creating CloseTableModel...');
            closeData = CloseTableModel.fromJson(jsonObject);
            holdNumber = "T-${closeData.table.number}";
            print('[SERVER] Table: ${closeData.table.number}, PayMode: ${closeData.payMode}');
            print('[SERVER] Details count: ${closeData.process.details.length}');
          } catch (parseError, parseStack) {
            print('[SERVER] ERROR parsing JSON: $parseError');
            print('[SERVER] Stack: $parseStack');
            response.write("");
            response.close();
            break;
          }

          // ✅ สร้าง/อัพเดท Hold Bill ก่อนประมวลผล (เพื่อให้มี posHoldProcessResult)
          await rebuildOrderToHoldBill(closeData.table.number, closeData.table.number);
          print('[SERVER] rebuildOrderToHoldBill done');

          final box = global.objectBoxStore.box<TableProcessObjectBoxStruct>();
          final result = box.query(TableProcessObjectBoxStruct_.number.equals(closeData.table.number)).build().findFirst();
          print('[SERVER] Table found in DB: ${result != null}');
          if (result != null) {
            double cashAmount = closeData.process.total_amount_pay;
            if (closeData.process.details.isEmpty) {
              // กรณีไม่มีรายการ ให้ปิดโต๊ะเลย (0=ปิดโต๊ะแล้ว)
              result.table_status = 0;
              box.put(result, mode: PutMode.update);
              // save temp log
              await global.saveOrderTempToSyncTempLog(docNumber: const Uuid().v4(), guidPos: const Uuid().v4(), orderId: closeData.table.number, orderEmtry: true);
            } else {
              switch (closeData.payMode) {
                case 0: // ชำระที่ Cashier (2=ปิดโต๊ะแล้วรอคิดเงิน)
                  result.table_status = 2;
                  break;
                case 1: // ชำระที่โต๊ะ (3=รับชำระเงินแล้ว)
                  result.table_status = 3;
                  cashAmount = closeData.payAmount;
                  {
                    int holdIndex = global.findPosHoldProcessResultIndex(holdNumber);
                    if (holdIndex != -1) {
                      global.posHoldProcessResult[holdIndex].payScreenData.round_amount = closeData.process.cash_round_amount;
                      global.posHoldProcessResult[holdIndex].payScreenData.round_amount_cash = closeData.process.cash_round_amount;
                    }
                  }
                  break;
                case 2: // ชำระที่โต๊ะ ด้วย QR Code (3=รับชำระเงินแล้ว)
                  result.table_status = 3;
                  cashAmount = 0;
                  {
                    int holdIndex = global.findPosHoldProcessResultIndex(holdNumber);
                    if (holdIndex != -1) {
                      global.posHoldProcessResult[holdIndex].payScreenData.qr.add(
                        PayQrModel(provider_code: closeData.providercode, provider_name: closeData.providername, amount: closeData.process.total_amount_pay),
                      );
                      global.posHoldProcessResult[holdIndex].payScreenData.round_amount = closeData.process.cash_round_amount;
                      global.posHoldProcessResult[holdIndex].payScreenData.round_amount_qr = closeData.process.cash_round_amount;
                    }
                  }
                  break;
                case 3: // ชำระที่โต๊ะ ด้วย QR Code SML (3=รับชำระเงินแล้ว)
                  result.table_status = 3;
                  cashAmount = 0;
                  {
                    int holdIndex = global.findPosHoldProcessResultIndex(holdNumber);
                    if (holdIndex != -1) {
                      global.posHoldProcessResult[holdIndex].payScreenData.qr.add(
                        PayQrModel(
                          provider_code: closeData.providercode,
                          provider_name: closeData.providername,
                          description: closeData.transactionId,
                          transactionId: closeData.transactionId,
                          amount: closeData.process.total_amount_pay,
                        ),
                      );
                      global.posHoldProcessResult[holdIndex].payScreenData.round_amount = closeData.process.cash_round_amount;
                      global.posHoldProcessResult[holdIndex].payScreenData.round_amount_qr = closeData.process.cash_round_amount;
                    }
                  }
                  break;
              }
              // ✅ Fix: ต้อง copy table_status จาก result ไปยัง closeData.table ก่อนบันทึก
              closeData.table.table_status = result.table_status;
              closeData.table.detail_discount_formula = closeData.discountFormula;
              box.put(closeData.table, mode: PutMode.update);
              print('[SERVER] Table status set to: ${result.table_status}');
              print('[SERVER] Checking if table_status == 3: ${result.table_status == 3}');
              if (result.table_status == 3) {
                try {
                  // สร้างบิล และพิมพ์ใบเสร็จ (ร้านอาหาร)

                  await posCompileProcess(
                    holdCode: holdNumber,
                    docMode: 1,
                    detailDiscountFormula: closeData.discountFormula,
                    cashRoundAmount: (closeData.payMode == 2 || closeData.payMode == 3) ? false : true,
                    discountFoodOnly: true,
                    customermode: global.secondScreenCommandPay,
                  );

                  // ✅ Fix: ใช้ await แทน .then() เพื่อให้ docNumber ถูก assign ก่อน response.write()
                  final billResult = await saveBill(
                    docMode: global.posScreenToInt(global.PosScreenModeEnum.posSale),
                    roundAmount: closeData.process.cash_round_amount,
                    totalAmountAfterDiscount: 0,
                    cashAmount: 0,
                    totalAmount: closeData.process.total_amount_pay,
                    tableNumber: closeData.table.number,
                    discountFormula: "",
                    discountAmount: 0,
                    isDelivery: false,
                    deliveryCode: "",
                    deliveryNumber: "",
                    posHoldActiveCode: holdNumber,
                    pointscode: "",
                  );

                  print('[SERVER] saveBill result: docNumber=${billResult.docNumber}');
                  if (billResult.docNumber.isNotEmpty) {
                    docNumber = billResult.docNumber;
                    print('[SERVER] docNumber assigned: $docNumber');
                    await global.saveOrderTempToSyncTempLog(docNumber: billResult.docNumber, guidPos: billResult.guidPos, orderId: closeData.table.number, orderEmtry: false);
                    if (closeData.slipImage.isNotEmpty) {
                      // เก็บ slip base64
                      Uint8List imageBytes = base64Decode(closeData.slipImage);
                      final dateDirectory = await global.createPath(global.paySlipPath, DateTime.now());
                      // Save the image to the new directory รูป SLIP
                      final path = "${dateDirectory.path}/${billResult.docNumber}.jpg";
                      final file = File(path);
                      await file.writeAsBytes(imageBytes);
                    }
                    await printBillProcess(
                      posScreenMode: global.PosScreenModeEnum.posSale,
                      docDate: billResult.docDate,
                      docNo: billResult.docNumber,
                      printLogo: global.posTicket.logo,
                      languageCode: global.userScreenLanguage,
                      isPaySlip: true,
                    );
                    // สำเนา
                    await printBillProcess(
                      posScreenMode: global.PosScreenModeEnum.posSale,
                      docDate: billResult.docDate,
                      docNo: billResult.docNumber,
                      languageCode: global.userScreenLanguage,
                      topText: "สำเนา",
                      printLogo: false,
                      printPaySlip: true,
                    );
                    // ลบรายการ Order Temp ออก
                    var dataTemp = global.objectBoxStore.box<OrderTempObjectBoxStruct>().query(OrderTempObjectBoxStruct_.orderId.equals(closeData.table.number)).build().findIds();
                    global.objectBoxStore.box<OrderTempObjectBoxStruct>().removeMany(dataTemp);
                    // ลบรายการที่ Hold ออก
                    await PosLogHelper().deleteByHoldCode(holdCode: holdNumber);
                    // ร้านอาหาร update โต๊ะ
                    final tableBox = global.objectBoxStore.box<TableProcessObjectBoxStruct>();
                    final tableResult = tableBox.query(TableProcessObjectBoxStruct_.number.equals(closeData.table.number)).build().findFirst();
                    if (tableResult != null) {
                      // ถ้าเป็นโต๊ะเสริม ให้ลบออก
                      if (tableResult.number.contains("#")) {
                        tableBox.remove(tableResult.id);
                      } else {
                        tableResult.table_status = 0;
                        tableBox.put(tableResult, mode: PutMode.update);
                      }
                    }
                    // Clear QR payment data
                    int holdIndex = global.findPosHoldProcessResultIndex(holdNumber);
                    if (holdIndex != -1) {
                      global.posHoldProcessResult[holdIndex].payScreenData.qr.clear();
                    }
                  }
                  // update สถานะโต๊ะ = 2 รอคิดเงิน (order online)
                  String query = "alter table dedeorderonline.tableinfo update tablestatus=2 where tablenumber='${closeData.table.number}' and shopid='${global.shopId}'";
                  await clickHouseExecute(query);
                } catch (e, stackTrace) {
                  AppLogger.error(e);
                  global.sendErrorToDevTeam(
                    "server_post.dart->staff.close_table",
                    "Error Server POS : ${httpPost.command} สร้างบิล และพิมพ์ใบเสร็จ (ร้านอาหาร) : $e ${stackTrace.toString()}",
                  );
                }
              }

              print('[SERVER] ========== RESPONSE: docNumber="$docNumber" ==========');
              response.write(docNumber);
              response.close();
            }
          } else {
            print('[SERVER] ERROR: Table not found in DB!');
            response.write("");
            response.close();
          }
        } catch (e, stackTrace) {
          print('[SERVER] ERROR in staff.close_table: $e');
          print('[SERVER] Stack: $stackTrace');
          global.sendErrorToDevTeam("server_post.dart->staff.close_table", "$e:$stackTrace");
          response.write("");
          response.close();
        }
        break;
      case "staff.update_table":
        try {
          var jsonObject = await jsonDecode(httpPost.data);
          TableProcessObjectBoxStruct getTable = TableProcessObjectBoxStruct.fromJson(jsonObject);
          final box = global.objectBoxStore.box<TableProcessObjectBoxStruct>();
          final result = box.query(TableProcessObjectBoxStruct_.number.equals(getTable.number)).build().findFirst();
          if (result != null) {
            box.put(getTable, mode: PutMode.update);
            if (!getTable.isUpdate) {
              await global.orderSumAndUpdateTable(getTable.number);

              switch (getTable.table_status) {
                case 1:
                  // ลบ Order Temp ออก ด้วยหมายเลขโต๊ะ
                  AppLogger.debug(getTable.order_success);
                  var dataTemp = global.objectBoxStore.box<OrderTempObjectBoxStruct>().query(OrderTempObjectBoxStruct_.orderId.equals(getTable.number)).build().findIds();
                  global.objectBoxStore.box<OrderTempObjectBoxStruct>().removeMany(dataTemp);
                  // พิมพ์ใบเปิดโต๊ะ
                  printer.printTableInformationAndQrCode(tableManagerMode: global.TableManagerEnum.openTable, table: getTable, qrCode: global.qrCodeOrderOnline(getTable.qr_code));
                  break;
              }

              await rebuildOrderToHoldBill(getTable.number, getTable.number);
            }

            clickHouseTableUpdateNew(getTable, getTable.isUpdate);
          }
        } catch (e, stackTrace) {
          global.sendErrorToDevTeam("server_post.dart->staff.update_table", "$e:$stackTrace");
        }
        break;
      case "staff.cancel_close_table":
        try {
          var jsonObject = await jsonDecode(httpPost.data);
          TableProcessObjectBoxStruct getTable = TableProcessObjectBoxStruct.fromJson(jsonObject);
          final box = global.objectBoxStore.box<TableProcessObjectBoxStruct>();
          final result = box.query(TableProcessObjectBoxStruct_.number.equals(getTable.number)).build().findFirst();
          if (result != null) {
            box.put(getTable, mode: PutMode.update);
            await global.orderSumAndUpdateTable(getTable.number);

            await rebuildOrderToHoldBill(getTable.number, getTable.number);
            clickHouseTableUpdate(getTable);
          }
        } catch (e, stackTrace) {
          global.sendErrorToDevTeam("server_post.dart->staff.update_table", "$e:$stackTrace");
        }
        break;
      case "staff.move_table":
        try {
          // ย้ายโต๊ะ
          var jsonObject = await jsonDecode(httpPost.data);
          String fromTableNumber = jsonObject["from_table"];
          String toTableNumber = jsonObject["to_table"];
          final fromTableResult = global.objectBoxStore.box<TableProcessObjectBoxStruct>().query(TableProcessObjectBoxStruct_.number.equals(fromTableNumber)).build().findFirst();
          final toTableResult = global.objectBoxStore.box<TableProcessObjectBoxStruct>().query(TableProcessObjectBoxStruct_.number.equals(toTableNumber)).build().findFirst();
          if (fromTableResult != null && toTableResult != null) {
            // Update เปิดโต๊ะ ปลายทาง
            toTableResult.number_main = toTableResult.number;
            toTableResult.table_status = 1;
            toTableResult.man_count = fromTableResult.man_count;
            toTableResult.woman_count = fromTableResult.woman_count;
            toTableResult.child_count = fromTableResult.child_count;
            toTableResult.table_al_la_crate_mode = fromTableResult.table_al_la_crate_mode;
            toTableResult.buffet_code = fromTableResult.buffet_code;
            toTableResult.amount = fromTableResult.amount;
            toTableResult.order_count = fromTableResult.order_count;
            toTableResult.table_open_datetime = fromTableResult.table_open_datetime;
            global.objectBoxStore.box<TableProcessObjectBoxStruct>().put(toTableResult, mode: PutMode.update);
            // Update ปิดโต๊ะ ต้นทาง
            fromTableResult.table_status = 0;
            fromTableResult.order_count = 0;
            fromTableResult.amount = 0;
            fromTableResult.man_count = 0;
            fromTableResult.woman_count = 0;
            fromTableResult.child_count = 0;
            fromTableResult.number_main = "";
            global.objectBoxStore.box<TableProcessObjectBoxStruct>().put(fromTableResult, mode: PutMode.update);
            // ย้าย Order (Hold Bill)
            final posLogs = global.objectBoxStore.box<PosLogObjectBoxStruct>().query(PosLogObjectBoxStruct_.hold_code.equals("T-$fromTableNumber")).build().find();
            for (int index = 0; index < posLogs.length; index++) {
              posLogs[index].hold_code = "T-$toTableNumber";
            }
            global.objectBoxStore.box<PosLogObjectBoxStruct>().putMany(posLogs, mode: PutMode.update);
            // ย้าย Order (Order Temp)
            final orderTemps = global.objectBoxStore
                .box<OrderTempObjectBoxStruct>()
                .query(OrderTempObjectBoxStruct_.orderId.equals(fromTableNumber).and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false)))
                .build()
                .find();
            for (int index = 0; index < orderTemps.length; index++) {
              orderTemps[index].orderId = toTableNumber;
              orderTemps[index].orderIdMain = toTableNumber;
            }
            global.objectBoxStore.box<OrderTempObjectBoxStruct>().putMany(orderTemps, mode: PutMode.update);
            // print ticket to cashier and kitchen station
            printer.printTableInformationAndQrCode(
              tableManagerMode: global.TableManagerEnum.moveTable,
              table: fromTableResult,
              fromTable: fromTableResult.number,
              toTable: toTableResult.number,
              qrCode: global.qrCodeOrderOnline(toTableResult.qr_code),
            );
            // สร้างใหม่ (Hold)
            await rebuildOrderToHoldBill(fromTableResult.number, fromTableResult.number);
            await rebuildOrderToHoldBill(toTableNumber, toTableNumber);
            // คำนวณใหม่
            await global.orderSumAndUpdateTable(fromTableResult.number);
            await global.orderSumAndUpdateTable(toTableNumber);
          }
        } catch (e, stackTrace) {
          global.sendErrorToDevTeam("server_post.dart->staff.move_table", "$e:$stackTrace");
        }
        break;
      case "staff.merge_table":
        try {
          // รวมโต๊ะ
          var jsonObject = await jsonDecode(httpPost.data);
          String fromTableNumber = jsonObject["from_table"];
          String toTableNumber = jsonObject["to_table"];
          final fromTableResult = global.objectBoxStore.box<TableProcessObjectBoxStruct>().query(TableProcessObjectBoxStruct_.number.equals(fromTableNumber)).build().findFirst();
          final toTableResult = global.objectBoxStore.box<TableProcessObjectBoxStruct>().query(TableProcessObjectBoxStruct_.number.equals(toTableNumber)).build().findFirst();
          if (fromTableResult != null && toTableResult != null) {
            // Update โต๊ะ ปลายทาง
            toTableResult.table_status = 1;
            toTableResult.man_count += fromTableResult.man_count;
            toTableResult.woman_count += fromTableResult.woman_count;
            toTableResult.child_count += fromTableResult.child_count;
            toTableResult.table_al_la_crate_mode = fromTableResult.table_al_la_crate_mode;
            toTableResult.buffet_code = fromTableResult.buffet_code;
            toTableResult.amount = fromTableResult.amount;
            toTableResult.order_count = fromTableResult.order_count;
            toTableResult.table_open_datetime = fromTableResult.table_open_datetime;
            global.objectBoxStore.box<TableProcessObjectBoxStruct>().put(toTableResult, mode: PutMode.update);
            // ย้าย Order (Hold Bill)
            final posLogs = global.objectBoxStore.box<PosLogObjectBoxStruct>().query(PosLogObjectBoxStruct_.hold_code.equals("T-$fromTableNumber")).build().find();
            for (int index = 0; index < posLogs.length; index++) {
              posLogs[index].hold_code = "T-$toTableNumber";
            }
            global.objectBoxStore.box<PosLogObjectBoxStruct>().putMany(posLogs, mode: PutMode.update);
            // ย้าย Order (Order Temp)
            final orderTemps = global.objectBoxStore
                .box<OrderTempObjectBoxStruct>()
                .query(OrderTempObjectBoxStruct_.orderId.equals(fromTableNumber).and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false)))
                .build()
                .find();
            for (int index = 0; index < orderTemps.length; index++) {
              orderTemps[index].orderId = toTableNumber;
              orderTemps[index].orderIdMain = toTableNumber.split("#")[0];
            }
            global.objectBoxStore.box<OrderTempObjectBoxStruct>().putMany(orderTemps, mode: PutMode.update);
            // ลบโต๊ กรณีเป็นโต๊ะลูก
            if (fromTableNumber.contains("#")) {
              global.objectBoxStore.box<TableProcessObjectBoxStruct>().remove(fromTableResult.id);
            }
            // คำนวณใหม่
            await global.orderSumAndUpdateTable(fromTableNumber);
            await global.orderSumAndUpdateTable(toTableNumber);
          }
        } catch (e, stackTrace) {
          global.sendErrorToDevTeam("server_post.dart->staff.merge_table", "$e:$stackTrace");
        }
        break;
      case "process_result":
        try {
          PosHoldProcessModel result = PosHoldProcessModel.fromJson(await jsonDecode(httpPost.data));
          global.posHoldProcessResult[global.findPosHoldProcessResultIndex(result.code)] = result;
          PosProcess().sumCategoryCount(value: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(result.code)].posProcess);
          if (global.functionPosScreenRefresh != null) {
            global.functionPosScreenRefresh!(result.code);
          }
        } catch (e, stackTrace) {
          global.sendErrorToDevTeam("server_post.dart->process_result", "$e:$stackTrace");
        }
        break;
      case "PosLogHelper.insert":
        PosLogObjectBoxStruct jsonData = PosLogObjectBoxStruct.fromJson(await jsonDecode(httpPost.data));
        final box = global.objectBoxStore.box<PosLogObjectBoxStruct>();
        response.write(box.put(jsonData));
        for (int index = 0; index < global.posRemoteDeviceList.length; index++) {
          if (global.posRemoteDeviceList[index].holdCodeActive == jsonData.hold_code) {
            global.posRemoteDeviceList[index].processSuccess = false;
          }
        }
        await posCompileProcess(
          holdCode: jsonData.hold_code,
          docMode: jsonData.doc_mode,
          detailDiscountFormula: "",
          cashRoundAmount: false,
          discountFoodOnly: false,
          customermode: global.activeCustomerDisplayScreen,
        ).then((_) {
          PosProcess().sumCategoryCount(value: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.orderHoldActiveCode)].posProcess);
          if (global.functionPosScreenRefresh != null) {
            global.functionPosScreenRefresh!(global.orderHoldActiveCode);
          }
        });
        break;
      case "PosLogHelper.deleteByHoldCode":
        String holdCode = httpPost.data;
        int docMode = 0; //********* Dummy
        final box = global.objectBoxStore.box<PosLogObjectBoxStruct>();
        final ids = box.query(PosLogObjectBoxStruct_.hold_code.equals(holdCode)).build().findIds();
        box.removeMany(ids);
        await posCompileProcess(
          holdCode: holdCode,
          docMode: docMode,
          detailDiscountFormula: "",
          cashRoundAmount: false,
          discountFoodOnly: false,
          customermode: global.activeCustomerDisplayScreen,
        ).then((_) {
          PosProcess().sumCategoryCount(value: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(holdCode)].posProcess);
          if (global.functionPosScreenRefresh != null) {
            global.functionPosScreenRefresh!(global.orderHoldActiveCode);
          }
        });
        break;
      case "get_device_name":
        // Return ชื่อเครื่อง server , ip server
        response.write(jsonEncode(await jsonDecode('{"device": "${global.deviceName}"}') as Map));
        break;
      case "register_remote_device":
        // ลงทะเบียนเครื่องช่วยขาย
        SyncDeviceModel posClientDevice = SyncDeviceModel.fromJson(await jsonDecode(httpPost.data));
        int indexFound = -1;
        for (int index = 0; index < global.posRemoteDeviceList.length; index++) {
          if (global.posRemoteDeviceList[index].deviceId == posClientDevice.deviceId) {
            indexFound = index;
            break;
          }
        }
        if (indexFound != -1) {
          global.posRemoteDeviceList[indexFound].ip = posClientDevice.ip;
          global.posRemoteDeviceList[indexFound].holdCodeActive = posClientDevice.holdCodeActive;
          serviceLocator<Log>().debug("register_remote_device : ${posClientDevice.ip},hold_number : ${global.posRemoteDeviceList[indexFound].holdCodeActive}");
        } else {
          global.posRemoteDeviceList.add(posClientDevice);
          serviceLocator<Log>().debug("register_remote_device : ${posClientDevice.deviceId} : ${global.posRemoteDeviceList.length}");
        }
        break;
      case "register_customer_display_device":
        // ลงทะเบียนเครื่องแสดงผลลูกค้า
        SyncDeviceModel customerDisplayDevice = SyncDeviceModel.fromJson(await jsonDecode(httpPost.data));
        bool found = false;
        for (var device in global.customerDisplayDeviceList) {
          if (device.deviceId == customerDisplayDevice.deviceId) {
            found = true;
            break;
          }
        }
        if (!found) {
          global.customerDisplayDeviceList.add(customerDisplayDevice);
          serviceLocator<Log>().debug("register_customer_display_device : ${customerDisplayDevice.deviceId} : ${global.customerDisplayDeviceList.length}");
        }
        break;
      case "change_customer_by_phone":
        // รับข้อมูลหมายเลขโทรศัพท์ แล้วมาค้นหาชื่อ และประมวลผล
        SyncCustomerDisplayModel postCustomer = SyncCustomerDisplayModel.fromJson(await jsonDecode(httpPost.data));
        String customerCode = postCustomer.phone;
        String customerName = "";
        String customerPhone = postCustomer.phone;
        SyncCustomerDisplayModel result = SyncCustomerDisplayModel(code: customerCode, phone: customerPhone, name: customerName);
        response.write(jsonEncode(result.toJson()));
        try {
          global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.orderHoldActiveCode)].customerCode = "";
          global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.orderHoldActiveCode)].customerName = customerName;
          global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.orderHoldActiveCode)].customerPhone = customerPhone;
          // ประมวลผลหน้าจอขายใหม่
          PosProcess().sumCategoryCount(value: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.orderHoldActiveCode)].posProcess);
          if (global.functionPosScreenRefresh != null) {
            global.functionPosScreenRefresh!(global.orderHoldActiveCode);
            global.sendProcessToCustomerDisplay(mode: "");
          }
        } catch (e) {
          AppLogger.error(e);
        }
        break;
    }
  } catch (e, stackTrace) {
    global.sendErrorToDevTeam("serverPost:", "$e\n$stackTrace");
  }
}
