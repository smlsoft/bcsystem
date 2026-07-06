// ⚠️ DEPRECATED - ไม่ใช้แล้ว
// ปัญหา: compute() เป็น isolate ที่ไม่มี Flutter Bindings
// ทำให้ CapabilityProfile.load() error: "Binding has not yet been initialized"
//
// แก้ไขโดย: ใช้ Main Thread แทน (ดูที่ bootstrap_print_timer_manager.dart)
// วันที่เปลี่ยน: 2025-10-20
//
// ไฟล์นี้เก็บไว้เป็น reference เท่านั้น

import 'dart:io';
import 'package:dedecashier/util/printer.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter/foundation.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

/// @deprecated Top-level function สำหรับ compute() - ต้องเป็น static หรือ top-level
/// รับ printer config ผ่าน parameters เพราะไม่สามารถเข้าถึง global state ได้
Future<Map<String, dynamic>> printJobWorker(Map<String, dynamic> params) async {
  try {
    final fileName = params['fileName'] as String;
    final printerName = params['printerName'] as String;
    final filePath = params['filePath'] as String;
    final printerConfig = params['printerConfig'] as Map<String, dynamic>;

    if (kDebugMode) {
      AppLogger.debug('[PrintCompute] 🖨️ Processing: $fileName');
      AppLogger.debug('[PrintCompute]    Printer: $printerName');
      AppLogger.debug('[PrintCompute]    File: $filePath');
    }

    // เช็คว่าไฟล์มีอยู่จริง
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    // สร้าง PrinterLocalStrongDataModel จาก config
    final printer = PrinterLocalStrongDataModel(
      deviceName: printerConfig['deviceName'] as String,
      ipAddress: printerConfig['ipAddress'] as String,
      ipPort: printerConfig['ipPort'] as int,
      paperType: printerConfig['paperType'] as int,
      printerConnectType: _parsePrinterConnectType(
        printerConfig['printerConnectType'] as String,
      ),
      isConfigConnectSuccess: printerConfig['isConfigConnectSuccess'] as bool,
      vendorId: (printerConfig['vendorId'] as int? ?? 0).toString(),
      productId: (printerConfig['productId'] as int? ?? 0).toString(),
      code: printerConfig['code'] as String? ?? '',
    );

    // พิมพ์ไฟล์
    await printFromFile(printerData: printer, pathName: filePath);

    AppLogger.debug('[PrintCompute] ✅ Success: $fileName');

    return {'success': true, 'fileName': fileName, 'printer': printerName};
  } catch (e, stackTrace) {
    if (kDebugMode) {
      AppLogger.error('[PrintCompute] ❌ Error: $e');
      AppLogger.debug('[PrintCompute] Stack: $stackTrace');
    }

    return {
      'success': false,
      'error': e.toString(),
      'fileName': params['fileName'],
    };
  }
}

/// Helper function to parse printer connect type
global.PrinterConnectEnum _parsePrinterConnectType(String type) {
  switch (type) {
    case 'ip':
      return global.PrinterConnectEnum.ip;
    case 'bluetooth':
      return global.PrinterConnectEnum.bluetooth;
    case 'usb':
      return global.PrinterConnectEnum.usb;
    case 'windows':
      return global.PrinterConnectEnum.windows;
    case 'sunmi1':
      return global.PrinterConnectEnum.sunmi1;
    default:
      return global.PrinterConnectEnum.ip;
  }
}
