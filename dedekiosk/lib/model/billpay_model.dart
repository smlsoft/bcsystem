import 'package:json_annotation/json_annotation.dart';
part 'billpay_model.g.dart';

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
  })  : due_date = DateTime.now(),
        doc_date_time = DateTime.now();

  factory BillPayObjectBoxStruct.fromJson(Map<String, dynamic> json) => _$BillPayObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$BillPayObjectBoxStructToJson(this);
}
