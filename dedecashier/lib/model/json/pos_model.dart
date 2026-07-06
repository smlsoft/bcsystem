import 'package:dedecashier/global_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pos_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductCategoryCodeListModel {
  String code;
  List<LanguageDataModel> names;
  int xorder;
  String barcode;
  String unitcode;
  List<LanguageDataModel> unitnames;

  ProductCategoryCodeListModel({required this.code, required this.names, required this.xorder, required this.barcode, required this.unitcode, required this.unitnames});

  factory ProductCategoryCodeListModel.fromJson(Map<String, dynamic> json) => _$ProductCategoryCodeListModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductCategoryCodeListModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SortDataModel {
  String code;
  int xorder;

  SortDataModel({required this.code, required this.xorder});

  factory SortDataModel.fromJson(Map<String, dynamic> json) => _$SortDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$SortDataModelToJson(this);
}

@JsonSerializable()
class BarcodeModel {
  final String barcode;
  final String item_code;
  final String item_name;
  final String unit_code;
  final String unit_name;

  const BarcodeModel({this.barcode = '', this.item_code = '', this.item_name = '', this.unit_code = '', this.unit_name = ''});
  factory BarcodeModel.fromJson(Map<String, dynamic> json) => _$BarcodeModelFromJson(json);
  Map<String, dynamic> toJson() => _$BarcodeModelToJson(this);

  /*factory BarcodeStruct.fromJson(dynamic json) {
    return BarcodeStruct(
      barcode: json['barcode'],
      item_code: json['item_code'],
      item_name: json['item_name'],
      unit_code: json['unit_code'],
      unit_name: json['unit_name'],
    );
  }*/
}

class SelectItemConditionModel {
  int command;
  double qty;
  String prices;
  BarcodeModel data;

  SelectItemConditionModel({required this.command, required this.data, required this.qty, required this.prices});
}

/*class ItemStruct {
  final int index = 0;
  final String barcode = '';
  final String itemCode = '';
  final String itemName = '';
  final String unitCode = '';
  final String unitName = '';
  final double price = 0;

  const ItemStruct({required index, required barcode, required itemCode, required itemName, required unitCode, required unitName, required price});
  factory ItemStruct.fromJson(Map<String, dynamic> jsonString) {
    return ItemStruct(
      index: int.tryParse(jsonString['index'].toString()) ?? 0,
      barcode: jsonString['barcode'].toString(),
      itemCode: jsonString['item_code'].toString(),
      itemName: jsonString['item_name'].toString(),
      unitCode: jsonString['unit_code'].toString(),
      unitName: jsonString['unit_name'].toString(),
      price: double.tryParse(jsonString['price'].toString()) ?? 0.0,
    );
  }
}
*/

@JsonSerializable(explicitToJson: true)
class OrderOnlineParameterModel {
  String shopid;

  /// 0=สั่งจาก Order Kiosk ด้วย QrCode,1=สั่งด้วย Qrcode โต๊ะ,2=สั่งด้วยโทรศัพท์
  int type;
  String? table;
  String? qrcode;
  String? phone;
  String? tablebuffetcode;

  OrderOnlineParameterModel({required this.shopid, this.type = 0, this.table = "", this.qrcode = "", this.phone = "", this.tablebuffetcode = ""});

  factory OrderOnlineParameterModel.fromJson(Map<String, dynamic> json) => _$OrderOnlineParameterModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderOnlineParameterModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderBarcodeStatusModel {
  String shopid;
  String barcode;
  int orderstatus;
  int orderautostock;
  int orderdisable;
  double qtystart;
  double qtybalance;
  double qtymin;

  OrderBarcodeStatusModel({
    required this.shopid,
    required this.barcode,
    required this.orderstatus,
    required this.orderautostock,
    required this.orderdisable,
    required this.qtystart,
    required this.qtybalance,
    required this.qtymin,
  });

  factory OrderBarcodeStatusModel.fromJson(Map<String, dynamic> json) {
    return OrderBarcodeStatusModel(
      shopid: json['shopid'] as String,
      barcode: json['barcode'] as String,
      orderstatus: _parseToInt(json['orderstatus']),
      orderautostock: _parseToInt(json['orderautostock']),
      orderdisable: _parseToInt(json['orderdisable']),
      qtystart: _parseToDouble(json['qtystart']),
      qtybalance: _parseToDouble(json['qtybalance']),
      qtymin: _parseToDouble(json['qtymin']),
    );
  }

  static int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double _parseToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() => _$OrderBarcodeStatusModelToJson(this);
}
