import 'dart:convert';
import 'dart:io' as io;
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/json/pos_process_model.dart';
import 'package:dedecashier/model/objectbox/form_design_struct.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:dedecashier/services/print_process.dart';
import 'package:dedecashier/util/load_form_design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/api/sync/model/trans_model.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'dart:ui' as ui;

/// Class สำหรับเก็บข้อมูลสรุป Pattern
class PatternSummary {
  final String code;
  final String name;
  int count;
  double totalAmount;

  PatternSummary({required this.code, required this.name, required this.count, required this.totalAmount});
}

Future<void> printBillProcess({
  required global.PosScreenModeEnum posScreenMode,
  required DateTime docDate,
  required String docNo,
  required String languageCode,
  required bool printLogo,
  String bottomText = "",
  String topText = "",
  bool printPaySlip = false,
  bool isPaySlip = false,
}) async {
  if (global.posTicket.print_mode == 0) {
    PosPrintBillClass posPrintBill = PosPrintBillClass(docDate: docDate, docNo: docNo, languageCode: languageCode, bottomText: bottomText, topText: topText, printPaySlip: printPaySlip);
    await posPrintBill.printBill(posScreenMode: posScreenMode, printLogo: printLogo, isPaySlip: isPaySlip);
  } else {
    //printBillImage(docNo);
  }
}

class PosPrintBillCommandModel {
  int? mode; // 0=Reset,1=Logo Image,2=Text,3=Line
  String? text;
  Uint8List? image;
  PosStyles? posStyles;
  PosTextSize? posTextSize;
  List<FormDesignColumnModel> columns;
  double value;
  String qrCode;

  PosPrintBillCommandModel({required this.mode, this.text, this.image, this.value = 0, this.posStyles = const PosStyles(bold: false), this.columns = const [], this.qrCode = "", this.posTextSize = PosTextSize.size1});
}

class PosPrintBillClass {
  DateTime docDate;
  String docNo;
  String languageCode;
  String bottomText;
  String topText;
  bool printPaySlip;
  double billWidth = global.paperWidth(global.printerLocalStrongData[0].paperType);

  PosPrintBillClass({required this.docDate, required this.docNo, required this.languageCode, required this.bottomText, required this.topText, this.printPaySlip = false});

  /// 🎯 ดึง tier_level จาก bill.promotion_bonus_json
  ///
  /// **Returns:** tier_level (1-5) หรือ null ถ้าไม่เจอ Type 102
  int? _getTierLevelFromBill(BillObjectBoxStruct bill) {
    try {
      if (bill.promotion_bonus_json.isEmpty) {
        return null;
      }

      // Parse JSON
      final promotionJsonList = jsonDecode(bill.promotion_bonus_json);
      final promotions = promotionJsonList.map((e) => PosProcessPromotionModel.fromJson(e)).toList();

      // หา promotion ที่มี tier_level (Type 102)
      for (var promo in promotions) {
        if (promo.tier_level != null) {
          if (kDebugMode) {
            print('[Print] 🎁 Found Tier ${promo.tier_level} in bill');
          }
          return promo.tier_level;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[Print] ⚠️ Failed to extract tier_level: $e');
      }
      return null;
    }
  }

  Future<String> findValueBillDetail(BillDetailObjectBoxStruct detail, String source) async {
    String result = source;
    result = result.replaceAll("&item_qty&", global.moneyFormat.format(detail.qty));
    result = result.replaceAll("&item_name&", global.getNameFromJsonLanguage(detail.item_name, languageCode));
    result = result.replaceAll("&item_unit_name&", global.getNameFromJsonLanguage(detail.unit_name, languageCode));
    {
      // ส่วนลด + รายละเอียดการลดราคา
      String discountValue = "";

      // 🎯 แสดงรายละเอียดการลดราคา (ราคาเดิม → ราคาใหม่)
      if (detail.price_original > detail.price && detail.price > 0) {
        discountValue = "(${global.moneyFormat.format(detail.price_original)} ";
        discountValue += "-${global.moneyFormat.format(detail.price_original - detail.price)} ";
        discountValue += "= ${global.moneyFormat.format(detail.price)})";
      }

      // แสดงส่วนลดตาม discount_text (ถ้ามี)
      if (detail.discount_text.isNotEmpty) {
        if (discountValue.isNotEmpty) discountValue += " ";
        discountValue += global.language("discount");
        if (detail.discount_text.contains("%") || detail.discount_text.contains(",")) {
          discountValue = "$discountValue ${detail.discount_text}=";
        }
        discountValue += " ${global.moneyFormat.format(detail.discount)}";
        discountValue += " ${global.language("money_symbol")}";
      }

      result = result.replaceAll("&item_discount&", discountValue);
    }
    {
      // ราคา
      String priceValue = "";
      if (detail.price != detail.total_amount - detail.discount) {
        if (detail.price != 0) {
          priceValue = global.moneyFormat.format(detail.price);
        }
      }
      result = result.replaceAll("&item_price&", priceValue);
    }
    {
      // ราคา+สัญลักษณ์
      String priceValue = "";
      if (detail.price != detail.total_amount - detail.discount) {
        if (detail.price != 0) {
          priceValue = "@${global.moneyFormat.format(detail.price)}";
        }
      }
      result = result.replaceAll("&item_price_and_symbol&", priceValue);
    }
    {
      // มูลค่าทั้งหมด
      result = result.replaceAll("&item_total_amount&", ((detail.is_except_vat == true) ? "n " : "") + global.moneyFormatAndDot.format(detail.total_amount - detail.discount));
    }
    return result.trim().replaceAll("  ", " ").replaceAll("  ", " ");
  }

  String findValueBillDetailExtra(BillDetailExtraObjectBoxStruct detailExtra, String source) {
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

  String findValueBillTotal(BillObjectBoxStruct value, String source) {
    String result = source;
    // จำนวนชิ้น
    result = result.replaceAll("&total_piece_name&", "จำนวนชิ้น");
    result = result.replaceAll("&total_piece&", global.moneyFormatAndDot.format(value.total_qty));

    if (F.appFlavor != Flavor.MARINEPOS) {
      // ยอดรวมอาหาร
      result = result.replaceAll("&detail_total_amount_food_name&", "ยอดรวมอาหาร");
      result = result.replaceAll("&detail_total_amount_food_amount&", global.moneyFormatAndDot.format(value.food_amount));
      // ยอดรวมเครื่องดื่ม/ของหวาน
      result = result.replaceAll("&detail_total_amount_drink_name&", "ยอดรวมเครื่องดื่ม/ของหวาน");
      result = result.replaceAll("&detail_total_amount_drink_amount&", global.moneyFormatAndDot.format(value.beverage_amount));
    }

    // ยอดรวมสินค้าก่อนหักส่วนลดสินค้า
    result = result.replaceAll("&detail_total_amount_before_discount_name&", "ยอดรวม");
    result = result.replaceAll("&detail_total_amount_before_discount&", global.moneyFormatAndDot.format(value.detail_total_amount_before_discount));
    // ยอดรวมสินค้ามีภาษี
    result = result.replaceAll("&total_item_vat_amount_name&", "มูลค่าสินค้ามีภาษี");
    result = result.replaceAll("&total_item_vat_amount&", global.moneyFormatAndDot.format(value.total_item_vat_amount));
    // ยอดรวมสินค้ายกเว้นภาษี
    result = result.replaceAll("&total_itm_except_vat_amount_name&", "มูลค่าสินค้ายกเว้นภาษี");
    result = result.replaceAll("&total_itm_except_vat_amount&", global.moneyFormatAndDot.format(value.total_item_except_vat_amount));

    // ไม่แสดง "ส่วนลดจากโปรโมชั่น" ในส่วนยอดรวม เพราะไม่ใช่ส่วนลดทางบัญชี
    // แสดงเฉพาะ banner "ประหยัดไปแล้ว XX บาท" ที่ท้ายบิลเท่านั้น

    // ใช้แต้ม
    if (value.pointdiscountamount != 0) {
      result = result.replaceAll("&point_discount_amount_name&", "ใช้แต้ม ${global.moneyFormat.format(value.usepoint)}");
      result = result.replaceAll("&point_discount_amount&", global.moneyFormatAndDot.format(value.pointdiscountamount));
    }

    // if (value.getpoint != 0) {
    //   result = result.replaceAll("&earn_point_name&", "ได้รับแต้ม");
    //   result = result.replaceAll("&earn_point&", global.moneyFormatAndDot.format(value.getpoint));
    // }

    if (value.paypointamount > 0) {
      result = result.replaceAll("&point_payment_name&", "ชำระด้วยแต้ม");
      result = result.replaceAll("&point_payment&", global.moneyFormatAndDot.format(value.paypointamount));
    }

    if (value.coupondiscountamount > 0) {
      result = result.replaceAll("&detail_coupon_discount_name&", "ส่วนลดคูปอง");
      result = result.replaceAll("&detail_coupon_discount_amount&", global.moneyFormatAndDot.format(value.coupondiscountamount));
    }

    // ส่วนลดก่อนชำระเงิน (ไม่รวมส่วนต่างราคาพิเศษ)
    result = result.replaceAll("&detail_total_discount_name&", "ส่วนลด ${value.detail_discount_formula}");
    result = result.replaceAll(
      "&detail_total_discount_amount&",
      global.moneyFormatAndDot.format(
        value.detail_total_discount -
            // ❌ ไม่ลบ total_discount_from_promotion เพราะไม่ได้รวมอยู่แล้ว
            value.pointdiscountamount -
            value.coupondiscountamount,
      ),
    );
    // ส่วนลดสินค้ามีภาษี
    result = result.replaceAll("&total_discount_vat_name&", "ส่วนลดสินค้ามีภาษี");
    result = result.replaceAll("&total_discount_vat_amount&", global.moneyFormatAndDot.format(value.total_discount_vat_amount));
    // ส่วนลดสินค้ายกเว้นภาษี
    result = result.replaceAll("&total_discount_vat_except_name&", "ส่วนลดสินค้ายกเว้นภาษี");
    result = result.replaceAll("&total_discount_vat_except_amount&", global.moneyFormatAndDot.format(value.total_discount_except_vat_amount));
    // ส่วนลดเงินสดทั้งหมด (หลังคำนวณ)
    result = result.replaceAll("&total_discount_name&", "ส่วนลดท้ายบิล ${value.discount_formula}");
    result = result.replaceAll("&total_discount_amount&", global.moneyFormatAndDot.format(value.total_discount));
    // มูลค่าสินค้าหลังคิดภาษี (หลังหักส่วนลด)
    result = result.replaceAll("&total_item_vat_amount_after_discount_name&", "มูลค่าหลังคิดภาษี");
    result = result.replaceAll("&total_item_vat_amount_after_discount&", global.moneyFormatAndDot.format(value.amount_after_calc_vat));
    // มูลค่าสินค้ายกเว้นภาษี (หลังหักส่วนลด)
    result = result.replaceAll("&total_item_except_vat_amount_after_discount_name&", "มูลค่ายกเว้นภาษี");
    result = result.replaceAll("&total_item_except_vat_amount_after_discount&", global.moneyFormatAndDot.format(value.amount_except_vat));
    // รวมทั้งสิ้น (ก่อนคิดเงิน)
    result = result.replaceAll("&detail_total_amount_name&", "ยอดรวมก่อนคิดเงิน");
    result = result.replaceAll("&detail_total_amount&", global.moneyFormatAndDot.format(value.detail_total_amount));
    // ยอดรวมหลังหักส่วนลด (คิดเงิน)
    result = result.replaceAll("&total_amount_after_discount_name&", "ยอดรวมหลังหักส่วนลดท้ายบิล");
    result = result.replaceAll("&total_amount_after_discount&", global.moneyFormatAndDot.format(value.total_amount_after_discount));
    // ยอดปัดเศษ (คิดเงิน)
    result = result.replaceAll("&round_amount_name&", "ปัดเศษ");
    result = result.replaceAll("&round_amount&", global.moneyFormatAndDot.format(value.round_amount));
    // รวมทั้งสิ้น (คิดเงินแล้ว)
    result = result.replaceAll("&total_amount_name&", "ยอดรวมสุทธิ");
    result = result.replaceAll("&total_amount&", global.moneyFormatAndDot.format(value.total_amount));
    // ยอดก่อนภาษีมูลค่าเพิ่ม สินค้ายกเว้นภาษี
    result = result.replaceAll("&total_before_except_vat_name&", "มูลค่าสินค้ายกเว้นภาษี");
    result = result.replaceAll("&total_before_except_vat&", global.moneyFormatAndDot.format(value.amount_except_vat));
    // ยอดก่อนภาษีมูลค่าเพิ่ม
    result = result.replaceAll("&total_before_vat_name&", "มูลค่าก่อนภาษี");
    result = result.replaceAll("&total_before_vat&", global.moneyFormatAndDot.format(value.amount_before_calc_vat));
    // ภาษี
    result = result.replaceAll("&total_vat_name&", "ภาษีมูลค่าเพิ่ม : ${global.moneyFormat.format(value.vat_rate)}%");
    result = result.replaceAll("&total_vat&", global.moneyFormatAndDot.format(value.total_vat_amount));
    // เงินสด
    result = result.replaceAll("&total_pay_cash_name&", "ชำระเงินสด");
    result = result.replaceAll("&total_pay_cash&", global.moneyFormatAndDot.format(value.pay_cash_amount));
    // เงินทอน
    result = result.replaceAll("&total_pay_cash_change_name&", "เงินทอน");
    result = result.replaceAll("&total_pay_cash_change&", global.moneyFormatAndDot.format(value.pay_cash_change));
    // ชำระด้วย QR Code
    result = result.replaceAll("&total_pay_qr_name&", "ชำระด้วย QR Code");
    result = result.replaceAll("&total_pay_qr&", global.moneyFormatAndDot.format(value.sum_qr_code));

    result = result.replaceAll("&total_pay_qr_transaction&", "เลขธุรกรรม");
    result = result.replaceAll("&total_pay_qr_transaction_value&", value.trancsaction_id);

    // ชำระด้วย Credit Card
    result = result.replaceAll("&total_pay_credit_card_name&", "ชำระด้วยบัตรเครดิต");
    result = result.replaceAll("&total_pay_credit_card&", global.moneyFormatAndDot.format(value.sum_credit_card));
    // ชำระด้วยเงินโอน
    result = result.replaceAll("&total_pay_transfer_name&", "ชำระด้วยเงินโอน");
    result = result.replaceAll("&total_pay_transfer&", global.moneyFormatAndDot.format(value.sum_money_transfer));
    // ชำระด้วยเช็ค
    result = result.replaceAll("&total_pay_cheque_name&", "ชำระด้วยเช็ค");
    result = result.replaceAll("&total_pay_cheque&", global.moneyFormatAndDot.format(value.sum_cheque));
    // ชำระด้วยคูปอง
    result = result.replaceAll("&total_pay_coupon_name&", "ชำระด้วยคูปอง");
    result = result.replaceAll("&total_pay_coupon&", global.moneyFormatAndDot.format(value.couponcashamount));
    // เงินเชื่อ
    result = result.replaceAll("&total_pay_credit_name&", "เงินเชื่อ");
    result = result.replaceAll("&total_pay_credit&", global.moneyFormatAndDot.format(value.sum_credit));

    return result.trim().replaceAll("  ", " ").replaceAll("  ", " ");
  }

  Future<List<PosPrintBillCommandModel>> buildCommand({required global.PosScreenModeEnum posScreenMode, required String topText, required String bottomText, bool isCopy = false}) async {
    late FormDesignObjectBoxStruct formDesign;
    List<PosPrintBillCommandModel> commandList = [];

    BillObjectBoxStruct? bill = global.billHelper.selectByDocNumber(docNumber: docNo, posScreenMode: global.posScreenToInt(posScreenMode));

    if (bill!.is_vat_register) {
      // 1=แบบย่อ,2=แบบเต็ม
      formDesign = (bill.bill_tax_type == 1) ? global.formDesignList[global.findFormByCode(global.formS02)] : global.formDesignList[global.findFormByCode(global.formS03)];
    } else {
      // ไม่จดทะเบียนภาษีมูลค่าเพิ่ม
      formDesign = global.formDesignList[global.findFormByCode(global.formS04)];
    }

    // Reset Printer
    commandList.add(PosPrintBillCommandModel(mode: 0));

    if (global.posTicket.logo) {
      // พิมพ์ Logo
      io.File file = io.File(global.getShopLogoPathName());
      if (file.existsSync()) {
        Uint8List bytes = file.readAsBytesSync();
        ui.Image getImage = await decodeImageFromList(bytes);
        final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List(), targetHeight: (getImage.height).toInt(), targetWidth: (getImage.width).toInt());
        final frame = await codec.getNextFrame();
        final image = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        bytes = image!.buffer.asUint8List();
        commandList.add(PosPrintBillCommandModel(mode: 1, image: bytes));
      }
    }
    if (topText.isNotEmpty) {
      // พิมพ์ข้อความด้านบน
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: topText, font_weight_bold: false, font_size: 32, text_align: PrintColumnAlign.center)],
        ),
      );
    }
    if (bill.is_vat_register && bill.bill_tax_type != 2 && posScreenMode == global.PosScreenModeEnum.posSale) {
      if (global.posTicket.shop_name) {
        // พิมพ์ชื่อร้าน
        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [FormDesignColumnModel(width: 1, text: global.getNameFromLanguage(global.profileSetting.company.names, languageCode), font_weight_bold: true, font_size: 32, text_align: PrintColumnAlign.center)],
            posTextSize: PosTextSize.size2,
          ),
        );
      } // ที่อยู่ร้าน
    }
    List<LanguageDataModel> branchName = [];
    Iterable<ProfileSettingBranchModel> branchModels = global.profileSetting.branch.where((element) => element.guidfixed == global.posConfig.branch.guidfixed);
    ProfileSettingBranchModel branchModel = branchModels.isNotEmpty ? branchModels.first : global.profileSetting.branch[0];
    branchName = branchModel.names;
    String address = global.getNameFromLanguage(branchName, languageCode);
    // if (global.posTicket.shop_address) {
    //   address = "$address ${global.getNameFromLanguage(global.profileSetting.company.addresses, languageCode)}";
    // }
    if (global.posTicket.shop_tax_id && bill.is_vat_register && bill.bill_tax_type != 2) {
      if (branchModel.contact.address.isNotEmpty) {
        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [FormDesignColumnModel(width: 1, text: branchModel.contact.address.first.name, text_align: PrintColumnAlign.center)],
          ),
        );
      }
      // พิมพ์ เลขที่ผู้เสียภาษี
      if (global.posConfig.branch.pos!.taxid != null && global.posConfig.branch.pos!.taxid != "") {
        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [FormDesignColumnModel(width: 1, text: "เลขประจำตัวผู้เสียภาษี : ${global.posConfig.branch.pos!.taxid}", text_align: PrintColumnAlign.center)],
          ),
        );
      }
    }
    if (posScreenMode == global.PosScreenModeEnum.posReturn) {
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: "ใบรับคืนสินค้า/ใบคืนเงิน", font_weight_bold: true, font_size: 24, text_align: PrintColumnAlign.center)],
        ),
      );
    }

    if (bill.is_vat_register && bill.bill_tax_type != 2 && posScreenMode == global.PosScreenModeEnum.posSale) {
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: address, font_weight_bold: false, font_size: 18, text_align: PrintColumnAlign.center)],
        ),
      ); //
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: global.getNameFromJsonLanguage(formDesign.names_json, languageCode), font_size: 24, font_weight_bold: true, text_align: PrintColumnAlign.center)],
        ),
      );
    }
    // เพิ่มข้อมูลสำหรับใบกำกับภาษีแบบเต็ม (bill_tax_type == 2)
    if (bill.is_vat_register && bill.bill_tax_type == 2 && posScreenMode == global.PosScreenModeEnum.posSale) {
      // Get the correct branch data
      Iterable<ProfileSettingBranchModel> branchModels = global.profileSetting.branch.where((element) => element.guidfixed == global.posConfig.branch.guidfixed);
      ProfileSettingBranchModel branchModel = branchModels.isNotEmpty ? branchModels.first : ProfileSettingBranchModel(); //หัวข้อ ใบเสร็จ/ใบกำกับภาษี(ต้นฉบับ หรือ สำเนา)
      String receiptTitle = isCopy ? "ใบเสร็จรับเงิน/ใบกำกับภาษี (สำเนา)" : "ใบเสร็จรับเงิน/ใบกำกับภาษี (ต้นฉบับ)";

      // ข้อมูลบริษัท/สาขา

      // commandList.add(PosPrintBillCommandModel(mode: 3)); // Line

      // ชื่อบริษัท
      if (branchModel.companynames.isNotEmpty) {
        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [FormDesignColumnModel(width: 1, text: "บริษัท: ${branchModel.companynames.first.name}", text_align: PrintColumnAlign.center)],
          ),
        );
      }

      // ที่อยู่บริษัท
      if (branchModel.contact.address.isNotEmpty) {
        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [FormDesignColumnModel(width: 1, text: "ที่อยู่: ${branchModel.contact.address.first.name}", text_align: PrintColumnAlign.center)],
          ),
        );
      }

      // เลขที่ผู้เสียภาษีของบริษัท
      if (branchModel.pos.taxid?.isNotEmpty ?? false) {
        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [FormDesignColumnModel(width: 1, text: "เลขประจำตัวผู้เสียภาษี: ${branchModel.pos.taxid!}", text_align: PrintColumnAlign.center)],
          ),
        );
      }
      // ชื่อสาขา
      if (branchModel.names.isNotEmpty) {
        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [FormDesignColumnModel(width: 1, text: "สาขา: ${branchModel.names.first.name} (${branchModel.code})", text_align: PrintColumnAlign.center)],
          ),
        );
      }

      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: receiptTitle, font_weight_bold: true, text_align: PrintColumnAlign.center)],
        ),
      );
      commandList.add(PosPrintBillCommandModel(mode: 3));
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: "หมายเลขเครื่อง POS : ${global.posConfig.devicenumber}", text_align: PrintColumnAlign.center)],
        ),
      );
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [
            FormDesignColumnModel(width: 1, text: "เลขที่: ${bill.doc_number}", text_align: PrintColumnAlign.left),
            FormDesignColumnModel(width: 1, text: "วันที่:${global.dateTimeFormatThaiShortMonth(bill.date_time)}", text_align: PrintColumnAlign.right),
          ],
        ),
      );

      // ข้อมูลลูกค้า
      if (bill.full_vat_name.isNotEmpty || bill.full_vat_address.isNotEmpty || bill.full_vat_tax_id.isNotEmpty) {
        // ชื่อลูกค้า

        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [
              FormDesignColumnModel(width: 1, text: "รหัสลูกค้า : ${bill.customer_code}", text_align: PrintColumnAlign.left),
              FormDesignColumnModel(width: 1, text: global.getNameFromJsonLanguage(bill.customer_name, languageCode), text_align: PrintColumnAlign.right),
            ],
          ),
        );

        if (bill.full_vat_name.isNotEmpty) {
          commandList.add(
            PosPrintBillCommandModel(
              mode: 2,
              columns: [FormDesignColumnModel(width: 1, text: "ชื่อ: ${bill.full_vat_name}", text_align: PrintColumnAlign.left)],
            ),
          );
        }

        // ที่อยู่ลูกค้า
        if (bill.full_vat_address.isNotEmpty) {
          commandList.add(
            PosPrintBillCommandModel(
              mode: 2,
              columns: [FormDesignColumnModel(width: 1, text: "ที่อยู่: ${bill.full_vat_address}", text_align: PrintColumnAlign.left)],
            ),
          );
        }

        // เบอร์โทรศัพท์ลูกค้า (ถ้ามี)
        if (bill.customer_telephone.isNotEmpty) {
          commandList.add(
            PosPrintBillCommandModel(
              mode: 2,
              columns: [FormDesignColumnModel(width: 1, text: "โทรศัพท์: ${bill.customer_telephone}", text_align: PrintColumnAlign.left)],
            ),
          );
        }

        // เลขที่ผู้เสียภาษีของลูกค้า
        if (bill.full_vat_tax_id.isNotEmpty) {
          commandList.add(
            PosPrintBillCommandModel(
              mode: 2,
              columns: [FormDesignColumnModel(width: 1, text: "เลขประจำตัวผู้เสียภาษี: ${bill.full_vat_tax_id}", text_align: PrintColumnAlign.left)],
            ),
          );
        }

        // สาขาลูกค้า (ถ้ามี)
        if (bill.full_vat_branch_number.isNotEmpty) {
          commandList.add(
            PosPrintBillCommandModel(
              mode: 2,
              columns: [FormDesignColumnModel(width: 1, text: "สาขา: ${bill.full_vat_branch_number}", text_align: PrintColumnAlign.left)],
            ),
          );
        }
      }

      commandList.add(PosPrintBillCommandModel(mode: 3)); // Line
    }
    //

    //
    if (global.posTicket.shop_tel) {
      // พิมพ์ เบอร์โทรศัพท์
      String phone = "";
      for (var item in global.profileSetting.company.phones) {
        if (item.trim().isEmpty) {
          if (phone.isNotEmpty) {
            phone += ",";
          }
          phone += item;
        }
      }
      if (phone.isNotEmpty) {
        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [FormDesignColumnModel(width: 1, text: "โทรศัพท์ : $phone", text_align: PrintColumnAlign.center)],
          ),
        );
      }
    }
    if (bill.bill_tax_type != 2) {
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: "หมายเลขเครื่อง POS : ${global.posConfig.devicenumber}", text_align: PrintColumnAlign.center)],
        ),
      );
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [
            FormDesignColumnModel(width: 1, text: bill.doc_number, text_align: PrintColumnAlign.left),
            FormDesignColumnModel(width: 1, text: global.dateTimeFormatThaiShortMonth2(bill.date_time), text_align: PrintColumnAlign.right),
          ],
        ),
      );
    }
    if (bill.is_vat_register && bill.bill_tax_type != 2) {
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: (bill.vat_type == 0) ? "(ราคารวมภาษีมูลค่าเพิ่มแล้ว)" : "(ราคาไม่รวมภาษีมูลค่าเพิ่ม)", text_align: PrintColumnAlign.center)],
        ),
      );
    }
    if (bill.customer_code.isNotEmpty && bill.bill_tax_type != 2) {
      // พิมพ์รหัสลูกค้า
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [
            FormDesignColumnModel(width: 1, text: "รหัสลูกค้า : ${bill.customer_code}", text_align: PrintColumnAlign.left),
            FormDesignColumnModel(width: 1, text: global.getNameFromJsonLanguage(bill.customer_name, languageCode), text_align: PrintColumnAlign.right),
          ],
        ),
      );
    }
    // Header
    String headerDescription = global.getNameFromLanguage(global.posConfig.billheader, global.userScreenLanguage).trim();
    if (headerDescription.isNotEmpty) {
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: headerDescription, text_align: PrintColumnAlign.center)],
        ),
      );
    }
    // Detail
    List<BillDetailObjectBoxStruct> billDetails = global.objectBoxStore
        .box<BillDetailObjectBoxStruct>()
        .query(BillDetailObjectBoxStruct_.doc_number.equals(bill.doc_number).and(BillDetailObjectBoxStruct_.is_void.equals(false)))
        .order(BillDetailObjectBoxStruct_.line_number)
        .build()
        .find();

    if (formDesign.sum_by_barcode) {
      // กรณีพิมพ์บิลแบบรวมรายการ
      List<BillDetailObjectBoxStruct> billDetailSum = [];
      for (var billDetail in billDetails) {
        bool isFound = false;
        for (var billDetailSumItem in billDetailSum) {
          if (billDetailSumItem.barcode == billDetail.barcode && billDetailSumItem.extra_json == billDetail.extra_json) {
            billDetailSumItem.qty += billDetail.qty;
            billDetailSumItem.total_amount += billDetail.total_amount;
            isFound = true;
            break;
          }
        }
        if (!isFound) {
          billDetailSum.add(billDetail);
        }
      }
      billDetails = billDetailSum;
    }

    List<FormDesignColumnModel> formDetailList = (await jsonDecode(formDesign.detail_json) as List).map((e) => FormDesignColumnModel.fromJson(e)).toList();
    List<FormDesignColumnModel> formDetailExtraList = (await jsonDecode(formDesign.detail_extra_json) as List).map((e) => FormDesignColumnModel.fromJson(e)).toList();
    List<FormDesignRowModel> formTotalRowList = (await jsonDecode(formDesign.detail_total_json) as List).map((e) => FormDesignRowModel.fromJson(e)).toList();
    // พิมพ์ หัว Column
    // Line
    commandList.add(PosPrintBillCommandModel(mode: 3));
    {
      List<FormDesignColumnModel> columns = [];
      for (var formDetail in formDetailList) {
        columns.add(FormDesignColumnModel(width: formDetail.width, text: global.getNameFromLanguage(formDetail.header_names, languageCode), text_align: formDetail.text_align, font_weight_bold: true, font_size: formDetail.font_size));
      }
      commandList.add(PosPrintBillCommandModel(mode: 2, columns: columns));
    }
    // Line
    commandList.add(PosPrintBillCommandModel(mode: 3));
    // detail
    for (var detail in billDetails) {
      {
        // รายละเอียดสินค้า
        List<FormDesignColumnModel> columns = [];
        for (var formDetail in formDetailList) {
          {
            columns.add(FormDesignColumnModel(width: formDetail.width, text: await findValueBillDetail(detail, formDetail.command_text), text_align: formDetail.text_align, font_weight_bold: false, font_size: formDetail.font_size));
          }
        }
        commandList.add(PosPrintBillCommandModel(mode: 2, columns: columns));
      }
      {
        // ส่วนเพิ่มเติม
        List<BillDetailExtraObjectBoxStruct> extraList = (await jsonDecode(detail.extra_json) as List).map((e) => BillDetailExtraObjectBoxStruct.fromJson(e)).toList();
        for (var extra in extraList) {
          List<FormDesignColumnModel> columns = [];
          for (var formDetailExtra in formDetailExtraList) {
            columns.add(
              FormDesignColumnModel(width: formDetailExtra.width, text: findValueBillDetailExtra(extra, formDetailExtra.command_text), text_align: formDetailExtra.text_align, font_weight_bold: formDetailExtra.font_weight_bold, font_size: formDetailExtra.font_size),
            );
          }
          commandList.add(PosPrintBillCommandModel(mode: 2, columns: columns));
        }
      }
    }
    // Line
    commandList.add(PosPrintBillCommandModel(mode: 3));

    {
      // ยอดรวม
      for (var formTotalRow in formTotalRowList) {
        bool isPrint = false;
        List<int> conditionCompare = [];
        if (formTotalRow.condition.isEmpty) {
          isPrint = true;
        } else {
          if (bill.total_item_vat_amount != 0 && bill.total_item_except_vat_amount != 0) {
            // มี : สินค้ามีภาษี และ สินค้ายกเว้นภาษี
            conditionCompare.add(1);
          }
          if (bill.total_discount != 0) {
            // มี : ส่วนลดท้ายบิล
            conditionCompare.add(5);
          }
          if (bill.total_discount != 0 && bill.total_amount_after_discount != bill.total_amount) {
            // ยอดไม่เท่ากับยอดรวมสุทธิ
            conditionCompare.add(6);
          }
          if (global.tempIsRestaurantSystem) {
            conditionCompare.add(7);
          }
          // Scan
          for (int index = 0; index < formTotalRow.condition.length; index++) {
            for (int find = 0; find < conditionCompare.length; find++) {
              if (formTotalRow.condition[index] == conditionCompare[find]) {
                isPrint = true;
                break;
              }
            }
          }
        }
        if (isPrint) {
          bool isZero = true;
          List<FormDesignColumnModel> columns = [];
          for (int index = 0; index < formTotalRow.columns.length; index++) {
            FormDesignColumnModel formTotalColumn = formTotalRow.columns[index];

            if (formTotalColumn.command_text == "&total_pay_qr_transaction_value&") {
              if (bill.trancsaction_id.isNotEmpty) {
                columns.add(FormDesignColumnModel(width: formTotalColumn.width, text: bill.trancsaction_id, text_align: formTotalColumn.text_align, font_weight_bold: formTotalColumn.font_weight_bold, font_size: formTotalColumn.font_size));
                isZero = false;
              }
            } else {
              double value = (double.tryParse(findValueBillTotal(bill, formTotalColumn.command_text).replaceAll(",", "")) ?? 0);
              if (value != 0) {
                isZero = false;
              }
              // พิมพ์ยอดรวม
              columns.add(
                FormDesignColumnModel(
                  width: formTotalColumn.width,
                  text: findValueBillTotal(bill, formTotalColumn.command_text) /*+
                      formTotalColumn.command_text*/,
                  text_align: formTotalColumn.text_align,
                  font_weight_bold: formTotalColumn.font_weight_bold,
                  font_size: formTotalColumn.font_size,
                ),
              );
              // ถ้าไม่มีภาษี (1=ถ้าแบบฟอร์มไม่มีภาษีไม่ต้องพิมพ์)
              if (formTotalColumn.condition_join_is_vat_register == 1 && bill.is_vat_register == false) {
                isZero = true;
              }
            }
          }

          if (isZero == false) {
            commandList.add(PosPrintBillCommandModel(mode: 2, columns: columns));
          }
        }
      }
    }
    // Line
    commandList.add(PosPrintBillCommandModel(mode: 3));
    // Footer
    String footerDescription = global.getNameFromLanguage(global.posConfig.billfooter, global.userScreenLanguage).trim();
    if (footerDescription.isNotEmpty) {
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: footerDescription, text_align: PrintColumnAlign.center)],
        ),
      );
    }
    // Line
    commandList.add(PosPrintBillCommandModel(mode: 3));
    //
    commandList.add(
      PosPrintBillCommandModel(
        mode: 2,
        columns: [
          FormDesignColumnModel(width: 1, text: "${bill.cashier_code} ${bill.cashier_name}", text_align: PrintColumnAlign.left),
          FormDesignColumnModel(width: 1, text: global.dateTimeFormatThaiShortMonth(bill.date_time, showTime: true), text_align: PrintColumnAlign.right),
        ],
      ),
    );
    if (bill.getpoint > 0) {
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: "รหัสสะสมแต้ม ${bill.points_code}", text_align: PrintColumnAlign.left)],
        ),
      );

      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: "แต้มที่ได้รับ ${bill.getpoint} แต้ม", text_align: PrintColumnAlign.left)],
        ),
      );
    }
    commandList.add(PosPrintBillCommandModel(mode: 3));
    if (bill.getpoint > 0) {
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [
            FormDesignColumnModel(width: 1, text: "แต้มคงเหลือ", text_align: PrintColumnAlign.left),
            FormDesignColumnModel(width: 1, text: global.moneyFormatAndDot.format(bill.point_balance_after), text_align: PrintColumnAlign.right),
          ],
        ),
      );
    }

    // 🎯 แสดงยอดรวมที่ประหยัดได้จากโปรโมชั่น (ท้ายบิล - ตัวโตๆ)
    if (kDebugMode) {
      print('[Print] 🔍 Checking promotion discount: ${bill.total_discount_from_promotion} บาท');
    }

    if (bill.total_discount_from_promotion > 0) {
      if (kDebugMode) {
        print('[Print] ✅ Adding promotion banner to receipt');
      }

      commandList.add(PosPrintBillCommandModel(mode: 3)); // เส้นคั่น
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [
            FormDesignColumnModel(
              width: 100,
              text: "🎉 ประหยัดไปแล้ว ${global.moneyFormat.format(bill.total_discount_from_promotion)} บาท! 🎉",
              text_align: PrintColumnAlign.center,
              font_weight_bold: true,
              font_size: 24, // ตัวโต
            ),
          ],
        ),
      );
      commandList.add(PosPrintBillCommandModel(mode: 3)); // เส้นคั่น
    } else {
      if (kDebugMode) {
        print('[Print] ❌ No promotion discount - banner NOT added');
      }
    }

    if (bottomText.isNotEmpty) {
      // พิมพ์ข้อความด้านล่าง
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: bottomText, font_weight_bold: false, font_size: 32, text_align: PrintColumnAlign.center)],
        ),
      );
    }
    // พิมพ์หมายเลขโต๊ะ ถ้ามี
    String tableOrDelivery = "";
    if (bill.is_delivery) {
      tableOrDelivery = "${bill.delivery_code} ${bill.delivery_number}";
    } else {
      if (bill.table_number.isNotEmpty) {
        tableOrDelivery = "โต๊ะ ${bill.table_number}";
      }
    }
    if (tableOrDelivery.isNotEmpty) {
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: tableOrDelivery, font_weight_bold: false, font_size: 32, text_align: PrintColumnAlign.center)],
        ),
      );
    }
    {
      // promotion list (รายละเอียดโปรโมชั่น)
      List<dynamic> promotionJsonList = jsonDecode(bill.promotion_json);
      List<PosProcessPromotionModel> promotionList = promotionJsonList.map((e) => PosProcessPromotionModel.fromJson(e)).toList();
      if (promotionList.isNotEmpty) {
        // Line
        commandList.add(PosPrintBillCommandModel(mode: 3));
        //
        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [FormDesignColumnModel(width: 1, text: "โปรโมชั่นสินค้าที่ได้", font_weight_bold: true, font_size: 32, text_align: PrintColumnAlign.left)],
          ),
        );
        //
        for (int index = 0; index < promotionList.length; index++) {
          // แสดงชื่อโปรโมชั่นและจำนวนครั้ง
          commandList.add(
            PosPrintBillCommandModel(
              mode: 2,
              columns: [
                FormDesignColumnModel(width: 3, text: "${global.getNameFromJsonLanguage(promotionList[index].promotion_name, languageCode)} x ${promotionList[index].count}", font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.left),
                FormDesignColumnModel(width: 1, text: promotionList[index].discount_amount != 0 ? global.moneyFormatAndDot.format(promotionList[index].discount_amount) : "", font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.right),
              ],
            ),
          );
          // ✅ แสดงรายละเอียด (description) ถ้ามี
          if (promotionList[index].description.isNotEmpty) {
            commandList.add(
              PosPrintBillCommandModel(
                mode: 2,
                columns: [FormDesignColumnModel(width: 1, text: "  ${promotionList[index].description}", font_weight_bold: false, font_size: 22, text_align: PrintColumnAlign.left)],
              ),
            );
          }
          // ✅ แสดงรายละเอียดเพิ่มเติม (discount_word) ถ้ามี
          if (promotionList[index].discount_word.isNotEmpty) {
            commandList.add(
              PosPrintBillCommandModel(
                mode: 2,
                columns: [FormDesignColumnModel(width: 1, text: "  ${promotionList[index].discount_word}", font_weight_bold: false, font_size: 20, text_align: PrintColumnAlign.left)],
              ),
            );
          }
        }
      }
    }
    {
      // promotion list (รายละเอียดโปรโมชั่น) ท้ายบิล
      List<dynamic> promotionJsonList = jsonDecode(bill.promotion_bottom_json);
      List<PosProcessPromotionModel> promotionList = promotionJsonList.map((e) => PosProcessPromotionModel.fromJson(e)).toList();
      if (promotionList.isNotEmpty) {
        // Line
        commandList.add(PosPrintBillCommandModel(mode: 3));
        //
        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [FormDesignColumnModel(width: 1, text: "โปรโมชั่นยอดรวมที่ได้", font_weight_bold: true, font_size: 32, text_align: PrintColumnAlign.left)],
          ),
        );
        //
        for (int index = 0; index < promotionList.length; index++) {
          // แสดงชื่อโปรโมชั่นและจำนวนครั้ง
          commandList.add(
            PosPrintBillCommandModel(
              mode: 2,
              columns: [
                FormDesignColumnModel(width: 3, text: "${global.getNameFromJsonLanguage(promotionList[index].promotion_name, languageCode)} x ${promotionList[index].count} ครั้ง", font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.left),
                FormDesignColumnModel(width: 1, text: global.moneyFormatAndDot.format(promotionList[index].discount_amount), font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.right),
              ],
            ),
          );
          // ✅ แสดงรายละเอียด (description) ถ้ามี
          if (promotionList[index].description.isNotEmpty) {
            commandList.add(
              PosPrintBillCommandModel(
                mode: 2,
                columns: [FormDesignColumnModel(width: 1, text: "  ${promotionList[index].description}", font_weight_bold: false, font_size: 22, text_align: PrintColumnAlign.left)],
              ),
            );
          }
          // ✅ แสดงรายละเอียดเพิ่มเติม (discount_word) ถ้ามี
          if (promotionList[index].discount_word.isNotEmpty) {
            commandList.add(
              PosPrintBillCommandModel(
                mode: 2,
                columns: [FormDesignColumnModel(width: 1, text: "  ${promotionList[index].discount_word}", font_weight_bold: false, font_size: 20, text_align: PrintColumnAlign.left)],
              ),
            );
          }
        }
      }
    }
    {
      // promotion list (รายละเอียดโปรโมชั่น) ท้ายบิล BONUS
      List<dynamic> promotionJsonList = jsonDecode(bill.promotion_bonus_json);
      List<PosProcessPromotionModel> promotionList = promotionJsonList.map((e) => PosProcessPromotionModel.fromJson(e)).toList();
      if (promotionList.isNotEmpty) {
        // Line
        commandList.add(PosPrintBillCommandModel(mode: 3));
        //
        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [FormDesignColumnModel(width: 1, text: "โปรโมชั่น ที่จุดแลกของแถม", font_weight_bold: true, font_size: 32, text_align: PrintColumnAlign.left)],
          ),
        );
        //
        for (int index = 0; index < promotionList.length; index++) {
          commandList.add(
            PosPrintBillCommandModel(
              mode: 2,
              columns: [
                FormDesignColumnModel(width: 3, text: global.getNameFromJsonLanguage(promotionList[index].promotion_name, languageCode), font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.left),
                FormDesignColumnModel(width: 1, text: global.moneyFormat.format(promotionList[index].count), font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.right),
              ],
            ),
          );
        }
      }
    }
    {
      // promotion list (รายละเอียดโปรโมชั่น) ท้ายบิล COUPON (Type 101)
      List<dynamic> promotionJsonList = jsonDecode(bill.promotion_coupon_json);
      List<PosProcessPromotionModel> promotionList = promotionJsonList.map((e) => PosProcessPromotionModel.fromJson(e)).toList();
      if (promotionList.isNotEmpty) {
        // Line
        commandList.add(PosPrintBillCommandModel(mode: 3));
        //
        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [FormDesignColumnModel(width: 1, text: "[ สิทธิพิเศษ/คูปอง ]", font_weight_bold: true, font_size: 32, text_align: PrintColumnAlign.left)],
          ),
        );
        //
        for (int index = 0; index < promotionList.length; index++) {
          commandList.add(
            PosPrintBillCommandModel(
              mode: 2,
              columns: [FormDesignColumnModel(width: 4, text: promotionList[index].description, font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.left)],
            ),
          );
        }
      }
    }
    {
      // 📊 สรุปตาม Pattern Code (แสดงเฉพาะเมื่อได้รับโปรโมชั่น House Brand)

      // ✅ ตรวจสอบว่าได้รับโปรโมชั่น House Brand หรือไม่
      List<dynamic> promotionCouponJsonList = jsonDecode(bill.promotion_coupon_json);
      List<PosProcessPromotionModel> promotionCouponList = promotionCouponJsonList.map((e) => PosProcessPromotionModel.fromJson(e)).toList();

      bool hasHouseBrandPromotion = promotionCouponList.isNotEmpty;

      // ถ้าได้รับโปรโมชั่น House Brand แล้ว ให้แสดงสรุป Pattern
      if (hasHouseBrandPromotion) {
        Map<String, PatternSummary> patternSummaries = {};

        for (var detail in billDetails) {
          if (detail.pattern_code.isNotEmpty && !detail.is_void) {
            if (!patternSummaries.containsKey(detail.pattern_code)) {
              patternSummaries[detail.pattern_code] = PatternSummary(code: detail.pattern_code, name: detail.pattern_name.isNotEmpty ? detail.pattern_name : detail.pattern_code, count: 0, totalAmount: 0);
            }
            patternSummaries[detail.pattern_code]!.count++;
            patternSummaries[detail.pattern_code]!.totalAmount += detail.total_amount;
          }
        }

        // แสดงเฉพาะถ้ามี pattern_code
        if (patternSummaries.isNotEmpty) {
          // Line separator
          commandList.add(PosPrintBillCommandModel(mode: 3));

          // Header
          commandList.add(
            PosPrintBillCommandModel(
              mode: 2,
              columns: [FormDesignColumnModel(width: 1, text: "สรุปตาม Pattern", font_weight_bold: true, font_size: 32, text_align: PrintColumnAlign.left)],
            ),
          );

          // แสดงแต่ละ pattern
          for (var pattern in patternSummaries.values) {
            commandList.add(
              PosPrintBillCommandModel(
                mode: 2,
                columns: [FormDesignColumnModel(width: 2, text: "[${pattern.code}] ${pattern.name}", font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.left)],
              ),
            );
            commandList.add(
              PosPrintBillCommandModel(
                mode: 2,
                columns: [
                  FormDesignColumnModel(width: 2, text: "  ${pattern.count} รายการ", font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.left),
                  FormDesignColumnModel(width: 2, text: global.moneyFormatAndDot.format(pattern.totalAmount), font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.right),
                ],
              ),
            );
          }
        }
      }
    }

    {
      // 💰 แสดงรายละเอียดส่วนลดพิเศษ
      List<BillDetailObjectBoxStruct> manualDiscountItems = [];

      for (var detail in billDetails) {
        if (detail.discount > 0 && !detail.is_void) {
          manualDiscountItems.add(detail);
        }
      }

      if (manualDiscountItems.isNotEmpty) {
        // Line
        commandList.add(PosPrintBillCommandModel(mode: 3));
        //
        commandList.add(
          PosPrintBillCommandModel(
            mode: 2,
            columns: [FormDesignColumnModel(width: 1, text: "[ ส่วนลดพิเศษ ]", font_weight_bold: true, font_size: 28, text_align: PrintColumnAlign.left)],
          ),
        );

        for (var detail in manualDiscountItems) {
          // แปลงชื่อสินค้าจาก JSON format เป็นภาษาปกติ
          String itemName = global.getNameFromJsonLanguage(detail.item_name, global.userScreenLanguage);

          commandList.add(
            PosPrintBillCommandModel(
              mode: 2,
              columns: [
                FormDesignColumnModel(width: 3, text: itemName, font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.left),
                FormDesignColumnModel(width: 2, text: "${global.moneyFormat.format(detail.discount)} บาท", font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.right),
              ],
            ),
          );
        }
      }
    }

    if ((bill.couponcashamount + bill.coupondiscountamount) > 0) {
      //รายการคูปอง
      commandList.add(PosPrintBillCommandModel(mode: 3)); // Line
      commandList.add(
        PosPrintBillCommandModel(
          mode: 2,
          columns: [FormDesignColumnModel(width: 1, text: "รายการคูปอง", font_weight_bold: true, font_size: 32, text_align: PrintColumnAlign.left)],
        ),
      );

      // Parse coupons from JSON
      try {
        if (bill.coupons_json.isNotEmpty) {
          List<dynamic> couponJsonList = jsonDecode(bill.coupons_json);
          List<CouponItemModel> couponList = couponJsonList.map((e) => CouponItemModel.fromJson(e)).toList();

          for (int index = 0; index < couponList.length; index++) {
            String couponDescription = couponList[index].coupondescription.isNotEmpty ? couponList[index].coupondescription : "คูปอง ${couponList[index].couponno}";

            commandList.add(
              PosPrintBillCommandModel(
                mode: 2,
                columns: [
                  FormDesignColumnModel(width: 3, text: couponDescription, font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.left),
                  FormDesignColumnModel(width: 1, text: global.moneyFormatAndDot.format(couponList[index].couponamount), font_weight_bold: false, font_size: 24, text_align: PrintColumnAlign.right),
                ],
              ),
            );
          }
        }
      } catch (e) {
        // Error parsing JSON, show totals as fallback
      }
    }
    return commandList;
  }

  Future<void> printBillByBluetoothImageMode({required global.PosScreenModeEnum posScreenMode, required bool printLogo, bool isCopy = false}) async {
    /*await PrintBluetoothThermal.connect(
        macPrinterAddress: global.printerLocalStrongData[0].ipAddress);
    bool connectStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectStatus) {
      await createImage(
          printerData: global.printerLocalStrongData[0],
          docNumber: docNo,
          printLogo: global.posTicket.logo,
          saveToFile: true,
          commandList: await buildCommand(posScreenMode));
      await PrintBluetoothThermal.writeBytes(imageBytes);
    }*/
  }

  Future<void> printBillByIpImageMode({required global.PosScreenModeEnum posScreenMode, required bool printLogo, bool isPaySlip = false, bool isCopy = false}) async {
    // ดึงข้อมูล bill
    BillObjectBoxStruct? bill = global.billHelper.selectByDocNumber(docNumber: docNo, posScreenMode: global.posScreenToInt(posScreenMode));

    var imageBytes = await global.ticketCreateImage(
      printerData: global.printerLocalStrongData[0],
      docDate: docDate,
      docNumber: docNo,
      printLogo: printLogo,
      saveToFile: true,
      qrCodeBottom: "",
      printPaySlip: printPaySlip,
      commandList: await buildCommand(posScreenMode: posScreenMode, topText: topText, bottomText: bottomText, isCopy: isCopy),
    );

    // ดึง tier_level จาก bill เพื่อส่งไปยัง print queue
    int? tierLevel = bill != null ? _getTierLevelFromBill(bill) : null;

    global.savePrintQueueToFile(
      global.printerLocalStrongData[0].deviceName,
      imageBytes,
      isPaySlip,
      docNo,
      printLogo,
      tierLevel: tierLevel, // ⭐ ส่ง tier_level
    );
  }

  Future<void> printBillByWindowsImageMode({required global.PosScreenModeEnum posScreenMode, required bool printLogo, bool isCopy = false}) async {
    // ดึงข้อมูล bill
    BillObjectBoxStruct? bill = global.billHelper.selectByDocNumber(docNumber: docNo, posScreenMode: global.posScreenToInt(posScreenMode));

    var imageBytes = await global.ticketCreateImage(
      printerData: global.printerLocalStrongData[0],
      docDate: docDate,
      docNumber: docNo,
      printLogo: printLogo,
      saveToFile: true,
      qrCodeBottom: "",
      printPaySlip: printPaySlip,
      commandList: await buildCommand(posScreenMode: posScreenMode, topText: topText, bottomText: bottomText, isCopy: isCopy),
    );

    // ดึง tier_level จาก bill เพื่อส่งไปยัง print queue
    int? tierLevel = bill != null ? _getTierLevelFromBill(bill) : null;

    global.savePrintQueueToFile(
      global.printerLocalStrongData[0].deviceName,
      imageBytes,
      true,
      docNo,
      printLogo,
      tierLevel: tierLevel, // ⭐ ส่ง tier_level
    );
    // String printerName = global.printerLocalStrongData[0].deviceName;
    // global.windowsPrintRawData(printerName, imageBytes);
  }

  Future<void> printBillByUSBImageMode({required global.PosScreenModeEnum posScreenMode, required bool printLogo, bool isCopy = false}) async {
    // ดึงข้อมูล bill
    BillObjectBoxStruct? bill = global.billHelper.selectByDocNumber(docNumber: docNo, posScreenMode: global.posScreenToInt(posScreenMode));

    var imageBytes = await global.ticketCreateImage(
      printerData: global.printerLocalStrongData[0],
      docDate: docDate,
      docNumber: docNo,
      printLogo: printLogo,
      saveToFile: true,
      qrCodeBottom: "",
      printPaySlip: printPaySlip,
      commandList: await buildCommand(posScreenMode: posScreenMode, topText: topText, bottomText: bottomText, isCopy: isCopy),
    );

    // ดึง tier_level จาก bill เพื่อส่งไปยัง print queue
    int? tierLevel = bill != null ? _getTierLevelFromBill(bill) : null;

    global.savePrintQueueToFile(
      global.printerLocalStrongData[0].deviceName,
      imageBytes,
      true,
      docNo,
      printLogo,
      tierLevel: tierLevel, // ⭐ ส่ง tier_level
    );
    // String printerName = global.printerLocalStrongData[0].deviceName;
    // global.windowsPrintRawData(printerName, imageBytes);
  }

  /*Future<void> printBillByIpTextMode() async {
    PaperSize paper = (global.printerLocalStrongData.paperSize == 1)
        ? PaperSize.mm58
        : PaperSize.mm80;
    CapabilityProfile profile = await CapabilityProfile.load();
    NetworkPrinter printer = NetworkPrinter(paper, profile);
    PosPrintResult res = await printer.connect(
        global.printerLocalStrongData.ipAddress,
        port: global.printerLocalStrongData.ipPort);

    if (res == PosPrintResult.success) {
      await buildCommand().then((value) async {
        PrintProcess printProcess = PrintProcess();
        for (var command in value) {
          // 0=Reset,1=Logo Image,2=Text,3=Line,9=Cut
          switch (command.mode) {
            case 0: // Reset
              printer.reset();
              break;
            case 1: // Logo Image
              printer.image(command.image!);
              break;
            case 2: // Text
              printProcess.columnWidth.clear();
              printProcess.column.clear();
              for (int index = 0; index < command.columns.length; index++) {
                printProcess.columnWidth.add(command.columns[index].width);
                printProcess.column.add(PrintColumn(
                    text: command.columns[index].text,
                    align: command.columns[index].align));
              }
              await printProcess.lineFeedText(
                  printer, command.posStyles ?? const PosStyles());
              break;
            case 3: // Line
              await printProcess.drawLine(printer);
              break;
            case 9: // Cut
              printer.cut();
              break;
          }
        }
      });
      printer.disconnect();
    }
  }*/

  Future<void> printBillBySunmi({required global.PosScreenModeEnum posScreenMode, required bool printLogo, bool isCopy = false}) async {
    /*await SunmiPrinter.bindingPrinter();
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);

    var imageBytes = await global.ticketCreateImage(
        printerData: global.printerLocalStrongData[0],
        docDate: docDate,
        docNumber: docNo,
        printPaySlip: printPaySlip,
        printLogo: printLogo,
        saveToFile: true,        commandList: await buildCommand(
            posScreenMode: posScreenMode,
            topText: topText,
            bottomText: bottomText,
            isCopy: isCopy));
    try {
      SunmiPrinter.printRawData(Uint8List.fromList(imageBytes));
    } catch (e, s) {
      global.sendErrorToDevTeam(
          "pos_print.dart->printBillBySunmi", "printBillBySunmi : $e : $s");
    }

    await SunmiPrinter.submitTransactionPrint();
    await SunmiPrinter.exitTransactionPrint(true);
    // ต้อง delay หน่วงเวลาเพื่อให้ปริ้นเตอร์ทำงานเสร็จ 1 วินาที ถึงจะปิดการเชื่อมต่อได้
    await Future.delayed(const Duration(seconds: 1));*/
  }

  /// ⭐ บันทึกรูปบิลไปที่ /posbill โดยไม่ต้องพึ่งเครื่องพิมพ์
  /// ใช้ default printer settings ถ้าไม่มีเครื่องพิมพ์เชื่อมต่อ
  Future<void> _saveBillImageOnly({required global.PosScreenModeEnum posScreenMode, required bool printLogo, bool isCopy = false}) async {
    try {
      // ใช้ default printer data หรือ printer ตัวแรกถ้ามี
      PrinterLocalStrongDataModel printerData;
      if (global.printerLocalStrongData.isNotEmpty) {
        printerData = global.printerLocalStrongData[0];
      } else {
        // สร้าง default printer data สำหรับบันทึกรูป (80mm paper)
        printerData = PrinterLocalStrongDataModel(
          deviceName: 'default',
          ipAddress: '',
          ipPort: 9100,
          paperType: 2, // 80mm
          printerConnectType: global.PrinterConnectEnum.ip,
          isConfigConnectSuccess: false,
          vendorId: '',
          productId: '',
        );
      }

      // สร้าง command list สำหรับ bill
      final commandList = await buildCommand(posScreenMode: posScreenMode, topText: topText, bottomText: bottomText, isCopy: isCopy);

      // สร้าง image จาก command list
      final imageBytes = await global.ticketCreateImage(
        printerData: printerData,
        docDate: docDate,
        docNumber: docNo,
        printLogo: printLogo,
        saveToFile: false, // ไม่ใช้ saveToFile เพราะเราจะบันทึกเอง
        qrCodeBottom: "",
        printPaySlip: printPaySlip,
        commandList: commandList,
      );

      // ⭐ บันทึกรูปไปที่ /posbill ผ่าน ticketSaveImageToJpgFile
      // สร้าง ui.Image จาก bytes
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;

      // บันทึกไปที่ /posbill
      await global.ticketSaveImageToJpgFile(docDate, docNo, Future.value(uiImage));

      if (kDebugMode) {
        print('[SaveBill] ✅ Bill image saved to /posbill: $docNo');
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[SaveBill] ❌ Error saving bill image: $e');
        print('[SaveBill] Stack: $s');
      }
    }
  }

  Future<void> printBill({required global.PosScreenModeEnum posScreenMode, required bool isPaySlip, required bool printLogo}) async {
    loadFormDesign();

    // Check if this is a full VAT invoice that needs a copy
    BillObjectBoxStruct? bill = global.billHelper.selectByDocNumber(docNumber: docNo, posScreenMode: global.posScreenToInt(posScreenMode));
    bool shouldPrintCopy = bill != null && bill.is_vat_register && bill.bill_tax_type == 2;

    // ⭐ บันทึกรูปบิลไปที่ /posbill ก่อนเสมอ (ไม่ต้องพึ่งเครื่องพิมพ์)
    await _saveBillImageOnly(posScreenMode: posScreenMode, printLogo: printLogo, isCopy: false);

    // ตรวจสอบว่าเครื่องพิมพ์พร้อมหรือไม่ ถ้าไม่พร้อมก็จบแค่บันทึกรูป
    // if (global.printerLocalStrongData.isEmpty || !global.printerLocalStrongData[0].isConfigConnectSuccess) {
    //   if (kDebugMode) {
    //     print('[Print] ⚠️ Printer is not configured or disabled, bill image saved but skipping print');
    //   }
    //   return;
    // }
    if (global.printerLocalStrongData.isEmpty) {
      if (kDebugMode) {
        print('[Print] ⚠️ Printer is not configured or disabled, bill image saved but skipping print');
      }
      return;
    }

    // Print original
    switch (global.printerLocalStrongData[0].printerConnectType) {
      case global.PrinterConnectEnum.ip:
        await printBillByIpImageMode(posScreenMode: posScreenMode, printLogo: printLogo, isPaySlip: isPaySlip, isCopy: false);
        break;
      case global.PrinterConnectEnum.bluetooth:
        await printBillByBluetoothImageMode(posScreenMode: posScreenMode, printLogo: printLogo, isCopy: false);
        break;
      case global.PrinterConnectEnum.usb:
        await printBillByUSBImageMode(posScreenMode: posScreenMode, printLogo: printLogo, isCopy: false);
        break;
      case global.PrinterConnectEnum.windows:
        await printBillByWindowsImageMode(posScreenMode: posScreenMode, printLogo: printLogo, isCopy: false);
        break;
      case global.PrinterConnectEnum.sunmi1:
        await printBillBySunmi(posScreenMode: posScreenMode, printLogo: printLogo, isCopy: false);
        break;
    }

    // Print copy for full VAT invoices
    if (shouldPrintCopy) {
      // Add delay between original and copy printing
      await Future.delayed(const Duration(seconds: 2));

      switch (global.printerLocalStrongData[0].printerConnectType) {
        case global.PrinterConnectEnum.ip:
          await printBillByIpImageMode(posScreenMode: posScreenMode, printLogo: printLogo, isPaySlip: isPaySlip, isCopy: true);
          break;
        case global.PrinterConnectEnum.bluetooth:
          await printBillByBluetoothImageMode(posScreenMode: posScreenMode, printLogo: printLogo, isCopy: true);
          break;
        case global.PrinterConnectEnum.usb:
          await printBillByUSBImageMode(posScreenMode: posScreenMode, printLogo: printLogo, isCopy: true);
          break;
        case global.PrinterConnectEnum.windows:
          await printBillByWindowsImageMode(posScreenMode: posScreenMode, printLogo: printLogo, isCopy: true);
          break;
        case global.PrinterConnectEnum.sunmi1:
          await printBillBySunmi(posScreenMode: posScreenMode, printLogo: printLogo, isCopy: true);
          break;
      }
    }
  }
}
