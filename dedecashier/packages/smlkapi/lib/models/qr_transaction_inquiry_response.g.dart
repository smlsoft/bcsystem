// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_transaction_inquiry_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QRTransactionInquiryResponse _$QRTransactionInquiryResponseFromJson(
        Map<String, dynamic> json) =>
    QRTransactionInquiryResponse(
      partnerTxnUid: json['partnerTxnUid'] as String,
      partnerId: json['partnerId'] as String,
      statusCode: json['statusCode'] as String,
      errorCode: json['errorCode'] as String,
      errorDesc: json['errorDesc'] as String,
      txnStatus: json['txnStatus'] as String,
      txnNo: json['txnNo'] as String?,
      loyaltyId: json['loyaltyId'] as String?,
      channel: json['channel'] as String?,
      merchantId: json['merchantId'] as String,
      terminalId: json['terminalId'] as String,
      qrType: json['qrType'] as String,
      txnAmount: json['txnAmount'] as String,
      txnCurrencyCode: json['txnCurrencyCode'] as String,
      reference1: json['reference1'] as String,
      reference2: json['reference2'] as String,
      reference3: json['reference3'] as String,
      reference4: json['reference4'] as String,
    );

Map<String, dynamic> _$QRTransactionInquiryResponseToJson(
        QRTransactionInquiryResponse instance) =>
    <String, dynamic>{
      'partnerTxnUid': instance.partnerTxnUid,
      'partnerId': instance.partnerId,
      'statusCode': instance.statusCode,
      'errorCode': instance.errorCode,
      'errorDesc': instance.errorDesc,
      'txnStatus': instance.txnStatus,
      'txnNo': instance.txnNo,
      'loyaltyId': instance.loyaltyId,
      'channel': instance.channel,
      'merchantId': instance.merchantId,
      'terminalId': instance.terminalId,
      'qrType': instance.qrType,
      'txnAmount': instance.txnAmount,
      'txnCurrencyCode': instance.txnCurrencyCode,
      'reference1': instance.reference1,
      'reference2': instance.reference2,
      'reference3': instance.reference3,
      'reference4': instance.reference4,
    };
