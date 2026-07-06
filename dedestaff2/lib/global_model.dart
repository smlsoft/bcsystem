import 'package:dedeorder/global.dart';
import 'package:dedeorder/model/pos_hold_process_model.dart';
import 'package:dedeorder/model/pos_process_model.dart';
import 'package:dedeorder/model/table_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'global_model.g.dart';

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

  factory PrinterLocalStrongDataModel.fromJson(Map<String, dynamic> json) => _$PrinterLocalStrongDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$PrinterLocalStrongDataModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PosInformationModel {
  /// เอาไว้เชื่อมต่อระหว่างเครื่อง
  final String shop_id;
  final String shop_name;

  PosInformationModel({
    required this.shop_id,
    required this.shop_name,
  });

  factory PosInformationModel.fromJson(Map<String, dynamic> json) => _$PosInformationModelFromJson(json);

  Map<String, dynamic> toJson() => _$PosInformationModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LanguageDataModel {
  String code;
  String name;

  LanguageDataModel({required this.code, required this.name});

  factory LanguageDataModel.fromJson(Map<String, dynamic> json) => _$LanguageDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$LanguageDataModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CloseTableModel {
  TableProcessObjectBoxStruct table;

  /// 0=ชำระที่ Cashier,1=ชำระที่โต๊ะเงินสด,2=ชำระที่โต๊ะ QR Code
  int payMode;
  String slipImage;
  PosProcessModel process;
  String discountFormula;
  double payAmount = 0;
  String transactionId;
  String payqrcodename;
  String providercode;
  String providername;
  double roundamount;

  CloseTableModel(
      {required this.table, required this.payMode, required this.slipImage, required this.discountFormula, required this.payAmount, required this.process, double? roundamount, String? transactionId, String? payqrcodename, String? providercode, String? providername})
      : this.transactionId = transactionId ?? "",
        this.roundamount = roundamount ?? 0,
        this.payqrcodename = payqrcodename ?? "",
        this.providercode = providercode ?? "",
        this.providername = providername ?? "";

  factory CloseTableModel.fromJson(Map<String, dynamic> json) => _$CloseTableModelFromJson(json);

  Map<String, dynamic> toJson() => _$CloseTableModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CallerModel {
  final String command;
  final DateTime calldatetime;
  final int actionstatus;
  final DateTime actiondatetime;
  final String refguid;

  CallerModel({required this.command, required this.refguid, required this.calldatetime, required this.actionstatus, required this.actiondatetime});

  factory CallerModel.fromJson(Map<String, dynamic> json) => _$CallerModelFromJson(json);

  Map<String, dynamic> toJson() => _$CallerModelToJson(this);
}
