import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/order/qr_slip_capture_page.dart';
import 'package:dedekiosk/widget/count_down.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gbprimepay/gbprimepay.dart';
import 'package:gbprimepay/models/gb_inquiry_payment_response.dart';
import 'package:gbprimepay/models/gb_payment_gen_qr_response.dart';
import 'package:xenditpay/models/models.dart';
import 'package:xenditpay/xenditpay.dart';
import 'package:lugentpayment/inquiry_payment_response.dart';
import 'package:lugentpayment/qrpayment_response.dart';
import 'package:lugentpayment/lugentpay.dart';
import 'package:path_provider/path_provider.dart';
import 'package:promptpay/promptpay.dart';
import 'package:decimal/decimal.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kapi/models/models.dart';
import 'package:kapi/smlkapi.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:tigerboard/tigerboard.dart';
import 'package:tigerboard/models/models.dart';

class PayQrcodePage extends StatefulWidget {
  final int payIndex;
  final double amount;
  final double payCashAmount;
  final double roundAmount;
  final String customerCode;
  final String posId;

  const PayQrcodePage(
      {super.key, required this.amount, required this.payCashAmount, required this.payIndex, required this.roundAmount, required this.customerCode, required this.posId});

  @override
  PayQrcodePageState createState() => PayQrcodePageState();
}

class PayQrcodePageState extends State<PayQrcodePage> {
  String qrCodePayDataString = "";
  String transactionId = "";
  int qrType = -1;
  late Uint8List qrCodeImage;
  late Timer paymentTimer;
  bool paySuccess = false;
  late CountdownTimerWidget countDownTimerWidget;
  late Widget countDownWidget;
  late Widget bankNameWidget;
  bool qrCodeCreateSuccess = false;
  bool tigerCancel = false;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = "";
  String? _qrPaymentProofPath; // Path ของรูปหลักฐานการโอนเงิน

  /// บันทึกรูปหลักฐานการโอนเงินไปยัง directory สำหรับ upload (mode=1)
  /// ใช้ PENDING_ prefix เพื่อรอให้ sale-invoice บันทึกสำเร็จก่อน
  Future<String?> _saveQrPaymentProofForUpload(String sourcePath, String docNo) async {
    try {
      if (kDebugMode) {
        print("🟢 _saveQrPaymentProofForUpload START - source: $sourcePath, docNo: $docNo");
      }

      final directory = await getApplicationDocumentsDirectory().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('getApplicationDocumentsDirectory timeout');
        },
      );

      if (kDebugMode) {
        print("🟢 Got directory: ${directory.path}");
      }

      final qrProofDir = Directory('${directory.path}/${global.qrPaymentProofPath}');

      if (!await qrProofDir.exists()) {
        await qrProofDir.create(recursive: true);
        if (kDebugMode) {
          print("🟢 Created qrProofDir: ${qrProofDir.path}");
        }
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // ใช้ PENDING_ prefix เพื่อบอกว่ายังไม่พร้อม upload (รอ sale-invoice บันทึกสำเร็จ)
      final fileName = "PENDING_QR_${docNo}_$timestamp.jpg";
      final destPath = '${qrProofDir.path}/$fileName';

      if (kDebugMode) {
        print("🟢 File will be saved as: $fileName");
        print("🟢 orderId used for file: $docNo");
        print("🟢 Destination path: $destPath");
      }

      // Copy file จาก camera ไปยัง directory สำหรับ upload
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        if (kDebugMode) {
          print("🟢 Source file exists, copying...");
        }
        await sourceFile.copy(destPath).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('File copy timeout');
          },
        );
        if (kDebugMode) {
          print("✅ QR Payment proof saved (pending): $destPath");
        }
        return destPath;
      } else {
        if (kDebugMode) {
          print("🔴 Source file does not exist: $sourcePath");
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("🔴 Error saving QR payment proof: $e");
      }
      return null;
    }
  }

  /// เปิดหน้าถ่ายภาพหลักฐานการโอนเงิน
  Future<String?> _captureQrPaymentProof() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => QrSlipCapturePage(
          docNo: global.orderId, // ใช้ orderId เป็นตัวระบุ (จะ rename ทีหลังเมื่อได้ orderDocNumber)
          amount: widget.amount - widget.payCashAmount,
        ),
      ),
    );
    return result;
  }

  void savePay() async {
    // Debug logging
    if (kDebugMode) {
      print("🟡 savePay() called - qrType: $qrType, payIndex: ${widget.payIndex}");
      print("🟡 isslipsave: ${global.profileQrPayment[widget.payIndex].isslipsave}");
      print("🟡 Condition check: qrType == 100 (${qrType == 100}) && isslipsave (${global.profileQrPayment[widget.payIndex].isslipsave})");
    }

    // ตรวจสอบว่าต้องถ่ายรูปหลักฐานการโอนเงินหรือไม่ (qrtype 100 และ isslipsave = true)
    if (qrType == 100 && global.profileQrPayment[widget.payIndex].isslipsave) {
      if (kDebugMode) {
        print("🟢 Entering QR payment proof capture flow...");
      }

      // บังคับให้ถ่ายรูปหลักฐานการโอนเงิน
      final capturedPath = await _captureQrPaymentProof();

      if (kDebugMode) {
        print("🟢 Captured path result: $capturedPath");
      }

      if (capturedPath == null) {
        // ผู้ใช้ยกเลิกการถ่ายรูป - แจ้งเตือน
        if (kDebugMode) {
          print("🔴 User cancelled camera capture");
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(global.language("payment_proof_required")),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return; // ไม่บันทึกการชำระเงิน
      }

      // บันทึกรูปไปยัง directory สำหรับ upload
      if (kDebugMode) {
        print("🟢 Saving QR payment proof to upload directory...");
        print("🟢 orderId: ${global.orderId}");
      }
      final savedPath = await _saveQrPaymentProofForUpload(capturedPath, global.orderId);
      if (savedPath != null) {
        _qrPaymentProofPath = savedPath;
        if (kDebugMode) {
          print("✅ QR Payment proof saved successfully: $savedPath");
        }
      } else {
        if (kDebugMode) {
          print("🔴 Failed to save QR payment proof!");
        }
      }
    } else {
      if (kDebugMode) {
        print("🟡 Skipping QR payment proof capture - conditions not met");
      }
    }

    // สำเร็จ
    if (kDebugMode) {
      print("🟢 savePay() completing payment...");
    }
    paySuccess = true;
    global.payCondition.add(PayConditionModel(
      payType: 2,
      amount: widget.amount,
      payAmount: widget.amount - widget.payCashAmount,
      roundAmount: widget.roundAmount,
      changeAmount: 0,
      payTypeName: global.getNameFromLanguage(global.profileQrPayment[widget.payIndex].qrnames, global.languageForCustomer),
    ));
    if (kDebugMode) {
      print("🟢 payCondition added, mounted: $mounted");
    }
    if (mounted) {
      String message = global.findLanguage(code: "successfully_received_payment_printing_receipt", languageCode: global.languageForCustomer);
      if (kDebugMode) {
        print("🟢 Calling textToSpeech...");
      }
      global.textToSpeech(message);
      if (kDebugMode) {
        print("🟢 Navigator.pop(context, true) - returning to pay_page");
      }
      // ส่งค่า true กลับไปเพื่อให้ flow ชำระเงินสำเร็จทำงานต่อได้
      // (QR payment proof จะถูก upload โดย uploadQrPaymentProofWorker หลัง sale-invoice บันทึกสำเร็จ)
      // ใช้ rootNavigator: false เพื่อ pop เฉพาะ dialog นี้ (ไม่ใช่ root navigator)
      Navigator.of(context).pop(true);
      if (kDebugMode) {
        print("🟢 Navigator.pop completed");
      }
    } else {
      if (kDebugMode) {
        print("🔴 Widget not mounted! Cannot pop");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    createQrCode(widget.payIndex).then(
      (_) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        paymentTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (transactionId.isNotEmpty && paySuccess == false) {
            try {
              if (qrType == 131) {
                print("trx : $transactionId");
                GBPrimePay primePay = GBPrimePay(
                    publicKey: global.profileQrPayment[widget.payIndex].apikey,
                    accessToken: global.profileQrPayment[widget.payIndex].token,
                    secretKey: global.profileQrPayment[widget.payIndex].accessCode);

                GBInquiryPaymentResponse response = await primePay.inquiryQRPayment(transactionId);
                if (response.isPaymentSuccess()) {
                  savePay();
                }
              } else if (qrType == 201) {
                XenditPay xenditPay = XenditPay(accessToken: global.profileQrPayment[widget.payIndex].apikey);

                XenditPaymentPayQRResponse response = await xenditPay.inquiryQRPayment(transactionId);
                if (response.data.isNotEmpty) {
                  if (response.data[0].status == "SUCCEEDED") {
                    savePay();
                  }
                }
              } else if (qrType == 301 || qrType == 302) {
                SMLKBankConnector smlKApiConnector = SMLKBankConnector(apiKey: global.profileQrPayment[widget.payIndex].apikey, uatMode: false);

                var response = await smlKApiConnector.CheckPayment(transactionId);

                if (response.txnStatus == "PAID") {
                  savePay();
                }
              } else if (qrType == 401) {
                TigerBoard tigerBoard = TigerBoard(
                    apiUrl: global.profileQrPayment[widget.payIndex].host,
                    apiKey: global.profileQrPayment[widget.payIndex].apikey,
                    appId: global.profileQrPayment[widget.payIndex].appid);

                PaymentGenQRResponse response = await tigerBoard.inquiryPayment(transactionId);
                if (response.status == "success") {
                  savePay();
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
                LugentPay lugentPay = LugentPay.InitDemoInstance();
                InquiryPaymentResponse inquiryPaymentResponse = await lugentPay.InquiryPayment(transactionId);
                if (inquiryPaymentResponse.isApproved()) {
                  savePay();
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print("Payment inquiry error: $e");
              }
            }
          }
        });
      },
    ).catchError((error) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = error.toString();
        });
      }
    });
    countDownWidget = CountdownTimerWidget(
      duration: const Duration(minutes: 2),
      onCountdownComplete: () {
        Navigator.pop(context, false);
      },
    );
    bankNameWidget = Container(
        constraints: const BoxConstraints(maxWidth: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        child: FittedBox(
            child: Text(global.getNameFromLanguage(global.profileQrPayment[widget.payIndex].qrnames, global.languageForCustomer),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))));
  }

  @override
  void dispose() {
    super.dispose();
    try {
      paymentTimer.cancel();
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
  }

  double qrCodeAmount() {
    return widget.amount - widget.payCashAmount;
  }

  Future<QRPaymentResponse> qrLugentPromptPay() async {
    // Promptpay ลูเจ้นท์ ไทย
    LugentPay lugentPay = LugentPay.InitDemoInstance();
    QRPaymentResponse qrPayment =
        await lugentPay.CreateThaiQRPaymentTransaction(lugentPay.CreateReferenceWithUnixTime("SMLINV"), "SMLSOFT", Decimal.parse((qrCodeAmount()).toString()), "");
    return qrPayment;
  }

  Future<QRPaymentResponse> qrLugentAliPay() async {
    // Promptpay ลูเจ้นท์ ไทย
    LugentPay lugentPay = LugentPay.InitDemoInstance();
    QRPaymentResponse qrPayment =
        await lugentPay.CreateAliPayTransaction(lugentPay.CreateReferenceWithUnixTime("SMLINV"), "SMLSOFT", Decimal.parse((qrCodeAmount()).toString()), "");
    return qrPayment;
  }

  Future<QRPaymentResponse> qrLugentTrueMoney() async {
    // Promptpay ลูเจ้นท์ ไทย
    LugentPay lugentPay = LugentPay.InitDemoInstance();
    QRPaymentResponse qrPayment = await lugentPay.CreateTrueMoneyTransaction(
        "ค่าอาหาร/เครื่องดื่ม",
        "่ค่าบริการ/ค่าบริการ",
        "https://dedeposblosstorage.blob.core.windows.net/dedeposassets/app_logo.png",
        lugentPay.CreateReferenceWithUnixTime("SMLINV"),
        "SMLSOFT",
        Decimal.parse((qrCodeAmount()).toString()),
        "");
    return qrPayment;
  }

  Future<QRPaymentResponse> qrLugentLinePay() async {
    // Promptpay ลูเจ้นท์ ไทย
    LugentPay lugentPay = LugentPay.InitDemoInstance();
    QRPaymentResponse qrPayment =
        await lugentPay.CreateLinePayTransaction(lugentPay.CreateReferenceWithUnixTime("SMLINV"), "SMLSOFT", Decimal.parse((qrCodeAmount()).toString()), "");
    return qrPayment;
  }

  Future<QRPaymentResponse> qrLugentWeChatPay() async {
    // Promptpay ลูเจ้นท์ ไทย
    LugentPay lugentPay = LugentPay.InitDemoInstance();
    QRPaymentResponse qrPayment =
        await lugentPay.CreateWechatTransaction(lugentPay.CreateReferenceWithUnixTime("SMLINV"), "SMLSOFT", Decimal.parse((qrCodeAmount()).toString()), "");
    return qrPayment;
  }

  Future<GBPaymentGenQRResponse> qrGBPrimePayThaiQR(ProfileQrPaymentModel paymentProfile) async {
    GBPrimePay primePay = GBPrimePay(publicKey: paymentProfile.apikey, accessToken: paymentProfile.token, secretKey: paymentProfile.accessCode);
    String key = global.generateRandomString(5);
    String refCode = primePay.genRefUnixTimeNow(key);

    return await primePay.generateImageThaiQRPayment(refCode, Decimal.parse((qrCodeAmount()).toString()));
  }

  Future<PaymentGenQRResponse> payTigerBoard(ProfileQrPaymentModel paymentProfile) async {
    TigerBoard tigerBoard = TigerBoard(
      apiUrl: paymentProfile.host,
      appId: paymentProfile.appid!,
      apiKey: paymentProfile.apikey!,
    );

    return await tigerBoard.generatePayrequest(widget.customerCode, widget.posId, widget.amount);
  }

  Future<XenditPaymentGenQRResponse> qrXenditPayThaiQR(ProfileQrPaymentModel paymentProfile) async {
    XenditPay xenditPay = XenditPay(
      accessToken: paymentProfile.apikey,
    );
    String key = global.generateRandomString(5);
    String refCode = xenditPay.genRefUnixTimeNow(key);

    DateTime now = DateTime.now();
    DateTime expiryDate = now.add(const Duration(minutes: 15));

    String expiryDateISO = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(expiryDate.toUtc());

    return await xenditPay.generateQRPayment(refCode, qrCodeAmount(), "THB", expiryDateISO);
  }

  Future<QRGenerateResponse> qrSMLPromptPay(ProfileQrPaymentModel paymentProfile) async {
    SMLKBankConnector smlKApiConnector = SMLKBankConnector(apiKey: paymentProfile.apikey, uatMode: false);

    String key = global.generateRandomString(5);
    String refCode = global.shopProfile!.orderstation.code;
    String refCode2 = smlKApiConnector.genRefUnixTimeNow(key);
    String refCode3 = smlKApiConnector.genRefUnixTimeNow(key);
    String refCode4 = smlKApiConnector.genRefUnixTimeNow(key);

    QRGenerateResponse qrGenerateResponse = await smlKApiConnector.CreateQRPromptPayTransaction(Decimal.parse(qrCodeAmount().toString()), refCode, refCode2, refCode3, refCode4);

    return qrGenerateResponse;
  }

  Future<QRGenerateResponse> qrSMLCredit(ProfileQrPaymentModel paymentProfile) async {
    SMLKBankConnector smlKApiConnector = SMLKBankConnector(apiKey: paymentProfile.apikey, uatMode: false);

    String key = global.generateRandomString(5);
    String refCode = global.shopProfile!.orderstation.code;
    String refCode2 = smlKApiConnector.genRefUnixTimeNow(key);
    String refCode3 = smlKApiConnector.genRefUnixTimeNow(key);
    String refCode4 = smlKApiConnector.genRefUnixTimeNow(key);

    QRGenerateResponse qrGenerateResponse = await smlKApiConnector.CreateQRCreditCardTransaction(Decimal.parse(qrCodeAmount().toString()), refCode, refCode2, refCode3, refCode4);

    return qrGenerateResponse;
  }

  void startCountDown() {
    setState(() {});
  }

  Future<void> createQrCode(int index) async {
    try {
      qrType = global.profileQrPayment[index].qrtype;
      switch (qrType) {
        case 100:
          // Promptpay ทั่วไป
          qrCodePayDataString = PromptPay.generateQRData(global.profileQrPayment[index].qrcode, amount: (widget.amount - widget.payCashAmount).toDouble());
          setState(() {});
          break;
        case 110:
          // Promptpay ลูเจ้นท์ ไทย
          await qrLugentPromptPay().then((qrPayment) async {
            qrCodePayDataString = qrPayment.qrCode;
            startCountDown();
            if (qrPayment.isSuccess()) {
              transactionId = qrPayment.transactionId;
              qrCodePayDataString = qrPayment.qrCode;
            } else {
              throw Exception("ไม่สามารถสร้าง QR Code ได้");
            }
          });
          break;
        case 111:
          // AliPay ลูเจ้นท์ ไทย
          await qrLugentAliPay().then((qrPayment) async {
            qrCodePayDataString = qrPayment.qrCode;
            startCountDown();
            if (qrPayment.isSuccess()) {
              transactionId = qrPayment.transactionId;
              qrCodePayDataString = qrPayment.qrCode;
            } else {
              throw Exception("ไม่สามารถสร้าง QR Code ได้");
            }
          });
          break;
        case 112:
          // True Money ลูเจ้นท์ ไทย
          await qrLugentTrueMoney().then((qrPayment) async {
            qrCodePayDataString = qrPayment.qrCode;
            startCountDown();
            if (qrPayment.isSuccess()) {
              transactionId = qrPayment.transactionId;
              qrCodePayDataString = qrPayment.qrCode;
            } else {
              throw Exception("ไม่สามารถสร้าง QR Code ได้");
            }
          });
          break;
        case 113:
          // Line Pay ลูเจ้นท์ ไทย
          await qrLugentLinePay().then((qrPayment) async {
            qrCodePayDataString = qrPayment.qrCode;
            startCountDown();
            if (qrPayment.isSuccess()) {
              transactionId = qrPayment.transactionId;
              qrCodePayDataString = qrPayment.qrCode;
            } else {
              throw Exception("ไม่สามารถสร้าง QR Code ได้");
            }
          });
          break;
        case 114:
          // WeChat Pay ลูเจ้นท์ ไทย
          await qrLugentLinePay().then((qrPayment) async {
            qrCodePayDataString = qrPayment.qrCode;
            startCountDown();
            if (qrPayment.isSuccess()) {
              transactionId = qrPayment.transactionId;
              qrCodePayDataString = qrPayment.qrCode;
            } else {
              throw Exception("ไม่สามารถสร้าง QR Code ได้");
            }
          });
          break;
        case 131:
          // GB PrimePay Thai QR
          await qrGBPrimePayThaiQR(global.profileQrPayment[index]).then((qrPayment) async {
            qrCodePayDataString = "GB PrimePay Thai QR";
            startCountDown();
            if (qrPayment.isSuccess()) {
              transactionId = qrPayment.referenceNo!;
              qrCodePayDataString = "QR Image";
              qrCodeImage = qrPayment.qrImageData!;
            } else {
              throw Exception("ไม่สามารถสร้าง QR Code ได้");
            }
          });
          break;
        case 201:
          // xenditpay
          await qrXenditPayThaiQR(global.profileQrPayment[index]).then((qrPayment) async {
            qrCodePayDataString = "Xendit Pay Thai QR";
            startCountDown();
            if (qrPayment.id.isNotEmpty) {
              transactionId = qrPayment.id;
              qrCodePayDataString = qrPayment.qr_string;
            } else {
              throw Exception("ไม่สามารถสร้าง QR Code ได้");
            }
          });
          break;
        case 301:
          // smlpromptpay
          await qrSMLPromptPay(global.profileQrPayment[index]).then((qrPayment) async {
            qrCodePayDataString = "SML PromptPay";
            if (qrPayment.statusCode == "00") {
              if (qrPayment.qrCode.isNotEmpty) {
                startCountDown();
                transactionId = qrPayment.txnUid;
                qrCodePayDataString = qrPayment.qrCode;
              } else {
                throw Exception("ไม่สามารถสร้าง QR Code ได้");
              }
            } else {
              throw Exception("Error: ${qrPayment.errorCode}");
            }
          });
          break;
        case 302:
          // smlcredit
          await qrSMLCredit(global.profileQrPayment[index]).then((qrPayment) async {
            qrCodePayDataString = "SML Credit";
            if (qrPayment.statusCode == "00") {
              if (qrPayment.qrCode.isNotEmpty) {
                startCountDown();
                transactionId = qrPayment.txnUid;
                qrCodePayDataString = qrPayment.qrCode;
              } else {
                throw Exception("ไม่สามารถสร้าง QR Code ได้");
              }
            } else {
              throw Exception("Error: ${qrPayment.errorCode}");
            }
          });
          break;
        case 401:
          await payTigerBoard(global.profileQrPayment[index]).then((qrPayment) async {
            qrCodePayDataString = "";

            if (qrPayment.status == "new") {
              qrCodeCreateSuccess = true;
              transactionId = qrPayment.id.toString();
              setState(() {});
            } else {
              throw Exception("ไม่สามารถสร้างรายการชำระเงินได้");
            }
          });
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
      rethrow;
    }
  }

  Widget _buildErrorWidget(double screenWidth, bool isMobile, bool isTablet) {
    final iconSize = isMobile ? 80.0 : (isTablet ? 100.0 : 120.0);
    final titleFontSize = isMobile ? 20.0 : (isTablet ? 24.0 : 28.0);
    final messageFontSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
    final buttonPadding = isMobile ? 12.0 : 16.0;
    final containerWidth = isMobile ? screenWidth * 0.9 : (isTablet ? 400.0 : 450.0);

    return Center(
      child: Container(
        width: containerWidth,
        padding: EdgeInsets.all(isMobile ? 20 : 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: iconSize * 0.5,
                color: Colors.red.shade400,
              ),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              global.language("error_occurred"),
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                errorMessage.isNotEmpty ? errorMessage : "ไม่สามารถสร้าง QR Code ได้",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: messageFontSize,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 20 : 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: buttonPadding),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      global.language("back"),
                      style: TextStyle(
                        fontSize: messageFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        hasError = false;
                        errorMessage = "";
                        isLoading = true;
                      });
                      createQrCode(widget.payIndex).then((_) {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }).catchError((error) {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                            hasError = true;
                            errorMessage = error.toString().replaceAll("Exception: ", "");
                          });
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDA291C),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: buttonPadding),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      global.language("try_again"),
                      style: TextStyle(
                        fontSize: messageFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(double screenWidth, bool isMobile, bool isTablet) {
    final containerSize = isMobile ? 200.0 : (isTablet ? 250.0 : 300.0);
    final spinnerSize = isMobile ? 50.0 : (isTablet ? 60.0 : 70.0);
    final fontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);

    return Center(
      child: Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              global.language("generating_qr_code"),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTigerBoardWidget(double screenWidth, bool isMobile, bool isTablet) {
    final containerWidth = isMobile ? screenWidth * 0.9 : (isTablet ? 450.0 : 500.0);
    final iconSize = isMobile ? 80.0 : (isTablet ? 100.0 : 120.0);
    final titleFontSize = isMobile ? 22.0 : (isTablet ? 26.0 : 30.0);
    final subtitleFontSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
    final buttonFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);

    return Center(
      child: Container(
        width: containerWidth,
        padding: EdgeInsets.all(isMobile ? 20 : 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payment,
                size: iconSize * 0.5,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isMobile ? 20 : 30),
            Text(
              "กรุณาชำระที่เครื่องรับเงิน",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Transaction ID:",
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        transactionId,
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "รหัส:",
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          "${widget.posId}-${(widget.customerCode == "") ? "ลูกค้าทั่วไป" : widget.customerCode}",
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.cancel_outlined, color: Colors.grey.shade700),
                onPressed: () async {
                  if (qrType == 401) {
                    TigerBoard tigerBoard = TigerBoard(
                        apiUrl: global.profileQrPayment[widget.payIndex].host,
                        apiKey: global.profileQrPayment[widget.payIndex].apikey,
                        appId: global.profileQrPayment[widget.payIndex].appid);
                    try {
                      await tigerBoard.cancelPayment(transactionId);
                      if (mounted) {
                        Navigator.pop(context, false);
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context, false);
                      }
                    }
                  } else {
                    Navigator.pop(context, false);
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 18),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                label: Text(
                  global.language("cancel"),
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeWidget(double screenWidth, bool isMobile, bool isTablet) {
    final qrContainerSize = isMobile ? screenWidth * 0.7 : (isTablet ? 320.0 : 380.0);
    final amountFontSize = isMobile ? 24.0 : (isTablet ? 30.0 : 34.0);
    final labelFontSize = isMobile ? 14.0 : (isTablet ? 18.0 : 22.0);
    final buttonFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);

    return Column(
      children: [
        // Header - Amount Display
        Container(
          width: double.infinity,
          // margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
            ),
            borderRadius: BorderRadius.circular(0),
          ),
          child: Column(
            children: [
              Text(
                global.language("total_amount"),
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${global.moneyFormat.format(widget.amount - widget.payCashAmount)} ${global.language("money_baht")}",
                style: TextStyle(
                  fontSize: amountFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (widget.roundAmount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${global.language("round_money")} ${global.moneyFormat.format(widget.roundAmount)} ${global.language("money_baht")}",
                    style: TextStyle(
                      fontSize: labelFontSize - 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: isMobile ? 16 : 24),

        // QR Code Container
        Expanded(
          child: Center(
            child: Container(
              width: qrContainerSize,
              height: qrContainerSize,
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: (qrCodePayDataString.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            global.language("generating_qr_code"),
                            style: TextStyle(
                              fontSize: labelFontSize,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ((global.profileQrPayment[widget.payIndex].qrtype == 131)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            fit: BoxFit.contain,
                            qrCodeImage,
                          ),
                        )
                      : QrImageView(
                          data: qrCodePayDataString,
                          version: QrVersions.auto,
                          padding: EdgeInsets.zero,
                        )),
            ),
          ),
        ),

        SizedBox(height: isMobile ? 12 : 16),

        // Scan instruction
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: isMobile ? 18 : 22,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                global.language("please_scan_qrcode_to_pay"),
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isMobile ? 12 : 16),

        // Countdown Timer
        countDownWidget,

        const SizedBox(height: 8),

        // Bank Name
        Container(
          constraints: BoxConstraints(maxWidth: isMobile ? 200 : 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            global.getNameFromLanguage(global.profileQrPayment[widget.payIndex].qrnames, global.languageForCustomer),
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: isMobile ? 16 : 20),

        // Action Buttons
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 18),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    global.language("cancel"),
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              if (global.profileQrPayment[widget.payIndex].qrtype == 100) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      savePay();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      global.language("confirm"),
                      style: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: isMobile ? 16 : 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: hasError
            ? _buildErrorWidget(screenWidth, isMobile, isTablet)
            : isLoading && qrCodePayDataString.isEmpty && qrType != 401
                ? _buildLoadingWidget(screenWidth, isMobile, isTablet)
                : (qrType == 401 && qrCodeCreateSuccess)
                    ? _buildTigerBoardWidget(screenWidth, isMobile, isTablet)
                    : _buildQrCodeWidget(screenWidth, isMobile, isTablet),
      ),
    );
  }
}
