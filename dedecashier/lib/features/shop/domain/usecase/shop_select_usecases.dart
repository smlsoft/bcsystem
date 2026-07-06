import 'package:dartz/dartz.dart';
import 'package:dedecashier/core/failure.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/features/shop/domain/entity/shop.dart';
import 'package:dedecashier/features/shop/domain/entity/shop_user.dart';
import 'package:dedecashier/features/shop/domain/repository/shop_select_repository.dart';

abstract class ShopSelectUseCases {
  Future<Either<Failure, List<ShopUser>>> listMyShop();
  Future<Either<Failure, bool>> selectShop(String shopid);
  Future<Either<Failure, Shop>> createShop(String shopName);
}

class ShopSelectUseCasesImpl implements ShopSelectUseCases {
  @override
  Future<Either<Failure, List<ShopUser>>> listMyShop() => serviceLocator<ShopAuthenticationRepository>().listMyShop();

  @override
  Future<Either<Failure, bool>> selectShop(String shopid) => serviceLocator<ShopAuthenticationRepository>().selectShop(shopid: shopid);

  @override
  Future<Either<Failure, Shop>> createShop(String shopName) async {
    final shop = Shop(name: shopName);
    return serviceLocator<ShopAuthenticationRepository>().createShop(shop);
  }
}
