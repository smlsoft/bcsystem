// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShopUser {

 String get shopid; String get name; String get branchcode; int get role; bool get isfavorite; String get lastaccessedat;
/// Create a copy of ShopUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopUserCopyWith<ShopUser> get copyWith => _$ShopUserCopyWithImpl<ShopUser>(this as ShopUser, _$identity);

  /// Serializes this ShopUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopUser&&(identical(other.shopid, shopid) || other.shopid == shopid)&&(identical(other.name, name) || other.name == name)&&(identical(other.branchcode, branchcode) || other.branchcode == branchcode)&&(identical(other.role, role) || other.role == role)&&(identical(other.isfavorite, isfavorite) || other.isfavorite == isfavorite)&&(identical(other.lastaccessedat, lastaccessedat) || other.lastaccessedat == lastaccessedat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shopid,name,branchcode,role,isfavorite,lastaccessedat);

@override
String toString() {
  return 'ShopUser(shopid: $shopid, name: $name, branchcode: $branchcode, role: $role, isfavorite: $isfavorite, lastaccessedat: $lastaccessedat)';
}


}

/// @nodoc
abstract mixin class $ShopUserCopyWith<$Res>  {
  factory $ShopUserCopyWith(ShopUser value, $Res Function(ShopUser) _then) = _$ShopUserCopyWithImpl;
@useResult
$Res call({
 String shopid, String name, String branchcode, int role, bool isfavorite, String lastaccessedat
});




}
/// @nodoc
class _$ShopUserCopyWithImpl<$Res>
    implements $ShopUserCopyWith<$Res> {
  _$ShopUserCopyWithImpl(this._self, this._then);

  final ShopUser _self;
  final $Res Function(ShopUser) _then;

/// Create a copy of ShopUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shopid = null,Object? name = null,Object? branchcode = null,Object? role = null,Object? isfavorite = null,Object? lastaccessedat = null,}) {
  return _then(_self.copyWith(
shopid: null == shopid ? _self.shopid : shopid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,branchcode: null == branchcode ? _self.branchcode : branchcode // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as int,isfavorite: null == isfavorite ? _self.isfavorite : isfavorite // ignore: cast_nullable_to_non_nullable
as bool,lastaccessedat: null == lastaccessedat ? _self.lastaccessedat : lastaccessedat // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ShopUser].
extension ShopUserPatterns on ShopUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopUser() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopUser value)  $default,){
final _that = this;
switch (_that) {
case _ShopUser():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopUser value)?  $default,){
final _that = this;
switch (_that) {
case _ShopUser() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String shopid,  String name,  String branchcode,  int role,  bool isfavorite,  String lastaccessedat)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopUser() when $default != null:
return $default(_that.shopid,_that.name,_that.branchcode,_that.role,_that.isfavorite,_that.lastaccessedat);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String shopid,  String name,  String branchcode,  int role,  bool isfavorite,  String lastaccessedat)  $default,) {final _that = this;
switch (_that) {
case _ShopUser():
return $default(_that.shopid,_that.name,_that.branchcode,_that.role,_that.isfavorite,_that.lastaccessedat);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String shopid,  String name,  String branchcode,  int role,  bool isfavorite,  String lastaccessedat)?  $default,) {final _that = this;
switch (_that) {
case _ShopUser() when $default != null:
return $default(_that.shopid,_that.name,_that.branchcode,_that.role,_that.isfavorite,_that.lastaccessedat);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShopUser extends ShopUser {
  const _ShopUser({this.shopid = '', this.name = '', this.branchcode = '', this.role = 0, this.isfavorite = false, this.lastaccessedat = ''}): super._();
  factory _ShopUser.fromJson(Map<String, dynamic> json) => _$ShopUserFromJson(json);

@override@JsonKey() final  String shopid;
@override@JsonKey() final  String name;
@override@JsonKey() final  String branchcode;
@override@JsonKey() final  int role;
@override@JsonKey() final  bool isfavorite;
@override@JsonKey() final  String lastaccessedat;

/// Create a copy of ShopUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopUserCopyWith<_ShopUser> get copyWith => __$ShopUserCopyWithImpl<_ShopUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShopUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopUser&&(identical(other.shopid, shopid) || other.shopid == shopid)&&(identical(other.name, name) || other.name == name)&&(identical(other.branchcode, branchcode) || other.branchcode == branchcode)&&(identical(other.role, role) || other.role == role)&&(identical(other.isfavorite, isfavorite) || other.isfavorite == isfavorite)&&(identical(other.lastaccessedat, lastaccessedat) || other.lastaccessedat == lastaccessedat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shopid,name,branchcode,role,isfavorite,lastaccessedat);

@override
String toString() {
  return 'ShopUser(shopid: $shopid, name: $name, branchcode: $branchcode, role: $role, isfavorite: $isfavorite, lastaccessedat: $lastaccessedat)';
}


}

/// @nodoc
abstract mixin class _$ShopUserCopyWith<$Res> implements $ShopUserCopyWith<$Res> {
  factory _$ShopUserCopyWith(_ShopUser value, $Res Function(_ShopUser) _then) = __$ShopUserCopyWithImpl;
@override @useResult
$Res call({
 String shopid, String name, String branchcode, int role, bool isfavorite, String lastaccessedat
});




}
/// @nodoc
class __$ShopUserCopyWithImpl<$Res>
    implements _$ShopUserCopyWith<$Res> {
  __$ShopUserCopyWithImpl(this._self, this._then);

  final _ShopUser _self;
  final $Res Function(_ShopUser) _then;

/// Create a copy of ShopUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shopid = null,Object? name = null,Object? branchcode = null,Object? role = null,Object? isfavorite = null,Object? lastaccessedat = null,}) {
  return _then(_ShopUser(
shopid: null == shopid ? _self.shopid : shopid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,branchcode: null == branchcode ? _self.branchcode : branchcode // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as int,isfavorite: null == isfavorite ? _self.isfavorite : isfavorite // ignore: cast_nullable_to_non_nullable
as bool,lastaccessedat: null == lastaccessedat ? _self.lastaccessedat : lastaccessedat // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
