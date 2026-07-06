import 'package:dedecashier/global_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'member_model.g.dart';

@JsonSerializable(explicitToJson: true)
class MemberModel {
  String code;
  bool ismember;
  String guidfixed;
  List<LanguageDataModel> names;
  MemberAddressForBillingModel addressforbilling;
  int personaltype;
  String branchnumber;
  String taxid;
  String email;
  double pointbalance;
  int customertype;
  String pointscode;
  String pricelevel;
  List<Group> groups;

  MemberModel({
    required this.code,
    bool? ismember,
    int? personaltype,
    String? guidfixed,
    String? branchnumber,
    String? taxid,
    String? email,
    int? customertype,
    double? pointbalance,
    required this.names,
    MemberAddressForBillingModel? addressforbilling,
    String? pointscode,
    String? pricelevel,
    List<Group>? groups,
  })  : ismember = ismember ?? false,
        addressforbilling = addressforbilling ??
            MemberAddressForBillingModel(
              phoneprimary: '',
              phonesecondary: '',
              address: [],
              contactnames: [],
            ),
        guidfixed = guidfixed ?? '',
        pricelevel = pricelevel ?? '',
        groups = groups ?? [],
        taxid = taxid ?? '',
        email = email ?? '',
        customertype = customertype ?? 0,
        branchnumber = branchnumber ?? '',
        personaltype = personaltype ?? 0,
        pointbalance = pointbalance ?? 0.0,
        pointscode = pointscode ?? '';

  factory MemberModel.fromJson(Map<String, dynamic> json) => _$MemberModelFromJson(json);

  Map<String, dynamic> toJson() => _$MemberModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Group {
  String groupcode;
  List<LanguageDataModel> names;

  Group({required this.groupcode, required this.names});

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);

  Map<String, dynamic> toJson() => _$GroupToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MemberAddressForBillingModel {
  String phoneprimary;
  String phonesecondary;
  List<String> address;
  List<LanguageDataModel> contactnames;

  MemberAddressForBillingModel({
    List<String>? address,
    List<LanguageDataModel>? contactnames,
    required this.phoneprimary,
    required this.phonesecondary,
  })  : address = address ?? [],
        contactnames = contactnames ?? [];

  factory MemberAddressForBillingModel.fromJson(Map<String, dynamic> json) => _$MemberAddressForBillingModelFromJson(json);

  Map<String, dynamic> toJson() => _$MemberAddressForBillingModelToJson(this);
}
