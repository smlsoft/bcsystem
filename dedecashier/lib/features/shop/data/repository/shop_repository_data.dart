import 'package:dartz/dartz.dart';
import 'package:dedecashier/core/core.dart';
import 'package:dedecashier/features/shop/data/datasource/shop_remote_datasource.dart';
import 'package:dedecashier/features/shop/domain/entity/shop.dart';
import 'package:dedecashier/features/shop/domain/entity/shop_user.dart';
import 'package:dedecashier/features/shop/domain/repository/shop_select_repository.dart';

class ShopRepositoryData extends ShopAuthenticationRepository {
  @override
  Future<Either<Failure, Shop>> createShop(Shop shop) {
    return serviceLocator<ShopRemoteRepository>().createShop(shop: shop);
  }

  @override
  Future<Either<Failure, List<ShopUser>>> listMyShop() {
    return serviceLocator<ShopRemoteRepository>().listMyShop();
  }

  @override
  Future<Either<Failure, bool>> selectShop({required String shopid}) {
    return serviceLocator<ShopRemoteRepository>().selectShop(id: shopid);
  }

  @override
  Future<Either<Failure, Shop>> getSelectedShop() {
    return serviceLocator<ShopRemoteRepository>().getSelectedShop();
  }
}
