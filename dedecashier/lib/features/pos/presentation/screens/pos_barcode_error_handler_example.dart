// ตัวอย่างการใช้งาน Barcode Error Handler
// สำหรับแสดง SnackBar เมื่อไม่พบ barcode

import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';

/// ฟังก์ชันตัวอย่างสำหรับตรวจสอบและแสดง SnackBar หลังจาก posCompileProcess
///
/// วิธีใช้งาน:
/// ```dart
/// // หลังจากเรียก posCompileProcess
/// final result = await posCompileProcess(
///   holdCode: holdCode,
///   docMode: docMode,
///   detailDiscountFormula: formula,
///   cashRoundAmount: true,
///   discountFoodOnly: false,
///   customermode: 'normal',
/// );
///
/// // ตรวจสอบและแสดง error
/// if (mounted) {
///   showBarcodeErrorIfNeeded(context, result);
/// }
/// ```
void showBarcodeErrorIfNeeded(
  BuildContext context,
  PosProcessResultModel result,
) {
  if (result.barcodeNotFound && result.barcodeNotFoundText.isNotEmpty) {
    // แสดง SnackBar แจ้งเตือน
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  global.language('barcode_not_found') ?? 'ไม่พบรหัสสินค้า',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'รหัส: ${result.barcodeNotFoundText}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: SnackBarAction(
        label: 'ตกลง',
        textColor: Colors.white,
        onPressed: () {
          // ปิด SnackBar
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// Widget wrapper สำหรับแสดง SnackBar แบบ custom มากขึ้น
class BarcodeErrorSnackBar extends StatelessWidget {
  final String barcode;
  final VoidCallback? onRetry;

  const BarcodeErrorSnackBar({super.key, required this.barcode, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade900],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  global.language('barcode_not_found') ?? 'ไม่พบรหัสสินค้า',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'รหัส: $barcode',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'กรุณาตรวจสอบรหัสสินค้าหรือติดต่อผู้ดูแลระบบ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: onRetry,
              tooltip: 'สแกนใหม่',
            ),
          ],
        ],
      ),
    );
  }

  /// วิธีใช้งาน custom SnackBar
  static void show(
    BuildContext context,
    String barcode, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: BarcodeErrorSnackBar(barcode: barcode, onRetry: onRetry),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
