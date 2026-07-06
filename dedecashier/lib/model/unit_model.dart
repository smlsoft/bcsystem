class UnitModel {
  final String guidfixed;
  final String unitcode;
  final String unitname1;
  final List<UnitName> names;

  UnitModel({
    required this.guidfixed,
    required this.unitcode,
    required this.unitname1,
    required this.names,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      guidfixed: json['guidfixed'] ?? '',
      unitcode: json['unitcode'] ?? '',
      unitname1: json['unitname1'] ?? '',
      names: (json['names'] as List<dynamic>?)?.map((name) => UnitName.fromJson(name)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guidfixed': guidfixed,
      'unitcode': unitcode,
      'unitname1': unitname1,
      'names': names.map((name) => name.toJson()).toList(),
    };
  }
}

class UnitName {
  final String code;
  final String name;
  final bool isauto;
  final bool isdelete;

  UnitName({
    required this.code,
    required this.name,
    required this.isauto,
    required this.isdelete,
  });

  factory UnitName.fromJson(Map<String, dynamic> json) {
    return UnitName(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      isauto: json['isauto'] ?? false,
      isdelete: json['isdelete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'isauto': isauto,
      'isdelete': isdelete,
    };
  }
}

class UnitResponse {
  final bool success;
  final List<UnitModel> data;
  final UnitPagination pagination;

  UnitResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory UnitResponse.fromJson(Map<String, dynamic> json) {
    return UnitResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)?.map((unit) => UnitModel.fromJson(unit)).toList() ?? [],
      pagination: UnitPagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class UnitPagination {
  final int total;
  final int page;
  final int perPage;
  final int prev;
  final int next;
  final int totalPage;

  UnitPagination({
    required this.total,
    required this.page,
    required this.perPage,
    required this.prev,
    required this.next,
    required this.totalPage,
  });

  factory UnitPagination.fromJson(Map<String, dynamic> json) {
    return UnitPagination(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['perPage'] ?? 500,
      prev: json['prev'] ?? 0,
      next: json['next'] ?? 0,
      totalPage: json['totalPage'] ?? 1,
    );
  }
}
