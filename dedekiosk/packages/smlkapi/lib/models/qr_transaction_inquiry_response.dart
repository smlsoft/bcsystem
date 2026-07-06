import 'package:json_annotation/json_annotation.dart';

part 'qr_transaction_inquiry_response.g.dart';

@JsonSerializable()
class QRTransactionInquiryResponse {
  final String partnerTxnUid;
  final String partnerId;
  final String statusCode;
  final String errorCode;
  final String errorDesc;
  final String txnStatus;
  String? txnNo;
  String? loyaltyId;
  String? channel;
  final String merchantId;
  final String terminalId;
  final String qrType;
  final String txnAmount;
  final String txnCurrencyCode;
  final String reference1;
  final String reference2;
  final String reference3;
  final String reference4;

  QRTransactionInquiryResponse({
    required this.partnerTxnUid,
    required this.partnerId,
    required this.statusCode,
    required this.errorCode,
    required this.errorDesc,
    required this.txnStatus,
    this.txnNo,
    this.loyaltyId,
    this.channel,
    required this.merchantId,
    required this.terminalId,
    required this.qrType,
    required this.txnAmount,
    required this.txnCurrencyCode,
    required this.reference1,
    required this.reference2,
    required this.reference3,
    required this.reference4,
  });

  factory QRTransactionInquiryResponse.fromJson(Map<String, dynamic> json) =>
      _$QRTransactionInquiryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$QRTransactionInquiryResponseToJson(this);
}
