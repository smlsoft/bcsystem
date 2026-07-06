import 'package:flutter/foundation.dart';
import 'package:dedecashier/model/coupon/coupon_model.dart';
import 'package:dedecashier/services/coupon_api_service.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/core/logger/app_logger.dart';

class CouponManager extends ChangeNotifier {
  static final CouponManager _instance = CouponManager._internal();
  factory CouponManager() => _instance;
  CouponManager._internal();

  final CouponApiService _apiService = CouponApiService();

  // State variables
  List<AppliedCouponModel> _appliedCoupons = [];
  CouponCalculationResponse? _lastCalculation;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<AppliedCouponModel> get appliedCoupons =>
      List.unmodifiable(_appliedCoupons);
  CouponCalculationResponse? get lastCalculation => _lastCalculation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCoupons => _appliedCoupons.isNotEmpty;

  // Summary getters
  double get totalDiscount => _lastCalculation?.total_discount ?? 0.0;
  double get totalCashVoucher => _lastCalculation?.total_cash_voucher ?? 0.0;
  double get finalAmount => _lastCalculation?.final_amount ?? 0.0;
  int get couponCount => _appliedCoupons.length;

  /// ค้นหาและเพิ่มคูปอง
  ///
  /// การใช้งานใหม่ที่รองรับ items:
  /// ```dart
  /// final items = CouponApiService.createAvailabilityItemsFromPos(posItems);
  /// final success = await couponManager.addCoupon(
  ///   "COUPON_CODE",
  ///   orderAmount: 2500.0,
  ///   items: items,
  ///   branchCode: "00000",
  /// );
  /// ```
  Future<bool> addCoupon(
    String couponCode, {
    double? useAmount,
    double? orderAmount,
    List<CouponAvailabilityItem>? items,
    String? branchCode,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // ตรวจสอบว่าคูปองนี้ใช้แล้วหรือยัง
      if (_appliedCoupons.any(
        (applied) => applied.coupon.couponcode == couponCode,
      )) {
        _setError('คูปองนี้ถูกใช้แล้ว');
        return false;
      }

      // ค้นหาคูปอง
      final coupon = await _apiService.searchCoupon(couponCode);
      if (coupon == null) {
        _setError('ไม่พบคูปอง $couponCode');
        return false;
      } // ตรวจสอบความพร้อมใช้งาน
      final customerId = global.couponCustomerId;
      final availability = await _apiService.checkCouponAvailability(
        coupon.couponcode,
        customerId,
        items: items,
        branchCode: branchCode,
      );
      if (kDebugMode) {
        AppLogger.debug('Coupon availability check: $availability');
        AppLogger.debug('Available: ${availability?.available}');
        AppLogger.debug('Usage count: ${availability?.usage_count}');
        AppLogger.debug('Max usage count: ${availability?.max_usage_count}');
        AppLogger.debug('Remaining usage: ${availability?.remaining_usage}');
        AppLogger.debug('Remaining value: ${availability?.remaining_value}');
        AppLogger.debug('Status: ${availability?.status}');
        AppLogger.debug('Is expired: ${availability?.is_expired}');
        AppLogger.debug('Message: ${availability?.message}');
      }
      if (availability == null || !availability.available) {
        String errorMessage = availability?.message ?? 'คูปองไม่พร้อมใช้งาน';

        // // เพิ่มข้อความเฉพาะสำหรับกรณีต่างๆ
        // if (availability != null) {
        //   if (availability.is_expired) {
        //     errorMessage = 'คูปองหมดอายุแล้ว';
        //   } else if (availability.remaining_usage <= 0) {
        //     errorMessage = 'คูปองถูกใช้หมดแล้ว (ใช้ไปแล้ว ${availability.usage_count}/${availability.max_usage_count} ครั้ง)';
        //   } else if (availability.remaining_value == 0) {
        //     errorMessage = 'คูปองไม่มีมูลค่าคงเหลือ';
        //   } else if (!availability.available) {
        //     errorMessage = availability.message ?? 'คูปองไม่พร้อมใช้งาน';
        //   }
        // }

        _setError(errorMessage);
        return false;
      }

      double finalUseAmount = useAmount ?? coupon.couponvalue;
      if (coupon.coupontype == 2 || coupon.coupontype == 0) {
        // คูปองแทนเงินสด
        finalUseAmount = useAmount ?? coupon.couponvalue;
      }

      // จองคูปองทันที
      final transactionId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

      if (kDebugMode) {
        AppLogger.debug('Reserving coupon with transaction ID: $transactionId');
        AppLogger.debug('Coupon type: ${coupon.coupontype}');
        AppLogger.debug('Final use amount: $finalUseAmount');
      }

      final reservation = await _apiService.reserveCoupon(
        couponCode: coupon.couponcode,
        customerId: customerId,
        transactionId: transactionId,
      );

      if (kDebugMode) {
        AppLogger.debug('Reservation response: $reservation');
        AppLogger.debug('Reservation reserved: ${reservation?.reserved}');
        AppLogger.debug('Reservation transaction_id: ${reservation?.transaction_id}');
      }

      if (reservation == null || !reservation.reserved) {
        _setError('ไม่สามารถจองคูปองได้');
        return false;
      } // เพิ่มคูปองลงรายการพร้อมการจอง
      final appliedCoupon = AppliedCouponModel(
        coupon: coupon,
        useAmount: finalUseAmount,
        reservation: reservation,
        addedAt: DateTime.now(),
        message: reservation.message,
        customerId: customerId,
        remaining_usage: availability.remaining_usage,
      );

      // ตรวจสอบว่ามีการจองคูปองอยู่แล้วหรือไม่
      final existingIndex = _appliedCoupons.indexWhere(
        (applied) => applied.coupon.couponcode == couponCode,
      );
      if (existingIndex >= 0) {
        // ถ้ามีคูปองนี้อยู่แล้ว ให้แทนที่ด้วยคูปองใหม่
        _appliedCoupons[existingIndex] = appliedCoupon;
      } else {
        // ถ้ายังไม่มี ให้เพิ่มคูปองใหม่เข้าไป
        _appliedCoupons.add(appliedCoupon);
      }

      // คำนวนส่วนลดทันทีถ้ามี orderAmount
      if (orderAmount != null && orderAmount > 0) {
        await _calculateSingleCouponDiscount(
          orderAmount,
          customerId,
          branchCode: branchCode,
          items: items,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('เกิดข้อผิดพลาด: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ลบคูปองออกจากรายการและยกเลิกการจอง
  Future<void> removeCoupon(
    String couponCode, {
    bool skipCancelReservation = false,
  }) async {
    final index = _appliedCoupons.indexWhere(
      (applied) => applied.coupon.couponcode == couponCode,
    );
    if (index < 0) return;

    final appliedCoupon =
        _appliedCoupons[index]; // ยกเลิกการจองถ้ามีการจองและไม่ได้ขอให้ข้าม
    if (!skipCancelReservation &&
        appliedCoupon.reservation != null &&
        appliedCoupon.isReserved) {
      try {
        final customerId = global.couponCustomerId;
        // ใช้ helper method ที่ปลอดภัย
        final transactionId = appliedCoupon.transactionId;
        final reservationId = appliedCoupon.reservationId;
        if (transactionId != null && transactionId.isNotEmpty) {
          await _apiService.cancelCouponReservation(
            couponId: appliedCoupon.coupon.guidfixed,
            customerId: customerId,
            transactionId: transactionId,
            reservationId: reservationId,
          );
        }
      } catch (e) {
        AppLogger.error('ไม่สามารถยกเลิกการจองคูปอง $couponCode: $e');
      }
    }

    // ลบคูปองออกจากรายการ
    _appliedCoupons.removeAt(index);
    _lastCalculation = null;
    notifyListeners();
  }

  /// คำนวนส่วนลดทั้งหมด
  Future<bool> calculateDiscount(
    double orderAmount, {
    String? branchCode,
    List<CouponAvailabilityItem>? items,
  }) async {
    if (_appliedCoupons.isEmpty) {
      _setError('ไม่มีคูปองที่จะคำนวน');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      final customerId = global.couponCustomerId;

      final calculation = await _apiService.calculateDiscount(
        appliedCoupons: _appliedCoupons,
        orderAmount: orderAmount,
        customerId: customerId,
        branchCode: branchCode,
        items: items,
      );

      if (calculation == null) {
        _setError('ไม่สามารถคำนวนส่วนลดได้');
        return false;
      }
      if (!calculation.success) {
        _setError(
          calculation.errors.isNotEmpty
              ? calculation.errors.first.error
              : 'คำนวนไม่สำเร็จ',
        );
        return false;
      } // อัพเดทผลการคำนวนกลับไปยัง applied coupons
      for (int i = 0; i < _appliedCoupons.length; i++) {
        final result = calculation.coupon_results.firstWhere(
          (r) => r.coupon_code == _appliedCoupons[i].coupon.couponcode,
          orElse: () => CouponCalculationResult(
            coupon_code: _appliedCoupons[i].coupon.couponcode,
            coupon_type: _appliedCoupons[i].coupon.coupontype,
            coupon_type_name: _appliedCoupons[i].coupon.couponTypeName,
            discount_amount: 0,
            cash_voucher_amount: 0,
            applied: false,
            description: '',
            error_message: 'ไม่สามารถใช้ได้',
          ),
        );
        _appliedCoupons[i] = AppliedCouponModel(
          coupon: _appliedCoupons[i].coupon,
          useAmount: _appliedCoupons[i].useAmount,
          reservation: _appliedCoupons[i].reservation,
          calculationResult: result,
          addedAt: _appliedCoupons[i].addedAt,
          message: _appliedCoupons[i].message,
          customerId: _appliedCoupons[i].customerId,
          remaining_usage: _appliedCoupons[i].remaining_usage,
        );
      }
      _lastCalculation = calculation;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการคำนวน: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// คำนวนส่วนลดสำหรับคูปองเดียว (ใช้ภายใน)
  Future<bool> _calculateSingleCouponDiscount(
    double orderAmount,
    String customerId, {
    String? branchCode,
    List<CouponAvailabilityItem>? items,
  }) async {
    if (_appliedCoupons.isEmpty) return false;

    try {
      final calculation = await _apiService.calculateDiscount(
        appliedCoupons: _appliedCoupons,
        orderAmount: orderAmount,
        customerId: customerId,
        branchCode: branchCode,
        items: items,
      );

      if (calculation != null && calculation.success) {
        // อัพเดทผลการคำนวนกลับไปยัง applied coupons
        for (int i = 0; i < _appliedCoupons.length; i++) {
          final result = calculation.coupon_results.firstWhere(
            (r) => r.coupon_code == _appliedCoupons[i].coupon.couponcode,
            orElse: () => CouponCalculationResult(
              coupon_code: _appliedCoupons[i].coupon.couponcode,
              coupon_type: _appliedCoupons[i].coupon.coupontype,
              coupon_type_name: _appliedCoupons[i].coupon.couponTypeName,
              discount_amount: 0,
              cash_voucher_amount: 0,
              applied: false,
              description: '',
              error_message: 'ไม่สามารถใช้ได้',
            ),
          );
          _appliedCoupons[i] = AppliedCouponModel(
            coupon: _appliedCoupons[i].coupon,
            useAmount: _appliedCoupons[i].useAmount,
            reservation: _appliedCoupons[i].reservation,
            calculationResult: result,
            addedAt: _appliedCoupons[i].addedAt,
            message: _appliedCoupons[i].message,
            customerId: _appliedCoupons[i].customerId,
            remaining_usage: _appliedCoupons[i].remaining_usage,
          );
        }

        _lastCalculation = calculation;
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('เกิดข้อผิดพลาดในการคำนวนอัตโนมัติ: $e');
      return false;
    }
  }

  /// จองคูปองทั้งหมด (15 นาที) - ไม่จำเป็นแล้วเพราะจองอัตโนมัติ
  @Deprecated('ไม่จำเป็นแล้ว เพราะจองอัตโนมัติเมื่อเพิ่มคูปอง')
  Future<bool> reserveAllCoupons(String transactionId) async {
    // ส่งคืน true เสมอเพราะคูปองถูกจองอัตโนมัติแล้ว
    return true;
  }

  /// ยกเลิกการจองคูปองทั้งหมด
  Future<bool> cancelAllReservations() async {
    try {
      _setLoading(true);
      _clearError();

      final customerId = global.couponCustomerId;
      bool allSuccess = true;
      for (int i = 0; i < _appliedCoupons.length; i++) {
        final appliedCoupon = _appliedCoupons[i];
        if (appliedCoupon.reservation != null && appliedCoupon.isReserved) {
          // ใช้ helper method ที่ปลอดภัย
          final transactionId = appliedCoupon.transactionId;
          final reservationId = appliedCoupon.reservationId;
          if (transactionId != null && transactionId.isNotEmpty) {
            final success = await _apiService.cancelCouponReservation(
              couponId: appliedCoupon.coupon.guidfixed,
              customerId: customerId,
              transactionId: transactionId,
              reservationId: reservationId,
            );
            if (success) {
              _appliedCoupons[i] = AppliedCouponModel(
                coupon: appliedCoupon.coupon,
                useAmount: appliedCoupon.useAmount,
                reservation: null,
                calculationResult: appliedCoupon.calculationResult,
                addedAt: appliedCoupon.addedAt,
                message: appliedCoupon.message,
                customerId: appliedCoupon.customerId,
                remaining_usage: appliedCoupon.remaining_usage,
              );
            } else {
              allSuccess = false;
            }
          }
        }
      }

      if (!allSuccess) {
        _setError('ไม่สามารถยกเลิกการจองบางตัวได้');
      }

      notifyListeners();
      return allSuccess;
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการยกเลิก: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ใช้คูปองหลังจากขาย (saveBill)
  Future<bool> useAllCoupons(String transactionId) async {
    if (_appliedCoupons.isEmpty) {
      return true; // ไม่มีคูปองถือว่าสำเร็จ
    }
    try {
      final customerId = global.couponCustomerId;
      int successCount = 0;

      // ใช้คูปองทีละตัว
      for (final appliedCoupon in _appliedCoupons) {
        if (appliedCoupon.isReserved) {
          final success = await _apiService.useCoupon(
            couponId: appliedCoupon.coupon.couponcode,
            transactionId: transactionId,
            customerId: customerId,
            actualAmount: appliedCoupon.useAmount,
          );

          if (success) {
            successCount++;
          }
        }
      }

      AppLogger.debug(
        'ใช้คูปองเสร็จแล้ว: $successCount/${_appliedCoupons.where((c) => c.isReserved).length}',
      );

      return successCount == _appliedCoupons.where((c) => c.isReserved).length;
    } catch (e) {
      AppLogger.error('เกิดข้อผิดพลาดในการใช้คูปอง: $e');
      return false;
    }
  }

  /// เคลียร์คูปองทั้งหมดและยกเลิกการจอง
  Future<void> clearAllCoupons({bool afterSale = false}) async {
    if (kDebugMode) {
      AppLogger.debug('🧹 CouponManager.clearAllCoupons() called');
      AppLogger.debug('- Current coupons before clear: ${_appliedCoupons.length}');
      AppLogger.debug('- After sale mode: $afterSale');
    }

    // ยกเลิกการจองเฉพาะเมื่อไม่ใช่หลังจากการขาย
    if (!afterSale) {
      await cancelAllReservations();
    } else {
      AppLogger.debug(
        '   - Skipping cancellation - coupons will be used in sale',
      );
    }

    // เคลียร์รายการ
    _appliedCoupons.clear();
    _lastCalculation = null;
    _clearError();
    AppLogger.debug('   - Coupons after clear: ${_appliedCoupons.length}');
    notifyListeners();
  }

  /// อัพเดท use amount ของคูปอง
  void updateCouponAmount(String couponCode, double newAmount) {
    final index = _appliedCoupons.indexWhere(
      (applied) => applied.coupon.couponcode == couponCode,
    );
    if (index >= 0) {
      _appliedCoupons[index] = AppliedCouponModel(
        coupon: _appliedCoupons[index].coupon,
        useAmount: newAmount,
        reservation: _appliedCoupons[index].reservation,
        calculationResult: _appliedCoupons[index].calculationResult,
        addedAt: _appliedCoupons[index].addedAt,
        message: _appliedCoupons[index].message,
        customerId: _appliedCoupons[index].customerId,
        remaining_usage: _appliedCoupons[index].remaining_usage,
      );
      notifyListeners();
    }
  }

  /// คำนวนส่วนลดใหม่หลังการเปลี่ยนแปลง
  Future<bool> recalculateDiscount(
    double orderAmount, {
    String? branchCode,
    List<CouponAvailabilityItem>? items,
  }) async {
    if (_appliedCoupons.isEmpty) return true;
    final customerId = global.couponCustomerId;
    return await _calculateSingleCouponDiscount(
      orderAmount,
      customerId,
      branchCode: branchCode,
      items: items,
    );
  }

  /// ยกเลิกการจองคูปองเฉพาะตัว
  Future<bool> cancelReservation(String reservationId) async {
    try {
      _setLoading(true);
      _clearError();

      final customerId = global.couponCustomerId;

      // หาคูปองที่มี reservation_id ตรงกัน
      final index = _appliedCoupons.indexWhere(
        (applied) => applied.reservationId == reservationId,
      );
      if (index < 0) {
        _setError('ไม่พบคูปองที่จองไว้');
        return false;
      }

      final appliedCoupon = _appliedCoupons[index];
      if (appliedCoupon.reservation == null || !appliedCoupon.isReserved) {
        _setError('คูปองนี้ไม่ได้จองไว้');
        return false;
      } // ยกเลิกการจอง
      final transactionId = appliedCoupon.transactionId;
      if (transactionId != null && transactionId.isNotEmpty) {
        final success = await _apiService.cancelCouponReservation(
          couponId: appliedCoupon.coupon.guidfixed,
          customerId: customerId,
          transactionId: transactionId,
          reservationId: reservationId,
        );
        if (success) {
          // อัพเดทคูปองให้ไม่มีการจอง
          _appliedCoupons[index] = AppliedCouponModel(
            coupon: appliedCoupon.coupon,
            useAmount: appliedCoupon.useAmount,
            reservation: null,
            calculationResult: appliedCoupon.calculationResult,
            addedAt: appliedCoupon.addedAt,
            message: appliedCoupon.message,
            customerId: appliedCoupon.customerId,
            remaining_usage: appliedCoupon.remaining_usage,
          );

          notifyListeners();
          return true;
        } else {
          _setError('ไม่สามารถยกเลิกการจองได้');
          return false;
        }
      } else {
        _setError('ไม่พบ transaction ID');
        return false;
      }
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการยกเลิกการจอง: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Validation helpers
  bool canAddMoreCoupons() {
    return _appliedCoupons.length < 5; // จำกัดสูงสุด 5 คูปอง
  }

  String? validateCouponCode(String code) {
    if (code.isEmpty) return 'กรุณาป้อนรหัสคูปอง';
    if (code.length < 3) return 'รหัสคูปองต้องมีอย่างน้อย 3 ตัวอักษร';
    if (_appliedCoupons.any((applied) => applied.coupon.couponcode == code)) {
      return 'คูปองนี้ถูกใช้แล้ว';
    }
    return null;
  }
}
