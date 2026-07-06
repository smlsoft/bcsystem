import 'package:dio/dio.dart';
import 'app_const.dart';
import 'package:smlaicloud/global.dart' as global;

class Client {
  Dio init() {
    Dio _dio = Dio();
    _dio.interceptors.add(ApiInterceptors());

    String endPointService = global.myAppConfig.serviceApi;

    endPointService +=
        endPointService[endPointService.length - 1] == "/" ? "" : "/";

    _dio.options.baseUrl = endPointService;
    _dio.options.connectTimeout = 20000 as Duration?; //20s
    _dio.options.receiveTimeout = 30000 as Duration?; //5s

    return _dio;
  }
}

class ApiResponse<T> {
  late final bool success;
  late final bool error;
  // ignore: unnecessary_question_mark
  late final dynamic? data;
  late final message;
  late final code;
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
      page: map['pagination'] == null
          ? Pages.empty
          : Pages.fromMap(map['pagination']),
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
    return Pages(
        perPage: map['perPage'],
        page: map['page'],
        total: map['total'],
        totalPage: map['totalPage']);
  }
}

class ApiInterceptors extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    String authorization = global.appConfig.getString("token") ?? '';
    if (authorization.isNotEmpty) {
      options.headers['Authorization'] = "Bearer $authorization";
    }

    super.onRequest(options, handler);
  }
}
