// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_shop_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateShopModel _$CreateShopModelFromJson(Map<String, dynamic> json) =>
    CreateShopModel(
      address: (json['address'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      branchcode: json['branchcode'] as String?,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ImagesModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      logo: json['logo'] as String?,
      name1: json['name1'] as String?,
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      profilepicture: json['profilepicture'] as String?,
      settings: json['settings'] == null
          ? null
          : Settings.fromJson(json['settings'] as Map<String, dynamic>),
      telephone: json['telephone'] as String?,
      businesstype: json['businesstype'] == null
          ? null
          : BusinessTypeModel.fromJson(
              json['businesstype'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreateShopModelToJson(CreateShopModel instance) =>
    <String, dynamic>{
      'address': instance.address,
      'branchcode': instance.branchcode,
      'images': instance.images,
      'logo': instance.logo,
      'name1': instance.name1,
      'names': instance.names,
      'profilepicture': instance.profilepicture,
      'settings': instance.settings,
      'telephone': instance.telephone,
      'businesstype': instance.businesstype,
    };

Settings _$SettingsFromJson(Map<String, dynamic> json) => Settings(
      emailowners: (json['emailowners'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      emailstaffs: (json['emailstaffs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isusebranch: json['isusebranch'] as bool?,
      isusedepartment: json['isusedepartment'] as bool?,
      languageconfigs: (json['languageconfigs'] as List<dynamic>?)
          ?.map((e) => LanguageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      taxid: json['taxid'] as String?,
      vatrate: (json['vatrate'] as num?)?.toDouble(),
      vattypesale: json['vattypesale'] as int?,
      vattypepurchase: json['vattypepurchase'] as int?,
      inquirytypesale: json['inquirytypesale'] as int?,
      inquirytypepurchase: json['inquirytypepurchase'] as int?,
    );

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
      'emailowners': instance.emailowners,
      'emailstaffs': instance.emailstaffs,
      'isusebranch': instance.isusebranch,
      'isusedepartment': instance.isusedepartment,
      'languageconfigs': instance.languageconfigs,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'taxid': instance.taxid,
      'vatrate': instance.vatrate,
      'vattypesale': instance.vattypesale,
      'vattypepurchase': instance.vattypepurchase,
      'inquirytypesale': instance.inquirytypesale,
      'inquirytypepurchase': instance.inquirytypepurchase,
    };
