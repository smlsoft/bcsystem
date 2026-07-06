// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentGenQRResponse _$PaymentGenQRResponseFromJson(Map<String, dynamic> json) => PaymentGenQRResponse(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String?,
    );

Map<String, dynamic> _$PaymentGenQRResponseToJson(PaymentGenQRResponse instance) => <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
    };
