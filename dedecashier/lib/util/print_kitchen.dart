import 'dart:convert';
import 'package:dedecashier/db/kitchen_helper.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/form_design_struct.dart';
import 'package:dedecashier/model/objectbox/kitchen_struct.dart';
import 'package:dedecashier/model/objectbox/order_temp_struct.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:dedecashier/services/print_process.dart';
import 'package:dedecashier/util/printer.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/features/pos/presentation/screens/pos_print.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

Future<void> sendOrderToKitchen({
  required String orderId,
  required List<OrderTempDataModel> orderList,
}) async {
  // ✅ Performance monitoring (Debug mode only)
  Stopwatch? stopwatch;
  if (kDebugMode) {
    stopwatch = Stopwatch()..start();
  }

  String tableOrDeliveryNumber = "โต๊ะ $orderId";
  final resultTable = global.objectBoxStore
      .box<TableProcessObjectBoxStruct>()
      .query(TableProcessObjectBoxStruct_.number.equals(orderId))
      .build()
      .findFirst();
  if (resultTable != null) {
    if (resultTable.delivery_code.isNotEmpty) {
      tableOrDeliveryNumber =
          "${resultTable.delivery_code} : ${resultTable.delivery_number}";
    }
  }

  double fontSize = 40;

  // ✅ Cache: Pre-load product barcodes to avoid redundant DB queries (saves ~80% DB calls)
  Map<String, ProductBarcodeObjectBoxStruct?> barcodeCache = {};
  for (var order in orderList) {
    if (!barcodeCache.containsKey(order.barcode)) {
      barcodeCache[order.barcode] = await global.productBarcodeHelper
          .selectByBarcodeFirst(order.barcode);
    }
  }

  // ✅ Cache: Pre-decode JSON options to avoid redundant jsonDecode calls (saves ~70% decode time)
  Map<String, List<OrderProductOptionModel>> optionsCache = {};
  for (var order in orderList) {
    if (order.optionSelected.isNotEmpty &&
        !optionsCache.containsKey(order.orderGuid)) {
      try {
        optionsCache[order.orderGuid] =
            (jsonDecode(order.optionSelected) as List)
                .map<OrderProductOptionModel>(
                  (item) => OrderProductOptionModel.fromJson(item),
                )
                .toList();
      } catch (e) {
        AppLogger.error('[PrintKitchen] ⚠️ JSON decode error: $e');
        optionsCache[order.orderGuid] = [];
      }
    }
  }

  // ✅ Optimization: Create Set for O(1) lookup instead of O(n) indexWhere
  Set<String> orderBarcodeSet = orderList.map((e) => e.barcode).toSet();

  // แบ่งครัว ค้นหาจาก Order ว่าอยู่ครัวไหนบ้าง
  List<KitchenObjectBoxStruct> kitchenList = KitchenHelper().getAll();
  List<String> kitchenCodeActiveList = [];
  // ✅ Optimization: Use Set for kitchen codes
  Set<String> kitchenCodeSet = {};
  for (var kitchen in kitchenList) {
    for (var barcode in kitchen.products) {
      // ✅ Use Set lookup - O(1) instead of indexWhere O(n)
      if (orderBarcodeSet.contains(barcode)) {
        if (!kitchenCodeSet.contains(kitchen.code)) {
          kitchenCodeActiveList.add(kitchen.code);
          kitchenCodeSet.add(kitchen.code);
        }
        break;
      }
    }
  }

  // ✅ Optimization: Create Map for kitchen lookup - O(1) instead of indexWhere O(n)
  Map<String, KitchenObjectBoxStruct> kitchenMap = {
    for (var k in kitchenList) k.code: k,
  };

  // update KDS
  final box = global.objectBoxStore.box<OrderTempObjectBoxStruct>();
  Map<String, List<Map<String, dynamic>>> ordersByKitchen = {};

  for (var kitchenCode in kitchenCodeActiveList) {
    // ✅ Use Map lookup - O(1) instead of indexWhere O(n)
    KitchenObjectBoxStruct kitchen = kitchenMap[kitchenCode]!;
    List<Map<String, dynamic>> kitchenOrders = [];

    for (var order in orderList) {
      if (kitchen.products.contains(order.barcode) == true) {
        var orderTempUpdate = box
            .query(OrderTempObjectBoxStruct_.orderGuid.equals(order.orderGuid))
            .build()
            .findFirst();
        if (orderTempUpdate != null) {
          orderTempUpdate.kdsId = kitchen.code;
          orderTempUpdate.kdsSuccess = false;
          orderTempUpdate.kdsSuccessTime = DateTime.now();
          box.put(orderTempUpdate, mode: PutMode.update);

          // Collect order data for WebSocket broadcast
          kitchenOrders.add({
            'orderGuid': order.orderGuid,
            'barcode': order.barcode,
            'qty': order.qty,
            'orderId': order.orderId,
            'orderDateTime': order.orderDateTime.toIso8601String(),
            'price': order.price,
            'amount': order.amount,
            'optionSelected': order.optionSelected,
            'remark': order.remark,
            'isTakeAway': order.isTakeAway,
            'orderEmployeeCode': order.orderEmployeeCode,
            'orderEmployeeDetail': order.orderEmployeeDetail,
          });
        }
      }
    }

    if (kitchenOrders.isNotEmpty) {
      ordersByKitchen[kitchenCode] = kitchenOrders;
    }
  }

  // ✅ Broadcast new orders to KDS via WebSocket
  if (ordersByKitchen.isNotEmpty && global.wsServer != null) {
    global.wsServer!.broadcast({
      'type': 'broadcast',
      'broadcastType': 'new_kitchen_orders',
      'data': {
        'orderId': orderId,
        'tableOrDeliveryNumber': tableOrDeliveryNumber,
        'ordersByKitchen': ordersByKitchen,
        'timestamp': DateTime.now().toIso8601String(),
      },
    });

    if (kDebugMode) {
      AppLogger.info('[PrintKitchen] 📡 Broadcast new orders to KDS for table: $tableOrDeliveryNumber');
    }
  }

  // พิมพ์
  for (var kitchenCode in kitchenCodeActiveList) {
    List<OrderTempDataModel> orderListForSummery = [];
    // ✅ Use Map lookup - O(1) instead of indexWhere O(n)
    KitchenObjectBoxStruct kitchen = kitchenMap[kitchenCode]!;

    int printerIndex = -1;
    for (var printer in global.printerLocalStrongData) {
      if (printer.code == kitchenCode) {
        printerIndex = global.printerLocalStrongData.indexOf(printer);
        break;
      }
    }
    if (printerIndex != -1) {
      {
        // พิมพ์รายการแบบรวมใบเดียว
        bool found = false;
        for (var order in orderList) {
          if (kitchen.products.contains(order.barcode) == true) {
            // ✅ Use cache instead of DB query
            ProductBarcodeObjectBoxStruct? findBarcode =
                barcodeCache[order.barcode];
            if (findBarcode != null && findBarcode.issplitunitprint == false) {
              found = true;
              break;
            }
          }
        }
        if (found) {
          // ⭐ รวบรวมชื่อสินค้าสำหรับ metadata
          List<String> productNamesForPrint = [];
          for (var order in orderList) {
            if (kitchen.products.contains(order.barcode) == true) {
              ProductBarcodeObjectBoxStruct? findBarcode = barcodeCache[order.barcode];
              if (findBarcode != null) {
                productNamesForPrint.add(global.getNameFromJsonLanguage(findBarcode.names, global.userScreenLanguage));
              }
            }
          }

          PrinterClass printer = PrinterClass(
            printerIndex: printerIndex,
            qrCode: "",
            docDate: DateTime.now(),
            docNo: "",
            productNames: productNamesForPrint, // ⭐ ส่งชื่อสินค้า
          );
          // Reset Printer
          printer.addCommand(PosPrintBillCommandModel(mode: 0));
          printer.addCommand(
            PosPrintBillCommandModel(
              mode: 2,
              posStyles: const PosStyles(bold: true),
              columns: [
                FormDesignColumnModel(
                  font_size: fontSize * 2,
                  width: 1,
                  text: tableOrDeliveryNumber,
                  text_align: PrintColumnAlign.center,
                ),
              ],
            ),
          );
          for (var order in orderList) {
            orderListForSummery.add(order);
            if (kitchen.products.contains(order.barcode) == true) {
              // ✅ Use cache instead of DB query
              ProductBarcodeObjectBoxStruct? findBarcode =
                  barcodeCache[order.barcode];
              if (findBarcode != null) {
                String name = "";
                if (order.isTakeAway == 1) {
                  name += "* ${global.language("กลับบ้าน")} * ";
                }
                name +=
                    "${global.getNameFromJsonLanguage(findBarcode.names, global.userScreenLanguage)}-${global.getNameFromJsonLanguage(findBarcode.unit_names, global.userScreenLanguage)}";
                printer.addCommand(
                  PosPrintBillCommandModel(
                    mode: 2,
                    posStyles: const PosStyles(bold: true),
                    columns: [
                      FormDesignColumnModel(
                        font_size: fontSize,
                        width: 4,
                        text: name,
                        text_align: PrintColumnAlign.left,
                      ),
                      FormDesignColumnModel(
                        font_size: fontSize,
                        width: 1,
                        text: global.moneyFormat.format(order.qty),
                        text_align: PrintColumnAlign.right,
                      ),
                    ],
                  ),
                );
                if (order.remark.trim().isNotEmpty) {
                  printer.addCommand(
                    PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: true),
                      columns: [
                        FormDesignColumnModel(
                          font_size: fontSize,
                          width: 1,
                          text: "x หมายเหตุ x : ${order.remark}",
                          text_align: PrintColumnAlign.left,
                        ),
                      ],
                    ),
                  );
                }
                if (order.optionSelected.isNotEmpty) {
                  // ✅ Use cache instead of jsonDecode
                  List<OrderProductOptionModel> options =
                      optionsCache[order.orderGuid] ?? [];
                  for (var option in options) {
                    bool optionPrint = false;
                    for (var choice in option.choices) {
                      if (choice.selected) {
                        if (optionPrint == false) {
                          printer.addCommand(
                            PosPrintBillCommandModel(
                              mode: 2,
                              posStyles: const PosStyles(bold: false),
                              columns: [
                                FormDesignColumnModel(
                                  font_size: fontSize,
                                  width: 1,
                                  text: " * ${option.names[0].name}",
                                  text_align: PrintColumnAlign.left,
                                ),
                              ],
                            ),
                          );
                          optionPrint = true;
                        }
                        printer.addCommand(
                          PosPrintBillCommandModel(
                            mode: 2,
                            posStyles: const PosStyles(bold: false),
                            columns: [
                              FormDesignColumnModel(
                                font_size: fontSize,
                                width: 1,
                                text: "   - ${choice.names[0].name}",
                                text_align: PrintColumnAlign.left,
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  }
                }
                printer.addCommand(
                  PosPrintBillCommandModel(
                    mode: 2,
                    posStyles: const PosStyles(bold: false),
                    columns: [
                      FormDesignColumnModel(
                        font_size: fontSize / 1.5,
                        width: 1,
                        text: order.orderEmployeeDetail,
                        text_align: PrintColumnAlign.left,
                      ),
                    ],
                  ),
                );
              }
            }
          }
          printer.addCommand(
            PosPrintBillCommandModel(
              mode: 2,
              posStyles: const PosStyles(bold: true),
              columns: [
                FormDesignColumnModel(
                  font_size: fontSize / 1.5,
                  width: 1,
                  text:
                      "${global.getNameFromJsonLanguage(kitchen.names, global.userScreenLanguage)} : เวลา : ${DateFormat("HH:mm").format(DateTime.now())}",
                  text_align: PrintColumnAlign.center,
                ),
              ],
            ),
          );
          await printer.sendToPrinter(printerIndex: printerIndex);
        }
        if (orderListForSummery.isNotEmpty) {
          // พิมพ์ใบสรุปแยกตามครัว
          /*await printOrderSummery(
              orderId: orderId,
              orderList: orderListForSummery,
              printerIndex: printerIndex,
              bottomWord: global.getNameFromJsonLanguage(
                  kitchen.names, global.userScreenLanguage));*/
        }
      }
      {
        bool found = false;
        List<OrderTempDataModel> orderListForSummery = [];
        for (var order in orderList) {
          if (kitchen.products.contains(order.barcode) == true) {
            // ✅ Use cache instead of DB query
            ProductBarcodeObjectBoxStruct? findBarcode =
                barcodeCache[order.barcode];
            if (findBarcode != null && findBarcode.issplitunitprint == true) {
              found = true;
              break;
            }
          }
        }
        if (found) {
          // พิมพ์รายการแบบแยกแต่ละรายการ
          for (var order in orderList) {
            if (kitchen.products.contains(order.barcode) == true) {
              // ✅ Use cache instead of DB query
              ProductBarcodeObjectBoxStruct? findBarcode =
                  barcodeCache[order.barcode];
              orderListForSummery.add(order);
              double orderQty = order.qty;
              if (findBarcode != null && findBarcode.issplitunitprint == true) {
                int loopQty = orderQty.ceil();
                // ⭐ ชื่อสินค้าสำหรับ split unit print
                String productName = global.getNameFromJsonLanguage(findBarcode.names, global.userScreenLanguage);
                for (int loop = 0; loop < loopQty; loop++) {
                  PrinterClass printer = PrinterClass(
                    printerIndex: printerIndex,
                    qrCode: "",
                    docDate: DateTime.now(),
                    docNo: "",
                    productNames: [productName], // ⭐ ส่งชื่อสินค้า
                  );
                  // Reset Printer
                  printer.addCommand(PosPrintBillCommandModel(mode: 0));
                  // qr code สำหรับ checker
                  printer.addCommand(
                    PosPrintBillCommandModel(mode: 9, qrCode: order.orderGuid),
                  );
                  printer.addCommand(
                    PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: true),
                      columns: [
                        FormDesignColumnModel(
                          font_size: fontSize * 1.25,
                          width: 1,
                          text:
                              "$tableOrDeliveryNumber : ${DateFormat("HH:mm").format(DateTime.now())}",
                          text_align: PrintColumnAlign.center,
                        ),
                      ],
                    ),
                  );
                  if (order.isTakeAway == 1) {
                    printer.addCommand(
                      PosPrintBillCommandModel(
                        mode: 2,
                        posStyles: const PosStyles(bold: true),
                        columns: [
                          FormDesignColumnModel(
                            font_size: fontSize,
                            width: 1,
                            text: "* ${global.language("กลับบ้าน")} * ",
                            text_align: PrintColumnAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  printer.addCommand(
                    PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: true),
                      columns: [
                        FormDesignColumnModel(
                          font_size: fontSize,
                          width: 4,
                          text:
                              "${global.getNameFromJsonLanguage(findBarcode.names, global.userScreenLanguage)}/${global.getNameFromJsonLanguage(findBarcode.unit_names, global.userScreenLanguage)} @${global.moneyFormat.format(order.price * order.qty)}",
                          text_align: PrintColumnAlign.left,
                        ),
                        FormDesignColumnModel(
                          font_size: fontSize,
                          width: 1,
                          text: global.moneyFormat.format(
                            (orderQty > 1) ? 1 : orderQty,
                          ),
                          text_align: PrintColumnAlign.right,
                        ),
                      ],
                    ),
                  );
                  if (order.remark.trim().isNotEmpty) {
                    printer.addCommand(
                      PosPrintBillCommandModel(
                        mode: 2,
                        posStyles: const PosStyles(bold: true),
                        columns: [
                          FormDesignColumnModel(
                            font_size: fontSize,
                            width: 1,
                            text: "x หมายเหตุ x : ${order.remark}",
                            text_align: PrintColumnAlign.left,
                          ),
                        ],
                      ),
                    );
                  }
                  if (order.optionSelected.isNotEmpty) {
                    // ✅ Use cache instead of jsonDecode
                    List<OrderProductOptionModel> options =
                        optionsCache[order.orderGuid] ?? [];
                    for (var option in options) {
                      bool optionPrint = false;
                      for (var choice in option.choices) {
                        if (choice.selected) {
                          if (optionPrint == false) {
                            printer.addCommand(
                              PosPrintBillCommandModel(
                                mode: 2,
                                posStyles: const PosStyles(bold: false),
                                columns: [
                                  FormDesignColumnModel(
                                    font_size: fontSize,
                                    width: 1,
                                    text: "* ${option.names[0].name}",
                                    text_align: PrintColumnAlign.left,
                                  ),
                                ],
                              ),
                            );
                            optionPrint = true;
                          }
                          String name = " - ${choice.names[0].name}";
                          if (choice.priceValue * order.qty > 0) {
                            name +=
                                " @${global.moneyFormat.format(choice.priceValue * order.qty)}";
                          }
                          printer.addCommand(
                            PosPrintBillCommandModel(
                              mode: 2,
                              posStyles: const PosStyles(bold: false),
                              columns: [
                                FormDesignColumnModel(
                                  font_size: fontSize,
                                  width: 1,
                                  text: name,
                                  text_align: PrintColumnAlign.left,
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    }
                  }
                  printer.addCommand(
                    PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: false),
                      columns: [
                        FormDesignColumnModel(
                          font_size: fontSize / 1.5,
                          width: 1,
                          text: order.orderEmployeeDetail,
                          text_align: PrintColumnAlign.left,
                        ),
                      ],
                    ),
                  );
                  printer.addCommand(
                    PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: true),
                      columns: [
                        FormDesignColumnModel(
                          font_size: fontSize / 1.5,
                          width: 1,
                          text:
                              "${global.getNameFromJsonLanguage(kitchen.names, global.userScreenLanguage)} : เวลา : ${DateFormat("HH:mm").format(DateTime.now())}",
                          text_align: PrintColumnAlign.center,
                        ),
                      ],
                    ),
                  );
                  await printer.sendToPrinter(printerIndex: printerIndex);
                  orderQty = orderQty - 1;
                }
              }
            }
          }
          // พิมพ์ใบสรุปแยกตามครัว
          /*await printOrderSummery(
              orderId: orderId,
              orderList: orderListForSummery,
              printerIndex: printerIndex,
              bottomWord: global.getNameFromJsonLanguage(
                  kitchen.names, global.userScreenLanguage));*/
        }
      }
    }
  }

  // ✅ Log performance (Debug mode only)
  if (kDebugMode && stopwatch != null) {
    stopwatch.stop();
    AppLogger.success(
      '[PrintKitchen] 🖨️ sendOrderToKitchen processed ${orderList.length} orders in ${stopwatch.elapsedMilliseconds}ms',
    );
    if (stopwatch.elapsedMilliseconds > 3000) {
      AppLogger.warning('[PrintKitchen] ⚠️ Slow kitchen print detected!');
    }
  }
}

Future<void> sendOrderCancelToKitchen({
  required String orderId,
  required List<OrderTempDataModel> orderList,
}) async {
  String tableOrDeliveryNumber = orderId;
  double fontSize = 40;
  // แบ่งครัว ค้นหาจาก Order ว่าอยู่ครัวไหนบ้าง
  List<KitchenObjectBoxStruct> kitchenList = KitchenHelper().getAll();
  List<String> kitchenCodeActiveList = [];
  for (var kitchen in kitchenList) {
    for (var barcode in kitchen.products) {
      if (orderList.indexWhere((element) => element.barcode == barcode) != -1) {
        if (kitchenCodeActiveList.indexWhere(
              (element) => element == kitchen.code,
            ) ==
            -1) {
          kitchenCodeActiveList.add(kitchen.code);
        }
        break;
      }
    }
  }

  // พิมพ์
  for (var kitchenCode in kitchenCodeActiveList) {
    KitchenObjectBoxStruct kitchen =
        kitchenList[kitchenList.indexWhere(
          (element) => element.code == kitchenCode,
        )];

    int printerKitchenIndex = -1;
    for (var printer in global.printerLocalStrongData) {
      if (printer.code == kitchenCode) {
        printerKitchenIndex = global.printerLocalStrongData.indexOf(printer);
        break;
      }
    }
    if (printerKitchenIndex != -1) {
      bool found = false;
      for (var order in orderList) {
        if (kitchen.products.contains(order.barcode) == true) {
          // ค้นหาชื่อสินค้า
          ProductBarcodeObjectBoxStruct? findBarcode = await global
              .productBarcodeHelper
              .selectByBarcodeFirst(order.barcode);
          if (findBarcode != null && findBarcode.issplitunitprint == true) {
            found = true;
            break;
          }
        }
      }
      if (found) {
        // พิมพ์รายการแบบแยกแต่ละรายการ
        for (var order in orderList) {
          if (kitchen.products.contains(order.barcode) == true) {
            // ค้นหาชื่อสินค้า
            ProductBarcodeObjectBoxStruct? findBarcode = await global
                .productBarcodeHelper
                .selectByBarcodeFirst(order.barcode);
            double cancelQty = order.qtyLastCancel;
            if (findBarcode != null && findBarcode.issplitunitprint == true) {
              int loopQty = cancelQty.ceil();
              for (int loop = 0; loop < loopQty; loop++) {
                for (int loopPrint = 0; loopPrint < 2; loopPrint++) {
                  double cancelAmount = 0;
                  String buttonName = (loopPrint == 0)
                      ? "ใบยกเลิก ${global.getNameFromJsonLanguage(kitchen.names, global.userScreenLanguage)}"
                      : "ใบยกเลิก หน้าร้าน";
                  int printerIndex = printerKitchenIndex;
                  if (loopPrint == 1) {
                    // ส่งไปหน้าร้าน
                    for (var printer in global.printerLocalStrongData) {
                      if (printer.code == "printer_config_ticket") {
                        printerIndex = global.printerLocalStrongData.indexOf(
                          printer,
                        );
                        break;
                      }
                    }
                  }
                  PrinterClass printer = PrinterClass(
                    printerIndex: printerIndex,
                    qrCode: "",
                    docDate: DateTime.now(),
                    docNo: "",
                  );
                  // Reset Printer
                  printer.addCommand(PosPrintBillCommandModel(mode: 0));
                  printer.addCommand(
                    PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: true),
                      columns: [
                        FormDesignColumnModel(
                          font_size: fontSize * 2,
                          width: 1,
                          text: "* ยกเลิก *",
                          text_align: PrintColumnAlign.center,
                        ),
                      ],
                    ),
                  );
                  printer.addCommand(
                    PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: true),
                      columns: [
                        FormDesignColumnModel(
                          font_size: fontSize * 2,
                          width: 1,
                          text: "โต๊ะ : $tableOrDeliveryNumber",
                          text_align: PrintColumnAlign.center,
                        ),
                      ],
                    ),
                  );
                  if (order.isTakeAway == 1) {
                    printer.addCommand(
                      PosPrintBillCommandModel(
                        mode: 2,
                        posStyles: const PosStyles(bold: true),
                        columns: [
                          FormDesignColumnModel(
                            font_size: fontSize,
                            width: 1,
                            text: "* ${global.language("กลับบ้าน")} * ",
                            text_align: PrintColumnAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  cancelAmount = cancelAmount + (order.price * order.qty);
                  printer.addCommand(
                    PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: true),
                      columns: [
                        FormDesignColumnModel(
                          font_size: fontSize,
                          width: 4,
                          text:
                              "${global.getNameFromJsonLanguage(findBarcode.names, global.userScreenLanguage)}-${global.getNameFromJsonLanguage(findBarcode.unit_names, global.userScreenLanguage)} @${global.moneyFormat.format(order.price * order.qty)}",
                          text_align: PrintColumnAlign.left,
                        ),
                        FormDesignColumnModel(
                          font_size: fontSize,
                          width: 1,
                          text: global.moneyFormat.format(
                            (cancelQty > 1) ? 1 : cancelQty,
                          ),
                          text_align: PrintColumnAlign.right,
                        ),
                      ],
                    ),
                  );
                  if (order.remark.trim().isNotEmpty) {
                    printer.addCommand(
                      PosPrintBillCommandModel(
                        mode: 2,
                        posStyles: const PosStyles(bold: true),
                        columns: [
                          FormDesignColumnModel(
                            font_size: fontSize,
                            width: 1,
                            text: "x หมายเหตุ x : ${order.remark}",
                            text_align: PrintColumnAlign.left,
                          ),
                        ],
                      ),
                    );
                  }
                  if (order.remarkForCancel.trim().isNotEmpty) {
                    printer.addCommand(
                      PosPrintBillCommandModel(
                        mode: 2,
                        posStyles: const PosStyles(bold: true),
                        columns: [
                          FormDesignColumnModel(
                            font_size: fontSize,
                            width: 1,
                            text: "x สาเหตุ x : ${order.remarkForCancel}",
                            text_align: PrintColumnAlign.left,
                          ),
                        ],
                      ),
                    );
                  }
                  if (order.optionSelected.isNotEmpty) {
                    List<OrderProductOptionModel> options =
                        await jsonDecode(order.optionSelected)
                            .map<OrderProductOptionModel>(
                              (item) => OrderProductOptionModel.fromJson(item),
                            )
                            .toList();
                    for (var option in options) {
                      bool optionPrint = false;
                      for (var choice in option.choices) {
                        if (choice.selected) {
                          if (optionPrint == false) {
                            printer.addCommand(
                              PosPrintBillCommandModel(
                                mode: 2,
                                posStyles: const PosStyles(bold: false),
                                columns: [
                                  FormDesignColumnModel(
                                    font_size: fontSize,
                                    width: 1,
                                    text: "* ${option.names[0].name}",
                                    text_align: PrintColumnAlign.left,
                                  ),
                                ],
                              ),
                            );
                            optionPrint = true;
                          }
                          String name = " - ${choice.names[0].name}";
                          if (choice.priceValue * order.qty > 0) {
                            name +=
                                " @${global.moneyFormat.format(choice.priceValue * order.qty)}";
                          }
                          cancelAmount =
                              cancelAmount + (choice.priceValue * order.qty);
                          printer.addCommand(
                            PosPrintBillCommandModel(
                              mode: 2,
                              posStyles: const PosStyles(bold: false),
                              columns: [
                                FormDesignColumnModel(
                                  font_size: fontSize,
                                  width: 1,
                                  text: name,
                                  text_align: PrintColumnAlign.left,
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    }
                  }
                  // รวมเงินยกเลิก
                  printer.addCommand(
                    PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: true),
                      columns: [
                        FormDesignColumnModel(
                          font_size: fontSize,
                          width: 1,
                          text:
                              "รวมเงินยกเลิก : ${global.moneyFormat.format(cancelAmount)}",
                          text_align: PrintColumnAlign.center,
                        ),
                      ],
                    ),
                  );

                  //
                  printer.addCommand(
                    PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: false),
                      columns: [
                        FormDesignColumnModel(
                          font_size: fontSize / 1.5,
                          width: 1,
                          text: order.orderEmployeeDetail,
                          text_align: PrintColumnAlign.left,
                        ),
                      ],
                    ),
                  );
                  printer.addCommand(
                    PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: true),
                      columns: [
                        FormDesignColumnModel(
                          font_size: fontSize,
                          width: 1,
                          text:
                              "${global.getNameFromJsonLanguage(kitchen.names, global.userScreenLanguage)} : เวลา : ${DateFormat("HH:mm").format(DateTime.now())}",
                          text_align: PrintColumnAlign.center,
                        ),
                      ],
                    ),
                  );
                  printer.addCommand(
                    PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: false),
                      columns: [
                        FormDesignColumnModel(
                          font_size: fontSize,
                          width: 1,
                          text: buttonName,
                          text_align: PrintColumnAlign.center,
                        ),
                      ],
                    ),
                  );
                  await printer.sendToPrinter(printerIndex: printerIndex);
                }
                cancelQty = cancelQty - 1;
              }
            }
          }
        }
      }
    }
  }
}
