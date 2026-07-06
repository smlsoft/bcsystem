import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/json/customer_display_model.dart';
import 'package:flutter/material.dart';
import 'package:kapi/models/qr_generate_response.dart';
import 'package:kapi/smlkapi.dart';
import 'package:lugentpayment/inquiry_payment_response.dart';
import 'package:lugentpayment/lugentpay.dart';
import 'package:lugentpayment/qrpayment_response.dart';
import 'package:promptpay/kplusshop_payment.dart';

import 'package:promptpay/promptpay.dart';
// import 'package:countdown_progress_indicator/countdown_progress_indicator.dart';
import 'package:gbprimepay/gbprimepay.dart';
import 'package:gbprimepay/models/gb_inquiry_payment_response.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:xenditpay/models/xendit_payment_gen_thai_qr_response.dart';
import 'package:xenditpay/models/xendit_payment_pay_thai_qr_response.dart';
import 'package:xenditpay/xenditpay.dart';
import 'package:tigerboard/tigerboard.dart';
import 'package:tigerboard/models/models.dart';
import 'package:intl/intl.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class PayQrScreen extends StatefulWidget {
  final ProfileQrPaymentModel provider;
  final String customerCode;
  final String posId;
  final double amount;
  final BuildContext context;

  const PayQrScreen({
    super.key,
    required this.provider,
    required this.amount,
    required this.context,
    required this.customerCode,
    required this.posId,
  });

  @override
  State<PayQrScreen> createState() => _PayQrScreenState();
}

class _PayQrScreenState extends State<PayQrScreen>
    with TickerProviderStateMixin {
  // final countDownController = CountDownController();
  bool qrCodeCreateSuccess = false;
  String qrCodePayDataString = "";
  String transactionId = "";
  late Uint8List qrCodeImage;
  String qrCodeString = "";
  late Timer paymentTimer;
  bool paySuccess = false;
  bool tigerCancel = true;

  Future<QRPaymentResponse> qrLugentPromptPay() async {
    // Promptpay ลูเจ้นท์ ไทย
    LugentPay lugentPay = LugentPay.InitDemoInstance();
    QRPaymentResponse qrPayment =
        await lugentPay.CreateThaiQRPaymentTransaction(
          lugentPay.CreateReferenceWithUnixTime("SMLINV"),
          "SMLSOFT",
          Decimal.parse(widget.amount.toString()),
          "",
        );
    return qrPayment;
  }

  Future<QRPaymentResponse> qrLugentAliPay() async {
    // Promptpay ลูเจ้นท์ ไทย
    LugentPay lugentPay = LugentPay.InitDemoInstance();
    QRPaymentResponse qrPayment = await lugentPay.CreateAliPayTransaction(
      lugentPay.CreateReferenceWithUnixTime("SMLINV"),
      "SMLSOFT",
      Decimal.parse(widget.amount.toString()),
      "",
    );
    return qrPayment;
  }

  Future<QRPaymentResponse> qrLugentTrueMoney() async {
    // Promptpay ลูเจ้นท์ ไทย
    LugentPay lugentPay = LugentPay.InitDemoInstance();
    QRPaymentResponse qrPayment = await lugentPay.CreateTrueMoneyTransaction(
      "ค่าอาหาร",
      "่ค่าบริการ",
      "https://dedeposblosstorage.blob.core.windows.net/dedeposassets/app_logo.png",
      lugentPay.CreateReferenceWithUnixTime("SMLINV"),
      "SMLSOFT",
      Decimal.parse(widget.amount.toString()),
      "",
    );
    return qrPayment;
  }

  Future<XenditPaymentGenQRResponse> qrXenditPayThaiQR(
    ProfileQrPaymentModel paymentProfile,
  ) async {
    XenditPay xenditPay = XenditPay(accessToken: paymentProfile.apikey!);
    String key = global.generateRandomString(5);
    String refCode = xenditPay.genRefUnixTimeNow(key);

    DateTime now = DateTime.now();
    DateTime expiryDate = now.add(const Duration(minutes: 15));

    String expiryDateISO = DateFormat(
      "yyyy-MM-ddTHH:mm:ss'Z'",
    ).format(expiryDate.toUtc());

    return await xenditPay.generateQRPayment(
      refCode,
      widget.amount,
      "THB",
      expiryDateISO,
    );
  }

  Future<PaymentGenQRResponse> payTigerBoard(
    ProfileQrPaymentModel paymentProfile,
  ) async {
    TigerBoard tigerBoard = TigerBoard(
      appId: paymentProfile.accessCode!,
      apiKey: paymentProfile.apikey!,
    );

    return await tigerBoard.generatePayrequest(
      widget.customerCode,
      widget.posId,
      widget.amount,
    );
  }

  Future<QRGenerateResponse> qrSMLPromptPay(
    ProfileQrPaymentModel paymentProfile,
  ) async {
    SMLKBankConnector smlKApiConnector = SMLKBankConnector(
      apiKey: paymentProfile.apikey!,
      uatMode: false,
    );

    String key = global.generateRandomString(5);
    String refCode = smlKApiConnector.genRefUnixTimeNow(key);
    String refCode2 = smlKApiConnector.genRefUnixTimeNow(key);
    String refCode3 = smlKApiConnector.genRefUnixTimeNow(key);
    String refCode4 = smlKApiConnector.genRefUnixTimeNow(key);

    QRGenerateResponse qrGenerateResponse =
        await smlKApiConnector.CreateQRPromptPayTransaction(
          Decimal.parse(widget.amount.toString()),
          refCode,
          refCode2,
          refCode3,
          refCode4,
        );

    return qrGenerateResponse;
  }

  Future<QRGenerateResponse> qrSMLCredit(
    ProfileQrPaymentModel paymentProfile,
  ) async {
    SMLKBankConnector smlKApiConnector = SMLKBankConnector(
      apiKey: paymentProfile.apikey!,
      uatMode: false,
    );

    String key = global.generateRandomString(5);
    String refCode = smlKApiConnector.genRefUnixTimeNow(key);
    String refCode2 = smlKApiConnector.genRefUnixTimeNow(key);
    String refCode3 = smlKApiConnector.genRefUnixTimeNow(key);
    String refCode4 = smlKApiConnector.genRefUnixTimeNow(key);

    QRGenerateResponse qrGenerateResponse =
        await smlKApiConnector.CreateQRCreditCardTransaction(
          Decimal.parse(widget.amount.toString()),
          refCode,
          refCode2,
          refCode3,
          refCode4,
        );

    return qrGenerateResponse;
  }

  Future<QRPaymentResponse> qrLugentLinePay() async {
    // Promptpay ลูเจ้นท์ ไทย
    LugentPay lugentPay = LugentPay.InitDemoInstance();
    QRPaymentResponse qrPayment = await lugentPay.CreateLinePayTransaction(
      lugentPay.CreateReferenceWithUnixTime("SMLINV"),
      "SMLSOFT",
      Decimal.parse(widget.amount.toString()),
      "",
    );
    return qrPayment;
  }

  Future<void> createQrCode() async {
    qrCodeString = "";
    switch (widget.provider.qrtype) {
      case 100:
        // Promptpay ทั่วไป
        qrCodePayDataString = PromptPay.generateQRData(
          widget.provider.qrcode,
          amount: (widget.amount).toDouble(),
        );
        qrCodeImage = await global.toQrImageData(qrCodePayDataString);
        qrCodeCreateSuccess = true;
        setState(() {});
        break;
      case 101:
        // Kplus ทั่วไป
        qrCodePayDataString = KplusshopPayment.generateQRData(
          widget.provider.billerID!,
          amount: (widget.amount).toDouble(),
        );
        qrCodeImage = await global.toQrImageData(qrCodePayDataString);
        qrCodeCreateSuccess = true;
        setState(() {});
        break;
      case 110:
        // Promptpay ลูเจ้นท์ ไทย
        await qrLugentAliPay().then((qrPayment) async {
          qrCodePayDataString = qrPayment.qrCode;
          if (qrPayment.isSuccess()) {
            transactionId = qrPayment.transactionId;
            qrCodePayDataString = qrPayment.qrCode;
          }
        });
        break;
      case 111:
        // AliPay ลูเจ้นท์ ไทย
        await qrLugentAliPay().then((qrPayment) async {
          qrCodePayDataString = qrPayment.qrCode;
          if (qrPayment.isSuccess()) {
            transactionId = qrPayment.transactionId;
            qrCodePayDataString = qrPayment.qrCode;
          }
        });
        break;
      case 112:
        // True Money ลูเจ้นท์ ไทย
        await qrLugentTrueMoney().then((qrPayment) async {
          qrCodePayDataString = qrPayment.qrCode;
          if (qrPayment.isSuccess()) {
            transactionId = qrPayment.transactionId;
            qrCodePayDataString = qrPayment.qrCode;
          }
        });
        break;
      case 113:
        // Line Pay ลูเจ้นท์ ไทย
        await qrLugentLinePay().then((qrPayment) async {
          qrCodePayDataString = qrPayment.qrCode;
          if (qrPayment.isSuccess()) {
            transactionId = qrPayment.transactionId;
            qrCodePayDataString = qrPayment.qrCode;
          }
        });
        break;
      case 114:
        // WeChat Pay ลูเจ้นท์ ไทย
        await qrLugentLinePay().then((qrPayment) async {
          qrCodePayDataString = qrPayment.qrCode;
          if (qrPayment.isSuccess()) {
            transactionId = qrPayment.transactionId;
            qrCodePayDataString = qrPayment.qrCode;
          }
        });
        break;
      case 131:
        // GB PrimePay Thai QR
        await global
            .qrGBPrimePayThaiQR(
              paymentProfile: widget.provider,
              qrAmount: (global.isDemoMode) ? 1 : widget.amount,
            )
            .then((qrPayment) async {
              if (qrPayment.isSuccess()) {
                transactionId = qrPayment.referenceNo!;
                qrCodePayDataString = "GB PrimePay Thai QR";
                qrCodeImage = qrPayment.qrImageData!;
                global.customerDisplayQrData = CustomerDisplayQrData(
                  widget.provider,
                  widget.amount,
                  qrCodePayDataString,
                  base64Encode(qrCodeImage),
                  qrCodeString,
                );
                qrCodeCreateSuccess = true;
                global.sendProcessToCustomerDisplay(
                  mode: global.secondScreenCommandPay,
                );
              } else {
                AppLogger.error('error');
              }
            });
        break;
      case 201:
        await qrXenditPayThaiQR(widget.provider).then((qrPayment) async {
          qrCodePayDataString = "Xendit Pay Thai QR";
          if (qrPayment.id.isNotEmpty) {
            transactionId = qrPayment.id;
            qrCodePayDataString = qrPayment.qr_string;
            qrCodeImage = await global.toQrImageData(qrCodePayDataString);
            qrCodeCreateSuccess = true;
          }
        });
        break;
      case 301:
        await qrSMLPromptPay(widget.provider).then((qrPayment) async {
          qrCodePayDataString = "SML PromptPay";
          if (qrPayment.statusCode == "00") {
            if (qrPayment.qrCode.isNotEmpty) {
              transactionId = qrPayment.txnUid;
              qrCodePayDataString = qrPayment.qrCode;
              qrCodeImage = await global.toQrImageData(qrCodePayDataString);
              qrCodeString = qrCodePayDataString;
              qrCodeCreateSuccess = true;
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Fail ${qrPayment.errorCode}"),
                backgroundColor: Colors.deepOrange,
              ),
            );
          }
        });
        break;
      case 302:
        await qrSMLCredit(widget.provider).then((qrPayment) async {
          qrCodePayDataString = "SML Credit";
          if (qrPayment.statusCode == "00") {
            if (qrPayment.qrCode.isNotEmpty) {
              transactionId = qrPayment.txnUid;
              qrCodePayDataString = qrPayment.qrCode;
              qrCodeImage = await global.toQrImageData(qrCodePayDataString);
              qrCodeString = qrCodePayDataString;
              qrCodeCreateSuccess = true;
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Fail ${qrPayment.errorCode}"),
                backgroundColor: Colors.deepOrange,
              ),
            );
          }
        });
        break;
      case 401:
        await payTigerBoard(widget.provider).then((qrPayment) async {
          qrCodePayDataString = "";

          if (qrPayment.status == "new") {
            qrCodeCreateSuccess = true;
            transactionId = qrPayment.id.toString();
            setState(() {});
          }
        });
        break;
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose

    paymentTimer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    createQrCode().then((_) {
      paymentTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (transactionId.isNotEmpty && paySuccess == false) {
          if (widget.provider.qrtype == 131) {
            AppLogger.debug('trx : $transactionId');
            GBPrimePay primePay = GBPrimePay(
              publicKey: widget.provider.apikey!,
              accessToken: widget.provider.token,
              secretKey: widget.provider.accessCode!,
            );

            GBInquiryPaymentResponse response = await primePay.inquiryQRPayment(
              transactionId,
            );
            if (response.isPaymentSuccess()) {
              if (mounted) {
                Navigator.pop(context, true);
              }
            }
          } else if (widget.provider.qrtype == 201) {
            XenditPay xenditPay = XenditPay(
              accessToken: widget.provider.apikey!,
            );

            XenditPaymentPayQRResponse response = await xenditPay
                .inquiryQRPayment(transactionId);
            if (response.data.isNotEmpty) {
              if (response.data[0].status == "SUCCEEDED") {
                if (mounted) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context, true);
                  }
                }
              }
            }
          } else if (widget.provider.qrtype == 301 ||
              widget.provider.qrtype == 302) {
            SMLKBankConnector smlKApiConnector = SMLKBankConnector(
              apiKey: widget.provider.apikey!,
              uatMode: false,
            );

            var response = await smlKApiConnector.CheckPayment(transactionId);

            if (response.txnStatus == "PAID") {
              if (mounted) {
                // Navigator.pop(context, true);
                if (Navigator.canPop(context)) {
                  Navigator.pop(context, {
                    'success': true,
                    'transactionId': transactionId,
                  });
                }
              }
            }
          } else if (widget.provider.qrtype == 401) {
            TigerBoard tigerBoard = TigerBoard(
              apiKey: widget.provider.apikey!,
              appId: widget.provider.accessCode!,
            );

            PaymentGenQRResponse response = await tigerBoard.inquiryPayment(
              transactionId,
            );
            if (response.status == "success") {
              Navigator.pop(context, true);
            } else if (response.status == "cancel") {
              Navigator.pop(context, false);
            } else if (response.status == "failed") {
              Navigator.pop(context, false);
            } else if (response.status == "new") {
              tigerCancel = true;
            } else if (response.status == "processing") {
              setState(() {
                tigerCancel = false;
              });
            }
          } else {
            // ตรวจสอบรายการ Order เพื่อพิมพ์ใบเสร็จ
            LugentPay lugentPay = LugentPay.InitDemoInstance();
            InquiryPaymentResponse inquiryPaymentResponse =
                await lugentPay.InquiryPayment(transactionId);
            if (inquiryPaymentResponse.isApproved()) {
              if (mounted) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context, true);
                }
              }
            }
          }
        }
      });
      if (mounted) {
        global.customerDisplayQrData = CustomerDisplayQrData(
          widget.provider,
          widget.amount,
          qrCodePayDataString,
          base64Encode(qrCodeImage),
          qrCodeString,
        );
        global.customerDisplayCommand = "qr";
        if (qrCodeCreateSuccess) {
          global.sendProcessToCustomerDisplay(
            mode: global.secondScreenCommandPay,
          );
        }
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    List<Widget> titleList = [
      if (widget.provider.qrtype != 401)
        FittedBox(
          child: Text(
            global.getNameFromLanguage(
              widget.provider.qrnames!,
              global.userScreenLanguage,
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      if (widget.provider.logo.isNotEmpty)
        Container(
          margin: const EdgeInsets.all(5),
          width: 100,
          height: 100,
          child: Image.network(fit: BoxFit.fill, widget.provider.logo),
        ),
      // SizedBox(
      //     width: 100,
      //     height: 100,
      //     child: CountDownProgressIndicator(
      //       controller: countDownController,
      //       valueColor: Colors.red,
      //       backgroundColor: Colors.blue,
      //       initialPosition: 0,
      //       duration: 5 * 60,
      //       text: global.language('time_remaining_to_complete_the_transaction'),
      //       onComplete: () {
      //         Navigator.pop(context, false);
      //       },
      //       timeFormatter: (seconds) {
      //         return Duration(seconds: seconds).toString().split('.')[0].substring(2);
      //       },
      //     )),
      FittedBox(
        fit: BoxFit.fitWidth,
        child: Text(
          global.getNameFromLanguage(
            widget.provider.bookbanknames!,
            global.userScreenLanguage,
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      FittedBox(
        fit: BoxFit.fitWidth,
        child: Text(
          widget.provider.bookbankcode,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      FittedBox(
        fit: BoxFit.fitWidth,
        child: Text(
          '${global.language('money_amount')} : ${global.moneyFormat.format(widget.amount)} ${global.language('money_symbol')}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            shadows: [
              Shadow(
                blurRadius: 5.0,
                color: Colors.grey,
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
        ),
      ),
      (widget.provider.qrcode.isNotEmpty)
          ? FittedBox(
              fit: BoxFit.fitWidth,
              child: Text(
                widget.provider.qrcode,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : Container(),
    ];
    Widget title = Padding(
      padding: const EdgeInsets.all(10),
      child: (isPortrait)
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: titleList,
            )
          : Column(children: titleList),
    );
    Widget qr = SizedBox(
      width: (isPortrait) ? 220 : 400,
      height: (isPortrait) ? 220 : 400,
      child: (qrCodePayDataString.isEmpty)
          ? (widget.provider.qrtype == 401 && qrCodeCreateSuccess)
                ? Column(
                    children: [
                      const Center(
                        child: Text(
                          "กรุณาชำระที่เครื่องรับเงิน",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          "รหัส: $transactionId\n${widget.posId}-${(widget.customerCode == "") ? "ลูกค้าทั่วไป" : widget.customerCode}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator())
          : Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: (qrCodeCreateSuccess == false)
                  ? Container()
                  : (qrCodeString.isNotEmpty)
                  ? QrImageView(data: qrCodeString, version: QrVersions.auto)
                  : Image.memory(fit: BoxFit.fitHeight, qrCodeImage),
            ),
    );

    Widget command = Row(
      children: [
        if (tigerCancel)
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.cancel),
              onPressed: () async {
                global.playSound(sound: global.SoundEnum.buttonTing);
                if (widget.provider.qrtype == 401) {
                  TigerBoard tigerBoard = TigerBoard(
                    apiKey: widget.provider.apikey!,
                    appId: widget.provider.accessCode!,
                  );
                  try {
                    PaymentGenQRResponse response = await tigerBoard
                        .cancelPayment(transactionId);
                    if (response.status == "cancel") {
                      Navigator.pop(context, false);
                    } else {
                      Navigator.pop(context, false);
                    }
                  } catch (e) {
                    Navigator.pop(context, false);
                  }
                } else {
                  Navigator.pop(context, false);
                }
              },
              label: Text(
                global.language("cancel"),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        if (widget.provider.qrtype != 301 &&
            widget.provider.qrtype != 302 &&
            widget.provider.qrtype != 401)
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              onPressed: () {
                global.playSound(sound: global.SoundEnum.qrPaymentSuccess);
                Navigator.pop(context, true);
              },
              label: Text(
                global.language("save"),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
    return (isPortrait)
        ? Column(
            children: [
              SizedBox(height: 100, child: title),
              qr,
              command,
            ],
          )
        : Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [title, qr],
              ),
              const SizedBox(height: 10),
              command,
            ],
          );
  }
}
