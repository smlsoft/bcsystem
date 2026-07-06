import 'package:dedeorder/model/pos_pay_model.dart';
import 'package:dedeorder/model/promotion_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pos_process_model.g.dart';

@JsonSerializable()
class PosProcessDetailModel {
  String guid;
  int index;
  String barcode;
  String item_code;
  String item_name;
  String unit_code;
  String unit_name;
  double qty;
  double price;
  double price_original;
  String discount_text;
  double discount;
  double total_amount;
  double total_amount_with_extra;
  bool is_void;
  String remark;
  String image_url;

  double unit_dividend;
  double unit_divisor;

  /// ราคารวมภาษี (True = ราคารวมภาษี, False = ราคาไม่รวมภาษี)
  bool price_exclude_vat_type;

  /// สินค้ายกเว้นภาษี (True = สินค้ายกเว้นภาษี, False = สินค้าไม่ยกเว้นภาษี)
  bool is_except_vat;

  int vat_type;

  /// ราคาไม่รวมภาษี
  double price_exclude_vat;

  /// 0=อาหาร,1=เครื่องดื่ม,2=ของหวาน
  int food_type;

  List<PosProcessDetailExtraModel> extra;

  PosProcessDetailModel(
      {required this.guid,
      required this.index,
      required this.barcode,
      required this.item_code,
      required this.item_name,
      required this.unit_code,
      required this.unit_name,
      required this.qty,
      required this.price,
      required this.price_original,
      required this.discount_text,
      required this.discount,
      required this.total_amount,
      required this.total_amount_with_extra,
      required this.is_void,
      required this.remark,
      required this.image_url,
      required this.price_exclude_vat_type,
      required this.is_except_vat,
      required this.extra,
      required this.vat_type,
      required this.price_exclude_vat,
      required this.food_type,
      double? unit_dividend = 0,
      double? unit_divisor = 0})
      : unit_dividend = unit_dividend ?? 0,
        unit_divisor = unit_divisor ?? 0;

  factory PosProcessDetailModel.fromJson(Map<String, dynamic> json) => _$PosProcessDetailModelFromJson(json);
  Map<String, dynamic> toJson() => _$PosProcessDetailModelToJson(this);
}

@JsonSerializable()
class PosProcessDetailExtraModel {
  String guid_auto_fixed;
  String guid_code_or_ref;
  String guid_category;
  int index;
  String barcode;
  String item_code;
  String item_name;
  String unit_code;
  String unit_name;
  double qty;
  double qty_fixed;
  double price;
  double total_amount;
  bool is_void;

  /// ราคารวมภาษี (True = ราคารวมภาษี, False = ราคาไม่รวมภาษี)
  bool price_exclude_vat_type;

  /// สินค้ายกเว้นภาษี (True = สินค้ายกเว้นภาษี, False = สินค้าไม่ยกเว้นภาษี)
  bool is_except_vat;

  /// ราคาไม่รวมภาษี
  double price_exclude_vat;

  /// ประเภทภาษีมูลค่าเพิ่ม 1=ภาษีมูลค่าเพิ่มรวมใน,2=ภาษีมูลค่าเพิ่มแยกนอก
  int vat_type;

  PosProcessDetailExtraModel(
      {required this.guid_auto_fixed,
      required this.guid_category,
      required this.guid_code_or_ref,
      required this.index,
      required this.barcode,
      required this.item_code,
      required this.item_name,
      required this.unit_code,
      required this.unit_name,
      required this.qty,
      required this.qty_fixed,
      required this.price,
      required this.total_amount,
      required this.price_exclude_vat_type,
      required this.is_except_vat,
      required this.vat_type,
      required this.is_void,
      required this.price_exclude_vat});

  factory PosProcessDetailExtraModel.fromJson(Map<String, dynamic> json) => _$PosProcessDetailExtraModelFromJson(json);
  Map<String, dynamic> toJson() => _$PosProcessDetailExtraModelToJson(this);
}

@JsonSerializable()
class PosProcessPromotionModel {
  late String promotion_name;
  late String discount_word;
  late double discount;

  PosProcessPromotionModel({required this.promotion_name, required this.discount_word, required this.discount});

  factory PosProcessPromotionModel.fromJson(Map<String, dynamic> json) => _$PosProcessPromotionModelFromJson(json);
  Map<String, dynamic> toJson() => _$PosProcessPromotionModelToJson(this);
}

@JsonSerializable()
class PosProcessModel {
  /// จำนวนชิ้น
  double total_piece;

  /// จำนวนชิ้น สินค้ามีภาษี
  double total_piece_vat;

  /// จำนวนชิ้น สินค้ายกเว้นภาษี
  double total_piece_except_vat;

  /// ยอดรวมภาษี
  double total_vat_amount;

  /// ยอดรวมสินค้าก่อนหักส่วนลดสินค้า
  double detail_total_amount_before_discount;

  /// ยอดรวมทั้งสิ้นหลังหักส่วนลด
  double total_amount;

  /// ยอดรวม Promotion
  double total_discount_from_promotion;

  // Qr Code
  String qr_code;

  /// จดทะเบียนภาษีมูลค่าเพิ่ม
  bool is_vat_register;

  /// ประเภทภาษีมูลค่าเพิ่ม 1=ภาษีมูลค่าเพิ่มรวมใน,2=ภาษีมูลค่าเพิ่มแยกนอก
  int vat_type;

  /// อัตราภาษี
  double vat_rate;

  /// ยอดรวมสินค้ามีภาษี
  double total_item_vat_amount;

  /// ยอดรวมสินค้ายกเว้นภาษี
  double total_item_except_vat_amount;

  /// รายการสินค้า
  List<PosProcessDetailModel> details;

  /// รายการ Promotion
  List<PromotionTempModel> select_promotion_temp_list;

  /// รายการ Promotion ที่เลือก
  List<PosProcessPromotionModel> promotion_list;

  /// สูตรส่วนลด (ก่อนคิดเงิน)
  String detail_discount_formula;

  /// ส่วนลดทั้งหมด (ก่อนคิดเงิน)
  double detail_total_discount;

  /// ส่วนลดสินค้ามีภาษี
  double total_discount_vat_amount;

  /// ส่วนลดสินค้ายกเว้นภาษี
  double total_discount_except_vat_amount;

  /// ยอดรวมก่อนคำนวณภาษี (สินค้ามีภาษี)
  double amount_before_calc_vat;

  /// มูลค่าสินค้าหลังคิดภาษี
  double amount_after_calc_vat;

  /// มูลค่าสินค้ายกเว้นภาษี
  double amount_except_vat;

  /// ยอดปัดเศษ (เงินสด)
  double cash_round_amount;

  /// ยอดชำระ (หลังหักปัดเศษ)
  double total_amount_pay;

  /// ยอดรวมอาหาร
  double total_food_amount;

  /// ยอดรวมเครื่องดื่ม
  double total_drink_amount;

  /// ยอดรวมเครื่องดื่มแอลกอฮอล์
  double total_alcohol_amount;

  /// ยอดรวมอื่นๆ
  double total_other_amount;

  double total_credit_card_amount;
  double total_qr_code_amount;
  double total_cheque_amount;
  double total_transfer_amount;
  double total_coupon_amount;
  double total_credit_amount;

  PosProcessModel(
      {this.total_piece = 0.0,
      this.detail_total_amount_before_discount = 0.0,
      this.total_piece_except_vat = 0,
      this.total_piece_vat = 0,
      this.total_amount = 0.0,
      this.total_discount_from_promotion = 0,
      this.qr_code = "",
      this.vat_type = 0,
      this.vat_rate = 0,
      this.is_vat_register = false,
      this.total_vat_amount = 0,
      this.total_item_vat_amount = 0,
      this.total_item_except_vat_amount = 0,
      this.amount_except_vat = 0,
      this.details = const [],
      this.select_promotion_temp_list = const [],
      this.detail_discount_formula = "",
      this.detail_total_discount = 0,
      this.total_discount_vat_amount = 0,
      this.total_discount_except_vat_amount = 0,
      this.amount_after_calc_vat = 0,
      this.amount_before_calc_vat = 0,
      this.cash_round_amount = 0,
      this.total_amount_pay = 0,
      this.total_drink_amount = 0,
      this.total_alcohol_amount = 0,
      this.total_other_amount = 0,
      this.total_food_amount = 0,
      this.total_cheque_amount = 0,
      this.total_transfer_amount = 0,
      this.total_coupon_amount = 0,
      this.total_credit_amount = 0,
      this.total_credit_card_amount = 0,
      this.total_qr_code_amount = 0,
      this.promotion_list = const []});

  factory PosProcessModel.fromJson(Map<String, dynamic> json) => _$PosProcessModelFromJson(json);
  Map<String, dynamic> toJson() => _$PosProcessModelToJson(this);
}
