// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableModel _$TableModelFromJson(Map<String, dynamic> json) => TableModel(
      guidfixed: json['guidfixed'] as String,
      number: json['number'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      zone: json['zone'] as String,
      xorder: json['xorder'] as int?,
      orderendcode: json['orderendcode'] as String?,
      groupnumber: json['groupnumber'] as int?,
      zonenumber: json['zonenumber'] as int?,
    );

Map<String, dynamic> _$TableModelToJson(TableModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'number': instance.number,
      'names': instance.names,
      'zone': instance.zone,
      'xorder': instance.xorder,
      'orderendcode': instance.orderendcode,
      'groupnumber': instance.groupnumber,
      'zonenumber': instance.zonenumber,
    };

TableXorderModel _$TableXorderModelFromJson(Map<String, dynamic> json) =>
    TableXorderModel(
      guidfixed: json['guidfixed'] as String,
      xorder: json['xorder'] as int,
    );

Map<String, dynamic> _$TableXorderModelToJson(TableXorderModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'xorder': instance.xorder,
    };
