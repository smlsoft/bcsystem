import 'package:json_annotation/json_annotation.dart';

part 'xendit_payment_pay_thai_qr_response.g.dart';

@JsonSerializable()
class XenditPaymentPayQRResponse {
  List<XenditPaymentPayQRDetail> data;

  XenditPaymentPayQRResponse({List<XenditPaymentPayQRDetail>? data}) : data = data ?? <XenditPaymentPayQRDetail>[];

  Map<String, dynamic> toJson() => _$XenditPaymentPayQRResponseToJson(this);
  factory XenditPaymentPayQRResponse.fromJson(Map<String, dynamic> json) => _$XenditPaymentPayQRResponseFromJson(json);
}

@JsonSerializable()
class XenditPaymentPayQRDetail {
  String reference_id;
  double amount;
  String type;
  String currency;
  String expires_at;
  String channel_code;
  String id;
  String created;
  String updated;
  String qr_string;
  String status;
  XenditPaymentDetail payment_detail;

  XenditPaymentPayQRDetail(
      {String? reference_id,
      double? amount,
      String? type,
      String? currency,
      String? expires_at,
      String? channel_code,
      String? id,
      String? created,
      String? updated,
      String? qr_string,
      String? status,
      XenditPaymentDetail? payment_detail})
      : reference_id = reference_id ?? "",
        amount = amount ?? 0.0,
        type = type ?? "",
        currency = currency ?? "",
        expires_at = expires_at ?? "",
        channel_code = channel_code ?? "",
        id = id ?? "",
        created = created ?? "",
        updated = updated ?? "",
        qr_string = qr_string ?? "",
        status = status ?? "",
        payment_detail = payment_detail ?? XenditPaymentDetail();

  Map<String, dynamic> toJson() => _$XenditPaymentPayQRDetailToJson(this);
  factory XenditPaymentPayQRDetail.fromJson(Map<String, dynamic> json) => _$XenditPaymentPayQRDetailFromJson(json);
}

@JsonSerializable()
class XenditPaymentDetail {
  String receipt_id;
  String name;

  XenditPaymentDetail({String? receipt_id = "", String? name = ""})
      : receipt_id = receipt_id ?? "",
        name = name ?? "";

  Map<String, dynamic> toJson() => _$XenditPaymentDetailToJson(this);
  factory XenditPaymentDetail.fromJson(Map<String, dynamic> json) => _$XenditPaymentDetailFromJson(json);
}
