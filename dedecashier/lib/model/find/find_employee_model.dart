// ignore_for_file: non_constant_identifier_names

class FindEmployeeModel {
  late String code;
  late String guidfixed;
  late String name;
  late String roles;
  late String username;
  late String profile_picture;

  FindEmployeeModel({
    required this.profile_picture,
    required this.name,
    required this.roles,
    required this.code,
    required this.username,
  });
}
