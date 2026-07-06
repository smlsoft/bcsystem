// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barcodemaster_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BarcodeMasterModel _$BarcodeMasterModelFromJson(Map<String, dynamic> json) =>
    BarcodeMasterModel(
      guidfixed: json['guidfixed'] as String?,
      itemcode: json['itemcode'] as String?,
      itemunitcode: json['itemunitcode'] as String?,
      itemunitnames: (json['itemunitnames'] as List<dynamic>?)
          ?.map((e) => ItemUnitName.fromJson(e as Map<String, dynamic>))
          .toList(),
      ismainitem: json['ismainitem'] as bool?,
      ismainbarcode: json['ismainbarcode'] as bool?,
      groupcode: json['groupcode'] as String?,
      groupnames: (json['groupnames'] as List<dynamic>?)
          ?.map((e) => GroupName.fromJson(e as Map<String, dynamic>))
          .toList(),
      barcode: json['barcode'] as String?,
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => ItemName.fromJson(e as Map<String, dynamic>))
          .toList(),
      prices: (json['prices'] as List<dynamic>?)
          ?.map((e) => PriceInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageuri: json['imageuri'] as String?,
      useimageorcolor: json['useimageorcolor'] as bool?,
      colorselect: json['colorselect'] as String?,
      colorselecthex: json['colorselecthex'] as String?,
      options: json['options'] as List<dynamic>?,
      parentguid: json['parentguid'] as String?,
      itemtype: (json['itemtype'] as num?)?.toInt(),
      taxtype: (json['taxtype'] as num?)?.toInt(),
      vattype: (json['vattype'] as num?)?.toInt(),
      issumpoint: json['issumpoint'] as bool?,
      maxdiscount: json['maxdiscount'] as String?,
      isdividend: json['isdividend'] as bool?,
      barcodes: json['barcodes'] as List<dynamic>?,
      isusesubbarcodes: json['isusesubbarcodes'] as bool?,
      condition: json['condition'] as bool?,
      standvalue: (json['standvalue'] as num?)?.toInt(),
      dividevalue: (json['dividevalue'] as num?)?.toInt(),
      vatcal: (json['vatcal'] as num?)?.toInt(),
      refbarcodes: json['refbarcodes'] as List<dynamic>?,
      bom: json['bom'] as List<dynamic>?,
      isalacarte: json['isalacarte'] as bool?,
      ordertypes: json['ordertypes'] as List<dynamic>?,
      issplitunitprint: json['issplitunitprint'] as bool?,
      isonlystaff: json['isonlystaff'] as bool?,
      producttype: json['producttype'] == null
          ? null
          : ProductType.fromJson(json['producttype'] as Map<String, dynamic>),
      foodtype: (json['foodtype'] as num?)?.toInt(),
      showisdividend: (json['showisdividend'] as num?)?.toInt(),
      rownumber: (json['rownumber'] as num?)?.toInt(),
      discount: json['discount'] as String?,
      isstockforrestaurant: json['isstockforrestaurant'] as bool?,
      manufacturerguid: json['manufacturerguid'] as String?,
      manufacturercode: json['manufacturercode'] as String?,
      manufacturernames: (json['manufacturernames'] as List<dynamic>?)
          ?.map((e) => ManufacturerName.fromJson(e as Map<String, dynamic>))
          .toList(),
      dimensions: json['dimensions'] as List<dynamic>?,
      businesstypes: (json['businesstypes'] as List<dynamic>?)
          ?.map((e) => BusinessType.fromJson(e as Map<String, dynamic>))
          .toList(),
      ignorebranches: json['ignorebranches'] as List<dynamic>?,
      branches: json['branches'] as List<dynamic>?,
      isdiscountpointofpurchase: json['isdiscountpointofpurchase'] as bool?,
      restaurant: json['restaurant'] == null
          ? null
          : Restaurant.fromJson(json['restaurant'] as Map<String, dynamic>),
      isalert: json['isalert'] as bool?,
      alertdescription: json['alertdescription'] as String?,
      description: json['description'] as String?,
      isdisable: json['isdisable'] as bool?,
      categorys: json['categorys'] as List<dynamic>?,
      timeforsales: json['timeforsales'] as List<dynamic>?,
      fixedcost: json['fixedcost'] as List<dynamic>?,
      materialtype: (json['materialtype'] as num?)?.toInt(),
      refguidfixed: json['refguidfixed'] as String?,
    );

Map<String, dynamic> _$BarcodeMasterModelToJson(BarcodeMasterModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'itemcode': instance.itemcode,
      'itemunitcode': instance.itemunitcode,
      'itemunitnames': instance.itemunitnames.map((e) => e.toJson()).toList(),
      'ismainitem': instance.ismainitem,
      'ismainbarcode': instance.ismainbarcode,
      'groupcode': instance.groupcode,
      'groupnames': instance.groupnames.map((e) => e.toJson()).toList(),
      'barcode': instance.barcode,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'prices': instance.prices.map((e) => e.toJson()).toList(),
      'imageuri': instance.imageuri,
      'useimageorcolor': instance.useimageorcolor,
      'colorselect': instance.colorselect,
      'colorselecthex': instance.colorselecthex,
      'options': instance.options,
      'parentguid': instance.parentguid,
      'itemtype': instance.itemtype,
      'taxtype': instance.taxtype,
      'vattype': instance.vattype,
      'issumpoint': instance.issumpoint,
      'maxdiscount': instance.maxdiscount,
      'isdividend': instance.isdividend,
      'barcodes': instance.barcodes,
      'isusesubbarcodes': instance.isusesubbarcodes,
      'condition': instance.condition,
      'standvalue': instance.standvalue,
      'dividevalue': instance.dividevalue,
      'vatcal': instance.vatcal,
      'refbarcodes': instance.refbarcodes,
      'bom': instance.bom,
      'isalacarte': instance.isalacarte,
      'ordertypes': instance.ordertypes,
      'issplitunitprint': instance.issplitunitprint,
      'isonlystaff': instance.isonlystaff,
      'producttype': instance.producttype.toJson(),
      'foodtype': instance.foodtype,
      'showisdividend': instance.showisdividend,
      'rownumber': instance.rownumber,
      'discount': instance.discount,
      'isstockforrestaurant': instance.isstockforrestaurant,
      'manufacturerguid': instance.manufacturerguid,
      'manufacturercode': instance.manufacturercode,
      'manufacturernames': instance.manufacturernames
          .map((e) => e.toJson())
          .toList(),
      'dimensions': instance.dimensions,
      'businesstypes': instance.businesstypes.map((e) => e.toJson()).toList(),
      'ignorebranches': instance.ignorebranches,
      'branches': instance.branches,
      'isdiscountpointofpurchase': instance.isdiscountpointofpurchase,
      'restaurant': instance.restaurant.toJson(),
      'isalert': instance.isalert,
      'alertdescription': instance.alertdescription,
      'description': instance.description,
      'isdisable': instance.isdisable,
      'categorys': instance.categorys,
      'timeforsales': instance.timeforsales,
      'fixedcost': instance.fixedcost,
      'materialtype': instance.materialtype,
      'refguidfixed': instance.refguidfixed,
    };

ItemUnitName _$ItemUnitNameFromJson(Map<String, dynamic> json) =>
    ItemUnitName(code: json['code'] as String, name: json['name'] as String);

Map<String, dynamic> _$ItemUnitNameToJson(ItemUnitName instance) =>
    <String, dynamic>{'code': instance.code, 'name': instance.name};

GroupName _$GroupNameFromJson(Map<String, dynamic> json) =>
    GroupName(code: json['code'] as String, name: json['name'] as String);

Map<String, dynamic> _$GroupNameToJson(GroupName instance) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
};

ItemName _$ItemNameFromJson(Map<String, dynamic> json) =>
    ItemName(code: json['code'] as String, name: json['name'] as String);

Map<String, dynamic> _$ItemNameToJson(ItemName instance) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
};

PriceInfo _$PriceInfoFromJson(Map<String, dynamic> json) => PriceInfo(
  keynumber: (json['keynumber'] as num).toInt(),
  price: (json['price'] as num).toDouble(),
);

Map<String, dynamic> _$PriceInfoToJson(PriceInfo instance) => <String, dynamic>{
  'keynumber': instance.keynumber,
  'price': instance.price,
};

ProductType _$ProductTypeFromJson(Map<String, dynamic> json) => ProductType(
  guidfixed: json['guidfixed'] as String,
  code: json['code'] as String,
  names: (json['names'] as List<dynamic>)
      .map((e) => ProductTypeName.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProductTypeToJson(ProductType instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'code': instance.code,
      'names': instance.names.map((e) => e.toJson()).toList(),
    };

ProductTypeName _$ProductTypeNameFromJson(Map<String, dynamic> json) =>
    ProductTypeName(code: json['code'] as String, name: json['name'] as String);

Map<String, dynamic> _$ProductTypeNameToJson(ProductTypeName instance) =>
    <String, dynamic>{'code': instance.code, 'name': instance.name};

ManufacturerName _$ManufacturerNameFromJson(Map<String, dynamic> json) =>
    ManufacturerName(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$ManufacturerNameToJson(ManufacturerName instance) =>
    <String, dynamic>{'code': instance.code, 'name': instance.name};

BusinessType _$BusinessTypeFromJson(Map<String, dynamic> json) => BusinessType(
  guidfixed: json['guidfixed'] as String,
  code: json['code'] as String,
  names: (json['names'] as List<dynamic>)
      .map((e) => BusinessTypeName.fromJson(e as Map<String, dynamic>))
      .toList(),
  isdefault: json['isdefault'] as bool,
);

Map<String, dynamic> _$BusinessTypeToJson(BusinessType instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'code': instance.code,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'isdefault': instance.isdefault,
    };

BusinessTypeName _$BusinessTypeNameFromJson(Map<String, dynamic> json) =>
    BusinessTypeName(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$BusinessTypeNameToJson(BusinessTypeName instance) =>
    <String, dynamic>{'code': instance.code, 'name': instance.name};

Restaurant _$RestaurantFromJson(Map<String, dynamic> json) => Restaurant(
  isforrestaurant: json['isforrestaurant'] as bool,
  isfortakeaway: json['isfortakeaway'] as bool,
  isfordelivery: json['isfordelivery'] as bool,
  isforcustomer: json['isforcustomer'] as bool,
  isforcustomerpreorder: json['isforcustomerpreorder'] as bool,
);

Map<String, dynamic> _$RestaurantToJson(Restaurant instance) =>
    <String, dynamic>{
      'isforrestaurant': instance.isforrestaurant,
      'isfortakeaway': instance.isfortakeaway,
      'isfordelivery': instance.isfordelivery,
      'isforcustomer': instance.isforcustomer,
      'isforcustomerpreorder': instance.isforcustomerpreorder,
    };

CouponModel _$CouponModelFromJson(Map<String, dynamic> json) => CouponModel(
  guidfixed: json['guidfixed'] as String,
  couponcode: json['couponcode'] as String,
  names: (json['names'] as List<dynamic>)
      .map((e) => CouponName.fromJson(e as Map<String, dynamic>))
      .toList(),
  couponvalue: (json['couponvalue'] as num).toDouble(),
  issueddate: DateTime.parse(json['issueddate'] as String),
  expirydate: DateTime.parse(json['expirydate'] as String),
  coupontype: (json['coupontype'] as num).toInt(),
  customercodes: (json['customercodes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  remark: json['remark'] as String,
  status: (json['status'] as num).toInt(),
  isonetimeuse: json['isonetimeuse'] as bool,
  maxusagecount: (json['maxusagecount'] as num).toInt(),
  maxusagecountpercustomer: (json['maxusagecountpercustomer'] as num).toInt(),
);

Map<String, dynamic> _$CouponModelToJson(CouponModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'couponcode': instance.couponcode,
      'names': instance.names,
      'couponvalue': instance.couponvalue,
      'issueddate': instance.issueddate.toIso8601String(),
      'expirydate': instance.expirydate.toIso8601String(),
      'coupontype': instance.coupontype,
      'customercodes': instance.customercodes,
      'remark': instance.remark,
      'status': instance.status,
      'isonetimeuse': instance.isonetimeuse,
      'maxusagecount': instance.maxusagecount,
      'maxusagecountpercustomer': instance.maxusagecountpercustomer,
    };

CouponName _$CouponNameFromJson(Map<String, dynamic> json) => CouponName(
  code: json['code'] as String,
  name: json['name'] as String,
  isauto: json['isauto'] as bool,
  isdelete: json['isdelete'] as bool,
);

Map<String, dynamic> _$CouponNameToJson(CouponName instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'isauto': instance.isauto,
      'isdelete': instance.isdelete,
    };
