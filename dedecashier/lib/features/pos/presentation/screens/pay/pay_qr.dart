import 'package:dedecashier/features/pos/presentation/screens/pay/pay_qr_edc_page.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/bloc/pay_screen_bloc.dart';
import 'package:dedecashier/model/json/customer_display_model.dart';
import 'package:dedecashier/features/pos/presentation/screens/pay/pay_qr_screen.dart';
import 'package:dedecashier/features/pos/presentation/screens/pay/pay_util.dart';
import 'package:dedecashier/widgets/button.dart';
import 'package:dedecashier/widgets/numpad.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/model/system/pos_pay_model.dart';

// ⭐ Theme Colors: MARINEPOS = น้ำเงินเข้ม, อื่นๆ = อิฐบ้านเชียง (Terracotta)
final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF003366) : const Color(0xFFB5651D);

class PayQrWidget extends StatefulWidget {
  final PosHoldProcessModel posProcess;
  final BuildContext blocContext;
  final Function onPaySuccess;

  const PayQrWidget({super.key, required this.posProcess, required this.blocContext, required this.onPaySuccess});

  @override
  PayQrWidgetState createState() => PayQrWidgetState();
}

class PayQrWidgetState extends State<PayQrWidget> {
  final descriptionController = TextEditingController();
  double payAmount = 0;
  GlobalKey widgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  void refreshEvent() {
    widget.blocContext.read<PayScreenBloc>().add(PayScreenRefresh());
  }

  bool savePayData({required String providerCode, required String providerName, required payAmount, required String logo, String transactionId = ""}) {
    if (payAmount > 0) {
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.qr.add(
        PayQrModel(provider_code: providerCode, provider_name: providerName, description: descriptionController.text, amount: payAmount, logo: logo, transactionId: transactionId),
      );
      return true;
    }
    return false;
  }

  Widget formDetail() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(offset: const Offset(0, 4), blurRadius: 8, color: Colors.black.withOpacity(0.1))],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: _themeColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              global.language('qr_code_split'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _themeColor),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: _themeColor, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _themeColor, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelText: global.language('description'),
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      key: widgetKey,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _themeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          global.playSound(sound: global.SoundEnum.buttonTing);
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                title: Text(
                                  global.language('amount'),
                                  style: TextStyle(color: _themeColor, fontWeight: FontWeight.w600),
                                ),
                                content: SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: NumberPad(
                                    onChange: (value) {
                                      setState(() {
                                        payAmount = double.tryParse(value) ?? 0.0;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                          refreshEvent();
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              global.language('amount'),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              global.moneyFormatAndDot.format(payAmount),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: _themeColor, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(offset: const Offset(0, 2), blurRadius: 4, color: Colors.black.withOpacity(0.1))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                      color: _themeColor,
                    ),
                    child: Center(
                      child: Text(
                        '${global.language('wallet_amount')} : ${global.moneyFormatAndDot.format(payAmount)} ${global.language('money_symbol')}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  qrList(payAmount, 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container buildCard({required int index}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _themeColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(offset: const Offset(0, 4), blurRadius: 8, color: Colors.black.withOpacity(0.1))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Provider logo and name
            SizedBox(
              width: 80,
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.qr[index].logo.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.qr[index].logo,
                              height: 48,
                              width: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.qr_code, color: _themeColor, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.qr[index].provider_name,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _themeColor),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildDetailsBlock(
                    label: global.language('qr_description'),
                    value: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.qr[index].description,
                  ),
                  buildDetailsBlock(
                    label: global.language('qr_amount'),
                    value: global.moneyFormatAndDot.format(
                      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.qr[index].amount,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Delete button
            Container(
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: IconButton(
                icon: Icon(Icons.delete_outline, size: 24, color: Colors.red.shade600),
                onPressed: () {
                  global.playSound(sound: global.SoundEnum.itemRemoved);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Text(
                          global.language("delete_confirm"),
                          style: TextStyle(color: _themeColor, fontWeight: FontWeight.w600),
                        ),
                        actions: [
                          TextButton(
                            child: Text(global.language("cancel"), style: TextStyle(color: Colors.grey.shade600)),
                            onPressed: () {
                              global.playSound(sound: global.SoundEnum.buttonTing);
                              Navigator.of(context).pop();
                            },
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(global.language("confirm")),
                            onPressed: () {
                              global.playSound(sound: global.SoundEnum.itemRemoved);
                              setState(() {
                                Navigator.of(context).pop();
                                global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.qr.removeAt(index);
                                refreshEvent();
                              });
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Column buildDetailsBlock({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: _themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(
            value,
            style: TextStyle(color: _themeColor, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void onKeyboardTap(String value) {
    setState(() {});
  }

  void promptPay({required double amount, required ProfileQrPaymentModel provider, required int qrmode}) {
    refreshEvent();
    if (amount != 0.0) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: PayQrScreen(context: context, provider: provider, amount: amount, customerCode: widget.posProcess.customerName, posId: global.posConfig.code),
              );
            },
          );
        },
      ).then((value) {
        if (value is Map && value['success'] == true) {
          String transactionId = value['transactionId'] ?? '';

          if (savePayData(providerCode: provider.qrcode, providerName: provider.qrnames![0].name, payAmount: amount, logo: provider.logo, transactionId: transactionId)) {
            // You might need to update savePayData to accept transactionId
            descriptionController.text = '';
            payAmount = 0.0;
          }
          refreshEvent();
          // กรณีชำระครบให้บันทึกข้อมูลทันที
          if (diffAmount(global.posHoldActiveCode) == 0 && qrmode == 0) {
            widget.onPaySuccess();
          }
        }
        // Handle map return (Navigator.pop(context, {'success': true, 'transactionId': 'TXN1234567890'}))
        else if (value != null) {
          if (qrmode == 0) {}
          // Handle boolean return (Navigator.pop(context, true))
          if (value == true) {
            if (savePayData(providerCode: provider.qrcode, providerName: provider.qrnames![0].name, payAmount: amount, logo: provider.logo)) {
              descriptionController.text = '';
              payAmount = 0.0;
            }
          }

          refreshEvent();
          // กรณีชำระครบให้บันทึกข้อมูลทันที
          if (diffAmount(global.posHoldActiveCode) == 0 && qrmode == 0) {
            widget.onPaySuccess();
          }
        }
        // if (value) {
        //   if (value == true) {
        //     if (savePayData(providerCode: provider.qrcode, providerName: provider.qrnames![0].name, payAmount: amount, logo: provider.logo)) {
        //       descriptionController.text = '';
        //       payAmount = 0.0;
        //     }
        //   }
        //   refreshEvent();
        //   // กรณีชำระครบให้บันทึกข้อมูลทันที
        //   if (diffAmount(global.posHoldActiveCode) == 0 && qrmode == 0) {
        //     widget.onPaySuccess();
        //   }
        // }
        global.customerDisplayQrData = CustomerDisplayQrData(
          ProfileQrPaymentModel(
            guidfixed: '',
            code: '',
            bankcode: '',
            banknames: [],
            bookbankcode: '',
            bookbanknames: [],
            bookbankimages: [],
            isactive: true,
            qrtype: 0,
            qrnames: [],
            qrcode: '',
            logo: '',
            apikey: '',
            accessCode: '',
            bankcharge: '',
            billerCode: '',
            billerID: '',
            closeQr: 0,
            customercharge: '',
            merchantName: '',
            storeID: '',
            terminalID: '',
          ),
          0,
          "",
          "",
          "",
        );
        global.customerDisplayCommand = "";
        global.sendProcessToCustomerDisplay(mode: global.secondScreenCommandPay);
      });
    } else {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Column(
                  children: [
                    Text(global.language('money_amount')),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        Navigator.pop(context);
                      },
                      label: Text(
                        global.language("close"),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }

  Widget qrList(double amount, int qrmode) {
    double iconHeight = 100;
    double iconWidth = 100;

    List<ProfileQrPaymentModel> providerList = [];

    if (qrmode == 0) {
      providerList.addAll(global.posConfig.qrcodes ?? []);
    } else {
      for (var element in global.posConfig.qrcodes!) {
        if (element.qrtype != 301 && element.qrtype != 302) {
          providerList.add(element);
        }
      }
    }
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var provider in providerList)
            (provider.qrtype == 401)
                ? CommandButton(
                    height: iconHeight,
                    width: iconWidth,
                    primaryColor: Colors.white,
                    label:
                        "${global.getNameFromLanguage(provider.qrnames!, global.userScreenLanguage)}\n${global.getNameFromLanguage(provider.bookbanknames!, global.userScreenLanguage)}",
                    imgAssetPath: 'assets/images/TigerHead.png',
                    onPressed: () {
                      global.playSound(sound: global.SoundEnum.qrScanned);
                      promptPay(amount: amount, provider: provider, qrmode: qrmode);
                    },
                  )
                : CommandButton(
                    height: iconHeight,
                    width: iconWidth,
                    primaryColor: Colors.white,
                    label:
                        "${global.getNameFromLanguage(provider.qrnames!, global.userScreenLanguage)}\n${global.getNameFromLanguage(provider.bookbanknames!, global.userScreenLanguage)}",
                    imgNetworkPath: provider.logo,
                    onPressed: () {
                      global.playSound(sound: global.SoundEnum.qrScanned);
                      promptPay(amount: amount, provider: provider, qrmode: qrmode);
                    },
                  ),
          if (global.edcProductName.isNotEmpty)
            CommandButton(
              height: iconHeight,
              width: iconWidth,
              primaryColor: Colors.white,
              label: global.language("edc_qrcode"),
              imgAssetPath: "assets/images/qrpay1.png",
              onPressed: () async {
                global.playSound(sound: global.SoundEnum.qrScanned);
                double payCashAmount = 0;
                final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => PayQREDCPage(amount: amount)));
                if (res != null) {
                  if (res == "Failed") {
                    if (mounted) {
                      showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("ชำระเงินไม่สำเร็จ"),
                            content: const Text("ไม่สามารถเชื่อมต่อเครื่อง EDC ได้"),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  global.playSound(sound: global.SoundEnum.buttonTing);
                                  Navigator.pop(context);
                                },
                                child: const Text("ตกลง"),
                              ),
                            ],
                          );
                        },
                      );
                    }
                    return;
                  }
                  payCashAmount = res;

                  setState(() {});
                  if (payCashAmount >= amount) {
                    if (mounted) {
                      if (savePayData(providerCode: "QR_EDC", providerName: "KBANKEDC", payAmount: amount, logo: "")) {
                        descriptionController.text = '';
                        payAmount = 0.0;
                      }
                      refreshEvent();
                      if (diffAmount(global.posHoldActiveCode) == 0) {
                        widget.onPaySuccess();
                      }
                      global.customerDisplayQrData = CustomerDisplayQrData(
                        ProfileQrPaymentModel(
                          guidfixed: '',
                          code: '',
                          bankcode: '',
                          banknames: [],
                          bookbankcode: '',
                          bookbanknames: [],
                          bookbankimages: [],
                          isactive: true,
                          qrtype: 0,
                          qrnames: [],
                          qrcode: '',
                          logo: '',
                          apikey: '',
                          accessCode: '',
                          bankcharge: '',
                          billerCode: '',
                          billerID: '',
                          closeQr: 0,
                          customercharge: '',
                          merchantName: '',
                          storeID: '',
                          terminalID: '',
                        ),
                        0,
                        "",
                        "",
                        "",
                      );
                      global.customerDisplayCommand = "";
                      global.sendProcessToCustomerDisplay(mode: global.secondScreenCommandPay);
                    }
                  }
                }
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return (global.posConfig.qrcodes!.isNotEmpty)
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Colors.grey.shade50]),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 8),
                    child: (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.qr.isEmpty)
                        ? Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: _themeColor, width: 2),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(offset: const Offset(0, 4), blurRadius: 8, color: Colors.black.withOpacity(0.1))],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: _themeColor,
                                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${global.language("pay_qr_code_full_amount")} : ${global.moneyFormatAndDot.format(diffAmount(global.posHoldActiveCode))} ${global.language("money_symbol")}",
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                qrList(diffAmount(global.posHoldActiveCode), 0),
                              ],
                            ),
                          )
                        : Container(),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      formDetail(),
                      Column(
                        children: <Widget>[
                          ...global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.qr.map((detail) {
                            var index = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.qr.indexOf(detail);
                            return buildCard(index: index);
                          }),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        : Container();
  }
}
