// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromotionMainModel _$PromotionMainModelFromJson(Map<String, dynamic> json) =>
    PromotionMainModel(
      promotion_list: (json['promotion_list'] as List<dynamic>)
          .map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PromotionMainModelToJson(PromotionMainModel instance) =>
    <String, dynamic>{'promotion_list': instance.promotion_list};

PromotionModel _$PromotionModelFromJson(Map<String, dynamic> json) =>
    PromotionModel(
      promotion_code: json['promotion_code'] as String,
      type: (json['type'] as num).toInt(),
      index: (json['index'] as num).toInt(),
      date_begin: DateTime.parse(json['date_begin'] as String),
      date_end: DateTime.parse(json['date_end'] as String),
      promotion_name: json['promotion_name'] as String,
      discount_text: json['discount_text'] as String,
      promotion_item_code_include_list:
          (json['promotion_item_code_include_list'] as List<dynamic>)
              .map(
                (e) => PromotionProductIncludeModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
      limit_qty: (json['limit_qty'] as num?)?.toDouble() ?? 0,
      promotion_qty: (json['promotion_qty'] as num?)?.toDouble() ?? 0,
      limit_amount: (json['limit_amount'] as num?)?.toDouble() ?? 0,
      customer_only: (json['customer_only'] as num?)?.toInt() ?? 0,
      promotion_house_brand_list:
          (json['promotion_house_brand_list'] as List<dynamic>?)
              ?.map(
                (e) => PromotionHouseBrandModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      tier_display_count: (json['tier_display_count'] as num?)?.toInt(),
      tier_priority: (json['tier_priority'] as num?)?.toInt(),
      tier_threshold: (json['tier_threshold'] as num?)?.toDouble(),
      tier_reward_message: json['tier_reward_message'] as String?,
    );

Map<String, dynamic> _$PromotionModelToJson(
  PromotionModel instance,
) => <String, dynamic>{
  'type': instance.type,
  'index': instance.index,
  'promotion_code': instance.promotion_code,
  'date_begin': instance.date_begin.toIso8601String(),
  'date_end': instance.date_end.toIso8601String(),
  'promotion_name': instance.promotion_name,
  'customer_only': instance.customer_only,
  'discount_text': instance.discount_text,
  'promotion_item_code_include_list': instance.promotion_item_code_include_list,
  'promotion_house_brand_list': instance.promotion_house_brand_list,
  'limit_qty': instance.limit_qty,
  'promotion_qty': instance.promotion_qty,
  'limit_amount': instance.limit_amount,
  'tier_display_count': instance.tier_display_count,
  'tier_priority': instance.tier_priority,
  'tier_threshold': instance.tier_threshold,
  'tier_reward_message': instance.tier_reward_message,
};

PromotionProductModel _$PromotionProductModelFromJson(
  Map<String, dynamic> json,
) => PromotionProductModel(
  item_code: json['item_code'] as String,
  name: json['name'] as String,
  qty: (json['qty'] as num).toDouble(),
  unit_code: json['unit_code'] as String,
  unit_name: json['unit_name'] as String,
  price: (json['price'] as num).toDouble(),
  discount_text: json['discount_text'] as String? ?? "",
  stand_value: (json['stand_value'] as num?)?.toDouble() ?? 1,
  dived_value: (json['dived_value'] as num?)?.toDouble() ?? 1,
);

Map<String, dynamic> _$PromotionProductModelToJson(
  PromotionProductModel instance,
) => <String, dynamic>{
  'item_code': instance.item_code,
  'name': instance.name,
  'unit_code': instance.unit_code,
  'unit_name': instance.unit_name,
  'qty': instance.qty,
  'price': instance.price,
  'discount_text': instance.discount_text,
  'stand_value': instance.stand_value,
  'dived_value': instance.dived_value,
};

PromotionHouseBrandModel _$PromotionHouseBrandModelFromJson(
  Map<String, dynamic> json,
) => PromotionHouseBrandModel(formatcode: json['formatcode'] as String);

Map<String, dynamic> _$PromotionHouseBrandModelToJson(
  PromotionHouseBrandModel instance,
) => <String, dynamic>{'formatcode': instance.formatcode};

PromotionProductIncludeModel _$PromotionProductIncludeModelFromJson(
  Map<String, dynamic> json,
) => PromotionProductIncludeModel(
  promotion_product: (json['promotion_product'] as List<dynamic>)
      .map((e) => PromotionProductModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  include_product: (json['include_product'] as List<dynamic>)
      .map((e) => PromotionProductModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PromotionProductIncludeModelToJson(
  PromotionProductIncludeModel instance,
) => <String, dynamic>{
  'promotion_product': instance.promotion_product,
  'include_product': instance.include_product,
};

PromotionDiscountModel _$PromotionDiscountModelFromJson(
  Map<String, dynamic> json,
) => PromotionDiscountModel(
  code_detail: json['code_detail'] as String,
  promotion_code: json['promotion_code'] as String,
  promotion_name: json['promotion_name'] as String,
  promotion_item_code: json['promotion_item_code'] as String,
  limit_qty: (json['limit_qty'] as num).toDouble(),
  promotion_discount: json['promotion_discount'] as String,
  include_extra: (json['include_extra'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PromotionDiscountModelToJson(
  PromotionDiscountModel instance,
) => <String, dynamic>{
  'code_detail': instance.code_detail,
  'promotion_code': instance.promotion_code,
  'promotion_name': instance.promotion_name,
  'promotion_item_code': instance.promotion_item_code,
  'limit_qty': instance.limit_qty,
  'promotion_discount': instance.promotion_discount,
  'include_extra': instance.include_extra,
};

PromotionTempModel _$PromotionTempModelFromJson(Map<String, dynamic> json) =>
    PromotionTempModel(
      promotion_code: json['promotion_code'] as String,
      date_begin: DateTime.parse(json['date_begin'] as String),
      date_end: DateTime.parse(json['date_end'] as String),
      name: json['name'] as String? ?? "",
      item_code_promotion: json['item_code_promotion'] as String,
      customer_only: (json['customer_only'] as num?)?.toInt() ?? 0,
      discount_text: json['discount_text'] as String,
      limit_qty: (json['limit_qty'] as num).toDouble(),
      promotion_name: json['promotion_name'] as String,
      include_extra: (json['include_extra'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PromotionTempModelToJson(PromotionTempModel instance) =>
    <String, dynamic>{
      'promotion_code': instance.promotion_code,
      'date_begin': instance.date_begin.toIso8601String(),
      'date_end': instance.date_end.toIso8601String(),
      'name': instance.name,
      'promotion_name': instance.promotion_name,
      'customer_only': instance.customer_only,
      'item_code_promotion': instance.item_code_promotion,
      'limit_qty': instance.limit_qty,
      'discount_text': instance.discount_text,
      'include_extra': instance.include_extra,
    };
