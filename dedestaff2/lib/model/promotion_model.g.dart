// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromotionModel _$PromotionModelFromJson(Map<String, dynamic> json) =>
    PromotionModel(
      promotion_code: json['promotion_code'] as String,
      date_begin: DateTime.parse(json['date_begin'] as String),
      date_end: DateTime.parse(json['date_end'] as String),
      promotion_name_1: json['promotion_name_1'] as String,
      promotion_name_2: json['promotion_name_2'] as String? ?? '',
      promotion_name_3: json['promotion_name_3'] as String? ?? '',
      promotion_name_4: json['promotion_name_4'] as String? ?? '',
      promotion_name_5: json['promotion_name_5'] as String? ?? '',
      customer_only: (json['customer_only'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PromotionModelToJson(PromotionModel instance) =>
    <String, dynamic>{
      'promotion_code': instance.promotion_code,
      'date_begin': instance.date_begin.toIso8601String(),
      'date_end': instance.date_end.toIso8601String(),
      'promotion_name_1': instance.promotion_name_1,
      'promotion_name_2': instance.promotion_name_2,
      'promotion_name_3': instance.promotion_name_3,
      'promotion_name_4': instance.promotion_name_4,
      'promotion_name_5': instance.promotion_name_5,
      'customer_only': instance.customer_only,
    };

PromotionDiscountModel _$PromotionDiscountModelFromJson(
        Map<String, dynamic> json) =>
    PromotionDiscountModel(
      code_detail: json['code_detail'] as String,
      promotion_code: json['promotion_code'] as String,
      promotion_barcode: json['promotion_barcode'] as String,
      limit_qty: (json['limit_qty'] as num).toDouble(),
      promotion_discount: json['promotion_discount'] as String,
      include_extra: (json['include_extra'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PromotionDiscountModelToJson(
        PromotionDiscountModel instance) =>
    <String, dynamic>{
      'code_detail': instance.code_detail,
      'promotion_code': instance.promotion_code,
      'promotion_barcode': instance.promotion_barcode,
      'limit_qty': instance.limit_qty,
      'promotion_discount': instance.promotion_discount,
      'include_extra': instance.include_extra,
    };

PromotionTempModel _$PromotionTempModelFromJson(Map<String, dynamic> json) =>
    PromotionTempModel(
      promotion_code: json['promotion_code'] as String,
      date_begin: DateTime.parse(json['date_begin'] as String),
      date_end: DateTime.parse(json['date_end'] as String),
      name_1: json['name_1'] as String? ?? "",
      name_2: json['name_2'] as String? ?? "",
      name_3: json['name_3'] as String? ?? "",
      name_4: json['name_4'] as String? ?? "",
      name_5: json['name_5'] as String? ?? "",
      barcode_promotion: json['barcode_promotion'] as String,
      customer_only: (json['customer_only'] as num?)?.toInt() ?? 0,
      discount_text: json['discount_text'] as String,
      limit_qty: (json['limit_qty'] as num).toDouble(),
      promotion_name_1: json['promotion_name_1'] as String,
      promotion_name_2: json['promotion_name_2'] as String? ?? "",
      promotion_name_3: json['promotion_name_3'] as String? ?? "",
      promotion_name_4: json['promotion_name_4'] as String? ?? "",
      promotion_name_5: json['promotion_name_5'] as String? ?? "",
      include_extra: (json['include_extra'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PromotionTempModelToJson(PromotionTempModel instance) =>
    <String, dynamic>{
      'promotion_code': instance.promotion_code,
      'date_begin': instance.date_begin.toIso8601String(),
      'date_end': instance.date_end.toIso8601String(),
      'name_1': instance.name_1,
      'name_2': instance.name_2,
      'name_3': instance.name_3,
      'name_4': instance.name_4,
      'name_5': instance.name_5,
      'promotion_name_1': instance.promotion_name_1,
      'promotion_name_2': instance.promotion_name_2,
      'promotion_name_3': instance.promotion_name_3,
      'promotion_name_4': instance.promotion_name_4,
      'promotion_name_5': instance.promotion_name_5,
      'customer_only': instance.customer_only,
      'barcode_promotion': instance.barcode_promotion,
      'limit_qty': instance.limit_qty,
      'discount_text': instance.discount_text,
      'include_extra': instance.include_extra,
    };
