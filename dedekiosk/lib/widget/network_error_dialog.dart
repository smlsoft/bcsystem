import 'package:flutter/material.dart';
import '../global.dart' as global;
import '../util/network_helper.dart';

/// Network error dialog with retry and cancel options
class NetworkErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final NetworkErrorType? errorType;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final VoidCallback? onContinue;
  final bool showContinue;

  const NetworkErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.errorType,
    this.onRetry,
    this.onCancel,
    this.onContinue,
    this.showContinue = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getIconForErrorType(errorType),
            color: _getColorForErrorType(errorType),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: _getColorForErrorType(errorType),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _getHintForErrorType(errorType),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        if (onCancel != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
            child: Text(
              global.language("cancel"),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        if (showContinue && onContinue != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onContinue?.call();
            },
            child: Text(
              global.language("continue_anyway"),
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        if (onRetry != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getColorForErrorType(errorType),
            ),
            child: Text(
              global.language("retry"),
              style: const TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }

  IconData _getIconForErrorType(NetworkErrorType? type) {
    switch (type) {
      case NetworkErrorType.timeout:
        return Icons.access_time;
      case NetworkErrorType.noConnection:
        return Icons.wifi_off;
      case NetworkErrorType.serverError:
        return Icons.error_outline;
      case NetworkErrorType.unknown:
      default:
        return Icons.warning_amber;
    }
  }

  Color _getColorForErrorType(NetworkErrorType? type) {
    switch (type) {
      case NetworkErrorType.timeout:
        return Colors.orange;
      case NetworkErrorType.noConnection:
        return Colors.red;
      case NetworkErrorType.serverError:
        return Colors.deepOrange;
      case NetworkErrorType.unknown:
      default:
        return Colors.amber;
    }
  }

  String _getHintForErrorType(NetworkErrorType? type) {
    switch (type) {
      case NetworkErrorType.timeout:
        return 'เครือข่ายช้า ลองใหม่อีกครั้งหรือตรวจสอบการเชื่อมต่อ';
      case NetworkErrorType.noConnection:
        return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต กรุณาเชื่อมต่อ WiFi หรือข้อมูลมือถือ';
      case NetworkErrorType.serverError:
        return 'เซิร์ฟเวอร์ขัดข้อง ลองใหม่ภายหลัง';
      case NetworkErrorType.unknown:
      default:
        return 'เกิดข้อผิดพลาดที่ไม่คาดคิด';
    }
  }

  /// Show timeout error dialog
  static Future<bool?> showTimeoutError(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
    VoidCallback? onContinue,
    bool showContinue = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NetworkErrorDialog(
        title: global.language("network_timeout"),
        message: customMessage ?? global.language("operation_timeout"),
        errorType: NetworkErrorType.timeout,
        onRetry: onRetry,
        onCancel: onCancel,
        onContinue: onContinue,
        showContinue: showContinue,
      ),
    );
  }

  /// Show connection error dialog
  static Future<bool?> showConnectionError(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NetworkErrorDialog(
        title: global.language("network_error"),
        message: customMessage ?? 'ไม่สามารถเชื่อมต่อเครือข่ายได้',
        errorType: NetworkErrorType.noConnection,
        onRetry: onRetry,
        onCancel: onCancel,
      ),
    );
  }

  /// Show server error dialog
  static Future<bool?> showServerError(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NetworkErrorDialog(
        title: global.language("error"),
        message: customMessage ?? 'เซิร์ฟเวอร์ขัดข้อง',
        errorType: NetworkErrorType.serverError,
        onRetry: onRetry,
        onCancel: onCancel,
      ),
    );
  }

  /// Show generic error dialog
  static Future<bool?> showGenericError(
    BuildContext context, {
    String? title,
    String? message,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NetworkErrorDialog(
        title: title ?? global.language("error"),
        message: message ?? 'เกิดข้อผิดพลาด',
        errorType: NetworkErrorType.unknown,
        onRetry: onRetry,
        onCancel: onCancel,
      ),
    );
  }
}

/// Simple error snackbar for non-critical errors
class NetworkErrorSnackbar {
  /// Show error snackbar
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    NetworkErrorType? errorType,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconForErrorType(errorType),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: _getColorForErrorType(errorType),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: global.language("retry"),
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  static IconData _getIconForErrorType(NetworkErrorType? type) {
    switch (type) {
      case NetworkErrorType.timeout:
        return Icons.access_time;
      case NetworkErrorType.noConnection:
        return Icons.wifi_off;
      case NetworkErrorType.serverError:
        return Icons.error_outline;
      case NetworkErrorType.unknown:
      default:
        return Icons.warning_amber;
    }
  }

  static Color _getColorForErrorType(NetworkErrorType? type) {
    switch (type) {
      case NetworkErrorType.timeout:
        return Colors.orange;
      case NetworkErrorType.noConnection:
        return Colors.red;
      case NetworkErrorType.serverError:
        return Colors.deepOrange;
      case NetworkErrorType.unknown:
      default:
        return Colors.amber;
    }
  }
}
