import 'package:dedecashier/global_model.dart';
import 'package:json_annotation/json_annotation.dart';
part 'clickhouse_server_trans_model.g.dart';

// สำหรับส่งขึ้น Server ClickHouse
@JsonSerializable(explicitToJson: true)
class TableProcessClickHouseServerStruct {
  final String guidfixed;
  final String number;
  late String number_main;
  final List<LanguageDataModel> names;
  late String zone;

  /// 0=ว่าง,1=เปิดโต๊ะแล้ว,2=ปิดโต๊ะแล้วรอคิดเงิน,3=รับชำระเงินแล้ว
  late int table_status;

  /// จำนวนรายการที่สั่ง
  late double order_count;

  /// ยอดเงิน (รวมทั้งหมด)
  late double amount;

  /// สถานะการสั่งอาหาร (False=ยังได้ไม่ครบ, True=ครบแล้ว)
  late bool order_success;

  /// เวลาเปิดโต๊ะ
  late DateTime table_open_datetime;

  /// Qr Code ล่าสุด
  late String qr_code;

  /// จำนวนคน ชาย
  late int man_count;

  /// จำนวนคน หญิง
  late int woman_count;

  /// จำนวนเด็ก
  late int child_count;

  /// False=สั่งแบบอลาคาร์ทไม่ได้,True=สั่งแบบอลาคาร์ทได้
  late bool table_al_la_crate_mode;

  /// Buffet ที่เลือก
  late String buffet_code;

  /// รหัสหรือเบอร์โทรศัพท์ลูกค้า
  late String customer_code_or_telephone;

  /// ชื่อลูกค้า
  late String customer_name;

  /// ที่อยู่ลูกค้า
  late String customer_address;

  /// Delivery ที่เลือก
  late String delivery_code;

  /// Delivery Ticket Number
  late String delivery_ticket_number;

  /// Delivery Number
  late String delivery_number;

  /// Remark
  late String remark;

  /// พนักงานที่เปิดโต๊ะ
  late String open_by_staff_code;

  /// ทำอาหารทันที
  late bool make_food_immediately;

  /// is Delivery
  late bool is_delivery;

  /// อาหารเสร็จแล้ว พร้อมเวลา
  late bool delivery_cook_success;

  late DateTime delivery_cook_success_datetime;

  /// ส่งอาหารแล้ว พร้อมเวลา
  late bool delivery_send_success;

  late DateTime delivery_send_success_datetime;

  /// สถานะ 0=รับที่ร้านรอคิดเงิน,1=คิดเงินแล้ว ทำส่ง Delivery
  late int delivery_status;

  /// จำนวนโต๊ะลูก (กรณีแยกโต๊ะ)
  late int table_child_count;

  /// ส่วนลดค่าอาหาร
  late String detail_discount_formula;

  TableProcessClickHouseServerStruct({
    required this.guidfixed,
    required this.number,
    required this.number_main,
    required this.names,
    required this.zone,
    required this.table_status,
    required this.order_count,
    required this.amount,
    required this.order_success,
    required this.qr_code,
    required this.table_open_datetime,
    required this.man_count,
    required this.woman_count,
    required this.child_count,
    required this.table_al_la_crate_mode,
    required this.buffet_code,
    required this.customer_code_or_telephone,
    required this.customer_name,
    required this.customer_address,
    required this.delivery_code,
    required this.delivery_number,
    required this.delivery_ticket_number,
    required this.remark,
    required this.open_by_staff_code,
    required this.make_food_immediately,
    required this.is_delivery,
    required this.delivery_cook_success,
    required this.delivery_cook_success_datetime,
    required this.delivery_send_success,
    required this.delivery_send_success_datetime,
    required this.delivery_status,
    required this.table_child_count,
    required this.detail_discount_formula,
  });

  factory TableProcessClickHouseServerStruct.fromJson(Map<String, dynamic> json) => _$TableProcessClickHouseServerStructFromJson(json);

  Map<String, dynamic> toJson() => _$TableProcessClickHouseServerStructToJson(this);
}

// สำหรับส่งขึ้น Server ClickHouse
@JsonSerializable(explicitToJson: true)
class OrderTempClickHouseServerStruct {
  int id;

  /// รหัส Order (โทรศัพท์,GUID โต๊ะ)
  String orderId;

  /// รหัส อ้างอิง
  String orderGuid;

  /// รหัส Order หลัก (โทรศัพท์,GUID โต๊ะ)
  String orderIdMain;

  /// UUID หน้าจอกรณีเลือกพร้อมกันหลายคน
  String machineId;

  DateTime orderDateTime;
  String barcode;

  /// จำนวนสั่ง (เมื่อจากกดส่งแล้ว)
  double orderQty;

  /// จำนวนจริง หลังจากหักยกเลิก
  double qty;

  /// จำนวนยกเลิก (เมื่อกดส่งแล้วมีการยกเลิก)
  double cancelQty;

  double price;
  double amount;

  /// สถานะล่าสุด True=กำลังรับ Order,False=จบการรับ Order
  bool isOrder;

  /// สั่งเรียบร้อย (รอคิดเงิน)
  bool isOrderSuccess;

  /// ส่งเข้าครัวเรียบร้อย
  bool isOrderSendKdsSuccess;

  /// รายการนี้รอส่งเข้าครัว
  bool isOrderReadySendKds;

  /// ปิด (เก็บสะสม)
  bool isPaySuccess;

  /// ข้อเลือกพิเศษ
  List<OrderProductOptionClickHouseServerModel> optionSelected;
  String remark;
  List<LanguageDataModel> names;
  String unitCode;
  List<LanguageDataModel> unitName;
  String imageUri;
  bool takeAway;

  /// KDS System
  DateTime kdsSuccessTime;

  /// ครัวปรุงเสร็จ
  bool kdsSuccess;
  String kdsId;

  // เสริฟท์
  DateTime servedTime;
  bool servedSuccess;
  double servedQty;

  // Delivery
  String deliveryNumber;
  String deliveryCode;
  String deliveryName;

  /// วันที่เวลาแก้ไขล่าสุด เพื่อให้ระบบอื่นนำไปใช้เป็นตัวเช็คว่ามีการแก้ไขหรือยัง
  DateTime lastUpdateDateTime;

  /// 0=พนักงานสั่ง,1=ลูกค้าสั่งเองด้วย Order Online
  int orderType;

  /// รหัสพนักงานสั่ง Order
  String orderEmployeeCode;
  String orderEmployeeDetail;

  OrderTempClickHouseServerStruct({
    required this.id,
    required this.orderId,
    required this.orderIdMain,
    required this.orderGuid,
    required this.machineId,
    required this.orderDateTime,
    required this.barcode,
    required this.qty,
    required this.price,
    required this.amount,
    required this.isOrder,
    required this.isPaySuccess,
    required this.optionSelected,
    required this.remark,
    required this.names,
    required this.takeAway,
    required this.unitCode,
    required this.unitName,
    required this.imageUri,
    required this.kdsSuccessTime,
    required this.kdsSuccess,
    required this.isOrderSuccess,
    required this.isOrderSendKdsSuccess,
    required this.kdsId,
    required this.cancelQty,
    required this.orderQty,
    required this.deliveryNumber,
    required this.deliveryCode,
    required this.isOrderReadySendKds,
    required this.deliveryName,
    required this.lastUpdateDateTime,
    required this.servedTime,
    required this.servedSuccess,
    required this.servedQty,
    required this.orderType,
    required this.orderEmployeeCode,
    required this.orderEmployeeDetail,
  });

  factory OrderTempClickHouseServerStruct.fromJson(Map<String, dynamic> json) => _$OrderTempClickHouseServerStructFromJson(json);

  Map<String, dynamic> toJson() => _$OrderTempClickHouseServerStructToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderProductOptionClickHouseServerModel {
  final String guid;
  final int choicetype;
  final int maxselect;
  final int minselect;
  final List<LanguageDataModel> names;
  final List<OrderProductOptionChoiceClickHouseServerModel> choices;

  OrderProductOptionClickHouseServerModel({
    required this.guid,
    required this.choicetype,
    required this.maxselect,
    required this.minselect,
    required this.names,
    required this.choices,
  });

  factory OrderProductOptionClickHouseServerModel.fromJson(Map<String, dynamic> json) => _$OrderProductOptionClickHouseServerModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderProductOptionClickHouseServerModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderProductOptionChoiceClickHouseServerModel {
  final String guid;
  final List<LanguageDataModel> names;
  final String price;
  final double qty;
  final bool selected;
  final double priceValue;

  OrderProductOptionChoiceClickHouseServerModel({
    required this.guid,
    required this.names,
    required this.price,
    required this.qty,
    required this.selected,
    required this.priceValue,
  });

  factory OrderProductOptionChoiceClickHouseServerModel.fromJson(Map<String, dynamic> json) => _$OrderProductOptionChoiceClickHouseServerModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderProductOptionChoiceClickHouseServerModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PosProcessClickHouseServerModel {
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
  List<PosProcessDetailClickHouseServerModel> details;

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

  PosProcessClickHouseServerModel({
    required this.total_piece,
    required this.detail_total_amount_before_discount,
    required this.total_piece_except_vat,
    required this.total_piece_vat,
    required this.total_amount,
    required this.total_discount_from_promotion,
    required this.qr_code,
    required this.vat_type,
    required this.vat_rate,
    required this.is_vat_register,
    required this.total_vat_amount,
    required this.total_item_vat_amount,
    required this.total_item_except_vat_amount,
    required this.amount_except_vat,
    required this.details,
    required this.detail_discount_formula,
    required this.detail_total_discount,
    required this.total_discount_vat_amount,
    required this.total_discount_except_vat_amount,
    required this.amount_after_calc_vat,
    required this.amount_before_calc_vat,
    required this.cash_round_amount,
    required this.total_amount_pay,
    required this.total_drink_amount,
    required this.total_alcohol_amount,
    required this.total_other_amount,
    required this.total_food_amount,
    required this.total_cheque_amount,
    required this.total_transfer_amount,
    required this.total_coupon_amount,
    required this.total_credit_amount,
    required this.total_credit_card_amount,
    required this.total_qr_code_amount,
  });

  factory PosProcessClickHouseServerModel.fromJson(Map<String, dynamic> json) => _$PosProcessClickHouseServerModelFromJson(json);

  Map<String, dynamic> toJson() => _$PosProcessClickHouseServerModelToJson(this);
}

@JsonSerializable()
class PosProcessDetailClickHouseServerModel {
  String guid;
  int index;
  String barcode;
  String item_code;
  List<LanguageDataModel> item_name;
  String unit_code;
  List<LanguageDataModel> unit_name;
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

  /// ราคารวมภาษี (True = ราคารวมภาษี, False = ราคาไม่รวมภาษี)
  bool price_exclude_vat_type;

  /// สินค้ายกเว้นภาษี (True = สินค้ายกเว้นภาษี, False = สินค้าไม่ยกเว้นภาษี)
  bool is_except_vat;

  int vat_type;

  /// ราคาไม่รวมภาษี
  double price_exclude_vat;
  int food_type;

  List<PosProcessDetailExtraClickHouseModel> extra;

  PosProcessDetailClickHouseServerModel({
    required this.guid,
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
  });

  factory PosProcessDetailClickHouseServerModel.fromJson(Map<String, dynamic> json) => _$PosProcessDetailClickHouseServerModelFromJson(json);

  Map<String, dynamic> toJson() => _$PosProcessDetailClickHouseServerModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PosProcessDetailExtraClickHouseModel {
  String guid_auto_fixed;
  String guid_code_or_ref;
  String guid_category;
  int index;
  String barcode;
  String refbarcode;
  String refunitcode;
  String item_code;
  List<LanguageDataModel> item_name;
  String unit_code;
  List<LanguageDataModel> unit_name;
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

  PosProcessDetailExtraClickHouseModel(
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
      required this.price_exclude_vat,
      String? refbarcode,
      String? refunitcode})
      : refbarcode = refbarcode ?? "",
        refunitcode = refunitcode ?? "";

  factory PosProcessDetailExtraClickHouseModel.fromJson(Map<String, dynamic> json) => _$PosProcessDetailExtraClickHouseModelFromJson(json);

  Map<String, dynamic> toJson() => _$PosProcessDetailExtraClickHouseModelToJson(this);
}
