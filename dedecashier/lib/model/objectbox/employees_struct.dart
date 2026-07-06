// ignore_for_file: non_constant_identifier_names

import 'package:objectbox/objectbox.dart';

@Entity()
class EmployeeObjectBoxStruct {
  int id = 0;

  @Unique()
  String guidfixed;

  @Index(type: IndexType.hash)
  String code;

  String email;
  bool is_enabled;
  bool is_use_pos;

  @Index()
  String name;

  String profile_picture;

  @Index(type: IndexType.hash)
  String pin_code;

  EmployeeObjectBoxStruct({
    required this.guidfixed,
    required this.code,
    required this.profile_picture,
    required this.name,
    required this.email,
    required this.is_enabled,
    required this.is_use_pos,
    required this.pin_code,
  });
}
