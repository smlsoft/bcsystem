// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inquiry_payment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InquiryPaymentResponse _$InquiryPaymentResponseFromJson(
        Map<String, dynamic> json) =>
    InquiryPaymentResponse(
      res_code: json['res_code'] as String,
      res_desc: json['res_desc'] as String,
      transactionId: json['transactionId'] as String,
      paymentId: json['paymentId'] as String,
    );

Map<String, dynamic> _$InquiryPaymentResponseToJson(
        InquiryPaymentResponse instance) =>
    <String, dynamic>{
      'res_code': instance.res_code,
      'res_desc': instance.res_desc,
      'transactionId': instance.transactionId,
      'paymentId': instance.paymentId,
    };
