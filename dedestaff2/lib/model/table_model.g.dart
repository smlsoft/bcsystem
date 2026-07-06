// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableProcessObjectBoxStruct _$TableProcessObjectBoxStructFromJson(
        Map<String, dynamic> json) =>
    TableProcessObjectBoxStruct(
      id: (json['id'] as num).toInt(),
      guidfixed: json['guidfixed'] as String,
      number: json['number'] as String,
      number_main: json['number_main'] as String,
      names: json['names'] as String,
      zone: json['zone'] as String,
      table_status: (json['table_status'] as num).toInt(),
      order_count: (json['order_count'] as num).toDouble(),
      order_cancel_count: (json['order_cancel_count'] as num).toDouble(),
      order_served_count: (json['order_served_count'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      order_success: json['order_success'] as bool,
      qr_code: json['qr_code'] as String,
      table_open_datetime:
          DateTime.parse(json['table_open_datetime'] as String),
      man_count: (json['man_count'] as num).toInt(),
      woman_count: (json['woman_count'] as num).toInt(),
      child_count: (json['child_count'] as num).toInt(),
      table_al_la_crate_mode: json['table_al_la_crate_mode'] as bool,
      buffet_code: json['buffet_code'] as String,
      customer_code_or_telephone: json['customer_code_or_telephone'] as String,
      customer_name: json['customer_name'] as String,
      customer_address: json['customer_address'] as String,
      delivery_code: json['delivery_code'] as String,
      delivery_ticket_number: json['delivery_ticket_number'] as String,
      delivery_number: json['delivery_number'] as String,
      remark: json['remark'] as String,
      open_by_staff_code: json['open_by_staff_code'] as String,
      make_food_immediately: json['make_food_immediately'] as bool,
      is_delivery: json['is_delivery'] as bool,
      delivery_cook_success: json['delivery_cook_success'] as bool,
      delivery_cook_success_datetime:
          DateTime.parse(json['delivery_cook_success_datetime'] as String),
      delivery_send_success: json['delivery_send_success'] as bool,
      delivery_send_success_datetime:
          DateTime.parse(json['delivery_send_success_datetime'] as String),
      delivery_status: (json['delivery_status'] as num).toInt(),
      table_child_count: (json['table_child_count'] as num).toInt(),
      detail_discount_formula: json['detail_discount_formula'] as String,
      customer_nationality_code: json['customer_nationality_code'] as String,
      isUpdate: json['isUpdate'] as bool?,
    );

Map<String, dynamic> _$TableProcessObjectBoxStructToJson(
        TableProcessObjectBoxStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'guidfixed': instance.guidfixed,
      'number': instance.number,
      'number_main': instance.number_main,
      'names': instance.names,
      'zone': instance.zone,
      'table_status': instance.table_status,
      'amount': instance.amount,
      'order_success': instance.order_success,
      'table_open_datetime': instance.table_open_datetime.toIso8601String(),
      'qr_code': instance.qr_code,
      'man_count': instance.man_count,
      'woman_count': instance.woman_count,
      'child_count': instance.child_count,
      'table_al_la_crate_mode': instance.table_al_la_crate_mode,
      'buffet_code': instance.buffet_code,
      'customer_code_or_telephone': instance.customer_code_or_telephone,
      'customer_name': instance.customer_name,
      'customer_address': instance.customer_address,
      'delivery_code': instance.delivery_code,
      'delivery_number': instance.delivery_number,
      'delivery_ticket_number': instance.delivery_ticket_number,
      'remark': instance.remark,
      'open_by_staff_code': instance.open_by_staff_code,
      'make_food_immediately': instance.make_food_immediately,
      'is_delivery': instance.is_delivery,
      'delivery_cook_success': instance.delivery_cook_success,
      'delivery_cook_success_datetime':
          instance.delivery_cook_success_datetime.toIso8601String(),
      'delivery_send_success': instance.delivery_send_success,
      'delivery_send_success_datetime':
          instance.delivery_send_success_datetime.toIso8601String(),
      'delivery_status': instance.delivery_status,
      'table_child_count': instance.table_child_count,
      'detail_discount_formula': instance.detail_discount_formula,
      'customer_nationality_code': instance.customer_nationality_code,
      'order_count': instance.order_count,
      'order_cancel_count': instance.order_cancel_count,
      'order_served_count': instance.order_served_count,
      'isUpdate': instance.isUpdate,
    };
