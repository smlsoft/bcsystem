import 'package:dartz/dartz.dart';
import 'package:dedecashier/core/failure.dart';
import 'package:dedecashier/features/authentication/domain/entity/entity.dart';

abstract class LoginUserRepository {
  Future<Either<Failure, User>> loginWithUserPassword({required String username, required String password});
  Future<Either<Failure, User>> loginWithToken({required String token});

  Future<Either<Failure, User>> profile();
}
