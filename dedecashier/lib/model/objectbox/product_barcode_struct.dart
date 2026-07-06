import 'package:json_annotation/json_annotation.dart';
import 'package:objectbox/objectbox.dart';

part 'product_barcode_struct.g.dart';

@JsonSerializable()
@Entity()
class ProductBarcodeObjectBoxStruct {
  int id = 0;

  /// Barcode สินค้า
  @Unique()
  @Index(type: IndexType.hash)
  String barcode;

  /// ชื่อสินค้า
  @Index()
  String names;

  /// ชื่อสินค้าทั้งหมด (เอาไว้ค้นหา)
  @Index()
  String name_all;

  /// GUID อ้างอิง
  String guid_fixed;

  /// GUID อ้างอิง
  String item_guid;

  /// รายละเอียดสินค้า
  String descriptions;

  /// รหัสสินค้า
  @Index(type: IndexType.hash)
  String item_code;

  double unit_stand; // ตัวตั้ง
  double unit_divide; // ตัวหาร

  /// รหัสหน่วยนับ
  @Index(type: IndexType.hash)
  String unit_code = "";

  /// ชื่อหน่วยนับ
  @Index()
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

  /// ประเภทภาษี 1=มีภาษี,2=ไม่มีภาษี (ยกเว้น)
  int vat_type;

  /// สินค้าแบบอลาคาร์ท
  late bool isalacarte;

  /// ประเภทสินค้ายกเว้นภาษี (True=ยกเว้น,False=ไม่ยกเว้น)
  late bool is_except_vat;

  /// ประเภท (Buffet) JSON
  late String ordertypes;

  /// พิมพ์ใบจัดอาหารแบบแยกใบ
  late bool issplitunitprint;

  bool issumpoint;

  late int food_type;

  /// ใช้สินค้าในร้านอาหาร True=ใช้,False=ไม่ใช้ (สต๊อก)
  late bool is_resterant_use_stock;

  /// จำนวนสินค้าที่สั่ง ย้อนหลัง 7 วัน (เอาไว้เรียงลำดับสั่งอาหาร)
  double sum_order_qty = 0;

  /// อ้างอิง Barcode อื่น (หลายหน่วยนับ)
  String ref_barcode_json = "";

  /// รูปแบบสินค้า (Pattern)
  String patterncode = "";

  ProductBarcodeObjectBoxStruct({
    required this.barcode,
    required this.names,
    required this.name_all,
    required this.guid_fixed,
    required this.item_guid,
    required this.descriptions,
    required this.item_code,
    required this.unit_names,
    required this.prices,
    required this.new_line,
    required this.unit_code,
    required this.unit_stand,
    required this.unit_divide,
    required this.options_json,
    required this.images_url,
    required this.image_or_color,
    required this.color_select,
    required this.color_select_hex,
    required this.isalacarte,
    required this.ordertypes,
    required this.vat_type,
    required this.is_except_vat,
    required this.product_count,
    required this.issplitunitprint,
    required this.food_type,
    required this.ref_barcode_json,
    required this.patterncode,
    required this.is_resterant_use_stock,
    bool? issumpoint,
  }) : issumpoint = issumpoint ?? false;

  factory ProductBarcodeObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$ProductBarcodeObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$ProductBarcodeObjectBoxStructToJson(this);
}
