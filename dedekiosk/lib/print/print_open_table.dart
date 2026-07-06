import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/print/print.dart' as pos_print;
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/logger.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:intl/intl.dart';

/// พิมพ์ใบเปิดโต๊ะ Order Online
/// แสดง: ชื่อร้าน, "ORDER ONLINE", เลขโต๊ะ, วันที่-เวลา, QR Code (uuid url)
Future<void> printOpenTable({
  required String tableNumber,
  required DateTime openDateTime,
  required String qrUrl,
  required PrinterLocalConfigModel printerConfig,
}) async {
  if (global.shopProfile == null) {
    throw Exception('printOpenTable: shopProfile is null');
  }

  // ✅ ตรวจสอบ printer config ก่อนพิมพ์
  final connectType = global.printerConnectToEnum(printerConfig.printerConnectType);
  bool isPrinterConfigValid = false;

  switch (connectType) {
    case global.PrinterConnectEnum.ip:
      isPrinterConfigValid = printerConfig.ipAddress.isNotEmpty && printerConfig.ipPort > 0;
      if (!isPrinterConfigValid) {
        Logger.e('❌ printOpenTable: Printer IP not configured - ipAddress="${printerConfig.ipAddress}", ipPort=${printerConfig.ipPort}', tag: 'PrintOpenTable');
      }
      break;
    case global.PrinterConnectEnum.usb:
      isPrinterConfigValid = printerConfig.vendorId.isNotEmpty || printerConfig.productId.isNotEmpty || printerConfig.code.isNotEmpty || printerConfig.deviceId.isNotEmpty;
      if (!isPrinterConfigValid) {
        Logger.e('❌ printOpenTable: Printer USB not configured - vendorId="${printerConfig.vendorId}", productId="${printerConfig.productId}"', tag: 'PrintOpenTable');
      }
      break;
    case global.PrinterConnectEnum.bluetooth:
    case global.PrinterConnectEnum.windows:
      // ยังไม่รองรับ bluetooth/windows สำหรับ printOpenTable
      Logger.w('⚠️ printOpenTable: Printer connect type ${connectType.name} not supported yet', tag: 'PrintOpenTable');
      break;
  }

  if (!isPrinterConfigValid) {
    throw Exception('printOpenTable: Printer not configured (connectType=${connectType.name}, ipAddress="${printerConfig.ipAddress}", ipPort=${printerConfig.ipPort})');
  }

  Logger.i('🖨️ printOpenTable: Starting print for table $tableNumber, printer: ${printerConfig.ipAddress}:${printerConfig.ipPort}', tag: 'PrintOpenTable');

  final double fontSizeScale = (printerConfig.paperType == 2) ? 1.0 : 0.75;

  // QR code วาดอัตโนมัติผ่าน PrinterClass.qrCode
  pos_print.PrinterClass printerData = pos_print.PrinterClass(
    printerIndex: 1,
    qrCode: qrUrl,
    openCashDrawer: false,
  );

  // Reset
  printerData.addCommand(pos_print.PosPrintBillCommandModel(mode: 0));

  // สแกนเพื่อสั่งอาหาร
  printerData.addCommand(pos_print.PosPrintBillCommandModel(
    mode: 2,
    posStyles: const PosStyles(bold: true),
    columns: [
      pos_print.PosPrintBillCommandColumnModel(
        fontSize: 26 * fontSizeScale,
        width: 1,
        text: "สแกนเพื่อสั่งอาหาร",
        align: global.PrintColumnAlign.center,
      ),
    ],
  ));

  // ชื่อร้าน
  final branchName = (global.shopProfile!.orderstation.branch.names?.isNotEmpty == true) ? global.shopProfile!.orderstation.branch.names![0].name : "";
  if (branchName.isNotEmpty) {
    printerData.addCommand(pos_print.PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        pos_print.PosPrintBillCommandColumnModel(
          fontSize: 26 * fontSizeScale,
          width: 1,
          text: branchName,
          align: global.PrintColumnAlign.center,
        ),
      ],
    ));
  }

  // เส้นคั่น
  printerData.addCommand(pos_print.PosPrintBillCommandModel(mode: 3));

  // หัวข้อ ORDER ONLINE
  printerData.addCommand(pos_print.PosPrintBillCommandModel(
    mode: 2,
    posStyles: const PosStyles(bold: true),
    columns: [
      pos_print.PosPrintBillCommandColumnModel(
        fontSize: 34 * fontSizeScale,
        width: 1,
        text: "*** ORDER ONLINE ***",
        align: global.PrintColumnAlign.center,
      ),
    ],
  ));

  // เว้นบรรทัด
  printerData.addCommand(pos_print.PosPrintBillCommandModel(mode: 4, value: 10));

  // เลขโต๊ะ
  printerData.addCommand(pos_print.PosPrintBillCommandModel(
    mode: 2,
    posStyles: const PosStyles(bold: true),
    columns: [
      pos_print.PosPrintBillCommandColumnModel(
        fontSize: 44 * fontSizeScale,
        width: 1,
        text: "โต๊ะ : $tableNumber",
        align: global.PrintColumnAlign.center,
      ),
    ],
  ));

  // วันที่ และเวลา
  final dateStr = DateFormat("dd/MM/yyyy").format(openDateTime);
  final timeStr = DateFormat("HH:mm:ss").format(openDateTime);
  printerData.addCommand(pos_print.PosPrintBillCommandModel(
    mode: 2,
    posStyles: const PosStyles(bold: false),
    columns: [
      pos_print.PosPrintBillCommandColumnModel(
        fontSize: 22 * fontSizeScale,
        width: 1,
        text: "วันที่ $dateStr  เวลา $timeStr",
        align: global.PrintColumnAlign.center,
      ),
    ],
  ));

  // เส้นคั่น
  printerData.addCommand(pos_print.PosPrintBillCommandModel(mode: 3));

  // คำอธิบาย QR
  printerData.addCommand(pos_print.PosPrintBillCommandModel(
    mode: 2,
    posStyles: const PosStyles(bold: false),
    columns: [
      pos_print.PosPrintBillCommandColumnModel(
        fontSize: 22 * fontSizeScale,
        width: 1,
        text: "สแกน QR เพื่อสั่งอาหารออนไลน์",
        align: global.PrintColumnAlign.center,
      ),
    ],
  ));

  // เว้นท้าย
  printerData.addCommand(pos_print.PosPrintBillCommandModel(mode: 4, value: 16));

  await printerData.sendToPrinter(
    printerData: printerConfig,
    saveToFile: false,
    printLogo: false,
    docNumber: "OPEN_TABLE_${tableNumber}_${openDateTime.millisecondsSinceEpoch}",
  );

  // ถ้าสร้างภาพไม่ได้ ให้ throw เพื่อให้ printQueueWorker retry ได้
  if (printerData.imageBytes.isEmpty) {
    Logger.e('❌ printOpenTable: Failed to render print image (imageBytes empty)', tag: 'PrintOpenTable');
    throw Exception('printOpenTable: failed to render print image (imageBytes empty)');
  }

  Logger.i('✅ printOpenTable: Successfully printed open table slip for table $tableNumber', tag: 'PrintOpenTable');
}
