// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qrpayment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QRPaymentResponse _$QRPaymentResponseFromJson(Map<String, dynamic> json) =>
    QRPaymentResponse(
      res_code: json['res_code'] as String,
      res_desc: json['res_desc'] as String,
      transactionId: json['transactionId'] as String,
      qrCode: json['qrCode'] as String,
    );

Map<String, dynamic> _$QRPaymentResponseToJson(QRPaymentResponse instance) =>
    <String, dynamic>{
      'res_code': instance.res_code,
      'res_desc': instance.res_desc,
      'transactionId': instance.transactionId,
      'qrCode': instance.qrCode,
    };
