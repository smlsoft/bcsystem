// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_log_struct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PosLogObjectBoxStruct _$PosLogObjectBoxStructFromJson(
  Map<String, dynamic> json,
) => PosLogObjectBoxStruct(
  id: (json['id'] as num?)?.toInt() ?? 0,
  doc_mode: (json['doc_mode'] as num?)?.toInt() ?? 1,
  guid_ref: json['guid_ref'] as String? ?? "",
  guid_code_ref: json['guid_code_ref'] as String? ?? "",
  log_date_time: DateTime.parse(json['log_date_time'] as String),
  hold_code: json['hold_code'] as String,
  command_code: (json['command_code'] as num).toInt(),
  barcode: json['barcode'] as String? ?? "",
  is_void: (json['is_void'] as num?)?.toInt() ?? 0,
  success: (json['success'] as num?)?.toInt() ?? 0,
  qty: (json['qty'] as num?)?.toDouble() ?? 0,
  qty_fixed: (json['qty_fixed'] as num?)?.toDouble() ?? 0,
  price: (json['price'] as num?)?.toDouble() ?? 0,
  selected: json['selected'] as bool? ?? false,
  remark: json['remark'] as String? ?? "",
  name: json['name'] as String? ?? "",
  code: json['code'] as String? ?? "",
  default_code: json['default_code'] as String? ?? "",
  discount_text: json['discount_text'] as String? ?? "",
  extra_code: json['extra_code'] as String? ?? "",
  unit_code: json['unit_code'] as String? ?? "",
  unit_stand: (json['unit_stand'] as num?)?.toDouble() ?? 1,
  unit_divide: (json['unit_divide'] as num?)?.toDouble() ?? 1,
  unit_name: json['unit_name'] as String? ?? "",
  price_exclude_vat_type: json['price_exclude_vat_type'] as bool? ?? false,
  is_except_vat: json['is_except_vat'] as bool? ?? false,
  price_exclude_vat: (json['price_exclude_vat'] as num?)?.toDouble() ?? 0,
  refbarcode: json['refbarcode'] as String?,
  refunitcode: json['refunitcode'] as String?,
  guid_auto_fixed: json['guid_auto_fixed'] as String?,
  issumpoint: json['issumpoint'] as bool? ?? false,
);

Map<String, dynamic> _$PosLogObjectBoxStructToJson(
  PosLogObjectBoxStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'guid_auto_fixed': instance.guid_auto_fixed,
  'doc_mode': instance.doc_mode,
  'guid_ref': instance.guid_ref,
  'guid_code_ref': instance.guid_code_ref,
  'log_date_time': instance.log_date_time.toIso8601String(),
  'hold_code': instance.hold_code,
  'command_code': instance.command_code,
  'is_void': instance.is_void,
  'success': instance.success,
  'issumpoint': instance.issumpoint,
  'extra_code': instance.extra_code,
  'remark': instance.remark,
  'discount_text': instance.discount_text,
  'code': instance.code,
  'price': instance.price,
  'name': instance.name,
  'qty': instance.qty,
  'qty_fixed': instance.qty_fixed,
  'default_code': instance.default_code,
  'selected': instance.selected,
  'unit_code': instance.unit_code,
  'unit_stand': instance.unit_stand,
  'unit_divide': instance.unit_divide,
  'unit_name': instance.unit_name,
  'barcode': instance.barcode,
  'price_exclude_vat_type': instance.price_exclude_vat_type,
  'is_except_vat': instance.is_except_vat,
  'price_exclude_vat': instance.price_exclude_vat,
  'refbarcode': instance.refbarcode,
  'refunitcode': instance.refunitcode,
};
