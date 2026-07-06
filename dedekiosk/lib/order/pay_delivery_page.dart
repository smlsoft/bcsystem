import 'dart:async';
import 'dart:typed_data';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/widget/count_down.dart';
import 'package:flutter/material.dart';
import 'package:gbprimepay/gbprimepay.dart';
import 'package:gbprimepay/models/gb_inquiry_payment_response.dart';
import 'package:gbprimepay/models/gb_payment_gen_qr_response.dart';
import 'package:xenditpay/models/models.dart';
import 'package:xenditpay/xenditpay.dart';
import 'package:lugentpayment/inquiry_payment_response.dart';
import 'package:lugentpayment/qrpayment_response.dart';
import 'package:lugentpayment/lugentpay.dart';
import 'package:promptpay/promptpay.dart';
import 'package:decimal/decimal.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kapi/models/models.dart';
import 'package:kapi/smlkapi.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class PayDeliveryPage extends StatefulWidget {
  final double amount;
  final double payCashAmount;
  final double roundAmount;

  const PayDeliveryPage({super.key, required this.amount, required this.payCashAmount, required this.roundAmount});

  @override
  PayDeliveryPageState createState() => PayDeliveryPageState();
}

class PayDeliveryPageState extends State<PayDeliveryPage> {
  bool paySuccess = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void savePay() {
    // สำเร็จ
    paySuccess = true;
    global.payCondition.add(PayConditionModel(
      payType: 4,
      amount: widget.amount,
      payAmount: widget.amount - widget.payCashAmount,
      roundAmount: widget.roundAmount,
      changeAmount: 0,
      payTypeName: global.saleChannelCode,
    ));
    if (mounted) {
      String message = global.findLanguage(code: "successfully_received_payment_printing_receipt", languageCode: global.languageForCustomer);
      global.textToSpeech(message);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget totalAmountWidget = Container(
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 400),
        width: double.infinity,
        child: FittedBox(child: Text("${global.language("amount")} ${global.moneyFormat.format(widget.amount - widget.payCashAmount)} ${global.language("money_baht")}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))));
    return Scaffold(
      body: Container(
          margin: const EdgeInsets.all(10),
          width: double.infinity,
          child: Column(children: [
            totalAmountWidget,
            const SizedBox(height: 10),
            if (widget.roundAmount > 0)
              Container(
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(maxWidth: 400),
                  width: double.infinity,
                  child: FittedBox(child: Text("${global.language("round_money")} ${global.moneyFormat.format(widget.roundAmount)} ${global.language("money_baht")}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)))),
            Expanded(
                child: Column(
              children: [
                Expanded(
                    child: (global.shopProfile!.orderstation.salechannels!.firstWhere((element) => element.code == global.saleChannelCode).imageuri.isNotEmpty)
                        ? Image.network(global.shopProfile!.orderstation.salechannels!.firstWhere((element) => element.code == global.saleChannelCode).imageuri)
                        : Container()),
                Row(children: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: Text(global.language("cancel"))),
                  const Spacer(),
                  ElevatedButton(
                      onPressed: () {
                        savePay();
                      },
                      child: Text(global.language("confirm")))
                ])
              ],
            ))
          ])),
    );
  }
}
