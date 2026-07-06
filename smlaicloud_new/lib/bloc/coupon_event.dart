import 'package:equatable/equatable.dart';

abstract class CouponEvent extends Equatable {
  const CouponEvent();

  @override
  List<Object> get props => [];
}

class GetCoupons extends CouponEvent {
  const GetCoupons();
}

class GetCouponById extends CouponEvent {
  final String id;

  const GetCouponById({required this.id});

  @override
  List<Object> get props => [id];
}

class CreateCoupon extends CouponEvent {
  final Map<String, dynamic> couponData;

  const CreateCoupon({required this.couponData});

  @override
  List<Object> get props => [couponData];
}

class UpdateCoupon extends CouponEvent {
  final String id;
  final Map<String, dynamic> couponData;

  const UpdateCoupon({required this.id, required this.couponData});

  @override
  List<Object> get props => [id, couponData];
}

class DeleteCoupon extends CouponEvent {
  final String id;

  const DeleteCoupon({required this.id});

  @override
  List<Object> get props => [id];
}
