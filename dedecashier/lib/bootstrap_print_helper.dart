import 'dart:isolate';
import 'package:dedecashier/util/printer.dart';
import 'package:dedecashier/global_model.dart';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/core/logger/app_logger.dart';

/// Process single print job asynchronously
Future<void> processPrintJobAsync(
  String fileName,
  String printerName,
  String filePath,
  Map<String, Map<String, dynamic>> printersCache,
  SendPort mainSendPort,
) async {
  if (kDebugMode) {
    AppLogger.debug('🖨️ Processing print job: $fileName');
    AppLogger.debug('Printer: $printerName');
    AppLogger.debug('File: $filePath');
  }

  try {
    // หา printer config จาก cache
    final printerData = printersCache[printerName];

    if (printerData == null) {
      throw Exception('Printer not found in cache: $printerName');
    }

    // แปลง Map เป็น PrinterLocalStrongDataModel
    final printer = PrinterLocalStrongDataModel.fromJson(printerData);

    // ส่งสถานะว่ากำลังพิมพ์
    mainSendPort.send({
      'status': 'printing',
      'data': {'fileName': fileName, 'printer': printerName},
    });

    // พิมพ์
    await printFromFile(printerData: printer, pathName: filePath);

    // ส่งสถานะว่าพิมพ์เสร็จ
    mainSendPort.send({
      'status': 'completed',
      'data': {'fileName': fileName, 'printer': printerName, 'success': true},
    });

    AppLogger.debug('[PrintQueue] ✅ Print job completed: $fileName');
  } catch (e, stackTrace) {
    if (kDebugMode) {
      AppLogger.error('❌ Print job failed: $e');
      AppLogger.debug('Stack: $stackTrace');
    }

    // ส่งสถานะ error (ใส่ fileName เสมอ)
    mainSendPort.send({
      'status': 'error',
      'data': {
        'fileName': fileName, // ⭐ เพิ่ม fileName
        'printer': printerName,
        'error': e.toString(),
        'message': 'Print job failed: ${e.toString()}', // ⭐ เพิ่ม message
        'stackTrace': stackTrace.toString(),
      },
    });

    global.sendErrorToDevTeam(
      "bootstrap_print_helper.dart->processPrintJobAsync",
      "Print job $fileName failed: $e\n${stackTrace.toString()}",
    );

    // ⭐ Re-throw เพื่อให้ Isolate worker catch และ update ObjectBox
    rethrow;
  }
}
