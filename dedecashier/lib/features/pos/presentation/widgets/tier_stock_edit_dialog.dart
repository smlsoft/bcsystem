// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dedecashier/global.dart' as global;

/// Dialog สำหรับแก้ไขจำนวนคงเหลือของ Tier Redemption Promotion
class TierStockEditDialog extends StatefulWidget {
  const TierStockEditDialog({super.key});

  @override
  State<TierStockEditDialog> createState() => _TierStockEditDialogState();
}

class _TierStockEditDialogState extends State<TierStockEditDialog> {
  final String _promotionCode = 'แลกของกำนัล';

  // Controllers สำหรับแต่ละ Tier
  final Map<int, TextEditingController> _controllers = {};

  // Loading state
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentStock();
  }

  @override
  void dispose() {
    // Dispose controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// โหลดข้อมูลจำนวนคงเหลือปัจจุบัน
  Future<void> _loadCurrentStock() async {
    setState(() => _isLoading = true);

    try {
      for (int tier = 1; tier <= 5; tier++) {
        final stockStruct = global.getTierStock(tier);
        final stock = stockStruct?.remaining_stock ?? 0;
        _controllers[tier] = TextEditingController(text: stock.toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// บันทึกข้อมูลจำนวนคงเหลือ
  Future<void> _saveStock() async {
    setState(() => _isSaving = true);

    try {
      for (int tier = 1; tier <= 5; tier++) {
        final value = int.tryParse(_controllers[tier]?.text ?? '0') ?? 0;
        global.updateTierStock(
          tierLevel: tier,
          promotionCode: _promotionCode,
          remainingStock: value,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // ส่ง true กลับไปเพื่อ refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ บันทึกจำนวนคงเหลือเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.inventory_2, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'จัดการจำนวนของแลก',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 16),

            // Loading or Content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ..._buildTierInputs(),

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveStock,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึก'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// สร้าง Input Fields สำหรับแต่ละ Tier
  List<Widget> _buildTierInputs() {
    final tiers = [
      {
        'level': 5,
        'amount': 7000,
        'name': 'พัดลมตั้งโต๊ะ',
        'color': Colors.purple,
      },
      {
        'level': 4,
        'amount': 5000,
        'name': 'กระทะไฟฟ้า',
        'color': Colors.orange,
      },
      {
        'level': 3,
        'amount': 2000,
        'name': 'กาต้มน้ำไฟฟ้า',
        'color': Colors.green,
      },
      {
        'level': 2,
        'amount': 1000,
        'name': 'ผ้ากันเปื้อน',
        'color': Colors.blue,
      },
      {'level': 1, 'amount': 0, 'name': 'ถุงผ้าน้ำเงิน', 'color': Colors.grey},
    ];

    return tiers.map((tier) {
      final level = tier['level'] as int;
      final amount = tier['amount'] as int;
      final name = tier['name'] as String;
      final color = tier['color'] as Color;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            // Tier Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Tier Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tier $level: $name',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amount == 0
                        ? 'ไม่จำกัดยอด'
                        : 'ซื้อครบ ${_formatAmount(amount)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Stock Input
            SizedBox(
              width: 100,
              child: TextField(
                controller: _controllers[level],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'ยอดคงเหลือ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Format amount with comma separator
  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}฿';
  }
}
