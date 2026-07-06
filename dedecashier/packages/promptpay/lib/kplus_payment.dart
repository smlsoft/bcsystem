import 'dart:convert';

import 'package:crclib/crclib.dart';
import 'package:promptpay/promptpay.dart';

const PromptPayBillPaymentTag = "30";
const PromptPayBillPaymentAIDTag = "00";
const PromptPayBillPaymentBillerIDTag = "01";
const PromptPayBillPaymentRef1Tag = "02";
const PromptPayBillPaymentRef2Tag = "03";

const PaymentInvocationTag = "31";
const PaymentInvocationAIDTag = "00";
const PaymentInvocationAcquirerIDTag = "01";
const PaymentInvocationAcquirerSpecial02Tag = "02";
const PaymentInvocationAcquirerSpecial04Tag = "04";

const PayPromptPayBillPaymentApplicationID = "A000000677010112";
const PayInnovationPaymentApplicationID = "A000000677010113";

class KplusPayment extends PromptPay {
  static String generateQRData(String kplusId, {double? amount}) {
    var payTag30Data = "0016${PayPromptPayBillPaymentApplicationID}01150107536000315080214${kplusId.substring(kplusId.length - 14)}0320$kplusId";

    var PayTag31Data = "0016${PayInnovationPaymentApplicationID}01030040214${kplusId.substring(kplusId.length - 14)}0420$kplusId";

    var data = [
      versionID,
      versionLength,
      versionData,
      qrTypeID,
      qrTypeLength,
      qrMultipleTypeData,

      PromptPayBillPaymentTag,
      payTag30Data.length.toString().padLeft(2, '0'),
      payTag30Data,

      PaymentInvocationTag,
      PayTag31Data.length.toString().padLeft(2, '0'),
      PayTag31Data,
      //merchantAccountID,
      //merchantAccountLength,

      //subMerchantApplicationID,
      //subMerchantApplicationIDLength,
      //applicationIDData,
      // PromptPay._getAccountID(accountType),
      // PromptPay._getAccountLength(accountType, target),
      // PromptPay._formatAccount(accountType, target),

      currencyID,
      currencyLength,
      bahtCurrencyData,
      countryID,
      countryLength,
      countryData,
    ];

    if (amount != null) {
      data.add(amountID);
      data.add(_formatAmount(amount).length.toString().padLeft(2, '0'));
      data.add(_formatAmount(amount));
    }

    data.add(checksumID);
    data.add(checksumLength);

    var checksum = _getCrc16XOR()
        .convert(utf8.encode(data.join()))
        .toRadixString(16)
        .toUpperCase();

    return data.join() + checksum;
  }

  static _formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  static ParametricCrc _getCrc16XOR() {
    // width=16 poly=0x1021 init=0x0000 refin=false refout=false xorout=0x0000 check=0x31c3 residue=0x0000 name="CRC-16/XOR"
    return ParametricCrc(16, 0x1021, 0xFFFF, 0x0000,
        inputReflected: false, outputReflected: false);
  }
}
