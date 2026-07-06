import 'dart:io';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/objectbox/objectbox.g.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<void> objectBoxInit() async {
  final appDirectory = await getApplicationDocumentsDirectory();
  final objectBoxDirectory = Directory("${appDirectory.path}/objectboxdata");
  try {
    await objectBoxDirectory.create(recursive: true);
    global.objectBoxStore = Store(getObjectBoxModel(),
        queriesCaseSensitiveDefault: false, directory: objectBoxDirectory.path);
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
      print(s);
    }
  }
}
