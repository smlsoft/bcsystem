import 'package:json_annotation/json_annotation.dart';

part 'payment_response.g.dart';

@JsonSerializable()
class PaymentGenQRResponse {
  int id;
  String status;

  PaymentGenQRResponse({
    required this.id,
    String? status,
  }) : status = status ?? "";

  Map<String, dynamic> toJson() => _$PaymentGenQRResponseToJson(this);
  factory PaymentGenQRResponse.fromJson(Map<String, dynamic> json) => _$PaymentGenQRResponseFromJson(json);
}
