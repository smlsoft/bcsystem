// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xendit_payment_pay_thai_qr_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

XenditPaymentPayQRResponse _$XenditPaymentPayQRResponseFromJson(
        Map<String, dynamic> json) =>
    XenditPaymentPayQRResponse(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) =>
              XenditPaymentPayQRDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$XenditPaymentPayQRResponseToJson(
        XenditPaymentPayQRResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
    };

XenditPaymentPayQRDetail _$XenditPaymentPayQRDetailFromJson(
        Map<String, dynamic> json) =>
    XenditPaymentPayQRDetail(
      reference_id: json['reference_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      type: json['type'] as String?,
      currency: json['currency'] as String?,
      expires_at: json['expires_at'] as String?,
      channel_code: json['channel_code'] as String?,
      id: json['id'] as String?,
      created: json['created'] as String?,
      updated: json['updated'] as String?,
      qr_string: json['qr_string'] as String?,
      status: json['status'] as String?,
      payment_detail: json['payment_detail'] == null
          ? null
          : XenditPaymentDetail.fromJson(
              json['payment_detail'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$XenditPaymentPayQRDetailToJson(
        XenditPaymentPayQRDetail instance) =>
    <String, dynamic>{
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
      'payment_detail': instance.payment_detail,
    };

XenditPaymentDetail _$XenditPaymentDetailFromJson(Map<String, dynamic> json) =>
    XenditPaymentDetail(
      receipt_id: json['receipt_id'] as String? ?? "",
      name: json['name'] as String? ?? "",
    );

Map<String, dynamic> _$XenditPaymentDetailToJson(
        XenditPaymentDetail instance) =>
    <String, dynamic>{
      'receipt_id': instance.receipt_id,
      'name': instance.name,
    };
