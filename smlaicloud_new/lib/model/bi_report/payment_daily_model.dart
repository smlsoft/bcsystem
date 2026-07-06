import 'package:json_annotation/json_annotation.dart';

part 'payment_daily_model.g.dart';

@JsonSerializable(explicitToJson: true)
class PaymentDailyModel {
  @JsonKey(name: 'doc_date')
  final String docDate;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @JsonKey(name: 'round_amount')
  final double roundAmount;
  @JsonKey(name: 'total_value')
  final double totalValue;
  @JsonKey(name: 'pay_cashamount')
  final double payCashAmount;
  @JsonKey(name: 'sum_transfer')
  final double sumTransfer;
  @JsonKey(name: 'sum_creditcard')
  final double sumCreditCard;
  @JsonKey(name: 'sum_cheque')
  final double sumCheque;
  @JsonKey(name: 'sum_coupon')
  final double sumCoupon;
  @JsonKey(name: 'sum_qrcode')
  final double sumQRCode;
  @JsonKey(name: 'sum_credit')
  final double sumCredit;
  @JsonKey(name: 'total_payment')
  final double totalPayment;
  @JsonKey(name: 'transactions')
  final List<TransactionModel> transactions;

  PaymentDailyModel({
    required this.docDate,
    required this.totalAmount,
    required this.roundAmount,
    required this.totalValue,
    required this.payCashAmount,
    required this.sumTransfer,
    required this.sumCreditCard,
    required this.sumCheque,
    required this.sumCoupon,
    required this.sumQRCode,
    required this.sumCredit,
    required this.totalPayment,
    required this.transactions,
  });

  factory PaymentDailyModel.fromJson(Map<String, dynamic> json) => _$PaymentDailyModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentDailyModelToJson(this);
}

/// PaymentDailySummaryModel
@JsonSerializable(explicitToJson: true)
class PaymentDailySummaryModel {
  @JsonKey(name: 'fromdate')
  final String fromDate;
  @JsonKey(name: 'todate')
  final String toDate;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @JsonKey(name: 'total_payment')
  final double totalPayment;

  PaymentDailySummaryModel({
    required this.fromDate,
    required this.toDate,
    required this.totalAmount,
    required this.totalPayment,
  });

  factory PaymentDailySummaryModel.fromJson(Map<String, dynamic> json) => _$PaymentDailySummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentDailySummaryModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransactionModel {
  @JsonKey(name: 'docdate')
  final String docDate;
  @JsonKey(name: 'doctime')
  final String docTime;
  @JsonKey(name: 'docno')
  final String docNo;
  @JsonKey(name: 'custname')
  final String custName;
  @JsonKey(name: 'totalamount')
  final double totalAmount;
  @JsonKey(name: 'roundamount')
  final double roundAmount;
  @JsonKey(name: 'totalvalue')
  final double totalValue;
  @JsonKey(name: 'paycashamount')
  final double payCashAmount;
  @JsonKey(name: 'summoneytransfer')
  final double sumMoneyTransfer;
  @JsonKey(name: 'sumcreditcard')
  final double sumCreditCard;
  @JsonKey(name: 'sumcheque')
  final double sumCheque;
  @JsonKey(name: 'sumcoupon')
  final double sumCoupon;
  @JsonKey(name: 'sumqrcode')
  final double sumQRCode;
  @JsonKey(name: 'sumcredit')
  final double sumCredit;
  @JsonKey(name: 'totalpayment')
  final double totalPayment;

  TransactionModel({
    required this.docDate,
    required this.docTime,
    required this.docNo,
    required this.custName,
    required this.totalAmount,
    required this.roundAmount,
    required this.totalValue,
    required this.payCashAmount,
    required this.sumMoneyTransfer,
    required this.sumCreditCard,
    required this.sumCheque,
    required this.sumCoupon,
    required this.sumQRCode,
    required this.sumCredit,
    required this.totalPayment,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => _$TransactionModelFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);
}
