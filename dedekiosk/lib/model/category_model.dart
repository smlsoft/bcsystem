import 'package:dedekiosk/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CategoryModel {
  final List<XSortModel> xsorts;
  final String guidfixed;
  final String parentguid;
  final String imageuri;
  final String coveruri;
  final List<LanguageNameModel> names;
  final List<CategoryCodeListModel> codelist;
  final List<CategoryTimeForSaleModel> timeforsales;

  CategoryModel({
    required this.xsorts,
    required this.guidfixed,
    required this.parentguid,
    required this.imageuri,
    required this.coveruri,
    required this.names,
    required this.codelist,
    required this.timeforsales,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => _$CategoryModelFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CategoryResponseMainModel {
  final List<CategoryResponseModel> data;

  CategoryResponseMainModel({
    required this.data,
  });

  factory CategoryResponseMainModel.fromJson(Map<String, dynamic> json) => _$CategoryResponseMainModelFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryResponseMainModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CategoryTimeForSaleModel {
  final String fromtime;
  final String totime;

  CategoryTimeForSaleModel({
    required this.fromtime,
    required this.totime,
  });

  factory CategoryTimeForSaleModel.fromJson(Map<String, dynamic> json) => _$CategoryTimeForSaleModelFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryTimeForSaleModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CategoryResponseModel {
  final String guidfixed;
  final int childcount;
  final String parentguid;
  final String parentguidall;
  final String imageuri;
  final List<LanguageNameModel> names;
  final List<XSortModel> xsorts;
  final List<CategoryCodeListModel> codelist;
  final bool useimageorcolor;
  final String colorselecthex;
  final bool isdisabled;
  final String coveruri;
  final List<CategoryTimeForSaleModel>? timeforsales;

  CategoryResponseModel({
    required this.guidfixed,
    required this.childcount,
    required this.parentguid,
    required this.parentguidall,
    required this.imageuri,
    required this.names,
    required this.xsorts,
    required this.codelist,
    required this.useimageorcolor,
    required this.colorselecthex,
    required this.isdisabled,
    required this.coveruri,
    required this.timeforsales,
  });

  factory CategoryResponseModel.fromJson(Map<String, dynamic> json) => _$CategoryResponseModelFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryResponseModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LanguageNameModel {
  final String code;
  final String name;
  final bool isauto;
  final bool isdelete;

  LanguageNameModel({
    required this.code,
    required this.name,
    bool? isauto,
    bool? isdelete,
  })  : isauto = isauto ?? false,
        isdelete = isdelete ?? false;

  factory LanguageNameModel.fromJson(Map<String, dynamic> json) => _$LanguageNameModelFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageNameModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class XSortModel {
  final String code;
  final int xorder;

  XSortModel({
    required this.code,
    required this.xorder,
  });

  factory XSortModel.fromJson(Map<String, dynamic> json) => _$XSortModelFromJson(json);
  Map<String, dynamic> toJson() => _$XSortModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CategoryCodeListModel {
  final String code;
  final int xorder;
  final String barcode;
  final String unitcode;
  List<LanguageNameModel> unitnames;
  List<LanguageNameModel> names;
  late String imageurl;
  late List<ProductPriceFromServerModel>? prices;
  late double? setprice;
  late double? orderqty;
  late bool? useoption;
  late String? discountword;
  String manufacturerguid;

  CategoryCodeListModel({
    required this.code,
    required this.xorder,
    required this.barcode,
    required this.unitcode,
    List<LanguageNameModel>? unitnames,
    List<LanguageNameModel>? names,
    String? imageurl,
    String? manufacturerguid,
  })  : prices = [],
        setprice = 0,
        orderqty = 0,
        discountword = "",
        useoption = false,
        imageurl = imageurl ?? "",
        unitnames = unitnames ?? [LanguageNameModel(code: "th", name: "หน่วย", isauto: true, isdelete: false)],
        names = names ?? [LanguageNameModel(code: "th", name: "ไม่มีชื่อ", isauto: true, isdelete: false)],
        manufacturerguid = manufacturerguid ?? "";

  factory CategoryCodeListModel.fromJson(Map<String, dynamic> json) => _$CategoryCodeListModelFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryCodeListModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CategoryProductResponseModel {
  final String code;
  final String barcode;
  final String unitcode;
  late List<LanguageNameModel> unitnames;
  final List<LanguageNameModel> names;
  final List<double> prices;
  late String imageuri;

  CategoryProductResponseModel(
      {required this.code, required this.barcode, required this.unitcode, required this.unitnames, required this.names, required this.prices, required this.imageuri});

  factory CategoryProductResponseModel.fromJson(Map<String, dynamic> json) => _$CategoryProductResponseModelFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryProductResponseModelToJson(this);
}
