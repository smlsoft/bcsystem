import 'package:json_annotation/json_annotation.dart';

part 'item_remove_model.g.dart';

@JsonSerializable()
class ItemRemoveModel {
  late String guidfixed;
  late String shopid;
  late String createdat;
  late String updatedat;
  late String deletedat;

  ItemRemoveModel({
    this.guidfixed = "",
    this.shopid = "",
    this.createdat = "",
    this.updatedat = "",
    this.deletedat = "",
  });

  factory ItemRemoveModel.fromJson(Map<String, dynamic> json) =>
      _$ItemRemoveModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItemRemoveModelToJson(this);
}
