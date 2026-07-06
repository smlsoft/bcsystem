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

ProductRestaurantModel _$ProductRestaurantModelFromJson(
        Map<String, dynamic> json) =>
    ProductRestaurantModel(
      isforrestaurant: json['isforrestaurant'] as bool?,
      isfortakeaway: json['isfortakeaway'] as bool?,
      isfordelivery: json['isfordelivery'] as bool?,
      isforcustomer: json['isforcustomer'] as bool?,
      isforcustomerpreorder: json['isforcustomerpreorder'] as bool?,
    );

Map<String, dynamic> _$ProductRestaurantModelToJson(
        ProductRestaurantModel instance) =>
    <String, dynamic>{
      'isforrestaurant': instance.isforrestaurant,
      'isfortakeaway': instance.isfortakeaway,
      'isfordelivery': instance.isfordelivery,
      'isforcustomer': instance.isforcustomer,
      'isforcustomerpreorder': instance.isforcustomerpreorder,
    };

ProductFromServerModel _$ProductFromServerModelFromJson(
        Map<String, dynamic> json) =>
    ProductFromServerModel(
      barcode: json['barcode'] as String,
      imageuri: json['imageuri'] as String,
      itemunitnames: (json['itemunitnames'] as List<dynamic>?)
          ?.map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemunitcode: json['itemunitcode'] as String,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => ProductOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      prices: (json['prices'] as List<dynamic>?)
          ?.map((e) =>
              ProductPriceFromServerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      ordertypes: (json['ordertypes'] as List<dynamic>?)
          ?.map((e) => ProductOrderTypeFromServerModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      isalacarte: json['isalacarte'] as bool?,
      foodtype: (json['foodtype'] as num?)?.toInt(),
      discount: json['discount'] as String?,
      isstockforrestaurant: json['isstockforrestaurant'] as bool?,
      manufacturerguid: json['manufacturerguid'] as String?,
      isonlystaff: json['isonlystaff'] as bool?,
      is_except_vat: json['is_except_vat'] as bool?,
      vatcal: (json['vatcal'] as num?)?.toInt(),
      restaurant: json['restaurant'] == null
          ? null
          : ProductRestaurantModel.fromJson(
              json['restaurant'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProductFromServerModelToJson(
        ProductFromServerModel instance) =>
    <String, dynamic>{
      'barcode': instance.barcode,
      'imageuri': instance.imageuri,
      'itemunitnames': instance.itemunitnames.map((e) => e.toJson()).toList(),
      'itemunitcode': instance.itemunitcode,
      'isonlystaff': instance.isonlystaff,
      'options': instance.options?.map((e) => e.toJson()).toList(),
      'prices': instance.prices.map((e) => e.toJson()).toList(),
      'ordertypes': instance.ordertypes?.map((e) => e.toJson()).toList(),
      'isalacarte': instance.isalacarte,
      'foodtype': instance.foodtype,
      'discount': instance.discount,
      'isstockforrestaurant': instance.isstockforrestaurant,
      'manufacturerguid': instance.manufacturerguid,
      'restaurant': instance.restaurant.toJson(),
      'is_except_vat': instance.is_except_vat,
      'vatcal': instance.vatcal,
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

ProductOptionModel _$ProductOptionModelFromJson(Map<String, dynamic> json) =>
    ProductOptionModel(
      guid: json['guid'] as String,
      choicetype: (json['choicetype'] as num).toInt(),
      maxselect: (json['maxselect'] as num).toInt(),
      minselect: (json['minselect'] as num).toInt(),
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      'names': instance.names.map((e) => e.toJson()).toList(),
      'choices': instance.choices.map((e) => e.toJson()).toList(),
    };

TransOptionsModel _$TransOptionsModelFromJson(Map<String, dynamic> json) =>
    TransOptionsModel(
      barcode: json['barcode'] as String?,
      item_code: json['item_code'] as String?,
      item_name: json['item_name'] as String?,
      unit_code: json['unit_code'] as String?,
      unit_name: json['unit_name'] as String?,
      qty: (json['qty'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      total_amount: (json['total_amount'] as num?)?.toDouble(),
      is_except_vat: json['is_except_vat'] as bool?,
      vat_type: (json['vat_type'] as num?)?.toInt(),
      price_exclude_vat: (json['price_exclude_vat'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TransOptionsModelToJson(TransOptionsModel instance) =>
    <String, dynamic>{
      'barcode': instance.barcode,
      'item_code': instance.item_code,
      'item_name': instance.item_name,
      'unit_code': instance.unit_code,
      'unit_name': instance.unit_name,
      'qty': instance.qty,
      'price': instance.price,
      'total_amount': instance.total_amount,
      'is_except_vat': instance.is_except_vat,
      'vat_type': instance.vat_type,
      'price_exclude_vat': instance.price_exclude_vat,
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
      imageuri: json['imageuri'] as String,
      refbarcode: json['refbarcode'] as String?,
      refunitcode: json['refunitcode'] as String?,
      refunitnames: (json['refunitnames'] as List<dynamic>?)
          ?.map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductOptionChoiceModelToJson(
        ProductOptionChoiceModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'price': instance.price,
      'qty': instance.qty,
      'imageuri': instance.imageuri,
      'refbarcode': instance.refbarcode,
      'refunitcode': instance.refunitcode,
      'refunitnames': instance.refunitnames.map((e) => e.toJson()).toList(),
    };

ProductProcessModel _$ProductProcessModelFromJson(Map<String, dynamic> json) =>
    ProductProcessModel(
      type: (json['type'] as num).toInt(),
      code: json['code'] as String,
      barcode: json['barcode'] as String,
      unitcode: json['unitcode'] as String,
      unitnames: (json['unitnames'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      prices: (json['prices'] as List<dynamic>)
          .map((e) =>
              ProductPriceFromServerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      setprice: (json['setprice'] as num).toDouble(),
      discountword: json['discountword'] as String,
      imageuri: json['imageuri'] as String,
      refcategoryguid: json['refcategoryguid'] as String,
      qty: (json['qty'] as num).toDouble(),
      options: (json['options'] as List<dynamic>)
          .map((e) =>
              ProductProcessOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      orderguid: json['orderguid'] as String,
      remark: json['remark'] as String,
      isAlacarte: json['isAlacarte'] as bool,
      ordertypes: (json['ordertypes'] as List<dynamic>)
          .map((e) => ProductOrderTypeFromServerModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      foodtype: (json['foodtype'] as num).toInt(),
      issplitunitprint: json['issplitunitprint'] as bool,
      amount: (json['amount'] as num).toDouble(),
      manufacturerguid: json['manufacturerguid'] as String?,
      isonlystaff: json['isonlystaff'] as bool?,
      isforcustomer: json['isforcustomer'] as bool?,
      isexceptvat: json['isexceptvat'] as bool,
    )
      ..issell = json['issell'] as bool
      ..isstockforrestaurant = json['isstockforrestaurant'] as bool
      ..stockqty = (json['stockqty'] as num).toDouble();

Map<String, dynamic> _$ProductProcessModelToJson(
        ProductProcessModel instance) =>
    <String, dynamic>{
      'type': instance.type,
      'code': instance.code,
      'barcode': instance.barcode,
      'unitcode': instance.unitcode,
      'unitnames': instance.unitnames.map((e) => e.toJson()).toList(),
      'names': instance.names.map((e) => e.toJson()).toList(),
      'setprice': instance.setprice,
      'prices': instance.prices.map((e) => e.toJson()).toList(),
      'imageuri': instance.imageuri,
      'refcategoryguid': instance.refcategoryguid,
      'qty': instance.qty,
      'options': instance.options.map((e) => e.toJson()).toList(),
      'orderguid': instance.orderguid,
      'remark': instance.remark,
      'isAlacarte': instance.isAlacarte,
      'ordertypes': instance.ordertypes.map((e) => e.toJson()).toList(),
      'foodtype': instance.foodtype,
      'discountword': instance.discountword,
      'manufacturerguid': instance.manufacturerguid,
      'isonlystaff': instance.isonlystaff,
      'isforcustomer': instance.isforcustomer,
      'issell': instance.issell,
      'isstockforrestaurant': instance.isstockforrestaurant,
      'stockqty': instance.stockqty,
      'issplitunitprint': instance.issplitunitprint,
      'amount': instance.amount,
      'isexceptvat': instance.isexceptvat,
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
      qty: (json['qty'] as num?)?.toDouble(),
      selected: json['selected'] as bool,
      priceValue: (json['priceValue'] as num).toDouble(),
      imageuri: json['imageuri'] as String,
      discountWord: json['discountWord'] as String,
      amount: (json['amount'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num).toDouble(),
      refbarcode: json['refbarcode'] as String?,
      refunitcode: json['refunitcode'] as String?,
      refunitnames: (json['refunitnames'] as List<dynamic>?)
          ?.map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      vatcal: (json['vatcal'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProductProcessOptionChoiceModelToJson(
        ProductProcessOptionChoiceModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'price': instance.price,
      'qty': instance.qty,
      'discountWord': instance.discountWord,
      'refbarcode': instance.refbarcode,
      'refunitcode': instance.refunitcode,
      'selected': instance.selected,
      'priceValue': instance.priceValue,
      'imageuri': instance.imageuri,
      'amount': instance.amount,
      'discountAmount': instance.discountAmount,
      'vatcal': instance.vatcal,
      'refunitnames': instance.refunitnames.map((e) => e.toJson()).toList(),
    };
