import 'dart:convert';
import 'package:dedecashier/app/app.dart';
import 'package:dedecashier/bootstrap.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_secondary_screen.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/core/performance/app_performance_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'flavors.dart';
import 'package:dedecashier/global.dart' as global;

void main() async {
  F.appFlavor = Flavor.BCPOS;
  global.posVersion = global.PosVersionEnum.pos;
  await initializeEnvironmentConfig();
  await initializeApp();

  // เริ่มต้น Performance Manager
  AppPerformanceManager.instance.start();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // ไอคอนสีขาว
      systemNavigationBarColor: Color(0xFFB5651D), // อิฐบ้านเชียง (terracotta)
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const App());
}

@pragma('vm:entry-point')
void secondaryDisplayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = "th";
  global.userScreenLanguage = "th";
  global.isInternalCustomerDisplayConnected = true;
  // global.initCustomerDisplayBanner();
  rootBundle.loadString(global.jsonLanguageFileName).then((value) {
    global.languageSystemCode = (json.decode(value) as List).map((i) => LanguageSystemCodeModel.fromJson(i)).toList();
    global.languageSelect(global.userScreenLanguage);
  });

  runApp(const PosSecondaryScreen());
}
