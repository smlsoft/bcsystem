// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authentication_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthenticationEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticationEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthenticationEvent()';
}


}

/// @nodoc
class $AuthenticationEventCopyWith<$Res>  {
$AuthenticationEventCopyWith(AuthenticationEvent _, $Res Function(AuthenticationEvent) __);
}


/// Adds pattern-matching-related methods to [AuthenticationEvent].
extension AuthenticationEventPatterns on AuthenticationEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LoginUserPasswordEvent value)?  onLoginWithUserPasswordTapped,TResult Function( LoginWithGoogleEvent value)?  onLoginWithGoogleTapped,TResult Function( AuthenticatedEvent value)?  authenticated,TResult Function( UserLogoutEvent value)?  unAuthenticated,TResult Function( AuthenticatedRefreshEvent value)?  onAuthenticatedRefresh,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LoginUserPasswordEvent() when onLoginWithUserPasswordTapped != null:
return onLoginWithUserPasswordTapped(_that);case LoginWithGoogleEvent() when onLoginWithGoogleTapped != null:
return onLoginWithGoogleTapped(_that);case AuthenticatedEvent() when authenticated != null:
return authenticated(_that);case UserLogoutEvent() when unAuthenticated != null:
return unAuthenticated(_that);case AuthenticatedRefreshEvent() when onAuthenticatedRefresh != null:
return onAuthenticatedRefresh(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LoginUserPasswordEvent value)  onLoginWithUserPasswordTapped,required TResult Function( LoginWithGoogleEvent value)  onLoginWithGoogleTapped,required TResult Function( AuthenticatedEvent value)  authenticated,required TResult Function( UserLogoutEvent value)  unAuthenticated,required TResult Function( AuthenticatedRefreshEvent value)  onAuthenticatedRefresh,}){
final _that = this;
switch (_that) {
case LoginUserPasswordEvent():
return onLoginWithUserPasswordTapped(_that);case LoginWithGoogleEvent():
return onLoginWithGoogleTapped(_that);case AuthenticatedEvent():
return authenticated(_that);case UserLogoutEvent():
return unAuthenticated(_that);case AuthenticatedRefreshEvent():
return onAuthenticatedRefresh(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LoginUserPasswordEvent value)?  onLoginWithUserPasswordTapped,TResult? Function( LoginWithGoogleEvent value)?  onLoginWithGoogleTapped,TResult? Function( AuthenticatedEvent value)?  authenticated,TResult? Function( UserLogoutEvent value)?  unAuthenticated,TResult? Function( AuthenticatedRefreshEvent value)?  onAuthenticatedRefresh,}){
final _that = this;
switch (_that) {
case LoginUserPasswordEvent() when onLoginWithUserPasswordTapped != null:
return onLoginWithUserPasswordTapped(_that);case LoginWithGoogleEvent() when onLoginWithGoogleTapped != null:
return onLoginWithGoogleTapped(_that);case AuthenticatedEvent() when authenticated != null:
return authenticated(_that);case UserLogoutEvent() when unAuthenticated != null:
return unAuthenticated(_that);case AuthenticatedRefreshEvent() when onAuthenticatedRefresh != null:
return onAuthenticatedRefresh(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String userName,  String password)?  onLoginWithUserPasswordTapped,TResult Function()?  onLoginWithGoogleTapped,TResult Function( User user)?  authenticated,TResult Function()?  unAuthenticated,TResult Function( User user)?  onAuthenticatedRefresh,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LoginUserPasswordEvent() when onLoginWithUserPasswordTapped != null:
return onLoginWithUserPasswordTapped(_that.userName,_that.password);case LoginWithGoogleEvent() when onLoginWithGoogleTapped != null:
return onLoginWithGoogleTapped();case AuthenticatedEvent() when authenticated != null:
return authenticated(_that.user);case UserLogoutEvent() when unAuthenticated != null:
return unAuthenticated();case AuthenticatedRefreshEvent() when onAuthenticatedRefresh != null:
return onAuthenticatedRefresh(_that.user);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String userName,  String password)  onLoginWithUserPasswordTapped,required TResult Function()  onLoginWithGoogleTapped,required TResult Function( User user)  authenticated,required TResult Function()  unAuthenticated,required TResult Function( User user)  onAuthenticatedRefresh,}) {final _that = this;
switch (_that) {
case LoginUserPasswordEvent():
return onLoginWithUserPasswordTapped(_that.userName,_that.password);case LoginWithGoogleEvent():
return onLoginWithGoogleTapped();case AuthenticatedEvent():
return authenticated(_that.user);case UserLogoutEvent():
return unAuthenticated();case AuthenticatedRefreshEvent():
return onAuthenticatedRefresh(_that.user);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String userName,  String password)?  onLoginWithUserPasswordTapped,TResult? Function()?  onLoginWithGoogleTapped,TResult? Function( User user)?  authenticated,TResult? Function()?  unAuthenticated,TResult? Function( User user)?  onAuthenticatedRefresh,}) {final _that = this;
switch (_that) {
case LoginUserPasswordEvent() when onLoginWithUserPasswordTapped != null:
return onLoginWithUserPasswordTapped(_that.userName,_that.password);case LoginWithGoogleEvent() when onLoginWithGoogleTapped != null:
return onLoginWithGoogleTapped();case AuthenticatedEvent() when authenticated != null:
return authenticated(_that.user);case UserLogoutEvent() when unAuthenticated != null:
return unAuthenticated();case AuthenticatedRefreshEvent() when onAuthenticatedRefresh != null:
return onAuthenticatedRefresh(_that.user);case _:
  return null;

}
}

}

/// @nodoc


class LoginUserPasswordEvent implements AuthenticationEvent {
  const LoginUserPasswordEvent({required this.userName, required this.password});
  

 final  String userName;
 final  String password;

/// Create a copy of AuthenticationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginUserPasswordEventCopyWith<LoginUserPasswordEvent> get copyWith => _$LoginUserPasswordEventCopyWithImpl<LoginUserPasswordEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginUserPasswordEvent&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.password, password) || other.password == password));
}


@override
int get hashCode => Object.hash(runtimeType,userName,password);

@override
String toString() {
  return 'AuthenticationEvent.onLoginWithUserPasswordTapped(userName: $userName, password: $password)';
}


}

/// @nodoc
abstract mixin class $LoginUserPasswordEventCopyWith<$Res> implements $AuthenticationEventCopyWith<$Res> {
  factory $LoginUserPasswordEventCopyWith(LoginUserPasswordEvent value, $Res Function(LoginUserPasswordEvent) _then) = _$LoginUserPasswordEventCopyWithImpl;
@useResult
$Res call({
 String userName, String password
});




}
/// @nodoc
class _$LoginUserPasswordEventCopyWithImpl<$Res>
    implements $LoginUserPasswordEventCopyWith<$Res> {
  _$LoginUserPasswordEventCopyWithImpl(this._self, this._then);

  final LoginUserPasswordEvent _self;
  final $Res Function(LoginUserPasswordEvent) _then;

/// Create a copy of AuthenticationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? userName = null,Object? password = null,}) {
  return _then(LoginUserPasswordEvent(
userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LoginWithGoogleEvent implements AuthenticationEvent {
  const LoginWithGoogleEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginWithGoogleEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthenticationEvent.onLoginWithGoogleTapped()';
}


}




/// @nodoc


class AuthenticatedEvent implements AuthenticationEvent {
  const AuthenticatedEvent({required this.user});
  

 final  User user;

/// Create a copy of AuthenticationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthenticatedEventCopyWith<AuthenticatedEvent> get copyWith => _$AuthenticatedEventCopyWithImpl<AuthenticatedEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticatedEvent&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'AuthenticationEvent.authenticated(user: $user)';
}


}

/// @nodoc
abstract mixin class $AuthenticatedEventCopyWith<$Res> implements $AuthenticationEventCopyWith<$Res> {
  factory $AuthenticatedEventCopyWith(AuthenticatedEvent value, $Res Function(AuthenticatedEvent) _then) = _$AuthenticatedEventCopyWithImpl;
@useResult
$Res call({
 User user
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$AuthenticatedEventCopyWithImpl<$Res>
    implements $AuthenticatedEventCopyWith<$Res> {
  _$AuthenticatedEventCopyWithImpl(this._self, this._then);

  final AuthenticatedEvent _self;
  final $Res Function(AuthenticatedEvent) _then;

/// Create a copy of AuthenticationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(AuthenticatedEvent(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,
  ));
}

/// Create a copy of AuthenticationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

/// @nodoc


class UserLogoutEvent implements AuthenticationEvent {
  const UserLogoutEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserLogoutEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthenticationEvent.unAuthenticated()';
}


}




/// @nodoc


class AuthenticatedRefreshEvent implements AuthenticationEvent {
  const AuthenticatedRefreshEvent({required this.user});
  

 final  User user;

/// Create a copy of AuthenticationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthenticatedRefreshEventCopyWith<AuthenticatedRefreshEvent> get copyWith => _$AuthenticatedRefreshEventCopyWithImpl<AuthenticatedRefreshEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticatedRefreshEvent&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'AuthenticationEvent.onAuthenticatedRefresh(user: $user)';
}


}

/// @nodoc
abstract mixin class $AuthenticatedRefreshEventCopyWith<$Res> implements $AuthenticationEventCopyWith<$Res> {
  factory $AuthenticatedRefreshEventCopyWith(AuthenticatedRefreshEvent value, $Res Function(AuthenticatedRefreshEvent) _then) = _$AuthenticatedRefreshEventCopyWithImpl;
@useResult
$Res call({
 User user
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$AuthenticatedRefreshEventCopyWithImpl<$Res>
    implements $AuthenticatedRefreshEventCopyWith<$Res> {
  _$AuthenticatedRefreshEventCopyWithImpl(this._self, this._then);

  final AuthenticatedRefreshEvent _self;
  final $Res Function(AuthenticatedRefreshEvent) _then;

/// Create a copy of AuthenticationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(AuthenticatedRefreshEvent(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,
  ));
}

/// Create a copy of AuthenticationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

/// @nodoc
mixin _$AuthenticationState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticationState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthenticationState()';
}


}

/// @nodoc
class $AuthenticationStateCopyWith<$Res>  {
$AuthenticationStateCopyWith(AuthenticationState _, $Res Function(AuthenticationState) __);
}


/// Adds pattern-matching-related methods to [AuthenticationState].
extension AuthenticationStatePatterns on AuthenticationState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthenticationInitialState value)?  initial,TResult Function( AuthenticationLoadingState value)?  loading,TResult Function( AuthenticationErrorState value)?  error,TResult Function( AuthenticationLoadedState value)?  loaded,TResult Function( AuthenticationAuthenticatedState value)?  authenticated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthenticationInitialState() when initial != null:
return initial(_that);case AuthenticationLoadingState() when loading != null:
return loading(_that);case AuthenticationErrorState() when error != null:
return error(_that);case AuthenticationLoadedState() when loaded != null:
return loaded(_that);case AuthenticationAuthenticatedState() when authenticated != null:
return authenticated(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthenticationInitialState value)  initial,required TResult Function( AuthenticationLoadingState value)  loading,required TResult Function( AuthenticationErrorState value)  error,required TResult Function( AuthenticationLoadedState value)  loaded,required TResult Function( AuthenticationAuthenticatedState value)  authenticated,}){
final _that = this;
switch (_that) {
case AuthenticationInitialState():
return initial(_that);case AuthenticationLoadingState():
return loading(_that);case AuthenticationErrorState():
return error(_that);case AuthenticationLoadedState():
return loaded(_that);case AuthenticationAuthenticatedState():
return authenticated(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthenticationInitialState value)?  initial,TResult? Function( AuthenticationLoadingState value)?  loading,TResult? Function( AuthenticationErrorState value)?  error,TResult? Function( AuthenticationLoadedState value)?  loaded,TResult? Function( AuthenticationAuthenticatedState value)?  authenticated,}){
final _that = this;
switch (_that) {
case AuthenticationInitialState() when initial != null:
return initial(_that);case AuthenticationLoadingState() when loading != null:
return loading(_that);case AuthenticationErrorState() when error != null:
return error(_that);case AuthenticationLoadedState() when loaded != null:
return loaded(_that);case AuthenticationAuthenticatedState() when authenticated != null:
return authenticated(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String message)?  error,TResult Function( User user)?  loaded,TResult Function( User user)?  authenticated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthenticationInitialState() when initial != null:
return initial();case AuthenticationLoadingState() when loading != null:
return loading();case AuthenticationErrorState() when error != null:
return error(_that.message);case AuthenticationLoadedState() when loaded != null:
return loaded(_that.user);case AuthenticationAuthenticatedState() when authenticated != null:
return authenticated(_that.user);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String message)  error,required TResult Function( User user)  loaded,required TResult Function( User user)  authenticated,}) {final _that = this;
switch (_that) {
case AuthenticationInitialState():
return initial();case AuthenticationLoadingState():
return loading();case AuthenticationErrorState():
return error(_that.message);case AuthenticationLoadedState():
return loaded(_that.user);case AuthenticationAuthenticatedState():
return authenticated(_that.user);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String message)?  error,TResult? Function( User user)?  loaded,TResult? Function( User user)?  authenticated,}) {final _that = this;
switch (_that) {
case AuthenticationInitialState() when initial != null:
return initial();case AuthenticationLoadingState() when loading != null:
return loading();case AuthenticationErrorState() when error != null:
return error(_that.message);case AuthenticationLoadedState() when loaded != null:
return loaded(_that.user);case AuthenticationAuthenticatedState() when authenticated != null:
return authenticated(_that.user);case _:
  return null;

}
}

}

/// @nodoc


class AuthenticationInitialState implements AuthenticationState {
  const AuthenticationInitialState();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticationInitialState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthenticationState.initial()';
}


}




/// @nodoc


class AuthenticationLoadingState implements AuthenticationState {
  const AuthenticationLoadingState();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticationLoadingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthenticationState.loading()';
}


}




/// @nodoc


class AuthenticationErrorState implements AuthenticationState {
  const AuthenticationErrorState(this.message);
  

 final  String message;

/// Create a copy of AuthenticationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthenticationErrorStateCopyWith<AuthenticationErrorState> get copyWith => _$AuthenticationErrorStateCopyWithImpl<AuthenticationErrorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticationErrorState&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AuthenticationState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $AuthenticationErrorStateCopyWith<$Res> implements $AuthenticationStateCopyWith<$Res> {
  factory $AuthenticationErrorStateCopyWith(AuthenticationErrorState value, $Res Function(AuthenticationErrorState) _then) = _$AuthenticationErrorStateCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$AuthenticationErrorStateCopyWithImpl<$Res>
    implements $AuthenticationErrorStateCopyWith<$Res> {
  _$AuthenticationErrorStateCopyWithImpl(this._self, this._then);

  final AuthenticationErrorState _self;
  final $Res Function(AuthenticationErrorState) _then;

/// Create a copy of AuthenticationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(AuthenticationErrorState(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthenticationLoadedState implements AuthenticationState {
  const AuthenticationLoadedState({required this.user});
  

 final  User user;

/// Create a copy of AuthenticationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthenticationLoadedStateCopyWith<AuthenticationLoadedState> get copyWith => _$AuthenticationLoadedStateCopyWithImpl<AuthenticationLoadedState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticationLoadedState&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'AuthenticationState.loaded(user: $user)';
}


}

/// @nodoc
abstract mixin class $AuthenticationLoadedStateCopyWith<$Res> implements $AuthenticationStateCopyWith<$Res> {
  factory $AuthenticationLoadedStateCopyWith(AuthenticationLoadedState value, $Res Function(AuthenticationLoadedState) _then) = _$AuthenticationLoadedStateCopyWithImpl;
@useResult
$Res call({
 User user
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$AuthenticationLoadedStateCopyWithImpl<$Res>
    implements $AuthenticationLoadedStateCopyWith<$Res> {
  _$AuthenticationLoadedStateCopyWithImpl(this._self, this._then);

  final AuthenticationLoadedState _self;
  final $Res Function(AuthenticationLoadedState) _then;

/// Create a copy of AuthenticationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(AuthenticationLoadedState(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,
  ));
}

/// Create a copy of AuthenticationState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

/// @nodoc


class AuthenticationAuthenticatedState implements AuthenticationState {
  const AuthenticationAuthenticatedState({required this.user});
  

 final  User user;

/// Create a copy of AuthenticationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthenticationAuthenticatedStateCopyWith<AuthenticationAuthenticatedState> get copyWith => _$AuthenticationAuthenticatedStateCopyWithImpl<AuthenticationAuthenticatedState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticationAuthenticatedState&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'AuthenticationState.authenticated(user: $user)';
}


}

/// @nodoc
abstract mixin class $AuthenticationAuthenticatedStateCopyWith<$Res> implements $AuthenticationStateCopyWith<$Res> {
  factory $AuthenticationAuthenticatedStateCopyWith(AuthenticationAuthenticatedState value, $Res Function(AuthenticationAuthenticatedState) _then) = _$AuthenticationAuthenticatedStateCopyWithImpl;
@useResult
$Res call({
 User user
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$AuthenticationAuthenticatedStateCopyWithImpl<$Res>
    implements $AuthenticationAuthenticatedStateCopyWith<$Res> {
  _$AuthenticationAuthenticatedStateCopyWithImpl(this._self, this._then);

  final AuthenticationAuthenticatedState _self;
  final $Res Function(AuthenticationAuthenticatedState) _then;

/// Create a copy of AuthenticationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(AuthenticationAuthenticatedState(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,
  ));
}

/// Create a copy of AuthenticationState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
