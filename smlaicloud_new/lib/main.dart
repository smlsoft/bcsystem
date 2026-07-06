import 'dart:async';
import 'dart:convert';

import 'package:smlaicloud/api/app_const.dart';
import 'package:smlaicloud/flavors.dart';
import 'package:smlaicloud/main_app.dart';
import 'package:smlaicloud/environment.dart';
import 'package:smlaicloud/firebase_options.dart';
import 'package:smlaicloud/utils/google_sheet.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:smlaicloud/model/global_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global.dart' as global;

void initializeEnvironmentConfig() {
  // เชื่อมโยง Flavor กับ Environment
  String environment;

  switch (F.appFlavor) {
    case Flavor.smlaidev:
      environment = Environment.DEV;
      break;
    case Flavor.smlaiprod:
      environment = Environment.PROD;
      break;
    case Flavor.smlaiuat:
      environment = Environment.UAT;
      break;
    case Flavor.dohomedev:
      environment = Environment.DOHOME_DEV;
      break;
    case Flavor.dohomeprod:
      environment = Environment.DOHOME_PROD;
      break;
    case Flavor.dohomeuat:
      environment = Environment.DOHOME_UAT;
      break;
    default:
      // ค่า default ถ้าไม่ได้ระบุ flavor
      environment = Environment.DEV;
      break;
  }

  Environment().initConfig(environment);
  global.isdevPin = global.checkDeveloperMode(environment);
  if (kDebugMode) {
    print("isdev for active pin :  ${global.isdevPin}");
    print("Current Flavor: ${F.title}");
    print("Current Environment: $environment");
  }
}

FutureOr<void> main() async {
  initializeEnvironmentConfig();
  global.prefs = await SharedPreferences.getInstance();
  // global.posVersion = global.PosVersionEnum.restaurant;
  global.posVersion = global.PosVersionEnum.pos;
  WidgetsFlutterBinding.ensureInitialized();
  try {
    global.myAppConfig = appConfigInit();
  } catch (e) {
    // กรณี error เกิดจาก web platform
    print('Using default web config: $e');
  }

  global.appConfig = await SharedPreferences.getInstance();

  if (F.appFlavor == Flavor.smlaidev || F.appFlavor == Flavor.smlaiprod || F.appFlavor == Flavor.smlaiuat) {
    global.themeSelect(0);
  } else if (F.appFlavor == Flavor.dohomedev || F.appFlavor == Flavor.dohomeprod || F.appFlavor == Flavor.dohomeuat) {
    global.themeSelect(1);
  }

  // if (global.apiConnected == false) {
  //   if (!global.isLoginProcess) {
  //     global.isLoginProcess = true;
  //     UserRepository userRepository = UserRepository();
  //     await userRepository
  //         .authenUser(global.apiUserName, global.apiUserPassword)
  //         .then((_result) async {
  //       if (_result.success) {
  //         global.apiConnected = true;
  //         global.apiToken = _result.data["token"];
  //         global.appConfig .write("token", _result.data["token"]);
  //         // print("Login Succerss");
  //         ApiResponse selectShop =
  //             await userRepository.selectShop(global.apiShopCode);
  //         if (selectShop.success) {
  //           // print("Select Shop Sucess");
  //         }
  //       }
  //     }).catchError((e) {
  //       // print("Login Error");
  //       // print(e);
  //     }).whenComplete(() async {
  //       global.isLoginProcess = false;
  //     });
  //   }
  // }

  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  // await SystemChrome.setPreferredOrientations(
  //     [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

  if (kIsWeb) {
    // Web Base
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase initialized successfully on web");
    } catch (e) {
      print('Error initializing Firebase on web: $e');
    }
  } else {
    // Non-web platforms
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase initialized successfully on native platform");
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  // if (shouldUseFirebaseEmulator) {
  //   await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  // }

  ///ดึงภาษาจาก Google Sheet
  /*if (global.developerMode && kIsWeb == false) {
    // Developer Mode
    await googleMultiLanguageSheetLoad().then((_) {
      global.userLanguage = "th";
      global.languageSelect(global.userLanguage);
    });
  } else {
    try {
      global.languageSystemCode = (json.decode(await rootBundle.loadString('assets/language.json')) as List).map((i) => LanguageSystemCodeModel.fromJson(i)).toList();
    } catch (_) {}
    global.userLanguage = "th";
    global.languageSelect(global.userLanguage);
  }*/
  try {
    global.languageSystemCode = (json.decode(await rootBundle.loadString('assets/language.json')) as List).map((i) => LanguageSystemCodeModel.fromJson(i)).toList();
  } catch (_) {}
  global.userLanguage = "th";
  global.languageSelect(global.userLanguage);
  /*try {
    global.userLanguage = GetStorage().read("language");
  } catch (_) {}*/

  /*BlocOverrides.runZoned(
    () => runApp(const MyApp()),
    blocObserver: AppObserver(), 
  );*/
  // สร้าง Json จาก Google Sheet
  if (global.developerMode && kIsWeb == false) {
    // createJsonFromGoogleSheet();
  }

  global.deviceConfigLoad();

  /// load timezonelist
  global.getTimezones();

  global.userLanguage = global.appConfig.getString("language") ?? "th";
  global.languageSelect(global.userLanguage);

  runApp(const MyApp());
}
