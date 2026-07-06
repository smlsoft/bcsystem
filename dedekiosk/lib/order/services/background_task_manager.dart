import 'dart:async';
import 'package:dedekiosk/order/models/background_task_data.dart';
import 'package:dedekiosk/util/logger.dart';
import 'package:flutter/foundation.dart';

/// ผู้จัดการ Background Task พร้อมระบบ Cancellation
/// ช่วยป้องกันปัญหา race condition เมื่อ user ทำ order ใหม่ก่อน background task เสร็จ
class BackgroundTaskManager {
  static final BackgroundTaskManager _instance =
      BackgroundTaskManager._internal();
  factory BackgroundTaskManager() => _instance;
  BackgroundTaskManager._internal();

  /// Map เก็บ CancellationToken ตาม orderDocNumber
  final Map<String, CancellationToken> _activeTasks = {};

  /// Notifier สำหรับให้ UI ฟังจำนวน task ที่กำลังทำงาน
  /// ใช้ ValueListenableBuilder เพื่อ enable/disable ปุ่ม start-order บนหน้า home
  /// ขณะที่ background saveTransaction ยังทำงานอยู่
  final ValueNotifier<int> activeTaskCountNotifier = ValueNotifier<int>(0);

  /// สร้าง CancellationToken ใหม่สำหรับ order
  CancellationToken createToken(String orderDocNumber) {
    // ยกเลิก task เก่าถ้ามี (กรณี order ใหม่มาก่อน task เก่าเสร็จ)
    cancelTask(orderDocNumber);

    final token = CancellationToken(orderDocNumber);
    _activeTasks[orderDocNumber] = token;
    _notifyCountChanged();

    Logger.d('BackgroundTaskManager: Created token for $orderDocNumber');
    return token;
  }

  /// ยกเลิก task ตาม orderDocNumber
  void cancelTask(String orderDocNumber) {
    final token = _activeTasks[orderDocNumber];
    if (token != null && !token.isCancelled) {
      token.cancel();
      Logger.d('BackgroundTaskManager: Cancelled task for $orderDocNumber');
    }
    if (_activeTasks.remove(orderDocNumber) != null) {
      _notifyCountChanged();
    }
  }

  /// ยกเลิก task ทั้งหมด (เรียกตอน logout หรือ app terminate)
  void cancelAllTasks() {
    for (var token in _activeTasks.values) {
      if (!token.isCancelled) {
        token.cancel();
      }
    }
    _activeTasks.clear();
    _notifyCountChanged();
    Logger.d('BackgroundTaskManager: Cancelled all tasks');
  }

  /// ลบ token ที่เสร็จแล้ว
  void removeToken(String orderDocNumber) {
    if (_activeTasks.remove(orderDocNumber) != null) {
      _notifyCountChanged();
    }
    Logger.d('BackgroundTaskManager: Removed token for $orderDocNumber');
  }

  /// ตรวจสอบว่ามี task ที่กำลังทำงานอยู่หรือไม่
  bool hasActiveTask(String orderDocNumber) {
    final token = _activeTasks[orderDocNumber];
    return token != null && !token.isCancelled;
  }

  /// จำนวน task ที่กำลังทำงาน
  int get activeTaskCount => _activeTasks.length;

  /// อัพเดท ValueNotifier ให้ UI ที่ฟังอยู่รับรู้การเปลี่ยนแปลง
  /// (ป้องกัน redundant notification — ค่าเท่าเดิมไม่ต้องแจ้ง)
  void _notifyCountChanged() {
    if (activeTaskCountNotifier.value != _activeTasks.length) {
      activeTaskCountNotifier.value = _activeTasks.length;
    }
  }
}

/// Token สำหรับยกเลิก Background Task
class CancellationToken {
  final String orderDocNumber;
  bool _isCancelled = false;
  final Completer<void> _cancelCompleter = Completer<void>();

  CancellationToken(this.orderDocNumber);

  /// ตรวจสอบว่าถูกยกเลิกหรือยัง
  bool get isCancelled => _isCancelled;

  /// Future ที่จะ complete เมื่อถูกยกเลิก
  Future<void> get whenCancelled => _cancelCompleter.future;

  /// ยกเลิก task
  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      if (!_cancelCompleter.isCompleted) {
        _cancelCompleter.complete();
      }
    }
  }

  /// ตรวจสอบและ throw exception ถ้าถูกยกเลิก
  void throwIfCancelled() {
    if (_isCancelled) {
      throw TaskCancelledException(orderDocNumber);
    }
  }
}

/// Exception เมื่อ task ถูกยกเลิก
class TaskCancelledException implements Exception {
  final String orderDocNumber;
  TaskCancelledException(this.orderDocNumber);

  @override
  String toString() => 'Task cancelled for order: $orderDocNumber';
}

/// Extension สำหรับรัน Future พร้อม cancellation check
extension CancellableFuture<T> on Future<T> {
  /// รัน Future พร้อมตรวจสอบ cancellation
  Future<T> withCancellation(CancellationToken token) async {
    token.throwIfCancelled();

    // Race ระหว่าง task จริง กับ cancellation
    final result = await Future.any<T>([
      this,
      token.whenCancelled
          .then((_) => throw TaskCancelledException(token.orderDocNumber)),
    ]);

    token.throwIfCancelled();
    return result;
  }
}

/// Helper class สำหรับรัน Background Task พร้อม cancellation
class CancellableBackgroundTask {
  final CancellationToken token;
  final BackgroundTaskData data;

  CancellableBackgroundTask({
    required this.token,
    required this.data,
  });

  /// รัน task พร้อมตรวจสอบ cancellation ในแต่ละ step
  Future<void> run(Future<void> Function(CancellationToken token) task) async {
    try {
      token.throwIfCancelled();
      await task(token);
    } on TaskCancelledException catch (e) {
      Logger.d('CancellableBackgroundTask: ${e.toString()}');
      rethrow;
    } finally {
      // ลบ token เมื่อเสร็จ (ไม่ว่าจะสำเร็จหรือยกเลิก)
      BackgroundTaskManager().removeToken(data.orderDocNumber);
    }
  }
}
