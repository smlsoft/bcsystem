import 'package:dedecashier/api/network/server.dart' as server;
import 'dart:async';
import 'dart:io';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/util/login_by_employee_page.dart';
import 'package:flutter/material.dart';

class SelectIpServerPage extends StatefulWidget {
  const SelectIpServerPage({super.key});

  @override
  SelectIpServerPageState createState() => SelectIpServerPageState();
}

class SelectIpServerPageState extends State<SelectIpServerPage> {
  List<NetworkInterface> interfaces = <NetworkInterface>[];

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () async {
      interfaces = await NetworkInterface.list();

      interfaces.removeWhere((element) => element.addresses.first.address.split('.').last == '1');
      setState(() {});
      if (interfaces.length == 1) {
        global.ipAddress = interfaces.first.addresses.first.address;
        server.startServer();
        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => const LoginByEmployeePage()), (route) => false);
        }
      } else if (interfaces.isEmpty) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => const LoginByEmployeePage()), (route) => false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(global.language('select_pos_machine_ip')),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: (interfaces.isEmpty)
              ? const Text("Scan Network ...")
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: interfaces
                      .map((e) => Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                              textStyle: const TextStyle(fontSize: 20),
                            ),
                            onPressed: () {
                              global.ipAddress = e.addresses.first.address;
                              server.startServer();
                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => const LoginByEmployeePage()), (route) => false);
                            },
                            child: Text(e.addresses.first.address, style: const TextStyle(fontSize: 20)),
                          )))
                      .toList(),
                ),
        ),
      ),
    ));
  }
}
