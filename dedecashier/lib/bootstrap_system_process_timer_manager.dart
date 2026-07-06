// System Process Timer Manager
// จัดการ Timer สำหรับ:
// 1. Sync Master Counter (ทุก 10 วินาที)
// 2. System Process Tasks (ทุก 15 วินาที)
//    - systemProcess()
//    - registerRemoteToTerminal()
//    - compareBarcodeStatus()
//
// แทนที่ Isolate เดิมด้วย Timer ที่ปลอดภัยกว่า

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/global.dart' as global;

class SystemProcessTimerManager {
  static final SystemProcessTimerManager _instance = SystemProcessTimerManager._internal();

  factory SystemProcessTimerManager() => _instance;

  SystemProcessTimerManager._internal();

  Timer? _syncMasterTimer;
  Timer? _systemProcessTimer;
  Timer? _tierCsvReloadTimer; // ⭐ NEW: Timer สำหรับโหลด Tier CSV
  bool _isRunning = false;
  bool _isSyncProcessing = false;
  bool _isSystemProcessing = false;

  /// เริ่ม Timer Manager
  void start() {
    if (_isRunning) {
      AppLogger.warning('⚠️ [SystemProcess] Timer already running');
      return;
    }

    AppLogger.info('🚀 [SystemProcess] Starting Timer Manager...');

    _isRunning = true;

    // Timer 1: Sync Master Counter (ทุก 10 วินาที)
    _syncMasterTimer = Timer.periodic(const Duration(seconds: 10), (_) => _processSyncMasterCounter());

    // Timer 2: System Process Tasks (ทุก 15 วินาที)
    _systemProcessTimer = Timer.periodic(const Duration(seconds: 15), (_) => _processSystemTasks());

    // Timer 3: Tier CSV Reload (ทุก 5 นาที)
    // _tierCsvReloadTimer = Timer.periodic(const Duration(minutes: 5), (_) => _reloadTierCsv());

    AppLogger.success('✅ [SystemProcess] Timer Manager started');
    AppLogger.debug('   - Sync Master: every 10 seconds');
    AppLogger.debug('   - System Tasks: every 15 seconds');
    AppLogger.debug('   - Tier CSV Reload: every 5 minutes');
  }

  /// หยุด Timer Manager
  void stop() {
    if (!_isRunning) return;

    AppLogger.debug('🛑 [SystemProcess] Stopping Timer Manager...');

    _syncMasterTimer?.cancel();
    _systemProcessTimer?.cancel();
    _tierCsvReloadTimer?.cancel();
    _syncMasterTimer = null;
    _systemProcessTimer = null;
    _tierCsvReloadTimer = null;
    _isRunning = false;

    AppLogger.success('✅ [SystemProcess] Timer Manager stopped');
  }

  /// Pause (เมื่อ app เข้า background)
  void pause() {
    if (!_isRunning) return;

    AppLogger.debug('⏸️  [SystemProcess] Timer Manager paused');

    _syncMasterTimer?.cancel();
    _systemProcessTimer?.cancel();
    _tierCsvReloadTimer?.cancel();
  }

  /// Resume (เมื่อ app กลับมา foreground)
  void resume() {
    if (!_isRunning) return;

    AppLogger.debug('▶️  [SystemProcess] Timer Manager resumed');

    // Restart timers
    _syncMasterTimer = Timer.periodic(const Duration(seconds: 10), (_) => _processSyncMasterCounter());

    _systemProcessTimer = Timer.periodic(const Duration(seconds: 15), (_) => _processSystemTasks());

    // _tierCsvReloadTimer = Timer.periodic(const Duration(minutes: 5), (_) => _reloadTierCsv());
  }

  /// Process Sync Master Counter (ทุก 10 วินาที)
  Future<void> _processSyncMasterCounter() async {
    // ป้องกัน concurrent execution
    if (_isSyncProcessing) {
      if (kDebugMode) {
        AppLogger.debug('⏭️  [SystemProcess] Skipping sync - previous task still running');
      }
      return;
    }

    // เช็คว่า login แล้วหรือยัง
    if (!global.loginSuccess || global.shopId.isEmpty) {
      return;
    }

    _isSyncProcessing = true;

    try {
      if (kDebugMode) {
        AppLogger.debug('🔄 [SystemProcess] Sync master counter...');
      }

      // เพิ่ม counter
      if (global.syncTimeIntervalSecond < global.syncTimeIntervalMaxBySecond) {
        global.syncTimeIntervalSecond++;
      } else {
        global.syncTimeIntervalSecond = 1;
      }

      if (kDebugMode) {
        AppLogger.debug('✅ [SystemProcess] Sync counter: ${global.syncTimeIntervalSecond}/${global.syncTimeIntervalMaxBySecond}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ [SystemProcess] Sync counter error', error: e, stackTrace: stackTrace);
    } finally {
      _isSyncProcessing = false;
    }
  }

  /// Process System Tasks (ทุก 15 วินาที)
  Future<void> _processSystemTasks() async {
    // ป้องกัน concurrent execution
    if (_isSystemProcessing) {
      if (kDebugMode) {
        AppLogger.debug('⏭️  [SystemProcess] Skipping tasks - previous task still running');
      }
      return;
    }

    // เช็คว่า login แล้วหรือยัง
    if (!global.loginSuccess || global.shopId.isEmpty) {
      return;
    }

    _isSystemProcessing = true;

    try {
      if (kDebugMode) {
        AppLogger.debug('🔄 [SystemProcess] Running system tasks...');
      }

      // Task 1: System Process (ตรวจสอบสถานะระบบ)
      await global.systemProcess();

      // Task 2: Register Remote to Terminal (สำหรับ POS Remote)
      if (global.appMode == global.AppModeEnum.posRemote) {
        await global.registerRemoteToTerminal();
      }

      // Task 3: Barcode Status Flag (ใช้ flag จาก global แทน)
      // NOTE: global.rebuildProductBarcodeStatus จะถูกจัดการใน sync process

      if (kDebugMode) {
        AppLogger.debug('✅ [SystemProcess] System tasks completed');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ [SystemProcess] System tasks error', error: e, stackTrace: stackTrace);
    } finally {
      _isSystemProcessing = false;
    }
  }

  /// โหลด Tier CSV ใหม่
  // Future<void> _reloadTierCsv() async {
  //   try {
  //     if (kDebugMode) {
  //       AppLogger.debug('🔄 [TierCSV] Reloading Tier promotions...');
  //     }

  //     await global.loadTierPromotions(forceReload: true);

  //     if (kDebugMode) {
  //       AppLogger.success('✅ [TierCSV] Reload completed');
  //     }
  //   } catch (e, stackTrace) {
  //     AppLogger.error(
  //       '❌ [TierCSV] Reload error',
  //       error: e,
  //       stackTrace: stackTrace,
  //     );
  //   }
  // }

  /// สถานะ
  bool get isRunning => _isRunning;
  bool get isSyncProcessing => _isSyncProcessing;
  bool get isSystemProcessing => _isSystemProcessing;
}

// Global instance
final systemProcessTimerManager = SystemProcessTimerManager();
