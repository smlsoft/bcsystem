import 'package:json_annotation/json_annotation.dart';

part 'gb_inquiry_payment_request.g.dart';

@JsonSerializable()
class GBInquiryPaymentRequest {
  final String referenceNo;

  GBInquiryPaymentRequest({required this.referenceNo});

  Map<String, dynamic> toJson() => _$GBInquiryPaymentRequestToJson(this);
  factory GBInquiryPaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$GBInquiryPaymentRequestFromJson(json);
}
