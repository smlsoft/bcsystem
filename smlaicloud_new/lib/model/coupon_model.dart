import 'package:json_annotation/json_annotation.dart';
import 'package:smlaicloud/model/global_model.dart';

part 'coupon_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CouponModel {
  String? guidfixed;
  String? couponcode;
  List<LanguageDataModel>? names;
  double? couponvalue;
  String? issueddate;
  String? expirydate;
  int? coupontype; // 0 = ลดตามมูลค่า, 1 = ลดตามเปอร์เซ็นต์, 2 = คูปองแทนเงินสด
  List<String>? customercodes;
  String? remark;
  int? status; // 0 = ใช้งาน, 1 = ยกเลิก
  bool? isonetimeuse;
  int? maxusagecount;
  int? maxusagecountpercustomer;

  CouponModel({
    this.guidfixed,
    this.couponcode,
    this.names,
    this.couponvalue,
    this.issueddate,
    this.expirydate,
    this.coupontype,
    this.customercodes,
    this.remark,
    this.status,
    this.isonetimeuse,
    this.maxusagecount,
    this.maxusagecountpercustomer,
  }) {
    names ??= <LanguageDataModel>[];
    customercodes ??= <String>[];
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) =>
      _$CouponModelFromJson(json);

  Map<String, dynamic> toJson() => _$CouponModelToJson(this);

  CouponModel copyWith({
    String? guidfixed,
    String? couponcode,
    List<LanguageDataModel>? names,
    double? couponvalue,
    String? issueddate,
    String? expirydate,
    int? coupontype,
    List<String>? customercodes,
    String? remark,
    int? status,
    bool? isonetimeuse,
    int? maxusagecount,
    int? maxusagecountpercustomer,
  }) {
    return CouponModel(
      guidfixed: guidfixed ?? this.guidfixed,
      couponcode: couponcode ?? this.couponcode,
      names: names ?? this.names,
      couponvalue: couponvalue ?? this.couponvalue,
      issueddate: issueddate ?? this.issueddate,
      expirydate: expirydate ?? this.expirydate,
      coupontype: coupontype ?? this.coupontype,
      customercodes: customercodes ?? this.customercodes,
      remark: remark ?? this.remark,
      status: status ?? this.status,
      isonetimeuse: isonetimeuse ?? this.isonetimeuse,
      maxusagecount: maxusagecount ?? this.maxusagecount,
      maxusagecountpercustomer: maxusagecountpercustomer ?? this.maxusagecountpercustomer,
    );
  }

  // Helper methods สำหรับแสดงข้อมูล
  String getCouponTypeText() {
    switch (coupontype) {
      case 0:
        return 'ลดตามมูลค่า';
      case 1:
        return 'ลดตามเปอร์เซ็นต์';
      case 2:
        return 'คูปองแทนเงินสด';
      default:
        return 'ไม่ระบุ';
    }
  }

  String getStatusText() {
    switch (status) {
      case 0:
        return 'ใช้งาน';
      case 1:
        return 'ยกเลิก';
      default:
        return 'ไม่ระบุ';
    }
  }

  String getCouponValueText() {
    if (couponvalue == null) return '';
    
    switch (coupontype) {
      case 0:
      case 2:
        return '${couponvalue!.toStringAsFixed(0)} บาท';
      case 1:
        return '${couponvalue!.toStringAsFixed(0)}%';
      default:
        return couponvalue!.toString();
    }
  }
}

@JsonSerializable(explicitToJson: true)
class CouponResponseModel {
  bool? success;
  List<CouponModel>? data;

  CouponResponseModel({
    this.success,
    this.data,
  });

  factory CouponResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CouponResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CouponResponseModelToJson(this);
}
