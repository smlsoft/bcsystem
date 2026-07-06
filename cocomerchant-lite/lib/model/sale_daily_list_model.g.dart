// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_daily_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleDailyListModel _$SaleDailyListModelFromJson(Map<String, dynamic> json) =>
    SaleDailyListModel(
      shopid: json['shopid'] as String,
      branchid: json['branchid'] as String,
      docdatetime: DateTime.parse(json['docdatetime'] as String),
      docno: json['docno'] as String,
      totalamount: (json['totalamount'] as num).toDouble(),
      sumpayamount: (json['sumpayamount'] as num).toDouble(),
      paycashamount: (json['paycashamount'] as num).toDouble(),
      paycashchange: (json['paycashchange'] as num).toDouble(),
      roundamount: (json['roundamount'] as num).toDouble(),
      paymentlist: (json['paymentlist'] as List<dynamic>)
          .map((e) => SaleDailyPaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      sumpaymentlist: (json['sumpaymentlist'] as num).toDouble(),
    );

Map<String, dynamic> _$SaleDailyListModelToJson(SaleDailyListModel instance) =>
    <String, dynamic>{
      'shopid': instance.shopid,
      'branchid': instance.branchid,
      'docdatetime': instance.docdatetime.toIso8601String(),
      'docno': instance.docno,
      'totalamount': instance.totalamount,
      'sumpayamount': instance.sumpayamount,
      'paycashamount': instance.paycashamount,
      'paycashchange': instance.paycashchange,
      'roundamount': instance.roundamount,
      'paymentlist': instance.paymentlist.map((e) => e.toJson()).toList(),
      'sumpaymentlist': instance.sumpaymentlist,
    };
