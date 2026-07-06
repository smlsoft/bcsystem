import 'package:dedekiosk/model/category_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductModel {
  final String guidfixed;

  ProductModel({
    required this.guidfixed,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}

@JsonSerializable()
class ProductResponseModel {
  final List<ProductFromServerModel> data;

  ProductResponseModel({
    required this.data,
  });

  factory ProductResponseModel.fromJson(Map<String, dynamic> json) => _$ProductResponseModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductResponseModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductRestaurantModel {
  final bool isforrestaurant;
  final bool isfortakeaway;
  final bool isfordelivery;
  final bool isforcustomer;
  final bool isforcustomerpreorder;

  ProductRestaurantModel({
    bool? isforrestaurant,
    bool? isfortakeaway,
    bool? isfordelivery,
    bool? isforcustomer,
    bool? isforcustomerpreorder,
  })  : isforrestaurant = isforrestaurant ?? false,
        isfortakeaway = isfortakeaway ?? false,
        isfordelivery = isfordelivery ?? false,
        isforcustomer = isforcustomer ?? false,
        isforcustomerpreorder = isforcustomerpreorder ?? false;

  factory ProductRestaurantModel.fromJson(Map<String, dynamic> json) => _$ProductRestaurantModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductRestaurantModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductFromServerModel {
  final String barcode;
  final String imageuri;
  final List<LanguageNameModel> itemunitnames;
  final String itemunitcode;
  bool isonlystaff;
  final List<ProductOptionModel>? options;
  final List<ProductPriceFromServerModel> prices;
  final List<ProductOrderTypeFromServerModel>? ordertypes;
  final bool? isalacarte;
  final int? foodtype;
  final String? discount;
  final bool? isstockforrestaurant;
  String manufacturerguid;
  ProductRestaurantModel restaurant;

  /// สินค้ายกเว้นภาษี (True=ยกเว้นภาษี,False=ไม่ยกเว้นภาษี)
  bool is_except_vat;

  int vatcal;

  ProductFromServerModel(
      {required this.barcode,
      required this.imageuri,
      List<LanguageNameModel>? itemunitnames,
      required this.itemunitcode,
      required this.options,
      List<ProductPriceFromServerModel>? prices,
      required this.ordertypes,
      required this.isalacarte,
      required this.foodtype,
      required this.discount,
      required this.isstockforrestaurant,
      String? manufacturerguid,
      bool? isforcustomer,
      bool? isonlystaff,
      bool? is_except_vat,
      int? vatcal,
      ProductRestaurantModel? restaurant})
      : manufacturerguid = manufacturerguid ?? '',
        itemunitnames = itemunitnames ?? [],
        is_except_vat = is_except_vat ?? false,
        isonlystaff = isonlystaff ?? false,
        vatcal = vatcal ?? 0,
        restaurant = restaurant ?? ProductRestaurantModel(isforcustomer: false, isforcustomerpreorder: false, isfordelivery: false, isfortakeaway: false, isforrestaurant: false),
        prices = prices ?? [ProductPriceFromServerModel(keynumber: 1, price: 0.0)];

  factory ProductFromServerModel.fromJson(Map<String, dynamic> json) => _$ProductFromServerModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductFromServerModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductPriceFromServerModel {
  final int keynumber;
  double price;

  ProductPriceFromServerModel({
    required this.keynumber,
    required this.price,
  });

  factory ProductPriceFromServerModel.fromJson(Map<String, dynamic> json) => _$ProductPriceFromServerModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductPriceFromServerModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductOrderTypeFromServerModel {
  final String code;
  final List<LanguageNameModel> names;
  final double price;

  ProductOrderTypeFromServerModel({
    required this.code,
    required this.names,
    required this.price,
  });

  factory ProductOrderTypeFromServerModel.fromJson(Map<String, dynamic> json) => _$ProductOrderTypeFromServerModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductOrderTypeFromServerModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductOptionModel {
  final String guid;
  final int choicetype;
  final int maxselect;
  final int minselect;
  final List<LanguageNameModel> names;
  final List<ProductOptionChoiceModel> choices;

  ProductOptionModel({
    required this.guid,
    required this.choicetype,
    required this.maxselect,
    required this.minselect,
    required this.names,
    required this.choices,
  });

  factory ProductOptionModel.fromJson(Map<String, dynamic> json) => _$ProductOptionModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductOptionModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransOptionsModel {
  String barcode;
  String item_code;
  String item_name;
  String unit_code;
  String unit_name;
  double qty;
  double price;
  double total_amount;
  bool is_except_vat;
  int vat_type;
  double price_exclude_vat;

  TransOptionsModel({
    String? barcode,
    String? item_code,
    String? item_name,
    String? unit_code,
    String? unit_name,
    double? qty,
    double? price,
    double? total_amount,
    bool? is_except_vat,
    int? vat_type,
    double? price_exclude_vat,
  })  : barcode = barcode ?? '',
        item_code = item_code ?? '',
        item_name = item_name ?? '',
        unit_code = unit_code ?? '',
        unit_name = unit_name ?? '',
        qty = qty ?? 0,
        price = price ?? 0,
        total_amount = total_amount ?? 0,
        is_except_vat = is_except_vat ?? false,
        vat_type = vat_type ?? 0,
        price_exclude_vat = price_exclude_vat ?? 0;

  factory TransOptionsModel.fromJson(Map<String, dynamic> json) => _$TransOptionsModelFromJson(json);
  Map<String, dynamic> toJson() => _$TransOptionsModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductOptionChoiceModel {
  final String guid;
  final List<LanguageNameModel> names;
  final String price;
  final double qty;
  final String imageuri;
  String refbarcode;
  String refunitcode;
  List<LanguageNameModel> refunitnames;

  ProductOptionChoiceModel({
    required this.guid,
    required this.names,
    required this.price,
    required this.qty,
    required this.imageuri,
    String? refbarcode,
    String? refunitcode,
    List<LanguageNameModel>? refunitnames,
  })  : refbarcode = refbarcode ?? '',
        refunitcode = refunitcode ?? '',
        refunitnames = refunitnames ?? [];

  factory ProductOptionChoiceModel.fromJson(Map<String, dynamic> json) => _$ProductOptionChoiceModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductOptionChoiceModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductProcessModel {
  late int type; // 0: product, 1: category
  late String code;
  late String barcode;
  late String unitcode;
  late List<LanguageNameModel> unitnames;
  late List<LanguageNameModel> names;
  late double setprice;
  late List<ProductPriceFromServerModel> prices;
  late String imageuri;
  late String refcategoryguid;
  late double qty;
  late List<ProductProcessOptionModel> options;
  late String orderguid;
  late String remark;
  late bool isAlacarte;
  late List<ProductOrderTypeFromServerModel> ordertypes;
  late int foodtype;
  late String discountword;
  String manufacturerguid;
  bool isonlystaff;
  bool isforcustomer;

  /// ขาย/หยุดขายชั่วคราว
  late bool issell;

  /// ใช้ระบบยอดคงเหลือ
  late bool isstockforrestaurant;

  /// จำนวนคงเหลือ
  late double stockqty;

  /// พิมพ์แยกใบ
  late bool issplitunitprint;

  /// ยอดรวมทั้งสิ้น
  late double amount;

  late bool isexceptvat;

  ProductProcessModel(
      {required this.type,
      required this.code,
      required this.barcode,
      required this.unitcode,
      required this.unitnames,
      required this.names,
      required this.prices,
      required this.setprice,
      required this.discountword,
      required this.imageuri,
      required this.refcategoryguid,
      required this.qty,
      required this.options,
      required this.orderguid,
      required this.remark,
      required this.isAlacarte,
      required this.ordertypes,
      required this.foodtype,
      required this.issplitunitprint,
      required this.amount,
      String? manufacturerguid,
      bool? isonlystaff,
      bool? isforcustomer,
      required this.isexceptvat})
      : manufacturerguid = manufacturerguid ?? '',
        issell = true,
        isonlystaff = isonlystaff ?? false,
        isforcustomer = isforcustomer ?? false,
        isstockforrestaurant = false,
        stockqty = 0;

  factory ProductProcessModel.fromJson(Map<String, dynamic> json) => _$ProductProcessModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductProcessModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductProcessOptionModel {
  final String guid;
  final int choicetype;
  final int maxselect;
  final int minselect;
  final List<LanguageNameModel> names;
  final List<ProductProcessOptionChoiceModel> choices;

  ProductProcessOptionModel({
    required this.guid,
    required this.choicetype,
    required this.maxselect,
    required this.minselect,
    required this.names,
    required this.choices,
  });

  factory ProductProcessOptionModel.fromJson(Map<String, dynamic> json) => _$ProductProcessOptionModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductProcessOptionModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductProcessOptionChoiceModel {
  final String guid;
  final List<LanguageNameModel> names;
  final String price;
  double qty;
  final String discountWord;
  String refbarcode;
  String refunitcode;
  bool selected;
  double priceValue;
  String imageuri;
  double amount;
  double discountAmount;
  int vatcal;
  List<LanguageNameModel> refunitnames;

  ProductProcessOptionChoiceModel({
    required this.guid,
    required this.names,
    required this.price,
    double? qty,
    required this.selected,
    required this.priceValue,
    required this.imageuri,
    required this.discountWord,
    required this.amount,
    required this.discountAmount,
    String? refbarcode,
    String? refunitcode,
    List<LanguageNameModel>? refunitnames,
    int? vatcal,
  })  : refbarcode = refbarcode ?? '',
        refunitcode = refunitcode ?? '',
        refunitnames = refunitnames ?? [],
        vatcal = vatcal ?? 0,
        qty = qty ?? 0.0;

  factory ProductProcessOptionChoiceModel.fromJson(Map<String, dynamic> json) => _$ProductProcessOptionChoiceModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductProcessOptionChoiceModelToJson(this);
}
