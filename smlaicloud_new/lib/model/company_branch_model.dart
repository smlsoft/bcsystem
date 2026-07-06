import 'package:smlaicloud/model/contact_model.dart';
import 'package:smlaicloud/model/business_type_model.dart';
import 'package:smlaicloud/model/department_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:smlaicloud/model/global_model.dart';

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
  PaymentRoundingModel? paymentrounding;
  PointConfigModel? pointconfig;

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
    PosModel? pos,
    BusinessTypeModel? businesstype,
    PaymentRoundingModel? paymentrounding,
    PointConfigModel? pointconfig,
  })  : names = names ?? <LanguageDataModel>[],
        companynames = companynames ?? <LanguageDataModel>[],
        departments = departments ?? <DepartmentModel>[],
        languages = languages ?? <String>[],
        contact = contact ?? ContactModel(),
        logouri = logouri ?? "",
        imageuri = imageuri ?? "",
        pos = pos ?? PosModel(),
        businesstype = businesstype ?? BusinessTypeModel(),
        paymentrounding = paymentrounding ?? PaymentRoundingModel(),
        pointconfig = pointconfig ?? PointConfigModel();

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
  bool? isbom;

  PosModel({
    String? taxid,
    double? vatrate,
    int? vattypesale,
    int? vattypepurchase,
    int? inquirytypesale,
    int? inquirytypepurchase,
    String? headerreceiptpos,
    String? footerreceiptpos,
    bool? isbom,
  })  : taxid = taxid ?? "",
        vatrate = vatrate ?? 0.0,
        vattypesale = vattypesale ?? 0,
        vattypepurchase = vattypepurchase ?? 0,
        inquirytypesale = inquirytypesale ?? 0,
        inquirytypepurchase = inquirytypepurchase ?? 0,
        headerreceiptpos = headerreceiptpos ?? "",
        footerreceiptpos = footerreceiptpos ?? "",
        isbom = isbom ?? false;

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

@JsonSerializable(explicitToJson: true)
class PaymentRoundingModel {
  PaymentMethodRoundingModel banktransfer;
  PaymentMethodRoundingModel cash;
  PaymentMethodRoundingModel cheque;
  PaymentMethodRoundingModel coupon;
  PaymentMethodRoundingModel creditcard;
  PaymentMethodRoundingModel delivery;
  PaymentMethodRoundingModel qrcode;

  PaymentRoundingModel({
    PaymentMethodRoundingModel? banktransfer,
    PaymentMethodRoundingModel? cash,
    PaymentMethodRoundingModel? cheque,
    PaymentMethodRoundingModel? coupon,
    PaymentMethodRoundingModel? creditcard,
    PaymentMethodRoundingModel? delivery,
    PaymentMethodRoundingModel? qrcode,
  })  : banktransfer = banktransfer ?? PaymentMethodRoundingModel(),
        cash = cash ?? PaymentMethodRoundingModel(),
        cheque = cheque ?? PaymentMethodRoundingModel(),
        coupon = coupon ?? PaymentMethodRoundingModel(),
        creditcard = creditcard ?? PaymentMethodRoundingModel(),
        delivery = delivery ?? PaymentMethodRoundingModel(),
        qrcode = qrcode ?? PaymentMethodRoundingModel();

  factory PaymentRoundingModel.fromJson(Map<String, dynamic> json) => _$PaymentRoundingModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentRoundingModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PaymentMethodRoundingModel {
  bool enabled;
  List<RoundingRuleModel> rules;

  PaymentMethodRoundingModel({
    bool? enabled,
    List<RoundingRuleModel>? rules,
  })  : enabled = enabled ?? true,
        rules = rules ?? [RoundingRuleModel()];

  factory PaymentMethodRoundingModel.fromJson(Map<String, dynamic> json) => _$PaymentMethodRoundingModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentMethodRoundingModelToJson(this);
}

@JsonSerializable()
class RoundingRuleModel {
  double lowerbound;
  double roundto;
  double upperbound;

  RoundingRuleModel({
    double? lowerbound,
    double? roundto,
    double? upperbound,
  })  : lowerbound = lowerbound ?? 0,
        roundto = roundto ?? 0,
        upperbound = upperbound ?? 0;

  factory RoundingRuleModel.fromJson(Map<String, dynamic> json) => _$RoundingRuleModelFromJson(json);

  Map<String, dynamic> toJson() => _$RoundingRuleModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PointConfigModel {
  List<GeneralRuleModel> generalrules;
  List<SpecialRuleModel> specialrules;
  int pointusagetype;
  PointConfigModel({
    List<GeneralRuleModel>? generalrules,
    List<SpecialRuleModel>? specialrules,
    int? pointusagetype,
  })  : generalrules = generalrules ?? <GeneralRuleModel>[],
        specialrules = specialrules ?? <SpecialRuleModel>[],
        pointusagetype = pointusagetype ?? 1;

  factory PointConfigModel.fromJson(Map<String, dynamic> json) => _$PointConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$PointConfigModelToJson(this);
}

@JsonSerializable()
class GeneralRuleModel {
  String startdate;
  String enddate;
  double payperpoint;
  double pointvalue;
  GeneralRuleModel({
    String? startdate,
    String? enddate,
    double? payperpoint,
    double? pointvalue,
  })  : startdate = startdate ?? DateTime.now().toUtc().toIso8601String(),
        enddate = enddate ?? DateTime.now().toUtc().add(const Duration(days: 365)).toIso8601String(),
        payperpoint = payperpoint ?? 20,
        pointvalue = pointvalue ?? 1;

  factory GeneralRuleModel.fromJson(Map<String, dynamic> json) => _$GeneralRuleModelFromJson(json);

  Map<String, dynamic> toJson() => _$GeneralRuleModelToJson(this);
}

@JsonSerializable()
class SpecialRuleModel {
  String startdate;
  String enddate;
  double multiplier;
  bool sunday;
  bool monday;
  bool tuesday;
  bool wednesday;
  bool thursday;
  bool friday;
  bool saturday;
  double maxpointperbill;

  SpecialRuleModel({
    String? startdate,
    String? enddate,
    double? multiplier,
    bool? sunday,
    bool? monday,
    bool? tuesday,
    bool? wednesday,
    bool? thursday,
    bool? friday,
    bool? saturday,
    double? maxpointperbill,  })  : startdate = startdate ?? DateTime.now().toUtc().toIso8601String(),
        enddate = enddate ?? DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String(),
        multiplier = multiplier ?? 2,
        sunday = sunday ?? false,
        monday = monday ?? true,
        tuesday = tuesday ?? true,
        wednesday = wednesday ?? true,
        thursday = thursday ?? true,
        friday = friday ?? true,
        saturday = saturday ?? false,
        maxpointperbill = maxpointperbill ?? 100;

  factory SpecialRuleModel.fromJson(Map<String, dynamic> json) => _$SpecialRuleModelFromJson(json);

  Map<String, dynamic> toJson() => _$SpecialRuleModelToJson(this);
}
