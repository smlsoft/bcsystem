import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dedecashier/model/coupon/coupon_model.dart';
import 'package:dedecashier/services/coupon_manager.dart';

class CouponWidget extends StatefulWidget {
  final double orderAmount;
  final Function(double discount, double cashVoucher)? onDiscountCalculated;
  final VoidCallback? onCouponsReserved;
  final VoidCallback? onReservationsCanceled;

  const CouponWidget({
    Key? key,
    required this.orderAmount,
    this.onDiscountCalculated,
    this.onCouponsReserved,
    this.onReservationsCanceled,
  }) : super(key: key);

  @override
  State<CouponWidget> createState() => _CouponWidgetState();
}

class _CouponWidgetState extends State<CouponWidget> {
  final TextEditingController _couponController = TextEditingController();
  final FocusNode _couponFocus = FocusNode();
  late CouponManager _couponManager;

  @override
  void initState() {
    super.initState();
    _couponManager = CouponManager();
  }

  @override
  void dispose() {
    _couponController.dispose();
    _couponFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _couponManager,
      child: Consumer<CouponManager>(
        builder: (context, couponManager, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.local_offer, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'คูปองส่วนลด',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (couponManager.hasCoupons)
                      Chip(
                        label: Text('${couponManager.couponCount} คูปอง'),
                        backgroundColor: Colors.orange.shade100,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Add Coupon Section
                _buildAddCouponSection(couponManager),

                const SizedBox(height: 16),

                // Applied Coupons List
                if (couponManager.hasCoupons) ...[
                  _buildAppliedCouponsList(couponManager),
                  const SizedBox(height: 16),
                ],

                // Summary Section
                if (couponManager.lastCalculation != null) _buildSummarySection(couponManager),

                // Action Buttons
                if (couponManager.hasCoupons) ...[
                  const SizedBox(height: 16),
                  _buildActionButtons(couponManager),
                ],

                // Error Message
                if (couponManager.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            couponManager.errorMessage!,
                            style: TextStyle(color: Colors.red.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddCouponSection(CouponManager couponManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                focusNode: _couponFocus,
                decoration: InputDecoration(
                  hintText: 'ป้อนรหัสคูปอง',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                ],
                onSubmitted: (value) => _addCoupon(couponManager),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: couponManager.isLoading || !couponManager.canAddMoreCoupons() ? null : () => _addCoupon(couponManager),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: couponManager.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('เพิ่ม'),
            ),
          ],
        ),
        if (!couponManager.canAddMoreCoupons())
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'สามารถใช้ได้สูงสุด 5 คูปอง',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppliedCouponsList(CouponManager couponManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'คูปองที่ใช้',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...couponManager.appliedCoupons.map((appliedCoupon) => _buildCouponCard(appliedCoupon, couponManager)),
      ],
    );
  }

  Widget _buildCouponCard(AppliedCouponModel appliedCoupon, CouponManager couponManager) {
    final coupon = appliedCoupon.coupon;
    final result = appliedCoupon.calculationResult;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Coupon Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.couponcode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        coupon.displayName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getCouponTypeColor(coupon.coupontype),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              coupon.couponTypeName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            coupon.discountText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status and Remove Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appliedCoupon),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        appliedCoupon.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Remove Button
                    IconButton(
                      onPressed: () => couponManager.removeCoupon(coupon.couponcode),
                      icon: const Icon(Icons.close, color: Colors.red),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ],
            ),

            // Calculation Result
            if (result != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: result.applied ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      result.applied ? 'ใช้ได้' : 'ใช้ไม่ได้',
                      style: TextStyle(
                        color: result.applied ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (result.applied)
                      Text(
                        result.discount_amount > 0 ? 'ลด ฿${result.discount_amount.toStringAsFixed(0)}' : 'เงินสด ฿${result.cash_voucher_amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(CouponManager couponManager) {
    final calculation = couponManager.lastCalculation!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สรุปส่วนลด',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('ยอดสินค้า', widget.orderAmount),
          if (calculation.total_discount > 0) _buildSummaryRow('ส่วนลด', -calculation.total_discount, color: Colors.red),
          if (calculation.total_cash_voucher > 0) _buildSummaryRow('คูปองเงินสด', -calculation.total_cash_voucher, color: Colors.blue),
          const Divider(),
          _buildSummaryRow(
            'ยอดชำระ',
            calculation.final_amount,
            color: Colors.green.shade700,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {Color? color, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            '฿${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CouponManager couponManager) {
    final hasReservedCoupons = couponManager.appliedCoupons.any((c) => c.isReserved);

    return Row(
      children: [
        // Calculate Button
        Expanded(
          child: ElevatedButton(
            onPressed: couponManager.isLoading ? null : () => _calculateDiscount(couponManager),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('คำนวนส่วนลด'),
          ),
        ),

        const SizedBox(width: 12),

        // Reserve/Cancel Button
        Expanded(
          child: ElevatedButton(
            onPressed: couponManager.isLoading
                ? null
                : hasReservedCoupons
                    ? () => _cancelReservations(couponManager)
                    : () => _reserveCoupons(couponManager),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasReservedCoupons ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(hasReservedCoupons ? 'ยกเลิกการจอง' : 'ยืนยันใช้คูปอง'),
          ),
        ),
      ],
    );
  }

  // Helper Methods
  Color _getCouponTypeColor(int type) {
    switch (type) {
      case 0:
        return Colors.blue; // ลดตามมูลค่า
      case 1:
        return Colors.orange; // ลดตามเปอร์เซ็นต์
      case 2:
        return Colors.purple; // คูปองแทนเงินสด
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(AppliedCouponModel appliedCoupon) {
    if (appliedCoupon.isExpired) return Colors.red;
    if (appliedCoupon.isReserved) return Colors.green;
    return Colors.orange;
  }

  // Action Methods
  void _addCoupon(CouponManager couponManager) async {
    final code = _couponController.text.trim().toUpperCase();
    final validation = couponManager.validateCouponCode(code);
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await couponManager.addCoupon(code);
    if (success) {
      _couponController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เพิ่มคูปองสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _calculateDiscount(CouponManager couponManager) async {
    final success = await couponManager.calculateDiscount(widget.orderAmount);
    if (success && couponManager.lastCalculation != null) {
      final calc = couponManager.lastCalculation!;
      widget.onDiscountCalculated?.call(calc.total_discount, calc.total_cash_voucher);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('คำนวนส่วนลดเรียบร้อย'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _reserveCoupons(CouponManager couponManager) async {
    final transactionId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
    final success = await couponManager.reserveAllCoupons(transactionId);
    if (success) {
      widget.onCouponsReserved?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('จองคูปองเรียบร้อย (15 นาที)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _cancelReservations(CouponManager couponManager) async {
    final success = await couponManager.cancelAllReservations();
    if (success) {
      widget.onReservationsCanceled?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยกเลิกการจองเรียบร้อย'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
