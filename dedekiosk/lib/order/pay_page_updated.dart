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
    final isTablet = screenSize.width > 600;
    int gridViewCount = isTablet ? 4 : 2;

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

    Widget paymentList = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: GridView.count(
        crossAxisCount: gridViewCount,
        childAspectRatio: isTablet ? 1.2 : 1.0,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          // Cash Payment
          if (global.deviceConfig.machineCondition == 0)
            _buildPaymentCard(
              context: context,
              isTablet: isTablet,
              colors: [Colors.green.shade50, Colors.green.shade100],
              borderColor: Colors.green.shade300,
              shadowColor: Colors.green,
              bottomColor: Colors.green.shade600,
              icon: Icons.money,
              iconColor: Colors.green.shade700,
              title: global.language("pay_by_cash"),
              imageUrl: "https://as2.ftcdn.net/v2/jpg/03/33/51/03/1000_F_333510357_rY9B8sKyQ5BZBLYuDHphMTtMlu5ASX1A.jpg",
              onTap: () => _handleCashPayment(),
            ),

          // Delivery Payment
          if (global.saleChannelCode.isNotEmpty && global.deviceConfig.machineCondition == 0)
            _buildPaymentCard(
              context: context,
              isTablet: isTablet,
              colors: [Colors.orange.shade50, Colors.orange.shade100],
              borderColor: Colors.orange.shade300,
              shadowColor: Colors.orange,
              bottomColor: Colors.orange.shade600,
              icon: Icons.delivery_dining,
              iconColor: Colors.orange.shade700,
              title: global.saleChannelCode,
              imageUrl: global.shopProfile!.orderstation.salechannels!.firstWhere((element) => element.code == global.saleChannelCode).imageuri,
              onTap: () => _handleDeliveryPayment(),
            ),

          // Credit Card Payment
          if (global.edcProductName.isNotEmpty)
            _buildPaymentCard(
              context: context,
              isTablet: isTablet,
              colors: [Colors.blue.shade50, Colors.blue.shade100],
              borderColor: Colors.blue.shade300,
              shadowColor: Colors.blue,
              bottomColor: Colors.blue.shade600,
              title: global.language("pay_by_creditcard"),
              assetPath: "assets/images/creditcard1.png",
              onTap: () => _handleCreditCardPayment(),
            ),

          // QR EDC Payment
          if (global.edcProductName.isNotEmpty)
            _buildPaymentCard(
              context: context,
              isTablet: isTablet,
              colors: [Colors.purple.shade50, Colors.purple.shade100],
              borderColor: Colors.purple.shade300,
              shadowColor: Colors.purple,
              bottomColor: Colors.purple.shade600,
              title: global.language("pay_by_qr_edc"),
              assetPath: "assets/images/qrpay1.png",
              onTap: () => _handleQREdcPayment(),
            ),

          // QR Payment
          if (global.edcProductName.isNotEmpty)
            _buildPaymentCard(
              context: context,
              isTablet: isTablet,
              colors: [Colors.teal.shade50, Colors.teal.shade100],
              borderColor: Colors.teal.shade300,
              shadowColor: Colors.teal,
              bottomColor: Colors.teal.shade600,
              title: global.language("pay_by_qr_payment"),
              assetPath: "assets/images/qrpay1.png",
              onTap: () => _handleQRPayment(),
            ),

          // QR Profile Payments
          for (var index = 0; index < global.profileQrPayment.length; index++)
            if (global.deviceConfig.machineCondition == 0 || (global.deviceConfig.machineCondition != 0 && global.profileQrPayment[index].qrtype != 100))
              _buildPaymentCard(
                context: context,
                isTablet: isTablet,
                colors: [Colors.indigo.shade50, Colors.indigo.shade100],
                borderColor: Colors.indigo.shade300,
                shadowColor: Colors.indigo,
                bottomColor: Colors.indigo.shade600,
                icon: Icons.qr_code,
                iconColor: Colors.indigo.shade700,
                title: global.getNameFromLanguage(global.profileQrPayment[index].qrnames, global.languageForCustomer),
                imageUrl: global.profileQrPayment[index].logo,
                onTap: () => _handleQRProfilePayment(index),
              ),
        ],
      ),
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade50,
                Colors.white,
                Colors.orange.shade50,
              ],
            ),
          ),
          child: Column(
            children: [
              // Header Section
              _buildHeaderSection(isTablet),

              // Payment Methods Grid
              Expanded(child: paymentList),

              // Cancel Button
              _buildCancelButton(isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isTablet) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                color: Colors.blue.shade600,
                size: isTablet ? 32 : 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  global.language("select_payment_method"),
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildPaymentHeaderList(isTablet),
        ],
      ),
    );
  }

  List<Widget> _buildPaymentHeaderList(bool isTablet) {
    List<Widget> widgets = [];

    // Order Tag Number
    if (widget.orderTagNumber.isNotEmpty) {
      widgets.add(_buildInfoCard(
        icon: Icons.tag,
        iconColor: Colors.green.shade700,
        backgroundColor: [Colors.green.shade100, Colors.green.shade50],
        borderColor: Colors.green.shade300,
        text: 'เลขป้าย : ${widget.orderTagNumber}',
        textColor: Colors.green.shade700,
        fontSize: isTablet ? 18 : 16,
      ));
    }

    // Amount
    widgets.add(_buildAmountCard(isTablet));

    // Cash Amount (if any)
    if (payCashAmount > 0) {
      widgets.add(_buildInfoCard(
        icon: Icons.money,
        iconColor: Colors.purple.shade700,
        backgroundColor: [Colors.purple.shade100, Colors.purple.shade50],
        borderColor: Colors.purple.shade300,
        text: 'ชำระด้วยเงินสด ${global.moneyFormatAndDot.format(payCashAmount)} ${global.language('money_symbol')}',
        textColor: Colors.purple.shade700,
        fontSize: isTablet ? 16 : 14,
      ));

      widgets.add(_buildInfoCard(
        icon: Icons.pending_actions,
        iconColor: Colors.orange.shade700,
        backgroundColor: [Colors.orange.shade100, Colors.orange.shade50],
        borderColor: Colors.orange.shade300,
        text: 'ยอดคงเหลือชำระอีก ${global.moneyFormatAndDot.format(widget.amount - payCashAmount)} ${global.language('money_symbol')}',
        textColor: Colors.orange.shade700,
        fontSize: isTablet ? 16 : 14,
      ));
    }

    return widgets;
  }

  Widget _buildAmountCard(bool isTablet) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  global.language('money_amount'),
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
                Text(
                  '${global.moneyFormatAndDot.format(widget.amount)} ${global.language('money_symbol')}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: isTablet ? 20 : 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required List<Color> backgroundColor,
    required Color borderColor,
    required String text,
    required Color textColor,
    required double fontSize,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: backgroundColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard({
    required BuildContext context,
    required bool isTablet,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.3),
                spreadRadius: 3,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: _buildPaymentImage(imageUrl, assetPath, icon, iconColor),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: bottomColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentImage(String? imageUrl, String? assetPath, IconData? icon, Color? iconColor) {
    if (assetPath != null) {
      return Image.asset(assetPath, fit: BoxFit.contain);
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        fit: BoxFit.contain,
        imageUrl: imageUrl,
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(
          icon ?? Icons.payment,
          size: 48,
          color: iconColor ?? Colors.grey,
        ),
      );
    }

    return Icon(
      icon ?? Icons.payment,
      size: 48,
      color: iconColor ?? Colors.grey,
    );
  }

  Widget _buildCancelButton(bool isTablet) {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.cancel, color: Colors.white),
        onPressed: () {
          global.payCondition.clear();
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade500,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 16 : 14,
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        label: Text(
          global.language("cancel"),
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Payment Handler Methods
  Future<void> _handleCashPayment() async {
    setState(() {
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
  }

  Future<void> _handleDeliveryPayment() async {
    if (mounted) {
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
      if (payResult == true && context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleCreditCardPayment() async {
    setState(() {
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
        if (context.mounted) await _showErrorDialog();
        return;
      }

      _updatePaymentCondition(res, 1, global.language("pay_by_creditcard"));

      if (payCashAmount >= roundAmount && mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleQREdcPayment() async {
    setState(() {
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
  }

  Future<void> _handleQRPayment() async {
    setState(() {
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

      if (payCashAmount >= roundAmount && context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleQRProfilePayment(int index) async {
    if (mounted) {
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
                customerCode: widget.orderTagNumber,
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

      if (payResult == true && context.mounted) {
        Navigator.pop(context);
      }
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
    final isTablet = MediaQuery.of(context).size.width > 600;

    TextStyle style = TextStyle(
      fontSize: (global.isMobileScreen) ? 18 : 32,
      fontWeight: FontWeight.bold,
    );

    List<String> payWords = [global.language("amount"), global.language("round_money"), global.language("total_amount"), global.language("pay_by_cash"), global.language("money_change")];

    List<double> payValues = [widget.amount, roundAmount - widget.amount, roundAmount, payCashAmount, payCashAmount - roundAmount];

    List<Color> payColors = [
      Colors.blue,
      Colors.red,
      Colors.purple,
      Colors.green,
      Colors.orange,
    ];

    if (context.mounted) {
      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade50, Colors.white],
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
                        colors: [Colors.green.shade600, Colors.green.shade500],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: isTablet ? 32 : 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'สรุปการชำระเงิน',
                            style: TextStyle(
                              fontSize: isTablet ? 24 : 20,
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
                        for (int i = 0; i < payWords.length; i++)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: payColors[i].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: payColors[i].withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    payWords[i],
                                    style: style.copyWith(
                                      color: payColors[i],
                                      fontSize: isTablet ? 18 : 16,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    global.moneyFormatAndDot.format(payValues[i]),
                                    textAlign: TextAlign.right,
                                    style: style.copyWith(
                                      color: payColors[i],
                                      fontSize: isTablet ? 20 : 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  global.language("money_baht"),
                                  style: style.copyWith(
                                    color: payColors[i],
                                    fontSize: isTablet ? 16 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                            label: Text(
                              global.language("confirm"),
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
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
                          "ชำระเงินไม่สำเร็จ",
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
                        "ไม่สามารถเชื่อมต่อเครื่อง EDC ได้",
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
                            "ตกลง",
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
