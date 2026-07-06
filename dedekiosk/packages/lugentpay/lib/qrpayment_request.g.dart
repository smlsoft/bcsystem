// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qrpayment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QRPaymentRequest _$QRPaymentRequestFromJson(Map<String, dynamic> json) =>
    QRPaymentRequest(
      billerCode: json['billerCode'] as String,
      billerID: json['billerID'] as String,
      ref1: json['ref1'] as String,
      ref2: json['ref2'] as String,
      amount: Decimal.fromJson(json['amount'] as String),
      storeID: json['storeID'] as String,
      terminalID: json['terminalID'] as String,
      merchantName: json['merchantName'] as String,
      accessCode: json['accessCode'] as String?,
      currencyCode: json['currencyCode'] as String?,
      productName: json['productName'] as String?,
      productDescription: json['productDescription'] as String?,
      productImageUrl: json['productImageUrl'] as String?,
    );

Map<String, dynamic> _$QRPaymentRequestToJson(QRPaymentRequest instance) =>
    <String, dynamic>{
      'billerCode': instance.billerCode,
      'billerID': instance.billerID,
      'ref1': instance.ref1,
      'ref2': instance.ref2,
      'amount': instance.amount,
      'storeID': instance.storeID,
      'terminalID': instance.terminalID,
      'merchantName': instance.merchantName,
      'accessCode': instance.accessCode,
      'currencyCode': instance.currencyCode,
      'productName': instance.productName,
      'productDescription': instance.productDescription,
      'productImageUrl': instance.productImageUrl,
    };
