import 'package:dedeorder/model/global_model.dart';
import 'package:dedeorder/model/product_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart';

class StaffCategoryModel {
  late String guidfixed;
  late String parentguid;
  late String imageuri;
  late List<LanguageNameModel> names;
  late List<ProductProcessModel> products;
  late int xorder;
}

@JsonSerializable()
class StaffCategoryResponseMainModel {
  final List<StaffCategoryResponseModel> data;

  StaffCategoryResponseMainModel({
    required this.data,
  });

  factory StaffCategoryResponseMainModel.fromJson(Map<String, dynamic> json) =>
      _$StaffCategoryResponseMainModelFromJson(json);
  Map<String, dynamic> toJson() => _$StaffCategoryResponseMainModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class StaffCategoryResponseModel {
  final String guidfixed;
  final int childcount;
  final String parentguid;
  final String parentguidall;
  final String imageuri;
  final String name;
  final List<StaffXSortModel> xsorts;
  final List<StaffCategoryCodeListModel> codelist;
  final bool useimageorcolor;
  final String colorselecthex;
  final bool isdisabled;

  StaffCategoryResponseModel({
    required this.guidfixed,
    required this.childcount,
    required this.parentguid,
    required this.parentguidall,
    required this.imageuri,
    required this.name,
    required this.xsorts,
    required this.codelist,
    required this.useimageorcolor,
    required this.colorselecthex,
    required this.isdisabled,
  });

  factory StaffCategoryResponseModel.fromJson(Map<String, dynamic> json) =>
      _$StaffCategoryResponseModelFromJson(json);
  Map<String, dynamic> toJson() => _$StaffCategoryResponseModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class StaffXSortModel {
  final String code;
  final int xorder;

  StaffXSortModel({
    required this.code,
    required this.xorder,
  });

  factory StaffXSortModel.fromJson(Map<String, dynamic> json) =>
      _$StaffXSortModelFromJson(json);
  Map<String, dynamic> toJson() => _$StaffXSortModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class StaffCategoryCodeListModel {
  final String code;
  final int xorder;
  final String barcode;
  final String unitcode;
  final String unitname;
  final String name;

  StaffCategoryCodeListModel({
    required this.code,
    required this.xorder,
    required this.barcode,
    required this.unitcode,
    required this.unitname,
    required this.name,
  });

  factory StaffCategoryCodeListModel.fromJson(Map<String, dynamic> json) =>
      _$StaffCategoryCodeListModelFromJson(json);
  Map<String, dynamic> toJson() => _$StaffCategoryCodeListModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class StaffCategoryProductResponseModel {
  final String code;
  final String barcode;
  final String unitcode;
  late String unitname;
  final String name;
  final List<double> prices;
  late String imageuri;

  StaffCategoryProductResponseModel(
      {required this.code,
      required this.barcode,
      required this.unitcode,
      required this.unitname,
      required this.name,
      required this.prices,
      required this.imageuri});

  factory StaffCategoryProductResponseModel.fromJson(
          Map<String, dynamic> json) =>
      _$StaffCategoryProductResponseModelFromJson(json);
  Map<String, dynamic> toJson() =>
      _$StaffCategoryProductResponseModelToJson(this);
}

@JsonSerializable()
class ProductCategoryCodeObjectBoxStruct {
  String code;
  List<LanguageNameModel> names;

  ProductCategoryCodeObjectBoxStruct({required this.code, required this.names});

  factory ProductCategoryCodeObjectBoxStruct.fromJson(
          Map<String, dynamic> json) =>
      _$ProductCategoryCodeObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() =>
      _$ProductCategoryCodeObjectBoxStructToJson(this);
}

@JsonSerializable()
class ProductCategoryObjectBoxStruct {
  String guid_fixed;

  String parent_guid_fixed;

  /// ชื่อกลุ่มสินค้า (ภาษา 1)
  String names;

  /// url รูปภาพกลุ่มสินค้า
  String image_url;

  /// True=Image,False=Color
  bool use_image_or_color;

  /// สีที่เลือก
  String colorselect;

  /// สีที่เลือก (Hex)
  String colorselecthex;

  // Json รายการสินค้าย่อย
  String codelist;

  int xorder;

  int category_count;

  ProductCategoryObjectBoxStruct(
      {required this.guid_fixed,
      required this.parent_guid_fixed,
      required this.names,
      required this.image_url,
      required this.category_count,
      required this.use_image_or_color,
      required this.xorder,
      required this.colorselect,
      required this.colorselecthex,
      required this.codelist});

  factory ProductCategoryObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$ProductCategoryObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$ProductCategoryObjectBoxStructToJson(this);
}
