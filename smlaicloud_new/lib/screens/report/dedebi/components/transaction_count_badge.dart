import 'package:flutter/material.dart';

class TransactionCountBadge extends StatelessWidget {
  final int count;
  final double fontSize;

  const TransactionCountBadge({
    super.key,
    required this.count,
    this.fontSize = 9,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const Text('-', style: TextStyle(fontSize: 11));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count รายการ',
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.blue.shade700,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
