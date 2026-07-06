// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_category_struct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductCategoryObjectBoxStruct _$ProductCategoryObjectBoxStructFromJson(
  Map<String, dynamic> json,
) => ProductCategoryObjectBoxStruct(
  guid_fixed: json['guid_fixed'] as String,
  parent_guid_fixed: json['parent_guid_fixed'] as String,
  names: json['names'] as String,
  image_url: json['image_url'] as String,
  category_count: (json['category_count'] as num).toInt(),
  use_image_or_color: json['use_image_or_color'] as bool,
  xorder: (json['xorder'] as num).toInt(),
  colorselect: json['colorselect'] as String,
  colorselecthex: json['colorselecthex'] as String,
  codelist: json['codelist'] as String,
)..id = (json['id'] as num).toInt();

Map<String, dynamic> _$ProductCategoryObjectBoxStructToJson(
  ProductCategoryObjectBoxStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'guid_fixed': instance.guid_fixed,
  'parent_guid_fixed': instance.parent_guid_fixed,
  'names': instance.names,
  'image_url': instance.image_url,
  'use_image_or_color': instance.use_image_or_color,
  'colorselect': instance.colorselect,
  'colorselecthex': instance.colorselecthex,
  'codelist': instance.codelist,
  'xorder': instance.xorder,
  'category_count': instance.category_count,
};
