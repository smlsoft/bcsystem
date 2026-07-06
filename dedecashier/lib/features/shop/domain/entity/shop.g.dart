// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Shop _$ShopFromJson(Map<String, dynamic> json) => _Shop(
  shopid: json['shopid'] as String? ?? '',
  guidfixed: json['guidfixed'] as String? ?? '',
  name: json['name'] as String? ?? '',
  name1: json['name1'] as String? ?? '',
  branchcode: json['branchcode'] as String? ?? '',
  role: (json['role'] as num?)?.toInt() ?? 0,
  isfavorite: json['isfavorite'] as bool? ?? false,
  lastaccessedat: json['lastaccessedat'] as String? ?? '',
);

Map<String, dynamic> _$ShopToJson(_Shop instance) => <String, dynamic>{
  'shopid': instance.shopid,
  'guidfixed': instance.guidfixed,
  'name': instance.name,
  'name1': instance.name1,
  'branchcode': instance.branchcode,
  'role': instance.role,
  'isfavorite': instance.isfavorite,
  'lastaccessedat': instance.lastaccessedat,
};
