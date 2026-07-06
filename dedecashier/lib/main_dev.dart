import 'package:dedecashier/bootstrap.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:flutter/material.dart';
import 'app/app_view.dart';
import 'flavors.dart';
import 'package:dedecashier/global.dart' as global;

void main() async {
  F.appFlavor = Flavor.DEV;
  await initializeEnvironmentConfig();
  global.applicationName = "BC Pos (Dev)";
  await setUpServiceLocator();
  await initializeApp();
  runApp(const App());
}
