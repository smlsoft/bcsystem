import 'package:json_annotation/json_annotation.dart';

part 'global_model.g.dart';

enum DateRange {
  today,
  yesterday,
  lastSevenDays,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  thisYear,
  lastYear,
  custom,
}

class DateRangeModel {
  DateRange dateRange;
  DateTime startDate;
  DateTime endDate;

  DateRangeModel({
    required this.dateRange,
    required this.startDate,
    required this.endDate,
  });
}

@JsonSerializable(explicitToJson: true)
class LanguageSystemModel {
  String code;
  String text;

  LanguageSystemModel({required this.code, required this.text});

  factory LanguageSystemModel.fromJson(Map<String, dynamic> json) => _$LanguageSystemModelFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageSystemModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LanguageSystemCodeModel {
  String code;
  List<LanguageSystemModel> langs;

  LanguageSystemCodeModel({required this.code, required this.langs});

  factory LanguageSystemCodeModel.fromJson(Map<String, dynamic> json) => _$LanguageSystemCodeModelFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageSystemCodeModelToJson(this);
}

@JsonSerializable()
class ResponseDataModel {
  final List<dynamic> data;

  ResponseDataModel({
    required this.data,
  });

  factory ResponseDataModel.fromJson(Map<String, dynamic> json) => _$ResponseDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$ResponseDataModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LanguageModel {
  String? code;
  String? codeTranslator;
  String? name;
  bool? isuse;
  bool? isdefault;
  bool? isauto;
  bool? isdelete;

  LanguageModel({
    String? code,
    String? codeTranslator,
    String? name,
    bool? isuse,
    bool? isdefault,
    bool? isauto,
    bool? isdelete,
  })  : code = code ?? '',
        codeTranslator = codeTranslator ?? '',
        name = name ?? '',
        isuse = isuse ?? false,
        isdefault = isdefault ?? false,
        isauto = isauto ?? false,
        isdelete = isdelete ?? false;

  factory LanguageModel.fromJson(Map<String, dynamic> json) => _$LanguageModelFromJson(json);

  Map<String, dynamic> toJson() => _$LanguageModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LanguageDataModel {
  String code;
  String name;

  LanguageDataModel({required this.code, required this.name});

  factory LanguageDataModel.fromJson(Map<String, dynamic> json) => _$LanguageDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$LanguageDataModelToJson(this);
}

@JsonSerializable()
class ImagesModel {
  String uri;
  int xorder;

  ImagesModel({
    required this.uri,
    required this.xorder,
  });

  factory ImagesModel.fromJson(Map<String, dynamic> json) => _$ImagesModelFromJson(json);

  Map<String, dynamic> toJson() => _$ImagesModelToJson(this);
}

@JsonSerializable()
class ImageUpload {
  String uri;

  ImageUpload({
    required this.uri,
  });

  factory ImageUpload.fromJson(Map<String, dynamic> json) => _$ImageUploadFromJson(json);

  Map<String, dynamic> toJson() => _$ImageUploadToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XSortModel {
  String guidfixed;
  String code;
  int xorder;

  XSortModel({
    required this.guidfixed,
    required this.xorder,
    required this.code,
  });

  factory XSortModel.fromJson(Map<String, dynamic> json) => _$XSortModelFromJson(json);

  Map<String, dynamic> toJson() => _$XSortModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SortDataModel {
  String code;
  int xorder;

  SortDataModel({required this.code, required this.xorder});

  factory SortDataModel.fromJson(Map<String, dynamic> json) => _$SortDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$SortDataModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SearchCodeAndNameAndUnitModel {
  String barcode;
  String code;
  List<LanguageDataModel> name;
  String unitcode;
  List<LanguageDataModel> unitname;
  SearchCodeAndNameAndUnitModel({
    required this.barcode,
    required this.code,
    required this.name,
    required this.unitcode,
    required this.unitname,
  });

  factory SearchCodeAndNameAndUnitModel.fromJson(Map<String, dynamic> json) => _$SearchCodeAndNameAndUnitModelFromJson(json);

  Map<String, dynamic> toJson() => _$SearchCodeAndNameAndUnitModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DayOfWeekModel {
  String code;
  String? name;

  DayOfWeekModel({
    required this.code,
    String? name,
  }) : name = name ?? "";

  factory DayOfWeekModel.fromJson(Map<String, dynamic> json) => _$DayOfWeekModelFromJson(json);

  Map<String, dynamic> toJson() => _$DayOfWeekModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SearchGuidCodeNameModel {
  String guid;
  String code;
  List<LanguageDataModel> names;
  bool isCancel;
  SearchGuidCodeNameModel({required this.guid, required this.code, required this.names, this.isCancel = false});

  factory SearchGuidCodeNameModel.fromJson(Map<String, dynamic> json) => _$SearchGuidCodeNameModelFromJson(json);

  Map<String, dynamic> toJson() => _$SearchGuidCodeNameModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FiltterBarcodeModel {
  bool? branch;

  FiltterBarcodeModel({
    bool? branch,
  }) : branch = branch ?? false;

  factory FiltterBarcodeModel.fromJson(Map<String, dynamic> json) => _$FiltterBarcodeModelFromJson(json);

  Map<String, dynamic> toJson() => _$FiltterBarcodeModelToJson(this);
}
