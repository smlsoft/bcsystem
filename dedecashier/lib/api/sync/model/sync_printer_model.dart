import 'package:json_annotation/json_annotation.dart';

part 'sync_printer_model.g.dart';

@JsonSerializable()
class SyncPrinterModel {
  String guidfixed;

  /// รหัส
  String code;

  /// ชื่อ
  String name1;

  /// ชนิดเครื่องพิมพ์
  int type;

  /// ไอพี
  String address;

  SyncPrinterModel({
    required this.guidfixed,
    required this.code,
    required this.name1,
    required this.type,
    required this.address,
  });

  factory SyncPrinterModel.fromJson(Map<String, dynamic> json) =>
      _$SyncPrinterModelFromJson(json);

  Map<String, dynamic> toJson() => _$SyncPrinterModelToJson(this);
}
