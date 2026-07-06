import 'dart:async';
import 'package:flutter/material.dart';
import '../global.dart' as global;
import '../util/network_helper.dart';
import 'network_loading_indicator.dart';

/// Network status widget with auto-refresh
/// แสดงสถานะ network และ pending sync count
class NetworkStatusWidget extends StatefulWidget {
  final Duration refreshInterval;

  const NetworkStatusWidget({
    super.key,
    this.refreshInterval = const Duration(seconds: 10),
  });

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  NetworkStatus _status = NetworkStatus.online;
  Timer? _refreshTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkNetworkStatus();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(widget.refreshInterval, (timer) {
      _checkNetworkStatus();
    });
  }

  Future<void> _checkNetworkStatus() async {
    if (_isChecking) return;

    _isChecking = true;
    try {
      final isAvailable = await NetworkHelper.isNetworkAvailable();

      if (mounted) {
        setState(() {
          _status = isAvailable ? NetworkStatus.online : NetworkStatus.offline;
        });
      }
    } finally {
      _isChecking = false;
    }
  }

  int _getPendingSyncCount() {
    // นับจำนวน pending transactions
    // อาจต้องอ่านจาก offline_transaction_service.dart
    return 0; // TODO: Implement actual counting
  }

  void _onTap() {
    // แสดง dialog หรือ trigger force sync
    if (_status == NetworkStatus.offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(global.language("offline_mode")),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Force sync
      _checkNetworkStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NetworkStatusBanner(
      status: _status,
      pendingSyncCount: _getPendingSyncCount(),
      onTap: _onTap,
    );
  }
}

/// Network status bar - วางที่ด้านบนของหน้าจอ
class NetworkStatusBar extends StatelessWidget {
  const NetworkStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: NetworkStatusWidget(),
    );
  }
}
