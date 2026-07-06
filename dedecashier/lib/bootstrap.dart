import 'dart:ui';
import 'dart:isolate';

import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/api/clickhouse/clickhouse_api.dart' as api;
import 'package:dedecashier/api/sync/sync_bill.dart';
import 'package:dedecashier/services/file_cleanup_service.dart';
import 'package:dedecashier/bootstrap_print_helper.dart';
import 'package:dedecashier/bootstrap_print_compute_worker.dart';
import 'package:dedecashier/bootstrap_print_timer_manager.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dedecashier/app/http_verify.dart';
import 'package:dedecashier/core/environment.dart';
import 'package:dedecashier/core/objectbox.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:dedecashier/model/objectbox/print_queue_struct.dart';
import 'package:dedecashier/objectbox.g.dart'; // ⭐ สำหรับ Store, Query, Order
import 'package:dedecashier/util/printer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dedecashier/widgets/display.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/bootstrap_online_orders_timer_manager.dart';
import 'package:dedecashier/bootstrap_system_process_timer_manager.dart';

// ⭐ Global variables for App State Management
bool _isAppActive = true;

// ⭐ [DEPRECATED] Isolate variables - Now using Timer Managers instead
// Kept for backward compatibility to prevent compile errors
Isolate? _printQueueIsolate;
bool _printQueueIsolateRunning = false;
SendPort? _printQueueIsolateSendPort;
ReceivePort? _printQueueMainReceivePort;
Isolate? _onlineOrdersIsolate;
bool _onlineOrdersIsolateRunning = false;
Isolate? _systemProcessIsolate;
bool _systemProcessIsolateRunning = false;

void bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  await runZonedGuarded(() async {
    runApp(await builder());
  }, (error, stackTrace) => log(error.toString(), stackTrace: stackTrace));
}

Future<void> initializeApp() async {
  HttpOverrides.global = MyHttpOverrides();
  await setupDisplay();
  await objectBoxInit();

  // ⭐ โหลดค่าเสียง beep จาก SharedPreferences ก่อนเริ่ม app
  await global.loadSoundSetting();

  // ⭐ Preload เสียงทั้งหมดตอนเริ่ม app (ไม่มี delay ตอนเล่น)
  AppLogger.debug('🔊 [Bootstrap] Starting sound preload...');
  global.preloadAllSounds().catchError((e) {
    AppLogger.debug('⚠️ [Bootstrap] Sound preload failed: $e');
  });
  // ⭐ ไม่ await เพื่อไม่ให้ app ช้า - โหลดเสียงแบบ background

  if (kDebugMode) {
    // Debug Mode สร้าง json จาก google sheet (จะไม่ทำงานทันที เพราะสร้าง source code ต้อง rerun ใหม่)
    /*await googleMultiLanguageSheetLoad().then((_) async {
      String json = jsonEncode(global.languageSystemCode);
      File file = File(jsonLanguageFileName);
      file.writeAsString(json);
    });*/
  }
  // release load ภาษาจาก assets (mode release)
  try {
    global.languageSystemCode = (json.decode(await rootBundle.loadString(global.jsonLanguageFileName)) as List).map((i) => LanguageSystemCodeModel.fromJson(i)).toList();
  } catch (ex) {
    AppLogger.debug(ex.toString());
  }
  global.languageSelect(global.userScreenLanguage);
  if (Platform.isAndroid) {
    global.getListOfAvailableDrivers();
  }

  await setUpServiceLocator();
}

Future<void> initializeEnvironmentConfig() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = "th";
  switch (global.posVersion) {
    case global.PosVersionEnum.vfpos:
      global.applicationName = "Vf Pos";
      break;
    case global.PosVersionEnum.pos:
      global.applicationName = "BC Pos";
      break;
    case global.PosVersionEnum.restaurant:
      global.applicationName = "BC Cashier";
      break;
    case global.PosVersionEnum.smlmobilepos:
      global.applicationName = "Sml Mobile Pos";
      break;
    case global.PosVersionEnum.marinepos:
      global.applicationName = "Marine POS";
      break;
  }

  if (Platform.isAndroid) {
    try {
      await [
        Permission.camera,
        Permission.storage,
        Permission.photos,
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.mediaLibrary,
        Permission.speech,
        Permission.manageExternalStorage,
        Permission.location,
        Permission.locationWhenInUse,
        Permission.microphone,
        Permission.notification,
        Permission.activityRecognition,
      ].request();
    } catch (ex) {
      AppLogger.debug(ex.toString());
    }
  }
  const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: Environment.DEV);
  Environment().initConfig(environment);

  await GetStorage.init();
  global.appStorage = GetStorage();
  //
  try {
    global.userScreenLanguage = GetStorage().read("language");
  } catch (ex) {
    global.userScreenLanguage = "th";
  }
  global.applicationDocumentsDirectory = await getApplicationDocumentsDirectory();
  // Sync Server
  await global.startLoading();

  // ⭐ Initialize Print Queue Management (Isolate-based)
  _initializePrintQueueManager();

  // ⭐ Initialize Online Orders Management (Isolate-based)
  _initializeOnlineOrdersManager();

  // ⭐ Initialize System Process Management (Isolate-based)
  _initializeSystemProcessManager();

  if (Platform.isAndroid || Platform.isIOS) {
    // Load เสียง
    /*BeepPlayer.load(global.beepScanSuccess);
    BeepPlayer.load(global.beepScanFail);
    BeepPlayer.load(global.beepButtonTing);*/
  }

  // Sync Bill to Mongo
  SyncBill().startSync();

  // ⭐ Start File Cleanup Service (ทำความสะอาดไฟล์รูปภาพเก่า > 7 วัน)
  fileCleanupService.start();

  //global.flutterTts = FlutterTts();
  global.speak("เริ่มต้นการทำงาน");
}

// ⭐ ============================================================================
// ⭐ ISOLATE-BASED PRINT QUEUE PROCESSING
// ⭐ [NOTE] Deprecated but kept for reference - Now using Timer Manager instead
// ⭐ ============================================================================

/// Print Queue Isolate Worker
/// ทำงานใน background thread แยกจาก main UI thread
void _printQueueIsolateWorker(Map<String, dynamic> params) async {
  final SendPort mainSendPort = params['sendPort'] as SendPort;
  final String tempPath = params['tempPath'] as String;
  final String dbPath = params['dbPath'] as String; // ⭐ ObjectBox directory path

  if (kDebugMode) {
    AppLogger.debug('[PrintQueue Isolate] 🚀 Worker started (INDEPENDENT MODE)');
    AppLogger.debug('[PrintQueue Isolate] 📂 Temp path: $tempPath');
    AppLogger.debug('[PrintQueue Isolate] 💾 DB path: $dbPath');
  }

  // ⭐ สร้าง ReceivePort สำหรับรับคำสั่ง shutdown
  final isolateReceivePort = ReceivePort();
  mainSendPort.send(isolateReceivePort.sendPort);

  // ⭐ เปิด ObjectBox Store ด้วย Store.attach()
  Store? store;
  try {
    store = Store.attach(getObjectBoxModel(), dbPath);
    AppLogger.debug('[PrintQueue Isolate] ✅ ObjectBox Store attached successfully');
  } catch (e) {
    AppLogger.error('[PrintQueue Isolate] ❌ Failed to attach ObjectBox Store: $e');
    mainSendPort.send({
      'status': 'error',
      'data': {'message': 'Failed to attach ObjectBox: $e'},
    });
    return;
  }

  // ⭐ In-memory cache สำหรับเก็บ printer configs
  final Map<String, Map<String, dynamic>> printersCache = {};
  bool shouldRun = true;

  // ⭐ รับคำสั่งจาก Main Thread (เฉพาะ init และ shutdown)
  isolateReceivePort.listen((message) {
    if (message is Map<String, dynamic>) {
      final messageType = message['type'] as String? ?? '';
      final messageData = message['data'] as Map<String, dynamic>? ?? {};

      switch (messageType) {
        case 'init':
          // รับ printer configs
          final printers = messageData['printers'] as List<dynamic>;
          for (var printer in printers) {
            final printerMap = printer as Map<String, dynamic>;
            printersCache[printerMap['deviceName']] = printerMap;
          }
          if (kDebugMode) {
            AppLogger.success('[PrintQueue Isolate] ✅ Initialized with ${printersCache.length} printers');
            AppLogger.debug('[PrintQueue Isolate]    Printers: ${printersCache.keys.join(", ")}');
          }
          mainSendPort.send({
            'status': 'ready',
            'data': {'printersCount': printersCache.length},
          });
          break;

        case 'update_printer':
          final printerData = messageData;
          printersCache[printerData['deviceName']] = printerData;
          AppLogger.debug('[PrintQueue Isolate] ✏️ Updated printer: ${printerData['deviceName']}');
          break;

        case 'remove_printer':
          final printerName = messageData['deviceName'];
          printersCache.remove(printerName);
          AppLogger.debug('[PrintQueue Isolate] 🗑️ Removed printer: $printerName');
          break;

        case 'shutdown':
          shouldRun = false;
          AppLogger.debug('[PrintQueue Isolate] 🛑 Shutdown requested');
          break;
      }
    }
  });

  // ⭐ Main Loop - Query ObjectBox และพิมพ์
  while (shouldRun) {
    try {
      AppLogger.debug('[PrintQueue Isolate] 🔄 Checking for pending jobs...');

      // ⭐ Query ObjectBox สำหรับงานที่รอพิมพ์
      final box = store.box<PrintQueueObjectBoxStruct>();
      final query = box
          .query(PrintQueueObjectBoxStruct_.status.equals(0)) // pending
          .order(PrintQueueObjectBoxStruct_.priority, flags: Order.descending)
          .order(PrintQueueObjectBoxStruct_.createdAt)
          .build();

      final pendingJobs = query.find();
      query.close();

      if (pendingJobs.isNotEmpty) {
        AppLogger.debug('[PrintQueue Isolate] 📋 Found ${pendingJobs.length} pending jobs');

        for (var job in pendingJobs) {
          if (!shouldRun) break;

          // เช็คว่ามี printer config หรือไม่
          if (!printersCache.containsKey(job.printerName)) {
            AppLogger.debug('[PrintQueue Isolate] ⚠️ Printer not found: ${job.printerName}');
            // Update status to failed
            job.status = PrintQueueStatus.failed.value;
            job.errorMessage = 'Printer not found: ${job.printerName}';
            job.printedAt = DateTime.now();
            box.put(job);
            continue;
          }

          if (kDebugMode) {
            AppLogger.debug('[PrintQueue Isolate] 🖨️ Processing job: ${job.fileName}');
            AppLogger.debug('[PrintQueue Isolate]    Printer: ${job.printerName}');
            AppLogger.debug('[PrintQueue Isolate]    Doc: ${job.docNumber}');
          }

          // Update status to printing
          job.status = PrintQueueStatus.printing.value;
          box.put(job);

          // ⭐ พิมพ์งาน
          try {
            await processPrintJobAsync(job.fileName, job.printerName, job.filePath, printersCache, mainSendPort);

            // Update status to completed
            job.status = PrintQueueStatus.completed.value;
            job.printedAt = DateTime.now();
            job.errorMessage = '';
            box.put(job);

            AppLogger.debug('[PrintQueue Isolate] ✅ Job completed: ${job.fileName}');
          } catch (e) {
            // Update status to failed
            job.status = PrintQueueStatus.failed.value;
            job.errorMessage = e.toString();
            job.printedAt = DateTime.now();
            job.retryCount++;
            box.put(job);

            if (kDebugMode) {
              AppLogger.error('[PrintQueue Isolate] ❌ Job failed: ${job.fileName}');
              AppLogger.error('[PrintQueue Isolate]    Error: $e');
            }
          }
        }
      } else {
        AppLogger.debug('[PrintQueue Isolate] 😴 No pending jobs, sleeping...');
      }

      // รอ 3 วินาทีก่อนรอบถัดไป
      await Future.delayed(const Duration(seconds: 3));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        AppLogger.error('[PrintQueue Isolate] ❌ Loop error: $e');
        AppLogger.debug('[PrintQueue Isolate] Stack: $stackTrace');
      }

      global.sendErrorToDevTeam("bootstrap.dart->_printQueueIsolateWorker", "Print Queue Isolate Loop Error: $e\n${stackTrace.toString()}");

      // ถ้า error รอนาน 10 วินาที
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  // ⭐ ปิด ObjectBox Store ก่อนออก
  store.close();
  AppLogger.debug('[PrintQueue Isolate] 👋 Worker stopped, Store closed');
}

/// Process single printer folder with in-memory cache
Future<void> _processPrinterFolderWithCache(String folderPath, Map<String, Map<String, dynamic>> printersCache, SendPort mainSendPort) async {
  AppLogger.debug('[PrintQueue] 📂 Processing folder: ${folderPath.split('\\').last}');

  try {
    // ⭐ ดึงไฟล์ทั้งหมดจากโฟลเดอร์
    final files = await global.getFilesInFolderSortedByModifiedDate(folderPath);

    if (files.isEmpty) {
      AppLogger.debug('[PrintQueue]    ℹ️ No print jobs in folder');
      return;
    }

    if (kDebugMode) {
      AppLogger.debug('📄 Found ${files.length} print jobs:');
      for (var i = 0; i < files.length; i++) {
        AppLogger.debug('[PrintQueue]       ${i + 1}. ${files[i].path.split('\\').last}');
      }
    }

    // ⭐ หา printer config จาก cache แทน global.printerLocalStrongData
    final folderName = folderPath.split('\\').last;

    if (kDebugMode) {
      AppLogger.debug('🔍 Looking for printer: $folderName');
      AppLogger.debug('[PrintQueue]    Available in cache: ${printersCache.keys.join(", ")}');
    }

    final printerData = printersCache[folderName];

    if (printerData == null) {
      AppLogger.debug('[PrintQueue]    ❌ Printer not found in cache: $folderName');
      // ส่ง error กลับไป Main Thread
      mainSendPort.send({
        'status': 'error',
        'data': {'message': 'Printer not found in cache: $folderName', 'folder': folderName},
      });
      return;
    }

    if (kDebugMode) {
      AppLogger.debug('[PrintQueue]    🖨️ Printer: ${printerData['deviceName']}');
      AppLogger.debug('[PrintQueue]    Connection: ${printerData['printerConnectType']}');
      AppLogger.success('[PrintQueue]    Config Success: ${printerData['isConfigConnectSuccess']}');
      AppLogger.debug('[PrintQueue]    IP: ${printerData['ipAddress']}:${printerData['ipPort']}');
    }

    // ส่ง progress กลับไป Main Thread
    mainSendPort.send({
      'status': 'progress',
      'data': {'printer': printerData['deviceName'], 'jobsCount': files.length, 'status': 'processing'},
    });

    // ⭐ สร้าง PrinterLocalStrongDataModel object จาก cache data
    final printer = PrinterLocalStrongDataModel.fromJson(printerData);

    // ⭐ Print jobs ทีละไฟล์ (sequential - ปลอดภัยสำหรับ printer)
    int successCount = 0;
    int errorCount = 0;

    for (var i = 0; i < files.length; i++) {
      final job = files[i];
      try {
        AppLogger.debug('[PrintQueue]    🖨️ Printing job ${i + 1}/${files.length}: ${job.path.split('\\').last}');

        await printFromFile(printerData: printer, pathName: job.path);
        successCount++;

        AppLogger.debug('[PrintQueue]    ✅ Print job ${i + 1} completed');
      } catch (printError) {
        errorCount++;
        AppLogger.debug('[PrintQueue]    ❌ Print job ${i + 1} failed: $printError');
        // Continue กับไฟล์ถัดไป
      }
    }

    // ส่ง result กลับไป Main Thread
    mainSendPort.send({
      'status': 'success',
      'data': {'printer': printerData['deviceName'], 'totalJobs': files.length, 'successCount': successCount, 'errorCount': errorCount},
    });

    AppLogger.debug('[PrintQueue]    🎉 Jobs processed: $successCount success, $errorCount failed');
  } catch (e, stackTrace) {
    if (kDebugMode) {
      AppLogger.error('❌ Folder processing error: $e');
      AppLogger.debug('Stack: $stackTrace');
    }

    mainSendPort.send({
      'status': 'error',
      'data': {'message': e.toString(), 'folder': folderPath.split('\\').last, 'stackTrace': stackTrace.toString()},
    });

    global.sendErrorToDevTeam("bootstrap.dart->_processPrinterFolderWithCache", "Folder ${folderPath.split('\\').last}: $e\n${stackTrace.toString()}");
  }
}

/// Process single printer folder (DEPRECATED - ใช้ _processPrinterFolderWithCache แทน)
Future<void> _processPrinterFolder(String folderPath) async {
  AppLogger.debug('[PrintQueue] 📂 Processing folder: ${folderPath.split('\\').last}');

  try {
    // ⭐ ดึงไฟล์ทั้งหมดจากโฟลเดอร์
    final files = await global.getFilesInFolderSortedByModifiedDate(folderPath);

    if (files.isEmpty) {
      AppLogger.debug('[PrintQueue]    ℹ️ No print jobs in folder');
      return;
    }

    if (kDebugMode) {
      AppLogger.debug('📄 Found ${files.length} print jobs:');
      for (var i = 0; i < files.length; i++) {
        AppLogger.debug('[PrintQueue]       ${i + 1}. ${files[i].path.split('\\').last}');
      }
    }

    // ⭐ หา printer config จาก folder name
    final folderName = folderPath.split('\\').last;

    if (kDebugMode) {
      AppLogger.debug('🔍 Looking for printer: $folderName');
      AppLogger.debug('[PrintQueue]    Available printers: ${global.printerLocalStrongData.map((p) => p.deviceName).join(", ")}');
    }

    final printer = global.printerLocalStrongData.firstWhere((p) => p.deviceName == folderName, orElse: () => throw Exception('Printer not found: $folderName'));

    if (kDebugMode) {
      AppLogger.debug('🖨️ Printer: ${printer.deviceName}');
      AppLogger.debug('Connection: ${printer.printerConnectType}');
      AppLogger.success('[PrintQueue]    Config Success: ${printer.isConfigConnectSuccess}');
      AppLogger.debug('IP: ${printer.ipAddress}:${printer.ipPort}');
    }

    // ⭐ Print jobs ทีละไฟล์ (sequential - ปลอดภัยสำหรับ printer)
    for (var i = 0; i < files.length; i++) {
      final job = files[i];
      try {
        AppLogger.debug('[PrintQueue]    🖨️ Printing job ${i + 1}/${files.length}: ${job.path.split('\\').last}');

        await printFromFile(printerData: printer, pathName: job.path);

        AppLogger.debug('[PrintQueue]    ✅ Print job ${i + 1} completed');
      } catch (printError) {
        AppLogger.debug('[PrintQueue]    ❌ Print job ${i + 1} failed: $printError');
        // Continue กับไฟล์ถัดไป
      }
    }

    AppLogger.debug('[PrintQueue]    🎉 All jobs processed for ${printer.deviceName}');
  } catch (e, stackTrace) {
    if (kDebugMode) {
      AppLogger.error('❌ Folder processing error: $e');
      AppLogger.debug('Stack: $stackTrace');
    }

    global.sendErrorToDevTeam("bootstrap.dart->_processPrinterFolder", "Folder ${folderPath.split('\\').last}: $e\n${stackTrace.toString()}");
  }
}

/// Process single printer queue (DEPRECATED - ใช้ _processPrinterFolder แทน)
Future<void> _processPrinterQueue(PrinterLocalStrongDataModel printer, [String? tempPath]) async {
  final name = global.filePath(printer.deviceName);

  // ⭐ สร้าง absolute path ถ้ามี tempPath
  final folderPath = tempPath != null ? '$tempPath/$name' : name;

  if (kDebugMode) {
    AppLogger.debug('📂 Processing printer: ${printer.deviceName}');
    AppLogger.debug('Folder path: $folderPath');
  }

  try {
    // สร้าง temp folder
    await global.createTempFolder(folderPath);

    AppLogger.debug('[PrintQueue]    ✅ Temp folder created/verified');

    // ⭐ ดึงไฟล์ทั้งหมด (file I/O ใน background) - ใช้ absolute path
    final files = await global.getFilesInFolderSortedByModifiedDate(folderPath);

    if (files.isEmpty) {
      AppLogger.debug('[PrintQueue]    ℹ️ No print jobs in queue');
      return; // ไม่มีงาน skip
    }

    if (kDebugMode) {
      AppLogger.debug('📄 Found ${files.length} print jobs:');
      for (var i = 0; i < files.length; i++) {
        AppLogger.debug('[PrintQueue]       ${i + 1}. ${files[i].path.split('\\').last}');
      }
    }

    // ⭐ Print jobs ทีละไฟล์ (sequential - ปลอดภัยสำหรับ printer)
    for (var i = 0; i < files.length; i++) {
      final job = files[i];
      try {
        AppLogger.debug('[PrintQueue]    🖨️ Printing job ${i + 1}/${files.length}: ${job.path.split('\\').last}');

        await printFromFile(printerData: printer, pathName: job.path);

        AppLogger.debug('[PrintQueue]    ✅ Print job ${i + 1} completed');
      } catch (printError) {
        AppLogger.debug('[PrintQueue]    ❌ Print job ${i + 1} failed: $printError');
        // Continue กับไฟล์ถัดไป
      }
    }

    AppLogger.debug('[PrintQueue]    🎉 All jobs processed for ${printer.deviceName}');
  } catch (e, stackTrace) {
    if (kDebugMode) {
      AppLogger.error('❌ Printer ${printer.deviceName} error: $e');
      AppLogger.debug('Stack: $stackTrace');
    }

    global.sendErrorToDevTeam("bootstrap.dart->_processPrinterQueue", "Printer ${printer.deviceName}: $e\n${stackTrace.toString()}");
  }
}

/// เริ่ม Print Queue Isolate
Future<void> _startPrintQueueIsolate() async {
  // ถ้า isolate กำลังทำงานอยู่ ไม่ต้องสร้างใหม่
  if (_printQueueIsolateRunning) {
    AppLogger.debug('[PrintQueue] ⚠️ Isolate already running');
    return;
  }

  try {
    if (kDebugMode) {
      AppLogger.debug('[PrintQueue] 🚀 Starting Print Queue Isolate with Two-Way Communication...');
      AppLogger.success('Login: ${global.loginSuccess}');
      AppLogger.debug('[PrintQueue]    Printers: ${global.printerLocalStrongData.length}');
    }

    // ⭐ สร้าง ReceivePort สำหรับรับข้อมูลจาก Isolate
    _printQueueMainReceivePort = ReceivePort();

    // ⭐ Get temp directory path ใน Main thread ก่อน
    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;

    // ⭐ Get ObjectBox store directory path (with null check)
    String dbPath;
    try {
      dbPath = global.objectBoxStore.directoryPath;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.warning('⚠️ ObjectBox not ready yet: $e');
        AppLogger.debug('⏱️ Will retry later...');
      }
      // Schedule retry after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        _startPrintQueueIsolate();
      });
      return;
    }

    if (kDebugMode) {
      AppLogger.debug('Temp path: $tempPath');
      AppLogger.debug('DB path: $dbPath');
    }

    // ⭐ Spawn isolate พร้อมส่ง temp path และ db path ไปด้วย
    _printQueueIsolate = await Isolate.spawn(_printQueueIsolateWorker, {
      'sendPort': _printQueueMainReceivePort!.sendPort,
      'tempPath': tempPath,
      'dbPath': dbPath, // ⭐ ส่ง ObjectBox path
    });

    _printQueueIsolateRunning = true;

    // ⭐ รับ messages จาก Isolate
    _printQueueMainReceivePort!.listen((message) {
      if (message is SendPort) {
        // เก็บ SendPort สำหรับส่งข้อความไปยัง Isolate
        _printQueueIsolateSendPort = message;

        AppLogger.debug('[PrintQueue] ✅ Two-way communication established');

        // ⭐ ส่ง printer configs ไปยัง Isolate ทันที
        _sendPrinterConfigsToIsolate();
      } else if (message is Map<String, dynamic>) {
        // รับ response จาก Isolate (เป็น Map แทน custom class)
        _handlePrintQueueResponse(message);
      }
    });

    AppLogger.debug('[PrintQueue] ✅ Isolate started successfully');
  } catch (e) {
    AppLogger.error('[PrintQueue] ❌ Failed to start isolate: $e');

    global.sendErrorToDevTeam("bootstrap.dart->_startPrintQueueIsolate", "Failed to start isolate: $e");
  }
}

/// ส่ง Printer Configs ไปยัง Isolate
void _sendPrinterConfigsToIsolate() {
  if (_printQueueIsolateSendPort == null) {
    AppLogger.debug('[PrintQueue] ⚠️ Cannot send configs: SendPort not ready');
    return;
  }

  try {
    final printersData = global.printerLocalStrongData.map((printer) {
      // ⭐ แปลง enum เป็น string value ที่ถูกต้อง
      String printerTypeString;
      switch (printer.printerConnectType) {
        case global.PrinterConnectEnum.ip:
          printerTypeString = 'ip';
          break;
        case global.PrinterConnectEnum.bluetooth:
          printerTypeString = 'bluetooth';
          break;
        case global.PrinterConnectEnum.usb:
          printerTypeString = 'usb';
          break;
        case global.PrinterConnectEnum.windows:
          printerTypeString = 'windows';
          break;
        case global.PrinterConnectEnum.sunmi1:
          printerTypeString = 'sunmi1';
          break;
      }

      return {
        'deviceName': printer.deviceName,
        'ipAddress': printer.ipAddress,
        'ipPort': printer.ipPort,
        'paperType': printer.paperType,
        'printerConnectType': printerTypeString, // ⭐ ส่ง string แทน index
        'isConfigConnectSuccess': printer.isConfigConnectSuccess,
        'vendorId': printer.vendorId,
        'productId': printer.productId,
        'code': printer.code,
      };
    }).toList();

    _printQueueIsolateSendPort!.send({
      'type': 'init',
      'data': {'printers': printersData},
    });

    AppLogger.debug('[PrintQueue] 📤 Sent ${printersData.length} printer configs to isolate');
  } catch (e) {
    AppLogger.error('[PrintQueue] ❌ Failed to send configs: $e');
  }
}

/// รับ Response จาก Isolate
void _handlePrintQueueResponse(Map<String, dynamic> response) {
  final status = response['status'] as String?;
  final data = response['data'] as Map<String, dynamic>? ?? {};

  AppLogger.debug('[PrintQueue] 📨 Response from isolate: $status');

  switch (status) {
    case 'ready':
      if (kDebugMode) {
        AppLogger.success('[PrintQueue]    ✅ Isolate ready with ${data['printersCount']} printers');
        AppLogger.debug('[PrintQueue]    🔄 Isolate will handle ObjectBox queries independently');
      }

      // ⭐ ไม่ต้องเริ่ม Timer แล้ว - Isolate จัดการเอง
      // _printQueueTimer = startPrintQueueTimer(_printQueueIsolateSendPort);
      break;

    case 'printing':
      // Isolate กำลังพิมพ์งาน
      if (kDebugMode) {
        final fileName = data['fileName'] as String?;
        final printer = data['printer'] as String?;
        AppLogger.debug('🖨️ Printing: $fileName on $printer');
      }

      // Update ObjectBox status to "printing"
      final fileName = data['fileName'] as String?;
      if (fileName != null) {
        global.updatePrintJobStatus(fileName: fileName, status: PrintQueueStatus.printing);
      }
      break;

    case 'completed':
      // Isolate พิมพ์เสร็จแล้ว
      if (kDebugMode) {
        final fileName = data['fileName'] as String?;
        final printer = data['printer'] as String?;
        AppLogger.success('✅ Completed: $fileName on $printer');
      }

      // ⭐ Step 6: Update ObjectBox status to "completed" (ไม่ลบไฟล์)
      final fileName = data['fileName'] as String?;
      if (fileName != null) {
        global.updatePrintJobStatus(fileName: fileName, status: PrintQueueStatus.completed);
      }
      break;

    case 'success':
      AppLogger.debug('[PrintQueue]    ✅ ${data['printer']}: ${data['successCount']}/${data['totalJobs']} jobs completed');
      break;

    case 'progress':
      AppLogger.debug('[PrintQueue]    ⏳ ${data['printer']}: Processing ${data['jobsCount']} jobs...');
      break;

    case 'error':
      if (kDebugMode) {
        final message = data['message'] ?? 'Unknown error';
        final fileName = data['fileName'];
        AppLogger.error('❌ Error: $message');
        if (fileName != null) {
          AppLogger.debug('File: $fileName');
        }
      }

      // ส่ง error report (ใช้ ?? เพื่อป้องกัน null)
      final errorMessage = data['message'] ?? 'Unknown error from isolate';
      global.sendErrorToDevTeam("PrintQueue Isolate", errorMessage is String ? errorMessage : errorMessage.toString());
      break;
  }
}

/// หยุด Print Queue Isolate
void _stopPrintQueueIsolate() {
  // ส่งคำสั่ง shutdown ไปยัง Isolate ก่อน
  if (_printQueueIsolateSendPort != null) {
    _printQueueIsolateSendPort!.send({'type': 'shutdown', 'data': {}});
  }

  if (_printQueueIsolate != null) {
    _printQueueIsolate!.kill(priority: Isolate.immediate);
    _printQueueIsolate = null;
    _printQueueIsolateRunning = false;

    AppLogger.debug('[PrintQueue] Isolate stopped');
  }

  // ปิด ReceivePort
  _printQueueMainReceivePort?.close();
  _printQueueMainReceivePort = null;
  _printQueueIsolateSendPort = null;
}

// ⭐ ============================================================================
// ⭐ ISOLATE-BASED ONLINE ORDERS PROCESSING
// ⭐ ============================================================================

/// Online Orders Isolate Worker
/// ทำงานใน background thread แยกจาก main UI thread
/// Self-scheduling: ทำงานเสร็จ → รอ 3 วิ → ทำใหม่
void _onlineOrdersIsolateWorker(SendPort mainSendPort) async {
  AppLogger.debug('[OnlineOrders Isolate] Worker started');

  // Self-scheduling loop - รอให้งานเสร็จก่อนรอบถัดไป
  while (true) {
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
    }

    try {
      // ตรวจสอบเงื่อนไข
      if (!global.loginSuccess || global.shopId.isEmpty) {
        // ถ้ายังไม่ login รอนาน 30 วินาที
        await Future.delayed(const Duration(seconds: 30));
        continue;
      }

      // ⭐ Process Online Orders & Kitchen
      await _processOnlineOrdersAndKitchen();

      // ⭐ Process ClickHouse Cleanup (ถ้า online)
      if (global.isOnline) {
        await _processClickHouseCleanup();
      }

      // ⭐ Process Caller & Line Notify
      if (global.isOnline) {
        await Future.wait([global.callerCheck(), global.lineNotifyCheck()]);
      }

      if (kDebugMode && stopwatch != null) {
        stopwatch.stop();
        AppLogger.debug('[Performance] Online orders cycle: ${stopwatch.elapsedMilliseconds}ms');
      }

      // ⭐ รอ 3 วินาทีก่อนรอบถัดไป (ทำงานเสร็จแล้ว ค่อยรอ)
      await Future.delayed(const Duration(seconds: 3));
    } catch (e, stackTrace) {
      AppLogger.error('[OnlineOrders Isolate] Error: $e');

      global.sendErrorToDevTeam("bootstrap.dart->_onlineOrdersIsolateWorker", "Online Orders Isolate: $e\n${stackTrace.toString()}");

      // ถ้า error รอนาน 30 วินาที
      await Future.delayed(const Duration(seconds: 30));
    }
  }
}

/// Process Online Orders and Kitchen
Future<void> _processOnlineOrdersAndKitchen() async {
  // รับ Order จากระบบ Order OnLine
  if (global.checkOrderFromOnLineActive == false) {
    try {
      await global.checkOrderOnline();
    } catch (ex) {
      AppLogger.debug('[OnlineOrders] checkOrderOnline error: $ex');
    }
  }

  // ครัว
  if (global.checkKitchenActive == false) {
    try {
      await global.checkKitchenOrder();
    } catch (ex) {
      AppLogger.debug('[OnlineOrders] checkKitchenOrder error: $ex');
    }
  }

  // ส่งข้อมูลอื่นๆ ไปที่ Server
  if (global.sendTempToServerActive == false && global.isOnline) {
    try {
      await global.sendTempToServer();
    } catch (ex) {
      AppLogger.debug('[OnlineOrders] sendTempToServer error: $ex');
    }
  }
}

/// Process ClickHouse Cleanup Operations
Future<void> _processClickHouseCleanup() async {
  try {
    // ⭐ ลบ Click House โต๊ะที่ปิดและจ่ายเงินแล้ว (dedetemp.jsoninfo)
    var jsonInfoSelect = await api.clickHouseSelect(
      "select code,count(*) as xcount from dedetemp.jsoninfo where shopid = '${global.shopId}' and posid = '${global.posConfig.code}' group by code",
    );

    ResponseDataModel response = ResponseDataModel.fromJson(jsonInfoSelect);

    var tableProcessData = global.objectBoxStore.box<TableProcessObjectBoxStruct>().getAll();

    // ⭐ Optimize: สร้าง Map สำหรับ O(1) lookup แทน nested loop
    final codeCountMap = <String, int>{};
    for (var data in response.data) {
      codeCountMap[data["code"].toString()] = int.tryParse(data["xcount"].toString()) ?? 0;
    }

    // ⭐ Parallel cleanup operations
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

    // ⭐ Execute all cleanup tasks in parallel
    if (cleanupTasks.isNotEmpty) {
      await Future.wait(cleanupTasks);
    }

    // ⭐ ลบ caller ถ้าเกิน 1 ชั่วโมง
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

      // ⭐ Execute all caller cleanup in parallel
      if (callerCleanupTasks.isNotEmpty) {
        await Future.wait(callerCleanupTasks);
      }
    }

    // ส่งข้อมูล OrderTempSync ไปที่ Click House
    global.sendOrderTempToDeDeOrderTempLog();
  } catch (e, stackTrace) {
    AppLogger.error('[OnlineOrders] ClickHouse cleanup error: $e');

    global.sendErrorToDevTeam("bootstrap.dart->_processClickHouseCleanup", "ClickHouse Cleanup: $e\n${stackTrace.toString()}");
  }
}

/// เริ่ม Online Orders Isolate
Future<void> _startOnlineOrdersIsolate() async {
  // ถ้า isolate กำลังทำงานอยู่ ไม่ต้องสร้างใหม่
  if (_onlineOrdersIsolateRunning) {
    AppLogger.debug('[OnlineOrders] Isolate already running');
    return;
  }

  try {
    final receivePort = ReceivePort();

    // ⭐ Spawn isolate
    _onlineOrdersIsolate = await Isolate.spawn(_onlineOrdersIsolateWorker, receivePort.sendPort);

    _onlineOrdersIsolateRunning = true;

    AppLogger.debug('[OnlineOrders] Isolate started successfully');
  } catch (e) {
    AppLogger.error('[OnlineOrders] Failed to start isolate: $e');

    global.sendErrorToDevTeam("bootstrap.dart->_startOnlineOrdersIsolate", "Failed to start isolate: $e");
  }
}

/// หยุด Online Orders Isolate
void _stopOnlineOrdersIsolate() {
  if (_onlineOrdersIsolate != null) {
    _onlineOrdersIsolate!.kill(priority: Isolate.immediate);
    _onlineOrdersIsolate = null;
    _onlineOrdersIsolateRunning = false;

    AppLogger.debug('[OnlineOrders] Isolate stopped');
  }
}

// ฟังก์ชันสำหรับ Initialize Online Orders Management
void _initializeOnlineOrdersManager() {
  // ✅ ใช้ Timer Manager แทน Isolate (ปลอดภัยกว่า)
  AppLogger.info('🚀 [Bootstrap] Starting Online Orders Timer Manager...');
  onlineOrdersTimerManager.start();
}

// ============================================================================
// ⭐ SYSTEM PROCESS ISOLATE (Sync Master + System Tasks)
// ============================================================================

/// Worker function สำหรับ SystemProcess Isolate
/// ประมวลผล:
/// 1. Sync Master Counter (เดิมทำใน Timer 10s)
/// 2. System Process Tasks (เดิมทำใน Timer 15s)
///    - systemProcess()
///    - registerRemoteToTerminal()
///    - compareBarcodeStatusTeminalAndServer()
void _systemProcessIsolateWorker(SendPort mainSendPort) async {
  Stopwatch? stopwatch;
  int syncMasterSecondCount = 0;

  while (true) {
    try {
      if (kDebugMode) {
        stopwatch = Stopwatch()..start();
      }

      // ============ SYNC MASTER COUNTER LOGIC ============
      // เดิมอยู่ใน Timer 10s ใน global.dart startLoading()
      if (global.loginSuccess && !global.syncDataProcess) {
        syncMasterSecondCount++;
        if (syncMasterSecondCount > global.syncTimeIntervalSecond) {
          // sync.syncMasterProcess(); // commented in original
          global.syncTimeIntervalSecond = global.syncTimeIntervalSecond * 2;
          if (global.syncTimeIntervalSecond > global.syncTimeIntervalMaxBySecond) {
            global.syncTimeIntervalSecond = global.syncTimeIntervalMaxBySecond;
          }
          syncMasterSecondCount = 0;

          AppLogger.debug('[SystemProcess] Sync Master Counter Reset: ${global.syncTimeIntervalSecond}s');
        }
      }

      // ============ SYSTEM PROCESS TASKS ============
      // เดิมอยู่ใน Timer 15s ใน global.dart startLoading()
      if (global.loginSuccess) {
        await Future.wait([Future(() => global.systemProcess()), Future(() => global.registerRemoteToTerminal()), Future(() => global.compareBarcodeStatusTeminalAndServer())]);
      }

      if (kDebugMode) {
        stopwatch?.stop();
        AppLogger.success('[SystemProcess] ⚡ Cycle completed in ${stopwatch?.elapsedMilliseconds}ms');
      }

      // ⭐ Self-scheduling: ทำงานเสร็จแล้วรอ 15 วิ
      await Future.delayed(const Duration(seconds: 15));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        AppLogger.error('[SystemProcess] ❌ Error: $e');
        AppLogger.debug('[SystemProcess] Stack trace: $stackTrace');
      }

      // หากเกิด error รอ 30 วิก่อน retry
      await Future.delayed(const Duration(seconds: 30));
    }
  }
}

/// เริ่ม SystemProcess Isolate
Future<void> _startSystemProcessIsolate() async {
  // ป้องกันเริ่มซ้ำ
  if (_systemProcessIsolateRunning) {
    AppLogger.debug('[SystemProcess] Isolate already running, skipping start');
    return;
  }

  try {
    AppLogger.debug('[SystemProcess] 🚀 Starting Isolate...');

    // Spawn isolate
    _systemProcessIsolate = await Isolate.spawn(_systemProcessIsolateWorker, ReceivePort().sendPort, debugName: 'SystemProcessIsolate');

    _systemProcessIsolateRunning = true;

    AppLogger.debug('[SystemProcess] ✅ Isolate started successfully');
  } catch (e, stackTrace) {
    if (kDebugMode) {
      AppLogger.error('[SystemProcess] ❌ Failed to start Isolate: $e');
      AppLogger.debug('[SystemProcess] Stack trace: $stackTrace');
    }

    _systemProcessIsolateRunning = false;

    // Retry หลัง 10 วิ
    await Future.delayed(const Duration(seconds: 10));
    await _startSystemProcessIsolate();
  }
}

/// หยุด SystemProcess Isolate
void _stopSystemProcessIsolate() {
  if (_systemProcessIsolate != null) {
    _systemProcessIsolate!.kill(priority: Isolate.immediate);
    _systemProcessIsolate = null;
    _systemProcessIsolateRunning = false;

    AppLogger.debug('[SystemProcess] Isolate stopped');
  }
}

// ฟังก์ชันสำหรับ Initialize SystemProcess Management
void _initializeSystemProcessManager() {
  // ✅ ใช้ Timer Manager แทน Isolate (ปลอดภัยกว่า)
  AppLogger.info('🚀 [Bootstrap] Starting System Process Timer Manager...');
  systemProcessTimerManager.start();
}

// ฟังก์ชันสำหรับจัดการ App Lifecycle
void _handleAppLifecycleChange(AppLifecycleState state) {
  if (kDebugMode) {
    AppLogger.debug('[Lifecycle] Handler Called: $state');
    AppLogger.debug('[Lifecycle] Current isAppActive: $_isAppActive');
    AppLogger.debug('[Lifecycle] PrintQueue Timer active: ${printQueueTimerManager.isActive}');
    AppLogger.debug('[Lifecycle] OnlineOrders Timer running: ${onlineOrdersTimerManager.isRunning}');
    AppLogger.debug('[Lifecycle] SystemProcess Timer running: ${systemProcessTimerManager.isRunning}');
  }

  switch (state) {
    case AppLifecycleState.resumed:
      _isAppActive = true;
      // ✅ Resume Timer Managers (ปลอดภัยกว่า Isolates)
      printQueueTimerManager.resume();
      onlineOrdersTimerManager.resume();
      systemProcessTimerManager.resume();
      AppLogger.debug('[Lifecycle] All Timer Managers resumed');
      break;
    case AppLifecycleState.paused:
    case AppLifecycleState.inactive:
    case AppLifecycleState.hidden:
      _isAppActive = false;
      // ✅ Pause Timer Managers
      printQueueTimerManager.pause();
      onlineOrdersTimerManager.pause();
      systemProcessTimerManager.pause();
      AppLogger.debug('[Lifecycle] All Timer Managers paused');
      break;
    case AppLifecycleState.detached:
      _isAppActive = false;
      printQueueTimerManager.stop();
      onlineOrdersTimerManager.stop();
      systemProcessTimerManager.stop();
      AppLogger.debug('[Lifecycle] All Timer Managers stopped');
      break;
  }
}

// ฟังก์ชันสำหรับ Initialize Print Queue Management
void _initializePrintQueueManager() {
  // เก็บฟังก์ชันไว้ใน global เพื่อให้เรียกใช้จาก main app
  global.handlePrintQueueLifecycle = _handleAppLifecycleChange;

  // ⭐ ไม่ต้องใช้ updatePrinterInIsolate แล้ว (Timer-based ไม่ต้อง sync)
  // global.updatePrinterInIsolate = _sendPrinterConfigsToIsolate;

  // ⭐ เริ่ม Timer Manager แทน Isolate
  printQueueTimerManager.start();

  AppLogger.debug('[PrintQueue] ✅ Timer Manager initialized');
}

void initCustomerDisplayBanner() async {
  ApiRepository apiRepository = ApiRepository();
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String mediaguid = prefs.getString("mediaguid") ?? "";
    if (mediaguid.isNotEmpty) {
      var value = await apiRepository.getMedia(mediaguid);
      PosMediaModel posMedia = PosMediaModel.fromJson(value.data);
      global.informationList.clear();
      for (var item in posMedia.resources) {
        if (item.mediaType == 0 || item.mediaType == 1) {
          if (item.daysofweek.isNotEmpty && !item.daysofweek.contains(DateTime.now().weekday)) {
            continue; // Skip if today is not in the list of days
          }
          if (item.fromDate.isNotEmpty && item.toDate.isNotEmpty) {
            DateTime now = DateTime.now().toUtc();
            DateTime fromDate = DateTime.parse(item.fromDate).toUtc();
            DateTime toDate = DateTime.parse(item.toDate).toUtc();

            if (now.isBefore(fromDate) || now.isAfter(toDate)) {
              continue; // Skip if current date is outside the specified range
            }
          }
          if (item.fromTime.isNotEmpty && item.toTime.isNotEmpty) {
            DateTime now = DateTime.now().toUtc();
            DateTime startTime = DateTime.utc(now.year, now.month, now.day, int.parse(item.fromTime.split(":")[0]), int.parse(item.fromTime.split(":")[1]));
            DateTime endTime = DateTime.utc(now.year, now.month, now.day, int.parse(item.toTime.split(":")[0]), int.parse(item.toTime.split(":")[1]));

            if (now.isBefore(startTime) || now.isAfter(endTime)) {
              continue; // Skip if current time is outside the specified range
            }
          }
          global.informationList.add(InformationModel(mode: item.mediaType, delaySecond: item.displaytime, sourceUrl: item.uri));
        }
      }
      AppLogger.debug(global.informationList);
    }
  } catch (e) {
    AppLogger.error("Error loading POS Setting: $e");
  }
}

Future<void> setupDisplay() async {
  AppLogger.debug('setupDisplay: start');
  List<Display>? displaysNullable = [];
  if (Platform.isAndroid) {
    displaysNullable = await global.displayManager.getDisplays();
    AppLogger.debug('setupDisplay: displays = $displaysNullable');
    await Future.delayed(const Duration(milliseconds: 500));
    if (displaysNullable != null && displaysNullable.isNotEmpty) {
      final displays = displaysNullable;
      final secondary = displays.firstWhere((d) => d.displayId != null, orElse: () => displays[0]);
      AppLogger.debug('setupDisplay: secondary = $secondary');
      if (secondary.displayId != null) {
        global.isInternalCustomerDisplayConnected = true;
        if (kDebugMode) {
          AppLogger.info(global.informationList);
          AppLogger.debug('internal Customer Display: displayId=${secondary.displayId}');
        }
        try {
          await global.displayManager.showSecondaryDisplay(displayId: secondary.displayId!, routerName: global.internalCustomerDisplayPageName);

          AppLogger.debug('setupDisplay: showSecondaryDisplay called');
        } catch (e, s) {
          AppLogger.error('setupDisplay: showSecondaryDisplay error: $e\n$s');
        }
      } else {
        AppLogger.debug('setupDisplay: secondary.displayId is null');
      }
    } else {
      AppLogger.debug('setupDisplay: No secondary display found');
    }
  }
}
