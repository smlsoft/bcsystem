import 'dart:io';

import 'package:dedecashier/core/environment.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

class Request {
  final Dio _dio = Dio();

  Request() {
    updateDioInterceptors();
  }

  void updateAuthorization(String token) {
    _dio.options.headers['authorization'] = 'Bearer $token';
  }

  void updateEndpoint() {
    _dio.options.baseUrl = Environment().config.serviceApi;
  }

  void updateDioInterceptors() {
    _dio.options = BaseOptions(
      baseUrl: Environment().config.serviceApi,
      receiveDataWhenStatusError: true,
      validateStatus: (value) {
        return value! <= 500;
      },
      headers: {
        'Accept': 'application/json',
      },
    );
    _dio
      ..interceptors.add(
        LogInterceptor(
          requestBody: kDebugMode ? true : false,
          responseBody: kDebugMode ? true : false,
          requestHeader: kDebugMode ? true : false,
        ),
      )
      ..interceptors.add(
        InterceptorsWrapper(
          onError: (DioException e, handler) {
            if (e.response?.statusCode == 402) {
              //logout user and go to login page
            }
            return handler.next(e);
          },
        ),
      );
    (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        // ignore: body_might_complete_normally_nullable
        (HttpClient client) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    };
  }

  // requests
  Future<Response> get(String path) async {
    return await _dio.get(path);
  }

  Future<Response> post(String path, {Object? data}) async {
    return await _dio.post(path, data: data);
  }
}
