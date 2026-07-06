// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_generate_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QRGenerateRequest _$QRGenerateRequestFromJson(Map<String, dynamic> json) =>
    QRGenerateRequest(
      amount: (json['amount'] as num).toDouble(),
      ref1: json['ref1'] as String,
      ref2: json['ref2'] as String,
      ref3: json['ref3'] as String,
      ref4: json['ref4'] as String,
    );

Map<String, dynamic> _$QRGenerateRequestToJson(QRGenerateRequest instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'ref1': instance.ref1,
      'ref2': instance.ref2,
      'ref3': instance.ref3,
      'ref4': instance.ref4,
    };
