import 'dart:convert';

import 'package:dedekiosk/util/client.dart';

import 'package:dio/dio.dart';

class UserRepository {
  /// token login
  Future<ApiResponse> authenUserByToken(String token) async {
    Dio client = Client().init();

    try {
      final response = await client.post('/tokenlogin', data: {"token": token});
      try {
        final result = json.decode(response.toString());
        final rawData = {"success": result["success"], "data": result};

        if (rawData['error'] != null) {
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      if (ex.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection Timeout');
      }
      if (ex.type == DioExceptionType.receiveTimeout) {
        throw Exception('unable to connect to the server');
      }
      /*if (ex.type == DioExceptionType.other) {
        throw Exception('Something went wrong');
      }
      if (ex.type == DioExceptionType.response) {
        // print(ex.response?.statusCode);
        throw Exception('User Not Found');
      }*/

      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getShopList() async {
    Dio client = Client().init();

    try {
      final response = await client.get('/list-shop?limit=1000');
      try {
        final rawData = json.decode(response.toString());

        // // print(rawData);

        if (rawData['error'] != null) {
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getKioskList() async {
    Dio client = Client().init();

    try {
      final response = await client.get('/order/device?limit=1000');
      try {
        final rawData = json.decode(response.toString());

        // // print(rawData);

        if (rawData['error'] != null) {
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getSettingList() async {
    Dio client = Client().init();

    try {
      final response = await client.get('/order/setting?limit=1000');
      try {
        final rawData = json.decode(response.toString());

        // // print(rawData);

        if (rawData['error'] != null) {
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> selectShop(String shopid) async {
    Dio client = Client().init();

    try {
      final response = await client.post('/select-shop', data: {"shopid": shopid});
      try {
        final rawData = json.decode(response.toString());

        if (rawData['error'] != null) {
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  /// ดึงผู้ใช้งานทั้งหมด
  Future<ApiResponse> getUserList({
    int limit = 0,
    int offset = 0,
    String search = "",
  }) async {
    Dio client = Client().init();

    try {
      String query = "/shop/users?offset=$offset&limit=$limit&q=$search&sort=code:1";
      final response = await client.get(query);
      try {
        final rawData = json.decode(response.toString());
        if (rawData['error'] != null) {
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }
        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  /// Logout
  Future<ApiResponse> logout() async {
    Dio client = Client().init();
    try {
      final response = await client.post('/logout');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }
}
