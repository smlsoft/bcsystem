part of 'select_shop_bloc.dart';

@freezed
class SelectShopState with _$SelectShopState {
  const factory SelectShopState.initial() = SelectShopInitialState;
  const factory SelectShopState.loading() = SelectShopLoadingState;
  const factory SelectShopState.error(String message) =
      SelectShopBlocErrorState;
  const factory SelectShopState.loaded(List<ShopUser> shops) =
      SelectShopLoadedState;
  const factory SelectShopState.selected(Shop shop) =
      SelectShopSubmitSuccessState;
}
