// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffOrderModel _$StaffOrderModelFromJson(Map<String, dynamic> json) =>
    StaffOrderModel(
      tableNumber: json['tableNumber'] as String,
      barcode: json['barcode'] as String,
      qty: json['qty'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$StaffOrderModelToJson(StaffOrderModel instance) =>
    <String, dynamic>{
      'tableNumber': instance.tableNumber,
      'barcode': instance.barcode,
      'qty': instance.qty,
      'amount': instance.amount,
    };
