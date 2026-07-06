import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapi/models/models.dart';
import 'package:kapi/smlkapi.dart';

void main() {
  final String giveToken =
      "135ef7ed0fd021b5d963138a4fa6b5abdf8c54e408a205b0ce3a5371fab5581a";
  test('test gen qrcode', () async {
    SMLKBankConnector smlKApiConnector =
        new SMLKBankConnector(apiKey: giveToken, uatMode: true);

    QRGenerateResponse qrGenerateResponse =
        await smlKApiConnector.CreateQRPromptPayTransaction(
            Decimal.parse("250.05"), "ref1", "ref2", "ref3", "ref4");

    expect(qrGenerateResponse, isNotNull);
    expect(qrGenerateResponse.qrCode, isNotNull);
    expect(qrGenerateResponse.errorCode, "");
  });

  test('check payment status', () async {
    SMLKBankConnector smlKApiConnector =
        new SMLKBankConnector(apiKey: giveToken, uatMode: true);

    var response = await smlKApiConnector.CheckPayment("SML000000000201");

    expect(response, isNotNull);
    expect(response.txnUid, "SML000000000201");
    // expect(response.txnStatus, "REQUESTED");
  });

  test('test inquiry qrcode', () async {
    SMLKBankConnector smlKApiConnector =
        new SMLKBankConnector(apiKey: giveToken, uatMode: true);

    var response = await smlKApiConnector.InquiryPayment("SML000000000201");

    expect(response, isNotNull);
    expect(response.statusCode, "00");
  });

  test('test Cancel QR Code', () async {
    SMLKBankConnector smlKApiConnector =
        new SMLKBankConnector(apiKey: giveToken, uatMode: true);

    var response = await smlKApiConnector.CancelPayment("SML000000000201");

    expect(response, isNotNull);
  });
}
