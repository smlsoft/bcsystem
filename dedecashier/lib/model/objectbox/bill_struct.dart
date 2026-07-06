// ignore_for_file: non_constant_identifier_names

import 'package:objectbox/objectbox.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'bill_struct.g.dart';

@Entity()
class BillObjectBoxStruct {
  int id = 0;

  /// GUID เอกสาร (Unique)

  String doc_guid;

  /// เลขที่เอกสาร
  @Unique()
  @Index()
  String doc_number;

  /// วันที่เอกสาร
  @Property(type: PropertyType.date)
  DateTime date_time;

  /// 0=บิลทั่วไปไม่มีภาษี,1=ใบเสร็จรับเงิน/ใบกำกับภาษีอย่างย่อ,2=ใบเสร็จรับเงิน/ใบกำกับภาษีอย่างเต็ม
  int bill_tax_type;

  /// ประเภทเอกสาร (1 = ขาย, 2 = คืน)
  int doc_mode;

  /// รหัสลูกค้า
  String customer_code;

  /// ชื่อลูกค้า
  String customer_name;

  /// เบอร์โทรลูกค้า (สะสมแต้ม)
  String customer_telephone;

  String trancsaction_id;

  /// จำนวนชิ้น
  double total_qty;

  /// ยอดรวมสินค้ามีภาษี
  double total_item_vat_amount;

  // ยอดรวมสินค้ายกเว้นภาษี
  double total_item_except_vat_amount;

  /// สูตรส่วนลดท้ายบิล
  String discount_formula;

  /// ส่วนลดทั้งหมด (ท้ายบิล)
  double total_discount;

  /// ส่วนลดจากโปรโมชั่น
  double total_discount_from_promotion;

  /// ส่วนลดสินค้ามีภาษี
  double total_discount_vat_amount;

  /// ส่วนลดสินค้ายกเว้นภาษี
  double total_discount_except_vat_amount;

  /// มูลค่าก่อนคิดภาษี (สินค้ามีภาษี)
  double amount_before_calc_vat;

  /// มูลค่าหลังคิดภาษี (สินค้ามีภาษี)
  double amount_after_calc_vat;

  // มูลค่า สินค้ายกเว้นภาษี
  double amount_except_vat;

  /// ยอดรวมทั้งสิ้น
  double total_amount;

  /// ยอด vat
  double total_vat_amount;

  /// อัตรา vat
  double vat_rate;

  /// รหัสพนักงานขาย
  String sale_code;

  /// ชื่อพนักงานขาย
  String sale_name;

  /// สถานะการ Sync (true = Sync แล้ว, false = ยังไม่ Sync)
  bool is_sync;

  /// สถานะการยกเลิก (true = ยกเลิก, false = ยังไม่ยกเลิก)
  bool is_cancel;

  /// วันที่ยกเลิก
  String cancel_date_time;

  /// เหตุผลที่ยกเลิก
  String cancel_description;

  /// พนักงานที่ยกเลิก
  String cancel_user_code;

  /// ชื่อพนักงานที่ยกเลิก
  String cancel_user_name;

  /// เหตุผลที่ยกเลิก
  String cancel_reason;

  /// พนักงาน Cashier
  String cashier_code;

  /// ชื่อพนักงาน Cashier
  String cashier_name;

  /// ชำระเงินสด
  double pay_cash_amount;

  /// เงินทอน
  double pay_cash_change;

  /// ชำระด้วย Point
  double paypointamount;

  /// ชำระเงินโดย QR Code
  double sum_qr_code;

  /// ชำระเงินโดย Credit Card
  double sum_credit_card;

  /// ชำระเงินโดยเงินโอน
  double sum_money_transfer;

  /// ชำระเงินโดยเช็ค
  double sum_cheque;

  /// ชำระเงินโดยCoupon
  double sum_coupon;

  /// ชำระโดยเงินเชื่อ
  double sum_credit;

  /// พิมพ์ใบกำกับภาษีแบบเต็มแล้ว
  bool full_vat_print;

  /// เลขที่ใบกำกับภาษีแบบเต็ม
  String full_vat_doc_number;

  /// ชื่อลูกค้าใบกำกับภาษีแบบเต็ม
  String full_vat_name;

  /// ที่อยู่ใบกำกับภาษีแบบเต็ม
  String full_vat_address;

  /// เลขประจำตัวผู้เสียภาษีใบกำกับภาษีแบบเต็ม
  String full_vat_tax_id;

  /// เลขสาขาใบกำกับภาษีแบบเต็ม
  String full_vat_branch_number;

  /// วันที่พิมพ์ใบเสร็จ (สำเนา)
  List<String> print_copy_bill_date_time;

  // หมายเลขโต๊ะ
  String table_number;

  /// จำนวนคน ชาย
  int man_count;

  /// จำนวนคน หญิง
  int woman_count;

  /// จำนวนเด็ก
  int child_count;

  /// False=สั่งแบบอลาคาร์ทไม่ได้,True=สั่งแบบอลาคาร์ทได้
  bool table_al_la_crate_mode;

  String buffet_code;

  /// เวลาเปิดโต๊ะ
  @Property(type: PropertyType.date)
  DateTime table_open_date_time;

  /// เวลาปิดโต๊ะ
  @Property(type: PropertyType.date)
  DateTime table_close_date_time;

  String pay_json;

  /// 1=ภาษีมูลค่าเพิ่มรวมใน,2=ภาษีมูลค่าเพิ่มแยกนอก
  int vat_type;

  bool is_vat_register;

  /// สูตรส่วนลดรายการสินค้า (ก่อนคิดเงิน)
  String detail_discount_formula;
  double detail_total_amount;
  double detail_total_discount;

  /// ยอดปัดเศษ
  double round_amount;

  /// ยอดรวมหลังหักส่วนลดท้ายบิล
  double total_amount_after_discount;

  // ยอดรวมสินค้าก่อนหักส่วนลดสินค้า
  double detail_total_amount_before_discount;

  /// ยอดรวมอาหาร
  double food_amount;

  /// ยอดรวมเครื่องดื่ม/ของหวาน
  double beverage_amount;

  /// เป็นรายการ delivery หรือไม่
  bool is_delivery;

  /// รหัสลูกค้าที่ส่งสินค้า
  String delivery_code;

  /// หมายเลขใบส่งสินค้า
  String delivery_number;

  String guidpos;

  /// json รายละเอียด Promotion ที่ได้รับ
  String promotion_json;

  /// json รายละเอียด Promotion ที่ได้รับ (ท้ายบิล)
  String promotion_bottom_json;

  /// json รายละเอียด Promotion ที่ได้รับ (ท้ายบิล) BONUS
  String promotion_bonus_json;

  /// json รายละเอียด Promotion ที่ได้รับ (ท้ายบิล) COUPON (Type 101)
  String promotion_coupon_json;

  /// เลขที่เอกสารกะที่เปิดอยู่ในขณะที่ขาย (ว่างถ้าไม่มีกะเปิด)
  String shift_doc_no;

  /// แต้มที่ได้รับ
  double getpoint;

  /// แต้มที่ใช้
  double usepoint;

  /// จำนวนเงินส่วนลดจากการใช้แต้ม
  double pointdiscountamount;

  /// ยอดแต้มคงเหลือหลังการทำรายการ
  double point_balance_after;

  String? points_code;

  /// จำนวนเงินคูปองแทนเงินสด
  double couponcashamount;

  /// จำนวนเงินส่วนลดจากคูปอง
  double coupondiscountamount;

  /// JSON ข้อมูลคูปองที่ใช้
  String coupons_json;

  BillObjectBoxStruct({
    required this.date_time,
    String? guidpos,
    required this.trancsaction_id,
    required this.table_open_date_time,
    required this.table_close_date_time,
    required this.doc_number,
    required this.doc_mode,
    required this.customer_code,
    required this.bill_tax_type,
    required this.customer_name,
    required this.customer_telephone,
    required this.vat_rate,
    required this.total_amount,
    required this.total_vat_amount,
    required this.cashier_code,
    required this.cashier_name,
    required this.sale_code,
    required this.amount_except_vat,
    required this.amount_before_calc_vat,
    required this.amount_after_calc_vat,
    required this.total_discount_vat_amount,
    required this.total_discount_except_vat_amount,
    required this.sale_name,
    required this.vat_type,
    required this.total_qty,
    required this.is_sync,
    required this.total_discount_from_promotion,
    required this.discount_formula,
    required this.pay_cash_amount,
    required this.paypointamount,
    required this.total_discount,
    required this.sum_qr_code,
    required this.sum_credit_card,
    required this.sum_money_transfer,
    required this.sum_coupon,
    required this.sum_cheque,
    required this.is_cancel,
    required this.cancel_date_time,
    required this.cancel_user_code,
    required this.cancel_user_name,
    required this.pay_cash_change,
    required this.cancel_reason,
    required this.cancel_description,
    required this.full_vat_print,
    required this.full_vat_doc_number,
    required this.full_vat_name,
    required this.full_vat_address,
    required this.full_vat_tax_id,
    required this.full_vat_branch_number,
    required this.table_number,
    required this.child_count,
    required this.woman_count,
    required this.man_count,
    required this.table_al_la_crate_mode,
    required this.buffet_code,
    required this.pay_json,
    required this.total_item_vat_amount,
    required this.total_item_except_vat_amount,
    required this.is_vat_register,
    required this.detail_discount_formula,
    required this.detail_total_amount,
    required this.detail_total_discount,
    required this.round_amount,
    required this.total_amount_after_discount,
    required this.sum_credit,
    required this.detail_total_amount_before_discount,
    required this.food_amount,
    required this.beverage_amount,
    required this.is_delivery,
    required this.delivery_code,
    required this.delivery_number,
    required this.promotion_json,
    required this.promotion_bottom_json,
    required this.promotion_bonus_json,
    required this.promotion_coupon_json,
    required this.shift_doc_no,
    required this.getpoint,
    required this.usepoint,
    required this.pointdiscountamount,
    required this.point_balance_after,
    required this.print_copy_bill_date_time,
    String? points_code,
    required this.couponcashamount,
    required this.coupondiscountamount,
    required this.coupons_json,
  }) : doc_guid = const Uuid().v4(),
       guidpos = guidpos ?? '',
       points_code = points_code ?? '';
}

@Entity()
class BillDetailObjectBoxStruct {
  int id = 0;

  /// ประเภทเอกสาร (1 = ขาย, 2 = คืน)
  int doc_mode;

  @Index()
  String doc_number;

  String guidpos;

  /// ลำดับรายการ
  int line_number;

  /// บาร์โค้ด
  @Index(type: IndexType.hash)
  String barcode;

  /// รหัสสินค้า
  @Index(type: IndexType.hash)
  String item_code;

  /// ชื่อสินค้า
  @Index()
  String item_name;

  /// รหัสหน่วย
  @Index(type: IndexType.hash)
  String unit_code;

  /// ชื่อหน่วย
  @Index()
  String unit_name;

  /// SKU สินค้า
  String sku;

  /// จำนวน
  double qty;

  /// ราคา
  double price;

  /// ราคาเดิมก่อนโปรโมชั่น (สำหรับแสดงใบเสร็จ)
  double price_original;

  /// ส่วนลด
  String discount_text;

  /// ส่วนลดเป็นเงิน
  double discount;

  /// ยอดรวมมูลค่า
  double total_amount;

  /// ยกเว้นภาษี (True=ยกเว้นภาษี,False=ไม่ยกเว้นภาษี)
  bool is_except_vat;

  /// 1=ภาษีมูลค่าเพิ่มรวมใน,2=ภาษีมูลค่าเพิ่มแยกนอก
  int vat_type;

  /// ราคาไม่รวมภาษีมูลค่าเพิ่ม
  double price_exclude_vat;

  int food_type;

  String extra_json;

  String refguid;

  bool is_void;

  String description;

  bool issumpoint;

  /// รหัส Pattern Code (เช่น HB สำหรับ House Brand)
  String pattern_code;

  /// ชื่อ Pattern (เช่น "สินค้าเฮาส์แบรนด์")
  String pattern_name;

  BillDetailObjectBoxStruct({
    required this.doc_mode,
    required this.doc_number,
    required this.line_number,
    String? guidpos,
    required this.barcode,
    required this.item_code,
    required this.item_name,
    required this.unit_code,
    required this.unit_name,
    required this.sku,
    required this.qty,
    required this.price,
    double? price_original,
    required this.discount_text,
    required this.discount,
    required this.is_except_vat,
    required this.extra_json,
    required this.total_amount,
    required this.vat_type,
    required this.price_exclude_vat,
    required this.food_type,
    required this.is_void,
    String? refguid,
    String? description,
    bool? issumpoint,
    String? pattern_code,
    String? pattern_name,
  }) : refguid = refguid ?? '',
       guidpos = guidpos ?? '',
       description = description ?? '',
       issumpoint = issumpoint ?? false,
       pattern_code = pattern_code ?? '',
       pattern_name = pattern_name ?? '',
       price_original = price_original ?? price;
}

@JsonSerializable(explicitToJson: true)
class BillDetailExtraObjectBoxStruct {
  /// บาร์โค้ด
  String barcode;

  /// บาร์โค้ด
  String refbarcode;

  /// ref
  String refunitcode;

  /// รหัสสินค้า
  String item_code;

  /// ชื่อสินค้า
  String item_name;

  /// รหัสหน่วย
  String unit_code;

  /// ชื่อหน่วย
  String unit_name;

  /// จำนวน
  double qty;

  /// ราคา
  double price;

  /// ยอดรวมมูลค่า
  double total_amount;

  /// ยกเว้นภาษี (True=ยกเว้นภาษี,False=ไม่ยกเว้นภาษี)
  bool is_except_vat;

  /// 1=ภาษีมูลค่าเพิ่มรวมใน,2=ภาษีมูลค่าเพิ่มแยกนอก
  int vat_type;

  /// ราคาไม่รวมภาษีมูลค่าเพิ่ม
  double price_exclude_vat;

  BillDetailExtraObjectBoxStruct({
    required this.barcode,
    required this.item_code,
    required this.item_name,
    required this.unit_code,
    required this.unit_name,
    required this.qty,
    required this.price,
    required this.is_except_vat,
    required this.vat_type,
    required this.price_exclude_vat,
    required this.total_amount,
    String? refbarcode,
    String? refunitcode,
  }) : refbarcode = refbarcode ?? '',
       refunitcode = refunitcode ?? '';

  factory BillDetailExtraObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$BillDetailExtraObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$BillDetailExtraObjectBoxStructToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BillPayObjectBoxStruct {
  /// ประเภทเอกสาร (1 = ขาย, 2 = คืน)
  int doc_mode;

  /// 1=บัตรเครดิต,2=เงินโอน,3=เช็ค,4=คูปอง,5=QR,9=เงินเชื่อ
  int trans_flag;

  /// รหัสธนาคาร
  String bank_code;

  /// ชื่อธนาคาร (อื่นๆ)
  String bank_name;

  /// เลขที่บัญชี (เงินเข้า)
  String book_bank_code;

  /// เลขที่บัตรเครดิต
  String card_number;

  /// รหัสอนุมัติ
  String approved_code;

  /// วันที่โอนเงิน
  DateTime doc_date_time;

  /// สาขาธนาคาร
  String branch_number;

  /// รหัสอ้างอิงธนาคาร
  String bank_reference;

  /// วันที่สั่งจ่ายบนเช็ค
  DateTime due_date;

  /// เลขที่เช็ค
  String cheque_number;

  /// รหัสส่วนลด
  String code;

  /// รายละเอียด (เพิ่มเติม)
  String description;

  /// เลขคูปอง
  String number;

  /// อ้างอิง 1
  String reference_one;

  /// อ้างอิง 2
  String reference_two;

  /// รหัสกระเป๋า เจ้าของเงิน (Provider)
  String provider_code;

  /// เจ้าของเงิน (Provider)
  String provider_name;

  /// จำนวนเงิน
  double amount;

  BillPayObjectBoxStruct({
    this.doc_mode = 0,
    this.trans_flag = 0,
    this.bank_code = "",
    this.card_number = "",
    this.approved_code = "",
    this.bank_name = "",
    this.book_bank_code = "",
    this.branch_number = "",
    this.bank_reference = "",
    this.cheque_number = "",
    this.code = "",
    this.description = "",
    this.number = "",
    this.reference_one = "",
    this.reference_two = "",
    this.provider_code = "",
    this.provider_name = "",
    this.amount = 0,
  }) : due_date = DateTime.now(),
       doc_date_time = DateTime.now();

  factory BillPayObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$BillPayObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$BillPayObjectBoxStructToJson(this);
}
