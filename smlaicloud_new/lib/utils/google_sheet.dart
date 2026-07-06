/*import 'dart:convert';
import 'dart:io';

import 'package:smlaicloud/global.dart' as global;
import 'package:smlaicloud/model/global_model.dart';
import 'package:gsheets/gsheets.dart';

const googleCredentials = r'''
{
  "type": "service_account",
  "project_id": "REPLACE_WITH_GOOGLE_PROJECT_ID",
  "private_key_id": "REPLACE_WITH_PRIVATE_KEY_ID",
  "private_key": "REPLACE_WITH_PRIVATE_KEY",
  "client_email": "REPLACE_WITH_SERVICE_ACCOUNT_EMAIL",
  "client_id": "REPLACE_WITH_CLIENT_ID",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "REPLACE_WITH_CERT_URL"
}
''';

int googleMultilanguageRowMax = 0;

Future<void> googleMultiLanguageSheetAppendRow(List<String> values) async {
  try {
    bool found = false;
    for (var i = 0; i < global.languageSystemCode.length; i++) {
      if (global.languageSystemCode[i].code == values[1]) {
        found = true;
        break;
      }
    }
    if (found == false) {
      global.languageSystemCode.add(
        LanguageSystemCodeModel(
          code: values[1],
          langs: [],
        ),
      );
      final gsheets = GSheets(googleCredentials);
      final spreadsheet = await gsheets.spreadsheet("1HpttLpbcDTHCBhPWw1tuiLmsoap1LFgPS94JarThNoU");
      Worksheet sheet = spreadsheet.worksheetByTitle("language")!;
      await sheet.values.insertRow(++googleMultilanguageRowMax, values);
    }
  } catch (e) {
    print(e);
  }
}

Future<void> googleMultiLanguageSheetLoad() async {
  try {
    final gsheets = GSheets(googleCredentials);
    final spreadsheet = await gsheets.spreadsheet("1HpttLpbcDTHCBhPWw1tuiLmsoap1LFgPS94JarThNoU");
    Worksheet sheet = spreadsheet.worksheetByTitle("language")!;
    print('Google Sheet Successfully Load');
    global.languageSystemCode = [];
    final values = await sheet.values.allRows();
    googleMultilanguageRowMax = values.length;
    for (var i = 0; i < values.length; i++) {
      global.googleLanguageCode.add(values[i][1]);
      int index = 2;
      String thaiText = (index < values[i].length) ? values[i][index++] : "";
      String laoTextAuto = (index < values[i].length) ? values[i][index++] : "";
      String laoTextManual = (index < values[i].length) ? values[i][index++] : "";
      String engTextAuto = (index < values[i].length) ? values[i][index++] : "";
      String engTextManual = (index < values[i].length) ? values[i][index++] : "";
      String zhTextAuto = (index < values[i].length) ? values[i][index++] : "";
      String zhTextManual = (index < values[i].length) ? values[i][index++] : "";
      List<LanguageSystemModel> languageList = [];
      languageList.add(LanguageSystemModel(
        code: 'th',
        text: thaiText,
      ));
      languageList.add(LanguageSystemModel(
        code: 'lo',
        text: (laoTextManual.trim().isEmpty) ? laoTextAuto : laoTextManual,
      ));
      languageList.add(LanguageSystemModel(
        code: 'en',
        text: (engTextManual.trim().isEmpty) ? engTextAuto : engTextManual,
      ));
      languageList.add(LanguageSystemModel(
        code: 'cn',
        text: (zhTextManual.trim().isEmpty) ? zhTextAuto : zhTextManual,
      ));
      global.languageSystemCode.add(
        LanguageSystemCodeModel(
          code: values[i][1],
          langs: languageList,
        ),
      );
    }
  } catch (e) {
    print(e);
  }
}

void createJsonFromGoogleSheet() {
  googleMultiLanguageSheetLoad().then((_) {
    String json = jsonEncode(global.languageSystemCode);
    File file = File('assets/language.json');
    file.writeAsString(json);
  });
}
*/
