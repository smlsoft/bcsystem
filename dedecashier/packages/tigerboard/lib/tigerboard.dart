import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'models/models.dart';

class TigerBoard {
  final String apiUrl = 'http://134.209.110.153:3001';
  final String apiKey;
  final String appId;

  String genRefFromTime(DateTime time) {
    String formattedDateTime = DateFormat('yyMMddHHmmss').format(time);
    return formattedDateTime;
  }

  TigerBoard({
    required this.apiKey,
    required this.appId,
  });

  Future<PaymentGenQRResponse> generatePayrequest(String custName, String posId, double amount) async {
    Dio client = init();

    PaymentGenQRRequest request = createGenPaymentRequest(custName, posId, amount);
    try {
      var bodyjson = request.toJson();
      final response = await client.post("/orders", data: bodyjson);
      // print(response);
      PaymentGenQRResponse qrPaymentResponseToJson = PaymentGenQRResponse.fromJson(response.data['data']);
      return qrPaymentResponseToJson;
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  PaymentGenQRRequest createGenPaymentRequest(String custName, String posId, double amount) {
    String key = generateRandomString(5);
    String refCode = genRefUnixTimeNow(key);
    String refCode2 = genRefUnixTimeNow(key);
    String cus = (custName == "") ? "ลูกค้าทั่วไป" : custName;
    PaymentGenQRRequest genQrRequest = PaymentGenQRRequest(
        order_id: const Uuid().v4(),
        customer_name: cus,
        title: "$posId - $cus",
        amount: amount,
        status: "new",
        total: amount,
        ref1: refCode,
        ref2: refCode2,
        pos_created_date: DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(DateTime.now().toUtc()));

    return genQrRequest;
  }

  String generateRandomString(int length) {
    const availableChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();

    return List.generate(length, (index) => availableChars[random.nextInt(availableChars.length)]).join();
  }

  Future<PaymentGenQRResponse> inquiryPayment(String id) async {
    Dio client = init();

    final String qrEndPoint = "/orders/$id";
    try {
      final response = await client.get(qrEndPoint);
      // ignore: avoid_print
      print(response);
      PaymentGenQRResponse qrPaymentResponseToJson = PaymentGenQRResponse.fromJson(response.data['data']);
      return qrPaymentResponseToJson;
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<PaymentGenQRResponse> cancelPayment(String id) async {
    Dio client = init();

    final String qrEndPoint = "/orders/$id";
    try {
      final response = await client.put(qrEndPoint, data: {"status": "cancel"});
      // ignore: avoid_print
      print(response);
      PaymentGenQRResponse qrPaymentResponseToJson = PaymentGenQRResponse.fromJson(response.data['data']);
      return qrPaymentResponseToJson;
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  String genRefUnixTimeNow(String code) {
    return genRefUnixTime(DateTime.now(), code);
  }

  String genRefUnixTime(DateTime time, String code) {
    String timeUnixStr = time.millisecondsSinceEpoch.toString().substring(0, 10);

    int maxLength = 5;
    int startPos = code.length > maxLength ? (code.length - maxLength) : 0;
    String substring = code.substring(startPos);

    return substring + timeUnixStr;
  }

  Dio init() {
    Dio dio = Dio();
    dio.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () {
      HttpClient client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return client;
    });

    dio.options.baseUrl = apiUrl;

    // Set headers
    dio.options.headers = {
      'app-id': appId,
      'x-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    return dio;
  }
}
