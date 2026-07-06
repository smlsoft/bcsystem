import 'package:json_annotation/json_annotation.dart';

part 'qr_transaction_response.g.dart';

@JsonSerializable()
class QRTransactionResponse {
  String txnUid;
  String txnStatus;
  String merchantId;
  String txnNo;
  double amount;
  String channel;
  String terminalId;
  String qrType;
  String paymentStatus;
  String UpdatedAt;

  QRTransactionResponse({
    String? txnUid,
    String? txnStatus,
    String? merchantId,
    String? txnNo,
    double? amount,
    String? channel,
    String? terminalId,
    String? qrType,
    String? paymentStatus,
    String? updatedAt,
  })  : txnUid = txnUid ?? "",
        txnStatus = txnStatus ?? "",
        merchantId = merchantId ?? "",
        txnNo = txnNo ?? "",
        amount = amount ?? 0.0,
        channel = channel ?? "",
        terminalId = terminalId ?? "",
        qrType = qrType ?? "",
        paymentStatus = paymentStatus ?? "",
        UpdatedAt = updatedAt ?? "";

  factory QRTransactionResponse.fromJson(Map<String, dynamic> json) => _$QRTransactionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$QRTransactionResponseToJson(this);

  bool IsPaided() {
    return txnStatus == "PAID";
  }

  bool IsError() {
    return txnStatus == "ERROR";
  }
}
