import 'package:dartz/dartz.dart';
import 'package:dedecashier/core/core.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/features/authentication/domain/entity/entity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class ILoginRemoteDataSource {
  Future<Either<Failure, User>> loginWithUserPassword({
    required String username,
    required String password,
  });
  Future<Either<Failure, User>> loginWithToken({required String token});
  Future<Either<Failure, User>> profile();
}

class LoginRemoteDataSource implements ILoginRemoteDataSource {
  final Request request = serviceLocator<Request>();
  @override
  Future<Either<Failure, User>> loginWithToken({required String token}) async {
    try {
      final response = await request.post(
        '/tokenlogin',
        data: {"token": token},
      );
      final result = Json.decode(response.toString());

      if (response.statusCode == 200) {
        UserToken token = UserToken.fromJson(result);

        request.updateAuthorization(token.token);

        final userResponse = await request.get('/profile');
        final userResult = Json.decode(userResponse.toString());
        ApiResponse responseGetProfile = ApiResponse.fromMap(userResult);

        User user = User.fromJson(responseGetProfile.data);
        user = user.copyWith(token: token.token);

        return Right(user);
      }

      String errorMessage = '${result['message']}';
      return Left(ConnectionFailure(errorMessage));
    } catch (e) {
      AppLogger.error('LoginRemoteDataSourceImplError $e');
      return const Left(
        Exception('Exception Occurred in LoginRemoteDataSource'),
      );
    }
  }

  @override
  Future<Either<Failure, User>> loginWithUserPassword({
    required String username,
    required String password,
  }) async {
    try {
      final response = await request.post(
        '/login',
        data: {"username": username, "password": password},
      );
      final result = Json.decode(response.toString());

      if (response.statusCode == 200) {
        UserToken token = UserToken.fromJson(result);

        request.updateAuthorization(token.token);

        final userResponse = await request.get('/profile');
        final userResult = Json.decode(userResponse.toString());
        ApiResponse responseGetProfile = ApiResponse.fromMap(userResult);

        User user = User.fromJson(responseGetProfile.data);
        user = user.copyWith(token: token.token);

        return Right(user);
      }

      String errorMessage = '${result['code']}: ${result['message']}';
      return Left(ConnectionFailure(errorMessage));
    } catch (e) {
      AppLogger.error('LoginRemoteDataSourceImplError $e');
      return const Left(
        Exception('Exception Occurred in LoginRemoteDataSource'),
      );
    }
  }

  @override
  Future<Either<Failure, User>> profile() async {
    try {
      final response = await request.get('/profile');
      final result = Json.decode(response.toString());

      if (response.statusCode == 200) {
        ApiResponse responseGetProfile = ApiResponse.fromMap(result);
        User user = User.fromJson(responseGetProfile.data);
        return right(user);
      }

      return const Left(
        Exception('Exception Occurred in LoginRemoteDataSource'),
      );
    } catch (e) {
      AppLogger.error('LoginRemoteDataSourceImplError $e');
      return const Left(
        Exception('Exception Occurred in LoginRemoteDataSource'),
      );
    }
  }
}
