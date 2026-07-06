import 'package:flutter/material.dart';
import 'package:dedecashier/bootstrap.dart';
import 'app.dart';
import 'flavors.dart';
import 'package:dedecashier/global.dart' as global;

void main() async {
  F.appFlavor = Flavor.SMLSUPERPOS;
  global.posVersion = global.PosVersionEnum.pos;
  await initializeEnvironmentConfig();
  await initializeApp(); // ⭐ เพิ่มบรรทัดนี้ - จะ preload เสียงอัตโนมัติ
  runApp(const App());
}
