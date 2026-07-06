import 'package:dedecashier/bloc/pay_screen_bloc.dart';
import 'package:dedecashier/db/bank_helper.dart';
import 'package:dedecashier/features/pos/presentation/screens/pay/pay_creditcard_page.dart';
import 'package:dedecashier/model/objectbox/bank_struct.dart';
import 'package:dedecashier/features/pos/presentation/screens/pay/pay_util.dart';
import 'package:dedecashier/widgets/numpad.dart';
import 'package:dedecashier/widgets/numpadtext.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/model/system/pos_pay_model.dart';
import 'package:dedecashier/global_model.dart';
import 'package:network_to_file_image/network_to_file_image.dart';

class PayCreditCard extends StatefulWidget {
  final PosHoldProcessModel posProcess;
  final BuildContext blocContext;

  const PayCreditCard({
    super.key,
    required this.posProcess,
    required this.blocContext,
  });

  @override
  State<PayCreditCard> createState() => _PayCreditCardState();
}

class _PayCreditCardState extends State<PayCreditCard> {
  GlobalKey cardNumberKey = GlobalKey();
  GlobalKey approveNumberKey = GlobalKey();
  GlobalKey amountNumberKey = GlobalKey();
  String bookBankCode = "";
  String bankCode = "";
  String bankName = "";
  String cardNumber = "";
  double cardAmount = 0;
  String approveNumber = "";

  @override
  void initState() {
    super.initState();
    if (global.posConfig.creditcards!.isNotEmpty) {
      bookBankCode = global.posConfig.creditcards![0].bookbank.passbook!;
    }
  }

  void refreshEvent() {
    widget.blocContext.read<PayScreenBloc>().add(PayScreenRefresh());
  }

  bool saveData() {
    if (cardNumber.trim().isNotEmpty && cardAmount > 0) {
      PayCreditCardModel data = PayCreditCardModel(
        book_bank_code: bookBankCode,
        bank_code: bankCode,
        bank_name: bankName,
        card_number: cardNumber,
        approved_code: approveNumber,
        amount: cardAmount,
      );
      global
          .posHoldProcessResult[global.findPosHoldProcessResultIndex(
            global.posHoldActiveCode,
          )]
          .payScreenData
          .credit_card
          .add(data);
      return true;
    } else {
      return false;
    }
  }

  Widget cardDetail() {
    List<BankObjectBoxStruct> bankDataList = BankHelper().selectAll();
    return Card(
      elevation: 3.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        padding: const EdgeInsets.all(5),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var item in global.posConfig.creditcards!)
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: ElevatedButton(
                      onPressed: () {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        bookBankCode = item.bookbank.passbook!;
                        refreshEvent();
                      },
                      child: Column(
                        children: [
                          Container(
                            alignment: Alignment.center,
                            width: 100,
                            height: 50,
                            child: Image(
                              image: NetworkToFileImage(
                                url: global.findBankLogo(
                                  item.bookbank.bankcode!,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            "${global.getNameFromLanguage(item.names!, global.userScreenLanguage)} ",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (global.edcProductName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: ElevatedButton(
                      onPressed: () {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        double amountPay = diffAmount(global.posHoldActiveCode);
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("จำนวนเงินที่ต้องการชำระ"),
                              content: TextField(
                                controller: TextEditingController(
                                  text: amountPay.toString(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    amountPay = double.parse(value);
                                  }
                                },
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    global.playSound(
                                      sound: global.SoundEnum.buttonTing,
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: const Text("ยกเลิก"),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    global.playSound(
                                      sound: global.SoundEnum.paymentSuccess,
                                    );
                                    double payCashAmount = 0;
                                    final res = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PayCreditCardPage(
                                          amount: amountPay,
                                        ),
                                      ),
                                    );
                                    if (res != null) {
                                      if (res == "Failed") {
                                        if (mounted) {
                                          showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text(
                                                  "ชำระเงินไม่สำเร็จ",
                                                ),
                                                content: const Text(
                                                  "ไม่สามารถเชื่อมต่อเครื่อง EDC ได้",
                                                ),
                                                actions: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      global.playSound(
                                                        sound: global
                                                            .SoundEnum
                                                            .buttonTing,
                                                      );
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
                                      if (payCashAmount >= amountPay) {
                                        if (mounted) {
                                          Navigator.pop(context);
                                          refreshEvent();
                                        }
                                      }
                                    }
                                  },
                                  child: const Text("ตกลง"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            alignment: Alignment.center,
                            width: 100,
                            height: 50,
                            child: Image.asset("assets/images/creditcard1.png"),
                          ),
                          Text(
                            "${global.language("pay_by_creditcard")} ",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 90,
                  child: ElevatedButton(
                    onPressed: () {
                      global.playSound(sound: global.SoundEnum.buttonTing);
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: Text(global.language("select_card_type")),
                          content: SizedBox(
                            width: 350,
                            height: 300,
                            child: ListView.builder(
                              itemBuilder: (BuildContext context, int index) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  child: ElevatedButton(
                                    child: Row(
                                      children: [
                                        Container(
                                          alignment: Alignment.center,
                                          width: 100,
                                          height: 50,
                                          child: Image(
                                            image: NetworkToFileImage(
                                              url: global.findBankLogo(
                                                bankDataList[index].code,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(bankDataList[index].names[0]),
                                      ],
                                    ),
                                    onPressed: () {
                                      global.playSound(
                                        sound: global.SoundEnum.buttonTing,
                                      );
                                      bankCode = bankDataList[index].code;
                                      bankName = bankDataList[index].names[0];
                                      Navigator.of(context).pop();
                                      refreshEvent();
                                    },
                                  ),
                                );
                              },
                              itemCount: bankDataList.length,
                            ),
                          ),
                        ),
                      );
                      refreshEvent();
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            width: 100,
                            height: 50,
                            child: (bankCode.isNotEmpty)
                                ? Image(
                                    image: NetworkToFileImage(
                                      url: global.findBankLogo(bankCode),
                                    ),
                                  )
                                : Container(),
                          ),
                        ),
                        Text(
                          (bankName.isNotEmpty)
                              ? bankName
                              : global.language('bank'),
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    key: cardNumberKey,
                    height: 90,
                    child: ElevatedButton(
                      onPressed: () async {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        if (bankCode.isNotEmpty) {
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(global.language('card_number')),
                                content: SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: NumberPadText(
                                    onChange: (value) {
                                      setState(() {
                                        cardNumber = value;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                          refreshEvent();
                        }
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                cardNumber,
                                style: const TextStyle(fontSize: 32),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          Text(
                            global.language('card_number'),
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    key: approveNumberKey,
                    height: 90,
                    child: ElevatedButton(
                      onPressed: () async {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        if (bankCode.isNotEmpty) {
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                  global.language('authorization_code'),
                                ),
                                content: SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: NumberPadText(
                                    onChange: (value) {
                                      setState(() {
                                        approveNumber = value;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                          refreshEvent();
                        }
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                approveNumber,
                                style: const TextStyle(fontSize: 32),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          Text(
                            global.language('authorization_code'),
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    key: amountNumberKey,
                    height: 90,
                    child: ElevatedButton(
                      onPressed: () async {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        if (bankCode.isNotEmpty) {
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(global.language('amount')),
                                content: SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: NumberPad(
                                    onChange: (value) {
                                      setState(() {
                                        cardAmount =
                                            double.tryParse(value) ?? 0;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                          refreshEvent();
                        }
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                cardAmount == 0
                                    ? global.moneyFormat.format(
                                        diffAmount(global.posHoldActiveCode),
                                      )
                                    : global.moneyFormat.format(cardAmount),
                                style: const TextStyle(fontSize: 32),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          Text(
                            global.language('amount'),
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.push_pin),
                    onPressed: () {
                      global.playSound(sound: global.SoundEnum.buttonTing);
                      if (saveData()) {
                        bankCode = "";
                        cardAmount = 0;
                        cardNumber = "";
                        approveNumber = "";
                        refreshEvent();
                      }
                    },
                    label: Text(
                      global.language("credit_card_save"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 8,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget buildCreditCard({required int index}) {
    return Column(
      children: [
        Card(
          elevation: 3.0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: ListTile(
              title: Column(
                children: [
                  // Text(global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.credit_card[index].book_bank_code),
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child:
                            (global
                                    .posHoldProcessResult[global
                                        .findPosHoldProcessResultIndex(
                                          global.posHoldActiveCode,
                                        )]
                                    .payScreenData
                                    .credit_card[index]
                                    .bank_code ==
                                "VISA")
                            ? Image.asset(
                                'assets/images/visa.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : (global
                                      .posHoldProcessResult[global
                                          .findPosHoldProcessResultIndex(
                                            global.posHoldActiveCode,
                                          )]
                                      .payScreenData
                                      .credit_card[index]
                                      .bank_code ==
                                  "MASTER")
                            ? Image.asset(
                                'assets/images/master.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Image(
                                image: NetworkToFileImage(
                                  url: global.findBankLogo(
                                    global
                                        .posHoldProcessResult[global
                                            .findPosHoldProcessResultIndex(
                                              global.posHoldActiveCode,
                                            )]
                                        .payScreenData
                                        .credit_card[index]
                                        .bank_code,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 5),
                      // Text(
                      //   '${global.language('card_number')} : ',
                      //   style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'CourrierPrime'),
                      // ),
                      Text(
                        'XXXXXXXX${global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.credit_card[index].card_number.substring(global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.credit_card[index].card_number.length - 4)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'CourrierPrime',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              subtitle: Container(
                margin: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    buildDetailsBlock(
                      label: global.language('authorization_code'),
                      value: global
                          .posHoldProcessResult[global
                              .findPosHoldProcessResultIndex(
                                global.posHoldActiveCode,
                              )]
                          .payScreenData
                          .credit_card[index]
                          .approved_code,
                    ),
                    buildDetailsBlock(
                      label: global.language('amount'),
                      value: global.moneyFormat.format(
                        global
                            .posHoldProcessResult[global
                                .findPosHoldProcessResultIndex(
                                  global.posHoldActiveCode,
                                )]
                            .payScreenData
                            .credit_card[index]
                            .amount,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete,
                  size: 30.0,
                  color: Colors.redAccent,
                ),
                onPressed: () {
                  global.playSound(sound: global.SoundEnum.itemRemoved);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: Text(
                          global.language("delete_confirm_warning"),
                        ),
                        actions: [
                          TextButton(
                            child: Text(global.language("cancel")),
                            onPressed: () {
                              global.playSound(
                                sound: global.SoundEnum.buttonTing,
                              );
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text(global.language("confirm")),
                            onPressed: () {
                              global.playSound(
                                sound: global.SoundEnum.itemRemoved,
                              );
                              setState(() {
                                Navigator.of(context).pop();
                                global
                                    .posHoldProcessResult[global
                                        .findPosHoldProcessResultIndex(
                                          global.posHoldActiveCode,
                                        )]
                                    .payScreenData
                                    .credit_card
                                    .removeAt(index);
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
          ),
        ),
      ],
    );
  }

  Column buildDetailsBlock({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.green.shade500,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cardAmount == 0) cardAmount = diffAmount(global.posHoldActiveCode);
    return Scaffold(
      backgroundColor: Colors.blue[100],
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            cardDetail(),
            (global
                    .posHoldProcessResult[global.findPosHoldProcessResultIndex(
                      global.posHoldActiveCode,
                    )]
                    .payScreenData
                    .credit_card
                    .isEmpty)
                ? Container()
                : Column(
                    children: <Widget>[
                      ...global
                          .posHoldProcessResult[global
                              .findPosHoldProcessResultIndex(
                                global.posHoldActiveCode,
                              )]
                          .payScreenData
                          .credit_card
                          .map((detail) {
                            var index = global
                                .posHoldProcessResult[global
                                    .findPosHoldProcessResultIndex(
                                      global.posHoldActiveCode,
                                    )]
                                .payScreenData
                                .credit_card
                                .indexOf(detail);
                            return buildCreditCard(index: index);
                          }),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
