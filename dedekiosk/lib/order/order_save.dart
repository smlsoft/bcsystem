import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dedekiosk/model/billpay_model.dart';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/trans_model.dart';
import 'package:dedekiosk/model/category_model.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:dedekiosk/order/pay_page.dart';
import 'package:dedekiosk/order/models/background_task_data.dart';
import 'package:dedekiosk/order/services/background_task_manager.dart';
import 'package:dedekiosk/order/widgets/payment_success_dialog.dart';
import 'package:dedekiosk/widget/network_loading_indicator.dart';
import 'package:dedekiosk/order/order_util.dart' as order_util;
import 'package:dedekiosk/util/print_queue.dart';
import 'package:dedekiosk/service/bill_ledger_service.dart';
import 'package:dedekiosk/print/print.dart';
import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/api.dart' as api;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:dedekiosk/util/logger.dart';

Future<void> saveToClickHouse(
    {required DateTime docDateTime,
    required String orderDocNumber,
    required BillCalcAmount bill,
    required String queueNumber,
    required String orderTagNumber,
    required int orderType,
    required String discountWord,
    required List<OrderTempDetailModel> orderTempDetailList,
    bool forceUsePayLaterTable = false}) async {
  // Guard: Check if shopProfile is available
  if (global.shopProfile == null) {
    global.sendErrorToDevTeam("saveToClickHouse error: shopProfile is null");
    return;
  }

  const int maxRetries = 3;
  const Duration timeoutDuration = Duration(seconds: 15);

  {
    // forceUsePayLaterTable=true บังคับเขียนลง paylater tables (สำหรับ pay-at-cashier)
    // ไม่ตั้งใจให้กระทบ systemCondition global — แค่เลือก table ใน scope นี้
    final bool usePayLaterTable =
        forceUsePayLaterTable || global.deviceConfig.systemCondition == 1;
    String tableNameDoc = usePayLaterTable
        ? "${global.clickHouseDatabaseName}.ordertempdocpaylater"
        : "${global.clickHouseDatabaseName}.ordertempdoc";
    String tableNameTemp = usePayLaterTable
        ? "${global.clickHouseDatabaseName}.ordertemppaylater"
        : "${global.clickHouseDatabaseName}.ordertemp";
    // Insert data from ObjectBox to ClickHouse
    // insert order detail (isclose=9 wait)
    String queryData = "";
    int lineNumber = 0;
    String dateTimeNowForInsert =
        DateFormat("yyyy-MM-dd HH:mm:ss").format(docDateTime.toUtc());
    for (var order in orderTempDetailList) {
      lineNumber++;
      if (queryData.isNotEmpty) {
        queryData += ",";
      }
      queryData +=
          "($lineNumber, '${global.deviceConfig.shopId}', '${global.deviceConfig.branchId}', '${global.orderId}', '${order.orderguid}', '$dateTimeNowForInsert', '${order.barcode}', 2, ${order.qty}, '${order.optionselected}', '${global.shopProfile?.orderstation.deviceinfo.code}', '${order.remark}', ${order.istakeaway}, ${order.price}, ${order.amount}, 0, '', '$orderTagNumber', $queueNumber, ${order.optionamount}, '${order.salechannelcode}', '$orderDocNumber')";
    }
    if (queryData.isNotEmpty) {
      String queryInsert =
          "insert into $tableNameTemp (linenumber, shopid, branchid, orderid, orderguid, orderdatetime, barcode, isclose, qty, optionselected, machineid, remark, istakeaway, price, amount, isprintkitchensuccess, tablenumber, ordertagnumber, queuenumber, optionamount, salechannelcode, ordernumber) values $queryData";

      // Retry with timeout for order details
      for (int retry = 0; retry < maxRetries; retry++) {
        try {
          await api.clickHouseExecute(queryInsert).timeout(timeoutDuration);
          break;
        } catch (e) {
          Logger.w(
              'saveToClickHouse ordertemp retry ${retry + 1}/$maxRetries: $e');
          if (retry == maxRetries - 1) {
            global.sendErrorToDevTeam(
                "saveToClickHouse ordertemp failed after $maxRetries retries: $e");
          } else {
            await Future.delayed(Duration(seconds: retry + 1));
          }
        }
      }
    }
    String payJson = jsonEncode(global.payCondition);
    String queryInsert =
        "insert into $tableNameDoc (shopid, branchid, orderid, ordernumber, orderdatetime, phonenumber, tablenumber, queuenumber, ordertype, istakeaway, detailsuccess, isclose, ordertagnumber, paycondition, totalamount, vatamount, discountword, discountamount, diffamount, saveamount, beforvat, vatrate, exceptvat, aftervat, salechannelcode) values ('${global.deviceConfig.shopId}', '${global.deviceConfig.branchId}', '${global.orderId}', '$orderDocNumber', '$dateTimeNowForInsert', '${global.phoneNumber}', '${global.tableNumber}', $queueNumber, $orderType, ${global.isTakeAway}, 1, 1, '$orderTagNumber', '$payJson', ${bill.totalAmount}, ${bill.totalVatAmount}, '$discountWord', ${bill.totalDiscount}, ${bill.diffAmount}, ${bill.saveAmount}, ${bill.amountBeforeCalcVat}, ${global.shopProfile!.orderstation.vatrate}, ${bill.totalItemExceptVatAmount}, ${bill.amountAfterCalcVat}, '${global.saleChannelCode}')";

    // Retry with timeout for order doc
    for (int retry = 0; retry < maxRetries; retry++) {
      try {
        var result =
            await api.clickHouseExecute(queryInsert).timeout(timeoutDuration);
        ResponseExcludeModel responseData =
            ResponseExcludeModel.fromJson(result);
        if (responseData.success == false) {
          throw Exception("insert failed");
        }
        break;
      } catch (e) {
        Logger.w(
            'saveToClickHouse ordertempdoc retry ${retry + 1}/$maxRetries: $e');
        if (retry == maxRetries - 1) {
          global.sendErrorToDevTeam(
              "saveToClickHouse ordertempdoc failed after $maxRetries retries: $queryInsert - $e");
        } else {
          await Future.delayed(Duration(seconds: retry + 1));
        }
      }
    }
  }
  // หมายเหตุ: การอัพเดท isclose=1 ถูกย้ายไปทำใน payAndSave() แล้ว
  // เพื่อให้แน่ใจว่าทำเสร็จก่อนกลับหน้าหลัก (ป้องกัน race condition)
}

Future<void> payAndSave({
  required double totalAmount,
  required double vatAmount,
  required double discountAmount,
  required String discountWord,
  required double diffAmount,
  required double saveAmount,
  required String orderTagNumber,
  required BuildContext context,
  required List<OrderTempDetailModel> orderTempDetailList,
  required BillCalcAmount bill,
  required bool payNow,
  bool payAtCashier = false,
}) async {
  // Guard: Check if shopProfile is available
  if (global.shopProfile == null) {
    global.sendErrorToDevTeam("payAndSave error: shopProfile is null");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(global.language("error_occurred_please_try_again"))),
      );
    }
    return;
  }
  // Send Order to shop owner
  // Get queue number with offline fallback
  final queueResult =
      await global.getQueueNumberWithFallback(orderId: global.orderId);
  int queueNumber = queueResult['queueNumber'] as int;
  bool isOfflineMode = queueResult['isOffline'] as bool;

  /// 0=ordered by customer, 1=ordered by staff
  int orderType = 1;
  DateTime docDateTime = DateTime.now();

  // ===== Pay-at-Cashier branch — STUB CREATION =====
  // pending-cashier = "ใบแจ้งยอด" ไม่ใช่ order
  // - ไม่ reserve สต็อก (release ที่ orderAdd จองไว้)
  // - ไม่ส่งครัว (เขียน paylater ด้วย isclose=0 ทำให้ kitchen poll ข้าม)
  // - ไม่สร้าง BillLedger (origin device ไม่ได้สร้าง transaction)
  // - ไม่ใช้ doc no (ใช้ stubId UUID แทน — ไม่ชนกับ pay-now)
  // cashier settle ภายหลัง = เข้า payAndSave(payNow:true) เต็มรูปแบบ
  if (payAtCashier) {
    if (context.mounted) {
      NetworkLoadingOverlay.show(context, message: "กำลังเตรียมใบแจ้งยอด...");
      try {
        final db = global.clickHouseDatabaseName;
        final shopId = global.deviceConfig.shopId;
        final branchId = global.deviceConfig.branchId;
        final deviceId = global.deviceConfig.orderStationCode;

        // 1. สร้าง stub id (UUID — ไม่ชนกับ doc no ของ pay-now)
        final stubId = 'CASHIER-${const Uuid().v4()}';
        final cartOrderId = global.orderId; // orderId ของ cart ปัจจุบัน

        // cashierKitchenTiming: 0 = ส่งครัวหลัง settle (default), 1 = ส่งครัวทันที
        final bool sendKitchenNow =
            global.deviceConfig.cashierKitchenTiming == 1;
        // โหมด A (0): isclose=0 (ข้าม kitchen), release stock
        // โหมด B (1): isclose=2 (kitchen poll เจอ), ไม่ release stock (ใช้ที่ orderAdd จอง)
        final int detailIsclose = sendKitchenNow ? 2 : 0;
        final int detailKitchenPrintFlag =
            sendKitchenNow ? 0 : 1; // 0 = ให้ kitchen พิมพ์, 1 = ข้าม kitchen

        // 2. RELEASE stock เฉพาะโหมด A (โหมด B เก็บ reservation ไว้)
        if (!sendKitchenNow) {
          await api.releaseCartStock(orderId: cartOrderId);
        }

        // 3. เขียน cart snapshot ลง paylater tables
        //    header: ordertempdocpaylater (ordernumber=stubId, orderpaysuccess=0)
        final escapedStub = stubId.replaceAll("'", "''");
        final escapedTag = orderTagNumber.replaceAll("'", "''");
        await api.clickHouseExecute(
            "insert into $db.ordertempdocpaylater (shopid, branchid, orderid, ordernumber, orderdatetime, phonenumber, tablenumber, queuenumber, ordertype, istakeaway, detailsuccess, isclose, ordertagnumber, paycondition, totalamount, vatamount, discountword, discountamount, diffamount, saveamount, beforvat, vatrate, exceptvat, aftervat, salechannelcode) "
            "values ('$shopId', '$branchId', '$cartOrderId', '$escapedStub', now(), '', '$escapedTag', $queueNumber, $orderType, ${global.isTakeAway}, 0, 0, '$escapedTag', '[]', ${bill.totalAmount}, ${bill.totalVatAmount}, '$discountWord', ${bill.totalDiscount}, 0, 0, 0, 0, 0, ${bill.amountAfterCalcVat}, '${global.saleChannelCode}')");

        //    detail: ordertemppaylater
        //    NOTE schema จริง (verify แล้ว): tablenumber/queuenumber/salechannelcode/optionamount/discountamount
        //    เป็น Int32 (ต่างจาก ordertemp ที่เป็น String/Float64); ไม่มี column ordernumber/manufacturerguid
        //    โหมด A: isclose=0 (ข้าม kitchen), isprintkitchensuccess=1
        //    โหมด B: isclose=2 (kitchen poll เจอ), isprintkitchensuccess=0 (ให้ครัวพิมพ์)
        int lineNumber = 0;
        // parse Int32 columns (fallback 0 ถ้าไม่ใช่ตัวเลข)
        int safeParseInt(dynamic v) {
          if (v == null) return 0;
          return int.tryParse(v.toString()) ?? 0;
        }

        final int tableNum = safeParseInt(orderTagNumber);
        final int saleChannelNum = safeParseInt(global.saleChannelCode);
        for (final item in orderTempDetailList) {
          lineNumber++;
          final optionSel = item.optionselected.replaceAll("'", "''");
          final remark = item.remark.replaceAll("'", "''");
          await api.clickHouseExecute(
              "insert into $db.ordertemppaylater (linenumber, shopid, branchid, orderid, orderguid, orderdatetime, barcode, isclose, qty, optionselected, machineid, remark, istakeaway, price, amount, isprintkitchensuccess, tablenumber, ordertagnumber, queuenumber, optionamount, discountamount, salechannelcode) "
              "values ($lineNumber, '$shopId', '$branchId', '$cartOrderId', '${item.orderguid}', now(), '${item.barcode}', $detailIsclose, ${item.qty}, '$optionSel', '$deviceId', '$remark', ${item.istakeaway}, ${item.price}, ${item.amount}, $detailKitchenPrintFlag, $tableNum, '$escapedTag', $queueNumber, ${(item.optionamount ?? 0).toInt()}, ${(item.discountamount ?? 0).toInt()}, $saleChannelNum)");
        }

        // 4. พิมพ์ใบแจ้งยอด QR (encode stubId — ยังไม่มี doc no จริง)
        final qrPayload = jsonEncode({
          'shopid': shopId,
          'stubid': stubId,
          'table': orderTagNumber,
          'amount': bill.totalAmount,
          'v': '2',
        });

        if (context.mounted) {
          NetworkLoadingOverlay.hide(context);
        }

        final printerConfig = global.deviceConfig.printerForOrderStation;
        if (printerConfig.ipAddress.isNotEmpty ||
            printerConfig.vendorId.isNotEmpty) {
          PayResultModel cashierPayResult = PayResultModel();
          cashierPayResult.totalAmount = bill.totalAmount;
          cashierPayResult.discountAmount = bill.totalDiscount;
          global.printQueue.add(PrintTicketClass(
            queueNumber: queueNumber,
            docDate: docDateTime,
            docNumber: stubId,
            orderTagNumber: orderTagNumber,
            orderId: cartOrderId,
            printType: 3,
            openCashDrawer: false,
            orderType: orderType,
            footer: "",
            saveToFile: false,
            orderList: orderTempDetailList,
            printerLocalConfig: printerConfig,
            orderTempDetails: [],
            payResult: cashierPayResult,
            printLogo: false,
            printHeader: false,
            qrCode: qrPayload,
          ));
          await printQueueWorker();
        } else {
          Logger.w('payAtCashier: no printer configured, skipping slip print',
              tag: 'PayAtCashier');
        }

        // 5. Clear cart + กลับ home
        global.objectBoxStore.box<OrderTempObjectBoxModel>().removeAll();
        if (context.mounted) {
          global.backToHome(context);
        }
      } catch (e, s) {
        Logger.e('payAtCashier stub creation error', error: e, stackTrace: s);
        if (context.mounted) {
          NetworkLoadingOverlay.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("เกิดข้อผิดพลาดในการเตรียมใบแจ้งยอด: $e")),
          );
        }
      }
    }
    return;
  }

  if (payNow == false) {
    // Don't show payment page (pay later mode)
    if (context.mounted) {
      // Pay later mode: when order is placed, no payment prompt, save to ClickHouse immediately
      PayLaterSavingDialog.show(context);

      // Go back to home after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          global.backToHome(context);
        }
      });

      // Save to ClickHouse Server to store data and send to kitchen
      await saveToClickHouse(
          docDateTime: docDateTime,
          orderDocNumber: await global.orderPayLaterRunning(),
          bill: bill,
          queueNumber: queueNumber.toString(),
          orderTagNumber: orderTagNumber,
          orderType: orderType,
          discountWord: discountWord,
          orderTempDetailList: orderTempDetailList);

      // Clear selected items in ObjectBox to start fresh
      global.objectBoxStore.box<OrderTempObjectBoxModel>().removeAll();
    }
  } else {
    // Show payment page (pay now mode)
    // Running
    if (context.mounted) {
      // Payment page
      global.countDownForHome = global.countDownForHomeMax;
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PayPage(
                context: context,
                amount: bill.totalAmount,
                orderTagNumber: orderTagNumber)),
      );

      // Check if user cancelled payment
      if (global.payCondition.isEmpty) {
        Logger.d('payAndSave: User cancelled payment');
        return; // Exit function if user cancelled
      }

      // ===== ช่องโหว่ A: ล็อกหน้าจอระหว่างประมวลผลหลังชำระเงิน =====
      // ก่อนหน้านี้หลัง PayPage ปิดจนถึงตอน PaymentSuccessDialog.show ขึ้น
      // จะมีช่องว่างที่ user กดปุ่มอื่นได้ (cart ยังโต้ตอบได้) เพราะงานด้านล่าง
      // (สร้าง payResult, reserveNextDocNo, createPaidLedger) ใช้เวลา async สั้นๆ
      // จึงแสดง blocking overlay ทันที แล้วปิดตอน PaymentSuccessDialog ขึ้นรับช่วง
      if (context.mounted) {
        NetworkLoadingOverlay.show(context, message: "กำลังบันทึก...");
      }

      // After payment success
      bill.roundAmount = 0;
      if (global.payCondition.isNotEmpty) {
        int payCashIndex = global.payCondition.indexWhere(
          (element) => element.payType == 0,
        );
        if (payCashIndex != -1 && global.payCondition.isNotEmpty) {
          global.payCondition[payCashIndex].changeAmount = 0;
          bill.roundAmount += global.payCondition[payCashIndex].roundAmount;
        }

        PayConditionModel qrPay = global.payCondition.firstWhere(
          (element) => element.payType == 2,
          orElse: () => PayConditionModel(
              payType: 2,
              payTypeName: "",
              amount: 0,
              payAmount: 0,
              changeAmount: 0),
        );

        PayConditionModel payCredit = global.payCondition.firstWhere(
          (element) => element.payType == 1,
          orElse: () => PayConditionModel(
              payType: 1,
              payTypeName: "",
              amount: 0,
              payAmount: 0,
              changeAmount: 0),
        );

        List<BillPayObjectBoxStruct> pays = [];
        if (qrPay.payAmount > 0) {
          bill.roundAmount += qrPay.roundAmount;
          pays.add(BillPayObjectBoxStruct(
            trans_flag: 5,
            provider_code: qrPay.payTypeName,
            provider_name: qrPay.payTypeName,
            description: "QRPayment",
            amount: qrPay.payAmount,
          ));
        }
        if (payCredit.payAmount > 0) {
          bill.roundAmount += payCredit.roundAmount;
          pays.add(BillPayObjectBoxStruct(
            trans_flag: 1,
            book_bank_code: payCredit.payTypeName,
            bank_code: payCredit.payTypeName,
            bank_name: payCredit.payTypeName,
            approved_code: payCredit.approvalCode,
            card_number: payCredit.cardNumber,
            description: "CreditCard",
            amount: payCredit.amount,
          ));
        } // Calculate rounding from payCondition (for receipt, don't modify bill object)
        double roundAmountForReceipt =
            double.parse((bill.roundAmount).toStringAsFixed(2));
        double diffAmountForReceipt = roundAmountForReceipt;

        // Don't modify bill.totalAmount and bill.diffAmount
        // To avoid affecting summary page that uses same bill object

        // Get final doc number from local-first running. Do not use OFF- fallback.
        final billLedgerService = BillLedgerService();
        String orderDocNumber = await billLedgerService.reserveNextDocNo();

        // Show "Printing receipt" Dialog (don't go home immediately)
        // Dialog จะถูกปิดโดย backToHome หรือ user กด skip
        if (context.mounted) {
          // ปิด blocking overlay จากช่องโหว่ A ก่อน PaymentSuccessDialog รับช่วงครอบ
          NetworkLoadingOverlay.hide(context);
          // ไม่ต้อง await - dialog จะแสดงและรอจนกว่าพิมพ์เสร็จหรือ user กด skip
          PaymentSuccessDialog.show(context, isOfflineMode: isOfflineMode);
        }
        PayResultModel payResult = PayResultModel();
        payResult.discountWord = discountWord;
        payResult.discountAmount = bill.totalDiscount;
        payResult.diffAmount = diffAmountForReceipt;
        payResult.totalAmount = bill.totalAmount;
        payResult.vatAmount = bill.totalVatAmount;
        payResult.saveAmount = bill.saveAmount;
        payResult.payCondition = global.payCondition;
        payResult.vatrate = global.shopProfile!.orderstation.vatrate;
        payResult.totalAmountExceptVat = bill.totalItemExceptVatAmount;
        payResult.totalAmountAfterVat = bill.amountAfterCalcVat;
        payResult.totalAmountBeforeVat = bill.amountBeforeCalcVat;
        // ข้อมูลแต้มสะสม
        payResult.usePoint = global.usePoint;
        payResult.getPoint = global.getPoint;
        payResult.pointDiscountAmount = global.pointDiscountAmount;
        payResult.payPointAmount = global.pointAmount;
        payResult.previousPointBalance = global.memberPointBalance;
        payResult.currentPointBalance = global.currentPointBalance;
        payResult.memberName = global.memberName;
        payResult.memberPhone = global.phoneNumber;

        final billLedger = billLedgerService.createPaidLedger(
          printedDocNo: orderDocNumber,
          queueNumber: queueNumber,
          orderTagNumber: orderTagNumber,
          orderType: orderType,
          docDateTime: docDateTime,
          bill: bill,
          orderTempDetailList: orderTempDetailList,
          payCondition: global.payCondition,
          orderId: global.orderId,
          saleChannelCode: global.saleChannelCode,
          pinHistoryId:
              '${global.deviceConfig.shopId}|${global.deviceConfig.branchId}|${global.deviceConfig.orderStationCode}|${global.deviceConfig.isdev}',
        );

        {
          // ============ PREPARE LEDGER PAYLOAD ============
          // Build before printing so the local ledger has a full
          // saveTransaction payload before it becomes syncable.
          final backgroundData = BackgroundTaskData.fromCurrentState(
            localBillId: billLedger.localBillId,
            billLedgerId: billLedger.id,
            payloadChecksum: billLedger.payloadChecksum,
            orderDocNumber: orderDocNumber,
            queueNumber: queueNumber,
            orderTagNumber: orderTagNumber,
            orderType: orderType,
            docDateTime: docDateTime,
            discountWord: discountWord,
            bill: bill,
            orderTempDetailList: orderTempDetailList,
            memberCode: global.memberCode,
            custNames: global.custNames,
            phoneNumber: global.phoneNumber,
            tableNumber: global.tableNumber,
            orderId: global.orderId,
            isTakeAway: global.isTakeAway,
            globalOrderType: global.orderType,
            saleChannelCode: global.saleChannelCode,
            saleChannelgp: global.saleChannelgp,
            saleChannelgptype: global.saleChannelgptype,
            tableNumberSelectedOrdertagnumber:
                global.tableNumberSelected.ordertagnumber,
            payConditionList: global.payCondition,
            shopName1: global.shopProfile!.name1,
            branchCode: global.shopProfile!.orderstation.branch.code,
            branchNames: global.shopProfile!.orderstation.branch.names,
            orderStationCode: global.shopProfile!.orderstation.code,
            vatRate: global.shopProfile!.orderstation.vatrate,
            vatType: global.shopProfile!.orderstation.vattype,
            isVatRegister: global.shopProfile!.orderstation.isvatregister,
            deviceShopId: global.deviceConfig.shopId,
            deviceBranchId: global.deviceConfig.branchId,
            deviceOrderStationCode: global.deviceConfig.orderStationCode,
            deviceSystemCondition: global.deviceConfig.systemCondition,
            usePoint: 0,
            getPoint: 0,
            pointDiscountAmount: global.pointDiscountAmount,
            pointAmount: global.pointAmount,
            currentPointBalance: global.currentPointBalance,
            memberPointsCode: global.memberPointsCode,
            memberGuidFixed: global.memberGuidFixed,
            memberPinCode: global.memberPinCode,
            isBCMember: global.shopProfile?.isbcmember ?? false,
            shopName: global.shopProfile?.name1 ?? '',
            bcMemberName: global.memberName,
            bcMemberPicture: global.memberPicture,
          );
          final taskManager = BackgroundTaskManager();
          final cancellationToken = taskManager.createToken(orderDocNumber);
          try {
            await _saveTransactionBackgroundWithData(
              backgroundData,
              cancellationToken,
              prepareLedgerPayloadOnly: true,
            );
          } finally {
            taskManager.removeToken(orderDocNumber);
          }
        }

        // Print receipt with Device (pay now mode)
        String orderTypeName = "";
        if (global.orderType == 1) {
          // Takeaway
          String orderTakeAwayWord =
              " ${global.findLanguage(code: "order_take_away", languageCode: global.countryCodes[0])}";
          if (global.countryCodes[0] != global.languageForCustomer) {
            orderTakeAwayWord +=
                "/${global.findLanguage(code: "order_take_away", languageCode: global.languageForCustomer)}";
          }
          orderTypeName = orderTakeAwayWord;
          if (global.saleChannelCode.isNotEmpty) {
            orderTypeName += " ${global.saleChannelCode}";
          }
        }

        String footerWord = global.findLanguage(
            code: ((global.deviceConfig.machineCondition == 0)
                ? "the_officer_ordered"
                : "customers_order_it_themselves"),
            languageCode: global.countryCodes[0]);
        // If the language ordered is not the same as the first language of the system, print the language chosen by the customer
        if (global.countryCodes[0] != global.languageForCustomer) {
          footerWord +=
              "/${global.findLanguage(code: ((global.deviceConfig.machineCondition == 0) ? "the_officer_ordered" : "customers_order_it_themselves"), languageCode: global.languageForCustomer)}";
        }
        // If there is cash, open the drawer
        bool openCashDrawer = false;
        for (var payCondition in payResult.payCondition) {
          if (payCondition.payType == 0) {
            openCashDrawer = true;
            break;
          }
        } // Print with the device itself
        global.printQueue.add(PrintTicketClass(
            docDate: docDateTime,
            docNumber: orderDocNumber,
            orderTagNumber: orderTagNumber,
            orderId: orderDocNumber,
            printType: 0,
            printLogo: true,
            orderType: global.orderType,
            printHeader: true,
            orderTempDetails: [],
            queueNumber: queueNumber,
            saveToFile: true,
            footer: "$footerWord$orderTypeName",
            orderList: orderTempDetailList,
            printerLocalConfig: global.deviceConfig.printerForOrderStation,
            payResult: payResult,
            openCashDrawer: openCashDrawer,
            qrCode: "",
            memberPinCode: global.memberPinCode,
            isBCMember: global.shopProfile?.isbcmember ?? false));

        // Print now and wait for completion before going home
        await printQueueWorker();
        billLedgerService.markPrinted(billLedger);

        // ============ CREATE BACKGROUND TASK DATA ============
        // Use Data Class to reduce variable copying
        final backgroundData = BackgroundTaskData.fromCurrentState(
          localBillId: billLedger.localBillId,
          billLedgerId: billLedger.id,
          payloadChecksum: billLedger.payloadChecksum,
          orderDocNumber: orderDocNumber,
          queueNumber: queueNumber,
          orderTagNumber: orderTagNumber,
          orderType: orderType,
          docDateTime: docDateTime,
          discountWord: discountWord,
          bill: bill,
          orderTempDetailList: orderTempDetailList,
          memberCode: global.memberCode,
          custNames: global.custNames,
          phoneNumber: global.phoneNumber,
          tableNumber: global.tableNumber,
          orderId: global.orderId,
          isTakeAway: global.isTakeAway,
          globalOrderType: global.orderType,
          saleChannelCode: global.saleChannelCode,
          saleChannelgp: global.saleChannelgp,
          saleChannelgptype: global.saleChannelgptype,
          tableNumberSelectedOrdertagnumber:
              global.tableNumberSelected.ordertagnumber,
          payConditionList: global.payCondition,
          shopName1: global.shopProfile!.name1,
          branchCode: global.shopProfile!.orderstation.branch.code,
          branchNames: global.shopProfile!.orderstation.branch.names,
          orderStationCode: global.shopProfile!.orderstation.code,
          vatRate: global.shopProfile!.orderstation.vatrate,
          vatType: global.shopProfile!.orderstation.vattype,
          isVatRegister: global.shopProfile!.orderstation.isvatregister,
          deviceShopId: global.deviceConfig.shopId,
          deviceBranchId: global.deviceConfig.branchId,
          deviceOrderStationCode: global.deviceConfig.orderStationCode,
          deviceSystemCondition:
              global.deviceConfig.systemCondition, // ข้อมูลแต้มสะสม
          usePoint: 0,
          getPoint: 0,
          pointDiscountAmount: global.pointDiscountAmount,
          pointAmount: global.pointAmount,
          currentPointBalance: global.currentPointBalance,
          memberPointsCode: global.memberPointsCode,
          memberGuidFixed: global.memberGuidFixed,
          // BC Member
          memberPinCode: global.memberPinCode,
          isBCMember: global.shopProfile?.isbcmember ?? false,
          shopName: global.shopProfile?.name1 ?? '',
          bcMemberName: global.memberName,
          bcMemberPicture: global.memberPicture,
        ); // Create cancellation token for this order
        final taskManager = BackgroundTaskManager();
        final cancellationToken = taskManager.createToken(orderDocNumber);

        // ============ CRITICAL: UPDATE isclose=1 BEFORE GOING HOME ============
        // อัพเดท isclose=1 เพื่อยืนยันว่าขายแล้ว (ก่อนกลับหน้าหลัก)
        // ป้องกัน race condition: ถ้าไม่ทำตอนนี้ removeCalcQty() อาจลบรายการทิ้ง!
        try {
          const Duration updateTimeout = Duration(seconds: 10);
          String updateQuery =
              "alter table ${global.clickHouseDatabaseName}.ordertempcalcqty "
              "update isclose=1 "
              "where shopid='${global.deviceConfig.shopId}' "
              "and branchid='${global.deviceConfig.branchId}' "
              "and orderid='${global.orderId}' "
              "and isclose=0";

          await api.clickHouseExecute(updateQuery).timeout(updateTimeout);
          Logger.i(
              '✅ Updated isclose=1 for orderid=${global.orderId} (BEFORE going home)',
              tag: 'StockManagement');
        } catch (e) {
          Logger.e('❌ CRITICAL: Failed to update isclose=1 (BEFORE going home)',
              error: e);
          global.sendErrorToDevTeam(
              "CRITICAL: isclose update failed for ${global.orderId}: $e");

          // แสดง error dialog ให้ user รู้ว่ามีปัญหา
          if (context.mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text(global.language("warning")),
                content: const Text(
                    "การอัพเดทสต๊อกมีปัญหา กรุณาติดต่อเจ้าหน้าที่\n(Stock update failed, please contact staff)"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(global.language("confirm")),
                  ),
                ],
              ),
            );
          }
        }

        // ============ IMMEDIATE: CLEAR CART & GO HOME ============
        // Clear cart immediately
        global.objectBoxStore.box<OrderTempObjectBoxModel>().removeAll();

        // Reset global states
        global.saleChannelCode = "";
        global.saleChannelgp = 0;
        global.saleChannelgptype = 0;

        // Go back to home after printing completed
        if (context.mounted) {
          global.backToHome(context);
        }

        // ============ BACKGROUND: SAVE TRANSACTION & NOTIFICATIONS ============
        // Perform background tasks without blocking UI with cancellation support
        _runBackgroundTasksWithCancellation(backgroundData, cancellationToken);
      }
    }
  }
}

/// รัน Background Tasks พร้อม Cancellation support
void _runBackgroundTasksWithCancellation(
  BackgroundTaskData data,
  CancellationToken token,
) {
  Future.microtask(() async {
    try {
      // Check cancellation before starting
      token.throwIfCancelled();

      // Save to ClickHouse (if systemCondition == 2: pay now mode)
      if (data.deviceData.systemCondition == 2) {
        try {
          token.throwIfCancelled();
          await _saveToClickHouseBackgroundWithData(data);

          // Trigger kitchen print after ClickHouse save (for server mode)
          if (global.deviceConfig.isServer) {
            // Run print queue worker to check for kitchen prints
            // ใช้ await เพื่อป้องกัน race condition กับ timer
            await printQueueWorker();
          }
        } on TaskCancelledException {
          rethrow;
        } catch (e) {
          Logger.w('Background ClickHouse save failed: $e');
        }
      }

      // Check cancellation before telegram
      token.throwIfCancelled();

      // Send telegram notification
      try {
        await _sendTelegramNotificationWithData(data);
      } on TaskCancelledException {
        rethrow;
      } catch (e) {
        Logger.w('Background telegram notification failed: $e');
      }

      // Check cancellation before saving transaction
      token.throwIfCancelled();

      // Save transaction to MongoDB
      await _saveTransactionBackgroundWithData(data, token);

      // ✅ FIX: Upload slip หลังจาก save transaction สำเร็จแล้วเท่านั้น
      // เพราะ uploadslip ต้องการ docno ที่ได้จาก save transaction
      try {
        token.throwIfCancelled();
        Logger.i(
            '🔵 Starting slip upload after transaction saved: ${data.orderDocNumber}',
            tag: 'SlipUpload');
        await order_util.uploadSlipWorker();
        Logger.i('✅ Slip upload completed for order: ${data.orderDocNumber}',
            tag: 'SlipUpload');
      } on TaskCancelledException {
        rethrow;
      } catch (e) {
        Logger.w('Background slip upload failed for ${data.orderDocNumber}: $e',
            tag: 'SlipUpload');
        // ไม่ต้อง throw error เพราะ transaction บันทึกสำเร็จแล้ว
      }

      Logger.d('Background tasks completed for order: ${data.orderDocNumber}');
    } on TaskCancelledException catch (e) {
      Logger.d('Background task cancelled: $e');
    } catch (e, s) {
      Logger.e('Background task error', error: e, stackTrace: s);
      global.sendErrorToDevTeam("Background saveTransaction error: $e");
    } finally {
      // Always remove token when done
      BackgroundTaskManager().removeToken(data.orderDocNumber);
    }
  });
}

// ============ DATA CLASS WRAPPER FUNCTIONS ============

/// Wrapper: Save to ClickHouse using BackgroundTaskData
Future<void> _saveToClickHouseBackgroundWithData(
    BackgroundTaskData data) async {
  await _saveToClickHouseBackground(
    docDateTime: data.docDateTime,
    orderDocNumber: data.orderDocNumber,
    queueNumber: data.queueNumber.toString(),
    orderTagNumber: data.orderTagNumber,
    orderType: data.orderType,
    discountWord: data.discountWord,
    shopId: data.deviceData.shopId,
    branchId: data.deviceData.branchId,
    phoneNumber: data.globalData.phoneNumber,
    tableNumber: data.globalData.tableNumber,
    orderId: data.globalData.orderId,
    isTakeAway: data.globalData.isTakeAway,
    payCondition: data.payCondition,
    totalAmount: data.billData.totalAmount,
    totalVatAmount: data.billData.totalVatAmount,
    totalDiscount: data.billData.totalDiscount,
    diffAmount: data.billData.diffAmount,
    saveAmount: data.billData.saveAmount,
    amountBeforeCalcVat: data.billData.amountBeforeCalcVat,
    vatRate: data.shopData.vatRate,
    totalItemExceptVatAmount: data.billData.amountExceptVat,
    amountAfterCalcVat: data.billData.amountAfterCalcVat,
    saleChannelCode: data.globalData.saleChannelCode,
    orderTempDetailList: data.orderTempDetailList,
  );
}

/// Wrapper: Send telegram notification using BackgroundTaskData
Future<void> _sendTelegramNotificationWithData(BackgroundTaskData data) async {
  await _sendTelegramNotificationBackground(
    orderDocNumber: data.orderDocNumber,
    shopName1: data.shopData.shopName1,
    branchNames: data.shopData.branchNames,
    orderStationCode: data.shopData.orderStationCode,
    memberCode: data.globalData.memberCode,
    custNames: data.globalData.custNames,
    totalDiscount: data.billData.totalDiscount,
    totalAmount: data.billData.totalAmount,
    roundAmount: data.billData.roundAmount,
    payCondition: data.payCondition,
    tableNumber: data.globalData.tableNumber,
    orderTagNumber: data.orderTagNumber,
    orderTempDetailList: data.orderTempDetailList,
  );
}

/// Wrapper: Save transaction to MongoDB using BackgroundTaskData with cancellation support
Future<void> _saveTransactionBackgroundWithData(
    BackgroundTaskData data, CancellationToken token,
    {bool prepareLedgerPayloadOnly = false}) async {
  await _saveTransactionBackground(
    localBillId: data.localBillId,
    billLedgerId: data.billLedgerId,
    payloadChecksum: data.payloadChecksum,
    orderDocNumber: data.orderDocNumber,
    queueNumber: data.queueNumber,
    orderTagNumber: data.orderTagNumber,
    orderType: data.orderType,
    docDateTime: data.docDateTime,
    discountWord: data.discountWord,
    totalAmount: data.billData.totalAmount,
    totalVatAmount: data.billData.totalVatAmount,
    totalDiscount: data.billData.totalDiscount,
    amountBeforeCalcVat: data.billData.amountBeforeCalcVat,
    amountAfterCalcVat: data.billData.amountAfterCalcVat,
    amountExceptVat: data.billData.amountExceptVat,
    detailTotalAmountBeforeDiscount:
        data.billData.detailTotalAmountBeforeDiscount,
    totalAmountAfterDiscount: data.billData.totalAmountAfterDiscount,
    totalDiscountExceptVatAmount: data.billData.totalDiscountExceptVatAmount,
    totalDiscountVatAmount: data.billData.totalDiscountVatAmount,
    roundAmount: data.billData.roundAmount,
    sumCreditCard: data.billData.sumCreditCard,
    sumQrCode: data.billData.sumQrCode,
    memberCode: data.globalData.memberCode,
    custNames: data.globalData.custNames,
    orderStationCode: data.deviceData.orderStationCode,
    branchCode: data.shopData.branchCode,
    branchNames: data.shopData.branchNames,
    vatRate: data.shopData.vatRate,
    vatType: data.shopData.vatType,
    isVatRegister: data.shopData.isVatRegister,
    globalOrderType: data.globalData.globalOrderType,
    saleChannelCode: data.globalData.saleChannelCode,
    saleChannelgp: data.globalData.saleChannelgp,
    saleChannelgptype: data.globalData.saleChannelgptype,
    payCondition: data.payCondition,
    orderTempDetailList: data.orderTempDetailList,
    shopId: data.deviceData.shopId,
    branchId: data.deviceData.branchId,
    orderId: data.globalData.orderId,
    isTakeAway: data.globalData.isTakeAway,
    tableNumberSelectedOrdertagnumber:
        data.globalData.tableNumberSelectedOrdertagnumber,
    systemCondition: data.deviceData.systemCondition, // ข้อมูลแต้มสะสม
    usePoint: data.globalData.usePoint,
    getPoint: data.globalData.getPoint,
    pointDiscountAmount: data.globalData.pointDiscountAmount,
    pointAmount: data.globalData.pointAmount,
    currentPointBalance: data.globalData.currentPointBalance,
    memberPointsCode: data.globalData.memberPointsCode,
    memberGuidFixed: data.globalData.memberGuidFixed,
    // BC Member
    memberPinCode: data.globalData.memberPinCode,
    isBCMember: data.globalData.isBCMember,
    shopName: data.globalData.shopName,
    bcMemberName: data.globalData.bcMemberName,
    bcMemberPicture: data.globalData.bcMemberPicture,
    prepareLedgerPayloadOnly: prepareLedgerPayloadOnly,
  );
}

Future<bool> _serverHasSavedTransaction({
  required String localBillId,
  required String orderDocNumber,
  required double totalAmount,
}) async {
  for (int attempt = 0; attempt < 2; attempt++) {
    if (attempt > 0) {
      await Future.delayed(const Duration(seconds: 1));
    }
    try {
      final result = await api
          .getTransactionList(limit: 10, search: orderDocNumber)
          .timeout(const Duration(seconds: 10));
      final data = result.data;
      if (data is! List) continue;
      for (final item in data) {
        final text = jsonEncode(item);
        if (localBillId.isNotEmpty && text.contains(localBillId)) {
          return true;
        }
        if (item is Map) {
          final docNo = (item['docno'] ?? item['doc_no'] ?? '').toString();
          final savedTotal = double.tryParse(
              (item['totalamount'] ?? item['total_amount'] ?? '').toString());
          if (docNo == orderDocNumber &&
              savedTotal != null &&
              (savedTotal - totalAmount).abs() <= 0.01) {
            return true;
          }
        }
      }
    } catch (e) {
      Logger.w('Verify saveTransaction on server failed: $e',
          tag: 'SaveTransaction');
    }
  }
  return false;
}

// ============ BACKGROUND HELPER FUNCTIONS ============

/// Save to ClickHouse in background
Future<void> _saveToClickHouseBackground({
  required DateTime docDateTime,
  required String orderDocNumber,
  required String queueNumber,
  required String orderTagNumber,
  required int orderType,
  required String discountWord,
  required String shopId,
  required String branchId,
  required String phoneNumber,
  required String tableNumber,
  required String orderId,
  required int isTakeAway,
  required List<PayConditionModel> payCondition,
  required double totalAmount,
  required double totalVatAmount,
  required double totalDiscount,
  required double diffAmount,
  required double saveAmount,
  required double amountBeforeCalcVat,
  required double vatRate,
  required double totalItemExceptVatAmount,
  required double amountAfterCalcVat,
  required String saleChannelCode,
  required List<OrderTempDetailModel> orderTempDetailList,
}) async {
  const Duration timeoutDuration = Duration(seconds: 30);
  const int maxRetries = 3;

  try {
    // Insert doc header with retry
    String queryInsert =
        "insert into ${global.clickHouseDatabaseName}.ordertempdoc (shopid, branchid, orderid, ordernumber, orderdatetime, phonenumber, tablenumber, queuenumber, ordertype, istakeaway, detailsuccess, isclose, ordertagnumber, paycondition, totalamount, vatamount, discountword, discountamount, diffamount, saveamount, beforvat, vatrate, exceptvat, aftervat, salechannelcode, kitchensuccess, orderpaysuccess, copyprintsuccess) values ('$shopId', '$branchId', '$orderId', '$orderDocNumber', now(), '$phoneNumber', '$tableNumber', $queueNumber, $orderType, $isTakeAway, 1, 1, '$orderTagNumber', '${jsonEncode(payCondition)}', $totalAmount, $totalVatAmount, '$discountWord', $totalDiscount, $diffAmount, $saveAmount, $amountBeforeCalcVat, $vatRate, $totalItemExceptVatAmount, $amountAfterCalcVat, '$saleChannelCode', 0, 1, 0)";
    await api.clickHouseExecute(queryInsert).timeout(timeoutDuration);
    Logger.d('Background ClickHouse doc saved: $orderDocNumber');
  } catch (e) {
    Logger.w('Background ClickHouse doc save failed: $e');
  }

  // Insert order details using BATCH insert (more efficient & reliable)
  // Build batch insert query for all details at once
  if (orderTempDetailList.isNotEmpty) {
    String batchValues = "";
    for (int i = 0; i < orderTempDetailList.length; i++) {
      var detail = orderTempDetailList[i];
      if (batchValues.isNotEmpty) {
        batchValues += ",";
      }
      batchValues +=
          "('$shopId', '$orderId', '${const Uuid().v4()}', '', now(), '${detail.barcode}', ${detail.qty}, ${detail.price}, ${detail.amount}, 2, 0, $isTakeAway, '${detail.optionselected.replaceAll("'", "''")}', '${detail.remark.replaceAll("'", "''")}', 0, $queueNumber, '$orderDocNumber', '$branchId', 0, '$orderTagNumber', '$tableNumber', '${detail.barcode}', 0, ${detail.discountamount ?? 0}, '$saleChannelCode', $i, 0, 0, 0, 0, 0, 1, 1)";
    }

    String batchQuery =
        "insert into ${global.clickHouseDatabaseName}.ordertemp (shopid, orderid, orderguid, machineid, orderdatetime, barcode, qty, price, amount, isclose, isserved, istakeaway, optionselected, remark, istype, queuenumber, ordernumber, branchid, isprintkitchensuccess, ordertagnumber, tablenumber, orderbarcode, optionamount, discountamount, salechannelcode, linenumber, qtycancel, amountcancel, iscooked, iscookcancel, isservedcancel, paysuccess, orderpaysuccess) values $batchValues";

    // Retry mechanism for batch insert
    for (int retry = 0; retry < maxRetries; retry++) {
      try {
        await api.clickHouseExecute(batchQuery).timeout(timeoutDuration);
        Logger.d(
            'Background ClickHouse batch details saved: $orderDocNumber (${orderTempDetailList.length} items)');
        break;
      } catch (e) {
        Logger.w(
            'Background ClickHouse batch detail save retry ${retry + 1}/$maxRetries for $orderDocNumber: $e');
        if (retry == maxRetries - 1) {
          // Final retry failed, try inserting one-by-one as fallback
          Logger.w(
              'Batch insert failed, falling back to one-by-one insert for $orderDocNumber');
          await _insertDetailsOneByOne(
            shopId: shopId,
            orderId: orderId,
            isTakeAway: isTakeAway,
            queueNumber: queueNumber,
            orderDocNumber: orderDocNumber,
            branchId: branchId,
            orderTagNumber: orderTagNumber,
            tableNumber: tableNumber,
            saleChannelCode: saleChannelCode,
            orderTempDetailList: orderTempDetailList,
            timeoutDuration: timeoutDuration,
          );
        } else {
          await Future.delayed(Duration(seconds: (retry + 1) * 2));
        }
      }
    }
  }
}

/// Fallback: Insert details one by one with retry
Future<void> _insertDetailsOneByOne({
  required String shopId,
  required String orderId,
  required int isTakeAway,
  required String queueNumber,
  required String orderDocNumber,
  required String branchId,
  required String orderTagNumber,
  required String tableNumber,
  required String saleChannelCode,
  required List<OrderTempDetailModel> orderTempDetailList,
  required Duration timeoutDuration,
}) async {
  const int maxRetries = 3;

  for (int i = 0; i < orderTempDetailList.length; i++) {
    var detail = orderTempDetailList[i];
    String queryDetail =
        "insert into ${global.clickHouseDatabaseName}.ordertemp (shopid, orderid, orderguid, machineid, orderdatetime, barcode, qty, price, amount, isclose, isserved, istakeaway, optionselected, remark, istype, queuenumber, ordernumber, branchid, isprintkitchensuccess, ordertagnumber, tablenumber, orderbarcode, optionamount, discountamount, salechannelcode, linenumber, qtycancel, amountcancel, iscooked, iscookcancel, isservedcancel, paysuccess, orderpaysuccess) values ('$shopId', '$orderId', '${const Uuid().v4()}', '', now(), '${detail.barcode}', ${detail.qty}, ${detail.price}, ${detail.amount}, 2, 0, $isTakeAway, '${detail.optionselected.replaceAll("'", "''")}', '${detail.remark.replaceAll("'", "''")}', 0, $queueNumber, '$orderDocNumber', '$branchId', 0, '$orderTagNumber', '$tableNumber', '${detail.barcode}', 0, ${detail.discountamount ?? 0}, '$saleChannelCode', $i, 0, 0, 0, 0, 0, 1, 1)";

    for (int retry = 0; retry < maxRetries; retry++) {
      try {
        await api.clickHouseExecute(queryDetail).timeout(timeoutDuration);
        break;
      } catch (e) {
        Logger.w(
            'Background ClickHouse detail save retry ${retry + 1}/$maxRetries for ${detail.barcode}: $e');
        if (retry == maxRetries - 1) {
          global.sendErrorToDevTeam(
              "Background ClickHouse detail save failed after $maxRetries retries for $orderDocNumber item ${detail.barcode}: $e");
        } else {
          await Future.delayed(Duration(seconds: retry + 1));
        }
      }
    }
  }
}

/// Send telegram notification in background
Future<void> _sendTelegramNotificationBackground({
  required String orderDocNumber,
  required String shopName1,
  required List<LanguageNameModel>? branchNames,
  required String orderStationCode,
  required String memberCode,
  required List<TransNameInfoModel> custNames,
  required double totalDiscount,
  required double totalAmount,
  required double roundAmount,
  required List<PayConditionModel> payCondition,
  required String tableNumber,
  required String orderTagNumber,
  required List<OrderTempDetailModel> orderTempDetailList,
}) async {
  String branchName =
      (branchNames == null || branchNames.isEmpty) ? "" : branchNames[0].name;
  String message = "$shopName1 $branchName $orderStationCode\n";
  message += "Order number $orderDocNumber\n";

  if (memberCode.isNotEmpty && custNames.isNotEmpty) {
    message += "Member $memberCode~${custNames[0].name}\n";
  }

  if (totalDiscount != 0) {
    double totalAmountBeforeDiscount = totalAmount + totalDiscount;
    message +=
        "Total before discount ${global.moneyFormatAndDot.format(totalAmountBeforeDiscount)} Baht\n";
    message +=
        "Discount ${global.moneyFormatAndDot.format(totalDiscount)} Baht\n";
  }
  if (roundAmount != 0) {
    message +=
        "Rounding ${global.moneyFormatAndDot.format(roundAmount)} Baht\n";
  }
  message += "Total ${global.moneyFormatAndDot.format(totalAmount)} Baht\n";

  double changeAmount = 0;
  for (var pay in payCondition) {
    message +=
        "${pay.payTypeName} amount ${global.moneyFormatAndDot.format(pay.payAmount)} Baht\n";
    changeAmount += pay.changeAmount;
  }
  if (changeAmount != 0) {
    message += "Change ${global.moneyFormatAndDot.format(changeAmount)} Baht\n";
  }
  if (tableNumber.isNotEmpty) {
    message += "Table $tableNumber\n";
  }
  if (orderTagNumber.isNotEmpty) {
    message += "Order tag $orderTagNumber\n";
  }

  int lineNumber = 0;
  for (var order in orderTempDetailList) {
    int productIndex = global.findProductByBarcode(order.barcode);
    if (productIndex != -1) {
      lineNumber++;
      message +=
          "$lineNumber : ${global.getNameFromLanguage(global.productList[productIndex].names, global.languageForStaff)} : ${global.moneyFormat.format(order.qty)}/${global.getNameFromLanguage(global.productList[productIndex].unitnames, global.languageForStaff)} : ${global.moneyFormatAndDot.format(order.amount)} Baht";
      if (order.qty != 1) {
        message +=
            " Price (${global.moneyFormatAndDot.format(order.price)} Baht/${global.getNameFromLanguage(global.productList[productIndex].unitnames, global.languageForStaff)})";
      }
      message += "\n";
    }
  }

  global.telegramNotify(
      botToken: global.telegramTransBotToken,
      chatId: global.telegramTransChatId,
      message: message);
}

/// Save transaction to MongoDB in background with retry and offline fallback
Future<void> _saveTransactionBackground({
  required String localBillId,
  required int billLedgerId,
  required String payloadChecksum,
  required String orderDocNumber,
  required int queueNumber,
  required String orderTagNumber,
  required int orderType,
  required DateTime docDateTime,
  required String discountWord,
  required double totalAmount,
  required double totalVatAmount,
  required double totalDiscount,
  required double amountBeforeCalcVat,
  required double amountAfterCalcVat,
  required double amountExceptVat,
  required double detailTotalAmountBeforeDiscount,
  required double totalAmountAfterDiscount,
  required double totalDiscountExceptVatAmount,
  required double totalDiscountVatAmount,
  required double roundAmount,
  required double sumCreditCard,
  required double sumQrCode,
  required String memberCode,
  required List<TransNameInfoModel> custNames,
  required String orderStationCode,
  required String branchCode,
  required List<LanguageNameModel>? branchNames,
  required double vatRate,
  required int vatType,
  required bool isVatRegister,
  required int globalOrderType,
  required String saleChannelCode,
  required double saleChannelgp,
  required int saleChannelgptype,
  required List<PayConditionModel> payCondition,
  required List<OrderTempDetailModel> orderTempDetailList,
  required String shopId,
  required String branchId,
  required String orderId,
  required int isTakeAway,
  required String tableNumberSelectedOrdertagnumber,
  required int systemCondition, // ข้อมูลแต้มสะสม
  double usePoint = 0,
  double getPoint = 0,
  double pointDiscountAmount = 0,
  double pointAmount = 0,
  double currentPointBalance = 0,
  String memberPointsCode = '',
  String memberGuidFixed = '',
  // BC Member
  String memberPinCode = '',
  bool isBCMember = false,
  String shopName = '',
  String bcMemberName = '',
  String bcMemberPicture = '',
  bool prepareLedgerPayloadOnly = false,
}) async {
  DateTime dateNow = docDateTime;
  Logger.d(
    'Bill ledger context: id=$billLedgerId localBillId=$localBillId checksum=$payloadChecksum',
    tag: 'BillLedger',
  );

  // Build details
  List<TransDetailModel> details = [];
  double total_qty = 0;
  int linenumber = 0;

  int payCashIndex = payCondition.indexWhere((element) => element.payType == 0);

  // Build pays list
  List<BillPayObjectBoxStruct> pays = [];
  PayConditionModel? qrPay = payCondition.cast<PayConditionModel?>().firstWhere(
        (element) => element?.payType == 2,
        orElse: () => null,
      );
  PayConditionModel? payCredit =
      payCondition.cast<PayConditionModel?>().firstWhere(
            (element) => element?.payType == 1,
            orElse: () => null,
          );

  if (qrPay != null && qrPay.payAmount > 0) {
    pays.add(BillPayObjectBoxStruct(
      trans_flag: 5,
      provider_code: qrPay.payTypeName,
      provider_name: qrPay.payTypeName,
      description: "QRPayment",
      amount: qrPay.payAmount,
    ));
  }
  if (payCredit != null && payCredit.payAmount > 0) {
    pays.add(BillPayObjectBoxStruct(
      trans_flag: 1,
      book_bank_code: payCredit.payTypeName,
      bank_code: payCredit.payTypeName,
      bank_name: payCredit.payTypeName,
      approved_code: payCredit.approvalCode,
      card_number: payCredit.cardNumber,
      description: "CreditCard",
      amount: payCredit.amount,
    ));
  }

  for (var detail in orderTempDetailList) {
    List<TransNameInfoModel> itemnames = [];
    List<TransNameInfoModel> unitNames = [];
    String unitCode = "";

    for (var category in global.categoryList) {
      for (var product in category.codelist) {
        if (product.barcode == detail.barcode) {
          for (var ele in product.names) {
            itemnames.add(TransNameInfoModel(
                code: ele.code,
                name: ele.name,
                isauto: false,
                isdelete: false));
          }
          unitCode = product.unitcode;
          for (var ele in product.unitnames) {
            unitNames.add(TransNameInfoModel(
                code: ele.code,
                name: ele.name,
                isauto: false,
                isdelete: false));
          }
        }
      }
    }

    String optionSelected = detail.optionselected;
    String refGuidCode = const Uuid().v4();
    double sumamountchoice = 0;

    List<TransOptionsModel> transOptions = [];
    if (optionSelected.isNotEmpty) {
      detail.refguid = refGuidCode;
      List<ProductProcessOptionModel> optionList =
          (jsonDecode(optionSelected) as List)
              .map((e) => ProductProcessOptionModel.fromJson(e))
              .toList();
      for (var option in optionList) {
        for (var choice in option.choices) {
          if (choice.selected) {
            String refBarcodex =
                (choice.refbarcode.isNotEmpty) ? choice.refbarcode : "";
            if (choice.priceValue == 0) {
              if (choice.qty == 0) {
                choice.qty = 1;
              }

              TransOptionsModel optionModel = TransOptionsModel(
                barcode: refBarcodex,
                qty: detail.qty,
                price: choice.priceValue,
                item_code: refBarcodex,
                item_name: jsonEncode(choice.names),
                unit_code: "",
                unit_name: "",
                total_amount: choice.priceValue * detail.qty,
                is_except_vat: false,
                vat_type: vatType,
                price_exclude_vat: choice.priceValue,
              );
              sumamountchoice += (choice.priceValue * detail.qty);
              transOptions.add(optionModel);
            }
          }
        }
      }
    }

    double priceExcludeVat = 0;
    if (!detail.is_except_vat) {
      if (vatType == 0) {
        priceExcludeVat =
            ((detail.price + (sumamountchoice / detail.qty)) * 100) /
                (100 + vatRate);
      } else {
        priceExcludeVat = detail.price + (sumamountchoice / detail.qty);
      }
    } else {
      priceExcludeVat = detail.price + (sumamountchoice / detail.qty);
    }

    details.add(TransDetailModel(
        refguid: refGuidCode,
        averagecost: 0,
        barcode: detail.barcode,
        calcflag: -1,
        discount: detail.discountamount.toString(),
        discountamount: detail.discountamount ?? 0,
        standvalue: 1,
        dividevalue: 1,
        docdatetime: dateNow.toUtc().toIso8601String(),
        docref: "",
        docrefdatetime: null,
        inquirytype: 1,
        ispos: 1,
        itemcode: detail.barcode,
        itemguid: "",
        itemnames: itemnames,
        itemtype: 0,
        laststatus: 0,
        linenumber: linenumber,
        locationcode: "",
        locationnames: [],
        multiunit: false,
        price: detail.price + (detail.discountamount ?? 0),
        priceexcludevat: priceExcludeVat,
        qty: detail.qty,
        remark: "",
        shelfcode: "",
        sumamount: (detail.price * detail.qty),
        sumamountexcludevat: priceExcludeVat * detail.qty,
        sumamountchoice: sumamountchoice,
        sumofcost: 0,
        taxtype: vatType,
        tolocationcode: "",
        tolocationnames: [],
        totalqty: detail.qty,
        totalvaluevat: ((detail.price * detail.qty) + sumamountchoice) -
            (priceExcludeVat * detail.qty),
        towhcode: "",
        towhnames: [],
        unitcode: unitCode,
        unitnames: unitNames,
        vatcal: (detail.is_except_vat) ? 1 : 0,
        vattype: vatType,
        whcode: "",
        whnames: [],
        sku: "",
        extrajson: (transOptions.isNotEmpty) ? jsonEncode(transOptions) : "",
        manufacturerguid: detail.manufacturerguid));

    if (optionSelected.isNotEmpty) {
      detail.refguid = refGuidCode;
      List<ProductProcessOptionModel> optionList =
          (jsonDecode(optionSelected) as List)
              .map((e) => ProductProcessOptionModel.fromJson(e))
              .toList();
      for (var option in optionList) {
        for (var choice in option.choices) {
          if (choice.selected) {
            String refBarcodex =
                (choice.refbarcode.isNotEmpty) ? choice.refbarcode : "";

            if (choice.priceValue > 0) {
              List<TransNameInfoModel> choiceItemnames = [];
              for (var ele in choice.names) {
                choiceItemnames.add(TransNameInfoModel(
                    code: ele.code,
                    name: ele.name,
                    isauto: ele.isauto,
                    isdelete: ele.isdelete));
              }
              List<TransNameInfoModel> choiceUnitnames = [];
              for (var ele in choice.refunitnames) {
                choiceUnitnames.add(TransNameInfoModel(
                    code: ele.code,
                    name: ele.name,
                    isauto: ele.isauto,
                    isdelete: ele.isdelete));
              }
              double priceChoiceExcludeVat = 0;
              if (!detail.is_except_vat) {
                if (vatType == 0) {
                  priceChoiceExcludeVat =
                      (choice.priceValue * 100) / (100 + vatRate);
                } else {
                  priceChoiceExcludeVat = choice.priceValue;
                }
              } else {
                priceChoiceExcludeVat = choice.priceValue;
              }

              details.add(TransDetailModel(
                  refguid: refGuidCode,
                  ischoice: 1,
                  averagecost: 0,
                  barcode: refBarcodex,
                  calcflag: -1,
                  discount: "",
                  discountamount: 0,
                  standvalue: 1,
                  dividevalue: 1,
                  docdatetime: dateNow.toUtc().toIso8601String(),
                  docref: "",
                  docrefdatetime: null,
                  inquirytype: 1,
                  ispos: 1,
                  itemcode: refBarcodex,
                  itemguid: "",
                  itemnames: choiceItemnames,
                  itemtype: 0,
                  laststatus: 0,
                  linenumber: linenumber,
                  locationcode: "",
                  locationnames: [],
                  multiunit: false,
                  price: choice.priceValue,
                  priceexcludevat: priceChoiceExcludeVat,
                  qty: detail.qty,
                  remark: "",
                  shelfcode: "",
                  sumamount: choice.priceValue * detail.qty,
                  sumamountexcludevat: priceChoiceExcludeVat * detail.qty,
                  sumofcost: 0,
                  taxtype: vatType,
                  tolocationcode: "",
                  tolocationnames: [],
                  totalqty: detail.qty,
                  totalvaluevat: (choice.priceValue * detail.qty) -
                      (priceChoiceExcludeVat * detail.qty),
                  towhcode: "",
                  towhnames: [],
                  unitcode: choice.refunitcode,
                  unitnames: choiceUnitnames,
                  vatcal: choice.vatcal,
                  vattype: vatType,
                  whcode: "",
                  whnames: [],
                  sku: "",
                  extrajson: "",
                  manufacturerguid: detail.manufacturerguid));

              total_qty += detail.qty;
              linenumber++;
            }
          }
        }
      }
    }

    total_qty += detail.qty;
    linenumber++;
  }

  PosConfigBranchModel branchModel =
      PosConfigBranchModel(code: branchCode, names: branchNames);
  int transVatType = 0;
  if (!isVatRegister) {
    transVatType = 3;
  } else if (isVatRegister && vatType == 0) {
    transVatType = 1;
  } else if (isVatRegister && vatType == 1) {
    transVatType = 0;
  }

  final idempotencyRemark =
      localBillId.isNotEmpty ? ' KIOSK_LOCAL_BILL_ID=$localBillId' : '';
  TransactionModel trans = TransactionModel(
    cashiercode: orderStationCode,
    custcode: memberCode,
    custnames: custNames,
    description: "ORDERSTATION$idempotencyRemark",
    discountword: "",
    branch: branchModel,
    docdatetime: dateNow.toUtc().toIso8601String(),
    docno: orderDocNumber,
    docrefdate: dateNow.toUtc().toIso8601String(),
    docrefno: "",
    docreftype: 0,
    doctype: 0,
    guidref: localBillId,
    inquirytype: 1,
    iscancel: false,
    ismanualamount: false,
    ispos: true,
    posid: orderStationCode,
    membercode: memberCode,
    salecode: '',
    salename: '',
    status: 0,
    taxdocdate: dateNow.toUtc().toIso8601String(),
    taxdocno: orderDocNumber,
    totalaftervat: double.parse(amountAfterCalcVat.toStringAsFixed(2)),
    totalamount: totalAmount,
    totalbeforevat: double.parse(amountBeforeCalcVat.toStringAsFixed(2)),
    totalcost: 0,
    totaldiscount: 0,
    totalexceptvat: double.parse(amountExceptVat.toStringAsFixed(2)),
    totalvalue:
        double.parse(detailTotalAmountBeforeDiscount.toStringAsFixed(2)),
    totalvatvalue: double.parse(totalVatAmount.toStringAsFixed(2)),
    transflag: 0,
    vatrate: vatRate,
    vattype: transVatType,
    details: details,
    paycashamount: (payCashIndex != -1)
        ? payCondition[payCashIndex].payAmount -
            payCondition[payCashIndex].changeAmount
        : 0,
    paymentdetail: TransPaymentDetailModel(
        cashamount: 0,
        cashamounttext: "",
        paymentcreditcards: [],
        paymenttransfers: []),
    paymentdetailraw: jsonEncode(pays),
    billtaxtype: 0,
    buffetcode: "",
    detaildiscountformula: discountWord,
    detailtotalamount: totalAmountAfterDiscount,
    detailtotalamountbeforediscount: 0,
    detailtotaldiscount: double.parse(totalDiscount.toStringAsFixed(2)),
    isvatregister: (vatRate != 0) ? true : false,
    paycashchange: (payCashIndex != -1)
        ? double.parse(
            payCondition[payCashIndex].changeAmount.toStringAsFixed(2))
        : 0,
    roundamount: double.parse(roundAmount.toStringAsFixed(2)),
    sumcheque: 0,
    sumcoupon: 0,
    sumcreditcard: double.parse(sumCreditCard.toStringAsFixed(2)),
    summoneytransfer: 0,
    sumqrcode: double.parse(sumQrCode.toStringAsFixed(2)),
    sumcredit: 0,
    totalamountafterdiscount: totalAmountAfterDiscount,
    totaldiscountexceptvatamount: totalDiscountExceptVatAmount,
    totaldiscountvatamount: totalDiscountVatAmount,
    totalqty: total_qty,
    takeaway: (globalOrderType == 1) ? 1 : 0,
    salechannelcode: saleChannelCode,
    salechannelgp: saleChannelgp,
    isdelivery: saleChannelCode.trim().isNotEmpty,
    deliveryamount: (saleChannelCode.trim().isEmpty) ? 0 : totalAmount,
    salechannelgptype: saleChannelgptype, // ข้อมูลแต้มสะสม
    usepoint: usePoint,
    getpoint: getPoint,
    pointdiscountamount: pointDiscountAmount,
    paypointamount: pointAmount,
    currentpointbalance: currentPointBalance,
    pointscode: memberPointsCode,
    memberguidfixed: memberGuidFixed,
  );

  if (localBillId.isNotEmpty) {
    BillLedgerService().updatePayload(
      localBillId: localBillId,
      payload: trans.toJson(),
    );
  }

  if (prepareLedgerPayloadOnly) {
    Logger.i(
        'Bill ledger full saveTransaction payload prepared for $orderDocNumber',
        tag: 'BillLedger');
    return;
  }

  if (localBillId.isNotEmpty) {
    BillLedgerService().markSyncing(localBillId);
  }

  // Save transaction with retry and offline fallback
  bool transactionSaved = false;
  int retryCount = 0;
  const int maxRetries = 3;
  const Duration timeoutDuration = Duration(seconds: 15);

  Logger.i(
      '🔵 _saveTransactionBackground: START for order $orderDocNumber, orderId: $orderId',
      tag: 'SaveTransaction');

  Future<bool> verifySavedBeforeRetry(String reason) async {
    final found = await _serverHasSavedTransaction(
      localBillId: localBillId,
      orderDocNumber: orderDocNumber,
      totalAmount: totalAmount,
    );
    if (!found) return false;
    transactionSaved = true;
    Logger.w(
        'saveTransaction result was uncertain ($reason), but server already has bill $orderDocNumber. Stop retry to prevent duplicate.',
        tag: 'SaveTransaction');
    BillLedgerService().markSyncSuccess(
      localBillId: localBillId,
      serverDocNo: orderDocNumber,
    );
    if (isBCMember && memberPinCode.isNotEmpty) {
      try {
        final saleInvoiceResult = await api.sendBCMemberSaleInvoice(
          lineUid: memberPinCode,
          docNo: orderDocNumber,
          amount: totalAmount,
          usePoint: usePoint,
          displayName: bcMemberName,
          pictureUrl: bcMemberPicture,
        );
        Logger.i(
            'BC Member sale invoice after server verification: $saleInvoiceResult',
            tag: 'BCMember');
      } catch (bcError) {
        Logger.e('BC Member sale invoice after server verification failed',
            error: bcError, tag: 'BCMember');
      }
    }
    try {
      final renamed = await PrinterClass.renameSlipFile(orderDocNumber);
      if (renamed) {
        Logger.i('Slip file renamed after server verification',
            tag: 'SlipRename');
      }
    } catch (renameError) {
      Logger.e('Failed to rename slip file after server verification',
          error: renameError, tag: 'SlipRename');
    }
    try {
      await PrinterClass.renameQrProofFile(orderId, orderDocNumber);
    } catch (qrRenameError) {
      Logger.e('Failed to rename QR proof file after server verification',
          error: qrRenameError, tag: 'QrProofRename');
    }
    return true;
  }

  while (!transactionSaved && retryCount < maxRetries) {
    try {
      Logger.d(
          '🔵 Calling api.saveTransaction attempt ${retryCount + 1}/$maxRetries',
          tag: 'SaveTransaction');
      final apiResult = await api.saveTransaction(trans).timeout(
        timeoutDuration,
        onTimeout: () {
          throw TimeoutException(
              'Save transaction timeout after ${timeoutDuration.inSeconds} seconds');
        },
      );
      if (apiResult.success) {
        transactionSaved = true;
        Logger.d(
            'Background transaction saved successfully on attempt ${retryCount + 1}');
        BillLedgerService().markSyncSuccess(
          localBillId: localBillId,
          serverDocNo: orderDocNumber,
        );

        // ✅ BC Member: ส่ง Sale Invoice หลังจาก saveTransaction สำเร็จ
        if (isBCMember && memberPinCode.isNotEmpty) {
          try {
            Logger.i(
                '🔵 BC Member: Sending sale invoice for docNo=$orderDocNumber, lineUid=$memberPinCode, amount=$totalAmount',
                tag: 'BCMember');
            final saleInvoiceResult = await api.sendBCMemberSaleInvoice(
              lineUid: memberPinCode,
              docNo: orderDocNumber,
              amount: totalAmount,
              usePoint: usePoint,
              displayName: bcMemberName,
              pictureUrl: bcMemberPicture,
            );
            if (saleInvoiceResult['success'] == true) {
              Logger.i(
                  '✅ BC Member sale invoice sent successfully: $saleInvoiceResult',
                  tag: 'BCMember');
            } else {
              Logger.w(
                  '⚠️ BC Member sale invoice failed: ${saleInvoiceResult['message']}',
                  tag: 'BCMember');
            }
          } catch (bcError) {
            Logger.e('❌ BC Member sale invoice error',
                error: bcError, tag: 'BCMember');
            // ไม่ต้อง throw error เพราะ transaction บันทึกสำเร็จแล้ว
          }
        }

        // ✅ FIX: Rename slip file จาก PENDING_ หลังจาก saveTransaction สำเร็จ
        // เพื่อให้ uploadSlipWorker สามารถ upload ได้
        try {
          final renamed = await PrinterClass.renameSlipFile(orderDocNumber);
          if (renamed) {
            Logger.i('✅ Slip file renamed successfully after transaction saved',
                tag: 'SlipRename');
          } else {
            Logger.w('⚠️ No slip file to rename for order: $orderDocNumber',
                tag: 'SlipRename');
          }
        } catch (renameError) {
          Logger.e('❌ Failed to rename slip file',
              error: renameError, tag: 'SlipRename');
          // ไม่ต้อง throw error เพราะ transaction บันทึกสำเร็จแล้ว
        }

        // ✅ Rename QR payment proof file จาก PENDING_QR_{orderId}_ เป็น {orderDocNumber}_{timestamp}.jpg
        // เพื่อให้ uploadQrPaymentProofWorker สามารถ upload ด้วย docNo ที่ถูกต้อง (เลข invoice)
        // ⚠️ ใช้ orderId และ orderDocNumber จาก parameter ไม่ใช่ global เพราะ global อาจถูก reset แล้ว
        try {
          final qrProofRenamed =
              await PrinterClass.renameQrProofFile(orderId, orderDocNumber);
          if (qrProofRenamed) {
            Logger.i(
                '✅ QR proof file renamed successfully: orderId=$orderId → docNo=$orderDocNumber',
                tag: 'QrProofRename');
          }
          // ไม่ต้อง log warning ถ้าไม่มีไฟล์ เพราะอาจไม่ได้ใช้ isslipsave
        } catch (qrRenameError) {
          Logger.e('❌ Failed to rename QR proof file for orderId: $orderId',
              error: qrRenameError, tag: 'QrProofRename');
          // ไม่ต้อง throw error เพราะ transaction บันทึกสำเร็จแล้ว
        }
      } else {
        Logger.w(
            'Background transaction save failed on attempt ${retryCount + 1}: ${apiResult.message}');
        if (await verifySavedBeforeRetry(
            'api failure: ${apiResult.message ?? ''}')) {
          break;
        }
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount));
        }
      }
    } on TimeoutException catch (e) {
      Logger.w(
          'Background transaction save timeout on attempt ${retryCount + 1}: $e');
      if (await verifySavedBeforeRetry('timeout')) {
        break;
      }
      retryCount++;
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount));
      }
    } on SocketException catch (e) {
      Logger.w('Background network error on attempt ${retryCount + 1}: $e');
      if (await verifySavedBeforeRetry('network error')) {
        break;
      }
      retryCount++;
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount));
      }
    } catch (e) {
      Logger.w(
          'Background transaction save error on attempt ${retryCount + 1}: $e');
      if (await verifySavedBeforeRetry('error: $e')) {
        break;
      }
      retryCount++;
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
  }
  // Keep failed saves in BillLedger; BillLedgerSyncService is the only retry queue.
  if (!transactionSaved) {
    BillLedgerService().markSyncFailed(
      localBillId: localBillId,
      error:
          'saveTransaction failed after $maxRetries attempts; kept in BillLedger for background sync',
    );
    Logger.w(
      'saveTransaction failed after $maxRetries attempts; BillLedger will retry - DocNo: ${trans.docno}, localBillId=$localBillId',
      tag: 'BillLedger',
    );
  }

  // Handle systemCondition == 1 (pay later mode) - copy data to ordertempdoc
  if (transactionSaved && systemCondition == 1) {
    const Duration clickHouseTimeout = Duration(seconds: 10);
    try {
      String queryInsert =
          "insert into ${global.clickHouseDatabaseName}.ordertempdoc (shopid, branchid, orderid, ordernumber, orderdatetime, phonenumber, tablenumber, queuenumber, ordertype, istakeaway, detailsuccess, isclose, ordertagnumber, paycondition, totalamount, vatamount, discountword, discountamount, diffamount, saveamount, beforvat, vatrate, exceptvat, aftervat, salechannelcode, kitchensuccess, orderpaysuccess, copyprintsuccess) values ('$shopId', '$branchId', '$orderId', '$orderDocNumber', now(), '', '', $queueNumber, $orderType, $isTakeAway, 1, 1, '$orderTagNumber', '${jsonEncode(payCondition)}', $totalAmount, $totalVatAmount, '$discountWord', $totalDiscount, 0, 0, $amountBeforeCalcVat, $vatRate, 0, $amountAfterCalcVat, '$saleChannelCode', 1, 1, 0)";
      await api.clickHouseExecute(queryInsert).timeout(clickHouseTimeout);
    } catch (e) {
      Logger.w('Background ClickHouse copy doc error: $e');
    }
    try {
      String query =
          "INSERT INTO ${global.clickHouseDatabaseName}.ordertemp (shopid, orderid, orderguid, machineid, orderdatetime, barcode, qty, price, amount, isclose, isserved, istakeaway, optionselected, remark, istype, queuenumber, ordernumber, branchid, isprintkitchensuccess, ordertagnumber, tablenumber, orderbarcode, optionamount, discountamount, salechannelcode, linenumber, qtycancel, amountcancel, iscooked, iscookcancel, isservedcancel, paysuccess, orderpaysuccess) SELECT shopid, orderid, orderguid, machineid, orderdatetime, barcode, qty, price, amount, 2 as isclose, isserved, istakeaway, optionselected, remark, istype, queuenumber, '$orderDocNumber' as ordernumber, branchid, isprintkitchensuccess, ordertagnumber, tablenumber, orderbarcode, optionamount, discountamount, salechannelcode, linenumber, qtycancel, amountcancel, iscooked, iscookcancel, isservedcancel, paysuccess, 1 as orderpaysuccess FROM ${global.clickHouseDatabaseName}.ordertemppaylater WHERE shopid='$shopId' and branchid='$branchId' and ordertagnumber='$tableNumberSelectedOrdertagnumber'";
      await api.clickHouseExecute(query).timeout(clickHouseTimeout);
    } catch (e) {
      Logger.w('Background ClickHouse copy detail error: $e');
    }
    try {
      String query =
          "alter table ${global.clickHouseDatabaseName}.ordertempdocpaylater delete where shopid='$shopId' and branchid='$branchId' and ordertagnumber='$tableNumberSelectedOrdertagnumber' and orderpaysuccess=0";
      await api.clickHouseExecute(query).timeout(clickHouseTimeout);
    } catch (e) {
      Logger.w('Background ClickHouse delete doc error: $e');
    }
    try {
      String query =
          "alter table ${global.clickHouseDatabaseName}.ordertemppaylater delete where shopid='$shopId' and branchid='$branchId' and ordertagnumber='$tableNumberSelectedOrdertagnumber' and orderpaysuccess=0";
      await api.clickHouseExecute(query).timeout(clickHouseTimeout);
    } catch (e) {
      Logger.w('Background ClickHouse delete detail error: $e');
    }
  }
}
