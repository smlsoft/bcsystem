import 'dart:io';
import 'dart:math';
import 'package:buddhist_datetime_dateformat_sns/buddhist_datetime_dateformat_sns.dart';
import 'package:decimal/decimal.dart';
import 'package:smlaicloud/api/app_const.dart';
import 'package:smlaicloud/environment.dart';
import 'package:smlaicloud/model/bank_model.dart';
import 'package:smlaicloud/model/company_branch_model.dart';
import 'package:smlaicloud/model/profile_model.dart';
import 'package:smlaicloud/model/shop_model.dart';
import 'dart:async';
import 'dart:convert';
import 'package:smlaicloud/model/theme_model.dart';
import 'package:smlaicloud/model/timezones_model.dart';
import 'package:smlaicloud/model/transaction_model.dart';
import 'package:smlaicloud/model/user_login_model.dart';
import 'package:smlaicloud/repositories/client.dart';
import 'package:smlaicloud/repositories/company_branch_repository.dart';
import 'package:smlaicloud/repositories/shop_repository.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:smlaicloud/model/config_model.dart';
import 'package:smlaicloud/model/global_model.dart';
import 'package:smlaicloud/model/price_model.dart';
import 'package:smlaicloud/model/public_color_model.dart';
import 'package:smlaicloud/model/public_name_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart' as intl;
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

typedef GuidCallback = void Function({String guid, bool isEdit});

class FieldFocusModel {
  FocusNode focusNode;
  bool isReadOnly;

  FieldFocusModel({required this.focusNode, this.isReadOnly = false});
}

DeviceConfigModel deviceConfig = DeviceConfigModel(
  listDataFontSize: 12,
  listDataLineSpace: 0,
  itemDisplayPrice: true,
  itemDisplaySku: true,
);

class SearchCodeNameModel {
  String guidfixed;
  String code;
  List<LanguageDataModel> names;
  bool isCancel;
  SearchCodeNameModel({
    required this.guidfixed,
    required this.code,
    required this.names,
    this.isCancel = false,
  });
}

class SearchDebtorModel {
  String guid;
  String code;
  List<LanguageDataModel> names;
  bool ismember;
  String pricelevel;
  SearchDebtorModel({
    required this.guid,
    required this.code,
    required this.names,
    this.ismember = false,
    required this.pricelevel,
  });
}

enum DateTimeFormatEnum { fullDate, date, dateTime, dateTimeDay, time, dateDay }

enum PrintColumnAlign { left, right, center }

enum TransactionTypeEnum {
  purchase,
  purchasereturn,
  sale,
  salereturn,
  stocktransfer,
  stockreceiveproduct,
  stockpickupproduct,
  stockreturnproduct,
  adjust,
  paid,
  pay,
  stockbalance,
  saleorder,
  quotation,
  purchaseorder,
  //ทยอยรับ
  purchasepartial,
  //ตั้งหนี้จากการทยอยรับ
  accrualreceive,
}

enum SelectGroupNumberEnum {
  category,
  zone,
  table,
  tableOrder,
  kitchen,
  genQrcode,
}

enum ReportEnum {
  product,
  saleinvoice,
  saleinvoicedetail,
  debtor,
  creditor,
  bookbank,
  purchase,
  purchasereturn,
  saleinvoicereturn,
  transfer,
  receive,
  pickup,
  returnproduct,
  stockadjustment,

  ///รับชำระ
  paid,

  /// จ่ายชำระ
  pay,

  /// รับเงิน
  getpaid,

  /// จ่ายเงิน
  getpay,
  vatsale,
  vatpurchase,
  salebydebtor,

  /// new
  salebydate,
  receivemoney,
  salebyproduct,
  productmovement,

  /// สินค้าคงเหลือ
  stockbalance,

  ///บัญชีคุมพิเศษ
  stockcard,

  /// CSV
  csvsaledetail,
}

enum PosVersionEnum { pos, restaurant }

enum LoginEnum { none, google, facebook, apple }

enum ScreenEventEnum { add, edit, list, display }

enum DeviceModeEnum {
  none,
  iphone,
  ipad,
  windowsDesktop,
  macosDesktop,
  linuxDesktop,
  androidPhone,
  androidTablet,
}

// โหมด พัฒนาโปรแกรม
bool developerMode = true;

/// sent isdev mode to  clickhouse
/// 0 = dev , 1 = prod , 2 = uat
int isdevPin = 0;

UserLoginModel userLoginData = UserLoginModel(
  token: "",
  name: "",
  email: "",
  photourl: "",
  code: "",
  refreshtoken: "",
);
late SharedPreferences prefs;
List<String> googleLanguageCode = [];
late CompanyModel companyData;
String userLanguage = "";
bool apiConnected = false;
String apiToken = "";
TransactionPayModel payScreenData = TransactionPayModel();
String apiUserName = "";
String apiUserPassword = "";
String apiShopCode = "2Eh6e3pfWvXTp0yV3CyFEhKPjdI"; // "27dcEdktOoaSBYFmnN6G6ett4Jb";
bool isLoginProcess = false;
late SharedPreferences appConfig;
String systemLanguage = "th";
String loginName = "";
String loginEmail = "";
String loginPhotoUrl = "";
int activeIndexMenu = 0;
DeviceModeEnum deviceMode = DeviceModeEnum.androidPhone;
List<PublicColorModel> publicColors = [];
late List<LanguageSystemModel> languageSystemData;
late List<LanguageSystemCodeModel> languageSystemCode;
int loadDataPerPage = 500;
late PosVersionEnum posVersion;
ConfigModel config = ConfigModel();
String goApiVersion = "";
ShopModel shopSelectData = ShopModel();
CompanyBranchModel companyBranchSelectData = CompanyBranchModel(
  guidfixed: '',
  code: '',
  businesstype: null,
);
final translator = GoogleTranslator();
AppConfigClass myAppConfig = AppConfigClass();

List<int> groupNumber = [
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
];

ThemeModel theme = ThemeModel();
List<BankModel> bankTempListDatas = [];

/// รายการโปรโมชั่น
late List<PromotionListModel> promotionList;

SlipListModel summaryOrderBill = SlipListModel(
  code: "SALE01",
  names: [
    LanguageDataModel(code: "th", name: "ใบสรุปรายการก่อนบันทึก"),
    LanguageDataModel(code: "en", name: "Pre-Posting Summary"),
  ],
);

SlipListModel taxInvoice = SlipListModel(
  code: "SALE02",
  names: [
    LanguageDataModel(code: "th", name: "ใบกำกับภาษีอย่างย่อ"),
    LanguageDataModel(code: "en", name: "Pre-Posting Summary"),
  ],
);

SlipListModel taxInvoiceFull = SlipListModel(
  code: "SALE03",
  names: [
    LanguageDataModel(code: "th", name: "ใบกำกับภาษีอย่างเต็ม"),
    LanguageDataModel(code: "en", name: "Tax Invoice Full"),
  ],
);

SlipListModel slipReceipt = SlipListModel(
  code: "SALE04",
  names: [
    LanguageDataModel(code: "th", name: "ใบเสร็จรับเงิน"),
    LanguageDataModel(code: "en", name: "Receipt Slip"),
  ],
);

SlipListModel slipReturn = SlipListModel(
  code: "CN01",
  names: [
    LanguageDataModel(code: "th", name: "ใบรับคืนอย่างย่อ"),
    LanguageDataModel(code: "en", name: "Return Slip"),
  ],
);

SlipListModel slipReturnFull = SlipListModel(
  code: "CN02",
  names: [
    LanguageDataModel(code: "th", name: "ใบรับคืนอย่างเต็ม"),
    LanguageDataModel(code: "en", name: "Return Slip Full"),
  ],
);

/// slip pos ขาย
List<SlipListModel> slipPosSaleList = [
  summaryOrderBill,
  taxInvoice,
  taxInvoiceFull,
  slipReceipt,
  slipReturn,
  slipReturnFull,
];

/// timezone list
List<TimezonesModel> timezonesListData = [];

ProfileModel profileData = ProfileModel();

Locale local = const Locale('en', 'US');
EraMode eraMode = EraMode.CHRIST_YEAR;

final moneyFormatAndDot = intl.NumberFormat("##,##0.00");
final moneyFormat = intl.NumberFormat("##,##0.##");
// วิธีการปัดเศษเงินยอดรวม 0=ไม่ปัดเศษ,1=ปัดเศษตามกฏหมาย,2=ปัดเศษขึ้นเป็นจำนวนเต็ม,3=ปัดเศษลงเป็นจำนวนเต็ม
int payTotalMoneyRoundType = 1;
// Step การปัดเศษ ค่าว่าง=จำนวนเต็มอัตโนมัติ,0.25,0.5,0.75
List<MoneyRoundPayModel> payTotalMoneyRoundStep = [
  MoneyRoundPayModel(begin: 0.01, end: 0.12, value: 0),
  MoneyRoundPayModel(begin: 0.13, end: 0.37, value: 0.25),
  MoneyRoundPayModel(begin: 0.38, end: 0.62, value: 0.5),
  MoneyRoundPayModel(begin: 0.63, end: 0.87, value: 0.75),
  MoneyRoundPayModel(begin: 0.88, end: 0.99, value: 1.0),
];

double roundDouble(double value, int places) {
  num mod = pow(10.0, places);
  return ((value * mod).round().toDouble() / mod);
}

int getPageNumber(int itemIndex, int limit) {
  return (itemIndex ~/ limit) + 1;
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

bool isMobileScreen(BuildContext context) {
  return MediaQuery.of(context).size.width < 600;
}

String transactionName(TransactionTypeEnum transactionType) {
  switch (transactionType) {
    case TransactionTypeEnum.purchase:
      return language("transaction_purchase");
    case TransactionTypeEnum.purchasereturn:
      return language("transaction_purchasereturn");
    case TransactionTypeEnum.sale:
      return language("transaction_sale");
    case TransactionTypeEnum.salereturn:
      return language("transaction_salereturn");
    case TransactionTypeEnum.stockpickupproduct:
      return language("transaction_stock_pick_up_product");
    case TransactionTypeEnum.stockreceiveproduct:
      return language("transaction_stock_receive_product");
    case TransactionTypeEnum.stockreturnproduct:
      return language("transaction_stock_return_product");
    case TransactionTypeEnum.stocktransfer:
      return language("transaction_stock_transfer");
    case TransactionTypeEnum.adjust:
      return language("transaction_adjust");
    case TransactionTypeEnum.paid:
      return language("transaction_paid");
    case TransactionTypeEnum.pay:
      return language("transaction_pay");
    case TransactionTypeEnum.stockbalance:
      return language("transaction_stock_balance");
    case TransactionTypeEnum.saleorder:
      return language("transaction_sale_order");
    case TransactionTypeEnum.quotation:
      return language("transaction_quotation");
    case TransactionTypeEnum.purchaseorder:
      return language("transaction_purchase_order");
    case TransactionTypeEnum.purchasepartial:
      return language("transaction_purchase_partial");
    case TransactionTypeEnum.accrualreceive:
      return language("transaction_accrual_receive");
  }
}

String getreportName(ReportEnum reportType) {
  switch (reportType) {
    case ReportEnum.product:
      return language("report_product");
    case ReportEnum.saleinvoice:
      return language("report_saleinvoice");
    case ReportEnum.saleinvoicedetail:
      return language("report_saleinvoicedetail");
    case ReportEnum.debtor:
      return language("report_debtor");
    case ReportEnum.creditor:
      return language("report_creditor");
    case ReportEnum.bookbank:
      return language("report_bookbank");
    case ReportEnum.purchase:
      return language("report_purchase");
    case ReportEnum.purchasereturn:
      return language("report_purchasereturn");
    case ReportEnum.saleinvoicereturn:
      return language("report_saleinvoicereturn");
    case ReportEnum.transfer:
      return language("report_transfer");
    case ReportEnum.receive:
      return language("report_receive");
    case ReportEnum.pickup:
      return language("report_pickup");
    case ReportEnum.returnproduct:
      return language("report_returnproduct");
    case ReportEnum.stockadjustment:
      return language("report_stockadjustment");
    case ReportEnum.paid:
      return language("report_paid");
    case ReportEnum.pay:
      return language("report_pay");
    case ReportEnum.getpaid:
      return language("report_getpaid");
    case ReportEnum.getpay:
      return language("report_getpay");
    case ReportEnum.vatsale:
      return language("report_vatsale");
    case ReportEnum.vatpurchase:
      return language("report_vatpurchase");
    case ReportEnum.salebydebtor:
      return language("report_salebydebtor");
    case ReportEnum.salebydate:
      return language("report_salebydate");
    case ReportEnum.receivemoney:
      return language("report_receivemoney");
    case ReportEnum.salebyproduct:
      return language("report_salebyproduct");
    case ReportEnum.productmovement:
      return language("report_productmovement");
    case ReportEnum.stockbalance:
      return language("report_stockbalance");
    case ReportEnum.stockcard:
      return language("report_stockcard");
    case ReportEnum.csvsaledetail:
      return language("csv_saledetail");
  }
}

String dateTimeBuddhist(
  DateTime dateTime, {
  DateTimeFormatEnum format = DateTimeFormatEnum.fullDate,
}) {
  int day = dateTime.day;
  int month = dateTime.month;
  String dayOfWeek = intl.DateFormat.EEEE('th_TH').format(dateTime);
  String monthYear = intl.DateFormat.MMMM('th_TH').format(dateTime);
  String yearStr = dateTime.yearInBuddhistCalendar.toString();
  switch (format) {
    case DateTimeFormatEnum.fullDate:
      return '$dayOfWeek ที่ $day $monthYear $yearStr';
    case DateTimeFormatEnum.date:
      return "${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$yearStr";
    case DateTimeFormatEnum.time:
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    case DateTimeFormatEnum.dateTime:
      if (dateTime.hour == 0 && dateTime.minute == 0) {
        return "${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$yearStr";
      } else {
        return "${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$yearStr ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      }
    case DateTimeFormatEnum.dateTimeDay:
      if (dateTime.hour == 0 && dateTime.minute == 0) {
        return "${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$yearStr ($dayOfWeek)";
      } else {
        return "${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$yearStr ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ($dayOfWeek)";
      }
    case DateTimeFormatEnum.dateDay:
      return "${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$yearStr ($dayOfWeek)";
  }
}

void getTimezones() {
  const githubRawUrl = 'https://raw.githubusercontent.com/smlsoft/dedepos_template/main/timezones.json';
  readFileFromGithub(githubRawUrl).then((fileContent) {
    List<TimezonesModel> timezones = (json.decode(fileContent) as List).map((timezone) => TimezonesModel.fromJson(timezone)).toList();

    for (var data in timezones) {
      timezonesListData.add(data);
    }
  }).catchError((error) {
    // ignore: avoid_print
    print('Error reading file: $error');
  });
}

TimeOfDay getTimeOfDayFromString(String timeString) {
  // Split the time string into hours and minutes
  List<String> timeParts = timeString.split(":");
  int hours = int.parse(timeParts[0]);
  int minutes = int.parse(timeParts[1]);

  // Create the TimeOfDay object
  TimeOfDay time = TimeOfDay(hour: hours, minute: minutes);

  return time;
}

void themeSelect(int mode) {
  switch (mode) {
    case 0:
      theme.backgroundColor = Colors.grey[50]!;
      theme.appBarColor = colorFromHex("012A4A");
      theme.headTitleColor = Colors.white;
      theme.inputTextBoxForceColor = colorFromHex("8A1606");
      theme.inputTextBoxColor = Colors.black;
      theme.columnHeaderColor = colorFromHex("89C2D9");
      theme.columnHeaderTextColor = Colors.black;
      theme.columnAlternateEvenColor = colorFromHex("F3F7FA");
      theme.columnAlternateOddColor = Colors.white;
      theme.buttonIconBackgroundColor = Colors.white;
      theme.buttonColor = colorFromHex("2A6F97");
      theme.buttonYesColor = colorFromHex("2A6F97");
      theme.buttonNoColor = colorFromHex("A9D6E5");
      theme.toolBarEditModeColor = colorFromHex("2A6F97");
      break;
    case 1:

      /// color for dohome
      theme.primaryColor = colorFromHex("235396");
      theme.primaryLightColor = colorFromHex("4283C2");
      theme.secondaryColor = colorFromHex("FFFFFF");

      theme.backgroundColor = Colors.grey[50]!;
      theme.appBarColor = colorFromHex("012A4A");
      theme.headTitleColor = Colors.white;
      theme.inputTextBoxForceColor = colorFromHex("8A1606");
      theme.inputTextBoxColor = Colors.black;
      theme.columnHeaderColor = colorFromHex("89C2D9");
      theme.columnHeaderTextColor = Colors.black;
      theme.columnAlternateEvenColor = colorFromHex("F3F7FA");
      theme.columnAlternateOddColor = Colors.white;
      theme.buttonIconBackgroundColor = Colors.white;
      theme.buttonColor = colorFromHex("2A6F97");
      theme.buttonYesColor = colorFromHex("2A6F97");
      theme.buttonNoColor = colorFromHex("A9D6E5");
      theme.toolBarEditModeColor = colorFromHex("2A6F97");
  }
}

String randomDocNo(String header, DateTime selectedDate) {
  String returnValue = "";
  const uuid = Uuid();
  final formattedDate = intl.DateFormat('yyMMddHHmm').format(selectedDate);
  returnValue = header + formattedDate + uuid.v4().split("-")[1];
  return returnValue.toUpperCase();
}

String packName(List<LanguageDataModel> names) {
  String result = "";
  for (int i = 0; i < names.length; i++) {
    if (names[i].name.isNotEmpty) {
      if (i > 0) {
        if (names[i].name != '') {
          result += ",";
        }
      }
      result += names[i].name;
    }
  }
  return result;
}

class Debouncer {
  final int? milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer(this.milliseconds);

  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }

    _timer = Timer(Duration(milliseconds: milliseconds!), action);
  }
}

Future<void> loadShopProfile() async {}

Future<void> setSystemLanguage(BuildContext context) async {
  List<LanguageModel> defualtLanguages = [
    LanguageModel(code: "th", codeTranslator: "th", name: "Thai", isuse: false),
    LanguageModel(
      code: "en",
      codeTranslator: "en",
      name: "English",
      isuse: false,
    ),
    LanguageModel(
      code: "zh",
      codeTranslator: "zh",
      name: "Chinese",
      isuse: false,
    ),
    LanguageModel(
      code: "ja",
      codeTranslator: "ja",
      name: "Japanese",
      isuse: false,
    ),
    LanguageModel(
      code: "ko",
      codeTranslator: "ko",
      name: "Korean",
      isuse: false,
    ),
    LanguageModel(code: "lo", codeTranslator: "lo", name: "Lao", isuse: false),
    LanguageModel(
      code: "my",
      codeTranslator: "my",
      name: "Burmese",
      isuse: false,
    ),
    LanguageModel(
      code: "ms",
      codeTranslator: "ms",
      name: "Malaysian",
      isuse: false,
    ),
    LanguageModel(
      code: "vi",
      codeTranslator: "vi",
      name: "Vietnamese",
      isuse: false,
    ),
    LanguageModel(
      code: "km",
      codeTranslator: "km",
      name: "Khmer",
      isuse: false,
    ),
  ];
  config.languages = [];
  ShopRepository shopRepository = ShopRepository();
  // JsonRepository jsonRepository = JsonRepository();
  CompanyBranchRepository companyBranchRepository = CompanyBranchRepository();

  try {
    ApiResponse result = await shopRepository.loadShopInfo(getShopId());
    if (result.success) {
      ShopModel shopmodel = ShopModel.fromJson(result.data);
      shopSelectData = shopmodel;

      config.vatrate = shopmodel.settings!.vatrate!;
      config.vattypesale = shopmodel.settings!.vattypesale!;
      config.vattypepurchase = shopmodel.settings!.vattypepurchase!;
      config.inquirytypesale = shopmodel.settings!.inquirytypesale!;
      config.inquirytypepurchase = shopmodel.settings!.inquirytypepurchase!;

      for (var data in shopmodel.settings!.languageconfigs!) {
        if (data.code == "th") {
          config.languages.add(
            LanguageModel(
              code: "th",
              codeTranslator: "th",
              name: "Thai",
              isuse: true,
            ),
          );
        } else if (data.code == "en") {
          config.languages.add(
            LanguageModel(
              code: "en",
              codeTranslator: "en",
              name: "English",
              isuse: true,
            ),
          );
        } else if (data.code == "zh") {
          config.languages.add(
            LanguageModel(
              code: "zh",
              codeTranslator: "zh",
              name: "Chinese",
              isuse: true,
            ),
          );
        } else if (data.code == "ja") {
          config.languages.add(
            LanguageModel(
              code: "ja",
              codeTranslator: "ja",
              name: "Japanese",
              isuse: true,
            ),
          );
        } else if (data.code == "ko") {
          config.languages.add(
            LanguageModel(
              code: "ko",
              codeTranslator: "ko",
              name: "Korean",
              isuse: true,
            ),
          );
        } else if (data.code == "lo") {
          config.languages.add(
            LanguageModel(
              code: "lo",
              codeTranslator: "lo",
              name: "Lao",
              isuse: true,
            ),
          );
        } else if (data.code == "my") {
          config.languages.add(
            LanguageModel(
              code: "my",
              codeTranslator: "my",
              name: "Burmese",
              isuse: true,
            ),
          );
        } else if (data.code == "ms") {
          config.languages.add(
            LanguageModel(
              code: "ms",
              codeTranslator: "ms",
              name: "Malaysian",
              isuse: true,
            ),
          );
        } else if (data.code == "vi") {
          config.languages.add(
            LanguageModel(
              code: "vi",
              codeTranslator: "vi",
              name: "Vietnamese",
              isuse: true,
            ),
          );
        } else if (data.code == "km") {
          config.languages.add(
            LanguageModel(
              code: "km",
              codeTranslator: "km",
              name: "Khmer",
              isuse: true,
            ),
          );
        }
      }

      try {
        ApiResponse resultBranch = await companyBranchRepository.getBranch(
          getBranchGuidFixed(),
        );

        if (resultBranch.success) {
          CompanyBranchModel companyBranchModel = CompanyBranchModel.fromJson(
            resultBranch.data,
          );
          companyBranchSelectData = companyBranchModel;
        }
      } catch (ex) {
        print(ex);
      }
    }

    // ApiResponse result = await jsonRepository.getSetting("ConfigSystem", "");
    // if (result.success) {
    //   if (result.data.length > 0) {
    //     ConfigSystemModel configSystem = ConfigSystemModel.fromJson(json.decode(result.data[0]['body']));
    //     config.vatrate = configSystem.vatrate!;
    //     config.vattypesale = configSystem.vattypesale!;
    //     config.vattypepurchase = configSystem.vattypepurchase!;
    //     config.inquirytypesale = configSystem.inquirytypesale!;
    //     config.inquirytypepurchase = configSystem.inquirytypepurchase!;

    //     for (var data in configSystem.languageList) {
    //       if (data == "th") {
    //         config.languages.add(
    //           LanguageModel(code: "th", codeTranslator: "th", name: "Thai", isuse: true),
    //         );
    //       } else if (data == "en") {
    //         config.languages.add(
    //           LanguageModel(code: "en", codeTranslator: "en", name: "English", isuse: true),
    //         );
    //       } else if (data == "zh") {
    //         config.languages.add(
    //           LanguageModel(code: "zh", codeTranslator: "zh", name: "Chinese", isuse: true),
    //         );
    //       } else if (data == "ja") {
    //         config.languages.add(
    //           LanguageModel(code: "ja", codeTranslator: "ja", name: "Japanese", isuse: true),
    //         );
    //       } else if (data == "ko") {
    //         config.languages.add(
    //           LanguageModel(code: "ko", codeTranslator: "ko", name: "Korean", isuse: true),
    //         );
    //       } else if (data == "lo") {
    //         config.languages.add(
    //           LanguageModel(code: "lo", codeTranslator: "lo", name: "Lao", isuse: true),
    //         );
    //       } else if (data == "my") {
    //         config.languages.add(
    //           LanguageModel(code: "my", codeTranslator: "my", name: "Burmese", isuse: true),
    //         );
    //       } else if (data == "ms") {
    //         config.languages.add(
    //           LanguageModel(code: "ms", codeTranslator: "ms", name: "Malaysian", isuse: true),
    //         );
    //       } else if (data == "vi") {
    //         config.languages.add(
    //           LanguageModel(code: "vi", codeTranslator: "vi", name: "Vietnamese", isuse: true),
    //         );
    //       } else if (data == "km") {
    //         config.languages.add(
    //           LanguageModel(code: "km", codeTranslator: "km", name: "Khmer", isuse: true),
    //         );
    //       }
    //     }

    //     for (var defualtLang in defualtLanguages) {
    //       LanguageModel result =
    //           config.languages.firstWhere((data) => data.code == defualtLang.code, orElse: () => LanguageModel(code: '', codeTranslator: '', name: '', isuse: false));
    //       if (result.code == '') {
    //         config.languages.add(defualtLang);
    //       }
    //     }
    //   } else {
    //     config.languages = defualtLanguages;
    //     config.languages[0].use = true;
    //     config.vatrate = 7.0;
    //     config.vattypesale = 0;
    //     config.vattypepurchase = 0;
    //     config.inquirytypesale = 0;
    //     config.inquirytypepurchase = 0;
    //   }
    // }
  } catch (ex) {
    config.languages = defualtLanguages;
    config.languages[0].isuse = true;
    config.vatrate = 7.0;
    config.vattypesale = 0;
    config.vattypepurchase = 0;
    config.inquirytypesale = 0;
    config.inquirytypepurchase = 0;
  }

  List<PriceModel> allPrices = [
    PriceModel(
      keyNumber: 1,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาขายปลีก",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 2,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาขายสมาชิก",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 3,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาตามช่องทาง",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 4,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาตามช่องทาง 1",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 5,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาตามช่องทาง 2",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 6,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาตามช่องทาง 3",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 7,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาตามช่องทาง 4",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 8,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาตามช่องทาง 5",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 9,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาลู่ที่ 1",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 10,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาลู่ที่ 2",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 11,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาลู่ที่ 3",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 12,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาลู่ที่ 4",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 13,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาลู่ที่ 5",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 14,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาลู่ที่ 6",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 15,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาลู่ที่ 7",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 16,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาลู่ที่ 8",
          isuse: true,
        ),
      ],
    ),
    PriceModel(
      keyNumber: 17,
      isUse: true,
      names: [
        LanguageModel(
          code: "th",
          codeTranslator: "th",
          name: "ราคาลู่ที่ 9",
          isuse: true,
        ),
      ],
    ),
  ];

  // กรองราคาตาม posVersion
  if (posVersion == PosVersionEnum.pos) {
    // POS: แสดง keyNumber 1-2 และ 9-17
    config.prices = allPrices.where((price) => (price.keyNumber >= 1 && price.keyNumber <= 2) || (price.keyNumber >= 9 && price.keyNumber <= 17)).toList();
  } else if (posVersion == PosVersionEnum.restaurant) {
    // Restaurant: แสดง keyNumber 1-8
    config.prices = allPrices.where((price) => price.keyNumber >= 1 && price.keyNumber <= 8).toList();
  }

  publicColors = [
    PublicColorModel()
      ..code = "white"
      ..names = [
        PublicNameModel(languageCode: "th", name: "ขาว"),
        PublicNameModel(languageCode: "en", name: "White"),
        PublicNameModel(languageCode: "cn", name: "白色"),
        PublicNameModel(languageCode: "jp", name: "白"),
        PublicNameModel(languageCode: "kr", name: "하얀색"),
        PublicNameModel(languageCode: "lo", name: "ຊາຍ"),
        PublicNameModel(languageCode: "mr", name: "အဖြူ"),
        PublicNameModel(languageCode: "my", name: "Putih"),
        PublicNameModel(languageCode: "vi", name: "Trắng"),
        PublicNameModel(languageCode: "km", name: "ស"),
      ]
      ..color = "#FFFFFF",
    PublicColorModel()
      ..code = "black"
      ..names = [
        PublicNameModel(languageCode: "th", name: "ดำ"),
        PublicNameModel(languageCode: "en", name: "Black"),
        PublicNameModel(languageCode: "cn", name: "黑色"),
        PublicNameModel(languageCode: "jp", name: "黒"),
        PublicNameModel(languageCode: "kr", name: "검은색"),
        PublicNameModel(languageCode: "lo", name: "ດັງ"),
        PublicNameModel(languageCode: "mr", name: "အနောက်"),
        PublicNameModel(languageCode: "my", name: "Hitam"),
        PublicNameModel(languageCode: "vi", name: "Đen"),
        PublicNameModel(languageCode: "km", name: "ខ្មៅ"),
      ]
      ..color = "#000000",
    PublicColorModel()
      ..code = "red"
      ..names = [
        PublicNameModel(languageCode: "th", name: "แดง"),
        PublicNameModel(languageCode: "en", name: "Red"),
        PublicNameModel(languageCode: "cn", name: "红色"),
        PublicNameModel(languageCode: "jp", name: "赤"),
        PublicNameModel(languageCode: "kr", name: "빨간색"),
        PublicNameModel(languageCode: "lo", name: "ເທື່ອ"),
        PublicNameModel(languageCode: "mr", name: "အန္တရာယ်"),
        PublicNameModel(languageCode: "my", name: "Merah"),
        PublicNameModel(languageCode: "vi", name: "Đỏ"),
        PublicNameModel(languageCode: "km", name: "ក្រហម"),
      ]
      ..color = "#FF0000",
    PublicColorModel()
      ..code = "green"
      ..names = [
        PublicNameModel(languageCode: "th", name: "เขียว"),
        PublicNameModel(languageCode: "en", name: "Green"),
        PublicNameModel(languageCode: "cn", name: "绿色"),
        PublicNameModel(languageCode: "jp", name: "緑"),
        PublicNameModel(languageCode: "kr", name: "녹색"),
        PublicNameModel(languageCode: "lo", name: "ສີຂາວ"),
        PublicNameModel(languageCode: "mr", name: "အဖြူ"),
        PublicNameModel(languageCode: "my", name: "Hijau"),
        PublicNameModel(languageCode: "vi", name: "Xanh lá"),
        PublicNameModel(languageCode: "km", name: "បៃតង"),
      ]
      ..color = "#008000",
    PublicColorModel()
      ..code = "blue"
      ..names = [
        PublicNameModel(languageCode: "th", name: "น้ำเงิน"),
        PublicNameModel(languageCode: "en", name: "Blue"),
        PublicNameModel(languageCode: "cn", name: "蓝色"),
        PublicNameModel(languageCode: "jp", name: "青"),
        PublicNameModel(languageCode: "kr", name: "파란색"),
        PublicNameModel(languageCode: "lo", name: "ສີບາດ"),
        PublicNameModel(languageCode: "mr", name: "အဖြူ"),
        PublicNameModel(languageCode: "my", name: "Biru"),
        PublicNameModel(languageCode: "vi", name: "Xanh da trời"),
        PublicNameModel(languageCode: "km", name: "ខៀវ"),
      ]
      ..color = "#0000FF",
    PublicColorModel()
      ..code = "yellow"
      ..names = [
        PublicNameModel(languageCode: "th", name: "เหลือง"),
        PublicNameModel(languageCode: "en", name: "Yellow"),
        PublicNameModel(languageCode: "cn", name: "黄色"),
        PublicNameModel(languageCode: "jp", name: "黄"),
        PublicNameModel(languageCode: "kr", name: "노란색"),
        PublicNameModel(languageCode: "lo", name: "ສີເຫຼືອ"),
        PublicNameModel(languageCode: "mr", name: "အရောင်"),
        PublicNameModel(languageCode: "my", name: "Kuning"),
        PublicNameModel(languageCode: "vi", name: "Vàng"),
        PublicNameModel(languageCode: "km", name: "លឿង"),
      ]
      ..color = "#FFFF00",
    PublicColorModel()
      ..code = "orange"
      ..names = [
        PublicNameModel(languageCode: "th", name: "ส้ม"),
        PublicNameModel(languageCode: "en", name: "Orange"),
        PublicNameModel(languageCode: "cn", name: "橙色"),
        PublicNameModel(languageCode: "jp", name: "オレンジ"),
        PublicNameModel(languageCode: "kr", name: "주황색"),
        PublicNameModel(languageCode: "lo", name: "ສີເຫຼືອ"),
        PublicNameModel(languageCode: "mr", name: "အရောင်"),
        PublicNameModel(languageCode: "my", name: "Kuning"),
        PublicNameModel(languageCode: "vi", name: "Cam"),
        PublicNameModel(languageCode: "km", name: "លឿង"),
      ]
      ..color = "#FFA500",
    PublicColorModel()
      ..code = "purple"
      ..names = [
        PublicNameModel(languageCode: "th", name: "ม่วง"),
        PublicNameModel(languageCode: "en", name: "Purple"),
        PublicNameModel(languageCode: "cn", name: "紫色"),
        PublicNameModel(languageCode: "jp", name: "紫"),
        PublicNameModel(languageCode: "kr", name: "보라색"),
        PublicNameModel(languageCode: "lo", name: "ສີມາດ"),
        PublicNameModel(languageCode: "mr", name: "အမျိုးသား"),
        PublicNameModel(languageCode: "my", name: "Ungu"),
        PublicNameModel(languageCode: "vi", name: "Tím"),
        PublicNameModel(languageCode: "km", name: "ស្វាយ"),
      ]
      ..color = "#800080",
    PublicColorModel()
      ..code = "brown"
      ..names = [
        PublicNameModel(languageCode: "th", name: "น้ำตาล"),
        PublicNameModel(languageCode: "en", name: "Brown"),
        PublicNameModel(languageCode: "cn", name: "棕色"),
        PublicNameModel(languageCode: "jp", name: "茶色"),
        PublicNameModel(languageCode: "kr", name: "갈색"),
        PublicNameModel(languageCode: "lo", name: "ສີບາດ"),
        PublicNameModel(languageCode: "mr", name: "အဖြူ"),
        PublicNameModel(languageCode: "my", name: "Biru"),
        PublicNameModel(languageCode: "vi", name: "Xanh da trời"),
        PublicNameModel(languageCode: "km", name: "ខៀវ"),
      ]
      ..color = "#A52A2A",
    PublicColorModel()
      ..code = "pink"
      ..names = [
        PublicNameModel(languageCode: "th", name: "ชมพู"),
        PublicNameModel(languageCode: "en", name: "Pink"),
        PublicNameModel(languageCode: "cn", name: "粉色"),
        PublicNameModel(languageCode: "jp", name: "ピンク"),
        PublicNameModel(languageCode: "kr", name: "분홍색"),
        PublicNameModel(languageCode: "lo", name: "ສີມາດ"),
        PublicNameModel(languageCode: "mr", name: "အမျိုးသား"),
        PublicNameModel(languageCode: "my", name: "Ungu"),
        PublicNameModel(languageCode: "vi", name: "Tím"),
        PublicNameModel(languageCode: "km", name: "ស្វាយ"),
      ]
      ..color = "#FFC0CB",
    PublicColorModel()
      ..code = "gray"
      ..names = [
        PublicNameModel(languageCode: "th", name: "เทา"),
        PublicNameModel(languageCode: "en", name: "Gray"),
        PublicNameModel(languageCode: "cn", name: "灰色"),
        PublicNameModel(languageCode: "jp", name: "灰色"),
        PublicNameModel(languageCode: "kr", name: "회색"),
        PublicNameModel(languageCode: "lo", name: "ສີເຫຼືອ"),
        PublicNameModel(languageCode: "mr", name: "အရောင်"),
        PublicNameModel(languageCode: "my", name: "Kuning"),
        PublicNameModel(languageCode: "vi", name: "Vàng"),
        PublicNameModel(languageCode: "km", name: "លឿង"),
      ]
      ..color = "#808080",
  ];

  for (var i = 0; i < publicColors.length; i++) {
    for (var j = 0; j < publicColors[i].names.length; j++) {
      publicColors[i].name = "";
      if (publicColors[i].names[j].languageCode == systemLanguage) {
        publicColors[i].name = publicColors[i].names[j].name;
        break;
      }
    }
  }
}

Future<String> readFileFromGithub(String url) async {
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final fileContent = response.body;
      return fileContent;
    } else {
      throw Exception('Failed to load file');
    }
  } catch (e) {
    rethrow;
  }
}

Color colorFromHex(String hexColor) {
  final hexCode = hexColor.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}

void showSnackBar(
  BuildContext context,
  Icon icon,
  String message,
  Color color,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: color,
      duration: const Duration(seconds: 3),
      content: (Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Flexible(child: Text(message, overflow: TextOverflow.ellipsis)),
        ],
      )),
    ),
  );
}

String language(String code) {
  bool found = false;
  code = code.trim().toLowerCase();
  String result = code;
  for (int i = 0; i < languageSystemData.length; i++) {
    if (languageSystemData[i].code == code) {
      result = languageSystemData[i].text;
      found = true;
      break;
    }
  }
  if (!found) {
    /*dev.log("language not found: $code");
    if (developerMode && code.trim().isNotEmpty && kIsWeb == false) {
      googleMultiLanguageSheetAppendRow(["pos", code]);
    }*/
  }
  return (result.trim().isEmpty) ? code : result;
}

void languageSelect(String languageCode) {
  languageSystemData = [];
  for (int i = 0; i < languageSystemCode.length; i++) {
    for (int j = 0; j < languageSystemCode[i].langs.length; j++) {
      if (languageSystemCode[i].langs[j].code == userLanguage) {
        languageSystemData.add(
          LanguageSystemModel(
            code: languageSystemCode[i].code.trim(),
            text: languageSystemCode[i].langs[j].text.trim(),
          ),
        );
      }
    }
  }
  /*global.languageSystemData.sort((a, b) {
    return a.code.compareTo(b.code);
  });*/
}

void deviceConfigLoad() {
  try {
    dynamic json = appConfig.getString("device");
    if (json != null) {
      deviceConfig = DeviceConfigModel.fromJson(jsonDecode(json));
    }
  } catch (e) {
    if (kDebugMode) {
      dev.log("deviceConfigLoad : $e");
    }
  }
}

Future<List<TimezonesModel>> getTimezonesList(filter) async {
  return timezonesListData;
}

String getLangName(String code, List<LanguageModel> languageList) {
  LanguageModel name = languageList.firstWhere(
    (element) => element.code == code,
    orElse: () => LanguageModel(code: '', codeTranslator: '', name: '', isuse: false),
  );
  return name.name!;
}

Future<void> deviceConfigSaveJson() async {
  try {
    await appConfig.setString("device", jsonEncode(deviceConfig.toJson()));
  } catch (e) {
    dev.log("deviceConfigSaveJson : $e");
  }
}

void listDataFontSizeChange() {
  // เก็บขนาดตัวอักษร (หน้าจอ List Data ทุกจอ)
  if (deviceConfig.listDataFontSize > 24) {
    deviceConfig.listDataFontSize = 12;
  } else {
    deviceConfig.listDataFontSize = deviceConfig.listDataFontSize + 2;
  }
  deviceConfigSaveJson();
}

void listDataLineSpaceChange() {
  // ขนาดช่องว่างข้อมูล
  if (deviceConfig.listDataLineSpace > 5) {
    deviceConfig.listDataLineSpace = 0;
  } else {
    deviceConfig.listDataLineSpace = deviceConfig.listDataLineSpace + 1;
  }
  deviceConfigSaveJson();
}

class NumberInputFormatter extends TextInputFormatter {
  final int maximumFractionDigits;
  NumberInputFormatter({this.maximumFractionDigits = 2}) : assert(maximumFractionDigits >= 0);
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newText = newValue.text;
    var selectionOffset = newValue.selection.extent.offset;
    bool isNegative = false;
    if (newText.startsWith('-')) {
      newText = newText.substring(1);
      isNegative = true;
    }
    if (newText.isEmpty) {
      return newValue;
    }
    if (newText.indexOf('.') != newText.lastIndexOf('.')) {
      // inputted more than one dot.
      return oldValue;
    }
    if (newText.startsWith('.') && maximumFractionDigits > 0) {
      newText = '0$newText';
      selectionOffset += 1;
    }
    while (newText.length > 1 && !newText.startsWith('0.') && newText.startsWith('0')) {
      newText = newText.substring(1);
      selectionOffset -= 1;
    }
    if (decimalDigitsOf(newText) > maximumFractionDigits) {
      // delete the extra digits.
      newText = newText.substring(
        0,
        newText.indexOf('.') + 1 + maximumFractionDigits,
      );
    }
    if (newValue.text.length == oldValue.text.length - 1 &&
        oldValue.text.substring(
              newValue.selection.extentOffset,
              newValue.selection.extentOffset + 1,
            ) ==
            ',') {
      // in this case, user deleted the thousands separator, we should delete the digit number before the cursor.
      newText = newText.replaceRange(
        newValue.selection.extentOffset - 1,
        newValue.selection.extentOffset,
        '',
      );
      selectionOffset -= 1;
    }
    if (newText.endsWith('.')) {
      // in order to calculate the selection offset correctly, we delete the last decimal point first.
      newText = newText.replaceRange(newText.length - 1, newText.length, '');
    }
    int lengthBeforeFormat = newText.length;
    newText = _removeComma(newText);
    if (double.tryParse(newText) == null) {
      // invalid decimal number
      return oldValue;
    }
    newText = _addComma(newText);
    selectionOffset += newText.length - lengthBeforeFormat; // thousands separator newly added
    if (maximumFractionDigits > 0 && newValue.text.endsWith('.')) {
      // decimal point is at the last digit, we need to append it back.
      newText = '$newText.';
    }
    if (isNegative) {
      newText = '-$newText';
    }
    try {
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: math.min(selectionOffset, newText.length),
        ),
      );
    } catch (e) {
      return oldValue;
    }
  }

  static int decimalDigitsOf(String text) {
    var index = text.indexOf('.');
    return index == -1 ? 0 : text.length - index - 1;
  }

  static String _addComma(String text) {
    StringBuffer sb = StringBuffer();
    var pointIndex = text.indexOf('.');
    String integerPart;
    String decimalPart;
    if (pointIndex >= 0) {
      integerPart = text.substring(0, pointIndex);
      decimalPart = text.substring(pointIndex);
    } else {
      integerPart = text;
      decimalPart = '';
    }
    List<String> parts = [];
    while (integerPart.length > 3) {
      parts.add(integerPart.substring(integerPart.length - 3));
      integerPart = integerPart.substring(0, integerPart.length - 3);
    }
    parts.add(integerPart);
    sb.writeAll(parts.reversed, ',');
    sb.write(decimalPart);
    return sb.toString();
  }

  static String _removeComma(String text) {
    return text.replaceAll(',', '');
  }
}

String getVatName(int number) {
  String returnValue = "";
  if (number == 0) {
    returnValue = language("vat_exclude");
  } else if (number == 1) {
    returnValue = language("vat_include");
  } else if (number == 2) {
    returnValue = language("vat_zero");
  } else if (number == 3) {
    returnValue = language("vat_none");
  }
  return returnValue;
}

String getInquiryName(int number) {
  String returnValue = "";
  if (number == 0) {
    returnValue = language("credit");
  } else if (number == 1) {
    returnValue = language("cash");
  }
  return returnValue;
}

bool isWideScreen() {
  return (deviceMode == DeviceModeEnum.androidTablet ||
      deviceMode == DeviceModeEnum.ipad ||
      deviceMode == DeviceModeEnum.macosDesktop ||
      deviceMode == DeviceModeEnum.linuxDesktop ||
      deviceMode == DeviceModeEnum.windowsDesktop);
}

Future<void> getDeviceModel(BuildContext context) async {
  final deviceInfo = DeviceInfoPlugin();

  String model = '';

  if (kIsWeb) {
    deviceMode = DeviceModeEnum.windowsDesktop;
    return;
  }

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;

    model = androidInfo.model;

    // ignore: use_build_context_synchronously
    var shortestSide = MediaQuery.of(context).size.shortestSide;

    if (shortestSide > 600) {
      deviceMode = DeviceModeEnum.androidTablet;
    } else {
      deviceMode = DeviceModeEnum.androidPhone;
    }
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;

    model = iosInfo.model;

    model = model.toLowerCase();

    if (model.contains("iphone")) {
      deviceMode = DeviceModeEnum.iphone;
    } else if (model.contains("ipad")) {
      deviceMode = DeviceModeEnum.ipad;
    }
  } else if (Platform.isMacOS) {
    deviceMode = DeviceModeEnum.macosDesktop;
  } else if (Platform.isLinux) {
    deviceMode = DeviceModeEnum.linuxDesktop;
  } else if (Platform.isWindows) {
    deviceMode = DeviceModeEnum.windowsDesktop;
  }
}

String formatNumber(double val) {
  if (val == 0) {
    return "";
  }
  return intl.NumberFormat('#,##0.00', 'th_TH').format(val);
}

String formatname(String text) {
  if (text == "sale") {
    return text = "ชื่อลูกค้า   ";
  } else if (text == "purchase") {
    return text = "ชื่อเจ้าหนี้  ";
  }
  return text;
}

String activeLangName(List<LanguageDataModel> names) {
  String res = "";
  for (int i = 0; i < names.length; i++) {
    if (userLanguage == names[i].code) {
      res = names[i].name;
    }
  }
  return res;
}

String branchName() {
  // ชื่อสาขา
  return "สำนักงานใหญ่";
}

String shopType() {
  // ประเภทร้าน
  return "ร้านโซลาว";
}

bool isValidDate(String dateString) {
  try {
    intl.DateFormat('yyyy-MM-dd').parseStrict(dateString);
    return true;
  } catch (e) {
    return false;
  }
}

double calcTextToNumber(String text) {
  double result = 0;
  String textTrim = text.trim();
  while (textTrim.contains(" ")) {
    textTrim = textTrim.replaceAll(" ", "");
  }
  if (textTrim.isNotEmpty) {
    textTrim = textTrim.replaceAll("X", "").replaceAll("x", "").replaceAll("+", "").replaceAll("-", "");
    result = double.parse(textTrim);
  }
  return result;
}

class DataTableHeader {
  String label;
  String code;
  double width;
  TextAlign textAlign;
  Alignment alignment;

  DataTableHeader({
    required this.label,
    required this.code,
    required this.width,
    this.textAlign = TextAlign.left,
    this.alignment = Alignment.centerLeft,
  });
}

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final regExp = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

double calcDiscountFormula({
  required double totalAmount,
  required String discountText,
}) {
  double sumDiscount = 0.0;
  List<String> split = discountText.trim().replaceAll(" ", "").replaceAll(" ", "").split(",");
  for (int index = 0; index < split.length; index++) {
    String discount = split[index];
    double result = 0.0;
    if (discount.contains("%")) {
      // ลด %
      double? percent = double.tryParse(discount.replaceAll("%", ""));
      if (percent != null) {
        result = totalAmount * (percent / 100);
        sumDiscount += result;
        totalAmount -= result;
      }
    } else {
      // ลด จำนวนเงิน
      double? discountMoney = double.tryParse(discount);
      if (discountMoney != null) {
        sumDiscount += discountMoney;
        totalAmount -= discountMoney;
      }
    }
  }
  return sumDiscount;
}

Future<List<LanguageDataModel>> translateNames({
  required List<LanguageDataModel> namesData,
}) async {
  List<LanguageDataModel> result = [];
  for (int i = 0; i < config.languages.length; i++) {
    var translation = await translator.translate(
      namesData[0].name,
      to: config.languages[i].codeTranslator!,
    );
    result.add(
      LanguageDataModel(
        code: config.languages[i].code!,
        name: translation.text,
      ),
    );
  }
  return result;
}

String getDocType(int transflag) {
  String result = "";
  if (transflag == 12) {
    result = "transaction_purchase";
  } else if (transflag == 16) {
    result = "transaction_purchase_return";
  } else if (transflag == 44) {
    result = "transaction_sale";
  } else if (transflag == 48) {
    result = "transaction_sale_return";
  } else if (transflag == 56) {
    result = "transaction_stock_pick_up_product";
  } else if (transflag == 60) {
    result = "transaction_stock_receive_product";
  } else if (transflag == 58) {
    result = "transaction_returnproduct";
  } else if (transflag == 72) {
    result = "transaction_stock_transfer";
  } else if (transflag == 66) {
    result = "stock adjustment";
  } else {
    result = "Trans falg not found";
  }

  return result;
}

Future<Uint8List> fetchNetworkImage(String imageUrl) async {
  final response = await http.get(Uri.parse(imageUrl));
  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw Exception('Failed to load network image');
  }
}

class NumberToWordThai {
  static const String _baht = 'บาท';
  static const String _stang = 'สตางค์';
  static const String _zero = 'ศูนย์'; //0
  static const String _ed = 'เอ็ด'; //1
  static const String _hundred = 'ร้อย'; //100
  static const String _thousand = 'พัน'; //1000
  static const String _tenthousand = 'หมื่น'; //10 000
  static const String _hundredthousand = 'แสน'; //100 000
  static const String _million = 'ล้าน'; //1000 000
  static const String _billion = 'พันล้าน'; //1000 000 000

  ///numNames
  static const List<String> _numNames = [
    '',
    'หนึ่ง',
    'สอง',
    'สาม',
    'สี่',
    'ห้า',
    'หก',
    'เจ็ด',
    'แปด',
    'เก้า',
    'สิบ',
    'สิบเอ็ด',
    'สิบสอง',
    'สิบสาม',
    'สิบสี่',
    'สิบห้า',
    'สิบหก',
    'สิบเจ็ด',
    'สิบแปด',
    'สิบเก้า',
    'ยี่สิบ',
  ];

  ///tensNames
  static const List<String> _tensNames = [
    '',
    'สิบ',
    'ยี่สิบ',
    'สามสิบ',
    'สี่สิบ',
    'ห้าสิบ',
    'หกสิบ',
    'เจ็ดสิบ',
    'แปดสิบ',
    'เก้าสิบ',
  ];

  /// convertLessThanOneThousand
  static String _convertLessThanOneThousand(
    int number, [
    bool isLastThreeDigits = true,
  ]) {
    String soFar = '';

    if (number % 100 <= 20) {
      soFar = _numNames[number % 100];
      number = (number ~/ 100).toInt();
    } else {
      soFar = _numNames[number % 10];
      if (soFar == _numNames[1]) {
        soFar = _ed;
      }
      number = (number ~/ 10).toInt();
      soFar = _tensNames[number % 10] + soFar;
      number = (number ~/ 10).toInt();
    }
    if (number == 0) {
      return soFar;
    }
    return _numNames[number] + _hundred + soFar;
  }

  ///handle converter
  static String convert(double number) {
    Decimal decimalNumber = Decimal.parse(number.toString());
    String formattedNumber = decimalNumber.toStringAsFixed(2);
    if (number == 0) {
      return _zero;
    }

    final String strNumber = formattedNumber.split(".")[0].padLeft(12, '0');

    // XXXnnnnnnnnn
    final int billions = int.parse(strNumber.substring(0, 3));
    // nnnXXXnnnnnn
    final int millions = int.parse(strNumber.substring(3, 6));
    // nnnnnnXXXnnn
    final int hundredThousands = int.parse(strNumber.substring(6, 7));

    final int tenThousands = int.parse(strNumber.substring(7, 8));

    // nnnnnnnnnXXX
    final int thousands = int.parse(strNumber.substring(8, 9));

    // nnnnnnnnnXXX
    final int hundred = int.parse(strNumber.substring(9, 12));

    final int stang = int.parse(formattedNumber.toString().split(".")[1]);

    final String tradBillions = _getBillions(billions);
    String result = tradBillions + ((tradBillions != "") ? _baht : "");

    final String tradMillions = _getMillions(millions);
    result = result + tradMillions + ((tradMillions != "") ? _baht : "");

    final String tradHundredThousands = _getHundredThousands(hundredThousands);
    result = result + tradHundredThousands + ((tradHundredThousands != "") ? _baht : "");

    final String tradTenThousands = _getTenThousands(tenThousands);
    result = result + tradTenThousands + ((tradTenThousands != "") ? _baht : "");

    final String tradThousands = _getThousands(thousands);
    result = result + tradThousands + ((tradThousands != "") ? _baht : "");

    String tradThousand;
    tradThousand = _convertLessThanOneThousand(hundred);
    result = result + tradThousand + ((tradThousand != "") ? _baht : "");

    String tradStang;
    tradStang = _convertLessThanOneThousand(stang, false);
    result = result + tradStang + ((tradStang != "") ? _stang : "ถ้วน");

    // remove extra spaces!
    result = result.replaceAll(RegExp('\\s+'), ' ').replaceAll('\\b\\s{2,}\\b', ' ');
    return result.trim();
  }

  ///get Billions
  static String _getBillions(int billions) {
    String tradBillions;
    switch (billions) {
      case 0:
        tradBillions = '';
        break;
      case 1:
        tradBillions = _convertLessThanOneThousand(billions) + _billion;
        break;
      default:
        tradBillions = _convertLessThanOneThousand(billions) + _billion;
    }
    return tradBillions;
  }

  ///get Millions
  static String _getMillions(int millions) {
    String tradMillions;
    switch (millions) {
      case 0:
        tradMillions = '';
        break;
      case 1:
        tradMillions = _convertLessThanOneThousand(millions) + _million;
        break;
      default:
        tradMillions = _convertLessThanOneThousand(millions) + _million;
    }
    return tradMillions;
  }

  ///get Hundred Thousands
  static String _getHundredThousands(int hundredThousands) {
    String tradHundredThousands;
    switch (hundredThousands) {
      case 0:
        tradHundredThousands = '';
        break;
      case 1:
        tradHundredThousands = _convertLessThanOneThousand(hundredThousands) + _hundredthousand;
        break;
      default:
        tradHundredThousands = _convertLessThanOneThousand(hundredThousands) + _hundredthousand;
    }

    return tradHundredThousands;
  }

  static String _getTenThousands(int tenThousands) {
    String tradTenThousands;
    switch (tenThousands) {
      case 0:
        tradTenThousands = '';
        break;
      case 1:
        tradTenThousands = _convertLessThanOneThousand(tenThousands) + _tenthousand;
        break;
      default:
        tradTenThousands = _convertLessThanOneThousand(tenThousands) + _tenthousand;
    }

    return tradTenThousands;
  }

  static String _getThousands(int hundredThousands) {
    String tradHundredThousands;
    switch (hundredThousands) {
      case 0:
        tradHundredThousands = '';
        break;
      case 1:
        tradHundredThousands = _convertLessThanOneThousand(hundredThousands) + _thousand;
        break;
      default:
        tradHundredThousands = _convertLessThanOneThousand(hundredThousands) + _thousand;
    }

    return tradHundredThousands;
  }
}

int checkDeveloperMode(String environment) {
  switch (environment) {
    case Environment.DEV:
      return 1;
    case Environment.PROD:
      return 0;
    case Environment.UAT:
      return 0;
    case Environment.DOHOME_DEV:
      return 1;
    case Environment.DOHOME_PROD:
      return 0;
    case Environment.DOHOME_UAT:
      return 0;
    default:
      return 1;
  }
}

String docDateTimeFormateDDMMYYY(String docdatetime) {
  DateTime docDateTimeFormatDetail = DateTime.parse(docdatetime);
  if (profileData.yeartype == "buddhist") {
    return dateTimeBuddhist(
      docDateTimeFormatDetail,
      format: DateTimeFormatEnum.date,
    );
  } else {
    return intl.DateFormat('dd/MM/yyyy').format(docDateTimeFormatDetail);
  }
}

enum MainMenuEnum {
  /// Dashboard/Home page
  home,

  /// Customer Relationship Management
  crm,

  /// Sales module
  sell,

  /// Purchase module
  buy,

  /// Inventory/Warehouse management
  inventory,

  /// Delivery/Shipping management
  delivery,

  /// Accounts payable
  payable,

  /// Accounts receivable
  receivable,

  /// Financial management
  finance,

  /// Asset and depreciation management
  asset,

  /// General ledger
  ledger,

  /// Master data management
  master,

  /// System settings
  settings,

  /// Device permissions and management
  permissionDevices,
}

List<LanguageDataModel> convertToLanguageDataList(List<dynamic> names) {
  return names.map((item) {
    if (item is Map<String, dynamic>) {
      return LanguageDataModel(
        code: item['code'] ?? '',
        name: item['name'] ?? '',
      );
    }
    return LanguageDataModel(code: '', name: '');
  }).toList();
}

String getTransFlagText(int flag) {
  switch (flag) {
    case 12:
      return 'ซื้อ';
    case 16:
      return 'ส่งคืน';
    case 44:
      return 'ขาย';
    case 48:
      return 'คืนเงิน';
    case 60:
      return 'รับ';
    case 56:
      return 'เบิก';
    case 58:
      return 'รับคืน';
    case 66:
      return 'ปรับสต็อก';
    case 72:
      return 'โอน';
    default:
      return 'XXX';
  }
}

IconData getTransFlagIcon(int flag) {
  switch (flag) {
    case 56:
      return Icons.shopping_cart_checkout;
    case 58:
      return Icons.assignment_return;
    case 66:
      return Icons.inventory;
    case 72:
      return Icons.swap_horiz;
    default:
      return Icons.add_shopping_cart;
  }
}

Future<Map<String, dynamic>> clickhouseSelect(String query) async {
  var httpClient = http.Client();
  // ปรับให้ใช้ absolute URL เสมอ (ห้ามใช้ localhost/127.0.0.1 บน web)
  String apiPath = myAppConfig.serviceClickhouse;
  if (!apiPath.startsWith('http')) {
    apiPath = 'https://$apiPath';
  }
  var urlString = "$apiPath/select";
  var url = Uri.parse(urlString);

  if (kDebugMode) {
    print("query : $query");
  }
  try {
    var response = await httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"query": query}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        "status": "error",
        "code": response.statusCode,
        "message": "เกิดข้อผิดพลาดในการเรียก API: ${response.reasonPhrase}",
      };
    }
  } catch (e) {
    return {
      "status": "error",
      "code": 500,
      "message": "เกิดข้อผิดพลาดในการเชื่อมต่อ: $e",
    };
  } finally {
    httpClient.close();
  }
}

Future<Map<String, dynamic>> reportServicePost(String jsonCommand) async {
  var httpClient = http.Client();
  // ปรับให้ใช้ absolute URL เสมอ (ห้ามใช้ localhost/127.0.0.1 บน web)
  String apiPath = myAppConfig.reportApiPath;
  if (!apiPath.startsWith('http')) {
    apiPath = 'https://$apiPath';
  }
  var urlString = (myAppConfig.reportApiPort.isNotEmpty) ? "$apiPath:${myAppConfig.reportApiPort}/reportpost" : "$apiPath/reportpost";
  var url = Uri.parse(urlString);

  if (kDebugMode) {
    print("reportServiceCaller : $urlString");
  }
  try {
    var response = await httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(jsonCommand),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        "status": "error",
        "code": response.statusCode,
        "message": "เกิดข้อผิดพลาดในการเรียก API: ${response.reasonPhrase}",
      };
    }
  } catch (e) {
    return {
      "status": "error",
      "code": 500,
      "message": "เกิดข้อผิดพลาดในการเชื่อมต่อ: $e",
    };
  } finally {
    httpClient.close();
  }
}

Future<Map<String, dynamic>> reportServiceGet(
  Map<String, String> jsonCommand,
) async {
  var httpClient = http.Client();
  // ปรับให้ใช้ absolute URL เสมอ (ห้ามใช้ localhost/127.0.0.1 บน web)
  String apiPath = myAppConfig.reportApiPath;
  if (!apiPath.startsWith('http')) {
    apiPath = 'https://$apiPath';
  }
  var urlString = (myAppConfig.reportApiPort.isNotEmpty) ? "$apiPath:${myAppConfig.reportApiPort}/reportget" : "$apiPath/reportget";

  // แปลง jsonCommand เป็น query parameters
  var url = Uri.parse(urlString).replace(queryParameters: jsonCommand);

  if (kDebugMode) {
    print("reportServiceCaller : $url");
  }

  try {
    var response = await httpClient.get(
      url,
      headers: {'Content-Type': 'application/json'},
      // ไม่ต้องใส่ body สำหรับ GET
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        "status": "error",
        "code": response.statusCode,
        "message": "เกิดข้อผิดพลาดในการเรียก API: ${response.reasonPhrase}",
      };
    }
  } catch (e) {
    return {
      "status": "error",
      "code": 500,
      "message": "เกิดข้อผิดพลาดในการเชื่อมต่อ: $e",
    };
  } finally {
    httpClient.close();
  }
}

List<int> decodeResponse(Uint8List responseBodyBytes) {
  var decodedBytes = GZipDecoder().decodeBytes(responseBodyBytes);
  return decodedBytes;
}

Future<Map<String, dynamic>> reportServiceGetBinary(
  Map<String, String> jsonCommand,
) async {
  var httpClient = http.Client();
  // ปรับให้ใช้ absolute URL เสมอ (ห้ามใช้ localhost/127.0.0.1 บน web)
  String apiPath = myAppConfig.reportApiPath;
  if (!apiPath.startsWith('http')) {
    apiPath = 'https://$apiPath';
  }
  var urlString = (myAppConfig.reportApiPort.isNotEmpty) ? "$apiPath:${myAppConfig.reportApiPort}/reportget" : "$apiPath/reportget";

  // แปลง jsonCommand เป็น query parameters
  var url = Uri.parse(urlString).replace(queryParameters: jsonCommand);

  if (kDebugMode) {
    print("reportServiceGetBin : $url");
  }

  try {
    var response = await httpClient.get(
      url,
      headers: {
        'Accept': 'application/octet-stream', // ระบุว่าเราต้องการรับข้อมูลไบนารี่
      },
    );

    if (response.statusCode == 200) {
      // ส่งคืนข้อมูลไบนารี่เป็น Uint8List และข้อมูลเพิ่มเติม
      // unzip
      var bytes = decodeResponse(response.bodyBytes);

      return {
        "status": "success",
        "code": 200,
        "binaryData": bytes,
        "contentType": response.headers["content-type"] ?? "application/octet-stream",
        "contentLength": response.contentLength,
      };
    } else {
      // กรณีเกิดข้อผิดพลาด
      try {
        // ลองแปลงข้อความข้อผิดพลาดเป็น JSON (ถ้ามี)
        var errorResponse = String.fromCharCodes(response.bodyBytes);
        var errorJson = jsonDecode(errorResponse);
        return {
          "status": "error",
          "code": response.statusCode,
          "message": errorJson["message"] ?? "เกิดข้อผิดพลาดในการเรียก API",
          "error": errorJson,
        };
      } catch (e) {
        // ถ้าไม่สามารถแปลงเป็น JSON ได้ ให้ส่งข้อความผิดพลาดปกติ
        return {
          "status": "error",
          "code": response.statusCode,
          "message": "เกิดข้อผิดพลาดในการเรียก API: ${response.reasonPhrase}",
        };
      }
    }
  } catch (e) {
    return {
      "status": "error",
      "code": 500,
      "message": "เกิดข้อผิดพลาดในการเชื่อมต่อ: $e",
    };
  } finally {
    httpClient.close();
  }
}

String googleSignInClientId = "REPLACE_WITH_GOOGLE_CLIENT_ID";
String googleSignInClientSecret = "REPLACE_WITH_GOOGLE_CLIENT_SECRET";

String getShopId() {
  String shopid = appConfig.getString('shopid') ?? "";
  if (shopid.isEmpty) {
    if (kDebugMode) {
      print("shopid is empty, please set it in appConfig");
    }
  }
  return shopid;
}

String getBranchGuidFixed() {
  String branchGuid = appConfig.getString('branch_guidfixed') ?? "";
  if (branchGuid.isEmpty) {
    if (kDebugMode) {
      print("branchGuid is empty, please set it in appConfig");
    }
  }
  return branchGuid;
}

void setShopName(List<LanguageDataModel> languageData) {
  String jsonString = jsonEncode(languageData);
  appConfig.setString('shopname', jsonString);
}

String getShopName() {
  List<LanguageDataModel> languageData = [];
  String shopNameJson = appConfig.getString('shopname') ?? "";
  if (shopNameJson.isNotEmpty) {
    languageData = convertToLanguageDataList(jsonDecode(shopNameJson));
  } else {
    if (kDebugMode) {
      print("shopname is empty, please set it in appConfig");
    }
  }
  String shopName = activeLangName(languageData);
  return shopName;
}

Future<Object> getApiServiceVersion() async {
  var httpClient = http.Client();
  // ปรับให้ใช้ absolute URL เสมอ (ห้ามใช้ localhost/127.0.0.1 บน web)
  String apiPath = myAppConfig.reportApiPath;
  if (!apiPath.startsWith('http')) {
    apiPath = 'https://' + apiPath;
  }
  var urlString = (myAppConfig.reportApiPort.isNotEmpty) ? "${apiPath}:${myAppConfig.reportApiPort}/version" : "${apiPath}/version";

  // แปลง jsonCommand เป็น query parameters
  var url = Uri.parse(urlString).replace(queryParameters: {});

  try {
    var response = await httpClient.get(
      url,
      headers: {'Content-Type': 'application/json'},
      // ไม่ต้องใส่ body สำหรับ GET
    );

    if (response.statusCode == 200) {
      return response.body.toString();
    } else {
      return {
        "status": "error",
        "code": response.statusCode,
        "message": "เกิดข้อผิดพลาดในการเรียก API: ${response.reasonPhrase}",
      };
    }
  } catch (e) {
    return {
      "status": "error",
      "code": 500,
      "message": "เกิดข้อผิดพลาดในการเชื่อมต่อ: $e",
    };
  } finally {
    httpClient.close();
  }
}

String formatNumberRemoveBotttom(double val) {
  if (val == 0) {
    return "";
  }
  // ใช้ '#,##0.##' แทน '#,##0.00' เพื่อให้แสดงทศนิยมเฉพาะเมื่อจำเป็น
  // โดย ## จะแสดงทศนิยมเท่าที่มี โดยไม่แสดงเลข 0 ที่ไม่จำเป็น
  return intl.NumberFormat('#,##0.##', 'th_TH').format(val);
}

enum ProcessState { idle, processing, success, error }

// เพิ่มฟังก์ชันสำหรับอ่าน shop_info จาก local storage
String getShopsIdFromLocalStorage() {
  try {
    String? shopInfoString = appConfig.getString("shop_info");

    if (shopInfoString != null && shopInfoString.isNotEmpty) {
      Map<String, dynamic> shopInfoJson = jsonDecode(shopInfoString);
      ShopModel shopModel = ShopModel.fromJson(shopInfoJson);

      // ถ้า posproductcentertype = 1 ให้ส่งค่า guidfixed และ mainshopid
      if (shopModel.posproductcentertype == 1 && shopModel.guidfixed?.isNotEmpty == true && shopModel.mainshopid?.isNotEmpty == true) {
        return Uri.encodeComponent('${shopModel.guidfixed},${shopModel.mainshopid}');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error reading shop_info: $e');
    }
  }

  return '';
}
