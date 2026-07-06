import 'dart:convert';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:dedekiosk/print/print.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/logger.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:intl/intl.dart';

/// Exception สำหรับ kitchen print error
class KitchenPrintException implements Exception {
  final String message;
  final String orderId;
  final int successCount;
  final int totalCount;

  KitchenPrintException({
    required this.message,
    required this.orderId,
    required this.successCount,
    required this.totalCount,
  });

  @override
  String toString() => 'KitchenPrintException: $message (orderId: $orderId, success: $successCount/$totalCount)';
}

Future<void> sendToKitchen({required String orderId, required List<OrderTempDetailDataModel> orderList}) async {
  Logger.d("sendToKitchen: Start printing for orderId $orderId with ${orderList.length} items");

  // ตรวจสอบว่า kitchen print ถูก disable หรือไม่
  if (global.kitchenPrintDisabled) {
    Logger.w("sendToKitchen: Kitchen print is disabled, skipping orderId $orderId");
    // Mark ว่าพิมพ์แล้วเพื่อไม่ให้พยายามพิมพ์อีก
    global.kitchenPrintedOrderIds.add(orderId);
    return;
  }

  // Double-check: ตรวจสอบว่า order นี้ถูกพิมพ์ไปแล้วหรือยัง (last line of defense)
  // ป้องกันกรณี race condition ที่อาจทำให้พิมพ์ซ้ำ
  if (global.kitchenPrintedOrderIds.contains(orderId)) {
    Logger.w("sendToKitchen: orderId $orderId already printed, skipping to prevent duplicate");
    return;
  }
  // Mark ว่ากำลังพิมพ์ orderId นี้
  global.kitchenPrintedOrderIds.add(orderId);

  // Track จำนวนการพิมพ์ที่สำเร็จ/ล้มเหลว
  int printSuccessCount = 0;
  int printTotalCount = 0;
  String lastError = "";

  // แบ่งครัว ค้นหาจาก Order ว่าอยู่ครัวไหนบ้าง
  List<String> kitchenCodeActiveList = [];
  for (var kitchen in global.shopProfile!.kitchens!) {
    for (var barcode in kitchen.products) {
      if (orderList.indexWhere((element) => element.barcode == barcode) != -1) {
        if (kitchenCodeActiveList.indexWhere((element) => element == kitchen.code) == -1) {
          kitchenCodeActiveList.add(kitchen.code);
        }
        break;
      }
    }
  }

  Logger.d("sendToKitchen: Found ${kitchenCodeActiveList.length} kitchens to print");

  // พิมพ์
  for (var kitchenCode in kitchenCodeActiveList) {
    KitchenModel kitchen = global.shopProfile!.kitchens![global.shopProfile!.kitchens!.indexWhere((element) => element.code == kitchenCode)];

    int printerIndex = -1;
    for (var printer in global.deviceConfig.kitchens) {
      if (printer.code == kitchenCode) {
        printerIndex = global.deviceConfig.kitchens.indexOf(printer);
        break;
      }
    }
    if (printerIndex != -1) {
      // ตรวจสอบว่า printer ถูกตั้งค่าตาม connection type
      var kitchenPrinter = global.deviceConfig.kitchens[printerIndex].printer;
      bool isPrinterConfigured = false;

      switch (global.printerConnectToEnum(kitchenPrinter.printerConnectType)) {
        case global.PrinterConnectEnum.ip:
          // IP mode: ต้องมี ipAddress และ ipPort
          isPrinterConfigured = kitchenPrinter.ipAddress.isNotEmpty && kitchenPrinter.ipPort > 0;
          if (!isPrinterConfigured) {
            Logger.e("sendToKitchen: Kitchen ${kitchen.code} IP not configured: ipAddress='${kitchenPrinter.ipAddress}', ipPort=${kitchenPrinter.ipPort}");
          }
          break;
        case global.PrinterConnectEnum.usb:
          // USB mode: ต้องมี code หรือ deviceId
          isPrinterConfigured = kitchenPrinter.code.isNotEmpty || kitchenPrinter.deviceId.isNotEmpty;
          if (!isPrinterConfigured) {
            Logger.e("sendToKitchen: Kitchen ${kitchen.code} USB not configured: code='${kitchenPrinter.code}', deviceId='${kitchenPrinter.deviceId}'");
          }
          break;
        case global.PrinterConnectEnum.bluetooth:
          isPrinterConfigured = kitchenPrinter.code.isNotEmpty;
          if (!isPrinterConfigured) {
            Logger.e("sendToKitchen: Kitchen ${kitchen.code} Bluetooth not configured");
          }
          break;
        case global.PrinterConnectEnum.windows:
          isPrinterConfigured = kitchenPrinter.name.isNotEmpty;
          if (!isPrinterConfigured) {
            Logger.e("sendToKitchen: Kitchen ${kitchen.code} Windows printer not configured");
          }
          break;
      }

      if (!isPrinterConfigured) {
        lastError = "Kitchen ${kitchen.code} has no printer configured";
        continue; // ข้ามไปครัวถัดไป
      }
      /*{
        // พิมพ์รายการแบบรวมใบเดียว
        bool found = false;
        for (var order in orderList) {
          if (kitchen.products.contains(order.barcode) == true) {
            // ค้นหาชื่อสินค้า
            int findBarcodeIndex = global.findProductByBarcode(order.barcode);
            if (findBarcodeIndex != -1) {
              global.productList[findBarcodeIndex].issplitunitprint = true;
            }
            if (findBarcodeIndex != -1 &&
                global.productList[findBarcodeIndex].issplitunitprint ==
                    false) {
              found = true;
              break;
            }
          }
        }
        if (found) {
          PrinterClass printer =
              PrinterClass(printerIndex: printerIndex, qrCode: "");
          // Reset Printer
          printer.addCommand(PosPrintBillCommandModel(mode: 0));
          printer.addCommand(PosPrintBillCommandModel(
              mode: 2,
              posStyles: const PosStyles(bold: true),
              columns: [
                PosPrintBillCommandColumnModel(
                  width: 1,
                  text: "โต๊ะ : ",
                )
              ]));
          for (var order in orderList) {
            if (kitchen.products.contains(order.barcode) == true) {
              // ค้นหาชื่อสินค้า
              int findBarcodeIndex = global.findProductByBarcode(order.barcode);
              if (findBarcodeIndex != -1) {
                var findBarcode = global.productList[findBarcodeIndex];
                printer.addCommand(PosPrintBillCommandModel(
                    mode: 2,
                    posStyles: const PosStyles(bold: true),
                    columns: [
                      PosPrintBillCommandColumnModel(
                        width: 4,
                        text:
                            "${global.getNameFromLanguage(findBarcode.names, global.userLanguage)}-${global.getNameFromLanguage(findBarcode.unitnames, global.userLanguage)}",
                      ),
                      PosPrintBillCommandColumnModel(
                          width: 1,
                          text: global.moneyFormat.format(order.qty),
                          align: global.PrintColumnAlign.right),
                    ]));
                if (order.remark.trim().isNotEmpty) {
                  printer.addCommand(PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: true),
                      columns: [
                        PosPrintBillCommandColumnModel(
                            width: 1,
                            text: "x หมายเหตุ x : ${order.remark}",
                            align: global.PrintColumnAlign.left),
                      ]));
                }
                if (order.optionSelected.isNotEmpty) {
                  List<ProductProcessOptionModel> options =
                      await jsonDecode(order.optionSelected)
                          .map<ProductProcessOptionModel>((item) =>
                              ProductProcessOptionModel.fromJson(item))
                          .toList();
                  for (var option in options) {
                    bool optionPrint = false;
                    for (var choice in option.choices) {
                      if (choice.selected) {
                        if (optionPrint == false) {
                          printer.addCommand(PosPrintBillCommandModel(
                              mode: 2,
                              posStyles: const PosStyles(bold: false),
                              columns: [
                                PosPrintBillCommandColumnModel(
                                    width: 1,
                                    text: " * ${option.names[0].name}",
                                    align: global.PrintColumnAlign.left),
                              ]));
                          optionPrint = true;
                        }
                        printer.addCommand(PosPrintBillCommandModel(
                            mode: 2,
                            posStyles: const PosStyles(bold: false),
                            columns: [
                              PosPrintBillCommandColumnModel(
                                  width: 1,
                                  text: "   - ${choice.names[0].name}",
                                  align: global.PrintColumnAlign.left),
                            ]));
                      }
                    }
                  }
                }
              }
            }
          }
          printer.addCommand(PosPrintBillCommandModel(
              mode: 2,
              posStyles: const PosStyles(bold: true),
              columns: [
                PosPrintBillCommandColumnModel(
                    width: 1,
                    text:
                        "${global.getNameFromLanguage(kitchen.names, global.userLanguage)} : เวลา : ${DateFormat("HH:mm").format(DateTime.now())}",
                    align: global.PrintColumnAlign.center)
              ]));
          await printer.sendToPrinter(printerData:
              global.deviceConfig.kitchens[printerIndex].printer,docNumber: "",saveToFile: false);
        }
      }*/
      {
        // พิมพ์รายการแบบแยกแต่ละรายการ
        for (var order in orderList) {
          if (kitchen.products.contains(order.barcode) == true) {
            // ค้นหาชื่อสินค้า
            int findBarcodeIndex = global.findProductByBarcode(order.barcode);
            double orderQty = order.qty;
            if (findBarcodeIndex != -1) {
              global.productList[findBarcodeIndex].issplitunitprint = true;
            }
            if (findBarcodeIndex != -1 && global.productList[findBarcodeIndex].issplitunitprint == true) {
              var findBarcode = global.productList[findBarcodeIndex];
              int loopQty = orderQty.ceil();
              for (int loop = 0; loop < loopQty; loop++) {
                // ✅ สร้าง unique key สำหรับแต่ละใบพิมพ์ (กรณี qty > 1 จะพิมพ์หลายใบ)
                String printKey = "${order.orderGuid}_${kitchenCode}_$loop";

                // ✅ ตรวจสอบว่าใบนี้พิมพ์ไปแล้วหรือยัง (ป้องกันพิมพ์ซ้ำเมื่อ retry)
                if (global.kitchenPrintedOrderGuids.contains(printKey)) {
                  Logger.d("sendToKitchen: Skipping already printed item: $printKey");
                  continue; // ข้ามไปรายการถัดไป
                }

                PrinterClass printer = PrinterClass(printerIndex: printerIndex, qrCode: order.orderGuid, openCashDrawer: false);
                // Reset Printer
                printer.addCommand(PosPrintBillCommandModel(mode: 0));
                if (order.orderTagNumber.isNotEmpty) {
                  printer.addCommand(PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: true),
                      columns: [PosPrintBillCommandColumnModel(width: 1, fontSize: 32, text: "เลขป้าย : ${order.orderTagNumber}", align: global.PrintColumnAlign.center)]));
                }
                if (order.queueNumber != 0) {
                  printer.addCommand(PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: true),
                      columns: [PosPrintBillCommandColumnModel(width: 1, fontSize: 32, text: "เลขคิว : ${order.queueNumber.toString()}", align: global.PrintColumnAlign.center)]));
                }
                if (order.isTakeAway == 1) {
                  String word = "สั่งกลับบ้าน";
                  if (order.salechannelcode.isNotEmpty) {
                    word += " ${order.salechannelcode}";
                  }
                  printer.addCommand(PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: true),
                      columns: [PosPrintBillCommandColumnModel(width: 1, fontSize: 28, text: word, align: global.PrintColumnAlign.center)]));
                }
                printer.addCommand(PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
                  PosPrintBillCommandColumnModel(
                      fontSize: 32,
                      width: 4,
                      text:
                          "${global.getNameFromLanguage(findBarcode.names, global.languageForStaff)}-${global.getNameFromLanguage(findBarcode.unitnames, global.languageForStaff)}",
                      align: global.PrintColumnAlign.left),
                  PosPrintBillCommandColumnModel(width: 1, fontSize: 32, text: global.moneyFormat.format((orderQty > 1) ? 1 : orderQty), align: global.PrintColumnAlign.right),
                ]));
                if (order.remark.trim().isNotEmpty) {
                  printer.addCommand(PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
                    PosPrintBillCommandColumnModel(width: 1, text: "x หมายเหตุ x : ${order.remark}", align: global.PrintColumnAlign.left),
                  ]));
                }
                if (order.optionSelected.isNotEmpty) {
                  List<ProductProcessOptionModel> options =
                      await jsonDecode(order.optionSelected).map<ProductProcessOptionModel>((item) => ProductProcessOptionModel.fromJson(item)).toList();
                  for (var option in options) {
                    bool optionPrint = false;
                    for (var choice in option.choices) {
                      if (choice.selected) {
                        if (optionPrint == false) {
                          printer.addCommand(PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: false), columns: [
                            PosPrintBillCommandColumnModel(width: 1, text: " * ${option.names[0].name}", align: global.PrintColumnAlign.left),
                          ]));
                          optionPrint = true;
                        }
                        printer.addCommand(PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: false), columns: [
                          PosPrintBillCommandColumnModel(width: 1, text: "   - ${choice.names[0].name}", align: global.PrintColumnAlign.left),
                        ]));
                      }
                    }
                  }
                }
                printer.addCommand(PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
                  PosPrintBillCommandColumnModel(
                      width: 1,
                      text: "${global.getNameFromLanguage(kitchen.names, global.languageForStaff)} : เวลา : ${DateFormat("HH:mm").format(DateTime.now())}",
                      align: global.PrintColumnAlign.center)
                ]));
                try {
                  await printer.sendToPrinter(printerData: global.deviceConfig.kitchens[printerIndex].printer, docNumber: "", saveToFile: false, printLogo: false);
                  printSuccessCount++;
                  // ✅ พิมพ์สำเร็จ - เพิ่ม key เข้า tracking set
                  global.kitchenPrintedOrderGuids.add(printKey);
                  Logger.d("sendToKitchen: Successfully printed item: $printKey");
                } catch (e) {
                  lastError = e.toString();
                  Logger.e("sendToKitchen: Failed to print item for orderId $orderId, kitchen ${kitchen.code}, printKey: $printKey", error: e);
                  // ❌ พิมพ์ไม่สำเร็จ - ไม่เพิ่ม key เพื่อให้ retry ได้
                }
                printTotalCount++;
                orderQty = orderQty - 1;
              }
            }
          }
        }
      }
    }
  }

  // ตรวจสอบว่าพิมพ์สำเร็จทั้งหมดหรือไม่
  if (printTotalCount > 0 && printSuccessCount < printTotalCount) {
    // ลบออกจาก kitchenPrintedOrderIds เพื่อให้ retry ได้
    global.kitchenPrintedOrderIds.remove(orderId);
    throw KitchenPrintException(
      message: "Kitchen print failed: $lastError",
      orderId: orderId,
      successCount: printSuccessCount,
      totalCount: printTotalCount,
    );
  }

  Logger.i("sendToKitchen: Completed printing for orderId $orderId ($printSuccessCount/$printTotalCount items)");
}
