import 'package:dartz/dartz.dart';
import 'package:dedecashier/core/failure.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/features/authentication/domain/entity/user.dart';
import 'package:dedecashier/features/authentication/domain/repository/authentication_user_repository.dart';
import 'package:dedecashier/services/user_cache_service.dart';
// import 'package:firebase_authentication/firebase_authentication.dart';

class LoginUserUseCase {
  Future<Either<Failure, User>> loginWithUserPassword({required String username, required String password}) async {
    final response = await serviceLocator<LoginUserRepository>().loginWithUserPassword(username: username, password: password);
    if (response.isRight()) {
      final remoteUser = response.getOrElse(() => User());
      await serviceLocator<UserCacheService>().saveUser(remoteUser);
    }
    return response;
  }

  Future<Either<Failure, User>> loginWithToken({required String token}) async {
    final response = await serviceLocator<LoginUserRepository>().loginWithToken(token: token);
    if (response.isRight()) {
      final remoteUser = response.getOrElse(() => User());
      await serviceLocator<UserCacheService>().saveUser(remoteUser);
    }
    return response;
  }

  Future<Either<Failure, User>> loginWithGoogle() async {
    try {
      // await serviceLocator<FirebaseAuthentication>().logInWithGoogle();
      // final String? token =
      //     await serviceLocator<FirebaseAuthentication>().getIdToken();
      // if (token != null) {
      //   return loginWithToken(token: token);
      // }

      return left(const ConnectionFailure("Cannot Login With Google"));
    } catch (e) {
      return left(ConnectionFailure(e.toString()));
    }
  }

  Future<bool> logout() async {
    final isDeleted = await serviceLocator<UserCacheService>().deleteUser();
    return isDeleted;
  }
}
