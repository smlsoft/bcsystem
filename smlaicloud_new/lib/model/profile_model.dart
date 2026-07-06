import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class ProfileModel {
  String? username;
  String? name;
  String? avatar;
  String? timezonelabel;
  String? timezoneoffset;
  String? yeartype;

  ProfileModel({
    String? username,
    String? name,
    String? avatar,
    String? timezonelabel,
    String? timezoneoffset,
    String? yeartype,
  })  : username = username ?? "",
        name = name ?? "",
        avatar = avatar ?? "",
        timezonelabel = timezonelabel ?? "",
        timezoneoffset = timezoneoffset ?? "",
        yeartype = yeartype ?? "";

  factory ProfileModel.fromJson(Map<String, dynamic> json) => _$ProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);
}
