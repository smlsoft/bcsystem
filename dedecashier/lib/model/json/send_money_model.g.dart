// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_money_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendMoneyModel _$SendMoneyModelFromJson(Map<String, dynamic> json) =>
    SendMoneyModel(
      create_date_time: DateTime.parse(json['create_date_time'] as String),
      doc_date_time: DateTime.parse(json['doc_date_time'] as String),
      remark: json['remark'] as String? ?? "",
      doc_number: json['doc_number'] as String? ?? "",
      person_code: json['person_code'] as String? ?? "",
      pos_number: json['pos_number'] as String? ?? "",
      receive_money: (json['receive_money'] as num?)?.toDouble() ?? 0,
      send_cash: (json['send_cash'] as num?)?.toDouble() ?? 0,
      send_coupon: (json['send_coupon'] as num?)?.toDouble() ?? 0,
      send_credit: (json['send_credit'] as num?)?.toDouble() ?? 0,
      send_transfer: (json['send_transfer'] as num?)?.toDouble() ?? 0,
      send_cheque: (json['send_cheque'] as num?)?.toDouble() ?? 0,
      send_discount: (json['send_discount'] as num?)?.toDouble() ?? 0,
      send_wallet: (json['send_wallet'] as num?)?.toDouble() ?? 0,
      send_promptpay: (json['send_promptpay'] as num?)?.toDouble() ?? 0,
      total_send_money: (json['total_send_money'] as num?)?.toDouble() ?? 0,
      send_coupon_count: (json['send_coupon_count'] as num?)?.toInt() ?? 0,
      send_credit_count: (json['send_credit_count'] as num?)?.toInt() ?? 0,
      send_transfer_count: (json['send_transfer_count'] as num?)?.toInt() ?? 0,
      send_cheque_count: (json['send_cheque_count'] as num?)?.toInt() ?? 0,
      send_discount_count: (json['send_discount_count'] as num?)?.toInt() ?? 0,
      send_wallet_count: (json['send_wallet_count'] as num?)?.toInt() ?? 0,
      send_promptpay_count:
          (json['send_promptpay_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SendMoneyModelToJson(SendMoneyModel instance) =>
    <String, dynamic>{
      'create_date_time': instance.create_date_time.toIso8601String(),
      'doc_date_time': instance.doc_date_time.toIso8601String(),
      'doc_number': instance.doc_number,
      'person_code': instance.person_code,
      'pos_number': instance.pos_number,
      'remark': instance.remark,
      'receive_money': instance.receive_money,
      'send_cash': instance.send_cash,
      'send_coupon': instance.send_coupon,
      'send_credit': instance.send_credit,
      'send_transfer': instance.send_transfer,
      'send_cheque': instance.send_cheque,
      'send_discount': instance.send_discount,
      'send_wallet': instance.send_wallet,
      'total_send_money': instance.total_send_money,
      'send_promptpay': instance.send_promptpay,
      'send_coupon_count': instance.send_coupon_count,
      'send_credit_count': instance.send_credit_count,
      'send_transfer_count': instance.send_transfer_count,
      'send_cheque_count': instance.send_cheque_count,
      'send_discount_count': instance.send_discount_count,
      'send_wallet_count': instance.send_wallet_count,
      'send_promptpay_count': instance.send_promptpay_count,
    };
