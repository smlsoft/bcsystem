import 'package:dedecashier/core/core.dart';
import 'package:dedecashier/features/shop/shop.dart';
import 'package:dedecashier/services/services.dart';

abstract class CheckUserLoginStatus {
  Future<bool> checkIfUserLoggedIn();
  Future<Shop?> checkIfUserSelectedShop();
}

class CheckUserLoginStatusImpl extends CheckUserLoginStatus {
  @override
  Future<bool> checkIfUserLoggedIn() async {
    final user = await serviceLocator<UserCacheService>().getUser();

    // check token not expire

    if (user != null) {
      serviceLocator<Request>().updateAuthorization(user.token);
    }
    return user != null;
  }

  @override
  Future<Shop?> checkIfUserSelectedShop() async {
    final result = await serviceLocator<ShopAuthenticationRepository>().getSelectedShop();
    return result.fold((l) => null, (r) => r);
  }
}
