import 'package:json_annotation/json_annotation.dart';

part 'qr_payment_status_response.g.dart';

@JsonSerializable()
class QRPaymentStatusResponse {
  final String txnUid;
  final String txnStatus;
  final String txnNo;
  final double txnAmount;
  final String channel;
  final String terminalId;
  final String qrType;
  String? approvalCode;

  QRPaymentStatusResponse({
    required this.txnUid,
    required this.txnStatus,
    required this.txnNo,
    required this.txnAmount,
    this.approvalCode,
    required this.channel,
    required this.terminalId,
    required this.qrType,
  });

  factory QRPaymentStatusResponse.fromJson(Map<String, dynamic> json) => _$QRPaymentStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$QRPaymentStatusResponseToJson(this);

  bool IsPaided() {
    return txnStatus == "PAID";
  }

  bool IsError() {
    return txnStatus == "ERROR";
  }
}
