import 'dart:async';

import 'package:dedekiosk/model/trans_model.dart';
import 'package:dedekiosk/objectbox/objectbox.g.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/util/environment.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';
import 'package:dedekiosk/model/category_model.dart';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/util/print_queue.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:visibility_detector/visibility_detector.dart';
import 'package:dedekiosk/util/logger.dart';

bool allGranted = false;
String appVersion = ""; // Will be set from package_info_plus
String lineId = "https://lin.ee/7OQbXZU";
String clickHouseDatabaseName = "dedeorder";
String shopProfileTempString = "";
int cameraMode = 0; // 0 = front, 1 = back
List<LineNotifyModel> lineNotifyList = [];
bool isDemoMode = false;
List<PayConditionModel> payCondition = [];
String billImagePath = "orderstationbill";
String qrPaymentProofPath = "qrpaymentproof"; // Path สำหรับเก็บรูปหลักฐานการโอนเงิน (mode=1)
List<MoneyRoundPayModel> payTotalMoneyRoundStep = [
  MoneyRoundPayModel(begin: 0.01, end: 0.12, value: 0),
  MoneyRoundPayModel(begin: 0.13, end: 0.37, value: 0.25),
  MoneyRoundPayModel(begin: 0.38, end: 0.62, value: 0.5),
  MoneyRoundPayModel(begin: 0.63, end: 0.87, value: 0.75),
  MoneyRoundPayModel(begin: 0.88, end: 0.99, value: 1.0),
];
String adminPinCode = "";
String logoUrl = "";
late io.Directory applicationDocumentsDirectory;
ShopProfileModel? shopProfile;
late Store objectBoxStore;
String beepScanSuccess = "assets/audios/scan_success.wav";
String beepScanFail = "assets/audios/scan_fail.wav";
String beepButtonTing = "assets/audios/button_ting.wav";
late List<LanguageSystemModel> languageSystemData;
late List<LanguageSystemCodeModel> languageSystemCode;
List<CategoryModel> categoryList = [];
List<ProductProcessModel> productList = [];
String phoneNumber = '';
String tableNumber = '';
bool isNetworkError = false;
String tableBuffetCode = '';
String languageForCustomer = "th";
String languageForStaff = "th";
String orderId = "";
final moneyFormat = NumberFormat("##,##0.##");
final moneyFormatAndDot = NumberFormat("##,##0.00");
String memberPhoneNumber = "";
bool checkOrderActivePrint = false;
String memberName = "";
String memberPicture = "";
String memberEmail = "";
int videoIndex = 0;
bool orderShowImage = true;
String posTerminalPinCode = "";
int categoryIndex = -1;
List<TransNameInfoModel> custNames = [];
String storageDeviceConfigName = "order-station-device-config";
List<PrintTicketClass> printQueue = [];
bool printQueueProcessing = false;
bool kitchenPrintQueueProcessing = false;

/// ปิด kitchen print ชั่วคราว (ใช้เมื่อไม่มีเครื่องพิมพ์ต่ออยู่)
bool kitchenPrintDisabled = false;

/// Track orderId ที่กำลัง process อยู่เพื่อป้องกันการพิมพ์ครัวซ้ำ
Set<String> kitchenPrintProcessingOrderIds = {};

/// Track orderId ที่พิมพ์ครัวไปแล้ว (last line of defense ป้องกันพิมพ์ซ้ำ)
Set<String> kitchenPrintedOrderIds = {};

/// Track orderGuid (รายการแต่ละชิ้น) ที่พิมพ์ครัวสำเร็จแล้ว
/// ใช้เพื่อป้องกันการพิมพ์ซ้ำเมื่อ retry หลังจากเครื่องพิมพ์กลับมาทำงาน
Set<String> kitchenPrintedOrderGuids = {};

bool checkOrderActive = false;
bool checkDeviceActive = false;
int screenMode = 0;
List<ProfileQrPaymentModel> profileQrPayment = [];
List<String> countryNames = ["ไทย", "English", "ລາວ", "中国的", "日本", "한국"];
List<String> countryCodes = ["th", "en", "lo", "cn", "jp", "kr"];
List<String> orderTagNumbers = [];
int countDownForHomeMax = 60 * 5;
int countDownForHome = countDownForHomeMax;
String edcProductName = "";
List<dynamic> driversAvailableList = [];
const platform = MethodChannel('com.smlsoft.dedekiosk/usb');
bool isMobileScreen = false;
Timer? syncTimer;
String saleChannelCode = "";
double saleChannelgp = 0;
int saleChannelgptype = 0;
String saleChannelName = "";
String saleChannelImage = "";
bool isMember = false;
String memberCode = "";
String memberPointsCode = ""; // รหัสแต้มสะสม
int memberPriceLevel = 1; // ระดับราคาสมาชิก
String memberGuidFixed = ""; // GUID สมาชิก
double memberPointBalance = 0; // ยอดแต้มสะสมปัจจุบัน

// ตัวแปรสำหรับระบบแต้มสะสม (Transaction)
double usePoint = 0; // แต้มที่ใช้
double getPoint = 0; // แต้มที่จะได้รับ
double pointDiscountAmount = 0; // ส่วนลดจากแต้ม (ถ้า pointusagetype = 1)
double pointAmount = 0; // ยอดชำระจากแต้ม (ถ้า pointusagetype = 2)
double currentPointBalance = 0; // แต้มคงเหลือหลังใช้แต้ม

String lineMember = "";
String lineDestination = "";
String memberPinCode = "";
bool memberPinMode = true;
String telegramDevBotToken = const String.fromEnvironment('TELEGRAM_DEV_BOT_TOKEN');
String telegramDevChatId = const String.fromEnvironment('TELEGRAM_DEV_CHAT_ID');
String telegramTransBotToken = const String.fromEnvironment('TELEGRAM_BOT_TOKEN');
String telegramTransChatId = const String.fromEnvironment('TELEGRAM_CHAT_ID');
String bluetoothPlatformVersion = "";
int bluetoothPorcentBatery = 0;

/// โต๊ะที่เลือก
OrderTempTableModel tableNumberSelected = OrderTempTableModel(ordertagnumber: "", totalamount: 0);

/// 1=ราคาหน้าร้าน,2=ราคาสมาชิก,3=ราคา Delivery,4=ราคา Take Away
int priceIndex = 1;

/// 0=สั่งกินที่ร้าน 1=สั่งกลับบ้าน 5=เปลี่ยนสถานะสินค้า 6=ปรับปรุงยอดคงเหลือ
int orderType = 0;

/// 0=สั่งกินที่ร้าน 1=สั่งกลับบ้าน
int isTakeAway = 0;

DeviceConfigModel deviceConfig = DeviceConfigModel(
    usercode: "",
    token: "",
    shopId: "",
    branchId: "",
    orderStationCode: "",
    deviceId: "",
    printerForOwner: PrinterLocalConfigModel(),
    printerForOrderStation: PrinterLocalConfigModel(),
    systemCondition: 2,
    machineCondition: 0,
    shopPaymentCondition: 0,
    itemsPerRow: 3,
    latitude: 0,
    longitude: 0,
    showQrCodeOrderOnline: false,
    useOrderEatAtTheRestaurant: true,
    useOrderTakeAway: false,
    useMember: false,
    isServer: false,
    kitchens: [],
    isdev: "0",
    orderOnlineCondition: false);

enum PrintColumnAlign { left, right, center }

enum PrinterConnectEnum { ip, bluetooth, usb, windows }

enum PrinterTypeEnum { thermal, dot, laser, inkjet }

int printerDelayMilliseconds = 100;

int printerConnect(PrinterConnectEnum printerConnectEnum) {
  switch (printerConnectEnum) {
    case PrinterConnectEnum.ip:
      return 1;
    case PrinterConnectEnum.bluetooth:
      return 2;
    case PrinterConnectEnum.usb:
      return 3;
    case PrinterConnectEnum.windows:
      return 4;
    default:
      return 1;
  }
}

PrinterConnectEnum printerConnectToEnum(int printerConnect) {
  switch (printerConnect) {
    case 1:
      return PrinterConnectEnum.ip;
    case 2:
      return PrinterConnectEnum.bluetooth;
    case 3:
      return PrinterConnectEnum.usb;
    case 4:
      return PrinterConnectEnum.windows;
    default:
      return PrinterConnectEnum.ip;
  }
}

int printerType(PrinterTypeEnum printerTypeEnum) {
  switch (printerTypeEnum) {
    case PrinterTypeEnum.thermal:
      return 1;
    case PrinterTypeEnum.dot:
      return 2;
    case PrinterTypeEnum.laser:
      return 3;
    case PrinterTypeEnum.inkjet:
      return 4;
    default:
      return 1;
  }
}

/*Future<void> checkTableStatus(BuildContext context) async {
  String query =
      "select tablestatus from ${global.clickHouseDatabaseName}.tableinfo where tablenumber='$tableNumber' and shopid='${deviceConfig.shopId}'";
  var value = await api.clickHouseSelect(query);
  ResponseDataModel responseData = ResponseDataModel.fromJson(value);
  bool switchToClose = false;
  if (responseData.data.isNotEmpty) {
    int tableStatus = responseData.data[0]["tablestatus"];
    if (tableStatus != 1) {
      switchToClose = true;
    }
  } else {
    switchToClose = true;
  }
  if (switchToClose) {
    if (context.mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/close', (Route<dynamic> route) => false);
    }
  }
}
*/

void languageSelect(String languageCode) {
  languageSystemData = [];
  for (int i = 0; i < languageSystemCode.length; i++) {
    for (int j = 0; j < languageSystemCode[i].langs.length; j++) {
      if (languageSystemCode[i].langs[j].code == languageForCustomer) {
        languageSystemData.add(LanguageSystemModel(code: languageSystemCode[i].code.trim(), text: languageSystemCode[i].langs[j].text.trim()));
      }
    }
  }
  languageSystemData.sort((a, b) {
    return a.code.compareTo(b.code);
  });
}

String language(String code) {
  String result = code;
  for (int i = 0; i < languageSystemData.length; i++) {
    if (languageSystemData[i].code == code) {
      result = languageSystemData[i].text;
      break;
    }
  }
  return result;
}

// ค้นหาภาษาอื่นๆ
String findLanguage({required String code, required String languageCode}) {
  String result = code;

  for (int i = 0; i < languageSystemCode.length; i++) {
    if (languageSystemCode[i].code == code) {
      for (int j = 0; j < languageSystemCode[i].langs.length; j++) {
        if (languageSystemCode[i].langs[j].code == languageCode) {
          result = languageSystemCode[i].langs[j].text;
          break;
        }
      }
      break;
    }
  }
  return result;
}

int findProductByBarcode(String barcode) {
  int index = -1;
  for (int i = 0; i < productList.length; i++) {
    if (productList[i].barcode == barcode) {
      index = i;
      break;
    }
  }
  return index;
}

List<LanguageNameModel> languageJsonDecode(String jsonNames) {
  return jsonDecode(jsonNames).map<LanguageNameModel>((item) {
    return LanguageNameModel.fromJson(item);
  }).toList();
}

String getNameFromJsonLanguage(String jsonNames, String languageCode) {
  List<LanguageNameModel> names = languageJsonDecode(jsonNames);
  for (var item in names) {
    if (item.code == languageCode) {
      return item.name;
    }
  }
  return (names.isNotEmpty) ? names[0].name : "*";
}

String getNameFromLanguage(List<LanguageNameModel> names, String languageCode) {
  for (var item in names) {
    if (item.code == languageCode) {
      return item.name;
    }
  }
  return (names.isNotEmpty) ? names[0].name : "*";
}

String diffTime(DateTime start, DateTime stop) {
  Duration diff = stop.difference(start);
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(diff.inMinutes.remainder(60));
  return "${twoDigits(diff.inHours)}:$twoDigitMinutes";
}

bool _isPrivateIpv4Address(String value) {
  final parts = value.split('.');
  if (parts.length != 4) return false;

  final octets = parts.map((part) => int.tryParse(part)).toList();
  if (octets.any((octet) => octet == null || octet < 0 || octet > 255)) {
    return false;
  }

  final first = octets[0]!;
  final second = octets[1]!;
  return first == 10 || (first == 172 && second >= 16 && second <= 31) || (first == 192 && second == 168);
}

Future<String> ipAddress() async {
  // Get a list of the network interfaces available on the device
  List<io.NetworkInterface> interfaces = await io.NetworkInterface.list();

  // Iterate through the list of interfaces and return the first non-loopback IPv4 address
  for (io.NetworkInterface interface in interfaces) {
    if (interface.name == 'lo') continue; // Skip the loopback interface
    for (io.InternetAddress address in interface.addresses) {
      if (_isPrivateIpv4Address(address.address) && address.type == io.InternetAddressType.IPv4) {
        return address.address;
      }
    }
  }

  // If no non-loopback IPv4 address was found, return null
  return "";
}

Future<void> connectToDevice(data) async {
  if (data == "") {
    return;
  }
  try {
    final result = await platform.invokeMethod('connectToDevice', {
      "productName": data,
    });

    edcProductName = data;
    Logger.d('Connection result: $result');
  } on PlatformException catch (e, s) {
    Logger.e('Error occurred', error: e, stackTrace: s);

    edcProductName = "";
    Logger.d('Failed to connect to the device: ${e.message}');
  }
}

Future<void> loadConfig() async {
  applicationDocumentsDirectory = await getApplicationDocumentsDirectory();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  DeviceConfigModel getDeviceConfig = DeviceConfigModel.fromJson(await jsonDecode(prefs.getString(storageDeviceConfigName) ?? "{}"));
  // ดึงชื่อร้าน
  if (getDeviceConfig.isdev == '0') {
    Environment().initConfig("PROD");
  } else if (getDeviceConfig.isdev == '1') {
    Environment().initConfig("DEV");
  } else {
    Environment().initConfig("STAGING");
  }
  deviceConfig.shopId = getDeviceConfig.shopId;
  if (getDeviceConfig.shopId == "") {
    return;
  }
  var profile = await api.getShopProfileFromServer(deviceConfig: getDeviceConfig, shopId: getDeviceConfig.shopId, orderStationCode: getDeviceConfig.orderStationCode);

  if (jsonEncode(profile) != shopProfileTempString) {
    deviceConfig = getDeviceConfig;
    // กรณีมีการแก้ไขข้อมูล
    shopProfileTempString = jsonEncode(profile);
    try {
      shopProfile = ShopProfileModel.fromJson(profile["data"]);
    } catch (e, s) {
      Logger.e('Error occurred', error: e, stackTrace: s);
    }
    if (shopProfile!.kitchens == null) {
      shopProfile!.kitchens = [];
    }
    deviceConfig.useMember = shopProfile!.isbcmember;
    deviceConfig.branchId = shopProfile!.orderstation.branch.code;
    deviceConfig.paymentrounding = shopProfile!.orderstation.branch.paymentrounding;
    profileQrPayment = shopProfile!.orderstation.qrcodes;
    logoUrl = shopProfile!.orderstation.branch.logouri;
    String tagNumber = shopProfile!.orderstation.label;
    while (tagNumber.contains(" ")) {
      tagNumber = tagNumber.replaceAll(" ", "");
    }
    var orderTags = tagNumber.split(",");
    orderTagNumbers = [];
    for (var item in orderTags) {
      if (item.contains("-")) {
        var orderTag = item.split("-");
        int start = int.parse(orderTag[0]);
        int end = int.parse(orderTag[1]);
        for (int i = start; i <= end; i++) {
          orderTagNumbers.add(i.toString());
        }
      } else {
        orderTagNumbers.add(item);
      }
    }
    adminPinCode = shopProfile!.orderstation.adminpin;

    // ดึง logo
    if (logoUrl.isNotEmpty) {
      try {
        var response = await http.get(Uri.parse(logoUrl));
        var file = io.File(getPosLogoPathName());
        await file.writeAsBytes(response.bodyBytes);
      } catch (e, s) {
        Logger.e('Error occurred', error: e, stackTrace: s);

        logoUrl = "";
      }
    }
    if (isDemoMode) {
      const demoLineNotifyToken = String.fromEnvironment('DEMO_LINE_NOTIFY_TOKEN');
      if (demoLineNotifyToken.isNotEmpty) {
        lineNotifyList.add(LineNotifyModel(
          token: demoLineNotifyToken,
          isEnable: true,
          isSaveBill: true,
          isNearOutOfStock: true,
          isOutOfStock: true,
        ));
      }
    } else {
      // group
      try {
        var getLineNotify = await api.getLineNotifyFromServer(deviceConfig: getDeviceConfig, shopId: getDeviceConfig.shopId);

        try {
          lineNotifyList = [];
          var dataJson = getLineNotify["data"];
          for (var item in dataJson) {
            var lineNotify = LineNotifyFromServerModel.fromJson(item);
            lineNotifyList.add(LineNotifyModel(
              token: lineNotify.token,
              isEnable: true,
              isSaveBill: true,
              isNearOutOfStock: true,
              isOutOfStock: true,
            ));
          }
        } catch (e, s) {
          Logger.e('Error occurred', error: e, stackTrace: s);
        }
      } catch (e, s) {
        Logger.e('Error occurred', error: e, stackTrace: s);
      }
    }

    /*profileQrPayment.add(ProfileQrPaymentModel(
      guidfixed: const Uuid().v4(),
      code: "Lugent",
      bankcode: "Lugent",
      banknames: [
        LanguageNameModel(
            code: "th", name: "Prompt Pay", isauto: false, isdelete: false)
      ],
      bookbankcode: "Lugent",
      bookbanknames: [],
      bookbankimages: [],
      isactive: true,
      qrcode: "",
      qrnames: [],
      logo: "https://plern.co/assets/images/promptpay.png",
      accessCode: "",
      apikey: "",
      bankcharge: "",
      billerCode: "",
      billerID: "",
      closeQr: 0,
      customercharge: "",
      merchantName: "Lugent",
      qrtype: 110,
      storeID: "",
      terminalID: "",
    ));
    profileQrPayment.add(ProfileQrPaymentModel(
      guidfixed: const Uuid().v4(),
      code: "Lugent",
      bankcode: "Lugent",
      banknames: [
        LanguageNameModel(
            code: "th", name: "Ali Pay", isauto: false, isdelete: false)
      ],
      bookbankcode: "Lugent",
      bookbanknames: [],
      bookbankimages: [],
      isactive: true,
      qrcode: "",
      qrnames: [],
      logo:
          "https://chengdu-expat.com/wp-content/uploads/2019/07/alipay11111.jpg.webp",
      accessCode: "",
      apikey: "",
      bankcharge: "",
      billerCode: "",
      billerID: "",
      closeQr: 0,
      customercharge: "",
      merchantName: "Lugent",
      qrtype: 111,
      storeID: "",
      terminalID: "",
    ));
    profileQrPayment.add(ProfileQrPaymentModel(
      guidfixed: const Uuid().v4(),
      code: "Lugent",
      bankcode: "Lugent",
      banknames: [
        LanguageNameModel(
            code: "th", name: "True Money", isauto: false, isdelete: false)
      ],
      bookbankcode: "Lugent",
      bookbanknames: [],
      bookbankimages: [],
      isactive: true,
      qrcode: "",
      qrnames: [],
      logo:
          "https://i.playboard.app/p/aWp38-LVqL_fztxB3VkBaYHj6otE3dmCq-QMhEJUdRvDQbn1xU5gvU9CrB15x6-aWbLA9oQ1CQ/default.webp",
      accessCode: "",
      apikey: "",
      bankcharge: "",
      billerCode: "",
      billerID: "",
      closeQr: 0,
      customercharge: "",
      merchantName: "Lugent",
      qrtype: 112,
      storeID: "",
      terminalID: "",
    ));
    profileQrPayment.add(ProfileQrPaymentModel(
      guidfixed: const Uuid().v4(),
      code: "Lugent",
      bankcode: "Lugent",
      banknames: [
        LanguageNameModel(
            code: "th", name: "Line Pay", isauto: false, isdelete: false)
      ],
      bookbankcode: "Lugent",
      bookbanknames: [],
      bookbankimages: [],
      isactive: true,
      qrcode: "",
      qrnames: [],
      logo:
          "https://www.gsb-pracharat.com/wp-content/uploads/2022/05/rabbit-line-pay.png",
      accessCode: "",
      apikey: "",
      bankcharge: "",
      billerCode: "",
      billerID: "",
      closeQr: 0,
      customercharge: "",
      merchantName: "Lugent",
      qrtype: 113,
      storeID: "",
      terminalID: "",
    ));
    profileQrPayment.add(ProfileQrPaymentModel(
      guidfixed: const Uuid().v4(),
      code: "Lugent",
      bankcode: "Lugent",
      banknames: [
        LanguageNameModel(
            code: "th", name: "Wechat Pay", isauto: false, isdelete: false)
      ],
      bookbankcode: "Lugent",
      bookbanknames: [],
      bookbankimages: [],
      isactive: true,
      qrcode: "",
      qrnames: [],
      logo:
          "https://cdn.punchng.com/wp-content/uploads/2018/03/06085848/WeChat-logo.jpg",
      accessCode: "",
      apikey: "",
      bankcharge: "",
      billerCode: "",
      billerID: "",
      closeQr: 0,
      customercharge: "",
      merchantName: "Lugent",
      qrtype: 114,
      storeID: "",
      terminalID: "",
    ));*/
    // gb prime pay
    // profileQrPayment.add(ProfileQrPaymentModel(
    //   guidfixed: const Uuid().v4(),
    //   code: "Lugent",
    //   bankcode: "Lugent",
    //   banknames: [LanguageNameModel(code: "th", name: "Prompt Pay", isauto: false, isdelete: false)],
    //   bookbankcode: "Lugent",
    //   bookbanknames: [],
    //   bookbankimages: [],
    //   isactive: true,
    //   qrcode: "",
    //   qrnames: [],
    //   logo: "https://plern.co/assets/images/promptpay.png",
    //   accessCode: "",
    //   apikey: "",
    //   bankcharge: "",
    //   billerCode: "",
    //   billerID: "",
    //   closeQr: 0,
    //   customercharge: "",
    //   merchantName: "บริษัท โซมาย จำกัด",
    //   qrtype: 801,
    //   storeID:
    //       "",
    //   terminalID: "",
    // ));
  }
  deviceConfig.systemCondition = 2;
}

String generateRandomPin(int pinLength) {
  String pin = "";
  var rnd = Random();
  for (var i = 0; i < pinLength; i++) {
    pin += rnd.nextInt(10).toString();
  }
  return pin;
}

Future<void> saveDeviceConfigToStorage(BuildContext context) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // ลบข้อมูลเก่าออก
    await prefs.remove(storageDeviceConfigName);
    // บันทึกข้อมูลใหม่
    await prefs.setString(storageDeviceConfigName, jsonEncode(deviceConfig.toJson()));
    if (context.mounted) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(language("save_success")),
      //     backgroundColor: Colors.deepOrange,
      //   ),
      // );
    }
  } catch (e, s) {
    Logger.e('Error occurred', error: e, stackTrace: s);
  }
}

Future<void> saveDeviceConfigToStorageWithoutContext() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageDeviceConfigName);
    await prefs.setString(storageDeviceConfigName, jsonEncode(deviceConfig.toJson()));
  } catch (e, s) {
    Logger.e('Error occurred', error: e, stackTrace: s);
  }
}

Future<String> orderRunning() async {
  // Type 0=คริสต์ศักราช,1=พุทธศักราช
  // YYYY = ปี
  // MM = เดือน
  // DD = วัน
  // ###### = ลำดับ
  // ตัวอย่าง 001################ สำหรับ Tax ABB เครื่อง POS (001=รหัสเครื่อง POS)
  // ตัวอย่าง 002YYMMDD########## สำหรับ Tax ABB เครื่อง POS (002=รหัสเครื่อง POS)
  // ตัวอย่าง SO-YYMMDD-###### สำหรับขาย
  // ตัวอย่าง PO-YYMMDD-###### สำหรับซื้อ
  String orderFormat = "${shopProfile!.orderstation.deviceinfo.code}-${shopProfile!.orderstation.deviceinfo.docformat}";
  DateTime dateTimeNow = DateTime.now();
  String dateNow = DateFormat('yyyyMMdd').format(dateTimeNow);
  String dateNowQuery = DateFormat('yyyy-MM-dd').format(dateTimeNow);
  String result = "";
  String countDigit = "";
  String lastDigit = "";
  for (var item in orderFormat.split("")) {
    if (item == "#") {
      countDigit += "0";
      lastDigit += "9";
    }
  }
  String docFormat = orderFormat.replaceAll("#", "");
  docFormat = docFormat.replaceAll("YYYY", dateNow.substring(0, 4));
  docFormat = docFormat.replaceAll("YY", dateNow.substring(2, 4));
  docFormat = docFormat.replaceAll("MM", dateNow.substring(4, 6));
  docFormat = docFormat.replaceAll("DD", dateNow.substring(6, 8));

  int number = 0;
  var lastDocNumberJson = await api.serverGetLastDocNumber(docNumber: docFormat + lastDigit);
  String lastDocNumber = "";
  try {
    lastDocNumber = lastDocNumberJson["data"];
  } catch (e, s) {
    Logger.e('Error occurred', error: e, stackTrace: s);
  }
  if (lastDocNumber.isNotEmpty) {
    try {
      if (lastDocNumber.substring(0, docFormat.length) == docFormat) {
        number = int.parse(lastDocNumber.substring(lastDocNumber.length - countDigit.length));
      }
    } catch (e, s) {
      Logger.e('Error occurred', error: e, stackTrace: s);

      sendErrorToDevTeam("orderRunning : $e");
    }
  }
  result = "$docFormat${(NumberFormat(countDigit)).format(number + 1)}";
  return result;
}

Future<String> orderPayLaterRunning() async {
  // Type 0=คริสต์ศักราช,1=พุทธศักราช
  // YYYY = ปี
  // MM = เดือน
  // DD = วัน
  // ###### = ลำดับ
  // ตัวอย่าง 001################ สำหรับ Tax ABB เครื่อง POS (001=รหัสเครื่อง POS)
  // ตัวอย่าง 002YYMMDD########## สำหรับ Tax ABB เครื่อง POS (002=รหัสเครื่อง POS)
  // ตัวอย่าง SO-YYMMDD-###### สำหรับขาย
  // ตัวอย่าง PO-YYMMDD-###### สำหรับซื้อ
  String orderFormat = "${shopProfile!.orderstation.deviceinfo.code}-${shopProfile!.orderstation.deviceinfo.docformat}";
  DateTime dateTimeNow = DateTime.now();
  String dateNow = DateFormat('yyyyMMdd').format(dateTimeNow);
  String dateNowQuery = DateFormat('yyyy-MM-dd').format(dateTimeNow);
  String result = "";
  String countDigit = "";
  String lastDigit = "";
  for (var item in orderFormat.split("")) {
    if (item == "#") {
      countDigit += "0";
      lastDigit += "9";
    }
  }
  String docFormat = orderFormat.replaceAll("#", "");
  docFormat = docFormat.replaceAll("YYYY", dateNow.substring(0, 4));
  docFormat = docFormat.replaceAll("YY", dateNow.substring(2, 4));
  docFormat = docFormat.replaceAll("MM", dateNow.substring(4, 6));
  docFormat = docFormat.replaceAll("DD", dateNow.substring(6, 8));

  int number = 0;
  String queryGetLast =
      "select ordernumber from $clickHouseDatabaseName.ordertempdocpaylater where shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and toDate(toTimeZone(orderdatetime, 'Asia/Bangkok'))='$dateNowQuery' order by ordernumber desc limit 1";
  var resultRunning = await api.clickHouseSelect(queryGetLast);
  ResponseDataModel responseData = ResponseDataModel.fromJson(resultRunning);
  if (responseData.data.isNotEmpty) {
    String orderNumber = responseData.data[0]["ordernumber"];
    try {
      if (orderNumber.substring(0, docFormat.length) == docFormat) {
        number = int.parse(orderNumber.substring(orderNumber.length - countDigit.length));
      }
    } catch (e, s) {
      Logger.e('Error occurred', error: e, stackTrace: s);
    }
  }
  result = "X$docFormat${(NumberFormat(countDigit)).format(number + 1)}";
  Logger.d("orderPayLaterRunning : $result");
  return result;
}

// ======================== OFFLINE FALLBACK HELPERS ========================

/// OFF document numbers are disabled. Use BillLedgerService.reserveNextDocNo().
@Deprecated('OFF document numbers are disabled; use BillLedgerService.reserveNextDocNo().')
String generateOfflineOrderNumber() {
  throw UnsupportedError('OFF document numbers are disabled');
}

String _queueRunningDateKey(DateTime now) => DateFormat('yyyy-MM-dd').format(now);

String _localQueueRunningStorageKey(String dateKey) {
  return 'local_queue_running|${deviceConfig.shopId}|${deviceConfig.branchId}|${deviceConfig.orderStationCode}|$dateKey';
}

Future<int> _getLocalLatestQueueNumber(String dateKey) async {
  int latest = 0;
  try {
    final prefs = await SharedPreferences.getInstance();
    latest = max(latest, prefs.getInt(_localQueueRunningStorageKey(dateKey)) ?? 0);
  } catch (_) {}

  try {
    final box = objectBoxStore.box<BillLedgerModel>();
    for (final ledger in box.getAll()) {
      if (ledger.shopId != deviceConfig.shopId || ledger.branchId != deviceConfig.branchId || ledger.orderStationCode != deviceConfig.orderStationCode || ledger.docDateKey != dateKey || ledger.payloadJson.isEmpty) {
        continue;
      }
      final payload = jsonDecode(ledger.payloadJson);
      if (payload is! Map) continue;
      final queueNumber = int.tryParse((payload['queueNumber'] ?? '').toString()) ?? 0;
      // Ignore old HHMM fallback values such as 1412.
      if (queueNumber > 0 && queueNumber < 1000) {
        latest = max(latest, queueNumber);
      }
    }
  } catch (_) {}
  return latest;
}

Future<void> _rememberLocalQueueNumber(String dateKey, int queueNumber) async {
  if (queueNumber <= 0 || queueNumber >= 1000) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    final key = _localQueueRunningStorageKey(dateKey);
    final current = prefs.getInt(key) ?? 0;
    if (queueNumber > current) {
      await prefs.setInt(key, queueNumber);
    }
  } catch (_) {}
}

/// สร้าง queue number local ต่อจากเลขล่าสุดที่เครื่องรู้จัก
Future<int> generateLocalQueueNumber({String? dateKey}) async {
  final key = dateKey ?? _queueRunningDateKey(DateTime.now());
  final queueNumber = (await _getLocalLatestQueueNumber(key)) + 1;
  await _rememberLocalQueueNumber(key, queueNumber);
  return queueNumber;
}

/// Legacy helper. OFF fallback is disabled; callers should use BillLedgerService.
Future<Map<String, dynamic>> getOrderNumberWithFallback({Duration timeout = const Duration(seconds: 3)}) async {
  try {
    String orderNumber = await orderRunning().timeout(timeout);
    return {
      'orderNumber': orderNumber,
      'isOffline': false,
    };
  } on TimeoutException {
    Logger.w('getOrderNumberWithFallback: Timeout; OFF fallback is disabled');
    rethrow;
  } catch (e) {
    Logger.w('getOrderNumberWithFallback: Error $e; OFF fallback is disabled');
    rethrow;
  }
}

/// ดึง queue number พร้อม timeout และ fallback local
Future<Map<String, dynamic>> getQueueNumberWithFallback({required String orderId, Duration timeout = const Duration(seconds: 6)}) async {
  final dateKey = _queueRunningDateKey(DateTime.now());
  final localLatestQueueNumber = await _getLocalLatestQueueNumber(dateKey);
  try {
    int queueNumber = await api.getOrderQueueRunningFromServer(orderId, minQueueNumber: localLatestQueueNumber).timeout(timeout);
    await _rememberLocalQueueNumber(dateKey, queueNumber);
    return {
      'queueNumber': queueNumber,
      'isOffline': false,
    };
  } on TimeoutException {
    Logger.w('getQueueNumberWithFallback: Timeout, using local queue');
    return {
      'queueNumber': await generateLocalQueueNumber(dateKey: dateKey),
      'isOffline': true,
    };
  } catch (e) {
    Logger.w('getQueueNumberWithFallback: Error $e, using local queue');
    return {
      'queueNumber': await generateLocalQueueNumber(dateKey: dateKey),
      'isOffline': true,
    };
  }
}

// ======================== END OFFLINE FALLBACK HELPERS ========================

double calculateRoundedAmount(double amount, String paymentType) {
  double roundedAmount = amount;

  PaymentMethodRoundingModel roundingConfig;

  switch (paymentType) {
    case 'cash':
      roundingConfig = deviceConfig.paymentrounding.cash;
      break;
    case 'creditcard':
      roundingConfig = deviceConfig.paymentrounding.creditcard;
      break;
    case 'qrcode':
      roundingConfig = deviceConfig.paymentrounding.qrcode;
      break;
    case 'banktransfer':
      roundingConfig = deviceConfig.paymentrounding.banktransfer;
      break;
    case 'cheque':
      roundingConfig = deviceConfig.paymentrounding.cheque;
      break;
    case 'coupon':
      roundingConfig = deviceConfig.paymentrounding.coupon;
      break;
    case 'delivery':
      roundingConfig = deviceConfig.paymentrounding.delivery;
      break;
    default:
      return roundedAmount;
  }

  if (roundingConfig.enabled != true || roundingConfig.rules.isEmpty) {
    return roundedAmount;
  }

  int wholePart = amount.floor();
  double decimalPart = amount - wholePart;

  for (var rule in roundingConfig.rules) {
    if (decimalPart >= rule.lowerbound && decimalPart <= rule.upperbound) {
      roundedAmount = wholePart + rule.roundto;
      break;
    }
  }

  return roundedAmount;
}

Color get primaryThemeColor {
  return _hexToColor(deviceConfig.primaryThemeColor);
}

Color get primaryTextColor {
  return _hexToColor(deviceConfig.primaryTextColor);
}

// Helper function to convert hex string to Color
Color _hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

double calcTextToNumber(String text) {
  double result = 0;
  String textTrim = text.trim();
  while (textTrim.contains(" ")) {
    textTrim = textTrim.replaceAll(" ", "");
  }
  if (textTrim.isNotEmpty) {
    textTrim = textTrim.replaceAll("X", "").replaceAll("x", "").replaceAll("+", "").replaceAll(",", "").replaceAll("-", "");
    result = double.parse(textTrim);
  }
  return result;
}

/// ยอดคงเหลือสินค้าทั้งหมด
Future<void> getBalanceQtyAllFromServer() async {
  // คำนวณ stock โดยนับเฉพาะ isclose = 0 (รอชำระ), 1 (ขายแล้ว), 9 (ปรับสต็อก)
  // ไม่นับ isclose = 2 (ยกเลิก)
  String query = "select barcode,sum(qty) as qty from $clickHouseDatabaseName.ordertempcalcqty where shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and isclose in (0,1,9) group by barcode order by barcode";
  await api.clickHouseSelect(query).then((value) {
    for (var item in productList) {
      item.stockqty = 0;
    }
    ResponseDataModel responseData = ResponseDataModel.fromJson(value);
    for (var item in responseData.data) {
      int index = findProductByBarcode(item["barcode"]);
      if (index != -1) {
        productList[index].stockqty = double.parse(item["qty"].toString());
      }
    }
  });
}

Future<double> getBalanceQtyAllFromServerByItem(String barcode) async {
  double qty = 0;
  // คำนวณ stock โดยนับเฉพาะ isclose = 0 (รอชำระ), 1 (ขายแล้ว), 9 (ปรับสต็อก)
  // ไม่นับ isclose = 2 (ยกเลิก)
  String query = "select barcode,sum(qty) as qty from $clickHouseDatabaseName.ordertempcalcqty where shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and barcode='$barcode' and isclose in (0,1,9) group by barcode order by barcode";
  await api.clickHouseSelect(query).then((value) {
    ResponseDataModel responseData = ResponseDataModel.fromJson(value);

    for (var item in responseData.data) {
      qty = double.parse(item["qty"].toString());
    }
  });
  return qty;
}

TransactionModel convertToTransactionModel(TransactionObjModel transObj) {
  return TransactionModel(
    cashiercode: transObj.cashiercode,
    custcode: transObj.custcode,

    // แปลง JSON string กลับเป็น List<TransNameInfoModel>
    custnames: (jsonDecode(transObj.custnamesJson) as List).map((item) => TransNameInfoModel.fromJson(item)).toList(),

    // แปลง JSON string กลับเป็น PosConfigBranchModel
    branch: PosConfigBranchModel.fromJson(jsonDecode(transObj.branchJson)),

    // แปลง JSON string กลับเป็น List<TransDetailModel>
    details: (jsonDecode(transObj.detailsJson) as List).map((item) => TransDetailModel.fromJson(item)).toList(),

    description: transObj.description,
    discountword: transObj.discountword,
    docdatetime: transObj.docdatetime,
    docno: transObj.docno,
    docrefdate: transObj.docrefdate,
    docrefno: transObj.docrefno,
    docreftype: transObj.docreftype,
    doctype: transObj.doctype,
    guidref: transObj.guidref,
    inquirytype: transObj.inquirytype,
    iscancel: transObj.iscancel,
    ismanualamount: transObj.ismanualamount,
    ispos: transObj.ispos,
    posid: transObj.posid,
    membercode: transObj.membercode,
    salecode: transObj.salecode,
    salename: transObj.salename,
    status: transObj.status,
    taxdocdate: transObj.taxdocdate,
    taxdocno: transObj.taxdocno,
    totalaftervat: transObj.totalaftervat,
    totalamount: transObj.totalamount,
    totalbeforevat: transObj.totalbeforevat,
    totalcost: transObj.totalcost,
    totaldiscount: transObj.totaldiscount,
    totalexceptvat: transObj.totalexceptvat,
    totalvalue: transObj.totalvalue,
    totalvatvalue: transObj.totalvatvalue,
    transflag: transObj.transflag,
    vatrate: transObj.vatrate,
    vattype: transObj.vattype,

    // แปลง JSON string กลับเป็น TransPaymentDetailModel
    paymentdetail: TransPaymentDetailModel.fromJson(
      jsonDecode(transObj.paymentdetailJson),
    ),

    paymentdetailraw: transObj.paymentdetailraw,
    billtaxtype: transObj.billtaxtype,
    buffetcode: transObj.buffetcode,
    detaildiscountformula: transObj.detaildiscountformula,
    detailtotalamount: transObj.detailtotalamount,
    detailtotalamountbeforediscount: transObj.detailtotalamountbeforediscount,
    detailtotaldiscount: transObj.detailtotaldiscount,
    isvatregister: transObj.isvatregister,
    paycashchange: transObj.paycashchange,
    roundamount: transObj.roundamount,
    sumcheque: transObj.sumcheque,
    sumcoupon: transObj.sumcoupon,
    sumcreditcard: transObj.sumcreditcard,
    summoneytransfer: transObj.summoneytransfer,
    sumqrcode: transObj.sumqrcode,
    sumcredit: transObj.sumcredit,
    totalamountafterdiscount: transObj.totalamountafterdiscount,
    totaldiscountexceptvatamount: transObj.totaldiscountexceptvatamount,
    totaldiscountvatamount: transObj.totaldiscountvatamount,
    totalqty: transObj.totalqty,
    takeaway: transObj.takeaway,
    salechannelcode: transObj.salechannelcode,
    salechannelgp: transObj.salechannelgp,
    salechannelgptype: transObj.salechannelgptype,
    isdelivery: transObj.isdelivery,
    deliveryamount: transObj.deliveryamount,
  );
}

// void startSyncTransaction() {
//   if (syncTimer == null || !syncTimer!.isActive) {
//     // สร้าง Timer ที่จะรันทุกๆ 10 วินาที
//     syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
//       try {
//         // ดึงข้อมูลที่ยังไม่ได้ sync (issync == false) จาก ObjectBox
//         final box = global.objectBoxStore.box<TransactionObjModel>();
//         final unsyncedTransactions = box.query(TransactionObjModel_.issync.equals(false)).build().find();

//         // วนลูปข้อมูลแต่ละรายการเพื่อลองทำการ sync
//         for (var transObj in unsyncedTransactions) {
//           try {
//             TransactionModel trans = convertToTransactionModel(transObj);

//             // ทำการบันทึกข้อมูลไปยัง API
//             final apiResult = await api.saveTransaction(trans);

//             if (apiResult.success) {
//               transObj.issync = true;
//               box.put(transObj);
//             } else {
//               if (kDebugMode) {
//                 print(apiResult.message);
//               }
//             }
//           } catch (e, s) {
//             if (kDebugMode) {
//               print(e);
//             }
//             global.sendErrorToDevTeam("saveTransaction error : $e");
//           }
//         }
//       } catch (e) {
//         if (kDebugMode) {
//           print("Error syncing transactions: $e");
//         }
//       }
//     });
//   }
// }

Future<io.File?> getImageFile(String docno) async {
  try {
    // สร้าง path ไปยังที่จัดเก็บรูป
    final dateDirectory = await global.createPath(global.billImagePath);
    final path = '${dateDirectory.path}/$docno.png'; // รูปที่ถูกบันทึกไว้ชื่อ docno.png

    // ตรวจสอบว่ารูปมีอยู่จริงหรือไม่
    final file = io.File(path);
    if (await file.exists()) {
      return file; // คืนค่าไฟล์รูปกลับไป
    } else {
      Logger.d('Image not found for docno: $docno');
      return null; // คืนค่า null หากไม่พบไฟล์
    }
  } catch (e, s) {
    if (kDebugMode) {
      print('Error fetching image file: $e');
      print(s);
    }
    return null;
  }
}

/// ยอดคงเหลือสินค้า (ตาม Barcode)
Future<double> getBalanceQtyFromServer({required String barcode, required int isclose}) async {
  String isCloseQuery = (isclose == -1) ? "" : " and isclose=$isclose";
  String query = "select barcode,sum(qty) as qty from $clickHouseDatabaseName.ordertempcalcqty where shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and barcode='$barcode' $isCloseQuery group by barcode";
  await api.clickHouseSelect(query).then((value) {
    ResponseDataModel responseData = ResponseDataModel.fromJson(value);
    for (var item in responseData.data) {
      int index = findProductByBarcode(item["barcode"]);
      if (index != -1) {
        return item["qty"];
      }
    }
  });
  return 0;
}

/// รายการสินค้าหยุดขายชั่วคราว
Future<void> getProductCancelFromServer() async {
  String query = "select barcode from $clickHouseDatabaseName.ordertempbarcodecancel where shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}'";
  await api.clickHouseSelect(query).then((value) {
    for (var index = 0; index < productList.length; index++) {
      productList[index].issell = true;
    }
    ResponseDataModel responseData = ResponseDataModel.fromJson(value);
    for (var item in responseData.data) {
      int index = findProductByBarcode(item["barcode"]);
      if (index != -1) {
        productList[index].issell = false;
      }
    }
  });
}

Future<bool> getProductCancelFromServerByItem(String barcode) async {
  bool issell = true;
  String query = "select barcode from $clickHouseDatabaseName.ordertempbarcodecancel where shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and barcode='${barcode}'";
  await api.clickHouseSelect(query).then((value) {
    ResponseDataModel responseData = ResponseDataModel.fromJson(value);
    for (var item in responseData.data) {
      if (item["barcode"] == barcode) {
        issell = false;
      }
    }
  });
  return issell;
}

String getPosLogoPathName() {
  return "${applicationDocumentsDirectory.path}/poslogo.png";
}

double calcDiscount({required double amount, required String discountWord, double qty = 1}) {
  double result = 0;
  if (discountWord.isNotEmpty) {
    List<String> formula = discountWord.split(",");
    for (int i = 0; i < formula.length; i++) {
      if (formula[i].contains("%")) {
        result = result + (amount * (double.parse(formula[i].replaceAll("%", "")) / 100));
      } else {
        result = result + double.parse(formula[i]);
        result = result * qty;
      }
    }
  }
  return result;
}

double roundDouble(double value, int places) {
  num mod = pow(10.0, places);
  return ((value * mod).round().toDouble() / mod);
}

double roundDoubleDown(double value, int precision) {
  final divideBy = pow(10, precision);
  return ((value * divideBy).floorToDouble() / divideBy);
}

double roundMoneyForPay(double value) {
  double result = value;
  if (payTotalMoneyRoundStep.isEmpty) {
    // ถ้าเป็นค่าว่าง ให้ปัดจำนวนเต็มอัตโนมัติ
    result = roundDouble(value, 0);
  } else {
    value = roundDouble(value, 2);
    double calcRound = roundDouble(value - value.floorToDouble(), 2);
    for (int index = 0; index < payTotalMoneyRoundStep.length; index++) {
      if (calcRound >= payTotalMoneyRoundStep[index].begin && calcRound <= payTotalMoneyRoundStep[index].end) {
        result = roundDoubleDown(value, 0) + payTotalMoneyRoundStep[index].value;
        break;
      }
    }
  }
  return result;
}

Future<io.Directory> createPath(String mainPath) async {
  final directory = await getApplicationDocumentsDirectory();

  // Create a new directory for the main path
  final mainDirectory = io.Directory('${directory.path}/$mainPath');
  if (!await mainDirectory.exists()) {
    await mainDirectory.create();
  }

  return mainDirectory;
}

double findProductPrice({required List<ProductPriceFromServerModel> prices}) {
  double result = 0;
  for (int i = 0; i < prices.length; i++) {
    if (priceIndex == prices[i].keynumber) {
      result = prices[i].price;
      break;
    }
  }
  if (result == 0) {
    result = prices[0].price;
  }
  return result;
}

Future<void> lineNotify({required String token, required String message}) async {
  try {
    // show image
    var url = Uri.parse("https://notify-api.line.me/api/notify");
    var header = {
      "Authorization": "Bearer $token",
    };
    var body = {
      "message": message,
    };
    await http.post(url, headers: header, body: body);
  } catch (e, s) {
    Logger.e('Error occurred', error: e, stackTrace: s);
  }
}

Future<void> telegramNotify({
  required String botToken,
  required String chatId,
  required String message,
}) async {
  try {
    final url = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'chat_id': chatId,
        'text': message,
        'parse_mode': 'HTML', // รองรับ HTML formatting
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (!result['ok']) {
        throw Exception('Telegram API error: ${result['description']}');
      }
    } else {
      throw Exception('HTTP error: ${response.statusCode}');
    }
  } catch (e, s) {
    Logger.e('Telegram notification error', error: e, stackTrace: s);
  }
}

void removeCalcQty() {
  // ลบเฉพาะ order ปัจจุบันที่ยังไม่ได้ชำระเงิน (เมื่อยกเลิก order)
  // ไม่ลบ orders อื่นที่กำลังรอชำระหรือที่ชำระแล้ว
  if (orderId.isNotEmpty) {
    api.clickHouseExecute("alter table $clickHouseDatabaseName.ordertempcalcqty delete "
        "where shopid='${deviceConfig.shopId}' "
        "and branchid='${deviceConfig.branchId}' "
        "and orderid='$orderId' "
        "and isclose=0");
    Logger.i('Removed calcqty for cancelled order: $orderId', tag: 'StockManagement');
  } else {
    Logger.w('removeCalcQty called but orderId is empty!', tag: 'StockManagement');
  }
}

Future<void> registerDeviceToServer() async {
  // update สถานะ เครื่อง
  try {
    if (deviceConfig.shopId.isEmpty) {
      return;
    }
    // refresh token ล่าสุดเข้า ClickHouse เพื่อให้ bcorderkiosk (web) ใช้ token ที่ถูกต้อง
    api.refreshSessionTemplate();
    int isserver = deviceConfig.isServer ? 1 : 0;
    var value = await api.clickHouseSelect("select * from $clickHouseDatabaseName.orderdevice where shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and devicename='${deviceConfig.orderStationCode}'");
    ResponseDataModel result = ResponseDataModel.fromJson(value);
    if (result.data.isNotEmpty) {
      await api.clickHouseExecute("alter table $clickHouseDatabaseName.orderdevice UPDATE lasttime=now(),isserver=$isserver WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and devicename='${deviceConfig.orderStationCode}'");
    } else {
      // get ip address
      String ipAddress = "";
      try {
        for (var interface in await io.NetworkInterface.list()) {
          for (var addr in interface.addresses) {
            if (addr.address.contains(".")) {
              ipAddress = addr.address;
            }
          }
        }
      } catch (e, s) {
        Logger.e('Error occurred', error: e, stackTrace: s);
      }

      // ตำแหน่ง gps
      double latitude = 0;
      double longitude = 0;
      // try {
      //   var location = await Geolocator.getCurrentPosition();
      //   latitude = location.latitude;
      //   longitude = location.longitude;
      // } catch (e, s) {
      //   if (kDebugMode) {
      //     print(e);
      //     print(s);
      //   }
      // }
      final shopProfile = global.shopProfile;
      final branchNames = shopProfile?.orderstation.branch.names;

      String shopName = shopProfile?.name1 ?? "";

      String branchName = (branchNames != null && branchNames.isNotEmpty) ? branchNames.first.name : "";
      await api.clickHouseExecute(
          "insert into $clickHouseDatabaseName.orderdevice (shopname,shopid,branchid,branchname,ipaddress,devicename,lasttime,isserver,latitude,longitude) values ('$shopName', '${deviceConfig.shopId}', '${deviceConfig.branchId}', '$branchName', '$ipAddress', '${deviceConfig.orderStationCode}',now(), $isserver, $latitude, $longitude)");
    }
    // ลบออกถ้าไม่ติดต่อเกิน 30 วินาที
    await api.clickHouseExecute("alter table $clickHouseDatabaseName.orderdevice delete where lasttime < now()-30");
  } catch (e, s) {
    Logger.e('Error occurred', error: e, stackTrace: s);
  }
}

void sendErrorToDevTeam(String message) {
  if (telegramDevBotToken.isNotEmpty && telegramDevChatId.isNotEmpty) {
    telegramNotify(botToken: telegramDevBotToken, chatId: telegramDevChatId, message: "${deviceConfig.shopId} : $message");
  }
}

TotalCalculateModel calcProductAndOption(ProductProcessModel product) {
  TotalCalculateModel result = TotalCalculateModel();
  // double totalAmount = product.prices[global.findPriceIndex(product)].price * product.qty;
  double totalAmount = product.setprice * product.qty;

  double totalDiscount = 0;
  if (global.priceIndex == 1) {
    totalDiscount = calcDiscount(amount: totalAmount, discountWord: product.discountword, qty: product.qty);
  }
  for (int i = 0; i < product.options.length; i++) {
    for (int j = 0; j < product.options[i].choices.length; j++) {
      if (product.options[i].choices[j].selected) {
        double choiceAmount = product.options[i].choices[j].priceValue * product.qty;
        double choiceDiscount = calcDiscount(amount: choiceAmount, discountWord: product.options[i].choices[j].discountWord);
        totalAmount += choiceAmount;
        totalDiscount += choiceDiscount;
      }
    }
  }
  result.qty = product.qty;
  result.totalAmount = totalAmount;
  result.totalDiscount = totalDiscount;
  result.totalAfterDiscount = totalAmount - totalDiscount;
  return result;
}

double calcProductOptionAmount({required List<ProductProcessOptionChoiceModel> choices, required double qty}) {
  double result = 0;
  for (int i = 0; i < choices.length; i++) {
    if (choices[i].selected) {
      double choiceAmount = choices[i].priceValue * qty;
      double choiceDiscount = calcDiscount(amount: choiceAmount, discountWord: choices[i].discountWord);
      result += choiceAmount - choiceDiscount;
    }
  }
  return result;
}

Future<void> textToSpeech(String text) async {
  if (text.isNotEmpty) {
    bool foundLanguage = false;
    /*FlutterTts tts = FlutterTts();
    switch (languageForCustomer) {
      case "th":
        tts.setLanguage("th-TH");
        foundLanguage = true;
        break;
      case "en":
        tts.setLanguage("en-US");
        foundLanguage = true;
        break;
      case "lo":
        tts.setLanguage("th-TH");
        foundLanguage = false;
        break;
      case "cn":
        tts.setLanguage("zh-CN");
        foundLanguage = true;
        break;
      case "jp":
        tts.setLanguage("ja-JP");
        foundLanguage = true;
        break;
      case "kr":
        tts.setLanguage("ko-KR");
        foundLanguage = true;
        break;
      default:
        tts.setLanguage("th-TH");
        foundLanguage = true;
        break;
    }
    if (foundLanguage) {
      tts.speak(text);
    }*/
  }
}

String generateRandomString(int length) {
  const availableChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();

  return List.generate(length, (index) => availableChars[random.nextInt(availableChars.length)]).join();
}

Future<Uint8List?> loadImageFromUrl(String imageUrl) async {
  try {
    // Fetch the image bytes from the URL
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      // If the request is successful, convert the response body to Uint8List
      return response.bodyBytes;
    } else {
      // If the request is not successful, return null
      Logger.d("Failed to load image: ${response.statusCode}");
      return null;
    }
  } catch (e, s) {
    Logger.e('Error occurred', error: e, stackTrace: s);
    // If an error occurs during the request, return null
    return null;
  }
}

int findPriceIndex(ProductProcessModel product) {
  int result = 0;
  for (int i = 0; i < product.prices.length; i++) {
    if (product.prices[i].keynumber == priceIndex) {
      result = i;
      break;
    }
  }
  return result;
}

Future<void> updateCookCancel({required String orderId, required String orderGuid, required Function reload}) async {
  String message = "";
  if (orderGuid.isNotEmpty) {
    // get qty
    int iscookcancel = 0;
    {
      String query = "SELECT iscookcancel FROM ${orderTempTableName()} WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderguid='$orderGuid'";
      var result = await api.clickHouseSelect(query);
      ResponseDataModel responseData = ResponseDataModel.fromJson(result);
      if (responseData.data.isNotEmpty) {
        iscookcancel = int.tryParse(responseData.data[0]['iscookcancel'].toString()) ?? 0;
      }
    }
    if (iscookcancel == 0) {
      iscookcancel = 1;
    } else {
      iscookcancel = 0;
    }
    {
      String query = "alter table ${orderTempTableName()} UPDATE iscookcancel=$iscookcancel WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderguid='$orderGuid'";
      Logger.d(query);
      await api.clickHouseExecute(query);
      await checkKitchenSuccess(orderId: orderId);

      message = "Success : $orderGuid";
      reload();
    }
    Get.snackbar("DeDe Order Kiosk", message,
        duration: const Duration(seconds: 1),
        icon: const Icon(
          Icons.qr_code,
          color: Colors.black,
          size: 48,
        ),
        animationDuration: const Duration(milliseconds: 100),
        snackPosition: SnackPosition.BOTTOM);
  }
}

Future<void> checkKitchenSuccess({
  required String orderId,
}) async {
  int kitchenSuccess = 0;
  double sumQty = 0;
  double sumIsCooked = 0;
  String query = "SELECT qty,iscooked,iscookcancel FROM ${orderTempTableName()} WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderid='$orderId'";
  var result = await api.clickHouseSelect(query);
  ResponseDataModel responseData = ResponseDataModel.fromJson(result);
  if (responseData.data.isNotEmpty) {
    for (var item in responseData.data) {
      double qty = double.tryParse(item['qty'].toString()) ?? 0.0;
      if (double.tryParse(item['iscookcancel'].toString()) == 1) {
        sumQty += qty;
        sumIsCooked += qty;
      } else {
        sumQty += qty;
        sumIsCooked += double.tryParse(item['iscooked'].toString()) ?? 0.0;
      }
    }
    if (sumIsCooked >= sumQty) {
      kitchenSuccess = 1;
    }
  }
  String queryUpdate = "alter table ${orderTempDocTableName()} UPDATE kitchensuccess=$kitchenSuccess WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderid='$orderId'";
  await api.clickHouseExecute(queryUpdate);
}

Future<void> updateCookedQty({required String orderId, required String orderDetailGuid, required Function reload}) async {
  String message = "";
  if (orderDetailGuid.isNotEmpty) {
    // get qty
    double iscooked = 0;
    double qty = 0;
    {
      String query = "SELECT qty,iscooked FROM ${orderTempTableName()} WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderguid='$orderDetailGuid'";
      var result = await api.clickHouseSelect(query);
      ResponseDataModel responseData = ResponseDataModel.fromJson(result);
      if (responseData.data.isNotEmpty) {
        qty = double.tryParse(responseData.data[0]['qty'].toString()) ?? 0.0;
        iscooked = double.tryParse(responseData.data[0]['iscooked'].toString()) ?? 0.0;
      }
    }
    if (iscooked < qty) {
      {
        // update detail
        String query = "alter table ${orderTempTableName()} UPDATE iscooked=iscooked+1 WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderguid='$orderDetailGuid'";
        Logger.d(query);
        await api.clickHouseExecute(query);
      }
      await Future.delayed(const Duration(milliseconds: 500));
      await checkKitchenSuccess(orderId: orderId);
      message = "Success : $orderDetailGuid";
      reload();
    }
    Get.snackbar("DeDe Order Kiosk", message,
        duration: const Duration(seconds: 1),
        icon: const Icon(
          Icons.qr_code,
          color: Colors.black,
          size: 48,
        ),
        animationDuration: const Duration(milliseconds: 100),
        snackPosition: SnackPosition.BOTTOM);
  }
}

Future<void> checkServedSuccess({
  required String orderId,
}) async {
  // Wait a short delay to allow ClickHouse mutation to be applied
  await Future.delayed(const Duration(milliseconds: 300));

  int servedSuccess = 0;
  double sumQty = 0;
  double sumIsServed = 0;
  String query = "SELECT qty,isserved,isservedcancel FROM ${orderTempTableName()} WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderid='$orderId'";
  var result = await api.clickHouseSelect(query);
  ResponseDataModel responseData = ResponseDataModel.fromJson(result);
  if (responseData.data.isNotEmpty) {
    for (var item in responseData.data) {
      double qty = double.tryParse(item['qty'].toString()) ?? 0.0;
      if (double.tryParse(item['isservedcancel'].toString()) == 1) {
        sumQty += qty;
        sumIsServed += qty;
      } else {
        sumQty += qty;
        sumIsServed += double.tryParse(item['isserved'].toString()) ?? 0.0;
      }
    }
    if (sumIsServed >= sumQty) {
      servedSuccess = 1;
    }
  }
  String updateKitchen = (servedSuccess == 0) ? "" : ",kitchensuccess=1";
  String queryUpdate = "alter table ${orderTempDocTableName()} UPDATE servedsuccess=$servedSuccess $updateKitchen WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderid='$orderId'";
  await api.clickHouseExecute(queryUpdate);
  if (servedSuccess == 1) {
    String queryUpdateKitchen = "alter table ${orderTempTableName()} UPDATE iscooked=qty WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderid='$orderId'";
    await api.clickHouseExecute(queryUpdateKitchen);
  }
}

/// Check served success using calculated value instead of reading from DB
/// This avoids timing issues with ClickHouse mutations
Future<void> checkServedSuccessWithValue({
  required String orderId,
  required String updatedGuid,
  required double newIsserved,
}) async {
  int servedSuccess = 0;
  double sumQty = 0;
  double sumIsServed = 0;

  // Read current values from DB (these are the old values before mutation)
  String query = "SELECT orderguid,qty,isserved,isservedcancel FROM ${orderTempTableName()} WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderid='$orderId'";
  var result = await api.clickHouseSelect(query);
  ResponseDataModel responseData = ResponseDataModel.fromJson(result);
  if (responseData.data.isNotEmpty) {
    for (var item in responseData.data) {
      double qty = double.tryParse(item['qty'].toString()) ?? 0.0;
      String itemGuid = item['orderguid'].toString();

      if (double.tryParse(item['isservedcancel'].toString()) == 1) {
        sumQty += qty;
        sumIsServed += qty;
      } else {
        sumQty += qty;
        // Use calculated value for the updated item, old value for others
        if (itemGuid == updatedGuid) {
          sumIsServed += newIsserved;
        } else {
          sumIsServed += double.tryParse(item['isserved'].toString()) ?? 0.0;
        }
      }
    }
    if (sumIsServed >= sumQty) {
      servedSuccess = 1;
    }
  }

  String updateKitchen = (servedSuccess == 0) ? "" : ",kitchensuccess=1";
  String queryUpdate = "alter table ${orderTempDocTableName()} UPDATE servedsuccess=$servedSuccess $updateKitchen WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderid='$orderId'";
  await api.clickHouseExecute(queryUpdate);
  if (servedSuccess == 1) {
    String queryUpdateKitchen = "alter table ${orderTempTableName()} UPDATE iscooked=qty WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderid='$orderId'";
    await api.clickHouseExecute(queryUpdateKitchen);
  }
}

Future<void> updateServedQty({required String orderDetailGuid, required Function reload}) async {
  String message = "";
  if (orderDetailGuid.isNotEmpty) {
    // get qty and current isserved
    double isserved = 0;
    double qty = 0;
    String orderId = "";
    {
      String query = "SELECT qty,isserved,orderid FROM ${orderTempTableName()} WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderguid='$orderDetailGuid'";
      var result = await api.clickHouseSelect(query);
      ResponseDataModel responseData = ResponseDataModel.fromJson(result);
      if (responseData.data.isNotEmpty) {
        qty = double.tryParse(responseData.data[0]['qty'].toString()) ?? 0.0;
        isserved = double.tryParse(responseData.data[0]['isserved'].toString()) ?? 0.0;
        orderId = responseData.data[0]['orderid'].toString();
      }
    }
    if (isserved < qty && orderId.isNotEmpty) {
      // Calculate the new isserved value
      double newIsserved = isserved + 1;

      {
        // update detail
        String query = "alter table ${orderTempTableName()} UPDATE isserved=isserved+1 WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderguid='$orderDetailGuid'";
        Logger.d(query);
        await api.clickHouseExecute(query);
      }

      // Check served success using calculated value instead of reading from DB
      await checkServedSuccessWithValue(orderId: orderId, updatedGuid: orderDetailGuid, newIsserved: newIsserved);

      message = "Success : $orderDetailGuid";
      reload();
    }
    Get.snackbar("DeDe Order Kiosk", message,
        duration: const Duration(seconds: 1),
        icon: const Icon(
          Icons.qr_code,
          color: Colors.black,
          size: 48,
        ),
        animationDuration: const Duration(milliseconds: 100),
        snackPosition: SnackPosition.BOTTOM);
  }
}

Future<void> updateServedCancel({required String orderId, required String orderGuid, required Function reload}) async {
  String message = "";
  if (orderGuid.isNotEmpty) {
    // get qty
    int isservedcancel = 0;
    {
      String query = "SELECT isservedcancel FROM ${orderTempTableName()} WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderguid='$orderGuid'";
      var result = await api.clickHouseSelect(query);
      ResponseDataModel responseData = ResponseDataModel.fromJson(result);
      if (responseData.data.isNotEmpty) {
        isservedcancel = int.tryParse(responseData.data[0]['isservedcancel'].toString()) ?? 0;
      }
    }
    if (isservedcancel == 0) {
      isservedcancel = 1;
    } else {
      isservedcancel = 0;
    }
    {
      String query = "alter table ${orderTempTableName()} UPDATE isservedcancel=$isservedcancel WHERE shopid='${deviceConfig.shopId}' and branchid='${deviceConfig.branchId}' and orderguid='$orderGuid'";
      Logger.d(query);
      await api.clickHouseExecute(query);
      await checkServedSuccess(orderId: orderId);

      message = "Success : $orderGuid";
      reload();
    }
    Get.snackbar("DeDe Order Kiosk", message,
        duration: const Duration(seconds: 1),
        icon: const Icon(
          Icons.qr_code,
          color: Colors.black,
          size: 48,
        ),
        animationDuration: const Duration(milliseconds: 100),
        snackPosition: SnackPosition.BOTTOM);
  }
}

Future<void> getListOfAvailableDrivers() async {
  try {
    final List<dynamic> drivers = await platform.invokeMethod('listAvailableDrivers');

    driversAvailableList = drivers;
    edcProductName = "";
    if (driversAvailableList.isNotEmpty) {
      connectToDevice(driversAvailableList[0]["productName"]);
    }
    Logger.d("listAvailableDrivers of devices: $drivers");
  } on PlatformException catch (e) {
    edcProductName = "";
    print("Failed to get drivers: ${e.message}");
  }
}

Future<String> selectOrderTagNumberOrTableNumber({required BuildContext context}) async {
  global.orderTagNumbers.removeWhere((element) => element.isEmpty);
  if (global.orderTagNumbers.isEmpty) {
    return "";
  }
  var result = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        late bool visible;
        final theme = Theme.of(context);

        return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            contentPadding: const EdgeInsets.all(24),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: theme.scaffoldBackgroundColor,
            title: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: const Color(0xFFB85C38), // สีอิฐแดง
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    global.language("select_label_number"),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB85C38), // สีอิฐแดง
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, "");
                  },
                  icon: const Icon(Icons.close),
                  label: Text(global.language("cancel")),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            content: VisibilityDetector(
                onVisibilityChanged: (VisibilityInfo info) {
                  visible = info.visibleFraction > 0;
                },
                key: const Key('visible-detector-key'),
                child: BarcodeKeyboardListener(
                    bufferDuration: const Duration(milliseconds: 200),
                    onBarcodeScanned: (barcode) async {
                      if (!visible) return;
                      bool found = false;
                      for (var i = 0; i < global.orderTagNumbers.length; i++) {
                        if (global.orderTagNumbers[i] == barcode) {
                          found = true;
                          break;
                        }
                      }
                      if (found) {
                        Navigator.pop(context, barcode);
                      }
                    },
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EBE0), // สีอิฐบ้านเชียงอ่อน
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD4A373).withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  color: const Color(0xFFB85C38), // สีอิฐแดง
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    global.language("take_label"),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: const Color(0xFFB85C38), // สีอิฐแดง
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            global.language("select_number_or_scan"),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.start,
                                children: [
                                  for (var i = 0; i < global.orderTagNumbers.length; i++)
                                    Material(
                                      elevation: 2,
                                      borderRadius: BorderRadius.circular(6),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(6),
                                        onTap: () {
                                          Navigator.pop(context, global.orderTagNumbers[i]);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFB85C38), // สีอิฐแดง
                                                const Color(0xFF8B4513), // สีน้ำตาลเข้ม
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFB85C38).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            global.orderTagNumbers[i],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))));
      });
  return result.toString();
}

void backToHome(BuildContext context) {
  // Clear member data when going back to home
  isMember = false;
  memberCode = "";
  memberPointsCode = "";
  memberPriceLevel = 1;
  memberGuidFixed = "";
  memberPointBalance = 0;
  memberName = "";
  memberPicture = "";
  memberEmail = "";
  memberPinCode = "";
  priceIndex = 1; // Reset to normal price
  lineDestination = "";
  custNames = [];

  // Clear point transaction data
  usePoint = 0;
  getPoint = 0;
  pointDiscountAmount = 0;
  pointAmount = 0;
  currentPointBalance = 0;

  // Clear order temp data
  objectBoxStore.box<OrderTempObjectBoxModel>().removeAll();

  if (global.deviceConfig.machineCondition == 0) {
    Navigator.pushNamedAndRemoveUntil(context, '/order_select', (Route<dynamic> route) => false);
  } else {
    Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
  }
}

String orderTempTableName() {
  return "$clickHouseDatabaseName.${(deviceConfig.systemCondition != 1) ? "ordertemp" : "ordertemppaylater"}";
}

String orderTempDocTableName() {
  return "$clickHouseDatabaseName.${(deviceConfig.systemCondition != 1) ? "ordertempdoc" : "ordertempdocpaylater"}";
}
