import 'package:cocomerchant_lite/model/business_type_model.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_shop_model.g.dart';

@JsonSerializable()
class CreateShopModel {
  List<LanguageDataModel>? address;
  String? branchcode;
  List<ImagesModel>? images;
  String? logo;
  String? name1;
  List<LanguageDataModel>? names;
  String? profilepicture;
  Settings? settings;
  String? telephone;
  BusinessTypeModel? businesstype;

  CreateShopModel({
    List<LanguageDataModel>? address,
    String? branchcode,
    List<ImagesModel>? images,
    String? logo,
    String? name1,
    List<LanguageDataModel>? names,
    String? profilepicture,
    Settings? settings,
    String? telephone,
    BusinessTypeModel? businesstype,
  })  : address = address ?? [],
        branchcode = branchcode ?? '',
        images = images ?? [],
        logo = logo ?? '',
        name1 = name1 ?? '',
        names = names ?? [],
        profilepicture = profilepicture ?? '',
        settings = settings ?? Settings(),
        telephone = telephone ?? '',
        businesstype = businesstype ?? BusinessTypeModel();

  factory CreateShopModel.fromJson(Map<String, dynamic> json) => _$CreateShopModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreateShopModelToJson(this);
}

@JsonSerializable()
class Settings {
  List<String>? emailowners;
  List<String>? emailstaffs;
  bool? isusebranch;
  bool? isusedepartment;
  List<LanguageModel>? languageconfigs;
  double? latitude;
  double? longitude;
  String? taxid;
  double? vatrate;
  int? vattypesale;
  int? vattypepurchase;
  int? inquirytypesale;
  int? inquirytypepurchase;

  Settings({
    List<String>? emailowners,
    List<String>? emailstaffs,
    bool? isusebranch,
    bool? isusedepartment,
    List<LanguageModel>? languageconfigs,
    double? latitude,
    double? longitude,
    String? taxid,
    double? vatrate,
    int? vattypesale,
    int? vattypepurchase,
    int? inquirytypesale,
    int? inquirytypepurchase,
  })  : emailowners = emailowners ?? [],
        emailstaffs = emailstaffs ?? [],
        isusebranch = isusebranch ?? false,
        isusedepartment = isusedepartment ?? false,
        languageconfigs = languageconfigs ?? [],
        latitude = latitude ?? 0.0,
        longitude = longitude ?? 0.0,
        taxid = taxid ?? '',
        vatrate = vatrate ?? 7,
        vattypesale = vattypesale ?? 0,
        vattypepurchase = vattypepurchase ?? 0,
        inquirytypesale = inquirytypesale ?? 0,
        inquirytypepurchase = inquirytypepurchase ?? 0;

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsToJson(this);
}
