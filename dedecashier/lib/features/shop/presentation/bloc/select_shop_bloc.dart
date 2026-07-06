import 'package:bloc/bloc.dart';
import 'package:dedecashier/core/core.dart';
import 'package:dedecashier/features/shop/domain/entity/shop.dart';
import 'package:dedecashier/features/shop/domain/entity/shop_user.dart';
import 'package:dedecashier/features/shop/domain/repository/shop_select_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_shop_event.dart';
part 'select_shop_state.dart';
part 'select_shop_bloc.freezed.dart';

class SelectShopBloc extends Bloc<SelectShopEvent, SelectShopState> {
  SelectShopBloc() : super(const SelectShopInitialState()) {
    on<SelectShopStarted>((event, emit) async {
      emit(const SelectShopState.loading());

      var result = await serviceLocator<ShopAuthenticationRepository>().listMyShop();
      result.fold(
        (failure) {
          emit(SelectShopState.error(failure.message));
        },
        (data) {
          emit(SelectShopState.loaded(data));
        },
      );
    });

    on<ShopSelectSubmit>((event, emit) async {
      var result = await serviceLocator<ShopAuthenticationRepository>().selectShop(shopid: event.shop.guidfixed);

      result.fold(
        (failure) {
          emit(SelectShopBlocErrorState(failure.message));
        },
        (data) {
          emit(SelectShopSubmitSuccessState(event.shop));
        },
      );
    });

    on<SelectShopRefresh>((event, emit) async {
      emit(SelectShopSubmitSuccessState(event.shop.copyWith(shopid: event.shop.guidfixed, name: event.shop.name1)));
    });
  }
}
