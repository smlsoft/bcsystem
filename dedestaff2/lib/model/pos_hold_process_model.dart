import 'package:dedeorder/model/pos_pay_model.dart';
import 'package:dedeorder/model/pos_process_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pos_hold_process_model.g.dart';

enum PayScreenNumberPadWidgetEnum {
  text,
  number,
}

@JsonSerializable(explicitToJson: true)
class LanguageSystemModel {
  String code;
  String text;

  LanguageSystemModel({required this.code, required this.text});

  factory LanguageSystemModel.fromJson(Map<String, dynamic> json) =>
      _$LanguageSystemModelFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageSystemModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LanguageSystemCodeModel {
  String code;
  List<LanguageSystemModel> langs;

  LanguageSystemCodeModel({required this.code, required this.langs});

  factory LanguageSystemCodeModel.fromJson(Map<String, dynamic> json) =>
      _$LanguageSystemCodeModelFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageSystemCodeModelToJson(this);
}

class SyncMasterStatusModel {
  late String tableName;
  late String lastUpdate;
}

@JsonSerializable(explicitToJson: true)
class PosHoldProcessModel {
  /// รหัสการ Hold
  String code;

  /// 1=POS,2=ร้านอาหาร (โต๊ะ)
  int holdType;

  /// จำนวน Log
  int logCount = 0;

  /// รหัส Sale
  String saleCode = "";

  /// ชื่อ Sale
  String saleName = "";

  /// รหัสลูกค้า
  String customerCode;

  /// ชื่อลูกค้า
  String customerName;

  /// เบอร์โทรลูกค้า
  String customerPhone;

  /// การชำระเงิน
  PosPayModel payScreenData = PosPayModel();

  /// รายการสินค้า
  PosProcessModel posProcess = PosProcessModel();

  String tableNumber;

  /// เป็นรายการกลับบ้านหรือไม่
  bool isDelivery;

  String deliveryNumber;

  // ส่วนลดเฉพาะค่าอาหาร
  String detailDiscountFormula;

  // guid line active
  String activeLineGuid;

  PosHoldProcessModel(
      {required this.code,
      this.holdType = 1,
      this.tableNumber = "",
      this.isDelivery = false,
      this.deliveryNumber = "",
      this.customerCode = "",
      this.customerName = "",
      this.detailDiscountFormula = "",
      this.activeLineGuid = "",
      this.customerPhone = ""});

  factory PosHoldProcessModel.fromJson(Map<String, dynamic> json) =>
      _$PosHoldProcessModelFromJson(json);
  Map<String, dynamic> toJson() => _$PosHoldProcessModelToJson(this);
}
