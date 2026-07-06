// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xendit_payment_gen_thai_qr_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

XenditPaymentGenQRRequest _$XenditPaymentGenQRRequestFromJson(
        Map<String, dynamic> json) =>
    XenditPaymentGenQRRequest(
      reference_id: json['reference_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      currency: json['currency'] as String,
      expires_at: json['expires_at'] as String,
      token: json['token'] as String? ?? "",
    );

Map<String, dynamic> _$XenditPaymentGenQRRequestToJson(
        XenditPaymentGenQRRequest instance) =>
    <String, dynamic>{
      'reference_id': instance.reference_id,
      'amount': instance.amount,
      'type': instance.type,
      'currency': instance.currency,
      'expires_at': instance.expires_at,
      'token': instance.token,
    };
