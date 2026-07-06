import 'dart:convert';

import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/json/member_model.dart';
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/features/pos/presentation/screens/pay/pay_util.dart';
import 'dart:async';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/order_temp_struct.dart';
import 'package:dedecashier/model/objectbox/pos_log_struct.dart';
import 'package:dedecashier/services/coupon_manager.dart';
import 'package:dedecashier/services/coupon_api_service.dart';
import 'package:dedecashier/model/coupon/coupon_model.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

/// Helper function เพื่อแปลง pattern_code เป็น pattern_name
/// ถ้าไม่มีใน mapping จะคืนค่า code เดิม
String _getPatternName(String patternCode) {
  if (patternCode.isEmpty) return '';

  // Mapping ของ pattern codes ที่รู้จัก
  const Map<String, String> patternNames = {
    'HB': 'สินค้าเฮาส์แบรนด์',
    'PREMIUM': 'สินค้าพรีเมี่ยม',
    'SALE': 'สินค้าลดราคา',
    'NEW': 'สินค้าใหม่',
    'PROMO': 'สินค้าโปรโมชั่น',
  };

  return patternNames[patternCode] ?? patternCode;
}

class SaveBillResultClass {
  late String docNumber;
  late DateTime docDate;
  late String guidPos;
}

Future<String> billRunning(int docMode) async {
  try {
    // Type 0=คริสต์ศักราช,1=พุทธศักราช
    // YYYY = ปี
    // MM = เดือน
    // DD = วัน
    // ###### = ลำดับ mn
    // ตัวอย่าง 001################ สำหรับ Tax ABB เครื่อง POS (001=รหัสเครื่อง POS)
    // ตัวอย่าง 002YYMMDD########## สำหรับ Tax ABB เครื่อง  POS (002=รหัสเครื่อง POS)
    // ตัวอย่าง SO-YYMMDD-###### สำหรับขาย
    // ตัวอย่าง PO-YYMMDD-###### สำหรับซื้อ
    DateTime dateTimeNow = DateTime.now();

    String dateNow = intl.DateFormat('yyyyMMdd').format(dateTimeNow);
    String result = "";
    String countDigit = "";
    String lastDigit = "";
    for (var item in global.posConfig.docformatinv.split("")) {
      if (item == "#") {
        countDigit += "0";
        lastDigit += "9";
      }
    }
    String docFormat = global.posConfig.doccode;

    if (docMode == 1) {
      docFormat += global.posConfig.docformatinv.replaceAll("#", "");
    } else if (docMode == 2) {
      docFormat += global.posConfig.docformatesalereturn.replaceAll("#", "");
    } else {
      docFormat += global.posConfig.docformatinv.replaceAll("#", "");
    }
    docFormat = docFormat.replaceAll("YYYY", dateNow.substring(0, 4));
    docFormat = docFormat.replaceAll("YY", dateNow.substring(2, 4));
    docFormat = docFormat.replaceAll("MM", dateNow.substring(4, 6));
    docFormat = docFormat.replaceAll("DD", dateNow.substring(6, 8));
    int number = 0;

    if (global.last_doc_no.isNotEmpty &&
        global.last_doc_no.contains(docFormat)) {
      number = int.parse(
        global.last_doc_no.substring(
          global.last_doc_no.length - countDigit.length,
        ),
      );
    } else {
      List<BillObjectBoxStruct> allDocs = global.objectBoxStore
          .box<BillObjectBoxStruct>()
          .query(
            BillObjectBoxStruct_.doc_number.lessOrEqual(docFormat + lastDigit),
          )
          .order(BillObjectBoxStruct_.doc_number, flags: Order.descending)
          .build()
          .find();

      var filteredDocs = allDocs
          .where((doc) => !doc.doc_number.contains('-x'))
          .toList();
      filteredDocs.sort((a, b) => b.doc_number.compareTo(a.doc_number));

      var getLast = filteredDocs.isNotEmpty ? filteredDocs.first : null;

      if (getLast != null) {
        try {
          if (getLast.doc_number.substring(0, docFormat.length) == docFormat) {
            number = int.parse(
              getLast.doc_number.substring(
                getLast.doc_number.length - countDigit.length,
              ),
            );
          }
        } catch (e) {
          number = 0;
        }
      } else {
        // ค้นหาข้อมูลบน Cloud
        var lastDocNumberJson = await ApiRepository().serverGetLastDocNumber(
          docNumber: docFormat + lastDigit,
        );
        String lastDocNumber = "";
        try {
          lastDocNumber = lastDocNumberJson.data;
          try {
            AppLogger.debug(
              "lastDocNumber:${lastDocNumber.substring(0, docFormat.length)}",
            );
            if (lastDocNumber.substring(0, docFormat.length) == docFormat) {
              number = int.parse(
                lastDocNumber.substring(
                  lastDocNumber.length - countDigit.length,
                ),
              );
            } else {
              number = 0;
              lastDocNumber = "";
            }
          } catch (e) {
            number = 0;
          }
        } catch (e) {
          number = 0;
          //AppLogger.error(e);
        }
        if (lastDocNumber.isNotEmpty) {
          number = int.parse(
            lastDocNumber.substring(lastDocNumber.length - countDigit.length),
          );
        }
      }
    }
    result = "$docFormat${(intl.NumberFormat(countDigit)).format(number + 1)}";
    global.last_doc_no = result;

    return global.last_doc_no;
  } catch (e, stackTrace) {
    AppLogger.error(
      "global.dart->billRunning"
      "billRunning : $e ${stackTrace.toString()}",
    );
    // sendErrorToDevTeam("global.dart->billRunning", "billRunning : $e ${stackTrace.toString()}");
    return const Uuid().v4();
  }
}

/// บันทึกบิล
Future<SaveBillResultClass> saveBill({
  required int docMode,
  required double totalAmountAfterDiscount,
  required double roundAmount,
  required double totalAmount,
  required double cashAmount,
  required String discountFormula,
  required double discountAmount,
  required String tableNumber,
  required bool isDelivery,
  required String deliveryNumber,
  required String deliveryCode,
  required String posHoldActiveCode,
  required String pointscode,
}) async {
  SaveBillResultClass result = SaveBillResultClass();

  bool isSaved = false;

  PosHoldProcessModel posHoldProcess =
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(
        posHoldActiveCode,
      )];

  while (!isSaved) {
    String docNumber = await billRunning(docMode);
    DateTime docDate = DateTime.now();

    String guidpos = const Uuid().v4();
    result.docNumber = docNumber;
    result.docDate = docDate;
    result.guidPos = guidpos;
    // จ่าย
    List<BillPayObjectBoxStruct> pays = [];
    // บัตรเครดิต
    for (var value
        in global
            .posHoldProcessResult[global.findPosHoldProcessResultIndex(
              posHoldActiveCode,
            )]
            .payScreenData
            .credit_card) {
      pays.add(
        BillPayObjectBoxStruct(
          trans_flag: 1,
          provider_name: "บัตรเครดิต",
          book_bank_code: value.book_bank_code,
          bank_code: value.bank_code,
          bank_name: value.bank_name,
          card_number: value.card_number,
          amount: value.amount,
        ),
      );
    }
    // เงินโอน
    for (var value
        in global
            .posHoldProcessResult[global.findPosHoldProcessResultIndex(
              posHoldActiveCode,
            )]
            .payScreenData
            .transfer) {
      pays.add(
        BillPayObjectBoxStruct(
          trans_flag: 2,
          provider_name: "เงินโอน",
          bank_code: value.bank_code,
          bank_name: value.bank_name,
          book_bank_code: value.book_bank_code,
          amount: value.amount,
        ),
      );
    }
    // เช็ค
    for (var value
        in global
            .posHoldProcessResult[global.findPosHoldProcessResultIndex(
              posHoldActiveCode,
            )]
            .payScreenData
            .cheque) {
      BillPayObjectBoxStruct data = BillPayObjectBoxStruct(
        trans_flag: 3,
        provider_name: "เช็ค",
        bank_code: value.bank_code,
        bank_name: value.bank_name,
        cheque_number: value.cheque_number,
        branch_number: value.branch_number,
        amount: value.amount,
      );
      data.due_date = value.due_date;
      pays.add(data);
    }
    // คูปอง
    for (var value
        in global
            .posHoldProcessResult[global.findPosHoldProcessResultIndex(
              posHoldActiveCode,
            )]
            .payScreenData
            .coupon) {
      if (value.coupon_type == 2) {
        pays.add(
          BillPayObjectBoxStruct(
            trans_flag: 4,
            provider_name: "คูปอง",
            number: value.number,
            description: value.description,
            amount: value.cash_voucher_amount,
          ),
        );
      }
    }

    // จ่ายด้วย QR
    String transactionId = "";
    for (var value
        in global
            .posHoldProcessResult[global.findPosHoldProcessResultIndex(
              posHoldActiveCode,
            )]
            .payScreenData
            .qr) {
      if (value.transactionId.isNotEmpty) {
        transactionId = value.transactionId;
      }
      pays.add(
        BillPayObjectBoxStruct(
          trans_flag: 5,
          provider_code: value.provider_code,
          provider_name: value.provider_name,
          description: transactionId != "" ? transactionId : value.description,
          amount: value.amount,
        ),
      );
    }

    // รายละเอียด
    int lineNumber = 1;
    List<BillDetailObjectBoxStruct> details = [];
    for (var value in posHoldProcess.posProcess.details) {
      if (!value.is_void) {
        List<BillDetailExtraObjectBoxStruct> detailExtras = [];
        for (var element in value.extra) {
          detailExtras.add(
            BillDetailExtraObjectBoxStruct(
              barcode: element.barcode,
              refbarcode: element.refbarcode,
              refunitcode: element.refunitcode,
              item_code: element.item_code,
              item_name: element.item_name,
              unit_code: element.unit_code,
              unit_name: element.unit_name,
              qty: element.qty,
              price: element.price,
              // ***
              price_exclude_vat: element.price_exclude_vat,
              vat_type: element.vat_type,
              //
              is_except_vat: element.is_except_vat,
              total_amount: element.total_amount,
            ),
          );
        }
        details.add(
          BillDetailObjectBoxStruct(
            guidpos: guidpos,
            doc_mode: docMode,
            doc_number: docNumber,
            line_number: lineNumber,
            barcode: value.barcode,
            item_code: value.item_code,
            item_name: value.item_name,
            unit_code: value.unit_code,
            unit_name: value.unit_name,
            sku: "",
            is_void: value.is_void,
            qty: value.qty,
            price: value.price,
            price_original: value.price_original,
            discount_text: value.discount_text,
            discount: value.discount,
            is_except_vat: value.is_except_vat,
            extra_json: jsonEncode(detailExtras),
            total_amount: value.total_amount,
            vat_type: value.vat_type,
            price_exclude_vat: value.price_exclude_vat,
            food_type: value.food_type,
            description: value.remark,
            issumpoint: value.issumpoint,
            pattern_code: value.pattern_code,
            pattern_name: _getPatternName(value.pattern_code),
          ),
        );
        lineNumber++;
      }
    }
    // รายละเอียดโต๊ะ (DEDE POS Cafe)
    int manCount = 0;
    int womanCount = 0;
    int childCount = 0;
    String buffetCode = "";
    // ยอดรวมก่อนคำนวณภาษี
    // Save
    int billTaxType = 0;
    if (global.posConfig.isvatregister == false) {
      // ถ้าไม่ลงทะเบียนภาษีมูลค่าเพิ่ม
      billTaxType = 0;
    } else {
      // ถ้าลงทะเบียนภาษีแล้ว ให้เป็น 1=อย่างย่อ
      billTaxType = 1;
      // ในกรณีที่เป็นลูกหนี้ออกแบบเต็มแบบ Makro อัตโนมัติ
      // billTaxType = 2;
    }

    // Get current open shift's doc_no (empty string if no shift open)
    String currentShiftDocNo = "";
    try {
      final currentOpenShift = global.shiftHelper.getLastOpenShift(
        global.posConfig.code,
      );
      if (currentOpenShift != null) {
        currentShiftDocNo = currentOpenShift.docno;
      }
    } catch (e) {
      AppLogger.error("Error getting current shift doc_no: $e");
    } // คำนวณยอดแต้มคงเหลือหลังการทำรายการ
    double currentPointBalance = 0.0;
    double pointBalanceAfter = 0.0;

    // ถ้ามีลูกค้า ให้ดึงยอดแต้มปัจจุบัน
    if (posHoldProcess.customerCode.isNotEmpty) {
      try {
        List<MemberModel> memberResult = [];

        // ลองดึงข้อมูลจาก API ก่อนถ้า online
        if (global.isOnline) {
          try {
            AppLogger.debug(
              'Online mode: fetching customer point balance from API...',
            );
            memberResult = await ApiRepository().findMemberByTelName(
              posHoldProcess.customerCode,
              0,
              1,
            );
          } catch (e) {
            AppLogger.error(
              'API call failed: $e, falling back to local database...',
            );
          }
        }

        // ถ้าไม่พบข้อมูลจาก API หรือไม่ online ให้ดึงจาก local database
        if (memberResult.isEmpty) {
          AppLogger.debug(
            'Fetching customer point balance from local database...',
          );
          final customer = global.customerHelper.selectByCode(
            code: posHoldProcess.customerCode,
          );
          if (customer != null) {
            // แปลง CustomerObjectBoxStruct เป็น MemberModel
            memberResult = [
              MemberModel(
                code: customer.code,
                guidfixed: customer.guidfixed,
                pointbalance: customer.pointbalance,
                pointscode: customer.pointscode,
                email: customer.email,
                names: [LanguageDataModel(code: 'th', name: customer.name)],
                addressforbilling: MemberAddressForBillingModel(
                  address: [customer.address],
                  phoneprimary: customer.tel,
                  phonesecondary: '',
                  contactnames: [
                    LanguageDataModel(code: 'th', name: customer.name),
                  ],
                ),
              ),
            ];
          }
        }

        if (memberResult.isNotEmpty) {
          currentPointBalance = memberResult.first.pointbalance;
          AppLogger.debug(
            'Current point balance for customer ${posHoldProcess.customerCode}: $currentPointBalance',
          );
        }
      } catch (e) {
        AppLogger.error('Error loading customer point balance: $e');
        currentPointBalance = 0.0;
      }

      if (pointscode == posHoldProcess.customerPointsCode) {
        pointBalanceAfter =
            currentPointBalance -
            posHoldProcess.posProcess.usepoint +
            posHoldProcess.posProcess.getpoint;
      } else {
        pointBalanceAfter =
            currentPointBalance - posHoldProcess.posProcess.usepoint;
      }
    }

    double getPointTemp = 0;
    if (pointscode.isNotEmpty) {
      getPointTemp = posHoldProcess.posProcess.getpoint;
    }

    // 💰 คำนวณยอดรวมส่วนลดและส่วนต่างทั้งหมด
    double totalPromotionSavings = 0;

    // 1. ส่วนต่างจากราคาพิเศษ (price_original - price)
    for (var detail in posHoldProcess.posProcess.details) {
      if (detail.price_original > detail.price && detail.price > 0) {
        totalPromotionSavings +=
            (detail.price_original - detail.price) * detail.qty;
      }

      // 2. ส่วนลดในแต่ละบรรทัดที่ป้อนมือ (detail.discount)
      // Note: detail.discount เป็นยอดรวมแล้ว ไม่ต้องคูณด้วย qty
      if (detail.discount > 0) {
        totalPromotionSavings += detail.discount;
      }
    }

    // 3. ส่วนลดท้ายบิล + แต้ม + คูปอง จะถูกเพิ่มเข้าไปทีหลัง (detail_total_discount)

    if (kDebugMode) {
      print(
        '[SaveBill] 💰 Price Difference & Manual Discount: $totalPromotionSavings บาท',
      );
      print(
        '[SaveBill] 💰 Bottom Discount + Points + Coupon: ${posHoldProcess.posProcess.detail_total_discount} บาท',
      );
      print(
        '[SaveBill] 💰 Grand Total Savings: ${totalPromotionSavings + posHoldProcess.posProcess.detail_total_discount} บาท',
      );
    }

    BillObjectBoxStruct billData = BillObjectBoxStruct(
      doc_mode: docMode, // 1=ขาย,2=คืน
      guidpos: guidpos,
      points_code: pointscode,
      bill_tax_type: billTaxType,
      vat_type: posHoldProcess.posProcess.vat_type,
      trancsaction_id: transactionId,
      is_cancel: false,
      cancel_date_time: "",
      cancel_user_code: "",
      cancel_user_name: "",
      cancel_description: "",
      cancel_reason: "",
      full_vat_address: "",
      full_vat_branch_number: "",
      full_vat_name: "",
      full_vat_doc_number: "",
      full_vat_print: false,
      full_vat_tax_id: "",
      table_al_la_crate_mode: false,
      table_number: tableNumber,
      child_count: childCount,
      woman_count: womanCount,
      man_count: manCount,
      buffet_code: buffetCode,
      total_qty: posHoldProcess.posProcess.total_piece,
      print_copy_bill_date_time: [],
      date_time: docDate,
      table_close_date_time: DateTime.now(),
      table_open_date_time: DateTime.now(),
      doc_number: docNumber,
      customer_code: posHoldProcess.customerCode,
      customer_name: posHoldProcess.customerName,
      customer_telephone: posHoldProcess.customerPhone,
      sale_code: posHoldProcess.saleCode,
      sale_name: posHoldProcess.saleName,
      total_amount: totalAmount,
      cashier_code: global.userLogin!.code,
      cashier_name: global.userLogin!.name,
      total_discount_from_promotion:
          totalPromotionSavings +
          posHoldProcess
              .posProcess
              .detail_total_discount, // รวมส่วนลดท้ายบิล + แต้ม + คูปอง
      pay_cash_amount: cashAmount,
      paypointamount: global
          .posHoldProcessResult[global.findPosHoldProcessResultIndex(
            posHoldActiveCode,
          )]
          .payScreenData
          .point_amount,
      pay_cash_change:
          ((cashAmount +
                      global
                          .posHoldProcessResult[global
                              .findPosHoldProcessResultIndex(posHoldActiveCode)]
                          .payScreenData
                          .point_amount +
                      global
                          .posHoldProcessResult[global
                              .findPosHoldProcessResultIndex(posHoldActiveCode)]
                          .payScreenData
                          .credit_amount +
                      sumCouponCashVoucher(posHoldActiveCode) +
                      sumQr(posHoldActiveCode) +
                      sumCreditCard(posHoldActiveCode) +
                      sumTransfer(posHoldActiveCode) +
                      sumCheque(posHoldActiveCode)) -
                  totalAmount)
              .abs(),
      is_sync: false,
      amount_except_vat: posHoldProcess.posProcess.amount_except_vat,
      amount_before_calc_vat: posHoldProcess.posProcess.amount_before_calc_vat,
      amount_after_calc_vat: posHoldProcess.posProcess.amount_after_calc_vat,
      vat_rate: posHoldProcess.posProcess.vat_rate,
      is_vat_register: posHoldProcess.posProcess.is_vat_register,
      total_item_vat_amount: posHoldProcess.posProcess.total_item_vat_amount,
      total_item_except_vat_amount:
          posHoldProcess.posProcess.total_item_except_vat_amount,
      total_vat_amount: posHoldProcess.posProcess.total_vat_amount,
      discount_formula: "",
      total_discount: 0,
      total_discount_vat_amount:
          posHoldProcess.posProcess.total_discount_vat_amount,
      total_discount_except_vat_amount:
          posHoldProcess.posProcess.total_discount_except_vat_amount,
      detail_discount_formula:
          posHoldProcess.posProcess.detail_discount_formula,
      detail_total_amount: posHoldProcess.posProcess.total_amount,
      detail_total_discount: posHoldProcess.posProcess.detail_total_discount,
      round_amount: roundAmount,
      total_amount_after_discount: totalAmountAfterDiscount,
      detail_total_amount_before_discount:
          posHoldProcess.posProcess.detail_total_amount_before_discount,
      food_amount: posHoldProcess.posProcess.total_food_amount,
      beverage_amount:
          posHoldProcess.posProcess.total_drink_amount +
          posHoldProcess.posProcess.total_alcohol_amount +
          posHoldProcess.posProcess.total_other_amount,
      is_delivery: isDelivery,
      delivery_number: deliveryNumber,
      delivery_code: deliveryCode,
      pay_json: jsonEncode(pays),
      promotion_json: jsonEncode(
        posHoldProcess.posProcess.promotion_product_list,
      ),
      promotion_bottom_json: jsonEncode(
        posHoldProcess.posProcess.promotion_bottom_list,
      ),
      promotion_bonus_json: jsonEncode(
        posHoldProcess.posProcess.promotion_bonus_list,
      ),
      promotion_coupon_json: jsonEncode(
        posHoldProcess.posProcess.promotion_coupon_list,
      ),
      shift_doc_no: currentShiftDocNo,
      getpoint: getPointTemp,
      usepoint: posHoldProcess.posProcess.usepoint,
      pointdiscountamount: posHoldProcess.posProcess.pointdiscountamount,
      point_balance_after: pointBalanceAfter,
      couponcashamount: _getCouponCashAmount(posHoldActiveCode),
      coupondiscountamount: _getCouponDiscountAmount(posHoldActiveCode),
      coupons_json: _getCouponsJson(posHoldActiveCode),
      sum_credit: global
          .posHoldProcessResult[global.findPosHoldProcessResultIndex(
            posHoldActiveCode,
          )]
          .payScreenData
          .credit_amount,
      sum_coupon: sumCouponCashVoucher(posHoldActiveCode),
      sum_qr_code: sumQr(posHoldActiveCode),
      sum_credit_card: sumCreditCard(posHoldActiveCode),
      sum_money_transfer: sumTransfer(posHoldActiveCode),
      sum_cheque: sumCheque(posHoldActiveCode),
    );

    try {
      global.billHelper.insert(billData);
      isSaved = true;
      global.objectBoxStore.box<BillDetailObjectBoxStruct>().putMany(
        details,
        mode: PutMode.insert,
      ); // อัปเดตยอดแต้มใน local database หลังจากบันทึกบิลสำเร็จ
      if (posHoldProcess.posProcess.usepoint > 0) {
        try {
          final updateSuccess = global.customerHelper.updatePointBalance(
            posHoldProcess.customerCode,
            pointBalanceAfter,
          );
          if (updateSuccess) {
            AppLogger.debug(
              'Updated local point balance for customer ${posHoldProcess.customerCode}: $pointBalanceAfter',
            );
          } else {
            AppLogger.debug(
              'Failed to update local point balance for customer ${posHoldProcess.customerCode}',
            );
          }
        } catch (e) {
          AppLogger.error('Error updating local point balance: $e');
        }
      } else if (pointscode.isNotEmpty && getPointTemp > 0) {
        try {
          final updateSuccess = global.customerHelper.updateGetPointBalance(
            pointscode,
            getPointTemp,
          );
          if (updateSuccess) {
            AppLogger.debug(
              'Updated local point balance for customer $pointscode: $getPointTemp',
            );
          } else {
            AppLogger.debug(
              'Failed to update local point balance for customer $pointscode',
            );
          }
        } catch (e) {
          AppLogger.error('Error updating local point balance: $e');
        }
      }

      // update Order Temp ร้านอาหาร
      if (global.tableNumberSelected.isNotEmpty) {
        final orderTemps = global.objectBoxStore
            .box<OrderTempObjectBoxStruct>()
            .query(
              OrderTempObjectBoxStruct_.orderId
                  .equals(global.tableNumberSelected)
                  .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false)),
            )
            .build()
            .find();
        for (int index = 0; index < orderTemps.length; index++) {
          orderTemps[index].isPaySuccess = true;
          orderTemps[index].guidPos = guidpos;
          global.objectBoxStore.box<OrderTempObjectBoxStruct>().put(
            orderTemps[index],
            mode: PutMode.update,
          );
        }
      }
      // update Pos Log
      final posLogs = global.objectBoxStore
          .box<PosLogObjectBoxStruct>()
          .query(
            PosLogObjectBoxStruct_.hold_code
                .equals(posHoldActiveCode)
                .and(PosLogObjectBoxStruct_.success.equals(0)),
          )
          .build()
          .find();
      for (int index = 0; index < posLogs.length; index++) {
        posLogs[index].success = 1;
      }
      global.objectBoxStore.box<PosLogObjectBoxStruct>().putMany(
        posLogs,
        mode: PutMode.update,
      );
      await global.saveOrderTempToSyncTempLog(
        docNumber: docNumber,
        guidPos: guidpos,
        orderId: global.tableNumberSelected,
        orderEmtry: false,
      );

      // Hook: ใช้คูปองหลัง saveBill สำเร็จ
      await _useCouponsAfterSaveBill(guidpos, posHoldActiveCode);
    } catch (e) {
      if (e is ObjectBoxException) {
        AppLogger.debug("doc_number ซ้ำ กำลังสร้างใหม่...");
      } else {
        rethrow;
      }
    }
  }
  Future.delayed(const Duration(seconds: 1), () {});
  return result;
}

Future<void> processPromotionTemp() async {
  /*await global.promotionTempHelper.deleteAll();
   {
      // Discount
      await global.promotionHelper.select().then((promotion) {
        for (final _getPromotion in promotion)
          global.promotionDiscountHelper
              .select(
                  where: global.promotionDiscountTableName +
                      ".promotion_code='" +
                      _getPromotion.promotion_code +
                      "'")
              .then((promotionDiscount) {
            for (final _getPromotionDiscount in promotionDiscount) {
              final List<Product> _product = global.productHelper
                  .selectByBarcode(_getPromotionDiscount.promotion_barcode);
              for (final _getProduct in _product) {
                PromotionTempStruct _temp = PromotionTempStruct(
                    promotion_code: _getPromotion.promotion_code,
                    date_begin: _getPromotion.date_begin,
                    date_end: _getPromotion.date_end,
                    barcode_promotion: _getPromotionDiscount.promotion_barcode,
                    name_1: _getProduct.name1!,
                    name_2: _getProduct.name2!,
                    name_3: _getProduct.name3!,
                    name_4: _getProduct.name4!,
                    name_5: _getProduct.name5!,
                    customer_only: _getPromotion.customer_only,
                    discount: _getPromotionDiscount.promotion_discount,
                    limit_qty: _getPromotionDiscount.limit_qty,
                    promotion_name_1: _getPromotion.promotion_name_1,
                    promotion_name_2: _getPromotion.promotion_name_2,
                    promotion_name_3: _getPromotion.promotion_name_3,
                    promotion_name_4: _getPromotion.promotion_name_4,
                    promotion_name_5: _getPromotion.promotion_name_5);
                global.promotionTempHelper.insert(_temp);
              }
            }
          });
      });
    }*/
}

/// ใช้คูปองหลังจาก saveBill สำเร็จ
Future<void> _useCouponsAfterSaveBill(
  String guidpos,
  String posHoldActiveCode,
) async {
  try {
    final couponApiService = CouponApiService();

    // ดึงข้อมูลบิลที่เพิ่งสร้าง โดยใช้ guidpos
    BillObjectBoxStruct? bill = global.objectBoxStore
        .box<BillObjectBoxStruct>()
        .query(BillObjectBoxStruct_.guidpos.equals(guidpos))
        .build()
        .findFirst();

    if (bill == null) {
      AppLogger.debug('❌ ไม่พบบิลสำหรับ guidpos: $guidpos');
      return;
    }

    // ดึงข้อมูลคูปองจาก coupons_json
    if (bill.coupons_json.isNotEmpty) {
      try {
        List<dynamic> couponJsonList = jsonDecode(bill.coupons_json);

        if (couponJsonList.isNotEmpty) {
          final posHoldProcess =
              global.posHoldProcessResult[global.findPosHoldProcessResultIndex(
                posHoldActiveCode,
              )];
          final customerCode = posHoldProcess.customerCode;
          final customerName = posHoldProcess.customerName;

          int successCount = 0;

          for (var couponData in couponJsonList) {
            try {
              // แปลงข้อมูลคูปองจาก JSON
              final couponId = couponData['couponno'] as String? ?? '';
              final reservationId =
                  couponData['reservationid'] as String? ?? '';
              final transactionId =
                  couponData['transactionid'] as String? ?? '';
              final useAmount =
                  (couponData['couponamount'] as num?)?.toDouble() ?? 0.0;
              final customerId = couponData['customerId'] as String? ?? '';

              AppLogger.debug(
                'กำลังใช้คูปอง: $couponId, Reservation ID: $reservationId, Transaction ID: $transactionId, Use Amount: $useAmount',
              );
              if (couponId.isNotEmpty) {
                // สร้าง request สำหรับการใช้คูปอง โดยใช้ guidpos เป็น transaction_id
                final useRequest = CouponUseRequest(
                  customer_code: customerCode,
                  customer_id: customerId,
                  customer_name: customerName,
                  order_amount: bill.detail_total_amount_before_discount,
                  remark: 'POS Transaction',
                  reservation_id: reservationId,
                  sale_invoice_id: guidpos,
                  sale_invoice_number: bill.doc_number,
                  transaction_id: transactionId,
                  use_amount: useAmount,
                );

                // เรียก API เพื่อใช้คูปอง
                final success = await couponApiService.useCouponWithRequest(
                  couponId: couponId,
                  request: useRequest,
                );

                if (success) {
                  successCount++;
                  AppLogger.debug(
                    '✅ ใช้คูปอง $couponId สำเร็จ (จำนวน: $useAmount)',
                  );
                } else {
                  AppLogger.debug('❌ การใช้คูปอง $couponId ไม่สำเร็จ');
                }
              }
            } catch (e) {
              AppLogger.error('❌ เกิดข้อผิดพลาดในการใช้คูปอง: $e');
            }
          }

          if (successCount > 0) {
            AppLogger.debug(
              '✅ ใช้คูปองทั้งหมด $successCount จาก ${couponJsonList.length} คูปอง สำเร็จ',
            );
          } else {
            AppLogger.debug('❌ ไม่สามารถใช้คูปองใดได้');
          }
        }
      } catch (e) {
        AppLogger.error('❌ เกิดข้อผิดพลาดในการ parse coupons_json: $e');
      }
    } else {
      AppLogger.debug('❌ ไม่มีข้อมูลคูปองใน coupons_json');
    }
  } catch (e) {
    AppLogger.error('❌ เกิดข้อผิดพลาดทั่วไปในการใช้คูปองหลัง saveBill: $e');
  }
}

Widget posBill(BillObjectBoxStruct bill) {
  return Container(
    width: 300,
    padding: const EdgeInsets.all(4),
    child: Table(
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(3)},
      children: [
        TableRow(
          children: [
            Text(global.language("doc_number")),
            Text(
              bill.doc_number,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        TableRow(
          children: [
            Text(global.language("doc_date")),
            Text(
              global.dateTimeFormatThaiShortMonth(
                bill.date_time,
                showTime: true,
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        TableRow(
          children: [
            Text(global.language("amount")),
            Text(
              global.moneyFormat.format(bill.total_amount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        TableRow(
          children: [
            Text(global.language("copy")),
            Text(
              global.moneyFormat.format(bill.print_copy_bill_date_time.length),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget posBillDetail({required String docNumber}) {
  BillObjectBoxStruct? bill = global.billHelper.selectByDocNumber(
    docNumber: docNumber,
    posScreenMode: 1,
  );
  if (bill == null) {
    return Text("Bill {$docNumber} not found");
  }
  List<BillDetailObjectBoxStruct> billDetails = global.objectBoxStore
      .box<BillDetailObjectBoxStruct>()
      .query(BillDetailObjectBoxStruct_.doc_number.equals(bill.doc_number))
      .order(BillDetailObjectBoxStruct_.line_number)
      .build()
      .find();

  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.black),
      borderRadius: BorderRadius.circular(5),
      boxShadow: const [
        BoxShadow(
          color: Colors.grey,
          blurRadius: 4.0,
          spreadRadius: 0.5,
          offset: Offset(0.5, 0.5),
        ),
      ],
    ),
    child: Column(
      children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(3)},
          children: [
            TableRow(
              children: [
                Text(global.language("doc_number")),
                Text(bill.doc_number),
              ],
            ),
            TableRow(
              children: [
                Text(global.language("doc_date")),
                Text(global.dateTimeFormatThaiShortMonth(bill.date_time)),
              ],
            ),
            TableRow(
              children: [
                Text(global.language("total_amount")),
                Text(global.moneyFormat.format(bill.total_amount)),
              ],
            ),
            TableRow(
              children: [
                Text(global.language("discount")),
                Text(bill.discount_formula),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Table(
          border: TableBorder.all(width: 0.5, color: Colors.grey),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(5),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(2),
            5: FlexColumnWidth(3),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.cyan.shade100),
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    global.language("line"),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    global.language("item_name"),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    global.language("unit_name"),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    global.language("qty"),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    global.language("price"),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    global.language("total_amount"),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            for (var i = 0; i < billDetails.length; i++)
              TableRow(
                decoration: BoxDecoration(
                  color: (i % 2 == 0) ? Colors.white : Colors.grey.shade200,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      (i + 1).toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      global.getNameFromJsonLanguage(
                        billDetails[i].item_name,
                        global.userScreenLanguage,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      global.getNameFromJsonLanguage(
                        billDetails[i].unit_name,
                        global.userScreenLanguage,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      global.moneyFormat.format(billDetails[i].qty),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      global.moneyFormat.format(billDetails[i].price),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      global.moneyFormat.format(billDetails[i].total_amount),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    ),
  );
}

/// Helper functions for coupon data
double _getCouponCashAmount(String posHoldActiveCode) {
  try {
    final couponManager = CouponManager();
    final calculation = couponManager.lastCalculation;
    return calculation?.total_cash_voucher ?? 0.0;
  } catch (e) {
    return 0.0;
  }
}

double _getCouponDiscountAmount(String posHoldActiveCode) {
  try {
    final couponManager = CouponManager();
    final calculation = couponManager.lastCalculation;
    return calculation?.total_discount ?? 0.0;
  } catch (e) {
    return 0.0;
  }
}

String _getCouponsJson(String posHoldActiveCode) {
  try {
    final couponManager = CouponManager();
    final appliedCoupons = couponManager.appliedCoupons;

    if (kDebugMode) {
      AppLogger.debug('🧪 _getCouponsJson Debug:');
      AppLogger.debug('- Applied Coupons Count: ${appliedCoupons.length}');
      AppLogger.debug(
        '- Has Calculation: ${couponManager.lastCalculation != null}',
      );
      AppLogger.debug(
        '- CouponManager instance hash: ${couponManager.hashCode}',
      );
    }

    // เพิ่มการตรวจสอบโดยละเอียด
    if (appliedCoupons.isEmpty) {
      if (kDebugMode) {
        AppLogger.error(
          '❌ No applied coupons found in CouponManager singleton',
        );
        AppLogger.debug('- Instance: $couponManager');
        AppLogger.debug('- Trying to access singleton again...');
      }
      // ลองเข้าถึง singleton อีกครั้ง
      final anotherInstance = CouponManager();
      if (kDebugMode) {
        AppLogger.debug('- Another instance hash: ${anotherInstance.hashCode}');
        AppLogger.debug(
          '   - Another instance coupons: ${anotherInstance.appliedCoupons.length}',
        );
      }
    }

    List<Map<String, dynamic>> couponsData = [];
    for (final appliedCoupon in appliedCoupons) {
      final result = appliedCoupon.calculationResult;
      if (kDebugMode) {
        AppLogger.debug(
          '- Processing Coupon: ${appliedCoupon.coupon.couponcode}',
        );
        AppLogger.debug('* Has Result: ${result != null}');
        AppLogger.debug('* Applied: ${result?.applied ?? false}');
        AppLogger.debug(
          '* Has Reservation: ${appliedCoupon.reservation != null}',
        );
        AppLogger.debug(
          '     * Reservation ID: ${appliedCoupon.reservation?.reservation_id ?? 'none'}',
        );
        AppLogger.debug(
          '     * Transaction ID: ${appliedCoupon.reservation?.transaction_id ?? 'none'}',
        );
      }

      if (result != null && result.applied) {
        // ดึง reservation ID ที่ถูกต้องจากการจอง
        final reservationId = appliedCoupon.reservation?.reservation_id ?? '';

        // ใช้ transaction_id จาก reservation หรือ empty string ถ้าไม่มี
        final reservationTransactionId =
            appliedCoupon.reservation?.transaction_id ?? '';

        if (kDebugMode) {
          AppLogger.debug('* Final Reservation ID: $reservationId');
          AppLogger.debug('* Final Transaction ID: $reservationTransactionId');
        }

        couponsData.add({
          'couponamount': result.totalAmount, // ใช้ computed property ใหม่
          'coupondescription': appliedCoupon.coupon.displayName,
          'couponno': appliedCoupon.coupon.couponcode,
          'coupontype': appliedCoupon.coupon.coupontype.toString(),
          'reservationid': reservationId,
          'customerId': appliedCoupon.customerId, // ใช้ customerId ถ้ามี
          'transactionid':
              reservationTransactionId, // ใช้ transaction_id จาก reservation
          'couponid': appliedCoupon.coupon.guidfixed,
          // เพิ่มข้อมูลใหม่จาก API
          'discount_amount': result.discount_amount,
          'cash_voucher_amount': result.cash_voucher_amount,
          'used_amount': result.used_amount,
          'remaining_value': result.remaining_value,
          'message': result.message,
          // เพิ่มข้อมูลสำหรับ debugging
          'is_reserved': appliedCoupon.isReserved,
          'reservation_expires_at':
              appliedCoupon.reservation?.expires_at?.toIso8601String() ?? '',
        });

        AppLogger.debug('     ✅ Added to coupons JSON');
      } else {
        AppLogger.debug('     ❌ Skipped - not applied or no result');
      }
    }

    final jsonResult = jsonEncode(couponsData);
    if (kDebugMode) {
      AppLogger.debug('- Final JSON Length: ${jsonResult.length}');
      AppLogger.debug('- Final JSON: $jsonResult');
    }

    return jsonResult;
  } catch (e) {
    AppLogger.error('❌ Error in _getCouponsJson: $e');
    return '[]';
  }
}
