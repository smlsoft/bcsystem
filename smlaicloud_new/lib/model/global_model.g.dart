// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SortDataModel _$SortDataModelFromJson(Map<String, dynamic> json) =>
    SortDataModel(
      code: json['code'] as String,
      xorder: (json['xorder'] as num).toInt(),
    );

Map<String, dynamic> _$SortDataModelToJson(SortDataModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'xorder': instance.xorder,
    };

XSortModel _$XSortModelFromJson(Map<String, dynamic> json) => XSortModel(
      guidfixed: json['guidfixed'] as String,
      xorder: (json['xorder'] as num).toInt(),
      code: json['code'] as String,
    );

Map<String, dynamic> _$XSortModelToJson(XSortModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'code': instance.code,
      'xorder': instance.xorder,
    };

LanguageModel _$LanguageModelFromJson(Map<String, dynamic> json) =>
    LanguageModel(
      code: json['code'] as String?,
      codeTranslator: json['codeTranslator'] as String?,
      name: json['name'] as String?,
      isuse: json['isuse'] as bool?,
      isdefault: json['isdefault'] as bool?,
      isauto: json['isauto'] as bool?,
      isdelete: json['isdelete'] as bool?,
    );

Map<String, dynamic> _$LanguageModelToJson(LanguageModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'codeTranslator': instance.codeTranslator,
      'name': instance.name,
      'isuse': instance.isuse,
      'isdefault': instance.isdefault,
      'isauto': instance.isauto,
      'isdelete': instance.isdelete,
    };

LanguageDataModel _$LanguageDataModelFromJson(Map<String, dynamic> json) =>
    LanguageDataModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$LanguageDataModelToJson(LanguageDataModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };

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

ImageUpload _$ImageUploadFromJson(Map<String, dynamic> json) => ImageUpload(
      uri: json['uri'] as String,
    );

Map<String, dynamic> _$ImageUploadToJson(ImageUpload instance) =>
    <String, dynamic>{
      'uri': instance.uri,
    };

ImagesModel _$ImagesModelFromJson(Map<String, dynamic> json) => ImagesModel(
      uri: json['uri'] as String,
      xorder: (json['xorder'] as num).toInt(),
    );

Map<String, dynamic> _$ImagesModelToJson(ImagesModel instance) =>
    <String, dynamic>{
      'uri': instance.uri,
      'xorder': instance.xorder,
    };

PromotionListModel _$PromotionListModelFromJson(Map<String, dynamic> json) =>
    PromotionListModel(
      code: (json['code'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$PromotionListModelToJson(PromotionListModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };

SlipListModel _$SlipListModelFromJson(Map<String, dynamic> json) =>
    SlipListModel(
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      headernames: (json['headernames'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SlipListModelToJson(SlipListModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'headernames': instance.headernames?.map((e) => e.toJson()).toList(),
    };

DayOfWeekModel _$DayOfWeekModelFromJson(Map<String, dynamic> json) =>
    DayOfWeekModel(
      code: json['code'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$DayOfWeekModelToJson(DayOfWeekModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };

QrTypeModel _$QrTypeModelFromJson(Map<String, dynamic> json) => QrTypeModel(
      code: (json['code'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$QrTypeModelToJson(QrTypeModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };

SearchGuidCodeNameModel _$SearchGuidCodeNameModelFromJson(
        Map<String, dynamic> json) =>
    SearchGuidCodeNameModel(
      guid: json['guid'] as String,
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isCancel: json['isCancel'] as bool? ?? false,
    );

Map<String, dynamic> _$SearchGuidCodeNameModelToJson(
        SearchGuidCodeNameModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'code': instance.code,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'isCancel': instance.isCancel,
    };

FiltterBarcodeModel _$FiltterBarcodeModelFromJson(Map<String, dynamic> json) =>
    FiltterBarcodeModel(
      branch: json['branch'] as bool?,
    );

Map<String, dynamic> _$FiltterBarcodeModelToJson(
        FiltterBarcodeModel instance) =>
    <String, dynamic>{
      'branch': instance.branch,
    };

ReportStockBalanceModel _$ReportStockBalanceModelFromJson(
        Map<String, dynamic> json) =>
    ReportStockBalanceModel(
      barCodeMain: json['barcode_main'] as String,
      barCodeName: json['barcode_name'] as String,
      unitCode: json['unit_code'] as String?,
      unitName: json['unit_name'] as String?,
      balanceQty: (json['balance_qty'] as num?)?.toDouble(),
      averageCost: (json['average_cost'] as num?)?.toDouble(),
      balanceAmount: (json['balance_amount'] as num?)?.toDouble(),
      balanceWord: json['balance_word'] as String?,
      isAutoPacking: (json['is_auto_packing'] as num?)?.toInt(),
      warehouses: (json['warehouses'] as List<dynamic>?)
          ?.map((e) => ReportStockBalanceWarehouseModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReportStockBalanceModelToJson(
        ReportStockBalanceModel instance) =>
    <String, dynamic>{
      'barcode_main': instance.barCodeMain,
      'barcode_name': instance.barCodeName,
      'unit_code': instance.unitCode,
      'unit_name': instance.unitName,
      'balance_qty': instance.balanceQty,
      'average_cost': instance.averageCost,
      'balance_amount': instance.balanceAmount,
      'balance_word': instance.balanceWord,
      'is_auto_packing': instance.isAutoPacking,
      'warehouses': instance.warehouses?.map((e) => e.toJson()).toList(),
    };

ReportStockBalanceWarehouseModel _$ReportStockBalanceWarehouseModelFromJson(
        Map<String, dynamic> json) =>
    ReportStockBalanceWarehouseModel(
      warehouseCode: json['warehouse_code'] as String,
      balanceQty: (json['balance_qty'] as num).toDouble(),
      averageCost: (json['average_cost'] as num).toDouble(),
      balanceWord: json['balance_word'] as String,
      balanceAmount: (json['balance_amount'] as num).toDouble(),
      locations: (json['locations'] as List<dynamic>)
          .map((e) => ReportStockBalanceLocationModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReportStockBalanceWarehouseModelToJson(
        ReportStockBalanceWarehouseModel instance) =>
    <String, dynamic>{
      'warehouse_code': instance.warehouseCode,
      'balance_qty': instance.balanceQty,
      'average_cost': instance.averageCost,
      'balance_word': instance.balanceWord,
      'balance_amount': instance.balanceAmount,
      'locations': instance.locations.map((e) => e.toJson()).toList(),
    };

ReportStockBalanceLocationModel _$ReportStockBalanceLocationModelFromJson(
        Map<String, dynamic> json) =>
    ReportStockBalanceLocationModel(
      locationCode: json['location_code'] as String,
      balanceQty: (json['balance_qty'] as num).toDouble(),
      balanceWord: json['balance_word'] as String,
    );

Map<String, dynamic> _$ReportStockBalanceLocationModelToJson(
        ReportStockBalanceLocationModel instance) =>
    <String, dynamic>{
      'location_code': instance.locationCode,
      'balance_qty': instance.balanceQty,
      'balance_word': instance.balanceWord,
    };

ReportStockBalanceWhBarcodeModel _$ReportStockBalanceWhBarcodeModelFromJson(
        Map<String, dynamic> json) =>
    ReportStockBalanceWhBarcodeModel(
      whCode: json['whcode'] as String,
      barCodeMain: json['barcode_main'] as String,
      barCodeName: json['barcode_name'] as String,
      unitCode: json['unit_code'] as String?,
      unitName: json['unit_name'] as String?,
      balanceQty: (json['balance_qty'] as num?)?.toDouble(),
      balanceWord: json['balance_word'] as String?,
    );

Map<String, dynamic> _$ReportStockBalanceWhBarcodeModelToJson(
        ReportStockBalanceWhBarcodeModel instance) =>
    <String, dynamic>{
      'whcode': instance.whCode,
      'barcode_main': instance.barCodeMain,
      'barcode_name': instance.barCodeName,
      'unit_code': instance.unitCode,
      'unit_name': instance.unitName,
      'balance_qty': instance.balanceQty,
      'balance_word': instance.balanceWord,
    };

ReportStockBalanceLocationBarcodeModel
    _$ReportStockBalanceLocationBarcodeModelFromJson(
            Map<String, dynamic> json) =>
        ReportStockBalanceLocationBarcodeModel(
          whCode: json['whcode'] as String,
          locationCode: json['location_code'] as String,
          barCodeMain: json['barcode_main'] as String,
          barCodeName: json['barcode_name'] as String,
          unitCode: json['unit_code'] as String?,
          unitName: json['unit_name'] as String?,
          balanceQty: (json['balance_qty'] as num?)?.toDouble(),
          balanceWord: json['balance_word'] as String?,
        );

Map<String, dynamic> _$ReportStockBalanceLocationBarcodeModelToJson(
        ReportStockBalanceLocationBarcodeModel instance) =>
    <String, dynamic>{
      'whcode': instance.whCode,
      'location_code': instance.locationCode,
      'barcode_main': instance.barCodeMain,
      'barcode_name': instance.barCodeName,
      'unit_code': instance.unitCode,
      'unit_name': instance.unitName,
      'balance_qty': instance.balanceQty,
      'balance_word': instance.balanceWord,
    };

ReportStockMovementModel _$ReportStockMovementModelFromJson(
        Map<String, dynamic> json) =>
    ReportStockMovementModel(
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      unitCode: json['unitCode'] as String,
      unitName: json['unitName'] as String?,
      details: (json['details'] as List<dynamic>)
          .map((e) => ReportStockMovementDetailModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReportStockMovementModelToJson(
        ReportStockMovementModel instance) =>
    <String, dynamic>{
      'barcode': instance.barcode,
      'name': instance.name,
      'unitCode': instance.unitCode,
      'unitName': instance.unitName,
      'details': instance.details.map((e) => e.toJson()).toList(),
    };

ReportStockMovementDetailModel _$ReportStockMovementDetailModelFromJson(
        Map<String, dynamic> json) =>
    ReportStockMovementDetailModel(
      isExtra: json['isExtra'] as bool,
      docDateTime: json['docDateTime'] as String,
      barcodeuse: json['barcodeuse'] as String,
      docNo: json['docNo'] as String,
      transFlag: (json['transFlag'] as num).toInt(),
      unitCode: json['unitCode'] as String,
      whCode: json['whCode'] as String,
      locationCode: json['locationCode'] as String,
      totalQty: (json['totalQty'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      unitStand: (json['unitStand'] as num).toDouble(),
      unitDivide: (json['unitDivide'] as num).toDouble(),
      unitCost: (json['unitCost'] as num).toDouble(),
      averageCost: (json['averageCost'] as num).toDouble(),
      calcAmount: (json['calcAmount'] as num).toDouble(),
      balanceAmount: (json['balanceAmount'] as num).toDouble(),
      balanceQty: (json['balanceQty'] as num).toDouble(),
      docRef: json['docRef'] as String,
    );

Map<String, dynamic> _$ReportStockMovementDetailModelToJson(
        ReportStockMovementDetailModel instance) =>
    <String, dynamic>{
      'isExtra': instance.isExtra,
      'docDateTime': instance.docDateTime,
      'docNo': instance.docNo,
      'barcodeuse': instance.barcodeuse,
      'transFlag': instance.transFlag,
      'unitCode': instance.unitCode,
      'whCode': instance.whCode,
      'locationCode': instance.locationCode,
      'totalQty': instance.totalQty,
      'price': instance.price,
      'unitStand': instance.unitStand,
      'unitDivide': instance.unitDivide,
      'unitCost': instance.unitCost,
      'averageCost': instance.averageCost,
      'calcAmount': instance.calcAmount,
      'balanceAmount': instance.balanceAmount,
      'balanceQty': instance.balanceQty,
      'docRef': instance.docRef,
    };
