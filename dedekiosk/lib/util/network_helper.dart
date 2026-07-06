import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../global.dart' as global;
import 'logger.dart';

/// Network timeout constants for different types of operations
class NetworkTimeouts {
  /// Quick operations like stock check (5 seconds)
  static const Duration quick = Duration(seconds: 5);

  /// Standard operations (10 seconds)
  static const Duration standard = Duration(seconds: 10);

  /// Long operations like payment, order save (15 seconds)
  static const Duration long = Duration(seconds: 15);

  /// Background sync operations (30 seconds)
  static const Duration background = Duration(seconds: 30);
}

/// Result wrapper for network operations
class NetworkResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  final NetworkErrorType? errorType;

  NetworkResult.success(this.data)
      : error = null,
        isSuccess = true,
        errorType = null;

  NetworkResult.failure(this.error, {this.errorType})
      : data = null,
        isSuccess = false;
}

/// Types of network errors
enum NetworkErrorType {
  timeout,
  noConnection,
  serverError,
  unknown,
}

/// Network Helper - Centralized timeout and retry management
class NetworkHelper {
  /// Execute operation with retry logic and timeout
  ///
  /// Example:
  /// ```dart
  /// var result = await NetworkHelper.executeWithRetry<Map>(
  ///   operation: () => api.clickHouseSelect(query),
  ///   timeout: NetworkTimeouts.standard,
  ///   maxRetries: 2,
  /// );
  ///
  /// if (result.isSuccess) {
  ///   // Use result.data
  /// } else {
  ///   // Handle result.error
  /// }
  /// ```
  static Future<NetworkResult<T>> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration timeout = NetworkTimeouts.standard,
    bool exponentialBackoff = true,
    bool logErrors = true,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;

      try {
        // Execute operation with timeout
        final result = await operation().timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException(
              'Operation timed out after ${timeout.inSeconds} seconds',
            );
          },
        );

        return NetworkResult.success(result);

      } on TimeoutException catch (e) {
        if (logErrors) {
          Logger.w('Network timeout on attempt $attempt/$maxRetries: $e');
        }

        // Last attempt - return failure
        if (attempt >= maxRetries) {
          return NetworkResult.failure(
            'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง',
            errorType: NetworkErrorType.timeout,
          );
        }

        // Wait before retry (exponential backoff)
        if (exponentialBackoff) {
          await Future.delayed(Duration(seconds: attempt * 2));
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }

      } on SocketException catch (e) {
        if (logErrors) {
          Logger.w('Network connection error on attempt $attempt/$maxRetries: $e');
        }

        if (attempt >= maxRetries) {
          return NetworkResult.failure(
            'ไม่สามารถเชื่อมต่อเครือข่ายได้ กรุณาตรวจสอบการเชื่อมต่อ',
            errorType: NetworkErrorType.noConnection,
          );
        }

        await Future.delayed(Duration(seconds: attempt));

      } on DioException catch (e) {
        if (logErrors) {
          Logger.w('Dio error on attempt $attempt/$maxRetries: ${e.message}');
        }

        // Check if it's a timeout
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          if (attempt >= maxRetries) {
            return NetworkResult.failure(
              'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง',
              errorType: NetworkErrorType.timeout,
            );
          }
        } else {
          // Other Dio errors - don't retry
          return NetworkResult.failure(
            'เกิดข้อผิดพลาด: ${e.message ?? "Unknown error"}',
            errorType: NetworkErrorType.serverError,
          );
        }

        await Future.delayed(Duration(seconds: attempt));

      } on http.ClientException catch (e) {
        if (logErrors) {
          Logger.w('HTTP client error on attempt $attempt/$maxRetries: $e');
        }

        if (attempt >= maxRetries) {
          return NetworkResult.failure(
            'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
            errorType: NetworkErrorType.noConnection,
          );
        }

        await Future.delayed(Duration(seconds: attempt));

      } catch (e, s) {
        if (logErrors) {
          Logger.e('Unexpected error on attempt $attempt/$maxRetries',
                   error: e, stackTrace: s);
        }

        if (attempt >= maxRetries) {
          return NetworkResult.failure(
            'เกิดข้อผิดพลาดที่ไม่คาดคิด: ${e.toString()}',
            errorType: NetworkErrorType.unknown,
          );
        }

        await Future.delayed(Duration(seconds: attempt));
      }
    }

    // Should never reach here, but just in case
    return NetworkResult.failure(
      'การดำเนินการล้มเหลวหลังจากลองใหม่ $maxRetries ครั้ง',
      errorType: NetworkErrorType.unknown,
    );
  }

  /// Check if network is available
  ///
  /// Returns true if able to resolve DNS lookup
  static Future<bool> isNetworkAvailable() async {
    try {
      // Try to lookup a domain
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      Logger.w('Network not available: $e');
      return false;
    }
  }

  /// Get user-friendly error message based on error type
  static String getErrorMessage(
    NetworkErrorType? errorType,
    String languageCode,
  ) {
    if (languageCode == 'th') {
      switch (errorType) {
        case NetworkErrorType.timeout:
          return 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
        case NetworkErrorType.noConnection:
          return 'ไม่สามารถเชื่อมต่อเครือข่ายได้ กรุณาตรวจสอบการเชื่อมต่อ';
        case NetworkErrorType.serverError:
          return 'เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่ภายหลัง';
        case NetworkErrorType.unknown:
        default:
          return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
      }
    } else {
      // English
      switch (errorType) {
        case NetworkErrorType.timeout:
          return 'Connection timeout. Please try again.';
        case NetworkErrorType.noConnection:
          return 'No network connection. Please check your connection.';
        case NetworkErrorType.serverError:
          return 'Server error. Please try again later.';
        case NetworkErrorType.unknown:
        default:
          return 'An error occurred. Please try again.';
      }
    }
  }

  /// Send error to dev team (wrapper for global function)
  static void reportError(String context, dynamic error, [StackTrace? stackTrace]) {
    try {
      final errorMessage = '$context: $error';
      if (kDebugMode) {
        print('Network Error: $errorMessage');
        if (stackTrace != null) {
          print('Stack trace: $stackTrace');
        }
      }
      global.sendErrorToDevTeam(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to report error: $e');
      }
    }
  }
}

/// Circuit Breaker pattern - prevents repeated calls to failing services
class CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration timeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitBreakerState _state = CircuitBreakerState.closed;

  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.timeout = const Duration(minutes: 1),
  });

  /// Check if circuit breaker allows the call
  bool get isOpen => _state == CircuitBreakerState.open;

  /// Execute operation with circuit breaker protection
  Future<T?> execute<T>(Future<T> Function() operation) async {
    // Check if circuit is open
    if (_state == CircuitBreakerState.open) {
      final timeSinceLastFailure = DateTime.now().difference(_lastFailureTime!);

      if (timeSinceLastFailure > timeout) {
        // Try to half-open the circuit
        _state = CircuitBreakerState.halfOpen;
        Logger.d('Circuit breaker $name: half-open');
      } else {
        Logger.w('Circuit breaker $name: open - rejecting call');
        return null;
      }
    }

    try {
      final result = await operation();

      // Success - reset circuit
      if (_state == CircuitBreakerState.halfOpen) {
        _state = CircuitBreakerState.closed;
        _failureCount = 0;
        Logger.d('Circuit breaker $name: closed');
      }

      return result;

    } catch (e) {
      _failureCount++;
      _lastFailureTime = DateTime.now();

      Logger.w('Circuit breaker $name: failure $_failureCount/$failureThreshold');

      if (_failureCount >= failureThreshold) {
        _state = CircuitBreakerState.open;
        Logger.w('Circuit breaker $name: OPEN');
      }

      rethrow;
    }
  }

  /// Reset circuit breaker
  void reset() {
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _lastFailureTime = null;
    Logger.d('Circuit breaker $name: manually reset');
  }
}

enum CircuitBreakerState {
  closed,  // Normal operation
  open,    // Blocking calls
  halfOpen, // Testing if service recovered
}
