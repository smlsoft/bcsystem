import 'package:json_annotation/json_annotation.dart';

part 'point_transaction_model.g.dart';

@JsonSerializable(explicitToJson: true)
class PointTransactionModel {
  String guidfixed;
  String transactiondocno;
  DateTime transactiondate;
  String debtorcode;
  String pointscode;
  int transactiontype; // 1 = earned, 2 = redeemed
  int pointamount;
  int balancebefore;
  int balanceafter;
  String description;

  PointTransactionModel({
    required this.guidfixed,
    required this.transactiondocno,
    required this.transactiondate,
    required this.debtorcode,
    required this.pointscode,
    required this.transactiontype,
    required this.pointamount,
    required this.balancebefore,
    required this.balanceafter,
    required this.description,
  });

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) => _$PointTransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$PointTransactionModelToJson(this);
}
