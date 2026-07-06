import 'dart:convert';

import 'package:cocomerchant_lite/model/sale_daily_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sale_daily_list_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SaleDailyListModel {
  final String shopid;
  final String branchid;
  final DateTime docdatetime;
  final String docno;
  final double totalamount;
  final double sumpayamount;
  final double paycashamount;
  final double paycashchange;
  final double roundamount;
  final List<SaleDailyPaymentModel> paymentlist;
  final double sumpaymentlist;

  SaleDailyListModel({
    required this.shopid,
    required this.branchid,
    required this.docdatetime,
    required this.docno,
    required this.totalamount,
    required this.sumpayamount,
    required this.paycashamount,
    required this.paycashchange,
    required this.roundamount,
    required this.paymentlist,
    required this.sumpaymentlist,
  });

  factory SaleDailyListModel.fromJson(Map<String, dynamic> json) => _$SaleDailyListModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleDailyListModelToJson(this);
}
