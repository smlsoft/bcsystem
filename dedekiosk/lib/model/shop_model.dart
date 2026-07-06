import 'package:dedekiosk/model/global_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shop_model.g.dart';

@JsonSerializable()
class ShopModel {
  String? guidfixed;
  String? branchcode;
  String? name1;
  List<LanguageDataModel>? names;
  String? profilepicture;

  ShopModel({
    String? guidfixed,
    String? branchcode,
    String? logo,
    String? name1,
    List<LanguageDataModel>? names,
    String? profilepicture,
    String? telephone,
  })  : branchcode = branchcode ?? '',
        name1 = name1 ?? '',
        names = names ?? [],
        profilepicture = profilepicture ?? '',
        guidfixed = guidfixed ?? '';

  factory ShopModel.fromJson(Map<String, dynamic> json) => _$ShopModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShopModelToJson(this);
}
