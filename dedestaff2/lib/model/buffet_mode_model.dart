import 'package:json_annotation/json_annotation.dart';

part 'buffet_mode_model.g.dart';

@JsonSerializable()
class BuffetModeObjectBoxStruct {
  String code;
  List<String> names;
  double adult_price;
  double child_price;
  int max_minute = 0;

  BuffetModeObjectBoxStruct({
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
