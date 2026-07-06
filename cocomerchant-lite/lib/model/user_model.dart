import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  int role;
  String shopid;
  String username;
  String? editusername;

  UserModel({
    required this.role,
    required this.shopid,
    required this.username,
    String? editusername,
  }) : editusername = editusername ?? '';

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
