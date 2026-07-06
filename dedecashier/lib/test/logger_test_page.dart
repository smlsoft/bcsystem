import 'package:flutter/material.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

/// ทดสอบ AppLogger clickable paths
///
/// วิธีทดสอบ:
/// 1. รัน app ใน debug mode
/// 2. ไปที่หน้าจอนี้
/// 3. กดปุ่ม "Test Logger"
/// 4. ดู Debug Console
/// 5. คลิกที่ file path ใน log → VSCode จะเปิดไฟล์ได้เลย!

class LoggerTestPage extends StatelessWidget {
  const LoggerTestPage({super.key});

  void _testLogger() {
    AppLogger.separator('Logger Clickable Test');

    // Test 1: Debug log
    AppLogger.debug(
      '🐛 This is a debug message - try clicking the path above!',
    );

    // Test 2: Info log
    AppLogger.info('ℹ️ This is an info message');

    // Test 3: Warning
    AppLogger.warning('⚠️ This is a warning message');

    // Test 4: Error
    AppLogger.error('❌ This is an error message');

    // Test 5: Success helper
    AppLogger.success('Operation completed successfully');

    // Test 6: Timing
    AppLogger.timing('Database query', 150);

    // Test 7: List
    AppLogger.list('Test items', ['Item 1', 'Item 2', 'Item 3']);

    AppLogger.separator();

    AppLogger.info('✅ Click any file path above to open the file!');
    AppLogger.info('💡 Format: lib/path/to/file.dart:lineNumber');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logger Clickable Test'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bug_report, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'AppLogger Clickable Path Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _testLogger,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Test Logger'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'กดปุ่ม "Test Logger" แล้วดู Debug Console\n'
                'คลิกที่ file path (เช่น lib/test/logger_test_page.dart:25)\n'
                'VSCode จะเปิดไฟล์และไปที่บรรทัดนั้นเลย!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
