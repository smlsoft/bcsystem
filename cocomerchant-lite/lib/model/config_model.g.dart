// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigSystemModel _$ConfigSystemModelFromJson(Map<String, dynamic> json) =>
    ConfigSystemModel(
      languageList: (json['languageList'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ConfigSystemModelToJson(ConfigSystemModel instance) =>
    <String, dynamic>{
      'languageList': instance.languageList,
    };

DeviceConfigModel _$DeviceConfigModelFromJson(Map<String, dynamic> json) =>
    DeviceConfigModel(
      listDataFontSize: (json['listDataFontSize'] as num).toDouble(),
      listDataLineSpace: (json['listDataLineSpace'] as num).toDouble(),
      itemDisplaySku: json['itemDisplaySku'] as bool,
      itemDisplayPrice: json['itemDisplayPrice'] as bool,
    );

Map<String, dynamic> _$DeviceConfigModelToJson(DeviceConfigModel instance) =>
    <String, dynamic>{
      'listDataFontSize': instance.listDataFontSize,
      'listDataLineSpace': instance.listDataLineSpace,
      'itemDisplaySku': instance.itemDisplaySku,
      'itemDisplayPrice': instance.itemDisplayPrice,
    };

CompanyModel _$CompanyModelFromJson(Map<String, dynamic> json) => CompanyModel(
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      taxID: json['taxID'] as String,
      branchNames: (json['branchNames'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      addresses: (json['addresses'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      phones:
          (json['phones'] as List<dynamic>).map((e) => e as String).toList(),
      emailOwners: (json['emailOwners'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      emailStaffs: (json['emailStaffs'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      latitude: json['latitude'] as String,
      longitude: json['longitude'] as String,
      usebranch: json['usebranch'] as bool?,
      usedepartment: json['usedepartment'] as bool?,
      images: (json['images'] as List<dynamic>)
          .map((e) => ImagesModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      logo: json['logo'] as String?,
    );

Map<String, dynamic> _$CompanyModelToJson(CompanyModel instance) =>
    <String, dynamic>{
      'names': instance.names.map((e) => e.toJson()).toList(),
      'taxID': instance.taxID,
      'branchNames': instance.branchNames.map((e) => e.toJson()).toList(),
      'addresses': instance.addresses.map((e) => e.toJson()).toList(),
      'phones': instance.phones,
      'emailOwners': instance.emailOwners,
      'emailStaffs': instance.emailStaffs,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'usebranch': instance.usebranch,
      'usedepartment': instance.usedepartment,
      'images': instance.images.map((e) => e.toJson()).toList(),
      'logo': instance.logo,
    };
