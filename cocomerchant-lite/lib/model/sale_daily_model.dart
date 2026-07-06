import 'dart:convert';

import 'package:cocomerchant_lite/model/shop_model.dart';
import 'package:cocomerchant_lite/model/user_login_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sale_daily_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SaleDailyPaymentModel {
  final String description;
  final double totalamount;

  SaleDailyPaymentModel({
    required this.description,
    required this.totalamount,
  });

  factory SaleDailyPaymentModel.fromJson(Map<String, dynamic> json) => _$SaleDailyPaymentModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleDailyPaymentModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SaleDailyModel {
  String shopid;
  double doccount;
  String branchid;
  double totalamount;
  double totalpayamount;
  double totalpaycashamount;
  double totalpaycashchange;
  double totalroundamount;
  List<SaleDailyPaymentModel> paymentlist;
  double totalpaymentlist;

  SaleDailyModel({
    required this.shopid,
    required this.branchid,
    required this.doccount,
    required this.totalamount,
    required this.totalpayamount,
    required this.totalpaycashamount,
    required this.totalpaycashchange,
    required this.totalroundamount,
    required this.paymentlist,
    required this.totalpaymentlist,
  });

  factory SaleDailyModel.fromJson(Map<String, dynamic> json) => _$SaleDailyModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleDailyModelToJson(this);
}

class SaleDailyProcessBranchModel {
  // รายการขายรายวันตาม Branch
  String branchid;
  int countDoc;
  double totalAmount;
  double payCashAmount;
  double roundAmount;
  int countPayCash;
  List<SaleDailyByDeliveryCodeModel> saleDailyByDeliveryCode;
  List<SaleDailyByPayTypeModel> saleDailyByPayType;

  SaleDailyProcessBranchModel({
    required this.branchid,
    required this.countDoc,
    required this.totalAmount,
    required this.roundAmount,
    required this.saleDailyByDeliveryCode,
    required this.saleDailyByPayType,
    required this.payCashAmount,
    required this.countPayCash,
  });
}

class SaleDailyProcessByShopModel {
  // รายการขายรายวันตาม Shop
  String shopid;
  String shopName;
  int countDoc;
  double totalAmount;
  double payCashAmount;
  double roundAmount;
  int countPayCash;
  List<SaleDailyProcessBranchModel> saleDailyByBranch;
  List<SaleDailyByDeliveryCodeModel> saleDailyByDeliveryCodes;
  List<SaleDailyByPayTypeModel> saleDailyByPayType;

  SaleDailyProcessByShopModel({
    required this.shopid,
    required this.shopName,
    required this.countDoc,
    required this.totalAmount,
    required this.payCashAmount,
    required this.roundAmount,
    required this.countPayCash,
    required this.saleDailyByBranch,
    required this.saleDailyByDeliveryCodes,
    required this.saleDailyByPayType,
  });
}

class SaleDailyByDeliveryCodeModel {
  // รายการขายรายวันตาม DeliveryCode
  String deliveryCode;
  int countDoc;
  double totalAmount;

  SaleDailyByDeliveryCodeModel({
    required this.deliveryCode,
    required this.countDoc,
    required this.totalAmount,
  });
}

class SaleDailyByPayTypeModel {
  // รายการขายรายวันตาม DeliveryCode
  String payDescription;
  int countDoc;
  double totalAmount;

  SaleDailyByPayTypeModel({
    required this.payDescription,
    required this.countDoc,
    required this.totalAmount,
  });
}
