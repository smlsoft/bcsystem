// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_branch_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompanyBranchModel _$CompanyBranchModelFromJson(Map<String, dynamic> json) =>
    CompanyBranchModel(
      guidfixed: json['guidfixed'] as String,
      code: json['code'] as String,
      companynames: (json['companynames'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      departments: (json['departments'] as List<dynamic>?)
          ?.map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      contact: json['contact'] == null
          ? null
          : ContactModel.fromJson(json['contact'] as Map<String, dynamic>),
      imageuri: json['imageuri'] as String?,
      logouri: json['logouri'] as String?,
      businesstype: json['businesstype'] == null
          ? null
          : BusinessTypeModel.fromJson(
              json['businesstype'] as Map<String, dynamic>),
    )..pos = json['pos'] == null
        ? null
        : PosModel.fromJson(json['pos'] as Map<String, dynamic>);

Map<String, dynamic> _$CompanyBranchModelToJson(CompanyBranchModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'companynames': instance.companynames.map((e) => e.toJson()).toList(),
      'code': instance.code,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'departments': instance.departments.map((e) => e.toJson()).toList(),
      'languages': instance.languages,
      'contact': instance.contact?.toJson(),
      'imageuri': instance.imageuri,
      'logouri': instance.logouri,
      'pos': instance.pos?.toJson(),
      'businesstype': instance.businesstype?.toJson(),
    };

PosModel _$PosModelFromJson(Map<String, dynamic> json) => PosModel(
      taxid: json['taxid'] as String?,
      vatrate: (json['vatrate'] as num?)?.toDouble(),
      vattypesale: json['vattypesale'] as int?,
      vattypepurchase: json['vattypepurchase'] as int?,
      inquirytypesale: json['inquirytypesale'] as int?,
      inquirytypepurchase: json['inquirytypepurchase'] as int?,
      headerreceiptpos: json['headerreceiptpos'] as String?,
      footerreceiptpos: json['footerreceiptpos'] as String?,
    );

Map<String, dynamic> _$PosModelToJson(PosModel instance) => <String, dynamic>{
      'taxid': instance.taxid,
      'vatrate': instance.vatrate,
      'vattypesale': instance.vattypesale,
      'vattypepurchase': instance.vattypepurchase,
      'inquirytypesale': instance.inquirytypesale,
      'inquirytypepurchase': instance.inquirytypepurchase,
      'headerreceiptpos': instance.headerreceiptpos,
      'footerreceiptpos': instance.footerreceiptpos,
    };

BranchModel _$BranchModelFromJson(Map<String, dynamic> json) => BranchModel(
      code: json['code'] as String?,
      guidfixed: json['guidfixed'] as String?,
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isignore: json['isignore'] as bool?,
    );

Map<String, dynamic> _$BranchModelToJson(BranchModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'guidfixed': instance.guidfixed,
      'names': instance.names,
      'isignore': instance.isignore,
    };
