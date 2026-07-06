// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'promotion_model.g.dart';

@JsonSerializable()
class PromotionMainModel {
  final List<PromotionModel> promotion_list;

  PromotionMainModel({required this.promotion_list});

  factory PromotionMainModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionMainModelFromJson(json);

  Map<String, dynamic> toJson() => _$PromotionMainModelToJson(this);
}

@JsonSerializable()
class PromotionModel {
  /*
  ประเภท Promotion พร้อมตัวอย่าง
  การคำนวณโปรโมชั่น ใช้อัตราส่วนหน่วยนับ (Unit Ratio) ในการแปลงหน่วย
  1 = แถมสินค้า เมื่อซื้อสินค้าครบตามจำนวน
     ตัวอย่าง 1: ซื้อปูนซีเมนต์ครบ 50 ถุง แถมฟรี 5 ถุง
     ตัวอย่าง 2: ซื้อสีน้ำภายนอกครบ 3 ถัง แถมฟรี 1 ถัง
     ตัวอย่าง 3: ซื้อกระเบื้องปูพื้นครบ 100 แผ่น แถมฟรี 10 แผ่น

  2 = ส่วนลดเงินสด หรือเปอร์เซ็นต์ เมื่อซื้อครบตามจำนวน
     ตัวอย่าง 1: ซื้อวัสดุก่อสร้างครบ 50,000 บาท รับส่วนลด 15% หรือ 7,500 บาท
     ตัวอย่าง 2: ซื้อสุขภัณฑ์ครบ 20,000 บาท รับส่วนลด 2,000 บาท หรือ 10%
     ตัวอย่าง 3: ซื้อเหล็กเส้นครบ 100,000 บาท รับส่วนลด 20% หรือ 20,000 บาท

  3 = ซื้อสินค้าตาม List แล้วแถมสินค้าตาม List
      ตัวอย่าง 1: ซื้อโถสุขภัณฑ์ 1 ชุด แถมฝารองนั่ง 1 อัน
      ตัวอย่าง 2: ซื้อสีรองพื้นปูน 1 ถัง แถมลูกกลิ้งทาสี 1 ชุด
      ตัวอย่าง 3: ซื้อก๊อกน้ำอ่างล้างหน้า 1 ชุด แถมสายน้ำดี 1 เส้น

  4 = ราคาพิเศษ เมื่อซื้อครบตามจำนวน
     ตัวอย่าง 1: ซื้อปูนซีเมนต์ 100 ถุง ราคาพิเศษเหลือถุงละ 120 บาท (ปกติ 150 บาท)
     ตัวอย่าง 2: ซื้อกระเบื้องมุงหลังคา 1,000 แผ่น ราคาพิเศษเหลือแผ่นละ 45 บาท (ปกติ 55 บาท)
     ตัวอย่าง 3: ซื้อเหล็กเส้น 100 เส้น ราคาพิเศษเหลือเส้นละ 180 บาท (ปกติ 220 บาท) 

  5 = ซื้อครบตามจำนวน ลดเปอร์เซ็นต์หรือจำนวนเงิน
     ตัวอย่าง 1: ซื้อวัสดุก่อสร้างครบ 30,000 บาท ลดเพิ่มอีก 8% หรือ 2,400 บาท
     ตัวอย่าง 2: ซื้อสุขภัณฑ์ครบ 50,000 บาท ลดเพิ่มอีก 12% หรือ 6,000 บาท
     ตัวอย่าง 3: ซื้อวัสดุมุงหลังคาครบ 100,000 บาท ลดเพิ่มอีก 15% หรือ 15,000 บาท

  6 = ซื้อครบ xxx บาท แถมสินค้า xx ชิ้น
     ตัวอย่าง 1: ซื้อสินค้าครบ 10,000 บาท แถมชุดเครื่องมือช่าง 1 ชุด
     ตัวอย่าง 2: ซื้อสินค้าครบ 30,000 บาท แถมปั๊มน้ำอัตโนมัติ 1 เครื่อง
     ตัวอย่าง 3: ซื้อสินค้าครบ 50,000 บาท แถมเครื่องฉีดน้ำแรงดันสูง 1 เครื่อง

  7 = ซื้อบิลครบ xxx บาท ส่วนลดเพิ่มอีก xxx บาท หรือ x%
     ตัวอย่าง 1: ซื้อสินค้าครบ 25,000 บาท รับส่วนลดเพิ่ม 3,000 บาท หรือ 12%
     ตัวอย่าง 2: ซื้อสินค้าครบ 40,000 บาท รับส่วนลดเพิ่ม 6,000 บาท หรือ 15%
     ตัวอย่าง 3: ซื้อสินค้าครบ 80,000 บาท รับส่วนลดเพิ่ม 12,000 บาท หรือ 18%

  8 = ซื้อบิลครบ xxx บาท ได้สินค้ารางวัล (Bonus)
     ตัวอย่าง 1: ซื้อสินค้าครบ 20,000 บาท รับฟรี! เครื่องเจียร์ไฟฟ้า มูลค่า 2,590 บาท
     ตัวอย่าง 2: ซื้อสินค้าครบ 35,000 บาท รับฟรี! สว่านไร้สาย 18V มูลค่า 4,990 บาท
     ตัวอย่าง 3: ซื้อสินค้าครบ 50,000 บาท รับฟรี! เครื่องปั๊มน้ำอัตโนมัติ มูลค่า 8,900 บาท

  101 : Marin App Promotion
     ซื้อสินค้า House Brand ครบ xxx บาท ได้รับคูปองหมุนวงล้อชิงรางวัล ให้แสดงท้ายใบเสร็จ เพราะเอาไปแลกเองที่ Counter
     field formatcode = house brand


  
  1.ข้อความท้ายใบเสร็จ
 เงือนไข : 
- ซื้อกลุ่มสินค้า HB ครบ 2000 ได้สิทธิ์หมุนกรงล้อ
- กำหนดเวลา ได้รับคูปอง วันที่ 25/10/2568

2.โปรโมชั่น ราคาพิเศษ
เงือนไข : 
- เมื่อซื้อรหัสสินค้า : หน่วยนับ ที่กำหนด ต้องได้ราคาโปรโมชั่น
- กำหนดเวลา ได้รับโปรโมชั่น 25/10/2568 - 31/12/2568

3.โปรโมชั่นตาม Tier (ข้อความท้ายใบเสร็จ แลกของแถม)
เงือนไข :
- เมื่อซื้อรหัสสินค้า : หน่วยนับ ที่กำหนด ครบมูลค่าตาม Tier จะได้สิทธิแลกของ
- กำหนด จำนวนครั้ง ที่ได้แลกของ ได้
- กำหนด ลำดับความสำคัญ (ว่าจะต้องเข้า Tier ไหนก่อน)
- กำหนดเวลา ได้รับโปรโมชั่น 25/10/2568 - 31/12/2568
*/

  final int type;
  // ลำดับ Promotion
  final int index;
  // รหัส Promotion
  final String promotion_code;
  // วันที่เริ่มต้น
  final DateTime date_begin;
  // วันที่สิ้นสุด
  final DateTime date_end;
  // ชื่อ Promotion
  final String promotion_name;
  // สำหรับสมาชิกเท่านั้น
  final int customer_only;
  // ข้อความส่วนลด
  final String discount_text;
  // รายการ Promotion
  final List<PromotionProductIncludeModel> promotion_item_code_include_list;
  // House Brand
  final List<PromotionHouseBrandModel> promotion_house_brand_list;
  // จำนวนที่ต้องซื้อ
  final double limit_qty;
  // จำนวนที่แถม
  final double promotion_qty;
  // มูลค่าที่ต้องซื้อ
  final double limit_amount;

  // 🎁 Type 102: Tier-based Redemption Fields
  // จำนวนบิลที่แสดง (สำหรับ Tier ที่มีการนับ เช่น Tier 5 = 10 บิล)
  final int? tier_display_count;
  // ลำดับความสำคัญ (1 = สูงสุด ตรวจสอบก่อน, 5 = ต่ำสุด)
  final int? tier_priority;
  // มูลค่าขั้นต่ำที่ต้องซื้อ (0, 1000, 2000, 5000, 7000)
  final double? tier_threshold;
  // ข้อความรางวัล (เช่น "แลกรับของแถม พัดลมตั้งโต๊ะ 16 นิ้ว")
  final String? tier_reward_message;

  PromotionModel({
    required this.promotion_code,
    required this.type,
    required this.index,
    required this.date_begin,
    required this.date_end,
    required this.promotion_name,
    required this.discount_text,
    required this.promotion_item_code_include_list,
    this.limit_qty = 0,
    this.promotion_qty = 0,
    this.limit_amount = 0,
    this.customer_only = 0,
    this.promotion_house_brand_list = const [],
    this.tier_display_count,
    this.tier_priority,
    this.tier_threshold,
    this.tier_reward_message,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionModelFromJson(json);
  Map<String, dynamic> toJson() => _$PromotionModelToJson(this);
}

@JsonSerializable()
class PromotionProductModel {
  final String item_code;
  late String name;
  final String unit_code;
  final String unit_name;
  final double qty; // จำนวนจริงห้ามเปลี่ยน (ยังไม่แปลงหน่วย)
  late double price; // ราคาจริงห้ามเปลี่ยน
  final String discount_text;
  final double stand_value; // ตัวตั้ง (dividend) สำหรับคำนวณหน่วยนับ
  final double dived_value; // ตัวหาร (divisor) สำหรับคำนวณหน่วยนับ

  PromotionProductModel({
    required this.item_code,
    required this.name,
    required this.qty,
    required this.unit_code,
    required this.unit_name,
    required this.price,
    this.discount_text = "",
    this.stand_value = 1, // default = 1
    this.dived_value = 1, // default = 1
  });

  factory PromotionProductModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$PromotionProductModelToJson(this);
}

class PromotionDetailModel {
  // dup รายการ เพื่อประมวลผล
  String item_name;
  String item_code;
  double qty;
  double promotion_balance_qty; // คงเหลือสำหรับ promotion
  double promotion_used_qty; // จำนวนที่ใช้ promotion ไปแล้ว
  double price;
  double total_amount;
  double unit_dividend; // ตัวตั้ง (อัตราส่วน)
  double unit_divisor; // ตัวหาร (อัตราส่วน)

  PromotionDetailModel({
    required this.item_name,
    required this.qty,
    required this.item_code,
    required this.promotion_balance_qty,
    required this.promotion_used_qty,
    required this.price,
    required this.total_amount,
    this.unit_dividend = 1.0,
    this.unit_divisor = 1.0,
  });
}

@JsonSerializable()
class PromotionHouseBrandModel {
  // โปรโมชั่น House Brand
  final String formatcode; // ประเภทโปรโมชั่น

  PromotionHouseBrandModel({required this.formatcode});

  factory PromotionHouseBrandModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionHouseBrandModelFromJson(json);
  Map<String, dynamic> toJson() => _$PromotionHouseBrandModelToJson(this);
}

@JsonSerializable()
class PromotionProductIncludeModel {
  // ซื้อ xxx แถม xxx ชิ้น
  List<PromotionProductModel> promotion_product; // เงื่อนไข
  List<PromotionProductModel> include_product; // รายการที่แถม

  PromotionProductIncludeModel({
    required this.promotion_product,
    required this.include_product,
  });

  factory PromotionProductIncludeModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionProductIncludeModelFromJson(json);
  Map<String, dynamic> toJson() => _$PromotionProductIncludeModelToJson(this);
}

@JsonSerializable()
class PromotionDiscountModel {
  // ส่วนลด เช่น ซื้อ 2 แถม 1 = ลด 50%
  final String code_detail;
  final String promotion_code;
  final String promotion_name;
  final String promotion_item_code;
  final double limit_qty;
  final String promotion_discount;
  final int include_extra; // เอายอดรวมของส่วนเพิ่มมาคิดด้วยหรือไม่ (1=Yes,0=No)

  PromotionDiscountModel({
    required this.code_detail,
    required this.promotion_code,
    required this.promotion_name,
    required this.promotion_item_code,
    required this.limit_qty,
    required this.promotion_discount,
    this.include_extra = 0,
  });
  factory PromotionDiscountModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionDiscountModelFromJson(json);
  Map<String, dynamic> toJson() => _$PromotionDiscountModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PromotionTempModel {
  // เพื่อเพิ่มความเร็วในการประมวลผล เอาทุกอย่างมาไว้ที่เดียว
  final String promotion_code;
  final DateTime date_begin;
  final DateTime date_end;
  final String name;
  final String promotion_name;
  final int customer_only;
  final String item_code_promotion;
  final double limit_qty;
  final String discount_text;
  final int include_extra; // เอายอดรวมของส่วนเพิ่มมาคิดด้วยหรือไม่ (1=Yes,0=No)

  PromotionTempModel({
    required this.promotion_code,
    required this.date_begin,
    required this.date_end,
    this.name = "",
    required this.item_code_promotion,
    this.customer_only = 0,
    required this.discount_text,
    required this.limit_qty,
    required this.promotion_name,
    this.include_extra = 0,
  });

  factory PromotionTempModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionTempModelFromJson(json);
  Map<String, dynamic> toJson() => _$PromotionTempModelToJson(this);
}

class PromotionProcessByModel {
  final String item_code;
  final double amount;
  final double sum_qty;
  final double extra_amount;

  PromotionProcessByModel({
    required this.item_code,
    required this.amount,
    required this.sum_qty,
    required this.extra_amount,
  });
}
