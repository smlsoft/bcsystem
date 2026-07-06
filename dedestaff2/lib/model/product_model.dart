import 'dart:convert';
import 'package:dedeorder/model/global_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductModel {
  final String guidfixed;

  ProductModel({
    required this.guidfixed,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}

@JsonSerializable()
class ProductResponseModel {
  final List<ProductFromServerModel> data;

  ProductResponseModel({
    required this.data,
  });

  factory ProductResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ProductResponseModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductResponseModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductFromServerModel {
  final String barcode;
  final String imageuri;
  final String itemunitname;
  final String itemunitcode;
  final List<ProductOptionModel> options;
  final List<ProductPriceFromServerModel> prices;

  ProductFromServerModel({
    required this.barcode,
    required this.imageuri,
    required this.itemunitname,
    required this.itemunitcode,
    required this.options,
    required this.prices,
  });

  factory ProductFromServerModel.fromJson(Map<String, dynamic> json) =>
      _$ProductFromServerModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductFromServerModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductPriceFromServerModel {
  final int keynumber;
  final double price;

  ProductPriceFromServerModel({
    required this.keynumber,
    required this.price,
  });

  factory ProductPriceFromServerModel.fromJson(Map<String, dynamic> json) =>
      _$ProductPriceFromServerModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductPriceFromServerModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductOptionModel {
  final String guid;
  final int choicetype;
  final int maxselect;
  final int minselect;
  final String name;
  final List<ProductOptionChoiceModel> choices;

  ProductOptionModel({
    required this.guid,
    required this.choicetype,
    required this.maxselect,
    required this.minselect,
    required this.name,
    required this.choices,
  });

  factory ProductOptionModel.fromJson(Map<String, dynamic> json) =>
      _$ProductOptionModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductOptionModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductOptionChoiceModel {
  final String guid;
  final List<LanguageNameModel> names;
  final String price;
  final double qty;

  ProductOptionChoiceModel({
    required this.guid,
    required this.names,
    required this.price,
    required this.qty,
  });

  factory ProductOptionChoiceModel.fromJson(Map<String, dynamic> json) =>
      _$ProductOptionChoiceModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductOptionChoiceModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductOrderTypeFromServerModel {
  final String code;
  final List<LanguageNameModel> names;
  final double price;

  ProductOrderTypeFromServerModel({
    required this.code,
    required this.names,
    required this.price,
  });

  factory ProductOrderTypeFromServerModel.fromJson(Map<String, dynamic> json) =>
      _$ProductOrderTypeFromServerModelFromJson(json);
  Map<String, dynamic> toJson() =>
      _$ProductOrderTypeFromServerModelToJson(this);
}

class ProductProcessModel {
  int type; // 0: product, 1: category
  String code;
  String barcode;
  String unitcode;
  String unitname;
  List<LanguageNameModel> names;
  double price;
  String imageuri;
  String refcategoryguid;
  double qty;
  List<ProductProcessOptionModel> options;
  String orderguid;
  String remark;
  bool isAlacarte;
  List<ProductOrderTypeFromServerModel> ordertypes;
  double totalAmount;
  bool takeAway;
  double sumOrderQty;

  ProductProcessModel({
    required this.type,
    required this.code,
    required this.barcode,
    required this.unitcode,
    required this.unitname,
    required this.names,
    required this.price,
    required this.imageuri,
    required this.refcategoryguid,
    required this.qty,
    required this.options,
    required this.orderguid,
    required this.remark,
    required this.isAlacarte,
    required this.ordertypes,
    required this.totalAmount,
    required this.takeAway,
    required this.sumOrderQty,
  });
}

@JsonSerializable(explicitToJson: true)
class ProductProcessOptionModel {
  final String guid;
  final int choicetype;
  final int maxselect;
  final int minselect;
  final List<LanguageNameModel> names;
  final List<ProductProcessOptionChoiceModel> choices;

  ProductProcessOptionModel({
    required this.guid,
    required this.choicetype,
    required this.maxselect,
    required this.minselect,
    required this.names,
    required this.choices,
  });

  factory ProductProcessOptionModel.fromJson(Map<String, dynamic> json) =>
      _$ProductProcessOptionModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductProcessOptionModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductProcessOptionChoiceModel {
  final String guid;
  final List<LanguageNameModel> names;
  final String price;
  final double qty;
  bool? selected;
  double? priceValue;

  ProductProcessOptionChoiceModel({
    required this.guid,
    required this.names,
    required this.price,
    required this.qty,
    required this.selected,
    required this.priceValue,
  });

  factory ProductProcessOptionChoiceModel.fromJson(Map<String, dynamic> json) =>
      _$ProductProcessOptionChoiceModelFromJson(json);
  Map<String, dynamic> toJson() =>
      _$ProductProcessOptionChoiceModelToJson(this);
}

@JsonSerializable()
class ProductBarcodeObjectBoxStruct {
  int id = 0;

  /// Barcode สินค้า
  String barcode;

  /// ชื่อสินค้า
  String names;

  /// ชื่อสินค้าทั้งหมด (เอาไว้ค้นหา)
  String name_all;

  /// GUID อ้างอิง
  String guid_fixed;

  /// GUID อ้างอิง
  String item_guid;

  /// รหัสสินค้า
  String item_code;

  /// รหัสหน่วยนับ
  String unit_code = "";

  /// ชื่อหน่วยนับ
  String unit_names;

  /// ราคาขายสินค้า
  String prices;

  /// ขึ้นบรรทัดใหม่
  int new_line;

  /// นับจำนวนที่เลือกแล้ว
  double product_count;

  /// ตัวเลือกพิเศษ ProductOptionStruct
  String options_json;

  /// รูปภาพสินค้า
  String images_url;

  /// ใช้รูปหรือสี True=Image,False=Color
  bool image_or_color;

  /// สีที่เลือก
  String color_select;

  /// สีที่เลือก (Hex)
  String color_select_hex;

  late bool isalacarte;

  late String ordertypes;

  /// จำนวนสินค้าที่สั่ง ย้อนหลัง 7 วัน (เอาไว้เรียงลำดับสั่งอาหาร)
  double sum_order_qty;

  ProductBarcodeObjectBoxStruct(
      {required this.barcode,
      required this.names,
      required this.name_all,
      required this.guid_fixed,
      required this.item_guid,
      required this.item_code,
      required this.unit_names,
      required this.prices,
      required this.new_line,
      required this.unit_code,
      required this.options_json,
      required this.images_url,
      required this.image_or_color,
      required this.color_select,
      required this.color_select_hex,
      required this.isalacarte,
      required this.ordertypes,
      required this.sum_order_qty,
      required this.product_count});

  List<ProductOptionModel> options() {
    try {
      return jsonDecode(options_json)
          .map<ProductOptionModel>((e) => ProductOptionModel.fromJson(e))
          .toList();
    } catch (e, s) {
      print("ProductBarcodeObjectBoxStruct.options:$e $s");
      return [];
    }
  }

  factory ProductBarcodeObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$ProductBarcodeObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$ProductBarcodeObjectBoxStructToJson(this);
}
