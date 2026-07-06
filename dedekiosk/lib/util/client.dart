import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/util/environment.dart';
import 'package:dio/dio.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dio/io.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Client {
  Dio init() {
    Dio dio = Dio();
    dio.interceptors.add(ApiInterceptors());

    String endPointService = Environment().config.serviceApi;

    endPointService += endPointService[endPointService.length - 1] == "/" ? "" : "/";

    dio.options.baseUrl = endPointService;
    dio.options.connectTimeout = const Duration(seconds: 40); //20s
    dio.options.receiveTimeout = const Duration(seconds: 60); //5s
    (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        // ignore: body_might_complete_normally_nullable
        (HttpClient client) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    };
    return dio;
  }
}

class ApiAuthManager {
  static bool _isRefreshing = false;
  static Completer<bool>? _refreshCompleter;

  static Future<bool> reauthenticate({
    bool useStoredConfig = false,
  }) async {
    if (_isRefreshing) return _refreshCompleter!.future;
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();
    try {
      if (useStoredConfig) {
        await _loadStoredConfigIfNeeded();
      }

      final username = global.deviceConfig.usercode;
      final shopId = global.deviceConfig.shopId;
      if (username.isEmpty || shopId.isEmpty) {
        _complete(false);
        return false;
      }

      _initEnvironment(global.deviceConfig.isdev);

      final dio = Dio();
      String endPoint = Environment().config.serviceApi;
      if (!endPoint.endsWith('/')) endPoint += '/';
      dio.options.baseUrl = endPoint;
      dio.options.connectTimeout = const Duration(seconds: 20);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
        client.badCertificateCallback = (_, __, ___) => true;
        return client;
      };

      final response = await dio.post('/poslogin', data: {'username': username, 'shopid': shopId});
      final result = response.data is Map ? Map<String, dynamic>.from(response.data as Map) : jsonDecode(response.toString()) as Map<String, dynamic>;
      final newToken = result['token'] as String?;

      if (newToken != null && newToken.isNotEmpty) {
        global.deviceConfig.token = newToken;
        await _saveDeviceConfig();
        _complete(true);
        return true;
      }
      _complete(false);
      return false;
    } catch (_) {
      _complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  static Future<void> _loadStoredConfigIfNeeded() async {
    if (global.deviceConfig.shopId.isNotEmpty && global.deviceConfig.usercode.isNotEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final rawConfig = prefs.getString(global.storageDeviceConfigName);
    if (rawConfig == null || rawConfig.isEmpty) return;
    final storedConfig = DeviceConfigModel.fromJson(jsonDecode(rawConfig));
    if (storedConfig.shopId.isEmpty || storedConfig.usercode.isEmpty) return;
    global.deviceConfig = storedConfig;
  }

  static Future<void> _saveDeviceConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(global.storageDeviceConfigName);
    await prefs.setString(global.storageDeviceConfigName, jsonEncode(global.deviceConfig.toJson()));
  }

  static void _initEnvironment(String isdev) {
    if (isdev == '0') {
      Environment().initConfig(Environment.PROD);
    } else if (isdev == '1') {
      Environment().initConfig(Environment.DEV);
    } else {
      Environment().initConfig(Environment.STAGING);
    }
  }

  static void _complete(bool value) {
    if (!(_refreshCompleter?.isCompleted ?? true)) {
      _refreshCompleter!.complete(value);
    }
  }
}

class ApiResponse<T> {
  late final bool success;
  late final bool error;
  // ignore: unnecessary_question_mark
  late final dynamic? data;
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
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    String authorization = global.deviceConfig.token;
    final isLoginRequest = options.path.contains('/poslogin');
    if (authorization.isNotEmpty && !isLoginRequest) {
      // if (global.deviceConfig.apikey.isNotEmpty) {
      //   options.headers['x-api-key'] = global.deviceConfig.apikey;
      // } else {
      options.headers['Authorization'] = "Bearer $authorization";
      // }
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final options = err.requestOptions;
    final isAuthError = statusCode == 401 || statusCode == 403;
    final alreadyRetried = options.extra['_retried'] == true;
    final isLoginRequest = options.path.contains('/poslogin');

    if (isAuthError && !alreadyRetried && !isLoginRequest) {
      final refreshed = await ApiAuthManager.reauthenticate();
      if (refreshed) {
        options.extra['_retried'] = true;
        options.headers['Authorization'] = 'Bearer ${global.deviceConfig.token}';
        try {
          final cloned = await Client().init().fetch(options);
          handler.resolve(cloned);
          return;
        } catch (_) {}
      }
    }
    handler.next(err);
  }
}
