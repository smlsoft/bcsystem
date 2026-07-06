import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/core/logger/app_logger.dart';

/// File Cleanup Service
/// แยกการทำความสะอาดไฟล์:
/// 1. ไฟล์พิมพ์บิล (PNG): ลบทันทีหลังพิมพ์เสร็จ (ดูแลโดย PrintQueueManager)
/// 2. ไฟล์ upload (JPG): เก็บไว้ 7 วัน หลัง upload สำเร็จ
class FileCleanupService {
  Timer? _cleanupTimer;
  bool _isRunning = false;

  // ⭐ Configuration
  static const Duration cleanupInterval = Duration(
    hours: 1,
  ); // ตรวจสอบทุก 1 ชั่วโมง
  static const int uploadFilesKeepDays = 7; // เก็บไฟล์ upload ไว้ 7 วัน

  /// Start cleanup timer
  void start() {
    if (_cleanupTimer != null && _cleanupTimer!.isActive) {
      AppLogger.debug('[FileCleanup] ⚠️ Cleanup timer already running');
      return;
    }

    if (kDebugMode) {
      AppLogger.debug('🚀 Starting File Cleanup Service...');
      AppLogger.debug('Interval: ${cleanupInterval.inHours} hour(s)');
      AppLogger.debug('Upload files keep: $uploadFilesKeepDays days');
    }

    // ⭐ รันทันทีครั้งแรก
    _performCleanup();

    // ⭐ สร้าง Timer ที่ทำงานทุก 1 ชั่วโมง
    _cleanupTimer = Timer.periodic(cleanupInterval, (timer) {
      _performCleanup();
    });

    AppLogger.debug('[FileCleanup] ✅ Cleanup timer started');
  }

  /// Stop cleanup timer
  void stop() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    AppLogger.debug('[FileCleanup] ⏹️ Cleanup timer stopped');
  }

  /// Perform cleanup of old files
  /// แบ่งเป็น 2 ประเภท:
  /// 1. ไฟล์พิมพ์บิล (PNG): ลบทันทีหลังพิมพ์ (handled by PrintQueueManager)
  /// 2. ไฟล์ upload (JPG): ลบหลังเก็บไว้ 7 วัน
  Future<void> _performCleanup() async {
    if (_isRunning) {
      AppLogger.debug(
        '[FileCleanup] ⚠️ Cleanup already in progress, skipping...',
      );
      return;
    }

    _isRunning = true;

    try {
      AppLogger.debug('[FileCleanup] 🧹 Starting cleanup process...');

      final Stopwatch stopwatch = Stopwatch()..start();

      // ⭐ 1. Cleanup old Upload Queue files (JPG - เก็บ 7 วัน)
      final uploadFilesDeleted = await global.cleanupOldUploadJobsAndFiles(
        daysToKeep: uploadFilesKeepDays,
      );

      // ⭐ 2. Cleanup old Print Queue records (ObjectBox only, files already deleted after printing)
      final printRecordsDeleted = await global.cleanupOldPrintJobs(
        daysToKeep: uploadFilesKeepDays,
      );

      stopwatch.stop();

      if (kDebugMode) {
        AppLogger.success(
          '[FileCleanup] ✅ Cleanup completed in ${stopwatch.elapsedMilliseconds}ms',
        );
        AppLogger.info(
          '[FileCleanup]    📤 Upload files deleted: $uploadFilesDeleted',
        );
        AppLogger.info(
          '[FileCleanup]    🖨️ Print records cleaned: $printRecordsDeleted',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        AppLogger.error('[FileCleanup] ❌ Cleanup error: $e');
        AppLogger.debug('Stack: $stackTrace');
      }

      global.sendErrorToDevTeam(
        'FileCleanupService',
        'Cleanup error: $e\n$stackTrace',
      );
    } finally {
      _isRunning = false;
    }
  }

  /// Format bytes to human-readable string (kept for future use)
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Global instance
final fileCleanupService = FileCleanupService();
