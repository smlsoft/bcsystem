// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_invoice_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleInvoiceItemModel _$SaleInvoiceItemModelFromJson(
  Map<String, dynamic> json,
) => SaleInvoiceItemModel(
  linenumber: (json['linenumber'] as num).toInt(),
  itemcode: json['itemcode'] as String,
  itemguid: json['itemguid'] as String,
  itemsku: json['itemsku'] as String,
  barcode: json['barcode'] as String,
  name1: json['name1'] as String,
  name2: json['name2'] as String,
  name3: json['name3'] as String,
  name4: json['name4'] as String,
  name5: json['name5'] as String,
  itemunitcode: json['itemunitcode'] as String,
  itemunitdiv: json['itemunitdiv'] as String,
  itemunitstd: json['itemunitstd'] as String,
  category: json['category'] as String,
  price: (json['price'] as num).toDouble(),
  qty: (json['qty'] as num).toDouble(),
  discounttext: json['discounttext'] as String,
  discountamount: (json['discountamount'] as num).toDouble(),
  amount: (json['amount'] as num).toDouble(),
);

Map<String, dynamic> _$SaleInvoiceItemModelToJson(
  SaleInvoiceItemModel instance,
) => <String, dynamic>{
  'linenumber': instance.linenumber,
  'itemcode': instance.itemcode,
  'itemguid': instance.itemguid,
  'itemsku': instance.itemsku,
  'barcode': instance.barcode,
  'name1': instance.name1,
  'name2': instance.name2,
  'name3': instance.name3,
  'name4': instance.name4,
  'name5': instance.name5,
  'itemunitcode': instance.itemunitcode,
  'itemunitdiv': instance.itemunitdiv,
  'itemunitstd': instance.itemunitstd,
  'category': instance.category,
  'price': instance.price,
  'qty': instance.qty,
  'discounttext': instance.discounttext,
  'discountamount': instance.discountamount,
  'amount': instance.amount,
};
