// ignore_for_file: non_constant_identifier_names

import 'package:dedecashier/model/json/pos_process_model.dart';
import 'package:objectbox/objectbox.dart';
import 'package:json_annotation/json_annotation.dart';

part 'table_struct.g.dart';

@JsonSerializable(explicitToJson: true)
@Entity()
class TableObjectBoxStruct {
  int id = 0;

  @Unique()
  @Index(type: IndexType.hash)
  String guidfixed;

  @Index(type: IndexType.hash)
  String number;

  @Index(type: IndexType.hash)
  String numberMain;

  @Index()
  String names;

  @Index()
  String zone;

  TableObjectBoxStruct({
    required this.guidfixed,
    required this.number,
    required this.numberMain,
    required this.names,
    required this.zone,
  });

  factory TableObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$TableObjectBoxStructFromJson(json);

  Map<String, dynamic> toJson() => _$TableObjectBoxStructToJson(this);
}

@JsonSerializable(explicitToJson: true)
@Entity()
class TableProcessObjectBoxStruct {
  int id = 0;

  @Unique()
  @Index(type: IndexType.hash)
  final String guidfixed;

  @Index(type: IndexType.hash)
  final String number;

  late String number_main;
  final String names;
  late String zone;

  /// 0=ว่าง,1=เปิดโต๊ะแล้ว,2=ปิดโต๊ะแล้วรอคิดเงิน,3=รับชำระเงินแล้ว
  late int table_status;

  /// ยอดเงิน (รวมทั้งหมด)
  late double amount;

  /// สถานะการสั่งอาหาร (False=ยังได้ไม่ครบ, True=ครบแล้ว)
  late bool order_success;

  /// เวลาเปิดโต๊ะ
  @Property(type: PropertyType.date)
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

  @Property(type: PropertyType.date)
  late DateTime delivery_cook_success_datetime;

  /// ส่งอาหารแล้ว พร้อมเวลา
  late bool delivery_send_success;

  @Property(type: PropertyType.date)
  late DateTime delivery_send_success_datetime;

  /// สถานะ 0=รับที่ร้านรอคิดเงิน,1=คิดเงินแล้ว ทำส่ง Delivery
  late int delivery_status;

  /// จำนวนโต๊ะลูก (กรณีแยกโต๊ะ)
  late int table_child_count;

  /// ส่วนลดค่าอาหาร
  late String detail_discount_formula;

  /// สัญชาติลูกค้า
  late String customer_nationality_code;

  /// จำนวนรายการที่สั่ง
  late double order_count;

  /// จำนวนยกเลิก
  late double order_cancel_count;

  // จำนวนเสิร์ฟ
  late double order_served_count;

  bool isUpdate;

  TableProcessObjectBoxStruct({
    required this.guidfixed,
    String? number,
    String? number_main,
    String? names,
    String? zone,
    int? table_status,
    double? order_count,
    double? order_cancel_count,
    double? order_served_count,
    double? amount,
    bool? order_success,
    String? qr_code,
    DateTime? table_open_datetime,
    int? man_count,
    int? woman_count,
    int? child_count,
    bool? table_al_la_crate_mode,
    String? buffet_code,
    String? customer_code_or_telephone,
    String? customer_name,
    String? customer_address,
    String? delivery_code,
    String? delivery_number,
    String? delivery_ticket_number,
    String? remark,
    String? open_by_staff_code,
    bool? make_food_immediately,
    bool? is_delivery,
    bool? delivery_cook_success,
    DateTime? delivery_cook_success_datetime,
    bool? delivery_send_success,
    DateTime? delivery_send_success_datetime,
    int? delivery_status,
    int? table_child_count,
    String? detail_discount_formula,
    String? customer_nationality_code,
    bool? isUpdate,
  }) : number = number ?? '',
       number_main = number_main ?? '',
       names = names ?? '',
       zone = zone ?? '',
       table_status = table_status ?? 0,
       order_count = order_count ?? 0,
       order_cancel_count = order_cancel_count ?? 0,
       order_served_count = order_served_count ?? 0,
       amount = amount ?? 0,
       order_success = order_success ?? false,
       qr_code = qr_code ?? '',
       table_open_datetime = table_open_datetime ?? DateTime.now(),
       man_count = man_count ?? 0,
       woman_count = woman_count ?? 0,
       child_count = child_count ?? 0,
       table_al_la_crate_mode = table_al_la_crate_mode ?? false,
       buffet_code = buffet_code ?? '',
       customer_code_or_telephone = customer_code_or_telephone ?? '',
       customer_name = customer_name ?? '',
       customer_address = customer_address ?? '',
       delivery_code = delivery_code ?? '',
       delivery_number = delivery_number ?? '',
       delivery_ticket_number = delivery_ticket_number ?? '',
       remark = remark ?? '',
       open_by_staff_code = open_by_staff_code ?? '',
       make_food_immediately = make_food_immediately ?? false,
       is_delivery = is_delivery ?? false,
       delivery_cook_success = delivery_cook_success ?? false,
       delivery_cook_success_datetime =
           delivery_cook_success_datetime ?? DateTime.now(),
       delivery_send_success = delivery_send_success ?? false,
       delivery_send_success_datetime =
           delivery_send_success_datetime ?? DateTime.now(),
       delivery_status = delivery_status ?? 0,
       table_child_count = table_child_count ?? 0,
       detail_discount_formula = detail_discount_formula ?? '',
       customer_nationality_code = customer_nationality_code ?? '',
       isUpdate = isUpdate ?? false;

  factory TableProcessObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$TableProcessObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$TableProcessObjectBoxStructToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CloseTableModel {
  TableProcessObjectBoxStruct table;

  /// 0=ชำระที่ Cashier,1=ชำระที่โต๊ะเงินสด,2=ชำระที่โต๊ะ QR Code
  int payMode;
  String slipImage;
  PosProcessModel process;
  String discountFormula;
  double roundamount;
  double payAmount;
  String transactionId;
  String payqrcodename;
  String providercode;
  String providername;

  CloseTableModel({
    required this.table,
    required this.payMode,
    required this.slipImage,
    required this.discountFormula,
    required this.payAmount,
    required this.process,
    double? roundamount,
    String? transactionId,
    String? payqrcodename,
    String? providercode,
    String? providername,
  }) : transactionId = transactionId ?? "",
       roundamount = roundamount ?? 0,
       payqrcodename = payqrcodename ?? "",
       providercode = providercode ?? "",
       providername = providername ?? "";

  factory CloseTableModel.fromJson(Map<String, dynamic> json) =>
      _$CloseTableModelFromJson(json);

  Map<String, dynamic> toJson() => _$CloseTableModelToJson(this);
}
