// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemInfoModel _$SystemInfoModelFromJson(Map<String, dynamic> json) =>
    SystemInfoModel(
      tableObjectBox: (json['tableObjectBox'] as List<dynamic>)
          .map((e) => TableObjectBoxStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      tableProcessObjectBox: (json['tableProcessObjectBox'] as List<dynamic>)
          .map(
            (e) =>
                TableProcessObjectBoxStruct.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$SystemInfoModelToJson(SystemInfoModel instance) =>
    <String, dynamic>{
      'tableObjectBox': instance.tableObjectBox.map((e) => e.toJson()).toList(),
      'tableProcessObjectBox': instance.tableProcessObjectBox
          .map((e) => e.toJson())
          .toList(),
    };
