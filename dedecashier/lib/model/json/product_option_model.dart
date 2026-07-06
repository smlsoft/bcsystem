// ignore_for_file: non_constant_identifier_names

import 'package:dedecashier/global_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_option_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductOptionModel {
  /// GUID อ้างอิง
  String guid;

  /// ประเภทข้อเลือก (0=Check Box,1=Radio Button)
  int choicetype = 0;

  /// เลือกได้สูงสุด กรณี Check Box
  int maxselect = 0;

  /// ชื่อข้อเลือก Multi Language
  List<LanguageDataModel> names;

  /// รายการข้อเลือก ProductChoiceStruct
  List<ProductChoiceModel> choices;

  /// ตัวเลือกที่เลือก
  int? select_index = 0;

  ProductOptionModel({required this.guid, required this.choicetype, required this.maxselect, required this.names, required this.choices});

  factory ProductOptionModel.fromJson(Map<String, dynamic> json) => _$ProductOptionModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductOptionModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductChoiceModel {
  /// GUID (ดึงจาก API)
  String guid;

  /// ชื่อข้อเลือก Multi Language
  List<LanguageDataModel> names;

  /// ราคาขาย (คิดเพิ่ม)
  String price;

  // GUID Code เชื่อมไปยัง Extra Process
  String? guidcode;

  /// ข้อเลือกแรก
  bool? isdefault;

  /// ตัดสต๊อก
  bool? isstock;

  /// Barcode สินค้า (กรณีมีการตัดสต๊อก)
  String? refbarcode;

  /// รหัสสินค้า (กรณีมีการตัดสต๊อก)
  String? refproductcode;

  /// รหัสหน่วยนับ (กรณีมีการตัดสต๊อก)
  String? refunitcode;

  String? barcode;

  List<LanguageDataModel> refunitnames;

  /// จำนวนตัดสต๊อก (กรณีมีการตัดสต๊อก)
  double qty;

  /// เลือกแล้ว กรณีเป็น check box (True/False)
  bool? selected;

  ProductChoiceModel({
    required this.guid,
    required this.refproductcode,
    required this.isdefault,
    required this.refunitcode,
    required this.barcode,
    required this.names,
    required this.guidcode,
    required this.price,
    required this.qty,
    required this.isstock,
    required this.selected,
    String? refbarcode,
    List<LanguageDataModel>? refunitnames,
  })  : refbarcode = refbarcode ?? '',
        refunitnames = refunitnames ?? <LanguageDataModel>[];

  factory ProductChoiceModel.fromJson(Map<String, dynamic> json) => _$ProductChoiceModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductChoiceModelToJson(this);
}
