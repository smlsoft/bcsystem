// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_struct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShiftObjectBoxStruct _$ShiftObjectBoxStructFromJson(
  Map<String, dynamic> json,
) => ShiftObjectBoxStruct(
  guidfixed: json['guidfixed'] as String,
  doctype: (json['doctype'] as num).toInt(),
  docdate: DateTime.parse(json['docdate'] as String),
  remark: json['remark'] as String,
  usercode: json['usercode'] as String,
  username: json['username'] as String,
  amount: (json['amount'] as num).toDouble(),
  creditcard: (json['creditcard'] as num).toDouble(),
  promptpay: (json['promptpay'] as num).toDouble(),
  transfer: (json['transfer'] as num).toDouble(),
  cheque: (json['cheque'] as num).toDouble(),
  coupon: (json['coupon'] as num).toDouble(),
  isSync: json['isSync'] as bool,
  posid: json['posid'] as String,
  docno: json['docno'] as String,
)..id = (json['id'] as num).toInt();

Map<String, dynamic> _$ShiftObjectBoxStructToJson(
  ShiftObjectBoxStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'guidfixed': instance.guidfixed,
  'doctype': instance.doctype,
  'docdate': instance.docdate.toIso8601String(),
  'usercode': instance.usercode,
  'username': instance.username,
  'remark': instance.remark,
  'amount': instance.amount,
  'creditcard': instance.creditcard,
  'promptpay': instance.promptpay,
  'transfer': instance.transfer,
  'cheque': instance.cheque,
  'coupon': instance.coupon,
  'isSync': instance.isSync,
  'posid': instance.posid,
  'docno': instance.docno,
};
