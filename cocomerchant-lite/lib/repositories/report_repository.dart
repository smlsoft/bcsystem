import 'package:cocomerchant_lite/environment.dart';
import 'package:cocomerchant_lite/global.dart';

import 'client.dart';
import 'package:dio/dio.dart';

class ReportRepository {
  Future<ApiResponse> getReportMovement(String barcode, String fromdate, String todate, String whcode, String lccode) async {
    Dio dio = Dio();
    final token = appConfig.read("token");
    try {
      final response = await dio.get('${Environment().config.reportApi}/movement?token=$token$barcode$fromdate$todate$whcode$lccode');
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

  Future<ApiResponse> getReportProductBalance(String barcode) async {
    Dio dio = Dio();
    final token = appConfig.read("token");
    try {
      final response = await dio.get('${Environment().config.reportApi}/productbalance?token=$token$barcode');
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

  Future<ApiResponse> activePos(String pincode, String devicenumber, int isdev, String apikey) async {
    Dio dio = Dio();
    final shopid = appConfig.read("shopid");
    final token = appConfig.read("refreshtoken");
    final actoken = appConfig.read("token");

    try {
      final response = await dio
          .get('${Environment().config.reportApi}/poscenter/active?shopid=$shopid&pin=$pincode&token=$token&deviceid=$devicenumber&actoken=$actoken&isdev=$isdev&apikey=$apikey');
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

  /// delete pos
  Future<ApiResponse> deletePos(String pincode) async {
    Dio dio = Dio();
    final shopid = appConfig.read("shopid");

    try {
      final response = await dio.get('${Environment().config.reportApi}/poscenter/delete?shopid=$shopid&pin=$pincode');
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

  /// get apikey
  Future<ApiResponse> getApiKey(String pincode) async {
    Dio dio = Dio();
    final shopid = appConfig.read("shopid");

    try {
      final response = await dio.get('${Environment().config.reportApi}/poscenter/getapikey?shopid=$shopid&pin=$pincode');
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
