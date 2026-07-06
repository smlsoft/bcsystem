import 'dart:convert';
import 'dart:math';
import 'package:cocomerchant_lite/environment.dart';
import 'package:http/http.dart' as http;
import 'package:cocomerchant_lite/global.dart' as global;
import 'dart:developer' as dev;

Future<Map<String, dynamic>> returnGetResponse({required String url, bool showData = false}) async {
  if (global.isdevPin == '0') {
    Environment().initConfig("PROD");
  } else if (global.isdevPin == '1') {
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

Future<Map<String, dynamic>> clickHouseExecute(String query) async {
  print(query);
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
      print('Error executing query. Status code: ${response.statusCode}');
      throw Exception("Error clickHouseExecute() query. $count : Status code: ${response.statusCode} : $query");
    }
    count++;
  }
  throw Exception("Error clickHouseExecute() Time out " + query);
}

Future<Map<String, dynamic>> clickHouseSelect(String query) async {
  try {
    // dev.log(query);
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
      // แปลง field วันที่จาก UTC 0 เป็นเวลาประเทศไทย
      void convertDatesToThaiTime(Map<String, dynamic> map) {
        map.forEach((key, value) {
          if (value is String && DateTime.tryParse(value) != null) {
            DateTime utcDate = DateTime.parse(value);
            DateTime thaiDate = utcDate.add(const Duration(hours: 7));
            map[key] = thaiDate.toIso8601String();
          } else if (value is Map<String, dynamic>) {
            convertDatesToThaiTime(value);
          } else if (value is List) {
            for (var item in value) {
              if (item is Map<String, dynamic>) {
                convertDatesToThaiTime(item);
              }
            }
          }
        });
      }

      convertDatesToThaiTime(responseBody);

      return responseBody;
    } else {
      print('Error executing query. Status code: ${response.statusCode}');

      throw Exception("Error clickHouseSelect() Status code: ${response.statusCode} : $query");
    }
  } catch (e) {
    print(e);
    throw Exception("Error clickHouseSelect() $e");
  }
}
