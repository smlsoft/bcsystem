import 'package:json_annotation/json_annotation.dart';

part 'xendit_payment_gen_thai_qr_request.g.dart';

@JsonSerializable()
class XenditPaymentGenQRRequest {
  String reference_id;
  double amount;
  String type;
  String currency;
  String expires_at;
  String token;

  XenditPaymentGenQRRequest({required this.reference_id, required this.amount, required this.type, required this.currency, required this.expires_at, String? token = ""})
      : token = token ?? "";

  Map<String, dynamic> toJson() => _$XenditPaymentGenQRRequestToJson(this);
  factory XenditPaymentGenQRRequest.fromJson(Map<String, dynamic> json) => _$XenditPaymentGenQRRequestFromJson(json);
}
