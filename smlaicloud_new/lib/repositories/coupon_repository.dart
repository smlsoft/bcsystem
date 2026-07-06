import 'package:dio/dio.dart';
import '../model/coupon_model.dart';
import '../model/responses_model.dart';
import 'client.dart';

class CouponRepository {
  Future<CouponResponseModel> getCoupons() async {
    Dio client = Client().init();
    try {
      final response = await client.get('/coupon');

      if (response.statusCode == 200) {
        return CouponResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load coupons: ${response.statusCode}');
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response?.data?.toString() ?? ex.message ?? 'Unknown error';
      throw Exception('Error fetching coupons: $errorMessage');
    }
  }

  Future<CouponModel> getCouponById(String id) async {
    Dio client = Client().init();
    try {
      print('🌐 API Call: GET /coupon/$id');
      final response = await client.get('/coupon/$id');

      if (response.statusCode == 200) {
        print('📡 API Response: ${response.data}');
        // Parse เฉพาะส่วน data ที่อยู่ใน response.data['data']
        final couponData = response.data['data'];
        print('📊 Coupon Data to parse: $couponData');
        final coupon = CouponModel.fromJson(couponData);
        print('🔄 Parsed CouponModel: ${coupon.toJson()}');
        return coupon;
      } else {
        throw Exception('Failed to load coupon: ${response.statusCode}');
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response?.data?.toString() ?? ex.message ?? 'Unknown error';
      print('❌ DioException in getCouponById: $errorMessage');
      throw Exception('Error fetching coupon: $errorMessage');
    }
  }

  Future<ResponsesModel> createCoupon(CouponModel coupon) async {
    Dio client = Client().init();
    try {
      final response = await client.post('/coupon', data: coupon.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ResponsesModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create coupon: ${response.statusCode}');
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response?.data?.toString() ?? ex.message ?? 'Unknown error';
      throw Exception('Error creating coupon: $errorMessage');
    }
  }

  Future<ResponsesModel> updateCoupon(String id, CouponModel coupon) async {
    Dio client = Client().init();
    try {
      final response = await client.put('/coupon/$id', data: coupon.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ResponsesModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update coupon: ${response.statusCode}');
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response?.data?.toString() ?? ex.message ?? 'Unknown error';
      throw Exception('Error updating coupon: $errorMessage');
    }
  }

  Future<ResponsesModel> deleteCoupon(String id) async {
    Dio client = Client().init();
    try {
      final response = await client.delete('/coupon/$id');

      if (response.statusCode == 200) {
        return ResponsesModel.fromJson(response.data);
      } else {
        throw Exception('Failed to delete coupon: ${response.statusCode}');
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response?.data?.toString() ?? ex.message ?? 'Unknown error';
      throw Exception('Error deleting coupon: $errorMessage');
    }
  }
}
