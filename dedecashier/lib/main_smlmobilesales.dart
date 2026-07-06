import 'package:flutter/material.dart';
import 'package:dedecashier/bootstrap.dart';
import 'app.dart';
import 'flavors.dart';
import 'package:dedecashier/global.dart' as global;

void main() async {
  F.appFlavor = Flavor.SMLMOBILESALES;
  global.posVersion = global.PosVersionEnum.smlmobilepos;
  await initializeEnvironmentConfig();
  await initializeApp(); // ⭐ เพิ่มบรรทัดนี้ - จะ preload เสียงอัตโนมัติ
  runApp(const App());
}
