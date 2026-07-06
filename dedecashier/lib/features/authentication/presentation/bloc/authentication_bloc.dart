import 'package:bloc/bloc.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/features/authentication/domain/entity/user.dart';
import 'package:dedecashier/features/authentication/domain/usecase/authentication_usecase.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';
part 'authentication_bloc.freezed.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc() : super(const AuthenticationInitialState()) {
    on<LoginUserPasswordEvent>((event, emit) async {
      emit(const AuthenticationLoadingState());
      var result = await serviceLocator<LoginUserUseCase>().loginWithUserPassword(username: event.userName, password: event.password);

      result.fold(
        (failure) {
          emit(AuthenticationState.error(failure.message));
        },
        (data) {
          emit(AuthenticationState.loaded(user: data));
        },
      );
    });

    on<LoginWithGoogleEvent>((event, emit) async {
      emit(const AuthenticationLoadingState());

      var result = await serviceLocator<LoginUserUseCase>().loginWithGoogle();
      result.fold(
        (failure) {
          emit(AuthenticationState.error(failure.message));
        },
        (data) {
          emit(AuthenticationState.loaded(user: data));
        },
      );
    });

    on<AuthenticatedEvent>((event, emit) async {
      emit(AuthenticationState.authenticated(user: event.user));
    });

    on<UserLogoutEvent>((event, emit) async {
      var result = await serviceLocator<LoginUserUseCase>().logout();
      if (result) {
        emit(const AuthenticationInitialState());
      }
    });
  }
}
