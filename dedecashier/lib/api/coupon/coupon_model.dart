class CouponModel {
  final String couponcode;
  final List<CouponName> names;
  final double couponvalue;
  final double remainingvalue;
  final DateTime issueddate;
  final DateTime expirydate;
  final int coupontype; // 0 = Value Discount, 1 = Percent Discount
  final String customercode;
  final String remark;
  final int status; // 0 = Active, 1 = Canceled
  final bool isonetimeuse;

  const CouponModel({
    required this.couponcode,
    required this.names,
    required this.couponvalue,
    required this.remainingvalue,
    required this.issueddate,
    required this.expirydate,
    required this.coupontype,
    required this.customercode,
    required this.remark,
    required this.status,
    required this.isonetimeuse,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      couponcode: json['couponcode'] ?? '',
      names: (json['names'] as List<dynamic>?)?.map((e) => CouponName.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      couponvalue: (json['couponvalue'] as num?)?.toDouble() ?? 0.0,
      remainingvalue: (json['remainingvalue'] as num?)?.toDouble() ?? 0.0,
      issueddate: DateTime.tryParse(json['issueddate'] ?? '') ?? DateTime.now(),
      expirydate: DateTime.tryParse(json['expirydate'] ?? '') ?? DateTime.now(),
      coupontype: json['coupontype'] ?? 0,
      customercode: json['customercode'] ?? '',
      remark: json['remark'] ?? '',
      status: json['status'] ?? 0,
      isonetimeuse: json['isonetimeuse'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'couponcode': couponcode,
      'names': names.map((e) => e.toJson()).toList(),
      'couponvalue': couponvalue,
      'remainingvalue': remainingvalue,
      'issueddate': issueddate.toIso8601String(),
      'expirydate': expirydate.toIso8601String(),
      'coupontype': coupontype,
      'customercode': customercode,
      'remark': remark,
      'status': status,
      'isonetimeuse': isonetimeuse,
    };
  }
}

class CouponName {
  final String code;
  final String name;
  final bool isauto;
  final bool isdelete;

  const CouponName({
    required this.code,
    required this.name,
    required this.isauto,
    required this.isdelete,
  });

  factory CouponName.fromJson(Map<String, dynamic> json) {
    return CouponName(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      isauto: json['isauto'] ?? false,
      isdelete: json['isdelete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'isauto': isauto,
      'isdelete': isdelete,
    };
  }
}

class CouponAvailabilityResponse {
  final bool available;
  final double remaining_value;
  final int status;
  final bool is_expired;
  final String message;

  const CouponAvailabilityResponse({
    required this.available,
    required this.remaining_value,
    required this.status,
    required this.is_expired,
    required this.message,
  });

  factory CouponAvailabilityResponse.fromJson(Map<String, dynamic> json) {
    return CouponAvailabilityResponse(
      available: json['available'] ?? false,
      remaining_value: (json['remaining_value'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 0,
      is_expired: json['is_expired'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'available': available,
      'remaining_value': remaining_value,
      'status': status,
      'is_expired': is_expired,
      'message': message,
    };
  }
}

class CouponReservationResponse {
  final String reservation_id;
  final String coupon_id;
  final String coupon_code; // เพิ่ม field นี้
  final double reserved_amount;
  final DateTime expires_at;
  final bool reserved;
  final String message;

  const CouponReservationResponse({
    required this.reservation_id,
    required this.coupon_id,
    required this.coupon_code,
    required this.reserved_amount,
    required this.expires_at,
    required this.reserved,
    required this.message,
  });
  factory CouponReservationResponse.fromJson(Map<String, dynamic> json) {
    return CouponReservationResponse(
      reservation_id: json['reservation_id'] ?? '',
      coupon_id: json['coupon_id'] ?? '',
      coupon_code: json['coupon_code'] ?? '',
      reserved_amount: (json['reserved_amount'] as num?)?.toDouble() ?? 0.0,
      expires_at: DateTime.tryParse(json['expires_at'] ?? '') ?? DateTime.now(),
      reserved: json['reserved'] ?? false,
      message: json['message'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'reservation_id': reservation_id,
      'coupon_id': coupon_id,
      'coupon_code': coupon_code,
      'reserved_amount': reserved_amount,
      'expires_at': expires_at.toIso8601String(),
      'reserved': reserved,
      'message': message,
    };
  }
}

class CouponUseResponse {
  final bool used;
  final double discount_amount;
  final String transaction_id;
  final double remaining_value;
  final String message;

  const CouponUseResponse({
    required this.used,
    required this.discount_amount,
    required this.transaction_id,
    required this.remaining_value,
    required this.message,
  });

  factory CouponUseResponse.fromJson(Map<String, dynamic> json) {
    return CouponUseResponse(
      used: json['used'] ?? false,
      discount_amount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      transaction_id: json['transaction_id'] ?? '',
      remaining_value: (json['remaining_value'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'used': used,
      'discount_amount': discount_amount,
      'transaction_id': transaction_id,
      'remaining_value': remaining_value,
      'message': message,
    };
  }
}

// Request models
class CouponReserveRequest {
  final String code;
  final String type;
  final String posid;
  final String empcode;
  final String docno;
  final double netamt;
  final String? customer_id;
  final String? transaction_id;
  final double? reserved_amount;

  const CouponReserveRequest({
    required this.code,
    required this.type,
    required this.posid,
    required this.empcode,
    required this.docno,
    required this.netamt,
    this.customer_id,
    this.transaction_id,
    this.reserved_amount,
  });

  factory CouponReserveRequest.fromJson(Map<String, dynamic> json) {
    return CouponReserveRequest(
      code: json['code'] ?? '',
      type: json['type'] ?? '',
      posid: json['posid'] ?? '',
      empcode: json['empcode'] ?? '',
      docno: json['docno'] ?? '',
      netamt: (json['netamt'] as num?)?.toDouble() ?? 0.0,
      customer_id: json['customer_id'],
      transaction_id: json['transaction_id'],
      reserved_amount: (json['reserved_amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'code': code,
      'type': type,
      'posid': posid,
      'empcode': empcode,
      'docno': docno,
      'netamt': netamt,
    };

    if (customer_id != null) data['customer_id'] = customer_id;
    if (transaction_id != null) data['transaction_id'] = transaction_id;
    if (reserved_amount != null) data['reserved_amount'] = reserved_amount;

    return data;
  }
}

class CouponUseRequest {
  final String code;
  final String type;
  final String posid;
  final String empcode;
  final String docno;
  final double netamt;
  final String? customer_id;
  final String? reservation_id;
  final String? transaction_id;
  final double? use_amount;

  const CouponUseRequest({
    required this.code,
    required this.type,
    required this.posid,
    required this.empcode,
    required this.docno,
    required this.netamt,
    this.customer_id,
    this.reservation_id,
    this.transaction_id,
    this.use_amount,
  });

  factory CouponUseRequest.fromJson(Map<String, dynamic> json) {
    return CouponUseRequest(
      code: json['code'] ?? '',
      type: json['type'] ?? '',
      posid: json['posid'] ?? '',
      empcode: json['empcode'] ?? '',
      docno: json['docno'] ?? '',
      netamt: (json['netamt'] as num?)?.toDouble() ?? 0.0,
      customer_id: json['customer_id'],
      reservation_id: json['reservation_id'],
      transaction_id: json['transaction_id'],
      use_amount: (json['use_amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'code': code,
      'type': type,
      'posid': posid,
      'empcode': empcode,
      'docno': docno,
      'netamt': netamt,
    };

    if (customer_id != null) data['customer_id'] = customer_id;
    if (reservation_id != null) data['reservation_id'] = reservation_id;
    if (transaction_id != null) data['transaction_id'] = transaction_id;
    if (use_amount != null) data['use_amount'] = use_amount;

    return data;
  }
}

class CouponCancelRequest {
  final String code;
  final String type;
  final String posid;

  const CouponCancelRequest({
    required this.code,
    required this.type,
    required this.posid,
  });

  factory CouponCancelRequest.fromJson(Map<String, dynamic> json) {
    return CouponCancelRequest(
      code: json['code'] ?? '',
      type: json['type'] ?? '',
      posid: json['posid'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'type': type,
      'posid': posid,
    };
  }
}

// Coupon Calculation Models
class CouponCalculationRequest {
  final double order_amount;
  final List<CouponForCalculation> coupons;
  final String? customer_id;

  const CouponCalculationRequest({
    required this.order_amount,
    required this.coupons,
    this.customer_id,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_amount': order_amount,
      'coupons': coupons.map((e) => e.toJson()).toList(),
      if (customer_id != null) 'customer_id': customer_id,
    };
  }
}

class CouponForCalculation {
  final String coupon_code;
  final double? use_amount;

  const CouponForCalculation({
    required this.coupon_code,
    this.use_amount,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'coupon_code': coupon_code,
    };
    if (use_amount != null) data['use_amount'] = use_amount;
    return data;
  }
}

class CouponCalculationResult {
  final bool success;
  final double total_discount;
  final double total_cash_voucher;
  final double final_amount;
  final List<CouponCalculationItem> coupon_results;

  const CouponCalculationResult({
    required this.success,
    required this.total_discount,
    required this.total_cash_voucher,
    required this.final_amount,
    required this.coupon_results,
  });

  factory CouponCalculationResult.fromJson(Map<String, dynamic> json) {
    return CouponCalculationResult(
      success: json['success'] ?? false,
      total_discount: (json['total_discount'] as num?)?.toDouble() ?? 0.0,
      total_cash_voucher: (json['total_cash_voucher'] as num?)?.toDouble() ?? 0.0,
      final_amount: (json['final_amount'] as num?)?.toDouble() ?? 0.0,
      coupon_results: (json['coupon_results'] as List<dynamic>?)?.map((e) => CouponCalculationItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

class CouponCalculationItem {
  final String coupon_code;
  final int coupon_type;
  final String coupon_type_name;
  final double discount_amount;
  final double cash_voucher_amount;
  final bool applied;

  const CouponCalculationItem({
    required this.coupon_code,
    required this.coupon_type,
    required this.coupon_type_name,
    required this.discount_amount,
    required this.cash_voucher_amount,
    required this.applied,
  });

  factory CouponCalculationItem.fromJson(Map<String, dynamic> json) {
    return CouponCalculationItem(
      coupon_code: json['coupon_code'] ?? '',
      coupon_type: json['coupon_type'] ?? 0,
      coupon_type_name: json['coupon_type_name'] ?? '',
      discount_amount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      cash_voucher_amount: (json['cash_voucher_amount'] as num?)?.toDouble() ?? 0.0,
      applied: json['applied'] ?? false,
    );
  }
}
