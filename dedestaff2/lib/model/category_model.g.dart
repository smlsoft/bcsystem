// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffCategoryResponseMainModel _$StaffCategoryResponseMainModelFromJson(
        Map<String, dynamic> json) =>
    StaffCategoryResponseMainModel(
      data: (json['data'] as List<dynamic>)
          .map((e) =>
              StaffCategoryResponseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StaffCategoryResponseMainModelToJson(
        StaffCategoryResponseMainModel instance) =>
    <String, dynamic>{
      'data': instance.data,
    };

StaffCategoryResponseModel _$StaffCategoryResponseModelFromJson(
        Map<String, dynamic> json) =>
    StaffCategoryResponseModel(
      guidfixed: json['guidfixed'] as String,
      childcount: (json['childcount'] as num).toInt(),
      parentguid: json['parentguid'] as String,
      parentguidall: json['parentguidall'] as String,
      imageuri: json['imageuri'] as String,
      name: json['name'] as String,
      xsorts: (json['xsorts'] as List<dynamic>)
          .map((e) => StaffXSortModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      codelist: (json['codelist'] as List<dynamic>)
          .map((e) =>
              StaffCategoryCodeListModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      useimageorcolor: json['useimageorcolor'] as bool,
      colorselecthex: json['colorselecthex'] as String,
      isdisabled: json['isdisabled'] as bool,
    );

Map<String, dynamic> _$StaffCategoryResponseModelToJson(
        StaffCategoryResponseModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'childcount': instance.childcount,
      'parentguid': instance.parentguid,
      'parentguidall': instance.parentguidall,
      'imageuri': instance.imageuri,
      'name': instance.name,
      'xsorts': instance.xsorts.map((e) => e.toJson()).toList(),
      'codelist': instance.codelist.map((e) => e.toJson()).toList(),
      'useimageorcolor': instance.useimageorcolor,
      'colorselecthex': instance.colorselecthex,
      'isdisabled': instance.isdisabled,
    };

StaffXSortModel _$StaffXSortModelFromJson(Map<String, dynamic> json) =>
    StaffXSortModel(
      code: json['code'] as String,
      xorder: (json['xorder'] as num).toInt(),
    );

Map<String, dynamic> _$StaffXSortModelToJson(StaffXSortModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'xorder': instance.xorder,
    };

StaffCategoryCodeListModel _$StaffCategoryCodeListModelFromJson(
        Map<String, dynamic> json) =>
    StaffCategoryCodeListModel(
      code: json['code'] as String,
      xorder: (json['xorder'] as num).toInt(),
      barcode: json['barcode'] as String,
      unitcode: json['unitcode'] as String,
      unitname: json['unitname'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$StaffCategoryCodeListModelToJson(
        StaffCategoryCodeListModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'xorder': instance.xorder,
      'barcode': instance.barcode,
      'unitcode': instance.unitcode,
      'unitname': instance.unitname,
      'name': instance.name,
    };

StaffCategoryProductResponseModel _$StaffCategoryProductResponseModelFromJson(
        Map<String, dynamic> json) =>
    StaffCategoryProductResponseModel(
      code: json['code'] as String,
      barcode: json['barcode'] as String,
      unitcode: json['unitcode'] as String,
      unitname: json['unitname'] as String,
      name: json['name'] as String,
      prices: (json['prices'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      imageuri: json['imageuri'] as String,
    );

Map<String, dynamic> _$StaffCategoryProductResponseModelToJson(
        StaffCategoryProductResponseModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'barcode': instance.barcode,
      'unitcode': instance.unitcode,
      'unitname': instance.unitname,
      'name': instance.name,
      'prices': instance.prices,
      'imageuri': instance.imageuri,
    };

ProductCategoryCodeObjectBoxStruct _$ProductCategoryCodeObjectBoxStructFromJson(
        Map<String, dynamic> json) =>
    ProductCategoryCodeObjectBoxStruct(
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductCategoryCodeObjectBoxStructToJson(
        ProductCategoryCodeObjectBoxStruct instance) =>
    <String, dynamic>{
      'code': instance.code,
      'names': instance.names,
    };

ProductCategoryObjectBoxStruct _$ProductCategoryObjectBoxStructFromJson(
        Map<String, dynamic> json) =>
    ProductCategoryObjectBoxStruct(
      guid_fixed: json['guid_fixed'] as String,
      parent_guid_fixed: json['parent_guid_fixed'] as String,
      names: json['names'] as String,
      image_url: json['image_url'] as String,
      category_count: (json['category_count'] as num).toInt(),
      use_image_or_color: json['use_image_or_color'] as bool,
      xorder: (json['xorder'] as num).toInt(),
      colorselect: json['colorselect'] as String,
      colorselecthex: json['colorselecthex'] as String,
      codelist: json['codelist'] as String,
    );

Map<String, dynamic> _$ProductCategoryObjectBoxStructToJson(
        ProductCategoryObjectBoxStruct instance) =>
    <String, dynamic>{
      'guid_fixed': instance.guid_fixed,
      'parent_guid_fixed': instance.parent_guid_fixed,
      'names': instance.names,
      'image_url': instance.image_url,
      'use_image_or_color': instance.use_image_or_color,
      'colorselect': instance.colorselect,
      'colorselecthex': instance.colorselecthex,
      'codelist': instance.codelist,
      'xorder': instance.xorder,
      'category_count': instance.category_count,
    };
