import 'package:json_annotation/json_annotation.dart';

part 'barcodemaster_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BarcodeMasterModel {
  String guidfixed;
  String itemcode;
  String itemunitcode;
  List<ItemUnitName> itemunitnames;
  bool ismainitem;
  bool ismainbarcode;
  String groupcode;
  List<GroupName> groupnames;
  String barcode;
  List<ItemName> names;
  List<PriceInfo> prices;
  String imageuri;
  bool useimageorcolor;
  String colorselect;
  String colorselecthex;
  List<dynamic> options;
  String parentguid;
  int itemtype;
  int taxtype;
  int vattype;
  bool issumpoint;
  String maxdiscount;
  bool isdividend;
  List<dynamic> barcodes;
  bool isusesubbarcodes;
  bool condition;
  int standvalue;
  int dividevalue;
  int vatcal;
  List<dynamic> refbarcodes;
  List<dynamic> bom;
  bool isalacarte;
  List<dynamic> ordertypes;
  bool issplitunitprint;
  bool isonlystaff;
  ProductType producttype;
  int foodtype;
  int showisdividend;
  int rownumber;
  String discount;
  bool isstockforrestaurant;
  String manufacturerguid;
  String manufacturercode;
  List<ManufacturerName> manufacturernames;
  List<dynamic> dimensions;
  List<BusinessType> businesstypes;
  List<dynamic> ignorebranches;
  List<dynamic> branches;
  bool isdiscountpointofpurchase;
  Restaurant restaurant;
  bool isalert;
  String alertdescription;
  String description;
  bool isdisable;
  List<dynamic> categorys;
  List<dynamic> timeforsales;
  List<dynamic> fixedcost;
  int materialtype;
  String refguidfixed;
  BarcodeMasterModel({
    String? guidfixed,
    String? itemcode,
    String? itemunitcode,
    List<ItemUnitName>? itemunitnames,
    bool? ismainitem,
    bool? ismainbarcode,
    String? groupcode,
    List<GroupName>? groupnames,
    String? barcode,
    List<ItemName>? names,
    List<PriceInfo>? prices,
    String? imageuri,
    bool? useimageorcolor,
    String? colorselect,
    String? colorselecthex,
    List<dynamic>? options,
    String? parentguid,
    int? itemtype,
    int? taxtype,
    int? vattype,
    bool? issumpoint,
    String? maxdiscount,
    bool? isdividend,
    List<dynamic>? barcodes,
    bool? isusesubbarcodes,
    bool? condition,
    int? standvalue,
    int? dividevalue,
    int? vatcal,
    List<dynamic>? refbarcodes,
    List<dynamic>? bom,
    bool? isalacarte,
    List<dynamic>? ordertypes,
    bool? issplitunitprint,
    bool? isonlystaff,
    ProductType? producttype,
    int? foodtype,
    int? showisdividend,
    int? rownumber,
    String? discount,
    bool? isstockforrestaurant,
    String? manufacturerguid,
    String? manufacturercode,
    List<ManufacturerName>? manufacturernames,
    List<dynamic>? dimensions,
    List<BusinessType>? businesstypes,
    List<dynamic>? ignorebranches,
    List<dynamic>? branches,
    bool? isdiscountpointofpurchase,
    Restaurant? restaurant,
    bool? isalert,
    String? alertdescription,
    String? description,
    bool? isdisable,
    List<dynamic>? categorys,
    List<dynamic>? timeforsales,
    List<dynamic>? fixedcost,
    int? materialtype,
    String? refguidfixed,
  })  : guidfixed = guidfixed ?? "",
        itemcode = itemcode ?? "",
        itemunitcode = itemunitcode ?? "",
        itemunitnames = itemunitnames ?? [],
        ismainitem = ismainitem ?? false,
        groupcode = groupcode ?? "",
        groupnames = groupnames ?? [],
        barcode = barcode ?? "",
        names = names ?? [],
        ismainbarcode = ismainbarcode ?? false,
        prices = prices ??
            [
              PriceInfo(keynumber: 1, price: 0),
              PriceInfo(keynumber: 2, price: 0),
            ],
        imageuri = imageuri ?? "",
        useimageorcolor = useimageorcolor ?? true,
        colorselect = colorselect ?? "",
        colorselecthex = colorselecthex ?? "",
        options = options ?? [],
        parentguid = parentguid ?? "",
        itemtype = itemtype ?? 0,
        taxtype = taxtype ?? 0,
        vattype = vattype ?? 0,
        issumpoint = issumpoint ?? true,
        maxdiscount = maxdiscount ?? "",
        isdividend = isdividend ?? false,
        barcodes = barcodes ?? [],
        isusesubbarcodes = isusesubbarcodes ?? false,
        condition = condition ?? false,
        standvalue = standvalue ?? 1,
        dividevalue = dividevalue ?? 1,
        vatcal = vatcal ?? 0,
        refbarcodes = refbarcodes ?? [],
        bom = bom ?? [],
        isalacarte = isalacarte ?? true,
        ordertypes = ordertypes ?? [],
        issplitunitprint = issplitunitprint ?? true,
        isonlystaff = isonlystaff ?? false,
        producttype = producttype ?? ProductType(guidfixed: "", code: "", names: []),
        foodtype = foodtype ?? 0,
        showisdividend = showisdividend ?? 0,
        rownumber = rownumber ?? 0,
        discount = discount ?? "",
        isstockforrestaurant = isstockforrestaurant ?? false,
        manufacturerguid = manufacturerguid ?? "",
        manufacturercode = manufacturercode ?? "",
        manufacturernames = manufacturernames ?? [],
        dimensions = dimensions ?? [],
        businesstypes = businesstypes ?? [],
        ignorebranches = ignorebranches ?? [],
        branches = branches ?? [],
        isdiscountpointofpurchase = isdiscountpointofpurchase ?? true,
        restaurant = restaurant ??
            Restaurant(
              isforrestaurant: true,
              isfortakeaway: true,
              isfordelivery: true,
              isforcustomer: true,
              isforcustomerpreorder: true,
            ),
        isalert = isalert ?? false,
        alertdescription = alertdescription ?? "",
        description = description ?? "",
        isdisable = isdisable ?? false,
        categorys = categorys ?? [],
        timeforsales = timeforsales ?? [],
        fixedcost = fixedcost ?? [],
        materialtype = materialtype ?? 0,
        refguidfixed = refguidfixed ?? "";

  factory BarcodeMasterModel.fromJson(Map<String, dynamic> json) => _$BarcodeMasterModelFromJson(json);
  Map<String, dynamic> toJson() => _$BarcodeMasterModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ItemUnitName {
  String code;
  String name;
  ItemUnitName({
    required this.code,
    required this.name,
  });

  factory ItemUnitName.fromJson(Map<String, dynamic> json) => _$ItemUnitNameFromJson(json);
  Map<String, dynamic> toJson() => _$ItemUnitNameToJson(this);
}

@JsonSerializable(explicitToJson: true)
class GroupName {
  String code;
  String name;
  GroupName({
    required this.code,
    required this.name,
  });

  factory GroupName.fromJson(Map<String, dynamic> json) => _$GroupNameFromJson(json);
  Map<String, dynamic> toJson() => _$GroupNameToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ItemName {
  String code;
  String name;
  ItemName({
    required this.code,
    required this.name,
  });

  factory ItemName.fromJson(Map<String, dynamic> json) => _$ItemNameFromJson(json);
  Map<String, dynamic> toJson() => _$ItemNameToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PriceInfo {
  int keynumber;
  double price;
  PriceInfo({
    required this.keynumber,
    required this.price,
  });

  factory PriceInfo.fromJson(Map<String, dynamic> json) => _$PriceInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PriceInfoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductType {
  String guidfixed;
  String code;
  List<ProductTypeName> names;
  ProductType({
    required this.guidfixed,
    required this.code,
    required this.names,
  });

  factory ProductType.fromJson(Map<String, dynamic> json) => _$ProductTypeFromJson(json);
  Map<String, dynamic> toJson() => _$ProductTypeToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductTypeName {
  String code;
  String name;
  ProductTypeName({
    required this.code,
    required this.name,
  });

  factory ProductTypeName.fromJson(Map<String, dynamic> json) => _$ProductTypeNameFromJson(json);
  Map<String, dynamic> toJson() => _$ProductTypeNameToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ManufacturerName {
  String code;
  String name;

  ManufacturerName({
    required this.code,
    required this.name,
  });

  factory ManufacturerName.fromJson(Map<String, dynamic> json) => _$ManufacturerNameFromJson(json);
  Map<String, dynamic> toJson() => _$ManufacturerNameToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BusinessType {
  String guidfixed;
  String code;
  List<BusinessTypeName> names;
  bool isdefault;

  BusinessType({
    required this.guidfixed,
    required this.code,
    required this.names,
    required this.isdefault,
  });

  factory BusinessType.fromJson(Map<String, dynamic> json) => _$BusinessTypeFromJson(json);
  Map<String, dynamic> toJson() => _$BusinessTypeToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BusinessTypeName {
  String code;
  String name;

  BusinessTypeName({
    required this.code,
    required this.name,
  });

  factory BusinessTypeName.fromJson(Map<String, dynamic> json) => _$BusinessTypeNameFromJson(json);
  Map<String, dynamic> toJson() => _$BusinessTypeNameToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Restaurant {
  bool isforrestaurant;
  bool isfortakeaway;
  bool isfordelivery;
  bool isforcustomer;
  bool isforcustomerpreorder;

  Restaurant({
    required this.isforrestaurant,
    required this.isfortakeaway,
    required this.isfordelivery,
    required this.isforcustomer,
    required this.isforcustomerpreorder,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => _$RestaurantFromJson(json);
  Map<String, dynamic> toJson() => _$RestaurantToJson(this);
}

@JsonSerializable()
class CouponModel {
  final String guidfixed;
  final String couponcode;
  final List<CouponName> names;
  final double couponvalue;
  final DateTime issueddate;
  final DateTime expirydate;
  final int coupontype;
  final List<String> customercodes;
  final String remark;
  final int status;
  final bool isonetimeuse;
  final int maxusagecount;
  final int maxusagecountpercustomer;

  const CouponModel({
    required this.guidfixed,
    required this.couponcode,
    required this.names,
    required this.couponvalue,
    required this.issueddate,
    required this.expirydate,
    required this.coupontype,
    required this.customercodes,
    required this.remark,
    required this.status,
    required this.isonetimeuse,
    required this.maxusagecount,
    required this.maxusagecountpercustomer,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) => _$CouponModelFromJson(json);
  Map<String, dynamic> toJson() => _$CouponModelToJson(this);
}

@JsonSerializable()
class CouponName {
  final String code;
  final String name;
  final bool isauto;
  final bool isdelete;

  const CouponName({
    required this.code,
    required this.name,
    required this.isauto,
    required this.isdelete,
  });

  factory CouponName.fromJson(Map<String, dynamic> json) => _$CouponNameFromJson(json);
  Map<String, dynamic> toJson() => _$CouponNameToJson(this);
}
