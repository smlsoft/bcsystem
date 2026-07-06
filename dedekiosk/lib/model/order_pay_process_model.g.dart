// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_pay_process_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderPayProcessModel _$OrderPayProcessModelFromJson(
        Map<String, dynamic> json) =>
    OrderPayProcessModel(
      shopid: json['shopid'] as String,
      transid: json['transid'] as String,
      tablenumber: json['tablenumber'] as String,
      transguid: json['transguid'] as String,
      paysuccess: (json['paysuccess'] as num).toInt(),
      totalamount: (json['totalamount'] as num).toDouble(),
      orderguid: json['orderguid'] as String,
      wallettype: (json['wallettype'] as num).toInt(),
    );

Map<String, dynamic> _$OrderPayProcessModelToJson(
        OrderPayProcessModel instance) =>
    <String, dynamic>{
      'shopid': instance.shopid,
      'transid': instance.transid,
      'tablenumber': instance.tablenumber,
      'transguid': instance.transguid,
      'paysuccess': instance.paysuccess,
      'totalamount': instance.totalamount,
      'orderguid': instance.orderguid,
      'wallettype': instance.wallettype,
    };
