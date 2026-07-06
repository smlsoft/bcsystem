import 'package:json_annotation/json_annotation.dart';

part 'staff_order_model.g.dart';

@JsonSerializable(explicitToJson: true)
class StaffOrderModel {
  String tableNumber;
  String barcode;
  String qty;
  double amount;

  StaffOrderModel({
    required this.tableNumber,
    required this.barcode,
    required this.qty,
    required this.amount,
  });

  factory StaffOrderModel.fromJson(Map<String, dynamic> json) =>
      _$StaffOrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$StaffOrderModelToJson(this);
}
