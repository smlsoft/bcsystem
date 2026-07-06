// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xendit_payment_gen_thai_qr_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

XenditPaymentGenQRResponse _$XenditPaymentGenQRResponseFromJson(Map<String, dynamic> json) => XenditPaymentGenQRResponse(
      reference_id: json['reference_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      currency: json['currency'] as String,
      expires_at: json['expires_at'] as String,
      channel_code: json['channel_code'] as String,
      id: json['id'] as String,
      created: json['created'] as String,
      updated: json['updated'] as String,
      qr_string: json['qr_string'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$XenditPaymentGenQRResponseToJson(XenditPaymentGenQRResponse instance) => <String, dynamic>{
      'reference_id': instance.reference_id,
      'amount': instance.amount,
      'type': instance.type,
      'currency': instance.currency,
      'expires_at': instance.expires_at,
      'channel_code': instance.channel_code,
      'id': instance.id,
      'created': instance.created,
      'updated': instance.updated,
      'qr_string': instance.qr_string,
      'status': instance.status,
    };
