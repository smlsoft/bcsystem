import 'package:json_annotation/json_annotation.dart';

part 'kitchen_model.g.dart';

@JsonSerializable(explicitToJson: true)
class KitchenObjectBoxStruct {
  int id = 0;
  String guidfixed;
  String code;
  String names;
  List<String> products;
  List<String> zones;

  KitchenObjectBoxStruct({
    required this.guidfixed,
    required this.code,
    required this.names,
    required this.products,
    required this.zones,
  });

  factory KitchenObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$KitchenObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$KitchenObjectBoxStructToJson(this);
}
