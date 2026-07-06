// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'send_money_model.g.dart';

@JsonSerializable()
class SendMoneyModel {
  late DateTime create_date_time;
  late DateTime doc_date_time;
  late String doc_number;
  late String person_code;
  late String pos_number;
  late String remark;
  late double receive_money;
  late double send_cash;
  late double send_coupon;
  late double send_credit;
  late double send_transfer;
  late double send_cheque;
  late double send_discount;
  late double send_wallet;
  late double total_send_money;
  late double send_promptpay;
  late int send_coupon_count;
  late int send_credit_count;
  late int send_transfer_count;
  late int send_cheque_count;
  late int send_discount_count;
  late int send_wallet_count;
  late int send_promptpay_count;

  SendMoneyModel({
    required this.create_date_time,
    required this.doc_date_time,
    this.remark = "",
    this.doc_number = "",
    this.person_code = "",
    this.pos_number = "",
    this.receive_money = 0,
    this.send_cash = 0,
    this.send_coupon = 0,
    this.send_credit = 0,
    this.send_transfer = 0,
    this.send_cheque = 0,
    this.send_discount = 0,
    this.send_wallet = 0,
    this.send_promptpay = 0,
    this.total_send_money = 0,
    this.send_coupon_count = 0,
    this.send_credit_count = 0,
    this.send_transfer_count = 0,
    this.send_cheque_count = 0,
    this.send_discount_count = 0,
    this.send_wallet_count = 0,
    this.send_promptpay_count = 0,
  });

  factory SendMoneyModel.fromJson(Map<String, dynamic> json) => _$SendMoneyModelFromJson(json);
  Map<String, dynamic> toJson() => _$SendMoneyModelToJson(this);
  /*SendMoneyStruct.map(dynamic obj) {
    doc_date_time = obj["doc_date_time"];
    doc_number = obj["doc_number"];
    create_date_time = DateTime.tryParse(obj["create_date_time"])!;    person_code = obj["emp_code"];
    pos_number = obj["pos_number"];
    receive_money = double.tryParse(obj["receive_money"].toString()) ?? 0.0;
    send_cash = double.tryParse(obj["send_cash"].toString()) ?? 0.0;
    send_coupon = double.tryParse(obj["send_coupon"].toString()) ?? 0.0;
    send_credit = double.tryParse(obj["send_credit"].toString()) ?? 0.0;
    send_transfer = double.tryParse(obj["send_transfer"].toString()) ?? 0.0;
    send_cheque = double.tryParse(obj["send_cheque"].toString()) ?? 0.0;
    send_discount = double.tryParse(obj["send_discount"].toString()) ?? 0.0;
    send_wallet = double.tryParse(obj["send_wallet"].toString()) ?? 0.0;
    total_send_money = double.tryParse(obj["total_sendmoney"].toString()) ?? 0.0;
    send_coupon_count = int.tryParse(obj["send_coupon_count"].toString()) ?? 0;
    send_credit_count = int.tryParse(obj["send_credit_count"].toString()) ?? 0;
    send_transfer_count = int.tryParse(obj["send_transfer_count"].toString()) ?? 0;
    send_cheque_count = int.tryParse(obj["send_cheque_count"].toString()) ?? 0;
    send_discount_count = int.tryParse(obj["send_discount_count"].toString()) ?? 0;
    send_wallet_count = int.tryParse(obj["send_wallet_count"].toString()) ?? 0;
  }

  Map<String, dynamic> toMap() {
    var _map = <String, dynamic>{};
    _map["doc_date_time"] = doc_date_time;
    _map["doc_number"] = doc_number;
    _map["emp_code"] = person_code;
    _map["pos_number"] = pos_number;
    _map["receive_money"] = receive_money;
    _map["send_cash"] = send_cash;
    _map["send_coupon"] = send_coupon;
    _map["send_credit"] = send_credit;
    _map["send_transfer"] = send_transfer;
    _map["send_cheque"] = send_cheque;
    _map["send_discount"] = send_discount;
    _map["send_wallet"] = send_wallet;
    _map["total_sendmoney"] = total_send_money;
    _map["send_coupon_count"] = send_coupon_count;
    _map["send_credit_count"] = send_credit_count;
    _map["send_transfer_count"] = send_transfer_count;
    _map["send_cheque_count"] = send_cheque_count;
    _map["send_discount_count"] = send_discount_count;
    _map["send_wallet_count"] = send_wallet_count;
    return _map;
  }*/
}
