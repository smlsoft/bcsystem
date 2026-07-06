import 'package:dedecashier/bloc/bloc.dart';
import 'package:dedecashier/model/coupon/coupon_model.dart';
import 'package:dedecashier/services/coupon_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/system/pos_pay_model.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/util/pos_compile_process.dart';
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class PayCoupon extends StatefulWidget {
  final PosHoldProcessModel posProcess;
  final BuildContext blocContext;
  const PayCoupon({
    super.key,
    required this.posProcess,
    required this.blocContext,
  });

  @override
  State<PayCoupon> createState() => _PayCouponState();
}

class _PayCouponState extends State<PayCoupon> {
  final couponCodeController = TextEditingController();

  // Initialize CouponManager
  late CouponManager couponManager;

  @override
  void initState() {
    super.initState();
    couponManager = CouponManager();

    // Listen to coupon manager state changes
    couponManager.addListener(_onCouponStateChanged);
  }

  @override
  void dispose() {
    // Don't cancel reservations here - let them persist until after bill save
    // couponManager.cancelAllReservations();
    couponManager.removeListener(_onCouponStateChanged);
    if (kDebugMode) {
      AppLogger.debug('💡 PayCoupon disposed - preserving coupon data for bill save');
      AppLogger.debug('- Current coupons: ${couponManager.appliedCoupons.length}');
      AppLogger.debug(
        '   - Reserved coupons: ${couponManager.appliedCoupons.where((c) => c.isReserved).length}',
      );
    }
    super.dispose();
  }

  void _onCouponStateChanged() async {
    if (mounted) {
      // Update payment amount based on calculation
      if (couponManager.lastCalculation != null) {
        _updatePaymentAmount();
      }
      await posCompileProcess(
        holdCode: global.posHoldActiveCode,
        docMode: 1,
        detailDiscountFormula: "",
        cashRoundAmount: false,
        discountFoodOnly: false,
        customermode: global.secondScreenCommandPay,
      );
    }
  }

  void refreshEvent() {
    widget.blocContext.read<PayScreenBloc>().add(PayScreenRefresh());
  }

  void _updatePaymentAmount() {
    final result = couponManager.lastCalculation;
    if (result != null && result.success) {
      // Create coupon payment entries based on calculation
      final totalCouponAmount =
          result.total_discount + result.total_cash_voucher;
      if (totalCouponAmount > 0) {
        // Clear existing coupon entries
        widget.posProcess.payScreenData.coupon
            .clear(); // Add coupon entries for each applied coupon
        for (final couponResult in result.coupon_results) {
          if (couponResult.applied) {
            final totalAmount =
                couponResult.totalAmount; // ใช้ computed property ใหม่
            if (totalAmount > 0) {
              widget.posProcess.payScreenData.coupon.add(
                PayCouponModel(
                  number: couponResult.coupon_code,
                  description:
                      "${_getCouponTypeDisplayName(couponResult.coupon_type)}: ${global.moneyFormat.format(totalAmount)}",
                  discount_amount: couponResult.discount_amount,
                  cash_voucher_amount: couponResult.cash_voucher_amount,
                  coupon_type: couponResult.coupon_type,
                ),
              );
            }
          }
        }
      }
    }
    refreshEvent();
  }

  Future<void> _searchCoupon() async {
    final couponCode = couponCodeController.text.trim();
    if (couponCode.isEmpty) {
      _showMessage("กรุณาใส่รหัสคูปอง");
      return;
    }

    if (global.posConfig.branch.couponusetype == 1 &&
        couponManager.appliedCoupons.isNotEmpty) {
      _showMessage("สาขานี้อนุญาตให้ใช้คูปองได้ 1 ใบต่อบิลเท่านั้น");
      return;
    }

    // Get total amount for auto calculation
    final totalAmount =
        widget.posProcess.posProcess.detail_total_amount_before_discount;

    // Get items from pos details for eligibility check
    List<CouponAvailabilityItem> items = [];
    if (widget.posProcess.posProcess.details.isNotEmpty) {
      for (var detail in widget.posProcess.posProcess.details) {
        items.add(
          CouponAvailabilityItem(
            barcode: detail.barcode,
            qty: detail.qty,
            price: detail.price,
            sumamount: detail.qty * detail.price,
          ),
        );
      }
    }

    final success = await couponManager.addCoupon(
      couponCode,
      orderAmount: totalAmount,
      items: items,
      branchCode: global.posConfig.branch.code,
    );
    if (success) {
      couponCodeController.clear();
      _showMessage("เพิ่มคูปองและคำนวณส่วนลดสำเร็จ");

      // Debug information
      if (kDebugMode) {
        AppLogger.success('🎫 Coupon added successfully:');
        AppLogger.debug('- Total coupons now: ${couponManager.appliedCoupons.length}');
        AppLogger.debug('- CouponManager instance: ${couponManager.hashCode}');
        AppLogger.debug(
          '   - Has reservations: ${couponManager.appliedCoupons.any((c) => c.isReserved)}',
        );
      }

      // ไม่ต้องเรียก _calculateDiscount() เพิ่ม เพราะทำอัตโนมัติแล้วใน addCoupon
    } else {
      _showMessage(couponManager.errorMessage ?? "ไม่สามารถเพิ่มคูปองได้");
    }
  }

  Future<void> _calculateDiscount() async {
    if (couponManager.appliedCoupons.isEmpty) {
      _showMessage("กรุณาเพิ่มคูปองก่อน");
      return;
    }
    List<CouponAvailabilityItem> items = [];
    if (widget.posProcess.posProcess.details.isNotEmpty) {
      for (var detail in widget.posProcess.posProcess.details) {
        items.add(
          CouponAvailabilityItem(
            barcode: detail.barcode,
            qty: detail.qty,
            price: detail.price,
            sumamount: detail.qty * detail.price,
          ),
        );
      }
    }

    // Get total amount from posProcess
    final totalAmount =
        widget.posProcess.posProcess.detail_total_amount_before_discount;
    final success = await couponManager.recalculateDiscount(
      totalAmount,
      branchCode: global.posConfig.branch.code,
      items: items,
    );
    if (success) {
      _showMessage("คำนวณส่วนลดสำเร็จ");
      setState(() {});
    } else {
      _showMessage(couponManager.errorMessage ?? "เกิดข้อผิดพลาดในการคำนวณ");
    }
  }

  bool _hasActiveReservations() {
    return couponManager.appliedCoupons.any(
      (c) => c.isReserved && !c.isExpired,
    );
  }

  void _removeCoupon(String couponCode) async {
    // ใช้ method removeCoupon ที่มีอยู่แล้ว (แต่การยกเลิกจองทำไปแล้วข้างบน)
    await couponManager.removeCoupon(couponCode, skipCancelReservation: true);
    _showMessage("ลบคูปอง $couponCode แล้ว");

    // คำนวณส่วนลดใหม่หลังลบคูปอง (ถ้ายังมีคูปองเหลืออยู่)
    if (couponManager.appliedCoupons.isNotEmpty) {
      await _calculateDiscount();
    } else {
      // ถ้าไม่มีคูปองเหลือ ให้เคลียร์ข้อมูลการคำนวณ
      widget.posProcess.payScreenData.coupon.clear();
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    }
  }

  String _getCouponTypeDisplayName(int coupontype) {
    switch (coupontype) {
      case 0:
        return global.language('value_discount');
      case 1:
        return global.language('percent_discount');
      case 2:
        return global.language('cash_coupon');
      default:
        return global.language('value_discount');
    }
  }

  IconData _getCouponTypeIcon(int coupontype) {
    switch (coupontype) {
      case 0:
        return Icons.local_offer;
      case 1:
        return Icons.percent;
      case 2:
        return Icons.attach_money;
      default:
        return Icons.local_offer;
    }
  }

  Color _getCouponTypeColor(int coupontype) {
    switch (coupontype) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: couponCodeController,
                            decoration: InputDecoration(
                              labelText: global.language("coupon_code"),
                              hintText: global.language("enter_coupon_code"),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.qr_code),
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchCoupon(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: couponManager.isLoading
                              ? null
                              : () {
                                  global.playSound(
                                    sound: global.SoundEnum.buttonTing,
                                  );
                                  _searchCoupon();
                                },
                          icon: couponManager.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: Text(global.language("search")),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),

            // Selected Coupons List
            if (couponManager.appliedCoupons.isNotEmpty) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${global.language('selected_coupons')} (${couponManager.appliedCoupons.length})",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (couponManager.appliedCoupons.isNotEmpty)
                            TextButton.icon(
                              onPressed: () async {
                                global.playSound(
                                  sound: global.SoundEnum.buttonTing,
                                );
                                // ยกเลิกการจองทั้งหมดก่อนเคลียร์
                                if (_hasActiveReservations()) {
                                  await couponManager.cancelAllReservations();
                                }
                                setState(() {
                                  couponManager.clearAllCoupons();
                                  // เคลียร์ข้อมูลการคำนวณเมื่อลบคูปองทั้งหมด
                                  widget.posProcess.payScreenData.coupon
                                      .clear();
                                });
                                _showMessage("ลบคูปองทั้งหมดแล้ว");
                              },
                              icon: const Icon(Icons.clear_all),
                              label: Text(global.language("clear_all")),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: couponManager.appliedCoupons.length,
                        itemBuilder: (context, index) {
                          final appliedCoupon =
                              couponManager.appliedCoupons[index];
                          final coupon = appliedCoupon.coupon;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getCouponTypeColor(
                                  coupon.coupontype,
                                ),
                                child: Icon(
                                  _getCouponTypeIcon(coupon.coupontype),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                coupon.couponcode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getCouponTypeDisplayName(
                                      coupon.coupontype,
                                    ),
                                  ),
                                  Text(
                                    "${global.language('value')}: ${global.moneyFormat.format(coupon.couponvalue)} ${coupon.coupontype == 1 ? "%" : ""} ${(coupon.maxusagecountpercustomer > 0) ? "${global.language("remaining_usage")}: ${appliedCoupon.remaining_usage}" : ""}",
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                onPressed: () async {
                                  global.playSound(
                                    sound: global.SoundEnum.itemRemoved,
                                  );
                                  // ยกเลิกการจองของคูปองนี้ก่อนลบ (ถ้ามีการจอง)
                                  if (appliedCoupon.isReserved) {
                                    final reservationId =
                                        appliedCoupon.reservationId;
                                    if (reservationId != null) {
                                      await couponManager.cancelReservation(
                                        reservationId,
                                      );
                                    }
                                  }
                                  _removeCoupon(coupon.couponcode);
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: global.language("remove_coupon"),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Calculation Result
            if (couponManager.lastCalculation != null &&
                couponManager.lastCalculation!.success) ...[
              Card(
                elevation: 4,
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            global.language("calculation_result"),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildCalculationSummary(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ], // Cancel Reservation Button
            // // Error Message
            // if (couponManager.errorMessage != null) ...[
            //   Card(
            //     elevation: 4,
            //     color: ไ,
            //     child: Padding(
            //       padding: const EdgeInsets.all(16),
            //       child: Row(
            //         children: [
            //           const Icon(
            //             Icons.error,
            //             color: Colors.red,
            //           ),
            //           const SizedBox(width: 8),
            //           Expanded(
            //             child: Text(
            //               couponManager.errorMessage!,
            //               style: const TextStyle(
            //                 color: Colors.red,
            //                 fontWeight: FontWeight.w500,
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ],

            // Loading Status
            if (couponManager.isLoading) ...[
              Card(
                elevation: 4,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          global.language("calculating_discount") !=
                                  "calculating_discount"
                              ? global.language("calculating_discount")
                              : "กำลังคำนวณส่วนลด...",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationSummary() {
    final result = couponManager.lastCalculation!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order Amount
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              global.language("order_amount"),
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              global.moneyFormat.format(
                widget
                    .posProcess
                    .posProcess
                    .detail_total_amount_before_discount,
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 5), // Individual Coupon Results
        ...result.coupon_results.map((couponResult) {
          if (couponResult.applied) {
            final totalAmount =
                couponResult.discount_amount + couponResult.cash_voucher_amount;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${couponResult.coupon_code} (${_getCouponTypeDisplayName(couponResult.coupon_type)})",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    "-${global.moneyFormat.format(totalAmount)}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // แสดง error สำหรับคูปองที่ใช้ไม่ได้
            String errorMessage = couponResult.error_message;
            if (errorMessage.isEmpty) {
              // หาสาเหตุจาก appliedCoupon
              final appliedCoupon = couponManager.appliedCoupons
                  .where(
                    (ac) => ac.coupon.couponcode == couponResult.coupon_code,
                  )
                  .firstOrNull;
              if (appliedCoupon != null && appliedCoupon.isExpired) {
                errorMessage = "คูปองถูกใช้หมดแล้ว";
              } else {
                errorMessage =
                    appliedCoupon!.calculationResult?.message ??
                    "ไม่สามารถใช้คูปองนี้ได้";
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${couponResult.coupon_code} (${_getCouponTypeDisplayName(couponResult.coupon_type)})",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }
        }),

        const Divider(height: 16),

        // Total Discount
        if (result.total_discount > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                global.language("total_discount"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "-${global.moneyFormat.format(result.total_discount)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Total Cash Voucher
        if (result.total_cash_voucher > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                global.language("cash_voucher"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "-${global.moneyFormat.format(result.total_cash_voucher)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // const Divider(height: 16),

        // Final Amount
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     Text(
        //       global.language("final_amount"),
        //       style: TextStyle(
        //         fontSize: 18,
        //         fontWeight: FontWeight.bold,
        //         color: Theme.of(context).primaryColor,
        //       ),
        //     ),
        //     Text(
        //       global.moneyFormat.format(result.final_amount),
        //       style: TextStyle(
        //         fontSize: 18,
        //         fontWeight: FontWeight.bold,
        //         color: Theme.of(context).primaryColor,
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }
}

// เพิ่ม function สำหรับใช้คูปองหลัง saveBill
Future<bool> useCouponsAfterSaveBill(
  String transactionId,
  String posHoldActiveCode,
) async {
  try {
    final couponManager = CouponManager();

    // ใช้คูปองทั้งหมดที่จองไว้
    final success = await couponManager.useAllCoupons(transactionId);

    if (success) {
      AppLogger.debug('ใช้คูปองสำเร็จหลัง saveBill: $transactionId');
    } else {
      AppLogger.debug(
        'เกิดข้อผิดพลาดในการใช้คูปองหลัง saveBill: $transactionId',
      );
    }

    return success;
  } catch (e) {
    AppLogger.error('เกิดข้อผิดพลาดในการใช้คูปองหลัง saveBill: $e');
    return false;
  }
}
