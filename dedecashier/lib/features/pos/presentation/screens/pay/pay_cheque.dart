import 'package:dedecashier/bloc/pay_screen_bloc.dart';
import 'package:dedecashier/db/bank_helper.dart';
import 'package:dedecashier/model/objectbox/bank_struct.dart';
import 'package:dedecashier/features/pos/presentation/screens/pay/pay_util.dart';
import 'package:dedecashier/widgets/numpad.dart';
import 'package:dedecashier/widgets/numpadtext.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:dedecashier/model/system/pos_pay_model.dart';
import 'package:dedecashier/global_model.dart';
import 'package:network_to_file_image/network_to_file_image.dart';

class PayCheque extends StatefulWidget {
  final PosHoldProcessModel posProcess;
  final BuildContext blocContext;
  const PayCheque({
    super.key,
    required this.posProcess,
    required this.blocContext,
  });

  @override
  State<PayCheque> createState() => _PayChequeState();
}

class _PayChequeState extends State<PayCheque> {
  GlobalKey chequeNumberKey = GlobalKey();
  GlobalKey branchNumberKey = GlobalKey();
  GlobalKey amountNumberKey = GlobalKey();
  GlobalKey dueDateKey = GlobalKey();
  String bankCode = "";
  String bankName = "";
  String chequeNumber = "";
  double chequeAmount = 0;
  String branchNumber = "";
  DateTime dueDate = DateTime.now();
  int buttonIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void refreshEvent() {
    widget.blocContext.read<PayScreenBloc>().add(PayScreenRefresh());
  }

  bool saveData() {
    if (chequeNumber.trim().isNotEmpty && chequeAmount > 0) {
      global
          .posHoldProcessResult[global.findPosHoldProcessResultIndex(
            global.posHoldActiveCode,
          )]
          .payScreenData
          .cheque
          .add(
            PayChequeModel(
              due_date: DateTime.now(),
              bank_code: bankCode,
              bank_name: bankName,
              cheque_number: chequeNumber,
              branch_number: branchNumber,
              amount: chequeAmount,
            ),
          );
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
                          title: Text(global.language("please_select_bank")),
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
                                              url: bankDataList[index].logo,
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
                              : global.language("bank_name"),
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
                    key: chequeNumberKey,
                    height: 90,
                    child: ElevatedButton(
                      onPressed: () async {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        if (bankCode.isNotEmpty) {
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(global.language('cheque_number')),
                                content: SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: NumberPadText(
                                    onChange: (value) {
                                      setState(() {
                                        chequeNumber = value;
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
                                chequeNumber,
                                style: const TextStyle(fontSize: 32),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          Text(
                            global.language('cheque_number'),
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
                    key: branchNumberKey,
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
                                  global.language('chq_branch_number'),
                                ),
                                content: SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: NumberPadText(
                                    onChange: (value) {
                                      setState(() {
                                        branchNumber = value;
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
                                branchNumber,
                                style: const TextStyle(fontSize: 32),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          Text(
                            global.language('chq_branch_number'),
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
                    key: dueDateKey,
                    height: 90,
                    child: ElevatedButton(
                      onPressed: () async {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        if (bankCode.isNotEmpty) {
                          DateTime? newDateTime = await showRoundedDatePicker(
                            height: 300,
                            context: context,
                            locale: const Locale("th", "TH"),
                            era: EraMode.BUDDHIST_YEAR,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(DateTime.now().year - 10),
                            lastDate: DateTime(DateTime.now().year + 10),
                            borderRadius: 16,
                          );
                          dueDate = newDateTime ?? DateTime.now();
                          refreshEvent();
                        }
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: FittedBox(
                                child: Text(
                                  global.dateTimeFormatFull(dueDate),
                                  style: const TextStyle(fontSize: 32),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            global.language('due_date'),
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
                                        chequeAmount =
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
                                global.moneyFormat.format(chequeAmount),
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
                        chequeAmount = 0;
                        chequeNumber = "";
                        branchNumber = "";
                        refreshEvent();
                      }
                    },
                    label: Text(
                      global.language("cheque_save"),
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
              title: Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 50,
                    child: Image(
                      image: NetworkImage(
                        global.findBankLogo(
                          global
                              .posHoldProcessResult[global
                                  .findPosHoldProcessResultIndex(
                                    global.posHoldActiveCode,
                                  )]
                              .payScreenData
                              .cheque[index]
                              .bank_code,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  buildDetailsBlock(
                    label: global.language("cheque_number"),
                    value: global
                        .posHoldProcessResult[global
                            .findPosHoldProcessResultIndex(
                              global.posHoldActiveCode,
                            )]
                        .payScreenData
                        .cheque[index]
                        .cheque_number,
                  ),
                  const SizedBox(width: 50),
                  buildDetailsBlock(
                    label: global.language("bank_branch_number"),
                    value: global
                        .posHoldProcessResult[global
                            .findPosHoldProcessResultIndex(
                              global.posHoldActiveCode,
                            )]
                        .payScreenData
                        .cheque[index]
                        .branch_number,
                  ),
                ],
              ),
              subtitle: Container(
                margin: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    buildDetailsBlock(
                      label: global.language('due_date'),
                      value: global.dateTimeFormatFull(
                        global
                            .posHoldProcessResult[global
                                .findPosHoldProcessResultIndex(
                                  global.posHoldActiveCode,
                                )]
                            .payScreenData
                            .cheque[index]
                            .due_date,
                      ),
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
                            .cheque[index]
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
                        content: Text(global.language("delete_confirm")),
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
                                    .cheque
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
    if (chequeAmount == 0) chequeAmount = diffAmount(global.posHoldActiveCode);
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              cardDetail(),
              (global
                      .posHoldProcessResult[global
                          .findPosHoldProcessResultIndex(
                            global.posHoldActiveCode,
                          )]
                      .payScreenData
                      .cheque
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
                            .cheque
                            .map((detail) {
                              var index = global
                                  .posHoldProcessResult[global
                                      .findPosHoldProcessResultIndex(
                                        global.posHoldActiveCode,
                                      )]
                                  .payScreenData
                                  .cheque
                                  .indexOf(detail);
                              return buildCreditCard(index: index);
                            }),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
