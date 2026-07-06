// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zone_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ZoneModel _$ZoneModelFromJson(Map<String, dynamic> json) => ZoneModel(
  guidfixed: json['guidfixed'] as String? ?? "",
  code: json['code'] as String? ?? "",
  name1: json['name1'] as String? ?? "",
)..shopid = json['shopid'] as String;

Map<String, dynamic> _$ZoneModelToJson(ZoneModel instance) => <String, dynamic>{
  'guidfixed': instance.guidfixed,
  'code': instance.code,
  'name1': instance.name1,
  'shopid': instance.shopid,
};
