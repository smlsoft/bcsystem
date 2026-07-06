import 'package:freezed_annotation/freezed_annotation.dart';

import 'shop.dart';

part 'shop_user.freezed.dart';
part 'shop_user.g.dart';

@freezed
class ShopUser with _$ShopUser {
  const ShopUser._();
  const factory ShopUser({
    @Default('') String shopid,
    @Default('') String name,
    @Default('') String branchcode,
    @Default(0) int role,
    @Default(false) bool isfavorite,
    @Default('') String lastaccessedat,
  }) = _ShopUser;

  factory ShopUser.fromJson(Map<String, dynamic> json) => _$ShopUserFromJson(json);

  Shop get toShop {
    return Shop(guidfixed: shopid, name1: name, name: name, branchcode: branchcode);
  }

  @override
  // TODO: implement branchcode
  String get branchcode => throw UnimplementedError();

  @override
  // TODO: implement isfavorite
  bool get isfavorite => throw UnimplementedError();

  @override
  // TODO: implement lastaccessedat
  String get lastaccessedat => throw UnimplementedError();

  @override
  // TODO: implement name
  String get name => throw UnimplementedError();

  @override
  // TODO: implement role
  int get role => throw UnimplementedError();

  @override
  // TODO: implement shopid
  String get shopid => throw UnimplementedError();

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
