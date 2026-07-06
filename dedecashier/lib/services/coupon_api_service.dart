// ignore_for_file: unused_import
import 'dart:convert';
import 'package:dedecashier/api/client.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/model/coupon/coupon_model.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dio/dio.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class CouponApiService {
  static final CouponApiService _instance = CouponApiService._internal();
  factory CouponApiService() => _instance;
  CouponApiService._internal();

  /// ค้นหาคูปองด้วยรหัส
  Future<CouponModel?> searchCoupon(String couponCode) async {
    Dio client = Client().init();
    try {
      final response = await client.get('/coupon/code/$couponCode');
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug('Search coupon response: $rawData');

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception(errorMessage);
        }

        if (rawData['success'] == true && rawData['data'] != null) {
          // API ใหม่ส่งคืน data เป็น object ตรง ๆ ไม่ใช่ array
          final dataObject = rawData['data'];
          return CouponModel.fromJson(dataObject);
        }
        return null;
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  /// ตรวจสอบความพร้อมใช้งานคูปองแบบใหม่ (รองรับ items)
  ///
  /// วิธีการใช้งาน:
  /// ```dart
  /// final items = [
  ///   CouponAvailabilityItem(
  ///     barcode: "58002384",
  ///     price: 1250,
  ///     qty: 2,
  ///     sumamount: 2500,
  ///   ),
  /// ];
  ///
  /// final response = await couponApiService.checkCouponAvailabilityWithItems(
  ///   "COUPON_CODE",
  ///   "00000",      // branch_code
  ///   "T001",       // customer_id
  ///   items,
  /// );
  /// ```
  Future<CouponAvailabilityNewResponse?> checkCouponAvailabilityWithItems(
    String couponCode,
    String branchCode,
    String customerId,
    List<CouponAvailabilityItem> items,
  ) async {
    Dio client = Client().init();
    try {
      final requestData = CouponAvailabilityCheckRequest(
        branch_code: branchCode,
        customer_id: customerId,
        items: items,
      );

      final response = await client.post(
        '/coupon/$couponCode/availability/check',
        data: json.encode(requestData.toJson()),
      );

      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(
          'Check coupon availability with items response: $rawData',
        );

        if (rawData is! Map<String, dynamic>) {
          AppLogger.debug(
            'Warning: Expected Map but got ${rawData.runtimeType}',
          );
          return null;
        }

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception(errorMessage);
        }

        if (rawData['success'] == true && rawData['data'] != null) {
          return CouponAvailabilityNewResponse.fromJson(rawData['data']);
        }
        return null;
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  /// ตรวจสอบความพร้อมใช้งานคูปอง (ใช้ API ใหม่ที่รองรับ items โดยอัตโนมัติ)
  Future<CouponAvailabilityResponse?> checkCouponAvailability(
    String couponCode,
    String customerId, {
    List<CouponAvailabilityItem>? items,
    String? branchCode,
  }) async {
    // ถ้ามี items ให้ใช้ API ใหม่
    if (items != null && items.isNotEmpty) {
      final branchCodeToUse =
          branchCode ??
          (global.branchId.isNotEmpty ? global.branchId : "00000");
      final newResponse = await checkCouponAvailabilityWithItems(
        couponCode,
        branchCodeToUse,
        customerId,
        items,
      );

      if (newResponse != null) {
        // แปลง response ใหม่เป็น response เดิมเพื่อ backward compatibility
        return CouponAvailabilityResponse(
          available: newResponse.available,
          usage_count: newResponse.usage_count,
          max_usage_count: newResponse.max_usage_count,
          remaining_usage: newResponse.remaining_usage,
          status: newResponse.status,
          is_expired: newResponse.is_expired,
          message: newResponse.message,
          remaining_value: 0.0, // ไม่มีใน API ใหม่
        );
      }
      return null;
    }

    // ถ้าไม่มี items ให้ใช้ API เดิม
    Dio client = Client().init();
    try {
      final response = await client.get(
        '/coupon/$couponCode/availability?customer_id=$customerId',
      );
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug('Check coupon availability response: $rawData');
        if (rawData is! Map<String, dynamic>) {
          AppLogger.debug(
            'Warning: Expected Map but got ${rawData.runtimeType}',
          );
          return null;
        }

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception(errorMessage);
        }

        if (rawData['success'] == true && rawData['data'] != null) {
          return CouponAvailabilityResponse.fromJson(rawData['data']);
        }
        return null;
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  /// คำนวณส่วนลดจากคูปอง (API ใหม่ที่รองรับ branch_code และ items)
  ///
  /// วิธีการใช้งาน:
  /// ```dart
  /// final items = [
  ///   CouponAvailabilityItem(
  ///     barcode: "58002384",
  ///     price: 1250,
  ///     qty: 2,
  ///     sumamount: 2500,
  ///   ),
  /// ];
  ///
  /// final response = await couponApiService.calculateDiscount(
  ///   appliedCoupons: appliedCoupons,
  ///   orderAmount: 2500.0,
  ///   customerId: "T001",
  ///   branchCode: "00000",
  ///   items: items,
  /// );
  /// ```
  Future<CouponCalculationResponse?> calculateDiscount({
    required List<AppliedCouponModel> appliedCoupons,
    required double orderAmount,
    String? customerId,
    String? branchCode,
    List<CouponAvailabilityItem>? items,
  }) async {
    Dio client = Client().init();
    try {
      final requestData = {
        'branch_code':
            branchCode ??
            (global.branchId.isNotEmpty ? global.branchId : "00000"),
        'order_amount': orderAmount,
        'coupons': appliedCoupons
            .map(
              (appliedCoupon) => {
                'coupon_code': appliedCoupon.coupon.couponcode,
                if (appliedCoupon.coupon.coupontype == 2 ||
                    appliedCoupon.useAmount != appliedCoupon.coupon.couponvalue)
                  'use_amount': appliedCoupon.useAmount,
              },
            )
            .toList(),
        'customer_id': customerId ?? 'GUEST',
        if (items != null) 'items': items.map((item) => item.toJson()).toList(),
      };

      final response = await client.post(
        '/coupon/calculate',
        data: json.encode(requestData),
      );
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug('Calculate coupon response: $rawData');

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception(errorMessage);
        }
        if (rawData['success'] == true && rawData['data'] != null) {
          final data = rawData['data'] as Map<String, dynamic>;

          // Safe parsing with null checks for the new API structure
          final success = data['success'] as bool? ?? false;
          final totalDiscount =
              (data['total_discount'] as num?)?.toDouble() ?? 0.0;
          final totalCashVoucher =
              (data['total_cash_voucher'] as num?)?.toDouble() ?? 0.0;
          final finalAmount = (data['final_amount'] as num?)?.toDouble() ?? 0.0;
          final couponResultsList =
              data['coupon_results'] as List<dynamic>? ?? [];
          final errorsList =
              data['errors'] as List<dynamic>? ??
              []; // Parse coupon results safely
          final couponResults = <CouponCalculationResult>[];
          for (final item in couponResultsList) {
            if (item is Map<String, dynamic>) {
              try {
                // Parse item_results array
                final itemResultsList =
                    item['item_results'] as List<dynamic>? ?? [];
                final itemResults = <CouponItemResult>[];
                for (final itemResult in itemResultsList) {
                  if (itemResult is Map<String, dynamic>) {
                    try {
                      final result = CouponItemResult(
                        barcode: itemResult['barcode'] as String? ?? '',
                        qty: (itemResult['qty'] as num?)?.toDouble() ?? 0.0,
                        price: (itemResult['price'] as num?)?.toDouble() ?? 0.0,
                        sumamount:
                            (itemResult['sumamount'] as num?)?.toDouble() ??
                            0.0,
                        is_eligible:
                            itemResult['is_eligible'] as bool? ?? false,
                        discount_amount:
                            (itemResult['discount_amount'] as num?)
                                ?.toDouble() ??
                            0.0,
                        matched_category:
                            itemResult['matched_category'] as String?,
                      );
                      itemResults.add(result);
                    } catch (e) {
                      AppLogger.error(
                        'Error parsing item result: $e, item: $itemResult',
                      );
                    }
                  }
                }

                final result = CouponCalculationResult(
                  coupon_code: item['coupon_code'] as String? ?? '',
                  coupon_type: (item['coupon_type'] as num?)?.toInt() ?? 0,
                  coupon_type_name: item['coupon_type_name'] as String? ?? '',
                  discount_amount:
                      (item['discount_amount'] as num?)?.toDouble() ?? 0.0,
                  cash_voucher_amount:
                      (item['cash_voucher_amount'] as num?)?.toDouble() ?? 0.0,
                  used_amount: (item['used_amount'] as num?)?.toDouble() ?? 0.0,
                  remaining_usage:
                      (item['remaining_usage'] as num?)?.toInt() ?? 0,
                  usage_count: (item['usage_count'] as num?)?.toInt() ?? 0,
                  applied: item['applied'] as bool? ?? false,
                  branch_allowed: item['branch_allowed'] as bool? ?? true,
                  eligible_amount:
                      (item['eligible_amount'] as num?)?.toDouble() ?? 0.0,
                  eligible_item_count:
                      (item['eligible_item_count'] as num?)?.toInt() ?? 0,
                  minimum_amount:
                      (item['minimum_amount'] as num?)?.toDouble() ?? 0.0,
                  item_results: itemResults,
                  message: item['message'] as String? ?? '',
                  // Backward compatibility fields - may not exist in new API
                  remaining_value:
                      (item['remaining_value'] as num?)?.toDouble() ?? 0.0,
                  description: item['description'] as String? ?? '',
                  error_message: item['error_message'] as String? ?? '',
                );
                couponResults.add(result);
              } catch (e) {
                AppLogger.error('Error parsing coupon result: $e, item: $item');
              }
            }
          }

          // Parse errors safely
          final errors = <CouponCalculationError>[];
          for (final item in errorsList) {
            if (item is Map<String, dynamic>) {
              try {
                final error = CouponCalculationError(
                  code: item['code'] as String? ?? '',
                  coupon_code: item['coupon_code'] as String? ?? '',
                  error: item['error'] as String? ?? '',
                );
                errors.add(error);
              } catch (e) {
                AppLogger.error('Error parsing coupon error: $e, item: $item');
              }
            }
          }

          return CouponCalculationResponse(
            success: success,
            total_discount: totalDiscount,
            total_cash_voucher: totalCashVoucher,
            final_amount: finalAmount,
            coupon_results: couponResults,
            errors: errors,
          );
        }
        return null;
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  /// จองคูปอง
  Future<CouponReservationResponse?> reserveCoupon({
    required String couponCode,
    required String transactionId,
    String? customerId,
  }) async {
    Dio client = Client().init();
    try {
      final requestData = {
        'transaction_id': transactionId,
        'customer_id': customerId,
      };

      final response = await client.post(
        '/coupon/$couponCode/reserve',
        data: json.encode(requestData),
      );

      if (kDebugMode) {
        AppLogger.debug('Reserve coupon HTTP status: ${response.statusCode}');
        AppLogger.debug('Reserve coupon HTTP response: ${response.data}');
      }

      try {
        // Handle different response types
        String responseString;
        if (response.data is String) {
          responseString = response.data;
        } else {
          responseString = json.encode(response.data);
        }

        final rawData = json.decode(responseString);

        if (kDebugMode) {
          AppLogger.debug('Reserve coupon request: $requestData');
          AppLogger.debug('Reserve coupon response: $rawData');
          AppLogger.debug('Response type: ${rawData.runtimeType}');
          if (rawData is Map && rawData['data'] != null) {
            AppLogger.debug('Data field type: ${rawData['data'].runtimeType}');
            AppLogger.debug('Data field content: ${rawData['data']}');
          }
        }
        if (rawData is! Map<String, dynamic>) {
          AppLogger.debug(
            'Warning: Expected Map but got ${rawData.runtimeType}',
          );
          return null;
        }

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception(errorMessage);
        }

        if (rawData['success'] == true && rawData['data'] != null) {
          try {
            // Safe parsing with additional null checks
            final data = rawData['data'] as Map<String, dynamic>;

            AppLogger.debug('Parsing reservation data: $data');

            return CouponReservationResponse.fromJson(data);
          } catch (parseError) {
            if (kDebugMode) {
              AppLogger.error('Error parsing CouponReservationResponse: $parseError');
              AppLogger.debug('Raw data: ${rawData['data']}');
            }

            // Try to create a fallback response if parsing fails
            try {
              final data = rawData['data'] as Map<String, dynamic>;
              return CouponReservationResponse(
                reservation_id: data['reservation_id']?.toString() ?? '',
                coupon_id: data['coupon_id']?.toString() ?? couponCode,
                transaction_id: data['transaction_id']?.toString() ?? '',
                reserved_amount:
                    (data['reserved_amount'] as num?)?.toDouble() ?? 0.0,
                expires_at: data['expires_at'] != null
                    ? DateTime.tryParse(data['expires_at'].toString())
                    : null,
                reserved: data['reserved'] as bool? ?? false,
                message: data['message']?.toString() ?? '',
              );
            } catch (fallbackError) {
              AppLogger.error(
                'Fallback parse error in reserveCoupon: $fallbackError',
              );
              throw Exception(
                'Failed to parse reservation response: $parseError',
              );
            }
          }
        }
        return null;
      } catch (ex) {
        AppLogger.debug('Inner exception in reserveCoupon: $ex');
        AppLogger.error('Inner exception in reserveCoupon: $ex');
        throw Exception('Response parsing error: $ex');
      }
    } on DioException catch (ex) {
      String errorMessage = "";
      if (ex.response?.data != null) {
        errorMessage +=
            ' - Response: ${ex.response?.data['message'] ?? ex.response?.data}';
      }

      AppLogger.debug('DioException in reserveCoupon: $errorMessage');

      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    } catch (generalEx) {
      String errorMessage = 'General error in reserveCoupon: $generalEx';

      AppLogger.debug('General exception in reserveCoupon: $errorMessage');

      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  /// ยกเลิกการจองคูปอง
  Future<bool> cancelCouponReservation({
    required String couponId,
    required String transactionId,
    String? customerId,
    String? reservationId,
  }) async {
    Dio client = Client().init();
    try {
      final requestData = {
        'transaction_id': transactionId,
        'customer_id': customerId ?? 'GUEST',
        'pos_code': global.posConfig.code,
      };

      // เพิ่ม reservation_id ถ้ามี
      if (reservationId != null && reservationId.isNotEmpty) {
        requestData['reservation_id'] = reservationId;
      }

      final response = await client.delete(
        '/coupon/$couponId/reserve',
        data: json.encode(requestData),
      );
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug('Cancel coupon reservation response: $rawData');

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception(errorMessage);
        }

        return rawData['success'] == true;
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  /// ใช้คูปอง (หลังจากชำระเงินเสร็จ)
  Future<bool> useCoupon({
    required String couponId,
    required String transactionId,
    String? customerId,
    double? actualAmount,
  }) async {
    Dio client = Client().init();
    try {
      final requestData = {
        'transaction_id': transactionId,
        'customer_id': customerId ?? 'GUEST',
        'actual_amount': actualAmount,
        'pos_code': global.posConfig.code,
        'used_at': DateTime.now().toIso8601String(),
      };

      final response = await client.post(
        '/coupon/$couponId/use',
        data: json.encode(requestData),
      );
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug('Use coupon response: $rawData');

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception(errorMessage);
        }

        return rawData['success'] == true;
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  /// ใช้คูปองด้วย CouponUseRequest model (API ใหม่)
  Future<bool> useCouponWithRequest({
    required String couponId,
    required CouponUseRequest request,
  }) async {
    Dio client = Client().init();
    try {
      // ใช้ endpoint /coupon/{couponId}/use พร้อมกับ body ที่สมบูรณ์
      final response = await client.post(
        '/coupon/$couponId/use',
        data: json.encode(request.toJson()),
      );

      if (kDebugMode) {
        AppLogger.debug('Use coupon with request - couponId: $couponId');
        AppLogger.debug('Use coupon with request - body: ${request.toJson()}');
      }

      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug('Use coupon with request response: $rawData');

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception(errorMessage);
        }

        return rawData['success'] == true;
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  /// ดึงประวัติการใช้คูปองของลูกค้า
  Future<ApiResponse> getCouponUsageHistory({
    required String customerId,
    int limit = 50,
    int offset = 0,
  }) async {
    Dio client = Client().init();
    try {
      final response = await client.get(
        '/coupon/usage-history?customer_id=$customerId&limit=$limit&offset=$offset',
      );
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug('Coupon usage history response: $rawData');

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception(errorMessage);
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  /// สร้าง CouponAvailabilityItem จาก POS Items
  static List<CouponAvailabilityItem> createAvailabilityItemsFromPos(
    List<dynamic> posItems,
  ) {
    final List<CouponAvailabilityItem> items = [];

    for (final item in posItems) {
      if (item is Map<String, dynamic>) {
        final barcode = item['barcode'] as String? ?? '';
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final qty = (item['qty'] as num?)?.toDouble() ?? 1;
        final amount = (item['amount'] as num?)?.toDouble() ?? (price * qty);

        if (barcode.isNotEmpty) {
          items.add(
            CouponAvailabilityItem(
              barcode: barcode,
              price: price,
              qty: qty,
              sumamount: amount,
            ),
          );
        }
      }
    }

    return items;
  }

  /// สร้าง CouponAvailabilityItem จาก PosProcessDetailModel list
  static List<CouponAvailabilityItem> createAvailabilityItemsFromPosDetails(
    List<dynamic> details,
  ) {
    final List<CouponAvailabilityItem> items = [];

    for (final detail in details) {
      try {
        // Assuming detail has barcode, price, qty properties
        final barcode = detail.barcode as String? ?? '';
        final price = (detail.price as num?)?.toDouble() ?? 0.0;
        final qty = (detail.qty as num?)?.toDouble() ?? 1;
        final amount = (detail.amount as num?)?.toDouble() ?? (price * qty);

        if (barcode.isNotEmpty) {
          items.add(
            CouponAvailabilityItem(
              barcode: barcode,
              price: price,
              qty: qty,
              sumamount: amount,
            ),
          );
        }
      } catch (e) {
        AppLogger.error('Error creating availability item from detail: $e');
      }
    }

    return items;
  }
}
