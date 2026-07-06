import 'dart:convert';
import 'dart:io';
import 'package:dedeorder/global.dart' as global;
import 'package:dedeorder/global_model.dart';
import 'package:dedeorder/model/buffet_mode_model.dart';
import 'package:dedeorder/model/category_model.dart';
import 'package:dedeorder/model/global_model.dart';
import 'package:dedeorder/model/order_temp_model.dart';
import 'package:dedeorder/model/pos_hold_process_model.dart';
import 'package:dedeorder/model/pos_process_model.dart';
import 'package:dedeorder/model/product_model.dart';
import 'package:dedeorder/model/table_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class HttpPost {
  late String command;
  late String data;

  HttpPost({required this.command, this.data = ""});

  Map toJson() => {
        'command': command,
        'data': data,
      };

  factory HttpPost.fromJson(Map<String, dynamic> json) {
    return HttpPost(
      command: json['command'],
      data: json['data'],
    );
  }
}

Future<String> getFromServer({required String json}) async {
  final base64String = base64Encode(utf8.encode(json));
  // String url = "$httpServerIp:$httpServerPort?data=$base64String";

  String url = "${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  final response = await http.get(Uri.http(url, '/', {'json': base64String}), headers: {"Content-Type": "application/json", "Cache-Control": "no-cache", "Accept": "text/event-stream"});
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to load data');
  }
}

Future<String> ipAddress() async {
  // Get a list of the network interfaces available on the device
  List<NetworkInterface> interfaces = await NetworkInterface.list();

  // Iterate through the list of interfaces and return the first non-loopback IPv4 address
  for (NetworkInterface interface in interfaces) {
    if (interface.name == 'lo') continue; // Skip the loopback interface
    for (InternetAddress address in interface.addresses) {
      if (address.type == InternetAddressType.IPv4) {
        return address.address;
      }
    }
  }

  // If no non-loopback IPv4 address was found, return null
  return "";
}

Future<String> insertTicketToTerminal(TableProcessObjectBoxStruct ticket) async {
  String result = "";
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.insert_delivery_ticket',
        'data': jsonEncode(ticket.toJson()),
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("Insert success");
    }
    result = response.body;
  } else {
    if (kDebugMode) {
      print("Insert failed");
    }
  }
  return result;
}

Future<String> registerStaffClientToServer({required String serverIpAddress, required String connectCode}) async {
  String result = "";
  if (serverIpAddress.isNotEmpty) {
    var newGuid = const Uuid().v4();
    var url = "http://$serverIpAddress:${global.posTerminalDevicePort}";
    var uri = Uri.parse(url);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("client_guid", newGuid);
    try {
      SyncStaffDeviceModel sendData = SyncStaffDeviceModel(clientGuid: newGuid, clientName: global.machineName, clientIp: await ipAddress(), securityCode: connectCode);
      var jsonEncodeStr = jsonEncode(sendData.toJson());
      var response = await http
          .post(uri,
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(<String, String>{
                'command': 'register_staff_device',
                'data': jsonEncodeStr,
              }))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("Register staff device success");
        }
        result = response.body;
      } else {
        if (kDebugMode) {
          print("Register staff device failed");
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
      }
      global.sendErrorToDevTeam("registerStaffClientToServer : $e $s");
    }
  }
  return result;
}

Future<List<ProductBarcodeStatusObjectBoxStruct>> getProductBarcodeStatusFromTerminal() async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "staff.get_product_barcode_status",
    json: "",
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  var result = (await jsonDecode(response) as List).map((item) => ProductBarcodeStatusObjectBoxStruct.fromJson(item)).toList();
  return result;
}

Future<String> getPaySlipFromTerminal(String docNumber) async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "get_pay_slip",
    json: docNumber,
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  return response;
}

Future<String> getSMLQrPay(String apikey, double amount) async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "smlqrpay",
    json: '{"apikey":"$apikey","amount":"$amount"}',
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  return response;
}

Future<String> getSMLQrPayCheckPay(String apikey, String transactionId) async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "checkqrpay",
    json: '{"apikey":"$apikey","transactionId":"$transactionId"}',
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  return response;
}

Future<List<ProductCategoryObjectBoxStruct>> getCategoryFromTerminal() async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "get_all_category",
    json: "",
  );
  try {
    var response = await getFromServer(json: jsonEncode(getData.toJson()));
    return (await jsonDecode(response) as List).map((item) => ProductCategoryObjectBoxStruct.fromJson(item)).toList();
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    global.sendErrorToDevTeam("getCategoryFromTerminal : $e $s");
    return [];
  }
}

Future<List<BuffetModeObjectBoxStruct>> getBuffetModeFromTerminal() async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "get_all_buffet_mode",
    json: "",
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  try {
    return (await jsonDecode(response) as List).map((item) => BuffetModeObjectBoxStruct.fromJson(item)).toList();
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    global.sendErrorToDevTeam("getBuffetModeFromTerminal : $e $s");
    return [];
  }
}

Future<List<ProductBarcodeObjectBoxStruct>> getProductByBarcodeFromTerminal() async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "get_all_barcode",
    json: "",
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  List<ProductBarcodeObjectBoxStruct> res = (await jsonDecode(response) as List).map((item) => ProductBarcodeObjectBoxStruct.fromJson(item)).toList();

  return res;
}

Future<List<TableProcessObjectBoxStruct>> getAllTableFromTerminal() async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "get_all_table",
    json: "",
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  return (await jsonDecode(response) as List).map((item) => TableProcessObjectBoxStruct.fromJson(item)).toList();
}

Future<List<ProfileQrPaymentModel>> getSMLQRFromTerminal() async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "get_sml_qr_list",
    json: "",
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  return (await jsonDecode(response) as List).map((item) => ProfileQrPaymentModel.fromJson(item)).toList();
}

Future<TableProcessObjectBoxStruct> getTableFromTerminal({required String number, required String mainNumber}) async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "get_table",
    json: '{"number":"$number","mainNumber":"$mainNumber"}',
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  return TableProcessObjectBoxStruct.fromJson(await jsonDecode(response));
}

Future<void> terminalPrintTableAndQrCode({required String number}) async {
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var jsonEncodeStr = '{"number":"$number"}';
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.print_table_and_qrcode',
        'data': jsonEncodeStr,
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("terminalPrintTableAndQrCode table success");
    }
  } else {
    if (kDebugMode) {
      print("TerminalPrintTableAndQrCodepdate table failed");
    }
    global.sendErrorToDevTeam("terminalPrintTableAndQrCode : ${response.body}");
  }
}

Future<List<TableProcessObjectBoxStruct>> getDeliveryTicketFromTerminal({required bool sendSuccess}) async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "staff.get_all_delivery_ticket",
    json: '{"sendSuccess":$sendSuccess}',
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  return (await jsonDecode(response) as List).map((item) => TableProcessObjectBoxStruct.fromJson(item)).toList();
}

Future<bool> updateTableToTerminal(TableProcessObjectBoxStruct table) async {
  bool result = false;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var jsonEncodeStr = jsonEncode(table);
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.update_table',
        'data': jsonEncodeStr,
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("updateTableToTerminal table success");
    }
    result = true;
  } else {
    if (kDebugMode) {
      print("updateTableToTerminal table failed");
      global.sendErrorToDevTeam("updateTableToTerminal : ${response.body}");
    }
  }
  return result;
}

Future<bool> updateCancelCloseTableToTerminal(TableProcessObjectBoxStruct table) async {
  bool result = false;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var jsonEncodeStr = jsonEncode(table);
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.cancel_close_table',
        'data': jsonEncodeStr,
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("updateTableToTerminal table success");
    }
    result = true;
  } else {
    if (kDebugMode) {
      print("updateTableToTerminal table failed");
      global.sendErrorToDevTeam("updateTableToTerminal : ${response.body}");
    }
  }
  return result;
}

Future<String> closeTableToTerminal(
    {required TableProcessObjectBoxStruct table,
    required BuildContext context,
    required PosProcessModel process,
    required int payMode,
    required double payAmount,
    required String discountFormula,
    required String slipImagePath,
    String transactionId = "",
    String payqrcodename = "",
    String providerCode = "",
    String providerName = ""}) async {
  String result = "";
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  String imageBase64 = "";
  if (slipImagePath.isNotEmpty) {
    File file = File(slipImagePath);
    List<int> imageBytes = file.readAsBytesSync();
    imageBase64 = base64Encode(imageBytes);
  }
  CloseTableModel closeTable = CloseTableModel(
      table: table,
      payMode: payMode,
      slipImage: imageBase64,
      discountFormula: discountFormula,
      payAmount: payAmount,
      process: process,
      transactionId: transactionId,
      payqrcodename: payqrcodename,
      providercode: providerCode,
      providername: providerName,
      roundamount: process.cash_round_amount);
  var jsonEncodeStr = jsonEncode(closeTable);

  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.close_table',
        'data': jsonEncodeStr,
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("Update table success");
    }
    result = response.body;
  } else {
    if (kDebugMode) {
      print("Update table failed");
    }
    global.sendErrorToDevTeam("closeTableToTerminal : ${response.body}");
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("มีปัญหา"),
            content: const Text("ปิดโต๊ะไม่สำเร็จ"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("รับทราบ"),
              ),
            ],
          );
        });
  }
  return result;
}

Future<bool> moveTableToTerminal(String fromTable, String toTable) async {
  bool result = false;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var jsonEncodeStr = '{"from_table":"$fromTable","to_table":"$toTable"}';
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.move_table',
        'data': jsonEncodeStr,
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("Update table success");
    }
    result = true;
  } else {
    if (kDebugMode) {
      print("Update table failed");
    }
    global.sendErrorToDevTeam("moveTableToTerminal : ${response.body}");
  }
  return result;
}

Future<bool> mergeTableToTerminal(String fromTable, String toTable) async {
  bool result = false;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var jsonEncodeStr = '{"from_table":"$fromTable","to_table":"$toTable"}';
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.merge_table',
        'data': jsonEncodeStr,
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("Update table success");
    }
    result = true;
  } else {
    if (kDebugMode) {
      print("Update table failed");
    }
    global.sendErrorToDevTeam("mergeTableToTerminal : ${response.body}");
  }
  return result;
}

Future<bool> orderTempDeleteByBarcode(String tableNumber, String barcode) async {
  bool result = false;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.order_temp_delete_by_barcode',
        'data': '{"orderId":"$tableNumber","barcode":"$barcode"}',
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("orderTempDeleteByBarcode success");
    }
    result = true;
  } else {
    if (kDebugMode) {
      print("orderTempDeleteByBarcode failed");
    }
    global.sendErrorToDevTeam("orderTempDeleteByBarcode : ${response.body}");
  }
  return result;
}

Future<bool> orderTempSendOrderByOrderId({required String tableNumber, required String machineId}) async {
  bool result = false;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var jsonParameter = jsonEncode({
    "orderId": tableNumber,
    "machineId": machineId,
  });
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.order_temp_send_order_by_orderid',
        'data': jsonParameter,
      }));
  if (response.statusCode == 200) {
    result = true;
  } else {
    if (kDebugMode) {
      print("orderTempSendOrderByOrderId failed");
    }
    global.sendErrorToDevTeam("orderTempSendOrderByOrderId : ${response.body}");
  }
  return result;
}

Future<bool> orderTempDeleteByOrderGuid(String tableNumber, String orderGuid) async {
  bool result = false;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.order_temp_delete_by_guid',
        'data': '{"orderId":"$tableNumber","guid":"$orderGuid"}',
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("orderTempDeleteByOrderGuid success");
    }
    result = true;
  } else {
    if (kDebugMode) {
      print("orderTempDeleteByOrderGuid failed");
    }
    global.sendErrorToDevTeam("orderTempDeleteByOrderGuid : ${response.body}");
  }

  return result;
}

Future<int> orderTempInsertToTerminal(OrderTempObjectBoxStruct order) async {
  int result = 0;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var jsonEncodeStr = jsonEncode(order);
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.order_temp_insert',
        'data': jsonEncodeStr,
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("orderTempInsertToTerminal success");
    }
    result = int.parse(response.body);
  } else {
    if (kDebugMode) {
      print("orderTempInsertToTerminal failed");
    }
    global.sendErrorToDevTeam("orderTempInsertToTerminal failed : ${response.body}");
  }
  return result;
}

Future<int> orderTempUpdateToTerminal(OrderTempObjectBoxStruct order) async {
  int result = 0;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}?uuid=${Uuid().v4()}";
  var uri = Uri.parse(url);
  var jsonEncodeStr = jsonEncode(order);
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.order_temp_update',
        'data': jsonEncodeStr,
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("orderTempUpdateToTerminal success");
    }
    result = int.parse(response.body);
  } else {
    if (kDebugMode) {
      print("orderTempUpdateToTerminal failed");
    }
    global.sendErrorToDevTeam("orderTempUpdateToTerminal failed : ${response.body}");
  }
  return result;
}

Future<bool> orderTempUpdateOrderSplitToTerminal({required String sourceTable, required String targetTable, required String sourceGuid}) async {
  bool result = false;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}?uuid=${Uuid().v4()}";
  var uri = Uri.parse(url);
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'command': 'staff.order_temp_update_for_split', 'data': '{"sourceTable":"$sourceTable","targetTable":"$targetTable","sourceGuid":"$sourceGuid"}'}));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("orderTempUpdateOrderSplitToTerminal success");
    }
    result = true;
  } else {
    if (kDebugMode) {
      print("orderTempUpdateOrderSplitToTerminal failed");
    }
  }

  return result;
}

Future<OrderTempStruct?> getOrderTempByOrderIdFromTerminal({required String orderId, required bool isOrder, required String machineId}) async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "staff.order_temp_get_data_from_orderid",
    json: '{"orderId":"$orderId","isOrder":$isOrder,"machineId":"$machineId"}',
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  try {
    return OrderTempStruct.fromJson(await jsonDecode(response));
  } catch (e, s) {
    global.sendErrorToDevTeam("getOrderTempByOrderIdFromTerminal : $e $s");
    return null;
  }
}

Future<bool> orderTempServedStatusByGuid({required String guid, required double servedQty}) async {
  bool result = false;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.order_temp_served_status_by_guid',
        'data': '{"guid":"$guid","served_qty":$servedQty}',
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("orderTempServedStatusByGuid success");
    }
    result = true;
  } else {
    if (kDebugMode) {
      print("orderTempServedStatusByGuid failed");
    }
  }
  return result;
}

Future<List<OrderTempObjectBoxStruct>?> getOrderTempCheckerFromTerminal() async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "staff.order_temp_get_data_checker",
    json: '{}',
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  try {
    return (await jsonDecode(response) as List).map((item) => OrderTempObjectBoxStruct.fromJson(item)).toList();
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    global.sendErrorToDevTeam("getOrderTempCheckerFromTerminal : $e $s");
    return null;
  }
}

Future<OrderTempStruct?> getOrderTempByOrderMainIdFromTerminal({required String orderMainId, required bool isOrder, required String machineId}) async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "staff.order_temp_get_data_from_order_main_id",
    json: '{"orderMainId":"$orderMainId","isOrder":$isOrder,"machineId":"$machineId"}',
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  try {
    return OrderTempStruct.fromJson(await jsonDecode(response));
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    global.sendErrorToDevTeam("getOrderTempByOrderMainIdFromTerminal : $e $s");
    return null;
  }
}

Future<OrderTempObjectBoxStruct?> getOrderTempByOrderGuidFromTerminal(String orderGuid) async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "staff.order_temp_get_data_from_order_guid",
    json: orderGuid,
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  try {
    return OrderTempObjectBoxStruct.fromJson(await jsonDecode(response));
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    global.sendErrorToDevTeam("getOrderTempByOrderGuidFromTerminal : $e $s");
    return null;
  }
}

Future<PosProcessModel> getProcessFromTerminal(String holdId, String discountFormula, bool cash) async {
  String cashRoundAmount = cash ? "true" : "false";
  HttpGetDataModel getData = HttpGetDataModel(
    code: "get_process",
    json: '{"holdCode":"$holdId","docMode":1,"detailDiscountFormula":"$discountFormula","discountFormula":"","cashRoundAmount":$cashRoundAmount,"discountFoodOnly":true}',
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  try {
    return PosProcessModel.fromJson(await jsonDecode(response));
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    global.sendErrorToDevTeam("getProcessFromTerminal : $e $s");
    return PosProcessModel();
  }
}

Future<List<OrderTempObjectBoxStruct>?> getOrderTempByOrderIdAndBarcodeFromTerminal({required String orderId, required String barcode, required String machineId, required bool isOrder}) async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "staff.order_temp_get_data_from_orderid_and_barcode",
    json: '{"orderId":"$orderId","barcode":"$barcode","isOrder":$isOrder,"machineId":"$machineId"}',
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  try {
    return (await jsonDecode(response) as List).map((item) => OrderTempObjectBoxStruct.fromJson(item)).toList();
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    global.sendErrorToDevTeam("getOrderTempByOrderIdAndBarcodeFromTerminal : $e $s");
    return null;
  }
}

Future<bool> getConnectTerminal() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String newGuid = prefs.getString("client_guid") ?? const Uuid().v4();
  String connectCode = prefs.getString("connectCode") ?? "";
  SyncStaffDeviceModel sendData = SyncStaffDeviceModel(clientGuid: newGuid, clientName: global.machineName, clientIp: await ipAddress(), securityCode: connectCode);
  var jsonEncodeStr = jsonEncode(sendData.toJson());

  HttpGetDataModel getData = HttpGetDataModel(
    code: "get_connect",
    json: jsonEncodeStr,
  );

  try {
    var response = await getFromServer(json: jsonEncode(getData.toJson()));
    return (response == "connected");
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
  }
  return false;
}

Future<bool> orderTempCancelByGuid(String guid, double qty, String remark) async {
  bool result = false;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.order_temp_cancel_by_guid',
        'data': '{"guid":"$guid","qty":$qty,"remark":"$remark"}',
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("orderTempCancelByGuid success");
    }
    result = true;
  } else {
    if (kDebugMode) {
      print("orderTempCancelByGuid failed");
    }
  }
  return result;
}

Future<bool> productBarcodeStatusUpdateToTerminal(ProductBarcodeStatusObjectBoxStruct product) async {
  bool result = false;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var jsonEncodeStr = jsonEncode(product);
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.product_barcode_status_update',
        'data': jsonEncodeStr,
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("productBarcodeStatusUpdateToTerminal success");
    }
    result = true;
  } else {
    if (kDebugMode) {
      print("productBarcodeStatusUpdateToTerminal failed");
    }
  }
  return result;
}

Future<bool> setKdsStartCooking(String orderNumber) async {
  // สั่งประกอบอาหาร
  bool result = false;
  String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  var response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'command': 'staff.set_kds_start_cooking',
        'data': '{"orderNumber":"$orderNumber"}',
      }));
  if (response.statusCode == 200) {
    if (kDebugMode) {
      print("setKdsStartCooking success");
    }
    result = true;
  } else {
    if (kDebugMode) {
      print("setKdsStartCooking failed");
    }
  }
  return result;
}

Future<void> getInformationFromPosTerminal() async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "pos_information",
    json: "",
  );
  try {
    var response = await getFromServer(json: jsonEncode(getData.toJson()));
    global.posInformation = PosInformationModel.fromJson(await jsonDecode(response));
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    global.sendErrorToDevTeam("getInformationFromPosTerminal : $e $s");
  }
}

Future<void> printOrderSummery({required String orderId}) async {
  try {
    String url = "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
    var uri = Uri.parse(url);
    var jsonEncodeStr = jsonEncode({
      "orderid": orderId,
    });
    var response = await http.post(uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'command': 'staff.print_order_summery',
          'data': jsonEncodeStr,
        }));
    if (response.statusCode == 200) {
      if (kDebugMode) {
        print("success");
      }
    } else {
      if (kDebugMode) {
        print("failed");
      }
    }
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    global.sendErrorToDevTeam("printOrderSummery : $e $s");
  }
}

Future<String> clickHouseExecute(String query) async {
  String url = 'https://api2.dev.dedepos.com/orderonlineapi/execute';
  if (kDebugMode) {
    print(query);
  }
  // Create a Map object with the query field
  Map<String, String> requestBody = {
    'query': query,
  };

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
      if (kDebugMode) {
        print('Query executed successfully.');
      }
      // Do something with the response, if needed
      var responseBody = json.decode(response.body);
      return responseBody.toString();
      // ...
    } else {
      // Request failed
      String error = 'Error executing query. Status code: ${response.statusCode}';
      if (kDebugMode) {
        print(error);
      }
    }
    return "";
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    global.sendErrorToDevTeam("clickHouseExecute : $e $s");
    return "";
  }
}

Future<Map<String, dynamic>> clickHouseSelect(String query) async {
  // Create a Map object with the query field
  Map<String, String> requestBody = {
    'query': query,
  };

  // Convert the Map to JSON
  String jsonBody = json.encode(requestBody);

  // Make the HTTP POST request
  var response = await http.post(
    Uri.parse('https://api2.dev.dedepos.com/orderonlineapi/select'),
    headers: {'Content-Type': 'application/json'},
    body: jsonBody,
  );

  if (response.statusCode == 200) {
    // Request successful
    if (kDebugMode) {
      print('Query executed successfully.');
    }
    // Do something with the response, if needed
    var responseBody = json.decode(response.body);
    return responseBody;
  } else {
    // Request failed
    if (kDebugMode) {
      print('Error clickHouseSelect. Status code: ${response.statusCode}');
    }
  }
  return {};
}

Future<List<StaffModel>> getStaff() async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "staff.get_staff",
    json: "",
  );
  try {
    var response = await getFromServer(json: jsonEncode(getData.toJson()));
    return (await jsonDecode(response) as List).map((item) => StaffModel.fromJson(item)).toList();
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    global.sendErrorToDevTeam("getStaff : $e $s");
  }

  return [];
}
