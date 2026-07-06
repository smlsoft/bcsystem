// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_generate_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QRGenerateResponse _$QRGenerateResponseFromJson(Map<String, dynamic> json) =>
    QRGenerateResponse(
      txnUid: json['txnUid'] as String,
      partnerId: json['partnerId'] as String,
      statusCode: json['statusCode'] as String,
      errorCode: json['errorCode'] as String,
      errorDesc: json['errorDesc'] as String,
      accountName: json['accountName'] as String,
      qrCode: json['qrCode'] as String,
      qrType: json['qrType'] as String,
    );

Map<String, dynamic> _$QRGenerateResponseToJson(QRGenerateResponse instance) =>
    <String, dynamic>{
      'txnUid': instance.txnUid,
      'partnerId': instance.partnerId,
      'statusCode': instance.statusCode,
      'errorCode': instance.errorCode,
      'errorDesc': instance.errorDesc,
      'accountName': instance.accountName,
      'qrCode': instance.qrCode,
      'qrType': instance.qrType,
    };
