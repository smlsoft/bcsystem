// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gb_inquiry_payment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GBInquiryPaymentResponse _$GBInquiryPaymentResponseFromJson(
        Map<String, dynamic> json) =>
    GBInquiryPaymentResponse(
      resultCode: json['resultCode'] as String,
      resultMessage: json['resultMessage'] as String,
    )..txn = json['txn'] == null
        ? null
        : GBInquiryTxn.fromJson(json['txn'] as Map<String, dynamic>);

Map<String, dynamic> _$GBInquiryPaymentResponseToJson(
        GBInquiryPaymentResponse instance) =>
    <String, dynamic>{
      'resultCode': instance.resultCode,
      'resultMessage': instance.resultMessage,
      'txn': instance.txn,
    };
