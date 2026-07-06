import 'package:flutter/foundation.dart';

/// ทดสอบดู StackTrace format จริงๆ
void testStackTrace() {
  if (kDebugMode) {
    final stackTrace = StackTrace.current.toString();
    print('=== FULL STACK TRACE ===');
    print(stackTrace);
    print('=== END STACK TRACE ===');

    final lines = stackTrace.split('\n');
    print('\n=== PARSING EACH LINE ===');
    for (var i = 0; i < lines.length && i < 10; i++) {
      final line = lines[i];
      print('Line $i: $line');

      if (line.contains('package:dedecashier/')) {
        final match = RegExp(
          r'package:dedecashier/(.+\.dart):(\d+):\d+',
        ).firstMatch(line);
        if (match != null) {
          print('  ✅ Match found!');
          print('  - Full match: ${match.group(0)}');
          print('  - File path: ${match.group(1)}');
          print('  - Line number: ${match.group(2)}');
        }
      }
    }
  }
}
