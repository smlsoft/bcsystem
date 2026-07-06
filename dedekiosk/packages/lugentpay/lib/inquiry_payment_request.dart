import 'package:json_annotation/json_annotation.dart';

part 'inquiry_payment_request.g.dart';

@JsonSerializable()
class InquiryPaymentRequest {
  InquiryPaymentRequest({required this.transactionId, this.accessCode});

  final String transactionId;
  String? accessCode;

  factory InquiryPaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$InquiryPaymentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$InquiryPaymentRequestToJson(this);
}
