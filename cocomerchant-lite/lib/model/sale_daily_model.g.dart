// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_daily_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleDailyPaymentModel _$SaleDailyPaymentModelFromJson(Map<String, dynamic> json) => SaleDailyPaymentModel(
      description: json['description'] as String,
      totalamount: (json['totalamount'] as num).toDouble(),
    );

Map<String, dynamic> _$SaleDailyPaymentModelToJson(SaleDailyPaymentModel instance) => <String, dynamic>{
      'description': instance.description,
      'totalamount': instance.totalamount,
    };

SaleDailyModel _$SaleDailyModelFromJson(Map<String, dynamic> json) => SaleDailyModel(
      shopid: json['shopid'] as String,
      branchid: json['branchid'] as String,
      doccount: (json['doccount'] as num).toDouble(),
      totalamount: (json['totalamount'] as num).toDouble(),
      totalpayamount: (json['totalpayamount'] as num).toDouble(),
      totalpaycashamount: (json['totalpaycashamount'] as num).toDouble(),
      totalpaycashchange: (json['totalpaycashchange'] as num).toDouble(),
      totalroundamount: (json['totalroundamount'] as num).toDouble(),
      paymentlist: (json['paymentlist'] as List<dynamic>).map((e) => SaleDailyPaymentModel.fromJson(e as Map<String, dynamic>)).toList(),
      totalpaymentlist: (json['totalpaymentlist'] as num).toDouble(),
    );

Map<String, dynamic> _$SaleDailyModelToJson(SaleDailyModel instance) => <String, dynamic>{
      'shopid': instance.shopid,
      'branchid': instance.branchid,
      'doccount': instance.doccount,
      'totalamount': instance.totalamount,
      'totalpayamount': instance.totalpayamount,
      'totalpaycashamount': instance.totalpaycashamount,
      'totalpaycashchange': instance.totalpaycashchange,
      'totalroundamount': instance.totalroundamount,
      'paymentlist': instance.paymentlist.map((e) => e.toJson()).toList(),
      'totalpaymentlist': instance.totalpaymentlist,
    };
