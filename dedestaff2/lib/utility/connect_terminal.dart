import 'dart:io';
import 'package:dedeorder/utility/api.dart' as api;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectTerminalPage extends StatefulWidget {
  const ConnectTerminalPage({super.key});
  @override
  State<ConnectTerminalPage> createState() => _ConnectTerminalPageState();
}

class _ConnectTerminalPageState extends State<ConnectTerminalPage> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  TextEditingController urlController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  TextEditingController deviceNameController = TextEditingController();
  TextEditingController ipAddressController = TextEditingController();

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void initState() {
    deviceNameController.text = "";
    ipAddressController.text = "";
    codeController.text = "";
    if (Platform.isAndroid) {
      Future(
        () async {
          DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          print('Running on ${androidInfo.model}');
          setState(() {
            deviceNameController.text = "${androidInfo.brand}-${androidInfo.model}-${androidInfo.device}";
          });
        },
      );
    } else {}
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    urlController.dispose();
    codeController.dispose();
    super.dispose();
  }

  Future<bool> connectToServer(String url) async {
    print(url);
    List<String> values = url.split("/");
    if (values.length == 2) {
      String posServerDeviceIpAddress = values[0];
      String connectCode = values[1];
      String result = await api.registerStaffClientToServer(serverIpAddress: posServerDeviceIpAddress, connectCode: connectCode);
      if (result.isNotEmpty) {
        SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
        await sharedPreferences.setString('posServerName', result);
        await sharedPreferences.setString('posServerIpAddress', posServerDeviceIpAddress);
        await sharedPreferences.setString('connectCode', connectCode);
        return true;
      }
    }
    return false;
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera();
      bool connectResult = await connectToServer(scanData.code ?? "");
      if (connectResult == true) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      } else {
        controller.resumeCamera();
      }
    });
  }

  void onManualConfig(data, context) async {
    bool connectResult = await connectToServer(data);
    if (connectResult == true) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ข้อมูลไม่ถูกต้อง"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400) ? 250.0 : 300.0;
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Connect POS Terminal'),
            ),
            body: (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
                ? Center(
                    child: Container(
                        constraints: const BoxConstraints(minWidth: 100, maxWidth: 400),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("IP Address POS Terminal"),
                            const SizedBox(height: 20),
                            TextField(
                              controller: urlController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'IP Address',
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: codeController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Connect Code',
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                                onPressed: () {
                                  String url = "${urlController.text}/${codeController.text}";
                                  connectToServer(url).then((value) {
                                    if (value == true) {
                                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                                    }
                                  });
                                },
                                child: const Text("Connect"))
                          ],
                        )))
                : Column(children: [
                    Expanded(
                        child: QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                      overlay: QrScannerOverlayShape(borderColor: Colors.red, borderRadius: 10, borderLength: 30, borderWidth: 10, cutOutSize: scanArea),
                    )),
                    Container(
                      margin: const EdgeInsets.all(10),
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      color: Colors.blue.shade100,
                      child: const Center(child: Text("Scan QR Code POS Terminal")),
                    ),
                    Container(
                        margin: const EdgeInsets.all(10),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0), // Adjust the value as needed
                            side: const BorderSide(color: Colors.grey, width: 1.0), // Specify the border color and width
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(minWidth: 100, maxWidth: 400),
                            child: Column(
                              children: [
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Device Name',
                                  ),
                                  controller: deviceNameController,
                                ),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'IP Address',
                                  ),
                                  controller: ipAddressController,
                                ),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Connect Code',
                                  ),
                                  controller: codeController,
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (deviceNameController.text.isNotEmpty && ipAddressController.text.isNotEmpty && codeController.text.isNotEmpty) {
                                      onManualConfig('${ipAddressController.text}/${codeController.text}', context);
                                    }
                                  },
                                  child: const Text('Submit'),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ])));
  }
}
