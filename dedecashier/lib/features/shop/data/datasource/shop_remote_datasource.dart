import 'package:dartz/dartz.dart';
import 'package:dedecashier/core/core.dart';
import 'package:dedecashier/features/shop/domain/entity/shop.dart';
import 'package:dedecashier/features/shop/domain/entity/shop_user.dart';
import 'package:dedecashier/global.dart' as global;

abstract class ShopRemoteRepository {
  Future<Either<Failure, List<ShopUser>>> listMyShop();
  Future<Either<Failure, Shop>> getShopById({required String id});
  Future<Either<Failure, Shop>> createShop({required Shop shop});
  Future<Either<Failure, bool>> selectShop({required String id});
  Future<Either<Failure, Shop>> getSelectedShop();
}

class ShopRemoteRepositoryImpl extends ShopRemoteRepository {
  final Request request = serviceLocator<Request>();
  @override
  Future<Either<Failure, Shop>> createShop({required Shop shop}) async {
    try {
      final response = await request.post('/create-shop', data: shop.toJson());
      final result = Json.decode(response.toString());
      final ApiResponse apiResponse = ApiResponse.fromMap(result);
      if (response.statusCode == 200 && apiResponse.success == true) {
        final id = result['id'];
        shop = shop.copyWith(shopid: id);
        return Right(shop);
      }
      return Left(ConnectionFailure(result['message']));
    } catch (e) {
      return Left(ConnectionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Shop>> getShopById({required String id}) async {
    try {
      final response = await request.get('/shop/$id');
      final result = Json.decode(response.toString());
      final ApiResponse apiResponse = ApiResponse.fromMap(result);

      if (response.statusCode == 200 && apiResponse.success == true) {
        Shop shop = Shop.fromJson(apiResponse.data);
        return Right(shop);
      }
      return Left(ConnectionFailure(result['message']));
    } catch (e) {
      return Left(ConnectionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ShopUser>>> listMyShop() async {
    try {
      final response = await request.get('/list-shop');
      final result = Json.decode(response.toString());

      if (response.statusCode == 200 && result['success'] == true) {
        List<ShopUser> shops = [];
        result['data'].forEach((element) {
          shops.add(ShopUser.fromJson(element));
        });
        return Right(shops);
      }
      return Left(ConnectionFailure(result['message']));
    } catch (e) {
      return Left(ConnectionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> selectShop({required String id}) async {
    try {
      final response = await request.post('/select-shop', data: {"shopid": id});
      final result = Json.decode(response.toString());
      final ApiResponse apiResponse = ApiResponse.fromMap(result);
      if (response.statusCode == 200 && apiResponse.success) {
        return const Right(true);
      }
      return Left(ConnectionFailure(apiResponse.message));
    } catch (e) {
      return Left(ConnectionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Shop>> getSelectedShop() async {
    try {
      final response = await request.get('/profileshop');
      final result = Json.decode(response.toString());
      final ApiResponse apiResponse = ApiResponse.fromMap(result);

      if (response.statusCode == 200 && result['success'] == true) {
        String shopGuid = apiResponse.data['guidfixed'];
        global.shopId = shopGuid;
        return await getShopById(id: shopGuid);
      }
      return Left(ConnectionFailure(apiResponse.message));
    } catch (e) {
      return Left(ConnectionFailure(e.toString()));
    }
  }
}
