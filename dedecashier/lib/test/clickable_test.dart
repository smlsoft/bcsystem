import 'package:flutter/foundation.dart';
import '../core/logger/app_logger.dart';

/// ทดสอบ clickable path ใน Debug Console
void testClickablePaths() {
  if (kDebugMode) {
    print('\n=== Testing Clickable Paths in Debug Console ===\n');

    // Test 1: Debug log
    AppLogger.debug(
      '🧪 Test 1: This is a debug message from clickable_test.dart',
    );

    // Test 2: Info log
    AppLogger.info('🧪 Test 2: This is an info message');

    // Test 3: Warning log
    AppLogger.warning('🧪 Test 3: This is a warning message');

    // Test 4: Error log
    AppLogger.error('🧪 Test 4: This is an error message');

    print('\n✅ Test completed! Now check Debug Console:');
    print('1. Look at the file paths in the log messages');
    print('2. They should look like: lib/test/clickable_test.dart:XX');
    print('3. Try Ctrl+Click (Windows) or Cmd+Click (Mac) on the path');
    print('4. VSCode should open this file at the exact line!');
    print('\n📝 Expected format: lib/test/clickable_test.dart:12\n');
  }
}
