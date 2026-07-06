import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:intl/intl.dart';
import 'models/models.dart';

class XenditPay {
  final String API_URL = 'https://api.xendit.co';

  final String THAI_QR_CODE_ENDPOINT = "/qr_codes";
  final String accessToken;

  String genRefFromTime(DateTime time) {
    String formattedDateTime = DateFormat('yyMMddHHmmss').format(time);
    return formattedDateTime;
  }

  XenditPay({
    required this.accessToken,
  });

  Future<XenditPaymentGenQRResponse> generateQRPayment(String refNo, double amount, String currency, String expireAt) async {
    Dio client = init();

    XenditPaymentGenQRRequest request = createGenQRPaymentRequest(refNo, amount, currency, expireAt);
    try {
      var bodyjson = request.toJson();
      final response = await client.post(THAI_QR_CODE_ENDPOINT, data: bodyjson);
      // print(response);
      XenditPaymentGenQRResponse qrPaymentResponseToJson = XenditPaymentGenQRResponse.fromJson(response.data);
      return qrPaymentResponseToJson;
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  XenditPaymentGenQRRequest createGenQRPaymentRequest(String refNo, double amount, String currency, String expiresAt) {
    XenditPaymentGenQRRequest genQrRequest = XenditPaymentGenQRRequest(amount: amount, reference_id: refNo, currency: currency, expires_at: expiresAt, type: "DYNAMIC");

    return genQrRequest;
  }

  Future<XenditPaymentPayQRResponse> inquiryQRPayment(String refNo) async {
    Dio client = init();

    final String qrEndPoint = "/qr_codes/$refNo/payments";
    try {
      final response = await client.get(qrEndPoint);
      // print(response);
      XenditPaymentPayQRResponse qrPaymentResponseToJson = XenditPaymentPayQRResponse.fromJson(response.data);
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

    dio.options.baseUrl = API_URL;
    String username = accessToken;
    String password = '';
    String basicAuth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    // Set headers
    dio.options.headers = {
      'Authorization': basicAuth,
      'Content-Type': 'application/json',
      'api-version': '2022-07-31', // Add any custom headers you need
    };

    return dio;
  }
}
