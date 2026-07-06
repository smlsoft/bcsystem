import 'dart:convert';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/form_design_struct.dart';
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

Future<void> printOrderSummery({
  required String orderId,
  required List<OrderTempDataModel> orderList,
  required int printerIndex,
  required String bottomWord,
}) async {
  // ✅ Performance monitoring (Debug mode only)
  Stopwatch? stopwatch;
  if (kDebugMode) {
    stopwatch = Stopwatch()..start();
  }

  String tableOrDeliveryNumber = "สรุปโต๊ะ : $orderId";
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

  double fontSize = 32;

  // ✅ Cache: Pre-load product barcodes to avoid redundant DB queries (saves ~80% DB calls)
  Map<String, ProductBarcodeObjectBoxStruct?> barcodeCache = {};
  for (var order in orderList) {
    if (!barcodeCache.containsKey(order.barcode)) {
      barcodeCache[order.barcode] = await global.productBarcodeHelper
          .selectByBarcodeFirst(order.barcode);
    }
  }

  // พิมพ์
  int findPrinterIndex = printerIndex;
  if (findPrinterIndex == -1) {
    for (var printer in global.printerLocalStrongData) {
      if (printer.code == "printer_config_ticket") {
        findPrinterIndex = global.printerLocalStrongData.indexOf(printer);
        break;
      }
    }
  }
  if (findPrinterIndex != -1) {
    PrinterClass printer = PrinterClass(
      printerIndex: findPrinterIndex,
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
            text: tableOrDeliveryNumber,
            text_align: PrintColumnAlign.center,
          ),
        ],
      ),
    );
    double amountSum = 0;
    List<OrderTempDataModel> orderListProcess = [];
    for (var order in orderList) {
      // ต้นหารายการเดิม
      bool isFound = false;
      int index = -1;
      for (var orderProcess in orderListProcess) {
        if (orderProcess.barcode == order.barcode &&
            orderProcess.optionSelected == order.optionSelected &&
            orderProcess.remark == order.remark) {
          isFound = true;
          index = orderListProcess.indexOf(orderProcess);
          break;
        }
      }
      if (isFound) {
        orderListProcess[index].qty += order.qty;
      } else {
        orderListProcess.add(
          OrderTempDataModel(
            orderId: orderId,
            orderDateTime: order.orderDateTime,
            amount: order.amount,
            orderGuid: order.orderGuid,
            barcode: order.barcode,
            qty: order.qty,
            qtyLastCancel: order.qtyLastCancel,
            price: order.price,
            isTakeAway: order.isTakeAway,
            optionSelected: order.optionSelected,
            orderType: order.orderType,
            orderEmployeeCode: order.orderEmployeeCode,
            orderEmployeeDetail: order.orderEmployeeDetail,
            remarkForCancel: order.remarkForCancel,
            remark: order.remark,
          ),
        );
      }
    }

    for (var order in orderListProcess) {
      // ✅ Use cache instead of DB query
      ProductBarcodeObjectBoxStruct? findBarcode = barcodeCache[order.barcode];
      if (findBarcode != null) {
        String name = "";
        if (order.isTakeAway == 1) {
          name += "* กลับบ้าน * ";
        }
        double amount = order.price * order.qty;
        name +=
            "${global.getNameFromJsonLanguage(findBarcode.names, global.userScreenLanguage)}-${global.getNameFromJsonLanguage(findBarcode.unit_names, global.userScreenLanguage)} @${global.moneyFormat.format(order.price)} = ${global.moneyFormat.format(amount)}";
        amountSum += amount;

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
          // ✅ Direct decode (no need for cache since orderListProcess is already deduplicated)
          try {
            List<OrderProductOptionModel> options =
                (jsonDecode(order.optionSelected) as List)
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
                            text: " * ${option.names[0].name}",
                            text_align: PrintColumnAlign.left,
                          ),
                        ],
                      ),
                    );
                    optionPrint = true;
                  }
                  String choiceName = choice.names[0].name;
                  if (choice.priceValue != 0) {
                    choiceName =
                        "$choiceName @${global.moneyFormat.format(choice.priceValue)}";
                    amountSum += (choice.priceValue * order.qty);
                  }
                  printer.addCommand(
                    PosPrintBillCommandModel(
                      mode: 2,
                      posStyles: const PosStyles(bold: false),
                      columns: [
                        FormDesignColumnModel(
                          font_size: fontSize,
                          width: 1,
                          text: "   - $choiceName",
                          text_align: PrintColumnAlign.left,
                        ),
                      ],
                    ),
                  );
                }
              }
            }
          } catch (e) {
            AppLogger.error('[PrintOrderSummery] ⚠️ JSON decode error: $e');
          }
        }
      }
    }

    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          FormDesignColumnModel(
            font_size: fontSize,
            width: 1,
            text: "รวมเงิน : ${global.moneyFormat.format(amountSum)} บาท",
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
            font_size: fontSize,
            width: 1,
            text:
                "เวลา : ${DateFormat("dd/MM/yyyy - HH:mm").format(DateTime.now())}",
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
            font_size: fontSize,
            width: 1,
            text: bottomWord,
            text_align: PrintColumnAlign.center,
          ),
        ],
      ),
    );

    await printer.sendToPrinter(printerIndex: findPrinterIndex);

    // ✅ Log performance (Debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.debug(
        '[PrintOrderSummery] 🖨️ processed ${orderList.length} orders in ${stopwatch.elapsedMilliseconds}ms',
      );
      if (stopwatch.elapsedMilliseconds > 2000) {
        AppLogger.warning('[PrintOrderSummery] ⚠️ Slow order summary detected!');
      }
    }
  }
}
