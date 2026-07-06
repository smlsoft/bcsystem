import 'package:smlaicloud/model/transaction_model.dart';

double _calTotalByDefualt(double totalvalue, double totalExceptvat, double discount) {
  double totalvalue = 0;
  return totalvalue;
}

double calSumAmount(double qty, double price, String discount) {
  double sumamount = 0.0;
  double discountAmount = 0.0;
  sumamount = qty * price;
  if (discount.contains('%')) {
    String discountWord = discount.replaceAll('%', '');
    discountAmount = (sumamount * double.parse(discountWord)) / 100;
  } else if (discount.trim().isNotEmpty) {
    discountAmount = double.parse(discount);
  }

  return discountAmount;
}

TransactionModel calTotalValue(TransactionModel screenData) {
  double totalValue = 0;
  double totalexceptvat = 0;

  for (var val in screenData.details!) {
    double discountAmount = calSumAmount(val.qty, val.price, val.discount);
    val.sumamount = (val.qty * val.price) - discountAmount;
    if (val.sumamount < 0) {
      val.sumamount = 0;
    }
    val.discountamount = discountAmount;
    val.totalqty = val.qty;
    val.vattype = screenData.vattype;
    if (screenData.vattype == 1) {
      if (val.vatcal == 1) {
        val.priceexcludevat = val.price;
        val.sumamountexcludevat = val.sumamount;
        val.totalvaluevat = 0;
      } else {
        val.priceexcludevat = (val.price * 100) / (100 + screenData.vatrate);
        val.sumamountexcludevat = (val.sumamount * 100) / (100 + screenData.vatrate);
        val.totalvaluevat = (val.sumamount * screenData.vatrate) / (100 + screenData.vatrate);
      }
    } else if (screenData.vattype == 0) {
      val.priceexcludevat = val.price;
      val.sumamountexcludevat = val.sumamount;
      val.totalvaluevat = (val.sumamount * screenData.vatrate) / 100;
    } else {
      val.priceexcludevat = val.price;
      val.sumamountexcludevat = val.sumamount;
      val.totalvaluevat = 0;
    }

    if (val.vatcal == 1) {
      totalexceptvat += val.sumamount;
    }
    totalValue += val.sumamount;

    val.inquirytype = screenData.inquirytype;
    val.vattype = screenData.vattype;
  }

  /// ไม่บันทึกยอดเงินเอง คำนวนจากโปรแกรม
  if (!screenData.ismanualamount) {
    double sumAmountTax0 = totalValue - totalexceptvat;
    double sumAmountTax1 = totalexceptvat;

    int optionNumber = 0;
    double valueForCal = 0;
    if (optionNumber == 0) {
      double val1 = 0;
      val1 = sumAmountTax0 - screenData.totaldiscount;
      if (val1 < 0) {
        sumAmountTax1 = sumAmountTax1 + val1;
        val1 = 0;
      }
      if (sumAmountTax1 < 0) {
        sumAmountTax1 = 0;
      }
      valueForCal = val1;

      screenData.totalexceptvat = sumAmountTax1;
    } else {
      screenData.totalexceptvat = totalexceptvat;
    }

    if (screenData.vattype == 1) {
      screenData.totalvatvalue = ((valueForCal) * screenData.vatrate) / (100 + screenData.vatrate);
      screenData.totalbeforevat = ((valueForCal) - screenData.totalvatvalue);
    } else if (screenData.vattype == 0) {
      screenData.totalbeforevat = valueForCal;
      screenData.totalvatvalue = ((valueForCal) * screenData.vatrate) / 100;
    } else {
      screenData.totalbeforevat = valueForCal;
      screenData.totalvatvalue = 0;
    }

    screenData.totalvalue = totalValue;
    screenData.totalaftervat = screenData.totalvatvalue + screenData.totalbeforevat;
    screenData.totalamount = screenData.totalexceptvat + screenData.totalaftervat;
  }
  return screenData;
}
