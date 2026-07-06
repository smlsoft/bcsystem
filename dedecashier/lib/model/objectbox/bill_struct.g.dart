// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_struct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillDetailExtraObjectBoxStruct _$BillDetailExtraObjectBoxStructFromJson(
  Map<String, dynamic> json,
) => BillDetailExtraObjectBoxStruct(
  barcode: json['barcode'] as String,
  item_code: json['item_code'] as String,
  item_name: json['item_name'] as String,
  unit_code: json['unit_code'] as String,
  unit_name: json['unit_name'] as String,
  qty: (json['qty'] as num).toDouble(),
  price: (json['price'] as num).toDouble(),
  is_except_vat: json['is_except_vat'] as bool,
  vat_type: (json['vat_type'] as num).toInt(),
  price_exclude_vat: (json['price_exclude_vat'] as num).toDouble(),
  total_amount: (json['total_amount'] as num).toDouble(),
  refbarcode: json['refbarcode'] as String?,
  refunitcode: json['refunitcode'] as String?,
);

Map<String, dynamic> _$BillDetailExtraObjectBoxStructToJson(
  BillDetailExtraObjectBoxStruct instance,
) => <String, dynamic>{
  'barcode': instance.barcode,
  'refbarcode': instance.refbarcode,
  'refunitcode': instance.refunitcode,
  'item_code': instance.item_code,
  'item_name': instance.item_name,
  'unit_code': instance.unit_code,
  'unit_name': instance.unit_name,
  'qty': instance.qty,
  'price': instance.price,
  'total_amount': instance.total_amount,
  'is_except_vat': instance.is_except_vat,
  'vat_type': instance.vat_type,
  'price_exclude_vat': instance.price_exclude_vat,
};

BillPayObjectBoxStruct _$BillPayObjectBoxStructFromJson(
  Map<String, dynamic> json,
) =>
    BillPayObjectBoxStruct(
        doc_mode: (json['doc_mode'] as num?)?.toInt() ?? 0,
        trans_flag: (json['trans_flag'] as num?)?.toInt() ?? 0,
        bank_code: json['bank_code'] as String? ?? "",
        card_number: json['card_number'] as String? ?? "",
        approved_code: json['approved_code'] as String? ?? "",
        bank_name: json['bank_name'] as String? ?? "",
        book_bank_code: json['book_bank_code'] as String? ?? "",
        branch_number: json['branch_number'] as String? ?? "",
        bank_reference: json['bank_reference'] as String? ?? "",
        cheque_number: json['cheque_number'] as String? ?? "",
        code: json['code'] as String? ?? "",
        description: json['description'] as String? ?? "",
        number: json['number'] as String? ?? "",
        reference_one: json['reference_one'] as String? ?? "",
        reference_two: json['reference_two'] as String? ?? "",
        provider_code: json['provider_code'] as String? ?? "",
        provider_name: json['provider_name'] as String? ?? "",
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      )
      ..doc_date_time = DateTime.parse(json['doc_date_time'] as String)
      ..due_date = DateTime.parse(json['due_date'] as String);

Map<String, dynamic> _$BillPayObjectBoxStructToJson(
  BillPayObjectBoxStruct instance,
) => <String, dynamic>{
  'doc_mode': instance.doc_mode,
  'trans_flag': instance.trans_flag,
  'bank_code': instance.bank_code,
  'bank_name': instance.bank_name,
  'book_bank_code': instance.book_bank_code,
  'card_number': instance.card_number,
  'approved_code': instance.approved_code,
  'doc_date_time': instance.doc_date_time.toIso8601String(),
  'branch_number': instance.branch_number,
  'bank_reference': instance.bank_reference,
  'due_date': instance.due_date.toIso8601String(),
  'cheque_number': instance.cheque_number,
  'code': instance.code,
  'description': instance.description,
  'number': instance.number,
  'reference_one': instance.reference_one,
  'reference_two': instance.reference_two,
  'provider_code': instance.provider_code,
  'provider_name': instance.provider_name,
  'amount': instance.amount,
};
