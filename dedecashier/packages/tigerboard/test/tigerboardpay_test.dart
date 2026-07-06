// import 'dart:convert';
// import 'dart:io';

// import 'package:decimal/decimal.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:xenditpay/xenditpay.dart';
// import 'package:xenditpay/models/models.dart';

// void main() {
//   final String testPublicKey = String.fromEnvironment("PAYMENT_PUBLIC_KEY");
//   final String testSecretKey = String.fromEnvironment("PAYMENT_SECRET_KEY");
//   final String testToken = String.fromEnvironment("PAYMENT_ACCESS_TOKEN");
//   final String testDeviceId = "ORDER001";

//   test('test gen refcode', () {
//     final DeviceID = "REF000001";
//     GBPrimePay gbPrimePay = GBPrimePay(
//         accessToken: testToken,
//         secretKey: testSecretKey,
//         publicKey: testPublicKey);

//     DateTime date = DateTime(2023, 10, 31, 1, 16, 59, 0, 0);
//     String dateStr = gbPrimePay.genRefUnixTime(date, DeviceID);

//     final String want = "000011698689819";
//     expect(dateStr, want);
//   });

//   test('try decode result error', () {
//     final String genQRErrorResult = """
// {
//     "resultCode": "90",
//     "resultMessage": "Incomplete information"
// }
// """;

//     Map<String, dynamic> jsonMap = json.decode(genQRErrorResult);
//     GBPaymentGenQRResponse response = GBPaymentGenQRResponse.fromJson(jsonMap);

//     expect(response.resultCode, "90");
//     expect(response.resultMessage, "Incomplete information");
//   });

//   test('try decode gen qr response success', () {
//     final String genQRSuccessResult = """
// {
//     "referenceNo": "231027064705125",
//     "qrcode": "00020101021230830016A0000006770101120115010556006812748021800000023102805242203180002310270647051255303764540515.005802TH5910GBPrimePay6304F10B",
//     "resultCode": "00",
//     "gbpReferenceNo": "gbp520141144787975",
//     "resultMessage": "Success"
// }
// """;

//     Map<String, dynamic> jsonMap = json.decode(genQRSuccessResult);
//     GBPaymentGenQRResponse response = GBPaymentGenQRResponse.fromJson(jsonMap);

//     expect(response.resultCode, "00");
//     expect(response.resultMessage, "Success");
//     expect(response.referenceNo, "231027064705125");
//     expect(response.qrcode,
//         "00020101021230830016A0000006770101120115010556006812748021800000023102805242203180002310270647051255303764540515.005802TH5910GBPrimePay6304F10B");
//     expect(response.gbpReferenceNo, "gbp520141144787975");
//   });

//   test('test gen date time', () {
//     DateTime date = DateTime(2023, 10, 28, 5, 24, 22, 0, 0);
//     GBPrimePay gbPrimePay = GBPrimePay(
//         accessToken: testToken,
//         secretKey: testSecretKey,
//         publicKey: testPublicKey);
//     String dateStr = gbPrimePay.genRefFromTime(date);
//     expect(dateStr, "231028052422");
//   });

//   test('test request gen qrcode', () async {
//     GBPrimePay gbPrimePay = GBPrimePay(
//         accessToken: testToken,
//         secretKey: testSecretKey,
//         publicKey: testPublicKey);

//     String refFromDateTime = gbPrimePay.genRefFromTime(DateTime.now());
//     final response = await gbPrimePay.generateQRPayment(
//         refFromDateTime, Decimal.fromInt(33));

//     expect(response.resultCode, "00");
//   });

//   test('test decode query response assert not pay', () {
//     final String queryResponse = """
// {
//     "resultCode": "00",
//     "txn": {
//         "amount": "33.00",
//         "referenceNo": "231029174050",
//         "gbpReferenceNo": "gbp520141145009386",
//         "merchantDefined5": null,
//         "merchantDefined3": null,
//         "merchantDefined4": null,
//         "merchantDefined1": null,
//         "status": "G",
//         "paymentType": "Q",
//         "merchantDefined2": null
//     },
//     "resultMessage": "Success"
// }
//     """;

//     GBInquiryPaymentResponse response =
//         GBInquiryPaymentResponse.fromJson(json.decode(queryResponse));

//     expect(response.resultCode, "00");
//     expect(response.resultMessage, "Success");
//     expect(response.isPaymentSuccess(), false);
//   });

//   test('test query payment from gb host', () async {
//     GBPrimePay gbPrimePay = GBPrimePay(
//         accessToken: testToken,
//         secretKey: testSecretKey,
//         publicKey: testPublicKey);

//     final String referenceNo = "231029174050";

//     GBInquiryPaymentResponse response =
//         await gbPrimePay.inquiryQRPayment(referenceNo);
//     expect(response.resultCode, "00");
//     expect(response.resultMessage, "Success");
//     expect(response.isPaymentSuccess(), false);
//   });

//   test('test gen qr code response image', () async {
//     GBPrimePay gbPrimePay = GBPrimePay(
//         accessToken: testToken,
//         secretKey: testSecretKey,
//         publicKey: testPublicKey);

//     final String reference = gbPrimePay.genRefUnixTimeNow(testDeviceId);
//     final qrResponse = await gbPrimePay.generateImageThaiQRPayment(
//         reference, Decimal.fromInt(8));

//     expect(qrResponse.resultCode, "00");
//     expect(qrResponse.resultMessage, "Success");

//     // write image to local
//     final file = File("qrcode.png");
//     final raf = file.openSync(mode: FileMode.write);
//     // response.data is List<int> type
//     raf.writeFromSync(qrResponse.qrImageData!);
//     await raf.close();
//   });
// }
