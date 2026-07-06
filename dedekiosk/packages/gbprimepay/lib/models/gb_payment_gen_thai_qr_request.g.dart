// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gb_payment_gen_thai_qr_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GBPaymentGenQRRequest _$GBPaymentGenQRRequestFromJson(
        Map<String, dynamic> json) =>
    GBPaymentGenQRRequest(
      referenceNo: json['referenceNo'] as String,
      amount: Decimal.fromJson(json['amount'] as String),
    )..token = json['token'] as String?;

Map<String, dynamic> _$GBPaymentGenQRRequestToJson(
        GBPaymentGenQRRequest instance) =>
    <String, dynamic>{
      'referenceNo': instance.referenceNo,
      'amount': instance.amount,
      'token': instance.token,
    };
