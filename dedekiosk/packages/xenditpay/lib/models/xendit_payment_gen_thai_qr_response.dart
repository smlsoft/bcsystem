import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

part 'xendit_payment_gen_thai_qr_response.g.dart';

@JsonSerializable()
class XenditPaymentGenQRResponse {
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

  XenditPaymentGenQRResponse(
      {required this.reference_id,
      required this.amount,
      required this.type,
      required this.currency,
      required this.expires_at,
      required this.channel_code,
      required this.id,
      required this.created,
      required this.updated,
      required this.qr_string,
      required this.status});

  Map<String, dynamic> toJson() => _$XenditPaymentGenQRResponseToJson(this);
  factory XenditPaymentGenQRResponse.fromJson(Map<String, dynamic> json) => _$XenditPaymentGenQRResponseFromJson(json);
}
