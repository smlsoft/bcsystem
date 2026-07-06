import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

/// ⚠️ DEPRECATED - ไม่ใช้แล้ว
/// Isolate จะ query ObjectBox ด้วยตัวเองโดยใช้ Store.attach()
///
/// Timer นี้ถูกแทนที่ด้วย internal timer ใน Isolate worker
Timer? startPrintQueueTimer(SendPort? isolateSendPort) {
  AppLogger.debug(
    '[PrintQueue] ⚠️ Timer is deprecated - Isolate handles its own queries',
  );
  return null;
}
