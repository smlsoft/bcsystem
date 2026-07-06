import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;

/// Flag บอกว่า user กด skip printing หรือไม่
bool skipPrintingRequested = false;

/// Dialog แสดงผลชำระเงินสำเร็จและกำลังพิมพ์ใบเสร็จ
class PaymentSuccessDialog extends StatefulWidget {
  final bool isOfflineMode;

  const PaymentSuccessDialog({
    super.key,
    this.isOfflineMode = false,
  });

  /// แสดง Dialog แบบ static method
  /// Returns true ถ้า user กด skip, false ถ้าพิมพ์สำเร็จหรือ dialog ถูก pop ปกติ
  static Future<bool> show(BuildContext context, {bool isOfflineMode = false}) async {
    // Reset skip flag
    skipPrintingRequested = false;

    final result = await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => PaymentSuccessDialog(
        isOfflineMode: isOfflineMode,
      ),
    );
    return result ?? false;
  }

  @override
  State<PaymentSuccessDialog> createState() => _PaymentSuccessDialogState();
}

class _PaymentSuccessDialogState extends State<PaymentSuccessDialog> {
  bool _showSkipButton = false;
  bool _printerError = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // ตั้ง timer 15 วินาที ถ้ายังพิมพ์ไม่เสร็จให้แสดงปุ่ม skip
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _showSkipButton = true;
          _printerError = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _skipAndClose() {
    // ตั้ง flag บอกว่า user กด skip
    skipPrintingRequested = true;
    // Pop with true to indicate skip was pressed
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    // Responsive sizing
    final dialogWidth = isMobile ? screenWidth * 0.85 : (isTablet ? 400.0 : 450.0);
    final imageSize = isMobile ? 120.0 : (isTablet ? 150.0 : 180.0);
    final titleFontSize = isMobile ? 18.0 : (isTablet ? 22.0 : 26.0);
    final subtitleFontSize = isMobile ? 13.0 : (isTablet ? 15.0 : 16.0);
    final padding = isMobile ? 24.0 : 32.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Offline Badge
            if (widget.isOfflineMode) ...[
              _buildOfflineBadge(),
              SizedBox(height: padding * 0.5),
            ],
            // Printer Error Badge
            if (_printerError) ...[
              _buildPrinterErrorBadge(),
              SizedBox(height: padding * 0.5),
            ],
            // Success Icon
            _buildSuccessIcon(isMobile),
            SizedBox(height: padding * 0.5),
            // Title
            _buildTitle(titleFontSize),
            SizedBox(height: padding * 0.25),
            // Subtitle
            _buildSubtitle(subtitleFontSize),
            SizedBox(height: padding * 0.75),
            // Printer Animation or Error
            if (_printerError) _buildPrinterError(imageSize) else _buildPrinterAnimation(imageSize),
            SizedBox(height: padding * 0.5),
            // Loading indicator or Skip button
            if (_showSkipButton) _buildSkipButton(isMobile) else _buildLoadingIndicator(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterErrorBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.print_disabled, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 6),
          Text(
            global.language("printer_connection_failed"),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterError(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.print_disabled,
            size: size * 0.4,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            global.language("printer_connection_failed"),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _skipAndClose,
        icon: const Icon(Icons.skip_next),
        label: Text(
          global.language("skip"),
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Text(
            'Offline Mode',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon(bool isMobile) {
    return Container(
      width: isMobile ? 56 : 64,
      height: isMobile ? 56 : 64,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_circle,
        color: Colors.green.shade600,
        size: isMobile ? 32 : 40,
      ),
    );
  }

  Widget _buildTitle(double fontSize) {
    return Text(
      global.language("payment_success"),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(double fontSize) {
    return Text(
      global.language("successfully_received_payment_printing_receipt"),
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPrinterAnimation(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Image.asset(
        "assets/images/thermal-print-animated.gif",
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: isMobile ? 16 : 20,
          height: isMobile ? 16 : 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey.shade400,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Text(
          global.language("printing"),
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Dialog แสดงผลกำลังบันทึก (Pay Later Mode)
class PayLaterSavingDialog extends StatelessWidget {
  const PayLaterSavingDialog({super.key});

  /// แสดง Dialog แบบ static method
  static void show(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => const PayLaterSavingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Image.asset(
            "assets/images/thermal-print-animated.gif",
          );
        },
      ),
    );
  }
}
