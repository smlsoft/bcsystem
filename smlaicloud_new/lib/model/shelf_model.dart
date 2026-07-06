import 'package:json_annotation/json_annotation.dart';

part 'shelf_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ShelfModel {
  String code;
  String name;

  ShelfModel({
    required this.code,
    required this.name,
  });
  factory ShelfModel.fromJson(Map<String, dynamic> json) =>
      _$ShelfModelFromJson(json);
  Map<String, dynamic> toJson() => _$ShelfModelToJson(this);
}
