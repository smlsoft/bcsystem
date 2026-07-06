class ApiResponse<T> {
  late final bool success;
  late final bool error;
  // ignore: unnecessary_question_mark
  late final dynamic? data;
  late final String message;
  late final int code;
  final Page? page;

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
          ? Page.empty
          : Page.fromMap(map['pagination']),
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
    return Page(
        perPage: map['perPage'],
        page: map['page'],
        total: map['total'],
        totalPage: map['totalPage']);
  }
}
