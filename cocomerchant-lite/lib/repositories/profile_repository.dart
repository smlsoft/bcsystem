import 'package:cocomerchant_lite/model/profile_model.dart';

import 'client.dart';
import 'package:dio/dio.dart';

class ProfileRepository {
  /// get profile
  Future<ApiResponse> getProfile() async {
    Dio client = Client().init();
    try {
      final response = await client.get('/profile');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      throw Exception(ex);
    }
  }

  /// update profile
  Future<ApiResponse> updateProfile(ProfileModel profileModel) async {
    Dio client = Client().init();
    final data = profileModel.toJson();
    try {
      final response = await client.put('/profile', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      throw Exception(ex);
    }
  }
}
