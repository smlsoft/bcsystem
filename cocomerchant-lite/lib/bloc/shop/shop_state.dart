part of 'shop_bloc.dart';

abstract class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object> get props => [];
}

class ShopInitial extends ShopState {}

class GetShopInfoInProgress extends ShopState {}

class GetShopInfoSuccess extends ShopState {
  final ShopModel shop;

  const GetShopInfoSuccess({required this.shop});

  @override
  List<Object> get props => [shop];
}

class GetShopInfoFailed extends ShopState {
  final String message;

  const GetShopInfoFailed({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

class ShopUpdateInitial extends ShopState {}

class ShopUpdateInProgress extends ShopState {}

class ShopUpdateSuccess extends ShopState {}

class ShopUpdateFailed extends ShopState {
  final String message;

  const ShopUpdateFailed({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}
