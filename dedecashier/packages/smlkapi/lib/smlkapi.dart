import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:kapi/models/api_common_error.dart';
import 'package:kapi/models/qr_payment_status_response.dart';
import 'package:kapi/models/qr_transaction_common_response.dart';
import 'package:kapi/models/qr_transaction_id_request.dart';
import 'package:kapi/models/qr_transaction_inquiry_response.dart';
import 'package:kapi/models/qr_transaction_response.dart';

import 'models/qr_generate_request.dart';
import 'models/qr_generate_response.dart';

class SMLKBankConnector {
  final String UAT_API_ENDPOINT = "https://kapiqr-uat.smlsoft.com";
  final String API_ENDPOINT = "https://kapiqr.smlsoft.com";
  final String PROMPTPAY_GENERATE_QR_ENDPOINT = "/qrapi/create-promptpay-qrcode";
  final String CREDITCARD_GENERATE_QR_ENDPOINT = "/qrapi/create-creditcard-qrcode";
  final String CHECK_PAYMENT_ENDPOINT = "/qrapi/payment-status";
  final String INQUIRY_PAYMENT_ENDPOINT = "/qrapi/inquiry-qrcode";
  final String CANCEL_PAYMENT_ENDPOINT = "/qrapi/cancel-qrcode";
  final String LIST_TRANSACTION_ENDPOINT = "/transaction";

  final String apiKey;
  final bool uatMode;

  SMLKBankConnector({
    required this.apiKey,
    this.uatMode = false,
  });

  Future<QRGenerateResponse> CreateQRPromptPayTransaction(Decimal amount, String ref1, ref2, ref3, ref4) async {
    Dio client = getClient();

    QRGenerateRequest request = QRGenerateRequest(
      amount: amount.toDouble(),
      ref1: ref1,
      ref2: ref2,
      ref3: ref3,
      ref4: ref4,
    );

    try {
      var jsonData = request.toJson();
      final response = await client.post(
        PROMPTPAY_GENERATE_QR_ENDPOINT,
        data: jsonData,
      );

      QRGenerateResponse qrPaymentResponseToJson = QRGenerateResponse.fromJson(response.data);
      return qrPaymentResponseToJson;
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<QRGenerateResponse> CreateQRCreditCardTransaction(Decimal amount, String ref1, ref2, ref3, ref4) async {
    QRGenerateRequest request = QRGenerateRequest(
      amount: amount.toDouble(),
      ref1: ref1,
      ref2: ref2,
      ref3: ref3,
      ref4: ref4,
    );

    Dio client = getClient();

    try {
      final response = await client.post(
        CREDITCARD_GENERATE_QR_ENDPOINT,
        data: request.toJson(),
      );

      QRGenerateResponse qrPaymentResponseToJson = QRGenerateResponse.fromJson(response.data);
      return qrPaymentResponseToJson;
    } on DioException catch (ex) {
      if (ex.response != null) {
        QRGenerateResponse qrPaymentResponseToJson = QRGenerateResponse(
          txnUid: "",
          partnerId: "",
          statusCode: "",
          errorCode: "ERROR",
          errorDesc: ex.response!.data.toString(),
          accountName: "",
          qrCode: "",
          qrType: "",
        );
        return qrPaymentResponseToJson;
      } else {
        String errorMessage = ex.response.toString();
        throw Exception(errorMessage);
      }
    }
  }

  Future<QRPaymentStatusResponse> CheckPayment(String txnId) async {
    Dio client = getClient();

    QRTransactionIDRequest request = QRTransactionIDRequest(txnUid: txnId);

    try {
      final response = await client.post(
        CHECK_PAYMENT_ENDPOINT,
        data: request.toJson(),
      );

      QRPaymentStatusResponse qrPaymentResponseToJson = QRPaymentStatusResponse.fromJson(response.data);

      return qrPaymentResponseToJson;
    } on DioException catch (ex) {
      if (ex.response != null) {
        QRPaymentStatusResponse qrPaymentResponseToJson = QRPaymentStatusResponse(
          txnUid: "",
          txnNo: "",
          txnStatus: "ERROR",
          txnAmount: 0,
          channel: "ERROR",
          terminalId: "ERROR",
          qrType: "",
        );
        return qrPaymentResponseToJson;
      } else {
        String errorMessage = ex.response.toString();
        throw Exception(errorMessage);
      }
    }
  }

  Future<QRTransactionInquiryResponse> InquiryPayment(String txnId) async {
    Dio client = getClient();

    QRTransactionIDRequest request = QRTransactionIDRequest(txnUid: txnId);
    try {
      final response = await client.post(
        INQUIRY_PAYMENT_ENDPOINT,
        data: request.toJson(),
      );

      QRTransactionInquiryResponse qrPaymentResponseToJson = QRTransactionInquiryResponse.fromJson(response.data);

      return qrPaymentResponseToJson;
    } on DioException catch (ex) {
      if (ex.response != null) {
        CommonErrorResponse errorResponse = CommonErrorResponse.fromJson(ex.response!.data);

        QRTransactionInquiryResponse qrPaymentResponseToJson = QRTransactionInquiryResponse(
          partnerTxnUid: "",
          partnerId: "",
          statusCode: "ERROR",
          errorCode: "ERROR",
          errorDesc: errorResponse.Message,
          txnStatus: "",
          merchantId: "",
          terminalId: "",
          qrType: "",
          txnAmount: "",
          txnCurrencyCode: "",
          reference1: "",
          reference2: "",
          reference3: "",
          reference4: "",
        );
        return qrPaymentResponseToJson;
      } else {
        String errorMessage = ex.response.toString();
        throw Exception(errorMessage);
      }
    }
  }

  Future<List<QRTransactionResponse>> ListTransaction({int page = 0, int size = 10}) async {
    Dio client = getClient();

    try {
      final response = await client.get(
        "$LIST_TRANSACTION_ENDPOINT?page=$page&size=$size",
      );
      if (response.statusCode != 200) {
        throw Exception("Failed to load transactions");
      }
      // print(response.data['data']);
      List<QRTransactionResponse> qrPaymentResponseToJson = response.data['data'].map<QRTransactionResponse>((json) => QRTransactionResponse.fromJson(json)).toList();

      return qrPaymentResponseToJson;
    } on DioException catch (ex) {
      if (ex.response != null) {
        List<QRTransactionResponse> qrPaymentResponseToJsonArr = [];
        return qrPaymentResponseToJsonArr;
      } else {
        String errorMessage = ex.response.toString();
        throw Exception(errorMessage);
      }
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

  Future<QRTransactionCommonResponse> CancelPayment(String txnId) async {
    Dio client = getClient();

    QRTransactionIDRequest request = QRTransactionIDRequest(txnUid: txnId);
    try {
      final response = await client.post(
        CANCEL_PAYMENT_ENDPOINT,
        data: request.toJson(),
      );

      QRTransactionCommonResponse qrPaymentResponseToJson = QRTransactionCommonResponse.fromJson(response.data);

      return qrPaymentResponseToJson;
    } on DioException catch (ex) {
      if (ex.response != null) {
        // String errorMessage = ex.response.toString();
        CommonErrorResponse errorResponse = CommonErrorResponse.fromJson(ex.response!.data);

        QRTransactionCommonResponse qrPaymentResponseToJson = QRTransactionCommonResponse(
          partnerTxnUid: "",
          partnerId: "",
          statusCode: "ERROR",
          errorCode: "ERROR",
          errorDesc: errorResponse.Message,
        );

        return qrPaymentResponseToJson;
      } else {
        String errorMessage = ex.response.toString();
        throw Exception(errorMessage);
      }
    }
  }

  Dio getClient() {
    Dio client = Dio();
    client.options.baseUrl = uatMode ? UAT_API_ENDPOINT : API_ENDPOINT;
    client.options.headers['x-api-key'] = apiKey;

    return client;
  }
}
