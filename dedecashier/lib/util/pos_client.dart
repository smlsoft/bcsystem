import 'dart:async';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class PosClient extends StatefulWidget {
  const PosClient({super.key});

  @override
  State<PosClient> createState() => _PosClientState();
}

class _PosClientState extends State<PosClient> {
  late Timer findTerminalTimer;
  String posTerminalCode = 'POS01,0';
  TextEditingController posTerminalCodeController = TextEditingController();
  bool scanStart = false;

  @override
  void initState() {
    super.initState();
    findTerminalTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (global.targetDeviceConnected) {
        findTerminalTimer.cancel();
        global.loginSuccess = true;
        setState(() {
          Navigator.of(context).pushReplacementNamed('menu');
        });
      }
    });
    posTerminalCodeController.text = posTerminalCode;
  }

  @override
  void dispose() {
    findTerminalTimer.cancel();
    posTerminalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Column(children: [
            TextField(
              controller: posTerminalCodeController,
            ),
            ElevatedButton(
                onPressed: () {
                  List<String> split = posTerminalCodeController.text.split(',');
                  global.scanServerById(split[0]);
                  setState(() {
                    scanStart = true;
                  });
                },
                child: const Text("Connect Terminal")),
            if (scanStart)
              LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.blue,
                size: 200,
              ),
          ])),
    );
  }
}
