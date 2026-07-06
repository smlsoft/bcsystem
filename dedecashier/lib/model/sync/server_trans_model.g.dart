// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_trans_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerTransModel _$ServerTransModelFromJson(Map<String, dynamic> json) =>
    ServerTransModel(
      docno: json['docno'] as String,
      docdatetime: json['docdatetime'] as String,
      slipurl: json['slipurl'] as String,
    );

Map<String, dynamic> _$ServerTransModelToJson(ServerTransModel instance) =>
    <String, dynamic>{
      'docno': instance.docno,
      'docdatetime': instance.docdatetime,
      'slipurl': instance.slipurl,
    };
