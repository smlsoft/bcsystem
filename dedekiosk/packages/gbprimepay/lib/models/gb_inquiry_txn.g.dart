// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gb_inquiry_txn.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GBInquiryTxn _$GBInquiryTxnFromJson(Map<String, dynamic> json) => GBInquiryTxn(
      referenceNo: json['referenceNo'] as String,
      gbpReferenceNo: json['gbpReferenceNo'] as String,
      amount: Decimal.fromJson(json['amount'] as String),
    )
      ..status = json['status'] as String?
      ..paymentType = json['paymentType'] as String?
      ..merchantDefined1 = json['merchantDefined1'] as String?
      ..merchantDefined2 = json['merchantDefined2'] as String?
      ..merchantDefined3 = json['merchantDefined3'] as String?
      ..merchantDefined4 = json['merchantDefined4'] as String?
      ..merchantDefined5 = json['merchantDefined5'] as String?;

Map<String, dynamic> _$GBInquiryTxnToJson(GBInquiryTxn instance) =>
    <String, dynamic>{
      'referenceNo': instance.referenceNo,
      'gbpReferenceNo': instance.gbpReferenceNo,
      'amount': instance.amount,
      'status': instance.status,
      'paymentType': instance.paymentType,
      'merchantDefined1': instance.merchantDefined1,
      'merchantDefined2': instance.merchantDefined2,
      'merchantDefined3': instance.merchantDefined3,
      'merchantDefined4': instance.merchantDefined4,
      'merchantDefined5': instance.merchantDefined5,
    };
