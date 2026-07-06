// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:dedekiosk/model/user_login_model.dart';
import 'package:dedekiosk/service/user_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:dedekiosk/global.dart' as global;

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final UserRepository _userRepository;

  LoginBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(LoginInitial()) {
    on<TokenLogin>(_onTokenLogin);
    on<TokenInvalid>(_onTokenInvalid);
  }

  void _onTokenLogin(TokenLogin event, Emitter<LoginState> emit) async {
    emit(TokenLoginInProgress());
    try {
      final result = await _userRepository.authenUserByToken(event.token);

      if (result.success) {
        // print(result.data);
        UserLoginModel userLogin = UserLoginModel(userName: event.user, token: result.data["token"]);

        emit(TokenLoginSuccess(userLogin: userLogin));
      } else {
        emit(const TokenLoginFailed(message: 'User Not Found'));
      }
    } on Exception catch (exception) {
      emit(TokenLoginFailed(message: 'ติดต่อ Server ไม่ได้ : $exception'));
    } catch (e) {
      emit(TokenLoginFailed(message: 'ติดต่อ Server ไม่ได้ : $e'));
    }
  }

  /// handler token invalid
  /// Clear all data in GetStorage
  void _onTokenInvalid(TokenInvalid event, Emitter<LoginState> emit) async {
    emit(LogoutInProgress());
    try {
      emit(LogoutSuccess());
    } catch (e) {
      final error = jsonDecode(e.toString());
      emit(LogoutFailed(message: error['message']));
    }
  }
}
