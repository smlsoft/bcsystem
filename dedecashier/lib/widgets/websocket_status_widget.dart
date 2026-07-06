/// WebSocket Connection Status Widget
///
/// แสดงสถานะการเชื่อมต่อ WebSocket real-time
/// ✅ Connection status (online/offline)
/// ✅ Connected clients count (for Terminal)
/// ✅ Offline queue size (for Remote)
/// ✅ Auto reconnect indicator

import 'package:flutter/material.dart';
import 'package:dedecashier/api/network/websocket_server.dart';
import 'package:dedecashier/api/network/websocket_client.dart' as ws_client;
import 'package:dedecashier/global.dart' as global;
import 'dart:async';

/// Connection status indicator widget
class WebSocketStatusWidget extends StatefulWidget {
  final bool isCompact;
  final VoidCallback? onTap;

  const WebSocketStatusWidget({super.key, this.isCompact = true, this.onTap});

  @override
  State<WebSocketStatusWidget> createState() => _WebSocketStatusWidgetState();
}

class _WebSocketStatusWidgetState extends State<WebSocketStatusWidget> {
  Timer? _updateTimer;
  bool _isConnected = false;
  int _clientsCount = 0;
  int _queueSize = 0;

  @override
  void initState() {
    super.initState();
    _startUpdateTimer();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (global.appMode == global.AppModeEnum.posTerminal) {
            // Terminal mode: show clients count
            _isConnected = WebSocketServer().isRunning;
            _clientsCount = WebSocketServer().connectedClientsCount;
          } else {
            // Remote mode: show connection status and queue
            _isConnected = ws_client.WebSocketClient().isConnected;
            _queueSize = ws_client.WebSocketClient().queueSize;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactView();
    } else {
      return _buildDetailedView();
    }
  }

  Widget _buildCompactView() {
    return InkWell(
      onTap: widget.onTap ?? _showStatusDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isConnected ? Colors.green : Colors.red,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                boxShadow: _isConnected
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            // Status text
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _isConnected
                    ? Colors.green.shade900
                    : Colors.red.shade900,
              ),
            ),
            // Badge for counts
            if (_shouldShowBadge())
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getBadgeText(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedView() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap ?? _showStatusDialog,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    _isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: _isConnected ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WebSocket Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isConnected ? 'ONLINE' : 'OFFLINE',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Details
              if (global.appMode == global.AppModeEnum.posTerminal) ...[
                _buildInfoRow('Mode', 'Terminal (Server)'),
                _buildInfoRow('Connected Clients', '$_clientsCount'),
                _buildInfoRow(
                  'Server Status',
                  _isConnected ? 'Running' : 'Stopped',
                ),
              ] else ...[
                _buildInfoRow('Mode', 'Remote (Client)'),
                _buildInfoRow(
                  'Connection',
                  _isConnected ? 'Connected' : 'Disconnected',
                ),
                _buildInfoRow('Offline Queue', '$_queueSize messages'),
                if (!_isConnected && _queueSize > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Offline mode: $_queueSize messages pending',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (global.appMode == global.AppModeEnum.posTerminal) {
      return _isConnected ? 'Server' : 'Offline';
    } else {
      return _isConnected ? 'Connected' : 'Offline';
    }
  }

  String _getBadgeText() {
    if (global.appMode == global.AppModeEnum.posTerminal) {
      return '$_clientsCount';
    } else {
      return '$_queueSize';
    }
  }

  bool _shouldShowBadge() {
    if (global.appMode == global.AppModeEnum.posTerminal) {
      return _clientsCount > 0;
    } else {
      return _queueSize > 0;
    }
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _isConnected ? Icons.check_circle : Icons.error,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('WebSocket Status'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (global.appMode == global.AppModeEnum.posTerminal) ...[
                _buildDialogInfoRow('Mode', 'POS Terminal (Server)'),
                _buildDialogInfoRow(
                  'Status',
                  _isConnected ? 'Running' : 'Stopped',
                ),
                _buildDialogInfoRow('Clients', '$_clientsCount connected'),
                _buildDialogInfoRow('IP', global.ipAddress),
                _buildDialogInfoRow('Port', '${global.targetDeviceIpPort}'),
                const Divider(),
                const Text(
                  'Connected Devices:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_clientsCount > 0)
                  ...WebSocketServer().getConnectedClients().map(
                    (client) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.devices, size: 20),
                        title: Text(
                          client['deviceName'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          '${client['ip']} • Hold: ${client['holdCodeActive'] ?? 'None'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  )
                else
                  const Text(
                    'No clients connected',
                    style: TextStyle(color: Colors.grey),
                  ),
              ] else ...[
                _buildDialogInfoRow('Mode', 'POS Remote (Client)'),
                _buildDialogInfoRow(
                  'Status',
                  _isConnected ? 'Connected' : 'Disconnected',
                ),
                _buildDialogInfoRow('Server IP', global.targetDeviceIpAddress),
                _buildDialogInfoRow(
                  'Server Port',
                  '${global.targetDeviceIpPort}',
                ),
                _buildDialogInfoRow('Offline Queue', '$_queueSize messages'),
                if (!_isConnected)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Connection lost. Auto reconnecting...\n$_queueSize messages queued.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (global.appMode == global.AppModeEnum.posRemote && !_isConnected)
            ElevatedButton.icon(
              onPressed: () {
                ws_client.WebSocketClient().connect();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reconnect'),
            ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Connection status indicator for AppBar
class AppBarWebSocketStatus extends StatelessWidget {
  const AppBarWebSocketStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: WebSocketStatusWidget(isCompact: true),
    );
  }
}
