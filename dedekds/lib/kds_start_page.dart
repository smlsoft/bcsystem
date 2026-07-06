import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dedekds/kds_home_page.dart';
import 'package:dedekds/scan_server_page.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:dedekds/global.dart' as global;
import 'package:dedekds/utility/util.dart' as util;

class KdsStartPage extends StatefulWidget {
  const KdsStartPage({super.key});

  @override
  State<KdsStartPage> createState() => _KdsStartPageState();
}

class _KdsStartPageState extends State<KdsStartPage> {
  bool loadSuccess = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    global.loadServerData().then((_) {
      /*loadSuccess = true;
      print(global.posTerminalDeviceId);
      scanServer();
      setState(() {});*/
      
    });

    /*timerScan = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (global.posTerminalDeviceId.isNotEmpty &&
          global.posKitchenId.isNotEmpty) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
      setState(() {});
    });*/
    util.getIpAddress().then((value) {
      global.ipAddress = value;
      _controller.text = global.ipAddress;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> scanServer() async {
    while (global.posTerminalDeviceId.isNotEmpty) {
      await util.findPosTerminalById(global.posTerminalDeviceId);
      setState(() {});
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> scanServerPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanServerPage()),
    );
  }

  void gotoScanServer() {
    Navigator.pushNamedAndRemoveUntil(
        context, '/scan_server', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          height: 100,
          child: Row(
            children: [
              Expanded(
                  child: TextField(
                      focusNode: FocusNode(),
                      autofocus: true,
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Enter IP Address',
                      ))),
              IconButton(
                  onPressed: () async {
                    global.ipPosTerminalFixed = true;
                    global.ipPosTerminalAddress = _controller.text;
                    global.posTerminalDeviceIpAddress = _controller.text;
                    global.posTerminalConnected = true;
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/select_kitchen', (route) => false);
                  },
                  icon: const Icon(Icons.save))
            ],
          ),
        ),
        ElevatedButton(
            onPressed: () async {
              global.ipPosTerminalFixed = false;
              global.ipPosTerminalAddress = "";
              await scanServerPage();
            },
            child: const Text("ค้นหาเครื่อง POS Terminal ใหม่ อัตโนมัติ")),
      ],
    ));
  }
}
