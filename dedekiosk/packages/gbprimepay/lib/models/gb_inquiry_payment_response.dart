import 'package:gbprimepay/models/gb_inquiry_txn.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gb_inquiry_payment_response.g.dart';

@JsonSerializable()
class GBInquiryPaymentResponse {
  final String resultCode;
  final String resultMessage;
  GBInquiryTxn? txn;

  GBInquiryPaymentResponse(
      {required this.resultCode, required this.resultMessage});

  Map<String, dynamic> toJson() => _$GBInquiryPaymentResponseToJson(this);
  factory GBInquiryPaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$GBInquiryPaymentResponseFromJson(json);

  bool isPaymentSuccess() {
    if (txn == null) {
      return false;
    }

    return txn != null && txn!.status == "S";
  }
}
