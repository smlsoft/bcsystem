import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/print/print.dart' as pos_print;
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/logger.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:intl/intl.dart';

/// พิมพ์ใบแจ้งยอดสำหรับไปจ่ายที่ Cashier
/// แสดง: ชื่อร้าน, "ชำระที่ Cashier", doc no, เลขโต๊ะ, ยอดรวม, วันที่-เวลา, QR Code (JSON payload)
///
/// QR payload format:
///   {"shopid":"...","docno":"001-250705-0001","table":"5","amount":450.00,"v":"1"}
Future<void> printCashierSlip({
  required String docNo,
  required String tableNumber,
  required double totalAmount,
  required String qrPayload,
  required DateTime docDateTime,
  required PrinterLocalConfigModel printerConfig,
}) async {
  if (global.shopProfile == null) {
    throw Exception('printCashierSlip: shopProfile is null');
  }

  // ตรวจสอบ printer config ก่อนพิมพ์ (เหมือน printOpenTable)
  final connectType =
      global.printerConnectToEnum(printerConfig.printerConnectType);
  bool isPrinterConfigValid = false;

  switch (connectType) {
    case global.PrinterConnectEnum.ip:
      isPrinterConfigValid =
          printerConfig.ipAddress.isNotEmpty && printerConfig.ipPort > 0;
      if (!isPrinterConfigValid) {
        Logger.e(
            '❌ printCashierSlip: Printer IP not configured - ipAddress="${printerConfig.ipAddress}", ipPort=${printerConfig.ipPort}',
            tag: 'PrintCashierSlip');
      }
      break;
    case global.PrinterConnectEnum.usb:
      isPrinterConfigValid = printerConfig.vendorId.isNotEmpty ||
          printerConfig.productId.isNotEmpty ||
          printerConfig.code.isNotEmpty ||
          printerConfig.deviceId.isNotEmpty;
      if (!isPrinterConfigValid) {
        Logger.e(
            '❌ printCashierSlip: Printer USB not configured - vendorId="${printerConfig.vendorId}", productId="${printerConfig.productId}"',
            tag: 'PrintCashierSlip');
      }
      break;
    case global.PrinterConnectEnum.bluetooth:
    case global.PrinterConnectEnum.windows:
      Logger.w(
          '⚠️ printCashierSlip: Printer connect type ${connectType.name} not supported yet',
          tag: 'PrintCashierSlip');
      break;
  }

  if (!isPrinterConfigValid) {
    throw Exception(
        'printCashierSlip: Printer not configured (connectType=${connectType.name}, ipAddress="${printerConfig.ipAddress}", ipPort=${printerConfig.ipPort})');
  }

  Logger.i(
      '🖨️ printCashierSlip: Starting print for docNo $docNo, printer: ${printerConfig.ipAddress}:${printerConfig.ipPort}',
      tag: 'PrintCashierSlip');

  final double fontSizeScale = (printerConfig.paperType == 2) ? 1.0 : 0.75;

  // QR code ที่ encode JSON payload
  pos_print.PrinterClass printerData = pos_print.PrinterClass(
    printerIndex: 1,
    qrCode: qrPayload,
    openCashDrawer: false,
  );

  // Reset
  printerData.addCommand(pos_print.PosPrintBillCommandModel(mode: 0));

  // หัวข้อ "ใบแจ้งยอดชำระ"
  printerData.addCommand(pos_print.PosPrintBillCommandModel(
    mode: 2,
    posStyles: const PosStyles(bold: true),
    columns: [
      pos_print.PosPrintBillCommandColumnModel(
        fontSize: 26 * fontSizeScale,
        width: 1,
        text: "ใบแจ้งยอดชำระ",
        align: global.PrintColumnAlign.center,
      ),
    ],
  ));

  // ชื่อร้าน
  final branchName =
      (global.shopProfile!.orderstation.branch.names?.isNotEmpty == true)
          ? global.shopProfile!.orderstation.branch.names![0].name
          : "";
  if (branchName.isNotEmpty) {
    printerData.addCommand(pos_print.PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        pos_print.PosPrintBillCommandColumnModel(
          fontSize: 22 * fontSizeScale,
          width: 1,
          text: branchName,
          align: global.PrintColumnAlign.center,
        ),
      ],
    ));
  }

  // เส้นคั่น
  printerData.addCommand(pos_print.PosPrintBillCommandModel(mode: 3));

  // "ชำระที่ Cashier"
  printerData.addCommand(pos_print.PosPrintBillCommandModel(
    mode: 2,
    posStyles: const PosStyles(bold: true),
    columns: [
      pos_print.PosPrintBillCommandColumnModel(
        fontSize: 30 * fontSizeScale,
        width: 1,
        text: "** ชำระที่ CASHIER **",
        align: global.PrintColumnAlign.center,
      ),
    ],
  ));

  printerData.addCommand(pos_print.PosPrintBillCommandModel(mode: 4, value: 6));

  // รหัสอ้างอิง (stubId — ใช้สำหรับสแกน QR ที่ cashier; แสดงแค่ 8 ตัวท้ายเพื่อประหยัด paper)
  final shortRef = docNo.length > 12
      ? docNo.substring(docNo.length - 8).toUpperCase()
      : docNo;
  printerData.addCommand(pos_print.PosPrintBillCommandModel(
    mode: 2,
    posStyles: const PosStyles(bold: false),
    columns: [
      pos_print.PosPrintBillCommandColumnModel(
        fontSize: 20 * fontSizeScale,
        width: 1,
        text: "รหัสอ้างอิง: $shortRef",
        align: global.PrintColumnAlign.left,
      ),
    ],
  ));

  // เลขโต๊ะ (ถ้ามี)
  if (tableNumber.isNotEmpty) {
    printerData.addCommand(pos_print.PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        pos_print.PosPrintBillCommandColumnModel(
          fontSize: 20 * fontSizeScale,
          width: 1,
          text: "โต๊ะ/ป้าย: $tableNumber",
          align: global.PrintColumnAlign.left,
        ),
      ],
    ));
  }

  // วันที่ และเวลา
  final dateStr = DateFormat("dd/MM/yyyy").format(docDateTime);
  final timeStr = DateFormat("HH:mm:ss").format(docDateTime);
  printerData.addCommand(pos_print.PosPrintBillCommandModel(
    mode: 2,
    posStyles: const PosStyles(bold: false),
    columns: [
      pos_print.PosPrintBillCommandColumnModel(
        fontSize: 20 * fontSizeScale,
        width: 1,
        text: "วันที่ $dateStr  เวลา $timeStr",
        align: global.PrintColumnAlign.left,
      ),
    ],
  ));

  // เส้นคั่น
  printerData.addCommand(pos_print.PosPrintBillCommandModel(mode: 3));

  // ยอดรวม (เด่น)
  printerData.addCommand(pos_print.PosPrintBillCommandModel(
    mode: 2,
    posStyles: const PosStyles(bold: true),
    columns: [
      pos_print.PosPrintBillCommandColumnModel(
        fontSize: 36 * fontSizeScale,
        width: 1,
        text: "ยอดชำระ: ${global.moneyFormat.format(totalAmount)} บาท",
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
        fontSize: 20 * fontSizeScale,
        width: 1,
        text: "นำใบนี้ไปชำระที่ Cashier",
        align: global.PrintColumnAlign.center,
      ),
    ],
  ));

  printerData.addCommand(pos_print.PosPrintBillCommandModel(
    mode: 2,
    posStyles: const PosStyles(bold: false),
    columns: [
      pos_print.PosPrintBillCommandColumnModel(
        fontSize: 20 * fontSizeScale,
        width: 1,
        text: "(Cashier สแกน QR เพื่อรับชำระ)",
        align: global.PrintColumnAlign.center,
      ),
    ],
  ));

  // เว้นท้าย
  printerData
      .addCommand(pos_print.PosPrintBillCommandModel(mode: 4, value: 16));

  await printerData.sendToPrinter(
    printerData: printerConfig,
    saveToFile: false,
    printLogo: false,
    docNumber: "CASHIER_$docNo",
  );

  if (printerData.imageBytes.isEmpty) {
    Logger.e(
        '❌ printCashierSlip: Failed to render print image (imageBytes empty)',
        tag: 'PrintCashierSlip');
    throw Exception(
        'printCashierSlip: failed to render print image (imageBytes empty)');
  }

  Logger.i(
      '✅ printCashierSlip: Successfully printed cashier slip for docNo $docNo',
      tag: 'PrintCashierSlip');
}
