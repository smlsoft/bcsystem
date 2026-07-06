#!/usr/bin/env dart

/// 🔍 Sound Integration Guide Generator
///
/// สคริปต์นี้จะวิเคราะห์ไฟล์ทั้งหมดและสร้างคู่มือว่าควรเพิ่มเสียงที่ไหนบ้าง
///
/// วิธีใช้:
/// ```bash
/// dart run lib/util/sound_integration_guide.dart
/// ```

import 'dart:io';
import 'package:dedecashier/core/logger/app_logger.dart';

void main() async {
  AppLogger.debug('🔊 Sound Integration Guide Generator');
  AppLogger.debug('=' * 60);

  final screens = await findScreenFiles();

  AppLogger.info('\n📊 พบหน้าจอทั้งหมด: ${screens.length} ไฟล์\n');

  for (final screen in screens) {
    await analyzeScreen(screen);
  }

  AppLogger.debug('\n' + '=' * 60);
  AppLogger.success('✅ วิเคราะห์เสร็จสมบูรณ์!');
  AppLogger.debug('\n📝 คำแนะนำ:');
  AppLogger.debug('1. เพิ่ม import:');
  AppLogger.debug('   import \'package:dedecashier/util/widget_sound_extensions.dart\';');
  AppLogger.debug('');
  AppLogger.debug('2. เพิ่มเสียงให้ปุ่มโดยใช้ extension:');
  AppLogger.debug('onPressed: () { ... }.withButtonSound()');
  AppLogger.debug('');
  AppLogger.debug('3. หรือใช้ Sound UI Helpers สำหรับ widgets ใหม่:');
  AppLogger.debug('SoundElevatedButton(...)');
}

Future<List<File>> findScreenFiles() async {
  final files = <File>[];
  final dir = Directory('lib');

  if (!await dir.exists()) {
    AppLogger.error('❌ ไม่พบโฟลเดอร์ lib');
    return files;
  }

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final filename = entity.path.split(Platform.pathSeparator).last;
      if (filename.contains('screen') ||
          filename.contains('page') ||
          filename.contains('dialog')) {
        files.add(entity);
      }
    }
  }

  return files;
}

Future<void> analyzeScreen(File file) async {
  final content = await file.readAsString();
  final filename = file.path.split(Platform.pathSeparator).last;

  // นับปุ่มทั้งหมด
  final buttons = <String, int>{
    'ElevatedButton': _countPattern(content, r'ElevatedButton\s*\('),
    'TextButton': _countPattern(content, r'TextButton\s*\('),
    'IconButton': _countPattern(content, r'IconButton\s*\('),
    'InkWell': _countPattern(content, r'InkWell\s*\('),
    'GestureDetector': _countPattern(content, r'GestureDetector\s*\('),
  };

  final totalButtons = buttons.values.reduce((a, b) => a + b);

  if (totalButtons == 0) return;

  AppLogger.debug('📄 $filename');
  AppLogger.debug('ปุ่มทั้งหมด: $totalButtons');
  buttons.forEach((type, count) {
    if (count > 0) {
      AppLogger.debug('- $type: $count');
    }
  });
  AppLogger.debug('');
}

int _countPattern(String content, String pattern) {
  final regex = RegExp(pattern);
  return regex.allMatches(content).length;
}
