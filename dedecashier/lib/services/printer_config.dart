import 'dart:convert';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/services/printer_config_select_form.dart';
import 'package:dedecashier/services/printer_config_select_printer.dart';
import 'package:flutter/material.dart';

// ⭐ Theme Colors: Ban Chiang Terracotta - Minimalist & Modern
class BanChiangTheme {
  BanChiangTheme._();

  // Primary Terracotta
  static const Color primary = Color(0xFFB5651D);
  static const Color primaryDark = Color(0xFF8B4513);
  static const Color primaryLight = Color(0xFFD4A574);

  // Surface & Background
  static const Color surface = Color(0xFFFAF6F2);
  static const Color surfaceVariant = Color(0xFFF5EDE5);
  static const Color cardBg = Colors.white;

  // Status Colors (Muted for Minimalist)
  static const Color success = Color(0xFF6B8E6B);
  static const Color error = Color(0xFFC27B7B);
  static const Color inactive = Color(0xFFB0A090);

  // Marine Theme
  static const Color marinePrimary = Color(0xFF005598);

  // Helper to get theme color based on flavor
  static Color get themeColor => (F.appFlavor == Flavor.MARINEPOS) ? marinePrimary : primary;
  static Color get themeLightBg => (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFFE8F0F8) : surfaceVariant;
}

class PrinterConfigScreen extends StatefulWidget {
  const PrinterConfigScreen({super.key});

  @override
  State<PrinterConfigScreen> createState() => _PrinterConfigScreenState();
}

class _PrinterConfigScreenState extends State<PrinterConfigScreen> {
  // ⭐ Dialog แสดงรายละเอียดเครื่องพิมพ์ที่จัดเก็บ
  Future<void> _showStoredPrintersDialog() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: BanChiangTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.print_rounded, color: BanChiangTheme.themeColor, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('เครื่องพิมพ์ที่จัดเก็บ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: global.printerLocalStrongData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.print_disabled_rounded, size: 48, color: BanChiangTheme.inactive),
                        const SizedBox(height: 12),
                        Text('ไม่มีเครื่องพิมพ์ที่จัดเก็บ', style: TextStyle(color: BanChiangTheme.inactive)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: global.printerLocalStrongData.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final printer = global.printerLocalStrongData[index];
                      final bool hasConfig = printer.isConfigConnectSuccess && (printer.ipAddress.isNotEmpty || printer.deviceId.isNotEmpty || printer.deviceName.isNotEmpty);

                      return Container(
                        decoration: BoxDecoration(color: BanChiangTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: hasConfig ? BanChiangTheme.success.withOpacity(0.15) : BanChiangTheme.inactive.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              hasConfig ? Icons.print_rounded : Icons.print_disabled_rounded,
                              color: hasConfig ? BanChiangTheme.success : BanChiangTheme.inactive,
                              size: 20,
                            ),
                          ),
                          title: Text(printer.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                            hasConfig ? _getPrinterTypeText(printer) : 'ยังไม่ได้ตั้งค่า',
                            style: TextStyle(color: hasConfig ? Colors.black54 : BanChiangTheme.inactive, fontSize: 12),
                          ),
                          trailing: hasConfig
                              ? IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: BanChiangTheme.error, size: 20),
                                  onPressed: () => _confirmDeletePrinter(printer, index, setDialogState),
                                )
                              : null,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('Code', printer.code),
                                  if (printer.ipAddress.isNotEmpty) _buildInfoRow('IP Address', '${printer.ipAddress}:${printer.ipPort}'),
                                  if (printer.deviceId.isNotEmpty) _buildInfoRow('Device ID', printer.deviceId),
                                  if (printer.deviceName.isNotEmpty) _buildInfoRow('Device Name', printer.deviceName),
                                  if (printer.manufacturer.isNotEmpty) _buildInfoRow('Manufacturer', printer.manufacturer),
                                  _buildInfoRow('Connect Type', printer.printerConnectType.name),
                                  _buildInfoRow('สถานะ', printer.isConfigConnectSuccess ? '✅ เชื่อมต่อแล้ว' : '❌ ยังไม่เชื่อมต่อ'),
                                  _buildInfoRow('พร้อมใช้งาน', printer.isReady ? '✅ พร้อม' : '❌ ไม่พร้อม'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ปิด', style: TextStyle(color: BanChiangTheme.themeColor)),
            ),
            if (global.printerLocalStrongData.any((p) => p.ipAddress.isNotEmpty || p.deviceId.isNotEmpty))
              TextButton(
                onPressed: () => _confirmClearAllPrinters(setDialogState),
                style: TextButton.styleFrom(foregroundColor: BanChiangTheme.error),
                child: const Text('ลบทั้งหมด'),
              ),
          ],
        ),
      ),
    );
  }

  String _getPrinterTypeText(PrinterLocalStrongDataModel printer) {
    switch (printer.printerConnectType) {
      case global.PrinterConnectEnum.ip:
        return 'IP: ${printer.ipAddress}:${printer.ipPort}';
      case global.PrinterConnectEnum.bluetooth:
        return 'Bluetooth: ${printer.deviceName}';
      case global.PrinterConnectEnum.usb:
        return 'USB: ${printer.deviceName}';
      case global.PrinterConnectEnum.windows:
        return 'Windows: ${printer.deviceName}';
      case global.PrinterConnectEnum.sunmi1:
        return 'Sunmi Built-in';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: BanChiangTheme.inactive, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePrinter(PrinterLocalStrongDataModel printer, int index, StateSetter setDialogState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการลบ', style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text('ต้องการลบเครื่องพิมพ์ "${printer.name}" หรือไม่?\n\nข้อมูลการตั้งค่าจะถูกลบออก'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: TextStyle(color: BanChiangTheme.inactive)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: BanChiangTheme.error),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // ลบข้อมูลจาก storage
      await global.appStorage.remove(printer.code);

      // Reset printer data
      global.printerLocalStrongData[index] = PrinterLocalStrongDataModel(code: printer.code, name: printer.name, isReady: false, isConfigConnectSuccess: false);

      // Save empty config
      var jsonString = const JsonEncoder().convert(global.printerLocalStrongData[index].toJson());
      await global.appStorage.write(printer.code, jsonString);

      setDialogState(() {});
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบเครื่องพิมพ์ "${printer.name}" แล้ว'),
            backgroundColor: BanChiangTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _confirmClearAllPrinters(StateSetter setDialogState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการลบทั้งหมด', style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text('ต้องการลบข้อมูลเครื่องพิมพ์ทั้งหมดหรือไม่?\n\nการดำเนินการนี้ไม่สามารถยกเลิกได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: TextStyle(color: BanChiangTheme.inactive)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: BanChiangTheme.error),
            child: const Text('ลบทั้งหมด'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (int i = 0; i < global.printerLocalStrongData.length; i++) {
        final printer = global.printerLocalStrongData[i];
        await global.appStorage.remove(printer.code);

        global.printerLocalStrongData[i] = PrinterLocalStrongDataModel(code: printer.code, name: printer.name, isReady: false, isConfigConnectSuccess: false);

        var jsonString = const JsonEncoder().convert(global.printerLocalStrongData[i].toJson());
        await global.appStorage.write(printer.code, jsonString);
      }

      setDialogState(() {});
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ลบข้อมูลเครื่องพิมพ์ทั้งหมดแล้ว'),
            backgroundColor: BanChiangTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Widget _buildPrinterCard(int index) {
    final printerData = global.printerLocalStrongData[index];
    final isConnected = printerData.isConfigConnectSuccess;

    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: BanChiangTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: BanChiangTheme.primary.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BanChiangTheme.themeLightBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isConnected ? BanChiangTheme.success.withOpacity(0.15) : BanChiangTheme.inactive.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(isConnected ? Icons.print_rounded : Icons.print_disabled_rounded, size: 18, color: isConnected ? BanChiangTheme.success : BanChiangTheme.inactive),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    printerData.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connect/Disconnect Button
                _buildActionButton(
                  label: isConnected ? global.language("printer_remove") : global.language("printer_connect"),
                  icon: isConnected ? Icons.link_off_rounded : Icons.link_rounded,
                  color: isConnected ? BanChiangTheme.error : BanChiangTheme.themeColor,
                  onPressed: () => _handlePrinterAction(index),
                ),

                // Form Select Button (only for first printer)
                if (index == 0) ...[
                  const SizedBox(height: 8),
                  _buildActionButton(
                    label: global.language('printer_select_form'),
                    icon: Icons.article_outlined,
                    color: BanChiangTheme.primaryLight,
                    onPressed: () => _navigateToFormSelect(index),
                  ),
                ],

                // Connection Info
                if (isConnected) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: BanChiangTheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (printerData.ipAddress.isNotEmpty) _buildConnectionInfo(Icons.wifi_rounded, '${printerData.ipAddress}:${printerData.ipPort}'),
                        if (printerData.deviceName.isNotEmpty) _buildConnectionInfo(Icons.devices_rounded, printerData.deviceName),
                        if (printerData.deviceId.isNotEmpty && printerData.deviceName.isEmpty) _buildConnectionInfo(Icons.tag_rounded, printerData.deviceId),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: BanChiangTheme.inactive),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: BanChiangTheme.primaryDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrinterAction(int index) async {
    if (global.printerLocalStrongData[index].isConfigConnectSuccess) {
      // Disconnect
      String code = global.printerLocalStrongData[index].code;
      String name = global.printerLocalStrongData[index].name;
      await global.appStorage.remove(code);
      global.printerLocalStrongData[index] = PrinterLocalStrongDataModel(code: code, name: name, isReady: false, isConfigConnectSuccess: false);
      var jsonString = const JsonEncoder().convert(global.printerLocalStrongData[index].toJson());
      await global.appStorage.write(code, jsonString);
      await global.loadPrinter();
      setState(() {});
      return;
    }

    // Navigate to printer selection
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrinterConfigSelectPrinterScreen(printerCode: global.printerLocalStrongData[index].code, printerName: global.printerLocalStrongData[index].name),
      ),
    ).then((value) async {
      await global.loadPrinter();
      setState(() {});
    });
  }

  Future<void> _navigateToFormSelect(int index) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => PrinterConfigSelectFormPage(printer: global.printerLocalStrongData[index]))).then((value) async {
      await global.loadPrinter();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BanChiangTheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: BanChiangTheme.themeColor,
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(global.language('printer_config'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [IconButton(icon: const Icon(Icons.list_alt_rounded, size: 22), tooltip: 'ดูเครื่องพิมพ์ที่จัดเก็บ', onPressed: _showStoredPrintersDialog)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(spacing: 12, runSpacing: 12, children: [for (int index = 0; index < global.printerLocalStrongData.length; index++) _buildPrinterCard(index)]),
      ),
    );
  }
}
