// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductCategoryCodeListModel _$ProductCategoryCodeListModelFromJson(
  Map<String, dynamic> json,
) => ProductCategoryCodeListModel(
  code: json['code'] as String,
  names: (json['names'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  xorder: (json['xorder'] as num).toInt(),
  barcode: json['barcode'] as String,
  unitcode: json['unitcode'] as String,
  unitnames: (json['unitnames'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProductCategoryCodeListModelToJson(
  ProductCategoryCodeListModel instance,
) => <String, dynamic>{
  'code': instance.code,
  'names': instance.names.map((e) => e.toJson()).toList(),
  'xorder': instance.xorder,
  'barcode': instance.barcode,
  'unitcode': instance.unitcode,
  'unitnames': instance.unitnames.map((e) => e.toJson()).toList(),
};

SortDataModel _$SortDataModelFromJson(Map<String, dynamic> json) =>
    SortDataModel(
      code: json['code'] as String,
      xorder: (json['xorder'] as num).toInt(),
    );

Map<String, dynamic> _$SortDataModelToJson(SortDataModel instance) =>
    <String, dynamic>{'code': instance.code, 'xorder': instance.xorder};

BarcodeModel _$BarcodeModelFromJson(Map<String, dynamic> json) => BarcodeModel(
  barcode: json['barcode'] as String? ?? '',
  item_code: json['item_code'] as String? ?? '',
  item_name: json['item_name'] as String? ?? '',
  unit_code: json['unit_code'] as String? ?? '',
  unit_name: json['unit_name'] as String? ?? '',
);

Map<String, dynamic> _$BarcodeModelToJson(BarcodeModel instance) =>
    <String, dynamic>{
      'barcode': instance.barcode,
      'item_code': instance.item_code,
      'item_name': instance.item_name,
      'unit_code': instance.unit_code,
      'unit_name': instance.unit_name,
    };

OrderOnlineParameterModel _$OrderOnlineParameterModelFromJson(
  Map<String, dynamic> json,
) => OrderOnlineParameterModel(
  shopid: json['shopid'] as String,
  type: (json['type'] as num?)?.toInt() ?? 0,
  table: json['table'] as String? ?? "",
  qrcode: json['qrcode'] as String? ?? "",
  phone: json['phone'] as String? ?? "",
  tablebuffetcode: json['tablebuffetcode'] as String? ?? "",
);

Map<String, dynamic> _$OrderOnlineParameterModelToJson(
  OrderOnlineParameterModel instance,
) => <String, dynamic>{
  'shopid': instance.shopid,
  'type': instance.type,
  'table': instance.table,
  'qrcode': instance.qrcode,
  'phone': instance.phone,
  'tablebuffetcode': instance.tablebuffetcode,
};

OrderBarcodeStatusModel _$OrderBarcodeStatusModelFromJson(
  Map<String, dynamic> json,
) => OrderBarcodeStatusModel(
  shopid: json['shopid'] as String,
  barcode: json['barcode'] as String,
  orderstatus: (json['orderstatus'] as num).toInt(),
  orderautostock: (json['orderautostock'] as num).toInt(),
  orderdisable: (json['orderdisable'] as num).toInt(),
  qtystart: (json['qtystart'] as num).toDouble(),
  qtybalance: (json['qtybalance'] as num).toDouble(),
  qtymin: (json['qtymin'] as num).toDouble(),
);

Map<String, dynamic> _$OrderBarcodeStatusModelToJson(
  OrderBarcodeStatusModel instance,
) => <String, dynamic>{
  'shopid': instance.shopid,
  'barcode': instance.barcode,
  'orderstatus': instance.orderstatus,
  'orderautostock': instance.orderautostock,
  'orderdisable': instance.orderdisable,
  'qtystart': instance.qtystart,
  'qtybalance': instance.qtybalance,
  'qtymin': instance.qtymin,
};
