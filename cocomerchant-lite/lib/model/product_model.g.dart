// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
      guidfixed: json['guidfixed'] as String,
      itemcode: json['itemcode'] as String,
      groupcode: json['groupcode'] as String?,
      groupnames: (json['groupnames'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      barcodes: (json['barcodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      useserialnumber: json['useserialnumber'] as bool?,
      units: (json['units'] as List<dynamic>?)
          ?.map((e) => ProductUnitModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      unit: json['unit'] == null
          ? null
          : ProductUnitModel.fromJson(json['unit'] as Map<String, dynamic>),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ImagesModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      unitcost: json['unitcost'] as String?,
      unitcostnames: (json['unitcostnames'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      unitstandard: json['unitstandard'] as String?,
      unitstandardnames: (json['unitstandardnames'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      multiunit: json['multiunit'] as bool?,
      itemstocktype: json['itemstocktype'] as int?,
      vattype: json['vattype'] as int?,
      taxtype: json['taxtype'] as int?,
      issumpoint: json['issumpoint'] as bool?,
      itemtype: json['itemtype'] as int?,
    );

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'itemcode': instance.itemcode,
      'groupcode': instance.groupcode,
      'groupnames': instance.groupnames?.map((e) => e.toJson()).toList(),
      'barcodes': instance.barcodes,
      'names': instance.names?.map((e) => e.toJson()).toList(),
      'multiunit': instance.multiunit,
      'useserialnumber': instance.useserialnumber,
      'units': instance.units?.map((e) => e.toJson()).toList(),
      'unit': instance.unit?.toJson(),
      'images': instance.images?.map((e) => e.toJson()).toList(),
      'unitcost': instance.unitcost,
      'unitcostnames': instance.unitcostnames?.map((e) => e.toJson()).toList(),
      'unitstandard': instance.unitstandard,
      'unitstandardnames':
          instance.unitstandardnames?.map((e) => e.toJson()).toList(),
      'itemstocktype': instance.itemstocktype,
      'itemtype': instance.itemtype,
      'taxtype': instance.taxtype,
      'vattype': instance.vattype,
      'issumpoint': instance.issumpoint,
    };

ProductUnitModel _$ProductUnitModelFromJson(Map<String, dynamic> json) =>
    ProductUnitModel(
      unitcode: json['unitcode'] as String,
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      divider: (json['divider'] as num).toDouble(),
      stand: (json['stand'] as num).toDouble(),
      xorder: json['xorder'] as int,
      stockcount: json['stockcount'] as bool,
    );

Map<String, dynamic> _$ProductUnitModelToJson(ProductUnitModel instance) =>
    <String, dynamic>{
      'unitcode': instance.unitcode,
      'names': instance.names?.map((e) => e.toJson()).toList(),
      'divider': instance.divider,
      'stand': instance.stand,
      'xorder': instance.xorder,
      'stockcount': instance.stockcount,
    };

ProductUnitPriceModel _$ProductUnitPriceModelFromJson(
        Map<String, dynamic> json) =>
    ProductUnitPriceModel(
      unitcode: json['unitcode'] as String,
      prices: (json['prices'] as List<dynamic>)
          .map((e) => PriceDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductUnitPriceModelToJson(
        ProductUnitPriceModel instance) =>
    <String, dynamic>{
      'unitcode': instance.unitcode,
      'prices': instance.prices.map((e) => e.toJson()).toList(),
    };

ProductWareHouseModel _$ProductWareHouseModelFromJson(
        Map<String, dynamic> json) =>
    ProductWareHouseModel(
      code: json['code'] as String,
      locatecodes: (json['locatecodes'] as List<dynamic>)
          .map((e) => ProductLocationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductWareHouseModelToJson(
        ProductWareHouseModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'locatecodes': instance.locatecodes.map((e) => e.toJson()).toList(),
    };

ProductLocationModel _$ProductLocationModelFromJson(
        Map<String, dynamic> json) =>
    ProductLocationModel(
      code: json['code'] as String,
      recommendshelfs: (json['recommendshelfs'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ProductLocationModelToJson(
        ProductLocationModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'recommendshelfs': instance.recommendshelfs,
    };

ProductBarcodeRefModel _$ProductBarcodeRefModelFromJson(
        Map<String, dynamic> json) =>
    ProductBarcodeRefModel(
      refbarcode: json['refbarcode'] as String?,
      qty: (json['qty'] as num?)?.toDouble(),
      stockbarcode: json['stockbarcode'] as String?,
      dividevalue: (json['dividevalue'] as num?)?.toDouble(),
      standvalue: (json['standvalue'] as num?)?.toDouble(),
    )..refunitnames = (json['refunitnames'] as List<dynamic>?)
        ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
        .toList();

Map<String, dynamic> _$ProductBarcodeRefModelToJson(
        ProductBarcodeRefModel instance) =>
    <String, dynamic>{
      'refbarcode': instance.refbarcode,
      'refunitnames': instance.refunitnames?.map((e) => e.toJson()).toList(),
      'stockbarcode': instance.stockbarcode,
      'qty': instance.qty,
      'dividevalue': instance.dividevalue,
      'standvalue': instance.standvalue,
    };

ProductBarcodeModel _$ProductBarcodeModelFromJson(Map<String, dynamic> json) =>
    ProductBarcodeModel(
      guidfixed: json['guidfixed'] as String,
      itemcode: json['itemcode'] as String?,
      groupcode: json['groupcode'] as String?,
      ismainitem: json['ismainitem'] as bool?,
      groupnames: (json['groupnames'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      barcode: json['barcode'] as String?,
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemunitcode: json['itemunitcode'] as String?,
      itemunitnames: (json['itemunitnames'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      prices: (json['prices'] as List<dynamic>?)
          ?.map((e) => PriceDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageuri: json['imageuri'] as String?,
      useimageorcolor: json['useimageorcolor'] as bool?,
      colorselect: json['colorselect'] as String?,
      colorselecthex: json['colorselecthex'] as String?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => ProductOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      parentguid: json['parentguid'] as String?,
      barcodes: (json['barcodes'] as List<dynamic>?)
          ?.map((e) => BarCodeSubModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isusesubbarcodes: json['isusesubbarcodes'] as bool?,
      standvalue: json['standvalue'] as int?,
      dividevalue: json['dividevalue'] as int?,
      condition: json['condition'] as bool?,
      itemtype: json['itemtype'] as int?,
      taxtype: json['taxtype'] as int?,
      vattype: json['vattype'] as int?,
      issumpoint: json['issumpoint'] as bool?,
      maxdiscount: json['maxdiscount'] as String?,
      isdividend: json['isdividend'] as bool?,
      vatcal: json['vatcal'] as int?,
      refbarcodes: (json['refbarcodes'] as List<dynamic>?)
          ?.map((e) => BarCodeSubModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      bom: (json['bom'] as List<dynamic>?)
          ?.map((e) => BomModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isalacarte: json['isalacarte'] as bool?,
      ordertypes: (json['ordertypes'] as List<dynamic>?)
          ?.map((e) =>
              OrderTypeProductBarcode.fromJson(e as Map<String, dynamic>))
          .toList(),
      issplitunitprint: json['issplitunitprint'] as bool?,
      isonlystaff: json['isonlystaff'] as bool?,
      producttype: json['producttype'] == null
          ? null
          : ProductTypeModel.fromJson(
              json['producttype'] as Map<String, dynamic>),
      foodtype: json['foodtype'] as int?,
      showisdividend: json['showisdividend'] as int?,
      rownumber: json['rownumber'] as int?,
      discount: json['discount'] as String?,
      isstockforrestaurant: json['isstockforrestaurant'] as bool?,
      manufacturerguid: json['manufacturerguid'] as String?,
      manufacturer: json['manufacturer'] == null
          ? null
          : SearchGuidCodeNameModel.fromJson(
              json['manufacturer'] as Map<String, dynamic>),
      dimensions: (json['dimensions'] as List<dynamic>?)
          ?.map(
              (e) => DimensionProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      businesstypes: (json['businesstypes'] as List<dynamic>?)
          ?.map((e) => BusinessTypeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      ignorebranches: (json['ignorebranches'] as List<dynamic>?)
          ?.map((e) => BranchModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      branches: (json['branches'] as List<dynamic>?)
          ?.map((e) => CompanyBranchModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isdiscountpointofpurchase: json['isdiscountpointofpurchase'] as bool?,
      restaurant: json['restaurant'] == null
          ? null
          : ProductBarcodeRestaurantModel.fromJson(
              json['restaurant'] as Map<String, dynamic>),
      isalert: json['isalert'] as bool?,
      alertdescription: json['alertdescription'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ProductBarcodeModelToJson(
        ProductBarcodeModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'itemcode': instance.itemcode,
      'itemunitcode': instance.itemunitcode,
      'itemunitnames': instance.itemunitnames?.map((e) => e.toJson()).toList(),
      'ismainitem': instance.ismainitem,
      'groupcode': instance.groupcode,
      'groupnames': instance.groupnames?.map((e) => e.toJson()).toList(),
      'barcode': instance.barcode,
      'names': instance.names?.map((e) => e.toJson()).toList(),
      'prices': instance.prices?.map((e) => e.toJson()).toList(),
      'imageuri': instance.imageuri,
      'useimageorcolor': instance.useimageorcolor,
      'colorselect': instance.colorselect,
      'colorselecthex': instance.colorselecthex,
      'options': instance.options?.map((e) => e.toJson()).toList(),
      'parentguid': instance.parentguid,
      'itemtype': instance.itemtype,
      'taxtype': instance.taxtype,
      'vattype': instance.vattype,
      'issumpoint': instance.issumpoint,
      'maxdiscount': instance.maxdiscount,
      'isdividend': instance.isdividend,
      'barcodes': instance.barcodes?.map((e) => e.toJson()).toList(),
      'isusesubbarcodes': instance.isusesubbarcodes,
      'condition': instance.condition,
      'standvalue': instance.standvalue,
      'dividevalue': instance.dividevalue,
      'vatcal': instance.vatcal,
      'refbarcodes': instance.refbarcodes?.map((e) => e.toJson()).toList(),
      'bom': instance.bom?.map((e) => e.toJson()).toList(),
      'isalacarte': instance.isalacarte,
      'ordertypes': instance.ordertypes?.map((e) => e.toJson()).toList(),
      'issplitunitprint': instance.issplitunitprint,
      'isonlystaff': instance.isonlystaff,
      'producttype': instance.producttype?.toJson(),
      'foodtype': instance.foodtype,
      'showisdividend': instance.showisdividend,
      'rownumber': instance.rownumber,
      'discount': instance.discount,
      'isstockforrestaurant': instance.isstockforrestaurant,
      'manufacturerguid': instance.manufacturerguid,
      'manufacturer': instance.manufacturer?.toJson(),
      'dimensions': instance.dimensions?.map((e) => e.toJson()).toList(),
      'businesstypes': instance.businesstypes?.map((e) => e.toJson()).toList(),
      'ignorebranches':
          instance.ignorebranches?.map((e) => e.toJson()).toList(),
      'branches': instance.branches?.map((e) => e.toJson()).toList(),
      'isdiscountpointofpurchase': instance.isdiscountpointofpurchase,
      'restaurant': instance.restaurant?.toJson(),
      'isalert': instance.isalert,
      'alertdescription': instance.alertdescription,
      'description': instance.description,
    };

BarCodeSubModel _$BarCodeSubModelFromJson(Map<String, dynamic> json) =>
    BarCodeSubModel(
      guidfixed: json['guidfixed'] as String?,
      barcode: json['barcode'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemunitcode: json['itemunitcode'] as String,
      itemunitnames: (json['itemunitnames'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      condition: json['condition'] as bool,
      standvalue: json['standvalue'] as int,
      dividevalue: json['dividevalue'] as int,
      qty: json['qty'] as int,
    );

Map<String, dynamic> _$BarCodeSubModelToJson(BarCodeSubModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'barcode': instance.barcode,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'itemunitnames': instance.itemunitnames.map((e) => e.toJson()).toList(),
      'itemunitcode': instance.itemunitcode,
      'condition': instance.condition,
      'standvalue': instance.standvalue,
      'dividevalue': instance.dividevalue,
      'qty': instance.qty,
    };

BomModel _$BomModelFromJson(Map<String, dynamic> json) => BomModel(
      guidfixed: json['guidfixed'] as String?,
      barcode: json['barcode'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemunitcode: json['itemunitcode'] as String,
      itemunitnames: (json['itemunitnames'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      condition: json['condition'] as bool,
      standvalue: json['standvalue'] as int,
      dividevalue: json['dividevalue'] as int,
      qty: (json['qty'] as num).toDouble(),
    );

Map<String, dynamic> _$BomModelToJson(BomModel instance) => <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'barcode': instance.barcode,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'itemunitnames': instance.itemunitnames.map((e) => e.toJson()).toList(),
      'itemunitcode': instance.itemunitcode,
      'condition': instance.condition,
      'standvalue': instance.standvalue,
      'dividevalue': instance.dividevalue,
      'qty': instance.qty,
    };

ProductChoiceModel _$ProductChoiceModelFromJson(Map<String, dynamic> json) =>
    ProductChoiceModel(
      guid: json['guid'] as String,
      refbarcode: json['refbarcode'] as String,
      refproductcode: json['refproductcode'] as String,
      refunitcode: json['refunitcode'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isstock: json['isstock'] as bool,
      price: json['price'] as String,
      qty: (json['qty'] as num).toDouble(),
      imageuri: json['imageuri'] as String?,
      isdefault: json['isdefault'] as bool?,
      refbarcodenames: (json['refbarcodenames'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      refunitnames: (json['refunitnames'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      vatcal: json['vatcal'] as int?,
    );

Map<String, dynamic> _$ProductChoiceModelToJson(ProductChoiceModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'price': instance.price,
      'isstock': instance.isstock,
      'refbarcode': instance.refbarcode,
      'refproductcode': instance.refproductcode,
      'refunitcode': instance.refunitcode,
      'refunitnames': instance.refunitnames?.map((e) => e.toJson()).toList(),
      'qty': instance.qty,
      'imageuri': instance.imageuri,
      'isdefault': instance.isdefault,
      'refbarcodenames':
          instance.refbarcodenames?.map((e) => e.toJson()).toList(),
      'vatcal': instance.vatcal,
    };

ProductOptionModel _$ProductOptionModelFromJson(Map<String, dynamic> json) =>
    ProductOptionModel(
      guid: json['guid'] as String,
      choicetype: json['choicetype'] as int,
      maxselect: json['maxselect'] as int,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      minselect: json['minselect'] as int,
      choices: (json['choices'] as List<dynamic>)
          .map((e) => ProductChoiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductOptionModelToJson(ProductOptionModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'choicetype': instance.choicetype,
      'minselect': instance.minselect,
      'maxselect': instance.maxselect,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'choices': instance.choices.map((e) => e.toJson()).toList(),
    };

UnitModel _$UnitModelFromJson(Map<String, dynamic> json) => UnitModel(
      unitcode: json['unitcode'] as String?,
      guidfixed: json['guidfixed'] as String?,
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UnitModelToJson(UnitModel instance) => <String, dynamic>{
      'unitcode': instance.unitcode,
      'guidfixed': instance.guidfixed,
      'names': instance.names?.map((e) => e.toJson()).toList(),
    };

OrderTypeProductBarcode _$OrderTypeProductBarcodeFromJson(
        Map<String, dynamic> json) =>
    OrderTypeProductBarcode(
      guidfixed: json['guidfixed'] as String,
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      price: (json['price'] as num).toDouble(),
    );

Map<String, dynamic> _$OrderTypeProductBarcodeToJson(
        OrderTypeProductBarcode instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'code': instance.code,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'price': instance.price,
    };

ProductBarcodeRestaurantModel _$ProductBarcodeRestaurantModelFromJson(
        Map<String, dynamic> json) =>
    ProductBarcodeRestaurantModel(
      isforrestaurant: json['isforrestaurant'] as bool?,
      isfortakeaway: json['isfortakeaway'] as bool?,
      isfordelivery: json['isfordelivery'] as bool?,
      isforcustomer: json['isforcustomer'] as bool?,
      isforcustomerpreorder: json['isforcustomerpreorder'] as bool?,
    );

Map<String, dynamic> _$ProductBarcodeRestaurantModelToJson(
        ProductBarcodeRestaurantModel instance) =>
    <String, dynamic>{
      'isforrestaurant': instance.isforrestaurant,
      'isfortakeaway': instance.isfortakeaway,
      'isfordelivery': instance.isfordelivery,
      'isforcustomer': instance.isforcustomer,
      'isforcustomerpreorder': instance.isforcustomerpreorder,
    };
