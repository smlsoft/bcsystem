import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dedekiosk/util/network_helper.dart';
import 'package:dedekiosk/bloc/category_bloc.dart';
import 'package:dedekiosk/bloc/click_house_order_temp_bloc.dart';
import 'package:dedekiosk/bloc/click_house_order_temp_kds_bloc.dart';
import 'package:dedekiosk/bloc/click_house_order_temp_served_bloc.dart';
import 'package:dedekiosk/bloc/click_house_order_temp_table_bloc.dart';
import 'package:dedekiosk/bloc/copy_print_queue_bloc.dart';
import 'package:dedekiosk/bloc/list_kiosk/list_kiosk_bloc.dart';
import 'package:dedekiosk/bloc/list_shop/list_shop_bloc.dart';
import 'package:dedekiosk/bloc/login_bloc/login_bloc.dart';
import 'package:dedekiosk/bloc/order_temp_bloc.dart';
import 'package:dedekiosk/bloc/server_trans_bloc.dart';
import 'package:dedekiosk/bloc/shop_select/shop_select_bloc.dart';
import 'package:dedekiosk/order/member_pin_page.dart';
import 'package:dedekiosk/order/member_qr_page.dart';
import 'package:dedekiosk/order/select_memter_type.dart';
import 'package:dedekiosk/service/user_repository.dart';
import 'package:dedekiosk/setting/register_order_station_page.dart';
import 'package:dedekiosk/util/check_payment.dart';
import 'package:dedekiosk/util/client.dart';
import 'package:dedekiosk/util/environment.dart';
import 'package:dedekiosk/util/http_verify.dart';
import 'package:dedekiosk/page/order_kds_page.dart';
import 'package:dedekiosk/page/main_page.dart';
import 'package:dedekiosk/page/network_test_page.dart';
import 'package:dedekiosk/objectbox.dart';
import 'package:dedekiosk/order/bill_list_page.dart';
import 'package:dedekiosk/page/bill_ledger_page.dart';
import 'package:dedekiosk/order/order_animation_one/order_animation_one_page.dart';
import 'package:dedekiosk/order/order_standard/order_standard_page.dart';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/page/order_select_page.dart';
import 'package:dedekiosk/page/cashier_scan_page.dart';
import 'package:dedekiosk/page/order_served_page.dart';
import 'package:dedekiosk/util/print_queue.dart';
import 'package:dedekiosk/service/bill_ledger_sync_service.dart';
import 'package:dedekiosk/service/kiosk_status_reporter_service.dart';
import 'package:dedekiosk/setting/setting_page.dart';
import 'package:dedekiosk/setting/setting_main_device_page.dart';
import 'package:dedekiosk/order/order_util.dart';
import 'package:dedekiosk/page/copy_print_queue_page.dart';
import 'package:dedekiosk/page/order_online_page.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dedekiosk/util/logger.dart';
// import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

void limitImageCacheSize() {
  PaintingBinding.instance.imageCache.maximumSizeBytes = 3 * 1024 * 1024; // 3MB
}

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();

  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  //   Logger.d("Firebase initialized successfully");
  // } catch (e) {
  //   Logger.d('Error initializing Firebase: $e');
  // }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  try {
    var permissions = [
      Permission.location,
      Permission.camera,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ];
    var permissionStatuses = await permissions.request();
    permissionStatuses.forEach((permission, status) {
      Logger.d('$permission: $status');
    });
    global.allGranted = permissionStatuses.values.every((status) {
      return status.isGranted;
    });
  } catch (e, s) {
    Logger.e('Error occurred', error: e, stackTrace: s);
  }
  const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: Environment.DEV,
  );
  Environment().initConfig(environment);

  // Load app version from package_info_plus
  try {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    global.appVersion = packageInfo.version;
    Logger.d("App version: ${global.appVersion}");
  } catch (e) {
    Logger.e('Error loading app version: $e');
    global.appVersion = "Unknown";
  }

/*  if (Platform.isAndroid || Platform.isIOS) {
    AssetsAudioPlayer.setupNotificationsOpenAction((notification) {
      return true;
    });
    // Load เสียง
  }*/
  try {
    String jsonData = await rootBundle.loadString('assets/language.json');
    global.languageSystemCode = (json.decode(jsonData) as List)
        .map((i) => LanguageSystemCodeModel.fromJson(i))
        .toList();
  } catch (e, s) {
    Logger.e('Error occurred', error: e, stackTrace: s);

    global.languageSystemCode = [];
  }
  global.languageForCustomer = global.countryCodes[0];
  global.languageSelect(global.languageForCustomer);
  bool loadConfigSuccess = false;
  bool hasSavedShopId = false;

  // Check if device was previously registered (has saved shopId)
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedConfig = prefs.getString(global.storageDeviceConfigName);
    if (savedConfig != null && savedConfig.isNotEmpty) {
      var config = json.decode(savedConfig);
      hasSavedShopId = (config['shopId'] ?? '').toString().isNotEmpty;
    }
  } catch (e) {
    Logger.w('Error checking saved config: $e');
  }

  try {
    if (hasSavedShopId) {
      await ApiAuthManager.reauthenticate(useStoredConfig: true);
    }
    await global.loadConfig();
    loadConfigSuccess = true;
    global.isNetworkError = false;
    if (global.deviceConfig.shopId == "") {
      loadConfigSuccess = false;
    }
  } catch (e, s) {
    Logger.e('Error occurred', error: e, stackTrace: s);
    // If device was registered but loadConfig failed (network error),
    // still go to main page but show retry dialog
    if (hasSavedShopId) {
      loadConfigSuccess = true;
      global.isNetworkError = true;
      Logger.w('Network error but device was registered, showing retry dialog');
    }
  }
  await objectBoxInit();

  // PERFORMANCE OPTIMIZATION: Background workers with smart conditional checks

  // Timer 1: Device Registration (Every 60 seconds) - With timeout protection
  Timer.periodic(const Duration(seconds: 60), (timer) async {
    // Skip if not connected yet
    if (global.deviceConfig.shopId.isEmpty) return;

    if (global.checkOrderActive == false) {
      global.checkDeviceActive = true;
      try {
        // Add timeout protection (10 seconds)
        await global.registerDeviceToServer().timeout(
          NetworkTimeouts.standard,
          onTimeout: () {
            Logger.w('Device registration timeout');
            return;
          },
        );
      } catch (e) {
        Logger.w('Device registration error: $e');
      } finally {
        global.checkDeviceActive = false;
      }
    }
  });

  // Timer 2: Print Queue Worker (Every 10 seconds)
  // OPTIMIZED: Only runs when there's actually something in the queue
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    // Skip if not connected yet
    if (global.deviceConfig.shopId.isEmpty) return;

    try {
      // Skip if no items in queue and not processing kitchen orders
      if (global.printQueue.isEmpty && !global.deviceConfig.isServer) {
        return;
      }
      await printQueueWorker();
    } catch (e, s) {
      Logger.e('Error occurred', error: e, stackTrace: s);
    }
  });

  // Timer 3: Order Sync and Slip Upload (Every 30 seconds)
  // With timeout protection and overlap prevention
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    // Skip if not connected yet
    if (global.deviceConfig.shopId.isEmpty) return;

    // Prevent overlap - skip if already syncing
    if (global.checkOrderActive) return;

    global.checkOrderActive = true;
    try {
      // Add timeout protection (15 seconds each)
      await Future.wait([
        checkOrderOnline().timeout(
          NetworkTimeouts.long,
          onTimeout: () {
            Logger.w('checkOrderOnline timeout');
            return;
          },
        ),
        uploadSlipWorker().timeout(
          NetworkTimeouts.long,
          onTimeout: () {
            Logger.w('uploadSlipWorker timeout');
            return;
          },
        ),
      ]);
    } catch (e, s) {
      Logger.e('Order sync error', error: e, stackTrace: s);
    } finally {
      global.checkOrderActive = false;
    }
  });

  // Timer 4: Payment Status Check (Every 30 seconds)
  // With timeout protection and overlap prevention
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    // Skip if not connected yet
    if (global.deviceConfig.shopId.isEmpty) return;

    // Skip if not a server device - payment checking only needed on server
    if (!global.deviceConfig.isServer) return;

    try {
      // Add timeout protection (10 seconds)
      await checkPaymentOnline().timeout(
        NetworkTimeouts.standard,
        onTimeout: () {
          Logger.w('checkPaymentOnline timeout');
          return;
        },
      );
    } catch (e, s) {
      Logger.e('Payment check error', error: e, stackTrace: s);
    }
  });

  // BillLedger is the single saveTransaction retry queue for new kiosk bills.
  BillLedgerSyncService().startBackgroundSync();
  KioskStatusReporterService().start();

  Logger.d('Shop ID: ${global.deviceConfig.shopId}');

  /*try {
    global.bluetoothPlatformVersion = await PrintBluetoothThermal.platformVersion;
    //print("patformversion: $platformVersion");
    global.bluetoothPorcentBatery = await PrintBluetoothThermal.batteryLevel;
  } on PlatformException {
    global.bluetoothPlatformVersion = 'Failed to get platform version.';
  }*/
  // PERFORMANCE OPTIMIZATION Phase 2: Lazy BLoC Loading
  // BLoCs are now created only when actually needed, reducing startup time
  runApp(MultiBlocProvider(
      providers: [
        // Core BLoCs - needed immediately
        BlocProvider<CategoryBloc>(
          create: (context) => CategoryBloc(),
          lazy: false, // Load immediately - needed for main order screen
        ),
        BlocProvider<OrderTempBloc>(
          create: (context) => OrderTempBloc(),
          lazy: false, // Load immediately - needed for all orders
        ),

        // Server sync BLoCs - lazy load when needed
        BlocProvider<ClickHouseOrderTempBloc>(
          create: (context) => ClickHouseOrderTempBloc(),
          lazy: true, // Only load when accessing order sync features
        ),
        BlocProvider<ClickHouseOrderTempKdsBloc>(
          create: (context) => ClickHouseOrderTempKdsBloc(),
          lazy: true, // Only load when accessing KDS screen
        ),
        BlocProvider<ClickHouseOrderTempTableBloc>(
          create: (context) => ClickHouseOrderTempTableBloc(),
          lazy: true, // Only load when accessing table management
        ),
        BlocProvider<ClickHouseOrderTempServedBloc>(
          create: (context) => ClickHouseOrderTempServedBloc(),
          lazy: true, // Only load when accessing served orders
        ),
        BlocProvider<CopyPrintQueueBloc>(
          create: (context) => CopyPrintQueueBloc(),
          lazy: true, // Only load when accessing copy print queue
        ),
        BlocProvider<ServerTransBloc>(
          create: (context) => ServerTransBloc(),
          lazy: true, // Only load when syncing transactions
        ),

        // Authentication BLoCs - lazy load
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(userRepository: UserRepository()),
          lazy: true, // Only load when user logs in
        ),
        BlocProvider<ListShopBloc>(
          create: (context) => ListShopBloc(userRepository: UserRepository()),
          lazy: true, // Only load when selecting shop
        ),
        BlocProvider<ShopSelectBloc>(
          create: (context) => ShopSelectBloc(userRepository: UserRepository()),
          lazy: true, // Only load when shop selection needed
        ),
        BlocProvider<ListKioskBloc>(
          create: (context) => ListKioskBloc(userRepository: UserRepository()),
          lazy: true, // Only load when managing kiosks
        ),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: (loadConfigSuccess) ? "/" : "/register_pos",
        theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: "nato",
            useMaterial3: false),
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => const MainPage(),
          '/order': (BuildContext context) => const OrderStandardPage(),
          '/member_pin': (BuildContext context) => const MemberPinPage(),
          '/member_qr': (BuildContext context) => const MemberQrPage(),
          '/order_animation_one': (BuildContext context) =>
              const OrderAnimationOnePage(),
          '/select_member': (BuildContext context) =>
              const SelectMemberScreen(),
          '/order_select': (BuildContext context) => const OrderSelectPage(),
          '/cashier_scan': (BuildContext context) => const CashierScanPage(),
          '/setting': (BuildContext context) => const SettingPage(),
          '/setting_main': (BuildContext context) =>
              const SettingMainDevicePage(),
          '/register_pos': (BuildContext context) =>
              const RegisterOrderStationPage(),
          '/bill_list': (BuildContext context) => const BillListPage(),
          '/bill_ledger': (BuildContext context) => const BillLedgerPage(),
          '/order_served_by_waiter': (BuildContext context) =>
              const OrderServedPage(),
          '/kds': (BuildContext context) => const OrderKdsPage(),
          '/network_test': (BuildContext context) => const NetworkTestPage(),
          '/copy_print_queue': (BuildContext context) =>
              const CopyPrintQueuePage(),
          '/order_online': (BuildContext context) => const OrderOnlinePage(),
        },
      )));
}
