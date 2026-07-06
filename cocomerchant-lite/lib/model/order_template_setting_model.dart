import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/qr_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_template_setting_model.g.dart';

@JsonSerializable()
class OrderTemplateSettingModel {
  String? guidfixed;
  String? activepin;
  BranchModel? branch;

  /// รหัสรเครื่อง
  String? code;

  /// หมายเลขเครื่อง
  String? devicenumber;

  /// 0 = เครื่องพนัักงาน , 1 = เครื่องลูกค้า
  int? devicetype;

  /// รูปแบบเลขที่เอกสาร
  String docformat;

  /// logo Order
  String? logourl;

  /// รหัสสื่อโฆษณา
  String? mediaguid;

  String? tablenumber;

  /// time for sale alcohol
  List<TimeForsaleModel>? timeforsales;

  /// qr code
  List<QrModel>? qrcodes;

  /// เครื่อง orders
  List<OrderDeviceModel>? orderdevices;

  /// หมายเลขสั่งอาหาร
  String? label;

  /// ช่องทางการขาย
  List<String>? salechannels;

  OrderTemplateSettingModel({
    String? guidfixed,
    String? activepin,
    BranchModel? branch,
    String? code,
    String? devicenumber,
    int? devicetype,
    String? docformat,
    String? logourl,
    String? mediaguid,
    String? tablenumber,
    List<TimeForsaleModel>? timeforsales,
    List<QrModel>? qrcodes,
    List<OrderDeviceModel>? orderdevices,
    String? label,
    List<String>? salechannels,
  })  : guidfixed = guidfixed ?? '',
        activepin = activepin ?? '',
        branch = branch ?? BranchModel(),
        code = code ?? '',
        devicenumber = devicenumber ?? '',
        docformat = docformat ?? '',
        logourl = logourl ?? '',
        mediaguid = mediaguid ?? '',
        tablenumber = tablenumber ?? '',
        timeforsales = timeforsales ?? [],
        qrcodes = qrcodes ?? [],
        devicetype = devicetype ?? 0,
        orderdevices = orderdevices ?? [],
        label = label ?? '',
        salechannels = salechannels ?? [];

  factory OrderTemplateSettingModel.fromJson(Map<String, dynamic> json) => _$OrderTemplateSettingModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderTemplateSettingModelToJson(this);
}

@JsonSerializable()
class BranchModel {
  String? code;
  String? guidfixed;
  List<LanguageDataModel>? names;

  BranchModel({
    String? code,
    String? guidfixed,
    List<LanguageDataModel>? names,
  })  : code = code ?? '',
        guidfixed = guidfixed ?? '',
        names = names ?? [];

  factory BranchModel.fromJson(Map<String, dynamic> json) => _$BranchModelFromJson(json);
  Map<String, dynamic> toJson() => _$BranchModelToJson(this);
}

/// เวลาขายสุรา
@JsonSerializable()
class TimeForsaleModel {
  String? from;
  String? to;
  List<LanguageDataModel>? names;

  TimeForsaleModel({
    String? from,
    String? to,
    List<LanguageDataModel>? names,
  })  : from = from ?? '',
        to = to ?? '',
        names = names ?? [];

  factory TimeForsaleModel.fromJson(Map<String, dynamic> json) => _$TimeForsaleModelFromJson(json);
  Map<String, dynamic> toJson() => _$TimeForsaleModelToJson(this);
}

/// เครื่องออเดอร์
@JsonSerializable()
class OrderDeviceModel {
  String? activepin;
  String? id;
  List<LanguageDataModel>? names;

  OrderDeviceModel({
    String? activepin,
    String? id,
    List<LanguageDataModel>? names,
  })  : activepin = activepin ?? '',
        id = id ?? '',
        names = names ?? [];

  factory OrderDeviceModel.fromJson(Map<String, dynamic> json) => _$OrderDeviceModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderDeviceModelToJson(this);
}
