// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShiftModel _$ShiftModelFromJson(Map<String, dynamic> json) => ShiftModel(
  guidfixed: json['guidfixed'] as String?,
  doctype: (json['doctype'] as num?)?.toInt(),
  docdate: json['docdate'] as String?,
  usercode: json['usercode'] as String?,
  username: json['username'] as String?,
  remark: json['remark'] as String?,
  amount: (json['amount'] as num?)?.toDouble(),
  creditcard: (json['creditcard'] as num?)?.toDouble(),
  promptpay: (json['promptpay'] as num?)?.toDouble(),
  transfer: (json['transfer'] as num?)?.toDouble(),
  cheque: (json['cheque'] as num?)?.toDouble(),
  coupon: (json['coupon'] as num?)?.toDouble(),
  posid: json['posid'] as String?,
  docno: json['docno'] as String?,
);

Map<String, dynamic> _$ShiftModelToJson(ShiftModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'doctype': instance.doctype,
      'docdate': instance.docdate,
      'usercode': instance.usercode,
      'username': instance.username,
      'remark': instance.remark,
      'amount': instance.amount,
      'creditcard': instance.creditcard,
      'promptpay': instance.promptpay,
      'transfer': instance.transfer,
      'cheque': instance.cheque,
      'coupon': instance.coupon,
      'posid': instance.posid,
      'docno': instance.docno,
    };
