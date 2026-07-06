// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_struct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableObjectBoxStruct _$TableObjectBoxStructFromJson(
  Map<String, dynamic> json,
) => TableObjectBoxStruct(
  guidfixed: json['guidfixed'] as String,
  number: json['number'] as String,
  numberMain: json['numberMain'] as String,
  names: json['names'] as String,
  zone: json['zone'] as String,
)..id = (json['id'] as num).toInt();

Map<String, dynamic> _$TableObjectBoxStructToJson(
  TableObjectBoxStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'guidfixed': instance.guidfixed,
  'number': instance.number,
  'numberMain': instance.numberMain,
  'names': instance.names,
  'zone': instance.zone,
};

TableProcessObjectBoxStruct _$TableProcessObjectBoxStructFromJson(
  Map<String, dynamic> json,
) => TableProcessObjectBoxStruct(
  guidfixed: json['guidfixed'] as String,
  number: json['number'] as String?,
  number_main: json['number_main'] as String?,
  names: json['names'] as String?,
  zone: json['zone'] as String?,
  table_status: (json['table_status'] as num?)?.toInt(),
  order_count: (json['order_count'] as num?)?.toDouble(),
  order_cancel_count: (json['order_cancel_count'] as num?)?.toDouble(),
  order_served_count: (json['order_served_count'] as num?)?.toDouble(),
  amount: (json['amount'] as num?)?.toDouble(),
  order_success: json['order_success'] as bool?,
  qr_code: json['qr_code'] as String?,
  table_open_datetime: json['table_open_datetime'] == null
      ? null
      : DateTime.parse(json['table_open_datetime'] as String),
  man_count: (json['man_count'] as num?)?.toInt(),
  woman_count: (json['woman_count'] as num?)?.toInt(),
  child_count: (json['child_count'] as num?)?.toInt(),
  table_al_la_crate_mode: json['table_al_la_crate_mode'] as bool?,
  buffet_code: json['buffet_code'] as String?,
  customer_code_or_telephone: json['customer_code_or_telephone'] as String?,
  customer_name: json['customer_name'] as String?,
  customer_address: json['customer_address'] as String?,
  delivery_code: json['delivery_code'] as String?,
  delivery_number: json['delivery_number'] as String?,
  delivery_ticket_number: json['delivery_ticket_number'] as String?,
  remark: json['remark'] as String?,
  open_by_staff_code: json['open_by_staff_code'] as String?,
  make_food_immediately: json['make_food_immediately'] as bool?,
  is_delivery: json['is_delivery'] as bool?,
  delivery_cook_success: json['delivery_cook_success'] as bool?,
  delivery_cook_success_datetime: json['delivery_cook_success_datetime'] == null
      ? null
      : DateTime.parse(json['delivery_cook_success_datetime'] as String),
  delivery_send_success: json['delivery_send_success'] as bool?,
  delivery_send_success_datetime: json['delivery_send_success_datetime'] == null
      ? null
      : DateTime.parse(json['delivery_send_success_datetime'] as String),
  delivery_status: (json['delivery_status'] as num?)?.toInt(),
  table_child_count: (json['table_child_count'] as num?)?.toInt(),
  detail_discount_formula: json['detail_discount_formula'] as String?,
  customer_nationality_code: json['customer_nationality_code'] as String?,
  isUpdate: json['isUpdate'] as bool?,
)..id = (json['id'] as num).toInt();

Map<String, dynamic> _$TableProcessObjectBoxStructToJson(
  TableProcessObjectBoxStruct instance,
) => <String, dynamic>{
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
  'delivery_ticket_number': instance.delivery_ticket_number,
  'delivery_number': instance.delivery_number,
  'remark': instance.remark,
  'open_by_staff_code': instance.open_by_staff_code,
  'make_food_immediately': instance.make_food_immediately,
  'is_delivery': instance.is_delivery,
  'delivery_cook_success': instance.delivery_cook_success,
  'delivery_cook_success_datetime': instance.delivery_cook_success_datetime
      .toIso8601String(),
  'delivery_send_success': instance.delivery_send_success,
  'delivery_send_success_datetime': instance.delivery_send_success_datetime
      .toIso8601String(),
  'delivery_status': instance.delivery_status,
  'table_child_count': instance.table_child_count,
  'detail_discount_formula': instance.detail_discount_formula,
  'customer_nationality_code': instance.customer_nationality_code,
  'order_count': instance.order_count,
  'order_cancel_count': instance.order_cancel_count,
  'order_served_count': instance.order_served_count,
  'isUpdate': instance.isUpdate,
};

CloseTableModel _$CloseTableModelFromJson(Map<String, dynamic> json) =>
    CloseTableModel(
      table: TableProcessObjectBoxStruct.fromJson(
        json['table'] as Map<String, dynamic>,
      ),
      payMode: (json['payMode'] as num).toInt(),
      slipImage: json['slipImage'] as String,
      discountFormula: json['discountFormula'] as String,
      payAmount: (json['payAmount'] as num).toDouble(),
      process: PosProcessModel.fromJson(
        json['process'] as Map<String, dynamic>,
      ),
      roundamount: (json['roundamount'] as num?)?.toDouble(),
      transactionId: json['transactionId'] as String?,
      payqrcodename: json['payqrcodename'] as String?,
      providercode: json['providercode'] as String?,
      providername: json['providername'] as String?,
    );

Map<String, dynamic> _$CloseTableModelToJson(CloseTableModel instance) =>
    <String, dynamic>{
      'table': instance.table.toJson(),
      'payMode': instance.payMode,
      'slipImage': instance.slipImage,
      'process': instance.process.toJson(),
      'discountFormula': instance.discountFormula,
      'roundamount': instance.roundamount,
      'payAmount': instance.payAmount,
      'transactionId': instance.transactionId,
      'payqrcodename': instance.payqrcodename,
      'providercode': instance.providercode,
      'providername': instance.providername,
    };
