// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inquiry_payment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InquiryPaymentRequest _$InquiryPaymentRequestFromJson(
        Map<String, dynamic> json) =>
    InquiryPaymentRequest(
      transactionId: json['transactionId'] as String,
      accessCode: json['accessCode'] as String?,
    );

Map<String, dynamic> _$InquiryPaymentRequestToJson(
        InquiryPaymentRequest instance) =>
    <String, dynamic>{
      'transactionId': instance.transactionId,
      'accessCode': instance.accessCode,
    };
