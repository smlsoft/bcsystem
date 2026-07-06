import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop.freezed.dart';
part 'shop.g.dart';

@freezed
abstract class Shop with _$Shop {
  const factory Shop({
    @Default('') String shopid,
    @Default('') String guidfixed,
    @Default('') String name,
    @Default('') String name1,
    @Default('') String branchcode,
    @Default(0) int role,
    @Default(false) bool isfavorite,
    @Default('') String lastaccessedat,
  }) = _Shop;

  factory Shop.fromJson(Map<String, dynamic> json) => _$ShopFromJson(json);
}
