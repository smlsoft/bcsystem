part of 'select_shop_bloc.dart';

@freezed
class SelectShopEvent with _$SelectShopEvent {
  const factory SelectShopEvent.onSelectShopStarted() = SelectShopStarted;
  const factory SelectShopEvent.onShopSelectSubmit({required Shop shop}) =
      ShopSelectSubmit;
  const factory SelectShopEvent.onSelectShopRefresh({required Shop shop}) =
      SelectShopRefresh;
}
