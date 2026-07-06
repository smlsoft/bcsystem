import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smlaicloud/global.dart' as global;

class Util {
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
}

class ReconnectingOverlay extends StatelessWidget {
  const ReconnectingOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
          ],
        ),
      );
}

Future<Map<String, dynamic>> clickhouseSelectGroup(List<String> querys) async {
  var httpClient = http.Client();
  // ปรับให้ใช้ absolute URL เสมอ (ห้ามใช้ localhost/127.0.0.1 บน web)
  String apiPath = global.myAppConfig.serviceClickhouse;
  if (!apiPath.startsWith('http')) {
    apiPath = 'https://' + apiPath;
  }
  var urlString = "$apiPath/selectgroup";
  var url = Uri.parse(urlString);

  if (kDebugMode) {
    print("querys : $querys");
  }

  try {
    var response = await httpClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"querys": querys}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        "status": "error",
        "code": response.statusCode,
        "message": "เกิดข้อผิดพลาดในการเรียก API: ${response.reasonPhrase}"
      };
    }
  } catch (e) {
    return {
      "status": "error",
      "code": 500,
      "message": "เกิดข้อผิดพลาดในการเชื่อมต่อ: $e"
    };
  } finally {
    httpClient.close();
  }
}
