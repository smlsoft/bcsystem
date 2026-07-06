// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
  PrinterConnectEnum.windows: 'windows',
};

PosInformationModel _$PosInformationModelFromJson(Map<String, dynamic> json) =>
    PosInformationModel(
      shop_id: json['shop_id'] as String,
      shop_name: json['shop_name'] as String,
    );

Map<String, dynamic> _$PosInformationModelToJson(
        PosInformationModel instance) =>
    <String, dynamic>{
      'shop_id': instance.shop_id,
      'shop_name': instance.shop_name,
    };

LanguageDataModel _$LanguageDataModelFromJson(Map<String, dynamic> json) =>
    LanguageDataModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$LanguageDataModelToJson(LanguageDataModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };

CloseTableModel _$CloseTableModelFromJson(Map<String, dynamic> json) =>
    CloseTableModel(
      table: TableProcessObjectBoxStruct.fromJson(
          json['table'] as Map<String, dynamic>),
      payMode: (json['payMode'] as num).toInt(),
      slipImage: json['slipImage'] as String,
      discountFormula: json['discountFormula'] as String,
      payAmount: (json['payAmount'] as num).toDouble(),
      process:
          PosProcessModel.fromJson(json['process'] as Map<String, dynamic>),
      roundamount: (json['roundamount'] as num?)?.toDouble(),
      transactionId: json['transactionId'] as String?,
      payqrcodename: json['payqrcodename'] as String?,
      providercode: json['providercode'] as String?,
      providername: json['providername'] as String?,
    );

Map<String, dynamic> _$CloseTableModelToJson(CloseTableModel instance) =>
    <String, dynamic>{
      'table': instance.table.toJson(),
      'payMode': instance.payMode,
      'slipImage': instance.slipImage,
      'process': instance.process.toJson(),
      'discountFormula': instance.discountFormula,
      'payAmount': instance.payAmount,
      'transactionId': instance.transactionId,
      'payqrcodename': instance.payqrcodename,
      'providercode': instance.providercode,
      'providername': instance.providername,
      'roundamount': instance.roundamount,
    };

CallerModel _$CallerModelFromJson(Map<String, dynamic> json) => CallerModel(
      command: json['command'] as String,
      refguid: json['refguid'] as String,
      calldatetime: DateTime.parse(json['calldatetime'] as String),
      actionstatus: (json['actionstatus'] as num).toInt(),
      actiondatetime: DateTime.parse(json['actiondatetime'] as String),
    );

Map<String, dynamic> _$CallerModelToJson(CallerModel instance) =>
    <String, dynamic>{
      'command': instance.command,
      'calldatetime': instance.calldatetime.toIso8601String(),
      'actionstatus': instance.actionstatus,
      'actiondatetime': instance.actiondatetime.toIso8601String(),
      'refguid': instance.refguid,
    };
