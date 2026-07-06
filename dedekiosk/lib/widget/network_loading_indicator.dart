import 'package:flutter/material.dart';
import '../global.dart' as global;

/// Fullscreen loading overlay with optional message and cancel button
class NetworkLoadingOverlay extends StatelessWidget {
  final String? message;
  final VoidCallback? onCancel;
  final bool dismissible;

  const NetworkLoadingOverlay({
    super.key,
    this.message,
    this.onCancel,
    this.dismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: dismissible,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (onCancel != null) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: onCancel,
                      child: Text(global.language("cancel")),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Show loading overlay
  static void show(
    BuildContext context, {
    String? message,
    VoidCallback? onCancel,
    bool dismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => NetworkLoadingOverlay(
        message: message,
        onCancel: onCancel,
        dismissible: dismissible,
      ),
    );
  }

  /// Hide loading overlay
  static void hide(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

/// Execute operation with loading indicator
Future<T?> withLoadingIndicator<T>({
  required BuildContext context,
  required Future<T> Function() operation,
  String? message,
  bool dismissible = false,
  VoidCallback? onCancel,
}) async {
  // Show loading
  NetworkLoadingOverlay.show(
    context,
    message: message,
    onCancel: onCancel,
    dismissible: dismissible,
  );

  try {
    // Execute operation
    final result = await operation();
    return result;
  } finally {
    // Hide loading (check if context is still mounted)
    if (context.mounted) {
      NetworkLoadingOverlay.hide(context);
    }
  }
}

/// Network status indicator banner
class NetworkStatusBanner extends StatelessWidget {
  final NetworkStatus status;
  final int? pendingSyncCount;
  final VoidCallback? onTap;

  const NetworkStatusBanner({
    super.key,
    required this.status,
    this.pendingSyncCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    IconData icon;
    String message;

    switch (status) {
      case NetworkStatus.online:
        backgroundColor = Colors.green;
        icon = Icons.wifi;
        message = 'Online';
        break;
      case NetworkStatus.offline:
        backgroundColor = Colors.red;
        icon = Icons.wifi_off;
        message = global.language("offline_mode");
        break;
      case NetworkStatus.slow:
        backgroundColor = Colors.orange;
        icon = Icons.signal_wifi_statusbar_4_bar;
        message = 'Slow Connection';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: backgroundColor,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (pendingSyncCount != null && pendingSyncCount! > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(76), // 0.3 * 255 = 76
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${global.language("pending_sync")}: $pendingSyncCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum NetworkStatus {
  online,
  offline,
  slow,
}

/// Progress indicator with percentage
class NetworkProgressSheet extends StatelessWidget {
  final String operation;
  final int? progress; // 0-100
  final VoidCallback? onCancel;

  const NetworkProgressSheet({
    super.key,
    required this.operation,
    this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            operation,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (progress != null) ...[
            LinearProgressIndicator(value: progress! / 100),
            const SizedBox(height: 8),
            Text('$progress%'),
          ] else ...[
            const LinearProgressIndicator(),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onCancel,
              child: Text(global.language("cancel")),
            ),
          ],
        ],
      ),
    );
  }

  /// Show progress sheet
  static void show(
    BuildContext context, {
    required String operation,
    int? progress,
    VoidCallback? onCancel,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => NetworkProgressSheet(
        operation: operation,
        progress: progress,
        onCancel: onCancel,
      ),
    );
  }

  /// Hide progress sheet
  static void hide(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
