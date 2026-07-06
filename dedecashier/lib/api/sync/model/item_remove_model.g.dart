// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_remove_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemRemoveModel _$ItemRemoveModelFromJson(Map<String, dynamic> json) =>
    ItemRemoveModel(
      guidfixed: json['guidfixed'] as String? ?? "",
      shopid: json['shopid'] as String? ?? "",
      createdat: json['createdat'] as String? ?? "",
      updatedat: json['updatedat'] as String? ?? "",
      deletedat: json['deletedat'] as String? ?? "",
    );

Map<String, dynamic> _$ItemRemoveModelToJson(ItemRemoveModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'shopid': instance.shopid,
      'createdat': instance.createdat,
      'updatedat': instance.updatedat,
      'deletedat': instance.deletedat,
    };
