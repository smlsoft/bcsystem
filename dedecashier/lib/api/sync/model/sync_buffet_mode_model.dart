import 'package:dedecashier/global_model.dart';
import 'package:json_annotation/json_annotation.dart';
part 'sync_buffet_mode_model.g.dart';

@JsonSerializable()
class SyncBuffetModeModel {
  String guidfixed;
  String code;
  List<LanguageDataModel> names;
  List<SyncBuffetModePriceModel> prices;

  SyncBuffetModeModel({
    required this.guidfixed,
    required this.code,
    required this.names,
    required this.prices,
  });

  factory SyncBuffetModeModel.fromJson(Map<String, dynamic> json) => _$SyncBuffetModeModelFromJson(json);
  Map<String, dynamic> toJson() => _$SyncBuffetModeModelToJson(this);
}

@JsonSerializable()
class SyncBuffetModePriceModel {
  int type;
  double price;

  SyncBuffetModePriceModel({
    required this.type,
    required this.price,
  });

  factory SyncBuffetModePriceModel.fromJson(Map<String, dynamic> json) => _$SyncBuffetModePriceModelFromJson(json);
  Map<String, dynamic> toJson() => _$SyncBuffetModePriceModelToJson(this);
}
