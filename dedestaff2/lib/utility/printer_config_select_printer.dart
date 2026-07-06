import 'dart:ui' as ui;
import 'dart:async';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:dedeorder/global_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:image/image.dart' as im;
import 'package:shared_preferences/shared_preferences.dart';

class PrinterConfigSelectPrinterScreen extends StatefulWidget {
  final String printerCode;
  final String printerName;

  const PrinterConfigSelectPrinterScreen(
      {Key? key, required this.printerCode, required this.printerName})
      : super(key: key);

  @override
  State<PrinterConfigSelectPrinterScreen> createState() =>
      _PrinterConfigSelectPrinterScreenState();
}

class _PrinterConfigSelectPrinterScreenState
    extends State<PrinterConfigSelectPrinterScreen> {
  bool connected = false;
  bool printBinder = false;
  int paperSize = 0;
  String serialNumber = "";
  String printerVersion = "";
  TextEditingController ipAddressController = TextEditingController();
  TextEditingController portController = TextEditingController();
  List<PrinterDeviceModel> printerList = [];
  late Timer screenTimer;
  bool printBillAuto = true;
  int printerPaperSize = 2;
  int printerSelectedIndex = -1;
  bool isDiscovering = false;

  @override
  void initState() {
    super.initState();
    getDeviceList();
    screenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    screenTimer.cancel();
    super.dispose();
  }

  Future<void> startBluetoothDiscovery() async {
    /*try {
      final List<BluetoothInfo> listResult =
          await PrintBluetoothThermal.pairedBluetooths;
      await Future.forEach(listResult, (BluetoothInfo bluetooth) {
        String name = bluetooth.name;
        String mac = bluetooth.macAdress;
        setState(() {
          printerList.add(
            PrinterDeviceModel(
              fullName: "Bluetooth : $name $mac",
              productName: "Bluetooth Printer",
              deviceName: name,
              deviceId: mac,
              ipAddress: mac,
              connectType: global.PrinterConnectEnum.bluetooth,
            ),
          );
        });
      });
    } catch (e,s) {
      print(e);
    }*/
  }

  void scanNetworkPrinter() async {
    String appIpAddress = await global
        .getIpAddress(); // Assuming global.ipAddress() is well-defined
    String subNet = appIpAddress.substring(0, appIpAddress.lastIndexOf('.'));
    int port = 9100;

    for (int i = 1; i < 255; i++) {
      String ip = "$subNet.$i";
      try {
        Socket.connect(ip, port, timeout: const Duration(seconds: 4)).then(
          (Socket socket) {
            // The connection was successful if this callback is called
            bool ipDuplicate =
                printerList.any((printer) => printer.ipAddress == ip);
            if (!ipDuplicate) {
              setState(() {
                // Assuming this is in a StatefulWidget
                printerList.add(PrinterDeviceModel(
                  fullName: "IP Printer : $ip",
                  productName: "IP Printer",
                  ipAddress: ip,
                  ipPort: 9100,
                  connectType: global.PrinterConnectEnum.ip,
                ));
              });
            }
            socket.destroy();
          },
        ).catchError((e, s) {
          if (kDebugMode) {
            print("Unable to connect to: $ip - ${e.toString()}");
          }
          global.sendErrorToDevTeam(
              "Unable to connect to: $ip - ${e.toString()}");
        });
      } catch (e, s) {
        if (kDebugMode) {
          print("Error with IP $ip: ${e.toString()}");
        }
        global.sendErrorToDevTeam("Error with IP $ip: ${e.toString()}");
      }
    }
  }

  void getDeviceList() async {
    printerList.clear();
    {
      // Windows
      /*PrinterManager.instance
          .discovery(type: PrinterType.usb, isBle: false)
          .listen((device) {
        setState(() {
          printerList.add(PrinterDeviceModel(
            fullName: "Windows Printer : ${device.name}",
            productName: "",
            deviceName: device.name,
            ipAddress: device.name,
            deviceId: "",
            manufacturer: "",
            vendorId: device.vendorId.toString(),
            productId: device.productId.toString(),
            connectType: global.PrinterConnectEnum.windows,
          ));
        });
      });*/
    }
    scanNetworkPrinter();
    startBluetoothDiscovery();
  }

  void printTest() {
    switch (printerList[printerSelectedIndex].connectType) {
      case global.PrinterConnectEnum.ip:
        printTestByIpAddress(
            ipAddress: ipAddressController.text,
            port: int.parse(portController.text));
        break;
      case global.PrinterConnectEnum.bluetooth:
        printTestByBluetooth();
        break;
      case global.PrinterConnectEnum.windows:
        printTestByWindows();
        break;
    }
  }

  void printTestByBluetooth() async {
    /*String mac = printerList[printerSelectedIndex].ipAddress;
    await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    bool connectStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectStatus) {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> xbytes = [];

      double maxHeight = 10;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final backgroundPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      double paperPixelWidth = (printerPaperSize == 1) ? 384 : 576;
      canvas.drawRect(
          Rect.fromLTWH(0.0, 0.0, paperPixelWidth, 10000.0), backgroundPaint);

      for (int loop = 1; loop < 10; loop++) {
        TextSpan span = TextSpan(
            style: TextStyle(
                color: Colors.black, fontSize: 24 + (loop.toDouble() * 2)),
            text: "สวัสดีประเทศไทย " + loop.toString());
        TextPainter tp = TextPainter(
            text: span,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(0, maxHeight.toDouble()));
        maxHeight += tp.height;
      }
      final picture = recorder.endRecording();
      final imageBuffer =
          picture.toImage(paperPixelWidth.toInt(), maxHeight.toInt());
      final pngBytes = await imageBuffer
          .then((value) => value.toByteData(format: ui.ImageByteFormat.png));
      im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
      int printMaxHeight = 500;
      int calcLoop = imageDecode!.height ~/ printMaxHeight;
      for (int i = 0; i <= calcLoop; i++) {
        try {
          if (i != 0) {
            sleep(const Duration(milliseconds: 100));
          }
          im.Image croppedImage = im.copyCrop(imageDecode, 0,
              i * printMaxHeight, imageDecode.width, printMaxHeight);
          xbytes += generator.imageRaster(croppedImage);
        } catch (e,s) {
          print(e);
        }
      }
      xbytes += generator.cut();
      await PrintBluetoothThermal.writeBytes(xbytes);
    } else {
      print("the printer is disconnected ($connectStatus)");
    }*/
  }

  void printTestByIpAddress(
      {required String ipAddress, required int port}) async {
    PaperSize paper = PaperSize.mm80;
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(paper, profile);

    try {
      PrinterNetworkManager printer =
          PrinterNetworkManager(ipAddress, port: port);
      PosPrintResult res = await printer.connect();
      if (res == PosPrintResult.success) {
        // Image
        double maxHeight = 10;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final backgroundPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawRect(
            const Rect.fromLTWH(0.0, 0.0, 640.0, 10000.0), backgroundPaint);

        for (int loop = 1; loop < 10; loop++) {
          TextSpan span = TextSpan(
              style: TextStyle(
                  color: Colors.black, fontSize: 24 + (loop.toDouble() * 2)),
              text: "สวัสดีประเทศไทย " + loop.toString());
          TextPainter tp = TextPainter(
              text: span,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr);
          tp.layout();
          tp.paint(canvas, Offset(0, maxHeight.toDouble()));
          maxHeight += tp.height;
        }
        List<int> imageBytes = [];
        final picture = recorder.endRecording();
        final imageBuffer = picture.toImage(640, maxHeight.toInt());
        final pngBytes = await imageBuffer
            .then((value) => value.toByteData(format: ui.ImageByteFormat.png));
        im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
        int printMaxHeight = 1000;
        int calcLoop = imageDecode!.height ~/ printMaxHeight;
        for (int i = 0; i <= calcLoop; i++) {
          try {
            im.Image croppedImage = im.copyCrop(imageDecode, 0,
                i * printMaxHeight, imageDecode.width, printMaxHeight);
            imageBytes += generator.imageRaster(croppedImage);
          } catch (e, s) {
            print(e);
            global.sendErrorToDevTeam("printTestByIpAddress:$e $s");
          }
        }
        imageBytes += generator.feed(3);
        imageBytes += generator.cut();
        printer.printTicket(imageBytes);
        printer.disconnect();
      }
    } catch (e, s) {
      print(e);
      global.sendErrorToDevTeam("printTestByIpAddress:$e $s");
    }
  }

  void printTestByWindows() async {
    /*String printerName = printerList[printerSelectedIndex].deviceName;
    try {
      print("Connecting..." + printerList[printerSelectedIndex].ipAddress);
      await PrinterManager.instance.connect(
          type: PrinterType.usb,
          model: UsbPrinterInput(
              name: printerList[printerSelectedIndex].deviceName,
              productId: printerList[printerSelectedIndex].productId,
              vendorId: printerList[printerSelectedIndex].vendorId));
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      // Image
      double maxHeight = 10;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final backgroundPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawRect(
          const Rect.fromLTWH(0.0, 0.0, 640.0, 10000.0), backgroundPaint);

      for (int loop = 1; loop < 10; loop++) {
        TextSpan span = TextSpan(
            style: TextStyle(
                color: Colors.black, fontSize: 24 + (loop.toDouble() * 2)),
            text: "สวัสดีประเทศไทย " + loop.toString());
        TextPainter tp = TextPainter(
            text: span,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(0, maxHeight.toDouble()));
        maxHeight += tp.height;
      }
      final picture = recorder.endRecording();
      final imageBuffer = picture.toImage(640, maxHeight.toInt());
      final pngBytes = await imageBuffer
          .then((value) => value.toByteData(format: ui.ImageByteFormat.png));
      im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
      int printMaxHeight = 500;
      int calcLoop = imageDecode!.height ~/ printMaxHeight;
      var bytes = generator.reset();
      for (int i = 0; i <= calcLoop; i++) {
        try {
          im.Image croppedImage = im.copyCrop(imageDecode, 0,
              i * printMaxHeight, imageDecode.width, printMaxHeight);
          bytes += generator.image(croppedImage);
        } catch (e,s) {
          print(e);
        }
      }
      bytes += generator.feed(1);
      bytes += generator.cut();
      bytes += generator.drawer();
      PrinterManager.instance.send(type: PrinterType.usb, bytes: bytes);
    } catch (e,s) {
      print(e);
    }*/
  }

  Widget printerListWidget() {
    return Container(
        padding: const EdgeInsets.all(2),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: (printerList.isEmpty)
            ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.blue,
                  size: 100,
                ),
              )
            : ListView.builder(
                itemBuilder: (context, index) {
                  return Padding(
                      padding: const EdgeInsets.all(4),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: (index == printerSelectedIndex)
                                ? Colors.orange
                                : Colors.blue,
                          ),
                          onPressed: () {
                            setState(() {
                              printerSelectedIndex = index;
                              switch (printerList[index].connectType) {
                                case global.PrinterConnectEnum.ip:
                                  ipAddressController.text =
                                      printerList[index].ipAddress;
                                  portController.text = "9100";
                                  break;
                                case global.PrinterConnectEnum.bluetooth:
                                  ipAddressController.text =
                                      printerList[index].ipAddress;
                                  break;
                                case global.PrinterConnectEnum.windows:
                                  break;
                              }
                            });
                          },
                          child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.print),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                      child: FittedBox(
                                          child: Text(
                                    printerList[index].fullName,
                                    style: const TextStyle(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ))),
                                ],
                              ))));
                },
                itemCount: printerList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ));
  }

  Widget printerIpConnectWidget() {
    return Column(children: [
      TextField(
        controller: ipAddressController,
        decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: global.language("printer_ip_address"),
            hintText: "xxx.xxx.xxx.xxx"),
        readOnly: true,
      ),
      const SizedBox(
        height: 10,
      ),
      TextField(
        controller: portController,
        decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: global.language("printer_ip_port"),
            hintText: "xxxx"),
      ),
    ]);
  }

  Widget printerBluetoothConnectWidget() {
    return Column(children: [
      TextField(
        controller: ipAddressController,
        decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: global.language("printer_mac_address"),
            hintText: "xxx.xxx.xxx.xxx"),
        readOnly: true,
      ),
    ]);
  }

  Widget printerConnect() {
    List<Widget> displayPrinterConnectWidget = [];
    if (printerSelectedIndex != -1) {
      displayPrinterConnectWidget.add(Text(
          "${global.language("printer_selected")} : ${printerList[printerSelectedIndex].fullName}",
          style: const TextStyle(
              fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold)));
      displayPrinterConnectWidget.add(const SizedBox(
        height: 10,
      ));
    }
    if (printerSelectedIndex != -1) {
      switch (printerList[printerSelectedIndex].connectType) {
        case global.PrinterConnectEnum.ip:
          displayPrinterConnectWidget.add(printerIpConnectWidget());
          break;
        case global.PrinterConnectEnum.bluetooth:
          displayPrinterConnectWidget.add(printerBluetoothConnectWidget());
          break;
        case global.PrinterConnectEnum.windows:
          break;
      }
    }
    displayPrinterConnectWidget.add(const SizedBox(
      height: 10,
    ));
    displayPrinterConnectWidget.add(Row(children: [
      Text(global.language("printer_paper_size")),
      const SizedBox(width: 10),
      Radio(
          value: 1,
          groupValue: printerPaperSize,
          onChanged: (value) {
            setState(() {
              printerPaperSize = value!;
            });
          }),
      const Text('58mm'),
      const SizedBox(width: 10),
      Radio(
          value: 2,
          groupValue: printerPaperSize,
          onChanged: (value) {
            setState(() {
              printerPaperSize = value!;
            });
          }),
      const Text('80mm'),
    ]));
    displayPrinterConnectWidget.add(const SizedBox(
      height: 10,
    ));
    displayPrinterConnectWidget.add(Row(children: [
      Checkbox(
          value: printBillAuto,
          onChanged: (value) {
            setState(() {
              printBillAuto = value!;
            });
          }),
      const SizedBox(width: 10),
      Text(global.language("printer_print_bill_auto")),
    ]));
    displayPrinterConnectWidget.add(const SizedBox(
      height: 10,
    ));
    displayPrinterConnectWidget.add(ElevatedButton(
        onPressed: () {
          printTest();
          showDialog(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                    title: Text(global.language("printer_connect_test")),
                    content:
                        Text(global.language("printer_connect_test_success")),
                    actions: [
                      ElevatedButton(
                        child: Text(global.language("success")),
                        onPressed: () async {
                          global.printToLocalPrinter == true;
                          var data = PrinterLocalStrongDataModel(
                              code: widget.printerCode,
                              name: widget.printerName,
                              printerConnectType:
                                  printerList[printerSelectedIndex].connectType,
                              printerType:
                                  printerList[printerSelectedIndex].printerType,
                              ipAddress: ipAddressController.text,
                              ipPort: int.tryParse(portController.text) ?? 0,
                              productName: "",
                              deviceName:
                                  printerList[printerSelectedIndex].deviceName,
                              deviceId: "",
                              manufacturer: "",
                              isConfigConnectSuccess: true,
                              vendorId: "",
                              productId: "",
                              paperSize: printerPaperSize,
                              printBillAuto: printBillAuto);
                          SharedPreferences sharedPreferences =
                              await SharedPreferences.getInstance();
                          sharedPreferences.setString(
                              "printer", jsonEncode(data.toJson()));
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                      ),
                      ElevatedButton(
                        child: Text(global.language("fail")),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ));
        },
        child: AutoSizeText(
          global.language("printer_connect_test_and_save"),
          maxLines: 1,
          style: const TextStyle(fontSize: 20),
        )));

    return Container(
      padding: const EdgeInsets.only(top: 10),
      width: double.infinity,
      child: (printerSelectedIndex == -1)
          ? printerListWidget()
          : Column(
              children: [
                printerListWidget(),
                const SizedBox(
                  height: 15,
                ),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(children: displayPrinterConnectWidget)),
                const SizedBox(
                  height: 10,
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
              "${global.language('printer_config')} : ${widget.printerName}"),
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => getDeviceList()),
          ],
        ),
        body: SingleChildScrollView(
            child: Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          child: printerConnect(),
        )));
  }
}
