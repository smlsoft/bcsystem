import 'package:dedecashier/global_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sync_bank_model.g.dart';

@JsonSerializable()
class SyncBankModel {
  String guidfixed;
  String code;
  String logo;
  List<LanguageDataModel> names;

  SyncBankModel({
    this.guidfixed = "",
    this.code = "",
    this.logo = "",
    this.names = const [],
  });

  factory SyncBankModel.fromJson(Map<String, dynamic> json) => _$SyncBankModelFromJson(json);

  Map<String, dynamic> toJson() => _$SyncBankModelToJson(this);
}
