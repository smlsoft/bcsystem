import 'package:dedecashier/widgets/button.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter/services.dart';

class ReceiveMoneyDialog extends StatefulWidget {
  const ReceiveMoneyDialog({super.key});

  @override
  State<ReceiveMoneyDialog> createState() => _MoneyReceiveState();
}

class _MoneyReceiveState extends State<ReceiveMoneyDialog> {
  TextEditingController receiveAmount = TextEditingController();
  TextEditingController empCode = TextEditingController();

  void textInputChanged(String value) {
    receiveAmount.text += value;
  }

  void showMsgDialog({required String header, required String msg, required String type}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(header),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(msg),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ตกลง'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void clearText() {
    receiveAmount.text = "";
  }

  void backSpace() {
    if (receiveAmount.text.isNotEmpty) {
      receiveAmount.text = receiveAmount.text.substring(0, receiveAmount.text.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(maxWidth: 250),
                        width: (MediaQuery.of(context).size.width / 100) * 40,
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "receive_money",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                controller: empCode,
                                decoration: const InputDecoration(
                                  icon: Icon(Icons.person),
                                  hintText: 'Emp Code',
                                  labelText: 'พนักงาน',
                                ),
                                readOnly: true,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                readOnly: true,
                                controller: receiveAmount,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  icon: Icon(Icons.money),
                                  hintText: global.language("money_amount"),
                                  labelText: global.language("money_change"),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade600),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(global.language("cancel")),
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                                    onPressed: () async {
                                      // String docNumber =
                                      //     const Uuid().v4();
                                      /*ReceiveMoneyHelper
                                                _receiveMoneyHelper =
                                                ReceiveMoneyHelper();
                                            _receiveMoneyHelper.insert(
                                                ReceiveMoneyStruct(
                                                    doc_number: docNumber,
                                                    person_code: emp_code.text,
                                                    create_date_time:
                                                        DateTime.now(),
                                                    receive_money: double.parse(
                                                        receiveAmount.text)));

                                            await PrintQueueHelper().insert(
                                                PrintQueueStruct(
                                                    code: 3,
                                                    doc_number: docNumber,
                                                    printer_code: global
                                                        .cashierPrinterCode));*/
                                      global.printQueueStartServer();
                                      //processEvent();

                                      Navigator.of(context).pop();

                                      global.playSound(word: "รับเงินทอน จำนวน ${receiveAmount.text} ${global.language("money_symbol")}");

                                      showMsgDialog(header: "บันทึกสำเร็จ", msg: "รับเงินทอน จำนวน ${receiveAmount.text} ${global.language("money_symbol")}", type: "success");
                                    },
                                    child: Text(global.language("save")),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 250),
                        width: (MediaQuery.of(context).size.width / 100) * 50,
                        child: Column(
                          children: <Widget>[
                            Align(
                              alignment: Alignment.topCenter,
                              child: Column(children: [
                                SizedBox(
                                    height: 60,
                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: '7',
                                            callBack: () => {textInputChanged("7")},
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: '8',
                                            callBack: () => {textInputChanged("8")},
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: '9',
                                            callBack: () => {textInputChanged("9")},
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: 'x',
                                            callBack: () => {},
                                          )),
                                    ])),
                                SizedBox(
                                    height: 60,
                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: '4',
                                            callBack: () => {textInputChanged("4")},
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: '5',
                                            callBack: () => {textInputChanged("5")},
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: '6',
                                            callBack: () => {textInputChanged("6")},
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: '+',
                                            callBack: () => {},
                                          )),
                                    ])),
                                SizedBox(
                                    height: 60,
                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: '1',
                                            callBack: () => {textInputChanged("1")},
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: '2',
                                            callBack: () => {textInputChanged("2")},
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: '3',
                                            callBack: () => {textInputChanged("3")},
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: 'C',
                                            callBack: () => {clearText()},
                                          )),
                                    ])),
                                SizedBox(
                                    height: 60,
                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: '0',
                                            callBack: () => {textInputChanged("0")},
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            text: '.',
                                            callBack: () => {textInputChanged(".")},
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            icon: Icons.backspace,
                                            callBack: () => {backSpace()},
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: NumPadButton(
                                            icon: Icons.expand,
                                            callBack: () => {},
                                          )),
                                    ])),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
