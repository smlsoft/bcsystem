import 'dart:io' as io;
import 'dart:async';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'dart:ui' as ui;
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:image/image.dart' as img;
import 'package:dedecashier/core/logger/app_logger.dart';

// ⭐ Ban Chiang Theme (shared with printer_config.dart)
class _BanChiangTheme {
  _BanChiangTheme._();

  static const Color primary = Color(0xFFB5651D);
  static const Color primaryDark = Color(0xFF8B4513);
  static const Color surface = Color(0xFFFAF6F2);
  static const Color surfaceVariant = Color(0xFFF5EDE5);
  static const Color cardBg = Colors.white;
  static const Color success = Color(0xFF6B8E6B);
  static const Color error = Color(0xFFC27B7B);
  static const Color inactive = Color(0xFFB0A090);
  static const Color marinePrimary = Color(0xFF005598);

  static Color get themeColor => (F.appFlavor == Flavor.MARINEPOS) ? marinePrimary : primary;
}

class PrinterConfigSelectPrinterScreen extends StatefulWidget {
  final String printerCode;
  final String printerName;

  const PrinterConfigSelectPrinterScreen({super.key, required this.printerCode, required this.printerName});

  @override
  State<PrinterConfigSelectPrinterScreen> createState() => _PrinterConfigSelectPrinterScreenState();
}

class _PrinterConfigSelectPrinterScreenState extends State<PrinterConfigSelectPrinterScreen> {
  // Controllers
  final TextEditingController _usbDeviceController = TextEditingController();
  final TextEditingController _usbVendorIdController = TextEditingController();
  final TextEditingController _usbProductIdController = TextEditingController();
  final TextEditingController _ipAddressController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  // State
  List<PrinterDeviceModel> _printerList = [];
  bool _printBillAuto = true;
  int _printerPaperSize = 2;
  int _printerSelectedIndex = -1;
  bool _isScanning = false;

  // Thermal Printer
  final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
  StreamSubscription<List<Printer>>? _devicesStreamSubscription;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _devicesStreamSubscription?.cancel();
    _usbDeviceController.dispose();
    _usbVendorIdController.dispose();
    _usbProductIdController.dispose();
    _ipAddressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _printerList.clear();
    });

    await _scanPrinters();

    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _scanPrinters() async {
    // Windows printers
    if (io.Platform.isWindows) {
      try {
        List<PrinterDeviceModel> results = global.windowsListPrinters();
        for (var printer in results) {
          _printerList.add(
            PrinterDeviceModel(
              fullName: "Windows: ${printer.fullName}",
              productName: printer.productName,
              deviceName: printer.deviceName,
              deviceId: printer.deviceId,
              manufacturer: printer.manufacturer,
              vendorId: printer.vendorId,
              productId: printer.productId,
              connectType: global.PrinterConnectEnum.windows,
            ),
          );
        }
        if (mounted) setState(() {});
      } catch (e) {
        AppLogger.error(e);
      }
    }

    // USB printers
    await _scanUsbPrinters();

    // Network printers
    await _scanNetworkPrinters();
  }

  Future<void> _scanUsbPrinters() async {
    try {
      _devicesStreamSubscription?.cancel();
      await _flutterThermalPrinterPlugin.getPrinters(connectionTypes: [ConnectionType.USB]);
      _devicesStreamSubscription = _flutterThermalPrinterPlugin.devicesStream.listen((List<Printer> event) {
        _devicesStreamSubscription?.cancel();
        for (var element in event) {
          _printerList.add(
            PrinterDeviceModel(
              fullName: "USB: ${element.name}",
              productName: element.productId.toString(),
              deviceName: element.name.toString(),
              deviceId: element.address.toString(),
              connectType: global.PrinterConnectEnum.usb,
              vendorId: element.vendorId.toString(),
              productId: element.productId.toString(),
            ),
          );
        }
        if (mounted) setState(() {});
      });
    } catch (e) {
      AppLogger.error(e);
    }
  }

  Future<void> _scanNetworkPrinters() async {
    if (global.ipAddress.isEmpty) return;

    String subNet = global.ipAddress.substring(0, global.ipAddress.lastIndexOf('.'));
    const int port = 9100;
    const int batchSize = 50; // ⭐ เพิ่ม batch size เพื่อความเร็ว

    for (int i = 254; i >= 1; i -= batchSize) {
      List<Future<void>> futures = [];
      for (int j = i; j > i - batchSize && j >= 1; j--) {
        futures.add(_scanIP("$subNet.$j", port));
      }
      await Future.wait(futures);
    }
  }

  Future<void> _scanIP(String ip, int port) async {
    try {
      final socket = await io.Socket.connect(ip, port, timeout: const Duration(seconds: 2));
      bool ipDuplicate = _printerList.any((p) => p.ipAddress == ip);
      if (!ipDuplicate && mounted) {
        setState(() {
          _printerList.add(
            PrinterDeviceModel(
              fullName: "IP: $ip",
              productName: "Network Printer",
              deviceName: ip,
              deviceId: ip,
              ipAddress: ip,
              ipPort: port,
              connectType: global.PrinterConnectEnum.ip,
            ),
          );
        });
      }
      socket.destroy();
    } catch (_) {
      // Connection failed - printer not found at this IP
    }
  }

  Future<void> _printTest() async {
    if (_printerSelectedIndex < 0) return;

    if (kDebugMode) {
      AppLogger.debug('🖨️ printTest() - ${_printerList[_printerSelectedIndex].connectType}');
    }

    switch (_printerList[_printerSelectedIndex].connectType) {
      case global.PrinterConnectEnum.usb:
        await _printTestByUsb(_printerSelectedIndex);
        break;
      case global.PrinterConnectEnum.ip:
        final ip = _ipAddressController.text;
        final port = int.tryParse(_portController.text) ?? 9100;
        await _printTestByIpAddress(ipAddress: ip, port: port);
        break;
      case global.PrinterConnectEnum.bluetooth:
        // Bluetooth print (not implemented)
        break;
      case global.PrinterConnectEnum.windows:
        await _printTestByWindows(_printerSelectedIndex);
        break;
      case global.PrinterConnectEnum.sunmi1:
        // Sunmi print (not implemented)
        break;
    }
  }

  Future<void> _printTestByUsb(int printerSelectedIndex) async {
    try {
      Printer printer = Printer(
        address: _printerList[printerSelectedIndex].ipAddress,
        name: _printerList[printerSelectedIndex].deviceName,
        vendorId: _printerList[printerSelectedIndex].vendorId,
        productId: _printerList[printerSelectedIndex].productId,
        connectionType: ConnectionType.USB,
        isConnected: false,
      );
      await _flutterThermalPrinterPlugin.connect(printer);
      await Future.delayed(const Duration(milliseconds: 500));

      var bytes = await _createTicket();

      await _flutterThermalPrinterPlugin.printData(printer, bytes);
      await _flutterThermalPrinterPlugin.disconnect(printer);
    } catch (e) {
      AppLogger.error(e);
    }
  }

  Future<void> _printTestByIpAddress({required String ipAddress, required int port}) async {
    io.Socket? socket;
    try {
      socket = await io.Socket.connect(ipAddress, port, timeout: const Duration(seconds: 5));
      socket.add([27, 64]); // ESC @ - Initialize printer

      List<int> bytes = await _createTicket();

      socket.add(bytes);
      await socket.flush();
      await Future.delayed(const Duration(milliseconds: 500));
      await socket.close();
    } catch (e) {
      if (kDebugMode) AppLogger.error('❌ printTestByIpAddress error: $e');
      rethrow;
    } finally {
      try {
        socket?.destroy();
      } catch (_) {}
    }
  }

  Future<void> _printTestByWindows(int printerSelectedIndex) async {
    String printerName = _printerList[printerSelectedIndex].deviceName;

    try {
      final printerBytes = await _createTicket();
      global.windowsPrintRawData(printerName, printerBytes, "");
    } catch (e) {
      AppLogger.error(e);
    }
  }

  void _selectPrinter(int index) {
    setState(() {
      _printerSelectedIndex = index;
      final printer = _printerList[index];

      switch (printer.connectType) {
        case global.PrinterConnectEnum.usb:
          _usbDeviceController.text = printer.deviceName;
          _usbVendorIdController.text = printer.vendorId;
          _usbProductIdController.text = printer.productId;
          break;
        case global.PrinterConnectEnum.ip:
          _ipAddressController.text = printer.ipAddress;
          _portController.text = "9100";
          break;
        case global.PrinterConnectEnum.bluetooth:
          _ipAddressController.text = printer.ipAddress;
          break;
        case global.PrinterConnectEnum.windows:
        case global.PrinterConnectEnum.sunmi1:
          _ipAddressController.text = printer.deviceName;
          _usbDeviceController.text = printer.deviceName;
          _usbVendorIdController.text = printer.vendorId;
          _usbProductIdController.text = printer.productId;
          break;
      }
    });
  }

  IconData _getPrinterIcon(global.PrinterConnectEnum type) {
    switch (type) {
      case global.PrinterConnectEnum.usb:
        return Icons.usb_rounded;
      case global.PrinterConnectEnum.ip:
        return Icons.wifi_rounded;
      case global.PrinterConnectEnum.bluetooth:
        return Icons.bluetooth_rounded;
      case global.PrinterConnectEnum.windows:
        return Icons.desktop_windows_rounded;
      case global.PrinterConnectEnum.sunmi1:
        return Icons.point_of_sale_rounded;
    }
  }

  // ===============================
  // UI WIDGETS
  // ===============================

  Widget _buildPrinterListWidget() {
    if (_isScanning && _printerList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, color: _BanChiangTheme.themeColor)),
            const SizedBox(height: 16),
            Text('กำลังค้นหาเครื่องพิมพ์...', style: TextStyle(color: _BanChiangTheme.inactive)),
          ],
        ),
      );
    }

    if (_printerList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.print_disabled_rounded, size: 48, color: _BanChiangTheme.inactive),
            const SizedBox(height: 12),
            Text(
              'ไม่พบเครื่องพิมพ์',
              style: TextStyle(color: _BanChiangTheme.inactive, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('ค้นหาอีกครั้ง'),
              style: TextButton.styleFrom(foregroundColor: _BanChiangTheme.themeColor),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _printerList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final printer = _printerList[index];
        final isSelected = index == _printerSelectedIndex;

        return Material(
          color: isSelected ? _BanChiangTheme.themeColor.withOpacity(0.1) : _BanChiangTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _selectPrinter(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? _BanChiangTheme.themeColor : Colors.transparent, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? _BanChiangTheme.themeColor.withOpacity(0.15) : _BanChiangTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_getPrinterIcon(printer.connectType), size: 20, color: isSelected ? _BanChiangTheme.themeColor : _BanChiangTheme.inactive),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          printer.fullName,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isSelected ? _BanChiangTheme.primaryDark : Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          printer.connectType.name.toUpperCase(),
                          style: TextStyle(fontSize: 11, color: _BanChiangTheme.inactive, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) Icon(Icons.check_circle_rounded, color: _BanChiangTheme.themeColor, size: 22),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsPanel() {
    if (_printerSelectedIndex == -1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _BanChiangTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _BanChiangTheme.primary.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Printer Title
          Row(
            children: [
              Icon(Icons.settings_rounded, size: 18, color: _BanChiangTheme.themeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _printerList[_printerSelectedIndex].fullName,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _BanChiangTheme.primaryDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Paper Size Selection
          _buildSectionTitle('ขนาดกระดาษ'),
          const SizedBox(height: 8),
          Row(children: [_buildRadioOption(1, '58mm'), const SizedBox(width: 16), _buildRadioOption(2, '80mm')]),

          const SizedBox(height: 16),

          // Auto Print Checkbox
          _buildCheckboxOption(),

          const SizedBox(height: 20),

          // Test & Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleTestAndSave,
              icon: const Icon(Icons.print_rounded, size: 18),
              label: Text(global.language("printer_connect_test_and_save")),
              style: ElevatedButton.styleFrom(
                backgroundColor: _BanChiangTheme.themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _BanChiangTheme.inactive),
    );
  }

  Widget _buildRadioOption(int value, String label) {
    final isSelected = _printerPaperSize == value;
    return Expanded(
      child: Material(
        color: isSelected ? _BanChiangTheme.themeColor.withOpacity(0.1) : _BanChiangTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _printerPaperSize = value),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  size: 18,
                  color: isSelected ? _BanChiangTheme.themeColor : _BanChiangTheme.inactive,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? _BanChiangTheme.primaryDark : _BanChiangTheme.inactive),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxOption() {
    return Material(
      color: _BanChiangTheme.surfaceVariant,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => setState(() => _printBillAuto = !_printBillAuto),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(
                _printBillAuto ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: _printBillAuto ? _BanChiangTheme.themeColor : _BanChiangTheme.inactive,
              ),
              const SizedBox(width: 12),
              Text(
                global.language("printer_print_bill_auto"),
                style: TextStyle(fontWeight: FontWeight.w500, color: _printBillAuto ? _BanChiangTheme.primaryDark : _BanChiangTheme.inactive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTestAndSave() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _BanChiangTheme.themeColor),
              const SizedBox(height: 16),
              const Text('กำลังทดสอบพิมพ์...'),
            ],
          ),
        ),
      );

      await _printTest();
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(global.language("printer_connect_test"), style: const TextStyle(fontWeight: FontWeight.w600)),
          content: Text(global.language("printer_connect_test_success")),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(global.language("fail"), style: TextStyle(color: _BanChiangTheme.error)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _BanChiangTheme.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(global.language("success")),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        await _savePrinterConfig();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading if open

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: _BanChiangTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _savePrinterConfig() async {
    var data = PrinterLocalStrongDataModel(
      code: widget.printerCode,
      name: widget.printerName,
      printerConnectType: _printerList[_printerSelectedIndex].connectType,
      printerType: _printerList[_printerSelectedIndex].printerType,
      ipAddress: _ipAddressController.text,
      ipPort: int.tryParse(_portController.text) ?? 0,
      productName: _printerList[_printerSelectedIndex].productName,
      deviceName: _printerList[_printerSelectedIndex].deviceName,
      deviceId: _printerList[_printerSelectedIndex].deviceId,
      manufacturer: "",
      isConfigConnectSuccess: true,
      vendorId: _printerList[_printerSelectedIndex].vendorId,
      productId: _printerList[_printerSelectedIndex].productId,
      paperType: _printerPaperSize,
      printBillAuto: _printBillAuto,
    );

    var jsonString = const JsonEncoder().convert(data.toJson());
    await global.appStorage.write(widget.printerCode, jsonString);
    global.loadConfig();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _BanChiangTheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _BanChiangTheme.themeColor,
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(widget.printerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          if (_isScanning)
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else
            IconButton(icon: const Icon(Icons.refresh_rounded, size: 22), onPressed: _startScan),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Icon(Icons.print_rounded, size: 20, color: _BanChiangTheme.themeColor),
                const SizedBox(width: 8),
                Text(
                  'เลือกเครื่องพิมพ์',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: _BanChiangTheme.primaryDark),
                ),
                const Spacer(),
                if (_printerList.isNotEmpty) Text('${_printerList.length} เครื่อง', style: TextStyle(fontSize: 12, color: _BanChiangTheme.inactive)),
              ],
            ),
            const SizedBox(height: 12),

            // Printer List
            _buildPrinterListWidget(),

            // Settings Panel
            _buildSettingsPanel(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===============================
  // PRINT UTILITIES
  // ===============================

  Future<List<int>> _createTicket() async {
    try {
      final generator = Generator(PaperSize.mm80, await CapabilityProfile.load());

      double maxHeight = 20.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final backgroundPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawRect(const Rect.fromLTWH(0.0, 0.0, 640.0, 20000.0), backgroundPaint);

      for (int loop = 0; loop < 10; loop++) {
        double fontSize = 12.0 + (loop * 2);

        final TextSpan span = TextSpan(
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            //fontFamily: 'nato'
          ),
          text: "TEST,ทดสอบ ${global.moneyFormat.format(fontSize)}",
        );

        final TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);

        tp.layout();
        tp.paint(canvas, Offset(0, maxHeight));
        maxHeight += tp.height;
      }

      final List<int> bytes = [];
      final picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(640, maxHeight.toInt());

      final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes == null) {
        throw Exception('Failed to generate image bytes');
      }

      final imageDecode = img.decodeImage(pngBytes.buffer.asUint8List());
      if (imageDecode == null) {
        throw Exception('Failed to decode image');
      }

      bytes.addAll(generator.reset());
      bytes.addAll(generator.imageRaster(imageDecode));
      bytes.addAll(generator.feed(2));
      bytes.addAll(generator.cut());
      bytes.addAll(generator.drawer());

      return bytes;
    } catch (e) {
      AppLogger.error('Error generating ticket: $e');
      rethrow;
    }
  }
}
