// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResponseDataModel _$ResponseDataModelFromJson(Map<String, dynamic> json) => ResponseDataModel(
      data: json['data'] as List<dynamic>,
    );

Map<String, dynamic> _$ResponseDataModelToJson(ResponseDataModel instance) => <String, dynamic>{
      'data': instance.data,
    };

LanguageSystemModel _$LanguageSystemModelFromJson(Map<String, dynamic> json) => LanguageSystemModel(
      code: json['code'] as String,
      text: json['text'] as String,
    );

Map<String, dynamic> _$LanguageSystemModelToJson(LanguageSystemModel instance) => <String, dynamic>{
      'code': instance.code,
      'text': instance.text,
    };

LanguageSystemCodeModel _$LanguageSystemCodeModelFromJson(Map<String, dynamic> json) => LanguageSystemCodeModel(
      code: json['code'] as String,
      langs: (json['langs'] as List<dynamic>).map((e) => LanguageSystemModel.fromJson(e as Map<String, dynamic>)).toList(),
    );

Map<String, dynamic> _$LanguageSystemCodeModelToJson(LanguageSystemCodeModel instance) => <String, dynamic>{
      'code': instance.code,
      'langs': instance.langs.map((e) => e.toJson()).toList(),
    };

LanguageModel _$LanguageModelFromJson(Map<String, dynamic> json) => LanguageModel(
      code: json['code'] as String?,
      codeTranslator: json['codeTranslator'] as String?,
      name: json['name'] as String?,
      isuse: json['isuse'] as bool?,
      isdefault: json['isdefault'] as bool?,
      isauto: json['isauto'] as bool?,
      isdelete: json['isdelete'] as bool?,
    );

Map<String, dynamic> _$LanguageModelToJson(LanguageModel instance) => <String, dynamic>{
      'code': instance.code,
      'codeTranslator': instance.codeTranslator,
      'name': instance.name,
      'isuse': instance.isuse,
      'isdefault': instance.isdefault,
      'isauto': instance.isauto,
      'isdelete': instance.isdelete,
    };

LanguageDataModel _$LanguageDataModelFromJson(Map<String, dynamic> json) => LanguageDataModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$LanguageDataModelToJson(LanguageDataModel instance) => <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };

ImagesModel _$ImagesModelFromJson(Map<String, dynamic> json) => ImagesModel(
      uri: json['uri'] as String,
      xorder: json['xorder'] as int,
    );

Map<String, dynamic> _$ImagesModelToJson(ImagesModel instance) => <String, dynamic>{
      'uri': instance.uri,
      'xorder': instance.xorder,
    };

ImageUpload _$ImageUploadFromJson(Map<String, dynamic> json) => ImageUpload(
      uri: json['uri'] as String,
    );

Map<String, dynamic> _$ImageUploadToJson(ImageUpload instance) => <String, dynamic>{
      'uri': instance.uri,
    };

XSortModel _$XSortModelFromJson(Map<String, dynamic> json) => XSortModel(
      guidfixed: json['guidfixed'] as String,
      xorder: json['xorder'] as int,
      code: json['code'] as String,
    );

Map<String, dynamic> _$XSortModelToJson(XSortModel instance) => <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'code': instance.code,
      'xorder': instance.xorder,
    };

SortDataModel _$SortDataModelFromJson(Map<String, dynamic> json) => SortDataModel(
      code: json['code'] as String,
      xorder: json['xorder'] as int,
    );

Map<String, dynamic> _$SortDataModelToJson(SortDataModel instance) => <String, dynamic>{
      'code': instance.code,
      'xorder': instance.xorder,
    };

SearchCodeAndNameAndUnitModel _$SearchCodeAndNameAndUnitModelFromJson(Map<String, dynamic> json) => SearchCodeAndNameAndUnitModel(
      barcode: json['barcode'] as String,
      code: json['code'] as String,
      name: (json['name'] as List<dynamic>).map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>)).toList(),
      unitcode: json['unitcode'] as String,
      unitname: (json['unitname'] as List<dynamic>).map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>)).toList(),
    );

Map<String, dynamic> _$SearchCodeAndNameAndUnitModelToJson(SearchCodeAndNameAndUnitModel instance) => <String, dynamic>{
      'barcode': instance.barcode,
      'code': instance.code,
      'name': instance.name.map((e) => e.toJson()).toList(),
      'unitcode': instance.unitcode,
      'unitname': instance.unitname.map((e) => e.toJson()).toList(),
    };

DayOfWeekModel _$DayOfWeekModelFromJson(Map<String, dynamic> json) => DayOfWeekModel(
      code: json['code'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$DayOfWeekModelToJson(DayOfWeekModel instance) => <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };

SearchGuidCodeNameModel _$SearchGuidCodeNameModelFromJson(Map<String, dynamic> json) => SearchGuidCodeNameModel(
      guid: json['guid'] as String,
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>).map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>)).toList(),
      isCancel: json['isCancel'] as bool? ?? false,
    );

Map<String, dynamic> _$SearchGuidCodeNameModelToJson(SearchGuidCodeNameModel instance) => <String, dynamic>{
      'guid': instance.guid,
      'code': instance.code,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'isCancel': instance.isCancel,
    };

FiltterBarcodeModel _$FiltterBarcodeModelFromJson(Map<String, dynamic> json) => FiltterBarcodeModel(
      branch: json['branch'] as bool?,
    );

Map<String, dynamic> _$FiltterBarcodeModelToJson(FiltterBarcodeModel instance) => <String, dynamic>{
      'branch': instance.branch,
    };
