import 'dart:convert';
import 'dart:io';
import 'package:dedekds/global.dart' as global;
import 'package:dedekds/model/global_model.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class HttpPost {
  late String command;
  late String data;

  HttpPost({required this.command, this.data = ""});

  Map toJson() => {
        'command': command,
        'data': data,
      };

  factory HttpPost.fromJson(Map<String, dynamic> json) {
    return HttpPost(
      command: json['command'],
      data: json['data'],
    );
  }
}

Future<String> getIpAddress() async {
  await Permission.speech.request();
  await Permission.audio.request();
  NetworkInfo info = NetworkInfo();
  var hostAddress = await info.getWifiIP();
  return hostAddress ?? "";
}

Future<void> findPosTerminalById(String id) async {
  bool loopScan = true;
  List<ServerDeviceModel> ipList = [];
  String subNet =
      global.ipAddress.substring(0, global.ipAddress.lastIndexOf("."));
  for (int i = 1; i < 255; i++) {
    String ip = "$subNet.$i";
    ipList.add(ServerDeviceModel(
        deviceId: "", deviceName: "", ip: ip, connected: false));
  }

  while (loopScan) {
    for (int index = 0; index < ipList.length; index++) {
      Future(() async {
        try {
          String url =
              "http://${ipList[index].ip}:${global.posTerminalDevicePort}/scan?uuid=${const Uuid().v4()}";
          var result = await Dio().get(url).timeout(const Duration(seconds: 5));

          if (result.statusCode == HttpStatus.ok) {
            if (result.data.isNotEmpty) {
              var jsonData = json.decode(result.data);
              if (jsonData["deviceId"] == id) {
                global.posTerminalDeviceIpAddress = ipList[index].ip;
                global.posTerminalDeviceName = jsonData["deviceName"];
                loopScan = false;
                global.posTerminalConnected = true;
              }
            }
          }
        } on DioException catch (e) {
          print(e);
        }
      });
    }
    await Future.delayed(const Duration(seconds: 1));
  }
}

Future<void> pingTerminal() async {
  try {
    String url =
        "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}/scan?uuid=${const Uuid().v4()}";
    var result = await Dio().get(url).timeout(const Duration(seconds: 1));
    if (result.statusCode == HttpStatus.ok) {
      global.posTerminalConnected = true;
    } else {
      global.posTerminalConnected = false;
    }
  } catch (e) {
    global.posTerminalConnected = false;
  }
}
