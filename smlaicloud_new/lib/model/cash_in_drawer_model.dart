import 'package:json_annotation/json_annotation.dart';

part 'cash_in_drawer_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CashInDrawerModel {
  String? guidfixed;
  String? usercode;
  String? username;
  String? posid;
  String? docno;
  int? doctype;
  String? docdate;
  String? remark;
  double? amount;
  double? creditcard;
  double? promptpay;
  double? transfer;
  double? cheque;
  double? coupon;

  CashInDrawerModel({
    String? guidfixed,
    String? usercode,
    String? username,
    String? posid,
    String? docno,
    int? doctype,
    String? docdate,
    String? remark,
    double? amount,
    double? creditcard,
    double? promptpay,
    double? transfer,
    double? cheque,
    double? coupon,
  })  : guidfixed = guidfixed ?? '',
        usercode = usercode ?? '',
        username = username ?? '',
        posid = posid ?? '',
        docno = docno ?? '',
        doctype = doctype ?? 0,
        docdate = docdate ?? '',
        remark = remark ?? '',
        amount = amount ?? 0.0,
        creditcard = creditcard ?? 0.0,
        promptpay = promptpay ?? 0.0,
        transfer = transfer ?? 0.0,
        cheque = cheque ?? 0.0,
        coupon = coupon ?? 0.0;

  factory CashInDrawerModel.fromJson(Map<String, dynamic> json) =>
      _$CashInDrawerModelFromJson(json);

  Map<String, dynamic> toJson() => _$CashInDrawerModelToJson(this);

  String get doctypeText {
    switch (doctype) {
      case 1:
        return 'เปิดกะ';
      case 2:
        return 'ปิดกะ';
      case 3:
        return 'เพิ่มเงินในลิ้นชัก';
      case 4:
        return 'ถอนเงิน';
      default:
        return 'ไม่ระบุ';
    }
  }

  bool get isCashIn => doctype == 1 || doctype == 3;
}
