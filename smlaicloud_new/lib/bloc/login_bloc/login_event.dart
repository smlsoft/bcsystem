part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

// ignore: must_be_immutable
class LoginOnLoad extends LoginEvent {
  String userName;
  String passWord;
  LoginOnLoad({required this.userName, required this.passWord});

  @override
  List<Object> get props => [];
}

// ignore: must_be_immutable
class RegisterUser extends LoginEvent {
  String userName;
  String passWord;
  String timezonelabel;
  String timezoneoffset;
  String yeartype;
  RegisterUser({
    required this.userName,
    required this.passWord,
    required this.timezonelabel,
    required this.timezoneoffset,
    required this.yeartype,
  });

  @override
  List<Object> get props => [];
}

// ignore: must_be_immutable
class TokenLogin extends LoginEvent {
  String token;
  TokenLogin({required this.token});

  @override
  List<Object> get props => [];
}

class CreateShop extends LoginEvent {
  final CreateShopModel createShop;

  const CreateShop({
    required this.createShop,
  });

  @override
  List<Object> get props => [createShop];
}

/// Logout
class Logout extends LoginEvent {
  const Logout();

  @override
  List<Object> get props => [];
}

/// Token Invalid
class TokenInvalid extends LoginEvent {
  const TokenInvalid();

  @override
  List<Object> get props => [];
}

