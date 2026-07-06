import 'package:dartz/dartz.dart';
import 'package:dedecashier/core/failure.dart';
import 'package:dedecashier/features/shop/domain/entity/shop.dart';
import 'package:dedecashier/features/shop/domain/entity/shop_user.dart';

abstract class ShopAuthenticationRepository {
  Future<Either<Failure, List<ShopUser>>> listMyShop();
  Future<Either<Failure, bool>> selectShop({required String shopid});
  Future<Either<Failure, Shop>> createShop(Shop shop);
  Future<Either<Failure, Shop>> getSelectedShop();
}
