// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_transaction_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QRTransactionResponse _$QRTransactionResponseFromJson(
        Map<String, dynamic> json) =>
    QRTransactionResponse(
      txnUid: json['txnUid'] as String?,
      txnStatus: json['txnStatus'] as String?,
      merchantId: json['merchantId'] as String?,
      txnNo: json['txnNo'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      channel: json['channel'] as String?,
      terminalId: json['terminalId'] as String?,
      qrType: json['qrType'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
    )..UpdatedAt = json['UpdatedAt'] as String;

Map<String, dynamic> _$QRTransactionResponseToJson(
        QRTransactionResponse instance) =>
    <String, dynamic>{
      'txnUid': instance.txnUid,
      'txnStatus': instance.txnStatus,
      'merchantId': instance.merchantId,
      'txnNo': instance.txnNo,
      'amount': instance.amount,
      'channel': instance.channel,
      'terminalId': instance.terminalId,
      'qrType': instance.qrType,
      'paymentStatus': instance.paymentStatus,
      'UpdatedAt': instance.UpdatedAt,
    };
