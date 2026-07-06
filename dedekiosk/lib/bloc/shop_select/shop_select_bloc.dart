import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/shop_list_model.dart';
import 'package:dedekiosk/service/user_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'shop_select_event.dart';
part 'shop_select_state.dart';

class ShopSelectBloc extends Bloc<ShopSelectEvent, ShopSelectState> {
  final UserRepository _userRepository;

  ShopSelectBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(ShopSelectInitial()) {
    on<ShopSelect>(_onShopSelect);
  }
  void _onShopSelect(ShopSelect event, Emitter<ShopSelectState> emit) async {
    emit(ShopSelectInProgress());
    try {
      final result = await _userRepository.selectShop(event.shop.shopid);

      if (result.success) {
        emit(ShopSelectLoadSuccess(shop: event.shop));
      } else {
        emit(const ShopSelectLoadFailed(message: 'Shop Not Found'));
      }
    } catch (e) {
      emit(ShopSelectLoadFailed(message: e.toString()));
    }
  }
}
