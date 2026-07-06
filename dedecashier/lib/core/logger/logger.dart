import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

abstract class Log {
  void trace(dynamic message, {dynamic error, StackTrace? stackTrace});
  void debug(dynamic message, {dynamic error, StackTrace? stackTrace});
  void info(dynamic message, {dynamic error, StackTrace? stackTrace});
  void warn(dynamic message, {dynamic error, StackTrace? stackTrace});
  void error(dynamic message, {dynamic error, StackTrace? stackTrace});
  void dangerFailure(dynamic message, {dynamic error, StackTrace? stackTrace});
}

/// Custom Logger Printer ที่แสดง filename:line
class CustomLogPrinter extends LogPrinter {
  final String? className;
  final bool printTime;
  final bool printEmojis;
  final bool colors;

  CustomLogPrinter({
    this.className,
    this.printTime = true,
    this.printEmojis = true,
    this.colors = false,
  });

  @override
  List<String> log(LogEvent event) {
    final emoji = PrettyPrinter.defaultLevelEmojis[event.level];
    final message = event.message;

    // ดึง StackTrace เพื่อหาชื่อไฟล์และบรรทัด
    String fileInfo = _getFileInfo();

    // สร้าง timestamp
    String timeStr = '';
    if (printTime) {
      final now = DateTime.now();
      timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    }

    // สร้าง level emoji/text
    String levelStr = '';
    if (printEmojis && emoji != null) {
      levelStr = '$emoji ';
    }
    levelStr += event.level
        .toString()
        .split('.')
        .last
        .toUpperCase()
        .padRight(5);

    // Format: [HH:MM:SS.mmm] [LEVEL] (file:line) message
    // ✅ ใช้วงเล็บ () เพื่อให้ VSCode Debug Console รู้จักและคลิกได้
    final output = StringBuffer();

    if (printTime) {
      output.write('[$timeStr] ');
    }

    output.write('[$levelStr] ');
    output.write('($fileInfo) '); // ✅ ใช้ () เพื่อให้ Debug Console คลิกได้
    output.write(message);

    // เพิ่ม error ถ้ามี
    if (event.error != null) {
      output.write('\n    ❌ Error: ${event.error}');
    }

    // เพิ่ม stackTrace ถ้ามี
    if (event.stackTrace != null) {
      output.write('\n${event.stackTrace}');
    }

    return [output.toString()];
  }

  /// ดึงชื่อไฟล์และบรรทัดจาก StackTrace
  /// ✅ Return full path เพื่อให้ VSCode รู้จักและคลิกได้
  /// Format: C:/path/to/file.dart:line:column (Windows absolute path)
  String _getFileInfo() {
    try {
      final stackTrace = StackTrace.current.toString();
      final lines = stackTrace.split('\n');

      // หาบรรทัดที่ไม่ใช่ logger.dart, log.dart
      for (var line in lines) {
        if (line.contains('package:dedecashier/') &&
            !line.contains('logger.dart') &&
            !line.contains('/core/logger/')) {
          // Extract full path and line number
          // ✅ Regex จับ path หลัง package:dedecashier/ ทั้งหมด
          final match = RegExp(
            r'package:dedecashier/(.+\.dart):(\d+):(\d+)',
          ).firstMatch(line);
          if (match != null) {
            var filePath = match.group(
              1,
            ); // e.g., "global.dart" or "lib/features/pos/pos_screen.dart"
            final lineNumber = match.group(2);
            final columnNumber = match.group(3);

            // ✅ Ensure path starts with "lib/"
            // Dart StackTrace format:
            // - Root files: package:dedecashier/global.dart → global.dart
            // - Subdir files: package:dedecashier/lib/features/... → lib/features/...
            if (!filePath!.startsWith('lib/')) {
              filePath = 'lib/$filePath';
            }

            // ✅ Return format that VSCode Debug Console can detect
            // Try absolute Windows path format: C:/gif/dedecashier/lib/global.dart:2819:5
            // This is the most reliable format for VSCode link detection
            final workspacePath = 'C:/gif/dedecashier'; // TODO: Get dynamically
            return '$workspacePath/$filePath:$lineNumber:$columnNumber';
          }
        }
      }

      // ถ้าหาไม่เจอ ให้แสดง className (ถ้ามี)
      if (className != null) {
        return className!;
      }

      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }
}

class LogImpl implements Log {
  late final Logger logger;

  LogImpl() {
    logger = Logger(
      printer: CustomLogPrinter(
        printTime: true,
        printEmojis: true,
        colors: false,
      ),
      level: kDebugMode ? Level.trace : Level.info,
    );
  }

  @override
  void trace(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      logger.t(message, error: error, stackTrace: stackTrace);
    }
  }

  @override
  void debug(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  @override
  void info(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    logger.i(message, error: error, stackTrace: stackTrace);
  }

  @override
  void warn(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    logger.w(message, error: error, stackTrace: stackTrace);
  }

  @override
  void error(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    logger.e(message, error: error, stackTrace: stackTrace);
  }

  @override
  void dangerFailure(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    logger.f(message, error: error, stackTrace: stackTrace);
  }
}
