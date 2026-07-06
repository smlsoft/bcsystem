import 'package:dedecashier/global.dart' as global;

double sumCreditCard(activeNumber) {
  double result = 0.0;
  for (var data in global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.credit_card) {
    result += data.amount;
  }
  return result;
}

double sumTransfer(activeNumber) {
  double result = 0.0;
  for (var data in global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.transfer) {
    result += data.amount;
  }
  return result;
}

double sumCheque(activeNumber) {
  double result = 0.0;
  for (var data in global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.cheque) {
    result += data.amount;
  }
  return result;
}

double sumQr(activeNumber) {
  double result = 0.0;
  for (var data in global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.qr) {
    result += data.amount;
  }
  return result;
}

double sumRoundAmount(activeNumber, index) {
  double result = 0.0;

  if (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.cash_amount > 0 || index == 0) {
    result += global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.round_amount_cash;
  }

  if (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.qr.isNotEmpty || index == 2) {
    result += global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.round_amount_qr;
  }
  if (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.credit_card.isNotEmpty || index == 3) {
    result += global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.round_amount_credit_card;
  }
  if (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.transfer.isNotEmpty || index == 4) {
    result += global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.round_amount_transfer;
  }
  if (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.cheque.isNotEmpty || index == 5) {
    result += global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.round_amount_cheque;
  }
  if (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.coupon.isNotEmpty || index == 6) {
    result += global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.round_amount_coupon;
  }
  if (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.credit_amount > 0 || index == 7) {
    result += global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.round_amount_credit;
  }

  return result;
}

double sumCoupon(activeNumber) {
  double result = 0.0;
  for (var data in global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.coupon) {
    result += data.amount; // ใช้ getter ที่รวม discount + cash voucher
  }
  return result;
}

// เพิ่มฟังก์ชันแยกส่วน
double sumCouponDiscount(activeNumber) {
  double result = 0.0;
  for (var data in global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.coupon) {
    result += data.discount_amount;
  }
  return result;
}

double sumCouponPay(activeNumber) {
  double result = 0.0;
  for (var data in global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.coupon) {
    result += data.cash_voucher_amount;
  }
  return result;
}

double sumCouponCashVoucher(activeNumber) {
  double result = 0.0;
  for (var data in global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.coupon) {
    result += data.cash_voucher_amount;
  }
  return result;
}

double diffAmount(activeNumber) {
  double totalAmount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].posProcess.total_amount;
  double sumCash = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.cash_amount;
  // double sumDiscount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.discount_amount;
  double sumTotalPayAmount =
      (sumCash + sumCouponCashVoucher(activeNumber) + sumCreditCard(activeNumber) + sumTransfer(activeNumber) + sumCheque(activeNumber) + sumQr(activeNumber)) - global.posHoldProcessResult[global.findPosHoldProcessResultIndex(activeNumber)].payScreenData.round_amount;

  double diffamount = totalAmount - sumTotalPayAmount;
  if (diffamount < 0) {
    diffamount = 0;
  }
  return diffamount;
}
