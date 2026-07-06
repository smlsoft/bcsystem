// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CouponModel _$CouponModelFromJson(Map<String, dynamic> json) => CouponModel(
  guidfixed: json['guidfixed'] as String?,
  couponcode: json['couponcode'] as String?,
  names: (json['names'] as List<dynamic>?)
      ?.map((e) => CouponName.fromJson(e as Map<String, dynamic>))
      .toList(),
  couponvalue: (json['couponvalue'] as num?)?.toDouble(),
  issueddate: DateTime.parse(json['issueddate'] as String),
  expirydate: DateTime.parse(json['expirydate'] as String),
  coupontype: (json['coupontype'] as num?)?.toInt(),
  customercodes:
      (json['customercodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  remark: json['remark'] as String? ?? '',
  status: (json['status'] as num?)?.toInt(),
  isonetimeuse: json['isonetimeuse'] as bool?,
  maxusagecount: (json['maxusagecount'] as num?)?.toInt(),
  maxusagecountpercustomer: (json['maxusagecountpercustomer'] as num?)?.toInt(),
  ignore_branch_code: (json['ignore_branch_code'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  product_condition: json['product_condition'] == null
      ? null
      : ProductCondition.fromJson(
          json['product_condition'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$CouponModelToJson(CouponModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'couponcode': instance.couponcode,
      'names': instance.names,
      'couponvalue': instance.couponvalue,
      'issueddate': instance.issueddate.toIso8601String(),
      'expirydate': instance.expirydate.toIso8601String(),
      'coupontype': instance.coupontype,
      'customercodes': instance.customercodes,
      'remark': instance.remark,
      'status': instance.status,
      'isonetimeuse': instance.isonetimeuse,
      'maxusagecount': instance.maxusagecount,
      'maxusagecountpercustomer': instance.maxusagecountpercustomer,
      'ignore_branch_code': instance.ignore_branch_code,
      'product_condition': instance.product_condition,
    };

CouponName _$CouponNameFromJson(Map<String, dynamic> json) => CouponName(
  code: json['code'] as String,
  name: json['name'] as String,
  isauto: json['isauto'] as bool,
  isdelete: json['isdelete'] as bool,
);

Map<String, dynamic> _$CouponNameToJson(CouponName instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'isauto': instance.isauto,
      'isdelete': instance.isdelete,
    };

ProductCondition _$ProductConditionFromJson(Map<String, dynamic> json) =>
    ProductCondition(
      product_codes: (json['product_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      group_codes: (json['group_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      group_subone_codes: (json['group_subone_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      group_subtwo_codes: (json['group_subtwo_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      brand_codes: (json['brand_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      design_codes: (json['design_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      model_codes: (json['model_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      pattern_codes: (json['pattern_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      grade_codes: (json['grade_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      category_codes: (json['category_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      class_codes: (json['class_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      minimum_amount: (json['minimum_amount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ProductConditionToJson(ProductCondition instance) =>
    <String, dynamic>{
      'product_codes': instance.product_codes,
      'group_codes': instance.group_codes,
      'group_subone_codes': instance.group_subone_codes,
      'group_subtwo_codes': instance.group_subtwo_codes,
      'brand_codes': instance.brand_codes,
      'design_codes': instance.design_codes,
      'model_codes': instance.model_codes,
      'pattern_codes': instance.pattern_codes,
      'grade_codes': instance.grade_codes,
      'category_codes': instance.category_codes,
      'class_codes': instance.class_codes,
      'minimum_amount': instance.minimum_amount,
    };

CouponAvailabilityCheckRequest _$CouponAvailabilityCheckRequestFromJson(
  Map<String, dynamic> json,
) => CouponAvailabilityCheckRequest(
  branch_code: json['branch_code'] as String,
  customer_id: json['customer_id'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => CouponAvailabilityItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CouponAvailabilityCheckRequestToJson(
  CouponAvailabilityCheckRequest instance,
) => <String, dynamic>{
  'branch_code': instance.branch_code,
  'customer_id': instance.customer_id,
  'items': instance.items,
};

CouponAvailabilityItem _$CouponAvailabilityItemFromJson(
  Map<String, dynamic> json,
) => CouponAvailabilityItem(
  barcode: json['barcode'] as String,
  price: (json['price'] as num).toDouble(),
  qty: (json['qty'] as num).toDouble(),
  sumamount: (json['sumamount'] as num).toDouble(),
);

Map<String, dynamic> _$CouponAvailabilityItemToJson(
  CouponAvailabilityItem instance,
) => <String, dynamic>{
  'barcode': instance.barcode,
  'price': instance.price,
  'qty': instance.qty,
  'sumamount': instance.sumamount,
};

CouponAvailabilityNewResponse _$CouponAvailabilityNewResponseFromJson(
  Map<String, dynamic> json,
) => CouponAvailabilityNewResponse(
  available: json['available'] as bool,
  usage_count: (json['usage_count'] as num?)?.toInt() ?? 0,
  max_usage_count: (json['max_usage_count'] as num?)?.toInt() ?? 0,
  remaining_usage: (json['remaining_usage'] as num?)?.toInt() ?? 0,
  status: (json['status'] as num).toInt(),
  is_expired: json['is_expired'] as bool,
  branch_allowed: json['branch_allowed'] as bool,
  total_amount: (json['total_amount'] as num).toDouble(),
  eligible_amount: (json['eligible_amount'] as num).toDouble(),
  total_discount: (json['total_discount'] as num).toDouble(),
  eligible_item_count: (json['eligible_item_count'] as num).toInt(),
  item_results: (json['item_results'] as List<dynamic>)
      .map(
        (e) => CouponAvailabilityItemResult.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  message: json['message'] as String?,
);

Map<String, dynamic> _$CouponAvailabilityNewResponseToJson(
  CouponAvailabilityNewResponse instance,
) => <String, dynamic>{
  'available': instance.available,
  'usage_count': instance.usage_count,
  'max_usage_count': instance.max_usage_count,
  'remaining_usage': instance.remaining_usage,
  'status': instance.status,
  'is_expired': instance.is_expired,
  'branch_allowed': instance.branch_allowed,
  'total_amount': instance.total_amount,
  'eligible_amount': instance.eligible_amount,
  'total_discount': instance.total_discount,
  'eligible_item_count': instance.eligible_item_count,
  'item_results': instance.item_results,
  'message': instance.message,
};

CouponAvailabilityItemResult _$CouponAvailabilityItemResultFromJson(
  Map<String, dynamic> json,
) => CouponAvailabilityItemResult(
  barcode: json['barcode'] as String,
  qty: (json['qty'] as num).toDouble(),
  price: (json['price'] as num).toDouble(),
  sumamount: (json['sumamount'] as num).toDouble(),
  is_eligible: json['is_eligible'] as bool,
  discount_amount: (json['discount_amount'] as num).toDouble(),
  matched_category: json['matched_category'] as String?,
);

Map<String, dynamic> _$CouponAvailabilityItemResultToJson(
  CouponAvailabilityItemResult instance,
) => <String, dynamic>{
  'barcode': instance.barcode,
  'qty': instance.qty,
  'price': instance.price,
  'sumamount': instance.sumamount,
  'is_eligible': instance.is_eligible,
  'discount_amount': instance.discount_amount,
  'matched_category': instance.matched_category,
};

CouponAvailabilityResponse _$CouponAvailabilityResponseFromJson(
  Map<String, dynamic> json,
) => CouponAvailabilityResponse(
  available: json['available'] as bool,
  usage_count: (json['usage_count'] as num?)?.toInt() ?? 0,
  max_usage_count: (json['max_usage_count'] as num?)?.toInt() ?? 0,
  remaining_usage: (json['remaining_usage'] as num?)?.toInt() ?? 0,
  status: (json['status'] as num).toInt(),
  is_expired: json['is_expired'] as bool,
  message: json['message'] as String?,
  remaining_value: (json['remaining_value'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$CouponAvailabilityResponseToJson(
  CouponAvailabilityResponse instance,
) => <String, dynamic>{
  'available': instance.available,
  'usage_count': instance.usage_count,
  'max_usage_count': instance.max_usage_count,
  'remaining_usage': instance.remaining_usage,
  'status': instance.status,
  'is_expired': instance.is_expired,
  'message': instance.message,
  'remaining_value': instance.remaining_value,
};

CouponReservationResponse _$CouponReservationResponseFromJson(
  Map<String, dynamic> json,
) => CouponReservationResponse(
  reservation_id: json['reservation_id'] as String? ?? '',
  coupon_id: json['coupon_id'] as String? ?? '',
  coupon_code: json['coupon_code'] as String? ?? '',
  transaction_id: json['transaction_id'] as String? ?? '',
  reserved_amount: (json['reserved_amount'] as num?)?.toDouble() ?? 0.0,
  expires_at: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  reserved: json['reserved'] as bool? ?? false,
  message: json['message'] as String? ?? '',
);

Map<String, dynamic> _$CouponReservationResponseToJson(
  CouponReservationResponse instance,
) => <String, dynamic>{
  'reservation_id': instance.reservation_id,
  'coupon_id': instance.coupon_id,
  'coupon_code': instance.coupon_code,
  'transaction_id': instance.transaction_id,
  'reserved_amount': instance.reserved_amount,
  'expires_at': instance.expires_at?.toIso8601String(),
  'reserved': instance.reserved,
  'message': instance.message,
};

CouponUseResponse _$CouponUseResponseFromJson(Map<String, dynamic> json) =>
    CouponUseResponse(
      used: json['used'] as bool,
      discount_amount: (json['discount_amount'] as num).toDouble(),
      transaction_id: json['transaction_id'] as String,
      remaining_value: (json['remaining_value'] as num).toDouble(),
      message: json['message'] as String,
    );

Map<String, dynamic> _$CouponUseResponseToJson(CouponUseResponse instance) =>
    <String, dynamic>{
      'used': instance.used,
      'discount_amount': instance.discount_amount,
      'transaction_id': instance.transaction_id,
      'remaining_value': instance.remaining_value,
      'message': instance.message,
    };

CouponReserveRequest _$CouponReserveRequestFromJson(
  Map<String, dynamic> json,
) => CouponReserveRequest(
  customer_id: json['customer_id'] as String,
  transaction_id: json['transaction_id'] as String,
  reserved_amount: (json['reserved_amount'] as num).toDouble(),
);

Map<String, dynamic> _$CouponReserveRequestToJson(
  CouponReserveRequest instance,
) => <String, dynamic>{
  'customer_id': instance.customer_id,
  'transaction_id': instance.transaction_id,
  'reserved_amount': instance.reserved_amount,
};

CouponUseRequest _$CouponUseRequestFromJson(Map<String, dynamic> json) =>
    CouponUseRequest(
      customer_code: json['customer_code'] as String,
      customer_id: json['customer_id'] as String,
      customer_name: json['customer_name'] as String,
      order_amount: (json['order_amount'] as num).toDouble(),
      remark: json['remark'] as String,
      reservation_id: json['reservation_id'] as String,
      sale_invoice_id: json['sale_invoice_id'] as String,
      sale_invoice_number: json['sale_invoice_number'] as String,
      transaction_id: json['transaction_id'] as String,
      use_amount: (json['use_amount'] as num).toDouble(),
    );

Map<String, dynamic> _$CouponUseRequestToJson(CouponUseRequest instance) =>
    <String, dynamic>{
      'customer_code': instance.customer_code,
      'customer_id': instance.customer_id,
      'customer_name': instance.customer_name,
      'order_amount': instance.order_amount,
      'remark': instance.remark,
      'reservation_id': instance.reservation_id,
      'sale_invoice_id': instance.sale_invoice_id,
      'sale_invoice_number': instance.sale_invoice_number,
      'transaction_id': instance.transaction_id,
      'use_amount': instance.use_amount,
    };

CouponCancelReservationRequest _$CouponCancelReservationRequestFromJson(
  Map<String, dynamic> json,
) => CouponCancelReservationRequest(
  customer_id: json['customer_id'] as String,
  reservation_id: json['reservation_id'] as String,
);

Map<String, dynamic> _$CouponCancelReservationRequestToJson(
  CouponCancelReservationRequest instance,
) => <String, dynamic>{
  'customer_id': instance.customer_id,
  'reservation_id': instance.reservation_id,
};

CouponCalculationRequest _$CouponCalculationRequestFromJson(
  Map<String, dynamic> json,
) => CouponCalculationRequest(
  order_amount: (json['order_amount'] as num).toDouble(),
  coupons: (json['coupons'] as List<dynamic>)
      .map((e) => CouponCalculationItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  customer_id: json['customer_id'] as String,
);

Map<String, dynamic> _$CouponCalculationRequestToJson(
  CouponCalculationRequest instance,
) => <String, dynamic>{
  'order_amount': instance.order_amount,
  'coupons': instance.coupons,
  'customer_id': instance.customer_id,
};

CouponCalculationItem _$CouponCalculationItemFromJson(
  Map<String, dynamic> json,
) => CouponCalculationItem(
  coupon_code: json['coupon_code'] as String,
  use_amount: (json['use_amount'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CouponCalculationItemToJson(
  CouponCalculationItem instance,
) => <String, dynamic>{
  'coupon_code': instance.coupon_code,
  'use_amount': instance.use_amount,
};

CouponCalculationError _$CouponCalculationErrorFromJson(
  Map<String, dynamic> json,
) => CouponCalculationError(
  code: json['code'] as String,
  coupon_code: json['coupon_code'] as String,
  error: json['error'] as String,
);

Map<String, dynamic> _$CouponCalculationErrorToJson(
  CouponCalculationError instance,
) => <String, dynamic>{
  'code': instance.code,
  'coupon_code': instance.coupon_code,
  'error': instance.error,
};

CouponCalculationResponse _$CouponCalculationResponseFromJson(
  Map<String, dynamic> json,
) => CouponCalculationResponse(
  success: json['success'] as bool,
  total_discount: (json['total_discount'] as num).toDouble(),
  total_cash_voucher: (json['total_cash_voucher'] as num).toDouble(),
  final_amount: (json['final_amount'] as num).toDouble(),
  coupon_results: (json['coupon_results'] as List<dynamic>)
      .map((e) => CouponCalculationResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  errors:
      (json['errors'] as List<dynamic>?)
          ?.map(
            (e) => CouponCalculationError.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
);

Map<String, dynamic> _$CouponCalculationResponseToJson(
  CouponCalculationResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'total_discount': instance.total_discount,
  'total_cash_voucher': instance.total_cash_voucher,
  'final_amount': instance.final_amount,
  'coupon_results': instance.coupon_results,
  'errors': instance.errors,
};

CouponItemResult _$CouponItemResultFromJson(Map<String, dynamic> json) =>
    CouponItemResult(
      barcode: json['barcode'] as String,
      qty: (json['qty'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      sumamount: (json['sumamount'] as num).toDouble(),
      is_eligible: json['is_eligible'] as bool,
      discount_amount: (json['discount_amount'] as num).toDouble(),
      matched_category: json['matched_category'] as String?,
    );

Map<String, dynamic> _$CouponItemResultToJson(CouponItemResult instance) =>
    <String, dynamic>{
      'barcode': instance.barcode,
      'qty': instance.qty,
      'price': instance.price,
      'sumamount': instance.sumamount,
      'is_eligible': instance.is_eligible,
      'discount_amount': instance.discount_amount,
      'matched_category': instance.matched_category,
    };

CouponCalculationResult _$CouponCalculationResultFromJson(
  Map<String, dynamic> json,
) => CouponCalculationResult(
  coupon_code: json['coupon_code'] as String,
  coupon_type: (json['coupon_type'] as num).toInt(),
  coupon_type_name: json['coupon_type_name'] as String,
  discount_amount: (json['discount_amount'] as num).toDouble(),
  cash_voucher_amount: (json['cash_voucher_amount'] as num).toDouble(),
  used_amount: (json['used_amount'] as num?)?.toDouble() ?? 0.0,
  remaining_usage: (json['remaining_usage'] as num?)?.toInt() ?? 0,
  usage_count: (json['usage_count'] as num?)?.toInt() ?? 0,
  applied: json['applied'] as bool,
  branch_allowed: json['branch_allowed'] as bool? ?? true,
  eligible_amount: (json['eligible_amount'] as num?)?.toDouble() ?? 0.0,
  eligible_item_count: (json['eligible_item_count'] as num?)?.toInt() ?? 0,
  minimum_amount: (json['minimum_amount'] as num?)?.toDouble() ?? 0.0,
  item_results:
      (json['item_results'] as List<dynamic>?)
          ?.map((e) => CouponItemResult.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  message: json['message'] as String? ?? '',
  remaining_value: (json['remaining_value'] as num?)?.toDouble() ?? 0.0,
  description: json['description'] as String? ?? '',
  error_message: json['error_message'] as String? ?? '',
);

Map<String, dynamic> _$CouponCalculationResultToJson(
  CouponCalculationResult instance,
) => <String, dynamic>{
  'coupon_code': instance.coupon_code,
  'coupon_type': instance.coupon_type,
  'coupon_type_name': instance.coupon_type_name,
  'discount_amount': instance.discount_amount,
  'cash_voucher_amount': instance.cash_voucher_amount,
  'used_amount': instance.used_amount,
  'remaining_usage': instance.remaining_usage,
  'usage_count': instance.usage_count,
  'applied': instance.applied,
  'branch_allowed': instance.branch_allowed,
  'eligible_amount': instance.eligible_amount,
  'eligible_item_count': instance.eligible_item_count,
  'minimum_amount': instance.minimum_amount,
  'item_results': instance.item_results,
  'message': instance.message,
  'remaining_value': instance.remaining_value,
  'description': instance.description,
  'error_message': instance.error_message,
};

AppliedCouponModel _$AppliedCouponModelFromJson(Map<String, dynamic> json) =>
    AppliedCouponModel(
      coupon: CouponModel.fromJson(json['coupon'] as Map<String, dynamic>),
      useAmount: (json['useAmount'] as num).toDouble(),
      reservation: json['reservation'] == null
          ? null
          : CouponReservationResponse.fromJson(
              json['reservation'] as Map<String, dynamic>,
            ),
      calculationResult: json['calculationResult'] == null
          ? null
          : CouponCalculationResult.fromJson(
              json['calculationResult'] as Map<String, dynamic>,
            ),
      addedAt: DateTime.parse(json['addedAt'] as String),
      message: json['message'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      remaining_usage: (json['remaining_usage'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AppliedCouponModelToJson(AppliedCouponModel instance) =>
    <String, dynamic>{
      'coupon': instance.coupon,
      'useAmount': instance.useAmount,
      'reservation': instance.reservation,
      'calculationResult': instance.calculationResult,
      'addedAt': instance.addedAt.toIso8601String(),
      'message': instance.message,
      'customerId': instance.customerId,
      'remaining_usage': instance.remaining_usage,
    };
