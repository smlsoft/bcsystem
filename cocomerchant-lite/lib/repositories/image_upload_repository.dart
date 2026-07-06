// ignore_for_file: await_only_futures

import 'dart:io';
import 'dart:typed_data';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'client.dart';
import 'package:dio/dio.dart';

class ImageUploadRepository {
  Future<ApiResponse> uploadImage(ImageUpload imageupload) async {
    Dio client = Client().init();
    // final data = imageupload.toJson();
    // print(data);

    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(imageupload.uri),
    });

    try {
      final response = await client.post('/upload/images', data: formData);
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

  Future<ApiResponse> uploadImageFile(File file, Uint8List image) async {
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
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      // print(ex);
      throw Exception(errorMessage);
    }
  }
}
