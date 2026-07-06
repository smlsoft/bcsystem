import 'dart:typed_data';

import 'package:smlaicloud/model/import_product_model.dart';

import 'client.dart';
import 'package:dio/dio.dart';

class ImportProductRepository {
  Future<ApiResponse> uploadFileExcel(Uint8List file, String filename) async {
    Dio client = Client().init();

    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(file, filename: filename),
    });

    try {
      final response = await client.post('/productimport/upload', data: formData);
      try {
        // print(response.data);

        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        // print(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      // print(ex);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getImportProduct(String taskid, String q, int limit, int page) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/productimport/$taskid?&limit=$limit&page=$page&q=$q');
      try {
        var data = response.data['data'];
        var pagination = response.data['pagination'];

        return ApiResponse.fromMap({
          'success': true,
          'data': data,
          'pagination': pagination,
        });
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  /// delete detail by guid
  Future<ApiResponse> deleteDetailByGuid(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/productimport/item/$guid');
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

  /// delete taskid
  Future<ApiResponse> deleteTaskid(String taskid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/productimport/$taskid');
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

  /// update detail
  Future<ApiResponse> updateDetail(String guid, ImportProductModel detail) async {
    Dio client = Client().init();
    final data = detail.toJson();
    try {
      final response = await client.put('/productimport/item/$guid', data: data);
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

  /// add detail
  Future<ApiResponse> addDetail(ImportProductModel detail) async {
    Dio client = Client().init();
    final data = detail.toJson();
    try {
      final response = await client.post('/productimport', data: data);
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

  /// save taskid
  Future<ApiResponse> saveTaskid(String taskid, String languangecode) async {
    Dio client = Client().init();

    try {
      final response = await client.post('/productimport/$taskid', data: {'languangecode': languangecode});
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

  /// verify taskid
  Future<ApiResponse> verifyTaskid(String taskid) async {
    Dio client = Client().init();

    try {
      final response = await client.post('/productimport/$taskid/verify');
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
}
