import 'package:dedecashier/util/load_form_design.dart';
import 'dart:convert';
import 'package:dedecashier/features/pos/presentation/screens/pos_print.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_process.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/json/pos_process_model.dart';
import 'package:dedecashier/model/objectbox/form_design_struct.dart';
import 'package:dedecashier/services/print_process.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

Future<void> printHoldBill({required BuildContext context, required String holdNumber}) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("พิมพ์ใบสรุปรายการ"),
        content: const Text("คุณต้องการพิมพ์ใบสรุปรายการหรือไม่"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () async {
              await PosPrintHoldBillClass(holdNumber: holdNumber, languageCode: global.userScreenLanguage).printHoldBill();
              Navigator.pop(context);
            },
            child: const Text("พิมพ์"),
          ),
        ],
      );
    },
  );
}

class PosPrintHoldBillClass {
  String languageCode;
  String holdNumber;

  PosPrintHoldBillClass({required this.holdNumber, required this.languageCode});

  Future<String> findValueBillDetail(PosProcessDetailModel detail, String source) async {
    String result = source;
    result = result.replaceAll("&item_qty&", global.moneyFormat.format(detail.qty));
    result = result.replaceAll("&item_name&", global.getNameFromJsonLanguage(detail.item_name, languageCode));
    result = result.replaceAll("&item_unit_name&", global.getNameFromJsonLanguage(detail.unit_name, languageCode));
    {
      // ส่วนลด
      String discountValue = "";
      if (detail.discount_text.isNotEmpty) {
        discountValue = global.language("discount");
        if (detail.discount_text.contains("%") || detail.discount_text.contains(",")) {
          discountValue = "$discountValue ${detail.discount_text}=";
        }
        discountValue = "$discountValue ${global.moneyFormat.format(detail.discount)}";
        discountValue = "$discountValue ${global.language("money_symbol")}/${global.getNameFromJsonLanguage(detail.unit_name, global.userScreenLanguage)}";
      }
      result = result.replaceAll("&item_discount&", discountValue);
    }
    {
      // ราคา
      String priceValue = "";
      if (detail.price != detail.total_amount) {
        if (detail.price != 0) {
          priceValue = global.moneyFormat.format(detail.price);
        }
      }
      result = result.replaceAll("&item_price&", priceValue);
    }
    {
      // ราคา+สัญลักษณ์
      String priceValue = "";
      if (detail.price != detail.total_amount) {
        if (detail.price != 0) {
          priceValue = "@${global.moneyFormat.format(detail.price)}";
        }
      }
      result = result.replaceAll("&item_price_and_symbol&", priceValue);
    }
    {
      // มูลค่าทั้งหมด
      result = result.replaceAll("&item_total_amount&", global.moneyFormat.format(detail.total_amount));
    }
    return result.trim().replaceAll("  ", " ").replaceAll("  ", " ");
  }

  Future<String> findValueBillDetailExtra(PosProcessDetailExtraModel detailExtra, String source) async {
    String result = source;
    result = result.replaceAll("&item_extra_qty&", (detailExtra.qty == 0) ? "" : global.moneyFormat.format(detailExtra.qty));
    result = result.replaceAll("&item_extra_name&", global.getNameFromJsonLanguage(detailExtra.item_name, languageCode));
    result = result.replaceAll("&item_extra_unit_name&", global.getNameFromJsonLanguage(detailExtra.unit_name, languageCode));
    // ราคา
    String priceValue = "";
    if (detailExtra.price != detailExtra.total_amount) {
      if (detailExtra.price != 0) {
        priceValue = "@${global.moneyFormat.format(detailExtra.price)}";
      }
    }
    result = result.replaceAll("&item_extra_price&", priceValue);

    result = result.replaceAll("&item_extra_total_amount&", (detailExtra.total_amount == 0) ? "" : global.moneyFormat.format(detailExtra.total_amount));

    return result.trim().replaceAll("  ", " ").replaceAll("  ", " ");
  }

  String findValueBillTotal(PosProcessModel value, String source) {
    String result = source;
    // จำนวนชิ้น
    result = result.replaceAll("&total_piece_name&", "จำนวนชิ้น");
    result = result.replaceAll("&total_piece&", global.moneyFormatAndDot.format(value.total_piece));
    // ยอดรวมสินค้ามีภาษี
    result = result.replaceAll("&total_item_vat_amount_name&", "รวมสินค้ามีภาษี");
    result = result.replaceAll("&total_item_vat_amount&", global.moneyFormatAndDot.format(value.total_item_vat_amount));
    // ยอดรวมสินค้ายกเว้นภาษี
    result = result.replaceAll("&total_itm_except_vat_amount_name&", "รวมสินค้ายกเว้นภาษี");
    result = result.replaceAll("&total_itm_except_vat_amount&", global.moneyFormatAndDot.format(value.total_item_except_vat_amount));
    // ภาษี
    result = result.replaceAll("&total_vat_name&", "ภาษีมูลค่าเพิ่ม : ${global.moneyFormat.format(value.vat_rate)}%");
    result = result.replaceAll("&total_vat&", global.moneyFormatAndDot.format(value.total_vat_amount));
    // ส่วนลด
    result = result.replaceAll("&total_discount_name&", "ส่วนลด");
    result = result.replaceAll("&total_discount_amount&", value.detail_discount_formula);
    // รวมทั้งสิ้น
    result = result.replaceAll("&total_amount_name&", "ยอดรวมสุทธิ");
    result = result.replaceAll("&total_amount&", global.moneyFormatAndDot.format(value.total_amount));
    return result.trim().replaceAll("  ", " ").replaceAll("  ", " ");
  }

  Future<List<PosPrintBillCommandModel>> buildCommand(PosProcessModel processResult) async {
    // ✅ Performance logging (Debug mode only)
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
    }

    FormDesignObjectBoxStruct formDesign = global.formDesignList[global.findFormByCode(global.formS01)];
    List<PosPrintBillCommandModel> commandList = [];

    // Reset Printer
    commandList.add(PosPrintBillCommandModel(mode: 0));

    commandList.add(
      PosPrintBillCommandModel(
        mode: 2,
        columns: [FormDesignColumnModel(width: 1, text: "พักบิลเลขที่ : $holdNumber", font_size: 30, font_weight_bold: true, text_align: PrintColumnAlign.center)],
      ),
    );

    commandList.add(
      PosPrintBillCommandModel(
        mode: 2,
        columns: [
          FormDesignColumnModel(width: 1, text: global.getNameFromJsonLanguage(formDesign.names_json, languageCode), font_size: 30, font_weight_bold: true, text_align: PrintColumnAlign.center),
        ],
      ),
    );

    commandList.add(
      PosPrintBillCommandModel(
        mode: 2,
        columns: [FormDesignColumnModel(width: 1, text: (1 == 1) ? "(ราคารวมภาษีมูลค่าเพิ่มแล้ว)" : "(ราคาไม่รวมภาษีมูลค่าเพิ่ม)", text_align: PrintColumnAlign.center)],
      ),
    );
    List<PosProcessDetailModel> details = processResult.details;
    if (formDesign.sum_by_barcode) {
      // กรณีพิมพ์บิลแบบรวมรายการ
      List<PosProcessDetailModel> detailSum = [];
      for (var detail in details) {
        bool isFound = false;
        for (var billDetailSumItem in detailSum) {
          if (billDetailSumItem.barcode == detail.barcode && jsonEncode(billDetailSumItem.extra) == jsonEncode(detail.extra)) {
            billDetailSumItem.qty += detail.qty;
            billDetailSumItem.total_amount += detail.total_amount;
            isFound = true;
            break;
          }
        }
        if (!isFound) {
          detailSum.add(detail);
        }
      }
      details = detailSum;
    }
    try {
      List<FormDesignColumnModel> formDetailList = (await jsonDecode(formDesign.detail_json) as List).map((e) => FormDesignColumnModel.fromJson(e)).toList();
      List<FormDesignColumnModel> formDetailExtraList = (await jsonDecode(formDesign.detail_extra_json) as List).map((e) => FormDesignColumnModel.fromJson(e)).toList();
      List<List<FormDesignColumnModel>> formDetailColumnList = (await jsonDecode(formDesign.detail_total_json) as List)
          .map((e) => (e as List).map((e) => FormDesignColumnModel.fromJson(e)).toList())
          .toList();
      // พิมพ์ หัว Column
      // Line
      commandList.add(PosPrintBillCommandModel(mode: 3));
      {
        List<FormDesignColumnModel> columns = [];
        for (var formDetail in formDetailList) {
          columns.add(
            FormDesignColumnModel(
              width: formDetail.width,
              text: global.getNameFromLanguage(formDetail.header_names, languageCode),
              text_align: formDetail.text_align,
              font_weight_bold: true,
              font_size: formDetail.font_size,
            ),
          );
        }
        commandList.add(PosPrintBillCommandModel(mode: 2, columns: columns));
      }
      // Line
      commandList.add(PosPrintBillCommandModel(mode: 3));
      for (var detail in details) {
        {
          // รายละเอียดสินค้า
          List<FormDesignColumnModel> columns = [];
          for (var formDetail in formDetailList) {
            {
              columns.add(
                FormDesignColumnModel(
                  width: formDetail.width,
                  text: await findValueBillDetail(detail, formDetail.command_text),
                  text_align: formDetail.text_align,
                  font_weight_bold: false,
                  font_size: formDetail.font_size,
                ),
              );
            }
          }
          commandList.add(PosPrintBillCommandModel(mode: 2, columns: columns));
        }
        {
          // ส่วนเพิ่มเติม
          for (var extra in detail.extra) {
            List<FormDesignColumnModel> columns = [];
            for (var formDetailExtra in formDetailExtraList) {
              columns.add(
                FormDesignColumnModel(
                  width: formDetailExtra.width,
                  text: await findValueBillDetailExtra(extra, formDetailExtra.command_text),
                  text_align: formDetailExtra.text_align,
                  font_weight_bold: formDetailExtra.font_weight_bold,
                  font_size: formDetailExtra.font_size,
                ),
              );
            }
            commandList.add(PosPrintBillCommandModel(mode: 2, columns: columns));
          }
        }
      }
      // Line
      commandList.add(PosPrintBillCommandModel(mode: 3));
      {
        double sumQty = 0;
        for (var detail in details) {
          sumQty += detail.qty;
        }
        for (var formDetailColumns in formDetailColumnList) {
          List<FormDesignColumnModel> columns = [];
          for (FormDesignColumnModel column in formDetailColumns) {
            // พิมพ์ยอดรวม (รายการ
            columns.add(
              FormDesignColumnModel(
                width: column.width,
                text: findValueBillTotal(processResult, column.command_text),
                text_align: column.text_align,
                font_weight_bold: column.font_weight_bold,
                font_size: column.font_size,
              ),
            );
          }
          commandList.add(PosPrintBillCommandModel(mode: 2, columns: columns));
        }
      }
      // Line
      commandList.add(PosPrintBillCommandModel(mode: 3));
      // Footer
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: "ใบสรุปยอดเพื่อตรวจสอบ", text_align: PrintColumnAlign.center)],
        ),
      );
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: "ไม่ใช่ใบเสร็จรับเงิน", text_align: PrintColumnAlign.center)],
        ),
      );
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: "ยอดภาษี และยอดรวม อาจเปลี่ยนแปลง", text_align: PrintColumnAlign.center)],
        ),
      );
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: "เมื่อถึงขึ้นตอนการชำระเงิน", text_align: PrintColumnAlign.center)],
        ),
      );
    } catch (e) {
      AppLogger.error(e);
    }

    // ✅ Log performance (Debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.success('[PrintHoldBill] 🖨️ buildCommand took ${stopwatch.elapsedMilliseconds}ms');
      if (stopwatch.elapsedMilliseconds > 1000) {
        AppLogger.warning('[PrintHoldBill] ⚠️ Slow build detected!');
      }
    }

    return commandList;
  }

  void printBillByIpImageMode(PosProcessModel processResult) async {
    await buildCommand(processResult).then((value) async {
      var imageBytes = await global.ticketCreateImage(
        printerData: global.printerLocalStrongData[0],
        docDate: DateTime.now(),
        docNumber: "",
        printLogo: false,
        commandList: value,
        printMaxHeight: 200,
        qrCodeBottom: "",
        saveToFile: false,
        printPaySlip: false,
      );
      global.savePrintQueueToFile(global.printerLocalStrongData[0].deviceName, imageBytes, false, "", false);
    });
  }

  void printBillByWindowsImageMode(PosProcessModel processResult) async {
    await buildCommand(processResult).then((value) async {
      var imageBytes = await global.ticketCreateImage(
        printerData: global.printerLocalStrongData[0],
        docDate: DateTime.now(),
        docNumber: "XXX",
        printLogo: false,
        commandList: value,
        printMaxHeight: 10000,
        qrCodeBottom: "",
        saveToFile: false,
        printPaySlip: false,
      );
      String printerName = global.printerLocalStrongData[0].deviceName;
      // global.windowsPrintRawData(printerName, imageBytes);
    });
  }

  Future<void> printHoldBill() async {
    PosProcessModel processResult = await PosProcess().process(holdCode: holdNumber, docMode: 1, detailDiscountFormula: "", discountFormula: "", cashRoundAmount: false, discountFoodOnly: false);

    loadFormDesign();

    switch (global.printerLocalStrongData[0].printerConnectType) {
      case global.PrinterConnectEnum.ip:
        printBillByIpImageMode(processResult);
        break;
      case global.PrinterConnectEnum.bluetooth:
        //printBillByBluetoothImageMode();
        break;
      case global.PrinterConnectEnum.usb:
        // TODO: Handle this case.
        break;
      case global.PrinterConnectEnum.windows:
        printBillByWindowsImageMode(processResult);
        break;
      case global.PrinterConnectEnum.sunmi1:
        //await printBillBySunmi();
        break;
    }
  }
}
