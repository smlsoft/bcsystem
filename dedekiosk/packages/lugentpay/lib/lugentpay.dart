import 'dart:io';
import 'package:decimal/decimal.dart';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:lugentpayment/inquiry_payment_response.dart';
import 'package:lugentpayment/qrpayment_request.dart';
import 'package:lugentpayment/qrpayment_response.dart';

import 'inquiry_payment_request.dart';

class LugentPay {
  LugentPay(
      {required this.billerCode,
      required this.billerID,
      required this.storeID,
      required this.terminalID,
      required this.merchantName,
      this.accessCode});

  final String billerCode;
  final String billerID;
  final String storeID;
  final String terminalID;
  final String merchantName;
  String? accessCode;

  final String lugentEndpoint = "https://paymentgw.lugentpay.com:44083";
  final String lugentDevEndpoint = "https://paymentgw-test.lugentpay.com:44093";

  final String THAI_QR_PAYMENT_GENERATER_ENDPOINT =
      "/cubems/msh/bpms/lugentpay/qrrequest/thaiqr";

  final String LINEPAY_QRCODE_GENERATER_ENDPOINT =
      "/cubems/msh/bpms/lugentpay/qrrequest/linepay";

  final String ALIPAY_QRCODE_GENERATER_ENDPOINT =
      "/cubems/msh/bpms/lugentpay/qrrequest/alipay";

  final String WECHAT_QRCODE_GENERATER_ENDPOINT =
      "/cubems/msh/bpms/lugentpay/qrrequest/wechatpay";

  final String TRUEMONEY_QRCODE_GENERATER_ENDPOINT =
      "/cubems/msh/bpms/lugentpay/qrrequest/tmn";

  final String BCEL_ONEPAY_QRCODE_GENERATER_ENDPOINT =
      "/cubems/msh/bpms/lugentpay/qrrequest/onepay";

  final String LUGENT_INQUIRY_ENDPOINT =
      "/cubems/msh/rest/lugentpay/checkpayment";

  static LugentPay InitDemoInstance() {
    LugentPay lugent = new LugentPay(
      billerCode: "LGN",
      billerID: "010555706234202",
      storeID: "4000015",
      terminalID: "1001",
      merchantName: "SMLSOFT",
      accessCode: "4TqvJ5jLQJPweLdnT4MhjML2jb5fSqfQ1KUWNNfi",
    );
    return lugent;
  }

  Dio init() {
    Dio dio = Dio();
    (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    dio.options.baseUrl = lugentDevEndpoint;
    return dio;
  }

  QRPaymentRequest CreateQRPaymentRequest(
      String ref1, String ref2, Decimal amount, String currencyCode) {
    QRPaymentRequest request = new QRPaymentRequest(
      billerCode: this.billerCode,
      billerID: this.billerID,
      storeID: this.storeID,
      terminalID: this.terminalID,
      merchantName: this.merchantName,
      ref1: ref1,
      ref2: ref2,
      amount: amount,
      currencyCode: currencyCode,
      accessCode: this.accessCode,
    );

    return request;
  }

  String CreateReferenceWithUnixTime(String ref1) {
    String timeUnixStr = DateTime.now().millisecondsSinceEpoch.toString();
    return ref1 + timeUnixStr;
  }

  /// Create Thai QR Payment Transaction
  Future<QRPaymentResponse> CreateThaiQRPaymentTransaction(
      String ref1, String ref2, Decimal amount, String currencyCode) async {
    Dio client = this.init();

    QRPaymentRequest request =
        this.CreateQRPaymentRequest(ref1, ref2, amount, currencyCode);
    try {
      final response = await client.post(THAI_QR_PAYMENT_GENERATER_ENDPOINT,
          data: request.toJson());
      // print(response);
      QRPaymentResponse qrPaymentResponseToJson =
          QRPaymentResponse.fromJson(response.data);
      return qrPaymentResponseToJson;
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      throw new Exception(errorMessage);
    }
  }

  /// Create Line Pay Transaction
  Future<QRPaymentResponse> CreateLinePayTransaction(
      String ref1, String ref2, Decimal amount, String currencyCode) async {
    Dio client = this.init();

    QRPaymentRequest request =
        this.CreateQRPaymentRequest(ref1, ref2, amount, currencyCode);
    try {
      final response = await client.post(LINEPAY_QRCODE_GENERATER_ENDPOINT,
          data: request.toJson());
      // print(response);
      QRPaymentResponse qrPaymentResponseToJson =
          QRPaymentResponse.fromJson(response.data);
      return qrPaymentResponseToJson;
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      throw new Exception(errorMessage);
    }
  }

  /// Create AliPay Pay Transaction
  Future<QRPaymentResponse> CreateAliPayTransaction(
      String ref1, String ref2, Decimal amount, String currencyCode) async {
    Dio client = this.init();

    QRPaymentRequest request =
        this.CreateQRPaymentRequest(ref1, ref2, amount, currencyCode);
    try {
      final response = await client.post(ALIPAY_QRCODE_GENERATER_ENDPOINT,
          data: request.toJson());
      // print(response);
      QRPaymentResponse qrPaymentResponseToJson =
          QRPaymentResponse.fromJson(response.data);
      return qrPaymentResponseToJson;
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      throw new Exception(errorMessage);
    }
  }

  /// Create Wechat Pay Transaction
  Future<QRPaymentResponse> CreateWechatTransaction(
      String ref1, String ref2, Decimal amount, String currencyCode) async {
    Dio client = this.init();

    QRPaymentRequest request =
        this.CreateQRPaymentRequest(ref1, ref2, amount, currencyCode);
    try {
      final response = await client.post(WECHAT_QRCODE_GENERATER_ENDPOINT,
          data: request.toJson());
      // print(response);
      QRPaymentResponse qrPaymentResponseToJson =
          QRPaymentResponse.fromJson(response.data);
      return qrPaymentResponseToJson;
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      throw new Exception(errorMessage);
    }
  }

  /// Create True Money Transaction
  Future<QRPaymentResponse> CreateTrueMoneyTransaction(
      String productName,
      String productDescription,
      String productImageUrl,
      String ref1,
      String ref2,
      Decimal amount,
      String currencyCode) async {
    Dio client = this.init();

    QRPaymentRequest request =
        this.CreateQRPaymentRequest(ref1, ref2, amount, currencyCode);
    request.productName = productName;
    request.productDescription = productDescription;
    request.productImageUrl = productImageUrl;

    try {
      final response = await client.post(TRUEMONEY_QRCODE_GENERATER_ENDPOINT,
          data: request.toJson());

      QRPaymentResponse qrPaymentResponseToJson =
          QRPaymentResponse.fromJson(response.data);
      return qrPaymentResponseToJson;
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      throw new Exception(errorMessage);
    }
  }

  /// Create AliPay Pay Transaction
  Future<QRPaymentResponse> CreateBCELOnePayTransaction(
      String ref1, String ref2, Decimal amount, String currencyCode) async {
    Dio client = this.init();

    QRPaymentRequest request =
        this.CreateQRPaymentRequest(ref1, ref2, amount, currencyCode);
    try {
      final response = await client.post(BCEL_ONEPAY_QRCODE_GENERATER_ENDPOINT,
          data: request.toJson());
      // print(response);
      QRPaymentResponse qrPaymentResponseToJson =
          QRPaymentResponse.fromJson(response.data);
      return qrPaymentResponseToJson;
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      throw new Exception(errorMessage);
    }
  }

  Future<InquiryPaymentResponse> InquiryPayment(String transactionId) async {
    Dio client = this.init();

    InquiryPaymentRequest request =
        new InquiryPaymentRequest(transactionId: transactionId);

    try {
      final responseData =
          await client.post(LUGENT_INQUIRY_ENDPOINT, data: request.toJson());
      print(responseData);
      InquiryPaymentResponse response =
          InquiryPaymentResponse.fromJson(responseData.data);
      return response;
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      throw new Exception(errorMessage);
    }
  }
}
