import 'package:json_annotation/json_annotation.dart';
import 'package:dedekds/global.dart';

part 'global_model.g.dart';

@JsonSerializable()
class ServerDeviceModel {
  late String deviceId;
  late String deviceName;
  late String ip;
  late bool connected;

  ServerDeviceModel(
      {required this.deviceId,
      required this.deviceName,
      required this.ip,
      required this.connected});

  factory ServerDeviceModel.fromJson(Map<String, dynamic> json) =>
      _$ServerDeviceModelFromJson(json);
  Map<String, dynamic> toJson() => _$ServerDeviceModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class HttpGetDataModel {
  String code;
  String json;

  HttpGetDataModel({required this.code, required this.json});

  factory HttpGetDataModel.fromJson(Map<String, dynamic> json) =>
      _$HttpGetDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$HttpGetDataModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LanguageNameModel {
  final String code;
  final String name;

  LanguageNameModel({
    required this.code,
    required this.name,
  });

  factory LanguageNameModel.fromJson(Map<String, dynamic> json) =>
      _$LanguageNameModelFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageNameModelToJson(this);
}

class PrinterDeviceModel {
  String fullName;
  String productName;
  String deviceName;
  String deviceId;
  String manufacturer;
  String vendorId;
  String productId;
  String ipAddress;
  int ipPort;
  PrinterConnectEnum connectType;
  PrinterTypeEnum printerType;
  // 1 = 58mm, 2 = 80mm
  int paperSize;

  PrinterDeviceModel(
      {this.fullName = "",
      this.productName = "",
      this.deviceName = "",
      this.deviceId = "",
      this.manufacturer = "",
      this.productId = "",
      this.vendorId = "",
      this.ipAddress = "",
      this.ipPort = 0,
      this.paperSize = 0,
      this.printerType = PrinterTypeEnum.thermal,
      this.connectType = PrinterConnectEnum.ip});
}

@JsonSerializable(explicitToJson: true)
class PrinterLocalStrongDataModel {
  String code;
  String name;
  String ipAddress;
  int ipPort;
  String productName;
  String deviceName;
  String deviceId;
  String manufacturer;
  String vendorId;
  String productId;
  int paperSize; // 1 = 58mm, 2 = 80mm
  bool printBillAuto;
  PrinterTypeEnum printerType;
  PrinterConnectEnum printerConnectType;
  bool isConfigConnectSuccess;
  bool isReady;

  PrinterLocalStrongDataModel(
      {this.code = "",
      this.name = "",
      this.ipAddress = "",
      this.ipPort = 0,
      this.productName = "",
      this.deviceName = "",
      this.deviceId = "",
      this.manufacturer = "",
      this.vendorId = "",
      this.productId = "",
      this.paperSize = 2,
      this.isReady = false,
      this.isConfigConnectSuccess = false,
      this.printerType = PrinterTypeEnum.thermal,
      this.printerConnectType = PrinterConnectEnum.ip,
      this.printBillAuto = false});

  factory PrinterLocalStrongDataModel.fromJson(Map<String, dynamic> json) =>
      _$PrinterLocalStrongDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$PrinterLocalStrongDataModelToJson(this);
}

class PosSaleChannelModel {
  String code;
  String name;
  String logoUrl;

  PosSaleChannelModel(
      {required this.code, required this.name, this.logoUrl = ""});
}
