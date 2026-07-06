// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_item_struct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CouponItemObjectBoxStruct _$CouponItemObjectBoxStructFromJson(
  Map<String, dynamic> json,
) => CouponItemObjectBoxStruct(
  couponamount: (json['couponamount'] as num?)?.toDouble() ?? 0,
  coupondescription: json['coupondescription'] as String? ?? '',
  couponno: json['couponno'] as String? ?? '',
  coupontype: json['coupontype'] as String? ?? '',
  reservationid: json['reservationid'] as String? ?? '',
  transactionid: json['transactionid'] as String? ?? '',
  couponid: json['couponid'] as String? ?? '',
)..id = (json['id'] as num).toInt();

Map<String, dynamic> _$CouponItemObjectBoxStructToJson(
  CouponItemObjectBoxStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'couponamount': instance.couponamount,
  'coupondescription': instance.coupondescription,
  'couponno': instance.couponno,
  'coupontype': instance.coupontype,
  'reservationid': instance.reservationid,
  'transactionid': instance.transactionid,
  'couponid': instance.couponid,
};
