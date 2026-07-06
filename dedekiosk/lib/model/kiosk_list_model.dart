import 'package:dedekiosk/model/category_model.dart';
import 'package:dedekiosk/model/global_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'kiosk_list_model.g.dart';

@JsonSerializable()
class KioskListModel {
  String guidfixed;
  String code;
  String settingcode;
  List<String> emails;
  String activepin;
  String devicenumber;
  int devicetype;
  String docformat;
  bool isposactive;

  KioskListModel({
    required this.guidfixed,
    required this.code,
    String? settingcode,
    List<String>? emails,
    String? activepin,
    String? devicenumber,
    int? devicetype,
    String? docformat,
    bool? isposactive,
  })  : emails = emails ?? <String>[],
        settingcode = settingcode ?? '',
        activepin = activepin ?? '',
        devicenumber = devicenumber ?? '',
        devicetype = devicetype ?? 0,
        docformat = docformat ?? '',
        isposactive = isposactive ?? false;

  factory KioskListModel.fromJson(Map<String, dynamic> json) => _$KioskListModelFromJson(json);

  Map<String, dynamic> toJson() => _$KioskListModelToJson(this);
}
