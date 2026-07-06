// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShopUser _$ShopUserFromJson(Map<String, dynamic> json) => _ShopUser(
  shopid: json['shopid'] as String? ?? '',
  name: json['name'] as String? ?? '',
  branchcode: json['branchcode'] as String? ?? '',
  role: (json['role'] as num?)?.toInt() ?? 0,
  isfavorite: json['isfavorite'] as bool? ?? false,
  lastaccessedat: json['lastaccessedat'] as String? ?? '',
);

Map<String, dynamic> _$ShopUserToJson(_ShopUser instance) => <String, dynamic>{
  'shopid': instance.shopid,
  'name': instance.name,
  'branchcode': instance.branchcode,
  'role': instance.role,
  'isfavorite': instance.isfavorite,
  'lastaccessedat': instance.lastaccessedat,
};
