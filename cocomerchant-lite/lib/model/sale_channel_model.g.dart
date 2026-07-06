// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_channel_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleChannelModel _$SaleChannelModelFromJson(Map<String, dynamic> json) =>
    SaleChannelModel(
      guidfixed: json['guidfixed'] as String?,
      code: json['code'] as String?,
      gp: json['gp'] as int?,
      gptype: json['gptype'] as int?,
      imageuri: json['imageuri'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$SaleChannelModelToJson(SaleChannelModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'code': instance.code,
      'gp': instance.gp,
      'gptype': instance.gptype,
      'imageuri': instance.imageuri,
      'name': instance.name,
    };
