import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;

/// ตัวเลือกวิธีจ่ายเงิน — แสดงหลังเลือกโต๊ะ/ป้ายบริการ (mode 0, staff device เท่านั้น)
enum PaymentChoice {
  /// จ่ายทันทีที่หน้าจอ (flow เดิม เปิด PayPage)
  payNow,

  /// พิมพ์ใบแจ้งยอดพร้อม QR แล้วไปจ่ายที่ cashier
  payAtCashier,

  /// ยกเลิก กลับไป cart
  cancel,
}

/// Dialog ให้เลือก "ชำระทันที" หรือ "จ่ายที่ Cashier"
///
/// ใช้ก่อนเข้า payAndSave ใน cart page (mode 0, staff device เท่านั้น)
/// barrierDismissible: false — user ต้องเลือกหรือกดยกเลิกเท่านั้น
class PaymentChoiceDialog extends StatelessWidget {
  final double totalAmount;
  final String orderTagNumber;

  const PaymentChoiceDialog({
    super.key,
    required this.totalAmount,
    required this.orderTagNumber,
  });

  /// แสดง dialog คืน PaymentChoice (default cancel ถ้า dismiss)
  static Future<PaymentChoice> show(
    BuildContext context, {
    required double totalAmount,
    required String orderTagNumber,
  }) async {
    final result = await showDialog<PaymentChoice>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => PaymentChoiceDialog(
        totalAmount: totalAmount,
        orderTagNumber: orderTagNumber,
      ),
    );
    return result ?? PaymentChoice.cancel;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(Icons.payment, size: 48, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              global.findLanguage(
                  code: "select_pay_type",
                  languageCode: global.languageForStaff),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // สรุปยอด + โต๊ะ
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    orderTagNumber.isNotEmpty
                        ? "${global.findLanguage(code: "select_serve_number", languageCode: global.languageForStaff)}: $orderTagNumber"
                        : "",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "${global.moneyFormat.format(totalAmount)} ${global.findLanguage(code: "money_baht", languageCode: global.languageForStaff)}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ปุ่ม จ่ายทันที
            _ChoiceButton(
              icon: Icons.point_of_sale,
              title: global.findLanguage(
                  code: "pay_now", languageCode: global.languageForStaff),
              subtitle: global.findLanguage(
                  code: "pay_now_subtitle",
                  languageCode: global.languageForStaff),
              color: Colors.green,
              onTap: () => Navigator.of(context).pop(PaymentChoice.payNow),
            ),
            const SizedBox(height: 12),
            // ปุ่ม จ่ายที่ Cashier
            _ChoiceButton(
              icon: Icons.receipt_long,
              title: global.findLanguage(
                  code: "pay_at_cashier",
                  languageCode: global.languageForStaff),
              subtitle: global.findLanguage(
                  code: "pay_at_cashier_subtitle",
                  languageCode: global.languageForStaff),
              color: Colors.orange,
              onTap: () =>
                  Navigator.of(context).pop(PaymentChoice.payAtCashier),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(PaymentChoice.cancel),
            child: Text(global.findLanguage(
                code: "cancel", languageCode: global.languageForStaff)),
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
