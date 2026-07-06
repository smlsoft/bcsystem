import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;

/// Widgets สำหรับแสดง status indicators ต่างๆ
/// แยกออกจาก pos_screen.dart เพื่อลดความซับซ้อน
class PosStatusWidgets {
  /// แสดง Button Size Indicator (S, M, L, XL)
  static Widget buildButtonSizeIndicator({
    required int currentLevel,
    required VoidCallback onTap,
  }) {
    List<String> sizeNames = ['S', 'M', 'L', 'XL'];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            sizeNames[currentLevel],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  /// แสดง Status Icon สำหรับ connection, printer, edc
  static Widget buildStatusIcon({
    required String type,
    required bool isReady,
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    // กำหนด icon ที่ไม่ต้องมีขอบและพื้นหลัง (online และ printer)
    bool shouldHaveBackground =
        !(type == "internet_connect" || type == "thermal_printer");

    Widget iconWidget = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: shouldHaveBackground
            ? (isReady
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: shouldHaveBackground
            ? Border.all(color: isReady ? Colors.green : Colors.red, width: 1)
            : null,
      ),
      child: Tooltip(
        message: tooltip,
        child: Icon(
          icon,
          size: 24,
          color: isReady ? Colors.green.shade400 : Colors.red.shade400,
        ),
      ),
    );

    // เพิ่มการคลิกถ้ามี callback
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: iconWidget);
    }

    return iconWidget;
  }

  /// Dialog แสดงสถานะเครื่องพิมพ์
  static Widget buildPrinterStatusDialog(BuildContext context) {
    // ตรวจสอบว่าทุกเครื่องพร้อมหรือไม่
    final allReady = global.printerLocalStrongData.every(
      (printer) => printer.isReady,
    );
    final statusColor = allReady ? Colors.green : Colors.red;
    final statusIcon = allReady ? Icons.check_circle : Icons.error;
    final statusText = allReady
        ? 'ทุกเครื่องพร้อมใช้งาน'
        : 'มีเครื่องพิมพ์ไม่พร้อม';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.print, size: 32, color: statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'สถานะเครื่องพิมพ์',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'ปิด',
                ),
              ],
            ),
            const Divider(height: 24),

            // Overall Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, size: 32, color: statusColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${global.printerLocalStrongData.length} เครื่องพิมพ์',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Printer List
            if (global.printerLocalStrongData.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: global.printerLocalStrongData.length,
                  itemBuilder: (context, index) {
                    final printer = global.printerLocalStrongData[index];
                    final isReady = printer.isReady;
                    final printerColor = isReady ? Colors.green : Colors.red;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: printerColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          isReady ? Icons.check_circle : Icons.error,
                          color: printerColor,
                          size: 24,
                        ),
                        title: Text(
                          printer.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isReady ? 'พร้อมใช้งาน' : 'ไม่พร้อม',
                          style: TextStyle(
                            fontSize: 12,
                            color: printerColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: printerColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'ไม่พบเครื่องพิมพ์',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'ปิด',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
