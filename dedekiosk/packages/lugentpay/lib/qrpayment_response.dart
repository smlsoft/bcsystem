import 'package:json_annotation/json_annotation.dart';

part 'qrpayment_response.g.dart';

@JsonSerializable()
class QRPaymentResponse {
  QRPaymentResponse(
      {required this.res_code,
      required this.res_desc,
      required this.transactionId,
      required this.qrCode});

  final String res_code;
  final String res_desc;
  final String transactionId;
  final String qrCode;

  factory QRPaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$QRPaymentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$QRPaymentResponseToJson(this);

  bool isSuccess() {
    if (this.res_code == "00") return true;
    return false;
  }
}
