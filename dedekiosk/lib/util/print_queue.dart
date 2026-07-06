import 'dart:async';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/order/widgets/payment_success_dialog.dart';
import 'package:dedekiosk/print/print_kitchen.dart';
import 'package:dedekiosk/print/print_open_table.dart';
import 'package:dedekiosk/print/print_cashier_slip.dart';
import 'package:dedekiosk/print/print_util.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:flutter/foundation.dart';
import 'package:dedekiosk/util/logger.dart';

class PrintTicketClass {
  final String docNumber;
  final DateTime docDate;
  final String orderId;
  final String orderTagNumber;

  /// 0=ใบสั่งอาหาร/ใบสรุป,1=พิมพ์ครัว
  final int printType;

  /// 0=กินที่ร้าน,1=กลับบ้าน
  final int orderType;
  final int queueNumber;
  final bool printLogo;
  final bool saveToFile;
  final bool printHeader;
  final bool openCashDrawer;
  final String footer;
  final List<OrderTempDetailModel> orderList;
  final PrinterLocalConfigModel printerLocalConfig;
  final String qrCode;
  final List<OrderTempDetailDataModel> orderTempDetails;
  final PayResultModel payResult;
  final String memberPinCode; // เพิ่มเพื่อส่ง receipt ไปยัง member
  final bool isBCMember; // flag สำหรับ BC Member (ใช้ API ต่างกัน)

  PrintTicketClass(
      {required this.queueNumber,
      required this.docDate,
      required this.docNumber,
      required this.orderTagNumber,
      required this.orderId,
      required this.printType,
      required this.openCashDrawer,
      required this.orderType,
      required this.footer,
      required this.saveToFile,
      required this.orderList,
      required this.printerLocalConfig,
      required this.orderTempDetails,
      required this.payResult,
      required this.printLogo,
      required this.printHeader,
      required this.qrCode,
      this.memberPinCode = "",
      this.isBCMember = false});
}

Future<void> printQueueWorker() async {
  // ตรวจสอบ Queue ที่ยังไม่ได้ปริ้น
  if (global.printQueue.isNotEmpty && global.printQueueProcessing == false) {
    global.printQueueProcessing = true;
    while (global.printQueue.isNotEmpty) {
      // ✅ ตรวจสอบว่า user กด skip หรือไม่
      if (skipPrintingRequested) {
        Logger.i('⏭️ Print skipped by user request', tag: 'PrintQueue');
        // ล้าง print queue ที่เหลือ (เฉพาะ printType 0 - ใบเสร็จ)
        global.printQueue.removeWhere((item) => item.printType == 0);
        skipPrintingRequested = false; // reset flag
        break;
      }

      PrintTicketClass printQueue = global.printQueue[0];
      bool printSuccess = false;
      int retryCount = 0;
      const int maxRetries = 10;

      while (!printSuccess && retryCount < maxRetries) {
        // ✅ ตรวจสอบ skip flag ระหว่าง retry
        if (skipPrintingRequested) {
          Logger.i('⏭️ Print skipped during retry', tag: 'PrintQueue');
          break;
        }

        try {
          switch (printQueue.printType) {
            case 0: // พิมพ์ใบสั่ง/ใบสรุป - เพิ่ม timeout 10 วินาที
              await printTicket(
                      docDate: printQueue.docDate,
                      docNumber: printQueue.docNumber,
                      orderTagNumber: printQueue.orderTagNumber,
                      queueNumber: printQueue.queueNumber,
                      header: printQueue.footer,
                      orderList: printQueue.orderList,
                      printerConfig: printQueue.printerLocalConfig,
                      payResult: printQueue.payResult,
                      printLogo: printQueue.printLogo,
                      saveToFile: printQueue.saveToFile,
                      printHeader: printQueue.printHeader,
                      openCashDrawer: printQueue.openCashDrawer,
                      qrCode: printQueue.qrCode,
                      memberPinCode: printQueue.memberPinCode,
                      isBCMember: printQueue.isBCMember)
                  .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  throw TimeoutException('Print timeout after 10 seconds');
                },
              );
              break;
            case 1:
              // พิมพ์ครัว
              await sendToKitchen(
                  orderId: printQueue.orderId,
                  orderList: printQueue.orderTempDetails);
              break;
            case 2:
              // พิมพ์ใบเปิดโต๊ะ Order Online
              Logger.i(
                  '🖨️ Processing printType=2 (Open Table): table=${printQueue.orderTagNumber}, printer=${printQueue.printerLocalConfig.ipAddress}:${printQueue.printerLocalConfig.ipPort}',
                  tag: 'PrintQueue');
              await printOpenTable(
                tableNumber: printQueue.orderTagNumber,
                openDateTime: printQueue.docDate,
                qrUrl: printQueue.qrCode,
                printerConfig: printQueue.printerLocalConfig,
              ).timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  throw TimeoutException(
                      'Open table print timeout after 10 seconds');
                },
              );
              Logger.i('✅ printType=2 (Open Table) completed successfully',
                  tag: 'PrintQueue');
              break;
            case 3:
              // พิมพ์ใบแจ้งยอดชำระที่ Cashier (พร้อม QR)
              Logger.i(
                  '🖨️ Processing printType=3 (Cashier Slip): docNo=${printQueue.docNumber}, table=${printQueue.orderTagNumber}, printer=${printQueue.printerLocalConfig.ipAddress}:${printQueue.printerLocalConfig.ipPort}',
                  tag: 'PrintQueue');
              await printCashierSlip(
                docNo: printQueue.docNumber,
                tableNumber: printQueue.orderTagNumber,
                totalAmount: printQueue.payResult.totalAmount,
                qrPayload: printQueue.qrCode,
                docDateTime: printQueue.docDate,
                printerConfig: printQueue.printerLocalConfig,
              ).timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  throw TimeoutException(
                      'Cashier slip print timeout after 10 seconds');
                },
              );
              Logger.i('✅ printType=3 (Cashier Slip) completed successfully',
                  tag: 'PrintQueue');
              break;
          }
          printSuccess = true;
        } on TimeoutException catch (e) {
          retryCount++;
          Logger.w('Print timeout attempt $retryCount/$maxRetries: $e',
              tag: 'PrintQueue');

          // ✅ เช็ค skip flag หลัง timeout
          if (skipPrintingRequested) {
            Logger.i('⏭️ Print skipped after timeout', tag: 'PrintQueue');
            break;
          }

          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: 1));
          } else {
            global.sendErrorToDevTeam(
                "พิมพ์ timeout หลัง $maxRetries ครั้ง ${printQueue.docNumber}");
          }
        } catch (e, s) {
          retryCount++;
          Logger.e('Print error attempt $retryCount/$maxRetries',
              error: e, stackTrace: s);

          if (retryCount < maxRetries) {
            // Wait before retry with progressive delay
            await Future.delayed(Duration(seconds: retryCount));
          } else {
            // All retries failed - log and continue
            global.sendErrorToDevTeam(
                "พิมพ์ไม่ได้หลัง $maxRetries ครั้ง ${printQueue.docNumber} ${printQueue.printerLocalConfig.code} ${e.toString()}");
          }
        }
      }

      // พิมพ์เสร็จ หรือ retry หมดแล้ว
      if (printQueue.printType == 1) {
        // ถ้าเป็นการพิมพ์ครัว
        global.kitchenPrintProcessingOrderIds.remove(printQueue.orderId);

        // ✅ ถ้าพิมพ์ครัวไม่สำเร็จ ให้ rollback isprintkitchensuccess=0 เพื่อให้ลองใหม่ได้
        if (!printSuccess) {
          Logger.w(
              '🔄 Kitchen print failed for orderId ${printQueue.orderId}, rollback isprintkitchensuccess=0',
              tag: 'PrintQueue');
          try {
            String tableNameOrderTemp =
                (global.deviceConfig.systemCondition == 1)
                    ? "${global.clickHouseDatabaseName}.ordertemppaylater"
                    : "${global.clickHouseDatabaseName}.ordertemp";
            await api.clickHouseExecute(
                "alter table $tableNameOrderTemp UPDATE isprintkitchensuccess=0 WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderid='${printQueue.orderId}'");
            // ลบ orderId ออกจาก kitchenPrintedOrderIds เพื่อให้ query มาพิมพ์ใหม่ได้
            global.kitchenPrintedOrderIds.remove(printQueue.orderId);
            Logger.i(
                '✅ Rollback success for orderId ${printQueue.orderId}, will retry later',
                tag: 'PrintQueue');
          } catch (rollbackError) {
            Logger.e(
                '❌ Failed to rollback isprintkitchensuccess for orderId ${printQueue.orderId}',
                error: rollbackError,
                tag: 'PrintQueue');
          }
        }
      }
      global.printQueue.removeAt(0);
    }
    global.printQueueProcessing = false;
  }
  try {
    if (global.deviceConfig.isServer &&
        global.kitchenPrintQueueProcessing == false) {
      global.kitchenPrintQueueProcessing = true;
      // ตรวจสอบพิมพ์ครัว ที่ยังไม่ได้ปริ้น เอาเข้า Queue
      String tableNameOrderTemp = (global.deviceConfig.systemCondition == 1)
          ? "${global.clickHouseDatabaseName}.ordertemppaylater"
          : "${global.clickHouseDatabaseName}.ordertemp";

      // ใช้ subquery เพื่อดึงข้อมูลล่าสุดตาม orderdatetime
      String query = """
        SELECT orderid, istakeaway 
        FROM (
          SELECT orderid, istakeaway, isprintkitchensuccess, isclose,
                 ROW_NUMBER() OVER (PARTITION BY orderid ORDER BY orderdatetime DESC) as rn
          FROM $tableNameOrderTemp 
          WHERE shopid='${global.deviceConfig.shopId}' 
            AND branchid='${global.deviceConfig.branchId}'
        ) 
        WHERE rn = 1 AND isprintkitchensuccess = 0 AND isclose = 2
        GROUP BY orderid, istakeaway
      """;
      var orderIdResponse = await api.clickHouseSelect(query).timeout(
            const Duration(seconds: 10),
            onTimeout: () => <String, dynamic>{},
          );
      if (orderIdResponse.isEmpty) {
        global.kitchenPrintQueueProcessing = false;
        return;
      }
      ResponseDataModel result = ResponseDataModel.fromJson(orderIdResponse);

      Logger.d("Kitchen print: Found ${result.data.length} orders to process");

      for (var order in result.data) {
        String orderId = order['orderid'];
        int orderType = order['istakeaway'];

        // ตรวจสอบว่า orderId นี้กำลัง process หรืออยู่ใน printQueue แล้วหรือไม่ (ป้องกันซ้ำ)
        if (global.kitchenPrintProcessingOrderIds.contains(orderId)) {
          Logger.d(
              "Kitchen print: orderId $orderId is being processed, skipping...");
          continue;
        }

        bool alreadyInQueue = global.printQueue
            .any((p) => p.orderId == orderId && p.printType == 1);
        if (alreadyInQueue) {
          Logger.d(
              "Kitchen print: orderId $orderId already in queue, skipping...");
          continue;
        }

        Logger.d("Kitchen print: Processing orderId $orderId");

        // Mark ว่ากำลัง process orderId นี้ (ป้องกัน race condition ก่อน ClickHouse mutation)
        global.kitchenPrintProcessingOrderIds.add(orderId);
        try {
          // Update ว่าพิมพ์ครัวแล้ว (isprintkitchensuccess=1) ก่อนเพิ่มเข้า Queue
          // เพื่อป้องกัน race condition ที่จะทำให้ดึงรายการซ้ำ
          await api.clickHouseExecute(
              "alter table $tableNameOrderTemp UPDATE isprintkitchensuccess=1 WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderid='$orderId' and isprintkitchensuccess=0");

          // รอให้ ClickHouse mutation เสร็จ (เพิ่มเป็น 1500ms เพื่อความมั่นใจมากขึ้น)
          // ClickHouse mutation เป็น async และอาจใช้เวลานานกว่า 500ms
          await Future.delayed(const Duration(milliseconds: 1500));

          // ใช้ subquery เพื่อดึงข้อมูลล่าสุดตาม orderdatetime (แทน FINAL)
          String queryDetail = """
            SELECT * FROM (
              SELECT *, ROW_NUMBER() OVER (PARTITION BY orderguid ORDER BY orderdatetime DESC) as rn
              FROM $tableNameOrderTemp 
              WHERE shopid='${global.deviceConfig.shopId}' 
                AND branchid='${global.deviceConfig.branchId}' 
                AND orderid='$orderId' 
                AND isclose=2
            ) 
            WHERE rn = 1 
            ORDER BY linenumber
          """;
          var orderTemp = await api.clickHouseSelect(queryDetail);
          ResponseDataModel resultDetail =
              ResponseDataModel.fromJson(orderTemp);
          if (resultDetail.data.isNotEmpty) {
            List<OrderTempDetailDataModel> orderTempDetails = [];
            for (int i = 0; i < resultDetail.data.length; i++) {
              var data = resultDetail.data[i];
              orderTempDetails.add(OrderTempDetailDataModel(
                orderId: data['orderid'],
                orderGuid: data['orderguid'],
                optionSelected: data['optionselected'],
                orderDateTime: DateTime.parse(data['orderdatetime']),
                isTakeAway: data['istakeaway'],
                salechannelcode: data['salechannelcode'],
                barcode: data['barcode'],
                remark: data['remark'],
                price: double.tryParse(data['price'].toString()) ?? 0,
                amount: double.tryParse(data['amount'].toString()) ?? 0,
                qty: double.tryParse(data['qty'].toString()) ?? 0,
                queueNumber: int.tryParse(data['queuenumber'].toString()) ?? 0,
                orderTagNumber: data['ordertagnumber'],
                tableNumber: data['tablenumber'],
              ));
            }

            // ตรวจสอบอีกครั้งก่อนเพิ่มเข้า queue (double-check)
            bool alreadyInQueueFinal = global.printQueue
                .any((p) => p.orderId == orderId && p.printType == 1);
            if (alreadyInQueueFinal) {
              Logger.w(
                  "Kitchen print: orderId $orderId already in queue after processing, skipping add...");
              global.kitchenPrintProcessingOrderIds.remove(orderId);
            } else {
              Logger.i(
                  "Kitchen print: Adding orderId $orderId to print queue (${orderTempDetails.length} items)");
              global.printQueue.add(PrintTicketClass(
                  docDate: DateTime.now(),
                  docNumber: "",
                  orderTagNumber: "",
                  orderId: orderId,
                  printType: 1,
                  queueNumber: 0,
                  printLogo: false,
                  openCashDrawer: false,
                  printHeader: false,
                  footer: "",
                  saveToFile: false,
                  orderList: [],
                  orderType: orderType,
                  orderTempDetails: orderTempDetails,
                  printerLocalConfig: global.deviceConfig.printerForOwner,
                  payResult: PayResultModel(),
                  qrCode: ""));
              // orderId จะถูกลบออกจาก Set เมื่อพิมพ์เสร็จใน printQueueWorker
            }
          } else {
            // ไม่พบรายละเอียด - Rollback: reset isprintkitchensuccess=0 เพื่อให้ลองใหม่ได้
            await api.clickHouseExecute(
                "alter table $tableNameOrderTemp UPDATE isprintkitchensuccess=0 WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderid='$orderId'");
            global.kitchenPrintProcessingOrderIds.remove(orderId);
            if (kDebugMode) {
              print(
                  "Kitchen print: orderId $orderId has no details, rollback isprintkitchensuccess=0");
            }
          }
        } catch (e, s) {
          // เกิด error ระหว่าง process - Rollback: reset isprintkitchensuccess=0 เพื่อให้ลองใหม่ได้
          try {
            await api.clickHouseExecute(
                "alter table $tableNameOrderTemp UPDATE isprintkitchensuccess=0 WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderid='$orderId'");
          } catch (_) {
            // ignore rollback error
          }
          global.kitchenPrintProcessingOrderIds.remove(orderId);
          Logger.e(
              'Kitchen print error for orderId $orderId, rollback attempted',
              error: e,
              stackTrace: s);
        }
      }
      global.kitchenPrintQueueProcessing = false;
    }
  } catch (e, s) {
    Logger.e('Error occurred', error: e, stackTrace: s);

    global.kitchenPrintQueueProcessing = false;
  }
}
