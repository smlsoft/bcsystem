import 'dart:convert';
import 'package:dedecashier/app/app.dart';
import 'package:dedecashier/bootstrap.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_secondary_screen.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/core/performance/app_performance_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'flavors.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/widgets/display.dart';
import 'package:dedecashier/widgets/displays_manager.dart';
import 'package:dedecashier/widgets/secondary_display.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

void main() async {
  F.appFlavor = Flavor.MARINEPOS;
  global.posVersion = global.PosVersionEnum.marinepos;
  await initializeEnvironmentConfig();
  await initializeApp();

  await WakelockPlus.enable();

  // เริ่มต้น Performance Manager
  AppPerformanceManager.instance.start();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // หรือกำหนดสี เช่น Color(0xFF005598)
      statusBarIconBrightness: Brightness.light, // ไอคอนสีขาว
      systemNavigationBarColor: Color(0xFF005598), // สีปุ่ม Back/Home ด้านล่าง
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const App());
}

@pragma('vm:entry-point')
void secondaryDisplayMain() {
  AppLogger.debug('secondaryDisplayMain: test');
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = "th";
  global.userScreenLanguage = "th";
  rootBundle.loadString(global.jsonLanguageFileName).then((value) {
    global.languageSystemCode = (json.decode(value) as List).map((i) => LanguageSystemCodeModel.fromJson(i)).toList();
    global.languageSelect(global.userScreenLanguage);
  });
  AppLogger.debug('secondaryDisplayMain: เริ่มต้น secondary display');
  runApp(const PosSecondaryScreen());
}
