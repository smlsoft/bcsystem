import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:smlaicloud/model/debtor_model.dart';
import 'package:flutter/foundation.dart';

import 'client.dart';
import 'package:dio/dio.dart';

class DebtorRepository {
  Future<ApiResponse> getDebtorList({
    int limit = 0,
    int offset = 0,
    String search = "",
    List<String>? groups,
  }) async {
    Dio client = Client().init();
    String filterGroup = "";

    try {
      if (groups!.isNotEmpty) {
        filterGroup = "&groups=${groups.join(',')}";
      }
      String query = "/debtaccount/debtor/list?offset=$offset&limit=$limit&q=$search$filterGroup";
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
      throw errorMessage;
    }
  }

  Future<ApiResponse> deleteDebtor(String guid) async {
    Dio client = Client().init();
    try {
      final response = await client.delete('/debtaccount/debtor/$guid');
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

  /// ลบที่ละหลาย GUID
  Future<ApiResponse> deleteDebtorMany(List<String> guids) async {
    Dio client = Client().init();
    try {
      final guidStrings = jsonEncode(guids);
      final response = await client.delete('/debtaccount/debtor', data: guidStrings);
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

  Future<ApiResponse> getDebtor(String guid) async {
    Dio client = Client().init();
    try {
      final response = await client.get('/debtaccount/debtor/$guid');
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

  Future<ApiResponse> getDebtorByCode(String custcode) async {
    Dio client = Client().init();
    try {
      final response = await client.get('/debtaccount/debtor/code/$custcode');
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

  Future<ApiResponse> saveDebtor(DebtorRequestModel debtorRequestModel) async {
    Dio client = Client().init();
    final data = debtorRequestModel.toJson();

    // print(data);
    try {
      final response = await client.post('/debtaccount/debtor', data: data);
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

  Future<ApiResponse> updateDebtor(String guid, DebtorRequestModel debtorModel) async {
    Dio client = Client().init();
    final data = debtorModel.toJson();
    try {
      // print(data);
      final response = await client.put('/debtaccount/debtor/$guid', data: data);
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

  Future<ApiResponse> uploadImage(File file, Uint8List image) async {
    Dio client = Client().init();
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromBytes(image, filename: '$fileName.png'),
    });
    try {
      final response = await client.post('/upload/images', data: formData);
      try {
        // print(response.data);
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        // print(ex);
        throw ex;
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      // print(ex);
      throw errorMessage;
    }
  }
}
