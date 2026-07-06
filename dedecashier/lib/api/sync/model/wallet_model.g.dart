// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletModel _$WalletModelFromJson(Map<String, dynamic> json) => WalletModel(
  code: json['code'] as String,
  apiKey: json['apiKey'] as String,
  bookbankcode: json['bookbankcode'] as String,
  paymentlogo: json['paymentlogo'] as String,
  paymenttype: (json['paymenttype'] as num).toInt(),
  feeRate: (json['feeRate'] as num).toDouble(),
  wallettype: (json['wallettype'] as num).toInt(),
  names: (json['names'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  billerCode: json['billerCode'] as String,
  billerID: json['billerID'] as String,
  storeID: json['storeID'] as String,
  terminalID: json['terminalID'] as String,
);

Map<String, dynamic> _$WalletModelToJson(WalletModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'names': instance.names,
      'paymenttype': instance.paymenttype,
      'bookbankcode': instance.bookbankcode,
      'paymentlogo': instance.paymentlogo,
      'feeRate': instance.feeRate,
      'wallettype': instance.wallettype,
      'apiKey': instance.apiKey,
      'billerCode': instance.billerCode,
      'billerID': instance.billerID,
      'storeID': instance.storeID,
      'terminalID': instance.terminalID,
    };
