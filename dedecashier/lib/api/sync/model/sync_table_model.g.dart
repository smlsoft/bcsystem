// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_table_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncTableModel _$SyncTableModelFromJson(Map<String, dynamic> json) =>
    SyncTableModel(
      groupnumber: (json['groupnumber'] as num?)?.toInt(),
      guidfixed: json['guidfixed'] as String,
      number: json['number'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      zone: json['zone'] as String,
    );

Map<String, dynamic> _$SyncTableModelToJson(SyncTableModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'number': instance.number,
      'names': instance.names,
      'zone': instance.zone,
      'groupnumber': instance.groupnumber,
    };
