import 'package:dedecashier/api/sync/sync_bill.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_sale_channel.dart';
import 'package:dedecashier/features/pos/presentation/screens/print_queue_viewer.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/model/objectbox/print_queue_struct.dart';
import 'package:dedecashier/objectbox.g.dart'; // For PrintQueueObjectBoxStruct_
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dedecashier/features/pos/presentation/widgets/pos_ui_helpers.dart';
import 'package:dedecashier/flavors.dart';

/// ✅ PosAppBar - AppBar widget สำหรับ POS Screen
///
/// แยกออกจาก pos_screen.dart เพื่อลดความซับซ้อน
/// ประกอบด้วย:
/// - Title section พร้อม sale channel logo
/// - Status indicators (Sync, Printer, EDC, Internet)
/// - Action buttons (Rotate, Grid size, Text height, Mode switch, etc.)
/// - Print queue button
class PosAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int posScreenMode;
  final int deviceMode;
  final bool showDetail;
  final int splitViewMode;
  final double gridItemSize;
  final double listTextHeight;
  final int cashierPrinterIndex;

  // Callbacks
  final VoidCallback onRefreshPressed;
  final VoidCallback onShowDetailToggle;
  final VoidCallback onRotatePressed;
  final VoidCallback onGridSizePressed;
  final VoidCallback onTextHeightPressed;
  final VoidCallback onDeviceModePressed;
  final VoidCallback onRequestKeyboardFocus;
  final Future<void> Function() onTierStockPressed;

  const PosAppBar({
    super.key,
    required this.title,
    required this.posScreenMode,
    required this.deviceMode,
    required this.showDetail,
    required this.splitViewMode,
    required this.gridItemSize,
    required this.listTextHeight,
    required this.cashierPrinterIndex,
    required this.onRefreshPressed,
    required this.onShowDetailToggle,
    required this.onRotatePressed,
    required this.onGridSizePressed,
    required this.onTextHeightPressed,
    required this.onDeviceModePressed,
    required this.onRequestKeyboardFocus,
    required this.onTierStockPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 56,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.5),
      backgroundColor: _getBackgroundColor(),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _getGradientColors()),
        ),
      ),
      title: _buildTitle(context),
      actions: _buildActions(context),
    );
  }

  /// สีพื้นหลัง AppBar
  ///
  /// 🎨 กำหนดสี AppBar ตาม posScreenMode (int):
  /// - posScreenMode == 1 (posSale/หน้าขาย) → สีฟ้า (Blue)
  /// - posScreenMode == 2 (posReturn/หน้ารับคืน) → สีแดง (Red)
  ///
  /// ⚠️ หมายเหตุสำคัญ: posScreenMode เป็น int ไม่ใช่ Enum
  /// ค่าที่ส่งมาจาก global.posScreenToInt(widget.posScreenMode):
  ///   - PosScreenModeEnum.posSale → 1
  ///   - PosScreenModeEnum.posReturn → 2
  Color _getBackgroundColor() {
    // posScreenMode == 1 คือหน้าขาย (posSale) → สีฟ้า/อิฐบ้านเชียง
    if (posScreenMode == 1) {
      return (F.appFlavor != Flavor.MARINEPOS)
          ? const Color(0xFFB5651D) // อิฐบ้านเชียง (terracotta)
          : const Color(0xFF005598); // Marine blue
    } else {
      // posScreenMode == 2 คือหน้ารับคืน (posReturn) → สีแดง
      return Colors.red.shade500;
    }
  }

  /// สี Gradient
  ///
  /// 🎨 กำหนดสี Gradient ตาม posScreenMode (int):
  /// - posScreenMode == 1 (posSale/หน้าขาย) → สีฟ้า/อิฐบ้านเชียง gradient
  /// - posScreenMode == 2 (posReturn/หน้ารับคืน) → สีแดง gradient
  ///
  /// ⚠️ หมายเหตุสำคัญ: posScreenMode เป็น int ไม่ใช่ Enum
  /// ค่าที่ส่งมาจาก global.posScreenToInt(widget.posScreenMode):
  ///   - PosScreenModeEnum.posSale → 1
  ///   - PosScreenModeEnum.posReturn → 2
  List<Color> _getGradientColors() {
    // posScreenMode == 1 คือหน้าขาย (posSale) → สีฟ้า/อิฐบ้านเชียง gradient
    if (posScreenMode == 1) {
      return (F.appFlavor != Flavor.MARINEPOS)
          ? [const Color(0xFFB5651D), const Color(0xFF8B4513)] // อิฐบ้านเชียง gradient
          : [const Color(0xFF005598), const Color(0xFF003366)]; // Marine blue gradient
    } else {
      // posScreenMode == 2 คือหน้ารับคืน (posReturn) → สีแดง gradient
      return [Colors.red.shade500, Colors.red.shade700];
    }
  }

  /// Title section
  Widget _buildTitle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sale Channel Logo
          if (global.posSaleChannelCode != "XXX")
            Container(
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 0, blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PosSaleChannelScreen()));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.network(global.posSaleChannelLogoUrl, height: 24, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          // Title Text
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 6.0, color: Colors.black45, offset: Offset(1.0, 1.0))],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Status Indicators
          _buildStatusIndicators(),
        ],
      ),
    );
  }

  /// Status Indicators (Sync, Printer, EDC, Internet)
  Widget _buildStatusIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildButtonSizeIndicator(),
        const SizedBox(width: 8),
        _buildStatusIcon("internet_connect", true, Icons.wifi, "เชื่อมต่ออินเทอร์เน็ต"),
        const SizedBox(width: 6),
        // ⭐ Sync Status Icon with real-time updates
        ValueListenableBuilder<SyncStatus>(
          valueListenable: SyncBill.syncStatus,
          builder: (context, status, child) {
            return ValueListenableBuilder<int>(
              valueListenable: SyncBill.pendingBillsCount,
              builder: (context, pendingCount, child) {
                IconData icon;
                Color color;
                String tooltip;

                switch (status) {
                  case SyncStatus.idle:
                    icon = Icons.cloud_outlined;
                    color = pendingCount > 0 ? Colors.orange.shade400 : Colors.grey.shade400;
                    tooltip = pendingCount > 0 ? 'รอ Sync $pendingCount บิล' : 'Sync พร้อม';
                    break;
                  case SyncStatus.syncing:
                    icon = Icons.cloud_upload;
                    color = Colors.blue.shade400;
                    tooltip = 'กำลัง Sync...';
                    break;
                  case SyncStatus.success:
                    icon = Icons.cloud_done;
                    color = Colors.green.shade400;
                    tooltip = 'Sync สำเร็จ';
                    break;
                  case SyncStatus.failed:
                    icon = Icons.cloud_off;
                    color = Colors.red.shade400;
                    tooltip = 'Sync ล้มเหลว';
                    break;
                }

                return GestureDetector(
                  onTap: () => _showSyncStatusDialog(context, status, pendingCount),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: tooltip,
                          child: Icon(icon, size: 24, color: color),
                        ),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange.shade400, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(width: 6),
        // ⭐ Printer Status Icon
        if (cashierPrinterIndex != -1)
          StreamBuilder<bool>(
            stream: Stream.periodic(const Duration(seconds: 1), (_) {
              return global.printerLocalStrongData.every((p) => p.isReady);
            }),
            initialData: global.printerLocalStrongData.every((p) => p.isReady),
            builder: (context, snapshot) {
              final allReady = snapshot.data ?? false;
              return _buildStatusIcon("thermal_printer", allReady, Icons.print, "เครื่องพิมพ์");
            },
          ),
        if (global.useEdc) ...[const SizedBox(width: 6), _buildStatusIcon("edc", false, Icons.credit_card, "EDC")],
      ],
    );
  }

  /// Button Size Indicator
  Widget _buildButtonSizeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: const Text(
        'M',
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Status Icon
  Widget _buildStatusIcon(String name, bool isConnected, IconData icon, String tooltipText) {
    return GestureDetector(
      onTap: () {
        // จัดการคลิกไอคอน (เช่น แสดง dialog)
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(6)),
        child: Tooltip(
          message: tooltipText,
          child: Icon(icon, size: 24, color: isConnected ? Colors.green.shade400 : Colors.red.shade400),
        ),
      ),
    );
  }

  /// Sync Status Dialog
  Future<void> _showSyncStatusDialog(BuildContext context, SyncStatus status, int pendingCount) async {
    // แสดง loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Query จาก ObjectBox
      final actualPendingCount = global.billHelper.selectSyncIsFalse().length;

      AppLogger.debug('[PosAppBar] ✅ Found $actualPendingCount pending bills');

      // ปิด loading
      Navigator.pop(context);

      // เปิด dialog ข้อมูล sync
      _buildSyncStatusDialog(context, status, actualPendingCount);
    } catch (e) {
      AppLogger.error('[PosAppBar] ❌ Error querying pending bills: $e');

      // ปิด loading
      Navigator.pop(context);

      // แสดง dialog ด้วยค่า fallback
      _buildSyncStatusDialog(context, status, pendingCount);
    }
  }

  /// Build Sync Status Dialog
  void _buildSyncStatusDialog(BuildContext context, SyncStatus status, int pendingCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('สถานะ Sync'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('สถานะ: ${status.toString().split('.').last}'), const SizedBox(height: 8), Text('บิลรอ Sync: $pendingCount บิล')],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด'))],
      ),
    );
  }

  /// Action Buttons
  List<Widget> _buildActions(BuildContext context) {
    return [
      // ซ่อนปุ่มต่างๆ เมื่อเป็นมือถือ (deviceMode == 2)
      if (deviceMode != 2) ...[
        // Print Queue Button
        _buildPrintQueueButton(context),
        // Rotate Button
        PosUiHelpers.buildAppBarButton(icon: FontAwesomeIcons.rotate, tooltip: 'หมุนมุมมอง', onPressed: onRotatePressed),
        // Grid Size Button
        PosUiHelpers.buildAppBarButton(icon: FontAwesomeIcons.searchengin, tooltip: 'ขนาดกริด', onPressed: onGridSizePressed),
        // Text Height Button
        PosUiHelpers.buildAppBarButton(icon: FontAwesomeIcons.textHeight, tooltip: 'ขนาดตัวอักษร', onPressed: onTextHeightPressed),
        // Device Mode Switch Button
        PosUiHelpers.buildAppBarButton(icon: (deviceMode == 0) ? Icons.tablet : FontAwesomeIcons.desktop, tooltip: 'เปลี่ยนโหมด', onPressed: onDeviceModePressed),
      ],
      // Tier Stock Management Button
      // PosUiHelpers.buildAppBarButton(icon: Icons.inventory_2, tooltip: 'จัดการของแลก', onPressed: () => onTierStockPressed()),
      // Refresh Button
      PosUiHelpers.buildAppBarButton(icon: Icons.refresh, tooltip: 'รีเฟรช', onPressed: onRefreshPressed),
      // Show/Hide Detail Button
      _buildShowDetailButton(),
      const SizedBox(width: 8),
    ];
  }

  /// Print Queue Button
  Widget _buildPrintQueueButton(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 2), (_) {
        try {
          final box = global.objectBoxStore.box<PrintQueueObjectBoxStruct>();
          final query = box.query(PrintQueueObjectBoxStruct_.status.equals(0)).build();
          final count = query.count();
          query.close();
          return count;
        } catch (e) {
          return 0;
        }
      }),
      initialData: 0,
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;
        final hasJobs = pendingCount > 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrintQueueViewerScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Tooltip(
                  message: 'คิวพิมพ์${hasJobs ? " ($pendingCount รอพิมพ์)" : "เสร็จแล้ว"}',
                  child: Icon(Icons.print_outlined, color: hasJobs ? Colors.orange : Colors.white, size: 24),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show/Hide Detail Button
  Widget _buildShowDetailButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onShowDetailToggle,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Tooltip(
              message: showDetail ? 'ซ่อนรายละเอียด' : 'แสดงรายละเอียด',
              child: showDetail ? const Icon(Icons.remove_red_eye, size: 20, color: Colors.orange) : const Icon(Icons.remove_red_eye_outlined, size: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
