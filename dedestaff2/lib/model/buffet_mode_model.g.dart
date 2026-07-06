// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buffet_mode_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuffetModeObjectBoxStruct _$BuffetModeObjectBoxStructFromJson(
        Map<String, dynamic> json) =>
    BuffetModeObjectBoxStruct(
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>).map((e) => e as String).toList(),
      adult_price: (json['adult_price'] as num).toDouble(),
      child_price: (json['child_price'] as num).toDouble(),
      max_minute: (json['max_minute'] as num).toInt(),
    );

Map<String, dynamic> _$BuffetModeObjectBoxStructToJson(
        BuffetModeObjectBoxStruct instance) =>
    <String, dynamic>{
      'code': instance.code,
      'names': instance.names,
      'adult_price': instance.adult_price,
      'child_price': instance.child_price,
      'max_minute': instance.max_minute,
    };
