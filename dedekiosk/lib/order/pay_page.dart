import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/order/pay_cash_page.dart';
import 'package:dedekiosk/order/pay_creditcard_page.dart';
import 'package:dedekiosk/order/pay_delivery_page.dart';
import 'package:dedekiosk/order/pay_qr_edc_page.dart';
import 'package:dedekiosk/order/pay_qr_payment_page.dart';
import 'package:dedekiosk/order/pay_qrcode_page.dart';
import 'package:dedekiosk/util/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PayPage extends StatefulWidget {
  final double amount;
  final BuildContext context;
  final String orderTagNumber;

  const PayPage({super.key, required this.amount, required this.context, required this.orderTagNumber});

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> with TickerProviderStateMixin {
  String qrCodePayDataString = "";
  String transactionId = "";
  int qrType = -1;
  double payCashAmount = 0;
  double roundAmount = 0;
  int paymentIndex = -1;
  late Uint8List qrCodeImage;

  @override
  void initState() {
    super.initState();
    global.payCondition = [];
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Responsive breakpoints
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900 && screenWidth < 1200;
    final isLargeDesktop = screenWidth >= 1200;

    // Grid columns based on screen size
    int gridViewCount;
    if (isMobile) {
      gridViewCount = 2;
    } else if (isTablet) {
      gridViewCount = 3;
    } else if (isDesktop) {
      gridViewCount = 4;
    } else {
      gridViewCount = 4;
    }

    // Responsive grid calculation
    int totalPaymentMethods = global.profileQrPayment.length;
    if (global.deviceConfig.machineCondition == 0) {
      totalPaymentMethods += 1; // Cash payment
    }
    if (global.saleChannelCode.isNotEmpty && global.deviceConfig.machineCondition == 0) {
      totalPaymentMethods += 1; // Delivery payment
    }
    if (global.edcProductName.isNotEmpty) {
      totalPaymentMethods += 3; // Credit card, QR EDC, QR Payment
    }

    // Adjust grid count based on total methods
    if (gridViewCount > totalPaymentMethods) {
      gridViewCount = totalPaymentMethods;
    }
    if (gridViewCount < 2) {
      gridViewCount = 2;
    }

    // Responsive padding and spacing
    final gridPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final cardSpacing = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    final aspectRatio = isMobile ? 0.9 : (isTablet ? 1.0 : 1.1);

    Widget paymentList = Container(
      padding: EdgeInsets.all(gridPadding),
      child: GridView.count(
        crossAxisCount: gridViewCount,
        childAspectRatio: aspectRatio,
        mainAxisSpacing: cardSpacing,
        crossAxisSpacing: cardSpacing,
        children: [
          // Cash Payment
          if (global.deviceConfig.machineCondition == 0)
            _buildPaymentCard(
              context: context,
              screenWidth: screenWidth,
              colors: [const Color(0xFFE8F5E9), const Color(0xFFD4E6D6)], // โทนเขียวอ่อน
              borderColor: const Color(0xFF81C784),
              shadowColor: Colors.green,
              bottomColor: const Color(0xFF66BB6A),
              icon: Icons.money,
              iconColor: const Color(0xFF388E3C),
              title: global.language("pay_by_cash"),
              imageUrl: "https://as2.ftcdn.net/v2/jpg/03/33/51/03/1000_F_333510357_rY9B8sKyQ5BZBLYuDHphMTtMlu5ASX1A.jpg",
              onTap: () => _handleCashPayment(),
            ),

          // Delivery Payment
          if (global.saleChannelCode.isNotEmpty && global.deviceConfig.machineCondition == 0)
            _buildPaymentCard(
              context: context,
              screenWidth: screenWidth,
              colors: [const Color(0xFFFFE7C4), const Color(0xFFFFD699)], // โทนส้มอ่อน
              borderColor: const Color(0xFFFF9800),
              shadowColor: Colors.orange,
              bottomColor: const Color(0xFFFB8C00),
              icon: Icons.delivery_dining,
              iconColor: const Color(0xFFE65100),
              title: global.saleChannelCode,
              imageUrl: global.shopProfile!.orderstation.salechannels!.firstWhere((element) => element.code == global.saleChannelCode).imageuri,
              onTap: () => _handleDeliveryPayment(),
            ),

          // Credit Card Payment
          if (global.edcProductName.isNotEmpty)
            _buildPaymentCard(
              context: context,
              screenWidth: screenWidth,
              colors: [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)], // โทนฟ้าอ่อน
              borderColor: const Color(0xFF64B5F6),
              shadowColor: Colors.blue,
              bottomColor: const Color(0xFF42A5F5),
              title: global.language("pay_by_creditcard"),
              assetPath: "assets/images/creditcard1.png",
              onTap: () => _handleCreditCardPayment(),
            ),

          // QR EDC Payment
          if (global.edcProductName.isNotEmpty)
            _buildPaymentCard(
              context: context,
              screenWidth: screenWidth,
              colors: [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)], // โทนม่วงอ่อน
              borderColor: const Color(0xFFBA68C8),
              shadowColor: Colors.purple,
              bottomColor: const Color(0xFFAB47BC),
              title: global.language("pay_by_qr_edc"),
              assetPath: "assets/images/qrpay1.png",
              onTap: () => _handleQREdcPayment(),
            ),

          // QR Payment
          if (global.edcProductName.isNotEmpty)
            _buildPaymentCard(
              context: context,
              screenWidth: screenWidth,
              colors: [const Color(0xFFE0F2F1), const Color(0xFFB2DFDB)], // โทนเขียวน้ำทะเล
              borderColor: const Color(0xFF4DB6AC),
              shadowColor: Colors.teal,
              bottomColor: const Color(0xFF26A69A),
              title: global.language("pay_by_qr_payment"),
              assetPath: "assets/images/qrpay1.png",
              onTap: () => _handleQRPayment(),
            ),

          // QR Profile Payments
          for (var index = 0; index < global.profileQrPayment.length; index++)
            if (global.deviceConfig.machineCondition == 0 || (global.deviceConfig.machineCondition != 0 && global.profileQrPayment[index].qrtype != 100))
              _buildPaymentCard(
                context: context,
                screenWidth: screenWidth,
                colors: [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)], // โทนน้ำเงินม่วง
                borderColor: const Color(0xFF7986CB),
                shadowColor: Colors.indigo,
                bottomColor: const Color(0xFF5C6BC0),
                icon: Icons.qr_code,
                iconColor: const Color(0xFF3F51B5),
                title: global.getNameFromLanguage(global.profileQrPayment[index].qrnames, global.languageForCustomer),
                imageUrl: global.profileQrPayment[index].logo,
                onTap: () => _handleQRProfilePayment(index),
              ),
        ],
      ),
    );
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5EBE0), // สีอิฐบ้านเชียง
        body: Column(
          children: [
            // Header Section
            _buildHeaderSection(screenWidth),

            // Payment Methods Grid
            Expanded(child: paymentList),

            // Cancel Button
            _buildCancelButton(screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(double screenWidth) {
    // Responsive variables
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isLargeScreen = screenWidth >= 900;

    // Responsive padding
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 20.0 : 28.0);
    final verticalPadding = isMobile ? 16.0 : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(horizontalPadding, verticalPadding, horizontalPadding, verticalPadding - 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Center(
            child: Text(
              "${global.language("select_payment_method")} : #${widget.orderTagNumber}",
              style: TextStyle(
                fontSize: isMobile ? 20 : (isTablet ? 42 : 48),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Payment Amount - Clean Display
          // Row(
          //   crossAxisAlignment: CrossAxisAlignment.end,
          //   children: [
          //     // Label
          //     Text(
          //       global.language('money_amount'),
          //       style: TextStyle(
          //         fontSize: isMobile ? 13 : (isTablet ? 15 : 17),
          //         color: Colors.black54,
          //         fontWeight: FontWeight.w500,
          //       ),
          //     ),
          //     SizedBox(width: isMobile ? 8 : 12),

          //     // Amount
          //     Expanded(
          //       child: Text(
          //         '${global.moneyFormatAndDot.format(payCashAmount > 0 ? widget.amount - payCashAmount : widget.amount)} ฿',
          //         textAlign: TextAlign.right,
          //         style: TextStyle(
          //           fontSize: isMobile ? 24 : (isTablet ? 28 : (isLargeScreen ? 36 : 32)),
          //           fontWeight: FontWeight.bold,
          //           color: const Color(0xFFDA291C),
          //           height: 1.0,
          //         ),
          //       ),
          //     ),

          //     // Order Tag Badge (if exists)
          //     // if (widget.orderTagNumber.isNotEmpty) ...[
          //     //   const SizedBox(width: 16),
          //     //   Container(
          //     //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          //     //     decoration: BoxDecoration(
          //     //       color: const Color(0xFFFFC72C).withOpacity(0.2),
          //     //       borderRadius: BorderRadius.circular(6),
          //     //       border: Border.all(color: const Color(0xFFFFC72C).withOpacity(0.4), width: 1),
          //     //     ),
          //     //     child: Row(
          //     //       mainAxisSize: MainAxisSize.min,
          //     //       children: [
          //     //         Icon(Icons.tag, size: 14, color: Colors.orange.shade800),
          //     //         const SizedBox(width: 4),
          //     //         Text(
          //     //           widget.orderTagNumber,
          //     //           style: TextStyle(
          //     //             fontSize: isTablet ? 13 : 11,
          //     //             fontWeight: FontWeight.w600,
          //     //             color: Colors.orange.shade800,
          //     //           ),
          //     //         ),
          //     //       ],
          //     //     ),
          //     //   ),
          //     // ],
          //   ],
          // ),

          // Paid with cash indicator
          if (payCashAmount > 0) ...[
            SizedBox(height: isMobile ? 8 : 10),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: isMobile ? 3 : 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: isMobile ? 12 : 14, color: Colors.green.shade700),
                      SizedBox(width: isMobile ? 3 : 4),
                      Text(
                        '${global.language("paid_with_cash")}: ${global.moneyFormatAndDot.format(payCashAmount)} ฿',
                        style: TextStyle(
                          fontSize: isMobile ? 10 : (isTablet ? 11 : 12),
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentCard({
    required BuildContext context,
    required double screenWidth,
    required List<Color> colors,
    required Color borderColor,
    required Color shadowColor,
    required Color bottomColor,
    required String title,
    required VoidCallback onTap,
    IconData? icon,
    Color? iconColor,
    String? imageUrl,
    String? assetPath,
  }) {
    // Responsive variables
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    // Card styling
    final borderRadius = isMobile ? 10.0 : (isTablet ? 8.0 : 10.0);
    final cardPadding = isMobile ? 12.0 : 16.0;
    final titlePadding = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              // Image/Icon Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  child: _buildPaymentImage(imageUrl, assetPath, icon, iconColor, isMobile),
                ),
              ),

              // Title Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: titlePadding, vertical: titlePadding),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : (isTablet ? 15 : 17),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentImage(String? imageUrl, String? assetPath, IconData? icon, Color? iconColor, bool isMobile) {
    final iconSize = isMobile ? 40.0 : 48.0;
    final loadingSize = isMobile ? 20.0 : 24.0;

    if (assetPath != null) {
      return Image.asset(assetPath, fit: BoxFit.contain);
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        fit: BoxFit.contain,
        imageUrl: imageUrl,
        placeholder: (context, url) => SizedBox(
          width: loadingSize,
          height: loadingSize,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => Icon(
          icon ?? Icons.payment,
          size: iconSize,
          color: iconColor ?? Colors.grey,
        ),
      );
    }

    return Icon(
      icon ?? Icons.payment,
      size: iconSize,
      color: iconColor ?? Colors.grey,
    );
  }

  Widget _buildCancelButton(double screenWidth) {
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    final buttonPadding = isMobile ? 18.0 : 22.0;
    final buttonHeight = isMobile ? 48.0 : (isTablet ? 60.0 : 65.0);

    return Container(
      padding: EdgeInsets.all(buttonPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton.icon(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: isMobile ? 20 : 24,
            ),
            onPressed: () {
              global.payCondition.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB85C38), // สีอิฐแดง
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.white, width: 1),
              ),
            ),
            label: Text(
              global.language("cancel"),
              style: TextStyle(
                fontSize: isMobile ? 15 : (isTablet ? 20 : 22),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Payment Handler Methods
  Future<void> _handleCashPayment() async {
    try {
      setState(() {
        global.countDownForHome = global.countDownForHomeMax;
        qrType = -1;
        qrCodePayDataString = "";
        roundAmount = global.calculateRoundedAmount(widget.amount, 'cash');
      });

      payCashAmount = await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              "${global.language("pay_by_cash")} ${global.moneyFormat.format(widget.amount)}  ${global.language("round_money")}  ${global.moneyFormat.format(roundAmount - widget.amount)}  ${global.language("total_amount")} ${global.moneyFormat.format(roundAmount)}  ${global.language("money_baht")}",
            ),
            content: PayCashPage(amount: roundAmount),
          );
        },
      );

      // Update payment condition
      global.payCondition.removeWhere((element) => element.payType == 0);
      if (payCashAmount > 0) {
        global.payCondition.add(PayConditionModel(
          payType: 0,
          amount: roundAmount,
          payAmount: payCashAmount,
          roundAmount: roundAmount - widget.amount,
          changeAmount: payCashAmount - roundAmount,
          payTypeName: global.language("pay_by_cash"),
        ));
      }

      setState(() {});

      if (payCashAmount >= roundAmount) {
        await _showPaymentSummary();
        if (mounted) Navigator.pop(context);
      }
    } catch (e, s) {
      Logger.e('Cash payment error', error: e, stackTrace: s);
      global.sendErrorToDevTeam("_handleCashPayment error: $e");
      if (mounted) await _showErrorDialog();
    }
  }

  Future<void> _handleDeliveryPayment() async {
    try {
      if (mounted) {
        global.countDownForHome = global.countDownForHomeMax;
        roundAmount = global.calculateRoundedAmount(widget.amount, 'delivery');
        var payResult = await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 900,
                  maxWidth: (MediaQuery.of(context).orientation == Orientation.portrait) ? 500 : 800,
                ),
                child: PayDeliveryPage(
                  amount: roundAmount,
                  payCashAmount: payCashAmount,
                  roundAmount: roundAmount - widget.amount,
                ),
              ),
            );
          },
        );
        if (payResult == true && mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e, s) {
      Logger.e('Delivery payment error', error: e, stackTrace: s);
      global.sendErrorToDevTeam("_handleDeliveryPayment error: $e");
      if (mounted) await _showErrorDialog();
    }
  }

  Future<void> _handleCreditCardPayment() async {
    try {
      setState(() {
        global.countDownForHome = global.countDownForHomeMax;
        qrType = -1;
        qrCodePayDataString = "";
        roundAmount = global.calculateRoundedAmount(widget.amount, 'creditcard');
      });

      final res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PayCreditCardPage(
            amount: roundAmount,
            roundAmount: roundAmount - widget.amount,
          ),
        ),
      );

      if (res != null) {
        if (res == "Failed") {
          if (mounted) await _showErrorDialog();
          return;
        }

        _updatePaymentCondition(res, 1, global.language("pay_by_creditcard"));

        if (payCashAmount >= roundAmount && mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e, s) {
      Logger.e('Credit card payment error', error: e, stackTrace: s);
      global.sendErrorToDevTeam("_handleCreditCardPayment error: $e");
      if (mounted) await _showErrorDialog();
    }
  }

  Future<void> _handleQREdcPayment() async {
    try {
      setState(() {
        global.countDownForHome = global.countDownForHomeMax;
        qrType = -1;
        qrCodePayDataString = "";
        roundAmount = global.calculateRoundedAmount(widget.amount, 'creditcard');
      });

      final res = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PayQRCreditEDCPage(amount: roundAmount)),
      );

      if (res != null) {
        _updatePaymentCondition(res, 1, global.language("pay_by_qr_edc"));

        if (payCashAmount >= roundAmount && mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e, s) {
      Logger.e('QR EDC payment error', error: e, stackTrace: s);
      global.sendErrorToDevTeam("_handleQREdcPayment error: $e");
      if (mounted) await _showErrorDialog();
    }
  }

  Future<void> _handleQRPayment() async {
    try {
      setState(() {
        global.countDownForHome = global.countDownForHomeMax;
        qrType = -1;
        qrCodePayDataString = "";
        roundAmount = global.calculateRoundedAmount(widget.amount, 'qrcode');
      });

      final res = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PayQRPaymentPage(amount: roundAmount)),
      );

      if (res != null) {
        payCashAmount = res;
        global.payCondition.removeWhere((element) => element.payType == 0);
        if (payCashAmount > 0) {
          global.payCondition.add(PayConditionModel(
            payType: 2,
            amount: roundAmount,
            roundAmount: roundAmount - widget.amount,
            payAmount: payCashAmount,
            changeAmount: 0,
            payTypeName: global.language("pay_by_qr_payment"),
          ));
        }
        setState(() {});

        if (payCashAmount >= roundAmount && mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e, s) {
      Logger.e('QR payment error', error: e, stackTrace: s);
      global.sendErrorToDevTeam("_handleQRPayment error: $e");
      if (mounted) await _showErrorDialog();
    }
  }

  Future<void> _handleQRProfilePayment(int index) async {
    try {
      if (mounted) {
        global.countDownForHome = global.countDownForHomeMax;
        roundAmount = global.calculateRoundedAmount(widget.amount, 'qrcode');
        paymentIndex = index;

        String message = global.findLanguage(code: "selected_pay_type", languageCode: global.languageForCustomer);
        message += " ${global.getNameFromLanguage(global.profileQrPayment[index].qrnames, global.languageForCustomer)} ";
        message += global.findLanguage(code: "wait_for_scan_qrcode_pay", languageCode: global.languageForCustomer);
        message += " ${global.findLanguage(code: "and", languageCode: global.languageForCustomer)} ";
        message += global.findLanguage(code: "speech_order_success", languageCode: global.languageForCustomer);
        global.textToSpeech(message);

        var payResult = await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 900,
                  maxWidth: (MediaQuery.of(context).orientation == Orientation.portrait) ? 500 : 800,
                ),
                child: PayQrcodePage(
                  customerCode: "โต๊ะ " + widget.orderTagNumber,
                  posId: global.deviceConfig.orderStationCode,
                  payIndex: index,
                  amount: roundAmount,
                  roundAmount: roundAmount - widget.amount,
                  payCashAmount: payCashAmount,
                ),
              ),
            );
          },
        );

        if (kDebugMode) {
          print("💳 QR Payment dialog closed - payResult: $payResult");
        }

        if (payResult == true && mounted) {
          if (kDebugMode) {
            print("💳 Payment success! Calling Navigator.pop from pay_page...");
          }
          Navigator.pop(context);
          if (kDebugMode) {
            print("💳 Navigator.pop from pay_page completed");
          }
        } else {
          if (kDebugMode) {
            print("💳 Payment NOT completed - payResult: $payResult, mounted: $mounted");
          }
        }
      }
    } catch (e, s) {
      Logger.e('QR Profile payment error', error: e, stackTrace: s);
      global.sendErrorToDevTeam("_handleQRProfilePayment error: $e");
      if (mounted) await _showErrorDialog();
    }
  }

  void _updatePaymentCondition(dynamic res, int payType, String payTypeName) {
    payCashAmount = res['amount'];
    global.payCondition.removeWhere((element) => element.payType == 0);
    if (payCashAmount > 0) {
      global.payCondition.add(PayConditionModel(
        payType: payType,
        amount: roundAmount,
        roundAmount: roundAmount - widget.amount,
        payAmount: payCashAmount,
        cardNumber: res['cardNumber'] ?? '',
        approvalCode: res['approvalCode'] ?? '',
        changeAmount: 0,
        payTypeName: payTypeName,
      ));
    }
    setState(() {});
  }

  Future<void> _showPaymentSummary() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    // Responsive sizing
    final padding = isMobile ? 16.0 : 24.0;
    final iconSize = isMobile ? 48.0 : (isTablet ? 56.0 : 64.0);
    final titleFontSize = isMobile ? 20.0 : (isTablet ? 24.0 : 28.0);
    final labelFontSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
    final valueFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    final totalFontSize = isMobile ? 28.0 : (isTablet ? 36.0 : 44.0);
    final buttonHeight = isMobile ? 50.0 : (isTablet ? 56.0 : 60.0);
    final buttonFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);

    // Payment summary data
    final summaryItems = [
      {'label': global.language("amount"), 'value': widget.amount, 'icon': Icons.receipt_outlined},
      {'label': global.language("round_money"), 'value': roundAmount - widget.amount, 'icon': Icons.autorenew},
      {'label': global.language("total_amount"), 'value': roundAmount, 'icon': Icons.summarize_outlined},
      {'label': global.language("pay_by_cash"), 'value': payCashAmount, 'icon': Icons.payments_outlined},
    ];

    final changeAmount = payCashAmount - roundAmount;

    if (context.mounted) {
      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: isMobile ? screenWidth * 0.95 : 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: padding * 1.5),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: iconSize * 0.6,
                          ),
                        ),
                        SizedBox(height: padding * 0.75),
                        Text(
                          global.language("payment_summary"),
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Summary Items
                  Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      children: [
                        // Payment details
                        ...summaryItems.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    size: isMobile ? 18 : 20,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item['label'] as String,
                                      style: TextStyle(
                                        fontSize: labelFontSize,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${global.moneyFormat.format(item['value'] as double)} ฿",
                                    style: TextStyle(
                                      fontSize: valueFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            )),

                        // Divider
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: padding * 0.75),
                          child: Divider(color: Colors.grey.shade200, thickness: 1),
                        ),

                        // Change Amount - Highlighted
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade400, Colors.green.shade600],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.currency_exchange,
                                    size: isMobile ? 20 : 24,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    global.language("money_change"),
                                    style: TextStyle(
                                      fontSize: labelFontSize,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${global.moneyFormat.format(changeAmount)} ฿",
                                style: TextStyle(
                                  fontSize: totalFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: padding),

                        // Confirm Button
                        SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.check_circle_outline, size: isMobile ? 20 : 24),
                            label: Text(
                              global.language("confirm"),
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _showErrorDialog() async {
    final isTablet = MediaQuery.of(context).size.width > 600;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red.shade50, Colors.white],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade600, Colors.red.shade500],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.white, size: isTablet ? 32 : 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          global.language("payment_failed"),
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: isTablet ? 64 : 48,
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        global.language("cannot_connect_edc"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          label: Text(
                            global.language("ok"),
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
