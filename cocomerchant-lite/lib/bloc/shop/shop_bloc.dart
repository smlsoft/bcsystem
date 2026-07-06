import 'package:cocomerchant_lite/model/shop_model.dart';
import 'package:cocomerchant_lite/repositories/shop_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'shop_event.dart';
part 'shop_state.dart';

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final ShopRepository _shopRepository;

  ShopBloc({required ShopRepository shopRepository})
      : _shopRepository = shopRepository,
        super(ShopInitial()) {
    on<GetShopInfo>(_onGetShopInfo);
    on<ShopUpdate>(_onShopUpdate);
  }
  void _onGetShopInfo(GetShopInfo event, Emitter<ShopState> emit) async {
    emit(GetShopInfoInProgress());
    try {
      final result = await _shopRepository.loadShopInfo(event.shopid);

      if (result.success) {
        ShopModel shopmodel = ShopModel.fromJson(result.data);
        emit(GetShopInfoSuccess(shop: shopmodel));
      } else {
        emit(const GetShopInfoFailed(message: 'Shop Not Found'));
      }
    } catch (e) {
      emit(GetShopInfoFailed(message: e.toString()));
    }
  }

  void _onShopUpdate(ShopUpdate event, Emitter<ShopState> emit) async {
    emit(ShopUpdateInProgress());
    try {
      final result = await _shopRepository.updateShop(event.shopid, event.shopdata);
      if (result.success) {
        emit(ShopUpdateSuccess());
      } else {
        emit(ShopUpdateFailed(message: 'Shop Update Failed :  ${result.message}'));
      }
    } catch (e) {
      emit(ShopUpdateFailed(message: e.toString()));
    }
  }
}
