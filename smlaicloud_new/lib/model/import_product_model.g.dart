// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadSuccessModel _$UploadSuccessModelFromJson(Map<String, dynamic> json) =>
    UploadSuccessModel(
      success: json['success'] as bool,
      id: json['id'] as String,
    );

Map<String, dynamic> _$UploadSuccessModelToJson(UploadSuccessModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'id': instance.id,
    };

ImportProductModel _$ImportProductModelFromJson(Map<String, dynamic> json) =>
    ImportProductModel(
      guidfixed: json['guidfixed'] as String?,
      shopid: json['shopid'] as String?,
      taskid: json['taskid'] as String?,
      rownumber: (json['rownumber'] as num?)?.toInt(),
      barcode: json['barcode'] as String?,
      name: json['name'] as String?,
      unitcode: json['unitcode'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      pricemember: (json['pricemember'] as num?)?.toDouble(),
      pricedelivery: (json['pricedelivery'] as num?)?.toDouble(),
      isduplicate: json['isduplicate'] as bool?,
      isexist: json['isexist'] as bool?,
      isunitnotexist: json['isunitnotexist'] as bool?,
    );

Map<String, dynamic> _$ImportProductModelToJson(ImportProductModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'shopid': instance.shopid,
      'taskid': instance.taskid,
      'rownumber': instance.rownumber,
      'barcode': instance.barcode,
      'name': instance.name,
      'unitcode': instance.unitcode,
      'price': instance.price,
      'pricemember': instance.pricemember,
      'pricedelivery': instance.pricedelivery,
      'isduplicate': instance.isduplicate,
      'isexist': instance.isexist,
      'isunitnotexist': instance.isunitnotexist,
    };
