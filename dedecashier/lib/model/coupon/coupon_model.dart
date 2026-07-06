import 'package:json_annotation/json_annotation.dart';

part 'coupon_model.g.dart';

@JsonSerializable()
class CouponModel {
  final String guidfixed;
  final String couponcode;
  final List<CouponName> names;
  final double couponvalue;
  final DateTime issueddate;
  final DateTime expirydate;
  final int coupontype; // 0 = Value Discount, 1 = Percent Discount, 2 = Cash Voucher
  @JsonKey(defaultValue: <String>[])
  final List<String>? customercodes;
  @JsonKey(defaultValue: '')
  final String remark;
  final int status; // 0 = Active, 1 = Canceled
  final bool isonetimeuse;
  final int maxusagecount;
  final int maxusagecountpercustomer;
  final List<String>? ignore_branch_code;
  final ProductCondition? product_condition;

  const CouponModel({
    String? guidfixed,
    String? couponcode,
    List<CouponName>? names,
    double? couponvalue,
    required this.issueddate,
    required this.expirydate,
    int? coupontype,
    List<String>? customercodes,
    String? remark,
    int? status,
    bool? isonetimeuse,
    int? maxusagecount,
    int? maxusagecountpercustomer,
    List<String>? ignore_branch_code,
    ProductCondition? product_condition,
  }) : guidfixed = guidfixed ?? '',
       couponcode = couponcode ?? '',
       names = names ?? const [],
       couponvalue = couponvalue ?? 0.0,
       coupontype = coupontype ?? 0,
       customercodes = customercodes ?? const [],
       remark = remark ?? '',
       status = status ?? 1,
       isonetimeuse = isonetimeuse ?? false,
       maxusagecount = maxusagecount ?? 0,
       maxusagecountpercustomer = maxusagecountpercustomer ?? 0,
       ignore_branch_code = ignore_branch_code,
       product_condition = product_condition;

  factory CouponModel.fromJson(Map<String, dynamic> json) => _$CouponModelFromJson(json);
  Map<String, dynamic> toJson() => _$CouponModelToJson(this);
}

@JsonSerializable()
class CouponName {
  final String code;
  final String name;
  final bool isauto;
  final bool isdelete;

  const CouponName({required this.code, required this.name, required this.isauto, required this.isdelete});

  factory CouponName.fromJson(Map<String, dynamic> json) => _$CouponNameFromJson(json);
  Map<String, dynamic> toJson() => _$CouponNameToJson(this);
}

@JsonSerializable()
class ProductCondition {
  final List<String>? product_codes;
  final List<String>? group_codes;
  final List<String>? group_subone_codes;
  final List<String>? group_subtwo_codes;
  final List<String>? brand_codes;
  final List<String>? design_codes;
  final List<String>? model_codes;
  final List<String>? pattern_codes;
  final List<String>? grade_codes;
  final List<String>? category_codes;
  final List<String>? class_codes;
  final double? minimum_amount;

  const ProductCondition({this.product_codes, this.group_codes, this.group_subone_codes, this.group_subtwo_codes, this.brand_codes, this.design_codes, this.model_codes, this.pattern_codes, this.grade_codes, this.category_codes, this.class_codes, this.minimum_amount});

  factory ProductCondition.fromJson(Map<String, dynamic> json) => _$ProductConditionFromJson(json);
  Map<String, dynamic> toJson() => _$ProductConditionToJson(this);
}

// New models for availability check with items
@JsonSerializable()
class CouponAvailabilityCheckRequest {
  final String branch_code;
  final String customer_id;
  final List<CouponAvailabilityItem> items;

  const CouponAvailabilityCheckRequest({required this.branch_code, required this.customer_id, required this.items});

  factory CouponAvailabilityCheckRequest.fromJson(Map<String, dynamic> json) => _$CouponAvailabilityCheckRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CouponAvailabilityCheckRequestToJson(this);
}

@JsonSerializable()
class CouponAvailabilityItem {
  final String barcode;
  final double price;
  final double qty;
  final double sumamount;

  const CouponAvailabilityItem({required this.barcode, required this.price, required this.qty, required this.sumamount});

  factory CouponAvailabilityItem.fromJson(Map<String, dynamic> json) => _$CouponAvailabilityItemFromJson(json);
  Map<String, dynamic> toJson() => _$CouponAvailabilityItemToJson(this);
}

@JsonSerializable()
class CouponAvailabilityNewResponse {
  final bool available;
  @JsonKey(defaultValue: 0)
  final int usage_count;
  @JsonKey(defaultValue: 0)
  final int max_usage_count;
  @JsonKey(defaultValue: 0)
  final int remaining_usage;
  final int status;
  final bool is_expired;
  final bool branch_allowed;
  final double total_amount;
  final double eligible_amount;
  final double total_discount;
  final int eligible_item_count;
  final List<CouponAvailabilityItemResult> item_results;
  final String message;

  const CouponAvailabilityNewResponse({
    required this.available,
    this.usage_count = 0,
    this.max_usage_count = 0,
    this.remaining_usage = 0,
    required this.status,
    required this.is_expired,
    required this.branch_allowed,
    required this.total_amount,
    required this.eligible_amount,
    required this.total_discount,
    required this.eligible_item_count,
    required this.item_results,
    String? message,
  }) : message = message ?? '';

  factory CouponAvailabilityNewResponse.fromJson(Map<String, dynamic> json) => _$CouponAvailabilityNewResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CouponAvailabilityNewResponseToJson(this);
}

@JsonSerializable()
class CouponAvailabilityItemResult {
  final String barcode;
  final double qty;
  final double price;
  final double sumamount;
  final bool is_eligible;
  final double discount_amount;
  final String matched_category;

  const CouponAvailabilityItemResult({required this.barcode, required this.qty, required this.price, required this.sumamount, required this.is_eligible, required this.discount_amount, String? matched_category}) : matched_category = matched_category ?? '';

  factory CouponAvailabilityItemResult.fromJson(Map<String, dynamic> json) => _$CouponAvailabilityItemResultFromJson(json);
  Map<String, dynamic> toJson() => _$CouponAvailabilityItemResultToJson(this);
}

@JsonSerializable()
class CouponAvailabilityResponse {
  final bool available;
  @JsonKey(defaultValue: 0)
  final int usage_count;
  @JsonKey(defaultValue: 0)
  final int max_usage_count;
  @JsonKey(defaultValue: 0)
  final int remaining_usage;
  final int status;
  final bool is_expired;
  final String? message;
  // Keep remaining_value for backward compatibility
  @JsonKey(defaultValue: 0.0)
  final double remaining_value;

  const CouponAvailabilityResponse({required this.available, required this.usage_count, required this.max_usage_count, required this.remaining_usage, required this.status, required this.is_expired, this.message, required this.remaining_value});

  factory CouponAvailabilityResponse.fromJson(Map<String, dynamic> json) => _$CouponAvailabilityResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CouponAvailabilityResponseToJson(this);
}

@JsonSerializable()
class CouponReservationResponse {
  @JsonKey(defaultValue: '')
  final String reservation_id;
  @JsonKey(defaultValue: '')
  final String coupon_id;
  @JsonKey(defaultValue: '')
  final String coupon_code;
  @JsonKey(defaultValue: '')
  final String transaction_id;
  @JsonKey(defaultValue: 0.0)
  final double reserved_amount;
  final DateTime? expires_at;
  @JsonKey(defaultValue: false)
  final bool reserved;
  @JsonKey(defaultValue: '')
  final String message;

  const CouponReservationResponse({this.reservation_id = '', this.coupon_id = '', this.coupon_code = '', this.transaction_id = '', this.reserved_amount = 0.0, this.expires_at, this.reserved = false, this.message = ''});

  factory CouponReservationResponse.fromJson(Map<String, dynamic> json) => _$CouponReservationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CouponReservationResponseToJson(this);
}

@JsonSerializable()
class CouponUseResponse {
  final bool used;
  final double discount_amount;
  final String transaction_id;
  final double remaining_value;
  final String message;

  const CouponUseResponse({required this.used, required this.discount_amount, required this.transaction_id, required this.remaining_value, required this.message});

  factory CouponUseResponse.fromJson(Map<String, dynamic> json) => _$CouponUseResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CouponUseResponseToJson(this);
}

// Request models
@JsonSerializable()
class CouponReserveRequest {
  final String customer_id;
  final String transaction_id;
  final double reserved_amount;

  const CouponReserveRequest({required this.customer_id, required this.transaction_id, required this.reserved_amount});

  factory CouponReserveRequest.fromJson(Map<String, dynamic> json) => _$CouponReserveRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CouponReserveRequestToJson(this);
}

@JsonSerializable()
class CouponUseRequest {
  final String customer_code;
  final String customer_id;
  final String customer_name;
  final double order_amount;
  final String remark;
  final String reservation_id;
  final String sale_invoice_id;
  final String sale_invoice_number;
  final String transaction_id;
  final double use_amount;

  const CouponUseRequest({
    required this.customer_code,
    required this.customer_id,
    required this.customer_name,
    required this.order_amount,
    required this.remark,
    required this.reservation_id,
    required this.sale_invoice_id,
    required this.sale_invoice_number,
    required this.transaction_id,
    required this.use_amount,
  });

  factory CouponUseRequest.fromJson(Map<String, dynamic> json) => _$CouponUseRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CouponUseRequestToJson(this);
}

@JsonSerializable()
class CouponCancelReservationRequest {
  final String customer_id;
  final String reservation_id;

  const CouponCancelReservationRequest({required this.customer_id, required this.reservation_id});

  factory CouponCancelReservationRequest.fromJson(Map<String, dynamic> json) => _$CouponCancelReservationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CouponCancelReservationRequestToJson(this);
}

// New models for multiple coupon calculation
@JsonSerializable()
class CouponCalculationRequest {
  final double order_amount;
  final List<CouponCalculationItem> coupons;
  final String customer_id;

  const CouponCalculationRequest({required this.order_amount, required this.coupons, required this.customer_id});

  factory CouponCalculationRequest.fromJson(Map<String, dynamic> json) => _$CouponCalculationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CouponCalculationRequestToJson(this);
}

@JsonSerializable()
class CouponCalculationItem {
  final String coupon_code;
  final double? use_amount; // Optional for Type 0 and Type 2

  const CouponCalculationItem({required this.coupon_code, this.use_amount});

  factory CouponCalculationItem.fromJson(Map<String, dynamic> json) => _$CouponCalculationItemFromJson(json);
  Map<String, dynamic> toJson() => _$CouponCalculationItemToJson(this);
}

@JsonSerializable()
class CouponCalculationError {
  final String code;
  final String coupon_code;
  final String error;

  const CouponCalculationError({required this.code, required this.coupon_code, required this.error});

  factory CouponCalculationError.fromJson(Map<String, dynamic> json) => _$CouponCalculationErrorFromJson(json);
  Map<String, dynamic> toJson() => _$CouponCalculationErrorToJson(this);
}

@JsonSerializable()
class CouponCalculationResponse {
  final bool success;
  final double total_discount;
  final double total_cash_voucher;
  final double final_amount;
  final List<CouponCalculationResult> coupon_results;
  @JsonKey(defaultValue: <CouponCalculationError>[])
  final List<CouponCalculationError> errors;

  const CouponCalculationResponse({required this.success, required this.total_discount, required this.total_cash_voucher, required this.final_amount, required this.coupon_results, this.errors = const []});

  factory CouponCalculationResponse.fromJson(Map<String, dynamic> json) => _$CouponCalculationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CouponCalculationResponseToJson(this);
}

@JsonSerializable()
class CouponItemResult {
  final String barcode;
  final double qty;
  final double price;
  final double sumamount;
  final bool is_eligible;
  final double discount_amount;
  final String? matched_category;

  const CouponItemResult({required this.barcode, required this.qty, required this.price, required this.sumamount, required this.is_eligible, required this.discount_amount, this.matched_category});

  factory CouponItemResult.fromJson(Map<String, dynamic> json) => _$CouponItemResultFromJson(json);
  Map<String, dynamic> toJson() => _$CouponItemResultToJson(this);
}

@JsonSerializable()
class CouponCalculationResult {
  final String coupon_code;
  final int coupon_type;
  final String coupon_type_name;
  final double discount_amount;
  final double cash_voucher_amount;
  @JsonKey(defaultValue: 0.0)
  final double used_amount;
  @JsonKey(defaultValue: 0)
  final int remaining_usage;
  @JsonKey(defaultValue: 0)
  final int usage_count;
  final bool applied;
  @JsonKey(defaultValue: true)
  final bool branch_allowed;
  @JsonKey(defaultValue: 0.0)
  final double eligible_amount;
  @JsonKey(defaultValue: 0)
  final int eligible_item_count;
  @JsonKey(defaultValue: 0.0)
  final double minimum_amount;
  @JsonKey(defaultValue: <CouponItemResult>[])
  final List<CouponItemResult> item_results;
  @JsonKey(defaultValue: '')
  final String message;
  // Backward compatibility fields
  @JsonKey(defaultValue: 0.0)
  final double remaining_value;
  @JsonKey(defaultValue: '')
  final String description;
  @JsonKey(defaultValue: '')
  final String error_message;

  const CouponCalculationResult({
    required this.coupon_code,
    required this.coupon_type,
    required this.coupon_type_name,
    required this.discount_amount,
    required this.cash_voucher_amount,
    this.used_amount = 0.0,
    this.remaining_usage = 0,
    this.usage_count = 0,
    required this.applied,
    this.branch_allowed = true,
    this.eligible_amount = 0.0,
    this.eligible_item_count = 0,
    this.minimum_amount = 0.0,
    this.item_results = const [],
    this.message = '',
    // Backward compatibility fields with default values
    this.remaining_value = 0.0,
    this.description = '',
    this.error_message = '',
  });

  factory CouponCalculationResult.fromJson(Map<String, dynamic> json) => _$CouponCalculationResultFromJson(json);
  Map<String, dynamic> toJson() => _$CouponCalculationResultToJson(this);

  // Computed properties for backward compatibility
  double get totalAmount => discount_amount + cash_voucher_amount;
  String get displayMessage => message.isNotEmpty ? message : (error_message.isNotEmpty ? error_message : description);
}

// Extended CouponModel with helper methods
extension CouponModelExtensions on CouponModel {
  String get displayName => names.isNotEmpty ? names.first.name : couponcode;

  bool get isActive => status == 0;
  bool get isExpired => DateTime.now().isAfter(expirydate);
  bool get isAvailable => isActive && !isExpired;

  String get couponTypeName {
    switch (coupontype) {
      case 0:
        return 'ลดตามมูลค่า';
      case 1:
        return 'ลดตามเปอร์เซ็นต์';
      case 2:
        return 'คูปองแทนเงินสด';
      default:
        return 'ไม่ทราบประเภท';
    }
  }

  String get discountText {
    switch (coupontype) {
      case 0:
        return '฿${couponvalue.toStringAsFixed(0)}';
      case 1:
        return '${couponvalue.toStringAsFixed(0)}%';
      case 2:
        return 'เงินสด ฿${couponvalue.toStringAsFixed(0)}';
      default:
        return '';
    }
  }

  // Check if coupon is available for specific customer
  bool isAvailableForCustomer(String customerCode) {
    if (!isAvailable) return false;
    if (customercodes == null || customercodes!.isEmpty) return true; // No customer restriction
    return customercodes!.contains(customerCode);
  }

  // Check if coupon has usage limit
  bool get hasUsageLimit => maxusagecount > 0;

  // Check if coupon has per-customer usage limit
  bool get hasPerCustomerLimit => maxusagecountpercustomer > 0;
}

// Applied coupon model for UI state management
@JsonSerializable()
class AppliedCouponModel {
  final CouponModel coupon;
  final double useAmount;
  final CouponReservationResponse? reservation;
  final CouponCalculationResult? calculationResult;
  final DateTime addedAt;
  @JsonKey(defaultValue: '')
  final String message;
  @JsonKey(defaultValue: '')
  final String customerId;
  @JsonKey(defaultValue: 0)
  final int remaining_usage;

  const AppliedCouponModel({required this.coupon, required this.useAmount, this.reservation, this.calculationResult, required this.addedAt, this.message = '', this.customerId = '', this.remaining_usage = 0});

  factory AppliedCouponModel.fromJson(Map<String, dynamic> json) => _$AppliedCouponModelFromJson(json);
  Map<String, dynamic> toJson() => _$AppliedCouponModelToJson(this);
  bool get isReserved => reservation != null && reservation!.reserved;
  bool get isExpired => reservation?.expires_at != null && DateTime.now().isAfter(reservation!.expires_at!);

  /// Get transaction ID from reservation (if exists)
  String? get transactionId => reservation?.transaction_id;

  /// Get reservation ID from reservation (if exists)
  String? get reservationId => reservation?.reservation_id;

  String get statusText {
    if (reservation == null) return 'ยังไม่จอง';
    if (isExpired) return 'หมดเวลาจอง';
    if (isReserved) return 'จองแล้ว';
    return 'ยกเลิกการจอง';
  }
}
