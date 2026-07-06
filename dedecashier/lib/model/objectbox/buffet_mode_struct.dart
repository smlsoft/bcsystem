// ignore_for_file: non_constant_identifier_names

import 'package:objectbox/objectbox.dart';
import 'package:json_annotation/json_annotation.dart';

part 'buffet_mode_struct.g.dart';

@JsonSerializable()
@Entity()
class BuffetModeObjectBoxStruct {
  int id = 0;
  @Unique()
  String guid_fixed;
  @Unique()
  String code;
  List<String> names;
  double adult_price;
  double child_price;
  int max_minute = 0;

  BuffetModeObjectBoxStruct({
    required this.guid_fixed,
    required this.code,
    required this.names,
    required this.adult_price,
    required this.child_price,
    required this.max_minute,
  });

  factory BuffetModeObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$BuffetModeObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$BuffetModeObjectBoxStructToJson(this);
}
