// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_barcode_struct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductBarcodeObjectBoxStruct _$ProductBarcodeObjectBoxStructFromJson(
  Map<String, dynamic> json,
) =>
    ProductBarcodeObjectBoxStruct(
        barcode: json['barcode'] as String,
        names: json['names'] as String,
        name_all: json['name_all'] as String,
        guid_fixed: json['guid_fixed'] as String,
        item_guid: json['item_guid'] as String,
        descriptions: json['descriptions'] as String,
        item_code: json['item_code'] as String,
        unit_names: json['unit_names'] as String,
        prices: json['prices'] as String,
        new_line: (json['new_line'] as num).toInt(),
        unit_code: json['unit_code'] as String,
        unit_stand: (json['unit_stand'] as num).toDouble(),
        unit_divide: (json['unit_divide'] as num).toDouble(),
        options_json: json['options_json'] as String,
        images_url: json['images_url'] as String,
        image_or_color: json['image_or_color'] as bool,
        color_select: json['color_select'] as String,
        color_select_hex: json['color_select_hex'] as String,
        isalacarte: json['isalacarte'] as bool,
        ordertypes: json['ordertypes'] as String,
        vat_type: (json['vat_type'] as num).toInt(),
        is_except_vat: json['is_except_vat'] as bool,
        product_count: (json['product_count'] as num).toDouble(),
        issplitunitprint: json['issplitunitprint'] as bool,
        food_type: (json['food_type'] as num).toInt(),
        ref_barcode_json: json['ref_barcode_json'] as String,
        patterncode: json['patterncode'] as String,
        is_resterant_use_stock: json['is_resterant_use_stock'] as bool,
        issumpoint: json['issumpoint'] as bool?,
      )
      ..id = (json['id'] as num).toInt()
      ..sum_order_qty = (json['sum_order_qty'] as num).toDouble();

Map<String, dynamic> _$ProductBarcodeObjectBoxStructToJson(
  ProductBarcodeObjectBoxStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'barcode': instance.barcode,
  'names': instance.names,
  'name_all': instance.name_all,
  'guid_fixed': instance.guid_fixed,
  'item_guid': instance.item_guid,
  'descriptions': instance.descriptions,
  'item_code': instance.item_code,
  'unit_stand': instance.unit_stand,
  'unit_divide': instance.unit_divide,
  'unit_code': instance.unit_code,
  'unit_names': instance.unit_names,
  'prices': instance.prices,
  'new_line': instance.new_line,
  'product_count': instance.product_count,
  'options_json': instance.options_json,
  'images_url': instance.images_url,
  'image_or_color': instance.image_or_color,
  'color_select': instance.color_select,
  'color_select_hex': instance.color_select_hex,
  'vat_type': instance.vat_type,
  'isalacarte': instance.isalacarte,
  'is_except_vat': instance.is_except_vat,
  'ordertypes': instance.ordertypes,
  'issplitunitprint': instance.issplitunitprint,
  'issumpoint': instance.issumpoint,
  'food_type': instance.food_type,
  'is_resterant_use_stock': instance.is_resterant_use_stock,
  'sum_order_qty': instance.sum_order_qty,
  'ref_barcode_json': instance.ref_barcode_json,
  'patterncode': instance.patterncode,
};
