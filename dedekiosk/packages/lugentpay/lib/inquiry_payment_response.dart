import 'package:json_annotation/json_annotation.dart';

part 'inquiry_payment_response.g.dart';

@JsonSerializable()
class InquiryPaymentResponse {
  InquiryPaymentResponse(
      {required this.res_code,
      required this.res_desc,
      required this.transactionId,
      required this.paymentId});

  final String res_code;
  final String res_desc;
  final String transactionId;
  final String paymentId;

  factory InquiryPaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$InquiryPaymentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$InquiryPaymentResponseToJson(this);

  bool isApproved() {
    if (this.res_code == "00") return true;
    return false;
  }
}
