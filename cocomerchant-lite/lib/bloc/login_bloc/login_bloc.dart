// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:cocomerchant_lite/auth_service.dart';
import 'package:cocomerchant_lite/model/company_branch_model.dart';
import 'package:cocomerchant_lite/model/config_model.dart';
import 'package:cocomerchant_lite/model/create_shop_model.dart';
import 'package:cocomerchant_lite/model/profile_model.dart';
import 'package:cocomerchant_lite/model/shop_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cocomerchant_lite/repositories/user_repository.dart';
import 'package:cocomerchant_lite/model/user_login_model.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cocomerchant_lite/global.dart' as global;

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final UserRepository _userRepository;

  GetStorage appConfig = GetStorage('AppConfig');

  LoginBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(LoginInitial()) {
    on<LoginOnLoad>(_onLoginLoad);
    on<RegisterUser>(_onRegisterUser);
    on<TokenLogin>(_onTokenLogin);
    on<CreateShop>(_onCreateShop);
    on<Logout>(_onLogout);
    on<TokenInvalid>(_onTokenInvalid);
  }

  void _onLoginLoad(LoginOnLoad event, Emitter<LoginState> emit) async {
    emit(LoginInProgress());
    try {
      final result = await _userRepository.authenUser(event.userName, event.passWord);

      if (result.success) {
        UserLoginModel userLogin = UserLoginModel(userName: event.userName, token: result.data["token"]);
        appConfig.write("refreshtoken", result.data["refresh"]);
        appConfig.write("token", result.data["token"]);
        appConfig.write("user", event.userName);
        // print(result.data["token"]);
        emit(LoginSuccess(userLogin: userLogin));
      } else {
        emit(const LoginFailed(message: 'User Not Found'));
      }
    } on Exception catch (exception) {
      emit(LoginFailed(message: 'ติดต่อ Server ไม่ได้ : $exception'));
    } catch (e) {
      emit(LoginFailed(message: 'ติดต่อ Server ไม่ได้ : $e'));
    }
  }

  void _onRegisterUser(RegisterUser event, Emitter<LoginState> emit) async {
    emit(RegisterInProgress());
    try {
      // DateTime now = DateTime.now();
      // int timeZoneOffset = now.timeZoneOffset.inHours;
      String timezonelabel = "";
      String timezonefffset = "";
      String yeartype = "christian";

      // String currentTimeZone = "";
      // if (kIsWeb == false) {
      //   currentTimeZone = await FlutterNativeTimezone.getLocalTimezone();
      // } else {
      //   currentTimeZone = "Asia/Bangkok";
      // }

      // // Find the first timezone that matches the given conditions
      // TimezonesModel timezone = global.timezonesListData.firstWhere((element) => element.offset == timeZoneOffset.abs().toString());
      // for (var element in timezone.utc) {
      //   if (element == currentTimeZone) {
      //     timezonelabel = timezone.text;
      //     timezonefffset = timezone.offset;
      //     break;
      //   }
      // }

      final result = await _userRepository.registerUser(event.userName, event.passWord, timezonelabel, timezonefffset, yeartype);

      if (result.success) {
        emit(RegisterSuccess());
      } else {
        emit(const RegisterFailed(message: 'Not Found'));
      }
    } on Exception catch (exception) {
      emit(RegisterFailed(message: 'ติดต่อ Server ไม่ได้ : $exception'));
    } catch (e) {
      emit(RegisterFailed(message: 'ติดต่อ Server ไม่ได้ : $e'));
    }
  }

  void _onTokenLogin(TokenLogin event, Emitter<LoginState> emit) async {
    emit(TokenLoginInProgress());
    try {
      final result = await _userRepository.authenUserByToken(event.token);

      if (result.success) {
        // print(result.data);
        UserLoginModel userLogin = UserLoginModel(userName: event.user, token: result.data["token"]);
        appConfig.write("token", result.data["token"]);

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

  void _onCreateShop(CreateShop event, Emitter<LoginState> emit) async {
    emit(CreateShopInProgress());
    try {
      await _userRepository.createShop(event.createShop);
      emit(CreateShopSuccess());
    } catch (e) {
      final error = jsonDecode(e.toString());
      emit(CreateShopFailed(message: error['message']));
    }
  }

  /// Logout
  /// Clear all data in GetStorage
  void _onLogout(Logout event, Emitter<LoginState> emit) async {
    emit(LogoutInProgress());
    try {
      await _userRepository.logout();
      final AuthService auth = AuthService();
      await auth.signOut();
      global.shopSelectData = ShopModel();
      global.companyBranchSelectData = CompanyBranchModel(
        guidfixed: '',
        code: '',
        businesstype: null,
      );
      global.profileData = ProfileModel();
      global.config = ConfigModel();
      appConfig.erase();
      global.shopid = "";
      emit(LogoutSuccess());
    } catch (e) {
      final error = jsonDecode(e.toString());
      emit(LogoutFailed(message: error['message']));
    }
  }

  /// handler token invalid
  /// Clear all data in GetStorage
  void _onTokenInvalid(TokenInvalid event, Emitter<LoginState> emit) async {
    emit(LogoutInProgress());
    try {
      appConfig.erase();
      emit(LogoutSuccess());
    } catch (e) {
      final error = jsonDecode(e.toString());
      emit(LogoutFailed(message: error['message']));
    }
  }
}
