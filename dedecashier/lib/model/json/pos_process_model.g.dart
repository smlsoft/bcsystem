// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_process_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PosProcessDetailModel _$PosProcessDetailModelFromJson(
  Map<String, dynamic> json,
) => PosProcessDetailModel(
  guid: json['guid'] as String,
  index: (json['index'] as num).toInt(),
  barcode: json['barcode'] as String,
  item_code: json['item_code'] as String,
  item_name: json['item_name'] as String,
  unit_code: json['unit_code'] as String,
  unit_name: json['unit_name'] as String,
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
        (e) => PosProcessDetailExtraModel.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  vat_type: (json['vat_type'] as num).toInt(),
  price_exclude_vat: (json['price_exclude_vat'] as num).toDouble(),
  food_type: (json['food_type'] as num).toInt(),
  pattern_code: json['pattern_code'] as String?,
  unit_dividend: (json['unit_dividend'] as num?)?.toDouble(),
  unit_divisor: (json['unit_divisor'] as num?)?.toDouble(),
  issumpoint: json['issumpoint'] as bool?,
);

Map<String, dynamic> _$PosProcessDetailModelToJson(
  PosProcessDetailModel instance,
) => <String, dynamic>{
  'guid': instance.guid,
  'index': instance.index,
  'barcode': instance.barcode,
  'item_code': instance.item_code,
  'item_name': instance.item_name,
  'unit_code': instance.unit_code,
  'unit_name': instance.unit_name,
  'unit_dividend': instance.unit_dividend,
  'unit_divisor': instance.unit_divisor,
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
  'issumpoint': instance.issumpoint,
  'pattern_code': instance.pattern_code,
  'price_exclude_vat_type': instance.price_exclude_vat_type,
  'is_except_vat': instance.is_except_vat,
  'vat_type': instance.vat_type,
  'price_exclude_vat': instance.price_exclude_vat,
  'food_type': instance.food_type,
  'extra': instance.extra,
};

PosProcessDetailExtraModel _$PosProcessDetailExtraModelFromJson(
  Map<String, dynamic> json,
) => PosProcessDetailExtraModel(
  guid_auto_fixed: json['guid_auto_fixed'] as String,
  guid_category: json['guid_category'] as String,
  guid_code_or_ref: json['guid_code_or_ref'] as String,
  index: (json['index'] as num).toInt(),
  barcode: json['barcode'] as String,
  item_code: json['item_code'] as String,
  item_name: json['item_name'] as String,
  unit_code: json['unit_code'] as String,
  unit_name: json['unit_name'] as String,
  unit_dividend: (json['unit_dividend'] as num?)?.toDouble(),
  unit_divisor: (json['unit_divisor'] as num?)?.toDouble(),
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

Map<String, dynamic> _$PosProcessDetailExtraModelToJson(
  PosProcessDetailExtraModel instance,
) => <String, dynamic>{
  'guid_auto_fixed': instance.guid_auto_fixed,
  'guid_code_or_ref': instance.guid_code_or_ref,
  'guid_category': instance.guid_category,
  'index': instance.index,
  'barcode': instance.barcode,
  'refbarcode': instance.refbarcode,
  'refunitcode': instance.refunitcode,
  'item_code': instance.item_code,
  'item_name': instance.item_name,
  'unit_code': instance.unit_code,
  'unit_name': instance.unit_name,
  'unit_dividend': instance.unit_dividend,
  'unit_divisor': instance.unit_divisor,
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

PosProcessPromotionModel _$PosProcessPromotionModelFromJson(
  Map<String, dynamic> json,
) => PosProcessPromotionModel(
  promotion_name: json['promotion_name'] as String,
  colorHex: json['colorHex'] as String,
  promotion_code: json['promotion_code'] as String,
  description: json['description'] as String,
  discount_word: json['discount_word'] as String,
  discount_amount: (json['discount_amount'] as num).toDouble(),
  count: (json['count'] as num).toInt(),
  isAchieved: json['isAchieved'] as bool? ?? false,
  tier_level: (json['tier_level'] as num?)?.toInt(),
);

Map<String, dynamic> _$PosProcessPromotionModelToJson(
  PosProcessPromotionModel instance,
) => <String, dynamic>{
  'colorHex': instance.colorHex,
  'promotion_code': instance.promotion_code,
  'promotion_name': instance.promotion_name,
  'description': instance.description,
  'discount_word': instance.discount_word,
  'discount_amount': instance.discount_amount,
  'count': instance.count,
  'isAchieved': instance.isAchieved,
  'tier_level': instance.tier_level,
};

PosProcessModel _$PosProcessModelFromJson(
  Map<String, dynamic> json,
) => PosProcessModel(
  total_piece: (json['total_piece'] as num?)?.toDouble() ?? 0.0,
  detail_total_amount_before_discount:
      (json['detail_total_amount_before_discount'] as num?)?.toDouble() ?? 0.0,
  total_piece_except_vat:
      (json['total_piece_except_vat'] as num?)?.toDouble() ?? 0,
  total_piece_vat: (json['total_piece_vat'] as num?)?.toDouble() ?? 0,
  total_amount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
  total_discount_from_promotion:
      (json['total_discount_from_promotion'] as num?)?.toDouble() ?? 0,
  total_discount_from_promotion_bottom:
      (json['total_discount_from_promotion_bottom'] as num?)?.toDouble() ?? 0,
  qr_code: json['qr_code'] as String? ?? "",
  vat_type: (json['vat_type'] as num?)?.toInt() ?? 0,
  vat_rate: (json['vat_rate'] as num?)?.toDouble() ?? 0,
  is_vat_register: json['is_vat_register'] as bool? ?? false,
  total_vat_amount: (json['total_vat_amount'] as num?)?.toDouble() ?? 0,
  total_item_vat_amount:
      (json['total_item_vat_amount'] as num?)?.toDouble() ?? 0,
  total_item_except_vat_amount:
      (json['total_item_except_vat_amount'] as num?)?.toDouble() ?? 0,
  amount_except_vat: (json['amount_except_vat'] as num?)?.toDouble() ?? 0,
  details:
      (json['details'] as List<dynamic>?)
          ?.map(
            (e) => PosProcessDetailModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  select_promotion_temp_list:
      (json['select_promotion_temp_list'] as List<dynamic>?)
          ?.map((e) => PromotionTempModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  detail_discount_formula: json['detail_discount_formula'] as String? ?? "",
  detail_total_discount:
      (json['detail_total_discount'] as num?)?.toDouble() ?? 0,
  total_discount_vat_amount:
      (json['total_discount_vat_amount'] as num?)?.toDouble() ?? 0,
  total_discount_except_vat_amount:
      (json['total_discount_except_vat_amount'] as num?)?.toDouble() ?? 0,
  amount_after_calc_vat:
      (json['amount_after_calc_vat'] as num?)?.toDouble() ?? 0,
  amount_before_calc_vat:
      (json['amount_before_calc_vat'] as num?)?.toDouble() ?? 0,
  cash_round_amount: (json['cash_round_amount'] as num?)?.toDouble() ?? 0,
  total_amount_pay: (json['total_amount_pay'] as num?)?.toDouble() ?? 0,
  total_drink_amount: (json['total_drink_amount'] as num?)?.toDouble() ?? 0,
  total_alcohol_amount: (json['total_alcohol_amount'] as num?)?.toDouble() ?? 0,
  total_other_amount: (json['total_other_amount'] as num?)?.toDouble() ?? 0,
  total_food_amount: (json['total_food_amount'] as num?)?.toDouble() ?? 0,
  total_cheque_amount: (json['total_cheque_amount'] as num?)?.toDouble() ?? 0,
  total_transfer_amount:
      (json['total_transfer_amount'] as num?)?.toDouble() ?? 0,
  total_coupon_amount: (json['total_coupon_amount'] as num?)?.toDouble() ?? 0,
  total_credit_amount: (json['total_credit_amount'] as num?)?.toDouble() ?? 0,
  total_credit_card_amount:
      (json['total_credit_card_amount'] as num?)?.toDouble() ?? 0,
  total_qr_code_amount: (json['total_qr_code_amount'] as num?)?.toDouble() ?? 0,
  getpoint: (json['getpoint'] as num?)?.toDouble() ?? 0.0,
  usepoint: (json['usepoint'] as num?)?.toDouble() ?? 0.0,
  pointdiscountamount: (json['pointdiscountamount'] as num?)?.toDouble() ?? 0.0,
  coupondiscount: (json['coupondiscount'] as num?)?.toDouble() ?? 0.0,
  promotion_warning_list:
      (json['promotion_warning_list'] as List<dynamic>?)
          ?.map(
            (e) => PosProcessPromotionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  promotion_bottom_list:
      (json['promotion_bottom_list'] as List<dynamic>?)
          ?.map(
            (e) => PosProcessPromotionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  promotion_bonus_list:
      (json['promotion_bonus_list'] as List<dynamic>?)
          ?.map(
            (e) => PosProcessPromotionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  promotion_coupon_list:
      (json['promotion_coupon_list'] as List<dynamic>?)
          ?.map(
            (e) => PosProcessPromotionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  promotion_product_list:
      (json['promotion_product_list'] as List<dynamic>?)
          ?.map(
            (e) => PosProcessPromotionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$PosProcessModelToJson(
  PosProcessModel instance,
) => <String, dynamic>{
  'total_piece': instance.total_piece,
  'total_piece_vat': instance.total_piece_vat,
  'total_piece_except_vat': instance.total_piece_except_vat,
  'total_vat_amount': instance.total_vat_amount,
  'detail_total_amount_before_discount':
      instance.detail_total_amount_before_discount,
  'total_amount': instance.total_amount,
  'total_discount_from_promotion': instance.total_discount_from_promotion,
  'total_discount_from_promotion_bottom':
      instance.total_discount_from_promotion_bottom,
  'qr_code': instance.qr_code,
  'is_vat_register': instance.is_vat_register,
  'vat_type': instance.vat_type,
  'vat_rate': instance.vat_rate,
  'total_item_vat_amount': instance.total_item_vat_amount,
  'total_item_except_vat_amount': instance.total_item_except_vat_amount,
  'details': instance.details,
  'select_promotion_temp_list': instance.select_promotion_temp_list,
  'promotion_product_list': instance.promotion_product_list,
  'promotion_bottom_list': instance.promotion_bottom_list,
  'promotion_bonus_list': instance.promotion_bonus_list,
  'promotion_coupon_list': instance.promotion_coupon_list,
  'promotion_warning_list': instance.promotion_warning_list,
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
  'getpoint': instance.getpoint,
  'usepoint': instance.usepoint,
  'pointdiscountamount': instance.pointdiscountamount,
  'coupondiscount': instance.coupondiscount,
};
