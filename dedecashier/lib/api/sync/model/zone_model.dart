import 'package:json_annotation/json_annotation.dart';
part 'zone_model.g.dart';

@JsonSerializable()
class ZoneModel {
  late String guidfixed;
  late String code;
  late String name1;
  late String shopid;

  ZoneModel({
    this.guidfixed = "",
    this.code = "",
    this.name1 = "",
  });
  factory ZoneModel.fromJson(Map<String, dynamic> json) =>
      _$ZoneModelFromJson(json);
  Map<String, dynamic> toJson() => _$ZoneModelToJson(this);
}
