import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lugentpayment/lugentpay.dart';
import 'package:lugentpayment/qrpayment_response.dart';
import 'dart:convert';

void main() {
  test('try json deserialization payment response', () {
    String jsonString = '''{
"res_code":"00",
"res_desc":"success",
"transactionId":"010555706234202ref1ref2",
"qrCode":"00020101021230550016A00000067701011201150105557062342020204ref10304ref253037645402555802TH5907SMLSOFT62180714LGN400001510016304599C"
  }''';

    Map<String, dynamic> jsonMap = json.decode(jsonString);
    QRPaymentResponse response = QRPaymentResponse.fromJson(jsonMap);

    expect(response.res_code, "00");
  });

  test('try json deserialization inquiry response', () {
    String jsonString = '''{
"res_code":"00",
"res_desc":"success",
"transactionId":"xxx",
"qrCode":"000201010212307...."
  }''';

    Map<String, dynamic> jsonMap = json.decode(jsonString);
    QRPaymentResponse response = QRPaymentResponse.fromJson(jsonMap);

    expect(response.res_code, "00");
  });

  test('try send create thaiqrpayment qrcode', () async {
    LugentPay lugentPayment = new LugentPay(
      billerCode: "LGN",
      billerID: "010555706234202",
      storeID: "4000015",
      terminalID: "1001",
      merchantName: "SMLSOFT",
      accessCode: "4TqvJ5jLQJPweLdnT4MhjML2jb5fSqfQ1KUWNNfi",
    );

    QRPaymentResponse response =
        await lugentPayment.CreateThaiQRPaymentTransaction(
            "ref1", "ref2", Decimal.parse('55'), "");

    expect(response.res_code, "00");
  });
}
