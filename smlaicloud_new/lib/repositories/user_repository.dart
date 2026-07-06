import 'dart:convert';

import 'package:smlaicloud/model/profile_model.dart';
import 'package:smlaicloud/model/user_model.dart';
import 'package:smlaicloud/model/create_shop_model.dart';

import 'client.dart';
import 'package:dio/dio.dart';

class UserRepository {
  Future<ApiResponse> registerUser(String userName, String passWord, String timezonelabel, String timezoneoffset, String yeartype) async {
    Dio client = Client().init();

    try {
      final response =
          await client.post('/register', data: {"name": userName, "username": userName, "password": passWord, "timezonelabel": timezonelabel, "timezoneoffset": timezoneoffset, "yeartype": yeartype});
      try {
        final result = json.decode(response.toString());
        final rawData = {"success": result["success"], "data": result};

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          throw Exception(errorMessage);
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
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> authenUser(String userName, String passWord) async {
    Dio client = Client().init();

    try {
      final response = await client.post('/login', data: {"username": userName, "password": passWord});
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

  /// token login
  Future<ApiResponse> authenUserByToken(String token) async {
    Dio client = Client().init();
    print(token);

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
      final response = await client.get('/list-shop?limit=100');
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

  Future<ApiResponse> createShop(CreateShopModel createShop) async {
    Dio client = Client().init();
    createShop.settings!.languageconfigs![0].isdefault = true;
    final data = createShop.toJson();
    try {
      final response = await client.post('/create-shop', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw errorMessage;
    }
  }

  Future<dynamic> requestOPT(String telephoneNumber) async {
    Dio client = Dio();

    try {
      final response = await client.post('https://smsapi.deecommerce.co.th:4300/service/v1/otp/request', data: {
        "accountId": "08992231310610",
        "secretKey": "U2FsdGVkX19gSK0SR/xX5DAa6B2Mn1wDyEo1es83LNQ=",
        "type": "OTP",
        "lang": 'th',
        "to": telephoneNumber,
        "sender": "deeSMS.OTP",
        "isShowRef": '1'
      });
      try {
        final rawData = json.decode(response.toString());

        if (rawData['error'] != '0') {
          throw Exception('${rawData['msg']}');
        }

        return rawData['result'];
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<bool> verifyOPT(String token, String pin) async {
    Dio client = Dio();

    try {
      final response = await client.post('https://smsapi.deecommerce.co.th:4300/service/v1/otp/verify', data: {
        "accountId": "08992231310610",
        "secretKey": "U2FsdGVkX19gSK0SR/xX5DAa6B2Mn1wDyEo1es83LNQ=",
        "token": token,
        "pin": pin,
      });
      try {
        final rawData = json.decode(response.toString());

        if (rawData['error'] != '0') {
          throw Exception('${rawData['msg']}');
        }

        return true;
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

  /// ลบผู้ใช้งาน

  Future<ApiResponse> deleteUser(String username) async {
    Dio client = Client().init();
    // print(username);
    try {
      final response = await client.delete('/shop/permission/$username');
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

  /// บันทึกและแก้ไขผู้ใช้งาน
  Future<ApiResponse> saveAndUpdateUser(UserModel userModel) async {
    Dio client = Client().init();
    final data = userModel.toJson();
    try {
      final response = await client.put('/shop/permission', data: data);
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

  /// ดึงผู้ใช้งานตาม username
  Future<ApiResponse> getUser(String username) async {
    Dio client = Client().init();
    try {
      final response = await client.get('/shop/permission/$username');
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

  /// profile shop
  Future<ApiResponse> loadProfileShop() async {
    Dio client = Client().init();
    try {
      final response = await client.get('/profileshop');
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
