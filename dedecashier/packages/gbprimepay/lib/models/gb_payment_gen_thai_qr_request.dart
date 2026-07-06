import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gb_payment_gen_thai_qr_request.g.dart';

@JsonSerializable()
class GBPaymentGenQRRequest {
  final String referenceNo;
  final Decimal amount;
  String? token;

  GBPaymentGenQRRequest({required this.referenceNo, required this.amount});

  Map<String, dynamic> toJson() => _$GBPaymentGenQRRequestToJson(this);
  factory GBPaymentGenQRRequest.fromJson(Map<String, dynamic> json) =>
      _$GBPaymentGenQRRequestFromJson(json);
}
