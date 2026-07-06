import 'package:cocomerchant_lite/model/create_shop_model.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shop_model.g.dart';

@JsonSerializable()
class ShopModel {
  String? guidfixed;
  List<LanguageDataModel>? address;
  String? branchcode;
  List<ImagesModel>? images;
  String? logo;
  String? name1;
  List<LanguageDataModel>? names;
  String? profilepicture;
  Settings? settings;
  String? telephone;

  ShopModel({
    String? guidfixed,
    List<LanguageDataModel>? address,
    String? branchcode,
    List<ImagesModel>? images,
    String? logo,
    String? name1,
    List<LanguageDataModel>? names,
    String? profilepicture,
    Settings? settings,
    String? telephone,
  })  : address = address ?? [],
        branchcode = branchcode ?? '',
        images = images ?? [],
        logo = logo ?? '',
        name1 = name1 ?? '',
        names = names ?? [],
        profilepicture = profilepicture ?? '',
        settings = settings ?? Settings(),
        telephone = telephone ?? '',
        guidfixed = guidfixed ?? '';

  factory ShopModel.fromJson(Map<String, dynamic> json) => _$ShopModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShopModelToJson(this);
}
