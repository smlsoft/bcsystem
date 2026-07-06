// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_buffet_mode_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncBuffetModeModel _$SyncBuffetModeModelFromJson(Map<String, dynamic> json) =>
    SyncBuffetModeModel(
      guidfixed: json['guidfixed'] as String,
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      prices: (json['prices'] as List<dynamic>)
          .map(
            (e) => SyncBuffetModePriceModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$SyncBuffetModeModelToJson(
  SyncBuffetModeModel instance,
) => <String, dynamic>{
  'guidfixed': instance.guidfixed,
  'code': instance.code,
  'names': instance.names,
  'prices': instance.prices,
};

SyncBuffetModePriceModel _$SyncBuffetModePriceModelFromJson(
  Map<String, dynamic> json,
) => SyncBuffetModePriceModel(
  type: (json['type'] as num).toInt(),
  price: (json['price'] as num).toDouble(),
);

Map<String, dynamic> _$SyncBuffetModePriceModelToJson(
  SyncBuffetModePriceModel instance,
) => <String, dynamic>{'type': instance.type, 'price': instance.price};
