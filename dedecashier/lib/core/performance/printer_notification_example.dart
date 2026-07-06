import 'package:flutter/material.dart';
import 'package:dedecashier/core/performance/app_performance_manager.dart';

/// ตัวอย่างการใช้งาน Printer Notification System
class PrinterNotificationExample extends StatefulWidget {
  const PrinterNotificationExample({super.key});

  @override
  State<PrinterNotificationExample> createState() =>
      _PrinterNotificationExampleState();
}

class _PrinterNotificationExampleState
    extends State<PrinterNotificationExample> {
  @override
  void initState() {
    super.initState();
    // เริ่ม performance manager
    AppPerformanceManager.instance.start();
  }

  @override
  void dispose() {
    AppPerformanceManager.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          // 📄 Main Content
          Scaffold(
            appBar: AppBar(
              title: const Text('POS System'),
              actions: [
                // 🔴 Status Indicator (แสดงสถานะถาวร)
                const PrinterStatusIndicator(),
                const SizedBox(width: 16),
              ],
            ),
            body: _buildContent(),
          ),

          // 🔔 Notification Overlay (แสดงเมื่อมีการเปลี่ยนแปลง)
          const PrinterNotificationOverlay(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Printer Status Monitor',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // แสดงสถานะ realtime
          _buildPrinterStatusList(),

          const SizedBox(height: 24),

          // ปุ่มทดสอบ (สำหรับ development)
          _buildTestButtons(),
        ],
      ),
    );
  }

  Widget _buildPrinterStatusList() {
    return ValueListenableBuilder<Map<String, bool>>(
      valueListenable: AppPerformanceManager.printerDetailStatusNotifier,
      builder: (context, printerDetails, child) {
        if (printerDetails.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('ไม่มีเครื่องพิมพ์'),
            ),
          );
        }

        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: printerDetails.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final entry = printerDetails.entries.elementAt(index);
              return ListTile(
                leading: Icon(
                  Icons.print,
                  color: entry.value ? Colors.green : Colors.red,
                ),
                title: Text(entry.key),
                subtitle: Text(
                  entry.value ? 'พร้อมใช้งาน' : 'ไม่พร้อมใช้งาน',
                  style: TextStyle(
                    color: entry.value ? Colors.green : Colors.red,
                  ),
                ),
                trailing: entry.value
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.error, color: Colors.red),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTestButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test Buttons (Development Only)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // Force update สถานะ
                AppPerformanceManager.instance.forceUpdatePrinterStatus();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Force Update'),
            ),
          ],
        ),
      ],
    );
  }
}
