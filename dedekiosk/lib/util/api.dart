import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dedekiosk/app_constant.dart';
import 'package:intl/intl.dart';
import 'package:dedekiosk/model/kiosk_list_model.dart';
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
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;
import '../model/global_model.dart';
import 'package:dedekiosk/util/logger.dart';
import 'package:dedekiosk/util/network_helper.dart';

Future<Map<String, dynamic>> returnGetResponse(
    {required String url, bool showData = false}) async {
  if (global.deviceConfig.isdev == '0') {
    Environment().initConfig("PROD");
  } else if (global.deviceConfig.isdev == '1') {
    Environment().initConfig("DEV");
  } else {
    Environment().initConfig("STAGING");
  }
  String endPointService = Environment().config.serviceApi;

  final response = await http.get(Uri.parse(url)).timeout(
    const Duration(seconds: 15),
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

Future<Map<String, dynamic>> getMemberPin(String pin) async {
  try {
    String endPointService = AppConstant.lineApi;
    String url =
        '$endPointService/dedelineoa/getpin?pin=$pin&shopId=${global.deviceConfig.shopId}';
    var response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    ).timeout(
      NetworkTimeouts.standard, // 10 seconds timeout
      onTimeout: () {
        throw TimeoutException('getMemberPin timeout');
      },
    );
    if (response.statusCode == 200) {
      var responseBody = await json.decode(response.body);
      return responseBody;
    } else {
      Logger.d('Error Get Pin. Status code: ${response.statusCode}');
      global.sendErrorToDevTeam(
          "Error getPin() Status code: ${response.statusCode} : $pin");
    }
  } catch (e, s) {
    Logger.e('Error occurred', error: e, stackTrace: s);
    global.sendErrorToDevTeam("Error getMemberPin() $e");
  }

  return {};
}

Future<Map<String, dynamic>> useMemberPin(String pin) async {
  try {
    String endPointService = AppConstant.lineApi;
    String url = '$endPointService/dedelineoa/pin/status?pin=$pin';

    // แปลง body เป็น JSON string
    var body = json.encode({"status": "used"});

    var response = await http.patch(Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body // ส่ง JSON string
        );

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      return responseBody;
    } else {
      Logger.d('Error Update Pin Status. Status code: ${response.statusCode}');
      // global.sendErrorToDevTeam("Error updatePinStatus() Status code: ${response.statusCode} : $pin");
      return {};
    }
  } catch (e, s) {
    Logger.e('Error occurred', error: e, stackTrace: s);
    // global.sendErrorToDevTeam("Error updatePinStatus() $e");
    return {};
  }
}

/// ส่ง receipt ให้ลูกค้าผ่าน LINE
/// POST /dedelineoa/shop/pin/send-receipt
/// Request: { pin, shopId, receiptUrl }
/// Response: { success, message, data: { pin, status, receiptSent, sentAt, customer } }
Future<Map<String, dynamic>> sendReceipt({
  required String pin,
  required String shopId,
  required String receiptUrl,
}) async {
  try {
    String endPointService = AppConstant.lineApi;
    String url = '$endPointService/dedelineoa/shop/pin/send-receipt';

    var body = json.encode({
      "pin": pin,
      "shopId": shopId,
      "receiptUrl": receiptUrl,
    });

    var response = await http
        .post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    )
        .timeout(
      NetworkTimeouts.standard,
      onTimeout: () {
        throw TimeoutException('sendReceipt timeout');
      },
    );

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      Logger.d('sendReceipt success: pin=$pin, response=$responseBody');
      return responseBody;
    } else {
      // Handle different error status codes
      var errorBody = {};
      try {
        errorBody = json.decode(response.body);
      } catch (_) {}

      String errorMsg = errorBody['error'] ?? 'Unknown error';
      Logger.d(
          'sendReceipt Error. Status code: ${response.statusCode}, error: $errorMsg');

      // ไม่ส่ง error ไป dev team สำหรับ expected errors (404, 400, 403)
      if (response.statusCode >= 500) {
        global.sendErrorToDevTeam(
            "Error sendReceipt() Status code: ${response.statusCode} : $pin");
      }

      return {
        "success": false,
        "error": errorMsg,
        "statusCode": response.statusCode
      };
    }
  } catch (e, s) {
    Logger.e('sendReceipt error', error: e, stackTrace: s);
    global.sendErrorToDevTeam("Error sendReceipt() $e");
    return {"success": false, "error": e.toString()};
  }
}

/// ร้านขอสร้าง PIN สำหรับสมาชิก
/// POST /dedelineoa/shop/request-pin
/// Response: { success, data: { pin, expiresIn, expiresAt, status } }
Future<Map<String, dynamic>> shopRequestMemberPin(String shopId) async {
  try {
    String endPointService = AppConstant.lineApi;
    String url = '$endPointService/dedelineoa/shop/request-pin';

    var body = json.encode({"shopId": shopId});

    var response = await http
        .post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    )
        .timeout(
      NetworkTimeouts.standard,
      onTimeout: () {
        throw TimeoutException('shopRequestMemberPin timeout');
      },
    );

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      Logger.d('shopRequestMemberPin success: $responseBody');
      return responseBody;
    } else {
      Logger.d(
          'shopRequestMemberPin Error. Status code: ${response.statusCode}');
      global.sendErrorToDevTeam(
          "Error shopRequestMemberPin() Status code: ${response.statusCode}");
      return {
        "success": false,
        "error": "Request failed with status ${response.statusCode}"
      };
    }
  } catch (e, s) {
    Logger.e('shopRequestMemberPin error', error: e, stackTrace: s);
    global.sendErrorToDevTeam("Error shopRequestMemberPin() $e");
    return {"success": false, "error": e.toString()};
  }
}

/// ร้าน Polling เช็คสถานะ PIN
/// GET /dedelineoa/shop/pin-status?pin=xxxx&shopId=xxxx
/// Response: { success, data: { pin, status, customer?, timeRemaining? } }
Future<Map<String, dynamic>> shopCheckMemberPinStatus(
    String pin, String shopId) async {
  try {
    String endPointService = AppConstant.lineApi;
    String url =
        '$endPointService/dedelineoa/shop/pin-status?pin=$pin&shopId=$shopId';

    var response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    ).timeout(
      NetworkTimeouts.standard,
      onTimeout: () {
        throw TimeoutException('shopCheckMemberPinStatus timeout');
      },
    );

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      return responseBody;
    } else {
      Logger.d(
          'shopCheckMemberPinStatus Error. Status code: ${response.statusCode}');
      return {
        "success": false,
        "error": "Request failed with status ${response.statusCode}"
      };
    }
  } catch (e, s) {
    Logger.e('shopCheckMemberPinStatus error', error: e, stackTrace: s);
    return {"success": false, "error": e.toString()};
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
  String url =
      "$endPointService/e-order/sale-invoice/last-pos-docno?shopid=${global.deviceConfig.shopId}&posid=${global.deviceConfig.orderStationCode}&maxdocno=$docNumber";
  return returnGetResponse(url: url);
}

Future<ApiResponse> getDebtorByCode({
  required String code,
}) async {
  try {
    if (global.deviceConfig.isdev == '0') {
      Environment().initConfig("PROD");
    } else if (global.deviceConfig.isdev == '1') {
      Environment().initConfig("DEV");
    } else {
      Environment().initConfig("STAGING");
    }
    Dio client = Client().init();

    final response = await client.get('/debtaccount/debtor/code/$code');
    try {
      final rawData = json.decode(response.toString());

      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }

      return ApiResponse.fromMap(rawData);
    } catch (ex) {
      ApiResponse apiResponse = ApiResponse(
          error: true, message: ex.toString(), data: {}, success: false);
      return apiResponse;
    }
  } on DioException catch (ex, s) {
    Logger.e('Error occurred', error: ex, stackTrace: s);

    String errorMessage = ex.response.toString();
    ApiResponse apiResponse = ApiResponse(
        error: true, message: errorMessage, data: {}, success: false);
    return apiResponse;
  }
}

Future<ApiResponse> getDebtorByLine({
  required String code,
}) async {
  try {
    if (global.deviceConfig.isdev == '0') {
      Environment().initConfig("PROD");
    } else if (global.deviceConfig.isdev == '1') {
      Environment().initConfig("DEV");
    } else {
      Environment().initConfig("STAGING");
    }
    Dio client = Client().init();

    final response = await client.get('/debtaccount/debtor/line/$code');
    try {
      final rawData = json.decode(response.toString());

      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }

      return ApiResponse.fromMap(rawData);
    } catch (ex) {
      ApiResponse apiResponse = ApiResponse(
          error: true, message: ex.toString(), data: {}, success: false);
      return apiResponse;
    }
  } on DioException catch (ex, s) {
    Logger.e('Error occurred', error: ex, stackTrace: s);

    String errorMessage = ex.response.toString();
    ApiResponse apiResponse = ApiResponse(
        error: true, message: errorMessage, data: {}, success: false);
    return apiResponse;
  }
}

Future<ApiResponse> createDebtor({
  required String code,
  String name = "",
  String email = "",
  String img = "",
}) async {
  try {
    if (global.deviceConfig.isdev == '0') {
      Environment().initConfig("PROD");
    } else if (global.deviceConfig.isdev == '1') {
      Environment().initConfig("DEV");
    } else {
      Environment().initConfig("STAGING");
    }
    Dio client = Client().init();
    var imgdata = img.isNotEmpty
        ? [
            {"uri": img, "xorder": 0}
          ]
        : [];
    var membercode =
        code.substring(code.length - 4) + const Uuid().v4().split('-')[0];
    var data = {
      "addressforbilling": {
        "guid": "",
        "address": [""],
        "countrycode": "",
        "provincecode": "",
        "districtcode": "",
        "subdistrictcode": "",
        "zipcode": "",
        "contactnames": [
          {"code": "th", "name": ""},
          {"code": "en", "name": ""},
          {"code": "ko", "name": ""}
        ],
        "phoneprimary": "",
        "phonesecondary": "",
        "latitude": 0,
        "longitude": 0
      },
      "pointscode": membercode.toUpperCase(),
      "line": {
        "clientids": [],
        "lineid": global.lineDestination,
        "lineuid": code
      },
      "addressforshipping": [],
      "branchnumber": global.shopProfile!.orderstation.branch.code ?? '',
      "code": membercode.toUpperCase(),
      "email": email,
      "groups": [],
      "images": imgdata,
      "names": [
        {"code": "th", "name": name},
        {"code": "en", "name": name},
      ],
      "personaltype": 1,
      "customertype": 1,
      "taxid": "",
      "guidfixed": "",
      "fundcode": "",
      "creditday": 0,
      "ismember": true
    };

    final response = await client.post('/debtaccount/debtor/', data: data);
    try {
      final rawData = json.decode(response.toString());

      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }
      global.memberCode = membercode.toUpperCase();
      global.memberPointsCode = membercode.toUpperCase();
      return ApiResponse.fromMap(rawData);
    } catch (ex) {
      ApiResponse apiResponse = ApiResponse(
          error: true, message: ex.toString(), data: {}, success: false);
      return apiResponse;
    }
  } on DioException catch (ex, s) {
    Logger.e('Error occurred', error: ex, stackTrace: s);

    String errorMessage = ex.response.toString();
    ApiResponse apiResponse = ApiResponse(
        error: true, message: errorMessage, data: {}, success: false);
    return apiResponse;
  }
}

Future<Map<String, dynamic>> getShopProfileFromServer(
    {required DeviceConfigModel deviceConfig,
    required String shopId,
    required String orderStationCode}) async {
  if (deviceConfig.isdev == '0') {
    Environment().initConfig("PROD");
  } else if (deviceConfig.isdev == '1') {
    Environment().initConfig("DEV");
  } else {
    Environment().initConfig("STAGING");
  }
  String endPointService = Environment().config.serviceApi;
  String url =
      '$endPointService/e-order/shop-info?shopid=$shopId&order-station=$orderStationCode';
  return returnGetResponse(url: url, showData: true);
}

Future<ApiResponse> authenUser(String userName, String shopid) async {
  if (global.deviceConfig.isdev == '0') {
    Environment().initConfig("PROD");
  } else if (global.deviceConfig.isdev == '1') {
    Environment().initConfig("DEV");
  } else {
    Environment().initConfig("STAGING");
  }
  Dio client = Client().init();

  try {
    final response = await client
        .post('/poslogin', data: {"username": userName, "shopid": shopid});
    try {
      final result = json.decode(response.toString());
      final rawData = {"success": result["success"], "data": result};

      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }

      return ApiResponse.fromMap(rawData);
    } catch (ex) {
      throw Exception(ex);
    }
  } on DioException catch (ex, s) {
    Logger.e('Error occurred', error: ex, stackTrace: s);

    String errorMessage = ex.response.toString();

    throw Exception(errorMessage);
  }
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
  String url =
      '$endPointService/e-order/category?shopid=${global.deviceConfig.shopId}&group-number=${global.shopProfile!.orderstation.categorygroupnumber}&limit=1000';
  Logger.d(url);
  return returnGetResponse(url: url);
}

Future<Map<String, dynamic>> getProductByBarcodeFromServer(
    List<String> barcode) async {
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
  String url =
      '$endPointService/e-order/product-barcode?shopid=${global.deviceConfig.shopId}&barcodes=[$barcodeStr]&limit=10000';
  return returnGetResponse(url: url);
}

/// บันทึก session เปิดโต๊ะ Order Online เข้า ClickHouse
Future<void> insertOrderTableSession({
  required String uuid,
  required String tableNumber,
}) async {
  if (global.shopProfile == null) return;

  String serviceApi;
  if (global.deviceConfig.isdev == '0') {
    serviceApi = AppConstant.serviceApi;
  } else if (global.deviceConfig.isdev == '1') {
    serviceApi = AppConstant.serviceDevApi;
  } else {
    serviceApi = AppConstant.serviceUatApi;
  }

  // escape single quotes เพื่อป้องกัน SQL injection จาก token/shopid
  String token = global.deviceConfig.token.replaceAll("'", "''");
  String shopId = global.deviceConfig.shopId.replaceAll("'", "''");
  String branchId = global.deviceConfig.branchId.replaceAll("'", "''");
  String tableNum = tableNumber.replaceAll("'", "''");
  int categoryGroupNumber =
      global.shopProfile!.orderstation.categorygroupnumber;
  String isdev = global.deviceConfig.isdev;
  String nowStr = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

  String orderStationCode =
      global.deviceConfig.orderStationCode.replaceAll("'", "''");

  String query = """
INSERT INTO ${global.clickHouseDatabaseName}.ordertable_session
  (uuid, shopid, branchid, tablenumber, apitoken, serviceapi, categorygroupnumber, isdev, orderstationcode, status, createddatetime)
VALUES
  ('$uuid', '$shopId', '$branchId', '$tableNum', '$token', '$serviceApi', $categoryGroupNumber, '$isdev', '$orderStationCode', 0, '$nowStr')
""";

  await clickHouseExecute(query);
}

/// อัปเดต apitoken ในทุก session ที่ยังเปิดอยู่ (status=0) ของ shop/branch นี้
/// เพื่อให้ bcorderkiosk (web) ใช้ token ล่าสุดเสมอ
/// เรียกจาก registerDeviceToServer() ทุก 20 วินาที
Future<void> refreshSessionTemplate() async {
  if (global.shopProfile == null) return;
  if (global.deviceConfig.token.isEmpty) return;
  if (global.deviceConfig.shopId.isEmpty) return;

  String token = global.deviceConfig.token.replaceAll("'", "''");
  String shopId = global.deviceConfig.shopId.replaceAll("'", "''");
  String branchId = global.deviceConfig.branchId.replaceAll("'", "''");

  try {
    await clickHouseExecute(
      "ALTER TABLE ${global.clickHouseDatabaseName}.ordertable_session UPDATE apitoken='$token' WHERE shopid='$shopId' AND branchid='$branchId' AND status=0",
    );
  } catch (e) {
    // non-fatal — silently ignore
  }
}

Future<Map<String, dynamic>> clickHouseExecute(String query) async {
  String url = 'https://api2.dev.dedepos.com/orderonlineapi/execute';
  Map<String, String> requestBody = {
    'query': query,
  };
  String jsonBody = json.encode(requestBody);
  int count = 0;
  const int maxRetries = 3; // ลดจาก 10 เป็น 3

  while (count < maxRetries) {
    try {
      var response = await http
          .post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      )
          .timeout(
        NetworkTimeouts.standard, // 10 seconds timeout
        onTimeout: () {
          throw TimeoutException('clickHouseExecute timeout');
        },
      );

      if (response.statusCode == 200) {
        var responseBody = await json.decode(response.body);
        return responseBody;
      } else {
        if (kDebugMode) {
          print(
              'clickHouseExecute Error executing query. Status code: ${response.statusCode}');
          print(query);
        }
        global.sendErrorToDevTeam(
            "Error clickHouseExecute() query. $count : Status code: ${response.statusCode} : $query");

        // ถ้าไม่ใช่ครั้งสุดท้าย ให้ delay ก่อน retry
        if (count < maxRetries - 1) {
          await Future.delayed(
              Duration(seconds: count + 1)); // Exponential backoff
        }
      }
    } catch (e, s) {
      Logger.e('clickHouseExecute error on attempt ${count + 1}/$maxRetries',
          error: e, stackTrace: s);

      if (count >= maxRetries - 1) {
        // ครั้งสุดท้ายแล้ว ส่ง error และ return
        global.sendErrorToDevTeam(
            "Error clickHouseExecute() timeout after $maxRetries retries: $query");
        return {};
      }

      // Exponential backoff
      await Future.delayed(Duration(seconds: count + 1));
    }
    count++;
  }

  return {};
}

Future<Map<String, dynamic>> clickHouseSelect(String query) async {
  const int maxRetries = 2; // Retry 2 times for SELECT queries
  int attempt = 0;

  while (attempt < maxRetries) {
    try {
      String url = 'https://api2.dev.dedepos.com/orderonlineapi/select';
      Map<String, String> requestBody = {
        'query': query,
      };
      String jsonBody = json.encode(requestBody);

      var response = await http
          .post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      )
          .timeout(
        NetworkTimeouts.standard, // 10 seconds timeout
        onTimeout: () {
          throw TimeoutException('clickHouseSelect timeout');
        },
      );

      if (response.statusCode == 200) {
        var responseBody = await json.decode(response.body);
        return responseBody;
      } else {
        Logger.d(
            'clickHouseSelect Error executing query. Status code: ${response.statusCode}');
        global.sendErrorToDevTeam(
            "Error clickHouseSelect() Status code: ${response.statusCode} : $query");

        // ถ้าไม่ใช่ครั้งสุดท้าย ให้ retry
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: attempt + 1));
        }
      }
    } catch (e, s) {
      Logger.e('clickHouseSelect error on attempt ${attempt + 1}/$maxRetries',
          error: e, stackTrace: s);

      if (attempt >= maxRetries - 1) {
        // ครั้งสุดท้ายแล้ว
        global.sendErrorToDevTeam(
            "Error clickHouseSelect() after $maxRetries retries: $e $query");
        return {};
      }

      // Retry with delay
      await Future.delayed(Duration(seconds: attempt + 1));
    }
    attempt++;
  }

  return {};
}

Future<List<OrderTempDetailModel>> getOrderTempFromObjectBox(
    {required String barcode, required int isTakeAway}) async {
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
    data = global.objectBoxStore
        .box<OrderTempObjectBoxModel>()
        .query(OrderTempObjectBoxModel_.istakeaway.equals(isTakeAway))
        .build()
        .find();
  } else {
    data = global.objectBoxStore
        .box<OrderTempObjectBoxModel>()
        .query(OrderTempObjectBoxModel_.barcode
            .equals(barcode)
            .and(OrderTempObjectBoxModel_.istakeaway.equals(isTakeAway)))
        .build()
        .find();
  }
  List<OrderTempDetailModel> valueReturn = [];
  for (var order in data) {
    Logger.d(
        "getOrderTempFromObjectBox: ${order.barcode} - qty=${order.qty}, price=${order.price}, amount=${order.amount}, optionamount=${order.optionamount}");
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

/// ===== Cashier (pay-at-cashier) helpers =====
/// โหลด pending-cashier order จาก ordertemppaylater + ordertempdocpaylater
/// คืน {doc: Map, details: List<OrderTempDetailModel>} หรือ null ถ้าไม่เจอ
/// ===== Cashier (pay-at-cashier) helpers — stub + settle pattern =====
/// pending-cashier = "ใบแจ้งยอด" (stub) ไม่ใช่ order ไม่ reserve stock ไม่ส่งครัว
/// cashier settle = เข้า logic สั่งเต็มรูปแบบผ่าน payAndSave (reserve+commit stock, ส่งครัว, saveTransaction)

/// โหลด stub (cart snapshot) จาก paylater tables ด้วย stubId
/// คืน {doc: Map, details: List<OrderTempDetailModel>} หรือ null ถ้าไม่เจอ/ถูก settle แล้ว
Future<Map<String, dynamic>?> loadCashierStub({
  required String stubId,
}) async {
  final shopId = global.deviceConfig.shopId;
  final branchId = global.deviceConfig.branchId;
  final escapedStub = stubId.replaceAll("'", "''");
  final db = global.clickHouseDatabaseName;

  // 1. โหลด header จาก ordertempdocpaylater (stubId เก็บในคอลัมน์ ordernumber)
  final docQuery = "SELECT * FROM $db.ordertempdocpaylater "
      "WHERE shopid='$shopId' AND branchid='$branchId' "
      "AND ordernumber='$escapedStub' AND orderpaysuccess=0 "
      "ORDER BY orderdatetime DESC LIMIT 1";
  final docResult = await clickHouseSelect(docQuery);
  final docData = docResult['data'] as List<dynamic>?;
  if (docData == null || docData.isEmpty) return null;
  final doc = docData[0] as Map<String, dynamic>;
  final orderId = doc['orderid']?.toString() ?? '';

  // 2. โหลด detail rows จาก ordertemppaylater (cart snapshot)
  final detailQuery = "SELECT * FROM $db.ordertemppaylater "
      "WHERE shopid='$shopId' AND branchid='$branchId' "
      "AND orderid='$orderId' ORDER BY linenumber, orderdatetime";
  final detailResult = await clickHouseSelect(detailQuery);
  final detailData = detailResult['data'] as List<dynamic>? ?? [];
  final details = <OrderTempDetailModel>[];
  for (final row in detailData) {
    details.add(OrderTempDetailModel.fromJson(row as Map<String, dynamic>));
  }

  // กำหนด stubMode จาก isclose ของ detail row แรก
  // 0 = โหมด A (ส่งครัวหลัง settle), 2 = โหมด B (ส่งครัวทันที)
  int stubMode = 0;
  if (detailData.isNotEmpty) {
    final firstRow = detailData[0] as Map<String, dynamic>;
    stubMode = int.tryParse(firstRow['isclose']?.toString() ?? '0') ?? 0;
  }

  return {'doc': doc, 'details': details, 'stubMode': stubMode};
}

/// ตรวจว่า stub ถูก settle แล้วหรือยัง (เพื่อแยก "จ่ายแล้ว" จาก "ไม่มีอยู่จริง")
/// คืน true ถ้ามี order ใน ordertempdoc ที่ ordertagnumber ตรง + ถูกสร้างในช่วงเวลาที่เป็นไปได้
Future<bool> isCashierStubAlreadySettled({required String stubId}) async {
  final shopId = global.deviceConfig.shopId;
  final branchId = global.deviceConfig.branchId;
  final db = global.clickHouseDatabaseName;
  // stub id เก็บใน paylater.ordernumber; หลัง settle, doc no จริงเข้า ordertempdoc.ordernumber
  // เราไม่สามารถ match โดยตรงได้ (doc no เปลี่ยน) — แต่ stub row จะถูก delete ตอน settle
  // ดังนั้น check: ยังมี stub อยู่ใน paylater ไหม?
  final checkQuery = "SELECT count() as cnt FROM $db.ordertempdocpaylater "
      "WHERE shopid='$shopId' AND branchid='$branchId' "
      "AND ordernumber='${stubId.replaceAll("'", "''")}' AND orderpaysuccess=0";
  try {
    final result = await clickHouseSelect(checkQuery);
    final data = result['data'] as List<dynamic>?;
    if (data != null && data.isNotEmpty) {
      final cnt = (data[0] as Map<String, dynamic>)['cnt'];
      return int.tryParse(cnt.toString()) ==
          0; // ไม่มี stub = ถูก settle แล้ว (หรือไม่เคยมี)
    }
  } catch (e) {
    Logger.w('isCashierStubAlreadySettled error: $e', tag: 'CashierStub');
  }
  return false;
}

/// Release stock ที่ orderAdd จองไว้ (ลบ ordertempcalcqty isclose=0 ของ orderid นี้)
/// เรียกตอนสร้าง stub — เพื่อไม่ให้ cart ที่จะไป cashier จองสต็อกค้าง
Future<void> releaseCartStock({required String orderId}) async {
  final shopId = global.deviceConfig.shopId;
  final branchId = global.deviceConfig.branchId;
  final db = global.clickHouseDatabaseName;
  try {
    await clickHouseExecute(
        "alter table $db.ordertempcalcqty delete where shopid='$shopId' AND branchid='$branchId' AND orderid='${orderId.replaceAll("'", "''")}' AND isclose=0");
  } catch (e) {
    Logger.w('releaseCartStock error: $e', tag: 'CashierStub');
  }
}

/// Reserve stock ใหม่ตอน cashier settle (INSERT ordertempcalcqty isclose=0 ด้วย orderId ใหม่)
/// เลียนแบบ order_util.dart:328-329 แต่รับ list ของ items + orderId ที่กำหนด
Future<void> reserveCartStock({
  required String orderId,
  required List<OrderTempDetailModel> items,
}) async {
  final shopId = global.deviceConfig.shopId;
  final branchId = global.deviceConfig.branchId;
  final deviceId = global.deviceConfig.orderStationCode;
  final db = global.clickHouseDatabaseName;
  for (final item in items) {
    try {
      await clickHouseExecute(
          "insert into $db.ordertempcalcqty (shopid,branchid,deviceid,orderid,orderguid,orderdatetime,barcode,isclose,qty,manufacturerguid) "
          "values ('$shopId','$branchId','$deviceId','${orderId.replaceAll("'", "''")}','${item.orderguid.replaceAll("'", "''")}',now(),'${item.barcode.replaceAll("'", "''")}',0,${item.qty * -1},'${(item.manufacturerguid ?? '').replaceAll("'", "''")}')");
    } catch (e) {
      Logger.w('reserveCartStock item ${item.barcode} error: $e',
          tag: 'CashierStub');
    }
  }
}

/// Consume stub — ลบ rows จาก paylater tables (เรียกหลัง settle สำเร็จ)
/// NOTE: ลบ DETAIL ก่อน HEADER เพราะ detail delete ใช้ subquery หา orderid จาก header
/// (ถ้าลบ header ก่อน subquery จะหา orderid ไม่เจอ → detail ตกค้าง)
Future<void> deleteCashierStub({required String stubId}) async {
  final shopId = global.deviceConfig.shopId;
  final branchId = global.deviceConfig.branchId;
  final db = global.clickHouseDatabaseName;
  final escapedStub = stubId.replaceAll("'", "''");
  // 1. DETAIL ก่อน (ใช้ subquery หา orderid จาก header ที่ยังอยู่)
  try {
    await clickHouseExecute(
        "alter table $db.ordertemppaylater delete where shopid='$shopId' AND branchid='$branchId' AND orderid IN (SELECT orderid FROM $db.ordertempdocpaylater WHERE shopid='$shopId' AND branchid='$branchId' AND ordernumber='$escapedStub')");
  } catch (e) {
    Logger.w('deleteCashierStub detail error: $e', tag: 'CashierStub');
  }
  // 2. HEADER ทีหลัง
  try {
    await clickHouseExecute(
        "alter table $db.ordertempdocpaylater delete where shopid='$shopId' AND branchid='$branchId' AND ordernumber='$escapedStub' AND orderpaysuccess=0");
  } catch (e) {
    Logger.w('deleteCashierStub doc error: $e', tag: 'CashierStub');
  }
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

Future<List<OrderTempDetailModel>> getOrderTempFromServerByOrderBarcode(
    {required String barcode, required int isTakeAway}) async {
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

Future<int> getOrderQueueRunningFromServer(String orderId,
    {int minQueueNumber = 0}) async {
  int result = 1;
  DateTime now = DateTime.now();
  String query =
      "SELECT runningnumber FROM ${global.clickHouseDatabaseName}.orderqueuerunning WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and toDate(runningdatetime)=makeDate(${now.year}, ${now.month}, ${now.day}) order by runningnumber desc limit 0,1";
  var value = await clickHouseSelect(query);
  ResponseDataModel responseData = ResponseDataModel.fromJson(value);
  if (responseData.data.isNotEmpty) {
    result = responseData.data[0]["runningnumber"] + 1;
  }
  if (result <= minQueueNumber) {
    result = minQueueNumber + 1;
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
  if (global.deviceConfig.isdev == '0') {
    Environment().initConfig("PROD");
  } else if (global.deviceConfig.isdev == '1') {
    Environment().initConfig("DEV");
  } else {
    Environment().initConfig("STAGING");
  }
  Dio client = Client().init();

  //String jsonPayload = jsonEncode(trx.toJson());
  try {
    final response =
        await client.post('/transaction/sale-invoice', data: trx.toJson());
    try {
      final rawData = json.decode(response.toString());

      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }
      return ApiResponse.fromMap(rawData);
    } catch (ex, s) {
      Logger.e('Error occurred', error: ex, stackTrace: s);

      throw Exception(ex);
    }
  } on DioException catch (ex, s) {
    Logger.e('Error occurred', error: ex, stackTrace: s);

    String errorMessage = ex.response.toString();

    throw Exception(errorMessage);
  }
}

/// Returns true if token is valid, false only on 401 (Token Invalid).
/// Network errors are treated as valid to avoid false alarms.
Future<bool> checkTokenHealth() async {
  if (global.deviceConfig.token.isEmpty) return false;
  try {
    Dio client = Client().init();
    await client.get('/profile');
    return true;
  } on DioException catch (ex) {
    if (ex.response?.statusCode == 401) return false;
    return true;
  } catch (_) {
    return true;
  }
}

Future<ApiResponse> updateDevice(KioskListModel kiosk) async {
  if (global.deviceConfig.isdev == '0') {
    Environment().initConfig("PROD");
  } else if (global.deviceConfig.isdev == '1') {
    Environment().initConfig("DEV");
  } else {
    Environment().initConfig("STAGING");
  }
  Dio client = Client().init();

  //String jsonPayload = jsonEncode(trx.toJson());
  try {
    final response = await client.put('/order/device/${kiosk.guidfixed}',
        data: kiosk.toJson());
    try {
      final rawData = json.decode(response.toString());

      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }
      return ApiResponse.fromMap(rawData);
    } catch (ex, s) {
      Logger.e('Error occurred', error: ex, stackTrace: s);

      throw Exception(ex);
    }
  } on DioException catch (ex, s) {
    Logger.e('Error occurred', error: ex, stackTrace: s);

    String errorMessage = ex.response.toString();

    throw Exception(errorMessage);
  }
}

Future<ApiResponse> uploadSlip(
    {required int mode,
    required String slipPath,
    required String fileName,
    required String docNo,
    required String posId,
    required String docDate,
    required String machineCode,
    required String branchCode,
    required String zoneGroupNumber}) async {
  try {
    var data = FormData.fromMap({
      'mode': mode, // 0=slip image, 1= qr payment image
      'file': [await MultipartFile.fromFile(slipPath, filename: fileName)],
      'docno': docNo,
      'posid': posId,
      'docdate': docDate,
      'machinecode': machineCode,
      'branchcode': branchCode,
      'zonegroupnumber': zoneGroupNumber
    });
    if (global.deviceConfig.isdev == '0') {
      Environment().initConfig("PROD");
    } else if (global.deviceConfig.isdev == '1') {
      Environment().initConfig("DEV");
    } else {
      Environment().initConfig("STAGING");
    }
    Dio client = Client().init();
    final response = await client.post('/slipimage/', data: data);
    try {
      final rawData = json.decode(response.toString());
      //   print(rawData);
      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }
      return ApiResponse.fromMap(rawData);
    } catch (ex) {
      throw Exception(ex);
    }
  } on DioException catch (ex, s) {
    Logger.e('Error occurred', error: ex, stackTrace: s);

    String errorMessage = ex.response.toString();
    throw Exception(errorMessage);
  }
}

Future<ApiResponse> getTransactionList({
  int limit = 60,
  int offset = 0,
  String search = "",
  String custcode = "",
  String ispos = "1",
  DateTime? fromDate,
  DateTime? toDate,
}) async {
  try {
    Dio client = Client().init();
    final Map<String, dynamic> queryParams = {
      'offset': offset,
      'limit': limit,
      'q': search,
      'custcode': custcode,
      'ispos': ispos,
      'sort': 'docdatetime:-1',
    };

    if (fromDate != null) {
      queryParams['fromdate'] = fromDate.toUtc().toIso8601String();
    }
    if (toDate != null) {
      queryParams['todate'] = toDate.toUtc().toIso8601String();
    }

    final response = await client.get(
      '/transaction/sale-invoice',
      queryParameters: queryParams,
    );
    try {
      final rawData = json.decode(response.toString());

      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }

      return ApiResponse.fromMap(rawData);
    } catch (ex) {
      throw Exception(ex);
    }
  } on DioException catch (ex, s) {
    Logger.e('Error occurred', error: ex, stackTrace: s);

    String errorMessage = ex.response.toString();

    throw Exception(errorMessage);
  }
}

/// BC Member: ขอ code สำหรับ login ผ่าน LINE (deprecated - ใช้ getBCMemberQRSession แทน)
/// POST {bcmemberurl}/api/login/code
Future<Map<String, dynamic>> getBCMemberLoginCode(String shopId) async {
  try {
    final apiKey = global.shopProfile?.apikey ?? '';
    final response = await http
        .post(
      Uri.parse('${AppConstant.bcmemberurl}/api/login/code'),
      headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
      body: jsonEncode({'shop_id': shopId}),
    )
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Connection timeout');
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get login code: ${response.statusCode}');
    }
  } catch (e) {
    Logger.e('getBCMemberLoginCode error', error: e);
    rethrow;
  }
}

/// BC Member: สร้าง QR Session สำหรับ login ผ่าน LINE LIFF (Kiosk - พร้อมดึง point_balance)
/// POST {bcmemberurl}/api/member/qr
/// Response: { success, session_id, liff_url, shop_id, expires_at }
Future<Map<String, dynamic>> getBCMemberQRSession(String shopId) async {
  try {
    final apiKey = global.shopProfile?.apikey ?? '';
    final response = await http
        .post(
      Uri.parse('${AppConstant.bcmemberurl}/api/member/qr'),
      headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
      body: jsonEncode({'shop_id': shopId}),
    )
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Connection timeout');
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get QR session: ${response.statusCode}');
    }
  } catch (e) {
    Logger.e('getBCMemberQRSession error', error: e);
    rethrow;
  }
}

/// BC Member: เช็ค status ของ QR session (Kiosk - พร้อม point_balance)
/// GET {bcmemberurl}/api/member/qr?session=xxx
/// Response: { success, status, line_user_id, display_name, picture_url, point_balance }
Future<Map<String, dynamic>> getBCMemberLoginStatus(String sessionId) async {
  try {
    final apiKey = global.shopProfile?.apikey ?? '';
    final response = await http.get(
      Uri.parse('${AppConstant.bcmemberurl}/api/member/qr?session=$sessionId'),
      headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Connection timeout');
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get login status: ${response.statusCode}');
    }
  } catch (e) {
    Logger.e('getBCMemberLoginStatus error', error: e);
    rethrow;
  }
}

/// BC Member: คำนวณแต้มที่จะได้รับจาก API
/// GET {bcmemberurl}/api/calculate-point?amount=500&line_uid=U123&use_point=10
/// Response: { success, amount, get_point, use_point, use_point_valid, member_balance, shop }
/// Error Response: { success: false, error, get_point: 0, point_balance: 0, min_amount: 0, max_points_per_tx: 0, redeem_rate: 0 }
Future<Map<String, dynamic>> calculateBCMemberPoint({
  required double amount,
  required String lineUid,
  double usePoint = 0,
}) async {
  try {
    final apiKey = global.shopProfile?.apikey ?? '';
    final uri = Uri.parse('${AppConstant.bcmemberurl}/api/calculate-point')
        .replace(queryParameters: {
      'amount': amount.toString(),
      'line_uid': lineUid,
      'use_point': usePoint.toString(),
    });

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('calculateBCMemberPoint timeout');
      },
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      Logger.d(
          'calculateBCMemberPoint success: amount=$amount, lineUid=$lineUid, response=$result');
      return result;
    } else {
      Logger.w('calculateBCMemberPoint failed: ${response.statusCode}');
      // Return error response format
      return {
        'success': false,
        'error': 'API request failed: ${response.statusCode}',
        'get_point': 0,
        'point_balance': 0,
      };
    }
  } catch (e) {
    Logger.e('calculateBCMemberPoint error', error: e);
    return {
      'success': false,
      'error': e.toString(),
      'get_point': 0,
      'point_balance': 0,
    };
  }
}

/// BC Member: ส่งข้อมูล Sale Invoice พร้อมคำนวณแต้ม
/// POST {bcmemberurl}/api/saleinvoice
/// Request: { line_uid, doc_no, amount, use_point, display_name, picture_url }
/// Response: { success, message, data: { doc_no, point_balance } }
Future<Map<String, dynamic>> sendBCMemberSaleInvoice({
  required String lineUid,
  required String docNo,
  required double amount,
  double usePoint = 0,
  String displayName = '',
  String pictureUrl = '',
}) async {
  try {
    final apiKey = global.shopProfile?.apikey ?? '';
    final body = <String, dynamic>{
      'line_uid': lineUid,
      'doc_no': docNo,
      'amount': amount,
      'use_point': usePoint,
    };
    if (displayName.isNotEmpty) body['display_name'] = displayName;
    if (pictureUrl.isNotEmpty) body['picture_url'] = pictureUrl;
    final response = await http
        .post(
      Uri.parse('${AppConstant.bcmemberurl}/api/saleinvoice'),
      headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
      body: jsonEncode(body),
    )
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('sendBCMemberSaleInvoice timeout');
      },
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      Logger.d(
          'sendBCMemberSaleInvoice success: docNo=$docNo, response=$result');
      return result;
    } else {
      Logger.w('sendBCMemberSaleInvoice failed: ${response.statusCode}');
      throw Exception('Failed to send sale invoice: ${response.statusCode}');
    }
  } catch (e) {
    Logger.e('sendBCMemberSaleInvoice error', error: e);
    rethrow;
  }
}

/// BC Member: ส่ง receipt ผ่าน LINE
/// POST {bcmemberurl}/api/send-receipt
/// Response: { success, message }
Future<Map<String, dynamic>> sendBCMemberReceipt({
  required String lineUid,
  required String imageUrl,
}) async {
  try {
    final apiKey = global.shopProfile?.apikey ?? '';
    final response = await http
        .post(
      Uri.parse('${AppConstant.bcmemberurl}/api/send-receipt'),
      headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
      body: jsonEncode({
        'line_uid': lineUid,
        'image_url': imageUrl,
      }),
    )
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('sendBCMemberReceipt timeout');
      },
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      Logger.d('sendBCMemberReceipt success: lineUid=$lineUid');
      return result;
    } else {
      Logger.w('sendBCMemberReceipt failed: ${response.statusCode}');
      throw Exception('Failed to send receipt: ${response.statusCode}');
    }
  } catch (e) {
    Logger.e('sendBCMemberReceipt error', error: e);
    rethrow;
  }
}
