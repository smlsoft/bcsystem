// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kiosk_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KioskListModel _$KioskListModelFromJson(Map<String, dynamic> json) =>
    KioskListModel(
      guidfixed: json['guidfixed'] as String,
      code: json['code'] as String,
      settingcode: json['settingcode'] as String?,
      emails:
          (json['emails'] as List<dynamic>?)?.map((e) => e as String).toList(),
      activepin: json['activepin'] as String?,
      devicenumber: json['devicenumber'] as String?,
      devicetype: (json['devicetype'] as num?)?.toInt(),
      docformat: json['docformat'] as String?,
      isposactive: json['isposactive'] as bool?,
    );

Map<String, dynamic> _$KioskListModelToJson(KioskListModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'code': instance.code,
      'settingcode': instance.settingcode,
      'emails': instance.emails,
      'activepin': instance.activepin,
      'devicenumber': instance.devicenumber,
      'devicetype': instance.devicetype,
      'docformat': instance.docformat,
      'isposactive': instance.isposactive,
    };
