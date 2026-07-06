import 'package:cocomerchant_lite/environment.dart';
import 'package:cocomerchant_lite/imports_bloc.dart';
import 'package:cocomerchant_lite/service_locator.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';

class Client {
  Dio init() {
    Dio dio = Dio();
    dio.interceptors.add(ApiInterceptors());

    String endPointService = Environment().config.serviceApi;

    endPointService += endPointService[endPointService.length - 1] == "/" ? "" : "/";

    dio.options.baseUrl = endPointService;
    // _dio.options.connectTimeout = 20000; //20s
    //_dio.options.receiveTimeout = 5000 as Duration?; //5s

    return dio;
  }
}

class ApiResponse<T> {
  late final bool success;
  late final bool error;
  // ignore: unnecessary_question_mark
  late final dynamic? data;
  late final String message;
  late final code;
  final Page? page;
  late final String id;
  final String? token;
  final String? uri;

  ApiResponse({
    required this.success,
    required this.data,
    this.id = "",
    this.error = true,
    required this.message,
    this.code = 00,
    this.page,
    this.token = "",
    this.uri,
  });

  factory ApiResponse.fromMap(Map<String, dynamic> map) {
    return ApiResponse(
      success: map['success'] ?? false,
      message: map['message'] ?? "",
      error: map['error'] ?? true,
      data: map['data'],
      id: map['id'] ?? "",
      page: map['pagination'] == null ? Page.empty : Page.fromMap(map['pagination']),
      token: map['token'],
      uri: map['uri'],
    );
  }
}

class Page {
  final int perPage;
  final int page;
  final int total;
  final int totalPage;

  const Page({
    required this.perPage,
    required this.page,
    required this.total,
    required this.totalPage,
  });

  static const empty = Page(perPage: 0, page: 0, total: 0, totalPage: 0);

  bool get isEmpty => this == Page.empty;

  bool get isNotEmpty => this == Page.empty;

  factory Page.fromMap(Map<String, dynamic> map) {
    return Page(perPage: map['perPage'], page: map['page'], total: map['total'], totalPage: map['totalPage']);
  }
}

class ApiInterceptors extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final appConfig = GetStorage('AppConfig');

    String authorization = appConfig.read("token") ?? '';
    if (authorization.isNotEmpty) {
      options.headers['Authorization'] = "Bearer $authorization";
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      serviceLocator<LoginBloc>().add(const TokenInvalid());
    }

    super.onError(err, handler);
  }
}
