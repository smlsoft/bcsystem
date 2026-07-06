import 'package:dedecashier/api/sync/model/employee_model.dart';
import 'package:dedecashier/api/sync/model/trans_model.dart';
import 'package:dedecashier/global.dart';
import 'package:dedecashier/model/json/pos_process_model.dart';
import 'package:dedecashier/model/system/pos_pay_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:dedecashier/global.dart' as global;

part 'global_model.g.dart';

enum PayScreenNumberPadWidgetEnum { text, number }

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

class SyncMasterStatusModel {
  late String tableName;
  late String lastUpdate;
}

@JsonSerializable(explicitToJson: true)
class PrinterLocalStrongDataModel {
  String code;
  String name;
  String ipAddress;
  int ipPort;
  String productName;
  String deviceName;
  String deviceId;
  String manufacturer;
  String vendorId;
  String productId;
  int paperType; // 1 = 58mm, 2 = 80mm
  bool printBillAuto;
  PrinterTypeEnum printerType;
  PrinterConnectEnum printerConnectType;
  bool isConfigConnectSuccess;
  bool isReady; // พร้อมใช้งาน
  bool isPaperOut; // กระดาษหมด
  String formSummeryCode; // ใบสรุปยอดขาย
  String formTaxCode; // ใบกำกับภาษีแบบย่อย
  String formFullTaxCode; // ใบกำกับภาษีแบบเต็ม

  PrinterLocalStrongDataModel({
    this.code = "",
    this.name = "",
    this.ipAddress = "",
    this.ipPort = 0,
    this.productName = "",
    this.deviceName = "",
    this.deviceId = "",
    this.manufacturer = "",
    this.vendorId = "",
    this.productId = "",
    this.paperType = 2,
    this.isReady = false,
    this.isPaperOut = false,
    this.formSummeryCode = "",
    this.formTaxCode = "",
    this.formFullTaxCode = "",
    this.isConfigConnectSuccess = false,
    this.printerType = PrinterTypeEnum.thermal,
    this.printerConnectType = PrinterConnectEnum.ip,
    this.printBillAuto = false,
  });

  factory PrinterLocalStrongDataModel.fromJson(Map<String, dynamic> json) => _$PrinterLocalStrongDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$PrinterLocalStrongDataModelToJson(this);
}

class PrinterDeviceModel {
  String fullName;
  String productName;
  String deviceName;
  String deviceId;
  String manufacturer;
  String vendorId;
  String productId;
  String ipAddress;
  int ipPort;
  global.PrinterConnectEnum connectType;
  global.PrinterTypeEnum printerType;
  // 1 = 58mm, 2 = 80mm
  int paperSize;

  PrinterDeviceModel({
    this.fullName = "",
    this.productName = "",
    this.deviceName = "",
    this.deviceId = "",
    this.manufacturer = "",
    this.productId = "",
    this.vendorId = "",
    this.ipAddress = "",
    this.ipPort = 0,
    this.paperSize = 0,
    this.printerType = global.PrinterTypeEnum.thermal,
    this.connectType = global.PrinterConnectEnum.ip,
  });
}

@JsonSerializable(explicitToJson: true)
class PosHoldProcessModel {
  /// รหัสการ Hold
  String code;

  /// 1=POS,2=ร้านอาหาร (โต๊ะ)
  int holdType;

  int payScreenActive = 0;

  /// จำนวน Log
  int logCount = 0;

  /// รหัส Sale
  String saleCode = "";

  /// ชื่อ Sale
  String saleName = "";

  /// รหัสลูกค้า
  String customerCode;

  String customerPointsCode;

  /// ชื่อลูกค้า
  String customerName;

  /// เบอร์โทรลูกค้า
  String customerPhone;

  bool ismember;

  String priceLevel;

  String customerGuid;

  /// การชำระเงิน
  PosPayModel payScreenData = PosPayModel();

  /// รายการสินค้า
  PosProcessModel posProcess = PosProcessModel();

  String tableNumber;

  /// เป็นรายการกลับบ้านหรือไม่
  bool isDelivery;

  String deliveryNumber;

  // ส่วนลดเฉพาะค่าอาหาร
  String detailDiscountFormula;

  // guid line active
  String activeLineGuid;

  PosHoldProcessModel({
    required this.code,
    this.holdType = 1,
    this.payScreenActive = 0,
    bool? ismember,
    String? customerGuid,
    this.tableNumber = "",
    this.isDelivery = false,
    this.deliveryNumber = "",
    this.customerCode = "",
    this.customerName = "",
    this.detailDiscountFormula = "",
    this.activeLineGuid = "",
    this.customerPhone = "",
    String? priceLevel,
    String? customerPointsCode,
  }) : ismember = ismember ?? false,
       priceLevel = priceLevel ?? "",
       customerGuid = customerGuid ?? "",
       customerPointsCode = customerPointsCode ?? "";

  factory PosHoldProcessModel.fromJson(Map<String, dynamic> json) => _$PosHoldProcessModelFromJson(json);
  Map<String, dynamic> toJson() => _$PosHoldProcessModelToJson(this);
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
class HttpParameterModel {
  String parentGuid;
  String guid;
  String barcode;
  String jsonData;
  String holdCode;
  int docMode;

  HttpParameterModel({this.parentGuid = "", this.guid = "", this.barcode = "", this.jsonData = "", this.holdCode = "", this.docMode = 0});

  factory HttpParameterModel.fromJson(Map<String, dynamic> json) => _$HttpParameterModelFromJson(json);
  Map<String, dynamic> toJson() => _$HttpParameterModelToJson(this);
}

class HttpPost {
  late String command;
  late String data;

  HttpPost({required this.command, this.data = ""});

  Map toJson() => {'command': command, 'data': data};

  factory HttpPost.fromJson(Map<String, dynamic> json) {
    return HttpPost(command: json['command'], data: json['data']);
  }
}

class PosProcessResultModel {
  String lineGuid;
  int lastCommandCode;
  bool barcodeNotFound; // Flag สำหรับ barcode ไม่พบ
  String barcodeNotFoundText; // ข้อความแสดงรหัส barcode ที่ไม่พบ

  PosProcessResultModel({this.lineGuid = "", this.lastCommandCode = 0, this.barcodeNotFound = false, this.barcodeNotFoundText = ""});
}

class InformationModel {
  // 0=Image,1=Video
  int mode = 0;
  String sourceUrl = "";
  int delaySecond = 10;

  InformationModel({required this.mode, required delaySecond, required this.sourceUrl});

  Map<String, dynamic> toJson() => {'mode': mode, 'sourceUrl': sourceUrl, 'delaySecond': delaySecond};
  factory InformationModel.fromJson(Map<String, dynamic> json) {
    return InformationModel(mode: json['mode'] ?? 0, delaySecond: json['delaySecond'] ?? 10, sourceUrl: json['sourceUrl'] ?? "");
  }
}

class PosSaleChannelModel {
  String code;
  String name;
  String logoUrl;

  PosSaleChannelModel({required this.code, required this.name, this.logoUrl = ""});
}

class LanguageModel {
  String code;
  String codeTranslator;
  String name;
  bool use;

  LanguageModel({required this.code, required this.codeTranslator, required this.name, required this.use});
}

@JsonSerializable(explicitToJson: true)
class LanguageDataModel {
  String code;
  String name;

  LanguageDataModel({required this.code, required this.name});

  factory LanguageDataModel.fromJson(Map<String, dynamic> json) => _$LanguageDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$LanguageDataModelToJson(this);
}

@JsonSerializable()
class ResponseDataModel {
  final List<dynamic> data;

  ResponseDataModel({required this.data});

  factory ResponseDataModel.fromJson(Map<String, dynamic> json) => _$ResponseDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$ResponseDataModelToJson(this);
}

class OrderTempDataModel {
  String orderId;
  String orderGuid;
  String barcode;
  String optionSelected;
  String remark;
  String remarkForCancel;
  DateTime orderDateTime;
  double price;
  double amount;
  int isTakeAway;
  double qty;
  double qtyLastCancel;
  int orderType;
  String orderEmployeeCode;
  String orderEmployeeDetail;

  OrderTempDataModel({
    required this.orderId,
    required this.orderGuid,
    required this.barcode,
    required this.qty,
    required this.qtyLastCancel,
    required this.remark,
    required this.remarkForCancel,
    required this.optionSelected,
    required this.orderDateTime,
    required this.price,
    required this.amount,
    required this.isTakeAway,
    required this.orderType,
    required this.orderEmployeeCode,
    required this.orderEmployeeDetail,
  });
}

@JsonSerializable(explicitToJson: true)
class OrderHistoryModel {
  final DateTime orderDateTime;
  final double orderQty;

  OrderHistoryModel({required this.orderDateTime, required this.orderQty});

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) => _$OrderHistoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderHistoryModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderServedHistoryModel {
  final DateTime servedDateTime;
  final double servedQty;

  OrderServedHistoryModel({required this.servedDateTime, required this.servedQty});

  factory OrderServedHistoryModel.fromJson(Map<String, dynamic> json) => _$OrderServedHistoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderServedHistoryModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderCancelHistoryModel {
  final DateTime cancelDateTime;
  final double cancelQty;

  OrderCancelHistoryModel({required this.cancelDateTime, required this.cancelQty});

  factory OrderCancelHistoryModel.fromJson(Map<String, dynamic> json) => _$OrderCancelHistoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCancelHistoryModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderProductOptionModel {
  final String guid;
  final int choicetype;
  final int maxselect;
  final int minselect;
  final List<LanguageDataModel> names;
  final List<OrderProductOptionChoiceModel> choices;

  OrderProductOptionModel({required this.guid, required this.choicetype, required this.maxselect, required this.minselect, required this.names, required this.choices});

  factory OrderProductOptionModel.fromJson(Map<String, dynamic> json) => _$OrderProductOptionModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderProductOptionModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderProductOptionChoiceModel {
  final String guid;
  final List<LanguageDataModel> names;
  final String price;
  final double qty;
  final bool selected;
  final double priceValue;

  OrderProductOptionChoiceModel({required this.guid, required this.names, required this.price, required this.qty, required this.selected, required this.priceValue});

  factory OrderProductOptionChoiceModel.fromJson(Map<String, dynamic> json) => _$OrderProductOptionChoiceModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderProductOptionChoiceModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PriceDataModel {
  int keynumber;
  double price;

  PriceDataModel({required this.keynumber, required this.price});

  factory PriceDataModel.fromJson(Map<String, dynamic> json) => _$PriceDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$PriceDataModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProfileSettingModel {
  ProfileSettingCompanyModel company;
  List<String> languagelist;
  ProfileSettingConfigSystemModel configsystem;
  List<ProfileSettingBranchModel> branch;
  ProfileCenterModel center;

  ProfileSettingModel({required this.company, required this.languagelist, required this.configsystem, required this.branch, ProfileCenterModel? center}) : center = center ?? ProfileCenterModel();

  factory ProfileSettingModel.fromJson(Map<String, dynamic> json) => _$ProfileSettingModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileSettingModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProfileSettingBranchModel {
  String guidfixed;
  String code;
  List<LanguageDataModel> names;
  PaymentRoundingModel paymentrounding;
  List<LanguageDataModel> companynames;
  ContactModel contact;
  PosModel pos;
  PointConfigModel pointconfig;
  bool ismainshop;
  String mainshopid;
  int productcentertype;
  int debtorcentertype;

  ProfileSettingBranchModel({
    String? guidfixed,
    String? code,
    List<LanguageDataModel>? names,
    PaymentRoundingModel? paymentrounding,
    List<LanguageDataModel>? companynames,
    ContactModel? contact,
    PosModel? pos,
    PointConfigModel? pointconfig,
    bool? ismainshop,
    String? mainshopid,
    int? productcentertype,
    int? debtorcentertype,
  }) : guidfixed = guidfixed ?? "",
       code = code ?? "",
       companynames = companynames ?? [],
       contact = contact ?? ContactModel(),
       pos = pos ?? PosModel(),
       names = names ?? [],
       paymentrounding = paymentrounding ?? PaymentRoundingModel(),
       pointconfig = pointconfig ?? PointConfigModel(),
       ismainshop = ismainshop ?? false,
       mainshopid = mainshopid ?? "",
       productcentertype = productcentertype ?? 0,
       debtorcentertype = debtorcentertype ?? 0;

  factory ProfileSettingBranchModel.fromJson(Map<String, dynamic> json) => _$ProfileSettingBranchModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileSettingBranchModelToJson(this);
}

//
@JsonSerializable(explicitToJson: true)
class ContactModel {
  List<LanguageDataModel> address;

  ContactModel({List<LanguageDataModel>? address}) : address = address ?? [];

  factory ContactModel.fromJson(Map<String, dynamic> json) => _$ContactModelFromJson(json);
  Map<String, dynamic> toJson() => _$ContactModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PosModel {
  String? taxid;
  double? vatrate;
  int? vattypesale;
  int? vattypepurchase;
  int? inquirytypesale;
  int? inquirytypepurchase;
  String? headerreceiptpos;
  String? footerreceiptpos;
  bool? isbom;

  PosModel({String? taxid, double? vatrate, int? vattypesale, int? vattypepurchase, int? inquirytypesale, int? inquirytypepurchase, String? headerreceiptpos, String? footerreceiptpos, bool? isbom})
    : taxid = taxid ?? "",
      vatrate = vatrate ?? 0.0,
      vattypesale = vattypesale ?? 0,
      vattypepurchase = vattypepurchase ?? 0,
      inquirytypesale = inquirytypesale ?? 0,
      inquirytypepurchase = inquirytypepurchase ?? 0,
      headerreceiptpos = headerreceiptpos ?? "",
      footerreceiptpos = footerreceiptpos ?? "",
      isbom = isbom ?? false;

  factory PosModel.fromJson(Map<String, dynamic> json) => _$PosModelFromJson(json);

  Map<String, dynamic> toJson() => _$PosModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProfileCreditCardModel {
  List<LanguageDataModel>? names;
  ProfileCreditCardBookBankModel bookbank;

  ProfileCreditCardModel({required this.names, required this.bookbank});

  factory ProfileCreditCardModel.fromJson(Map<String, dynamic> json) => _$ProfileCreditCardModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileCreditCardModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProfileTransferModel {
  List<LanguageDataModel>? names;
  ProfileCreditCardBookBankModel bookbank;

  ProfileTransferModel({required this.names, required this.bookbank});

  factory ProfileTransferModel.fromJson(Map<String, dynamic> json) => _$ProfileTransferModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileTransferModelToJson(this);
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
  }) : barcode = barcode ?? '',
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
class ProfileCreditCardBookBankModel {
  String? accountcode;
  String? accountname;
  String? bankbranch;
  String? bankcode;
  List<LanguageDataModel>? banknames;
  String? bookcode;
  List<String>? images;
  List<LanguageDataModel>? names;
  String? passbook;

  ProfileCreditCardBookBankModel({
    required this.accountcode,
    required this.accountname,
    required this.bankbranch,
    required this.bankcode,
    required this.banknames,
    required this.bookcode,
    required this.images,
    required this.names,
    required this.passbook,
  });

  factory ProfileCreditCardBookBankModel.fromJson(Map<String, dynamic> json) => _$ProfileCreditCardBookBankModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileCreditCardBookBankModelToJson(this);
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
class ProfileSettingConfigSystemModel {
  double vatrate;
  int vattypesale;
  int vattypepurchase;
  int inquirytypesale;
  int inquirytypepurchase;
  String headerreceiptpos;
  String footerreciptpos;

  ProfileSettingConfigSystemModel({
    required this.vatrate,
    required this.vattypesale,
    required this.vattypepurchase,
    required this.inquirytypesale,
    required this.inquirytypepurchase,
    String? headerreceiptpos,
    String? footerreciptpos,
  }) : headerreceiptpos = headerreceiptpos ?? "",
       footerreciptpos = footerreciptpos ?? "";

  factory ProfileSettingConfigSystemModel.fromJson(Map<String, dynamic> json) => _$ProfileSettingConfigSystemModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileSettingConfigSystemModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProfileSettingCompanyImageModel {
  int xorder;
  String uri;

  ProfileSettingCompanyImageModel({required this.xorder, required this.uri});

  factory ProfileSettingCompanyImageModel.fromJson(Map<String, dynamic> json) => _$ProfileSettingCompanyImageModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileSettingCompanyImageModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProfileSettingCompanyModel {
  List<LanguageDataModel> names;
  String taxID;
  List<LanguageDataModel> branchNames;
  List<LanguageDataModel> addresses;
  List<String> phones;
  List<String> emailOwners;
  List<String> emailStaffs;
  String latitude;
  String longitude;
  bool usebranch;
  bool usedepartment;
  List<ProfileSettingCompanyImageModel> images;
  String? logo;
  bool ismainshop;
  int productcentertype;
  int posproductcentertype;
  int debtorcentertype;
  String mainshopid;

  ProfileSettingCompanyModel({
    required this.names,
    required this.taxID,
    required this.branchNames,
    required this.addresses,
    required this.phones,
    required this.emailOwners,
    required this.emailStaffs,
    required this.latitude,
    required this.longitude,
    required this.usebranch,
    required this.usedepartment,
    required this.images,
    required this.logo,
    bool? ismainshop,
    int? productcentertype,
    int? posproductcentertype,
    int? debtorcentertype,
    String? mainshopid,
  }) : ismainshop = ismainshop ?? false,
       productcentertype = productcentertype ?? 0,
       posproductcentertype = posproductcentertype ?? 0,
       debtorcentertype = debtorcentertype ?? 0,
       mainshopid = mainshopid ?? "";

  factory ProfileSettingCompanyModel.fromJson(Map<String, dynamic> json) => _$ProfileSettingCompanyModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileSettingCompanyModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderTempUpdateForSplitModel {
  final String sourceTable;
  final String targetTable;
  final String sourceGuid;

  OrderTempUpdateForSplitModel({required this.sourceTable, required this.targetTable, required this.sourceGuid});

  factory OrderTempUpdateForSplitModel.fromJson(Map<String, dynamic> json) => _$OrderTempUpdateForSplitModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderTempUpdateForSplitModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PosConfigSlipModel {
  String code;
  String name;
  String formcode;
  List<LanguageDataModel> formnames;
  List<LanguageDataModel> headernames;

  PosConfigSlipModel({required this.code, required this.name, required this.formcode, required this.formnames, required this.headernames});

  factory PosConfigSlipModel.fromJson(Map<String, dynamic> json) => _$PosConfigSlipModelFromJson(json);
  Map<String, dynamic> toJson() => _$PosConfigSlipModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PosConfigBranchModel {
  final String guidfixed;
  final String code;
  final int couponusetype;
  final List<LanguageDataModel> names;
  PaymentRoundingModel paymentrounding;
  PosModel? pos;

  PosConfigBranchModel({required this.guidfixed, required this.code, required this.names, int? couponusetype, PosModel? pos, PaymentRoundingModel? paymentrounding})
    : pos = pos ?? PosModel(),
      couponusetype = couponusetype ?? 0,
      paymentrounding = paymentrounding ?? PaymentRoundingModel();

  factory PosConfigBranchModel.fromJson(Map<String, dynamic> json) => _$PosConfigBranchModelFromJson(json);

  Map<String, dynamic> toJson() => _$PosConfigBranchModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PaymentRoundingModel {
  final PaymentMethodRoundingModel banktransfer;
  final PaymentMethodRoundingModel cash;
  final PaymentMethodRoundingModel cheque;
  final PaymentMethodRoundingModel coupon;
  final PaymentMethodRoundingModel creditcard;
  final PaymentMethodRoundingModel delivery;
  final PaymentMethodRoundingModel qrcode;

  PaymentRoundingModel({
    PaymentMethodRoundingModel? banktransfer,
    PaymentMethodRoundingModel? cash,
    PaymentMethodRoundingModel? cheque,
    PaymentMethodRoundingModel? coupon,
    PaymentMethodRoundingModel? creditcard,
    PaymentMethodRoundingModel? delivery,
    PaymentMethodRoundingModel? qrcode,
  }) : banktransfer = banktransfer ?? PaymentMethodRoundingModel(),
       cash = cash ?? PaymentMethodRoundingModel(),
       cheque = cheque ?? PaymentMethodRoundingModel(),
       coupon = coupon ?? PaymentMethodRoundingModel(),
       creditcard = creditcard ?? PaymentMethodRoundingModel(),
       delivery = delivery ?? PaymentMethodRoundingModel(),
       qrcode = qrcode ?? PaymentMethodRoundingModel();

  factory PaymentRoundingModel.fromJson(Map<String, dynamic> json) => _$PaymentRoundingModelFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentRoundingModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PaymentMethodRoundingModel {
  final bool enabled;
  final List<RoundingRuleModel> rules;

  PaymentMethodRoundingModel({bool? enabled, List<RoundingRuleModel>? rules})
    : enabled = enabled ?? false, // ค่าเริ่มต้นคือ true
      rules = rules ?? [RoundingRuleModel()]; // ค่าเริ่มต้นมีกฎหนึ่งกฎ

  factory PaymentMethodRoundingModel.fromJson(Map<String, dynamic> json) => _$PaymentMethodRoundingModelFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentMethodRoundingModelToJson(this);
}

@JsonSerializable()
class RoundingRuleModel {
  final double lowerbound;
  final double roundto;
  final double upperbound;

  RoundingRuleModel({double? lowerbound, double? roundto, double? upperbound}) : lowerbound = lowerbound ?? 0.0, roundto = roundto ?? 0.0, upperbound = upperbound ?? 0.0;

  factory RoundingRuleModel.fromJson(Map<String, dynamic> json) => _$RoundingRuleModelFromJson(json);
  Map<String, dynamic> toJson() => _$RoundingRuleModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PosConfigModel {
  final String code;
  final String doccode;
  final int vattype;
  final int zonegroupnumber;
  final int tablegroupnumber;
  final int kitchengroupnumber;
  final int categorygroupnumber;
  final double vatrate;
  final String docformatinv;
  final String docformatesalereturn;
  final String docformattaxinv;
  final List<LanguageDataModel> billheader;
  final List<LanguageDataModel> billfooter;
  final bool isejournal;
  final String devicenumber;
  final bool isvatregister;
  final List<PosConfigSlipModel> slips;
  final String logourl;
  final List<ProfileQrPaymentModel>? qrcodes;
  final List<ProfileCreditCardModel>? creditcards;
  final List<ProfileTransferModel>? transfers;
  final String mediaguid;
  final List<PosEmployeeModel> employees;

  final LocationModel location;
  final WarehouseModel warehouse;
  final PosConfigBranchModel branch;
  final int businesstype;
  bool iscopyreceipt;

  PosConfigModel({
    String? code,
    String? doccode,
    int? vattype,
    int? zonegroupnumber,
    int? tablegroupnumber,
    int? kitchengroupnumber,
    int? categorygroupnumber,
    double? vatrate,
    String? docformatinv,
    String? docformatesalereturn,
    String? docformattaxinv,
    String? mediaguid,
    List<LanguageDataModel>? billheader,
    List<LanguageDataModel>? billfooter,
    bool? isvatregister,
    bool? isejournal,
    String? devicenumber,
    List<PosConfigSlipModel>? slips,
    String? logourl,
    List<ProfileQrPaymentModel>? qrcodes,
    List<ProfileCreditCardModel>? creditcards,
    List<ProfileTransferModel>? transfers,
    int? businesstype,
    LocationModel? location,
    WarehouseModel? warehouse,
    PosConfigBranchModel? branch,
    List<PosEmployeeModel>? employees,
    bool? iscopyreceipt,
  }) : code = code ?? "",
       employees = employees ?? [],
       doccode = doccode ?? "",
       vattype = vattype ?? 0,
       vatrate = vatrate ?? 0,
       mediaguid = mediaguid ?? "",
       zonegroupnumber = zonegroupnumber ?? 0,
       tablegroupnumber = tablegroupnumber ?? 0,
       kitchengroupnumber = kitchengroupnumber ?? 0,
       categorygroupnumber = categorygroupnumber ?? 0,
       docformatinv = docformatinv ?? "",
       docformatesalereturn = docformatesalereturn ?? "",
       docformattaxinv = docformattaxinv ?? "",
       billheader = billheader ?? [],
       billfooter = billfooter ?? [],
       isejournal = isejournal ?? false,
       devicenumber = devicenumber ?? "",
       isvatregister = isvatregister ?? false,
       slips = slips ?? [],
       logourl = logourl ?? "",
       qrcodes = qrcodes ?? [],
       creditcards = creditcards ?? [],
       transfers = transfers ?? [],
       businesstype = businesstype ?? 0,
       iscopyreceipt = iscopyreceipt ?? true,
       location = location ?? LocationModel(code: "", names: []),
       branch = branch ?? PosConfigBranchModel(guidfixed: "", code: "", names: []),
       warehouse = warehouse ?? WarehouseModel(code: "", names: [], guidfixed: "");

  factory PosConfigModel.fromJson(Map<String, dynamic> json) => _$PosConfigModelFromJson(json);
  Map<String, dynamic> toJson() => _$PosConfigModelToJson(this);
}

@JsonSerializable()
class PosEmployeeModel {
  String code;
  String name;

  PosEmployeeModel({required this.code, required this.name});

  factory PosEmployeeModel.fromJson(Map<String, dynamic> json) => _$PosEmployeeModelFromJson(json);
  Map<String, dynamic> toJson() => _$PosEmployeeModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PosMediaDescriptionModel {
  String code;
  String name;
  bool isauto;
  bool isdelete;

  PosMediaDescriptionModel({required this.code, required this.name, required this.isauto, required this.isdelete});

  factory PosMediaDescriptionModel.fromJson(Map<String, dynamic> json) =>
      PosMediaDescriptionModel(code: json['code'] ?? '', name: json['name'] ?? '', isauto: json['isauto'] ?? false, isdelete: json['isdelete'] ?? false);
  Map<String, dynamic> toJson() => {'code': code, 'name': name, 'isauto': isauto, 'isdelete': isdelete};
}

@JsonSerializable(explicitToJson: true)
class PosMediaResourceDescriptionModel {
  String code;
  String name;
  bool isauto;
  bool isdelete;

  PosMediaResourceDescriptionModel({required this.code, required this.name, required this.isauto, required this.isdelete});

  factory PosMediaResourceDescriptionModel.fromJson(Map<String, dynamic> json) =>
      PosMediaResourceDescriptionModel(code: json['code'] ?? '', name: json['name'] ?? '', isauto: json['isauto'] ?? false, isdelete: json['isdelete'] ?? false);
  Map<String, dynamic> toJson() => {'code': code, 'name': name, 'isauto': isauto, 'isdelete': isdelete};
}

@JsonSerializable(explicitToJson: true)
class PosMediaResourceModel {
  int mediaType;
  String uri;
  List<int> daysofweek;
  String fromDate;
  String toDate;
  String fromTime;
  String toTime;
  List<PosMediaResourceDescriptionModel> description;
  int displaytime;

  PosMediaResourceModel({
    required this.mediaType,
    required this.uri,
    required this.daysofweek,
    required this.fromDate,
    required this.toDate,
    required this.fromTime,
    required this.toTime,
    required this.description,
    required this.displaytime,
  });

  factory PosMediaResourceModel.fromJson(Map<String, dynamic> json) => PosMediaResourceModel(
    mediaType: json['mediaType'] ?? 0,
    uri: json['uri'] ?? '',
    daysofweek: (json['daysofweek'] as List<dynamic>? ?? []).map((e) => e as int).toList(),
    fromDate: json['fromDate'] ?? '',
    toDate: json['toDate'] ?? '',
    fromTime: json['fromTime'] ?? '',
    toTime: json['toTime'] ?? '',
    description: (json['description'] as List<dynamic>? ?? []).map((e) => PosMediaResourceDescriptionModel.fromJson(e)).toList(),
    displaytime: json['displaytime'] ?? 0,
  );
  Map<String, dynamic> toJson() => {
    'mediaType': mediaType,
    'uri': uri,
    'daysofweek': daysofweek,
    'fromDate': fromDate,
    'toDate': toDate,
    'fromTime': fromTime,
    'toTime': toTime,
    'description': description.map((e) => e.toJson()).toList(),
    'displaytime': displaytime,
  };
}

@JsonSerializable(explicitToJson: true)
class PosMediaModel {
  String guidfixed;
  String code;
  List<PosMediaDescriptionModel> description;
  List<PosMediaResourceModel> resources;

  PosMediaModel({String? guidfixed, String? code, List<PosMediaDescriptionModel>? description, List<PosMediaResourceModel>? resources})
    : guidfixed = guidfixed ?? '',
      code = code ?? '',
      description = description ?? [],
      resources = resources ?? [];

  factory PosMediaModel.fromJson(Map<String, dynamic> json) => PosMediaModel(
    guidfixed: json['guidfixed'] ?? '',
    code: json['code'] ?? '',
    description: (json['description'] as List<dynamic>? ?? []).map((e) => PosMediaDescriptionModel.fromJson(e)).toList(),
    resources: (json['resources'] as List<dynamic>? ?? []).map((e) => PosMediaResourceModel.fromJson(e)).toList(),
  );
  Map<String, dynamic> toJson() => {'guidfixed': guidfixed, 'code': code, 'description': description.map((e) => e.toJson()).toList(), 'resources': resources.map((e) => e.toJson()).toList()};
}

@JsonSerializable(explicitToJson: true)
class PosInformationModel {
  /// เอาไว้เชื่อมต่อระหว่างเครื่อง
  final String shop_id;
  final String shop_name;

  PosInformationModel({required this.shop_id, required this.shop_name});

  factory PosInformationModel.fromJson(Map<String, dynamic> json) => _$PosInformationModelFromJson(json);

  Map<String, dynamic> toJson() => _$PosInformationModelToJson(this);
}

// ปัดเศษสตางค์
class MoneyRoundPayModel {
  double begin;
  double end;
  double value;

  MoneyRoundPayModel({required this.begin, required this.end, required this.value});
}

@JsonSerializable(explicitToJson: true)
class LocationModel {
  String code;
  List<TransNameInfoModel> names;

  LocationModel({required this.code, required this.names});

  factory LocationModel.fromJson(Map<String, dynamic> json) => _$LocationModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocationModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WarehouseModel {
  String code;
  String guidfixed;
  List<TransNameInfoModel> names;

  WarehouseModel({required this.code, required this.names, required this.guidfixed});

  factory WarehouseModel.fromJson(Map<String, dynamic> json) => _$WarehouseModelFromJson(json);

  Map<String, dynamic> toJson() => _$WarehouseModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PrintQueueModel {
  final List<int> imageBytes;

  PrintQueueModel({required this.imageBytes});

  factory PrintQueueModel.fromJson(Map<String, dynamic> json) => _$PrintQueueModelFromJson(json);

  Map<String, dynamic> toJson() => _$PrintQueueModelToJson(this);
}

class SendTableInfoModel {
  String code;
  String jsonData;

  SendTableInfoModel({required this.code, required this.jsonData});
}

@JsonSerializable(explicitToJson: true)
class CallerModel {
  final String command;
  final DateTime calldatetime;
  final int actionstatus;
  final DateTime actiondatetime;
  final String refguid;

  CallerModel({required this.command, required this.refguid, required this.calldatetime, required this.actionstatus, required this.actiondatetime});

  factory CallerModel.fromJson(Map<String, dynamic> json) => _$CallerModelFromJson(json);

  Map<String, dynamic> toJson() => _$CallerModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LineNotifyModel {
  final String guid;
  final String token;
  final String message;

  LineNotifyModel({required this.guid, required this.token, required this.message});

  factory LineNotifyModel.fromJson(Map<String, dynamic> json) => _$LineNotifyModelFromJson(json);

  Map<String, dynamic> toJson() => _$LineNotifyModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PointConfigModel {
  List<PointGeneralRuleModel> generalrules;
  List<PointSpecialRuleModel> specialrules;
  int pointusagetype;

  PointConfigModel({List<PointGeneralRuleModel>? generalrules, List<PointSpecialRuleModel>? specialrules, int? pointusagetype})
    : generalrules = generalrules ?? [],
      specialrules = specialrules ?? [],
      pointusagetype = pointusagetype ?? 1;

  factory PointConfigModel.fromJson(Map<String, dynamic> json) => _$PointConfigModelFromJson(json);
  Map<String, dynamic> toJson() => _$PointConfigModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PointGeneralRuleModel {
  String startdate;
  String enddate;
  double payperpoint;
  double pointvalue;

  PointGeneralRuleModel({String? startdate, String? enddate, double? payperpoint, double? pointvalue})
    : startdate = startdate ?? "",
      enddate = enddate ?? "",
      payperpoint = payperpoint ?? 0.0,
      pointvalue = pointvalue ?? 0.0;

  factory PointGeneralRuleModel.fromJson(Map<String, dynamic> json) => _$PointGeneralRuleModelFromJson(json);
  Map<String, dynamic> toJson() => _$PointGeneralRuleModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PointSpecialRuleModel {
  String startdate;
  String enddate;
  double multiplier;
  bool sunday;
  bool monday;
  bool tuesday;
  bool wednesday;
  bool thursday;
  bool friday;
  bool saturday;
  double maxpointperbill;

  PointSpecialRuleModel({
    String? startdate,
    String? enddate,
    double? multiplier,
    bool? sunday,
    bool? monday,
    bool? tuesday,
    bool? wednesday,
    bool? thursday,
    bool? friday,
    bool? saturday,
    double? maxpointperbill,
  }) : startdate = startdate ?? "",
       enddate = enddate ?? "",
       multiplier = multiplier ?? 1.0,
       sunday = sunday ?? false,
       monday = monday ?? false,
       tuesday = tuesday ?? false,
       wednesday = wednesday ?? false,
       thursday = thursday ?? false,
       friday = friday ?? false,
       saturday = saturday ?? false,
       maxpointperbill = maxpointperbill ?? 0.0;
  factory PointSpecialRuleModel.fromJson(Map<String, dynamic> json) => _$PointSpecialRuleModelFromJson(json);
  Map<String, dynamic> toJson() => _$PointSpecialRuleModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProfileCenterModel {
  String guidfixed;
  String profilepicture;
  String name1;
  List<LanguageDataModel> names;
  String telephone;
  String branchcode;
  bool ismainshop;
  int productcentertype;
  int posproductcentertype;
  int debtorcentertype;
  String mainshopid;
  List<LanguageDataModel> address;
  List<ProfileSettingCompanyImageModel> images;
  String logo;
  ProfileCenterSettingsModel settings;

  ProfileCenterModel({
    String? guidfixed,
    String? profilepicture,
    String? name1,
    List<LanguageDataModel>? names,
    String? telephone,
    String? branchcode,
    bool? ismainshop,
    int? productcentertype,
    int? posproductcentertype,
    int? debtorcentertype,
    String? mainshopid,
    List<LanguageDataModel>? address,
    List<ProfileSettingCompanyImageModel>? images,
    String? logo,
    ProfileCenterSettingsModel? settings,
  }) : guidfixed = guidfixed ?? "",
       profilepicture = profilepicture ?? "",
       name1 = name1 ?? "",
       names = names ?? [],
       telephone = telephone ?? "",
       branchcode = branchcode ?? "",
       ismainshop = ismainshop ?? false,
       productcentertype = productcentertype ?? 0,
       posproductcentertype = posproductcentertype ?? 0,
       debtorcentertype = debtorcentertype ?? 0,
       mainshopid = mainshopid ?? "",
       address = address ?? [],
       images = images ?? [],
       logo = logo ?? "",
       settings = settings ?? ProfileCenterSettingsModel();

  factory ProfileCenterModel.fromJson(Map<String, dynamic> json) => _$ProfileCenterModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileCenterModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProfileCenterSettingsModel {
  String taxid;
  List<String> emailowners;
  List<String> emailstaffs;
  double latitude;
  double longitude;
  bool isusebranch;
  bool isusedepartment;
  int vattypesale;
  int vattypepurchase;
  int inquirytypesale;
  int inquirytypepurchase;
  List<LanguageDataModel> languageconfigs;

  ProfileCenterSettingsModel({
    String? taxid,
    List<String>? emailowners,
    List<String>? emailstaffs,
    double? latitude,
    double? longitude,
    bool? isusebranch,
    bool? isusedepartment,
    int? vattypesale,
    int? vattypepurchase,
    int? inquirytypesale,
    int? inquirytypepurchase,
    List<LanguageDataModel>? languageconfigs,
  }) : taxid = taxid ?? "",
       emailowners = emailowners ?? [],
       emailstaffs = emailstaffs ?? [],
       latitude = latitude ?? 0.0,
       longitude = longitude ?? 0.0,
       isusebranch = isusebranch ?? false,
       isusedepartment = isusedepartment ?? false,
       vattypesale = vattypesale ?? 0,
       vattypepurchase = vattypepurchase ?? 0,
       inquirytypesale = inquirytypesale ?? 0,
       inquirytypepurchase = inquirytypepurchase ?? 0,
       languageconfigs = languageconfigs ?? [];

  factory ProfileCenterSettingsModel.fromJson(Map<String, dynamic> json) => _$ProfileCenterSettingsModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileCenterSettingsModelToJson(this);
}
