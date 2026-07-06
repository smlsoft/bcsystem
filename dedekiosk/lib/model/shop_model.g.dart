// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopModel _$ShopModelFromJson(Map<String, dynamic> json) => ShopModel(
      guidfixed: json['guidfixed'] as String?,
      branchcode: json['branchcode'] as String?,
      name1: json['name1'] as String?,
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      profilepicture: json['profilepicture'] as String?,
    );

Map<String, dynamic> _$ShopModelToJson(ShopModel instance) => <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'branchcode': instance.branchcode,
      'name1': instance.name1,
      'names': instance.names,
      'profilepicture': instance.profilepicture,
    };
