// ignore_for_file: library_prefixes
import 'package:dedecashier/api/clickhouse/clickhouse_api.dart' as api;
import 'dart:developer' as dev;
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/features/pos/presentation/screens/pay/pay_credit.dart';
import 'package:dedecashier/model/json/customer_display_model.dart';
import 'package:dedecashier/model/objectbox/order_temp_struct.dart';
import 'package:dedecashier/model/objectbox/pos_log_struct.dart';
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:promptpay/promptpay.dart';
import 'dart:convert';
import 'package:dedecashier/bloc/pay_screen_bloc.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/features/pos/presentation/screens/pay/pay_cash.dart';
import 'package:dedecashier/features/pos/presentation/screens/pay/pay_coupon.dart';
import 'package:dedecashier/features/pos/presentation/screens/pay/pay_util.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_print.dart';
import 'package:dedecashier/services/coupon_manager.dart';
import 'package:dedecashier/widgets/button.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:uuid/uuid.dart';
import 'package:dedecashier/util/widget_sound_extensions.dart';
import 'pay_credit_card.dart';
import 'pay_transfer.dart';
import 'pay_discount.dart';
import 'pay_cheque.dart';
import 'pay_qr.dart';
import 'pay_widget.dart';
import '../pos_util.dart' as posUtil;
import 'package:dedecashier/util/pos_compile_process.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/flavors.dart';

// ⭐ Theme Colors: MARINEPOS = น้ำเงินเข้ม, อื่นๆ = อิฐบ้านเชียง (Terracotta)
final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF003366) : const Color(0xFFB5651D);

class PayScreenPage extends StatefulWidget {
  final global.PosScreenModeEnum posScreenMode;
  final PosHoldProcessModel posProcess;
  final int defaultTabIndex;
  final int docMode;

  const PayScreenPage({super.key, required this.posScreenMode, required this.posProcess, required this.defaultTabIndex, required this.docMode});

  @override
  State<PayScreenPage> createState() => _PayScreenPageState();
}

class _PayScreenPageState extends State<PayScreenPage> with TickerProviderStateMixin {
  String _textInputCash = "";
  late TabController tabBarMenuController;
  double sumTotalPayAmount = 0;
  double diffAmount = 0;
  double currentPointBalance = 0;
  TextEditingController pointsCodeTextEditor = TextEditingController();
  GlobalKey<PayCashWidgetState> posPayCashGlobalKey = GlobalKey();
  GlobalKey<PayQrWidgetState> posQrGlobalKey = GlobalKey();
  bool payProcess = false;

  @override
  void initState() {
    super.initState();
    pointsCodeTextEditor.text = widget.posProcess.customerPointsCode;
    tabBarMenuController = TabController(length: 8, vsync: this);
    tabBarMenuController.addListener(() {
      global.playSound(sound: global.SoundEnum.buttonTing);
      AppLogger.info("Selected Index: ${tabBarMenuController.index}");
      setState(() {});
    });
    sendPayScreenCommandToCustomerDisplay();
    tabBarMenuController.index = widget.defaultTabIndex;

    if (widget.posProcess.customerGuid.isNotEmpty) {
      _loadCustomerPointBalance();
    }
    global.couponCustomerId = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].customerCode.isNotEmpty
        ? global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].customerCode
        : const Uuid().v4();

    Timer(const Duration(milliseconds: 200), () {
      reCalc();
      if (widget.defaultTabIndex == 2) {
        //posQrGlobalKey.currentState!.promptPay(amount: diffAmount, provider: global.qrPaymentProviderList[0]);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    tabBarMenuController.dispose();
  }

  Future<void> sendPayScreenCommandToCustomerDisplay() async {
    for (int index = 0; index < global.customerDisplayDeviceList.length; index++) {
      AppLogger.info("sendPayScreenCommandToCustomerDisplay : ${global.customerDisplayDeviceList[index].ip}");
      var url = "${global.customerDisplayDeviceList[index].ip}:5041";
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess.qr_code = PromptPay.generateQRData(
        "",
        amount: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess.total_amount,
      );
      var jsonData = HttpPost(command: "pay_screen", data: jsonEncode(global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].toJson()));
      global.postToServer(ip: url, jsonData: jsonEncode(jsonData.toJson()), callBack: () {});
    }
  }

  Widget moneyButton(double value) {
    String imagePath = ('assets/images/moneythai${value.toStringAsFixed(0)}.gif').toLowerCase();
    return PayButton(
      primary: Colors.blue[400],
      onPressed: () {
        setState(() {
          global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount + value;
        });
      },
      label: "+${value.toStringAsFixed(0)}",
      child: Image(image: AssetImage(imagePath), width: 60, fit: BoxFit.fill),
    );
  }

  void cashTextInputAdd(String word) {
    setState(() {
      _textInputCash = _textInputCash + word;
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount = global.calcTextToNumber(_textInputCash);
    });
  }

  Widget cashNumberPad() {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: NumPadButton(text: '7', callBack: () => {cashTextInputAdd("7")}),
              ),
              Expanded(
                child: NumPadButton(text: '8', callBack: () => {cashTextInputAdd("8")}),
              ),
              Expanded(
                child: NumPadButton(text: '9', callBack: () => {cashTextInputAdd("9")}),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: NumPadButton(text: '4', callBack: () => {cashTextInputAdd("4")}),
              ),
              Expanded(
                child: NumPadButton(text: '5', callBack: () => {cashTextInputAdd("5")}),
              ),
              Expanded(
                child: NumPadButton(text: '6', callBack: () => {cashTextInputAdd("6")}),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: NumPadButton(text: '1', callBack: () => {cashTextInputAdd("1")}),
              ),
              Expanded(
                child: NumPadButton(text: '2', callBack: () => {cashTextInputAdd("2")}),
              ),
              Expanded(
                child: NumPadButton(text: '3', callBack: () => {cashTextInputAdd("3")}),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: NumPadButton(text: '0', callBack: () => {cashTextInputAdd("0")}),
              ),
              Expanded(
                child: NumPadButton(text: '.', callBack: () => {cashTextInputAdd(".")}),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: NumPadButton(
                  textAndIconColor: Colors.black,
                  icon: Icons.backspace,
                  color: Colors.red.shade200,
                  callBack: () => {
                    if (_textInputCash.isNotEmpty)
                      {
                        setState(() {
                          _textInputCash = _textInputCash.substring(0, _textInputCash.length - 1);
                          global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount = global.calcTextToNumber(_textInputCash);
                        }),
                      },
                  },
                ),
              ),
              Expanded(
                child: NumPadButton(
                  text: 'C',
                  color: Colors.grey.shade400,
                  callBack: () => {
                    setState(() {
                      _textInputCash = "";
                      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount = 0;
                    }),
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void paySuccessDialog() {
    String moneySymbol = global.language('money_symbol');
    double fontSize = (global.isDesktopScreen() || global.isTabletScreen()) ? 32 : 24;
    global.customerDisplayPaySuccessData = CustomerDisplayPaySuccessData(widget.posProcess.posProcess.total_amount, sumTotalPayAmount, diffAmount, moneySymbol);
    global.customerDisplayCommand = "paysuccess";
    global.sendProcessToCustomerDisplay(mode: global.secondScreenCommandPay);

    // Create a timer variable that we can cancel later
    Timer? dialogTimer;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        // Start the timer
        dialogTimer = Timer(const Duration(seconds: 60), () {
          try {
            global.customerDisplayPaySuccessData = CustomerDisplayPaySuccessData(0, 0, 0, '');
            global.customerDisplayCommand = "";
            global.sendProcessToCustomerDisplay(mode: global.secondScreenCommandPay);

            // Check if dialog context can still be popped
            if (Navigator.canPop(context)) {
              // Close the alert dialog
              Navigator.pop(context);

              // Check if parent context can still be popped
              if (mounted && Navigator.canPop(context)) {
                // Close the pay screen and clear data to start new sale
                Navigator.pop(context, true);
              }
            }
          } catch (e) {
            AppLogger.error(e);
          }
        });

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        global.language("total_amount_product_service"),
                        style: TextStyle(decoration: TextDecoration.none, fontSize: fontSize, color: Colors.blue),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        "${global.moneyFormatAndDot.format(widget.posProcess.posProcess.total_amount + widget.posProcess.payScreenData.round_amount)} $moneySymbol",
                        style: TextStyle(decoration: TextDecoration.none, fontSize: fontSize, color: Colors.blue),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        global.language("total_payment_amount"),
                        style: TextStyle(decoration: TextDecoration.none, fontSize: fontSize, color: Colors.green),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${global.moneyFormatAndDot.format(sumTotalPayAmount)} $moneySymbol',
                        style: TextStyle(decoration: TextDecoration.none, fontSize: fontSize, color: Colors.green),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        global.language("money_change"),
                        style: TextStyle(decoration: TextDecoration.none, fontSize: fontSize, color: Colors.orange),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${global.moneyFormatAndDot.format(diffAmount * -1)} $moneySymbol',
                        style: TextStyle(decoration: TextDecoration.none, fontSize: fontSize, color: Colors.orange),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      global.playSound(sound: global.SoundEnum.buttonTing);
                      // Cancel the timer when the button is pressed
                      dialogTimer?.cancel();

                      global.customerDisplayPaySuccessData = CustomerDisplayPaySuccessData(0, 0, 0, '');
                      global.customerDisplayCommand = "";
                      global.sendProcessToCustomerDisplay(mode: global.secondScreenCommandPay);

                      // Close the alert dialog
                      Navigator.of(context).pop();

                      // Close the pay screen and clear data to start new sale
                      Navigator.pop(context, true);
                    },
                    child: Text(
                      global.language("ok"),
                      style: const TextStyle(decoration: TextDecoration.none, fontSize: 25, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // This runs when the dialog is closed by any means
      // Cancel the timer to prevent it from firing after dialog is closed
      dialogTimer?.cancel();
    });
  }

  void reCalc() {
    // ยอดรวมหลังหักส่วนลด

    global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_amount =
        widget.posProcess.posProcess.total_amount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.discount_amount;
    global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount =
        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_amount - global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.discount_amount;
    widget.posProcess.payScreenData.total_after_discount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount;
    widget.posProcess.payScreenData.cash_amount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount;
    sumTotalPayAmount =
        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount +
        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.credit_amount +
        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.point_amount +
        sumCouponCashVoucher(global.posHoldActiveCode) + // ใช้เฉพาะ cash voucher สำหรับการชำระ
        sumCreditCard(global.posHoldActiveCode) +
        sumTransfer(global.posHoldActiveCode) +
        sumCheque(global.posHoldActiveCode) +
        sumQr(global.posHoldActiveCode);
    // ปัดเศษ
    global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, -1);
    widget.posProcess.posProcess.coupondiscount = sumCouponDiscount(global.posHoldActiveCode);
    widget.posProcess.payScreenData.round_amount = 0;
    if (tabBarMenuController.index == 0) {
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_cash = 0;
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, -1);
      double roundmoney = global.roundDouble(
        calculateRoundedAmount(
              (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                  sumTotalPayAmount,
              'cash',
            ) -
            ((global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                sumTotalPayAmount),
        2,
      );

      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_cash = roundmoney;

      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, 0);
      widget.posProcess.payScreenData.round_amount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount;
    } else if (tabBarMenuController.index == 2) {
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_qr = 0;
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, -1);
      double roundmoney = global.roundDouble(
        calculateRoundedAmount(
              (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                  sumTotalPayAmount,
              'qrcode',
            ) -
            ((global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                sumTotalPayAmount),
        2,
      );

      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_qr = roundmoney;
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, 2);
      widget.posProcess.payScreenData.round_amount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount;
    } else if (tabBarMenuController.index == 3) {
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_credit_card = 0;
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, -1);
      double roundmoney = global.roundDouble(
        calculateRoundedAmount(
              (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                  sumTotalPayAmount,
              'creditcard',
            ) -
            ((global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                sumTotalPayAmount),
        2,
      );

      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_credit_card = roundmoney;
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, 3);
      widget.posProcess.payScreenData.round_amount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount;
    } else if (tabBarMenuController.index == 4) {
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_transfer = 0;
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, -1);
      double roundmoney = global.roundDouble(
        calculateRoundedAmount(
              (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                  sumTotalPayAmount,
              'banktransfer',
            ) -
            ((global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                sumTotalPayAmount),
        2,
      );

      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_transfer = roundmoney;

      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, 4);
      widget.posProcess.payScreenData.round_amount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount;
    } else if (tabBarMenuController.index == 5) {
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_cheque = 0;
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, -1);
      double roundmoney = global.roundDouble(
        calculateRoundedAmount(
              (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                  sumTotalPayAmount,
              'cheque',
            ) -
            ((global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                sumTotalPayAmount),
        2,
      );

      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_cheque = roundmoney;

      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, 5);
      widget.posProcess.payScreenData.round_amount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount;
    } else if (tabBarMenuController.index == 6) {
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_coupon = 0;
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, -1);
      double roundmoney = global.roundDouble(
        calculateRoundedAmount(
              (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                  sumTotalPayAmount,
              'coupon',
            ) -
            ((global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                sumTotalPayAmount),
        2,
      );

      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_coupon = roundmoney;
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, 6);
      widget.posProcess.payScreenData.round_amount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount;
    } else if (tabBarMenuController.index == 7) {
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_credit = 0;
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, -1);
      double roundmoney = global.roundDouble(
        calculateRoundedAmount(
              (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                  sumTotalPayAmount,
              'creditcard',
            ) -
            ((global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount) -
                sumTotalPayAmount),
        2,
      );

      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount_credit = roundmoney;

      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = sumRoundAmount(global.posHoldActiveCode, 7);
      widget.posProcess.payScreenData.round_amount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount;
    }

    // switch (global.payTotalMoneyRoundType) {
    //   case 0: // 0=ไม่ปัดเศษ
    //     break;
    //   case 1: // 1=ปัดเศษตามกฏหมาย
    //     global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount = global.roundDouble(
    //         global.roundMoneyForPay(global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount) -
    //             global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount,
    //         2);
    //     widget.posProcess.payScreenData.round_amount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount;
    //     break;
    //   case 2: // 2=ปัดเศษขึ้นเป็นจำนวนเต็ม
    //     break;
    //   case 3: // 3=ปัดเศษลงเป็นจำนวนเต็ม
    //     break;
    // }
    // ยอดรวมหลังปัดเศษ
    global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_round =
        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount;

    widget.posProcess.payScreenData.total_after_round = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_round;

    diffAmount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_round - sumTotalPayAmount;

    if (posPayCashGlobalKey.currentState != null) {
      posPayCashGlobalKey.currentState!.setPayAmount(diffAmount);
    }

    widget.posProcess.posProcess.total_credit_card_amount = sumCreditCard(global.posHoldActiveCode);

    widget.posProcess.posProcess.total_transfer_amount = sumTransfer(global.posHoldActiveCode);

    widget.posProcess.posProcess.total_cheque_amount = sumCheque(global.posHoldActiveCode);

    widget.posProcess.posProcess.total_qr_code_amount = sumQr(global.posHoldActiveCode);

    widget.posProcess.posProcess.total_coupon_amount = sumCouponCashVoucher(global.posHoldActiveCode);

    widget.posProcess.posProcess.total_credit_amount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.credit_amount;
  }

  double calculateRoundedAmount(double amount, String paymentType) {
    double roundedAmount = amount;

    PaymentMethodRoundingModel roundingConfig;

    Iterable<ProfileSettingBranchModel> branchModels = global.profileSetting.branch.where((element) => element.guidfixed == global.posConfig.branch.guidfixed);
    ProfileSettingBranchModel branchModel = branchModels.isNotEmpty ? branchModels.first : ProfileSettingBranchModel();

    switch (paymentType) {
      case 'cash':
        roundingConfig = branchModel.paymentrounding.cash;
        break;
      case 'creditcard':
        roundingConfig = branchModel.paymentrounding.creditcard;
        break;
      case 'qrcode':
        roundingConfig = branchModel.paymentrounding.qrcode;
        break;
      case 'banktransfer':
        roundingConfig = branchModel.paymentrounding.banktransfer;
        break;
      case 'cheque':
        roundingConfig = branchModel.paymentrounding.cheque;
        break;
      case 'coupon':
        roundingConfig = branchModel.paymentrounding.coupon;
        break;
      case 'delivery':
        roundingConfig = branchModel.paymentrounding.delivery;
        break;
      default:
        return roundedAmount;
    }

    if (roundingConfig.enabled != true || roundingConfig.rules.isEmpty) {
      return roundedAmount;
    }

    int wholePart = amount.floor();
    double decimalPart = (amount - wholePart);
    double roundedDecimalPart = double.parse(decimalPart.toStringAsFixed(2));
    for (var rule in roundingConfig.rules) {
      if (roundedDecimalPart >= rule.lowerbound && roundedDecimalPart <= rule.upperbound) {
        roundedAmount = wholePart + rule.roundto;
        break;
      }
    }

    return roundedAmount;
  }

  Future<void> payProcessSave(global.PosScreenModeEnum posScreenMode) async {
    try {
      global.isOnline = await global.hasNetwork();
      reCalc(); // Recalculate before saving the bill
      String pointsCode = pointsCodeTextEditor.text.isNotEmpty ? pointsCodeTextEditor.text.trim() : "";
      await posUtil
          .saveBill(
            docMode: widget.docMode,
            totalAmountAfterDiscount: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_discount,
            roundAmount: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount,
            tableNumber: global.tableNumberSelected,
            totalAmount: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_round,
            cashAmount: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount,
            discountFormula: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess.detail_discount_formula,
            discountAmount: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess.detail_total_discount,
            isDelivery: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.is_delivery,
            deliveryCode: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.delivery_code,
            deliveryNumber: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.delivery_number,
            posHoldActiveCode: global.posHoldActiveCode,
            pointscode: pointsCode,
          )
          .then((value) async {
            if (value.docNumber.isNotEmpty) {
              // Clear coupons after successful bill save
              CouponManager().clearAllCoupons(afterSale: true);

              // Process successful save and print the bill
              await printBillProcess(posScreenMode: posScreenMode, docDate: value.docDate, docNo: value.docNumber, printLogo: global.posTicket.logo, languageCode: global.userScreenLanguage, isPaySlip: true);

              if (global.posConfig.iscopyreceipt) {
                // Print a copy
                await printBillProcess(posScreenMode: posScreenMode, docDate: value.docDate, docNo: value.docNumber, printPaySlip: true, printLogo: false, topText: "สำเนา", languageCode: global.userScreenLanguage);
              }
              // Update table status
              final box = global.objectBoxStore.box<TableProcessObjectBoxStruct>();
              final result = box.query(TableProcessObjectBoxStruct_.number.equals(global.tableNumberSelected)).build().findFirst();
              if (result != null) {
                if (result.number.contains("#")) {
                  box.remove(result.id); // Remove temporary tables
                } else {
                  result.table_status = 0; // Mark table as free
                  box.put(result);
                }
              }

              // Update orders as paid
              final boxOrder = global.objectBoxStore.box<OrderTempObjectBoxStruct>().query(OrderTempObjectBoxStruct_.orderGuid.equals(global.tableNumberSelected).and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))).build().find();
              for (var item in boxOrder) {
                item.isPaySuccess = true;
                global.objectBoxStore.box<OrderTempObjectBoxStruct>().put(item, mode: PutMode.update);
              }

              // Remove held bills
              var posLog = global.objectBoxStore.box<PosLogObjectBoxStruct>().query(PosLogObjectBoxStruct_.hold_code.equals(global.posHoldActiveCode)).build().find();
              for (var item in posLog) {
                global.objectBoxStore.box<PosLogObjectBoxStruct>().remove(item.id);
              }

              if (global.isOnline) {
                String query = "alter table dedeorderonline.tableinfo delete where tablenumber='${global.tableNumberSelected}' and shopid='${global.shopId}'";
                await api.clickHouseExecute(query);

                query = "alter table dedeorderonline.ordertemp delete where orderid='${global.tableNumberSelected}' and shopid='${global.shopId}'";
                await api.clickHouseExecute(query);
              }

              paySuccessDialog();

              global.tableNumberSelected = "";
              // global.posHoldActiveCode = "0";
            }
          });
    } catch (e) {
      // Handle errors and retry
      AppLogger.error('Error during payProcessSave: $e');
    }
  }

  Widget paySummeryScreen({required int docMode}) {
    String moneySymbol = global.language('money_symbol');
    reCalc();
    TextStyle textStyle = TextStyle(fontSize: (global.isTabletScreen() || global.isDesktopScreen()) ? 24 : 10);
    String beforeWord = (widget.posProcess.posProcess.total_discount_vat_amount != 0 && widget.posProcess.posProcess.total_discount_except_vat_amount != 0) ? global.language("average") : "";

    Widget payWidget = Padding(
      padding: const EdgeInsets.all(5),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade300, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
                onPressed: () => _showPointsCodeDialog(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.key, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      (pointsCodeTextEditor.text.isEmpty) ? global.language('points_code') : pointsCodeTextEditor.text,
                      style: textStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            if (widget.posProcess.customerCode.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade300),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Row(
                          children: [
                            Text("${global.language("customer")}: ", style: textStyle),
                            Text("${widget.posProcess.customerCode} ${widget.posProcess.customerName}", style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.green, size: 16),
                            const SizedBox(width: 5),
                            Text("${global.language("point_balance")}: ", style: textStyle.copyWith(color: Colors.green)),
                            Text(
                              global.moneyFormat.format(currentPointBalance),
                              style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (widget.posProcess.posProcess.usepoint > 0)
                          Row(
                            children: [
                              Icon(Icons.remove_circle, color: Colors.red.shade600, size: 16),
                              const SizedBox(width: 5),
                              Text("${global.language("used_points")}: ", style: textStyle.copyWith(color: Colors.red.shade600)),
                              Text(
                                global.moneyFormat.format(widget.posProcess.posProcess.usepoint),
                                style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade600),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
                        onPressed: () => _showUsePointsDialog(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              global.language('use_points'),
                              style: textStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(global.language('total_amount'), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(global.moneyFormatAndDot.format(widget.posProcess.posProcess.detail_total_amount_before_discount), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 5),
                Text(moneySymbol, style: textStyle),
              ],
            ),
            if (widget.posProcess.posProcess.total_piece != widget.posProcess.posProcess.total_piece_vat)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${global.language("product_has_tax")} : ${global.moneyFormat.format(widget.posProcess.posProcess.total_piece_vat)} ${global.language("piece")}", style: textStyle),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(global.moneyFormatAndDot.format(widget.posProcess.posProcess.total_item_vat_amount), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(moneySymbol, style: textStyle),
                ],
              ),
            if (widget.posProcess.posProcess.total_piece != widget.posProcess.posProcess.total_piece_vat)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${global.language("product_tax_exempt")} : ${global.moneyFormat.format(widget.posProcess.posProcess.total_piece_except_vat)} ${global.language("piece")}", style: textStyle),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(global.moneyFormatAndDot.format(widget.posProcess.posProcess.total_item_except_vat_amount), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(moneySymbol, style: textStyle),
                ],
              ),
            if ((widget.posProcess.posProcess.total_discount_from_promotion + widget.posProcess.posProcess.total_discount_from_promotion_bottom) != 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(global.language("promotion_discount"), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(global.moneyFormatAndDot.format(widget.posProcess.posProcess.total_discount_from_promotion + widget.posProcess.posProcess.total_discount_from_promotion_bottom), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(moneySymbol, style: textStyle),
                ],
              ),
            if (widget.posProcess.posProcess.pointdiscountamount > 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    global.language("point_discount_amount"),
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        global.moneyFormatAndDot.format(widget.posProcess.posProcess.pointdiscountamount),
                        style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(moneySymbol, style: textStyle),
                ],
              ),
            if (widget.posProcess.posProcess.coupondiscount > 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    global.language("coupon_discount_amount"),
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        global.moneyFormatAndDot.format(widget.posProcess.posProcess.coupondiscount),
                        style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(moneySymbol, style: textStyle),
                ],
              ),
            // หักส่วนลด
            if (widget.posProcess.posProcess.detail_total_discount -
                    (widget.posProcess.posProcess.total_discount_from_promotion + widget.posProcess.posProcess.total_discount_from_promotion_bottom + widget.posProcess.posProcess.coupondiscount + widget.posProcess.posProcess.pointdiscountamount) !=
                0)
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${global.language("discount_product")} : ${widget.posProcess.posProcess.detail_discount_formula}", style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            global.moneyFormatAndDot.format(
                              widget.posProcess.posProcess.detail_total_discount -
                                  (widget.posProcess.posProcess.total_discount_from_promotion + widget.posProcess.posProcess.total_discount_from_promotion_bottom + widget.posProcess.posProcess.coupondiscount + widget.posProcess.posProcess.pointdiscountamount),
                            ),
                            style: textStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(moneySymbol, style: textStyle),
                    ],
                  ),
                  if (widget.posProcess.posProcess.total_discount_vat_amount != 0)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("$beforeWord${global.language("discount_product_vat")}", style: textStyle),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(global.moneyFormatAndDot.format(widget.posProcess.posProcess.total_discount_vat_amount), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(moneySymbol, style: textStyle),
                      ],
                    ),
                  if (widget.posProcess.posProcess.total_discount_except_vat_amount != 0)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("$beforeWord${global.language("discount_prtoduct_no_vat")}", style: textStyle),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(global.moneyFormatAndDot.format(widget.posProcess.posProcess.total_discount_except_vat_amount), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(moneySymbol, style: textStyle),
                      ],
                    ),
                ],
              ),
            if (widget.posProcess.posProcess.amount_before_calc_vat != 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(global.language("pre_tax_value"), style: textStyle),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(global.moneyFormatAndDot.format(widget.posProcess.posProcess.amount_before_calc_vat), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(moneySymbol, style: textStyle),
                ],
              ),
            if (widget.posProcess.posProcess.total_vat_amount != 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(global.language("value_added_tax"), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(global.moneyFormatAndDot.format(widget.posProcess.posProcess.total_vat_amount), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(moneySymbol, style: textStyle),
                ],
              ),
            if (widget.posProcess.posProcess.amount_after_calc_vat != 0 && widget.posProcess.posProcess.amount_after_calc_vat != widget.posProcess.posProcess.total_amount)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(global.language("value_after_tax"), style: textStyle),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(global.moneyFormatAndDot.format(widget.posProcess.posProcess.amount_after_calc_vat), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(moneySymbol, style: textStyle),
                ],
              ),
            if (widget.posProcess.posProcess.amount_except_vat != 0 && widget.posProcess.posProcess.amount_except_vat != widget.posProcess.posProcess.total_amount)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(global.language("value_tax_exempt"), style: textStyle),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(global.moneyFormatAndDot.format(widget.posProcess.posProcess.amount_except_vat), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(moneySymbol, style: textStyle),
                ],
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(global.language("total"), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(global.moneyFormatAndDot.format(widget.posProcess.posProcess.total_amount), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 5),
                Text(moneySymbol, style: textStyle),
              ],
            ),
            // ปัดเศษ
            if (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount != 0)
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("ปัดเศษ", style: textStyle),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(global.moneyFormatAndDot.format(global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.round_amount), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(moneySymbol, style: textStyle),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("ยอดรวมหลังปัดเศษ", style: textStyle),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(global.moneyFormatAndDot.format(global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.total_after_round), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(moneySymbol, style: textStyle),
                    ],
                  ),
                ],
              ),
            // คูปอง
            if (sumCouponCashVoucher(global.posHoldActiveCode) != 0)
              Row(
                children: [
                  Text(global.language('total_pay_amount_coupon'), style: textStyle.copyWith(color: Colors.green)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        global.moneyFormatAndDot.format(sumCouponCashVoucher(global.posHoldActiveCode)),
                        style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    moneySymbol,
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            // ยอดชำระด้วยบัตรเครดิต
            if (sumCreditCard(global.posHoldActiveCode) != 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(global.language('total_pay_amount_card'), style: textStyle.copyWith(color: Colors.green)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        global.moneyFormatAndDot.format(sumCreditCard(global.posHoldActiveCode)),
                        style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    moneySymbol,
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),

            // ยอดชำระด้วยการโอน
            if (sumTransfer(global.posHoldActiveCode) != 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(global.language('total_pay_amount_transfer'), style: textStyle.copyWith(color: Colors.green)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        global.moneyFormatAndDot.format(sumTransfer(global.posHoldActiveCode)),
                        style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    moneySymbol,
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),

            // ยอดชำระด้วยเช็ค
            if (sumCheque(global.posHoldActiveCode) != 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(global.language('total_pay_amount_cheque'), style: textStyle.copyWith(color: Colors.green)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        global.moneyFormatAndDot.format(sumCheque(global.posHoldActiveCode)),
                        style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    moneySymbol,
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),

            // ยอดชำระด้วย Wallet
            if (sumQr(global.posHoldActiveCode) != 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(global.language('total_pay_amount_wallet'), style: textStyle.copyWith(color: Colors.green)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        global.moneyFormatAndDot.format(sumQr(global.posHoldActiveCode)),
                        style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    moneySymbol,
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ), // ยอดชำระด้วยเงินสด
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(global.language('total_pay_amount_cash'), style: textStyle.copyWith(color: Colors.green)),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      global.moneyFormatAndDot.format(global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount),
                      style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  moneySymbol,
                  style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            // ยอดชำระด้วย Point
            if (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.point_amount != 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(global.language('point_payment'), style: textStyle.copyWith(color: Colors.green)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        global.moneyFormatAndDot.format(global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.point_amount),
                        style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    moneySymbol,
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            // ยอดเงินเชื่อ
            if (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.credit_amount != 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(global.language('credit'), style: textStyle.copyWith(color: Colors.green)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        global.moneyFormatAndDot.format(global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.credit_amount),
                        style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    moneySymbol,
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            if (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount != sumTotalPayAmount)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(global.language('total_pay_amount'), style: textStyle.copyWith(color: Colors.blue)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        global.moneyFormatAndDot.format(sumTotalPayAmount),
                        style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    moneySymbol,
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  global.language('total_pay_amount_diff'),
                  style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      global.moneyFormatAndDot.format(diffAmount),
                      style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  moneySymbol,
                  style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
            if (widget.posProcess.posProcess.getpoint > 0 && pointsCodeTextEditor.text.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    global.language('earned_points'),
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade600),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        global.moneyFormatAndDot.format(widget.posProcess.posProcess.getpoint),
                        style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade600),
                      ),
                    ),
                  ),
                ],
              ),
            //แต้มคงเหลือหลังจากทั้งหมด
            if (widget.posProcess.customerCode.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    global.language('point_balance_after'),
                    style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade600),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].customerPointsCode == pointsCodeTextEditor.text)
                            ? global.moneyFormatAndDot.format(currentPointBalance + widget.posProcess.posProcess.getpoint)
                            : global.moneyFormatAndDot.format(currentPointBalance),
                        style: textStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade600),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
    // รายละเอียด/รูปแบบ การชำระเงิน
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(7)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0), topRight: Radius.circular(4.0)),
            ),
            child: Center(
              child: Text(
                global.language("pay_channel"),
                style: TextStyle(color: Colors.black, fontSize: (global.isTabletScreen() || global.isDesktopScreen()) ? 24 : 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          (global.isTabletScreen() || global.isDesktopScreen()) ? Expanded(child: payWidget) : Container(child: payWidget),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: Colors.red),
                    onPressed: () async {
                      if (payProcess == false) {
                        CouponManager().clearAllCoupons(afterSale: false);
                        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.coupon = [];

                        reCalc();
                        setState(() {});

                        Navigator.pop(context);
                      }
                    }.withButtonSound(),
                    child: (payProcess)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                              Text(
                                "",
                                style: TextStyle(
                                  fontSize: (global.isTabletScreen() || global.isDesktopScreen()) ? 32.0 : 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [(diffAmount <= 0) ? const Shadow(offset: Offset(1.0, 1.0), blurRadius: 3.0, color: Colors.black) : const Shadow()],
                                ),
                              ),
                            ],
                          )
                        : Text(
                            global.language("back"),
                            style: TextStyle(
                              fontSize: (global.isTabletScreen() || global.isDesktopScreen()) ? 32.0 : 12,
                              fontWeight: FontWeight.bold,
                              shadows: const <Shadow>[Shadow(offset: Offset(1.0, 1.0), blurRadius: 3.0, color: Colors.black)],
                            ),
                          ),
                  ),
                ),
                SizedBox(width: (global.isTabletScreen() || global.isDesktopScreen()) ? 10 : 5, height: (global.isTabletScreen() || global.isDesktopScreen()) ? 10 : 5),
                Expanded(
                  child: ElevatedButton(
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: (diffAmount <= 0 && payProcess == false) ? Colors.green : Colors.grey),
                    onPressed: (diffAmount > 0 && !payProcess)
                        ? null
                        : () async {
                            if (payProcess == false) {
                              payProcess = true;
                              setState(() {});
                              await payProcessSave(widget.posScreenMode);
                            }
                          }.withPaymentSound(),
                    child: (payProcess)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                              Text(
                                "",
                                style: TextStyle(
                                  fontSize: (global.isTabletScreen() || global.isDesktopScreen()) ? 32.0 : 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [(diffAmount <= 0) ? const Shadow(offset: Offset(1.0, 1.0), blurRadius: 3.0, color: Colors.black) : const Shadow()],
                                ),
                              ),
                            ],
                          )
                        : Text(
                            global.language("pay"),
                            style: TextStyle(
                              fontSize: (global.isTabletScreen() || global.isDesktopScreen()) ? 32.0 : 12,
                              fontWeight: FontWeight.bold,
                              shadows: [(diffAmount <= 0) ? const Shadow(offset: Offset(1.0, 1.0), blurRadius: 3.0, color: Colors.black) : const Shadow()],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget commandButton({required int index, required Function onPressed, String label = "", IconData? icon}) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: (index == tabBarMenuController.index) ? _themeColor : Colors.white, // Blue for active, white for inactive
          foregroundColor: (index == tabBarMenuController.index) ? Colors.white : _themeColor, // White text for active, blue for inactive
          side: BorderSide(color: _themeColor, width: 2), // Blue border
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 12), // Increased padding for larger size
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6), // Less rounded corners
          ),
          elevation: (index == tabBarMenuController.index) ? 2 : 1, // Slight elevation difference
          minimumSize: const Size(80, 50), // Minimum size to ensure consistent larger buttons
        ),
        onPressed: () {
          onPressed();
        },
        child: (icon != null)
            ? FittedBox(
                fit: BoxFit.fill,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      icon,
                      size: 20, // Increased icon size
                      color: (index == tabBarMenuController.index) ? Colors.white : _themeColor, // Dynamic icon color
                    ),
                    const SizedBox(
                      width: 6, // Slightly more spacing
                    ),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: 14, // Increased font size
                        fontWeight: (index == tabBarMenuController.index) ? FontWeight.bold : FontWeight.normal, // Bold for active
                        color: (index == tabBarMenuController.index) ? Colors.white : _themeColor, // Dynamic text color
                      ),
                    ),
                  ],
                ),
              )
            : FittedBox(
                fit: BoxFit.fill,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: 14, // Increased font size
                    fontWeight: (index == tabBarMenuController.index) ? FontWeight.bold : FontWeight.normal, // Bold for active
                    color: (index == tabBarMenuController.index) ? Colors.white : _themeColor, // Dynamic text color
                  ),
                ),
              ),
      ),
    );
  }

  Widget commandWidget() {
    List<Widget> commands = [
      if (global.posUseSaleType)
        commandButton(
          index: 0,
          label: global.language("cash"),
          onPressed: () {
            setState(() {
              tabBarMenuController.index = 0;
            });
          },
        ),
      commandButton(
        index: 1,
        icon: FontAwesomeIcons.walkieTalkie,
        label: global.language("discount"),
        onPressed: () {
          tabBarMenuController.index = 1;
        },
      ),
      commandButton(
        index: 2,
        icon: FontAwesomeIcons.cashRegister,
        label: "Wallet",
        onPressed: () {
          tabBarMenuController.index = 2;
        },
      ),
      commandButton(
        index: 3,
        icon: FontAwesomeIcons.user,
        label: global.language('credit_card'),
        onPressed: () {
          tabBarMenuController.index = 3;
        },
      ),
      commandButton(
        index: 4,
        icon: FontAwesomeIcons.user,
        label: global.language('money_transfer'),
        onPressed: () {
          tabBarMenuController.index = 4;
        },
      ),
      commandButton(
        index: 5,
        icon: Icons.restart_alt,
        label: global.language('cheque'),
        onPressed: () {
          tabBarMenuController.index = 5;
        },
      ),
      commandButton(
        index: 6,
        icon: Icons.print,
        label: global.language('coupon'),
        onPressed: () {
          tabBarMenuController.index = 6;
        },
      ),
      // commandButton(
      //     index: 7,
      //     icon: Icons.print,
      //     label: global.language('credit'),
      //     onPressed: () {
      //       tabBarMenuController.index = 7;
      //     }),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int rowNumber = 1;
        if (constraints.maxWidth < 500) rowNumber = 2;
        if (constraints.maxWidth < 200) rowNumber = 3;
        List<Widget> columns = [];
        int itemCount = 0;
        int itemPerRow = (commands.length / rowNumber).ceil();
        for (int rowIndex = 0; rowIndex < rowNumber; rowIndex++) {
          List<Widget> rows = [];
          for (int columnIndex = 0; columnIndex < itemPerRow; columnIndex++) {
            if (itemCount < commands.length) {
              if (columnIndex != 0) {
                rows.add(const SizedBox(width: 4));
              }
              rows.add(commands[itemCount]);
              itemCount++;
            }
          }
          if (rowIndex != 0) {
            columns.add(const SizedBox(height: 4));
          }
          columns.add(
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.all(2),
          child: Column(children: columns),
        );
      },
    );
  }

  Widget payDetailScreen(BuildContext blocContext) {
    List<Widget> tabViewList = [];
    tabViewList.add(PayCashWidget(blocContext: blocContext, key: posPayCashGlobalKey));
    tabViewList.add(PayDiscountWidget(posProcess: widget.posProcess, blocContext: blocContext));
    tabViewList.add(
      PayQrWidget(
        key: posQrGlobalKey,
        posProcess: widget.posProcess,
        blocContext: blocContext,
        onPaySuccess: () async {
          if (payProcess == false) {
            payProcess = true;
            setState(() {});
            await payProcessSave(widget.posScreenMode);
          }
        },
      ),
    );
    tabViewList.add(PayCreditCard(posProcess: widget.posProcess, blocContext: blocContext));
    tabViewList.add(PayTransfer(posProcess: widget.posProcess, blocContext: blocContext));
    tabViewList.add(PayCheque(posProcess: widget.posProcess, blocContext: blocContext));
    tabViewList.add(PayCoupon(posProcess: widget.posProcess, blocContext: blocContext));
    tabViewList.add(PayCredit(posProcess: widget.posProcess, blocContext: blocContext));
    return (payProcess)
        ? Container()
        : Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _themeColor, width: 2), // Blue border
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF), // Very light blue background
                borderRadius: BorderRadius.circular(7),
              ),
              child: Column(
                children: [
                  commandWidget(),
                  Expanded(
                    child: DefaultTabController(
                      length: 7,
                      child: Scaffold(
                        backgroundColor: const Color(0xFFF0F5FF),
                        resizeToAvoidBottomInset: false,
                        body: TabBarView(controller: tabBarMenuController, children: tabViewList),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    reCalc();
    return BlocBuilder<PayScreenBloc, PayScreenState>(
      builder: (blocContext, state) {
        if (state is PayScreenRefreshFinish) {
          reCalc();
          Future.delayed(const Duration(milliseconds: 300), () {
            global.sendProcessToCustomerDisplay(mode: global.activeCustomerDisplayScreen);
          });
        }
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: (global.isTabletScreen() || global.isDesktopScreen())
                ? Padding(
                    padding: const EdgeInsets.all(4),
                    child: (payProcess)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Center(child: CircularProgressIndicator()),
                              Center(
                                child: Text(
                                  "Processing...",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: (global.isTabletScreen() || global.isDesktopScreen()) ? 32.0 : 12,
                                    fontWeight: FontWeight.bold,
                                    shadows: [(diffAmount <= 0) ? const Shadow(offset: Offset(1.0, 1.0), blurRadius: 3.0, color: Colors.black) : const Shadow()],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: <Widget>[
                              Expanded(child: payDetailScreen(blocContext)),
                              const SizedBox(width: 2),
                              Expanded(child: paySummeryScreen(docMode: widget.docMode)),
                            ],
                          ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(4),
                    child: (payProcess)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Center(child: CircularProgressIndicator()),
                              Center(
                                child: Text(
                                  "Processing...",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: (global.isTabletScreen() || global.isDesktopScreen()) ? 32.0 : 12,
                                    fontWeight: FontWeight.bold,
                                    shadows: [(diffAmount <= 0) ? const Shadow(offset: Offset(1.0, 1.0), blurRadius: 3.0, color: Colors.black) : const Shadow()],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: <Widget>[
                              Expanded(child: payDetailScreen(blocContext)),
                              const SizedBox(height: 5),
                              paySummeryScreen(docMode: widget.docMode),
                            ],
                          ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _loadCustomerPointBalance() async {
    if (widget.posProcess.customerGuid.isEmpty) {
      setState(() {
        currentPointBalance = 0;
      });
      return;
    }

    try {
      final memberResult = await ApiRepository().findMemberByCode(widget.posProcess.customerCode);

      if (memberResult.code.isNotEmpty) {
        setState(() {
          currentPointBalance = memberResult.pointbalance;
        });
      } else {
        setState(() {
          currentPointBalance = 0;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading customer point balance: $e');
      setState(() {
        currentPointBalance = 0;
      });
    }
  }

  Future<void> _showPointsCodeDialog() async {
    var res = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(global.language('points_code')),
          content: TextFormField(
            controller: pointsCodeTextEditor,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: global.language('enter_points_code'), border: const OutlineInputBorder(), suffixText: global.language('points')),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return global.language('please_enter_points');
              }
              return null;
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(global.language('cancel'))),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(global.language('confirm')),
            ),
          ],
        );
      },
    );
    if (res) {
      setState(() {});
    }
  }

  Future<void> _showUsePointsDialog() async {
    if (widget.posProcess.customerGuid.isEmpty) {
      _showMessageDialog(header: global.language("error"), msg: global.language("no_customer_selected"), type: "error");
      return;
    }

    await _loadCustomerPointBalance();

    if (currentPointBalance <= 0) {
      _showMessageDialog(header: global.language("แจ้งเตือน"), msg: "${global.language("point_balance")}: ${global.moneyFormat.format(currentPointBalance)}", type: "info");
      return;
    }

    final TextEditingController pointsController = TextEditingController();
    double maxPoints = currentPointBalance;
    double totalAmount = widget.posProcess.posProcess.total_amount;
    double maxUsablePoints = maxPoints > totalAmount ? totalAmount : maxPoints;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(global.language('use_points')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${global.language("point_balance")}: ${global.moneyFormat.format(currentPointBalance)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("${global.language("max_usable_points")}: ${global.moneyFormat.format(maxUsablePoints)}", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: global.language('points_to_use'), border: const OutlineInputBorder(), suffixText: global.language('points')),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return global.language('please_enter_points');
                      }
                      double points = double.tryParse(value) ?? 0;
                      if (points < 0) {
                        return global.language('points_must_be_greater_than_zero');
                      }
                      if (points > maxUsablePoints) {
                        return global.language('points_exceed_maximum');
                      }
                      return null;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(global.language('cancel'))),
                ElevatedButton(
                  onPressed: () {
                    double points = double.tryParse(pointsController.text) ?? 0;
                    if (points > -1 && points <= maxUsablePoints) {
                      Navigator.of(context).pop();
                      _usePoints(points);
                    }
                  },
                  child: Text(global.language('confirm')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _usePoints(double points) async {
    try {
      double pointDiscountAmount = 0.0;
      double pointPaymentAmount = 0.0;

      Iterable<ProfileSettingBranchModel> branchModels = global.profileSetting.branch.where((element) => element.guidfixed == global.posConfig.branch.guidfixed);
      ProfileSettingBranchModel branchModel = branchModels.isNotEmpty ? branchModels.first : ProfileSettingBranchModel();

      if (branchModel.pointconfig.generalrules.isNotEmpty) {
        var generalRule = branchModel.pointconfig.generalrules.first;
        double pointValue = points / generalRule.pointvalue;

        // เช็ค pointusagetype
        if (branchModel.pointconfig.pointusagetype == 1) {
          // ใช้เป็นส่วนลด (แบบเดิม)
          pointDiscountAmount = pointValue;
        } else if (branchModel.pointconfig.pointusagetype == 2) {
          // ใช้เป็นการจ่ายชำระเงิน
          pointPaymentAmount = pointValue;
        }
      }

      // Set point values in process
      widget.posProcess.posProcess.usepoint = points;

      // เซ็ตค่าตาม pointusagetype
      if (branchModel.pointconfig.pointusagetype == 1) {
        widget.posProcess.posProcess.pointdiscountamount = pointDiscountAmount;
      } else if (branchModel.pointconfig.pointusagetype == 2) {
        widget.posProcess.posProcess.pointdiscountamount = 0; // ไม่ใช้เป็นส่วนลด
      }

      // Also update the hold process data
      int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
      if (holdIndex != -1) {
        global.posHoldProcessResult[holdIndex].posProcess.usepoint = points;

        if (branchModel.pointconfig.pointusagetype == 1) {
          global.posHoldProcessResult[holdIndex].posProcess.pointdiscountamount = pointDiscountAmount;
        } else if (branchModel.pointconfig.pointusagetype == 2) {
          global.posHoldProcessResult[holdIndex].posProcess.pointdiscountamount = 0;
          global.posHoldProcessResult[holdIndex].payScreenData.point_amount = pointPaymentAmount;
        }
      } // Trigger proper recalculation through posCompileProcess like pos_screen.dart
      await posCompileProcess(holdCode: global.posHoldActiveCode, docMode: widget.docMode, detailDiscountFormula: "", cashRoundAmount: false, discountFoodOnly: global.tempIsRestaurantSystem, customermode: global.secondScreenCommandPay);

      // Also trigger local recalculation
      reCalc();

      setState(() {
        currentPointBalance -= points;
      });

      _showMessageDialog(header: global.language("success"), msg: "${global.language("points_used_successfully")}: ${global.moneyFormat.format(points)}", type: "success");
    } catch (e) {
      AppLogger.error('Error using points: $e');
      _showMessageDialog(header: global.language("error"), msg: global.language("failed_to_use_points"), type: "error");
    }
  }

  void _showMessageDialog({required String header, required String msg, required String type}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        IconData icon;
        Color iconColor;

        switch (type) {
          case "success":
            icon = Icons.check_circle;
            iconColor = Colors.green;
            break;
          case "error":
            icon = Icons.error;
            iconColor = Colors.red;
            break;
          case "info":
          default:
            icon = Icons.info;
            iconColor = Colors.blue;
            break;
        }

        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(header),
            ],
          ),
          content: Text(msg),
          actions: <Widget>[
            TextButton(
              child: Text(global.language('ok')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
