// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Shop {

 String get shopid; String get guidfixed; String get name; String get name1; String get branchcode; int get role; bool get isfavorite; String get lastaccessedat;
/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopCopyWith<Shop> get copyWith => _$ShopCopyWithImpl<Shop>(this as Shop, _$identity);

  /// Serializes this Shop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Shop&&(identical(other.shopid, shopid) || other.shopid == shopid)&&(identical(other.guidfixed, guidfixed) || other.guidfixed == guidfixed)&&(identical(other.name, name) || other.name == name)&&(identical(other.name1, name1) || other.name1 == name1)&&(identical(other.branchcode, branchcode) || other.branchcode == branchcode)&&(identical(other.role, role) || other.role == role)&&(identical(other.isfavorite, isfavorite) || other.isfavorite == isfavorite)&&(identical(other.lastaccessedat, lastaccessedat) || other.lastaccessedat == lastaccessedat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shopid,guidfixed,name,name1,branchcode,role,isfavorite,lastaccessedat);

@override
String toString() {
  return 'Shop(shopid: $shopid, guidfixed: $guidfixed, name: $name, name1: $name1, branchcode: $branchcode, role: $role, isfavorite: $isfavorite, lastaccessedat: $lastaccessedat)';
}


}

/// @nodoc
abstract mixin class $ShopCopyWith<$Res>  {
  factory $ShopCopyWith(Shop value, $Res Function(Shop) _then) = _$ShopCopyWithImpl;
@useResult
$Res call({
 String shopid, String guidfixed, String name, String name1, String branchcode, int role, bool isfavorite, String lastaccessedat
});




}
/// @nodoc
class _$ShopCopyWithImpl<$Res>
    implements $ShopCopyWith<$Res> {
  _$ShopCopyWithImpl(this._self, this._then);

  final Shop _self;
  final $Res Function(Shop) _then;

/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shopid = null,Object? guidfixed = null,Object? name = null,Object? name1 = null,Object? branchcode = null,Object? role = null,Object? isfavorite = null,Object? lastaccessedat = null,}) {
  return _then(_self.copyWith(
shopid: null == shopid ? _self.shopid : shopid // ignore: cast_nullable_to_non_nullable
as String,guidfixed: null == guidfixed ? _self.guidfixed : guidfixed // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,name1: null == name1 ? _self.name1 : name1 // ignore: cast_nullable_to_non_nullable
as String,branchcode: null == branchcode ? _self.branchcode : branchcode // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as int,isfavorite: null == isfavorite ? _self.isfavorite : isfavorite // ignore: cast_nullable_to_non_nullable
as bool,lastaccessedat: null == lastaccessedat ? _self.lastaccessedat : lastaccessedat // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Shop].
extension ShopPatterns on Shop {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Shop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Shop() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Shop value)  $default,){
final _that = this;
switch (_that) {
case _Shop():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Shop value)?  $default,){
final _that = this;
switch (_that) {
case _Shop() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String shopid,  String guidfixed,  String name,  String name1,  String branchcode,  int role,  bool isfavorite,  String lastaccessedat)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Shop() when $default != null:
return $default(_that.shopid,_that.guidfixed,_that.name,_that.name1,_that.branchcode,_that.role,_that.isfavorite,_that.lastaccessedat);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String shopid,  String guidfixed,  String name,  String name1,  String branchcode,  int role,  bool isfavorite,  String lastaccessedat)  $default,) {final _that = this;
switch (_that) {
case _Shop():
return $default(_that.shopid,_that.guidfixed,_that.name,_that.name1,_that.branchcode,_that.role,_that.isfavorite,_that.lastaccessedat);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String shopid,  String guidfixed,  String name,  String name1,  String branchcode,  int role,  bool isfavorite,  String lastaccessedat)?  $default,) {final _that = this;
switch (_that) {
case _Shop() when $default != null:
return $default(_that.shopid,_that.guidfixed,_that.name,_that.name1,_that.branchcode,_that.role,_that.isfavorite,_that.lastaccessedat);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Shop implements Shop {
  const _Shop({this.shopid = '', this.guidfixed = '', this.name = '', this.name1 = '', this.branchcode = '', this.role = 0, this.isfavorite = false, this.lastaccessedat = ''});
  factory _Shop.fromJson(Map<String, dynamic> json) => _$ShopFromJson(json);

@override@JsonKey() final  String shopid;
@override@JsonKey() final  String guidfixed;
@override@JsonKey() final  String name;
@override@JsonKey() final  String name1;
@override@JsonKey() final  String branchcode;
@override@JsonKey() final  int role;
@override@JsonKey() final  bool isfavorite;
@override@JsonKey() final  String lastaccessedat;

/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopCopyWith<_Shop> get copyWith => __$ShopCopyWithImpl<_Shop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShopToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Shop&&(identical(other.shopid, shopid) || other.shopid == shopid)&&(identical(other.guidfixed, guidfixed) || other.guidfixed == guidfixed)&&(identical(other.name, name) || other.name == name)&&(identical(other.name1, name1) || other.name1 == name1)&&(identical(other.branchcode, branchcode) || other.branchcode == branchcode)&&(identical(other.role, role) || other.role == role)&&(identical(other.isfavorite, isfavorite) || other.isfavorite == isfavorite)&&(identical(other.lastaccessedat, lastaccessedat) || other.lastaccessedat == lastaccessedat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shopid,guidfixed,name,name1,branchcode,role,isfavorite,lastaccessedat);

@override
String toString() {
  return 'Shop(shopid: $shopid, guidfixed: $guidfixed, name: $name, name1: $name1, branchcode: $branchcode, role: $role, isfavorite: $isfavorite, lastaccessedat: $lastaccessedat)';
}


}

/// @nodoc
abstract mixin class _$ShopCopyWith<$Res> implements $ShopCopyWith<$Res> {
  factory _$ShopCopyWith(_Shop value, $Res Function(_Shop) _then) = __$ShopCopyWithImpl;
@override @useResult
$Res call({
 String shopid, String guidfixed, String name, String name1, String branchcode, int role, bool isfavorite, String lastaccessedat
});




}
/// @nodoc
class __$ShopCopyWithImpl<$Res>
    implements _$ShopCopyWith<$Res> {
  __$ShopCopyWithImpl(this._self, this._then);

  final _Shop _self;
  final $Res Function(_Shop) _then;

/// Create a copy of Shop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shopid = null,Object? guidfixed = null,Object? name = null,Object? name1 = null,Object? branchcode = null,Object? role = null,Object? isfavorite = null,Object? lastaccessedat = null,}) {
  return _then(_Shop(
shopid: null == shopid ? _self.shopid : shopid // ignore: cast_nullable_to_non_nullable
as String,guidfixed: null == guidfixed ? _self.guidfixed : guidfixed // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,name1: null == name1 ? _self.name1 : name1 // ignore: cast_nullable_to_non_nullable
as String,branchcode: null == branchcode ? _self.branchcode : branchcode // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as int,isfavorite: null == isfavorite ? _self.isfavorite : isfavorite // ignore: cast_nullable_to_non_nullable
as bool,lastaccessedat: null == lastaccessedat ? _self.lastaccessedat : lastaccessedat // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
