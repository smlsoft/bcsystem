// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_payment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferPaymentModel _$TransferPaymentModelFromJson(
  Map<String, dynamic> json,
) => TransferPaymentModel(
  bankcode: json['bankcode'] as String,
  amount: (json['amount'] as num).toDouble(),
);

Map<String, dynamic> _$TransferPaymentModelToJson(
  TransferPaymentModel instance,
) => <String, dynamic>{
  'bankcode': instance.bankcode,
  'amount': instance.amount,
};
