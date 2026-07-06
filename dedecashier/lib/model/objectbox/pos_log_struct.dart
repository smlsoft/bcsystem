// ignore_for_file: non_constant_identifier_names

import 'package:uuid/uuid.dart';
import 'package:objectbox/objectbox.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pos_log_struct.g.dart';

@JsonSerializable(explicitToJson: true)
@Entity()
class PosLogObjectBoxStruct {
  int id;

  /// GUID Log
  @Unique()
  @Index(type: IndexType.hash)
  String guid_auto_fixed = "";

  /// ประเภทเอกสาร (1 = ขาย, 2 = คืน)
  @Index()
  int doc_mode;

  /// อ้างอิงในระบบ
  @Index(type: IndexType.hash)
  String guid_ref;

  /// รหัสอ้างอิง (สร้างอัตโนมัติ) เช่น กลุ่มตัวเลือก
  @Index(type: IndexType.hash)
  String guid_code_ref;

  /// วันที่+เวลา
  @Property(type: PropertyType.date)
  @Index()
  DateTime log_date_time;

  /// รหัสการพักบิล
  @Index(type: IndexType.hash)
  String hold_code;

  /// คำสั่ง (หมายเหตุด้านล่าง)
  @Index()
  int command_code;

  /// ยกเลิกแล้ว
  @Index()
  int is_void;

  /// สำเร็จแล้ว
  @Index()
  int success;

  bool issumpoint;

  /// รหัสเพิ่มเติม
  String extra_code;

  /// หมายเหตุ
  String remark;

  /// ส่วนลด Text เช่น ลด 10%+5 บาท+6%=(10%,5,6%)
  String discount_text;

  /// รหัสสินค้า
  @Index(type: IndexType.hash)
  String code;

  /// ราคา
  double price;

  /// ชื่อสินค้า
  @Index()
  String name;

  /// จำนวน
  double qty;

  /// จำนวนสูงสุด
  double qty_fixed;

  /// รหัสสินค้า (Default) งง
  String default_code;

  /// เลือกแล้ว
  bool selected;

  /// รหัสหน่วยนับ
  @Index(type: IndexType.hash)
  String unit_code;

  /// ตัวตั้ง
  double unit_stand;

  /// ตัวหาร
  double unit_divide;

  /// ชื่อหน่วยนับ
  @Index()
  String unit_name;

  /// Barcode
  @Index(type: IndexType.hash)
  String barcode;

  /// exclude vat (ราคาไม่รวมภาษี True=ไม่รวมภาษี, False=รวมภาษี)
  bool price_exclude_vat_type;

  /// สินค้ายกเว้นภาษี (True=ยกเว้นภาษี,False=ไม่ยกเว้นภาษี)
  bool is_except_vat;

  /// ราคาไม่รวมภาษี
  double price_exclude_vat;

  String refbarcode;

  String refunitcode;

  /* 
      -- command
      1=เพิ่มสินค้า
      2=เพิ่มจำนวน + 1
      3=ลดจำนวน - 1
      4=แก้จำนวน
      5=แก้ราคา
      6=แก้ส่วนลด
      8=หมายเหตุ
      9=ลบรายการสินค้า
      80=เปิดลิ้นชัก
      99=เริ่มใหม่
      100=Radio Extra
      101=Check Box Extra
  */

  PosLogObjectBoxStruct({
    this.id = 0,
    this.doc_mode = 1,
    this.guid_ref = "",
    this.guid_code_ref = "",
    required this.log_date_time,
    required this.hold_code,
    required this.command_code,
    this.barcode = "",
    this.is_void = 0,
    this.success = 0,
    this.qty = 0,
    this.qty_fixed = 0,
    this.price = 0,
    this.selected = false,
    this.remark = "",
    this.name = "",
    this.code = "",
    this.default_code = "",
    this.discount_text = "",
    this.extra_code = "",
    this.unit_code = "",
    this.unit_stand = 1,
    this.unit_divide = 1,
    this.unit_name = "",
    this.price_exclude_vat_type = false,
    this.is_except_vat = false,
    this.price_exclude_vat = 0,
    String? refbarcode,
    String? refunitcode,
    String? guid_auto_fixed,
    bool? issumpoint = false,
  }) : guid_auto_fixed = guid_auto_fixed ?? const Uuid().v4(),
       refbarcode = refbarcode ?? "",
       refunitcode = refunitcode ?? "",
       issumpoint = issumpoint ?? false;

  factory PosLogObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$PosLogObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$PosLogObjectBoxStructToJson(this);
}
