import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/coupon_model.dart';
import '../repositories/coupon_repository.dart';
import 'coupon_event.dart';
import 'coupon_state.dart';

class CouponBloc extends Bloc<CouponEvent, CouponState> {
  final CouponRepository _couponRepository;

  CouponBloc({required CouponRepository couponRepository})
      : _couponRepository = couponRepository,
        super(const CouponInitial()) {
    on<GetCoupons>(_onGetCoupons);
    on<GetCouponById>(_onGetCouponById);
    on<CreateCoupon>(_onCreateCoupon);
    on<UpdateCoupon>(_onUpdateCoupon);
    on<DeleteCoupon>(_onDeleteCoupon);
  }

  Future<void> _onGetCoupons(GetCoupons event, Emitter<CouponState> emit) async {
    emit(const CouponLoading());
    try {
      final couponResponse = await _couponRepository.getCoupons();
      if (couponResponse.success == true && couponResponse.data != null) {
        emit(CouponsLoaded(coupons: couponResponse.data!));
      } else {
        emit(const CouponError(message: 'Failed to load coupons'));
      }
    } catch (e) {
      emit(CouponError(message: e.toString()));
    }
  }

  Future<void> _onGetCouponById(GetCouponById event, Emitter<CouponState> emit) async {
    emit(const CouponLoading());
    try {
      print('🔍 Getting coupon by ID: ${event.id}');
      final coupon = await _couponRepository.getCouponById(event.id);
      print('✅ Repository returned coupon: ${coupon.toJson()}');
      print('📋 Coupon guidfixed: ${coupon.guidfixed}');
      print('📋 Coupon couponcode: ${coupon.couponcode}');
      emit(CouponLoaded(coupon: coupon));
      print('🎯 Emitted CouponLoaded state');
    } catch (e) {
      print('❌ Error in _onGetCouponById: $e');
      emit(CouponError(message: e.toString()));
    }
  }

  Future<void> _onCreateCoupon(CreateCoupon event, Emitter<CouponState> emit) async {
    emit(const CouponLoading());
    try {
      final couponModel = CouponModel.fromJson(event.couponData);
      final response = await _couponRepository.createCoupon(couponModel);
      if (response.success) {
        emit(const CouponOperationSuccess(message: 'Coupon created successfully'));
      } else {
        emit(const CouponError(message: 'Failed to create coupon'));
      }
    } catch (e) {
      emit(CouponError(message: e.toString()));
    }
  }

  Future<void> _onUpdateCoupon(UpdateCoupon event, Emitter<CouponState> emit) async {
    emit(const CouponLoading());
    try {
      final couponModel = CouponModel.fromJson(event.couponData);
      final response = await _couponRepository.updateCoupon(event.id, couponModel);
      if (response.success) {
        emit(const CouponOperationSuccess(message: 'Coupon updated successfully'));
      } else {
        emit(const CouponError(message: 'Failed to update coupon'));
      }
    } catch (e) {
      emit(CouponError(message: e.toString()));
    }
  }

  Future<void> _onDeleteCoupon(DeleteCoupon event, Emitter<CouponState> emit) async {
    emit(const CouponLoading());
    try {
      final response = await _couponRepository.deleteCoupon(event.id);
      if (response.success) {
        emit(const CouponOperationSuccess(message: 'Coupon deleted successfully'));
      } else {
        emit(const CouponError(message: 'Failed to delete coupon'));
      }
    } catch (e) {
      emit(CouponError(message: e.toString()));
    }
  }
}
