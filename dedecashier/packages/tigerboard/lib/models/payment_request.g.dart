// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentGenQRRequest _$PaymentGenQRRequestFromJson(Map<String, dynamic> json) =>
    PaymentGenQRRequest(
      order_id: json['order_id'] as String,
      merchant_id: (json['merchant_id'] as num?)?.toInt(),
      pos_id: (json['pos_id'] as num?)?.toInt(),
      customer_name: json['customer_name'] as String?,
      title: json['title'] as String?,
      table_number: (json['table_number'] as num?)?.toInt(),
      status: json['status'] as String?,
      ref1: json['ref1'] as String?,
      ref2: json['ref2'] as String?,
      category: json['category'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      discount_amt: (json['discount_amt'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble(),
      created_id: (json['created_id'] as num?)?.toInt(),
      updated_id: (json['updated_id'] as num?)?.toInt(),
      pos_created_date: json['pos_created_date'] as String?,
    );

Map<String, dynamic> _$PaymentGenQRRequestToJson(
        PaymentGenQRRequest instance) =>
    <String, dynamic>{
      'order_id': instance.order_id,
      'merchant_id': instance.merchant_id,
      'pos_id': instance.pos_id,
      'customer_name': instance.customer_name,
      'title': instance.title,
      'table_number': instance.table_number,
      'status': instance.status,
      'ref1': instance.ref1,
      'ref2': instance.ref2,
      'category': instance.category,
      'amount': instance.amount,
      'discount_amt': instance.discount_amt,
      'total': instance.total,
      'created_id': instance.created_id,
      'updated_id': instance.updated_id,
      'pos_created_date': instance.pos_created_date,
    };
