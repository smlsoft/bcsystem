import 'package:json_annotation/json_annotation.dart';

part 'payment_model.g.dart';

@JsonSerializable()
class PaymentModel {
  double cash;
  double creditcard;
  double transfer;
  List<String> creditcarddetails = <String>[];
  List<String> transferdetails = <String>[];
  PaymentModel({
    required this.cash,
    required this.creditcard,
    required this.creditcarddetails,
    required this.transfer,
    required this.transferdetails,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentModelToJson(this);
}
