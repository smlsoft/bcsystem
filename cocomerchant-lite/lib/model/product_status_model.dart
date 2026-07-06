import 'package:json_annotation/json_annotation.dart';

part 'product_status_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductStatusModel {
  // สถานะสินค้า
  final String shopid;
  final String barcode;
  final String productname;
  final String unitcode;
  double totalquantity;
  double totalamount;

  ProductStatusModel({
    required this.shopid,
    required this.barcode,
    required this.unitcode,
    required this.productname,
    required this.totalquantity,
    required this.totalamount,
  });

  factory ProductStatusModel.fromJson(Map<String, dynamic> json) => _$ProductStatusModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductStatusModelToJson(this);
}
