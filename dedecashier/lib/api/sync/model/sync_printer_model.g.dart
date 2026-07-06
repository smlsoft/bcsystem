// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_printer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncPrinterModel _$SyncPrinterModelFromJson(Map<String, dynamic> json) =>
    SyncPrinterModel(
      guidfixed: json['guidfixed'] as String,
      code: json['code'] as String,
      name1: json['name1'] as String,
      type: (json['type'] as num).toInt(),
      address: json['address'] as String,
    );

Map<String, dynamic> _$SyncPrinterModelToJson(SyncPrinterModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'code': instance.code,
      'name1': instance.name1,
      'type': instance.type,
      'address': instance.address,
    };
