// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_barcode_status_struct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductBarcodeStatusObjectBoxStruct
_$ProductBarcodeStatusObjectBoxStructFromJson(Map<String, dynamic> json) =>
    ProductBarcodeStatusObjectBoxStruct(
      barcode: json['barcode'] as String,
      orderStatus: (json['orderStatus'] as num).toInt(),
      orderDisable: json['orderDisable'] as bool,
      orderAutoStock: json['orderAutoStock'] as bool,
      qtyStart: (json['qtyStart'] as num).toDouble(),
      qtyBalance: (json['qtyBalance'] as num).toDouble(),
      qtyMin: (json['qtyMin'] as num).toDouble(),
    )..id = (json['id'] as num).toInt();

Map<String, dynamic> _$ProductBarcodeStatusObjectBoxStructToJson(
  ProductBarcodeStatusObjectBoxStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'barcode': instance.barcode,
  'orderStatus': instance.orderStatus,
  'orderAutoStock': instance.orderAutoStock,
  'orderDisable': instance.orderDisable,
  'qtyStart': instance.qtyStart,
  'qtyBalance': instance.qtyBalance,
  'qtyMin': instance.qtyMin,
};
