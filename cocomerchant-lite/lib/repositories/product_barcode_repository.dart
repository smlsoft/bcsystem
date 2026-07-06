import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:cocomerchant_lite/model/product_model.dart';
import 'client.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

class ProductBarcodeRepository {
  Future<ApiResponse> getProductBarcodeList({
    int limit = 0,
    int offset = 0,
    String search = "",
    String itemtype = "",
    String branchcode = "",
    String businesstypecode = "",
    String isbom = "",
    String isusesubbarcodes = "",
  }) async {
    Dio client = Client().init();

    String filtterBom = "";
    String filtterIsUseSubBarcodes = "";
    if (isbom == "all") {
      filtterBom = "";
    } else if (isbom == "showbom") {
      filtterBom = "&isbom=true";
    } else if (isbom == "notshowbom") {
      filtterBom = "&isbom=false";
    } else {
      filtterBom = "";
    }

    if (isusesubbarcodes == "all") {
      filtterIsUseSubBarcodes = "";
    } else if (isusesubbarcodes == "showsubbarcodes") {
      filtterIsUseSubBarcodes = "&isusesubbarcodes=true";
    } else if (isusesubbarcodes == "notshowsubbarcodes") {
      filtterIsUseSubBarcodes = "&isusesubbarcodes=false";
    } else {
      filtterIsUseSubBarcodes = "";
    }

    if (itemtype.isNotEmpty) {
      itemtype = "&itemtype=$itemtype";
    }

    if (branchcode.isNotEmpty) {
      branchcode = "&branchcode=$branchcode";
    }

    if (businesstypecode.isNotEmpty) {
      businesstypecode = "&businesstypecode=$businesstypecode";
    }

    try {
      String query = "/product/barcode/list?offset=$offset&limit=$limit&q=$search$itemtype&sort=barcode:1$filtterBom$filtterIsUseSubBarcodes";
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

  Future<ApiResponse> deleteProductBarcode(String guid) async {
    Dio client = Client().init();
    try {
      final response = await client.delete('/product/barcode/$guid');
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

  /// ลบที่ละหลาย GUID
  Future<ApiResponse> deleteProductBarcodeMany(List<String> guids) async {
    Dio client = Client().init();
    final guidStrings = jsonEncode(guids);
    try {
      final response = await client.delete('/product/barcode', data: guidStrings);
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

  Future<ApiResponse> getProductBarcode(String guid) async {
    Dio client = Client().init();
    try {
      final response = await client.get('/product/barcode/$guid');
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

  Future<ApiResponse> getProductBarcodeRef(String guid) async {
    Dio client = Client().init();
    try {
      final response = await client.get('/product/barcode/ref/$guid');
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

  Future<ApiResponse> getProductBarcodeDetail(String guid) async {
    Dio client = Client().init();
    try {
      final response = await client.get('/product/barcode/pk/$guid');
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

  Future<ApiResponse> saveProductBarcode(ProductBarcodeModel productBarcode) async {
    Dio client = Client().init();
    final data = productBarcode.toJson();
    try {
      final response = await client.post('/product/barcode', data: data);
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

  Future<ApiResponse> updateProductBarcode(String guid, ProductBarcodeModel productBarcode) async {
    Dio client = Client().init();
    final data = productBarcode.toJson();
    try {
      final response = await client.put('/product/barcode/$guid', data: data);
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

  Future<ApiResponse> uploadImage(File file, Uint8List image) async {
    Dio client = Client().init();
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(image, filename: '$fileName.png'),
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

  Future<ApiResponse> getProductBarcodeByBarcode(List<String> productbarcodes) async {
    Dio client = Client().init();
    final barcodesJson = jsonEncode(productbarcodes);
    try {
      final response = await client.get('/product/barcode/by-code?codes=$barcodesJson');
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

  Future<ApiResponse> getProductBarcodeBom(String barcode) async {
    Dio client = Client().init();
    try {
      final response = await client.get('/product/barcode/bom/$barcode');
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
