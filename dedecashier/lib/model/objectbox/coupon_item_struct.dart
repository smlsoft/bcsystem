import 'package:objectbox/objectbox.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coupon_item_struct.g.dart';

@JsonSerializable()
@Entity()
class CouponItemObjectBoxStruct {
  int id = 0;

  /// จำนวนเงินคูปอง
  double couponamount;

  /// รายละเอียดคูปอง
  String coupondescription;

  /// หมายเลขคูปอง
  @Index(type: IndexType.hash)
  String couponno;

  /// ประเภทคูปอง
  @Index()
  String coupontype;

  /// ID การจอง
  String reservationid;

  /// ID ธุรกรรม
  @Index()
  String transactionid;

  /// ID คูปอง
  @Index(type: IndexType.hash)
  String couponid;

  CouponItemObjectBoxStruct({
    this.couponamount = 0,
    this.coupondescription = '',
    this.couponno = '',
    this.coupontype = '',
    this.reservationid = '',
    this.transactionid = '',
    this.couponid = '',
  });

  factory CouponItemObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$CouponItemObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$CouponItemObjectBoxStructToJson(this);
}
