import 'package:flutter/material.dart';
import 'button.dart';

class PinNumberPad extends StatefulWidget {
  final Function? onChange;
  final String header;
  final int pinLength;

  const PinNumberPad(
      {Key? key,
      required this.onChange,
      this.header = "PIN",
      this.pinLength = 4})
      : super(key: key);

  @override
  _PinNumberPadState createState() => _PinNumberPadState();
}

class _PinNumberPadState extends State<PinNumberPad> {
  String number = '';

  setValue(String val) {
    if (number.length < widget.pinLength) {
      number += val;
      setState(() {});
      widget.onChange!(number);
    }
  }

  backspace(String text) {
    if (text.isNotEmpty) {
      number = text.split('').sublist(0, text.length - 1).join('');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: <Widget>[
                if (widget.header != "")
                  Text(widget.header,
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(children: [
                  for (var i = 0; i < widget.pinLength; i++)
                    Expanded(
                        child: Container(
                            height: 75,
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: number.length > i
                                        ? Colors.blue
                                        : Colors.grey,
                                    width: 2),
                                borderRadius: BorderRadius.circular(4)),
                            child: (number.length > i)
                                ? const Center(
                                    child: Text(
                                    '*',
                                    style: TextStyle(fontSize: 32),
                                  ))
                                : Container()))
                ]),
                const SizedBox(height: 16),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                          child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                              flex: 1,
                              child: NumPadButton(
                                text: '1',
                                callBack: () => setValue('1'),
                              )),
                          Expanded(
                              flex: 1,
                              child: NumPadButton(
                                text: '2',
                                callBack: () => setValue('2'),
                              )),
                          Expanded(
                              flex: 1,
                              child: NumPadButton(
                                text: '3',
                                callBack: () => setValue('3'),
                              )),
                        ],
                      )),
                      Expanded(
                          child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                              flex: 1,
                              child: NumPadButton(
                                text: '4',
                                callBack: () => setValue('4'),
                              )),
                          Expanded(
                              flex: 1,
                              child: NumPadButton(
                                text: '5',
                                callBack: () => setValue('5'),
                              )),
                          Expanded(
                              flex: 1,
                              child: NumPadButton(
                                text: '6',
                                callBack: () => setValue('6'),
                              )),
                        ],
                      )),
                      Expanded(
                          child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                              flex: 1,
                              child: NumPadButton(
                                text: '7',
                                callBack: () => setValue('7'),
                              )),
                          Expanded(
                              flex: 1,
                              child: NumPadButton(
                                text: '8',
                                callBack: () => setValue('8'),
                              )),
                          Expanded(
                              flex: 1,
                              child: NumPadButton(
                                text: '9',
                                callBack: () => setValue('9'),
                              )),
                        ],
                      )),
                      Expanded(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                              flex: 2,
                              child: NumPadButton(
                                text: '0',
                                callBack: () => setValue('0'),
                              )),
                          Expanded(
                              flex: 1,
                              child: NumPadButton(
                                icon: Icons.backspace,
                                callBack: () => backspace(number),
                              )),
                        ],
                      )),
                    ],
                  ),
                )
              ],
            )));
  }
}
