import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/objectbox/objectbox.g.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:dedekiosk/util/logger.dart';
import 'package:dedekiosk/util/network_helper.dart';
import 'package:dedekiosk/util/print_queue.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/api.dart' as api;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

Future<void> orderAdd(
    {required BuildContext context,
    required String barcode,
    required bool calcStockQty,
    required String jsonOptions,
    required String remark,
    required double qty,
    required double optionamount,
    required double discountamount,
    required double price,
    required bool isexceptvat,
    String manufacturerguid = ""}) async {
  try {
    // ค้นหารายการ ถ้ามีอยู่แล้ว และเงื่อนไขเดิม ให้ทำการ update
    bool foundOldOrder = false;
    String oldOrderGuid = "";
    double amount = 0;

    List<OrderTempObjectBoxModel> getOrder;
    try {
      getOrder = global.objectBoxStore.box<OrderTempObjectBoxModel>().query(OrderTempObjectBoxModel_.orderid.equals(global.orderId).and(OrderTempObjectBoxModel_.barcode.equals(barcode))).build().find();
    } catch (e, s) {
      Logger.e('orderAdd ObjectBox query error', error: e, stackTrace: s);
      global.sendErrorToDevTeam("orderAdd ObjectBox query error: $e");
      getOrder = [];
    }

    if (getOrder.isNotEmpty) {
      for (var order in getOrder) {
        String optionSelected = order.optionselected;
        if (optionSelected == jsonOptions && order.remark == remark) {
          foundOldOrder = true;
          oldOrderGuid = order.orderguid;
          qty += order.qty;
          price = order.price;
          amount = (price * qty);
          optionamount = order.optionamount * qty;
          if (optionSelected.isNotEmpty) {
            try {
              List<ProductProcessOptionModel> optionList = (jsonDecode(optionSelected) as List).map((e) => ProductProcessOptionModel.fromJson(e)).toList();
              for (var option in optionList) {
                for (var choice in option.choices) {
                  if (choice.selected) {
                    amount += (choice.priceValue);
                  }
                }
              }
            } catch (e, s) {
              Logger.e('orderAdd jsonDecode optionSelected error', error: e, stackTrace: s);
              global.sendErrorToDevTeam("orderAdd jsonDecode optionSelected error: $e");
            }
          }
          break;
        }
      }
    }
    if (foundOldOrder) {
      // อัพเดทรายการเก่า
      var id = global.objectBoxStore.box<OrderTempObjectBoxModel>().query(OrderTempObjectBoxModel_.orderguid.equals(oldOrderGuid)).build().findFirst()?.id;
      if (id != null) {
        bool calcStockPass = true;
        if (calcStockQty) {
          // ตรวจสอบยอดคงเหลือ
          try {
            double oldQty = getOrder[0].qty;

            // Wrap stock check with timeout (NetworkTimeouts.quick = 5 seconds)
            // คำนวณ stock โดยนับเฉพาะ isclose = 0 (รอชำระ), 1 (ขายแล้ว), 9 (ปรับสต็อก)
            // ไม่นับ isclose = 2 (ยกเลิก)
            var getStockQty = await api
                .clickHouseSelect("select (sum(qty)+$oldQty)-$qty as qty from ${global.clickHouseDatabaseName}.ordertempcalcqty where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and barcode='$barcode' and isclose in (0,1,9)")
                .timeout(
              NetworkTimeouts.quick,
              onTimeout: () {
                throw TimeoutException('Stock check timeout (update)');
              },
            );

            ResponseDataModel responseData = ResponseDataModel.fromJson(getStockQty);
            if (responseData.data.isNotEmpty) {
              double stockQty = double.tryParse(responseData.data[0]["qty"].toString()) ?? 0;
              if (stockQty < 0) {
                if (context.mounted) {
                  calcStockPass = false;
                  await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(global.language("unable_to_complete_transaction")),
                          content: Text(global.language("inventory_is_not_enough")),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(global.language("confirm")),
                            ),
                          ],
                        );
                      });
                }
              }
            }
          } on TimeoutException catch (e) {
            Logger.w('Stock check timeout (update): $e');

            if (context.mounted) {
              // แสดง dialog ให้เลือก: ลองใหม่ / ดำเนินการต่อ / ยกเลิก
              calcStockPass = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(global.language("network_timeout")),
                        content: Text("${global.language("checking_stock")} ${global.language("operation_timeout")}\n\n${global.language("retry_question")}"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false); // ยกเลิก
                            },
                            child: Text(global.language("cancel")),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, true); // ข้ามการเช็คสต็อก
                            },
                            child: Text(global.language("continue_anyway")),
                          ),
                        ],
                      );
                    },
                  ) ??
                  false;

              if (!calcStockPass) {
                global.sendErrorToDevTeam("Stock check timeout - user cancelled (update): $barcode");
              }
            } else {
              calcStockPass = false;
            }
          } catch (e, s) {
            Logger.e('orderAdd stock check error (update)', error: e, stackTrace: s);
            global.sendErrorToDevTeam("orderAdd stock check error (update): $e");
            calcStockPass = false;
          }
        }
        if (calcStockPass) {
          try {
            global.objectBoxStore.box<OrderTempObjectBoxModel>().put(
                OrderTempObjectBoxModel(
                    id: id,
                    orderid: global.orderId,
                    orderguid: oldOrderGuid,
                    barcode: barcode,
                    qty: qty,
                    optionamount: optionamount,
                    salechannelcode: global.saleChannelCode,
                    discountamount: discountamount,
                    remark: remark,
                    optionselected: jsonOptions,
                    orderdatetime: DateTime.now(),
                    price: price,
                    amount: amount,
                    queuenumber: 0,
                    manufacturerguid: manufacturerguid,
                    istakeaway: global.orderType,
                    isexceptvat: isexceptvat),
                mode: PutMode.update);
            if (kDebugMode) {
              print("************** update order temp ************** qty$qty");
            }
            if (calcStockQty) {
              // update qty to server
              api.clickHouseExecute("alter table ${global.clickHouseDatabaseName}.ordertempcalcqty update qty=${qty * -1} where shopid='${global.deviceConfig.shopId}' and orderid='${global.orderId}' and orderguid='$oldOrderGuid';");
            }
          } catch (e, s) {
            Logger.e('orderAdd ObjectBox update error', error: e, stackTrace: s);
            global.sendErrorToDevTeam("orderAdd ObjectBox update error: $e");
          }
        }
      }
    } else {
      bool calcStockPass = true;
      if (calcStockQty) {
        try {
          // Wrap stock check with timeout (NetworkTimeouts.quick = 5 seconds)
          // คำนวณ stock โดยนับเฉพาะ isclose = 0 (รอชำระ), 1 (ขายแล้ว), 9 (ปรับสต็อก)
          // ไม่นับ isclose = 2 (ยกเลิก)
          var getStockQty = await api
              .clickHouseSelect("select sum(qty)-$qty as qty from ${global.clickHouseDatabaseName}.ordertempcalcqty where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and barcode='$barcode' and isclose in (0,1,9)")
              .timeout(
            NetworkTimeouts.quick,
            onTimeout: () {
              throw TimeoutException('Stock check timeout (insert)');
            },
          );

          ResponseDataModel responseData = ResponseDataModel.fromJson(getStockQty);
          if (responseData.data.isNotEmpty) {
            double stockQty = double.tryParse(responseData.data[0]["qty"].toString()) ?? 0;
            if (stockQty < 0) {
              if (context.mounted) {
                calcStockPass = false;
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(global.language("unable_to_complete_transaction")),
                        content: Text(global.language("inventory_is_not_enough")),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(global.language("confirm")),
                          ),
                        ],
                      );
                    });
              }
            }
          }
        } on TimeoutException catch (e) {
          Logger.w('Stock check timeout (insert): $e');

          if (context.mounted) {
            // แสดง dialog ให้เลือก: ยกเลิก / ดำเนินการต่อ
            calcStockPass = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(global.language("network_timeout")),
                      content: Text("${global.language("checking_stock")} ${global.language("operation_timeout")}\n\n${global.language("retry_question")}"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false); // ยกเลิก
                          },
                          child: Text(global.language("cancel")),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, true); // ข้ามการเช็คสต็อก
                          },
                          child: Text(global.language("continue_anyway")),
                        ),
                      ],
                    );
                  },
                ) ??
                false;

            if (!calcStockPass) {
              global.sendErrorToDevTeam("Stock check timeout - user cancelled (insert): $barcode");
            }
          } else {
            calcStockPass = false;
          }
        } catch (e, s) {
          Logger.e('orderAdd stock check error (insert)', error: e, stackTrace: s);
          global.sendErrorToDevTeam("orderAdd stock check error (insert): $e");
          calcStockPass = false;
        }
      }
      if (calcStockPass) {
        try {
          double amount = qty * price;
          if (jsonOptions.isNotEmpty) {
            try {
              List<ProductProcessOptionModel> optionList = (jsonDecode(jsonOptions) as List).map((e) => ProductProcessOptionModel.fromJson(e)).toList();
              for (var option in optionList) {
                for (var choice in option.choices) {
                  if (choice.selected) {
                    amount += (choice.priceValue * qty);
                  }
                }
              }
            } catch (e, s) {
              Logger.e('orderAdd jsonDecode jsonOptions error', error: e, stackTrace: s);
              global.sendErrorToDevTeam("orderAdd jsonDecode jsonOptions error: $e");
            }
          }
          optionamount = optionamount * qty;
          // เพิ่มรายการใหม่
          String orderGuid = const Uuid().v4();
          global.objectBoxStore.box<OrderTempObjectBoxModel>().put(
              OrderTempObjectBoxModel(
                  orderid: global.orderId,
                  orderguid: orderGuid,
                  barcode: barcode,
                  qty: qty,
                  optionamount: optionamount,
                  discountamount: discountamount,
                  salechannelcode: global.saleChannelCode,
                  remark: remark,
                  optionselected: jsonOptions,
                  orderdatetime: DateTime.now(),
                  price: price,
                  amount: amount,
                  manufacturerguid: manufacturerguid,
                  queuenumber: 0,
                  istakeaway: global.orderType,
                  isexceptvat: isexceptvat),
              mode: PutMode.insert);
          if (kDebugMode) {
            print("************** insert order temp ************** qty$qty");
          }
          if (calcStockQty) {
            // insert qty to server
            api.clickHouseExecute(
                "insert into ${global.clickHouseDatabaseName}.ordertempcalcqty (shopid,branchid,deviceid,orderid,orderguid,orderdatetime,barcode,isclose,qty,manufacturerguid) values ('${global.deviceConfig.shopId}', '${global.deviceConfig.branchId}', '${global.deviceConfig.orderStationCode}', '${global.orderId}', '$orderGuid',now(),'$barcode',0, ${qty * -1},'$manufacturerguid');");
          }
        } catch (e, s) {
          Logger.e('orderAdd ObjectBox insert error', error: e, stackTrace: s);
          global.sendErrorToDevTeam("orderAdd ObjectBox insert error: $e");
        }
      }
    }
  } catch (e, s) {
    Logger.e('orderAdd error', error: e, stackTrace: s);
    global.sendErrorToDevTeam("orderAdd error: $e");
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(global.language("error")),
          content: Text(global.language("operation_failed")),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(global.language("ok")),
            ),
          ],
        ),
      );
    }
  }
}

/// mode 0=รายการที่ยังปิด 1=รายการที่ยังไม่พิพม์สำเนา
Future<List<OrderTempModel>> loadOrderTempDoc(String tableName, int mode) async {
  String where = "where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}'";
  switch (mode) {
    case 0:
      where += " and (detailsuccess=1 and isclose=1)";
      break;
    case 1:
      where += " and (detailsuccess=1 and isclose=1 and copyprintsuccess=0)";
      break;
  }
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

Future<List<OrderTempDetailModel>> getOrderTempDetail({required String tableName, required String orderNumber, required String orderid}) async {
  String where = "";
  if (orderNumber.isNotEmpty) {
    where += " and ordernumber='$orderNumber'";
  }
  if (orderid.isNotEmpty) {
    where += " and orderid='$orderid'";
  }
  String selectQuery =
      "select orderid,orderguid,barcode,qty,optionselected,remark,orderdatetime,istakeaway,price,amount,ordertagnumber,optionamount,discountamount,salechannelcode from $tableName where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' $where and isclose=2 order by orderdatetime,linenumber";
  var value = await api.clickHouseSelect(selectQuery);
  ResponseDataModel responseData = ResponseDataModel.fromJson(value);
  List<OrderTempDetailModel> orderTempDetail = [];
  for (var order in responseData.data) {
    OrderTempDetailModel orderData = OrderTempDetailModel(
      barcode: order["barcode"],
      orderguid: order["orderguid"],
      qty: double.tryParse(order["qty"].toString()) ?? 0,
      optionamount: double.tryParse(order["optionamount"].toString()) ?? 0,
      discountamount: double.tryParse(order["discountamount"].toString()) ?? 0,
      optionselected: order["optionselected"],
      remark: order["remark"],
      ordertagnumber: order["ordertagnumber"],
      salechannelcode: order["salechannelcode"],
      orderdatetime: DateTime.tryParse(order["orderdatetime"]) ?? DateTime.now(),
      price: double.tryParse(order["price"].toString()) ?? 0,
      amount: double.tryParse(order["amount"].toString()) ?? 0,
      istakeaway: order["istakeaway"],
      queuenumber: int.tryParse(order["queuenumber"].toString()) ?? 0,
      isserved: 0,
      iscooked: 0,
      iscookcancel: 0,
      isservedcancel: 0,
      machineid: "",
    );
    orderTempDetail.add(orderData);
  }
  return orderTempDetail;
}

Future<void> checkOrderOnline() async {
  // ตรวจสอบ Order จากมือถือลูกค้า หรือมือถือพนักงาน (เครื่องลูก)
  if (global.checkOrderActivePrint == false) {
    global.checkOrderActivePrint = true;
    try {
      if (global.deviceConfig.shopId.isNotEmpty && global.deviceConfig.isServer) {
        try {
          // พิมพ์สำเนา ใบเสร็จ
          if (global.deviceConfig.systemCondition == 1) {
            // กินก่อนจ่าย
            // สำเนาใบกับกับภาษี
            // ดึงรายการที่ยังไม่พิมพ์สำเนา
            List<OrderTempModel> orderTempDocList = await loadOrderTempDoc("${global.clickHouseDatabaseName}.ordertempdoc", 1);
            for (var orderTempDoc in orderTempDocList) {
              List<OrderTempDetailModel> orderTempDetail = await getOrderTempDetail(tableName: "${global.clickHouseDatabaseName}.ordertemp", orderNumber: orderTempDoc.ordernumber, orderid: "");
              if (orderTempDoc.orderpaysuccess == 1) {
                global.printQueue.add(PrintTicketClass(
                    docDate: orderTempDoc.orderdatetime.add(const Duration(hours: 7)),
                    docNumber: orderTempDoc.ordernumber,
                    orderTagNumber: orderTempDoc.ordertagnumber,
                    orderId: orderTempDoc.ordernumber,
                    printType: 0,
                    printLogo: true,
                    orderType: global.orderType,
                    printHeader: true,
                    orderTempDetails: [],
                    queueNumber: orderTempDoc.queuenumber,
                    footer: "สำเนา",
                    saveToFile: false,
                    openCashDrawer: false,
                    orderList: orderTempDetail,
                    printerLocalConfig: global.deviceConfig.printerForOwner,
                    payResult: orderTempDoc.payresult,
                    qrCode: ""));
                // update orderpaysuccess=2
                String query =
                    "alter table ${global.clickHouseDatabaseName}.ordertempdoc update copyprintsuccess=1 where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and copyprintsuccess=0 and orderid='${orderTempDoc.orderid}' and ordernumber='${orderTempDoc.ordernumber}'";
                await api.clickHouseExecute(query);
              }

              if (global.deviceConfig.printerForOwner.ipAddress.isNotEmpty || global.deviceConfig.printerForOwner.code.isNotEmpty) {
                String header = "ใบสรุป";
                if (orderTempDetail[0].istakeaway == 1) {
                  header += " : สั่งกลับบ้าน";
                  if (orderTempDetail[0].salechannelcode.isNotEmpty) {
                    header += " ${orderTempDetail[0].salechannelcode}";
                  }
                }
                global.printQueue.add(PrintTicketClass(
                    docDate: orderTempDoc.orderdatetime.add(const Duration(hours: 7)),
                    docNumber: orderTempDoc.ordernumber,
                    orderTagNumber: orderTempDoc.ordertagnumber,
                    orderId: orderTempDoc.orderid,
                    printType: 0,
                    orderType: orderTempDoc.ordertype,
                    printLogo: false,
                    printHeader: false,
                    orderTempDetails: [],
                    queueNumber: orderTempDoc.queuenumber,
                    footer: header,
                    saveToFile: false,
                    openCashDrawer: false,
                    orderList: orderTempDetail,
                    printerLocalConfig: global.deviceConfig.printerForOwner,
                    payResult: orderTempDoc.payresult,
                    qrCode: ""));
              }
            }
          }
        } catch (e, s) {
          if (kDebugMode) {
            print(e);
            print(s);
          }
        }

        try {
          // ดึง Order ลูกค้า  สั่งเอง
          List<OrderTempModel> orderTempDocList = await loadOrderTempDoc("${global.clickHouseDatabaseName}.ordertempdoc", 0);
          for (var orderTempDoc in orderTempDocList) {
            // Print
            List<OrderTempDetailModel> orderTempDetail = await getOrderTempDetail(tableName: "${global.clickHouseDatabaseName}.ordertemp", orderNumber: orderTempDoc.ordernumber, orderid: orderTempDoc.orderid);
            if (orderTempDetail.isNotEmpty) {
              if (global.deviceConfig.systemCondition == 2) {
                // จ่ายก่อนกิน
                // สำเนาใบกับกับภาษี
                global.printQueue.add(PrintTicketClass(
                    docDate: orderTempDoc.orderdatetime.add(const Duration(hours: 7)),
                    docNumber: orderTempDoc.ordernumber,
                    orderTagNumber: orderTempDoc.ordertagnumber,
                    orderId: orderTempDoc.ordernumber,
                    printType: 0,
                    printLogo: true,
                    orderType: global.orderType,
                    printHeader: true,
                    orderTempDetails: [],
                    queueNumber: orderTempDoc.queuenumber,
                    footer: "สำเนา",
                    saveToFile: false,
                    openCashDrawer: false,
                    orderList: orderTempDetail,
                    printerLocalConfig: global.deviceConfig.printerForOwner,
                    payResult: orderTempDoc.payresult,
                    qrCode: ""));
              }

              if (global.deviceConfig.printerForOwner.ipAddress.isNotEmpty || global.deviceConfig.printerForOwner.code.isNotEmpty) {
                String header = "ใบสรุป";
                if (orderTempDetail[0].istakeaway == 1) {
                  header += " : สั่งกลับบ้าน";
                  if (orderTempDetail[0].salechannelcode.isNotEmpty) {
                    header += " ${orderTempDetail[0].salechannelcode}";
                  }
                }
                global.printQueue.add(PrintTicketClass(
                    docDate: orderTempDoc.orderdatetime.add(const Duration(hours: 7)),
                    docNumber: orderTempDoc.ordernumber,
                    orderTagNumber: orderTempDoc.ordertagnumber,
                    orderId: orderTempDoc.orderid,
                    printType: 0,
                    orderType: orderTempDoc.ordertype,
                    printLogo: false,
                    printHeader: false,
                    orderTempDetails: [],
                    queueNumber: orderTempDoc.queuenumber,
                    footer: header,
                    saveToFile: false,
                    openCashDrawer: false,
                    orderList: orderTempDetail,
                    printerLocalConfig: global.deviceConfig.printerForOwner,
                    payResult: orderTempDoc.payresult,
                    qrCode: ""));
              }

              // update ordertemp isclose=2 (รายการ)
              String query =
                  "alter table ${global.orderTempTableName()} update isclose=2 where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and isclose=1 and orderid='${orderTempDoc.orderid}' and ordernumber='${orderTempDoc.ordernumber}'";
              await api.clickHouseExecute(query);
            }
            // update ordertempdoc isclose=2 (หัวบิล)
            String query =
                "alter table ${global.orderTempDocTableName()} update isclose=2 where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and isclose=1 and orderid='${orderTempDoc.orderid}' and ordernumber='${orderTempDoc.ordernumber}'";
            await api.clickHouseExecute(query);
          }
        } catch (e, s) {
          if (kDebugMode) {
            print(e);
            print(s);
          }
        }
      }
    } finally {
      global.checkOrderActivePrint = false;
    }
  }
}

class NumPadButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final Function callBack;
  final Color? color;
  final Color? textAndIconColor;
  final double margin;

  const NumPadButton({super.key, this.text, this.icon, required this.callBack, this.color, this.margin = 0, this.textAndIconColor});

  @override
  Widget build(BuildContext context) {
    Widget label = icon != null
        ? FittedBox(
            fit: BoxFit.fill,
            child: Icon(icon,
                shadows: const <Shadow>[
                  Shadow(
                    blurRadius: 1.0,
                    color: Colors.black,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
                color: (textAndIconColor == null) ? Colors.white : textAndIconColor),
          )
        : Text(text ?? "",
            style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    blurRadius: 1.0,
                    color: Colors.black,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
                color: ((textAndIconColor == null) ? Colors.white : textAndIconColor)));
    ElevatedButton button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: (color == null) ? Colors.blue : color,
        minimumSize: Size.zero,
      ),
      onPressed: () {
        callBack.call();
      },
      child: FittedBox(fit: BoxFit.scaleDown, child: label),
    );
    return (margin == 0)
        ? button
        : Padding(
            padding: EdgeInsets.all(margin),
            child: button,
          );
  }
}

// Global flag to prevent concurrent uploads
bool _isUploadingSlip = false;

/// ตรวจสอบ internet connection โดยการ ping
Future<bool> _hasInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com').timeout(Duration(seconds: 5));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (e) {
    return false;
  }
}

Future<void> uploadSlipWorker() async {
  // ป้องกัน concurrent execution (Lock Mechanism)
  if (_isUploadingSlip) {
    Logger.w('uploadSlipWorker: Already running, skipping...', tag: 'SlipUpload');
    return;
  }

  Logger.i("🔵 uploadSlipWorker: START", tag: 'SlipUpload');
  Logger.d("🔵 shopId: ${global.deviceConfig.shopId}", tag: 'SlipUpload');
  Logger.d("🔵 branchId: ${global.deviceConfig.branchId}", tag: 'SlipUpload');
  Logger.d("🔵 deviceCode: ${global.deviceConfig.orderStationCode}", tag: 'SlipUpload');

  _isUploadingSlip = true;

  // upload slip to server
  try {
    // ตรวจสอบ internet connection ก่อน
    Logger.d("🔵 Checking internet connection...", tag: 'SlipUpload');
    final hasInternet = await _hasInternetConnection();
    Logger.d("🔵 Internet connection: $hasInternet", tag: 'SlipUpload');

    if (!hasInternet) {
      Logger.w('uploadSlipWorker: No internet connection, skipping...', tag: 'SlipUpload');
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    Logger.d("🔵 App documents directory: ${directory.path}", tag: 'SlipUpload');
    Directory dir = Directory('${directory.path}/${global.billImagePath}');
    Logger.d("🔵 Slip directory: ${dir.path}", tag: 'SlipUpload');
    Logger.d("🔵 Directory exists: ${dir.existsSync()}", tag: 'SlipUpload');

    if (!dir.existsSync()) {
      Logger.d('uploadSlipWorker: Directory does not exist', tag: 'SlipUpload');
      return;
    }

    // ✅ FIX: Cleanup ไฟล์เก่า (> 30 วัน) ก่อน process
    try {
      final now = DateTime.now();
      List<FileSystemEntity> allFiles = dir.listSync();
      int deletedCount = 0;

      for (var file in allFiles) {
        if (file is File && file.path.toLowerCase().endsWith('.jpg')) {
          try {
            final stat = file.statSync();
            final age = now.difference(stat.modified);

            if (age.inDays > 30) {
              await file.delete();
              deletedCount++;
              String fileName = file.path.replaceAll("\\", "/").split("/").last;
              Logger.d("uploadSlipWorker: Deleted old file (${age.inDays} days) - $fileName", tag: 'SlipUpload');
            }
          } catch (e) {
            // Ignore errors for individual files
          }
        }
      }

      if (deletedCount > 0) {
        Logger.i("uploadSlipWorker: Cleaned up $deletedCount old files", tag: 'SlipUpload');
      }
    } catch (e) {
      Logger.w("uploadSlipWorker: Cleanup failed: $e", tag: 'SlipUpload');
    }
    List<FileSystemEntity> files = dir.listSync();
    Logger.d("🔵 Total files in directory: ${files.length}", tag: 'SlipUpload'); // กรอง JPG files
    List<FileSystemEntity> jpgFiles = files.where((file) => file.path.toLowerCase().endsWith('.jpg')).toList();

    // ✅ FIX: ข้ามไฟล์ที่มี PENDING_ prefix (ยังไม่พร้อม upload)
    // ไฟล์เหล่านี้จะถูก rename เมื่อ saveTransaction สำเร็จแล้ว
    jpgFiles = jpgFiles.where((file) {
      final fileName = file.path.replaceAll("\\", "/").split("/").last;
      return !fileName.startsWith("PENDING_");
    }).toList();

    Logger.i("🔵 Found ${jpgFiles.length} JPG files to process", tag: 'SlipUpload');

    if (jpgFiles.isEmpty) {
      Logger.d('uploadSlipWorker: No slip files to upload', tag: 'SlipUpload');
      return;
    }

    // ✅ FIX: จำกัดจำนวนไฟล์ต่อรอบ (ป้องกัน worker ทำงานนานเกินไป)
    const int maxFilesPerBatch = 10;
    if (jpgFiles.length > maxFilesPerBatch) {
      Logger.w("uploadSlipWorker: Too many files (${jpgFiles.length}), processing first $maxFilesPerBatch", tag: 'SlipUpload');

      // เรียงตามเวลา modified (เก่าสุดก่อน)
      jpgFiles.sort((a, b) {
        try {
          final aStat = a.statSync();
          final bStat = b.statSync();
          return aStat.modified.compareTo(bStat.modified);
        } catch (e) {
          return 0;
        }
      });

      jpgFiles = jpgFiles.take(maxFilesPerBatch).toList();
      Logger.i("uploadSlipWorker: Processing oldest $maxFilesPerBatch files", tag: 'SlipUpload');
    }

    // List all files for debugging
    for (var file in jpgFiles) {
      String fileName = file.path.replaceAll("\\", "/").split("/").last;
      Logger.d("🔵 File: $fileName", tag: 'SlipUpload');
    }

    int successCount = 0;
    int failCount = 0;
    const int maxRetries = 3;
    const Duration uploadTimeout = Duration(seconds: 30);

    for (var file in jpgFiles) {
      if (file is File) {
        // แยก try-catch สำหรับแต่ละไฟล์ เพื่อไม่ให้ error ไฟล์หนึ่งกระทบไฟล์อื่น
        try {
          String fileName = file.path.replaceAll("\\", "/").split("/").last;

          // Validate file name format
          if (!fileName.contains('.')) {
            Logger.w('uploadSlipWorker: Invalid filename format - $fileName', tag: 'SlipUpload');
            continue;
          }
          String docNo = fileName.split(".").first;

          // ดึง memberPinCode และ isBCMember จากชื่อไฟล์
          // Format BC Member: docNo_lineUid_BC_timestamp.jpg
          // Format ระบบเดิม: docNo_memberPinCode_timestamp.jpg
          // Format ไม่มีสมาชิก: docNo_timestamp.jpg
          String memberPinCode = "";
          bool isBCMemberFromFile = false;

          if (fileName.contains("_")) {
            List<String> parts = fileName.split(".").first.split("_");
            // parts[0] = docNo
            // parts[1] = memberPinCode หรือ lineUid
            // parts[2] = "BC" (ถ้าเป็น BC Member) หรือ timestamp
            // parts[3] = timestamp (ถ้าเป็น BC Member)
            if (parts.length >= 2) {
              docNo = parts[0];
              // เช็คว่ามี _BC_ flag หรือไม่
              if (parts.length >= 3 && parts[2] == "BC") {
                // BC Member: docNo_lineUid_BC_timestamp.jpg
                memberPinCode = parts[1];
                isBCMemberFromFile = true;
              } else if (parts.length >= 3) {
                // ระบบเดิม: docNo_memberPinCode_timestamp.jpg
                memberPinCode = parts[1];
                isBCMemberFromFile = false;
              }
            }
          }

          String orderDateTime = DateTime.now().toString();
          // convert to yyyy-MM-dd
          orderDateTime = orderDateTime.split(" ").first;
          Logger.d("uploadSlipWorker: Processing $fileName (docNo: $docNo, member: $memberPinCode)", tag: 'SlipUpload');

          // ✅ FIX: ตรวจสอบไฟล์ก่อน upload
          // 1. เช็คว่าไฟล์ยังอยู่
          if (!await file.exists()) {
            Logger.w("uploadSlipWorker: File not found - $fileName", tag: 'SlipUpload');
            continue;
          }

          // 2. เช็ค file size
          final fileSize = await file.length();
          Logger.d("🔵 File size: $fileSize bytes", tag: 'SlipUpload');

          if (fileSize == 0) {
            Logger.w("uploadSlipWorker: Empty file detected - $fileName", tag: 'SlipUpload');
            await file.delete();
            Logger.w("uploadSlipWorker: Deleted empty file - $fileName", tag: 'SlipUpload');
            continue;
          }

          if (fileSize > 10 * 1024 * 1024) {
            // ไฟล์ใหญ่เกิน 10 MB (ผิดปกติ!)
            Logger.w("uploadSlipWorker: File too large (${fileSize} bytes) - $fileName", tag: 'SlipUpload');
            await file.delete();
            Logger.w("uploadSlipWorker: Deleted oversized file - $fileName", tag: 'SlipUpload');
            global.sendErrorToDevTeam("Slip file too large: $fileName (${fileSize} bytes)");
            continue;
          }

          // 3. เช็คอายุไฟล์
          final fileStats = await file.stat();
          final fileAge = DateTime.now().difference(fileStats.modified);
          Logger.d("🔵 File age: ${fileAge.inHours} hours", tag: 'SlipUpload');

          if (fileAge.inDays > 30) {
            // ไฟล์เก่ามาก (> 30 วัน) - ลบทิ้งเลย
            Logger.w("uploadSlipWorker: File too old (${fileAge.inDays} days) - $fileName", tag: 'SlipUpload');
            await file.delete();
            Logger.w("uploadSlipWorker: Deleted old file - $fileName", tag: 'SlipUpload');
            continue;
          }

          // Retry logic with exponential backoff
          bool uploadSuccess = false;
          int retryCount = 0;

          while (!uploadSuccess && retryCount < maxRetries) {
            try {
              Logger.d("🔵 Upload attempt ${retryCount + 1}/$maxRetries - $fileName", tag: 'SlipUpload');

              // upload slip with timeout
              var uploadResult = await api
                  .uploadSlip(
                mode: 0, // 0=upload slip 1=upload QR slip
                posId: global.deviceConfig.orderStationCode,
                slipPath: file.path,
                fileName: fileName,
                docDate: orderDateTime,
                docNo: docNo,
                machineCode: global.deviceConfig.orderStationCode,
                branchCode: global.deviceConfig.branchId,
                zoneGroupNumber: "XX",
              )
                  .timeout(
                uploadTimeout,
                onTimeout: () {
                  throw TimeoutException('Upload slip timeout after ${uploadTimeout.inSeconds}s');
                },
              );

              Logger.d("🔵 Upload result: success=${uploadResult.success}, message=${uploadResult.message}", tag: 'SlipUpload');

              if (uploadResult.success) {
                uploadSuccess = true;
                successCount++;
                Logger.i("uploadSlipWorker: Upload success - $fileName (attempt ${retryCount + 1})", tag: 'SlipUpload'); // ส่ง receipt ไปยัง member (ถ้ามี)
                if (memberPinCode.isNotEmpty) {
                  try {
                    String receiptUri = uploadResult.data["uri"] ?? "";
                    if (receiptUri.isNotEmpty) {
                      // ✅ BC Member: ใช้ isBCMemberFromFile จาก filename แทน global
                      // เพราะ global อาจเปลี่ยนไปแล้วตอน upload ทำงาน
                      if (isBCMemberFromFile) {
                        await api
                            .sendBCMemberReceipt(
                          lineUid: memberPinCode,
                          imageUrl: receiptUri,
                        )
                            .timeout(
                          Duration(seconds: 10),
                          onTimeout: () {
                            throw TimeoutException('sendBCMemberReceipt timeout');
                          },
                        );
                        Logger.i("uploadSlipWorker: sendBCMemberReceipt success - $memberPinCode", tag: 'SlipUpload');
                      } else {
                        await api
                            .sendReceipt(
                          pin: memberPinCode,
                          shopId: global.deviceConfig.shopId,
                          receiptUrl: receiptUri,
                        )
                            .timeout(
                          Duration(seconds: 10),
                          onTimeout: () {
                            throw TimeoutException('sendReceipt timeout');
                          },
                        );
                        Logger.i("uploadSlipWorker: sendReceipt success - $memberPinCode", tag: 'SlipUpload');
                      }
                    }
                  } catch (sendError) {
                    Logger.e("uploadSlipWorker: sendReceipt failed - $memberPinCode", error: sendError, tag: 'SlipUpload');
                    // ไม่ต้อง fail ถ้า sendReceipt ไม่สำเร็จ เพราะ upload สำเร็จแล้ว
                  }
                }

                // ลบไฟล์หลัง upload สำเร็จ
                await file.delete();
              } else {
                Logger.w("uploadSlipWorker: Upload failed (attempt ${retryCount + 1}) - $fileName, reason: ${uploadResult.message}", tag: 'SlipUpload');
              }
            } on TimeoutException catch (e) {
              Logger.w('uploadSlipWorker: Timeout (attempt ${retryCount + 1}) - $fileName: $e', tag: 'SlipUpload');
            } catch (uploadError) {
              Logger.w('uploadSlipWorker: Error (attempt ${retryCount + 1}) - $fileName: $uploadError', tag: 'SlipUpload');
            }

            retryCount++;
            if (!uploadSuccess && retryCount < maxRetries) {
              // Exponential backoff: 2s, 4s, 8s
              int delaySeconds = 2 << (retryCount - 1);
              Logger.d('uploadSlipWorker: Waiting ${delaySeconds}s before retry...', tag: 'SlipUpload');
              await Future.delayed(Duration(seconds: delaySeconds));
            }
          }
          if (!uploadSuccess) {
            failCount++;
            Logger.w("uploadSlipWorker: Upload failed after $maxRetries attempts - $fileName", tag: 'SlipUpload');

            // ✅ FIX: ลบไฟล์ที่ fail เพื่อไม่ให้ติดวนลูป
            // ตรวจสอบว่าไฟล์เก่าหรือไม่ (> 7 วัน)
            try {
              final fileStats = await file.stat();
              final fileAge = DateTime.now().difference(fileStats.modified);

              if (fileAge.inDays > 7) {
                // ไฟล์เก่ามาก (> 7 วัน) - ลบทิ้ง
                await file.delete();
                Logger.w("uploadSlipWorker: Deleted old failed file (${fileAge.inDays} days old) - $fileName", tag: 'SlipUpload');
              } else if (fileAge.inHours > 24) {
                // ไฟล์เก่า 1-7 วัน - ส่ง error report แล้วลบ
                global.sendErrorToDevTeam("Slip upload failed permanently: $fileName (${fileAge.inDays} days old)");
                await file.delete();
                Logger.w("uploadSlipWorker: Deleted failed file after reporting (${fileAge.inDays} days old) - $fileName", tag: 'SlipUpload');
              } else {
                // ไฟล์ใหม่ (< 24 ชม.) - เก็บไว้ลองใหม่รอบถัดไป
                Logger.i("uploadSlipWorker: Keeping recent failed file for retry (${fileAge.inHours} hours old) - $fileName", tag: 'SlipUpload');
              }
            } catch (deleteError) {
              Logger.e("uploadSlipWorker: Failed to handle failed file - $fileName", error: deleteError, tag: 'SlipUpload');
            }
          }
        } catch (fileError, fileStack) {
          failCount++;
          String fileName = file.path.replaceAll("\\", "/").split("/").last;
          Logger.e("uploadSlipWorker: Error processing $fileName", error: fileError, stackTrace: fileStack, tag: 'SlipUpload');

          // ✅ FIX: ถ้าไฟล์ corrupted หรือ error - ลบทิ้งเลย
          try {
            if (await file.exists()) {
              await file.delete();
              Logger.w("uploadSlipWorker: Deleted corrupted/error file - $fileName", tag: 'SlipUpload');
            }
          } catch (deleteError) {
            Logger.e("uploadSlipWorker: Failed to delete error file - $fileName", error: deleteError, tag: 'SlipUpload');
          }
        }

        // รอ 1 วินาทีก่อน upload ไฟล์ถัดไป (ป้องกัน rate limiting)
        if (files.indexOf(file) < files.length - 1) {
          await Future.delayed(Duration(seconds: 1));
        }
      }
    }

    if (failCount > 0) {
      Logger.w("uploadSlipWorker: Completed - success: $successCount, failed: $failCount", tag: 'SlipUpload');
    } else if (successCount > 0) {
      Logger.i("uploadSlipWorker: Completed - all $successCount files uploaded successfully", tag: 'SlipUpload');
    }

    // หลังจาก upload mode=0 เสร็จแล้ว ให้ upload mode=1 (QR payment proof) ต่อ
    await uploadQrPaymentProofWorker();
  } catch (e, s) {
    Logger.e("uploadSlipWorker: Critical error", error: e, stackTrace: s, tag: 'SlipUpload');
    global.sendErrorToDevTeam("uploadSlipWorker : $e");
  } finally {
    _isUploadingSlip = false;
  }
}

// Global flag to prevent concurrent QR payment proof uploads
bool _isUploadingQrProof = false;

/// Upload QR payment proof images (mode=1) หลังจาก upload slip (mode=0) เสร็จแล้ว
/// จะ upload เฉพาะไฟล์ที่ไม่มี PENDING_ prefix (รอให้ sale-invoice บันทึกสำเร็จก่อน)
Future<void> uploadQrPaymentProofWorker() async {
  // ป้องกัน concurrent execution
  if (_isUploadingQrProof) {
    Logger.w('uploadQrPaymentProofWorker: Already running, skipping...', tag: 'QrProofUpload');
    return;
  }

  Logger.i("🟢 uploadQrPaymentProofWorker: START", tag: 'QrProofUpload');

  _isUploadingQrProof = true;

  try {
    // ตรวจสอบ internet connection
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      Logger.w('uploadQrPaymentProofWorker: No internet connection, skipping...', tag: 'QrProofUpload');
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    Directory qrProofDir = Directory('${directory.path}/${global.qrPaymentProofPath}');

    Logger.d("🟢 QR proof directory: ${qrProofDir.path}", tag: 'QrProofUpload');

    if (!qrProofDir.existsSync()) {
      Logger.d('uploadQrPaymentProofWorker: Directory does not exist', tag: 'QrProofUpload');
      return;
    }

    // ดึงไฟล์ JPG ทั้งหมด
    List<FileSystemEntity> files = qrProofDir.listSync();
    List<FileSystemEntity> jpgFiles = files.where((file) => file.path.toLowerCase().endsWith('.jpg')).toList();

    Logger.d("🟢 Total JPG files in qrpaymentproof: ${jpgFiles.length}", tag: 'QrProofUpload');

    // Log all files including PENDING
    for (var file in jpgFiles) {
      final fileName = file.path.replaceAll("\\", "/").split("/").last;
      Logger.d("🟢 Found file: $fileName (PENDING: ${fileName.startsWith("PENDING_")})", tag: 'QrProofUpload');
    }

    // ✅ ข้ามไฟล์ที่มี PENDING_ prefix (รอให้ sale-invoice บันทึกสำเร็จก่อน)
    // ไฟล์เหล่านี้จะถูก rename เมื่อ saveTransaction สำเร็จแล้ว
    jpgFiles = jpgFiles.where((file) {
      final fileName = file.path.replaceAll("\\", "/").split("/").last;
      return !fileName.startsWith("PENDING_");
    }).toList();

    Logger.i("🟢 Found ${jpgFiles.length} QR proof files to process (excluding PENDING)", tag: 'QrProofUpload');

    if (jpgFiles.isEmpty) {
      Logger.d('uploadQrPaymentProofWorker: No QR proof files to upload', tag: 'QrProofUpload');
      return;
    }

    // จำกัดจำนวนไฟล์ต่อรอบ
    const int maxFilesPerBatch = 10;
    if (jpgFiles.length > maxFilesPerBatch) {
      jpgFiles.sort((a, b) {
        try {
          final aStat = a.statSync();
          final bStat = b.statSync();
          return aStat.modified.compareTo(bStat.modified);
        } catch (e) {
          return 0;
        }
      });
      jpgFiles = jpgFiles.take(maxFilesPerBatch).toList();
    }

    int successCount = 0;
    int failCount = 0;
    const int maxRetries = 3;
    const Duration uploadTimeout = Duration(seconds: 30);

    for (var file in jpgFiles) {
      if (file is File) {
        try {
          String fileName = file.path.replaceAll("\\", "/").split("/").last;

          if (!fileName.contains('.')) {
            Logger.w('uploadQrPaymentProofWorker: Invalid filename format - $fileName', tag: 'QrProofUpload');
            continue;
          }

          // ดึง docNo จากชื่อไฟล์
          // Format ใหม่: {docNo}_{timestamp}.jpg เช่น 95-2512170011_1765983565198.jpg (เหมือน slip)
          // Format เก่า (fallback): QR_{orderId}_{timestamp}.jpg
          String docNo = "";
          if (fileName.startsWith("QR_")) {
            // Format เก่า: QR_orderId_timestamp.jpg
            List<String> parts = fileName.replaceFirst("QR_", "").split("_");
            if (parts.isNotEmpty) {
              docNo = parts[0];
            }
          } else {
            // Format ใหม่: docNo_timestamp.jpg (เหมือน slip)
            // docNo อาจมี - เช่น 95-2512170011
            String nameWithoutExt = fileName.split(".").first;
            int lastUnderscore = nameWithoutExt.lastIndexOf("_");
            if (lastUnderscore > 0) {
              docNo = nameWithoutExt.substring(0, lastUnderscore);
            } else {
              docNo = nameWithoutExt;
            }
          }

          String orderDateTime = DateTime.now().toString().split(" ").first;
          Logger.d("uploadQrPaymentProofWorker: Processing $fileName (docNo: $docNo)", tag: 'QrProofUpload');

          // ตรวจสอบไฟล์
          if (!await file.exists()) {
            Logger.w("uploadQrPaymentProofWorker: File not found - $fileName", tag: 'QrProofUpload');
            continue;
          }

          final fileSize = await file.length();
          if (fileSize == 0) {
            await file.delete();
            Logger.w("uploadQrPaymentProofWorker: Deleted empty file - $fileName", tag: 'QrProofUpload');
            continue;
          }

          if (fileSize > 10 * 1024 * 1024) {
            await file.delete();
            Logger.w("uploadQrPaymentProofWorker: Deleted oversized file - $fileName", tag: 'QrProofUpload');
            continue;
          }

          // ตรวจสอบอายุไฟล์
          final fileStats = await file.stat();
          final fileAge = DateTime.now().difference(fileStats.modified);

          if (fileAge.inDays > 30) {
            await file.delete();
            Logger.w("uploadQrPaymentProofWorker: Deleted old file (${fileAge.inDays} days) - $fileName", tag: 'QrProofUpload');
            continue;
          }

          // Retry logic
          bool uploadSuccess = false;
          int retryCount = 0;

          while (!uploadSuccess && retryCount < maxRetries) {
            try {
              Logger.d("🟢 Upload attempt ${retryCount + 1}/$maxRetries - $fileName", tag: 'QrProofUpload');

              // Upload with mode=1 (QR payment proof)
              var uploadResult = await api
                  .uploadSlip(
                mode: 1, // 1 = QR payment proof image
                posId: global.deviceConfig.orderStationCode,
                slipPath: file.path,
                fileName: fileName,
                docDate: orderDateTime,
                docNo: docNo,
                machineCode: global.deviceConfig.orderStationCode,
                branchCode: global.deviceConfig.branchId,
                zoneGroupNumber: "XX",
              )
                  .timeout(
                uploadTimeout,
                onTimeout: () {
                  throw TimeoutException('Upload QR proof timeout after ${uploadTimeout.inSeconds}s');
                },
              );

              Logger.d("🟢 Upload result: success=${uploadResult.success}, message=${uploadResult.message}", tag: 'QrProofUpload');

              if (uploadResult.success) {
                uploadSuccess = true;
                successCount++;
                Logger.i("uploadQrPaymentProofWorker: Upload success - $fileName", tag: 'QrProofUpload');

                // ลบไฟล์หลัง upload สำเร็จ
                await file.delete();
              } else {
                Logger.w("uploadQrPaymentProofWorker: Upload failed - $fileName, reason: ${uploadResult.message}", tag: 'QrProofUpload');
              }
            } on TimeoutException catch (e) {
              Logger.w('uploadQrPaymentProofWorker: Timeout - $fileName: $e', tag: 'QrProofUpload');
            } catch (uploadError) {
              Logger.w('uploadQrPaymentProofWorker: Error - $fileName: $uploadError', tag: 'QrProofUpload');
            }

            retryCount++;
            if (!uploadSuccess && retryCount < maxRetries) {
              int delaySeconds = 2 << (retryCount - 1);
              await Future.delayed(Duration(seconds: delaySeconds));
            }
          }

          if (!uploadSuccess) {
            failCount++;
            Logger.w("uploadQrPaymentProofWorker: Upload failed after $maxRetries attempts - $fileName", tag: 'QrProofUpload');

            // ลบไฟล์เก่าที่ fail
            try {
              if (fileAge.inDays > 7) {
                await file.delete();
                Logger.w("uploadQrPaymentProofWorker: Deleted old failed file - $fileName", tag: 'QrProofUpload');
              } else if (fileAge.inHours > 24) {
                global.sendErrorToDevTeam("QR proof upload failed: $fileName (${fileAge.inDays} days old)");
                await file.delete();
              }
            } catch (deleteError) {
              Logger.e("uploadQrPaymentProofWorker: Failed to handle failed file - $fileName", error: deleteError, tag: 'QrProofUpload');
            }
          }
        } catch (fileError, fileStack) {
          failCount++;
          String fileName = file.path.replaceAll("\\", "/").split("/").last;
          Logger.e("uploadQrPaymentProofWorker: Error processing $fileName", error: fileError, stackTrace: fileStack, tag: 'QrProofUpload');

          try {
            if (await file.exists()) {
              await file.delete();
            }
          } catch (deleteError) {
            Logger.e("uploadQrPaymentProofWorker: Failed to delete error file", error: deleteError, tag: 'QrProofUpload');
          }
        }

        // รอ 1 วินาทีก่อน upload ไฟล์ถัดไป
        if (jpgFiles.indexOf(file) < jpgFiles.length - 1) {
          await Future.delayed(Duration(seconds: 1));
        }
      }
    }

    if (failCount > 0) {
      Logger.w("uploadQrPaymentProofWorker: Completed - success: $successCount, failed: $failCount", tag: 'QrProofUpload');
    } else if (successCount > 0) {
      Logger.i("uploadQrPaymentProofWorker: Completed - all $successCount files uploaded successfully", tag: 'QrProofUpload');
    }
  } catch (e, s) {
    Logger.e("uploadQrPaymentProofWorker: Critical error", error: e, stackTrace: s, tag: 'QrProofUpload');
    global.sendErrorToDevTeam("uploadQrPaymentProofWorker : $e");
  } finally {
    _isUploadingQrProof = false;
  }
}
