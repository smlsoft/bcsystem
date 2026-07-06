import 'dart:io';

import 'package:dedecashier/core/environment.dart';
import 'package:dio/dio.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dio/io.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Client {
  Dio init() {
    Dio dio = Dio();
    dio.interceptors.add(ApiInterceptors());

    String endPointService = Environment().config.serviceApi;
    endPointService += endPointService[endPointService.length - 1] == "/" ? "" : "/";

    dio.options.baseUrl = endPointService;
    // ลด timeout ให้สั้นลงเพื่อไม่ให้แอพค้าง
    dio.options.connectTimeout = const Duration(seconds: 10); // ลดจาก 20 เป็น 5 วินาที
    dio.options.receiveTimeout = const Duration(seconds: 12); // ลดจาก 30 เป็น 5 วินาที
    dio.options.sendTimeout = const Duration(seconds: 10); // เพิ่ม send timeout

    (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      // ตั้งค่า timeout ให้สั้นลง
      client.connectionTimeout = const Duration(seconds: 5);
      client.idleTimeout = const Duration(seconds: 5);
      return client;
    };
    return dio;
  }
}

class ApiResponse<T> {
  late final bool success;
  late final bool error;
  late final dynamic data;
  late final String? message;
  late final int? code;
  final Pages? page;

  ApiResponse({
    required this.success,
    required this.data,
    this.error = true,
    this.message = "",
    this.code = 00,
    this.page,
  });

  factory ApiResponse.fromMap(Map<String, dynamic> map) {
    return ApiResponse(
      success: map['success'] ?? false,
      error: map['error'] ?? true,
      data: map['data'],
      page: map['pagination'] == null ? Pages.empty : Pages.fromMap(map['pagination']),
    );
  }
}

class Pages {
  final int perPage;
  final int page;
  final int total;
  final int totalPage;

  const Pages({
    required this.perPage,
    required this.page,
    required this.total,
    required this.totalPage,
  });

  static const empty = Pages(perPage: 0, page: 0, total: 0, totalPage: 0);

  bool get isEmpty => this == Pages.empty;

  bool get isNotEmpty => this == Pages.empty;

  factory Pages.fromMap(Map<String, dynamic> map) {
    return Pages(perPage: map['perPage'], page: map['page'], total: map['total'], totalPage: map['totalPage']);
  }
}

class ApiInterceptors extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String authorization = sharedPreferences.getString("token") ?? global.appStorage.read("token") ?? '';
    String apikey = sharedPreferences.getString("apikey") ?? global.appStorage.read("apikey") ?? '';
    if (authorization.isNotEmpty) {
      options.headers['Authorization'] = "Bearer $authorization";
      if (apikey.isNotEmpty) {
        options.headers['x-api-key'] = apikey;
      } else {
        options.headers['Authorization'] = "Bearer $authorization";
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ไม่ทำอะไรเลย - เพียงแค่ผ่าน error ไปเงียบๆ
    // ไม่แสดง error message หรือ dialog ใดๆ
    super.onError(err, handler);
  }
}
