// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductStatusModel _$ProductStatusModelFromJson(Map<String, dynamic> json) =>
    ProductStatusModel(
      shopid: json['shopid'] as String,
      barcode: json['barcode'] as String,
      unitcode: json['unitcode'] as String,
      productname: json['productname'] as String,
      totalquantity: (json['totalquantity'] as num).toDouble(),
      totalamount: (json['totalamount'] as num).toDouble(),
    );

Map<String, dynamic> _$ProductStatusModelToJson(ProductStatusModel instance) =>
    <String, dynamic>{
      'shopid': instance.shopid,
      'barcode': instance.barcode,
      'productname': instance.productname,
      'unitcode': instance.unitcode,
      'totalquantity': instance.totalquantity,
      'totalamount': instance.totalamount,
    };
