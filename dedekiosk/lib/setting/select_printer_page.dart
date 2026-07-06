import 'dart:async';
import 'dart:io' as io;
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/printer_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as im;
import 'package:dedekiosk/global.dart' as global;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class SelectPrinterPage extends StatefulWidget {
  const SelectPrinterPage({Key? key}) : super(key: key);

  @override
  State<SelectPrinterPage> createState() => _SelectPrinterPageState();
}

class _SelectPrinterPageState extends State<SelectPrinterPage> {
  bool connected = false;
  bool printBinder = false;
  int paperSize = 0;
  String serialNumber = "";
  String printerVersion = "";
  TextEditingController usbDeviceController = TextEditingController();
  TextEditingController usbVendorIdController = TextEditingController();
  TextEditingController usbProductIdController = TextEditingController();
  TextEditingController ipAddressController = TextEditingController();
  TextEditingController portController = TextEditingController();
  List<PrinterDeviceModel> printerList = [];
  bool printBillAuto = true;
  int printerPaperSize = 2;
  int printerSelectedIndex = -1;
  bool isDiscovering = false;
  String printerCode = "";
  String printerName = "";
  final flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
  List<Printer> printers = [];
  StreamSubscription<List<Printer>>? _devicesStreamSubscription;
  StreamSubscription<List<Printer>>? _bluetoothStreamSubscription;
  Color get primaryThemeColor {
    return _hexToColor(global.deviceConfig.primaryThemeColor);
  }

  // Helper function to convert hex string to Color
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  void initState() {
    super.initState();
    getDeviceList();
  }

  @override
  void dispose() {
    usbDeviceController.dispose();
    usbVendorIdController.dispose();
    usbProductIdController.dispose();
    ipAddressController.dispose();
    portController.dispose();
    _devicesStreamSubscription?.cancel();
    _bluetoothStreamSubscription?.cancel();
    super.dispose();
  }

  void scanNetworkPrinter() async {
    String appIpAddress = await global.ipAddress();
    String subNet = appIpAddress.substring(0, appIpAddress.lastIndexOf('.'));
    const int port = 9100;
    const int batchSize = 50; // Increased batch size for faster scanning

    // Scan all IPs in parallel batches
    List<Future<void>> allScans = [];
    for (int i = 254; i > 1; i--) {
      String ip = "$subNet.$i";
      allScans.add(scanSingleIp(ip, port));

      // Process in batches to avoid too many concurrent connections
      if (allScans.length >= batchSize) {
        await Future.wait(allScans);
        allScans.clear();
        if (!mounted) return; // Stop if widget is disposed
      }
    }

    // Process remaining scans
    if (allScans.isNotEmpty) {
      await Future.wait(allScans);
    }
  }

  Future<void> scanSingleIp(String ip, int port) async {
    if (!mounted) return; // Skip if widget is disposed

    try {
      await io.Socket.connect(ip, port, timeout: const Duration(milliseconds: 500)).then(
        (io.Socket socket) {
          if (!mounted) {
            socket.destroy();
            return;
          }

          bool ipDuplicate = printerList.any((printer) => printer.ipAddress == ip);
          if (!ipDuplicate) {
            setState(() {
              printerList.add(PrinterDeviceModel(
                fullName: "IP Printer : $ip",
                productName: "IP Printer",
                deviceName: ip,
                deviceId: ip,
                ipAddress: ip,
                ipPort: port,
                connectType: global.printerConnect(global.PrinterConnectEnum.ip),
              ));
            });
          }
          socket.destroy();
        },
      ).catchError((e) {});
    } catch (e) {
      // Silently ignore connection errors (expected for non-printer IPs)
    }
  }

  void getDeviceList() async {
    setState(() {
      printerList.clear();
      printerSelectedIndex = -1;
    });

    // Request Bluetooth permissions before scanning
    await _requestBluetoothPermissions();

    // Scan all printer types
    scanNetworkPrinter();
    scanPrinterUsbDiscovery();
    scanPrinterBluetoothDiscovery();
  }

  Future<void> _requestBluetoothPermissions() async {
    if (io.Platform.isAndroid) {
      // Request Bluetooth permissions for Android
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      if (kDebugMode) {
        statuses.forEach((permission, status) {
          print("$permission: $status");
        });
      }
    }
  }

  Future<void> scanPrinterBluetoothDiscovery() async {
    try {
      // Cancel previous subscription
      _bluetoothStreamSubscription?.cancel();
      _bluetoothStreamSubscription = null;

      if (kDebugMode) {
        print("Starting Bluetooth printer scan...");
      }

      // Start scanning for Bluetooth printers
      await flutterThermalPrinterPlugin.getPrinters(connectionTypes: [
        ConnectionType.BLE,
      ]);

      // Listen to the devices stream for Bluetooth
      _bluetoothStreamSubscription = flutterThermalPrinterPlugin.devicesStream.listen(
        (List<Printer> event) {
          // Filter Bluetooth printers only
          final bluetoothPrinters = event.where((p) => p.connectionType == ConnectionType.BLE).toList();

          if (kDebugMode) {
            print("Bluetooth Printers received: ${bluetoothPrinters.length}");
            for (var p in bluetoothPrinters) {
              print("  - Name: ${p.name}, Address: ${p.address}, ConnectionType: ${p.connectionType}");
            }
          }

          // Add Bluetooth printers to list
          for (var element in bluetoothPrinters) {
            // Skip if name is null or empty
            if (element.name == null || element.name!.isEmpty) continue;

            // Check if already exists in list
            bool isDuplicate = printerList.any((p) => p.deviceId == element.address.toString() && p.connectType == global.printerConnect(global.PrinterConnectEnum.bluetooth));

            if (!isDuplicate) {
              if (mounted) {
                setState(() {
                  printerList.add(PrinterDeviceModel(
                    fullName: "Bluetooth Printer : ${element.name}",
                    productName: element.name.toString(),
                    deviceName: element.name.toString(),
                    deviceId: element.address.toString(),
                    ipAddress: element.address.toString(),
                    connectType: global.printerConnect(global.PrinterConnectEnum.bluetooth),
                    vendorId: "",
                    productId: "",
                  ));
                });
              }
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print("Bluetooth scan error: $error");
          }
        },
      );
    } catch (e, s) {
      if (kDebugMode) {
        print("Error scanning Bluetooth printers: $e");
        print(s);
      }
    }
  }

  Future<void> scanPrinterUsbDiscovery() async {
    try {
      // Cancel previous subscription
      _devicesStreamSubscription?.cancel();
      _devicesStreamSubscription = null;

      if (kDebugMode) {
        print("Starting USB printer scan...");
      }

      // Start scanning for USB printers
      await flutterThermalPrinterPlugin.getPrinters(connectionTypes: [
        ConnectionType.USB,
      ]);

      // Listen to the devices stream
      _devicesStreamSubscription = flutterThermalPrinterPlugin.devicesStream.listen(
        (List<Printer> event) {
          if (kDebugMode) {
            print("USB Printers received: ${event.length}");
            for (var p in event) {
              print("  - Name: ${p.name}, VendorId: ${p.vendorId}, ProductId: ${p.productId}, Address: ${p.address}, ConnectionType: ${p.connectionType}");
            }
          }

          // Filter USB printers only
          printers = event.where((p) => p.connectionType == ConnectionType.USB).toList();

          // Add printers to list
          for (var element in printers) {
            // Skip if name is null or empty
            if (element.name == null || element.name!.isEmpty) continue;

            // Check if already exists in list
            bool isDuplicate = printerList.any((p) => p.vendorId == element.vendorId.toString() && p.productId == element.productId.toString());

            if (!isDuplicate) {
              if (mounted) {
                setState(() {
                  printerList.add(PrinterDeviceModel(
                    fullName: "USB Printer : ${element.name}",
                    productName: element.productId.toString(),
                    deviceName: element.name.toString(),
                    deviceId: element.address.toString(),
                    connectType: 3,
                    vendorId: element.vendorId.toString(),
                    productId: element.productId.toString(),
                  ));
                });
              }
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print("USB scan error: $error");
          }
        },
      );

      // Wait a bit for devices to be discovered, then trigger another scan
      await Future.delayed(const Duration(seconds: 2));

      // Try scanning again after delay
      await flutterThermalPrinterPlugin.getPrinters(connectionTypes: [
        ConnectionType.USB,
      ]);
    } catch (e, s) {
      if (kDebugMode) {
        print("Error scanning USB printers: $e");
        print(s);
      }
    }
  }

  void printTest() {
    switch (global.printerConnectToEnum(printerList[printerSelectedIndex].connectType)) {
      case global.PrinterConnectEnum.usb:
        printTestByUsb(printerList[printerSelectedIndex].productName);
        break;
      case global.PrinterConnectEnum.ip:
        printTestByIpAddress(ipAddress: ipAddressController.text, port: int.parse(portController.text));
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
    if (printerSelectedIndex == -1) return;

    final selectedPrinter = printerList[printerSelectedIndex];

    try {
      PaperSize paper = PaperSize.mm80;
      CapabilityProfile profile = await CapabilityProfile.load();
      final generator = Generator(paper, profile);

      double maxHeight = 10;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final backgroundPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawRect(const Rect.fromLTWH(0.0, 0.0, 640.0, 10000.0), backgroundPaint);

      for (int loop = 1; loop < 10; loop++) {
        TextSpan span = TextSpan(style: TextStyle(color: Colors.black, fontSize: 10 + (loop.toDouble() * 2)), text: "สวัสดี,Hello,ສະ​ບາຍດີ,你好,こんにちは,안녕하세요 $loop");
        TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(0, maxHeight.toDouble()));
        maxHeight += tp.height;
      }

      List<int> bytes = [];
      final picture = recorder.endRecording();
      final imageBuffer = picture.toImage(640, maxHeight.toInt());
      final pngBytes = await imageBuffer.then((value) => value.toByteData(format: ui.ImageByteFormat.png));
      im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
      int printMaxHeight = 1000;
      int calcLoop = imageDecode!.height ~/ printMaxHeight;

      for (int i = 0; i <= calcLoop; i++) {
        try {
          im.Image croppedImage = im.copyCrop(imageDecode, x: 0, y: i * printMaxHeight, width: imageDecode.width, height: printMaxHeight);
          bytes += generator.imageRaster(croppedImage);
        } catch (e, s) {
          if (kDebugMode) {
            print(e);
            print(s);
          }
        }
      }
      bytes += generator.feed(3);
      bytes += generator.cut();

      // Find the Bluetooth printer
      Printer? printer;
      try {
        // Re-scan to get fresh printer list
        await flutterThermalPrinterPlugin.getPrinters(connectionTypes: [ConnectionType.BLE]);
        await Future.delayed(const Duration(seconds: 1));

        printer = printers.firstWhere(
          (element) => element.address.toString() == selectedPrinter.deviceId,
        );
      } catch (e) {
        if (kDebugMode) {
          print("Bluetooth printer not found: ${selectedPrinter.deviceId}");
        }
        return;
      }

      await flutterThermalPrinterPlugin.printData(
        printer,
        bytes,
        longData: true,
      );

      if (kDebugMode) {
        print("Bluetooth print completed successfully");
      }
    } catch (e, s) {
      if (kDebugMode) {
        print("Bluetooth print error: $e");
        print(s);
      }
    }
  }

  void printTestByIpAddress({required String ipAddress, required int port}) async {
    io.Socket socket;
    try {
      PaperSize paper = PaperSize.mm80;
      CapabilityProfile profile = await CapabilityProfile.load();
      socket = await io.Socket.connect(ipAddress, port);
      socket.add([27, 64]);
      final generator = Generator(paper, profile);
      double maxHeight = 10;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final backgroundPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawRect(const Rect.fromLTWH(0.0, 0.0, 640.0, 10000.0), backgroundPaint);

      for (int loop = 1; loop < 10; loop++) {
        TextSpan span = TextSpan(style: TextStyle(color: Colors.black, fontSize: 24 + (loop.toDouble() * 2)), text: "สวัสดี,Hello,ສະ​ບາຍດີ,你好,こんにちは,안녕하세요 $loop");
        TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(0, maxHeight.toDouble()));
        maxHeight += tp.height;
      }
      List<int> bytes = [];
      final picture = recorder.endRecording();
      final imageBuffer = picture.toImage(640, maxHeight.toInt());
      final pngBytes = await imageBuffer.then((value) => value.toByteData(format: ui.ImageByteFormat.png));
      im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
      int printMaxHeight = 1000;
      int calcLoop = imageDecode!.height ~/ printMaxHeight;
      for (int i = 0; i <= calcLoop; i++) {
        try {
          im.Image croppedImage = im.copyCrop(imageDecode, x: 0, y: i * printMaxHeight, width: imageDecode.width, height: printMaxHeight);
          bytes += generator.imageRaster(croppedImage);
        } catch (e, s) {
          if (kDebugMode) {
            print(e);
            print(s);
          }
        }
      }
      bytes += generator.feed(3);
      bytes += generator.cut();
      socket.add(bytes);
      await socket.flush();
      await socket.close();
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
  }

  void printTestByWindows() async {
    // Windows printing is not supported on Android
    // This is a placeholder for future Windows support
    if (kDebugMode) {
      print("Windows printing not supported on this platform");
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(global.language("windows_print_not_supported")),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void printTestByUsb(String printerName) async {
    PaperSize paper = PaperSize.mm80;
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(paper, profile);
    try {
      double maxHeight = 10;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final backgroundPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawRect(const Rect.fromLTWH(0.0, 0.0, 640.0, 10000.0), backgroundPaint);

      for (int loop = 1; loop < 10; loop++) {
        TextSpan span = TextSpan(style: TextStyle(color: Colors.black, fontSize: 10 + (loop.toDouble() * 2)), text: "สวัสดี,Hello,ສະ​ບາຍດີ,你好,こんにちは,안녕하세요 $loop");
        TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(0, maxHeight.toDouble()));
        maxHeight += tp.height;
      }
      List<int> bytes = [];
      final picture = recorder.endRecording();
      final imageBuffer = picture.toImage(640, maxHeight.toInt());
      final pngBytes = await imageBuffer.then((value) => value.toByteData(format: ui.ImageByteFormat.png));
      im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
      int printMaxHeight = 1000;
      int calcLoop = imageDecode!.height ~/ printMaxHeight;
      for (int i = 0; i <= calcLoop; i++) {
        try {
          im.Image croppedImage = im.copyCrop(imageDecode, x: 0, y: i * printMaxHeight, width: imageDecode.width, height: printMaxHeight);
          bytes += generator.imageRaster(croppedImage);
        } catch (e, s) {
          if (kDebugMode) {
            print(e);
            print(s);
          }
        }
      }
      bytes += generator.feed(3);
      bytes += generator.cut();
      if (printers.isEmpty) {
        print("No printers available");
        return;
      }
      Printer? printer;
      try {
        printer = printers.firstWhere(
          (element) => element.productId.toString() == printerName,
        );
      } catch (e) {
        print("Printer not found: $printerName");
        return;
      }

      await flutterThermalPrinterPlugin.printData(
        printer,
        bytes,
        longData: true,
      );
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
  }

  // Get printer type icon
  IconData _getPrinterIcon(int connectType) {
    switch (global.printerConnectToEnum(connectType)) {
      case global.PrinterConnectEnum.usb:
        return Icons.usb;
      case global.PrinterConnectEnum.ip:
        return Icons.wifi;
      case global.PrinterConnectEnum.bluetooth:
        return Icons.bluetooth;
      case global.PrinterConnectEnum.windows:
        return Icons.computer;
    }
  }

  // Get printer type label
  String _getPrinterTypeLabel(int connectType) {
    switch (global.printerConnectToEnum(connectType)) {
      case global.PrinterConnectEnum.usb:
        return "USB";
      case global.PrinterConnectEnum.ip:
        return "Network";
      case global.PrinterConnectEnum.bluetooth:
        return "Bluetooth";
      case global.PrinterConnectEnum.windows:
        return "Windows";
    }
  }

  Widget _buildPrinterCard(int index) {
    final printer = printerList[index];
    final isSelected = index == printerSelectedIndex;
    final connectType = global.printerConnectToEnum(printer.connectType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? Colors.blue.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              printerSelectedIndex = index;
              switch (connectType) {
                case global.PrinterConnectEnum.usb:
                  usbDeviceController.text = printer.deviceName;
                  usbVendorIdController.text = printer.vendorId;
                  usbProductIdController.text = printer.productId;
                  break;
                case global.PrinterConnectEnum.ip:
                  ipAddressController.text = printer.ipAddress;
                  portController.text = "9100";
                  break;
                case global.PrinterConnectEnum.bluetooth:
                  ipAddressController.text = printer.ipAddress;
                  break;
                case global.PrinterConnectEnum.windows:
                  usbDeviceController.text = printer.deviceName;
                  usbVendorIdController.text = printer.vendorId;
                  usbProductIdController.text = printer.productId;
                  break;
              }
            });
            _showConfigDialog();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Printer Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getPrinterIcon(printer.connectType),
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Printer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.deviceName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getPrinterTypeLabel(printer.connectType),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          if (printer.ipAddress.isNotEmpty && connectType == global.PrinterConnectEnum.ip) ...[
                            const SizedBox(width: 8),
                            Text(
                              printer.ipAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Selection indicator
                if (isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.blue,
            size: 60,
          ),
          const SizedBox(height: 24),
          Text(
            global.language("searching_printers"),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "กำลังค้นหาเครื่องพิมพ์ในเครือข่าย...",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: printerList.length,
      itemBuilder: (context, index) => _buildPrinterCard(index),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool readOnly = false,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade500, size: 22) : null,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showConfigDialog() {
    if (printerSelectedIndex == -1) return;

    final selectedPrinter = printerList[printerSelectedIndex];
    final connectType = global.printerConnectToEnum(selectedPrinter.connectType);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.settings,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                global.language("printer_settings"),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedPrinter.deviceName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey.shade600,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Connection settings based on type
                    if (connectType == global.PrinterConnectEnum.usb) ...[
                      _buildTextField(
                        controller: usbDeviceController,
                        label: global.language("printer_usb_device"),
                        prefixIcon: Icons.usb,
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: usbVendorIdController,
                              label: global.language("printer_usb_vendor_id"),
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: usbProductIdController,
                              label: global.language("printer_usb_product_id"),
                              readOnly: true,
                            ),
                          ),
                        ],
                      ),
                    ] else if (connectType == global.PrinterConnectEnum.ip) ...[
                      _buildTextField(
                        controller: ipAddressController,
                        label: global.language("printer_ip_address"),
                        hint: "xxx.xxx.xxx.xxx",
                        prefixIcon: Icons.wifi,
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: portController,
                        label: global.language("printer_ip_port"),
                        hint: "9100",
                        prefixIcon: Icons.numbers,
                      ),
                    ] else if (connectType == global.PrinterConnectEnum.bluetooth) ...[
                      _buildTextField(
                        controller: ipAddressController,
                        label: global.language("printer_mac_address"),
                        hint: "xx:xx:xx:xx:xx:xx",
                        prefixIcon: Icons.bluetooth,
                        readOnly: true,
                      ),
                    ] else if (connectType == global.PrinterConnectEnum.windows) ...[
                      _buildTextField(
                        controller: ipAddressController,
                        label: global.language("printer_name"),
                        prefixIcon: Icons.computer,
                        readOnly: true,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Paper size selection
                    Text(
                      global.language("printer_paper_size"),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildPaperSizeOption(1, "58mm"),
                        const SizedBox(width: 12),
                        _buildPaperSizeOption(2, "80mm"),
                      ],
                    ),

                    // const SizedBox(height: 20),

                    // // Auto print checkbox
                    // Container(
                    //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    //   decoration: BoxDecoration(
                    //     color: Colors.grey.shade50,
                    //     borderRadius: BorderRadius.circular(12),
                    //     border: Border.all(color: Colors.grey.shade200),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       SizedBox(
                    //         width: 24,
                    //         height: 24,
                    //         child: Checkbox(
                    //           value: printBillAuto,
                    //           onChanged: (value) {
                    //             setState(() {
                    //               printBillAuto = value!;
                    //             });
                    //           },
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(4),
                    //           ),
                    //           activeColor: Colors.blue,
                    //         ),
                    //       ),
                    //       const SizedBox(width: 12),
                    //       Expanded(
                    //         child: Text(
                    //           global.language("printer_print_bill_auto"),
                    //           style: TextStyle(
                    //             fontSize: 14,
                    //             color: Colors.grey.shade700,
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    const SizedBox(height: 24),

                    // Test and Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _onTestAndSave,
                        icon: const Icon(Icons.print, size: 22),
                        label: Text(
                          global.language("printer_connect_test_and_save"),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaperSizeOption(int value, String label) {
    final isSelected = printerPaperSize == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            printerPaperSize = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? Colors.white : Colors.grey.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTestAndSave() {
    printTest();
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.print,
                color: Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                global.language("printer_connect_test"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          global.language("printer_connect_test_success"),
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              global.language("fail"),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              var data = PrinterLocalConfigModel(
                code: printerCode,
                name: printerName,
                printerConnectType: printerList[printerSelectedIndex].connectType,
                printerType: printerList[printerSelectedIndex].printerType,
                ipAddress: ipAddressController.text,
                ipPort: int.tryParse(portController.text) ?? 0,
                productName: "",
                deviceName: printerList[printerSelectedIndex].deviceName,
                deviceId: "",
                manufacturer: "",
                isConfigConnectSuccess: true,
                vendorId: printerList[printerSelectedIndex].vendorId,
                productId: printerList[printerSelectedIndex].productId,
                paperType: printerPaperSize,
                printBillAuto: printBillAuto,
              );
              if (mounted) {
                Navigator.pop(context); // ปิด AlertDialog ยืนยัน
                Navigator.pop(context); // ปิด Config Dialog
                Navigator.pop(context, data); // ปิดหน้า SelectPrinterPage และส่ง data กลับ
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              global.language("success"),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryThemeColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () {
            _bluetoothStreamSubscription?.cancel();
            _devicesStreamSubscription?.cancel();
            Navigator.pop(context);
          },
        ),
        title: Text(
          global.language('printer_config'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              onPressed: getDeviceList,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Icon(
                  Icons.print_outlined,
                  color: Colors.grey.shade600,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  global.language("available_printers"),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                if (printerList.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${printerList.length} ${global.language("found")}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Printer list or loading/empty state
            if (printerList.isEmpty)
              SizedBox(
                height: 300,
                child: _buildLoadingState(),
              )
            else
              _buildPrinterList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
