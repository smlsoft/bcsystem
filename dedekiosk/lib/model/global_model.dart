import 'package:dedekiosk/model/category_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'global_model.g.dart';

class BillCalcAmount {
  double amountAfterCalcVat;
  double amountExceptVat;
  double amountBeforeCalcVat;
  double totalDiscount;
  double detailTotalAmountBeforeDiscount;
  double totalVatAmount;
  double payCashAmount;
  double payCashChange;
  double detailTotalAmount;
  double detailTotalDiscount;
  double roundAmount;
  double sumCoupon;
  double sumCreditCard;
  double sumQrCode;
  double totalAmountAfterDiscount;
  double totalDiscountExceptVatAmount;
  double totalDiscountVatAmount;
  double totalQty;
  double discountVatAmount;
  double totalItemVatAmount;
  double totalItemExceptVatAmount;
  double totalAmount;
  double shippingAmount;
  double saveAmount;
  double diffAmount;
  double sumOrderAmountNet;
  double totalAmountBeforeDiscount;

  BillCalcAmount(
      {double? amountAfterCalcVat,
      double? amountExceptVat,
      double? amountBeforeCalcVat,
      double? totalDiscount,
      double? detailTotalAmountBeforeDiscount,
      double? totalVatAmount,
      double? payCashAmount,
      double? payCashChange,
      double? detailTotalAmount,
      double? detailTotalDiscount,
      double? roundAmount,
      double? sumCoupon,
      double? sumCreditCard,
      double? sumQrCode,
      double? totalAmountAfterDiscount,
      double? totalDiscountExceptVatAmount,
      double? totalDiscountVatAmount,
      double? totalQty,
      double? discountVatAmount,
      double? totalItemVatAmount,
      double? totalItemExceptVatAmount,
      double? totalAmount,
      double? shippingAmount,
      double? saveAmount,
      double? diffAmount,
      double? sumOrderAmountNet,
      double? totalAmountBeforeDiscount})
      : amountAfterCalcVat = amountAfterCalcVat ?? 0,
        amountExceptVat = amountExceptVat ?? 0,
        amountBeforeCalcVat = amountBeforeCalcVat ?? 0,
        totalDiscount = totalDiscount ?? 0,
        detailTotalAmountBeforeDiscount = detailTotalAmountBeforeDiscount ?? 0,
        totalVatAmount = totalVatAmount ?? 0,
        payCashAmount = payCashAmount ?? 0,
        payCashChange = payCashChange ?? 0,
        detailTotalAmount = detailTotalAmount ?? 0,
        detailTotalDiscount = detailTotalDiscount ?? 0,
        roundAmount = roundAmount ?? 0,
        sumCoupon = sumCoupon ?? 0,
        sumCreditCard = sumCreditCard ?? 0,
        sumQrCode = sumQrCode ?? 0,
        totalAmountAfterDiscount = totalAmountAfterDiscount ?? 0,
        totalDiscountExceptVatAmount = totalDiscountExceptVatAmount ?? 0,
        totalDiscountVatAmount = totalDiscountVatAmount ?? 0,
        totalQty = totalQty ?? 0,
        discountVatAmount = discountVatAmount ?? 0,
        totalItemVatAmount = totalItemVatAmount ?? 0,
        totalItemExceptVatAmount = totalItemExceptVatAmount ?? 0,
        totalAmount = totalAmount ?? 0,
        shippingAmount = shippingAmount ?? 0,
        saveAmount = saveAmount ?? 0,
        diffAmount = diffAmount ?? 0,
        sumOrderAmountNet = sumOrderAmountNet ?? 0,
        totalAmountBeforeDiscount = totalAmountBeforeDiscount ?? 0;
}

@JsonSerializable(explicitToJson: true)
class LineNotifyFromServerModel {
  final String token;

  LineNotifyFromServerModel({
    required this.token,
  });

  factory LineNotifyFromServerModel.fromJson(Map<String, dynamic> json) =>
      _$LineNotifyFromServerModelFromJson(json);

  Map<String, dynamic> toJson() => _$LineNotifyFromServerModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ShopProfileModel {
  String name1;
  String shopid;
  String profilepicture;
  bool isbcmember;
  String apikey;
  List<KitchenModel>? kitchens;
  ShopProfileOrderStationModel orderstation;

  ShopProfileModel({
    required this.name1,
    required this.kitchens,
    required this.orderstation,
    String? shopid,
    String? profilepicture,
    bool? isbcmember,
    String? apikey,
  })  : shopid = shopid ?? "",
        profilepicture = profilepicture ?? "",
        isbcmember = isbcmember ?? false,
        apikey = apikey ?? "";

  factory ShopProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ShopProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$ShopProfileModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ShopProfileOrderStationModel {
  final String code;
  final ShopProfileBranchModel branch;
  final List<ShopProfileBranchSaleChannelModel>? salechannels;
  final ShopProfileDeviceInfoModel deviceinfo;
  final List<ProfileQrPaymentModel> qrcodes;
  final String label;
  final String adminpin;
  final int categorygroupnumber;
  final ShopProfileMediaModel media;
  final bool isvatregister;
  final int vattype;
  final double vatrate;
  final String lineoaimg;
  final String backgroundurl;

  ShopProfileOrderStationModel(
      {required this.code,
      required this.branch,
      required this.salechannels,
      required this.deviceinfo,
      required this.label,
      required this.adminpin,
      required this.categorygroupnumber,
      ShopProfileMediaModel? media,
      required this.isvatregister,
      required this.vattype,
      required this.vatrate,
      String? lineoaimg,
      String? backgroundurl,
      List<ProfileQrPaymentModel>? qrcodes})
      : qrcodes = qrcodes ?? [],
        lineoaimg = lineoaimg ?? "",
        backgroundurl = backgroundurl ?? "",
        media = media ?? ShopProfileMediaModel();

  factory ShopProfileOrderStationModel.fromJson(Map<String, dynamic> json) =>
      _$ShopProfileOrderStationModelFromJson(json);
  Map<String, dynamic> toJson() => _$ShopProfileOrderStationModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ShopProfileMediaModel {
  String code;
  List<ShopProfileMediaResourceModel> resources;

  ShopProfileMediaModel({
    String? code,
    List<ShopProfileMediaResourceModel>? resources,
  })  : code = code ?? "",
        resources = resources ?? [];

  factory ShopProfileMediaModel.fromJson(Map<String, dynamic> json) =>
      _$ShopProfileMediaModelFromJson(json);
  Map<String, dynamic> toJson() => _$ShopProfileMediaModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ShopProfileMediaResourceModel {
  int mediaType;
  String uri;

  ShopProfileMediaResourceModel({
    int? mediaType,
    String? uri,
  })  : mediaType = mediaType ?? 0,
        uri = uri ?? "";

  factory ShopProfileMediaResourceModel.fromJson(Map<String, dynamic> json) =>
      _$ShopProfileMediaResourceModelFromJson(json);
  Map<String, dynamic> toJson() => _$ShopProfileMediaResourceModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ShopProfileDeviceInfoModel {
  final String code;
  final String docformat;

  ShopProfileDeviceInfoModel({
    required this.code,
    required this.docformat,
  });

  factory ShopProfileDeviceInfoModel.fromJson(Map<String, dynamic> json) =>
      _$ShopProfileDeviceInfoModelFromJson(json);
  Map<String, dynamic> toJson() => _$ShopProfileDeviceInfoModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PointConfigModel {
  List<PointGeneralRuleModel> generalrules;
  List<PointSpecialRuleModel> specialrules;
  int pointusagetype;

  PointConfigModel({
    List<PointGeneralRuleModel>? generalrules,
    List<PointSpecialRuleModel>? specialrules,
    int? pointusagetype,
  })  : generalrules = generalrules ?? [],
        specialrules = specialrules ?? [],
        pointusagetype = pointusagetype ?? 1;

  factory PointConfigModel.fromJson(Map<String, dynamic> json) =>
      _$PointConfigModelFromJson(json);
  Map<String, dynamic> toJson() => _$PointConfigModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PointGeneralRuleModel {
  String startdate;
  String enddate;
  double payperpoint;
  double pointvalue;

  PointGeneralRuleModel({
    String? startdate,
    String? enddate,
    double? payperpoint,
    double? pointvalue,
  })  : startdate = startdate ?? "",
        enddate = enddate ?? "",
        payperpoint = payperpoint ?? 0.0,
        pointvalue = pointvalue ?? 0.0;

  factory PointGeneralRuleModel.fromJson(Map<String, dynamic> json) =>
      _$PointGeneralRuleModelFromJson(json);
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
  })  : startdate = startdate ?? "",
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
  factory PointSpecialRuleModel.fromJson(Map<String, dynamic> json) =>
      _$PointSpecialRuleModelFromJson(json);
  Map<String, dynamic> toJson() => _$PointSpecialRuleModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ShopProfileBranchModel {
  final String code;
  final List<LanguageNameModel>? names;
  final List<LanguageNameModel>? companynames;
  final ShopProfileBranchContactModel? contact;
  final ShopProfileBranchPosModel pos;
  final String logouri;
  final PaymentRoundingModel paymentrounding;

  PointConfigModel pointconfig;
  ShopProfileBranchModel({
    required this.code,
    required this.companynames,
    List<LanguageNameModel>? names,
    PointConfigModel? pointconfig,
    required this.contact,
    required this.pos,
    required this.logouri,
    PaymentRoundingModel? paymentrounding,
  })  : names = names ?? [],
        pointconfig = pointconfig ?? PointConfigModel(),
        paymentrounding = paymentrounding ?? PaymentRoundingModel();

  factory ShopProfileBranchModel.fromJson(Map<String, dynamic> json) =>
      _$ShopProfileBranchModelFromJson(json);
  Map<String, dynamic> toJson() => _$ShopProfileBranchModelToJson(this);
}

// โมเดลสำหรับ Payment Rounding ที่มีค่าเริ่มต้น
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
  })  : banktransfer = banktransfer ?? PaymentMethodRoundingModel(),
        cash = cash ?? PaymentMethodRoundingModel(),
        cheque = cheque ?? PaymentMethodRoundingModel(),
        coupon = coupon ?? PaymentMethodRoundingModel(),
        creditcard = creditcard ?? PaymentMethodRoundingModel(),
        delivery = delivery ?? PaymentMethodRoundingModel(),
        qrcode = qrcode ?? PaymentMethodRoundingModel();

  factory PaymentRoundingModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentRoundingModelFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentRoundingModelToJson(this);
}

// โมเดลสำหรับการกำหนดค่าการปัดเศษของแต่ละวิธีการชำระเงิน ที่มีค่าเริ่มต้น
@JsonSerializable(explicitToJson: true)
class PaymentMethodRoundingModel {
  final bool enabled;
  final List<RoundingRuleModel> rules;

  PaymentMethodRoundingModel({
    bool? enabled,
    List<RoundingRuleModel>? rules,
  })  : enabled = enabled ?? false, // ค่าเริ่มต้นคือ true
        rules = rules ?? [RoundingRuleModel()]; // ค่าเริ่มต้นมีกฎหนึ่งกฎ

  factory PaymentMethodRoundingModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodRoundingModelFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentMethodRoundingModelToJson(this);
}

// โมเดลสำหรับกฎการปัดเศษ ที่มีค่าเริ่มต้น
@JsonSerializable()
class RoundingRuleModel {
  final double lowerbound;
  final double roundto;
  final double upperbound;

  RoundingRuleModel({
    double? lowerbound,
    double? roundto,
    double? upperbound,
  })  : lowerbound = lowerbound ?? 0.0,
        roundto = roundto ?? 0.0,
        upperbound = upperbound ?? 0.0;

  factory RoundingRuleModel.fromJson(Map<String, dynamic> json) =>
      _$RoundingRuleModelFromJson(json);
  Map<String, dynamic> toJson() => _$RoundingRuleModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PosConfigBranchModel {
  final String code;

  final List<LanguageNameModel>? names;
  PosConfigBranchModel({
    required this.code,
    required this.names,
  });

  factory PosConfigBranchModel.fromJson(Map<String, dynamic> json) =>
      _$PosConfigBranchModelFromJson(json);

  Map<String, dynamic> toJson() => _$PosConfigBranchModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ShopProfileBranchContactModel {
  final List<LanguageNameModel>? address;
  final String phonenumber;

  ShopProfileBranchContactModel(
      {required this.address, required this.phonenumber});

  factory ShopProfileBranchContactModel.fromJson(Map<String, dynamic> json) =>
      _$ShopProfileBranchContactModelFromJson(json);
  Map<String, dynamic> toJson() => _$ShopProfileBranchContactModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ShopProfileBranchPosModel {
  final String taxid;
  final String headerreceiptpos;
  final String footerreceiptpos;

  ShopProfileBranchPosModel({
    required this.taxid,
    required this.headerreceiptpos,
    required this.footerreceiptpos,
  });

  factory ShopProfileBranchPosModel.fromJson(Map<String, dynamic> json) =>
      _$ShopProfileBranchPosModelFromJson(json);
  Map<String, dynamic> toJson() => _$ShopProfileBranchPosModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ShopProfileBranchSaleChannelModel {
  final String code;
  final String name;
  final String imageuri;
  final double gp;
  final int price;
  final int gptype;

  ShopProfileBranchSaleChannelModel({
    required this.code,
    required this.name,
    required this.imageuri,
    required this.gp,
    required this.gptype,
    required this.price,
  });

  factory ShopProfileBranchSaleChannelModel.fromJson(
          Map<String, dynamic> json) =>
      _$ShopProfileBranchSaleChannelModelFromJson(json);
  Map<String, dynamic> toJson() =>
      _$ShopProfileBranchSaleChannelModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class KitchenModel {
  final String code;
  final List<LanguageNameModel> names;
  final List<String> products;

  KitchenModel({
    required this.code,
    required this.names,
    required this.products,
  });

  factory KitchenModel.fromJson(Map<String, dynamic> json) =>
      _$KitchenModelFromJson(json);
  Map<String, dynamic> toJson() => _$KitchenModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class KitchenDeviceModel {
  final String code;
  final List<LanguageNameModel> names;
  late PrinterLocalConfigModel printer;

  KitchenDeviceModel({
    required this.code,
    required this.names,
  }) {
    printer = PrinterLocalConfigModel();
  }

  factory KitchenDeviceModel.fromJson(Map<String, dynamic> json) =>
      _$KitchenDeviceModelFromJson(json);
  Map<String, dynamic> toJson() => _$KitchenDeviceModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DeviceConfigModel {
  String usercode;
  String token;
  String shopId;
  String branchId;
  String orderStationCode;
  String apikey;
  String isdev;

  /// เครื่องพิมพ์เจ้าของร้าน
  PrinterLocalConfigModel printerForOwner;

  /// เครื่องพิมพ์สำหรับพนักงาน/ลูกค้า
  PrinterLocalConfigModel printerForOrderStation;

  /// 1=จ่ายก่อนกิน 2=กินก่อนจ่าย
  int systemCondition;

  /// 0=เป็นเครื่องสำหรับพนักงาน,1=เป็นเครื่องสำหรับลูกค้า
  int machineCondition;

  /// 0=ระบบ A,1=ระบบ ฺB,2=ระบบ C
  int shopPaymentCondition;

  /// 1=เชื่อมกับระบบ Order Online (ลูกค้าสั่งด้วยมือถือตัวเอง)
  bool orderOnlineCondition;

  bool showQrCodeOrderOnline = false;

  double latitude = 0.0;
  double longitude = 0.0;

  String deviceId;

  /// เปิดระบบสั่งทานที่ร้าน
  bool useOrderEatAtTheRestaurant = false;

  /// เปิดระบบสั้่งกลับบ้าน
  bool useOrderTakeAway = false;

  /// เป็นเครื่องแม่ (ได้เครื่องเดียวเท่านั้น) ใช้สำหรับพิมพ์ครัว และเชื่อม Server บางอย่าง
  bool isServer = false;

  /// Pay-at-cashier: ส่งครัวเมื่อไหร่
  /// 0 = ส่งครัวหลัง cashier settle (default — ปลอดภัยวัตถุดิบ)
  /// 1 = ส่งครัวทันทีตอนสั่ง (ลูกค้าได้อาหารเร็ว แต่ถ้าไม่จ่ายเสียวัตถุดิบ)
  int cashierKitchenTiming = 0;

  List<KitchenDeviceModel> kitchens;

  bool useMember = false;
  int itemsPerRow;

  PaymentRoundingModel paymentrounding;

  /// Order Here Text Customization
  String orderHereText;
  String orderHereTextColor;
  String orderHereTextColor2;
  String orderHereShadowColor;

  /// Order Layout Preset: 0=Default (category left), 1=KFC Style (category top)
  int orderLayoutPreset;

  /// Primary Theme Color for order pages (hex format, default: #FFDA291C - KFC Red)
  String primaryThemeColor;

  /// Primary Text Color for buttons, selected categories, and totals (hex format, default: #FFFFFFFF - White)
  String primaryTextColor;

  /// Flag to track if this is the first time setup
  bool isFirstTimeSetup;

  DeviceConfigModel(
      {String? shopId,
      String? branchId,
      String? orderStationCode,
      PrinterLocalConfigModel? printerForOwner,
      PrinterLocalConfigModel? printerForOrderStation,
      int? systemCondition,
      int? machineCondition,
      int? shopPaymentCondition,
      bool? orderOnlineCondition,
      bool? showQrCodeOrderOnline,
      double? latitude,
      double? longitude,
      String? deviceId,
      bool? useOrderEatAtTheRestaurant,
      bool? useOrderTakeAway,
      bool? isServer,
      int? cashierKitchenTiming,
      List<KitchenDeviceModel>? kitchens,
      bool? useMember,
      String? usercode,
      String? token,
      String? apikey,
      String? isdev,
      PaymentRoundingModel? paymentrounding,
      int? itemsPerRow,
      String? orderHereText,
      String? orderHereTextColor,
      String? orderHereTextColor2,
      String? orderHereShadowColor,
      int? orderLayoutPreset,
      String? primaryThemeColor,
      String? primaryTextColor,
      bool? isFirstTimeSetup})
      : token = token ?? "",
        shopId = shopId ?? "",
        apikey = apikey ?? "",
        isdev = isdev ?? "",
        usercode = usercode ?? "",
        useMember = useMember ?? false,
        branchId = branchId ?? "",
        orderStationCode = orderStationCode ?? "",
        printerForOwner = printerForOwner ?? PrinterLocalConfigModel(),
        printerForOrderStation =
            printerForOrderStation ?? PrinterLocalConfigModel(),
        systemCondition = systemCondition ?? 2,
        machineCondition = machineCondition ?? 0,
        shopPaymentCondition = shopPaymentCondition ?? 0,
        orderOnlineCondition = orderOnlineCondition ?? false,
        showQrCodeOrderOnline = showQrCodeOrderOnline ?? false,
        latitude = latitude ?? 0.0,
        longitude = longitude ?? 0.0,
        deviceId = deviceId ?? "",
        useOrderEatAtTheRestaurant = useOrderEatAtTheRestaurant ?? false,
        useOrderTakeAway = useOrderTakeAway ?? false,
        isServer = isServer ?? false,
        cashierKitchenTiming = cashierKitchenTiming ?? 0,
        kitchens = kitchens ?? [],
        itemsPerRow = itemsPerRow ?? 3,
        paymentrounding = paymentrounding ?? PaymentRoundingModel(),
        orderHereText = orderHereText ?? "Order\nHere!",
        orderHereTextColor = orderHereTextColor ?? "#FFFFFFFF",
        orderHereTextColor2 = orderHereTextColor2 ?? "",
        orderHereShadowColor = orderHereShadowColor ?? "#88000000",
        orderLayoutPreset = orderLayoutPreset ?? 0,
        primaryThemeColor = primaryThemeColor ?? "#FFB1441B",
        primaryTextColor = primaryTextColor ?? "#FFFFFFFF",
        isFirstTimeSetup = isFirstTimeSetup ?? true;

  factory DeviceConfigModel.fromJson(Map<String, dynamic> json) =>
      _$DeviceConfigModelFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceConfigModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LanguageSystemModel {
  String code;
  String text;

  LanguageSystemModel({required this.code, required this.text});

  factory LanguageSystemModel.fromJson(Map<String, dynamic> json) =>
      _$LanguageSystemModelFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageSystemModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LanguageSystemCodeModel {
  String code;
  List<LanguageSystemModel> langs;

  LanguageSystemCodeModel({required this.code, required this.langs});

  factory LanguageSystemCodeModel.fromJson(Map<String, dynamic> json) =>
      _$LanguageSystemCodeModelFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageSystemCodeModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderTempDetailModel {
  final String orderguid;
  final String barcode;
  final String optionselected;
  final String remark;
  final int istakeaway;
  final int isserved;
  final int isservedcancel;
  final int iscooked;
  final int iscookcancel;
  final DateTime orderdatetime;
  final double price;
  final double amount;
  final String machineid;
  final String ordertagnumber;
  final int queuenumber;
  final String salechannelcode;
  final String manufacturerguid;
  double qty;
  bool is_except_vat;

  String refguid;

  /// ยอดรวม Option
  double? optionamount;

  /// ยอดรวมส่วนลด
  double? discountamount;

  OrderTempDetailModel(
      {required this.orderguid,
      required this.barcode,
      required this.qty,
      required this.optionamount,
      required this.remark,
      required this.optionselected,
      required this.orderdatetime,
      required this.isserved,
      required this.iscooked,
      required this.iscookcancel,
      required this.isservedcancel,
      required this.ordertagnumber,
      required this.price,
      required this.amount,
      required this.discountamount,
      required this.salechannelcode,
      required this.machineid,
      required this.queuenumber,
      required this.istakeaway,
      bool? is_except_vat,
      String? refguid,
      String? manufacturerguid})
      : manufacturerguid = manufacturerguid ?? "",
        is_except_vat = is_except_vat ?? false,
        refguid = refguid ?? "";

  factory OrderTempDetailModel.fromJson(Map<String, dynamic> json) =>
      _$OrderTempDetailModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderTempDetailModelToJson(this);
}

@JsonSerializable()
class ResponseDataModel {
  final List<dynamic> data;

  ResponseDataModel({
    required this.data,
  });

  factory ResponseDataModel.fromJson(Map<String, dynamic> json) =>
      _$ResponseDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$ResponseDataModelToJson(this);
}

class OrderListModel {
  String name;
  String unitName;
  String imageUrl;
  double price;
  double orderQty;
  double amount;
  int isTakeAway;
  int isServed;
  String remark;
  String optionSelected;
  DateTime orderDateTime;

  OrderListModel(
      {required this.name,
      required this.unitName,
      required this.imageUrl,
      required this.orderQty,
      required this.isServed,
      required this.price,
      required this.isTakeAway,
      required this.remark,
      required this.optionSelected,
      required this.orderDateTime,
      required this.amount});
}

@JsonSerializable(explicitToJson: true)
class PrinterLocalConfigModel {
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
  int printerType;
  int printerConnectType;
  bool isConfigConnectSuccess;
  bool isReady;
  String formSummeryCode; // ใบสรุปยอดขาย
  String formTaxCode; // ใบกำกับภาษีแบบย่อย
  String formFullTaxCode; // ใบกำกับภาษีแบบเต็ม

  PrinterLocalConfigModel(
      {this.code = "",
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
      this.formSummeryCode = "",
      this.formTaxCode = "",
      this.formFullTaxCode = "",
      this.isConfigConnectSuccess = false,
      this.printerType = 0,
      this.printerConnectType = 0,
      this.printBillAuto = false});

  factory PrinterLocalConfigModel.fromJson(Map<String, dynamic> json) =>
      _$PrinterLocalConfigModelFromJson(json);
  Map<String, dynamic> toJson() => _$PrinterLocalConfigModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderOnlineParameterModel {
  String shopid;

  /// 0=สั่งจาก Order Kiosk ด้วย QrCode,1=สั่งด้วย Qrcode โต๊ะ,2=สั่งด้วยโทรศัพท์
  int type;
  String? table;
  String? qrcode;
  String? phone;
  String? tablebuffetcode;

  OrderOnlineParameterModel(
      {required this.shopid,
      this.type = 0,
      this.table = "",
      this.qrcode = "",
      this.phone = "",
      this.tablebuffetcode = ""});

  factory OrderOnlineParameterModel.fromJson(Map<String, dynamic> json) =>
      _$OrderOnlineParameterModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderOnlineParameterModelToJson(this);
}

class OrderTempModel {
  DateTime orderdatetime;
  String ordertagnumber;
  String orderid;
  String phonenumber;
  String tablenumber;
  String ordernumber;
  String salechannelcode;
  int queuenumber;
  int ordertype;
  int istakeaway;
  bool kitchensuccess;
  bool servedsuccess;
  PayResultModel payresult;
  int orderpaysuccess;
  int copyprintsuccess;

  OrderTempModel(
      {required this.orderid,
      required this.ordertagnumber,
      required this.orderdatetime,
      required this.phonenumber,
      required this.tablenumber,
      required this.ordernumber,
      required this.ordertype,
      required this.payresult,
      required this.istakeaway,
      required this.kitchensuccess,
      required this.servedsuccess,
      required this.salechannelcode,
      required this.orderpaysuccess,
      required this.copyprintsuccess,
      required this.queuenumber});
}

class OrderTempDocModel {
  OrderTempModel order;
  List<OrderTempDetailModel> orderDetails;

  OrderTempDocModel({required this.order, required this.orderDetails});
}

@JsonSerializable()
class ResponseExcludeModel {
  final bool success;

  ResponseExcludeModel({
    required this.success,
  });

  factory ResponseExcludeModel.fromJson(Map<String, dynamic> json) =>
      _$ResponseExcludeModelFromJson(json);
  Map<String, dynamic> toJson() => _$ResponseExcludeModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProfileQrPaymentModel {
  String code;
  String bankcode;
  List<LanguageNameModel> banknames;
  String bookbankcode;
  List<LanguageNameModel> bookbanknames;
  List<String> bookbankimages;
  bool isactive;
  bool isslipsave;
  int qrtype;
  List<LanguageNameModel> qrnames;
  String qrcode;
  String logo;
  String apikey;
  String accessCode;
  String bankcharge;
  String billerCode;
  String billerID;
  int closeQr;
  String customercharge;
  String guidfixed;
  String merchantName;
  String storeID;
  String terminalID;
  String token;
  String appid;
  String host;

  ProfileQrPaymentModel({
    String? guidfixed,
    String? code,
    String? bankcode,
    List<LanguageNameModel>? banknames,
    String? bookbankcode,
    List<LanguageNameModel>? bookbanknames,
    List<String>? bookbankimages,
    bool? isactive,
    int? qrtype,
    List<LanguageNameModel>? qrnames,
    String? qrcode,
    String? logo,
    String? apikey,
    String? accessCode,
    String? bankcharge,
    String? billerCode,
    String? billerID,
    int? closeQr,
    String? customercharge,
    String? merchantName,
    String? storeID,
    String? terminalID,
    String? token,
    String? appid,
    String? host,
    bool? isslipsave,
  })  : guidfixed = guidfixed ?? "",
        code = code ?? "",
        bankcode = bankcode ?? "",
        banknames = banknames ?? [],
        bookbankcode = bookbankcode ?? "",
        bookbanknames = bookbanknames ?? [],
        bookbankimages = bookbankimages ?? [],
        isactive = isactive ?? false,
        qrtype = qrtype ?? 0,
        qrnames = qrnames ?? [],
        qrcode = qrcode ?? "",
        logo = logo ?? "",
        apikey = apikey ?? "",
        accessCode = accessCode ?? "",
        bankcharge = bankcharge ?? "",
        billerCode = billerCode ?? "",
        billerID = billerID ?? "",
        closeQr = closeQr ?? 0,
        customercharge = customercharge ?? "",
        merchantName = merchantName ?? "",
        storeID = storeID ?? "",
        terminalID = terminalID ?? "",
        token = token ?? "",
        appid = appid ?? "",
        host = host ?? "",
        isslipsave = isslipsave ?? false;

  factory ProfileQrPaymentModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileQrPaymentModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileQrPaymentModelToJson(this);
}

class OrderTempDetailDataModel {
  final String orderId;
  final String orderGuid;
  final String barcode;
  final double qty;
  final String optionSelected;
  final String remark;
  final DateTime orderDateTime;
  final double price;
  final double amount;
  final int isTakeAway;
  final String tableNumber;
  final String orderTagNumber;
  final int queueNumber;
  final String salechannelcode;

  OrderTempDetailDataModel({
    required this.orderId,
    required this.orderGuid,
    required this.barcode,
    required this.qty,
    required this.remark,
    required this.optionSelected,
    required this.orderDateTime,
    required this.price,
    required this.amount,
    required this.isTakeAway,
    required this.tableNumber,
    required this.orderTagNumber,
    required this.salechannelcode,
    required this.queueNumber,
  });
}

@JsonSerializable(explicitToJson: true)
class LanguageDataModel {
  String code;
  String name;

  LanguageDataModel({required this.code, required this.name});

  factory LanguageDataModel.fromJson(Map<String, dynamic> json) =>
      _$LanguageDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$LanguageDataModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PayConditionModel {
  /// 0=เงินสด,1=บัตรเครดิต,2=QrCode,3=Delivery
  final int payType;

  /// ยอดรวมทั้งหมด
  final double amount;

  /// ยอดที่ลูกค้าจ่าย
  final double payAmount;

  /// เงินทอน
  double changeAmount;

  /// ประเภทการจ่ายเงิน
  final String payTypeName;

  String cardNumber;

  String approvalCode;

  double roundAmount = 0;

  PayConditionModel(
      {required this.payType,
      required this.payTypeName,
      required this.amount,
      required this.payAmount,
      required this.changeAmount,
      String? cardNumber,
      String? approvalCode,
      double? roundAmount})
      : roundAmount = roundAmount ?? 0,
        cardNumber = cardNumber ?? "",
        approvalCode = approvalCode ?? "";

  factory PayConditionModel.fromJson(Map<String, dynamic> json) =>
      _$PayConditionModelFromJson(json);

  Map<String, dynamic> toJson() => _$PayConditionModelToJson(this);
}

class PayResultModel {
  List<PayConditionModel> payCondition = [];
  double totalAmount = 0;
  double vatAmount = 0;
  String discountWord = "";
  double discountAmount = 0;
  double diffAmount = 0;
  double saveAmount = 0;
  double totalAmountBeforeDiscount = 0;
  double totalAmountAfterDiscount = 0;
  double totalAmountExceptVat = 0;
  double totalAmountBeforeVat = 0;
  double totalAmountAfterVat = 0;
  double vatrate = 0;

  // ข้อมูลแต้มสะสม
  double usePoint = 0; // แต้มที่ใช้
  double getPoint = 0; // แต้มที่จะได้รับ
  double pointDiscountAmount = 0; // ส่วนลดจากแต้ม (pointusagetype = 1)
  double payPointAmount = 0; // ยอดชำระจากแต้ม (pointusagetype = 2)
  double previousPointBalance = 0; // แต้มก่อนใช้ (แต้มเดิม)
  double currentPointBalance = 0; // แต้มคงเหลือหลังใช้แต้ม
  String memberName = ''; // ชื่อสมาชิก
  String memberPhone = ''; // เบอร์โทรสมาชิก
}

// ปัดเศษสตางค์
class MoneyRoundPayModel {
  double begin;
  double end;
  double value;

  MoneyRoundPayModel({
    required this.begin,
    required this.end,
    required this.value,
  });
}

class LineNotifyModel {
  final String token;

  /// เปิดการแจ้งเตือน
  final bool isEnable;

  /// เตือนเมื่อมีการบันทึกใบเสร็จ
  final bool isSaveBill;

  /// เตือนเมื่อสินค้าหมด
  final bool isOutOfStock;

  /// เตือนเมื่อสินค้าใกล้หมด (เหลือต่ำกว่าจุดผลิต)
  final bool isNearOutOfStock;

  LineNotifyModel({
    required this.token,
    required this.isEnable,
    required this.isSaveBill,
    required this.isOutOfStock,
    required this.isNearOutOfStock,
  });
}

class TotalCalculateModel {
  double qty = 0;
  double totalAmount = 0;
  double totalDiscount = 0;
  double totalAfterDiscount = 0;
}

class OrderQueueStatusModel {
  String queuenumber;
  double balance;
  double qty;

  OrderQueueStatusModel({
    required this.queuenumber,
    required this.balance,
    required this.qty,
  });
}

class TableModel {
  String tableNumber;
  double totalAmount;

  TableModel(this.tableNumber, this.totalAmount);
}

@JsonSerializable(explicitToJson: true)
class OrderTempTableModel {
  String ordertagnumber;
  double totalamount;

  OrderTempTableModel({
    required this.ordertagnumber,
    required this.totalamount,
  });

  factory OrderTempTableModel.fromJson(Map<String, dynamic> json) =>
      _$OrderTempTableModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderTempTableModelToJson(this);
}
