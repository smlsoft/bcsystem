import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gb_inquiry_txn.g.dart';

@JsonSerializable()
class GBInquiryTxn {
  final String referenceNo;
  final String gbpReferenceNo;
  final Decimal amount;
  String? status;
  String? paymentType;
  String? merchantDefined1;
  String? merchantDefined2;
  String? merchantDefined3;
  String? merchantDefined4;
  String? merchantDefined5;

  GBInquiryTxn(
      {required this.referenceNo,
      required this.gbpReferenceNo,
      required this.amount});

  Map<String, dynamic> toJson() => _$GBInquiryTxnToJson(this);
  factory GBInquiryTxn.fromJson(Map<String, dynamic> json) =>
      _$GBInquiryTxnFromJson(json);
}
