import 'dart:async';
import 'dart:math';

import 'package:dedecashier/flavors.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:uuid/uuid.dart';

class ConnectStaffClientPage extends StatefulWidget {
  const ConnectStaffClientPage({super.key});

  @override
  _ConnectStaffClientPageState createState() => _ConnectStaffClientPageState();
}

class _ConnectStaffClientPageState extends State<ConnectStaffClientPage> {
  Timer? updateTimer; // ⭐ OPTIMIZATION: ทำให้ nullable และเพิ่มระยะเวลา
  late String connectCode;
  final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

  @override
  void initState() {
    super.initState();
    global.connectSecureCode = (Random().nextInt(9000) + 1000).toString();
    connectCode = "${global.ipAddress}/${global.connectSecureCode}";

    // ⭐ OPTIMIZATION: เพิ่มจาก 5s → 10s เพื่อลด UI update frequency
    // หน้านี้ไม่ต้อง real-time มาก แค่ update QR display
    updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    updateTimer?.cancel();
  }

  /// ยืนยันการลบ client
  void _confirmDeleteClient(int index) {
    final client = global.staffClientList[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบ "${client.client_name}" (${client.client_ip}) หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () {
              setState(() {
                global.staffClientList.removeAt(index);
              });
              Navigator.pop(context);
              // แสดง feedback
              ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('ลบ "${client.client_name}" แล้ว'), duration: const Duration(seconds: 2)));
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('เชื่อมต่อเครื่องลูก'), backgroundColor: _themeColor),
          body: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      itemCount: global.staffClientList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: Text(
                            "${global.staffClientList[index].client_name} (${global.staffClientList[index].client_ip})",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'ลบ',
                            onPressed: () => _confirmDeleteClient(index),
                          ),
                          onTap: () {},
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text("เครื่องที่มีกล้องสามารถ Scan Qr Code ได้", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Center(
                            child: QrImageView(size: 200, backgroundColor: Colors.white, data: connectCode, version: QrVersions.auto),
                          ),
                        ),
                        const Text("เครื่องที่ไม่มีกล้อง สามารถเชื่อมต่อด้วย IP Address"),
                        Text("IP Address : ${global.ipAddress}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text("รหัสสำหรับเชื่อมต่อ : ${global.connectSecureCode}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
