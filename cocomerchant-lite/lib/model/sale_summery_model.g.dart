// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_summery_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleSummeryModel _$SaleSummeryModelFromJson(Map<String, dynamic> json) =>
    SaleSummeryModel(
      shopid: json['shopid'] as String,
      docdate: json['docdate'] as String,
      totalamount: (json['totalamount'] as num).toDouble(),
    );

Map<String, dynamic> _$SaleSummeryModelToJson(SaleSummeryModel instance) =>
    <String, dynamic>{
      'shopid': instance.shopid,
      'docdate': instance.docdate,
      'totalamount': instance.totalamount,
    };
