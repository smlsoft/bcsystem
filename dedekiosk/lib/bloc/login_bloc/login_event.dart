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
  String user;
  TokenLogin({required this.token, required this.user});

  @override
  List<Object> get props => [];
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
