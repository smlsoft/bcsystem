// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_daily_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentDailyModel _$PaymentDailyModelFromJson(Map<String, dynamic> json) =>
    PaymentDailyModel(
      docDate: json['doc_date'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      roundAmount: (json['round_amount'] as num).toDouble(),
      totalValue: (json['total_value'] as num).toDouble(),
      payCashAmount: (json['pay_cashamount'] as num).toDouble(),
      sumTransfer: (json['sum_transfer'] as num).toDouble(),
      sumCreditCard: (json['sum_creditcard'] as num).toDouble(),
      sumCheque: (json['sum_cheque'] as num).toDouble(),
      sumCoupon: (json['sum_coupon'] as num).toDouble(),
      sumQRCode: (json['sum_qrcode'] as num).toDouble(),
      sumCredit: (json['sum_credit'] as num).toDouble(),
      totalPayment: (json['total_payment'] as num).toDouble(),
      transactions: (json['transactions'] as List<dynamic>)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaymentDailyModelToJson(PaymentDailyModel instance) =>
    <String, dynamic>{
      'doc_date': instance.docDate,
      'total_amount': instance.totalAmount,
      'round_amount': instance.roundAmount,
      'total_value': instance.totalValue,
      'pay_cashamount': instance.payCashAmount,
      'sum_transfer': instance.sumTransfer,
      'sum_creditcard': instance.sumCreditCard,
      'sum_cheque': instance.sumCheque,
      'sum_coupon': instance.sumCoupon,
      'sum_qrcode': instance.sumQRCode,
      'sum_credit': instance.sumCredit,
      'total_payment': instance.totalPayment,
      'transactions': instance.transactions.map((e) => e.toJson()).toList(),
    };

PaymentDailySummaryModel _$PaymentDailySummaryModelFromJson(
        Map<String, dynamic> json) =>
    PaymentDailySummaryModel(
      fromDate: json['fromdate'] as String,
      toDate: json['todate'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      totalPayment: (json['total_payment'] as num).toDouble(),
    );

Map<String, dynamic> _$PaymentDailySummaryModelToJson(
        PaymentDailySummaryModel instance) =>
    <String, dynamic>{
      'fromdate': instance.fromDate,
      'todate': instance.toDate,
      'total_amount': instance.totalAmount,
      'total_payment': instance.totalPayment,
    };

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    TransactionModel(
      docDate: json['docdate'] as String,
      docTime: json['doctime'] as String,
      docNo: json['docno'] as String,
      custName: json['custname'] as String,
      totalAmount: (json['totalamount'] as num).toDouble(),
      roundAmount: (json['roundamount'] as num).toDouble(),
      totalValue: (json['totalvalue'] as num).toDouble(),
      payCashAmount: (json['paycashamount'] as num).toDouble(),
      sumMoneyTransfer: (json['summoneytransfer'] as num).toDouble(),
      sumCreditCard: (json['sumcreditcard'] as num).toDouble(),
      sumCheque: (json['sumcheque'] as num).toDouble(),
      sumCoupon: (json['sumcoupon'] as num).toDouble(),
      sumQRCode: (json['sumqrcode'] as num).toDouble(),
      sumCredit: (json['sumcredit'] as num).toDouble(),
      totalPayment: (json['totalpayment'] as num).toDouble(),
    );

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      'docdate': instance.docDate,
      'doctime': instance.docTime,
      'docno': instance.docNo,
      'custname': instance.custName,
      'totalamount': instance.totalAmount,
      'roundamount': instance.roundAmount,
      'totalvalue': instance.totalValue,
      'paycashamount': instance.payCashAmount,
      'summoneytransfer': instance.sumMoneyTransfer,
      'sumcreditcard': instance.sumCreditCard,
      'sumcheque': instance.sumCheque,
      'sumcoupon': instance.sumCoupon,
      'sumqrcode': instance.sumQRCode,
      'sumcredit': instance.sumCredit,
      'totalpayment': instance.totalPayment,
    };
