// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_payment_status_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QRPaymentStatusResponse _$QRPaymentStatusResponseFromJson(
        Map<String, dynamic> json) =>
    QRPaymentStatusResponse(
      txnUid: json['txnUid'] as String,
      txnStatus: json['txnStatus'] as String,
      txnNo: json['txnNo'] as String,
      txnAmount: (json['txnAmount'] as num).toDouble(),
      approvalCode: json['approvalCode'] as String?,
      channel: json['channel'] as String,
      terminalId: json['terminalId'] as String,
      qrType: json['qrType'] as String,
    );

Map<String, dynamic> _$QRPaymentStatusResponseToJson(
        QRPaymentStatusResponse instance) =>
    <String, dynamic>{
      'txnUid': instance.txnUid,
      'txnStatus': instance.txnStatus,
      'txnNo': instance.txnNo,
      'txnAmount': instance.txnAmount,
      'channel': instance.channel,
      'terminalId': instance.terminalId,
      'qrType': instance.qrType,
      'approvalCode': instance.approvalCode,
    };
