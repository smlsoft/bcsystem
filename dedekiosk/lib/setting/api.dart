import 'dart:convert';
import 'dart:io';
import 'package:dedekiosk/util/client.dart';
import 'package:dedekiosk/util/environment.dart';
import 'package:dedekiosk/model/trans_model.dart';
import 'package:dedekiosk/objectbox/objectbox.g.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dedekiosk/global.dart' as global;
import 'dart:developer' as dev;
import '../model/global_model.dart';

Future<Map<String, dynamic>> returnGetResponse({required String url, bool showData = false}) async {
  if (global.deviceConfig.isdev == '0') {
    Environment().initConfig("PROD");
  } else if (global.deviceConfig.isdev == '1') {
    Environment().initConfig("DEV");
  } else {
    Environment().initConfig("STAGING");
  }
  String endPointService = Environment().config.serviceApi;

  final response = await http.get(Uri.parse(url)).timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      throw Exception('Failed to load data');
    },
  );

  if (response.statusCode == 200) {
    if (showData) {
      dev.log("$endPointService:${response.body}");
    }
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load data');
  }
}

Future<Map<String, dynamic>> serverGetLastDocNumber({
  required String docNumber,
}) async {
  if (global.deviceConfig.isdev == '0') {
    Environment().initConfig("PROD");
  } else if (global.deviceConfig.isdev == '1') {
    Environment().initConfig("DEV");
  } else {
    Environment().initConfig("STAGING");
  }
  String endPointService = Environment().config.serviceApi;
  String url = "$endPointService/e-order/sale-invoice/last-pos-docno?shopid=${global.deviceConfig.shopId}&posid=${global.deviceConfig.orderStationCode}&maxdocno=$docNumber";
  return returnGetResponse(url: url);
}

Future<Map<String, dynamic>> getShopProfileFromServer({required DeviceConfigModel deviceConfig, required String shopId, required String orderStationCode}) async {
  if (deviceConfig.isdev == '0') {
    Environment().initConfig("PROD");
  } else if (deviceConfig.isdev == '1') {
    Environment().initConfig("DEV");
  } else {
    Environment().initConfig("STAGING");
  }
  String endPointService = Environment().config.serviceApi;
  String url = '$endPointService/e-order/shop-info?shopid=$shopId&order-station=$orderStationCode';
  return returnGetResponse(url: url, showData: true);
}

Future<Map<String, dynamic>> getLineNotifyFromServer({
  required DeviceConfigModel deviceConfig,
  required String shopId,
}) async {
  if (deviceConfig.isdev == '0') {
    Environment().initConfig("PROD");
  } else if (deviceConfig.isdev == '1') {
    Environment().initConfig("DEV");
  } else {
    Environment().initConfig("STAGING");
  }
  String endPointService = Environment().config.serviceApi;
  String url = '$endPointService/e-order/notify?shopid=$shopId';
  return returnGetResponse(url: url, showData: true);
}

Future<Map<String, dynamic>> getCategoryFromServer() async {
  if (global.deviceConfig.isdev == '0') {
    Environment().initConfig("PROD");
  } else if (global.deviceConfig.isdev == '1') {
    Environment().initConfig("DEV");
  } else {
    Environment().initConfig("STAGING");
  }
  String endPointService = Environment().config.serviceApi;
  String url = '$endPointService/e-order/category?shopid=${global.deviceConfig.shopId}&group-number=${global.shopProfile!.orderstation.categorygroupnumber}&limit=1000';
  if (kDebugMode) {
    print(url);
  }
  return returnGetResponse(url: url);
}

Future<Map<String, dynamic>> getProductByBarcodeFromServer(List<String> barcode) async {
  if (global.deviceConfig.isdev == '0') {
    Environment().initConfig("PROD");
  } else if (global.deviceConfig.isdev == '1') {
    Environment().initConfig("DEV");
  } else {
    Environment().initConfig("STAGING");
  }
  String endPointService = Environment().config.serviceApi;
  String barcodeStr = "";
  for (int i = 0; i < barcode.length; i++) {
    barcodeStr += '"${barcode[i]}"';
    if (i != barcode.length - 1) {
      barcodeStr += ",";
    }
  }
  String url = '$endPointService/e-order/product-barcode?shopid=${global.deviceConfig.shopId}&barcodes=[$barcodeStr]&limit=10000';
  return returnGetResponse(url: url);
}

Future<Map<String, dynamic>> clickHouseExecute(String query) async {
  if (kDebugMode) {
    print(query);
  }
  String url = 'https://api2.dev.dedepos.com/orderonlineapi/execute';
  Map<String, String> requestBody = {
    'query': query,
  };
  String jsonBody = json.encode(requestBody);
  int count = 0;
  while (count < 10) {
    var response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonBody,
    );
    if (response.statusCode == 200) {
      var responseBody = await json.decode(response.body);
      return responseBody;
    } else {
      if (kDebugMode) {
        print('clickHouseExecute Error executing query. Status code: ${response.statusCode}');
      }
      global.sendErrorToDevTeam("Error clickHouseExecute() query. $count : Status code: ${response.statusCode} : $query");
      await Future.delayed(const Duration(seconds: 1));
    }
    count++;
  }
  global.sendErrorToDevTeam("Error clickHouseExecute() Time out " + query);
  return {};
}

Future<Map<String, dynamic>> clickHouseSelect(String query) async {
  try {
    String url = 'https://api2.dev.dedepos.com/orderonlineapi/select';
    Map<String, String> requestBody = {
      'query': query,
    };
    String jsonBody = json.encode(requestBody);
    var response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonBody,
    );
    if (response.statusCode == 200) {
      var responseBody = await json.decode(response.body);
      return responseBody;
    } else {
      if (kDebugMode) {
        print('clickHouseSelect Error executing query. Status code: ${response.statusCode}');
      }
      global.sendErrorToDevTeam("Error clickHouseSelect() Status code: ${response.statusCode} : $query");
    }
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
      print(s);
    }
    global.sendErrorToDevTeam("Error clickHouseSelect() $e");
  }

  return {};
}

Future<List<OrderTempDetailModel>> getOrderTempFromObjectBox({required String barcode, required int isTakeAway}) async {
  /*String whereBarcode = (barcode.isEmpty) ? "" : " and barcode='$barcode'";
  String query =
      "SELECT orderguid,barcode,qty,optionselected,remark,istakeaway,orderdatetime,isserved,price,amount,machineid FROM ordertemp WHERE shopid='${global.deviceConfig.shopId}' and orderid='${global.tableNumber}' and isclose=0 and istakeaway=$isTakeAway $whereBarcode order by orderdatetime";
  var value = await clickHouseSelect(query);
  ResponseDataModel responseData = ResponseDataModel.fromJson(value);
  List<OrderTempDetailModel> orderTempList = [];
  for (int i = 0; i < responseData.data.length; i++) {
    orderTempList.add(OrderTempDetailModel.fromJson(responseData.data[i]));
  }
  */
  late List<OrderTempObjectBoxModel> data;
  if (barcode.isEmpty) {
    data = global.objectBoxStore.box<OrderTempObjectBoxModel>().query(OrderTempObjectBoxModel_.istakeaway.equals(isTakeAway)).build().find();
  } else {
    data = global.objectBoxStore
        .box<OrderTempObjectBoxModel>()
        .query(OrderTempObjectBoxModel_.barcode.equals(barcode).and(OrderTempObjectBoxModel_.istakeaway.equals(isTakeAway)))
        .build()
        .find();
  }
  List<OrderTempDetailModel> valueReturn = [];
  for (var order in data) {
    if (kDebugMode) {
      print("xxx ${order.orderguid} ${order.barcode} ${order.qty}");
    }
    valueReturn.add(OrderTempDetailModel(
      barcode: order.barcode,
      orderguid: order.orderguid,
      ordertagnumber: "",
      qty: order.qty,
      optionamount: order.optionamount,
      discountamount: order.discountamount,
      optionselected: order.optionselected,
      salechannelcode: order.salechannelcode,
      remark: order.remark,
      orderdatetime: order.orderdatetime,
      price: order.price,
      amount: order.amount,
      istakeaway: order.istakeaway,
      queuenumber: order.queuenumber,
      isserved: 0,
      iscooked: 0,
      iscookcancel: 0,
      isservedcancel: 0,
      machineid: "",
      manufacturerguid: order.manufacturerguid,
      is_except_vat: order.isexceptvat,
    ));
  }

  return valueReturn;
}

Future<List<OrderTempDetailModel>> getAllOrderTempFromServer() async {
  String query =
      "SELECT * FROM ${global.clickHouseDatabaseName}.ordertemp WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderid='${global.orderId}' and (isclose=1 or isclose=2) order by orderdatetime,linenumber";
  var value = await clickHouseSelect(query);
  ResponseDataModel responseData = ResponseDataModel.fromJson(value);
  List<OrderTempDetailModel> orderTempList = [];
  for (int i = 0; i < responseData.data.length; i++) {
    orderTempList.add(OrderTempDetailModel.fromJson(responseData.data[i]));
  }
  return orderTempList;
}

Future<List<OrderTempDetailModel>> getOrderTempFromServerByOrderBarcode({required String barcode, required int isTakeAway}) async {
  String query =
      "SELECT * FROM ${global.clickHouseDatabaseName}.ordertemp WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderid='${global.orderId}' and barcode='$barcode' and isclose=0 and istakeaway=$isTakeAway order by orderdatetime,linenumber";
  var value = await clickHouseSelect(query);
  ResponseDataModel responseData = ResponseDataModel.fromJson(value);
  List<OrderTempDetailModel> orderTempList = [];
  for (int i = 0; i < responseData.data.length; i++) {
    orderTempList.add(OrderTempDetailModel.fromJson(responseData.data[i]));
  }
  return orderTempList;
}

Future<int> getOrderQueueRunningFromServer(String orderId) async {
  int result = 1;
  DateTime now = DateTime.now();
  String query =
      "SELECT runningnumber FROM ${global.clickHouseDatabaseName}.orderqueuerunning WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and toDate(runningdatetime)=makeDate(${now.year}, ${now.month}, ${now.day}) order by runningnumber desc limit 0,1";
  var value = await clickHouseSelect(query);
  ResponseDataModel responseData = ResponseDataModel.fromJson(value);
  if (responseData.data.isNotEmpty) {
    result = responseData.data[0]["runningnumber"] + 1;
  }
  String queryInsert =
      "INSERT INTO ${global.clickHouseDatabaseName}.orderqueuerunning (shopid,branchid,orderid,runningnumber,runningdatetime) VALUES ('${global.deviceConfig.shopId}', '${global.deviceConfig.branchId}', '$orderId', $result,makeDate(${now.year}, ${now.month}, ${now.day}))";
  await clickHouseExecute(queryInsert);
  return result;
}

Future<void> reloadProductProcessFromServer() async {
  if (global.deviceConfig.shopId.isNotEmpty) {
    await global.getBalanceQtyAllFromServer();
    await global.getProductCancelFromServer();
  }
}

Future<ApiResponse> saveTransaction(TransactionModel trx) async {
  Dio client = Client().init();

  //String jsonPayload = jsonEncode(trx.toJson());
  try {
    final response = await client.post('/transaction/sale-invoice', data: trx.toJson());
    try {
      final rawData = json.decode(response.toString());

      //   print(rawData);

      if (rawData['error'] != null) {
        String errorMessage = '${rawData['code']}: ${rawData['message']}';

        throw Exception('${rawData['code']}: ${rawData['message']}');
      }

      return ApiResponse.fromMap(rawData);
    } catch (ex, s) {
      if (kDebugMode) {
        print(ex);
        print(s);
      }

      throw Exception(ex);
    }
  } on DioError catch (ex, s) {
    if (kDebugMode) {
      print(ex);
      print(s);
    }

    String errorMessage = ex.response.toString();

    throw Exception(errorMessage);
  }
}

// Future<ApiResponse> uploadSlip({required String slipPath, required String fileName, required String docNo, required String posId, required String docDate, required String machineCode, required String branchCode, required String zoneGroupNumber}) async {
//   Dio client = Client().init();
//   //String jsonPayload = jsonEncode(trx.toJson());
//   try {
//     var data = FormData.fromMap({
//       'mode': 0,
//       'file': [await MultipartFile.fromFile(slipPath, filename: fileName)],
//       'docno': docNo,
//       'posid': posId,
//       'docdate': docDate,
//       'machinecode': machineCode,
//       'branchcode': branchCode,
//       'zonegroupnumber': zoneGroupNumber
//     });
//     final response = await client.post('/slipimage/', data: data);
//     try {
//       final rawData = json.decode(response.toString());
//       //   print(rawData);
//       if (rawData['error'] != null) {
//         String errorMessage = '${rawData['code']}: ${rawData['message']}';
//         throw Exception('${rawData['code']}: ${rawData['message']}');
//       }
//       return ApiResponse.fromMap(rawData);
//     } catch (ex) {
//       throw Exception(ex);
//     }
//   } on DioError catch (ex, s) {
//     if (kDebugMode) {
//       print(ex);
//       print(s);
//     }

//     String errorMessage = ex.response.toString();
//     throw Exception(errorMessage);
//   }
// }

Future<ApiResponse> getTransactionList({int limit = 1000, int offset = 0, String search = "", String custcode = "", String ispos = "1"}) async {
  Dio client = Client().init();
  try {
    final response = await client.get('/transaction/sale-invoice/list?offset=$offset&limit=$limit&q=$search&custcode=$custcode&ispos=$ispos&sort=docdatetime:-1');
    try {
      final rawData = json.decode(response.toString());

      if (rawData['error'] != null) {
        String errorMessage = '${rawData['code']}: ${rawData['message']}';

        throw Exception('${rawData['code']}: ${rawData['message']}');
      }

      return ApiResponse.fromMap(rawData);
    } catch (ex) {
      throw Exception(ex);
    }
  } on DioError catch (ex, s) {
    if (kDebugMode) {
      print(ex);
      print(s);
    }

    String errorMessage = ex.response.toString();

    throw Exception(errorMessage);
  }
}
