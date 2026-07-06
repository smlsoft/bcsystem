import 'package:dedecashier/core/core.dart';
import 'package:dedecashier/features/authentication/auth.dart';
import 'package:dedecashier/features/shop/shop.dart';
import 'package:dedecashier/features/splash/domain/usecase/check_user_login_status.dart';
import 'package:dedecashier/services/user_cache_service.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final serviceLocator = GetIt.instance;

Future<void> setUpServiceLocator() async {
  // ป้องกันการ register ซ้ำ
  if (serviceLocator.isRegistered<LoginRemoteDataSource>()) {
    return;
  }

  // authentication
  serviceLocator.registerFactory<LoginRemoteDataSource>(() => LoginRemoteDataSource());
  serviceLocator.registerFactory<LoginUserRepository>(() => LoginUserRepositoryImpl());
  serviceLocator.registerFactory<LoginUserUseCase>(() => LoginUserUseCase());

  // serviceLocator
  //     .registerFactory<FirebaseAuthentication>(() => FirebaseAuthentication());

  // splash
  serviceLocator.registerFactory<CheckUserLoginStatus>(() => CheckUserLoginStatusImpl());

  // shop
  serviceLocator.registerFactory<ShopRemoteRepository>(() => ShopRemoteRepositoryImpl());
  serviceLocator.registerFactory<ShopAuthenticationRepository>(() => ShopRepositoryData());

  // pos

  //

  //services
  serviceLocator.registerSingleton<UserCacheService>(UserCacheService());
  //external
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator.registerFactory<SharedPreferences>(() => sharedPreferences);

  // core
  serviceLocator.registerSingleton<Request>(Request());
  serviceLocator.registerSingleton<Log>(LogImpl());
}
