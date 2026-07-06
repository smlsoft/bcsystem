/// ✅ WebSocket Server Starter
/// แทนที่ HTTP Server ด้วย WebSocket Server เต็มรูปแบบ
///
/// เดิม: HTTP Server (Port 4040)
/// ใหม่: WebSocket Server (Port 4040)

import 'package:dedecashier/api/network/websocket_server.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/util/network.dart' as network;

/// ✅ เริ่ม WebSocket Server (ใช้แทน HTTP Server)
Future<void> startServer() async {
  if (global.ipAddress.isEmpty) {
    global.ipAddress = await network.ipAddress();
  }

  if (global.ipAddress.isNotEmpty) {
    try {
      await network.connectivity();
      global.targetDeviceIpAddress = global.ipAddress;

      // ✅ เริ่ม WebSocket Server
      await WebSocketServer().start();

      AppLogger.info(
        "✅ WebSocket Server running on ${global.ipAddress}:${global.targetDeviceIpPort}",
      );
    } catch (e, stackTrace) {
      AppLogger.error("❌ Failed to start WebSocket Server: $e");
      global.sendErrorToDevTeam('server.dart->startServer', '$e:$stackTrace');
    }
  } else {
    AppLogger.error("❌ Cannot start server: IP address is empty");
  }
}
