/// WebSocket Bootstrap
///
/// Initialize WebSocket connections based on app mode
/// ✅ Auto start server for Terminal mode
/// ✅ Auto connect client for Remote mode
/// ✅ Setup message handlers

import 'package:dedecashier/api/network/websocket_server.dart';
import 'package:dedecashier/api/network/websocket_client.dart' as ws_client;
import 'package:dedecashier/api/sync/model/sync_model.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/db/pos_log_helper.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/pos_log_struct.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter/foundation.dart';

/// Initialize WebSocket based on app mode
Future<void> initializeWebSocket() async {
  Stopwatch? stopwatch;
  if (kDebugMode) {
    stopwatch = Stopwatch()..start();
    AppLogger.info('[WebSocket Bootstrap] 🚀 Initializing...');
  }

  try {
    if (global.appMode == global.AppModeEnum.posTerminal) {
      // Terminal mode: Start WebSocket server
      await _startWebSocketServer();
    } else if (global.appMode == global.AppModeEnum.posRemote) {
      // Remote mode: Connect to WebSocket server
      await _connectWebSocketClient();
    }
  } catch (e, stackTrace) {
    AppLogger.error(
      '[WebSocket Bootstrap] ❌ Failed to initialize: $e\n$stackTrace',
    );
    global.sendErrorToDevTeam('websocket_bootstrap', '$e:$stackTrace');
  } finally {
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.info(
        '[WebSocket Bootstrap] ✅ Initialization completed in ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }
}

/// Start WebSocket server (Terminal mode)
Future<void> _startWebSocketServer() async {
  if (kDebugMode) {
    AppLogger.info(
      '[WebSocket Bootstrap] Starting server on ${global.ipAddress}:${global.targetDeviceIpPort}',
    );
  }

  try {
    // Store WebSocket server instance globally for broadcast access
    global.wsServer = WebSocketServer();
    await global.wsServer!.start();
    AppLogger.info('[WebSocket Bootstrap] ✅ Server started successfully');
  } catch (e) {
    AppLogger.error('[WebSocket Bootstrap] ❌ Failed to start server: $e');
    rethrow;
  }
}

/// Connect WebSocket client (Remote mode)
Future<void> _connectWebSocketClient() async {
  if (kDebugMode) {
    AppLogger.info(
      '[WebSocket Bootstrap] Connecting to ${global.targetDeviceIpAddress}:${global.targetDeviceIpPort}',
    );
  }

  try {
    // Setup message handlers first
    _setupMessageHandlers();

    // Connect to server
    await ws_client.WebSocketClient().connect();

    // Wait a bit for connection to establish
    await Future.delayed(Duration(milliseconds: 500));

    if (ws_client.WebSocketClient().isConnected) {
      // Register this device
      ws_client.WebSocketClient().register();
      AppLogger.info('[WebSocket Bootstrap] ✅ Client connected successfully');
    } else {
      AppLogger.warning(
        '[WebSocket Bootstrap] ⚠️ Client connection pending (will retry)',
      );
    }
  } catch (e) {
    AppLogger.error('[WebSocket Bootstrap] ❌ Failed to connect: $e');
    // Don't throw - let auto reconnect handle it
  }
}

/// Setup message handlers for client
void _setupMessageHandlers() {
  ws_client.WebSocketClient().addMessageHandler((message) {
    try {
      final type = message['type'] as String?;

      if (kDebugMode && type != null) {
        AppLogger.debug('[WebSocket Bootstrap] 📨 Message received: $type');
      }

      switch (type) {
        case 'process_result':
          _handleProcessResult(message);
          break;

        case 'notification':
          _handleNotification(message);
          break;

        case 'pos_log_update':
          _handlePosLogUpdate(message);
          break;

        case 'sync_response':
          _handleSyncResponse(message);
          break;

        case 'broadcast':
          _handleBroadcast(message);
          break;

        default:
          if (kDebugMode && type != null) {
            AppLogger.debug(
              '[WebSocket Bootstrap] Unhandled message type: $type',
            );
          }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '[WebSocket Bootstrap] Message handler error: $e\n$stackTrace',
      );
    }
  });

  AppLogger.info('[WebSocket Bootstrap] ✅ Message handlers registered');
}

/// Handle process result from server
void _handleProcessResult(Map<String, dynamic> message) {
  try {
    final holdCode = message['holdCode'] as String?;
    final data = message['data'] as Map<String, dynamic>?;

    if (holdCode != null && data != null) {
      AppLogger.debug('[WebSocket Bootstrap] Process result for $holdCode');

      // Update local state
      // TODO: Parse and update global.posHoldProcessResult

      // Refresh UI
      if (global.functionPosScreenRefresh != null) {
        global.functionPosScreenRefresh!(holdCode);
      }
    }
  } catch (e) {
    AppLogger.error(
      '[WebSocket Bootstrap] Failed to handle process result: $e',
    );
  }
}

/// Handle notification from server
void _handleNotification(Map<String, dynamic> message) {
  try {
    final title = message['title'] as String?;
    final body = message['message'] as String?;
    final priority = message['priority'] as String? ?? 'info';

    if (title != null || body != null) {
      final notificationText = title ?? body ?? '';
      AppLogger.info('[WebSocket Bootstrap] 🔔 Notification: $notificationText');

      // Log notification with appropriate level based on priority
      switch (priority.toLowerCase()) {
        case 'error':
        case 'critical':
          AppLogger.error('[Notification] $notificationText');
          break;
        case 'warning':
          AppLogger.warning('[Notification] $notificationText');
          break;
        case 'info':
        default:
          AppLogger.info('[Notification] $notificationText');
      }

      // TODO: Integrate with UI notification system
      // Options:
      // 1. Use flutter_local_notifications package
      // 2. Use top_snackbar_flutter for in-app notifications
      // 3. Add to global notification queue for UI to consume
    }
  } catch (e) {
    AppLogger.error('[WebSocket Bootstrap] Failed to handle notification: $e');
  }
}

/// Handle POS log update from server
void _handlePosLogUpdate(Map<String, dynamic> message) async {
  try {
    final action = message['action'] as String?;
    final data = message['data'] as Map<String, dynamic>?;
    final holdCode = message['holdCode'] as String?;

    if (data != null) {
      AppLogger.debug('[WebSocket Bootstrap] POS log update: $action');

      // Update local ObjectBox database based on action
      switch (action) {
        case 'insert':
        case 'update':
          // Parse and insert/update POS log
          final posLog = PosLogObjectBoxStruct.fromJson(data);
          await PosLogHelper().insert(posLog);
          AppLogger.debug('[WebSocket Bootstrap] POS log saved: ${posLog.guid_auto_fixed}');

          // Refresh UI if needed
          if (holdCode != null && global.functionPosScreenRefresh != null) {
            global.functionPosScreenRefresh!(holdCode);
          }
          break;

        case 'delete':
          // Delete POS log by GUID
          final guid = data['guid_auto_fixed'] as String?;
          if (guid != null) {
            final box = global.objectBoxStore.box<PosLogObjectBoxStruct>();
            final query = box.query(PosLogObjectBoxStruct_.guid_auto_fixed.equals(guid)).build();
            query.remove();
            AppLogger.debug('[WebSocket Bootstrap] POS log deleted: $guid');
          }
          break;

        case 'delete_by_hold_code':
          // Delete all logs for a hold code
          if (holdCode != null) {
            await PosLogHelper().deleteByHoldCode(holdCode: holdCode);
            AppLogger.debug('[WebSocket Bootstrap] POS logs deleted for hold: $holdCode');

            // Refresh UI
            if (global.functionPosScreenRefresh != null) {
              global.functionPosScreenRefresh!(holdCode);
            }
          }
          break;

        default:
          AppLogger.warning('[WebSocket Bootstrap] Unknown POS log action: $action');
      }
    }
  } catch (e) {
    AppLogger.error(
      '[WebSocket Bootstrap] Failed to handle POS log update: $e',
    );
  }
}

/// Handle sync response from server
void _handleSyncResponse(Map<String, dynamic> message) {
  try {
    final data = message['data'] as Map<String, dynamic>?;

    if (data != null) {
      AppLogger.info('[WebSocket Bootstrap] 🔄 Sync data received');

      // Update global state with server data

      // 1. Update POS hold process results
      if (data.containsKey('posHoldProcessResult')) {
        final posHoldResults = data['posHoldProcessResult'] as List?;
        if (posHoldResults != null) {
          global.posHoldProcessResult.clear();
          for (var item in posHoldResults) {
            if (item is Map<String, dynamic>) {
              try {
                final model = PosHoldProcessModel.fromJson(item);
                global.posHoldProcessResult.add(model);
              } catch (e) {
                AppLogger.error('[WebSocket Bootstrap] Failed to parse PosHoldProcessModel: $e');
              }
            }
          }
          AppLogger.debug('[WebSocket Bootstrap] Updated ${global.posHoldProcessResult.length} hold process results');
        }
      }

      // 2. Update remote device list
      if (data.containsKey('posRemoteDeviceList')) {
        final remoteDevices = data['posRemoteDeviceList'] as List?;
        if (remoteDevices != null) {
          global.posRemoteDeviceList.clear();
          for (var item in remoteDevices) {
            if (item is Map<String, dynamic>) {
              try {
                final device = SyncDeviceModel.fromJson(item);
                global.posRemoteDeviceList.add(device);
              } catch (e) {
                AppLogger.error('[WebSocket Bootstrap] Failed to parse SyncDeviceModel: $e');
              }
            }
          }
          AppLogger.debug('[WebSocket Bootstrap] Updated ${global.posRemoteDeviceList.length} remote devices');
        }
      }

      // 3. Refresh UI with synced data
      if (global.functionPosScreenRefresh != null) {
        // Refresh all active hold codes
        for (var holdResult in global.posHoldProcessResult) {
          global.functionPosScreenRefresh!(holdResult.code);
        }
      }

      AppLogger.info('[WebSocket Bootstrap] ✅ Sync completed successfully');
    }
  } catch (e, stackTrace) {
    AppLogger.error('[WebSocket Bootstrap] Failed to handle sync response: $e\n$stackTrace');
  }
}

/// Handle broadcast message from server
void _handleBroadcast(Map<String, dynamic> message) {
  try {
    final broadcastType = message['broadcastType'] as String?;
    final data = message['data'];

    AppLogger.info('[WebSocket Bootstrap] 📡 Broadcast received: $broadcastType');

    // Handle different broadcast types
    switch (broadcastType) {
      case 'table_update':
        // Table status changed, refresh table UI
        AppLogger.debug('[WebSocket Bootstrap] Table update broadcast');
        if (global.functionPosScreenRefresh != null && data is Map<String, dynamic>) {
          final tableNumber = data['tableNumber'] as String?;
          if (tableNumber != null) {
            global.functionPosScreenRefresh!(tableNumber);
          }
        }
        break;

      case 'order_update':
        // Order changed, refresh order UI
        AppLogger.debug('[WebSocket Bootstrap] Order update broadcast');
        if (global.functionPosScreenRefresh != null && data is Map<String, dynamic>) {
          final holdCode = data['holdCode'] as String?;
          if (holdCode != null) {
            global.functionPosScreenRefresh!(holdCode);
          }
        }
        break;

      case 'system_announcement':
        // System-wide message
        if (data is Map<String, dynamic>) {
          final announcement = data['message'] as String?;
          if (announcement != null) {
            AppLogger.info('[WebSocket Bootstrap] 📢 System announcement: $announcement');
            // Could show dialog or notification to user
          }
        }
        break;

      case 'sync_required':
        // Server requires sync
        AppLogger.info('[WebSocket Bootstrap] Sync required by server');
        if (ws_client.WebSocketClient().isConnected) {
          ws_client.WebSocketClient().requestSync();
        }
        break;

      case 'reload_data':
        // Reload specific data type
        if (data is Map<String, dynamic>) {
          final dataType = data['dataType'] as String?;
          AppLogger.info('[WebSocket Bootstrap] Reload data: $dataType');
          // Could trigger specific data reload (products, categories, etc.)
        }
        break;

      default:
        AppLogger.debug('[WebSocket Bootstrap] Unhandled broadcast type: $broadcastType');
        if (kDebugMode) {
          AppLogger.debug('Broadcast data: $data');
        }
    }
  } catch (e, stackTrace) {
    AppLogger.error('[WebSocket Bootstrap] Failed to handle broadcast: $e\n$stackTrace');
  }
}

/// Cleanup WebSocket connections
Future<void> cleanupWebSocket() async {
  AppLogger.info('[WebSocket Bootstrap] 🧹 Cleaning up...');

  try {
    if (global.appMode == global.AppModeEnum.posTerminal) {
      if (global.wsServer != null) {
        await global.wsServer!.stop();
        global.wsServer = null;
      }
      AppLogger.info('[WebSocket Bootstrap] Server stopped');
    } else if (global.appMode == global.AppModeEnum.posRemote) {
      await ws_client.WebSocketClient().disconnect();
      AppLogger.info('[WebSocket Bootstrap] Client disconnected');
    }
  } catch (e) {
    AppLogger.error('[WebSocket Bootstrap] Cleanup error: $e');
  }
}

/// Request sync from server (Remote mode only)
void requestSync() {
  if (global.appMode == global.AppModeEnum.posRemote) {
    if (ws_client.WebSocketClient().isConnected) {
      ws_client.WebSocketClient().requestSync();
      AppLogger.info('[WebSocket Bootstrap] 🔄 Sync requested');
    } else {
      AppLogger.warning(
        '[WebSocket Bootstrap] Cannot request sync: not connected',
      );
    }
  }
}

/// Broadcast message to all clients (Terminal mode only)
void broadcast(Map<String, dynamic> data) {
  if (global.appMode == global.AppModeEnum.posTerminal && global.wsServer != null) {
    global.wsServer!.broadcast(data);
    AppLogger.debug('[WebSocket Bootstrap] 📡 Message broadcasted');
  }
}
