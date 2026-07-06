import 'package:json_annotation/json_annotation.dart';
part 'employee_model.g.dart';

@JsonSerializable()
class EmployeeModel {
  String guidfixed;
  String code;
  String email;
  bool isenabled;
  bool isusepos;
  String name;
  String profilepicture;
  String pincode;

  EmployeeModel({
    required this.guidfixed,
    required this.code,
    required this.profilepicture,
    required this.name,
    required this.email,
    required this.isenabled,
    required this.pincode,
    required this.isusepos,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) =>
      _$EmployeeModelFromJson(json);
  Map<String, dynamic> toJson() => _$EmployeeModelToJson(this);
}
