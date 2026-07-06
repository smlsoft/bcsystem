import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dedeorder/bloc/process_bloc.dart';
import 'package:dedeorder/bloc/sml_qr_bloc.dart';
import 'package:dedeorder/model/global_model.dart';
import 'package:dedeorder/model/pos_process_model.dart';
import 'package:dedeorder/model/table_model.dart';
import 'package:dedeorder/table/table_util.dart';
import 'package:dedeorder/utility/botton.dart';
import 'package:dedeorder/utility/kplusshop_payment.dart';
import 'package:dedeorder/utility/promptpay.dart';
import 'package:dedeorder/utility/take_picture_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slider_captcha/slider_captcha.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:dedeorder/utility/api.dart' as api;
import 'package:dedeorder/utility/printer.dart' as printer;

class TableManagerClosePage extends StatefulWidget {
  final TableProcessObjectBoxStruct tableData;

  const TableManagerClosePage({Key? key, required this.tableData}) : super(key: key);

  @override
  _TableManagerClosePageState createState() => _TableManagerClosePageState();
}

class _TableManagerClosePageState extends State<TableManagerClosePage> {
  SliderController sliderController = SliderController();
  String numericPadTextInput = "";
  bool confirm = false;
  bool confirmAmount = false;
  PosProcessModel? processResult;
  String textInputDiscountFormula = "";
  String qrCodePayDataString = "";
  // 0=ชำระที่ Cashier,1=ขำระทันทีด้วยเงินสด,2=ชำระทันทีด้วย Qr Code,3 sml qr
  int payType = 0;

  String imageSlipPath = "";
  bool closeIsProcessing = false;
  bool isProcess = true;
  String transactionId = "";
  late Timer paymentTimer;
  bool paySuccess = false;
  bool isCash = true;
  List<ProfileQrPaymentModel> providerList = [];
  List<ProfileQrPaymentModel> providerQrList = [];
  @override
  void initState() {
    super.initState();
    textInputDiscountFormula = "0";
    reloadData();
    global.getPayTypeEnableConfig();
    Future.delayed(const Duration(seconds: 1), () {
      refresh();
    });
    updateOrderOnLineStatus(1);
    global.speak("ปิดโต๊ะ ${widget.tableData.number}");
  }

  void reloadData() {
    context.read<SmlQrBloc>().add(SmlQrGetData());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> updateOrderOnLineStatus(int orderStatus) async {
    String query = "alter table dedeorderonline.tableinfo update orderonlinestatus=$orderStatus where tablenumber='${widget.tableData.number}' and shopid='${global.posInformation.shop_id}'";
    await api.clickHouseExecute(query);
    // ลบ Order Online ที่ค้างอยู่
    query = "alter table dedeorderonline.ordertemp delete where orderid='${widget.tableData.number}' and shopid='${global.posInformation.shop_id}'";
    await api.clickHouseExecute(query);
  }

  void refresh() {
    context.read<ProcessBloc>().add(ProcessGetData(holdId: "T-${widget.tableData.number}", discountWord: textInputDiscountFormula, isCash: isCash));
  }

  void textInputDiscountFormulaAdd(String word) {
    textInputDiscountFormula = textInputDiscountFormula + word;
  }

  void checkConfirmAmount() {
    double payAmount = double.tryParse(numericPadTextInput) ?? 0;
    if (payAmount >= processResult!.total_amount_pay) {
      confirmAmount = true;
    } else {
      confirmAmount = false;
    }
  }

  void numericPadTextInputAdd(String word) {
    numericPadTextInput = numericPadTextInput + word;
    checkConfirmAmount();
    setState(() {});
  }

  Widget moneyButton(double value) {
    String imageName = 'assets/moneys/moneythai${value.toInt()}.gif';
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          double total = double.tryParse(numericPadTextInput) ?? 0;
          total = total + value;
          numericPadTextInput = "";
          numericPadTextInputAdd(total.toString());
        },
        child: Image.asset(imageName));
  }

  Widget numericPadWidget() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey, width: 1),
                bottom: BorderSide(color: Colors.grey, width: 1),
                left: BorderSide(color: Colors.grey, width: 1),
                right: BorderSide(color: Colors.grey, width: 1),
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(5),
              ),
            ),
            padding: const EdgeInsets.all(5),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(numericPadTextInput, style: const TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
              child: Row(
            children: [
              moneyButton(1000),
              SizedBox(width: 10),
              moneyButton(500),
              SizedBox(width: 10),
              moneyButton(100),
              SizedBox(width: 10),
              moneyButton(50),
              SizedBox(width: 10),
              moneyButton(20),
            ],
          )),
          const SizedBox(height: 10),
          SizedBox(
            height: 240,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: NumPadButton(
                              margin: 2,
                              text: '7',
                              callBack: () => {numericPadTextInputAdd("7")},
                            ),
                          ),
                          Expanded(
                              flex: 2,
                              child: NumPadButton(
                                margin: 2,
                                text: '8',
                                callBack: () => {numericPadTextInputAdd("8")},
                              )),
                          Expanded(
                              flex: 2,
                              child: NumPadButton(
                                margin: 2,
                                text: '9',
                                callBack: () => {numericPadTextInputAdd("9")},
                              )),
                        ]),
                      ),
                      Expanded(
                          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                        Expanded(
                            flex: 2,
                            child: NumPadButton(
                              margin: 2,
                              text: '4',
                              callBack: () => {numericPadTextInputAdd("4")},
                            )),
                        Expanded(
                            flex: 2,
                            child: NumPadButton(
                              margin: 2,
                              text: '5',
                              callBack: () => {numericPadTextInputAdd("5")},
                            )),
                        Expanded(
                            flex: 2,
                            child: NumPadButton(
                              margin: 2,
                              text: '6',
                              callBack: () => {numericPadTextInputAdd("6")},
                            )),
                      ])),
                      Expanded(
                          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                        Expanded(
                            flex: 2,
                            child: NumPadButton(
                              margin: 2,
                              text: '1',
                              callBack: () => {numericPadTextInputAdd("1")},
                            )),
                        Expanded(
                            flex: 2,
                            child: NumPadButton(
                              margin: 2,
                              text: '2',
                              callBack: () => {numericPadTextInputAdd("2")},
                            )),
                        Expanded(
                            flex: 2,
                            child: NumPadButton(
                              margin: 2,
                              text: '3',
                              callBack: () => {numericPadTextInputAdd("3")},
                            )),
                      ])),
                      Expanded(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                          Expanded(
                              flex: 2,
                              child: NumPadButton(
                                margin: 2,
                                text: '.',
                                callBack: () => {numericPadTextInputAdd(".")},
                              )),
                          Expanded(
                              flex: 2,
                              child: NumPadButton(
                                margin: 2,
                                text: '0',
                                callBack: () => {numericPadTextInputAdd("0")},
                              )),
                          Expanded(
                              flex: 2,
                              child: NumPadButton(
                                margin: 2,
                                icon: Icons.backspace,
                                textAndIconColor: Colors.black,
                                callBack: () {
                                  if (numericPadTextInput.isNotEmpty) {
                                    setState(() {
                                      numericPadTextInput = numericPadTextInput.substring(0, numericPadTextInput.length - 1);
                                    });
                                  }
                                  checkConfirmAmount();
                                },
                              )),
                        ]),
                      ),
                      Expanded(
                          child: SizedBox(
                              width: double.infinity,
                              child: NumPadButton(
                                margin: 2,
                                text: 'C',
                                color: Colors.red[200],
                                callBack: () {
                                  setState(() {
                                    numericPadTextInput = "";
                                  });
                                  checkConfirmAmount();
                                },
                              ))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> previewList = [];
    if (processResult != null) {
      previewList.add(Container(
          width: double.infinity,
          margin: const EdgeInsets.all(10),
          child: ElevatedButton(
              onPressed: ((widget.tableData.order_count == 0))
                  ? null
                  : () async {
                      textInputDiscountFormula = textInputDiscountFormula.replaceAll("%", "");
                      double persent = double.tryParse(textInputDiscountFormula) ?? 0;
                      textInputDiscountFormula = (persent == 0) ? "" : global.moneyFormat.format(persent);
                      await showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, StateSetter setState) {
                                return AlertDialog(
                                    title: Text(
                                      'ส่วนลดเฉพาะอาหาร',
                                      style: TextStyle(fontSize: global.orderFontSize, fontWeight: FontWeight.bold),
                                    ),
                                    content: Column(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(2),
                                            border: Border.all(color: Colors.grey.shade400, width: 1),
                                          ),
                                          margin: const EdgeInsets.all(10),
                                          padding: const EdgeInsets.all(10),
                                          child: Text(
                                            (textInputDiscountFormula.isEmpty) ? "กรุณาใส่ส่วนลด" : textInputDiscountFormula,
                                            style: TextStyle(fontSize: global.orderFontSize),
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: <Widget>[
                                              Expanded(
                                                  child: NumPadButton(
                                                margin: 2,
                                                text: '7',
                                                callBack: () {
                                                  setState(() {
                                                    textInputDiscountFormulaAdd("7");
                                                  });
                                                },
                                              )),
                                              Expanded(
                                                  child: NumPadButton(
                                                margin: 2,
                                                text: '8',
                                                callBack: () {
                                                  setState(() {
                                                    textInputDiscountFormulaAdd("8");
                                                  });
                                                },
                                              )),
                                              Expanded(
                                                  child: NumPadButton(
                                                margin: 2,
                                                text: '9',
                                                callBack: () {
                                                  setState(() {
                                                    textInputDiscountFormulaAdd("9");
                                                  });
                                                },
                                              )),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: <Widget>[
                                              Expanded(
                                                  child: NumPadButton(
                                                margin: 2,
                                                text: '4',
                                                callBack: () {
                                                  setState(() {
                                                    textInputDiscountFormulaAdd("4");
                                                  });
                                                },
                                              )),
                                              Expanded(
                                                  child: NumPadButton(
                                                margin: 2,
                                                text: '5',
                                                callBack: () {
                                                  setState(() {
                                                    textInputDiscountFormulaAdd("5");
                                                  });
                                                },
                                              )),
                                              Expanded(
                                                  child: NumPadButton(
                                                margin: 2,
                                                text: '6',
                                                callBack: () {
                                                  setState(() {
                                                    textInputDiscountFormulaAdd("6");
                                                  });
                                                },
                                              )),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: <Widget>[
                                              Expanded(
                                                  child: NumPadButton(
                                                margin: 2,
                                                text: '1',
                                                callBack: () {
                                                  setState(() {
                                                    textInputDiscountFormulaAdd("1");
                                                  });
                                                },
                                              )),
                                              Expanded(
                                                  child: NumPadButton(
                                                margin: 2,
                                                text: '2',
                                                callBack: () {
                                                  setState(() {
                                                    textInputDiscountFormulaAdd("2");
                                                  });
                                                },
                                              )),
                                              Expanded(
                                                  child: NumPadButton(
                                                margin: 2,
                                                text: '3',
                                                callBack: () {
                                                  setState(() {
                                                    textInputDiscountFormulaAdd("3");
                                                  });
                                                },
                                              )),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: <Widget>[
                                              Expanded(
                                                  child: NumPadButton(
                                                margin: 2,
                                                text: '0',
                                                callBack: () {
                                                  setState(() {
                                                    textInputDiscountFormulaAdd("0");
                                                  });
                                                },
                                              )),
                                              Expanded(
                                                  child: NumPadButton(
                                                margin: 2,
                                                text: '.',
                                                callBack: () {
                                                  setState(() {
                                                    if (!textInputDiscountFormula.contains('.')) {
                                                      textInputDiscountFormulaAdd((textInputDiscountFormula.isNotEmpty) ? "." : "0.");
                                                    }
                                                  });
                                                },
                                              )),
                                              Expanded(
                                                  child: NumPadButton(
                                                margin: 2,
                                                textAndIconColor: Colors.black,
                                                icon: Icons.backspace,
                                                color: Colors.red.shade200,
                                                callBack: () {
                                                  setState(() {
                                                    if (textInputDiscountFormula.isNotEmpty) {
                                                      textInputDiscountFormula = textInputDiscountFormula.substring(0, textInputDiscountFormula.length - 1);
                                                    }
                                                  });
                                                },
                                              )),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                            child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: NumPadButton(
                                                margin: 2,
                                                text: 'C',
                                                color: Colors.red.shade400,
                                                callBack: () {
                                                  setState(() {
                                                    textInputDiscountFormula = "";
                                                  });
                                                },
                                              ),
                                            ),
                                            Expanded(
                                              child: NumPadButton(
                                                margin: 2,
                                                text: 'OK',
                                                color: Colors.blue.shade400,
                                                callBack: () {
                                                  textInputDiscountFormula = textInputDiscountFormula.replaceAll("%", "");
                                                  Navigator.pop(context);
                                                  double persent = double.tryParse(textInputDiscountFormula) ?? 0;
                                                  if (persent > 30) {
                                                    persent = 0;
                                                  }
                                                  textInputDiscountFormula = "${persent.toString()}%";
                                                },
                                              ),
                                            ),
                                          ],
                                        ))
                                      ],
                                    ));
                              },
                            );
                          });
                      refresh();
                    },
              child: Text((textInputDiscountFormula.isEmpty) ? "ส่วนลดเฉพาะอาหาร" : "ส่วนลดเฉพาะอาหาร : $textInputDiscountFormula", style: TextStyle(fontSize: global.orderFontSize)))));
      previewList.add(tableProcessWidget(processResult!));
      if (1 == 1) {
        // รับชำระด้วยเงินสด หรือ Qr Code
        previewList.add(Container(
            width: double.infinity,
            margin: const EdgeInsets.all(10),
            child: Row(
              children: [
                if (global.payTypeEnableList[0])
                  Expanded(
                      child: Container(
                    margin: const EdgeInsets.all(1),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (payType == 0) ? Colors.green.shade500 : Colors.grey.shade400,
                        ),
                        onPressed: (global.payTypeEnableList[0] == false)
                            ? null
                            : () {
                                setState(() {
                                  if (qrCodePayDataString.isNotEmpty) {
                                    try {
                                      if (paymentTimer.isActive) {
                                        paymentTimer.cancel();
                                      }
                                    } catch (e) {
                                      // Timer not initialized yet
                                    }
                                  }
                                  Future.delayed(const Duration(milliseconds: 500), () {
                                    qrCodePayDataString = "";
                                    payType = 0;
                                    isCash = true;
                                    confirm = false; // Reset confirm when changing payType
                                    isProcess = true; // Reset isProcess
                                    paySuccess = false; // Reset paySuccess
                                    transactionId = ""; // Reset transactionId

                                    refresh();
                                    sliderController.create();
                                  });
                                });
                              },
                        child: Column(children: [
                          Icon(
                            (payType == 0) ? Icons.check_circle : null,
                            color: Colors.white,
                          ),
                          Text((widget.tableData.order_count == 0) ? "ปิดโต๊ะ" : "ชำระที่ Cashier", style: TextStyle(fontSize: global.orderFontSize))
                        ])),
                  )),
                // if (global.payTypeEnableList[1])
                //   Expanded(
                //       child: Container(
                //     margin: const EdgeInsets.all(1),
                //     child: ElevatedButton(
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: (payType == 1) ? Colors.green.shade500 : Colors.grey.shade400,
                //         ),
                //         onPressed: (global.payTypeEnableList[1] == false)
                //             ? null
                //             : () {
                //                 setState(() {
                //                   payType = 1;
                //                   isCash = true;
                //                   refresh();
                //                 });
                //               },
                //         child: Column(children: [
                //           Icon(
                //             (payType == 1) ? Icons.check_circle : null,
                //             color: Colors.white,
                //           ),
                //           Text("ชำระด้วยเงินสด", style: TextStyle(fontSize: global.orderFontSize))
                //         ])),
                //   )),
                // if (global.payTypeEnableList[2])
                //   Expanded(
                //       child: Container(
                //     margin: const EdgeInsets.all(1),
                //     child: ElevatedButton(
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: (payType == 2) ? Colors.green.shade500 : Colors.grey.shade400,
                //         ),
                //         onPressed: (global.payTypeEnableList[2] == false)
                //             ? null
                //             : () {
                //                 setState(() {
                //                   payType = 2;
                //                 });
                //               },
                //         child: Column(children: [
                //           Icon(
                //             (payType == 2) ? Icons.check_circle : null,
                //             color: Colors.white,
                //           ),
                //           Text("ชำระด้วย QrCode", style: TextStyle(fontSize: global.orderFontSize))
                //         ])),
                //   )),

                // Expanded(
                //     child: Container(
                //   margin: const EdgeInsets.all(1),
                //   child: ElevatedButton(
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: (payType == 3) ? Colors.green.shade500 : Colors.grey.shade400,
                //       ),
                //       onPressed: (global.payTypeEnableList[3] == false)
                //           ? null
                //           : () {
                //               setState(() {
                //                 payType = 3;
                //               });
                //             },
                //       child: Column(children: [
                //         Icon(
                //           (payType == 3) ? Icons.check_circle : null,
                //           color: Colors.white,
                //         ),
                //         Text("ชำระด้วย SML QR", style: TextStyle(fontSize: global.orderFontSize))
                //       ])),
                // )),
              ],
            )));

        if (global.payTypeEnableList[2]) {
          previewList.add(Container(
              width: double.infinity,
              margin: const EdgeInsets.all(10),
              child: Row(
                children: [
                  for (var value in providerQrList)
                    Expanded(
                        child: Container(
                      margin: const EdgeInsets.all(1),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (payType == 2 && (global.payQrCode == value.qrcode || global.payQrCode == value.billerID)) ? Colors.green.shade500 : Colors.grey.shade400,
                          ),
                          onPressed: (global.payTypeEnableList[2] == false)
                              ? null
                              : () {
                                  setState(() {
                                    payType = 2;
                                    qrCodePayDataString = "";
                                    global.payQrCodeName = value.bookbanknames![0].name;
                                    if (value.qrtype == 100) {
                                      global.payQrCode = value.qrcode;
                                    } else if (value.qrtype == 101) {
                                      global.payQrCode = value.billerID!;
                                    }
                                    global.qrproviderCode = value.code;
                                    global.qrproviderName = value.qrnames![0].name;
                                    isCash = false;
                                    confirm = false; // Reset confirm when changing payType
                                    sliderController.create(); // Reset slider
                                    global.payQrType = value.qrtype;
                                    try {
                                      if (paymentTimer.isActive) {
                                        paymentTimer.cancel();
                                      }
                                    } catch (e) {
                                      // Timer not initialized yet
                                    }
                                    refresh();
                                  });
                                },
                          child: Column(children: [
                            Icon(
                              (payType == 2 && (global.payQrCode == value.qrcode || global.payQrCode == value.billerID)) ? Icons.check_circle : null,
                              color: Colors.white,
                            ),
                            Text((value.qrtype == 101) ? "KPlus \n${value.bankcode}~${value.bookbankcode}" : "PromptPay \n${value.bankcode}~${value.bookbankcode}", style: TextStyle(fontSize: global.orderFontSize))
                          ])),
                    )),
                ],
              )));
        }

        if (global.payTypeEnableList[3]) {
          previewList.add(Container(
              width: double.infinity,
              margin: const EdgeInsets.all(10),
              child: Row(
                children: [
                  for (var value in providerList)
                    Expanded(
                        child: Container(
                      margin: const EdgeInsets.all(1),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (payType == 3 && global.smlQrCode == value.apikey) ? Colors.green.shade500 : Colors.grey.shade400,
                          ),
                          onPressed: (global.payTypeEnableList[3] == false)
                              ? null
                              : () {
                                  if (qrCodePayDataString.isNotEmpty) {
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("แจ้งเตือน"),
                                            content: const Text("ต้องการสร้าง Qr Code ใหม่หรือไม่"),
                                            actions: [
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text("ยกเลิก")),
                                              TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      paymentTimer.cancel();
                                                      qrCodePayDataString = "";
                                                      global.smlQrCode = value.apikey!;
                                                      global.payQrCodeName = value.bookbanknames![0].name;
                                                      confirm = false;
                                                      isCash = false;
                                                      isProcess = true;
                                                      refresh();
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text("ตกลง"))
                                            ],
                                          );
                                        });
                                  } else {
                                    setState(() {
                                      payType = 3;
                                      qrCodePayDataString = "";
                                      global.smlQrCode = value.apikey!;
                                      global.payQrCodeName = value.bookbanknames![0].name;
                                      global.qrproviderCode = value.code;
                                      global.qrproviderName = value.qrnames![0].name;
                                      isCash = false;
                                      confirm = false;
                                      isProcess = true;
                                      refresh();
                                    });
                                  }
                                },
                          child: Column(children: [
                            Icon(
                              (payType == 3 && global.smlQrCode == value.apikey) ? Icons.check_circle : null,
                              color: Colors.white,
                            ),
                            Text("SML QR Code \n${value.bankcode}~${value.bookbankcode}", style: TextStyle(fontSize: global.orderFontSize))
                          ])),
                    )),
                ],
              )));
        }
        previewList.add(Text(
          "ยอดชำระ : ${global.moneyFormatAndDot.format(processResult!.total_amount_pay)} บาท",
          style: TextStyle(fontSize: global.orderFontSize * 1.5, fontWeight: FontWeight.bold),
        ));
        if (payType == 1) {
          previewList.add(numericPadWidget());
        }
        if (payType == 2) {
          // fix kPlus payment here
          if (global.payQrType == 100) {
            previewList.add(QrImageView(
              data: PromptPay.generateQRData(global.payQrCode, amount: processResult!.total_amount_pay.toDouble()),
              version: QrVersions.auto,
              size: 200.0,
            ));
          } else if (global.payQrType == 101) {
            previewList.add(QrImageView(
              data: KplusPayment.generateQRData(global.payQrCode, amount: processResult!.total_amount_pay.toDouble()),
              version: QrVersions.auto,
              size: 200.0,
            ));
          }

          /*previewList.add(QrImageView(
            data: PromptPay.generateQRData(global.payQrCode,
                amount: processResult!.total_amount_pay.toDouble()),
            version: QrVersions.auto,
            size: 200.0,
          ));*/

          if (global.payQrType == 100) {
            previewList.add(Text("KPlus : ${global.payQrCodeName}"));
          } else if (global.payQrType == 101) {
            previewList.add(Text("PromptPay : ${global.payQrCodeName}"));
          }

          if (global.cameras.isNotEmpty) {
            previewList.add(Container(
                width: double.infinity,
                margin: const EdgeInsets.all(10),
                child: ElevatedButton(
                    onPressed: () async {
                      var result = await Navigator.push(context, MaterialPageRoute(builder: (context) => TakePictureScreen(camera: global.cameras[0])));
                      if (result != null) {
                        imageSlipPath = result;
                        setState(() {});
                      }
                    },
                    child: const Text("ถ่ายรูป Slip การชำระเงิน"))));
            if (imageSlipPath.isNotEmpty) {
              previewList.add(Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(0, 1), // changes position of shadow
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Image.file(
                    File(imageSlipPath),
                    width: 400,
                  )));
            }
          }
        }
        if (payType == 3) {
          // fix kPlus payment here
          if (qrCodePayDataString.isEmpty && isProcess == false) {
            isCash = false;
            api.getSMLQrPay(global.smlQrCode, processResult!.total_amount_pay.toDouble()).then((value) async {
              if (value != null) {
                var json = jsonDecode(value);
                if (json['qrCodePayDataString'].isNotEmpty) {
                  transactionId = json['transactionId'];
                  qrCodePayDataString = await json['qrCodePayDataString'];

                  paymentTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
                    if (transactionId.isNotEmpty && paySuccess == false) {
                      await api.getSMLQrPayCheckPay(global.smlQrCode, transactionId).then((value) async {
                        if (value != null) {
                          var json = jsonDecode(value);
                          if (json['status'] == "success") {
                            paySuccess = true;
                            paymentTimer?.cancel();
                            confirm = true;
                            setState(() {});
                            //dialogShow"ชำระเงินสำเร็จ"
                            if (mounted) {
                              await showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("ชำระเงินสำเร็จ"),
                                      content: const Text("ชำระเงินสำเร็จ"),
                                      actions: [
                                        ElevatedButton(
                                            onPressed: () async {
                                              if ((confirm && !closeIsProcessing && (confirmAmount || payType != 1))) {
                                                setState(() {
                                                  closeIsProcessing = true;
                                                });
                                                widget.tableData.table_status = 3;

                                                double payAmount = double.tryParse(numericPadTextInput) ?? 0;
                                                String docNumber = await api.closeTableToTerminal(
                                                  context: context,
                                                  table: widget.tableData,
                                                  payMode: payType,
                                                  payAmount: payAmount,
                                                  discountFormula: textInputDiscountFormula,
                                                  slipImagePath: imageSlipPath,
                                                  process: processResult!,
                                                  transactionId: transactionId,
                                                  payqrcodename: global.payQrCodeName,
                                                  providerCode: global.qrproviderCode,
                                                  providerName: global.qrproviderName,
                                                );
                                                if (global.printToLocalPrinter && docNumber.isNotEmpty) {}
                                                if (mounted) {
                                                  Navigator.pop(context);
                                                  Navigator.pop(context);
                                                  Navigator.pop(context);
                                                }
                                              }
                                            },
                                            child: const Text("ปิดโต๊ะ", style: TextStyle(fontSize: 16))),
                                      ],
                                    );
                                  });
                            }
                          }
                        }
                      });
                      setState(() {});
                    }
                  });
                }
              }
            });
          } else if (isProcess == false) {
            previewList.add(QrImageView(
              data: qrCodePayDataString,
              version: QrVersions.auto,
              size: 200.0,
            ));

            previewList.add(Text("SML Qr : ${global.payQrCodeName}"));
            setState(() {});
          }
          /*previewList.add(QrImageView(
            data: PromptPay.generateQRData(global.payQrCode,
                amount: processResult!.total_amount_pay.toDouble()),
            version: QrVersions.auto,
            size: 200.0,
          ));*/
        }
      }
      if (payType != 3) {
        previewList.add(Padding(
          padding: const EdgeInsets.all(10.0),
          child: SliderCaptcha(
            controller: sliderController,
            image: Image.asset(
              'assets/images/captcha.png',
              fit: BoxFit.fitWidth,
            ),
            colorBar: Colors.blue,
            colorCaptChar: Colors.blue,
            onConfirm: (value) => Future.delayed(const Duration(seconds: 1)).then(
              (_) {
                if (value == false) {
                  sliderController.create();
                } else {
                  setState(() {
                    confirm = true;
                  });
                }
              },
            ),
          ),
        ));
      }
      previewList.add(const SizedBox(height: 10));
      previewList.add(Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 45,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () {
                    updateOrderOnLineStatus(0);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "ยกเลิก",
                    style: TextStyle(fontSize: 16),
                  )),
            ),
            const Spacer(),
            if (payType != 3)
              SizedBox(
                width: 100,
                height: 45,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade500,
                    ),
                    onPressed: (confirm && !closeIsProcessing && (confirmAmount || payType != 1))
                        ? () async {
                            setState(() {
                              closeIsProcessing = true;
                            });
                            widget.tableData.table_status = 2;
                            double payAmount = double.tryParse(numericPadTextInput) ?? 0;
                            String docNumber = await api.closeTableToTerminal(
                              context: context,
                              table: widget.tableData,
                              payMode: payType,
                              payAmount: payAmount,
                              discountFormula: textInputDiscountFormula,
                              slipImagePath: imageSlipPath,
                              process: processResult!,
                              providerCode: global.qrproviderCode,
                              providerName: global.qrproviderName,
                              payqrcodename: global.payQrCodeName,
                            );
                            if (global.printToLocalPrinter && docNumber.isNotEmpty) {
                              /*if (mounted) {
                                await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("พิมพ์ใบเสร็จ"),
                                        content: const Text(
                                            "ต้องการพิมพ์ใบเสร็จหรือไม่"),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text("ไม่พิมพ์")),
                                          TextButton(
                                              onPressed: () async {
                                                printer
                                                    .printerImageToLocalPrinter(
                                                        docNumber);
                                                if (mounted) {
                                                  Navigator.pop(context);
                                                }
                                              },
                                              child: const Text("พิมพ์"))
                                        ],
                                      );
                                    });
                              }*/
                            }
                            if (mounted) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                          }
                        : null,
                    child: const Text(
                      "ปิดโต๊ะ",
                      style: TextStyle(fontSize: 16),
                    )),
              )
          ],
        ),
      ));
    }

    return MultiBlocListener(
        listeners: [
          BlocListener<ProcessBloc, ProcessState>(
            listener: (context, state) {
              if (state is ProcessGetDataSuccess) {
                processResult = state.result;
                isProcess = false;
                context.read<ProcessBloc>().add(ProcessGetDataFinish());
                setState(() {});
              }
            },
          ),
          BlocListener<SmlQrBloc, SmlQrState>(
            listener: (context, state) {
              if (state is SmlQrGetDataSuccess) {
                if (state.result.isNotEmpty) {
                  state.result.forEach((element) {
                    if (element.qrtype == 301) {
                      providerList.add(element);
                    } else if (element.qrtype == 100 || element.qrtype == 101) {
                      providerQrList.add(element);
                    }
                  });
                }
              }
            },
          ),
        ],
        child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.deepPurple.shade900,
              title: Text("ปิดโต๊ะ ${widget.tableData.number}"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  textInputDiscountFormula = "0";
                  updateOrderOnLineStatus(0);
                  Navigator.pop(context);
                },
              ),
              actions: [
                IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: (widget.tableData.order_count == 0)
                        ? null
                        : () {
                            printer.printTableSummery(table: widget.tableData, processResult: processResult!);
                          }),
              ],
            ),
            body: (isProcess) ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: previewList))));
  }
}
