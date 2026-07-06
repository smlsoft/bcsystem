import 'package:dio/dio.dart';
import 'package:smlaicloud/repositories/client.dart';
import 'package:smlaicloud/model/bi_report/bi_report_models.dart';

class BiReportRepository {
  // Step 1: Submit report generation job
  Future<BiReportJobResponse> submitReport({
    required BiReportType reportType,
    required Map<String, dynamic> conditions,
    required String token,
  }) async {
    Dio client = Client().initBiReport();

    try {
      final requestBody = {
        'conditions': conditions,
      };

      final response = await client.post(
        reportType.endpoint,
        data: requestBody,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return BiReportJobResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (ex) {
      print('❌ DioException submitting report: ${ex.response?.data}');
      final errorData = ex.response?.data as Map<String, dynamic>? ?? {};
      throw BiReportException(
        code: ex.response?.statusCode ?? 500,
        message: errorData['message'] ?? 'เกิดข้อผิดพลาดในการส่งคำขอ',
      );
    } catch (e) {
      print('❌ Error submitting report: $e');
      throw BiReportException(
        code: 500,
        message: 'เกิดข้อผิดพลาดไม่คาดคิด: ${e.toString()}',
      );
    }
  }

  // Step 2: Check report status
  Future<BiReportStatusResponse> getReportStatus({
    required BiReportType reportType,
    required String jobId,
    required String token,
  }) async {
    Dio client = Client().initBiReport();

    try {
      final response = await client.get(
        '${reportType.endpoint}/$jobId/status',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return BiReportStatusResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (ex) {
      print('❌ DioException checking report status: ${ex.response?.data}');
      final errorData = ex.response?.data as Map<String, dynamic>? ?? {};
      throw BiReportException(
        code: ex.response?.statusCode ?? 500,
        message: errorData['message'] ?? 'เกิดข้อผิดพลาดในการตรวจสอบสถานะ',
      );
    } catch (e) {
      print('❌ Error checking report status: $e');
      throw BiReportException(
        code: 500,
        message: 'เกิดข้อผิดพลาดไม่คาดคิด: ${e.toString()}',
      );
    }
  }

  // Step 3: Get report detail data
  Future<BiReportDetailResponse<T>> getReportDetail<T>({
    required BiReportType reportType,
    required String jobId,
    required String token,
    required T Function(Object? json) fromJsonT,
    int page = 1,
    int size = 20,
  }) async {
    Dio client = Client().initBiReport();

    try {
      final response = await client.get(
        '${reportType.endpoint}/$jobId/detail',
        queryParameters: {
          'page': page,
          'size': size,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      try {
        final result = BiReportDetailResponse.fromJson(response.data as Map<String, dynamic>, fromJsonT);
        return result;
      } catch (parseError) {
        print('❌ JSON parsing error: $parseError');
        print('🔍 Raw response data type: ${response.data.runtimeType}');
        print('🔍 Response data: ${response.data}');
        throw BiReportException(
          code: 422,
          message: 'เกิดข้อผิดพลาดในการแปลงข้อมูล: ${parseError.toString()}',
        );
      }
    } on DioException catch (ex) {
      print('❌ DioException getting report detail: ${ex.response?.data}');
      final errorData = ex.response?.data as Map<String, dynamic>? ?? {};
      throw BiReportException(
        code: ex.response?.statusCode ?? 500,
        message: errorData['message'] ?? 'เกิดข้อผิดพลาดในการดึงข้อมูลรายงาน',
      );
    } catch (e) {
      print('❌ Error getting report detail: $e');
      throw BiReportException(
        code: 500,
        message: 'เกิดข้อผิดพลาดไม่คาดคิด: ${e.toString()}',
      );
    }
  }

  // Get Sale Report Summary
  Future<dynamic> getReportSummary({
    required BiReportType reportType,
    required String jobId,
    required String token,
  }) async {
    Dio client = Client().initBiReport();

    try {
      final response = await client.get(
        '${reportType.endpoint}/$jobId/summary',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      // Return raw response data
      return response.data;
    } on DioException catch (ex) {
      print('❌ DioException getting report summary: ${ex.response?.data}');
      final errorData = ex.response?.data as Map<String, dynamic>? ?? {};
      throw BiReportException(
        code: ex.response?.statusCode ?? 500,
        message: errorData['message'] ?? 'เกิดข้อผิดพลาดในการดึงข้อมูลสรุปรายงาน',
      );
    } catch (e) {
      print('❌ Error getting report summary: $e');
      throw BiReportException(
        code: 500,
        message: 'เกิดข้อผิดพลาดไม่คาดคิด: ${e.toString()}',
      );
    }
  }

  void dispose() {
    // Dio clients are automatically managed, no need to close manually
    // Each method creates its own client instance
  }
}

// Custom Exception Class
class BiReportException implements Exception {
  final int code;
  final String message;

  const BiReportException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'BiReportException($code): $message';
}
