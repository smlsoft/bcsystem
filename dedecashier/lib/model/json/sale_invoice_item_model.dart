import 'package:json_annotation/json_annotation.dart';

part 'sale_invoice_item_model.g.dart';

@JsonSerializable()
class SaleInvoiceItemModel {
  int linenumber;

  String itemcode;
  String itemguid;
  String itemsku;
  String barcode;
  String name1;
  String name2;
  String name3;
  String name4;
  String name5;
  String itemunitcode;
  String itemunitdiv;
  String itemunitstd;
  String category;
  double price;
  double qty;
  String discounttext;
  double discountamount;
  double amount;

  SaleInvoiceItemModel({
    required this.linenumber,
    required this.itemcode,
    required this.itemguid,
    required this.itemsku,
    required this.barcode,
    required this.name1,
    required this.name2,
    required this.name3,
    required this.name4,
    required this.name5,
    required this.itemunitcode,
    required this.itemunitdiv,
    required this.itemunitstd,
    required this.category,
    required this.price,
    required this.qty,
    required this.discounttext,
    required this.discountamount,
    required this.amount,
  });

  factory SaleInvoiceItemModel.fromJson(Map<String, dynamic> json) =>
      _$SaleInvoiceItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleInvoiceItemModelToJson(this);
}
