import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dedecashier/model/objectbox/print_queue_struct.dart';
import 'package:dedecashier/objectbox.g.dart'; // For PrintQueueObjectBoxStruct_
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/util/printer.dart';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

/// Timer-based Print Queue Manager (Main Thread Only)
///
/// 🎯 **ความสามารถหลัก:**
/// - **Main Thread Only**: ทำงานบน Main Thread เพื่อเข้าถึง Flutter Bindings
/// - **Per-Printer Locking**: ป้องกันการพิมพ์ซ้อนกันบนเครื่องพิมพ์เดียวกัน
/// - **Parallel Processing**: เครื่องพิมพ์แต่ละเครื่องทำงานอิสระ ไม่ต้องรอกัน
/// - **Sequential per Printer**: เครื่องเดียวกันพิมพ์ทีละ job ตามลำดับ
/// - **Auto Cleanup**: ลบรายการเก่า >24h และไฟล์ PNG อัตโนมัติ
///
/// 🔒 **การทำงาน:**
/// ```
/// Timer (1s) → Query Jobs → Group by Printer
///   ├─ Printer1: [Job1, Job2] → Sequential (Lock → Print → Unlock)
///   ├─ Printer2: [Job3] → Sequential (Lock → Print → Unlock)
///   └─ Printer3: [Job4, Job5] → Sequential (Lock → Print → Unlock)
///   ↑ ทั้ง 3 เครื่อง พิมพ์พร้อมกัน (Parallel) แต่ไม่ใช้ Isolate
/// ```
///
/// ⚠️ **ข้อจำกัด:**
/// - ไม่ใช้ Isolate/Compute (เพื่อเข้าถึง Flutter Bindings)
/// - เครื่องพิมพ์แต่ละเครื่องแยกหน้าที่ชัดเจน ห้ามข้ามเครื่อง
/// - Parallel Processing: เครื่องคนละตัวพิมพ์พร้อมกัน (แยกหน้าที่อิสระ)
/// - Sequential per Printer: เครื่องเดียวกันพิมพ์ทีละ job ตามลำดับ
/// - Main Thread Only: ไม่ใช้ Isolate/Compute (เข้าถึง Flutter Bindings ได้)
class PrintQueueTimerManager {
  Timer? _timer;
  bool _isProcessing = false;

  /// ⭐ Per-Printer Lock Map
  /// Key = printerName, Value = isCurrentlyPrinting
  ///
  /// 🔒 ป้องกันการพิมพ์ซ้อนกันบน printer เดียวกัน
  /// - true = printer กำลังพิมพ์อยู่ (ห้ามพิมพ์ job อื่น)
  /// - false/null = printer ว่าง (พิมพ์ได้)
  final Map<String, bool> _printerLocks = {};

  /// ⭐ Lock Timestamp Map (สำหรับ timeout detection)
  /// Key = printerName, Value = เวลาที่ lock
  final Map<String, DateTime> _lockTimestamps = {};

  /// ⏱️ Lock Timeout Duration (30 วินาที)
  /// ถ้า lock นานเกินนี้ จะถือว่า stuck และจะ force unlock
  static const Duration _lockTimeout = Duration(seconds: 30);

  /// ⭐ Current Jobs Tracking (สำหรับ debug)
  /// Key = printerName, Value = fileName ที่กำลังพิมพ์
  final Map<String, String> _currentJobs = {};

  /// Check if timer is active
  bool get isActive => _timer != null && _timer!.isActive;

  /// Start the print queue timer
  ///
  /// ⏱️ Timer ทำงานทุก 1 วินาที (Main Thread Only):
  /// 1. ลบรายการคิวพิมพ์ที่เกิน 24 ชม. (ทุกสถานะ: pending, completed, failed)
  /// 2. Query pending jobs และ group by printer
  /// 3. ⭐ Process แต่ละ printer แบบ parallel (แยกหน้าที่อิสระ, ไม่รอกัน)
  /// 4. แต่ละ printer process jobs ของตัวเองแบบ sequential (ป้องกันชนกัน)
  /// 5. ⭐ Keep Pending: ถ้าพิมพ์ไม่ได้จะรอ 10 วินาทีแล้ว retry จนกว่าจะสำเร็จ (หรือหมดอายุ 24 ชม.)
  /// 6. ลบไฟล์ PNG หลังพิมพ์เสร็จ
  void start() {
    if (_timer != null && _timer!.isActive) {
      AppLogger.debug('[PrintQueueTimer] ⚠️ Timer already running');
      return;
    }

    // ⭐ ล้าง locks ก่อน start ใหม่
    _printerLocks.clear();
    _lockTimestamps.clear();
    _currentJobs.clear();

    if (kDebugMode) {
      AppLogger.debug('🚀 Starting Print Queue Timer...');
      AppLogger.success('Login: ${global.loginSuccess}');
      AppLogger.debug('[PrintQueueTimer]    Printers: ${global.printerLocalStrongData.length}');
    }

    // ⭐ สร้าง Timer ที่ query ObjectBox ทุก 1 วินาที (Main Thread)
    // - ลบรายการเก่า > 24h อัตโนมัติ
    // - Process pending print jobs (แยกตาม printer, แต่ละเครื่องทำงานอิสระ)
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _processQueue();
    });

    AppLogger.debug('[PrintQueueTimer] ✅ Timer started successfully');
  }

  /// Stop the print queue timer
  void stop() {
    _timer?.cancel();
    _timer = null;
    _printerLocks.clear(); // ⭐ ล้าง locks
    _lockTimestamps.clear();
    _currentJobs.clear();

    AppLogger.debug('[PrintQueueTimer] Timer stopped');
  }

  /// Pause timer (เมื่อ app เข้า background)
  void pause() {
    _timer?.cancel();
    AppLogger.debug('[PrintQueueTimer] ⏸️  Timer paused');
  }

  /// Resume timer (เมื่อ app กลับมา foreground)
  void resume() {
    if (_timer != null && _timer!.isActive) {
      // Timer ยังทำงานอยู่แล้ว
      return;
    }

    // ⭐ Force unlock stale locks (ที่อาจค้างจาก pause)
    final now = DateTime.now();
    final staleLocksCleared = <String>[];

    _lockTimestamps.removeWhere((printerName, lockTime) {
      final lockAge = now.difference(lockTime);
      if (lockAge > const Duration(minutes: 2)) {
        _printerLocks[printerName] = false;
        _currentJobs.remove(printerName);
        staleLocksCleared.add(printerName);
        return true;
      }
      return false;
    });

    if (kDebugMode && staleLocksCleared.isNotEmpty) {
      AppLogger.warning('[PrintQueueTimer] 🔓 Cleared ${staleLocksCleared.length} stale locks on resume: ${staleLocksCleared.join(", ")}');
    }

    // Restart timer
    start();
    AppLogger.debug('[PrintQueueTimer] ▶️  Timer resumed');
  }

  /// Process pending print jobs (Main Thread Only)
  ///
  /// ⭐ แยก jobs ตาม printer → แต่ละเครื่องทำงานอิสระ (parallel)
  /// แต่ภายในเครื่องเดียวกันทำงาน sequential (ป้องกันชนกัน)
  Future<void> _processQueue() async {
    // ป้องกัน concurrent execution
    if (_isProcessing || !global.loginSuccess) {
      return;
    }

    _isProcessing = true;
    Stopwatch? stopwatch;

    try {
      if (kDebugMode) {
        stopwatch = Stopwatch()..start();
      }

      // ⭐ ลบรายการที่เกิน 24 ชม. ก่อน (ทุกประเภท: pending, completed, failed)
      await _cleanupOldJobs();

      // ⭐ Reset งานที่ค้างใน "printing" นานเกิน 2 นาที (อาจเกิดจาก app crash)
      await _resetStuckPrintingJobs();

      // Query pending jobs
      final pendingJobs = global.getPendingPrintJobs();

      if (pendingJobs.isEmpty) {
        return;
      }

      if (kDebugMode) {
        AppLogger.debug('[PrintQueueTimer] 📋 Found ${pendingJobs.length} pending jobs');
      }

      // ⭐ Group jobs by printer (แยกตามเครื่อง)
      final jobsByPrinter = <String, List<PrintQueueObjectBoxStruct>>{};
      for (var job in pendingJobs) {
        jobsByPrinter.putIfAbsent(job.printerName, () => []).add(job);
      }

      if (kDebugMode) {
        AppLogger.debug('[PrintQueueTimer] 📊 Jobs grouped by ${jobsByPrinter.length} printers:');
        for (var entry in jobsByPrinter.entries) {
          AppLogger.debug('  - ${entry.key}: ${entry.value.length} jobs');
        }
      }

      // ⭐ Process แต่ละ printer แบบ parallel (อิสระกัน, ไม่รอกัน)
      // แต่ละ printer จะ process jobs ของตัวเองแบบ sequential
      // ใช้ Future.wait (ทำงานบน Main Thread, ไม่ใช่ Isolate)
      final futures = <Future<void>>[];
      for (var entry in jobsByPrinter.entries) {
        final printerName = entry.key;
        final jobs = entry.value;

        // สร้าง Future สำหรับแต่ละ printer
        futures.add(_processPrinterJobs(printerName, jobs));
      }

      // รอให้ทุก printer เสร็จ (parallel processing on Main Thread)
      await Future.wait(futures);

      if (kDebugMode && stopwatch != null) {
        stopwatch.stop();
        AppLogger.success('[Performance] _processQueue() took ${stopwatch.elapsedMilliseconds}ms');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        AppLogger.error('❌ Queue processing error: $e');
        AppLogger.debug('Stack: $stackTrace');
      }

      global.sendErrorToDevTeam('PrintQueueTimer', 'Queue processing error: $e\n$stackTrace');
    } finally {
      _isProcessing = false;
    }
  }

  /// ⭐ Process jobs สำหรับ printer เครื่องเดียว (sequential)
  ///
  /// แต่ละ printer จะ process jobs ของตัวเองทีละ job ตามลำดับ
  /// ถ้า printer ถูก lock อยู่ จะ skip jobs (รอ timer รอบถัดไป)
  Future<void> _processPrinterJobs(String printerName, List<PrintQueueObjectBoxStruct> jobs) async {
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
      AppLogger.debug('[PrintQueueTimer] 🖨️ Processing ${jobs.length} jobs for "$printerName"');
    }

    // ⭐ Sort jobs by priority DESC → receipt (priority=1) พิมพ์ก่อน kitchen (priority=0)
    // แม้ว่า jobs จะถูกสร้างไม่พร้อมกัน (เช่น พิมพ์ครัวอยู่แล้วค่อยจ่ายเงิน)
    jobs.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority); // DESC (สูงก่อน)
      if (priorityCompare != 0) return priorityCompare;
      return a.createdAt.compareTo(b.createdAt); // ASC (เก่าก่อน)
    });

    if (kDebugMode && jobs.length > 1) {
      AppLogger.debug('[PrintQueueTimer] 📊 Job order after priority sort:');
      for (var job in jobs) {
        AppLogger.debug('  - ${job.fileName} (priority=${job.priority}, type=${job.jobType})');
      }
    }

    // Process jobs ทีละตัว sequential (ห้ามพิมพ์พร้อมกันบนเครื่องเดียว)
    // ⭐ ครอบด้วย try-catch เพื่อให้ error ใน job หนึ่งไม่หยุด jobs อื่น
    for (var job in jobs) {
      try {
        await _processSingleJob(job);
      } catch (e, stackTrace) {
        // ⭐ Catch error เพื่อให้ loop ทำงานต่อไปกับ jobs ที่เหลือ
        if (kDebugMode) {
          AppLogger.error('[PrintQueueTimer] ❌ Error processing job "${job.fileName}": $e');
          AppLogger.debug('Stack: $stackTrace');
        }

        // ⭐ ปลดล็อก printer ถ้าค้างอยู่
        if (_printerLocks[printerName] == true) {
          _unlockPrinter(printerName);
        }

        // ⭐ อัพเดท job status เป็น pending เพื่อ retry ในรอบถัดไป
        try {
          await global.updatePrintJobStatus(fileName: job.fileName, status: PrintQueueStatus.pending, errorMessage: 'Unexpected error: ${e.toString()}', updateLastAttempt: true);
        } catch (updateError) {
          AppLogger.error('[PrintQueueTimer] ⚠️ Failed to update job status: $updateError');
        }

        // ⭐ ไม่ rethrow - ให้ loop ทำงานต่อกับ jobs ถัดไป
      }
    }

    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.success('[Performance] Printer "$printerName" processed ${jobs.length} jobs in ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  /// ⭐ ตรวจสอบและ Lock printer
  ///
  /// Returns true ถ้า lock สำเร็จ (printer ว่าง)
  /// Returns false ถ้า printer กำลังพิมพ์อยู่
  bool _tryLockPrinter(String printerName, String fileName) {
    // ⭐ เช็ค stale lock (lock ที่ค้างเกิน timeout)
    final existingLockTime = _lockTimestamps[printerName];
    if (existingLockTime != null) {
      final lockAge = DateTime.now().difference(existingLockTime);
      if (lockAge > _lockTimeout) {
        // Force unlock stale lock
        if (kDebugMode) {
          AppLogger.warning('[PrintQueueTimer] ⏰ Force unlock stale lock on "$printerName" (age: ${lockAge.inSeconds}s, job: ${_currentJobs[printerName]})');
        }
        _printerLocks[printerName] = false;
        _lockTimestamps.remove(printerName);
        _currentJobs.remove(printerName);
      }
    }

    if (_printerLocks[printerName] == true) {
      // Printer กำลังพิมพ์อยู่
      if (kDebugMode) {
        AppLogger.warning('[PrintQueueTimer] 🔒 Printer "$printerName" is busy (printing: ${_currentJobs[printerName]}), skipping "$fileName"');
      }
      return false;
    }

    // Lock printer
    _printerLocks[printerName] = true;
    _lockTimestamps[printerName] = DateTime.now();
    _currentJobs[printerName] = fileName;

    if (kDebugMode) {
      AppLogger.debug('[PrintQueueTimer] 🔓 Locked "$printerName" for "$fileName"');
    }

    return true;
  }

  /// ⭐ ปลดล็อก printer หลังพิมพ์เสร็จ
  void _unlockPrinter(String printerName) {
    _printerLocks[printerName] = false;
    _lockTimestamps.remove(printerName);
    final finishedJob = _currentJobs.remove(printerName);

    if (kDebugMode) {
      AppLogger.debug('[PrintQueueTimer] 🔓 Unlocked "$printerName" (finished: $finishedJob)');
    }
  }

  /// ลบรายการคิวพิมพ์ที่เกิน 24 ชม. (ทุกสถานะ)
  ///
  /// 🗑️ ลบรายการที่ createdAt เก่ากว่า 24 ชม. ทั้งหมด
  /// เพื่อไม่ให้ database เต็มและ query ช้า
  Future<void> _cleanupOldJobs() async {
    try {
      final box = global.objectBoxStore.box<PrintQueueObjectBoxStruct>();
      final now = DateTime.now();
      final cutoffTime = now.subtract(const Duration(hours: 24));

      // Query รายการที่เก่ากว่า 24 ชม.
      final oldJobs = box.query(PrintQueueObjectBoxStruct_.createdAt.lessThan(cutoffTime.millisecondsSinceEpoch)).build().find();

      if (oldJobs.isEmpty) {
        return; // ไม่มีรายการที่ต้องลบ
      }

      // ลบไฟล์ PNG ก่อน (ถ้ายังมีอยู่)
      int filesDeleted = 0;
      for (var job in oldJobs) {
        try {
          final file = File(job.filePath);
          if (await file.exists()) {
            await file.delete();
            filesDeleted++;
          }
        } catch (e) {
          // ไม่ throw error ถ้าลบไฟล์ไม่ได้
          if (kDebugMode) {
            AppLogger.warning('[PrintQueueTimer] ⚠️ Failed to delete old file ${job.fileName}: $e');
          }
        }
      }

      // ลบ records จาก database
      final jobIds = oldJobs.map((job) => job.id).toList();
      box.removeMany(jobIds);

      if (kDebugMode) {
        AppLogger.info('[PrintQueueTimer] 🗑️ Cleaned up ${oldJobs.length} old jobs (>24h), deleted $filesDeleted files');
      }
    } catch (e, stackTrace) {
      // Log error แต่ไม่ throw เพราะไม่อยากให้กระทบการพิมพ์
      if (kDebugMode) {
        AppLogger.warning('[PrintQueueTimer] ⚠️ Cleanup error: $e');
        AppLogger.debug('Stack: $stackTrace');
      }
    }
  }

  /// ⏱️ ระยะเวลาขั้นต่ำระหว่าง retry (10 วินาที)
  static const _retryInterval = Duration(seconds: 10);

  /// ⏱️ Print Timeout Duration (30 วินาที)
  /// Timeout สำหรับ printFromFile() เพื่อป้องกันการค้าง
  static const Duration _printTimeout = Duration(seconds: 30);

  /// Reset งานที่ค้างใน "printing" status นานเกินไป
  ///
  /// 🔄 ถ้างานค้างเป็น "printing" นานกว่า 2 นาที แสดงว่าอาจเกิดจาก:
  /// - App crash ระหว่างพิมพ์
  /// - Connection timeout ที่ไม่ถูก handle
  /// - Bug อื่นๆ
  ///
  /// จะ reset กลับเป็น "pending" เพื่อให้ retry ได้
  Future<void> _resetStuckPrintingJobs() async {
    try {
      final box = global.objectBoxStore.box<PrintQueueObjectBoxStruct>();
      final now = DateTime.now();
      final stuckThreshold = now.subtract(const Duration(minutes: 2));

      // Query งานที่เป็น "printing" และ lastAttemptAt หรือ createdAt เก่ากว่า 2 นาที
      final stuckJobs = box.query(PrintQueueObjectBoxStruct_.status.equals(PrintQueueStatus.printing.value)).build().find();

      if (stuckJobs.isEmpty) {
        return;
      }

      int resetCount = 0;
      for (var job in stuckJobs) {
        // ใช้ lastAttemptAt ถ้ามี ไม่งั้นใช้ createdAt
        final lastActivity = job.lastAttemptAt ?? job.createdAt;

        if (lastActivity.isBefore(stuckThreshold)) {
          // งานค้างนานเกินไป → reset เป็น pending
          job.status = PrintQueueStatus.pending.value;
          job.lastAttemptAt = now;
          job.retryCount++;
          job.errorMessage = 'Reset from stuck printing status';
          box.put(job);
          resetCount++;

          // ⭐ Unlock printer ที่มี job stuck
          if (_printerLocks[job.printerName] == true) {
            _unlockPrinter(job.printerName);
            if (kDebugMode) {
              AppLogger.warning('[PrintQueueTimer] 🔓 Unlocked stuck printer: "${job.printerName}"');
            }
          }

          if (kDebugMode) {
            AppLogger.warning('[PrintQueueTimer] 🔄 Reset stuck job: ${job.fileName} (was printing for ${now.difference(lastActivity).inSeconds}s)');
          }
        }
      }

      if (resetCount > 0 && kDebugMode) {
        AppLogger.info('[PrintQueueTimer] 🔄 Reset $resetCount stuck printing jobs');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        AppLogger.warning('[PrintQueueTimer] ⚠️ Error resetting stuck jobs: $e');
        AppLogger.debug('Stack: $stackTrace');
      }
    }
  }

  /// Process a single print job (Main Thread Only)
  ///
  /// ⭐ **Keep Pending Strategy:**
  /// - งานจะคงเป็น pending จนกว่าจะพิมพ์สำเร็จ หรือหมดอายุ (24 ชม.)
  /// - ถ้าพิมพ์ไม่ได้ (ไม่เจอปริ้นเตอร์/connection fail) จะรอ 10 วินาทีแล้วลองใหม่
  /// - ไม่มาร์คเป็น failed ยกเว้นไฟล์หายหรือเสียหาย
  ///
  /// ⭐ มี Per-Printer Locking:
  /// - ตรวจสอบว่า printer ว่างหรือไม่ก่อนพิมพ์
  /// - ถ้าไม่ว่าง skip job นี้ (รอ timer รอบถัดไป)
  /// - Lock printer ก่อนพิมพ์ → Unlock หลังเสร็จ (ใน finally)
  Future<void> _processSingleJob(PrintQueueObjectBoxStruct job) async {
    // ⭐ Re-query เพื่อรับข้อมูลล่าสุด (ป้องกัน stale data)
    final box = global.objectBoxStore.box<PrintQueueObjectBoxStruct>();
    final freshJob = box.query(PrintQueueObjectBoxStruct_.fileName.equals(job.fileName)).build().findFirst();

    if (freshJob == null) {
      // Job ถูกลบไปแล้ว
      if (kDebugMode) {
        AppLogger.debug('[PrintQueueTimer] ⚠️ Job "${job.fileName}" no longer exists, skipping');
      }
      return;
    }

    // ใช้ข้อมูลล่าสุดแทน
    job = freshJob;

    // ⭐ ตรวจสอบว่าผ่านไป 10 วินาทีแล้วหรือยังก่อน retry
    if (job.lastAttemptAt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(job.lastAttemptAt!);
      if (timeSinceLastAttempt < _retryInterval) {
        // ยังไม่ถึงเวลา retry → skip รอบนี้
        if (kDebugMode) {
          final remaining = _retryInterval - timeSinceLastAttempt;
          AppLogger.debug('[PrintQueueTimer] ⏳ Skipping "${job.fileName}" - retry in ${remaining.inSeconds}s');
        }
        return;
      }
    }

    // ⭐ ตรวจสอบและ Lock printer ก่อนพิมพ์
    if (!_tryLockPrinter(job.printerName, job.fileName)) {
      // Printer กำลังพิมพ์อยู่ → skip job นี้ (รอ timer รอบถัดไป)
      return;
    }

    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
    }

    try {
      // ⭐ ตรวจสอบว่าไฟล์ยังมีอยู่หรือไม่
      final file = File(job.filePath);
      if (!await file.exists()) {
        // ไฟล์หายไปแล้ว → mark as failed (ไม่มีทางกู้คืนได้)
        AppLogger.warning('[PrintQueueTimer] ⚠️ File not found: ${job.filePath}');
        await global.updatePrintJobStatus(fileName: job.fileName, status: PrintQueueStatus.failed, errorMessage: 'File not found: ${job.filePath}');
        return;
      }

      // หา printer config
      final printerIndex = global.printerLocalStrongData.indexWhere((p) => p.deviceName == job.printerName);

      if (printerIndex == -1) {
        // ⭐ Printer ไม่อยู่ใน config → keep pending, รอ retry รอบถัดไป
        if (kDebugMode) {
          AppLogger.warning('[PrintQueueTimer] ⏳ Printer not found: "${job.printerName}" - will retry in ${_retryInterval.inSeconds}s');
        }

        // อัพเดท lastAttemptAt เพื่อรอ 30 วินาทีก่อน retry
        await global.updatePrintJobStatus(fileName: job.fileName, status: PrintQueueStatus.pending, errorMessage: 'Printer not found: ${job.printerName}', updateLastAttempt: true);
        return;
      }

      final printer = global.printerLocalStrongData[printerIndex];

      // Update status to printing
      await global.updatePrintJobStatus(fileName: job.fileName, status: PrintQueueStatus.printing);

      if (kDebugMode) {
        final retryText = job.retryCount > 0 ? ' (Retry #${job.retryCount})' : '';
        AppLogger.debug('[PrintQueueTimer] 🖨️ Processing: ${job.fileName}$retryText');
        AppLogger.debug('Printer: ${job.printerName}');
        AppLogger.debug('Path: ${job.filePath}');
        AppLogger.debug('[Performance] Starting print operation...');
      }

      // ⭐ พิมพ์ใน Main Thread พร้อม timeout (30 วินาที)
      final printSuccess = await printFromFile(printerData: printer, pathName: job.filePath).timeout(
        _printTimeout,
        onTimeout: () {
          if (kDebugMode) {
            AppLogger.warning('[PrintQueueTimer] ⏱️ Print timeout after ${_printTimeout.inSeconds}s for "${job.fileName}"');
          }
          return false;
        },
      );

      if (printSuccess) {
        // ✅ พิมพ์สำเร็จ - Update status to completed
        await global.updatePrintJobStatus(fileName: job.fileName, status: PrintQueueStatus.completed);

        if (kDebugMode) {
          AppLogger.debug('[PrintQueueTimer] ✅ Completed: ${job.fileName}');
          if (stopwatch != null) {
            stopwatch.stop();
            AppLogger.success('[Performance] Print job "${job.fileName}" took ${stopwatch.elapsedMilliseconds}ms');
          }
        }

        // ⭐ ลดจำนวน Tier Stock หลังพิมพ์บิลสำเร็จ (เฉพาะ Pay Slip)
        _handleTierStockDecrement(job);

        // ⭐ ลบไฟล์ PNG ทันทีหลังพิมพ์เสร็จ (ไม่ต้องเก็บไว้)
        try {
          if (await file.exists()) {
            final fileSize = await file.length();
            await file.delete();

            if (kDebugMode) {
              final sizeKB = (fileSize / 1024).toStringAsFixed(2);
              AppLogger.debug('[PrintQueueTimer] 🗑️ Deleted print file: ${job.fileName} ($sizeKB KB)');
            }
          }
        } catch (deleteError) {
          // Log but don't fail the process if delete fails
          AppLogger.warning('[PrintQueueTimer] ⚠️ Failed to delete file ${job.fileName}: $deleteError');
        }
      } else {
        // ❌ พิมพ์ไม่สำเร็จ (แต่ไม่ throw error) - Keep pending เพื่อ retry
        if (kDebugMode) {
          AppLogger.warning('[PrintQueueTimer] ⚠️ Print failed for ${job.fileName} - will retry in ${_retryInterval.inSeconds}s');
        }
        await global.updatePrintJobStatus(
          fileName: job.fileName,
          status: PrintQueueStatus.pending,
          errorMessage: 'Print failed (printer not ready or disconnected)',
          updateLastAttempt: true,
        );
      }
    } catch (e, stackTrace) {
      // ⭐ เกิด error (connection fail, timeout, etc.)
      // → Unlock ทันที แล้วค่อย update status (ป้องกัน deadlock)
      if (kDebugMode) {
        AppLogger.error('❌ Error processing ${job.fileName}: $e');
        AppLogger.debug('Stack: $stackTrace');
        AppLogger.info('[PrintQueueTimer] ⏳ Will retry "${job.fileName}" in ${_retryInterval.inSeconds}s');
      }

      // ⭐ Unlock ก่อน (ป้องกัน updatePrintJobStatus ค้าง)
      _unlockPrinter(job.printerName);

      // Safe update status (wrapped in try-catch)
      try {
        await global.updatePrintJobStatus(fileName: job.fileName, status: PrintQueueStatus.pending, errorMessage: e.toString(), updateLastAttempt: true);
      } catch (updateError) {
        if (kDebugMode) {
          AppLogger.error('[PrintQueueTimer] ⚠️ Failed to update status: $updateError');
        }
      }

      // ส่ง error ไป dev team เฉพาะ retry ครั้งที่ 5+ เพื่อไม่ให้ spam
      if (job.retryCount >= 5 && job.retryCount % 5 == 0) {
        global.sendErrorToDevTeam('PrintQueueTimer', 'Print job retry #${job.retryCount}: ${job.fileName}\n$e\n$stackTrace');
      }

      return; // Exit early (already unlocked)
    } finally {
      // ⭐ Guard: ปลดล็อก printer เฉพาะถ้ายัง lock อยู่
      if (_printerLocks[job.printerName] == true) {
        _unlockPrinter(job.printerName);
      }
    }
  }

  /// ลดจำนวน Tier Stock หลังพิมพ์บิลสำเร็จ
  ///
  /// ตรวจสอบ metadata ว่ามี tierLevel หรือไม่
  /// ถ้ามี จะเรียก decrementTierStock()
  void _handleTierStockDecrement(PrintQueueObjectBoxStruct job) {
    try {
      // ต้องเป็น Pay Slip เท่านั้น
      if (job.jobType != 'receipt') {
        return;
      }

      // Parse metadata JSON
      if (job.metadata.isEmpty) {
        return;
      }

      final metadata = json.decode(job.metadata) as Map<String, dynamic>;

      // ตรวจสอบว่ามี isPaySlip และเป็น true
      final isPaySlip = metadata['isPaySlip'] as bool? ?? false;
      if (!isPaySlip) {
        return;
      }

      // ตรวจสอบว่ามี tierLevel หรือไม่
      final tierLevel = metadata['tierLevel'] as int?;
      if (tierLevel == null || tierLevel < 1 || tierLevel > 5) {
        return;
      }

      // ⭐ ลดจำนวน Tier Stock
      final remainingStock = global.decrementTierStock(tierLevel);

      if (kDebugMode) {
        if (remainingStock >= 0) {
          AppLogger.success('[TierStock] ✅ Decremented Tier $tierLevel → $remainingStock remaining');
        } else {
          AppLogger.warning('[TierStock] ⚠️ Failed to decrement Tier $tierLevel');
        }
      }
    } catch (e) {
      // ไม่ throw error เพราะไม่อยากให้กระทบการพิมพ์
      if (kDebugMode) {
        AppLogger.warning('[TierStock] ⚠️ Error handling tier stock: $e');
      }
    }
  }
}

/// Global instance
final printQueueTimerManager = PrintQueueTimerManager();
