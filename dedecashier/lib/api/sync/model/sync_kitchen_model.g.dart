// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_kitchen_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncKitchenModel _$SyncKitchenModelFromJson(Map<String, dynamic> json) =>
    SyncKitchenModel(
      groupnumber: (json['groupnumber'] as num?)?.toInt(),
      guidfixed: json['guidfixed'] as String,
      products: (json['products'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      zones: (json['zones'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$SyncKitchenModelToJson(SyncKitchenModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'code': instance.code,
      'groupnumber': instance.groupnumber,
      'names': instance.names,
      'products': instance.products,
      'zones': instance.zones,
    };
