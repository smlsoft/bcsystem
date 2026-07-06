// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gb_payment_gen_qr_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GBPaymentGenQRResponse _$GBPaymentGenQRResponseFromJson(
        Map<String, dynamic> json) =>
    GBPaymentGenQRResponse(
      resultCode: json['resultCode'] as String,
      resultMessage: json['resultMessage'] as String,
    )
      ..referenceNo = json['referenceNo'] as String?
      ..qrcode = json['qrcode'] as String?
      ..gbpReferenceNo = json['gbpReferenceNo'] as String?;

Map<String, dynamic> _$GBPaymentGenQRResponseToJson(
        GBPaymentGenQRResponse instance) =>
    <String, dynamic>{
      'resultCode': instance.resultCode,
      'resultMessage': instance.resultMessage,
      'referenceNo': instance.referenceNo,
      'qrcode': instance.qrcode,
      'gbpReferenceNo': instance.gbpReferenceNo,
    };
