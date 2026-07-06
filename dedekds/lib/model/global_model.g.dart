// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerDeviceModel _$ServerDeviceModelFromJson(Map<String, dynamic> json) =>
    ServerDeviceModel(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      ip: json['ip'] as String,
      connected: json['connected'] as bool,
    );

Map<String, dynamic> _$ServerDeviceModelToJson(ServerDeviceModel instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'ip': instance.ip,
      'connected': instance.connected,
    };

HttpGetDataModel _$HttpGetDataModelFromJson(Map<String, dynamic> json) =>
    HttpGetDataModel(
      code: json['code'] as String,
      json: json['json'] as String,
    );

Map<String, dynamic> _$HttpGetDataModelToJson(HttpGetDataModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'json': instance.json,
    };

LanguageNameModel _$LanguageNameModelFromJson(Map<String, dynamic> json) =>
    LanguageNameModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$LanguageNameModelToJson(LanguageNameModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };

PrinterLocalStrongDataModel _$PrinterLocalStrongDataModelFromJson(
        Map<String, dynamic> json) =>
    PrinterLocalStrongDataModel(
      code: json['code'] as String? ?? "",
      name: json['name'] as String? ?? "",
      ipAddress: json['ipAddress'] as String? ?? "",
      ipPort: (json['ipPort'] as num?)?.toInt() ?? 0,
      productName: json['productName'] as String? ?? "",
      deviceName: json['deviceName'] as String? ?? "",
      deviceId: json['deviceId'] as String? ?? "",
      manufacturer: json['manufacturer'] as String? ?? "",
      vendorId: json['vendorId'] as String? ?? "",
      productId: json['productId'] as String? ?? "",
      paperSize: (json['paperSize'] as num?)?.toInt() ?? 2,
      isReady: json['isReady'] as bool? ?? false,
      isConfigConnectSuccess: json['isConfigConnectSuccess'] as bool? ?? false,
      printerType:
          $enumDecodeNullable(_$PrinterTypeEnumEnumMap, json['printerType']) ??
              PrinterTypeEnum.thermal,
      printerConnectType: $enumDecodeNullable(
              _$PrinterConnectEnumEnumMap, json['printerConnectType']) ??
          PrinterConnectEnum.ip,
      printBillAuto: json['printBillAuto'] as bool? ?? false,
    );

Map<String, dynamic> _$PrinterLocalStrongDataModelToJson(
        PrinterLocalStrongDataModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'ipAddress': instance.ipAddress,
      'ipPort': instance.ipPort,
      'productName': instance.productName,
      'deviceName': instance.deviceName,
      'deviceId': instance.deviceId,
      'manufacturer': instance.manufacturer,
      'vendorId': instance.vendorId,
      'productId': instance.productId,
      'paperSize': instance.paperSize,
      'printBillAuto': instance.printBillAuto,
      'printerType': _$PrinterTypeEnumEnumMap[instance.printerType]!,
      'printerConnectType':
          _$PrinterConnectEnumEnumMap[instance.printerConnectType]!,
      'isConfigConnectSuccess': instance.isConfigConnectSuccess,
      'isReady': instance.isReady,
    };

const _$PrinterTypeEnumEnumMap = {
  PrinterTypeEnum.thermal: 'thermal',
  PrinterTypeEnum.dot: 'dot',
  PrinterTypeEnum.laser: 'laser',
  PrinterTypeEnum.inkjet: 'inkjet',
};

const _$PrinterConnectEnumEnumMap = {
  PrinterConnectEnum.ip: 'ip',
  PrinterConnectEnum.bluetooth: 'bluetooth',
  PrinterConnectEnum.usb: 'usb',
  PrinterConnectEnum.windows: 'windows',
  PrinterConnectEnum.sunmi1: 'sunmi1',
};
