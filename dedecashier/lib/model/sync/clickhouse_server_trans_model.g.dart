// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clickhouse_server_trans_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableProcessClickHouseServerStruct _$TableProcessClickHouseServerStructFromJson(
  Map<String, dynamic> json,
) => TableProcessClickHouseServerStruct(
  guidfixed: json['guidfixed'] as String,
  number: json['number'] as String,
  number_main: json['number_main'] as String,
  names: (json['names'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  zone: json['zone'] as String,
  table_status: (json['table_status'] as num).toInt(),
  order_count: (json['order_count'] as num).toDouble(),
  amount: (json['amount'] as num).toDouble(),
  order_success: json['order_success'] as bool,
  qr_code: json['qr_code'] as String,
  table_open_datetime: DateTime.parse(json['table_open_datetime'] as String),
  man_count: (json['man_count'] as num).toInt(),
  woman_count: (json['woman_count'] as num).toInt(),
  child_count: (json['child_count'] as num).toInt(),
  table_al_la_crate_mode: json['table_al_la_crate_mode'] as bool,
  buffet_code: json['buffet_code'] as String,
  customer_code_or_telephone: json['customer_code_or_telephone'] as String,
  customer_name: json['customer_name'] as String,
  customer_address: json['customer_address'] as String,
  delivery_code: json['delivery_code'] as String,
  delivery_number: json['delivery_number'] as String,
  delivery_ticket_number: json['delivery_ticket_number'] as String,
  remark: json['remark'] as String,
  open_by_staff_code: json['open_by_staff_code'] as String,
  make_food_immediately: json['make_food_immediately'] as bool,
  is_delivery: json['is_delivery'] as bool,
  delivery_cook_success: json['delivery_cook_success'] as bool,
  delivery_cook_success_datetime: DateTime.parse(
    json['delivery_cook_success_datetime'] as String,
  ),
  delivery_send_success: json['delivery_send_success'] as bool,
  delivery_send_success_datetime: DateTime.parse(
    json['delivery_send_success_datetime'] as String,
  ),
  delivery_status: (json['delivery_status'] as num).toInt(),
  table_child_count: (json['table_child_count'] as num).toInt(),
  detail_discount_formula: json['detail_discount_formula'] as String,
);

Map<String, dynamic> _$TableProcessClickHouseServerStructToJson(
  TableProcessClickHouseServerStruct instance,
) => <String, dynamic>{
  'guidfixed': instance.guidfixed,
  'number': instance.number,
  'number_main': instance.number_main,
  'names': instance.names.map((e) => e.toJson()).toList(),
  'zone': instance.zone,
  'table_status': instance.table_status,
  'order_count': instance.order_count,
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
};

OrderTempClickHouseServerStruct _$OrderTempClickHouseServerStructFromJson(
  Map<String, dynamic> json,
) => OrderTempClickHouseServerStruct(
  id: (json['id'] as num).toInt(),
  orderId: json['orderId'] as String,
  orderIdMain: json['orderIdMain'] as String,
  orderGuid: json['orderGuid'] as String,
  machineId: json['machineId'] as String,
  orderDateTime: DateTime.parse(json['orderDateTime'] as String),
  barcode: json['barcode'] as String,
  qty: (json['qty'] as num).toDouble(),
  price: (json['price'] as num).toDouble(),
  amount: (json['amount'] as num).toDouble(),
  isOrder: json['isOrder'] as bool,
  isPaySuccess: json['isPaySuccess'] as bool,
  optionSelected: (json['optionSelected'] as List<dynamic>)
      .map(
        (e) => OrderProductOptionClickHouseServerModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  remark: json['remark'] as String,
  names: (json['names'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  takeAway: json['takeAway'] as bool,
  unitCode: json['unitCode'] as String,
  unitName: (json['unitName'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  imageUri: json['imageUri'] as String,
  kdsSuccessTime: DateTime.parse(json['kdsSuccessTime'] as String),
  kdsSuccess: json['kdsSuccess'] as bool,
  isOrderSuccess: json['isOrderSuccess'] as bool,
  isOrderSendKdsSuccess: json['isOrderSendKdsSuccess'] as bool,
  kdsId: json['kdsId'] as String,
  cancelQty: (json['cancelQty'] as num).toDouble(),
  orderQty: (json['orderQty'] as num).toDouble(),
  deliveryNumber: json['deliveryNumber'] as String,
  deliveryCode: json['deliveryCode'] as String,
  isOrderReadySendKds: json['isOrderReadySendKds'] as bool,
  deliveryName: json['deliveryName'] as String,
  lastUpdateDateTime: DateTime.parse(json['lastUpdateDateTime'] as String),
  servedTime: DateTime.parse(json['servedTime'] as String),
  servedSuccess: json['servedSuccess'] as bool,
  servedQty: (json['servedQty'] as num).toDouble(),
  orderType: (json['orderType'] as num).toInt(),
  orderEmployeeCode: json['orderEmployeeCode'] as String,
  orderEmployeeDetail: json['orderEmployeeDetail'] as String,
);

Map<String, dynamic> _$OrderTempClickHouseServerStructToJson(
  OrderTempClickHouseServerStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'orderGuid': instance.orderGuid,
  'orderIdMain': instance.orderIdMain,
  'machineId': instance.machineId,
  'orderDateTime': instance.orderDateTime.toIso8601String(),
  'barcode': instance.barcode,
  'orderQty': instance.orderQty,
  'qty': instance.qty,
  'cancelQty': instance.cancelQty,
  'price': instance.price,
  'amount': instance.amount,
  'isOrder': instance.isOrder,
  'isOrderSuccess': instance.isOrderSuccess,
  'isOrderSendKdsSuccess': instance.isOrderSendKdsSuccess,
  'isOrderReadySendKds': instance.isOrderReadySendKds,
  'isPaySuccess': instance.isPaySuccess,
  'optionSelected': instance.optionSelected.map((e) => e.toJson()).toList(),
  'remark': instance.remark,
  'names': instance.names.map((e) => e.toJson()).toList(),
  'unitCode': instance.unitCode,
  'unitName': instance.unitName.map((e) => e.toJson()).toList(),
  'imageUri': instance.imageUri,
  'takeAway': instance.takeAway,
  'kdsSuccessTime': instance.kdsSuccessTime.toIso8601String(),
  'kdsSuccess': instance.kdsSuccess,
  'kdsId': instance.kdsId,
  'servedTime': instance.servedTime.toIso8601String(),
  'servedSuccess': instance.servedSuccess,
  'servedQty': instance.servedQty,
  'deliveryNumber': instance.deliveryNumber,
  'deliveryCode': instance.deliveryCode,
  'deliveryName': instance.deliveryName,
  'lastUpdateDateTime': instance.lastUpdateDateTime.toIso8601String(),
  'orderType': instance.orderType,
  'orderEmployeeCode': instance.orderEmployeeCode,
  'orderEmployeeDetail': instance.orderEmployeeDetail,
};

OrderProductOptionClickHouseServerModel
_$OrderProductOptionClickHouseServerModelFromJson(Map<String, dynamic> json) =>
    OrderProductOptionClickHouseServerModel(
      guid: json['guid'] as String,
      choicetype: (json['choicetype'] as num).toInt(),
      maxselect: (json['maxselect'] as num).toInt(),
      minselect: (json['minselect'] as num).toInt(),
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      choices: (json['choices'] as List<dynamic>)
          .map(
            (e) => OrderProductOptionChoiceClickHouseServerModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );

Map<String, dynamic> _$OrderProductOptionClickHouseServerModelToJson(
  OrderProductOptionClickHouseServerModel instance,
) => <String, dynamic>{
  'guid': instance.guid,
  'choicetype': instance.choicetype,
  'maxselect': instance.maxselect,
  'minselect': instance.minselect,
  'names': instance.names.map((e) => e.toJson()).toList(),
  'choices': instance.choices.map((e) => e.toJson()).toList(),
};

OrderProductOptionChoiceClickHouseServerModel
_$OrderProductOptionChoiceClickHouseServerModelFromJson(
  Map<String, dynamic> json,
) => OrderProductOptionChoiceClickHouseServerModel(
  guid: json['guid'] as String,
  names: (json['names'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  price: json['price'] as String,
  qty: (json['qty'] as num).toDouble(),
  selected: json['selected'] as bool,
  priceValue: (json['priceValue'] as num).toDouble(),
);

Map<String, dynamic> _$OrderProductOptionChoiceClickHouseServerModelToJson(
  OrderProductOptionChoiceClickHouseServerModel instance,
) => <String, dynamic>{
  'guid': instance.guid,
  'names': instance.names.map((e) => e.toJson()).toList(),
  'price': instance.price,
  'qty': instance.qty,
  'selected': instance.selected,
  'priceValue': instance.priceValue,
};

PosProcessClickHouseServerModel _$PosProcessClickHouseServerModelFromJson(
  Map<String, dynamic> json,
) => PosProcessClickHouseServerModel(
  total_piece: (json['total_piece'] as num).toDouble(),
  detail_total_amount_before_discount:
      (json['detail_total_amount_before_discount'] as num).toDouble(),
  total_piece_except_vat: (json['total_piece_except_vat'] as num).toDouble(),
  total_piece_vat: (json['total_piece_vat'] as num).toDouble(),
  total_amount: (json['total_amount'] as num).toDouble(),
  total_discount_from_promotion: (json['total_discount_from_promotion'] as num)
      .toDouble(),
  qr_code: json['qr_code'] as String,
  vat_type: (json['vat_type'] as num).toInt(),
  vat_rate: (json['vat_rate'] as num).toDouble(),
  is_vat_register: json['is_vat_register'] as bool,
  total_vat_amount: (json['total_vat_amount'] as num).toDouble(),
  total_item_vat_amount: (json['total_item_vat_amount'] as num).toDouble(),
  total_item_except_vat_amount: (json['total_item_except_vat_amount'] as num)
      .toDouble(),
  amount_except_vat: (json['amount_except_vat'] as num).toDouble(),
  details: (json['details'] as List<dynamic>)
      .map(
        (e) => PosProcessDetailClickHouseServerModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  detail_discount_formula: json['detail_discount_formula'] as String,
  detail_total_discount: (json['detail_total_discount'] as num).toDouble(),
  total_discount_vat_amount: (json['total_discount_vat_amount'] as num)
      .toDouble(),
  total_discount_except_vat_amount:
      (json['total_discount_except_vat_amount'] as num).toDouble(),
  amount_after_calc_vat: (json['amount_after_calc_vat'] as num).toDouble(),
  amount_before_calc_vat: (json['amount_before_calc_vat'] as num).toDouble(),
  cash_round_amount: (json['cash_round_amount'] as num).toDouble(),
  total_amount_pay: (json['total_amount_pay'] as num).toDouble(),
  total_drink_amount: (json['total_drink_amount'] as num).toDouble(),
  total_alcohol_amount: (json['total_alcohol_amount'] as num).toDouble(),
  total_other_amount: (json['total_other_amount'] as num).toDouble(),
  total_food_amount: (json['total_food_amount'] as num).toDouble(),
  total_cheque_amount: (json['total_cheque_amount'] as num).toDouble(),
  total_transfer_amount: (json['total_transfer_amount'] as num).toDouble(),
  total_coupon_amount: (json['total_coupon_amount'] as num).toDouble(),
  total_credit_amount: (json['total_credit_amount'] as num).toDouble(),
  total_credit_card_amount: (json['total_credit_card_amount'] as num)
      .toDouble(),
  total_qr_code_amount: (json['total_qr_code_amount'] as num).toDouble(),
);

Map<String, dynamic> _$PosProcessClickHouseServerModelToJson(
  PosProcessClickHouseServerModel instance,
) => <String, dynamic>{
  'total_piece': instance.total_piece,
  'total_piece_vat': instance.total_piece_vat,
  'total_piece_except_vat': instance.total_piece_except_vat,
  'total_vat_amount': instance.total_vat_amount,
  'detail_total_amount_before_discount':
      instance.detail_total_amount_before_discount,
  'total_amount': instance.total_amount,
  'total_discount_from_promotion': instance.total_discount_from_promotion,
  'qr_code': instance.qr_code,
  'is_vat_register': instance.is_vat_register,
  'vat_type': instance.vat_type,
  'vat_rate': instance.vat_rate,
  'total_item_vat_amount': instance.total_item_vat_amount,
  'total_item_except_vat_amount': instance.total_item_except_vat_amount,
  'details': instance.details.map((e) => e.toJson()).toList(),
  'detail_discount_formula': instance.detail_discount_formula,
  'detail_total_discount': instance.detail_total_discount,
  'total_discount_vat_amount': instance.total_discount_vat_amount,
  'total_discount_except_vat_amount': instance.total_discount_except_vat_amount,
  'amount_before_calc_vat': instance.amount_before_calc_vat,
  'amount_after_calc_vat': instance.amount_after_calc_vat,
  'amount_except_vat': instance.amount_except_vat,
  'cash_round_amount': instance.cash_round_amount,
  'total_amount_pay': instance.total_amount_pay,
  'total_food_amount': instance.total_food_amount,
  'total_drink_amount': instance.total_drink_amount,
  'total_alcohol_amount': instance.total_alcohol_amount,
  'total_other_amount': instance.total_other_amount,
  'total_credit_card_amount': instance.total_credit_card_amount,
  'total_qr_code_amount': instance.total_qr_code_amount,
  'total_cheque_amount': instance.total_cheque_amount,
  'total_transfer_amount': instance.total_transfer_amount,
  'total_coupon_amount': instance.total_coupon_amount,
  'total_credit_amount': instance.total_credit_amount,
};

PosProcessDetailClickHouseServerModel
_$PosProcessDetailClickHouseServerModelFromJson(
  Map<String, dynamic> json,
) => PosProcessDetailClickHouseServerModel(
  guid: json['guid'] as String,
  index: (json['index'] as num).toInt(),
  barcode: json['barcode'] as String,
  item_code: json['item_code'] as String,
  item_name: (json['item_name'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  unit_code: json['unit_code'] as String,
  unit_name: (json['unit_name'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  qty: (json['qty'] as num).toDouble(),
  price: (json['price'] as num).toDouble(),
  price_original: (json['price_original'] as num).toDouble(),
  discount_text: json['discount_text'] as String,
  discount: (json['discount'] as num).toDouble(),
  total_amount: (json['total_amount'] as num).toDouble(),
  total_amount_with_extra: (json['total_amount_with_extra'] as num).toDouble(),
  is_void: json['is_void'] as bool,
  remark: json['remark'] as String,
  image_url: json['image_url'] as String,
  price_exclude_vat_type: json['price_exclude_vat_type'] as bool,
  is_except_vat: json['is_except_vat'] as bool,
  extra: (json['extra'] as List<dynamic>)
      .map(
        (e) => PosProcessDetailExtraClickHouseModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  vat_type: (json['vat_type'] as num).toInt(),
  price_exclude_vat: (json['price_exclude_vat'] as num).toDouble(),
  food_type: (json['food_type'] as num).toInt(),
);

Map<String, dynamic> _$PosProcessDetailClickHouseServerModelToJson(
  PosProcessDetailClickHouseServerModel instance,
) => <String, dynamic>{
  'guid': instance.guid,
  'index': instance.index,
  'barcode': instance.barcode,
  'item_code': instance.item_code,
  'item_name': instance.item_name,
  'unit_code': instance.unit_code,
  'unit_name': instance.unit_name,
  'qty': instance.qty,
  'price': instance.price,
  'price_original': instance.price_original,
  'discount_text': instance.discount_text,
  'discount': instance.discount,
  'total_amount': instance.total_amount,
  'total_amount_with_extra': instance.total_amount_with_extra,
  'is_void': instance.is_void,
  'remark': instance.remark,
  'image_url': instance.image_url,
  'price_exclude_vat_type': instance.price_exclude_vat_type,
  'is_except_vat': instance.is_except_vat,
  'vat_type': instance.vat_type,
  'price_exclude_vat': instance.price_exclude_vat,
  'food_type': instance.food_type,
  'extra': instance.extra,
};

PosProcessDetailExtraClickHouseModel
_$PosProcessDetailExtraClickHouseModelFromJson(Map<String, dynamic> json) =>
    PosProcessDetailExtraClickHouseModel(
      guid_auto_fixed: json['guid_auto_fixed'] as String,
      guid_category: json['guid_category'] as String,
      guid_code_or_ref: json['guid_code_or_ref'] as String,
      index: (json['index'] as num).toInt(),
      barcode: json['barcode'] as String,
      item_code: json['item_code'] as String,
      item_name: (json['item_name'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      unit_code: json['unit_code'] as String,
      unit_name: (json['unit_name'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      qty: (json['qty'] as num).toDouble(),
      qty_fixed: (json['qty_fixed'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      total_amount: (json['total_amount'] as num).toDouble(),
      price_exclude_vat_type: json['price_exclude_vat_type'] as bool,
      is_except_vat: json['is_except_vat'] as bool,
      vat_type: (json['vat_type'] as num).toInt(),
      is_void: json['is_void'] as bool,
      price_exclude_vat: (json['price_exclude_vat'] as num).toDouble(),
      refbarcode: json['refbarcode'] as String?,
      refunitcode: json['refunitcode'] as String?,
    );

Map<String, dynamic> _$PosProcessDetailExtraClickHouseModelToJson(
  PosProcessDetailExtraClickHouseModel instance,
) => <String, dynamic>{
  'guid_auto_fixed': instance.guid_auto_fixed,
  'guid_code_or_ref': instance.guid_code_or_ref,
  'guid_category': instance.guid_category,
  'index': instance.index,
  'barcode': instance.barcode,
  'refbarcode': instance.refbarcode,
  'refunitcode': instance.refunitcode,
  'item_code': instance.item_code,
  'item_name': instance.item_name.map((e) => e.toJson()).toList(),
  'unit_code': instance.unit_code,
  'unit_name': instance.unit_name.map((e) => e.toJson()).toList(),
  'qty': instance.qty,
  'qty_fixed': instance.qty_fixed,
  'price': instance.price,
  'total_amount': instance.total_amount,
  'is_void': instance.is_void,
  'price_exclude_vat_type': instance.price_exclude_vat_type,
  'is_except_vat': instance.is_except_vat,
  'price_exclude_vat': instance.price_exclude_vat,
  'vat_type': instance.vat_type,
};
