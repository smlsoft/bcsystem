import 'package:dedeorder/global_model.dart';
import 'package:dedeorder/model/order_temp_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'global_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProfileSettingCompanyImageModel {
  int xorder;
  String uri;

  ProfileSettingCompanyImageModel({required this.xorder, required this.uri});

  factory ProfileSettingCompanyImageModel.fromJson(Map<String, dynamic> json) => _$ProfileSettingCompanyImageModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileSettingCompanyImageModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProfileQrPaymentModel {
  String code;
  String bankcode;
  List<LanguageDataModel> banknames;
  String bookbankcode;
  List<LanguageDataModel>? bookbanknames;
  List<ProfileSettingCompanyImageModel>? bookbankimages;
  bool isactive;
  int qrtype;
  List<LanguageDataModel>? qrnames;
  String qrcode;
  String logo;
  String? apikey;
  String? accessCode;
  String? bankcharge;
  String? billerCode;
  String? billerID;
  int? closeQr;
  String? customercharge;
  String? guidfixed;
  String? merchantName;
  String? storeID;
  String? terminalID;
  String token;

  ProfileQrPaymentModel({
    required this.guidfixed,
    required this.code,
    required this.bankcode,
    required this.banknames,
    required this.bookbankcode,
    required this.bookbanknames,
    required this.bookbankimages,
    required this.isactive,
    required this.qrtype,
    required this.qrnames,
    required this.qrcode,
    required this.logo,
    required this.apikey,
    required this.accessCode,
    required this.bankcharge,
    required this.billerCode,
    required this.billerID,
    required this.closeQr,
    required this.customercharge,
    required this.merchantName,
    required this.storeID,
    required this.terminalID,
    String? token,
  }) : token = token ?? "";

  factory ProfileQrPaymentModel.fromJson(Map<String, dynamic> json) => _$ProfileQrPaymentModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileQrPaymentModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LanguageNameModel {
  final String code;
  final String name;

  LanguageNameModel({
    required this.code,
    required this.name,
  });

  factory LanguageNameModel.fromJson(Map<String, dynamic> json) => _$LanguageNameModelFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageNameModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LanguageSystemModel {
  String code;
  String text;

  LanguageSystemModel({required this.code, required this.text});

  factory LanguageSystemModel.fromJson(Map<String, dynamic> json) => _$LanguageSystemModelFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageSystemModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LanguageSystemCodeModel {
  String code;
  List<LanguageSystemModel> langs;

  LanguageSystemCodeModel({required this.code, required this.langs});

  factory LanguageSystemCodeModel.fromJson(Map<String, dynamic> json) => _$LanguageSystemCodeModelFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageSystemCodeModelToJson(this);
}

@JsonSerializable()
class ResponseDataModel {
  final List<dynamic> data;

  ResponseDataModel({
    required this.data,
  });

  factory ResponseDataModel.fromJson(Map<String, dynamic> json) => _$ResponseDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$ResponseDataModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class HttpGetDataModel {
  String code;
  String json;

  HttpGetDataModel({required this.code, required this.json});

  factory HttpGetDataModel.fromJson(Map<String, dynamic> json) => _$HttpGetDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$HttpGetDataModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SyncStaffDeviceModel {
  String clientGuid;
  String clientName;
  String clientIp;
  String securityCode;

  SyncStaffDeviceModel({
    required this.clientGuid,
    required this.clientName,
    required this.clientIp,
    required this.securityCode,
  });

  factory SyncStaffDeviceModel.fromJson(Map<String, dynamic> json) => _$SyncStaffDeviceModelFromJson(json);

  Map<String, dynamic> toJson() => _$SyncStaffDeviceModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class StaffOrderModel {
  String tableNumber;
  String barcode;
  String qty;
  double amount;

  StaffOrderModel({
    required this.tableNumber,
    required this.barcode,
    required this.qty,
    required this.amount,
  });

  factory StaffOrderModel.fromJson(Map<String, dynamic> json) => _$StaffOrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$StaffOrderModelToJson(this);
}

@JsonSerializable()
class ProductBarcodeStatusObjectBoxStruct {
  int id = 0;

  /// Barcode สินค้า
  String barcode;

  /// 0=ปรกติมีสินค้า,1=สินค้าหมด
  int orderStatus;

  // สินค้าหมดอัตโนมัติเมื่อยอดคงเหลือเป็นศูนย์ (True,False)
  bool orderAutoStock;

  // เลิกขาย (ไม่แสดง) True,False
  bool orderDisable;

  /// ยอดคงเหลือเริ่มต้นเปิดร้าน (เมื่อกด เริ่มต้น)
  double qtyStart;

  /// ยอดคงเหลือปัจจุบัน
  double qtyBalance;

  /// เตือนเมื่อต่ำกว่า (เตือน สินค้าใกล้หมด)
  double qtyMin;

  ProductBarcodeStatusObjectBoxStruct({required this.barcode, required this.orderAutoStock, required this.orderStatus, required this.orderDisable, required this.qtyStart, required this.qtyBalance, required this.qtyMin});

  factory ProductBarcodeStatusObjectBoxStruct.fromJson(Map<String, dynamic> json) => _$ProductBarcodeStatusObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$ProductBarcodeStatusObjectBoxStructToJson(this);
}

class PosSaleChannelModel {
  String code;
  String name;
  String logoUrl;

  PosSaleChannelModel({required this.code, required this.name, this.logoUrl = ""});
}

class TableInfoModel {
  String number;
  DateTime openDateTime;
  List<OrderTempObjectBoxStruct> orders;

  TableInfoModel({required this.number, required this.orders, required this.openDateTime});
}

class ProductTypeModel {
  List<LanguageNameModel> name;

  ProductTypeModel({required this.name});
}

@JsonSerializable()
class StaffModel {
  String code;
  String name;

  StaffModel({
    required this.code,
    required this.name,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) => _$StaffModelFromJson(json);

  Map<String, dynamic> toJson() => _$StaffModelToJson(this);
}

class CheckerHistoryModel {
  String tableNumber;
  String productName;
  String productUnitName;
  DateTime servedDateTime;
  double orderQty;

  CheckerHistoryModel({required this.tableNumber, required this.productName, required this.productUnitName, required this.servedDateTime, required this.orderQty});
}
