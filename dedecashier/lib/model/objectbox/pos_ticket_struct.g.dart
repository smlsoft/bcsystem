// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_ticket_struct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PosTicketObjectBoxStruct _$PosTicketObjectBoxStructFromJson(
  Map<String, dynamic> json,
) => PosTicketObjectBoxStruct(
  logo: json['logo'] as bool? ?? true,
  print_mode: (json['print_mode'] as num?)?.toInt() ?? 0,
  printer_width: (json['printer_width'] as num?)?.toInt() ?? 0,
  guidfixed: json['guidfixed'] as String? ?? "",
  ticket_name: json['ticket_name'] as String? ?? "",
  shop_name: json['shop_name'] as bool? ?? true,
  shop_address: json['shop_address'] as bool? ?? true,
  shop_tax_id: json['shop_tax_id'] as bool? ?? true,
  shop_tel: json['shop_tel'] as bool? ?? true,
  cashier_detail: json['cashier_detail'] as bool? ?? true,
  customer_detail: json['customer_detail'] as bool? ?? true,
  customer_address: json['customer_address'] as bool? ?? true,
  customer_tax_id: json['customer_tax_id'] as bool? ?? true,
  sale_detail: json['sale_detail'] as bool? ?? true,
  doc_no_qr_code: json['doc_no_qr_code'] as bool? ?? true,
)..id = (json['id'] as num).toInt();

Map<String, dynamic> _$PosTicketObjectBoxStructToJson(
  PosTicketObjectBoxStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'guidfixed': instance.guidfixed,
  'ticket_name': instance.ticket_name,
  'print_mode': instance.print_mode,
  'printer_width': instance.printer_width,
  'logo': instance.logo,
  'shop_name': instance.shop_name,
  'shop_address': instance.shop_address,
  'shop_tax_id': instance.shop_tax_id,
  'shop_tel': instance.shop_tel,
  'cashier_detail': instance.cashier_detail,
  'customer_detail': instance.customer_detail,
  'customer_address': instance.customer_address,
  'customer_tax_id': instance.customer_tax_id,
  'sale_detail': instance.sale_detail,
  'doc_no_qr_code': instance.doc_no_qr_code,
};
