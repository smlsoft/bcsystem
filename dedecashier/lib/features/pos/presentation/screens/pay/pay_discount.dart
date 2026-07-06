import 'package:dedecashier/bloc/pay_screen_bloc.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/util/pos_compile_process.dart';
import 'package:dedecashier/widgets/button.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';

class PayDiscountWidget extends StatefulWidget {
  final PosHoldProcessModel posProcess;
  final BuildContext blocContext;

  const PayDiscountWidget({super.key, required this.posProcess, required this.blocContext});

  @override
  State<PayDiscountWidget> createState() => _PayDiscountWidgetState();
}

class _PayDiscountWidgetState extends State<PayDiscountWidget> {
  String textInputFormula = "";
  final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

  @override
  initState() {
    super.initState();

    textInputFormula = widget.posProcess.posProcess.detail_discount_formula;
  }

  void refreshEvent() async {
    // global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.discount_formula = textInputFormula;
    // global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.discount_amount =
    //     global.calcDiscountFormula(totalAmount: widget.posProcess.posProcess.total_amount, discountText: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.discount_formula);
    // widget.posProcess.payScreenData.discount_formula = textInputFormula;
    // widget.posProcess.payScreenData.discount_amount = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.discount_amount;
    // widget.blocContext.read<PayScreenBloc>().add(PayScreenRefresh());
    global.discountFormular = textInputFormula;
    widget.posProcess.posProcess.detail_discount_formula = textInputFormula;
    await posCompileProcess(
      holdCode: global.posHoldActiveCode,
      docMode: global.posScreenToInt(global.PosScreenModeEnum.posSale),
      detailDiscountFormula: textInputFormula,
      cashRoundAmount: false,
      discountFoodOnly: global.tempIsRestaurantSystem,
      customermode: global.secondScreenCommandPay,
    ).then((value) {
      setState(() {});
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      widget.blocContext.read<PayScreenBloc>().add(PayScreenRefresh());
      setState(() {});
    });
  }

  void textInputAdd(String word) {
    textInputFormula = textInputFormula + word;
    refreshEvent();
  }

  Widget numberPad() {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: NumPadButton(margin: 2, text: '7', callBack: () => {textInputAdd("7")}),
              ),
              Expanded(
                child: NumPadButton(margin: 2, text: '8', callBack: () => {textInputAdd("8")}),
              ),
              Expanded(
                child: NumPadButton(margin: 2, text: '9', callBack: () => {textInputAdd("9")}),
              ),
              Expanded(
                child: NumPadButton(margin: 2, text: '%', callBack: () => {textInputAdd("%")}),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: NumPadButton(margin: 2, text: '4', callBack: () => {textInputAdd("4")}),
              ),
              Expanded(
                child: NumPadButton(margin: 2, text: '5', callBack: () => {textInputAdd("5")}),
              ),
              Expanded(
                child: NumPadButton(margin: 2, text: '6', callBack: () => {textInputAdd("6")}),
              ),
              Expanded(
                child: NumPadButton(margin: 2, text: ',', callBack: () => {textInputAdd(",")}),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: NumPadButton(margin: 2, text: '1', callBack: () => {textInputAdd("1")}),
              ),
              Expanded(
                child: NumPadButton(margin: 2, text: '2', callBack: () => {textInputAdd("2")}),
              ),
              Expanded(
                child: NumPadButton(margin: 2, text: '3', callBack: () => {textInputAdd("3")}),
              ),
              Expanded(
                child: NumPadButton(
                  margin: 2,
                  textAndIconColor: Colors.white,
                  icon: Icons.backspace,
                  color: Colors.red[600],
                  callBack: () {
                    if (textInputFormula.isNotEmpty) {
                      textInputFormula = textInputFormula.substring(0, textInputFormula.length - 1);
                      refreshEvent();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: NumPadButton(margin: 2, text: '0', callBack: () => {textInputAdd("0")}),
              ),
              Expanded(
                child: NumPadButton(margin: 2, text: '.', callBack: () => {if (!textInputFormula.contains('.')) textInputAdd((textInputFormula.isNotEmpty) ? "." : "0.")}),
              ),
              Expanded(
                child: NumPadButton(
                  margin: 2,
                  text: 'C',
                  color: Colors.grey[600],
                  textAndIconColor: Colors.white,
                  callBack: () {
                    textInputFormula = "";

                    refreshEvent();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8, top: 4),
            child: Container(
              height: 120,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(offset: const Offset(0, 2), color: Colors.black.withOpacity(0.1), spreadRadius: 2, blurRadius: 4)],
              ),
              padding: const EdgeInsets.only(right: 15),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        global.language('discount_formula_example'), // สูตรส่วนลด เช่น 5%,10,3%,20 = ลด 5% แล้วลดอีก 10 บาท แล้วลดอีก 3% แล้วลดอีก 20 บาท
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      textInputFormula,
                      style: TextStyle(
                        color: (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : _themeColor,
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(offset: Offset(-1, -1), color: Colors.white),
                          Shadow(offset: Offset(1, -1), color: Colors.white),
                          Shadow(offset: Offset(1, 1), color: Colors.white),
                          Shadow(offset: Offset(-1, 1), color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8, top: 4),
            child: Container(
              height: 120,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(offset: const Offset(0, 2), color: Colors.black.withOpacity(0.1), spreadRadius: 2, blurRadius: 4)],
              ),
              padding: const EdgeInsets.only(right: 15),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(global.language('discount'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      global.moneyFormat.format(global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess.detail_total_discount),
                      style: TextStyle(
                        color: (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : _themeColor,
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(offset: Offset(-1, -1), color: Colors.white),
                          Shadow(offset: Offset(1, -1), color: Colors.white),
                          Shadow(offset: Offset(1, 1), color: Colors.white),
                          Shadow(offset: Offset(-1, 1), color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Padding(padding: const EdgeInsets.only(bottom: 4), child: numberPad()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
