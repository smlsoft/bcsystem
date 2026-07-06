import 'package:json_annotation/json_annotation.dart';

part 'transfer_payment_model.g.dart';

@JsonSerializable()
class TransferPaymentModel {
  String bankcode;
  double amount;

  TransferPaymentModel({
    required this.bankcode,
    required this.amount,
  });

  factory TransferPaymentModel.fromJson(Map<String, dynamic> json) =>
      _$TransferPaymentModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransferPaymentModelToJson(this);
}
