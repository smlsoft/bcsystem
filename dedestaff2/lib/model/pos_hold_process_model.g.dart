// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_hold_process_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LanguageSystemModel _$LanguageSystemModelFromJson(Map<String, dynamic> json) =>
    LanguageSystemModel(
      code: json['code'] as String,
      text: json['text'] as String,
    );

Map<String, dynamic> _$LanguageSystemModelToJson(
        LanguageSystemModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'text': instance.text,
    };

LanguageSystemCodeModel _$LanguageSystemCodeModelFromJson(
        Map<String, dynamic> json) =>
    LanguageSystemCodeModel(
      code: json['code'] as String,
      langs: (json['langs'] as List<dynamic>)
          .map((e) => LanguageSystemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LanguageSystemCodeModelToJson(
        LanguageSystemCodeModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'langs': instance.langs.map((e) => e.toJson()).toList(),
    };

PosHoldProcessModel _$PosHoldProcessModelFromJson(Map<String, dynamic> json) =>
    PosHoldProcessModel(
      code: json['code'] as String,
      holdType: (json['holdType'] as num?)?.toInt() ?? 1,
      tableNumber: json['tableNumber'] as String? ?? "",
      isDelivery: json['isDelivery'] as bool? ?? false,
      deliveryNumber: json['deliveryNumber'] as String? ?? "",
      customerCode: json['customerCode'] as String? ?? "",
      customerName: json['customerName'] as String? ?? "",
      detailDiscountFormula: json['detailDiscountFormula'] as String? ?? "",
      activeLineGuid: json['activeLineGuid'] as String? ?? "",
      customerPhone: json['customerPhone'] as String? ?? "",
    )
      ..logCount = (json['logCount'] as num).toInt()
      ..saleCode = json['saleCode'] as String
      ..saleName = json['saleName'] as String
      ..payScreenData =
          PosPayModel.fromJson(json['payScreenData'] as Map<String, dynamic>)
      ..posProcess =
          PosProcessModel.fromJson(json['posProcess'] as Map<String, dynamic>);

Map<String, dynamic> _$PosHoldProcessModelToJson(
        PosHoldProcessModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'holdType': instance.holdType,
      'logCount': instance.logCount,
      'saleCode': instance.saleCode,
      'saleName': instance.saleName,
      'customerCode': instance.customerCode,
      'customerName': instance.customerName,
      'customerPhone': instance.customerPhone,
      'payScreenData': instance.payScreenData.toJson(),
      'posProcess': instance.posProcess.toJson(),
      'tableNumber': instance.tableNumber,
      'isDelivery': instance.isDelivery,
      'deliveryNumber': instance.deliveryNumber,
      'detailDiscountFormula': instance.detailDiscountFormula,
      'activeLineGuid': instance.activeLineGuid,
    };
