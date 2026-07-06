import 'dart:async';

import 'package:dedecashier/widgets/pin_numpad.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), () {
      global.loginSuccess = true;
      Navigator.of(context).pushReplacementNamed('loading');
    });
  }

  @override
  Widget build(BuildContext context) {
    //if (global.appLoadSuccess) {}
    late Widget screenWidget;

    if (global.posVersion == global.PosVersionEnum.vfpos) {
      screenWidget = Center(
          child: Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(minWidth: 300, maxWidth: 500, maxHeight: 500, minHeight: 200),
              child: PinNumberPad(
                onChange: (value) {
                  if (value == "0000") {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      global.loginSuccess = true;
                      Navigator.of(context).pushReplacementNamed('loading');
                    });
                  }
                },
                header: "Login Pin Code",
              )));
    } else {
      screenWidget = Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Image(image: AssetImage('assets/icon.png')),
          const Text("POS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 48)),
          const Text("POS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 96)),
          ElevatedButton.icon(
              icon: const Icon(Icons.lock_open_outlined),
              label: const Text("Continue With Google Account"),
              onPressed: () {
                global.loginSuccess = true;
                Navigator.of(context).pushReplacementNamed('/loading');
              }),
        ],
      ));
    }

    return SafeArea(child: Scaffold(resizeToAvoidBottomInset: false, body: screenWidget));
  }
}
