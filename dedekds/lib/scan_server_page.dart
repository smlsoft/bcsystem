import 'package:dedekds/model/global_model.dart';
import 'package:dedekds/global.dart' as global;
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:uuid/uuid.dart';

class ScanServerPage extends StatefulWidget {
  const ScanServerPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ScanServerPageState();
}

class _ScanServerPageState extends State<ScanServerPage> {
  List<ServerDeviceModel> serverList = [];
  List<ServerDeviceModel> ipList = [];

  Future<void> scanByIp(int index) async {
    try {
      String url =
          "http://${ipList[index].ip}:${global.posTerminalDevicePort}/scan?uuid=${const Uuid().v4()}";
      var result = await Dio()
          .get(url)
          .timeout(const Duration(seconds: 2)); // เพิ่ม timeout เป็น 2 วินาที
      if (result.statusCode == HttpStatus.ok) {
        if (result.data.isNotEmpty) {
          setState(() {
            var jsonData = json.decode(result.data);
            serverList.add(ServerDeviceModel(
                deviceId: jsonData["deviceId"],
                deviceName: jsonData["deviceName"],
                ip: ipList[index].ip,
                connected: true));
            ipList[index].connected = true;
          });
        }
      }
    } on SocketException catch (e) {
      print(e.toString());
    } on TimeoutException catch (e) {
      print(e.toString());
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> scanServer() async {
    global.posScanTerminal = true;
    if (global.ipAddress.isEmpty) {
      if (mounted) {
        await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text("ไม่พบ IP Address"),
                  content: const Text("กรุณาเชื่อมต่อกับ WiFi ก่อนทำการสแกน"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          exit(0);
                        },
                        child: const Text("OK"))
                  ],
                ));
      }
    }
    String subNet =
        global.ipAddress.substring(0, global.ipAddress.lastIndexOf("."));
    for (int i = 1; i < 255; i++) {
      String ip = "$subNet.$i";
      setState(() {
        ipList.add(ServerDeviceModel(
            deviceId: "", deviceName: "", ip: ip, connected: false));
      });
    }

    for (int i = 0; i < ipList.length; i += 20) {
      if (!global.posScanTerminal) break;

      List<Future> futures = [];
      for (int j = i; j < i + 20 && j < ipList.length; j++) {
        if (!ipList[j].connected) {
          futures.add(scanByIp(j));
        }
      }
      await Future.wait(futures);

      setState(() {});

      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> sendBroadcast() async {
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
        .then((RawDatagramSocket socket) {
      socket.broadcastEnabled = true;
      socket.send(
          utf8.encode('scan'), InternetAddress("255.255.255.255"), 8888);
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = socket.receive();
          if (dg != null) {
            var response = utf8.decode(dg.data);
            setState(() {
              serverList.add(ServerDeviceModel(
                  deviceId: "DeviceID",
                  deviceName: "DeviceName",
                  ip: dg.address.address,
                  connected: true));
            });
          }
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    scanServer();
    sendBroadcast();
  }

  Future<void> selected(int index) async {
    global.posTerminalDeviceId = serverList[index].deviceId;
    global.posTerminalDeviceName = serverList[index].deviceName;
    global.posTerminalDeviceIpAddress = serverList[index].ip;
    await global.saveServerData();
    global.posScanTerminal = false;
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/select_kitchen', (route) => false);
    }
  }

  void gotoPageStart() {
    global.posScanTerminal = false;
    Navigator.pushNamedAndRemoveUntil(context, '/start', (route) => false);
  }

  String keycode = "";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DEDE Customer Display',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
            appBar: AppBar(
              title: const Text('Scan POS Server'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      serverList.clear();
                      ipList.clear();
                      scanServer();
                    });
                  },
                )
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: gotoPageStart,
              child: const Icon(Icons.exit_to_app),
              tooltip: 'Exit',
            ),
            body: SafeArea(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                serverList.isEmpty
                    ? Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "กำลังค้นหาเครื่อง POS กรุณาเปิดเครื่อง และเปิดโปรแกรม POS",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54),
                            ),
                            const SizedBox(height: 20),
                            LoadingAnimationWidget.staggeredDotsWave(
                              color: Colors.blue,
                              size: 100,
                            ),
                          ],
                        ),
                      )
                    : Expanded(
                        child: Column(
                          children: [
                            const Text(
                              "เลือกเครื่อง POS ที่ต้องการเชื่อมต่อ",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            const Divider(),
                            Expanded(
                              child: ListView.builder(
                                itemCount: serverList.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    elevation: 3,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 4),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.devices_other,
                                        color: serverList[index].connected
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      title: Text(
                                          "ชื่อเครื่อง: ${serverList[index].deviceName}"),
                                      subtitle:
                                          Text("IP: ${serverList[index].ip}"),
                                      onTap: () {
                                        selected(index);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
              ]),
            ))));
  }
}
