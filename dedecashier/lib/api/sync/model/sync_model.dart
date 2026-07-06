import 'package:json_annotation/json_annotation.dart';

part 'sync_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SyncCustomerDisplayModel {
  String code;
  String phone;
  String name;

  SyncCustomerDisplayModel(
      {required this.code, required this.phone, required this.name});

  factory SyncCustomerDisplayModel.fromJson(Map<String, dynamic> json) =>
      _$SyncCustomerDisplayModelFromJson(json);

  Map<String, dynamic> toJson() => _$SyncCustomerDisplayModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SyncDeviceModel {
  String deviceId;
  String? deviceName;
  String ip;
  bool connected;
  bool? isCashierTerminal;
  bool? isClient;
  String? holdCodeActive;
  int? docModeActive;
  bool? processSuccess;

  SyncDeviceModel(
      {required this.deviceId,
      required this.deviceName,
      required this.ip,
      required this.connected,
      required this.isCashierTerminal,
      required this.isClient,
      required this.holdCodeActive,
      required this.docModeActive,
      this.processSuccess = true});

  factory SyncDeviceModel.fromJson(Map<String, dynamic> json) =>
      _$SyncDeviceModelFromJson(json);

  Map<String, dynamic> toJson() => _$SyncDeviceModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SyncStaffDeviceModel {
  // เชื่อมกับเครื่อง Staff
  String clientGuid;
  String clientName;
  String clientIp;
  String securityCode;

  SyncStaffDeviceModel({
    required this.clientGuid,
    required this.clientName,
    required this.clientIp,
    required this.securityCode,
  });

  factory SyncStaffDeviceModel.fromJson(Map<String, dynamic> json) =>
      _$SyncStaffDeviceModelFromJson(json);

  Map<String, dynamic> toJson() => _$SyncStaffDeviceModelToJson(this);
}
