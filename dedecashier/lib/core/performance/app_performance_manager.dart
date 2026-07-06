import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

/// จัดการ Performance ของแอปทั้งหมด
/// รวม Timer ทุกตัวเป็นตัวเดียวเพื่อลด CPU usage
class AppPerformanceManager {
  static AppPerformanceManager? _instance;
  static AppPerformanceManager get instance => _instance ??= AppPerformanceManager._();

  AppPerformanceManager._();

  Timer? _mainTimer;
  int _timerCounter = 0;
  bool _isRunning = false;

  // 🗄️ Cache สำหรับ IP Printer Status (ลด timeout checks)
  static final Map<String, _PrinterHealthCache> _printerHealthCache = {};

  // ValueNotifiers สำหรับ State Management แทน setState
  static final ValueNotifier<bool> printerStatusNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String> errorMessageNotifier = ValueNotifier<String>('');
  static final ValueNotifier<bool> networkStatusNotifier = ValueNotifier<bool>(true);
  static final ValueNotifier<Map<String, bool>> printerDetailStatusNotifier = ValueNotifier<Map<String, bool>>({});
  static final ValueNotifier<DateTime> lastUpdateNotifier = ValueNotifier<DateTime>(DateTime.now());

  // 🔔 Notification System
  static final ValueNotifier<_PrinterNotification?> printerNotificationNotifier = ValueNotifier<_PrinterNotification?>(null);
  static DateTime? _lastNotificationTime;
  static const Duration _notificationCooldown = Duration(seconds: 5); // ⚡ เตือนซ้ำทุก 5 วินาที

  /// เริ่มต้น Performance Manager
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _timerCounter = 0;

    // ⚡ เปลี่ยนเป็น 5 วินาที เพื่อให้ตรวจเครื่องพิมพ์บ่อยขึ้น (responsive)
    _mainTimer = Timer.periodic(const Duration(seconds: 5), _onTimerTick);
  }

  /// หยุด Performance Manager
  void stop() {
    _mainTimer?.cancel();
    _mainTimer = null;
    _isRunning = false;
    _timerCounter = 0;

    AppLogger.debug('AppPerformanceManager stopped');
  }

  /// Callback ของ Timer หลัก
  Future<void> _onTimerTick(Timer timer) async {
    _timerCounter++;

    try {
      // อัพเดทเวลา
      lastUpdateNotifier.value = DateTime.now();

      // ตรวจ Network ทุก 4 รอบ (ทุกๆ 20 วินาที - 5s x 4)
      if (_timerCounter % 4 == 0) {
        _checkNetworkStatusInBackground(); // ไม่ await
      }

      // ⭐ ตรวจเครื่องพิมพ์ทุก 6 รอบ (ทุกๆ 30 วินาที - ลดความถี่เพื่อไม่ให้ printer ค้าง)
      // หมายเหตุ: การ connect/disconnect บ่อยเกินไปทำให้ printer บางรุ่นค้าง
      if (_timerCounter % 6 == 0) {
        _checkPrinterStatusInBackground(); // ไม่ await
      }

      // ตรวจ Error ทุก 3 รอบ (ทุกๆ 15 วินาที - 5s x 3)
      if (_timerCounter % 3 == 0) {
        _checkErrorMessagesInBackground(); // ไม่ await
      }

      // Memory cleanup ทุก 60 รอบ (ทุกๆ 5 นาที - 5s x 60)
      if (_timerCounter % 60 == 0) {
        _performMemoryCleanupInBackground(); // ไม่ await
      }
    } catch (e) {
      AppLogger.error('AppPerformanceManager timer error: $e');
    }
  }

  /// ตรวจสอบสถานะเครื่องพิมพ์แบบ Optimized
  Future<void> _checkPrinterStatus() async {
    if (global.printerLocalStrongData.isEmpty) {
      printerStatusNotifier.value = false;
      return;
    }
    Map<String, bool> printerDetails = {};
    bool anyPrinterReady = false;

    // ตรวจเฉพาะเครื่องพิมพ์ที่ config แล้ว
    List<Future<void>> printerChecks = [];

    for (int i = 0; i < global.printerLocalStrongData.length; i++) {
      PrinterLocalStrongDataModel printer = global.printerLocalStrongData[i];

      // ✅ Skip เครื่องพิมพ์ที่ยังไม่ได้ config (ไม่นับเป็น offline)
      if (!printer.isConfigConnectSuccess) {
        continue;
      }

      // ใช้ Future.timeout เพื่อป้องกัน hang
      printerChecks.add(
        _testSinglePrinter(printer, i).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            global.printerLocalStrongData[i].isReady = false;
            printerDetails[printer.deviceName] = false;
          },
        ),
      );
    } // รอให้ตรวจเครื่องพิมพ์ทั้งหมดเสร็จ (แบบ parallel)
    await Future.wait(printerChecks);

    // อัพเดทสถานะเฉพาะเครื่องที่ config แล้ว
    for (var printer in global.printerLocalStrongData) {
      // ✅ นับเฉพาะเครื่องที่ config แล้ว
      if (printer.isConfigConnectSuccess) {
        printerDetails[printer.deviceName] = printer.isReady;
        if (printer.isReady) anyPrinterReady = true;
      }
    }

    // อัพเดท ValueNotifiers
    final previousStatus = printerStatusNotifier.value;
    printerStatusNotifier.value = anyPrinterReady;

    // 🔔 ส่ง notification เสมอเมื่อมีเครื่องพิมพ์ offline
    // (ไม่ต้องรอให้สถานะเปลี่ยน - เตือนซ้ำทุกครั้งที่ตรวจพบ)
    _sendPrinterNotification(previousStatus: previousStatus, currentStatus: anyPrinterReady, printerDetails: printerDetails);

    printerDetailStatusNotifier.value = Map.from(printerDetails);

    AppLogger.debug('Printer status check completed - Any ready: $anyPrinterReady');
  }

  /// ตรวจสอบ Network ใน Background (ไม่ block main thread)
  void _checkNetworkStatusInBackground() {
    Future.microtask(() async {
      try {
        bool isOnline = await global.hasNetwork(timeoutDuration: const Duration(seconds: 2));

        if (networkStatusNotifier.value != isOnline) {
          networkStatusNotifier.value = isOnline;
          global.isOnline = isOnline;
        }
      } catch (e) {
        networkStatusNotifier.value = false;
        global.isOnline = false;
        AppLogger.error('Network status check failed: $e');
      }
    });
  }

  /// ตรวจเครื่องพิมพ์ใน Background (ไม่ block main thread)
  void _checkPrinterStatusInBackground() {
    Future.microtask(() async {
      await _checkPrinterStatus();
    });
  }

  /// ตรวจสอบ Error Messages ใน Background
  void _checkErrorMessagesInBackground() {
    Future.microtask(() async {
      await _checkErrorMessages();
    });
  }

  /// ทำความสะอาด Memory ใน Background
  void _performMemoryCleanupInBackground() {
    Future.microtask(() async {
      await _performMemoryCleanup();
    });
  }

  /// ตรวจเครื่องพิมพ์ตัวเดียวแบบ optimized
  Future<void> _testSinglePrinter(PrinterLocalStrongDataModel printer, int index) async {
    try {
      switch (printer.printerConnectType) {
        case global.PrinterConnectEnum.ip:
          await _testIpPrinterOptimized(printer, index);
          break;
        case global.PrinterConnectEnum.bluetooth:
        case global.PrinterConnectEnum.usb:
          await _testBluetoothUsbPrinterOptimized(printer, index);
          break;
        case global.PrinterConnectEnum.windows:
          await _testWindowsPrinterOptimized(printer, index);
          break;
        default:
          global.printerLocalStrongData[index].isReady = false;
      }
    } catch (e) {
      global.printerLocalStrongData[index].isReady = false;
      AppLogger.error('Printer test error for ${printer.deviceName}: $e');
    }
  }

  /// ทดสอบ IP Printer แบบ optimized พร้อม cache และ retry
  Future<void> _testIpPrinterOptimized(PrinterLocalStrongDataModel printer, int index) async {
    if (printer.ipAddress.isEmpty || printer.ipPort <= 0) {
      global.printerLocalStrongData[index].isReady = false;
      return;
    }

    final cacheKey = '${printer.ipAddress}:${printer.ipPort}';
    final cachedHealth = _printerHealthCache[cacheKey];

    // ⚡ Skip check ถ้าเช็คไปไม่นานและ offline (ประหยัดเวลา)
    if (cachedHealth != null && !cachedHealth.isHealthy && cachedHealth.shouldSkipCheck()) {
      global.printerLocalStrongData[index].isReady = false;

      if (kDebugMode) {
        AppLogger.debug(
          '[Printer] ⏭️ Skipped check for ${printer.deviceName} '
          '(offline ${DateTime.now().difference(cachedHealth.lastCheckTime).inSeconds}s ago)',
        );
      }
      return;
    }

    // ดึง adaptive timeout จาก cache
    final timeout = cachedHealth?.adaptiveTimeout ?? const Duration(seconds: 2);

    Socket? socket;
    bool isHealthy = false;
    int attemptCount = 0;
    const maxAttempts = 2; // ลองสูงสุด 2 ครั้ง

    // 🔄 Retry Loop
    while (attemptCount < maxAttempts && !isHealthy) {
      attemptCount++;

      try {
        if (kDebugMode && attemptCount > 1) {
          AppLogger.debug('[Printer] 🔄 Retry #$attemptCount for ${printer.deviceName}');
        }

        socket = await Socket.connect(printer.ipAddress, printer.ipPort, timeout: timeout);

        // ⭐ รอสักครู่ก่อนปิด connection เพื่อไม่ให้ printer ค้าง
        await Future.delayed(const Duration(milliseconds: 100));

        // ✅ Success!
        isHealthy = true;
        global.printerLocalStrongData[index].isReady = true;
        global.printerLocalStrongData[index].isConfigConnectSuccess = true;

        if (kDebugMode) {
          AppLogger.debug(
            '[Printer] ✅ Connected to ${printer.deviceName} '
            '(${timeout.inMilliseconds}ms timeout)',
          );
        }
      } on SocketException catch (e) {
        // ❌ Timeout หรือ Connection Failed
        global.printerLocalStrongData[index].isReady = false;

        // Log เฉพาะครั้งสุดท้าย
        if (attemptCount >= maxAttempts) {
          if (kDebugMode) {
            AppLogger.error(
              '[Printer] ❌ ${printer.deviceName} offline after $attemptCount attempts '
              '(${e.osError?.errorCode ?? 'unknown'})',
            );
          } else {
            // Production: Log แค่ครั้งแรกที่ fail
            if (cachedHealth == null || cachedHealth.consecutiveFailures == 0) {
              AppLogger.error('IP Printer ${printer.deviceName} offline: ${e.message}');
            }
          }
        }

        // ถ้ายังมีโอกาส retry ให้รอสักครู่
        if (attemptCount < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        global.printerLocalStrongData[index].isReady = false;

        if (attemptCount >= maxAttempts) {
          AppLogger.error('IP Printer ${printer.deviceName} error: $e');
        }
      } finally {
        try {
          socket?.close();
          socket = null;
        } catch (e) {
          // Ignore close errors
        }
      }
    }

    // 💾 อัพเดท cache
    _printerHealthCache[cacheKey] =
        cachedHealth?.withResult(isHealthy: isHealthy, incrementFailure: true) ??
        _PrinterHealthCache(isHealthy: isHealthy, lastCheckTime: DateTime.now(), consecutiveFailures: isHealthy ? 0 : 1);

    // 📊 แสดง cache stats ทุกๆ 10 ครั้ง
    if (kDebugMode && _timerCounter % 10 == 0) {
      final cache = _printerHealthCache[cacheKey];
      if (cache != null && !cache.isHealthy) {
        AppLogger.debug(
          '[Printer] 📊 ${printer.deviceName}: '
          'consecutive failures=${cache.consecutiveFailures}, '
          'timeout=${cache.adaptiveTimeout.inMilliseconds}ms',
        );
      }
    }
  }

  Future<void> _testBluetoothUsbPrinterOptimized(PrinterLocalStrongDataModel printer, int index) async {
    if (printer.deviceName.isNotEmpty) {
      global.printerLocalStrongData[index].isReady = true;
      global.printerLocalStrongData[index].isConfigConnectSuccess = true;
    } else {
      global.printerLocalStrongData[index].isReady = false;
    }
  }

  Future<void> _testWindowsPrinterOptimized(PrinterLocalStrongDataModel printer, int index) async {
    try {
      if (Platform.isWindows && printer.deviceName.isNotEmpty) {
        List<PrinterDeviceModel> windowsPrinters = global.windowsListPrinters();
        bool printerExists = windowsPrinters.any((p) => p.deviceName == printer.deviceName);

        global.printerLocalStrongData[index].isReady = printerExists;
        global.printerLocalStrongData[index].isConfigConnectSuccess = printerExists;
      } else {
        global.printerLocalStrongData[index].isReady = false;
      }
    } catch (e) {
      global.printerLocalStrongData[index].isReady = false;
      AppLogger.error('Windows Printer test error for ${printer.deviceName}: $e');
    }
  }

  Future<void> _checkErrorMessages() async {
    try {
      String currentError = '';

      if (!networkStatusNotifier.value) {
        currentError = 'No network connection';
      } else if (!printerStatusNotifier.value && global.printerLocalStrongData.isNotEmpty) {
        currentError = 'Printer not ready';
      }

      if (errorMessageNotifier.value != currentError) {
        errorMessageNotifier.value = currentError;
      }
    } catch (e) {
      AppLogger.error('Error message check failed: $e');
    }
  }

  Future<void> _performMemoryCleanup() async {
    try {
      AppImageCacheManager.cleanupOldCache();

      AppLogger.debug('Memory cleanup performed');
    } catch (e) {
      AppLogger.error('Memory cleanup error: $e');
    }
  }

  Future<void> forceUpdatePrinterStatus() async {
    await _checkPrinterStatus();
  }

  /// 🔔 ส่ง notification เมื่อสถานะเครื่องพิมพ์เปลี่ยน
  void _sendPrinterNotification({required bool previousStatus, required bool currentStatus, required Map<String, bool> printerDetails}) {
    final now = DateTime.now();

    // หา printers ที่ offline
    final offlinePrinters = printerDetails.entries.where((entry) => !entry.value).map((entry) => entry.key).toList();

    // 🐛 Debug logging
    if (kDebugMode) {
      AppLogger.debug(
        '📊 [Notification] previousStatus=$previousStatus, currentStatus=$currentStatus, '
        'offline=${offlinePrinters.length}/${printerDetails.length}',
      );
    }

    _PrinterNotification? notification;

    // ✅ กรณีที่ 1: เครื่องพิมพ์กลับมา online (เช็คก่อน!)
    if (currentStatus && !previousStatus) {
      notification = _PrinterNotification(message: 'เครื่องพิมพ์พร้อมใช้งานแล้ว', type: _PrinterNotificationType.success, affectedPrinters: []);

      AppLogger.info('🔔 Printer online notification: ${notification.message}');

      // 🔊 เล่นเสียงสำเร็จ
      global.playSound(sound: global.SoundEnum.beep);

      // ⚠️ Clear last notification time เพื่อให้เตือน offline ได้ทันทีถ้าเกิดซ้ำ
      _lastNotificationTime = null;
    }
    // ⚠️ กรณีที่ 2: เครื่องพิมพ์ offline อยู่
    else if (!currentStatus && offlinePrinters.isNotEmpty) {
      // เช็ค cooldown เฉพาะกรณี offline ซ้ำๆ (5 วินาที)
      if (_lastNotificationTime != null &&
          !previousStatus && // ถ้า offline อยู่แล้วตั้งแต่ก่อนหน้า
          now.difference(_lastNotificationTime!) < _notificationCooldown) {
        return; // ยังไม่ถึงเวลาเตือนซ้ำ
      }

      // ❌ เครื่องพิมพ์ offline (เตือนทุกครั้งหลัง cooldown)
      notification = _PrinterNotification(
        message: offlinePrinters.length == 1 ? 'เครื่องพิมพ์ ${offlinePrinters.first} ไม่พร้อมใช้งาน' : 'เครื่องพิมพ์ ${offlinePrinters.length} เครื่องไม่พร้อมใช้งาน',
        type: _PrinterNotificationType.error,
        affectedPrinters: offlinePrinters,
      );

      AppLogger.warning('🔔 Printer offline notification: ${notification.message}');

      // 🔊 เล่นเสียงเตือน error (เครื่องพิมพ์ offline)
      global.playSound(sound: global.SoundEnum.printerError);
    }
    // 🔇 กรณีที่ 3: เครื่องพิมพ์ online อยู่แล้ว (ไม่ต้องทำอะไร - debug log only)
    else if (currentStatus && previousStatus) {
      if (kDebugMode) {
        AppLogger.debug('✅ [Notification] All printers still online - no action');
      }
      return; // ไม่ต้องส่ง notification
    }

    if (notification != null) {
      printerNotificationNotifier.value = notification;
      _lastNotificationTime = now;

      // Auto clear หลัง 5 วินาที
      Future.delayed(const Duration(seconds: 5), () {
        if (printerNotificationNotifier.value == notification) {
          printerNotificationNotifier.value = null;
        }
      });
    }
  }

  bool get isPrinterReady => printerStatusNotifier.value;
  bool get isNetworkOnline => networkStatusNotifier.value;
  String get currentError => errorMessageNotifier.value;
  Map<String, bool> get printerDetails => printerDetailStatusNotifier.value;
}

class AppImageCacheManager {
  static final Map<String, ImageProvider> _assetCache = {};
  static final Map<String, ImageProvider> _networkCache = {};
  static DateTime _lastCleanup = DateTime.now();
  static const int maxCacheSize = 50;

  static ImageProvider getCachedAsset(String assetPath) {
    if (_assetCache.containsKey(assetPath)) {
      return _assetCache[assetPath]!;
    }

    if (_assetCache.length >= maxCacheSize) {
      _cleanupAssetCache();
    }

    _assetCache[assetPath] = AssetImage(assetPath);
    return _assetCache[assetPath]!;
  }

  /// Get cached network image provider
  static ImageProvider getCachedNetwork(String url) {
    if (_networkCache.containsKey(url)) {
      return _networkCache[url]!;
    }

    if (_networkCache.length >= maxCacheSize) {
      _cleanupNetworkCache();
    }

    _networkCache[url] = NetworkImage(url);
    return _networkCache[url]!;
  }

  /// Widget สำหรับ cached asset image
  static Widget cachedAssetImage(String assetPath, {double? width, double? height, BoxFit? fit}) {
    return Image(image: getCachedAsset(assetPath), width: width, height: height, fit: fit);
  }

  /// Widget สำหรับ cached network image
  static Widget cachedNetworkImage(String url, {double? width, double? height, BoxFit? fit, Widget? placeholder, Widget? errorWidget}) {
    return Image(
      image: getCachedNetwork(url),
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const CircularProgressIndicator();
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error);
      },
    );
  }

  /// ทำความสะอาด asset cache
  static void _cleanupAssetCache() {
    if (_assetCache.length > maxCacheSize ~/ 2) {
      final keys = _assetCache.keys.take(_assetCache.length ~/ 2).toList();
      for (final key in keys) {
        _assetCache.remove(key);
      }
    }
  }

  /// ทำความสะอาด network cache
  static void _cleanupNetworkCache() {
    if (_networkCache.length > maxCacheSize ~/ 2) {
      final keys = _networkCache.keys.take(_networkCache.length ~/ 2).toList();
      for (final key in keys) {
        _networkCache.remove(key);
      }
    }
  }

  /// ทำความสะอาด cache เก่า
  static void cleanupOldCache() {
    final now = DateTime.now();
    if (now.difference(_lastCleanup).inMinutes >= 10) {
      _cleanupAssetCache();
      _cleanupNetworkCache();
      _lastCleanup = now;

      AppLogger.debug('Image cache cleanup completed');
    }
  }

  /// ล้าง cache ทั้งหมด
  static void clearAll() {
    _assetCache.clear();
    _networkCache.clear();
    _lastCleanup = DateTime.now();
  }

  /// ขนาด cache ปัจจุบัน
  static int get assetCacheSize => _assetCache.length;
  static int get networkCacheSize => _networkCache.length;
}

/// 🗄️ Cache สำหรับเก็บสถานะ Printer Health
/// ลด timeout checks โดยเก็บผลลัพธ์ล่าสุด
class _PrinterHealthCache {
  final bool isHealthy;
  final DateTime lastCheckTime;
  final int consecutiveFailures;

  _PrinterHealthCache({required this.isHealthy, required this.lastCheckTime, this.consecutiveFailures = 0});

  /// เช็คว่าควร skip check หรือไม่ (ถ้าเช็คไปไม่นาน)
  bool shouldSkipCheck({Duration cooldown = const Duration(seconds: 30)}) {
    return DateTime.now().difference(lastCheckTime) < cooldown;
  }

  /// สร้าง cache ใหม่จากผลลัพธ์
  _PrinterHealthCache withResult({required bool isHealthy, bool incrementFailure = false}) {
    return _PrinterHealthCache(
      isHealthy: isHealthy,
      lastCheckTime: DateTime.now(),
      consecutiveFailures: isHealthy ? 0 : (incrementFailure ? consecutiveFailures + 1 : consecutiveFailures),
    );
  }

  /// ดึง adaptive timeout ตาม failure count
  Duration get adaptiveTimeout {
    // ถ้า fail บ่อย ให้ timeout เร็วขึ้น (ประหยัดเวลา)
    if (consecutiveFailures >= 3) {
      return const Duration(milliseconds: 500);
    } else if (consecutiveFailures >= 1) {
      return const Duration(seconds: 1);
    }
    return const Duration(seconds: 2);
  }
}

/// 🔔 Notification Model สำหรับแจ้งเตือนเครื่องพิมพ์
class _PrinterNotification {
  final String message;
  final _PrinterNotificationType type;
  final DateTime timestamp;
  final List<String> affectedPrinters;

  _PrinterNotification({required this.message, required this.type, required this.affectedPrinters}) : timestamp = DateTime.now();

  /// สี notification ตาม type
  Color get color {
    switch (type) {
      case _PrinterNotificationType.error:
        return Colors.red.shade700;
      case _PrinterNotificationType.warning:
        return Colors.orange.shade700;
      case _PrinterNotificationType.success:
        return Colors.green.shade700;
    }
  }

  /// ไอคอน notification
  IconData get icon {
    switch (type) {
      case _PrinterNotificationType.error:
        return Icons.print_disabled;
      case _PrinterNotificationType.warning:
        return Icons.warning_amber;
      case _PrinterNotificationType.success:
        return Icons.check_circle;
    }
  }
}

enum _PrinterNotificationType { error, warning, success }

/// 🔔 Widget แสดง Notification แบบ Non-Intrusive
/// วางไว้ใน MaterialApp หรือ Scaffold root
class PrinterNotificationOverlay extends StatelessWidget {
  const PrinterNotificationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_PrinterNotification?>(
      valueListenable: AppPerformanceManager.printerNotificationNotifier,
      builder: (context, notification, child) {
        if (notification == null) return const SizedBox.shrink();

        return Positioned(
          bottom: 80,
          left: 16,
          right: 16,
          child: SafeArea(child: _NotificationCard(notification: notification)),
        );
      },
    );
  }
}

/// การ์ดแสดง notification
class _NotificationCard extends StatefulWidget {
  final _PrinterNotification notification;

  const _NotificationCard({required this.notification});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: widget.notification.color,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // ปิด notification เมื่อแตะ
              AppPerformanceManager.printerNotificationNotifier.value = null;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.notification.icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.notification.message,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if (widget.notification.affectedPrinters.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.notification.affectedPrinters.join(', '),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.close, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔴 Status Indicator Widget - แสดงไอคอนมุมจอ
/// ใช้ใน AppBar หรือ Scaffold
class PrinterStatusIndicator extends StatelessWidget {
  final double size;
  final EdgeInsets padding;

  const PrinterStatusIndicator({super.key, this.size = 24, this.padding = const EdgeInsets.all(8)});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppPerformanceManager.printerStatusNotifier,
      builder: (context, isPrinterReady, child) {
        return ValueListenableBuilder<Map<String, bool>>(
          valueListenable: AppPerformanceManager.printerDetailStatusNotifier,
          builder: (context, printerDetails, _) {
            if (printerDetails.isEmpty) return const SizedBox.shrink();

            final offlineCount = printerDetails.values.where((ready) => !ready).length;

            return Padding(
              padding: padding,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.print, size: size, color: isPrinterReady ? Colors.green : Colors.red),
                  if (offlineCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$offlineCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
