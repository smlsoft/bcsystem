import 'package:dedekiosk/model/shop_list_model.dart';
import 'package:dedekiosk/service/user_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'list_shop_event.dart';
part 'list_shop_state.dart';

class ListShopBloc extends Bloc<ListShopEvent, ListShopState> {
  final UserRepository _userRepository;

  ListShopBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(ListShopInitial()) {
    on<ListShopLoad>(_onListShopLoad);
  }

  void _onListShopLoad(ListShopLoad event, Emitter<ListShopState> emit) async {
    emit(ListShopInProgress());
    try {
      final result = await _userRepository.getShopList();

      // print(_result.data);

      if (result.success) {
        List<ShopListModel> shop = (result.data as List).map((shop) => ShopListModel.fromJson(shop)).toList();
        // print(_shop.toString());
        emit(ListShopLoadSuccess(shop: shop));
      } else {
        emit(const ListShopLoadFailed(message: 'Shop Not Found'));
      }
    } catch (e) {
      emit(ListShopLoadFailed(message: e.toString()));
    }
  }
}
