// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_invoice_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleInvoiceModel _$SaleInvoiceModelFromJson(Map<String, dynamic> json) =>
    SaleInvoiceModel(
      doc_number: json['doc_number'] as String? ?? "",
      customer_code: json['customer_code'] as String? ?? "",
      customer_name: json['customer_name'] as String? ?? "",
      customer_telephone: json['customer_telephone'] as String? ?? "",
      total_amount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      person_code: json['person_code'] as String? ?? "",
      person_name: json['person_name'] as String? ?? "",
      createDatetime: json['createDatetime'] as String? ?? "",
      issync: (json['issync'] as num?)?.toInt() ?? 0,
      syncdatetime: json['syncdatetime'] as String? ?? "",
    )..date_time = DateTime.parse(json['date_time'] as String);

Map<String, dynamic> _$SaleInvoiceModelToJson(SaleInvoiceModel instance) =>
    <String, dynamic>{
      'date_time': instance.date_time.toIso8601String(),
      'doc_number': instance.doc_number,
      'customer_code': instance.customer_code,
      'customer_name': instance.customer_name,
      'customer_telephone': instance.customer_telephone,
      'total_amount': instance.total_amount,
      'person_code': instance.person_code,
      'person_name': instance.person_name,
      'createDatetime': instance.createDatetime,
      'issync': instance.issync,
      'syncdatetime': instance.syncdatetime,
    };
