import 'dart:convert';
import 'package:dedecashier/api/client.dart';
import 'package:dedecashier/api/coupon/coupon_model.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dio/dio.dart';

class CouponService {
  final Dio _client = Client().init();

  /// Check coupon availability
  /// GET /coupon/availability?searchBy=<searchBy>&searchValue=<searchValue>&posid=<posid>
  Future<CouponAvailabilityResponse> checkCouponAvailability({
    required String searchBy,
    required String searchValue,
    required String posid,
  }) async {
    try {
      final response = await _client.get(
        '/coupon/availability',
        queryParameters: {
          'searchBy': searchBy,
          'searchValue': searchValue,
          'posid': posid,
        },
      );

      final rawData = json.decode(response.toString());

      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }

      return CouponAvailabilityResponse.fromJson(rawData);
    } on DioException catch (ex) {
      AppLogger.error('Coupon availability check failed: ${ex.toString()}');
      throw Exception('Failed to check coupon availability: ${ex.message}');
    } catch (ex) {
      AppLogger.error('Coupon availability check error: ${ex.toString()}');
      throw Exception('Error checking coupon availability: $ex');
    }
  }

  /// Reserve a coupon for use
  /// POST /coupon/reserve
  Future<CouponReservationResponse> reserveCoupon({
    required String code,
    required String type,
    required String posid,
    required String empcode,
    required String docno,
    required double netamt,
    String? customerId,
    String? transactionId,
    double? reservedAmount,
  }) async {
    try {
      final requestData = CouponReserveRequest(
        code: code,
        type: type,
        posid: posid,
        empcode: empcode,
        docno: docno,
        netamt: netamt,
        customer_id: customerId,
        transaction_id: transactionId,
        reserved_amount: reservedAmount,
      );

      final response = await _client.post(
        '/coupon/reserve',
        data: requestData.toJson(),
      );

      final rawData = json.decode(response.toString());
      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }

      // เพิ่ม coupon_code ใน response ถ้ายังไม่มี
      if (rawData['coupon_code'] == null) {
        rawData['coupon_code'] = code;
      }

      return CouponReservationResponse.fromJson(rawData);
    } on DioException catch (ex) {
      AppLogger.error('Coupon reservation failed: ${ex.toString()}');
      throw Exception('Failed to reserve coupon: ${ex.message}');
    } catch (ex) {
      AppLogger.error('Coupon reservation error: ${ex.toString()}');
      throw Exception('Error reserving coupon: $ex');
    }
  }

  /// Use a reserved coupon
  /// POST /coupon/use
  Future<CouponUseResponse> useCoupon({
    required String code,
    required String type,
    required String posid,
    required String empcode,
    required String docno,
    required double netamt,
    String? customerId,
    String? reservationId,
    String? transactionId,
    double? useAmount,
  }) async {
    try {
      final requestData = CouponUseRequest(
        code: code,
        type: type,
        posid: posid,
        empcode: empcode,
        docno: docno,
        netamt: netamt,
        customer_id: customerId,
        reservation_id: reservationId,
        transaction_id: transactionId,
        use_amount: useAmount,
      );

      final response = await _client.post(
        '/coupon/use',
        data: requestData.toJson(),
      );

      final rawData = json.decode(response.toString());

      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }

      return CouponUseResponse.fromJson(rawData);
    } on DioException catch (ex) {
      AppLogger.error('Coupon use failed: ${ex.toString()}');
      throw Exception('Failed to use coupon: ${ex.message}');
    } catch (ex) {
      AppLogger.error('Coupon use error: ${ex.toString()}');
      throw Exception('Error using coupon: $ex');
    }
  }

  /// Cancel a coupon reservation
  /// POST /coupon/cancel-reservation
  Future<ApiResponse> cancelCouponReservation({
    required String code,
    required String type,
    required String posid,
  }) async {
    try {
      final requestData = CouponCancelRequest(
        code: code,
        type: type,
        posid: posid,
      );

      final response = await _client.post(
        '/coupon/cancel-reservation',
        data: requestData.toJson(),
      );

      final rawData = json.decode(response.toString());

      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }

      return ApiResponse.fromMap(rawData);
    } on DioException catch (ex) {
      AppLogger.error('Coupon reservation cancellation failed: ${ex.toString()}');
      throw Exception('Failed to cancel coupon reservation: ${ex.message}');
    } catch (ex) {
      AppLogger.error('Coupon reservation cancellation error: ${ex.toString()}');
      throw Exception('Error canceling coupon reservation: $ex');
    }
  }

  /// Get coupon status
  /// GET /coupon/status?code=<code>&type=<type>&posid=<posid>
  Future<ApiResponse> getCouponStatus({
    required String code,
    required String type,
    required String posid,
  }) async {
    try {
      final response = await _client.get(
        '/coupon/status',
        queryParameters: {
          'code': code,
          'type': type,
          'posid': posid,
        },
      );

      final rawData = json.decode(response.toString());

      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }

      return ApiResponse.fromMap(rawData);
    } on DioException catch (ex) {
      AppLogger.error('Coupon status check failed: ${ex.toString()}');
      throw Exception('Failed to get coupon status: ${ex.message}');
    } catch (ex) {
      AppLogger.error('Coupon status check error: ${ex.toString()}');
      throw Exception('Error getting coupon status: $ex');
    }
  }

  /// Calculate coupon discounts
  /// POST /coupon/calculate
  Future<CouponCalculationResult> calculateCoupons({
    required double orderAmount,
    required List<CouponForCalculation> coupons,
    String? customerId,
  }) async {
    try {
      final request = CouponCalculationRequest(
        order_amount: orderAmount,
        coupons: coupons,
        customer_id: customerId,
      );

      final response = await _client.post(
        '/coupon/calculate',
        data: request.toJson(),
      );

      final rawData = json.decode(response.toString());

      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }

      return CouponCalculationResult.fromJson(rawData);
    } on DioException catch (ex) {
      AppLogger.error('Coupon calculation failed: ${ex.toString()}');
      throw Exception('Failed to calculate coupons: ${ex.message}');
    } catch (ex) {
      AppLogger.error('Coupon calculation error: ${ex.toString()}');
      throw Exception('Error calculating coupons: $ex');
    }
  }
}
