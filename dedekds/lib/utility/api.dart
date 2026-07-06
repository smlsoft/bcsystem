import 'dart:convert';
import 'package:dedekds/model/global_model.dart';
import 'package:dedekds/model/kitchen_model.dart';
import 'package:dedekds/model/order_temp_model.dart';
import 'package:http/http.dart' as http;
import 'package:dedekds/global.dart' as global;

Future<bool> orderTempUpdateStatusByGuid({required String guid}) async {
  bool result = false;
  String url =
      "http://${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  var uri = Uri.parse(url);
  http
      .post(uri,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'command': 'kds.order_temp_update_kds_success_status',
            'data': '{"guid":"$guid"}',
          }))
      .then((response) {
    if (response.statusCode == 200) {
      print("Init table success");
      result = true;
    } else {
      print("Init table failed");
    }
  });
  return result;
}

Future<OrderTempObjectBoxStruct> getOrderTempByGuidFromTerminal(
    {required guid}) async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "staff.order_temp_get_data_from_order_guid",
    json: guid,
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  return OrderTempObjectBoxStruct.fromJson(jsonDecode(response));
}

Future<List<OrderTempObjectBoxStruct>> getOrderTempByKitchenFromTerminal(
    {required kitchenId}) async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "kds.order_temp_get_data_from_kitchen",
    json: '{"kitchenId":"$kitchenId"}',
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  return (jsonDecode(response) as List)
      .map((item) => OrderTempObjectBoxStruct.fromJson(item))
      .toList();
}

Future<List<KitchenObjectBoxStruct>> getKitchenFromTerminal() async {
  HttpGetDataModel getData = HttpGetDataModel(
    code: "get_all_kitchen",
    json: "",
  );
  var response = await getFromServer(json: jsonEncode(getData.toJson()));
  return (jsonDecode(response) as List)
      .map((item) => KitchenObjectBoxStruct.fromJson(item))
      .toList();
}

Future<String> getFromServer({required String json}) async {
  final base64String = base64Encode(utf8.encode(json));
  // String url = "$httpServerIp:$httpServerPort?data=$base64String";

  String url =
      "${global.posTerminalDeviceIpAddress}:${global.posTerminalDevicePort}";
  final response =
      await http.get(Uri.http(url, '/', {'json': base64String}), headers: {
    "Content-Type": "application/json",
    "Cache-Control": "no-cache",
    "Accept": "text/event-stream"
  });
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to load data');
  }
}

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
