import 'package:decimal/decimal.dart';

class PaymentDataModel {
  PaymentDataModel(this.paymentMethod, this.amount, this.payToAccount);
  final PaymentMethod paymentMethod;
  final Decimal amount;
  String payToAccount;
}

enum PaymentMethod {
  thaiQRCode,
  lugentThaiQRCode,
  lugentTrueMoney,
  lugentLinePay,
  lugentAliPay,
  lugentBCELOnePay
}
