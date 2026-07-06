import 'package:json_annotation/json_annotation.dart';

part 'staff_model.g.dart';

@JsonSerializable(explicitToJson: true)
class StaffModel {
  String code;
  String name;

  StaffModel({
    required this.code,
    required this.name,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) =>
      _$StaffModelFromJson(json);

  Map<String, dynamic> toJson() => _$StaffModelToJson(this);

}
