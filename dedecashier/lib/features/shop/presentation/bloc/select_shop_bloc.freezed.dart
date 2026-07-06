// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'select_shop_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SelectShopEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectShopEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SelectShopEvent()';
}


}

/// @nodoc
class $SelectShopEventCopyWith<$Res>  {
$SelectShopEventCopyWith(SelectShopEvent _, $Res Function(SelectShopEvent) __);
}


/// Adds pattern-matching-related methods to [SelectShopEvent].
extension SelectShopEventPatterns on SelectShopEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SelectShopStarted value)?  onSelectShopStarted,TResult Function( ShopSelectSubmit value)?  onShopSelectSubmit,TResult Function( SelectShopRefresh value)?  onSelectShopRefresh,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SelectShopStarted() when onSelectShopStarted != null:
return onSelectShopStarted(_that);case ShopSelectSubmit() when onShopSelectSubmit != null:
return onShopSelectSubmit(_that);case SelectShopRefresh() when onSelectShopRefresh != null:
return onSelectShopRefresh(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SelectShopStarted value)  onSelectShopStarted,required TResult Function( ShopSelectSubmit value)  onShopSelectSubmit,required TResult Function( SelectShopRefresh value)  onSelectShopRefresh,}){
final _that = this;
switch (_that) {
case SelectShopStarted():
return onSelectShopStarted(_that);case ShopSelectSubmit():
return onShopSelectSubmit(_that);case SelectShopRefresh():
return onSelectShopRefresh(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SelectShopStarted value)?  onSelectShopStarted,TResult? Function( ShopSelectSubmit value)?  onShopSelectSubmit,TResult? Function( SelectShopRefresh value)?  onSelectShopRefresh,}){
final _that = this;
switch (_that) {
case SelectShopStarted() when onSelectShopStarted != null:
return onSelectShopStarted(_that);case ShopSelectSubmit() when onShopSelectSubmit != null:
return onShopSelectSubmit(_that);case SelectShopRefresh() when onSelectShopRefresh != null:
return onSelectShopRefresh(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  onSelectShopStarted,TResult Function( Shop shop)?  onShopSelectSubmit,TResult Function( Shop shop)?  onSelectShopRefresh,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SelectShopStarted() when onSelectShopStarted != null:
return onSelectShopStarted();case ShopSelectSubmit() when onShopSelectSubmit != null:
return onShopSelectSubmit(_that.shop);case SelectShopRefresh() when onSelectShopRefresh != null:
return onSelectShopRefresh(_that.shop);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  onSelectShopStarted,required TResult Function( Shop shop)  onShopSelectSubmit,required TResult Function( Shop shop)  onSelectShopRefresh,}) {final _that = this;
switch (_that) {
case SelectShopStarted():
return onSelectShopStarted();case ShopSelectSubmit():
return onShopSelectSubmit(_that.shop);case SelectShopRefresh():
return onSelectShopRefresh(_that.shop);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  onSelectShopStarted,TResult? Function( Shop shop)?  onShopSelectSubmit,TResult? Function( Shop shop)?  onSelectShopRefresh,}) {final _that = this;
switch (_that) {
case SelectShopStarted() when onSelectShopStarted != null:
return onSelectShopStarted();case ShopSelectSubmit() when onShopSelectSubmit != null:
return onShopSelectSubmit(_that.shop);case SelectShopRefresh() when onSelectShopRefresh != null:
return onSelectShopRefresh(_that.shop);case _:
  return null;

}
}

}

/// @nodoc


class SelectShopStarted implements SelectShopEvent {
  const SelectShopStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectShopStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SelectShopEvent.onSelectShopStarted()';
}


}




/// @nodoc


class ShopSelectSubmit implements SelectShopEvent {
  const ShopSelectSubmit({required this.shop});
  

 final  Shop shop;

/// Create a copy of SelectShopEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopSelectSubmitCopyWith<ShopSelectSubmit> get copyWith => _$ShopSelectSubmitCopyWithImpl<ShopSelectSubmit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopSelectSubmit&&(identical(other.shop, shop) || other.shop == shop));
}


@override
int get hashCode => Object.hash(runtimeType,shop);

@override
String toString() {
  return 'SelectShopEvent.onShopSelectSubmit(shop: $shop)';
}


}

/// @nodoc
abstract mixin class $ShopSelectSubmitCopyWith<$Res> implements $SelectShopEventCopyWith<$Res> {
  factory $ShopSelectSubmitCopyWith(ShopSelectSubmit value, $Res Function(ShopSelectSubmit) _then) = _$ShopSelectSubmitCopyWithImpl;
@useResult
$Res call({
 Shop shop
});


$ShopCopyWith<$Res> get shop;

}
/// @nodoc
class _$ShopSelectSubmitCopyWithImpl<$Res>
    implements $ShopSelectSubmitCopyWith<$Res> {
  _$ShopSelectSubmitCopyWithImpl(this._self, this._then);

  final ShopSelectSubmit _self;
  final $Res Function(ShopSelectSubmit) _then;

/// Create a copy of SelectShopEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shop = null,}) {
  return _then(ShopSelectSubmit(
shop: null == shop ? _self.shop : shop // ignore: cast_nullable_to_non_nullable
as Shop,
  ));
}

/// Create a copy of SelectShopEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShopCopyWith<$Res> get shop {
  
  return $ShopCopyWith<$Res>(_self.shop, (value) {
    return _then(_self.copyWith(shop: value));
  });
}
}

/// @nodoc


class SelectShopRefresh implements SelectShopEvent {
  const SelectShopRefresh({required this.shop});
  

 final  Shop shop;

/// Create a copy of SelectShopEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectShopRefreshCopyWith<SelectShopRefresh> get copyWith => _$SelectShopRefreshCopyWithImpl<SelectShopRefresh>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectShopRefresh&&(identical(other.shop, shop) || other.shop == shop));
}


@override
int get hashCode => Object.hash(runtimeType,shop);

@override
String toString() {
  return 'SelectShopEvent.onSelectShopRefresh(shop: $shop)';
}


}

/// @nodoc
abstract mixin class $SelectShopRefreshCopyWith<$Res> implements $SelectShopEventCopyWith<$Res> {
  factory $SelectShopRefreshCopyWith(SelectShopRefresh value, $Res Function(SelectShopRefresh) _then) = _$SelectShopRefreshCopyWithImpl;
@useResult
$Res call({
 Shop shop
});


$ShopCopyWith<$Res> get shop;

}
/// @nodoc
class _$SelectShopRefreshCopyWithImpl<$Res>
    implements $SelectShopRefreshCopyWith<$Res> {
  _$SelectShopRefreshCopyWithImpl(this._self, this._then);

  final SelectShopRefresh _self;
  final $Res Function(SelectShopRefresh) _then;

/// Create a copy of SelectShopEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shop = null,}) {
  return _then(SelectShopRefresh(
shop: null == shop ? _self.shop : shop // ignore: cast_nullable_to_non_nullable
as Shop,
  ));
}

/// Create a copy of SelectShopEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShopCopyWith<$Res> get shop {
  
  return $ShopCopyWith<$Res>(_self.shop, (value) {
    return _then(_self.copyWith(shop: value));
  });
}
}

/// @nodoc
mixin _$SelectShopState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectShopState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SelectShopState()';
}


}

/// @nodoc
class $SelectShopStateCopyWith<$Res>  {
$SelectShopStateCopyWith(SelectShopState _, $Res Function(SelectShopState) __);
}


/// Adds pattern-matching-related methods to [SelectShopState].
extension SelectShopStatePatterns on SelectShopState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SelectShopInitialState value)?  initial,TResult Function( SelectShopLoadingState value)?  loading,TResult Function( SelectShopBlocErrorState value)?  error,TResult Function( SelectShopLoadedState value)?  loaded,TResult Function( SelectShopSubmitSuccessState value)?  selected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SelectShopInitialState() when initial != null:
return initial(_that);case SelectShopLoadingState() when loading != null:
return loading(_that);case SelectShopBlocErrorState() when error != null:
return error(_that);case SelectShopLoadedState() when loaded != null:
return loaded(_that);case SelectShopSubmitSuccessState() when selected != null:
return selected(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SelectShopInitialState value)  initial,required TResult Function( SelectShopLoadingState value)  loading,required TResult Function( SelectShopBlocErrorState value)  error,required TResult Function( SelectShopLoadedState value)  loaded,required TResult Function( SelectShopSubmitSuccessState value)  selected,}){
final _that = this;
switch (_that) {
case SelectShopInitialState():
return initial(_that);case SelectShopLoadingState():
return loading(_that);case SelectShopBlocErrorState():
return error(_that);case SelectShopLoadedState():
return loaded(_that);case SelectShopSubmitSuccessState():
return selected(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SelectShopInitialState value)?  initial,TResult? Function( SelectShopLoadingState value)?  loading,TResult? Function( SelectShopBlocErrorState value)?  error,TResult? Function( SelectShopLoadedState value)?  loaded,TResult? Function( SelectShopSubmitSuccessState value)?  selected,}){
final _that = this;
switch (_that) {
case SelectShopInitialState() when initial != null:
return initial(_that);case SelectShopLoadingState() when loading != null:
return loading(_that);case SelectShopBlocErrorState() when error != null:
return error(_that);case SelectShopLoadedState() when loaded != null:
return loaded(_that);case SelectShopSubmitSuccessState() when selected != null:
return selected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String message)?  error,TResult Function( List<ShopUser> shops)?  loaded,TResult Function( Shop shop)?  selected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SelectShopInitialState() when initial != null:
return initial();case SelectShopLoadingState() when loading != null:
return loading();case SelectShopBlocErrorState() when error != null:
return error(_that.message);case SelectShopLoadedState() when loaded != null:
return loaded(_that.shops);case SelectShopSubmitSuccessState() when selected != null:
return selected(_that.shop);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String message)  error,required TResult Function( List<ShopUser> shops)  loaded,required TResult Function( Shop shop)  selected,}) {final _that = this;
switch (_that) {
case SelectShopInitialState():
return initial();case SelectShopLoadingState():
return loading();case SelectShopBlocErrorState():
return error(_that.message);case SelectShopLoadedState():
return loaded(_that.shops);case SelectShopSubmitSuccessState():
return selected(_that.shop);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String message)?  error,TResult? Function( List<ShopUser> shops)?  loaded,TResult? Function( Shop shop)?  selected,}) {final _that = this;
switch (_that) {
case SelectShopInitialState() when initial != null:
return initial();case SelectShopLoadingState() when loading != null:
return loading();case SelectShopBlocErrorState() when error != null:
return error(_that.message);case SelectShopLoadedState() when loaded != null:
return loaded(_that.shops);case SelectShopSubmitSuccessState() when selected != null:
return selected(_that.shop);case _:
  return null;

}
}

}

/// @nodoc


class SelectShopInitialState implements SelectShopState {
  const SelectShopInitialState();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectShopInitialState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SelectShopState.initial()';
}


}




/// @nodoc


class SelectShopLoadingState implements SelectShopState {
  const SelectShopLoadingState();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectShopLoadingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SelectShopState.loading()';
}


}




/// @nodoc


class SelectShopBlocErrorState implements SelectShopState {
  const SelectShopBlocErrorState(this.message);
  

 final  String message;

/// Create a copy of SelectShopState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectShopBlocErrorStateCopyWith<SelectShopBlocErrorState> get copyWith => _$SelectShopBlocErrorStateCopyWithImpl<SelectShopBlocErrorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectShopBlocErrorState&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SelectShopState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $SelectShopBlocErrorStateCopyWith<$Res> implements $SelectShopStateCopyWith<$Res> {
  factory $SelectShopBlocErrorStateCopyWith(SelectShopBlocErrorState value, $Res Function(SelectShopBlocErrorState) _then) = _$SelectShopBlocErrorStateCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SelectShopBlocErrorStateCopyWithImpl<$Res>
    implements $SelectShopBlocErrorStateCopyWith<$Res> {
  _$SelectShopBlocErrorStateCopyWithImpl(this._self, this._then);

  final SelectShopBlocErrorState _self;
  final $Res Function(SelectShopBlocErrorState) _then;

/// Create a copy of SelectShopState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SelectShopBlocErrorState(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SelectShopLoadedState implements SelectShopState {
  const SelectShopLoadedState(final  List<ShopUser> shops): _shops = shops;
  

 final  List<ShopUser> _shops;
 List<ShopUser> get shops {
  if (_shops is EqualUnmodifiableListView) return _shops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shops);
}


/// Create a copy of SelectShopState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectShopLoadedStateCopyWith<SelectShopLoadedState> get copyWith => _$SelectShopLoadedStateCopyWithImpl<SelectShopLoadedState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectShopLoadedState&&const DeepCollectionEquality().equals(other._shops, _shops));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_shops));

@override
String toString() {
  return 'SelectShopState.loaded(shops: $shops)';
}


}

/// @nodoc
abstract mixin class $SelectShopLoadedStateCopyWith<$Res> implements $SelectShopStateCopyWith<$Res> {
  factory $SelectShopLoadedStateCopyWith(SelectShopLoadedState value, $Res Function(SelectShopLoadedState) _then) = _$SelectShopLoadedStateCopyWithImpl;
@useResult
$Res call({
 List<ShopUser> shops
});




}
/// @nodoc
class _$SelectShopLoadedStateCopyWithImpl<$Res>
    implements $SelectShopLoadedStateCopyWith<$Res> {
  _$SelectShopLoadedStateCopyWithImpl(this._self, this._then);

  final SelectShopLoadedState _self;
  final $Res Function(SelectShopLoadedState) _then;

/// Create a copy of SelectShopState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shops = null,}) {
  return _then(SelectShopLoadedState(
null == shops ? _self._shops : shops // ignore: cast_nullable_to_non_nullable
as List<ShopUser>,
  ));
}


}

/// @nodoc


class SelectShopSubmitSuccessState implements SelectShopState {
  const SelectShopSubmitSuccessState(this.shop);
  

 final  Shop shop;

/// Create a copy of SelectShopState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectShopSubmitSuccessStateCopyWith<SelectShopSubmitSuccessState> get copyWith => _$SelectShopSubmitSuccessStateCopyWithImpl<SelectShopSubmitSuccessState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectShopSubmitSuccessState&&(identical(other.shop, shop) || other.shop == shop));
}


@override
int get hashCode => Object.hash(runtimeType,shop);

@override
String toString() {
  return 'SelectShopState.selected(shop: $shop)';
}


}

/// @nodoc
abstract mixin class $SelectShopSubmitSuccessStateCopyWith<$Res> implements $SelectShopStateCopyWith<$Res> {
  factory $SelectShopSubmitSuccessStateCopyWith(SelectShopSubmitSuccessState value, $Res Function(SelectShopSubmitSuccessState) _then) = _$SelectShopSubmitSuccessStateCopyWithImpl;
@useResult
$Res call({
 Shop shop
});


$ShopCopyWith<$Res> get shop;

}
/// @nodoc
class _$SelectShopSubmitSuccessStateCopyWithImpl<$Res>
    implements $SelectShopSubmitSuccessStateCopyWith<$Res> {
  _$SelectShopSubmitSuccessStateCopyWithImpl(this._self, this._then);

  final SelectShopSubmitSuccessState _self;
  final $Res Function(SelectShopSubmitSuccessState) _then;

/// Create a copy of SelectShopState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shop = null,}) {
  return _then(SelectShopSubmitSuccessState(
null == shop ? _self.shop : shop // ignore: cast_nullable_to_non_nullable
as Shop,
  ));
}

/// Create a copy of SelectShopState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShopCopyWith<$Res> get shop {
  
  return $ShopCopyWith<$Res>(_self.shop, (value) {
    return _then(_self.copyWith(shop: value));
  });
}
}

// dart format on
