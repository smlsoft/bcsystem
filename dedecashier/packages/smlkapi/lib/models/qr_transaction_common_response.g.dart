// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_transaction_common_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QRTransactionCommonResponse _$QRTransactionCommonResponseFromJson(
        Map<String, dynamic> json) =>
    QRTransactionCommonResponse(
      partnerTxnUid: json['partnerTxnUid'] as String,
      partnerId: json['partnerId'] as String,
      statusCode: json['statusCode'] as String,
      errorCode: json['errorCode'] as String,
      errorDesc: json['errorDesc'] as String,
    );

Map<String, dynamic> _$QRTransactionCommonResponseToJson(
        QRTransactionCommonResponse instance) =>
    <String, dynamic>{
      'partnerTxnUid': instance.partnerTxnUid,
      'partnerId': instance.partnerId,
      'statusCode': instance.statusCode,
      'errorCode': instance.errorCode,
      'errorDesc': instance.errorDesc,
    };
