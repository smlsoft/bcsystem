// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kitchen_struct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KitchenObjectBoxStruct _$KitchenObjectBoxStructFromJson(
  Map<String, dynamic> json,
) => KitchenObjectBoxStruct(
  guidfixed: json['guidfixed'] as String,
  code: json['code'] as String,
  names: json['names'] as String,
  products: (json['products'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  zones: (json['zones'] as List<dynamic>).map((e) => e as String).toList(),
)..id = (json['id'] as num).toInt();

Map<String, dynamic> _$KitchenObjectBoxStructToJson(
  KitchenObjectBoxStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'guidfixed': instance.guidfixed,
  'code': instance.code,
  'names': instance.names,
  'products': instance.products,
  'zones': instance.zones,
};
