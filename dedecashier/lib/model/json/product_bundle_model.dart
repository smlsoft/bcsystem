// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'product_bundle_model.g.dart';

@JsonSerializable()
class ProductBundleModel {
  late String main_barcode;
  late String bundle_barcode;
  late double price;

  ProductBundleModel(
      {required this.main_barcode,
      required this.bundle_barcode,
      this.price = 0});

  factory ProductBundleModel.fromJson(Map<String, dynamic> json) =>
      _$ProductBundleModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductBundleModelToJson(this);

  /*ProductBundleStruct.map(dynamic obj) {
    mainBarcode = obj["main_barcode"];
    bundleBarcode = obj["bundle_barcode"];
    price = double.parse(obj["price"].toString());
  }

  Map<String, dynamic> toMap() {
    var _map = <String, dynamic>{};

    _map["main_barcode"] = mainBarcode;
    _map["bundle_barcode"] = bundleBarcode;
    _map["price"] = price;

    return _map;
  }*/
}
