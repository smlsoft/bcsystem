// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buffet_mode_struct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuffetModeObjectBoxStruct _$BuffetModeObjectBoxStructFromJson(
  Map<String, dynamic> json,
) => BuffetModeObjectBoxStruct(
  guid_fixed: json['guid_fixed'] as String,
  code: json['code'] as String,
  names: (json['names'] as List<dynamic>).map((e) => e as String).toList(),
  adult_price: (json['adult_price'] as num).toDouble(),
  child_price: (json['child_price'] as num).toDouble(),
  max_minute: (json['max_minute'] as num).toInt(),
)..id = (json['id'] as num).toInt();

Map<String, dynamic> _$BuffetModeObjectBoxStructToJson(
  BuffetModeObjectBoxStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'guid_fixed': instance.guid_fixed,
  'code': instance.code,
  'names': instance.names,
  'adult_price': instance.adult_price,
  'child_price': instance.child_price,
  'max_minute': instance.max_minute,
};
