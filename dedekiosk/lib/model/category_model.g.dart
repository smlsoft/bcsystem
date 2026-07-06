// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) =>
    CategoryModel(
      xsorts: (json['xsorts'] as List<dynamic>)
          .map((e) => XSortModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      guidfixed: json['guidfixed'] as String,
      parentguid: json['parentguid'] as String,
      imageuri: json['imageuri'] as String,
      coveruri: json['coveruri'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      codelist: (json['codelist'] as List<dynamic>)
          .map((e) => CategoryCodeListModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeforsales: (json['timeforsales'] as List<dynamic>)
          .map((e) =>
              CategoryTimeForSaleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CategoryModelToJson(CategoryModel instance) =>
    <String, dynamic>{
      'xsorts': instance.xsorts.map((e) => e.toJson()).toList(),
      'guidfixed': instance.guidfixed,
      'parentguid': instance.parentguid,
      'imageuri': instance.imageuri,
      'coveruri': instance.coveruri,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'codelist': instance.codelist.map((e) => e.toJson()).toList(),
      'timeforsales': instance.timeforsales.map((e) => e.toJson()).toList(),
    };

CategoryResponseMainModel _$CategoryResponseMainModelFromJson(
        Map<String, dynamic> json) =>
    CategoryResponseMainModel(
      data: (json['data'] as List<dynamic>)
          .map((e) => CategoryResponseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CategoryResponseMainModelToJson(
        CategoryResponseMainModel instance) =>
    <String, dynamic>{
      'data': instance.data.map((e) => e.toJson()).toList(),
    };

CategoryTimeForSaleModel _$CategoryTimeForSaleModelFromJson(
        Map<String, dynamic> json) =>
    CategoryTimeForSaleModel(
      fromtime: json['fromtime'] as String,
      totime: json['totime'] as String,
    );

Map<String, dynamic> _$CategoryTimeForSaleModelToJson(
        CategoryTimeForSaleModel instance) =>
    <String, dynamic>{
      'fromtime': instance.fromtime,
      'totime': instance.totime,
    };

CategoryResponseModel _$CategoryResponseModelFromJson(
        Map<String, dynamic> json) =>
    CategoryResponseModel(
      guidfixed: json['guidfixed'] as String,
      childcount: (json['childcount'] as num).toInt(),
      parentguid: json['parentguid'] as String,
      parentguidall: json['parentguidall'] as String,
      imageuri: json['imageuri'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      xsorts: (json['xsorts'] as List<dynamic>)
          .map((e) => XSortModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      codelist: (json['codelist'] as List<dynamic>)
          .map((e) => CategoryCodeListModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      useimageorcolor: json['useimageorcolor'] as bool,
      colorselecthex: json['colorselecthex'] as String,
      isdisabled: json['isdisabled'] as bool,
      coveruri: json['coveruri'] as String,
      timeforsales: (json['timeforsales'] as List<dynamic>?)
          ?.map((e) =>
              CategoryTimeForSaleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CategoryResponseModelToJson(
        CategoryResponseModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'childcount': instance.childcount,
      'parentguid': instance.parentguid,
      'parentguidall': instance.parentguidall,
      'imageuri': instance.imageuri,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'xsorts': instance.xsorts.map((e) => e.toJson()).toList(),
      'codelist': instance.codelist.map((e) => e.toJson()).toList(),
      'useimageorcolor': instance.useimageorcolor,
      'colorselecthex': instance.colorselecthex,
      'isdisabled': instance.isdisabled,
      'coveruri': instance.coveruri,
      'timeforsales': instance.timeforsales?.map((e) => e.toJson()).toList(),
    };

LanguageNameModel _$LanguageNameModelFromJson(Map<String, dynamic> json) =>
    LanguageNameModel(
      code: json['code'] as String,
      name: json['name'] as String,
      isauto: json['isauto'] as bool?,
      isdelete: json['isdelete'] as bool?,
    );

Map<String, dynamic> _$LanguageNameModelToJson(LanguageNameModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'isauto': instance.isauto,
      'isdelete': instance.isdelete,
    };

XSortModel _$XSortModelFromJson(Map<String, dynamic> json) => XSortModel(
      code: json['code'] as String,
      xorder: (json['xorder'] as num).toInt(),
    );

Map<String, dynamic> _$XSortModelToJson(XSortModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'xorder': instance.xorder,
    };

CategoryCodeListModel _$CategoryCodeListModelFromJson(
        Map<String, dynamic> json) =>
    CategoryCodeListModel(
      code: json['code'] as String,
      xorder: (json['xorder'] as num).toInt(),
      barcode: json['barcode'] as String,
      unitcode: json['unitcode'] as String,
      unitnames: (json['unitnames'] as List<dynamic>?)
          ?.map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageurl: json['imageurl'] as String?,
      manufacturerguid: json['manufacturerguid'] as String?,
    )
      ..prices = (json['prices'] as List<dynamic>?)
          ?.map((e) =>
              ProductPriceFromServerModel.fromJson(e as Map<String, dynamic>))
          .toList()
      ..setprice = (json['setprice'] as num?)?.toDouble()
      ..orderqty = (json['orderqty'] as num?)?.toDouble()
      ..useoption = json['useoption'] as bool?
      ..discountword = json['discountword'] as String?;

Map<String, dynamic> _$CategoryCodeListModelToJson(
        CategoryCodeListModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'xorder': instance.xorder,
      'barcode': instance.barcode,
      'unitcode': instance.unitcode,
      'unitnames': instance.unitnames.map((e) => e.toJson()).toList(),
      'names': instance.names.map((e) => e.toJson()).toList(),
      'imageurl': instance.imageurl,
      'prices': instance.prices?.map((e) => e.toJson()).toList(),
      'setprice': instance.setprice,
      'orderqty': instance.orderqty,
      'useoption': instance.useoption,
      'discountword': instance.discountword,
      'manufacturerguid': instance.manufacturerguid,
    };

CategoryProductResponseModel _$CategoryProductResponseModelFromJson(
        Map<String, dynamic> json) =>
    CategoryProductResponseModel(
      code: json['code'] as String,
      barcode: json['barcode'] as String,
      unitcode: json['unitcode'] as String,
      unitnames: (json['unitnames'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      prices: (json['prices'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      imageuri: json['imageuri'] as String,
    );

Map<String, dynamic> _$CategoryProductResponseModelToJson(
        CategoryProductResponseModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'barcode': instance.barcode,
      'unitcode': instance.unitcode,
      'unitnames': instance.unitnames.map((e) => e.toJson()).toList(),
      'names': instance.names.map((e) => e.toJson()).toList(),
      'prices': instance.prices,
      'imageuri': instance.imageuri,
    };
