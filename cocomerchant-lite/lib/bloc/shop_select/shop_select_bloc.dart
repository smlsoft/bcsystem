import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/shop_list_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cocomerchant_lite/repositories/user_repository.dart';

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
        event.shop.names = event.shop.names ?? <LanguageDataModel>[];

        await global.appConfig.write("name", event.shop.name);
        await global.appConfig.write("shopname", event.shop.names);
        await global.appConfig.write("shopid", event.shop.shopid);
        await global.appConfig.write("createdby", event.shop.createdby);
        global.shopid = event.shop.shopid;
        if (kDebugMode) {
          print("token: ${global.appConfig.read("token")}");
          print("shopid: ${global.appConfig.read("shopid")}");
        }

        emit(ShopSelectLoadSuccess(shop: event.shop));
      } else {
        emit(const ShopSelectLoadFailed(message: 'Shop Not Found'));
      }
    } catch (e) {
      emit(ShopSelectLoadFailed(message: e.toString()));
    }
  }
}
