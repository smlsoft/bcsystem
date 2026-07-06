import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dedeorder/global_model.dart';
import 'package:dedeorder/model/buffet_mode_model.dart';
import 'package:dedeorder/model/category_model.dart';
import 'package:dedeorder/model/global_model.dart';
import 'package:dedeorder/model/product_model.dart';
import 'package:dedeorder/model/table_model.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:dedeorder/utility/api.dart' as api;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';

List<String> countryNames = ["English", "Thai", "Laos", "Chinese", "Japan", "Korea"];
List<String> countryCodes = ["en", "th", "lo", "zh-cn", "ja", "ko"];

List<StaffCategoryModel> orderPageCloneCategoryLists = [];
List<ProductProcessModel> orderPageOrderSelected = [];

/// รหัสพนักงานสั่ง Order
String staffCode = "";
String staffName = "";
late List<CameraDescription> cameras;
List<LanguageSystemModel> languageSystemData = [];
List<LanguageSystemCodeModel> languageSystemCode = [];
final moneyFormat = NumberFormat("##,##0.##");
final moneyFormatAndDot = NumberFormat("##,##0.00");
List<StaffCategoryModel> categoryLists = [];
List<ProductProcessModel> productLists = [];
List<BuffetModeObjectBoxStruct> buffetModeLists = [];
List<ProductBarcodeStatusObjectBoxStruct> productBarcodeStatusLists = [];
List<PosSaleChannelModel> posSaleChannelLists = [];
String machineId = "";
String machineName = "";
String posTerminalDeviceName = "";
String posTerminalDeviceIpAddress = "";
int posTerminalDevicePort = 4040;
bool posTerminalDeviceConnected = false;
String userLanguage = "th";
String phoneNumber = "";
String selectTableNumber = "";
String selectTableMainNumber = "";
String appVersion = "1.0.7";

TableProcessObjectBoxStruct selectTable = TableProcessObjectBoxStruct(
  id: 0,
  guidfixed: "",
  number: "",
  number_main: "",
  names: "",
  zone: "",
  table_status: 0,
  order_count: 0,
  order_cancel_count: 0,
  order_served_count: 0,
  amount: 0.0,
  order_success: false,
  qr_code: "",
  table_open_datetime: DateTime.now(),
  man_count: 0,
  woman_count: 0,
  child_count: 0,
  table_al_la_crate_mode: false,
  buffet_code: "",
  customer_code_or_telephone: "",
  customer_name: "",
  customer_address: "",
  delivery_code: "",
  delivery_ticket_number: "",
  delivery_number: "",
  remark: "",
  open_by_staff_code: "",
  make_food_immediately: false,
  is_delivery: false,
  delivery_cook_success: false,
  delivery_cook_success_datetime: DateTime.now(),
  delivery_send_success: false,
  delivery_send_success_datetime: DateTime.now(),
  delivery_status: 0,
  table_child_count: 0,
  detail_discount_formula: "",
  customer_nationality_code: "",
);
String currentLanguage = "th";
PrinterLocalStrongDataModel printerConnectData = PrinterLocalStrongDataModel();
bool printToLocalPrinter = false;
bool printerConnected = false;
PosInformationModel posInformation = PosInformationModel(
  shop_id: "",
  shop_name: "",
);
String payQrCode = ""; //KPS004KB000001927650
int payQrType = 0; //KPS004KB
String qrproviderCode = "";
String qrproviderName = "";
String payQrCodeName = "";
String smlQrCodeName = "";
String smlQrCode = "";
// 0=ชำระที่ Cashier,1=ขำระทันทีด้วยเงินสด,2=ชำระทันทีด้วย Qr Code,3 sml qr
List<bool> payTypeEnableList = [true, false, true, true];
//String payQrCode = "0898509343";
//String payQrCodeName = "ศิริลักษณ์ เวียงแสง";
int orderStyle = 0;
double orderFontSize = 14;
bool orderShowImage = true;
List<ProductTypeModel> productTypeLists = [];
List<CallerModel> callerLists = [];
bool callerAlert = true;
List<String> callerTextToSpeechList = [];
DateTime callerTextToSpeechLastTime = DateTime.now();
bool speechActive = false;
late FlutterTts flutterTts;

enum PrintColumnAlign { left, right, center }

enum PrinterTypeEnum { thermal, dot, laser, inkjet }

enum PrinterConnectEnum { ip, bluetooth, windows }

enum TableManagerEnum { openTable, updateTable, closeTable, closeTableCancel, moveTable, moveTableTarget, mergeTable, mergeTableTarget, informationTable, splitTable, selectTable, productUpdateStatus, productUpdateQty, checker, caller, payScreenType }

Future<void> getDevice() async {
  try {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    var getPosTerminalDeviceName = sharedPreferences.getString('posServerName') ?? "";
    if (getPosTerminalDeviceName.isNotEmpty) {
      posTerminalDeviceName = getPosTerminalDeviceName;
    }
    var getPosTerminalDeviceIpAddress = sharedPreferences.getString('posServerIpAddress') ?? "";
    if (getPosTerminalDeviceIpAddress.isNotEmpty) {
      posTerminalDeviceIpAddress = getPosTerminalDeviceIpAddress;
    }
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      machineName = androidInfo.board;
      machineId = "$machineName-${androidInfo.id}".toLowerCase().replaceAll(".", "");
    } else if (Platform.isIOS) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      machineName = iosInfo.name;
      machineId = "$machineName-${iosInfo.identifierForVendor ?? ""}".toLowerCase().replaceAll(".", "");
    } else {
      machineName = "Unknown";
      machineId = "";
    }
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    sendErrorToDevTeam("getDevice():$e\n$s");
  }
  if (kDebugMode) {
    print("Machine Name: $machineName");
    print("POS Terminal Device Name: $posTerminalDeviceName");
    print("POS Terminal Device IP Address: $posTerminalDeviceIpAddress");
  }
}

void languageSelect(String languageCode) {
  languageSystemData = [];
  for (int i = 0; i < languageSystemCode.length; i++) {
    for (int j = 0; j < languageSystemCode[i].langs.length; j++) {
      if (languageSystemCode[i].langs[j].code == userLanguage) {
        languageSystemData.add(LanguageSystemModel(code: languageSystemCode[i].code.trim(), text: languageSystemCode[i].langs[j].text.trim()));
      }
    }
  }
  languageSystemData.sort((a, b) {
    return a.code.compareTo(b.code);
  });
}

String language(String code) {
  code = code.trim().toLowerCase();
  int left = 0;
  int right = languageSystemData.length - 1;

  while (left <= right) {
    int mid = (left + right) ~/ 2;
    int compareResult = code.compareTo(languageSystemData[mid].code);

    if (compareResult == 0) {
      return languageSystemData[mid].text;
    } else if (compareResult < 0) {
      right = mid - 1;
    } else {
      left = mid + 1;
    }
  }

  return code;
}

Future<void> loadDataFromTerminal() async {
  if (posTerminalDeviceIpAddress.isNotEmpty) {
    List<StaffCategoryModel> category = [];
    List<String> barcode = [];
    List<ProductCategoryObjectBoxStruct> categoryData = await api.getCategoryFromTerminal();
    productBarcodeStatusLists = await api.getProductBarcodeStatusFromTerminal();
    categoryLists.clear();
    productLists.clear();
    buffetModeLists = await api.getBuffetModeFromTerminal();
    for (int categoryIndex = 0; categoryIndex < categoryData.length; categoryIndex++) {
      StaffCategoryModel newCategory = StaffCategoryModel();
      newCategory.guidfixed = categoryData[categoryIndex].guid_fixed;
      newCategory.parentguid = categoryData[categoryIndex].parent_guid_fixed;
      newCategory.imageuri = categoryData[categoryIndex].image_url;
      newCategory.names = (jsonDecode(categoryData[categoryIndex].names) as List<dynamic>).map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>)).toList();
      newCategory.products = [];
      newCategory.xorder = categoryData[categoryIndex].xorder;
      var xjson = await jsonDecode(categoryData[categoryIndex].codelist);
      List<ProductCategoryCodeObjectBoxStruct> codeList = [];
      for (int i = 0; i < xjson.length; i++) {
        List<LanguageNameModel> names = [];
        for (int j = 0; j < xjson[i]['names'].length; j++) {
          names.add(LanguageNameModel(code: xjson[i]['names'][j]['code'], name: xjson[i]['names'][j]['name']));
        }
        codeList.add(ProductCategoryCodeObjectBoxStruct(code: xjson[i]['barcode'], names: names));
      }
      for (int productIndex = 0; productIndex < codeList.length; productIndex++) {
        barcode.add(codeList[productIndex].code);
        ProductProcessModel product = ProductProcessModel(
          type: 0,
          names: codeList[productIndex].names,
          code: codeList[productIndex].code,
          barcode: codeList[productIndex].code,
          price: 0.0,
          imageuri: "",
          unitcode: "",
          unitname: "",
          qty: 0,
          options: [],
          isAlacarte: true,
          ordertypes: [],
          orderguid: "",
          sumOrderQty: 0,
          takeAway: false,
          totalAmount: 0,
          remark: "",
          refcategoryguid: categoryData[categoryIndex].guid_fixed,
        );
        newCategory.products.add(product);
        //
        bool productFound = false;
        for (int i = 0; i < productLists.length; i++) {
          if (productLists[i].barcode == product.barcode) {
            productFound = true;
            break;
          }
        }
        if (productFound == false) {
          productLists.add(product);
        }
      }
      // ค้นหาหมวดสินค้าลูก
      for (int index = 0; index < categoryData.length; index++) {
        if (categoryData[index].parent_guid_fixed == newCategory.guidfixed) {
          ProductProcessModel product = ProductProcessModel(
            barcode: "",
            names: (await jsonDecode(categoryData[index].names) as List<dynamic>).map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>)).toList(),
            type: 1,
            imageuri: "",
            unitcode: "",
            unitname: "",
            refcategoryguid: categoryData[index].guid_fixed,
            qty: 0,
            isAlacarte: true,
            ordertypes: [],
            options: [],
            orderguid: "",
            remark: "",
            code: "",
            price: 0.0,
            sumOrderQty: 0,
            takeAway: false,
            totalAmount: 0,
          );
          newCategory.products.add(product);
        }
      }
      category.add(newCategory);
    }
    category.sort((a, b) {
      return a.xorder.compareTo(b.xorder);
    });
    for (int i = 0; i < category.length; i++) {
      if (category[i].parentguid.isEmpty) {
        categoryLists.add(category[i]);
      }
    }
    productLists.sort((a, b) {
      return a.code.compareTo(b.barcode);
    });

    List<ProductBarcodeObjectBoxStruct> getProductAll = await api.getProductByBarcodeFromTerminal();
    //
    for (int i = 0; i < productLists.length; i++) {
      int index = -1;
      for (int j = 0; j < getProductAll.length; j++) {
        if (productLists[i].barcode == getProductAll[j].barcode) {
          index = j;
          break;
        }
      }
      if (index != -1) {
        productLists[i].unitcode = getProductAll[index].unit_code;
        productLists[i].unitname = getProductAll[index].unit_names;
        productLists[i].imageuri = getProductAll[index].images_url;
        productLists[i].isAlacarte = getProductAll[index].isalacarte;
        productLists[i].price = getProductPrice(getProductAll[index].prices, 1);
        productLists[i].ordertypes = [];
        productLists[i].sumOrderQty = getProductAll[index].sum_order_qty;
        if (getProductAll[index].ordertypes.isNotEmpty) {
          //String xordertype = getProduct[i].ordertypes;
          List<dynamic> jsonOrderType = await jsonDecode(getProductAll[index].ordertypes);
          /*List<ProductOrderTypeFromServerModel> orderTypes =
            (jsonDecode(getProduct[i].ordertypes) as List)
                .map((e) => ProductOrderTypeFromServerModel.fromJson(e))
                .toList();*/
          productLists[i].ordertypes = jsonOrderType.map((e) => ProductOrderTypeFromServerModel.fromJson(e)).toList();
        }
        productLists[i].options = [];
        List<ProductProcessOptionModel> options = [];
        var optionJson = await jsonDecode(getProductAll[index].options_json);
        options.addAll(optionJson == null ? [] : (optionJson as List).map((e) => ProductProcessOptionModel.fromJson(e)).toList());
        for (var option in options) {
          for (var choice in option.choices) {
            choice.selected = false;
            choice.priceValue = double.tryParse(choice.price) ?? 0.0;
          }
        }
        productLists[i].options = options;
      } else {
        if (kDebugMode) {
          print("Product not found: ${getProductAll[i].barcode}");
        }
      }
    }
    List<String> removeProduct = [];
    for (int i = 0; i < productLists.length; i++) {
      int index = (getProductAll.isEmpty) ? -1 : getProductAll.indexWhere((element) => element.barcode == productLists[i].barcode);
      if (index == -1) {
        removeProduct.add(productLists[i].barcode);
      }
    }
    for (int i = 0; i < removeProduct.length; i++) {
      productLists.removeWhere((element) => element.barcode == removeProduct[i]);
    }

    for (int index = 0; index < categoryData.length; index++) {
      List<String> removeProduct = [];
      for (int codeIndex = 0; codeIndex < category[index].products.length; codeIndex++) {
        int productIndex = findProductByBarcode(category[index].products[codeIndex].barcode);
        if (productIndex != -1) {
          category[index].products[codeIndex].price = productLists[productIndex].price;
          category[index].products[codeIndex].unitname = productLists[productIndex].unitname;
        } else {
          removeProduct.add(category[index].products[codeIndex].barcode);
        }
      }
      for (int i = 0; i < removeProduct.length; i++) {
        category[index].products.removeWhere((element) => element.barcode == removeProduct[i]);
        productLists.removeWhere((element) => element.barcode == removeProduct[i]);
      }
    }
  }
}

int findProductByBarcode(String barcode) {
  int index = -1;
  for (int i = 0; i < productLists.length; i++) {
    if (productLists[i].barcode == barcode) {
      return i;
    }
  }
  return index;
}

int findBuffetModeIndex(String code) {
  for (var item in buffetModeLists) {
    if (item.code == code) {
      return buffetModeLists.indexOf(item);
    }
  }
  return -1;
}

/// ตรวจสอบการเชื่อมต่อกับ POS Terminal และโหลดข้อมูลสถานะสินค้า
Future<void> checkConnectToPosTerminalAndLoadData() async {
  try {
    posTerminalDeviceConnected = await api.getConnectTerminal();
    if (posTerminalDeviceConnected) {
      productBarcodeStatusLists = await api.getProductBarcodeStatusFromTerminal();
      await api.getInformationFromPosTerminal();
    }
  } catch (e, s) {
    posTerminalDeviceConnected = false;
    if (kDebugMode) {
      print(e);
    }
    sendErrorToDevTeam("checkConnectToPosTerminalAndLoadData():$e\n$s");
  }
}

List<LanguageNameModel> languageJsonDecode(String jsonNames) {
  try {
    return jsonDecode(jsonNames).map<LanguageNameModel>((item) {
      return LanguageNameModel.fromJson(item);
    }).toList();
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    sendErrorToDevTeam("languageJsonDecode():$jsonNames\n$e\n$s");
    return [];
  }
}

String getNameFromJsonLanguage(String jsonNames, String languageCode) {
  List<LanguageNameModel> names = languageJsonDecode(jsonNames);
  for (var item in names) {
    if (item.code == languageCode) {
      return item.name;
    }
  }
  return "*";
}

String getNameFromLanguage(List<LanguageNameModel> names, String languageCode) {
  for (var item in names) {
    if (item.code == languageCode) {
      return item.name;
    }
  }
  return "*";
}

String getDeliveryName({required code}) {
  var result = "";
  for (var data in posSaleChannelLists) {
    if (data.code == code) {
      result = data.name;
      break;
    }
  }
  return result;
}

String getDeliveryLogo({required code}) {
  var result = "";
  for (var data in posSaleChannelLists) {
    if (data.code == code) {
      result = data.logoUrl;
      break;
    }
  }
  return result;
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

Future<String> getIpAddress() async {
  // Get a list of the network interfaces available on the device
  List<NetworkInterface> interfaces = await NetworkInterface.list();

  // Iterate through the list of interfaces and return the first non-loopback IPv4 address
  for (NetworkInterface interface in interfaces) {
    if (interface.name == 'lo') continue; // Skip the loopback interface
    for (InternetAddress address in interface.addresses) {
      if (_isPrivateIpv4Address(address.address) && address.type == InternetAddressType.IPv4) {
        return address.address;
      }
    }
  }

  // If no non-loopback IPv4 address was found, return null
  return "";
}

double printerWidthByPixel(int printerIndex) {
  if (printerConnectData.paperSize == 1) {
    return 384;
  } else {
    return 576;
  }
}

Future<void> lineNotify(String message) async {
  const String token = String.fromEnvironment('LINE_NOTIFY_TOKEN');
  if (token.isEmpty) {
    return;
  }
  try {
    var url = Uri.parse("https://notify-api.line.me/api/notify");
    var header = {
      "Authorization": "Bearer $token",
    };
    var body = {
      "message": message,
    };
    await http.post(url, headers: header, body: body);
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
  }
}

void setPayTypeEnableConfig() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.setBool('payTypeEnableList0', payTypeEnableList[0]);
  await prefs.setBool('payTypeEnableList1', payTypeEnableList[1]);
  await prefs.setBool('payTypeEnableList2', payTypeEnableList[2]);
  await prefs.setBool('payTypeEnableList3', payTypeEnableList[3]);
}

void getPayTypeEnableConfig() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  payTypeEnableList[0] = prefs.getBool('payTypeEnableList0') ?? true;
  payTypeEnableList[1] = prefs.getBool('payTypeEnableList1') ?? false;
  payTypeEnableList[2] = prefs.getBool('payTypeEnableList2') ?? true;
  payTypeEnableList[3] = prefs.getBool('payTypeEnableList3') ?? true;
}

Future<Uint8List> toQrImageData(String data) async {
  final image = await QrPainter(
    data: data,
    version: QrVersions.auto,
  ).toImageData(400);
  return image!.buffer.asUint8List();
}

Future<void> sendTelegramMessage(String message) async {
  const String token = String.fromEnvironment('TELEGRAM_BOT_TOKEN');
  const String chatId = String.fromEnvironment('TELEGRAM_CHAT_ID');
  if (token.isEmpty || chatId.isEmpty) {
    return;
  }
  final String url = 'https://api.telegram.org/bot$token/sendMessage';

  final response = await http.post(
    Uri.parse(url),
    body: {
      'chat_id': chatId,
      'text': message,
    },
  );

  if (response.statusCode == 200) {
    if (kDebugMode) {
      print('Message sent');
    }
  } else {
    if (kDebugMode) {
      print('Failed to send message');
    }
  }
}

void sendErrorToDevTeam(String message) {
  try {
    if (kDebugMode) {
      print("sendErrorToDevTeam:$message");
    }
    lineNotify("dedeorder:${posInformation.shop_id}:$message");
    sendTelegramMessage("dedeorder:${posInformation.shop_id}:$message");
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
  }
}

Future<bool> checkForCamera() async {
  var result = false;
  try {
    // รับรายชื่อกล้องที่มีอยู่
    final cameras = await availableCameras();

    // ตรวจสอบว่ามีกล้องอย่างน้อยหนึ่งตัวหรือไม่
    if (cameras.isNotEmpty) {
      if (kDebugMode) {
        print('กล้องพร้อมใช้งาน');
      }
      result = true;
    } else {
      if (kDebugMode) {
        print('ไม่พบกล้อง');
      }
      result = false;
    }
  } catch (_) {
    result = false;
  }
  return result;
}

double getProductPrice(String prices, int keyNumber) {
  List<ProductPriceFromServerModel> priceList = jsonDecode(prices).map<ProductPriceFromServerModel>((item) {
    return ProductPriceFromServerModel.fromJson(item);
  }).toList();
  for (ProductPriceFromServerModel item in priceList) {
    if (item.keynumber == keyNumber) {
      return item.price;
    }
  }
  return 0;
}

Future<void> callerCheck() async {
  try {
    if (callerTextToSpeechList.isEmpty) {
      var getData = await api.clickHouseSelect("select * from dedetemp.caller where shopid='${posInformation.shop_id}' and actionstatus=0 order by calldatetime");
      ResponseDataModel response = ResponseDataModel.fromJson(getData);
      if (response.data.isNotEmpty) {
        List<CallerModel> caller = response.data.map<CallerModel>((item) => CallerModel.fromJson(item)).toList();
        for (var call in caller) {
          if (call.actionstatus == 0) {
            // andoird แจ้งเตือน ด้วยเสียง
            if (Platform.isAndroid) {
              // แจ้งเตือนการสั่น
              Vibration.vibrate(duration: 1000);
              if (callerAlert) {
                // แจ้งเตือนด้วยเสียงพูด
                callerTextToSpeechList.add(call.command);
              }
            }
          }
        }
      }
    }
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    sendErrorToDevTeam("callerCheck():$e\n$s");
  }
  callerSpeech();
}

Future<void> callerSpeech() async {
  if (speechActive == false) {
    speechActive = true;
    try {
      // พูดทุก 1 นาที
      if (DateTime.now().difference(callerTextToSpeechLastTime).inSeconds >= 10) {
        callerTextToSpeechLastTime = DateTime.now();
        if (callerTextToSpeechList.isNotEmpty) {
          while (callerTextToSpeechList.isNotEmpty) {
            String word = callerTextToSpeechList[0];
            callerTextToSpeechList.removeAt(0);
            await speak(word);
            await Future.delayed(const Duration(seconds: 5));
          }
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
      }
      sendErrorToDevTeam("callerSpeech():$e\n$s");
    }
    speechActive = false;
  }
}

Future<void> speak(String word) async {
  if (Platform.isAndroid) {
    double volume = 1.0;
    double pitch = 1.0;
    double rate = 0.4;

    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    await flutterTts.setLanguage("th-TH");

    if (word.isNotEmpty) {
      await flutterTts.speak(word);
    }
  }
}

Future<void> loadCategoryData() async {
  orderPageCloneCategoryLists.clear();
  orderPageOrderSelected.clear();
  for (var category in categoryLists) {
    orderPageCloneCategoryLists.add(category);
  }
  for (int i = 0; i < productLists.length; i++) {
    {
      // ถ้าไม่พบสินค้า ให้ไปลบใน Category ที่เกี่ยวข้องออก (Memory)
      for (int i = 0; i < orderPageCloneCategoryLists.length; i++) {
        List<String> removeCodeList = [];
        for (int j = 0; j < orderPageCloneCategoryLists[i].products.length; j++) {
          int index = findProductByBarcode(orderPageCloneCategoryLists[i].products[j].barcode);
          if (index == -1) {
            // ถ้าไม่พบสินค้าใน Barcode Master ให้ลบออกจาก Category
            removeCodeList.add(orderPageCloneCategoryLists[i].products[j].barcode);
          } else {
            if (selectTable.buffet_code.isNotEmpty) {
              // กรณี เป็น Buffet
              if (productLists[index].ordertypes.isEmpty) {
                // ถ้าสินค้าไม่ใช่ Buffet ให้ลบออกจาก Category
                removeCodeList.add(orderPageCloneCategoryLists[i].products[j].barcode);
              } else {
                bool found = false;
                for (int k = 0; k < productLists[index].ordertypes.length; k++) {
                  if (selectTable.buffet_code == productLists[index].ordertypes[k].code) {
                    found = true;
                    break;
                  }
                }
                if (found == false) {
                  // ถ้าไม่พบสินค้าใน Barcode Master ให้ลบออกจาก Category
                  removeCodeList.add(orderPageCloneCategoryLists[i].products[j].barcode);
                }
              }
            } else {
              // กรณีเป็น A La Carte แต่สินค้าไม่ได้กำหนดให้เป็น A La Carte ให้ลบออก
              if (productLists[index].isAlacarte == false) {
                removeCodeList.add(orderPageCloneCategoryLists[i].products[j].barcode);
              }
            }
          }
        }
        for (int j = 0; j < removeCodeList.length; j++) {
          orderPageCloneCategoryLists[i].products.removeWhere((element) => element.barcode == removeCodeList[j]);
        }
      }
    }
  }
  // ลบ Category ที่ไม่มีสินค้าออก
  List<String> removeCategoryList = [];
  for (int i = 0; i < orderPageCloneCategoryLists.length; i++) {
    if (orderPageCloneCategoryLists[i].products.isEmpty) {
      removeCategoryList.add(orderPageCloneCategoryLists[i].guidfixed);
    }
  }
  for (int i = 0; i < removeCategoryList.length; i++) {
    orderPageCloneCategoryLists.removeWhere((element) => element.guidfixed == removeCategoryList[i]);
  }
}
