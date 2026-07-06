import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cocomerchant_lite/model/company_branch_model.dart';
import 'package:cocomerchant_lite/model/shop_model.dart';
import 'package:cocomerchant_lite/model/timezones_model.dart';
import 'package:cocomerchant_lite/repositories/company_branch_repository.dart';
import 'package:cocomerchant_lite/repositories/shop_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:cocomerchant_lite/model/config_model.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/price_model.dart';
import 'package:cocomerchant_lite/model/profile_model.dart';
import 'package:cocomerchant_lite/model/theme_model.dart';
import 'package:cocomerchant_lite/repositories/client.dart';
import 'package:cocomerchant_lite/utils/google_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

enum ScreenEventEnum { add, edit, list, display }

enum LoginEnum { none, google, facebook, apple }

String systemLanguage = "th";
String userLanguage = "";
bool developerMode = false;

/// sent isdev mode to  clickhouse
/// 0 = dev , 1 = prod , 2 = uat
int isdevPin = 0;
late List<LanguageSystemModel> languageSystemData;
late List<LanguageSystemCodeModel> languageSystemCode = [];
List<String> googleLanguageCode = [];
ProfileModel profileData = ProfileModel();
GetStorage appConfig = GetStorage('AppConfig');
ConfigModel config = ConfigModel();
int activeIndexMenu = 0;
ThemeModel theme = ThemeModel();
int loadDataPerPage = 500;
ShopModel shopSelectData = ShopModel();
CompanyBranchModel companyBranchSelectData = CompanyBranchModel(
  guidfixed: '',
  code: '',
  businesstype: null,
);
String shopid = "";
List<int> groupNumber = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];

/// timezone list
List<TimezonesModel> timezonesListData = [];

DeviceConfigModel deviceConfig = DeviceConfigModel(
  listDataFontSize: 12,
  listDataLineSpace: 0,
  itemDisplayPrice: true,
  itemDisplaySku: true,
);

final translator = GoogleTranslator();

class SearchCodeNameModel {
  String code;
  List<LanguageDataModel> names;
  bool isCancel;
  SearchCodeNameModel({required this.code, required this.names, this.isCancel = false});
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
    if (developerMode) {
      googleMultiLanguageSheetAppendRow(["pos", code]);
    }
  }
  return (result.trim().isEmpty) ? code : result;
}

Future<List<TimezonesModel>> getTimezonesList(filter) async {
  return timezonesListData;
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

final dateRangeNames = [
  'วันนี้',
  'เมื่อวาน',
  '7 วันย้อนหลัง',
  'สัปดาห์นี้',
  'สัปดาห์ก่อน',
  'เดือนนี้',
  'เดือนก่อน',
  'ปีนี้',
  'ปีก่อน',
  'กำหนดเอง',
];

String getDateRangeName(DateRange dateRange) {
  switch (dateRange) {
    case DateRange.today:
      return dateRangeNames[0];
    case DateRange.yesterday:
      return dateRangeNames[1];
    case DateRange.lastSevenDays:
      return dateRangeNames[2];
    case DateRange.thisWeek:
      return dateRangeNames[3];
    case DateRange.lastWeek:
      return dateRangeNames[4];
    case DateRange.thisMonth:
      return dateRangeNames[5];
    case DateRange.lastMonth:
      return dateRangeNames[6];
    case DateRange.thisYear:
      return dateRangeNames[7];
    case DateRange.lastYear:
      return dateRangeNames[8];
    case DateRange.custom:
      return dateRangeNames[9];
    default:
      return "ไม่ทราบช่วงเวลา";
  }
}

DateRangeModel getDateRange({required DateRange dateRange}) {
  DateTime today = DateTime.now();
  DateTime yesterday = today.subtract(const Duration(days: 1));
  DateTime lastSevenDays = today.subtract(const Duration(days: 7));
  DateTime thisWeek = today.subtract(Duration(days: today.weekday - 1));
  DateTime lastWeek = thisWeek.subtract(const Duration(days: 7));
  DateTime thisMonth = DateTime(today.year, today.month, 1);
  DateTime lastMonth = (today.month > 1) ? DateTime(today.year, today.month - 1, 1) : DateTime(today.year - 1, 12, 1);
  DateTime thisYear = DateTime(today.year, 1, 1);
  DateTime lastYear = DateTime(today.year - 1, 1, 1);

  DateTime endDate = dateRange == DateRange.thisMonth
      ? getLastDayOfMonth(thisMonth)
      : dateRange == DateRange.lastMonth
          ? getLastDayOfMonth(lastMonth)
          : dateRange == DateRange.today
              ? today
              : dateRange == DateRange.yesterday
                  ? yesterday
                  : dateRange == DateRange.lastSevenDays
                      ? today
                      : dateRange == DateRange.thisWeek
                          ? today
                          : dateRange == DateRange.lastWeek
                              ? thisWeek.subtract(const Duration(days: 1))
                              : dateRange == DateRange.thisYear
                                  ? getLastDayOfMonth(DateTime(today.year, 12, 1))
                                  : dateRange == DateRange.lastYear
                                      ? getLastDayOfMonth(DateTime(today.year - 1, 12, 1))
                                      : DateTime(2000, 1, 1);

  return DateRangeModel(
    dateRange: dateRange,
    startDate: dateRange == DateRange.today
        ? today
        : dateRange == DateRange.yesterday
            ? yesterday
            : dateRange == DateRange.lastSevenDays
                ? lastSevenDays
                : dateRange == DateRange.thisWeek
                    ? thisWeek
                    : dateRange == DateRange.lastWeek
                        ? lastWeek
                        : dateRange == DateRange.thisMonth
                            ? thisMonth
                            : dateRange == DateRange.lastMonth
                                ? lastMonth
                                : dateRange == DateRange.thisYear
                                    ? thisYear
                                    : dateRange == DateRange.lastYear
                                        ? lastYear
                                        : DateTime(2000, 1, 1),
    endDate: endDate,
  );
}

DateTime getLastDayOfMonth(DateTime date) {
  DateTime firstDayOfNextMonth = (date.month < 12) ? DateTime(date.year, date.month + 1, 1) : DateTime(date.year + 1, 1, 1);
  return firstDayOfNextMonth.subtract(const Duration(days: 1));
}

String getDayName(DateTime dateTime) {
  switch (dateTime.weekday) {
    case 1:
      return language("Monday");
    case 2:
      return language("Tuesday");
    case 3:
      return language("Wednesday");
    case 4:
      return language("Thursday");
    case 5:
      return language("Friday");
    case 6:
      return language("Saturday");
    case 7:
      return language("Sunday");
  }
  return "";
}

String getMonthName(DateTime dateTime) {
  switch (dateTime.month) {
    case 1:
      return language("January");
    case 2:
      return language("February");
    case 3:
      return language("March");
    case 4:
      return language("April");
    case 5:
      return language("May");
    case 6:
      return language("June");
    case 7:
      return language("July");
    case 8:
      return language("August");
    case 9:
      return language("September");
    case 10:
      return language("October");
    case 11:
      return language("November");
    case 12:
      return language("December");
  }
  return "";
}

String formatFullDate(DateTime date) {
  return '${date.day} ${getMonthName(date)} ${date.year + 543}';
}

Future<void> setSystemLanguage(BuildContext context) async {
  List<LanguageModel> defualtLanguages = [
    LanguageModel(code: "th", codeTranslator: "th", name: "Thai", isuse: false),
    LanguageModel(code: "en", codeTranslator: "en", name: "English", isuse: false),
    LanguageModel(code: "zh", codeTranslator: "zh", name: "Chinese", isuse: false),
    LanguageModel(code: "ja", codeTranslator: "ja", name: "Japanese", isuse: false),
    LanguageModel(code: "ko", codeTranslator: "ko", name: "Korean", isuse: false),
    LanguageModel(code: "lo", codeTranslator: "lo", name: "Lao", isuse: false),
    LanguageModel(code: "my", codeTranslator: "my", name: "Burmese", isuse: false),
    LanguageModel(code: "ms", codeTranslator: "ms", name: "Malaysian", isuse: false),
    LanguageModel(code: "vi", codeTranslator: "vi", name: "Vietnamese", isuse: false),
    LanguageModel(code: "km", codeTranslator: "km", name: "Khmer", isuse: false),
  ];
  config.languages = [];

  ShopRepository shopRepository = ShopRepository();
  CompanyBranchRepository companyBranchRepository = CompanyBranchRepository();
  try {
    ApiResponse result = await shopRepository.loadShopInfo(appConfig.read('shopid'));
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
            LanguageModel(code: "th", codeTranslator: "th", name: "Thai", isuse: true),
          );
        } else if (data.code == "en") {
          config.languages.add(
            LanguageModel(code: "en", codeTranslator: "en", name: "English", isuse: true),
          );
        } else if (data.code == "zh") {
          config.languages.add(
            LanguageModel(code: "zh", codeTranslator: "zh", name: "Chinese", isuse: true),
          );
        } else if (data.code == "ja") {
          config.languages.add(
            LanguageModel(code: "ja", codeTranslator: "ja", name: "Japanese", isuse: true),
          );
        } else if (data.code == "ko") {
          config.languages.add(
            LanguageModel(code: "ko", codeTranslator: "ko", name: "Korean", isuse: true),
          );
        } else if (data.code == "lo") {
          config.languages.add(
            LanguageModel(code: "lo", codeTranslator: "lo", name: "Lao", isuse: true),
          );
        } else if (data.code == "my") {
          config.languages.add(
            LanguageModel(code: "my", codeTranslator: "my", name: "Burmese", isuse: true),
          );
        } else if (data.code == "ms") {
          config.languages.add(
            LanguageModel(code: "ms", codeTranslator: "ms", name: "Malaysian", isuse: true),
          );
        } else if (data.code == "vi") {
          config.languages.add(
            LanguageModel(code: "vi", codeTranslator: "vi", name: "Vietnamese", isuse: true),
          );
        } else if (data.code == "km") {
          config.languages.add(
            LanguageModel(code: "km", codeTranslator: "km", name: "Khmer", isuse: true),
          );
        }
      }

      try {
        ApiResponse resultBranch = await companyBranchRepository.getBranch(appConfig.read("branch_guidfixed"));

        if (resultBranch.success) {
          CompanyBranchModel companyBranchModel = CompanyBranchModel.fromJson(resultBranch.data);
          companyBranchSelectData = companyBranchModel;
        }
      } catch (ex) {
        if (kDebugMode) {
          print(ex);
        }
      }
    }
  } catch (ex) {
    config.languages = defualtLanguages;
    config.languages[0].isuse = true;
    config.vatrate = 7.0;
    config.vattypesale = 0;
    config.vattypepurchase = 0;
    config.inquirytypesale = 0;
    config.inquirytypepurchase = 0;
  }

  config.prices = [
    PriceModel(
      keyNumber: 1,
      isUse: true,
      names: [LanguageModel(code: "th", codeTranslator: "th", name: "ราคาขายปลีก", isuse: true)],
    ),
    PriceModel(
      keyNumber: 2,
      isUse: true,
      names: [LanguageModel(code: "th", codeTranslator: "th", name: "ราคาขายสมาชิก", isuse: true)],
    ),
    PriceModel(
      keyNumber: 3,
      isUse: true,
      names: [LanguageModel(code: "th", codeTranslator: "th", name: "ราคาเดลิเวอรี่", isuse: true)],
    ),
    PriceModel(
      keyNumber: 4,
      isUse: true,
      names: [LanguageModel(code: "th", codeTranslator: "th", name: "ราคาเดลิเวอรี่ 1", isuse: true)],
    ),
    PriceModel(
      keyNumber: 5,
      isUse: true,
      names: [LanguageModel(code: "th", codeTranslator: "th", name: "ราคาเดลิเวอรี่ 2", isuse: true)],
    ),
    PriceModel(
      keyNumber: 6,
      isUse: true,
      names: [LanguageModel(code: "th", codeTranslator: "th", name: "ราคาเดลิเวอรี่ 3", isuse: true)],
    ),
    PriceModel(
      keyNumber: 7,
      isUse: true,
      names: [LanguageModel(code: "th", codeTranslator: "th", name: "ราคาเดลิเวอรี่ 4", isuse: true)],
    ),
    PriceModel(
      keyNumber: 8,
      isUse: true,
      names: [LanguageModel(code: "th", codeTranslator: "th", name: "ราคาเดลิเวอรี่ 5", isuse: true)],
    ),
  ];
}

void showSnackBar(BuildContext context, Icon icon, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: color,
      duration: const Duration(seconds: 3),
      content: (Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Flexible(
            child: Text(message, overflow: TextOverflow.ellipsis),
          ),
        ],
      )),
    ),
  );
}

void themeSelect(int mode) {
  switch (mode) {
    default:
      theme.backgroundColor = Colors.grey[50]!;
      theme.appBarColor = const Color.fromARGB(255, 189, 74, 53);
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
      theme.toolBarEditModeColor = const Color.fromARGB(255, 185, 97, 82);
      break;
  }
}

Color colorFromHex(String hexColor) {
  final hexCode = hexColor.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}

class FieldFocusModel {
  FocusNode focusNode;
  bool isReadOnly;

  FieldFocusModel({required this.focusNode, this.isReadOnly = false});
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

Future<void> deviceConfigSaveJson() async {
  try {
    await appConfig.write("device", jsonEncode(deviceConfig.toJson()));
  } catch (e) {
    // ignore: avoid_print
    print("deviceConfigSaveJson : $e");
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

Future<void> deviceConfigLoad() async {
  try {
    dynamic json = await appConfig.read("device");
    if (json != null) {
      deviceConfig = DeviceConfigModel.fromJson(jsonDecode(json));
    }
  } catch (e) {
    // print(e.toString());
  }
}

String formatNumber(double val) {
  var formatter = NumberFormat('#,###.##');
  return formatter.format(val);
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

class NumberInputFormatter extends TextInputFormatter {
  final int maximumFractionDigits;
  NumberInputFormatter({
    this.maximumFractionDigits = 2,
  }) : assert(maximumFractionDigits >= 0);
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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
      newText = newText.substring(0, newText.indexOf('.') + 1 + maximumFractionDigits);
    }
    if (newValue.text.length == oldValue.text.length - 1 && oldValue.text.substring(newValue.selection.extentOffset, newValue.selection.extentOffset + 1) == ',') {
      // in this case, user deleted the thousands separator, we should delete the digit number before the cursor.
      newText = newText.replaceRange(newValue.selection.extentOffset - 1, newValue.selection.extentOffset, '');
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
        selection: TextSelection.collapsed(offset: math.min(selectionOffset, newText.length)),
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

class SearchGuidCodeNameModel {
  String guid;
  String code;
  List<LanguageDataModel> names;
  bool isCancel;
  SearchGuidCodeNameModel({required this.guid, required this.code, required this.names, this.isCancel = false});
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

bool isValidDate(String dateString) {
  try {
    DateFormat('yyyy-MM-dd').parseStrict(dateString);
    return true;
  } catch (e) {
    return false;
  }
}

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final regExp = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

Future<List<LanguageDataModel>> translateNames({
  required List<LanguageDataModel> namesData,
}) async {
  List<LanguageDataModel> result = [];
  for (int i = 0; i < config.languages.length; i++) {
    var translation = await translator.translate(namesData[0].name, to: config.languages[i].codeTranslator!);
    result.add(LanguageDataModel(code: config.languages[i].code!, name: translation.text));
  }
  return result;
}
