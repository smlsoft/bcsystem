// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'pos_pay_model.g.dart';

@JsonSerializable(explicitToJson: true)
class PosPayModel {
  String cash_amount_text;
  double total_amount; // ยอดรวมทั้งหมด
  double cash_amount; // ยอดชำระเงินสด
  double point_amount; // ยอดชำระด้วย point
  String discount_formula; // สูตรส่วนลด
  double discount_amount; // ยอดส่วนลด
  double total_after_discount; // ยอดรวมหลังหักส่วนลด
  double round_amount; // ยอดปัดเศษ
  double round_amount_cash;
  double round_amount_credit_card;
  double round_amount_transfer;
  double round_amount_cheque;
  double round_amount_coupon;
  double round_amount_qr;
  double round_amount_delivery;
  double round_amount_credit;
  double total_after_round; // ยอดรวมหลังหักส่วนลดและปัดเศษ
  double credit_amount; // ยอดเงินเชื่อ
  bool is_delivery;
  String delivery_code;
  String delivery_number;
  List<PayCreditCardModel> credit_card; // บัตรเครดิต
  List<PayTransferModel> transfer; // เงินโอน
  List<PayChequeModel> cheque; // เช็ค
  List<PayCouponModel> coupon; // คูปอง
  List<PayQrModel> qr;
  PosPayModel({
    this.total_amount = 0,
    this.cash_amount_text = "",
    this.cash_amount = 0,
    this.point_amount = 0,
    this.total_after_discount = 0,
    this.total_after_round = 0,
    this.discount_formula = "",
    this.discount_amount = 0,
    this.credit_amount = 0,
    this.round_amount = 0,
    double? round_amount_cash,
    double? round_amount_credit_card = 0,
    double? round_amount_transfer = 0,
    double? round_amount_cheque = 0,
    double? round_amount_coupon = 0,
    double? round_amount_qr = 0,
    double? round_amount_delivery = 0,
    double? round_amount_credit = 0,
    this.is_delivery = false,
    this.delivery_code = "",
    this.delivery_number = "",
  })  : credit_card = [],
        transfer = [],
        cheque = [],
        coupon = [],
        qr = [],
        round_amount_cash = round_amount_cash ?? cash_amount,
        round_amount_credit_card = round_amount_credit_card ?? credit_amount,
        round_amount_transfer = round_amount_transfer ?? 0,
        round_amount_cheque = round_amount_cheque ?? 0,
        round_amount_coupon = round_amount_coupon ?? 0,
        round_amount_qr = round_amount_qr ?? 0,
        round_amount_delivery = round_amount_delivery ?? 0,
        round_amount_credit = round_amount_credit ?? 0;

  factory PosPayModel.fromJson(Map<String, dynamic> json) => _$PosPayModelFromJson(json);
  Map<String, dynamic> toJson() => _$PosPayModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PayCouponModel {
  String number; // เลขที่คูปอง
  String description; // รายละเอียด
  double discount_amount; // จำนวนเงินส่วนลด
  double cash_voucher_amount; // จำนวนเงิน cash voucher
  int coupon_type; // ประเภทคูปอง (0=discount, 1=percent, 2=cash voucher)

  PayCouponModel({
    required this.number,
    required this.description,
    this.discount_amount = 0.0,
    this.cash_voucher_amount = 0.0,
    this.coupon_type = 0,
  });

  // Helper getter สำหรับ backward compatibility
  double get amount => discount_amount + cash_voucher_amount;

  factory PayCouponModel.fromJson(Map<String, dynamic> json) => _$PayCouponModelFromJson(json);
  Map<String, dynamic> toJson() => _$PayCouponModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PayCashModel {
  String wallet_id; // รหัส
  String amount; // จำนวนเงิน

  PayCashModel({required this.wallet_id, required this.amount});

  factory PayCashModel.fromJson(Map<String, dynamic> json) => _$PayCashModelFromJson(json);
  Map<String, dynamic> toJson() => _$PayCashModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PayCreditCardModel {
  String book_bank_code; // รหัสบัญชีธนาคาร
  String bank_code; // รหัสธนาคาร
  String bank_name; // ธนาคาร
  String card_number; // เลขที่บัตรเครดิต
  String approved_code; // รหัสอนุมัติ
  double amount; // จำนวนเงิน

  PayCreditCardModel({required this.book_bank_code, required this.bank_code, required this.bank_name, required this.card_number, required this.approved_code, required this.amount});

  factory PayCreditCardModel.fromJson(Map<String, dynamic> json) => _$PayCreditCardModelFromJson(json);
  Map<String, dynamic> toJson() => _$PayCreditCardModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PayTransferModel {
  String book_bank_code; // รหัสบัญชีธนาคาร
  String bank_code; // รหัสธนาคาร
  String bank_name; // ธนาคาร
  double amount; // จำนวนเงิน

  PayTransferModel({required this.book_bank_code, required this.bank_code, required this.bank_name, required this.amount});

  factory PayTransferModel.fromJson(Map<String, dynamic> json) => _$PayTransferModelFromJson(json);
  Map<String, dynamic> toJson() => _$PayTransferModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PayChequeModel {
  DateTime due_date; // วันที่สั่งจ่ายบนเช็ค
  String bank_code; // รหัสธนาคาร
  String bank_name; // ธนาคาร
  String branch_number; // สาขาธนาคาร
  String cheque_number; // เลขที่เช็ค
  double amount; // จำนวนเงิน

  PayChequeModel({required this.due_date, required this.bank_code, required this.bank_name, required this.branch_number, required this.cheque_number, required this.amount});

  factory PayChequeModel.fromJson(Map<String, dynamic> json) => _$PayChequeModelFromJson(json);
  Map<String, dynamic> toJson() => _$PayChequeModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PayDiscountModel {
  String code; // รหัสส่วนลด
  String description; // รายละเอียด (เพิ่มเติม)
  String formula; // สูตร
  double amount; // มูลค่าส่วนลด

  PayDiscountModel({required this.code, required this.description, required this.formula, required this.amount});

  factory PayDiscountModel.fromJson(Map<String, dynamic> json) => _$PayDiscountModelFromJson(json);
  Map<String, dynamic> toJson() => _$PayDiscountModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PayQrModel {
  String provider_code; // รหัสกระเป๋า เจ้าของเงิน (Provider)
  String provider_name; // เจ้าของเงิน (Provider)
  String description; // รายละเอียด (อื่นๆ)
  String transactionId; // เลขที่อ้างอิงการทำรายการ
  String logo;
  double amount; // จำนวนเงิน

  PayQrModel({this.provider_code = "", this.provider_name = "", this.description = "", String? transactionId, required this.amount, this.logo = ""}) : transactionId = transactionId ?? "";

  factory PayQrModel.fromJson(Map<String, dynamic> json) => _$PayQrModelFromJson(json);
  Map<String, dynamic> toJson() => _$PayQrModelToJson(this);
}
