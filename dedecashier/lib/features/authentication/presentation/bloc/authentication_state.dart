part of 'authentication_bloc.dart';

@freezed
class AuthenticationState with _$AuthenticationState {
  const factory AuthenticationState.initial() = AuthenticationInitialState;
  const factory AuthenticationState.loading() = AuthenticationLoadingState;
  const factory AuthenticationState.error(String message) =
      AuthenticationErrorState;
  const factory AuthenticationState.loaded({
    required User user,
  }) = AuthenticationLoadedState;
  const factory AuthenticationState.authenticated({required User user}) =
      AuthenticationAuthenticatedState;
}
