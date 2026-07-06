import 'package:json_annotation/json_annotation.dart';
part 'order_pay_process_model.g.dart';

@JsonSerializable(explicitToJson: true)
class OrderPayProcessModel {
  final String shopid;
  final String transid;
  final String tablenumber;
  final String transguid;
  final int paysuccess;
  final double totalamount;
  final String orderguid;
  final int wallettype;

  OrderPayProcessModel({
    required this.shopid,
    required this.transid,
    required this.tablenumber,
    required this.transguid,
    required this.paysuccess,
    required this.totalamount,
    required this.orderguid,
    required this.wallettype,
  });

  factory OrderPayProcessModel.fromJson(Map<String, dynamic> json) =>
      _$OrderPayProcessModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderPayProcessModelToJson(this);
}
