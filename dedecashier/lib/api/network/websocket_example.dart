/// Example: How to use WebSocket in DedeCashier
///
/// แสดงตัวอย่างการใช้งาน WebSocket ทั้งฝั่ง Server (Terminal) และ Client (Remote)

import 'package:dedecashier/api/network/websocket_server.dart';
import 'package:dedecashier/api/network/websocket_client.dart' as ws_client;
import 'package:dedecashier/model/objectbox/pos_log_struct.dart';
import 'package:dedecashier/global.dart' as global;

// =====================================================
// SERVER SIDE (POS Terminal)
// =====================================================

class ServerExample {
  /// 1. เริ่มต้น WebSocket Server
  Future<void> startWebSocketServer() async {
    // เรียกใช้ตอน app start (แทน HTTP server)
    await WebSocketServer().start();
    print('✅ WebSocket Server started');
  }

  /// 2. Broadcast ข้อมูลไปทุกเครื่อง Remote
  void broadcastToAllClients() {
    // ส่งข้อมูลไปทุก client พร้อมกัน
    WebSocketServer().broadcast({
      'type': 'notification',
      'title': 'ระบบจะปิดปรับปรุงในอีก 5 นาที',
      'priority': 'high',
    });
  }

  /// 3. ส่งข้อมูล Process Result ไปเครื่องที่เกี่ยวข้อง
  void sendProcessResultToClient(String holdCode) {
    // หา process result จาก global
    final processResult = global.posHoldProcessResult.firstWhere(
      (item) => item.code == holdCode,
      orElse: () => throw Exception('Hold code not found'),
    );

    // ส่งไปเฉพาะเครื่องที่กำลัง hold bill นี้
    WebSocketServer().sendProcessResult(holdCode, processResult.toJson());

    print('📤 Sent process result for $holdCode');
  }

  /// 4. ส่งข้อมูลไปเครื่องเฉพาะด้วย Device ID
  void sendToSpecificDevice(String deviceId, Map<String, dynamic> data) {
    WebSocketServer().sendToDevice(deviceId, {
      'type': 'custom_message',
      'data': data,
    });

    print('📤 Sent to device: $deviceId');
  }

  /// 5. ดูสถานะ Clients ที่เชื่อมต่อ
  void showConnectedClients() {
    // จำนวน clients
    final count = WebSocketServer().connectedClientsCount;
    print('📊 Connected clients: $count');

    // รายละเอียด clients
    final clients = WebSocketServer().getConnectedClients();
    for (final client in clients) {
      print('  - ${client['deviceName']} (${client['ip']})');
      print('    Connected at: ${client['connectedAt']}');
      print('    Last ping: ${client['lastPingAt']}');
      print('    Hold code: ${client['holdCodeActive']}');
    }
  }

  /// 6. ปิด Server (เมื่อปิดแอพ)
  Future<void> stopServer() async {
    await WebSocketServer().stop();
    print('❌ WebSocket Server stopped');
  }
}

// =====================================================
// CLIENT SIDE (POS Remote)
// =====================================================

class ClientExample {
  /// 1. เชื่อมต่อกับ Server
  Future<void> connectToServer() async {
    // ตั้งค่า IP ของ Terminal ก่อน
    global.targetDeviceIpAddress = 'TERMINAL_HOST'; // IP ของ Terminal
    global.targetDeviceIpPort = 4040;

    // เชื่อมต่อ
    await ws_client.WebSocketClient().connect();

    // รอจนกว่าจะเชื่อมต่อสำเร็จ
    await Future.delayed(Duration(seconds: 2));

    if (ws_client.WebSocketClient().isConnected) {
      print('✅ Connected to server');

      // ลงทะเบียนตัวเอง
      ws_client.WebSocketClient().register();
    } else {
      print('❌ Failed to connect');
    }
  }

  /// 2. ส่ง POS Log ไป Server
  void sendPosLogToServer(Map<String, dynamic> posLogData) {
    ws_client.WebSocketClient().send({
      'type': 'pos_log',
      'action': 'insert',
      'data': posLogData,
    });

    print('📤 Sent POS log to server');
  }

  /// 3. ส่งคำสั่งไป Server
  void sendCommand(String command, dynamic data) {
    ws_client.WebSocketClient().sendCommand(command, data);
    print('📤 Sent command: $command');
  }

  /// 4. Request Sync ข้อมูลจาก Server
  void requestDataSync() {
    ws_client.WebSocketClient().requestSync();
    print('🔄 Requested sync from server');
  }

  /// 5. ลงทะเบียน Handler รับข้อมูลจาก Server
  void setupMessageHandler() {
    ws_client.WebSocketClient().addMessageHandler((message) {
      final type = message['type'];

      print('📨 Received: $type');

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

        default:
          print('Unknown message type: $type');
      }
    });

    print('✅ Message handler registered');
  }

  void _handleProcessResult(Map<String, dynamic> message) {
    final holdCode = message['holdCode'];
    final data = message['data'];

    print('📊 Process result for $holdCode');

    // อัพเดท local state
    // TODO: Update your PosHoldProcessResult

    // Refresh UI
    if (global.functionPosScreenRefresh != null) {
      global.functionPosScreenRefresh!(holdCode);
    }
  }

  void _handleNotification(Map<String, dynamic> message) {
    final title = message['title'];
    final priority = message['priority'];

    print('🔔 Notification: $title (Priority: $priority)');

    // แสดง notification ใน UI
    // TODO: Show notification dialog or snackbar
  }

  void _handlePosLogUpdate(Map<String, dynamic> message) {
    final data = message['data'];

    print('📝 POS log updated');

    // อัพเดท local database
    // TODO: Update local ObjectBox
  }

  void _handleSyncResponse(Map<String, dynamic> message) {
    final data = message['data'];

    print('🔄 Sync data received');

    // อัพเดทข้อมูลทั้งหมด
    // TODO: Update global.posHoldProcessResult and other data
  }

  /// 6. ตัดการเชื่อมต่อ
  Future<void> disconnectFromServer() async {
    await ws_client.WebSocketClient().disconnect();
    print('❌ Disconnected from server');
  }

  /// 7. ตรวจสอบสถานะ
  void checkStatus() {
    final isConnected = ws_client.WebSocketClient().isConnected;
    final queueSize = ws_client.WebSocketClient().queueSize;

    print('📊 Status:');
    print('  Connected: $isConnected');
    print('  Queue size: $queueSize');

    if (queueSize > 0) {
      print('  ⚠️ $queueSize messages waiting to be sent');
    }
  }
}

// =====================================================
// INTEGRATION EXAMPLES
// =====================================================

class IntegrationExample {
  /// ตัวอย่าง: แทนที่ HTTP POST ใน PosLogHelper
  ///
  /// เดิม (HTTP):
  /// ```dart
  /// Future<int> insert(PosLogObjectBoxStruct value) async {
  ///   if (global.appMode == global.AppModeEnum.posRemote) {
  ///     HttpPost json = HttpPost(
  ///       command: "PosLogHelper.insert",
  ///       data: jsonEncode(value.toJson()),
  ///     );
  ///     String result = await global.postToServerAndWait(...);
  ///     return int.tryParse(result) ?? 0;
  ///   }
  ///   ...
  /// }
  /// ```
  ///
  /// ใหม่ (WebSocket):
  Future<int> posLogInsertWebSocket(Map<String, dynamic> posLogData) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      // ส่งผ่าน WebSocket
      ws_client.WebSocketClient().send({
        'type': 'pos_log',
        'action': 'insert',
        'data': posLogData,
      });

      // ไม่ต้องรอ response แบบ blocking
      // Server จะส่ง acknowledgment กลับมาทาง message handler
      return 0;
    } else {
      // Local insert
      return global.objectBoxStore.box<PosLogObjectBoxStruct>().put(
        PosLogObjectBoxStruct.fromJson(posLogData),
      );
    }
  }

  /// ตัวอย่าง: แทนที่ sendProcessToRemote
  ///
  /// เดิม (HTTP):
  /// ```dart
  /// Future<void> sendProcessToRemote() async {
  ///   for (int index = 0; index < posRemoteDeviceList.length; index++) {
  ///     var jsonData = HttpPost(...);
  ///     postToServer(...);
  ///   }
  /// }
  /// ```
  ///
  /// ใหม่ (WebSocket):
  void sendProcessToRemoteWebSocket(String holdCode) {
    final processResult = global.posHoldProcessResult.firstWhere(
      (item) => item.code == holdCode,
    );

    // Broadcast ไปทุกเครื่อง Remote ที่เกี่ยวข้อง
    // WebSocket Server จะส่งไปเฉพาะเครื่องที่ holdCode ตรงกัน
    WebSocketServer().sendProcessResult(holdCode, processResult.toJson());
  }

  /// ตัวอย่าง: แทนที่ registerRemoteToTerminal
  ///
  /// เดิม (HTTP):
  /// ```dart
  /// Future<void> registerRemoteToTerminal() async {
  ///   var url = "http://$targetDeviceIpAddress:$targetDeviceIpPort";
  ///   await http.post(...);
  /// }
  /// ```
  ///
  /// ใหม่ (WebSocket):
  void registerRemoteToTerminalWebSocket() {
    // เชื่อมต่อ (auto register)
    ws_client.WebSocketClient().register();

    // ไม่ต้องใช้ Timer polling แล้ว
    // Connection status จะถูกอัพเดทอัตโนมัติผ่าน WebSocket events
  }
}

// =====================================================
// TESTING
// =====================================================

void main() async {
  print('🧪 WebSocket Integration Test\n');

  // Test Server
  final server = ServerExample();
  await server.startWebSocketServer();

  await Future.delayed(Duration(seconds: 1));

  // Test Client
  final client = ClientExample();
  await client.connectToServer();

  // Setup message handler
  client.setupMessageHandler();

  await Future.delayed(Duration(seconds: 2));

  // Test broadcast
  server.broadcastToAllClients();

  await Future.delayed(Duration(seconds: 1));

  // Test send data
  client.sendPosLogToServer({
    'barcode': 'TEST001',
    'name': 'Test Product',
    'qty': 1.0,
    'price': 100.0,
  });

  await Future.delayed(Duration(seconds: 1));

  // Show status
  server.showConnectedClients();
  client.checkStatus();

  await Future.delayed(Duration(seconds: 2));

  // Cleanup
  await client.disconnectFromServer();
  await server.stopServer();

  print('\n✅ Test completed');
}
