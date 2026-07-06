// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncCustomerDisplayModel _$SyncCustomerDisplayModelFromJson(
  Map<String, dynamic> json,
) => SyncCustomerDisplayModel(
  code: json['code'] as String,
  phone: json['phone'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$SyncCustomerDisplayModelToJson(
  SyncCustomerDisplayModel instance,
) => <String, dynamic>{
  'code': instance.code,
  'phone': instance.phone,
  'name': instance.name,
};

SyncDeviceModel _$SyncDeviceModelFromJson(Map<String, dynamic> json) =>
    SyncDeviceModel(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String?,
      ip: json['ip'] as String,
      connected: json['connected'] as bool,
      isCashierTerminal: json['isCashierTerminal'] as bool?,
      isClient: json['isClient'] as bool?,
      holdCodeActive: json['holdCodeActive'] as String?,
      docModeActive: (json['docModeActive'] as num?)?.toInt(),
      processSuccess: json['processSuccess'] as bool? ?? true,
    );

Map<String, dynamic> _$SyncDeviceModelToJson(SyncDeviceModel instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'ip': instance.ip,
      'connected': instance.connected,
      'isCashierTerminal': instance.isCashierTerminal,
      'isClient': instance.isClient,
      'holdCodeActive': instance.holdCodeActive,
      'docModeActive': instance.docModeActive,
      'processSuccess': instance.processSuccess,
    };

SyncStaffDeviceModel _$SyncStaffDeviceModelFromJson(
  Map<String, dynamic> json,
) => SyncStaffDeviceModel(
  clientGuid: json['clientGuid'] as String,
  clientName: json['clientName'] as String,
  clientIp: json['clientIp'] as String,
  securityCode: json['securityCode'] as String,
);

Map<String, dynamic> _$SyncStaffDeviceModelToJson(
  SyncStaffDeviceModel instance,
) => <String, dynamic>{
  'clientGuid': instance.clientGuid,
  'clientName': instance.clientName,
  'clientIp': instance.clientIp,
  'securityCode': instance.securityCode,
};
