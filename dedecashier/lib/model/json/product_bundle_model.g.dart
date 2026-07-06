// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_bundle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductBundleModel _$ProductBundleModelFromJson(Map<String, dynamic> json) =>
    ProductBundleModel(
      main_barcode: json['main_barcode'] as String,
      bundle_barcode: json['bundle_barcode'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$ProductBundleModelToJson(ProductBundleModel instance) =>
    <String, dynamic>{
      'main_barcode': instance.main_barcode,
      'bundle_barcode': instance.bundle_barcode,
      'price': instance.price,
    };
