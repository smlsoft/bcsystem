import 'package:json_annotation/json_annotation.dart';

part 'payment_request.g.dart';

@JsonSerializable()
class PaymentGenQRRequest {
  String order_id;
  int merchant_id;
  int pos_id;
  String customer_name;
  String title;
  int table_number;
  String status;
  String ref1;
  String ref2;
  String category;
  double amount;
  double discount_amt;
  double total;
  int created_id;
  int updated_id;
  String pos_created_date;

  PaymentGenQRRequest({
    required this.order_id,
    int? merchant_id,
    int? pos_id,
    String? customer_name,
    String? title,
    int? table_number,
    String? status,
    String? ref1,
    String? ref2,
    String? category,
    double? amount,
    double? discount_amt,
    double? total,
    int? created_id,
    int? updated_id,
    String? pos_created_date,
  })  : merchant_id = merchant_id ?? 0,
        pos_id = pos_id ?? 0,
        customer_name = customer_name ?? "",
        title = title ?? "",
        table_number = table_number ?? 0,
        status = status ?? "",
        ref1 = ref1 ?? "",
        ref2 = ref2 ?? "",
        category = category ?? "",
        amount = amount ?? 0.0,
        discount_amt = discount_amt ?? 0.0,
        total = total ?? 0.0,
        created_id = created_id ?? 1,
        updated_id = updated_id ?? 1,
        pos_created_date = pos_created_date ?? "";

  Map<String, dynamic> toJson() => _$PaymentGenQRRequestToJson(this);
  factory PaymentGenQRRequest.fromJson(Map<String, dynamic> json) => _$PaymentGenQRRequestFromJson(json);
}
