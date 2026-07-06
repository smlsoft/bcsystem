// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
      guidfixed: json['guidfixed'] as String,
    );

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
    };

ProductResponseModel _$ProductResponseModelFromJson(
        Map<String, dynamic> json) =>
    ProductResponseModel(
      data: (json['data'] as List<dynamic>)
          .map(
              (e) => ProductFromServerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductResponseModelToJson(
        ProductResponseModel instance) =>
    <String, dynamic>{
      'data': instance.data,
    };

ProductFromServerModel _$ProductFromServerModelFromJson(
        Map<String, dynamic> json) =>
    ProductFromServerModel(
      barcode: json['barcode'] as String,
      imageuri: json['imageuri'] as String,
      itemunitname: json['itemunitname'] as String,
      itemunitcode: json['itemunitcode'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => ProductOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      prices: (json['prices'] as List<dynamic>)
          .map((e) =>
              ProductPriceFromServerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductFromServerModelToJson(
        ProductFromServerModel instance) =>
    <String, dynamic>{
      'barcode': instance.barcode,
      'imageuri': instance.imageuri,
      'itemunitname': instance.itemunitname,
      'itemunitcode': instance.itemunitcode,
      'options': instance.options.map((e) => e.toJson()).toList(),
      'prices': instance.prices.map((e) => e.toJson()).toList(),
    };

ProductPriceFromServerModel _$ProductPriceFromServerModelFromJson(
        Map<String, dynamic> json) =>
    ProductPriceFromServerModel(
      keynumber: (json['keynumber'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
    );

Map<String, dynamic> _$ProductPriceFromServerModelToJson(
        ProductPriceFromServerModel instance) =>
    <String, dynamic>{
      'keynumber': instance.keynumber,
      'price': instance.price,
    };

ProductOptionModel _$ProductOptionModelFromJson(Map<String, dynamic> json) =>
    ProductOptionModel(
      guid: json['guid'] as String,
      choicetype: (json['choicetype'] as num).toInt(),
      maxselect: (json['maxselect'] as num).toInt(),
      minselect: (json['minselect'] as num).toInt(),
      name: json['name'] as String,
      choices: (json['choices'] as List<dynamic>)
          .map((e) =>
              ProductOptionChoiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductOptionModelToJson(ProductOptionModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'choicetype': instance.choicetype,
      'maxselect': instance.maxselect,
      'minselect': instance.minselect,
      'name': instance.name,
      'choices': instance.choices.map((e) => e.toJson()).toList(),
    };

ProductOptionChoiceModel _$ProductOptionChoiceModelFromJson(
        Map<String, dynamic> json) =>
    ProductOptionChoiceModel(
      guid: json['guid'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      price: json['price'] as String,
      qty: (json['qty'] as num).toDouble(),
    );

Map<String, dynamic> _$ProductOptionChoiceModelToJson(
        ProductOptionChoiceModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'price': instance.price,
      'qty': instance.qty,
    };

ProductOrderTypeFromServerModel _$ProductOrderTypeFromServerModelFromJson(
        Map<String, dynamic> json) =>
    ProductOrderTypeFromServerModel(
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      price: (json['price'] as num).toDouble(),
    );

Map<String, dynamic> _$ProductOrderTypeFromServerModelToJson(
        ProductOrderTypeFromServerModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'price': instance.price,
    };

ProductProcessOptionModel _$ProductProcessOptionModelFromJson(
        Map<String, dynamic> json) =>
    ProductProcessOptionModel(
      guid: json['guid'] as String,
      choicetype: (json['choicetype'] as num).toInt(),
      maxselect: (json['maxselect'] as num).toInt(),
      minselect: (json['minselect'] as num).toInt(),
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      choices: (json['choices'] as List<dynamic>)
          .map((e) => ProductProcessOptionChoiceModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductProcessOptionModelToJson(
        ProductProcessOptionModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'choicetype': instance.choicetype,
      'maxselect': instance.maxselect,
      'minselect': instance.minselect,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'choices': instance.choices.map((e) => e.toJson()).toList(),
    };

ProductProcessOptionChoiceModel _$ProductProcessOptionChoiceModelFromJson(
        Map<String, dynamic> json) =>
    ProductProcessOptionChoiceModel(
      guid: json['guid'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      price: json['price'] as String,
      qty: (json['qty'] as num).toDouble(),
      selected: json['selected'] as bool?,
      priceValue: (json['priceValue'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ProductProcessOptionChoiceModelToJson(
        ProductProcessOptionChoiceModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'price': instance.price,
      'qty': instance.qty,
      'selected': instance.selected,
      'priceValue': instance.priceValue,
    };

ProductBarcodeObjectBoxStruct _$ProductBarcodeObjectBoxStructFromJson(
        Map<String, dynamic> json) =>
    ProductBarcodeObjectBoxStruct(
      barcode: json['barcode'] as String,
      names: json['names'] as String,
      name_all: json['name_all'] as String,
      guid_fixed: json['guid_fixed'] as String,
      item_guid: json['item_guid'] as String,
      item_code: json['item_code'] as String,
      item_unit_code: json['item_unit_code'] as String,
      unit_names: json['unit_names'] as String,
      prices: json['prices'] as String,
      new_line: (json['new_line'] as num).toInt(),
      unit_code: json['unit_code'] as String,
      options_json: json['options_json'] as String,
      images_url: json['images_url'] as String,
      image_or_color: json['image_or_color'] as bool,
      color_select: json['color_select'] as String,
      color_select_hex: json['color_select_hex'] as String,
      isalacarte: json['isalacarte'] as bool,
      ordertypes: json['ordertypes'] as String,
      product_count: (json['product_count'] as num).toDouble(),
    )..id = (json['id'] as num).toInt();

Map<String, dynamic> _$ProductBarcodeObjectBoxStructToJson(
        ProductBarcodeObjectBoxStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'barcode': instance.barcode,
      'names': instance.names,
      'name_all': instance.name_all,
      'guid_fixed': instance.guid_fixed,
      'item_guid': instance.item_guid,
      'item_code': instance.item_code,
      'item_unit_code': instance.item_unit_code,
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
      'isalacarte': instance.isalacarte,
      'ordertypes': instance.ordertypes,
    };
