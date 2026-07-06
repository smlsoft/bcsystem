import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

part 'qrpayment_request.g.dart';

@JsonSerializable()
class QRPaymentRequest {
  QRPaymentRequest(
      {required this.billerCode,
      required this.billerID,
      required this.ref1,
      required this.ref2,
      required this.amount,
      required this.storeID,
      required this.terminalID,
      required this.merchantName,
      this.accessCode,
      this.currencyCode,
      this.productName,
      this.productDescription,
      this.productImageUrl});

  final String billerCode;
  final String billerID;
  final String ref1;
  final String ref2;
  final Decimal amount;
  final String storeID;
  final String terminalID;
  final String merchantName;
  String? accessCode;
  String? currencyCode;
  String? productName;
  String? productDescription;
  String? productImageUrl;

  factory QRPaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$QRPaymentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$QRPaymentRequestToJson(this);
}
