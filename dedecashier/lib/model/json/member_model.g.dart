// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberModel _$MemberModelFromJson(Map<String, dynamic> json) => MemberModel(
  code: json['code'] as String,
  ismember: json['ismember'] as bool?,
  personaltype: (json['personaltype'] as num?)?.toInt(),
  guidfixed: json['guidfixed'] as String?,
  branchnumber: json['branchnumber'] as String?,
  taxid: json['taxid'] as String?,
  email: json['email'] as String?,
  customertype: (json['customertype'] as num?)?.toInt(),
  pointbalance: (json['pointbalance'] as num?)?.toDouble(),
  names: (json['names'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  addressforbilling: json['addressforbilling'] == null
      ? null
      : MemberAddressForBillingModel.fromJson(
          json['addressforbilling'] as Map<String, dynamic>,
        ),
  pointscode: json['pointscode'] as String?,
  pricelevel: json['pricelevel'] as String?,
  groups: (json['groups'] as List<dynamic>?)
      ?.map((e) => Group.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MemberModelToJson(MemberModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'ismember': instance.ismember,
      'guidfixed': instance.guidfixed,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'addressforbilling': instance.addressforbilling.toJson(),
      'personaltype': instance.personaltype,
      'branchnumber': instance.branchnumber,
      'taxid': instance.taxid,
      'email': instance.email,
      'pointbalance': instance.pointbalance,
      'customertype': instance.customertype,
      'pointscode': instance.pointscode,
      'pricelevel': instance.pricelevel,
      'groups': instance.groups.map((e) => e.toJson()).toList(),
    };

Group _$GroupFromJson(Map<String, dynamic> json) => Group(
  groupcode: json['groupcode'] as String,
  names: (json['names'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
  'groupcode': instance.groupcode,
  'names': instance.names.map((e) => e.toJson()).toList(),
};

MemberAddressForBillingModel _$MemberAddressForBillingModelFromJson(
  Map<String, dynamic> json,
) => MemberAddressForBillingModel(
  address: (json['address'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  contactnames: (json['contactnames'] as List<dynamic>?)
      ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  phoneprimary: json['phoneprimary'] as String,
  phonesecondary: json['phonesecondary'] as String,
);

Map<String, dynamic> _$MemberAddressForBillingModelToJson(
  MemberAddressForBillingModel instance,
) => <String, dynamic>{
  'phoneprimary': instance.phoneprimary,
  'phonesecondary': instance.phonesecondary,
  'address': instance.address,
  'contactnames': instance.contactnames.map((e) => e.toJson()).toList(),
};
