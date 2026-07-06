import 'package:cocomerchant_lite/model/contact_model.dart';
import 'package:cocomerchant_lite/model/business_type_model.dart';
import 'package:cocomerchant_lite/model/department_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:cocomerchant_lite/model/global_model.dart';

part 'company_branch_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CompanyBranchModel {
  String guidfixed;
  List<LanguageDataModel> companynames = <LanguageDataModel>[];
  String code;
  List<LanguageDataModel> names = <LanguageDataModel>[];
  List<DepartmentModel> departments = <DepartmentModel>[];
  List<String> languages;
  ContactModel? contact;
  String? imageuri;
  String? logouri;
  PosModel? pos;
  BusinessTypeModel? businesstype;

  CompanyBranchModel({
    required this.guidfixed,
    required this.code,
    List<LanguageDataModel>? companynames,
    List<LanguageDataModel>? names,
    List<DepartmentModel>? departments,
    List<String>? languages,
    ContactModel? contact,
    String? imageuri,
    String? logouri,
    PosModel? taxid,
    BusinessTypeModel? businesstype,
  })  : names = names ?? <LanguageDataModel>[],
        companynames = companynames ?? <LanguageDataModel>[],
        departments = departments ?? <DepartmentModel>[],
        languages = languages ?? <String>[],
        contact = contact ?? ContactModel(),
        logouri = logouri ?? "",
        imageuri = imageuri ?? "",
        pos = taxid ?? PosModel(),
        businesstype = businesstype ?? BusinessTypeModel();

  factory CompanyBranchModel.fromJson(Map<String, dynamic> json) => _$CompanyBranchModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompanyBranchModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PosModel {
  String? taxid;
  double? vatrate;
  int? vattypesale;
  int? vattypepurchase;
  int? inquirytypesale;
  int? inquirytypepurchase;
  String? headerreceiptpos;
  String? footerreceiptpos;

  PosModel({
    String? taxid,
    double? vatrate,
    int? vattypesale,
    int? vattypepurchase,
    int? inquirytypesale,
    int? inquirytypepurchase,
    String? headerreceiptpos,
    String? footerreceiptpos,
  })  : taxid = taxid ?? "",
        vatrate = vatrate ?? 0.0,
        vattypesale = vattypesale ?? 0,
        vattypepurchase = vattypepurchase ?? 0,
        inquirytypesale = inquirytypesale ?? 0,
        inquirytypepurchase = inquirytypepurchase ?? 0,
        headerreceiptpos = headerreceiptpos ?? "",
        footerreceiptpos = footerreceiptpos ?? "";

  factory PosModel.fromJson(Map<String, dynamic> json) => _$PosModelFromJson(json);

  Map<String, dynamic> toJson() => _$PosModelToJson(this);
}

@JsonSerializable()
class BranchModel {
  String? code;
  String? guidfixed;
  List<LanguageDataModel>? names;
  bool? isignore;

  BranchModel({
    String? code,
    String? guidfixed,
    List<LanguageDataModel>? names,
    bool? isignore,
  })  : code = code ?? '',
        guidfixed = guidfixed ?? '',
        names = names ?? [],
        isignore = isignore ?? false;

  factory BranchModel.fromJson(Map<String, dynamic> json) => _$BranchModelFromJson(json);
  Map<String, dynamic> toJson() => _$BranchModelToJson(this);
}
