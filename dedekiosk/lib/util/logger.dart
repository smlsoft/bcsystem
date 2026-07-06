import 'package:flutter/foundation.dart';

/// Debug-only logging utility for DeDe Kiosk
///
/// This logger will only output in debug mode (kDebugMode = true)
/// In production builds, all logs are stripped out by the compiler
///
/// Usage:
/// ```dart
/// Logger.d('Debug message');
/// Logger.i('Info message');
/// Logger.w('Warning message');
/// Logger.e('Error message', error: e, stackTrace: s);
/// ```
class Logger {
  // Prefix for all logs to easily identify DeDe Kiosk logs
  static const String _prefix = '[DeDe Kiosk]';

  /// Debug log - for detailed debugging information
  /// Only appears in debug mode
  static void d(String message, {String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix$tagStr [DEBUG] $message');
    }
  }

  /// Info log - for general information
  /// Only appears in debug mode
  static void i(String message, {String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix$tagStr [INFO] $message');
    }
  }

  /// Warning log - for warnings that should be investigated
  /// Only appears in debug mode
  static void w(String message, {String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix$tagStr [WARN] ⚠️ $message');
    }
  }

  /// Error log - for errors with optional error object and stack trace
  /// Only appears in debug mode
  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix$tagStr [ERROR] ❌ $message');
      if (error != null) {
        debugPrint('$_prefix$tagStr [ERROR] Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('$_prefix$tagStr [ERROR] Stack trace: $stackTrace');
      }
    }
  }

  /// Performance log - for performance-related debugging
  /// Only appears in debug mode
  static void perf(String message, {String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix$tagStr [PERF] ⚡ $message');
    }
  }

  /// Network log - for network-related debugging
  /// Only appears in debug mode
  static void network(String message, {String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix$tagStr [NET] 🌐 $message');
    }
  }

  /// Timer to measure execution time of code blocks
  /// Only works in debug mode
  ///
  /// Usage:
  /// ```dart
  /// final timer = Logger.startTimer('My Operation');
  /// // ... do some work
  /// timer.stop();
  /// ```
  static LogTimer startTimer(String operation) {
    return LogTimer(operation);
  }
}

/// Timer for measuring execution time
/// Only works in debug mode
class LogTimer {
  final String operation;
  final DateTime startTime;

  LogTimer(this.operation) : startTime = DateTime.now() {
    if (kDebugMode) {
      Logger.d('Started: $operation');
    }
  }

  /// Stop the timer and log the duration
  void stop() {
    if (kDebugMode) {
      final duration = DateTime.now().difference(startTime);
      Logger.perf('$operation took ${duration.inMilliseconds}ms');
    }
  }
}

/// Extension method to easily log objects
/// Only works in debug mode
extension LogExtension on Object? {
  /// Log this object with optional tag
  void log({String? tag, String? label}) {
    if (kDebugMode) {
      final labelStr = label != null ? '$label: ' : '';
      Logger.d('$labelStr$this', tag: tag);
    }
  }
}
