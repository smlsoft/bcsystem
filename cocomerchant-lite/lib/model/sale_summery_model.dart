import 'package:json_annotation/json_annotation.dart';

part 'sale_summery_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SaleSummeryModel {
  // รายการขายรายวัน
  final String shopid;
  final String docdate;
  final double totalamount;

  SaleSummeryModel({
    required this.shopid,
    required this.docdate,
    required this.totalamount,
  });

  factory SaleSummeryModel.fromJson(Map<String, dynamic> json) =>
      _$SaleSummeryModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleSummeryModelToJson(this);
}
