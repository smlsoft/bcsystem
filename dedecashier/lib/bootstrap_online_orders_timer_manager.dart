// Online Orders Timer Manager
// จัดการ Timer สำหรับตรวจสอบออเดอร์ออนไลน์และครัว
//
// แทนที่ Isolate เดิมด้วย Timer ที่ปลอดภัยกว่า
// - ไม่มีปัญหา memory isolation
// - ใช้ global state ได้ปกติ
// - Debug ง่ายกว่า

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/api/clickhouse/clickhouse_api.dart' as api;
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/table_struct.dart';

class OnlineOrdersTimerManager {
  static final OnlineOrdersTimerManager _instance = OnlineOrdersTimerManager._internal();

  factory OnlineOrdersTimerManager() => _instance;

  OnlineOrdersTimerManager._internal();

  Timer? _checkOrdersTimer;
  Timer? _cleanupTimer;
  bool _isRunning = false;
  bool _isProcessing = false;

  /// เริ่ม Timer Manager
  /// ทำงานเฉพาะ Flavor.CASHIER เท่านั้น
  void start() {
    // ⭐ ทำงานเฉพาะ CASHIER flavor เท่านั้น
    if (F.appFlavor != Flavor.CASHIER) {
      AppLogger.info('⏭️ [OnlineOrders] Skipping - Not CASHIER flavor (current: ${F.appFlavor})');
      return;
    }

    if (_isRunning) {
      AppLogger.warning('⚠️ [OnlineOrders] Timer already running');
      return;
    }

    AppLogger.info('🚀 [OnlineOrders] Starting Timer Manager for CASHIER...');

    _isRunning = true;

    // Timer 1: Check Online Orders + Kitchen (ทุก 10 วินาที)
    _checkOrdersTimer = Timer.periodic(const Duration(seconds: 10), (_) => _processOnlineOrdersAndKitchen());

    // Timer 2: ClickHouse Cleanup (ทุก 60 วินาที)
    _cleanupTimer = Timer.periodic(const Duration(seconds: 60), (_) => _processClickHouseCleanup());

    AppLogger.success('✅ [OnlineOrders] Timer Manager started');
    AppLogger.debug('   - Check Orders: every 3 seconds');
    AppLogger.debug('   - Cleanup: every 60 seconds');
  }

  /// หยุด Timer Manager
  void stop() {
    if (!_isRunning) return;

    AppLogger.info('🛑 [OnlineOrders] Stopping Timer Manager...');

    _checkOrdersTimer?.cancel();
    _cleanupTimer?.cancel();
    _checkOrdersTimer = null;
    _cleanupTimer = null;
    _isRunning = false;

    AppLogger.success('✅ [OnlineOrders] Timer Manager stopped');
  }

  /// Pause (เมื่อ app เข้า background)
  void pause() {
    if (!_isRunning) return;

    AppLogger.debug('⏸️  [OnlineOrders] Timer Manager paused');

    _checkOrdersTimer?.cancel();
    _cleanupTimer?.cancel();
  }

  /// Resume (เมื่อ app กลับมา foreground)
  void resume() {
    if (!_isRunning) return;

    AppLogger.debug('▶️  [OnlineOrders] Timer Manager resumed');

    // Restart timers
    _checkOrdersTimer = Timer.periodic(const Duration(seconds: 3), (_) => _processOnlineOrdersAndKitchen());

    _cleanupTimer = Timer.periodic(const Duration(seconds: 60), (_) => _processClickHouseCleanup());
  }

  /// ตรวจสอบออเดอร์ออนไลน์และครัว
  /// รวม sendTempToServer, callerCheck, lineNotifyCheck
  Future<void> _processOnlineOrdersAndKitchen() async {
    // ป้องกัน concurrent execution
    if (_isProcessing) {
      AppLogger.debug('⏭️  [OnlineOrders] Skipping - previous task still running');
      return;
    }

    // เช็คว่า login แล้วหรือยัง
    if (!global.loginSuccess || global.shopId.isEmpty) {
      return; // ไม่ต้อง log เพราะจะเยอะเกิน
    }

    _isProcessing = true;

    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
      AppLogger.debug('🔄 [OnlineOrders] Processing cycle started...');
    }

    try {
      // 1️⃣ Check Online Orders
      if (global.checkOrderFromOnLineActive == false) {
        try {
          await global.checkOrderOnline();
        } catch (e) {
          AppLogger.debug('[OnlineOrders] checkOrderOnline error: $e');
        }
      }

      // 2️⃣ Check Kitchen Orders
      if (global.checkKitchenActive == false) {
        try {
          await global.checkKitchenOrder();
        } catch (e) {
          AppLogger.debug('[OnlineOrders] checkKitchenOrder error: $e');
        }
      }

      // 3️⃣ Send Temp Data to Server (ต้อง online และยังไม่ active)
      if (global.sendTempToServerActive == false && global.isOnline) {
        try {
          await global.sendTempToServer();
        } catch (e) {
          AppLogger.debug('[OnlineOrders] sendTempToServer error: $e');
        }
      }

      // 4️⃣ Caller Check & Line Notify (ต้อง online)
      if (global.isOnline) {
        try {
          await Future.wait([global.callerCheck(), global.lineNotifyCheck()]);
        } catch (e) {
          AppLogger.debug('[OnlineOrders] callerCheck/lineNotifyCheck error: $e');
        }
      }

      if (kDebugMode && stopwatch != null) {
        stopwatch.stop();
        AppLogger.debug('[Performance] Online orders cycle: ${stopwatch.elapsedMilliseconds}ms');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ [OnlineOrders] Error in processing cycle', error: e, stackTrace: stackTrace);
    } finally {
      _isProcessing = false;
    }
  }

  /// ทำความสะอาด ClickHouse (ทุก 60 วินาที)
  /// - ลบโต๊ะที่ปิดแล้วออกจาก dedetemp.jsoninfo
  /// - ลบ caller ที่เกิน 1 ชั่วโมง
  /// - ส่ง OrderTemp ไป ClickHouse
  Future<void> _processClickHouseCleanup() async {
    // เช็คว่า login แล้วและ online
    if (!global.loginSuccess || global.shopId.isEmpty || !global.isOnline) {
      return;
    }

    try {
      if (kDebugMode) {
        AppLogger.debug('🧹 [OnlineOrders] Running ClickHouse cleanup...');
      }

      // 1️⃣ ลบ Click House โต๊ะที่ปิดและจ่ายเงินแล้ว (dedetemp.jsoninfo)
      var jsonInfoSelect = await api.clickHouseSelect(
        "select code,count(*) as xcount from dedetemp.jsoninfo where shopid = '${global.shopId}' and posid = '${global.posConfig.code}' group by code",
      );

      ResponseDataModel response = ResponseDataModel.fromJson(jsonInfoSelect);

      var tableProcessData = global.objectBoxStore.box<TableProcessObjectBoxStruct>().getAll();

      // สร้าง Map สำหรับ O(1) lookup แทน nested loop
      final codeCountMap = <String, int>{};
      for (var data in response.data) {
        codeCountMap[data["code"].toString()] = int.tryParse(data["xcount"].toString()) ?? 0;
      }

      // Parallel cleanup operations
      final cleanupTasks = <Future>[];

      for (var table in tableProcessData) {
        if (table.number.isEmpty) continue;

        final count = codeCountMap[table.number];
        if (count != null && table.table_status == 0 && count > 0) {
          // โต๊ะปิดแล้ว ให้ลบออกจาก ClickHouse
          cleanupTasks.add(
            api.clickHouseExecute("alter table dedetemp.jsoninfo delete where shopid='${global.shopId}' and code='${table.number}' and posid = '${global.posConfig.code}'"),
          );
        }
      }

      // Execute all cleanup tasks in parallel
      if (cleanupTasks.isNotEmpty) {
        await Future.wait(cleanupTasks);
      }

      // 2️⃣ ลบ caller ถ้าเกิน 1 ชั่วโมง
      var callerData = await api.clickHouseSelect("select * from dedetemp.caller where shopid = '${global.shopId}'");

      ResponseDataModel callerResponse = ResponseDataModel.fromJson(callerData);

      if (callerResponse.data.isNotEmpty) {
        final now = DateTime.now();
        final callerCleanupTasks = <Future>[];

        for (var caller in callerResponse.data) {
          DateTime callerDate = DateTime.parse(caller["calldatetime"]);
          int diffTime = now.difference(callerDate).inHours;

          if (diffTime > 1) {
            callerCleanupTasks.add(api.clickHouseExecute("alter table dedetemp.caller delete where shopid='${global.shopId}' and refguid='${caller["refguid"]}'"));
          }
        }

        // Execute all caller cleanup in parallel
        if (callerCleanupTasks.isNotEmpty) {
          await Future.wait(callerCleanupTasks);
        }
      }

      // 3️⃣ ส่งข้อมูล OrderTempSync ไปที่ Click House
      global.sendOrderTempToDeDeOrderTempLog();

      if (kDebugMode) {
        AppLogger.debug('✅ [OnlineOrders] ClickHouse cleanup completed');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ [OnlineOrders] ClickHouse cleanup error', error: e, stackTrace: stackTrace);

      global.sendErrorToDevTeam("bootstrap_online_orders_timer_manager.dart->_processClickHouseCleanup", "ClickHouse Cleanup: $e\n${stackTrace.toString()}");
    }
  }

  /// สถานะ
  bool get isRunning => _isRunning;
  bool get isProcessing => _isProcessing;
}

// Global instance
final onlineOrdersTimerManager = OnlineOrdersTimerManager();
