// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_bank_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncBankModel _$SyncBankModelFromJson(Map<String, dynamic> json) =>
    SyncBankModel(
      guidfixed: json['guidfixed'] as String? ?? "",
      code: json['code'] as String? ?? "",
      logo: json['logo'] as String? ?? "",
      names:
          (json['names'] as List<dynamic>?)
              ?.map(
                (e) => LanguageDataModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SyncBankModelToJson(SyncBankModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'code': instance.code,
      'logo': instance.logo,
      'names': instance.names,
    };
