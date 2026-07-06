import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dedecashier/api/client.dart';
import 'package:dedecashier/api/sync/model/shift_model.dart';
import 'package:dedecashier/api/sync/model/trans_model.dart';
import 'package:dedecashier/api/user_repository.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/db/bill_helper.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/shift_struct.dart';
import 'package:dedecashier/model/objectbox/upload_queue_struct.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:synchronized/synchronized.dart'; // ใช้ synchronized เพื่อป้องกันการทำงานซ้ำ
import 'package:dedecashier/core/logger/app_logger.dart';

/// Sync Status Enum
enum SyncStatus {
  idle, // ไม่ทำงาน
  syncing, // กำลัง sync
  success, // สำเร็จ
  failed, // ล้มเหลว
}

class SyncBill {
  Timer? syncBillTimer;
  final Lock syncLock = Lock();
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};

  // ⭐ Sync Status Management
  static final ValueNotifier<SyncStatus> syncStatus = ValueNotifier(SyncStatus.idle);
  static final ValueNotifier<int> pendingBillsCount = ValueNotifier(0);
  static final ValueNotifier<String?> lastError = ValueNotifier(null);
  static final ValueNotifier<DateTime?> lastSyncTime = ValueNotifier(null);

  /// Helper method to parse coupon JSON string into list of CouponItemModel
  List<CouponItemModel> _buildCouponsList(String couponsJson) {
    if (couponsJson.isEmpty) return [];

    try {
      final List<dynamic> couponsData = jsonDecode(couponsJson);
      return couponsData.map((item) => CouponItemModel.fromJson(item)).toList();
    } catch (e) {
      AppLogger.error('Error parsing coupons JSON: $e');
      return [];
    }
  }

  void startSync() {
    if (syncBillTimer == null || !syncBillTimer!.isActive) {
      // ⭐ Optimized: Changed to 30 seconds for faster sync and retry
      syncBillTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        syncBillProcess();
      });

      AppLogger.debug('[SyncBill] 🚀 Sync timer started (interval: 30 seconds)');
    }
  }

  void stopSync() {
    syncBillTimer?.cancel();
    syncBillTimer = null;
  }

  Future syncBillData() async {
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
    }

    await initPlatformState();
    await syncLock.synchronized(() async {
      List<BillObjectBoxStruct> bills = (global.billHelper.selectSyncIsFalse());

      // ⭐ Update pending bills count
      pendingBillsCount.value = bills.length;

      // ⭐ Deduplication check - track guidpos that have been synced in this cycle
      Set<String> syncedGuidposInThisCycle = {};

      if (kDebugMode) {
        AppLogger.info('📊 Found ${bills.length} bills to sync');
        if (bills.isNotEmpty) {
          AppLogger.info('📋 Bill list:');
          for (var bill in bills.take(5)) {
            AppLogger.debug('[SyncBill]       • ${bill.doc_number} (${bill.total_amount})');
          }
          if (bills.length > 5) {
            AppLogger.debug('... และอีก ${bills.length - 5} บิล');
          }
        }
      }

      if (bills.isEmpty) {
        AppLogger.debug('[SyncBill] ✅ No bills to sync');
        return;
      }

      for (int index = 0; index < bills.length; index++) {
        BillObjectBoxStruct bill = bills[index];

        // ⭐ Skip if this guidpos was already synced in this cycle
        if (syncedGuidposInThisCycle.contains(bill.guidpos)) {
          AppLogger.debug('[SyncBill] ⚠️ Skipping duplicate guidpos in same cycle: ${bill.guidpos} (${bill.doc_number})');
          continue;
        }

        AppLogger.debug('[SyncBill] 🔄 Syncing bill ${index + 1}/${bills.length}: ${bill.doc_number}');

        List<TransNameInfoModel> custNames = [];

        if (bill.customer_name != '') {
          custNames.add(TransNameInfoModel(code: "th", isauto: false, isdelete: false, name: bill.customer_name));
        }

        List<BillDetailObjectBoxStruct> billDetails = global.objectBoxStore
            .box<BillDetailObjectBoxStruct>()
            .query(BillDetailObjectBoxStruct_.doc_number.equals(bill.doc_number).and(BillDetailObjectBoxStruct_.guidpos.equals(bill.guidpos)))
            .order(BillDetailObjectBoxStruct_.line_number)
            .build()
            .find();

        List<TransDetailModel> details = [];
        double totalQty = 0;
        int linenumber = 0;
        for (var detail in billDetails) {
          String optionSelected = detail.extra_json;
          String refGuidCode = const Uuid().v4();
          double sumamountchoice = 0;

          List<TransOptionsModel> transOptions = [];
          if (optionSelected.isNotEmpty) {
            detail.refguid = refGuidCode;
            List<BillDetailExtraObjectBoxStruct> optionList = (await jsonDecode(optionSelected) as List).map((e) => BillDetailExtraObjectBoxStruct.fromJson(e)).toList();
            for (var option in optionList) {
              // sumamountchoice += option.price;
              String refBarcodex = (option.refbarcode.isNotEmpty) ? option.refbarcode : "";
              if (option.price == 0) {
                TransOptionsModel optionModel = TransOptionsModel(
                  barcode: refBarcodex,
                  qty: detail.qty,
                  price: option.price,
                  item_code: "",
                  item_name: option.item_name,
                  unit_code: "",
                  unit_name: "",
                  total_amount: option.price * option.qty,
                  is_except_vat: false,
                  vat_type: global.posConfig.vattype,
                  price_exclude_vat: option.price,
                );
                sumamountchoice += (option.price * detail.qty);
                transOptions.add(optionModel);
              }
            }
          }

          double priceExcludeVat = 0;
          if (!detail.is_except_vat) {
            if (bill.vat_type == 0) {
              priceExcludeVat = ((detail.price + (sumamountchoice / detail.qty)) * 100) / (100 + bill.vat_rate);
            } else {
              priceExcludeVat = detail.price + (sumamountchoice / detail.qty);
            }
          } else {
            priceExcludeVat = detail.price + (sumamountchoice / detail.qty);
          }

          detail.price - (detail.price * (bill.vat_rate / 100));
          details.add(
            TransDetailModel(
              refguid: refGuidCode,
              averagecost: 0,
              barcode: detail.barcode,
              calcflag: -1,
              discount: detail.discount_text,
              discountamount: detail.discount,
              standvalue: 1,
              dividevalue: 1,
              docdatetime: bill.date_time.toUtc().toIso8601String(),
              docref: "",
              docrefdatetime: null,
              inquirytype: (bill.doc_mode == 1) ? 1 : 2,
              description: detail.description,
              ispos: 1,
              issumpoint: detail.issumpoint,
              itemcode: detail.item_code,
              itemguid: "",
              itemnames: (await jsonDecode(detail.item_name) as List).map((e) => TransNameInfoModel.fromJson(e)).toList(),
              itemtype: 0,
              laststatus: 0,
              linenumber: linenumber,
              locationcode: global.posConfig.location.code,
              locationnames: global.posConfig.location.names,
              multiunit: false,
              price: detail.price,
              priceexcludevat: priceExcludeVat,
              qty: detail.qty,
              remark: "",
              shelfcode: "",
              sumamount: (detail.price * detail.qty),
              sumamountexcludevat: priceExcludeVat * detail.qty,
              sumamountchoice: sumamountchoice,
              sumofcost: 0,
              taxtype: bill.bill_tax_type,
              tolocationcode: "",
              tolocationnames: [],
              totalqty: detail.qty,
              totalvaluevat: ((detail.price * detail.qty) + sumamountchoice) - (priceExcludeVat * detail.qty),
              towhcode: "",
              towhnames: [],
              unitcode: detail.unit_code,
              unitnames: (await jsonDecode(detail.unit_name) as List).map((e) => TransNameInfoModel.fromJson(e)).toList(),
              vatcal: (detail.is_except_vat) ? 1 : 0,
              vattype: detail.vat_type,
              whcode: global.posConfig.warehouse.code,
              whnames: global.posConfig.warehouse.names,
              sku: detail.sku,
              extrajson: (transOptions.isNotEmpty) ? jsonEncode(transOptions) : "",
            ),
          );

          if (optionSelected.isNotEmpty) {
            detail.refguid = refGuidCode;
            List<BillDetailExtraObjectBoxStruct> optionList = (await jsonDecode(optionSelected) as List).map((e) => BillDetailExtraObjectBoxStruct.fromJson(e)).toList();

            for (var option in optionList) {
              // sumamountchoice += option.price;
              String refBarcodex = (option.refbarcode.isNotEmpty) ? option.refbarcode : "";

              double priceChoiceExcludeVat = 0;
              if (!detail.is_except_vat) {
                if (global.posConfig.vattype == 0) {
                  priceChoiceExcludeVat = (option.price * 100) / (100 + global.posConfig.vatrate);
                } else {
                  priceChoiceExcludeVat = option.price;
                }
              } else {
                priceChoiceExcludeVat = option.price;
              }
              if (option.price > 0) {
                details.add(
                  TransDetailModel(
                    ischoice: 1,
                    refguid: refGuidCode,
                    averagecost: 0,
                    barcode: refBarcodex,
                    calcflag: -1,
                    discount: "",
                    discountamount: 0,
                    standvalue: 1,
                    dividevalue: 1,
                    docdatetime: bill.date_time.toUtc().toIso8601String(),
                    docref: "",
                    docrefdatetime: null,
                    inquirytype: (bill.doc_mode == 1) ? 1 : 2,
                    ispos: 1,
                    itemcode: refBarcodex,
                    itemguid: "",
                    itemnames: (await jsonDecode(option.item_name) as List).map((e) => TransNameInfoModel.fromJson(e)).toList(),
                    itemtype: 0,
                    laststatus: 0,
                    linenumber: linenumber,
                    locationcode: global.posConfig.location.code,
                    locationnames: global.posConfig.location.names,
                    multiunit: false,
                    price: option.price,
                    priceexcludevat: priceChoiceExcludeVat,
                    qty: detail.qty,
                    remark: "",
                    shelfcode: "",
                    sumamount: option.total_amount,
                    sumamountexcludevat: priceChoiceExcludeVat * detail.qty,
                    sumofcost: 0,
                    taxtype: bill.bill_tax_type,
                    tolocationcode: "",
                    tolocationnames: [],
                    totalqty: option.qty,
                    totalvaluevat: (option.price * detail.qty) - (priceChoiceExcludeVat * detail.qty),
                    towhcode: "",
                    towhnames: [],
                    unitcode: option.unit_code,
                    unitnames: (await jsonDecode(detail.unit_name) as List).map((e) => TransNameInfoModel.fromJson(e)).toList(),
                    vatcal: (detail.is_except_vat) ? 1 : 0,
                    vattype: detail.vat_type,
                    whcode: global.posConfig.warehouse.code,
                    whnames: global.posConfig.warehouse.names,
                    sku: detail.sku,
                    extrajson: "",
                  ),
                );
                linenumber++;
                totalQty += detail.qty;
              }
            }
          }
          linenumber++;
          totalQty += detail.qty;
        }
        List<BillPayObjectBoxStruct> payDetails = (await jsonDecode(bill.pay_json) as List).map((e) => BillPayObjectBoxStruct.fromJson(e)).toList();
        List<TransPaymentCreditCardModel> paymentCreditCards = [];
        List<TransPaymentTransferModel> paymentTransfers = [];

        for (var payDetail in payDetails) {
          // 1=บัตรเครดิต,2=เงินโอน,3=เช็ค,4=คูปอง,5=QR
          switch (payDetail.trans_flag) {
            case 1: // 1=บัตรเครดิต
              paymentCreditCards.add(
                TransPaymentCreditCardModel(
                  amount: payDetail.amount,
                  cardnumber: payDetail.card_number,
                  chargevalue: 0,
                  chargeword: "",
                  docdatetime: payDetail.doc_date_time.toString(),
                  totalnetworth: payDetail.amount,
                ),
              );
              break;
            case 2: // 2=เงินโอน
              paymentTransfers.add(
                TransPaymentTransferModel(
                  accountnumber: payDetail.book_bank_code,
                  amount: payDetail.amount,
                  bankcode: payDetail.bank_code,
                  banknames: [TransNameInfoModel(code: "th", isauto: false, isdelete: false, name: payDetail.bank_name)],
                  docdatetime: payDetail.doc_date_time.toString(),
                ),
              );
              break;
            case 3: // 3=เช็ค
              break;
            case 4: // 4=คูปอง
              break;
            case 5: // 5=QR
              break;
          }
        }

        TransPaymentDetailModel paymentDetail = TransPaymentDetailModel(cashamount: 0, cashamounttext: "", paymentcreditcards: [], paymenttransfers: []);
        int transVatType = 0;
        if (!global.posConfig.isvatregister) {
          transVatType = 3;
        } else if (global.posConfig.isvatregister && global.posConfig.vattype == 0) {
          transVatType = 1;
        } else if (global.posConfig.isvatregister && global.posConfig.vattype == 1) {
          transVatType = 0;
        }
        double getPointValue = 0.0;
        double usePointValue = 0.0;

        if (bill.getpoint > 0) {
          getPointValue = bill.getpoint;
        }

        if (bill.usepoint > 0) {
          usePointValue = bill.usepoint;
        }

        // Try to get point values from stored promotion data if available
        try {
          if (bill.promotion_json.isNotEmpty) {
            jsonDecode(bill.promotion_json);
          }
        } catch (e) {
          // Handle JSON parsing errors gracefully
        }

        // ส่งข้อมูล ขึ้น cloud
        TransactionModel trans = TransactionModel(
          cashiercode: bill.cashier_code,
          custcode: bill.customer_code,
          pointscode: bill.points_code,
          custnames: custNames,
          devicename: _deviceData['name'],
          description: "POS",
          guidpos: bill.guidpos,
          branch: global.posConfig.branch,
          discountword: bill.discount_formula,
          docdatetime: bill.date_time.toUtc().toIso8601String(),
          docno: bill.doc_number,
          docrefdate: bill.date_time.toUtc().toIso8601String(),
          docrefno: "",
          docreftype: 0,
          shiftdocno: bill.shift_doc_no,
          doctype: 0,
          guidref: "",
          inquirytype: (bill.doc_mode == 1) ? 1 : 2,
          iscancel: bill.is_cancel,
          ismanualamount: false,
          ispos: true,
          posid: global.posConfig.code,
          membercode: bill.customer_code,
          salecode: bill.sale_code,
          salename: bill.sale_name,
          status: 0,
          taxdocdate: bill.date_time.toUtc().toIso8601String(),
          taxdocno: bill.doc_number,
          totalaftervat: double.parse(bill.amount_after_calc_vat.toStringAsFixed(2)),
          totalamount: double.parse((((bill.amount_after_calc_vat + bill.amount_except_vat) - bill.total_discount) - bill.pointdiscountamount).toStringAsFixed(2)),
          totalbeforevat: double.parse(bill.amount_before_calc_vat.toStringAsFixed(2)),
          totalcost: 0,
          totaldiscount: double.parse(bill.total_discount.toStringAsFixed(2)),
          totalexceptvat: double.parse(bill.amount_except_vat.toStringAsFixed(2)),
          totalvalue: double.parse(bill.detail_total_amount_before_discount.toStringAsFixed(2)),
          totalvatvalue: double.parse(bill.total_vat_amount.toStringAsFixed(2)),
          transflag: 0,
          vatrate: bill.vat_rate,
          vattype: transVatType,
          details: details,
          paycashamount: bill.pay_cash_amount - bill.pay_cash_change,
          paypointamount: bill.paypointamount,
          paymentdetail: paymentDetail,
          paymentdetailraw: bill.pay_json,
          billtaxtype: bill.bill_tax_type,
          buffetcode: bill.buffet_code,
          canceldatetime: bill.cancel_date_time,
          canceldescription: bill.cancel_description,
          cancelusercode: bill.cancel_user_code,
          cancelusername: bill.cancel_user_name,
          cancelreason: bill.cancel_reason,
          cashiername: bill.cashier_name,
          childcount: bill.child_count,
          customertelephone: bill.customer_telephone,
          detaildiscountformula: bill.detail_discount_formula,
          detailtotalamount: bill.detail_total_amount,
          detailtotalamountbeforediscount: bill.detail_total_amount_before_discount,
          detailtotaldiscount: bill.detail_total_discount,
          fullvataddress: bill.full_vat_address,
          fullvatname: bill.full_vat_name,
          fullvatbranchnumber: bill.full_vat_branch_number,
          fullvatdocnumber: bill.full_vat_doc_number,
          fullvatprint: bill.full_vat_print,
          fullvattaxid: bill.full_vat_tax_id,
          isvatregister: bill.is_vat_register,
          mancount: bill.man_count,
          paycashchange: double.parse(bill.pay_cash_change.toStringAsFixed(2)),
          printcopybilldatetime: bill.print_copy_bill_date_time,
          roundamount: bill.round_amount,
          sumcheque: double.parse(bill.sum_cheque.toStringAsFixed(2)),
          sumcoupon: double.parse(bill.sum_coupon.toStringAsFixed(2)),
          sumcreditcard: double.parse(bill.sum_credit_card.toStringAsFixed(2)),
          summoneytransfer: double.parse(bill.sum_money_transfer.toStringAsFixed(2)),
          sumqrcode: double.parse(bill.sum_qr_code.toStringAsFixed(2)),
          sumcredit: double.parse(bill.sum_credit.toStringAsFixed(2)),
          istableallacratemode: bill.table_al_la_crate_mode,
          tableclosedatetime: bill.table_close_date_time.toUtc().toIso8601String(),
          tablenumber: bill.table_number,
          tableopendatetime: bill.table_open_date_time.toUtc().toIso8601String(),
          totalamountafterdiscount: bill.total_amount_after_discount,
          totaldiscountexceptvatamount: bill.total_discount_except_vat_amount,
          totaldiscountvatamount: bill.total_discount_vat_amount,
          totalqty: totalQty,
          womancount: bill.woman_count,
          isbom: global.posConfig.branch.pos!.isbom,
          getpoint: getPointValue,
          usepoint: usePointValue,
          pointdiscountamount: bill.pointdiscountamount,
          couponcashamount: bill.couponcashamount,
          coupondiscountamount: bill.coupondiscountamount,
          coupons: _buildCouponsList(bill.coupons_json),
        );

        try {
          if (bill.doc_mode == 1) {
            await checkAndSaveTransaction(trans);
          } else {
            await checkAndSaveReturn(trans);
          }

          // ⭐ Mark this guidpos as synced in this cycle to prevent duplicates
          syncedGuidposInThisCycle.add(bill.guidpos);

          AppLogger.debug('[SyncBill] ✅ Bill synced successfully: ${bill.doc_number}');
        } catch (e, s) {
          AppLogger.error(e);
          global.sendErrorToDevTeam("syncBillData", "$e : $s");

          AppLogger.debug('[SyncBill] ❌ Failed to sync bill ${bill.doc_number}: $e');
        }
      }

      // ⭐ Update pending count after sync
      final remainingBills = global.billHelper.selectSyncIsFalse();
      pendingBillsCount.value = remainingBills.length;

      AppLogger.debug('[SyncBill] 📊 Remaining bills after sync: ${remainingBills.length}');
    });

    // ⭐ Performance logging (debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.success('[SyncBill] ⏱️ syncBillData completed in ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  Future syncShift() async {
    List<ShiftObjectBoxStruct> shifts = (global.shiftHelper.selectSyncIsFalse());

    for (int index = 0; index < shifts.length; index++) {
      ShiftObjectBoxStruct shift = shifts[index];

      ShiftModel postShift = ShiftModel(
        guidfixed: shift.guidfixed,
        doctype: shift.doctype,
        amount: shift.amount,
        creditcard: shift.creditcard,
        promptpay: shift.promptpay,
        transfer: shift.transfer,
        cheque: shift.cheque,
        coupon: shift.coupon,
        docdate: shift.docdate.toUtc().toIso8601String(),
        remark: shift.remark,
        usercode: shift.usercode,
        username: shift.username,
        posid: shift.posid,
        docno: shift.docno,
      );
      await saveShift(postShift);
      global.shiftHelper.updatesSyncSuccess(docNumber: shift.guidfixed);
    }
  }

  Future<void> initPlatformState() async {
    var deviceData = <String, dynamic>{};

    try {
      if (kIsWeb) {
        deviceData = _readWebBrowserInfo(await deviceInfoPlugin.webBrowserInfo);
      } else {
        deviceData = switch (defaultTargetPlatform) {
          TargetPlatform.android => _readAndroidBuildData(await deviceInfoPlugin.androidInfo),
          TargetPlatform.iOS => _readIosDeviceInfo(await deviceInfoPlugin.iosInfo),
          TargetPlatform.linux => _readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo),
          TargetPlatform.windows => _readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo),
          TargetPlatform.macOS => _readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo),
          TargetPlatform.fuchsia => <String, dynamic>{'Error:': 'Fuchsia platform isn\'t supported'},
        };
      }
    } on PlatformException {
      deviceData = <String, dynamic>{'Error:': 'Failed to get platform version.'};
    }

    _deviceData = deviceData;
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'systemFeatures': build.systemFeatures,
      'isLowRamDevice': build.isLowRamDevice,
      'name': build.device,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }

  Map<String, dynamic> _readLinuxDeviceInfo(LinuxDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'version': data.version,
      'id': data.id,
      'idLike': data.idLike,
      'versionCodename': data.versionCodename,
      'versionId': data.versionId,
      'prettyName': data.prettyName,
      'buildId': data.buildId,
      'variant': data.variant,
      'variantId': data.variantId,
      'machineId': data.machineId,
    };
  }

  Map<String, dynamic> _readWebBrowserInfo(WebBrowserInfo data) {
    return <String, dynamic>{
      'browserName': data.browserName.name,
      'appCodeName': data.appCodeName,
      'appName': data.appName,
      'appVersion': data.appVersion,
      'deviceMemory': data.deviceMemory,
      'language': data.language,
      'languages': data.languages,
      'platform': data.platform,
      'product': data.product,
      'productSub': data.productSub,
      'userAgent': data.userAgent,
      'vendor': data.vendor,
      'vendorSub': data.vendorSub,
      'hardwareConcurrency': data.hardwareConcurrency,
      'maxTouchPoints': data.maxTouchPoints,
      'name': data.browserName.name,
    };
  }

  Map<String, dynamic> _readMacOsDeviceInfo(MacOsDeviceInfo data) {
    return <String, dynamic>{
      'computerName': data.computerName,
      'hostName': data.hostName,
      'arch': data.arch,
      'model': data.model,
      'kernelVersion': data.kernelVersion,
      'majorVersion': data.majorVersion,
      'minorVersion': data.minorVersion,
      'patchVersion': data.patchVersion,
      'osRelease': data.osRelease,
      'activeCPUs': data.activeCPUs,
      'memorySize': data.memorySize,
      'cpuFrequency': data.cpuFrequency,
      'systemGUID': data.systemGUID,
      'name': data.computerName,
    };
  }

  Map<String, dynamic> _readWindowsDeviceInfo(WindowsDeviceInfo data) {
    return <String, dynamic>{
      'numberOfCores': data.numberOfCores,
      'computerName': data.computerName,
      'systemMemoryInMegabytes': data.systemMemoryInMegabytes,
      'userName': data.userName,
      'majorVersion': data.majorVersion,
      'minorVersion': data.minorVersion,
      'buildNumber': data.buildNumber,
      'platformId': data.platformId,
      'csdVersion': data.csdVersion,
      'servicePackMajor': data.servicePackMajor,
      'servicePackMinor': data.servicePackMinor,
      'suitMask': data.suitMask,
      'productType': data.productType,
      'reserved': data.reserved,
      'buildLab': data.buildLab,
      'buildLabEx': data.buildLabEx,
      'digitalProductId': data.digitalProductId,
      'displayVersion': data.displayVersion,
      'editionId': data.editionId,
      'installDate': data.installDate,
      'productId': data.productId,
      'productName': data.productName,
      'registeredOwner': data.registeredOwner,
      'releaseId': data.releaseId,
      'deviceId': data.deviceId,
      'name': data.computerName,
    };
  }

  Future<ApiResponse> checkAndSaveTransaction(TransactionModel trx) async {
    Dio client = Client().init();
    try {
      // Check if transaction exists by guidpos (more reliable than docno)
      final checkResponse = await client.get('/transaction/sale-invoice/guidpos/${trx.guidpos}');
      final checkRawData = json.decode(checkResponse.toString());

      if (checkRawData['error'] == null) {
        // ตรวจสอบว่าเป็นบิลเดียวกันหรือไม่ (ตาม guidpos)
        if (trx.guidpos == checkRawData['data']['guidpos']) {
          // บิลเดียวกัน - ตรวจสอบว่ามีการเปลี่ยนแปลงหรือไม่
          if (trx.iscancel == checkRawData['data']['iscancel']) {
            // ไม่มีการเปลี่ยนแปลง status cancel - แต่อาจมีข้อมูลอื่นเปลี่ยน (เช่น VAT)
            // เรียก updateTransaction เพื่ออัพเดทข้อมูล (ถ้ามีการเปลี่ยนแปลง server จะจัดการ)
            return await updateTransaction(client, trx, checkRawData['data']['guidfixed']);
          } else {
            // มีการเปลี่ยน cancel status - update
            return await updateTransaction(client, trx, checkRawData['data']['guidfixed']);
          }
        } else {
          // ไม่ใช่บิลเดียวกัน (guidpos ต่างกัน) - docno ซ้ำ ต้องสร้าง docno ใหม่
          if (trx.iscancel) {
            // ถ้าเป็นการยกเลิก แต่ guidpos ต่างกัน ไม่ควรเกิดขึ้น - ให้ update ตาม guidfixed เดิม
            return await updateTransaction(client, trx, checkRawData['data']['guidfixed']);
          } else {
            try {
              String baseDocNo = trx.docno.split('-')[0];
              String suffix = trx.docno.contains('-') ? trx.docno.split('-')[1] : '';

              int xCount = suffix.replaceAll(RegExp(r'[^x]'), '').length;
              xCount++;
              trx.docno = "$baseDocNo-${'x' * xCount}";

              BillHelper().updatesDocNumber(newDocNumber: trx.docno, guidpos: trx.guidpos);
              List<BillDetailObjectBoxStruct> billDetails = global.objectBoxStore
                  .box<BillDetailObjectBoxStruct>()
                  .query(BillDetailObjectBoxStruct_.guidpos.equals(trx.guidpos))
                  .build()
                  .find();
              for (var billDetail in billDetails) {
                billDetail.doc_number = trx.docno;
                global.objectBoxStore.box<BillDetailObjectBoxStruct>().put(billDetail);
              }

              return await saveTransactionAndUploadImages(client, trx);
            } catch (e) {
              AppLogger.error('Error fetching bill details: $e');
              String baseDocNo = trx.docno.split('-')[0];
              String suffix = trx.docno.contains('-') ? trx.docno.split('-')[1] : '';

              int xCount = suffix.replaceAll(RegExp(r'[^x]'), '').length;
              xCount++;
              trx.docno = "$baseDocNo-${'xx' * xCount}";
              BillHelper().updatesDocNumber(newDocNumber: trx.docno, guidpos: trx.guidpos);
              List<BillDetailObjectBoxStruct> billDetails = global.objectBoxStore
                  .box<BillDetailObjectBoxStruct>()
                  .query(BillDetailObjectBoxStruct_.guidpos.equals(trx.guidpos))
                  .build()
                  .find();
              for (var billDetail in billDetails) {
                billDetail.doc_number = trx.docno;
                global.objectBoxStore.box<BillDetailObjectBoxStruct>().put(billDetail);
              }

              return await saveTransactionAndUploadImages(client, trx);
            }
          }
        }
      } else {
        throw handleError(checkRawData);
      }
    } on DioException catch (checkEx) {
      final errorData = checkEx.response?.data;
      if (errorData != null && errorData['message'] == "document not found") {
        return await saveTransactionAndUploadImages(client, trx);
      } else {
        global.syncDataProcess = false;
        throw handleError(checkEx.response?.toString());
      }
    }
  }

  Future<ApiResponse> saveTransactionAndUploadImages(Dio client, TransactionModel trx) async {
    final stopwatch = Stopwatch()..start();
    int uploadedCount = 0;
    int deletedCount = 0;

    try {
      if (kDebugMode) {
        AppLogger.debug('[ImageUpload] 🚀 Starting image upload process...');
        AppLogger.debug('[ImageUpload]    📄 DocNo: ${trx.docno}');
      }

      // ⭐ Add Idempotency-Key header to prevent duplicate submissions
      final saveResponse = await client.post(
        '/transaction/sale-invoice',
        data: trx.toJson(),
        options: Options(headers: {'X-Idempotency-Key': trx.guidpos}),
      );
      final saveRawData = json.decode(saveResponse.toString());

      if (saveRawData['error'] != null) {
        throw handleError(saveRawData);
      }

      // ⭐ Query ObjectBox เอาเฉพาะงานที่ยัง pending (ป้องกัน upload ซ้ำ)
      List<UploadQueueObjectBoxStruct> pendingJobs = global.getPendingUploadJobs(docNumber: trx.docno);

      // ⭐ เช็คว่าไฟล์ยังมีอยู่จริง
      List<File> filesToUpload = [];
      for (var job in pendingJobs) {
        final file = File(job.filePath);
        if (await file.exists()) {
          filesToUpload.add(file);
        } else {
          // ถ้าไฟล์หายไป แต่ยัง pending → mark เป็น failed
          AppLogger.warning('[ImageUpload]    ⚠️ File not found, marking as failed: ${job.fileName}');
          await global.updateUploadJobStatus(fileName: job.fileName, status: UploadQueueStatus.failed, errorMessage: 'File not found');
        }
      }

      // ⭐ Optimized: Parallel file upload instead of sequential
      if (filesToUpload.isNotEmpty) {
        AppLogger.debug('[ImageUpload] 📤 Uploading ${filesToUpload.length} image(s) (pending only)...');

        await Future.wait(filesToUpload.map((file) => uploadFile(client, file, trx)));
        uploadedCount = filesToUpload.length;

        // ⭐ แทนที่การลบไฟล์ทันที → บันทึก upload success ลง ObjectBox
        // ไฟล์จะถูกเก็บไว้ 7 วัน และลบโดย cleanup service
        AppLogger.debug('[ImageUpload] Marking images as uploaded (keep for 7 days)...');

        for (var file in filesToUpload) {
          try {
            final fileName = file.path.split('\\').last;

            // อัพเดทสถานะใน ObjectBox เป็น "completed"
            await global.updateUploadJobStatus(fileName: fileName, status: UploadQueueStatus.completed);

            deletedCount++; // นับเป็น "processed" แทน "deleted"
            AppLogger.debug('[ImageUpload]    ✅ Marked as uploaded: $fileName');
          } catch (updateEx) {
            // Log but don't fail the entire process
            AppLogger.warning('[ImageUpload]    ⚠️ Failed to update status for ${file.path.split('\\').last}: $updateEx');
          }
        }
      } else {
        AppLogger.debug('[ImageUpload]    ℹ️ No images to upload for docno: ${trx.docno}');
      }

      BillHelper().updatesSyncSuccess(docNumber: trx.docno);

      stopwatch.stop();
      if (kDebugMode) {
        AppLogger.success('[ImageUpload] ✅ Upload process completed in ${stopwatch.elapsedMilliseconds}ms');
        AppLogger.info('[ImageUpload]    📊 Uploaded: $uploadedCount | Deleted: $deletedCount');
      }

      return ApiResponse.fromMap(saveRawData);
    } catch (saveEx) {
      stopwatch.stop();
      AppLogger.debug('[ImageUpload] ❌ Upload process failed after ${stopwatch.elapsedMilliseconds}ms: $saveEx');
      global.syncDataProcess = false;
      AppLogger.error(saveEx);
      throw Exception(saveEx);
    }
  }

  Future<ApiResponse> updateTransaction(Dio client, TransactionModel trx, String guidfixed) async {
    try {
      final saveResponse = await client.put('/transaction/sale-invoice/$guidfixed', data: trx.toJson());
      final saveRawData = json.decode(saveResponse.toString());

      if (saveRawData['error'] != null) {
        throw handleError(saveRawData);
      }

      BillHelper().updatesSyncSuccess(docNumber: trx.docno);
      return ApiResponse.fromMap(saveRawData);
    } catch (saveEx) {
      global.syncDataProcess = false;
      AppLogger.error(saveEx);
      throw Exception(saveEx);
    }
  }

  /// Public method สำหรับ update VAT จาก bill_helper
  /// เรียกใช้เมื่อมีการ update Full VAT หลังจากที่บิล sync ไปแล้ว
  Future<ApiResponse> updateTransactionVat(TransactionModel trx) async {
    Dio client = Client().init();

    try {
      // เรียก API GET เพื่อเอา guidfixed (ใช้ guidpos แทน docno)
      final checkResponse = await client.get('/transaction/sale-invoice/guidpos/${trx.guidpos}');
      final checkRawData = json.decode(checkResponse.toString());

      if (checkRawData['error'] == null) {
        String guidfixed = checkRawData['data']['guidfixed'];

        // เรียก updateTransaction ที่มีอยู่แล้ว
        return await updateTransaction(client, trx, guidfixed);
      } else {
        throw handleError(checkRawData);
      }
    } on DioException catch (ex) {
      final errorData = ex.response?.data;
      if (errorData != null && errorData['message'] == "document not found") {
        // ถ้าไม่พบเอกสาร แสดงว่ายังไม่ได้ sync ให้ throw error
        throw Exception('Document not found on server. Cannot update VAT for un-synced bill.');
      } else {
        throw handleError(ex.response?.toString());
      }
    } catch (e) {
      AppLogger.error('Failed to update transaction VAT: $e');
      rethrow;
    }
  }

  Future<List<File>> getFilesContainingDocNo(Directory targetDir, String docno) async {
    if (kDebugMode) {
      AppLogger.debug('[ImageUpload] 🔍 Searching for slip images...');
      AppLogger.debug('[ImageUpload]    📂 Folder: ${targetDir.path}');
      AppLogger.debug('[ImageUpload]    📄 DocNo: $docno');
      AppLogger.success('[ImageUpload]    ✅ Folder exists: ${await targetDir.exists()}');
    }

    List<File> matchingFiles = [];
    if (await targetDir.exists()) {
      await for (var entity in targetDir.list()) {
        if (entity is File && entity.path.contains(docno)) {
          matchingFiles.add(entity);
          if (kDebugMode) {
            final fileSize = await entity.length();
            AppLogger.success('[ImageUpload]       ✅ Found: ${entity.path.split('\\').last} (${_formatBytes(fileSize)})');
          }
        }
      }
    }

    if (kDebugMode) {
      AppLogger.info('[ImageUpload]    📊 Total files found: ${matchingFiles.length}');
      if (matchingFiles.isEmpty) {
        AppLogger.warning('[ImageUpload]    ⚠️ No slip images found for docno: $docno');
      }
    }

    return matchingFiles;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> uploadFile(Dio client, File file, TransactionModel trx) async {
    final stopwatch = Stopwatch()..start();
    final fileName = file.path.split('\\').last;
    final fileSize = await file.length();

    try {
      if (kDebugMode) {
        AppLogger.debug('[ImageUpload] 📤 Uploading image...');
        AppLogger.debug('[ImageUpload]    📄 File: $fileName');
        AppLogger.debug('[ImageUpload]    📦 Size: ${_formatBytes(fileSize)}');
        AppLogger.debug('[ImageUpload]    🔢 DocNo: ${trx.docno}');
      }

      var data = FormData.fromMap({
        'mode': 0,
        'file': [await MultipartFile.fromFile(file.path, filename: file.path.split('/').last)],
        'docno': trx.docno,
        'posid': global.posConfig.code,
        'docdate': trx.docdatetime.split("T").first,
        'machinecode': global.posConfig.code,
        'branchcode': global.posConfig.branch.code,
        'zonegroupnumber': 'XX',
      });

      final response = await client.post('/slipimage/', data: data);
      final rawData = json.decode(response.toString());

      if (rawData['error'] != null) {
        throw handleError(rawData);
      }

      stopwatch.stop();
      AppLogger.debug('[ImageUpload]    ✅ Upload success in ${stopwatch.elapsedMilliseconds}ms');
    } catch (ex) {
      stopwatch.stop();
      if (kDebugMode) {
        AppLogger.error('[ImageUpload]    ❌ Upload failed: $ex');
        AppLogger.error('[ImageUpload]    ⏱️ Failed after ${stopwatch.elapsedMilliseconds}ms');
      }
      throw Exception(ex);
    }
  }

  Exception handleError(dynamic errorData) {
    String errorMessage = errorData is Map<String, dynamic> && errorData.containsKey('code') && errorData.containsKey('message')
        ? '${errorData['code']}: ${errorData['message']}'
        : errorData.toString();
    AppLogger.error(errorMessage);
    return Exception(errorMessage);
  }

  // Future<ApiResponse> checkAndSaveTransaction(TransactionModel trx) async {
  //   Dio client = Client().init();

  //   try {
  //     // Check if transaction exists
  //     final checkResponse = await client.get('/transaction/sale-invoice/code/${trx.docno}');
  //     final checkRawData = json.decode(checkResponse.toString());

  //     if (checkRawData['error'] == null) {
  //       if (trx.totalamount == checkRawData['data']['totalamount']) {
  //         BillHelper().updatesSyncSuccess(docNumber: trx.docno);
  //         return ApiResponse.fromMap(checkRawData);
  //       } else {
  //         final saveResponse = await client.post('/transaction/sale-invoice', data: trx.toJson());
  //         final saveRawData = json.decode(saveResponse.toString());

  //         if (saveRawData['error'] != null) {
  //           String errorMessage = '${saveRawData['code']}: ${saveRawData['message']}';
  //           AppLogger.error(errorMessage);
  //           throw Exception(errorMessage);
  //         }

  //         final Directory tempDir = await getTemporaryDirectory();
  //         final Directory targetDir = Directory('${tempDir.path}/${global.filePath(global.printerLocalStrongData[0].deviceName)}/temp');
  //         List<File> matchingFiles = [];
  //         if (!await targetDir.exists()) {
  //           matchingFiles = [];
  //         }

  //         await for (var entity in targetDir.list()) {
  //           if (entity is File) {
  //             if (entity.path.contains(trx.docno)) {
  //               matchingFiles.add(entity);
  //             }
  //           }
  //         }
  //         for (var file in filesToUpload) {
  //           AppLogger.debug('Found file: ${file.path}');

  //           var data = FormData.fromMap({
  //             'mode': 0,
  //             'file': [await MultipartFile.fromFile(file.path, filename: file.path.split('/').last)],
  //             'docno': trx.docno,
  //             'posid': global.posConfig.code,
  //             'docdate': trx.docdatetime.split("T").first,
  //             'machinecode': global.posConfig.code,
  //             'branchcode': global.posConfig.branch.code,
  //             'zonegroupnumber': 'XX'
  //           });
  //           final response = await client.post('/slipimage/', data: data);
  //           try {
  //             final rawData = json.decode(response.toString());
  //             //   print(rawData);
  //             if (rawData['error'] != null) {
  //               String errorMessage = '${rawData['code']}: ${rawData['message']}';
  //               throw Exception('${rawData['code']}: ${rawData['message']}');
  //             }
  //           } catch (ex) {
  //             throw Exception(ex);
  //           }
  //         }

  //         // Save successful, update sync status
  //         BillHelper().updatesSyncSuccess(docNumber: trx.docno);
  //         return ApiResponse.fromMap(saveRawData);
  //       }
  //     } else {
  //       String errorMessage = '${checkRawData['code']}: ${checkRawData['message']}';
  //       AppLogger.error(errorMessage);
  //       throw Exception(errorMessage);
  //     }
  //   } on DioException catch (checkEx) {
  //     final errorData = checkEx.response?.data;
  //     if (errorData != null && errorData['message'] == "document not found") {
  //       // If the document is not found (in the DioException response), proceed to save it
  //       try {
  //         final saveResponse = await client.post('/transaction/sale-invoice', data: trx.toJson());
  //         final saveRawData = json.decode(saveResponse.toString());

  //         if (saveRawData['error'] != null) {
  //           String errorMessage = '${saveRawData['code']}: ${saveRawData['message']}';
  //           AppLogger.error(errorMessage);
  //           throw Exception(errorMessage);
  //         }

  //         final Directory tempDir = await getTemporaryDirectory();
  //         final Directory targetDir = Directory('${tempDir.path}/${global.filePath(global.printerLocalStrongData[0].deviceName)}/temp');
  //         List<File> matchingFiles = [];
  //         if (!await targetDir.exists()) {
  //           matchingFiles = [];
  //         }

  //         await for (var entity in targetDir.list()) {
  //           if (entity is File) {
  //             if (entity.path.contains(trx.docno)) {
  //               matchingFiles.add(entity);
  //             }
  //           }
  //         }
  //         for (var file in filesToUpload) {
  //           AppLogger.debug('Found file: ${file.path}');

  //           var data = FormData.fromMap({
  //             'mode': 0,
  //             'file': [await MultipartFile.fromFile(file.path, filename: file.path.split('/').last)],
  //             'docno': trx.docno,
  //             'posid': global.posConfig.code,
  //             'docdate': trx.docdatetime.split("T").first,
  //             'machinecode': global.posConfig.code,
  //             'branchcode': global.posConfig.branch.code,
  //             'zonegroupnumber': 'XX'
  //           });
  //           final response = await client.post('/slipimage/', data: data);
  //           try {
  //             final rawData = json.decode(response.toString());
  //             //   print(rawData);
  //             if (rawData['error'] != null) {
  //               String errorMessage = '${rawData['code']}: ${rawData['message']}';
  //               throw Exception('${rawData['code']}: ${rawData['message']}');
  //             }
  //           } catch (ex) {
  //             throw Exception(ex);
  //           }
  //         }

  //         // Save successful, update sync status
  //         BillHelper().updatesSyncSuccess(docNumber: trx.docno);
  //         return ApiResponse.fromMap(saveRawData);
  //       } catch (saveEx) {
  //         global.syncDataProcess = false;
  //         AppLogger.error(saveEx);
  //         throw Exception(saveEx);
  //       }
  //     } else {
  //       global.syncDataProcess = false;
  //       String errorMessage = checkEx.response.toString();
  //       AppLogger.error(errorMessage);
  //       throw Exception(errorMessage);
  //     }
  //   }
  // }

  Future<ApiResponse> saveTransaction(TransactionModel trx) async {
    Dio client = Client().init();

    //String jsonPayload = jsonEncode(trx.toJson());
    try {
      final response = await client.post('/transaction/sale-invoice', data: trx.toJson());
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        global.syncDataProcess = false;
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      global.syncDataProcess = false;
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> saveShift(ShiftModel tran) async {
    Dio client = Client().init();
    //String jsonPayload = jsonEncode(trx.toJson());
    try {
      final response = await client.post('/pos/shift', data: tran.toJson());
      try {
        final rawData = json.decode(response.toString());
        AppLogger.debug(rawData);
        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        global.syncDataProcess = false;
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      global.syncDataProcess = false;
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> checkAndSaveReturn(TransactionModel trx) async {
    Dio client = Client().init();

    try {
      // Check if transaction exists
      final checkResponse = await client.get('/transaction/sale-invoice-return/code/${trx.docno}');
      final checkRawData = json.decode(checkResponse.toString());

      if (checkRawData['error'] == null) {
        BillHelper().updatesSyncSuccess(docNumber: trx.docno);
        return ApiResponse.fromMap(checkRawData);
      } else {
        String errorMessage = '${checkRawData['code']}: ${checkRawData['message']}';
        AppLogger.error(errorMessage);
        throw Exception(errorMessage);
      }
    } on DioException catch (checkEx) {
      final errorData = checkEx.response?.data;
      if (errorData != null && errorData['message'] == "document not found") {
        // If the document is not found (in the DioException response), proceed to save it
        try {
          final saveResponse = await client.post('/transaction/sale-invoice-return', data: trx.toJson());
          final saveRawData = json.decode(saveResponse.toString());

          if (saveRawData['error'] != null) {
            String errorMessage = '${saveRawData['code']}: ${saveRawData['message']}';
            AppLogger.error(errorMessage);
            throw Exception(errorMessage);
          }

          // Save successful, update sync status
          BillHelper().updatesSyncSuccess(docNumber: trx.docno);
          return ApiResponse.fromMap(saveRawData);
        } catch (saveEx) {
          global.syncDataProcess = false;
          AppLogger.error(saveEx);
          throw Exception(saveEx);
        }
      } else {
        global.syncDataProcess = false;
        String errorMessage = checkEx.response.toString();
        AppLogger.error(errorMessage);
        throw Exception(errorMessage);
      }
    }
  }

  Future<ApiResponse> saveReturn(TransactionModel trx) async {
    Dio client = Client().init();
    //String jsonPayload = jsonEncode(trx.toJson());
    try {
      final response = await client.post('/transaction/sale-invoice-return', data: trx.toJson());
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        global.syncDataProcess = false;
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      global.syncDataProcess = false;
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  /// ส่งข้อมูลขึ้น cloud
  Future syncBillProcess() async {
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
      AppLogger.debug('🔄 Sync process started...');
    }

    if (global.syncDataProcess == false && global.shopId.isNotEmpty) {
      global.syncDataProcess = true;
      syncStatus.value = SyncStatus.syncing;

      try {
        // Check network
        global.isOnline = await global.hasNetwork();

        if (kDebugMode) {
          AppLogger.debug('🌐 Network status: ${global.isOnline}');
          AppLogger.debug('🔐 API connected: ${global.apiConnected}');
        }

        if (global.isOnline) {
          // Login if not connected
          if (global.apiConnected == false) {
            if (!global.loginProcess) {
              AppLogger.debug('[SyncBill] 🔑 Attempting login...');

              global.loginProcess = true;
              UserRepository userRepository = UserRepository();
              await userRepository
                  .authenUser(global.apiUserName, global.apiUserPassword)
                  .then((result) async {
                    if (result.success) {
                      global.apiConnected = true;
                      global.appStorage.write("token", result.data["token"]);
                      serviceLocator<Log>().debug("Login Success");

                      AppLogger.debug('[SyncBill] ✅ Login successful');

                      ApiResponse selectShop = await userRepository.selectShop(global.apiShopID);
                      if (selectShop.success) {
                        serviceLocator<Log>().debug("Select Shop Success");

                        AppLogger.debug('[SyncBill] ✅ Shop selected: ${global.apiShopID}');
                      }
                    } else {
                      AppLogger.debug('[SyncBill] ❌ Login failed');
                    }
                  })
                  .catchError((e) {
                    AppLogger.error(e);
                    AppLogger.debug('[SyncBill] ❌ Login error: $e');
                    lastError.value = 'Login failed: $e';
                  })
                  .whenComplete(() async {
                    global.loginProcess = false;
                    await syncBillData();
                    await syncShift();
                  });
            }
          } else {
            // Already logged in, sync directly
            await syncBillData();
            await syncShift();
          }

          // Update success status
          syncStatus.value = SyncStatus.success;
          lastSyncTime.value = DateTime.now();
          lastError.value = null;

          AppLogger.debug('[SyncBill] ✅ Sync completed successfully');
        } else {
          AppLogger.debug('[SyncBill] ⚠️ No network connection');
          lastError.value = 'No network connection';
          syncStatus.value = SyncStatus.failed;
        }
      } catch (e, s) {
        AppLogger.error(e);
        global.sendErrorToDevTeam("syncBillProcess", "$e : $s");

        syncStatus.value = SyncStatus.failed;
        lastError.value = e.toString();

        if (kDebugMode) {
          AppLogger.error('❌ Sync error: $e');
          AppLogger.debug('Stack trace: $s');
        }
      }

      global.syncDataProcess = false;

      // ⭐ Performance logging (debug mode only)
      if (kDebugMode && stopwatch != null) {
        stopwatch.stop();
        AppLogger.success('[SyncBill] ⏱️ Sync process completed in ${stopwatch.elapsedMilliseconds}ms');
      }
    } else {
      if (kDebugMode) {
        if (global.syncDataProcess) {
          AppLogger.warning('⚠️ Sync already in progress, skipping...');
        }
        if (global.shopId.isEmpty) {
          AppLogger.warning('⚠️ Shop ID is empty, skipping sync');
        }
      }
    }
  }
}
