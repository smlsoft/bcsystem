import 'dart:convert';
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dedecashier/global.dart' as global;
import 'package:intl/intl.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

Future<String> clickHouseExecute(String query) async {
  if (!global.isOnline) {
    return "";
  }
  String url = 'https://api2.dev.dedepos.com/orderonlineapi/execute';
  AppLogger.debug(query);
  // Create a Map object with the query field
  Map<String, String> requestBody = {'query': query};

  // Convert the Map to JSON
  String jsonBody = json.encode(requestBody);

  try {
    // Make the HTTP POST request
    var response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonBody,
    );

    if (response.statusCode == 200) {
      // Request successful
      AppLogger.debug('clickHouseExecute : Query executed successfully.');
      // Do something with the response, if needed
      var responseBody = json.decode(response.body);
      return responseBody.toString();
      // ...
    } else {
      // Request failed
      String error =
          'Error executing query. Status code: ${response.statusCode}';
      AppLogger.debug(error);
      global.sendErrorToDevTeam(
        "clickhouse_api->clickHouseExecute",
        "clickHouseExecute : $query $error",
      );
    }
    return "";
  } catch (e, s) {
    AppLogger.error(e);
    global.sendErrorToDevTeam(
      "clickhouse_api->clickHouseExecute",
      "clickHouseExecute : $query $e ${s.toString()}",
    );
    return "";
  }
}

Future<Map<String, dynamic>> clickHouseSelect(String query) async {
  if (!global.isOnline) {
    return {};
  }
  String url = 'https://api2.dev.dedepos.com/orderonlineapi/select';

  // Create a Map object with the query field
  Map<String, String> requestBody = {'query': query};

  // Convert the Map to JSON
  String jsonBody = json.encode(requestBody);

  // Make the HTTP POST request
  var response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonBody,
  );

  if (response.statusCode == 200) {
    // Request successful
    if (kDebugMode) {
      //print(query);
      //AppLogger.success('clickHouseSelect : Query executed successfully.');
    }
    // Do something with the response, if needed
    var responseBody = json.decode(response.body);
    return responseBody;
  } else {
    // Request failed
    AppLogger.debug('Error clickHouseSelect. : ${response.statusCode} $query');
    global.sendErrorToDevTeam(
      "clickhouse_api->clickHouseSelect",
      'Error clickHouseSelect. : ${response.statusCode} $query',
    );
  }
  return {};
}

/// เปิดโต๊ะ
void clickHouseTableUpdate(TableProcessObjectBoxStruct tableData) async {
  AppLogger.debug("clickHouseTableOpen : $tableData");

  {
    /// ลบข้อมูล
    String query =
        "alter table dedeorderonline.tableinfo delete where shopid='${global.shopId}' and qrcode='${tableData.qr_code}'";
    AppLogger.debug(query);
    await clickHouseExecute(query);
  }
  {
    /// เพิ่มข้อมูลใหม่
    String tableOpenDateTime = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(tableData.table_open_datetime);
    String queryinc =
        "INSERT INTO dedeorderonline.tableinfo (shopid, guidfixed, tablenumber, tablename, tablezone, tablestatus, amount, ordersuccess, tableopendatetime, qrcode, mancount, womancount, childcount, tableallacratemode, buffetcode,customerlanguage) VALUES ('${global.shopId}','${tableData.guidfixed}','${tableData.number}','${global.getNameFromJsonLanguage(tableData.names, global.userScreenLanguage)}','${tableData.zone}',${tableData.table_status},${tableData.amount},${(tableData.order_success) ? '1' : '0'},'$tableOpenDateTime','${tableData.qr_code}',${tableData.man_count},${tableData.woman_count},${tableData.child_count},${(tableData.table_al_la_crate_mode) ? '1' : '0'},'${tableData.buffet_code}','${tableData.customer_nationality_code}')";
    AppLogger.debug(queryinc);
    await clickHouseExecute(queryinc);
  }
}

void clickHouseTableUpdateNew(
  TableProcessObjectBoxStruct tableData,
  bool isUpdate,
) async {
  AppLogger.debug("clickHouseTableOpen : $tableData");
  if (!isUpdate) {
    {
      /// ลบข้อมูล
      String query =
          "alter table dedeorderonline.tableinfo delete where shopid='${global.shopId}' and qrcode='${tableData.qr_code}'";
      AppLogger.debug(query);
      await clickHouseExecute(query);
    }
    {
      /// เพิ่มข้อมูลใหม่
      String tableOpenDateTime = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(tableData.table_open_datetime);
      String queryinc =
          "INSERT INTO dedeorderonline.tableinfo (shopid, guidfixed, tablenumber, tablename, tablezone, tablestatus, amount, ordersuccess, tableopendatetime, qrcode, mancount, womancount, childcount, tableallacratemode, buffetcode,customerlanguage) VALUES ('${global.shopId}','${tableData.guidfixed}','${tableData.number}','${global.getNameFromJsonLanguage(tableData.names, global.userScreenLanguage)}','${tableData.zone}',${tableData.table_status},${tableData.amount},${(tableData.order_success) ? '1' : '0'},'$tableOpenDateTime','${tableData.qr_code}',${tableData.man_count},${tableData.woman_count},${tableData.child_count},${(tableData.table_al_la_crate_mode) ? '1' : '0'},'${tableData.buffet_code}','${tableData.customer_nationality_code}')";
      AppLogger.debug(queryinc);
      await clickHouseExecute(queryinc);
    }
  } else {
    String query =
        "alter table dedeorderonline.tableinfo UPDATE mancount=${tableData.man_count}, womancount=${tableData.woman_count}, childcount=${tableData.child_count},tableallacratemode=${(tableData.table_al_la_crate_mode) ? '1' : '0'}, buffetcode='${tableData.buffet_code}',customerlanguage='${tableData.customer_nationality_code}' where shopid='${global.shopId}' and tablenumber='${tableData.number}'";
    AppLogger.debug(query);
    await clickHouseExecute(query);
  }
}
