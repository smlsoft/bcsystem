part of 'authentication_bloc.dart';

@freezed
class AuthenticationEvent with _$AuthenticationEvent {
  const factory AuthenticationEvent.onLoginWithUserPasswordTapped(
      {required String userName,
      required String password}) = LoginUserPasswordEvent;
  const factory AuthenticationEvent.onLoginWithGoogleTapped() =
      LoginWithGoogleEvent;
  const factory AuthenticationEvent.authenticated({required User user}) =
      AuthenticatedEvent;
  const factory AuthenticationEvent.unAuthenticated() = UserLogoutEvent;

  const factory AuthenticationEvent.onAuthenticatedRefresh(
      {required User user}) = AuthenticatedRefreshEvent;
}
