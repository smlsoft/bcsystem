import 'package:dedecashier/global_model.dart';
import 'package:json_annotation/json_annotation.dart';
part 'sync_kitchen_model.g.dart';

@JsonSerializable()
class SyncKitchenModel {
  String guidfixed;
  String code;
  int groupnumber;
  List<LanguageDataModel> names;
  List<String> products;
  List<String> zones;

  SyncKitchenModel({
    int? groupnumber,
    required this.guidfixed,
    required this.products,
    required this.code,
    required this.names,
    required this.zones,
  }) : groupnumber = groupnumber ?? 0;

  factory SyncKitchenModel.fromJson(Map<String, dynamic> json) => _$SyncKitchenModelFromJson(json);
  Map<String, dynamic> toJson() => _$SyncKitchenModelToJson(this);
}
