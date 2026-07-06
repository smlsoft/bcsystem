import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:intl/intl.dart';
import 'models/models.dart';

class GBPrimePay {
  final String API_URL = 'https://api.gbprimepay.com';
  final String API_URL_DEV = 'https://api.globalprimepay.com';

  final String GEN_THAI_QR_CODE_ENDPOINT = "/v3/qrcode";
  final String GEN_WECHAT_QR_ENDPOINT = "/v2/wechat";
  final String GEN_LINE_PAY_ENDPOINT = "/v2/linepay";
  final String GEN_TRUE_MONEY_ENDPOINT = "/v3/qrcode";
  final String GEN_SHOPEE_PAY_ENDPOINT = "/v3/qrcode";
  final String GEN_ALI_PAY_ENDPOINT = "/v3/qrcode";
  final String GEN_THAI_QR_CODE_TEXT_ENDPOINT = "/v3/qrcode/text";
  final String INQUIRY_PAYMENT_ENDPOINT = "/v1/check_status_txn";

  final String accessToken;
  final String publicKey;
  final String secretKey;

  String genRefFromTime(DateTime time) {
    String formattedDateTime = DateFormat('yyMMddHHmmss').format(time);
    return formattedDateTime;
  }

  GBPrimePay({
    required this.publicKey,
    required this.secretKey,
    required this.accessToken,
  });

  Future<GBPaymentGenQRResponse> generateQRPayment(
      String refNo, Decimal amount) async {
    Dio client = init();

    GBPaymentGenQRRequest request = createGenQRPaymentRequest(refNo, amount);
    try {
      final formData = FormData.fromMap(request.toJson());

      final response =
          await client.post(GEN_THAI_QR_CODE_TEXT_ENDPOINT, data: formData);
      // print(response);
      GBPaymentGenQRResponse qrPaymentResponseToJson =
          GBPaymentGenQRResponse.fromJson(response.data);
      return qrPaymentResponseToJson;
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<GBPaymentGenQRResponse> generateImageThaiQRPayment(
      String refNo, Decimal amount) async {
    GBPaymentGenQRRequest request = createGenQRPaymentRequest(refNo, amount);
    Dio client = init();

    try {
      final formData = FormData.fromMap(request.toJson());

      Response response = await client.post(GEN_THAI_QR_CODE_ENDPOINT,
          data: formData, options: Options(responseType: ResponseType.stream));

      if (response.statusCode == 200) {
        GBPaymentGenQRResponse qrPaymentResponseToJson =
            GBPaymentGenQRResponse(resultCode: "00", resultMessage: "Success");
        qrPaymentResponseToJson.referenceNo = request.referenceNo;
        Uint8List uint8List = Uint8List(0);
        await response.data.stream.forEach((data) {
          uint8List = Uint8List.fromList([...uint8List, ...data]);
        });
        qrPaymentResponseToJson.qrImageData = uint8List;
        return qrPaymentResponseToJson;
      }
      return GBPaymentGenQRResponse(
          resultCode: "99", resultMessage: "Failed to load data");
    } on DioException catch (ex) {
      String errorMessage = ex.toString();
      throw Exception(errorMessage);
    }
  }

  Future<GBPaymentGenQRResponse> generateImageWeChatQRPayment(
      String refNo, Decimal amount, String backgroundUri) async {
    final String detail = "Food & Beverage";

    // GBPaymentGenQRRequest request = createGenQRPaymentRequest(refNo, amount);
    String checkSumSource = amount.toString() + refNo + backgroundUri;
    String checksum = "";

    // chk sum
    GBPrimePayGenWeChatQRCodeRequest request = GBPrimePayGenWeChatQRCodeRequest(
        publicKey: publicKey,
        amount: amount,
        referenceNo: refNo,
        backgroundUrl: backgroundUri,
        detail: detail,
        checksum: checksum);

    Dio client = init();

    try {
      final formData = FormData.fromMap(request.toJson());

      Response response = await client.post(GEN_WECHAT_QR_ENDPOINT,
          data: formData, options: Options(responseType: ResponseType.stream));

      if (response.statusCode == 200) {
        GBPaymentGenQRResponse qrPaymentResponseToJson =
            GBPaymentGenQRResponse(resultCode: "00", resultMessage: "Success");
        qrPaymentResponseToJson.referenceNo = request.referenceNo;
        Uint8List uint8List = Uint8List(0);
        await response.data.stream.forEach((data) {
          uint8List = Uint8List.fromList([...uint8List, ...data]);
        });
        qrPaymentResponseToJson.qrImageData = uint8List;
        return qrPaymentResponseToJson;
      }
      return GBPaymentGenQRResponse(
          resultCode: "99", resultMessage: "Failed to load data");
    } on DioException catch (ex) {
      String errorMessage = ex.toString();
      throw Exception(errorMessage);
    }
  }

  GBPaymentGenQRRequest createGenQRPaymentRequest(
      String refNo, Decimal amount) {
    GBPaymentGenQRRequest genQrRequest =
        GBPaymentGenQRRequest(amount: amount, referenceNo: refNo);

    genQrRequest.token = accessToken;
    return genQrRequest;
  }

  GBInquiryPaymentRequest createInquiryPaymentRequest(String referenceNo) {
    return GBInquiryPaymentRequest(
      referenceNo: referenceNo,
    );
  }

  Future<GBInquiryPaymentResponse> inquiryQRPayment(String refNo) async {
    Dio client = init();

    GBInquiryPaymentRequest request = createInquiryPaymentRequest(refNo);

    String encodeSecretKey = base64Encode(utf8.encode("${this.secretKey}:"));

    final String authorization = "Basic $encodeSecretKey";
    try {
      final response = await client.post(INQUIRY_PAYMENT_ENDPOINT,
          data: request.toJson(),
          options: Options(headers: {
            'Content-Type': 'application/json',
            'Authorization': authorization
          }));
      // print(response);
      GBInquiryPaymentResponse qrPaymentResponseToJson =
          GBInquiryPaymentResponse.fromJson(response.data);
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
    String timeUnixStr =
        time.millisecondsSinceEpoch.toString().substring(0, 10);

    int maxLength = 5;
    int startPos = code.length > maxLength ? (code.length - maxLength) : 0;
    String substring = code.substring(startPos);

    return substring + timeUnixStr;
  }

  Dio init() {
    Dio dio = Dio();
    dio.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    });

    // (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
    //     (HttpClient client) {
    //   client.badCertificateCallback =
    //       (X509Certificate cert, String host, int port) => true;
    //   return client;
    // };

    dio.options.baseUrl = API_URL;
    return dio;
  }
}
