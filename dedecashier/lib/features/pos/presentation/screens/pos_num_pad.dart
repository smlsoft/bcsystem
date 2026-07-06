import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/widgets/button.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/core/logger/app_logger.dart';

class PosNumPad extends StatefulWidget {
  final Function onChange;
  final Function onSubmit;
  final String header;
  final Widget? title;
  final String? unitName;

  const PosNumPad({
    super.key,
    required this.onChange,
    this.title,
    required this.onSubmit,
    this.unitName,
    this.header = "",
  });

  @override
  PosNumPadState createState() => PosNumPadState();
}

class PosNumPadState extends State<PosNumPad> {
  String number = '';

  void clear({bool silent = false}) {
    if (!silent) {
      AppLogger.debug('🔊 [SOUND] Playing numpadClear from PosNumPad.clear()');
      global.playSound(sound: global.SoundEnum.numpadClear);
    } else {
      AppLogger.debug('🔇 [SILENT] PosNumPad.clear() called in silent mode');
    }
    setState(() {
      number = '';
    });
  }

  void passValue(String val) {
    global.playSound(sound: global.SoundEnum.numpadEnter);
    setState(() {
      number = "";
      widget.onSubmit(val);
    });
  }

  void addValue(String val) {
    // เล่นเสียงตามตัวเลขที่กด
    switch (val) {
      case '0':
        global.playSound(sound: global.SoundEnum.num0);
        break;
      case '1':
        global.playSound(sound: global.SoundEnum.num1);
        break;
      case '2':
        global.playSound(sound: global.SoundEnum.num2);
        break;
      case '3':
        global.playSound(sound: global.SoundEnum.num3);
        break;
      case '4':
        global.playSound(sound: global.SoundEnum.num4);
        break;
      case '5':
        global.playSound(sound: global.SoundEnum.num5);
        break;
      case '6':
        global.playSound(sound: global.SoundEnum.num6);
        break;
      case '7':
        global.playSound(sound: global.SoundEnum.num7);
        break;
      case '8':
        global.playSound(sound: global.SoundEnum.num8);
        break;
      case '9':
        global.playSound(sound: global.SoundEnum.num9);
        break;
      case '.':
        global.playSound(sound: global.SoundEnum.numDot);
        break;
      default:
        global.playSound(sound: global.SoundEnum.buttonTing);
    }

    setState(() {
      number += val;
      widget.onChange(number);
    });
  }

  void backspace() {
    if (number.isNotEmpty) {
      global.playSound(sound: global.SoundEnum.numpadDelete);
      setState(() {
        number = number.split('').sublist(0, number.length - 1).join('');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0),
        ),
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: <Widget>[
            if (widget.header != "")
              Text(
                widget.header,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (widget.title != null)
              Container(
                padding: const EdgeInsets.only(
                  left: 2,
                  right: 2,
                  top: 4,
                  bottom: 4,
                ),
                child: widget.title,
              ),
            Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.only(left: 2, right: 2),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
                            margin: 2,
                            text: '7',
                            callBack: () => addValue('7'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            margin: 2,
                            text: '8',
                            callBack: () => addValue('8'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            margin: 2,
                            text: '9',
                            callBack: () => addValue('9'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            margin: 2,
                            color: Colors.orange,
                            text: 'X',
                            callBack: () => addValue('X'),
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
                          flex: 1,
                          child: NumPadButton(
                            margin: 2,
                            text: '4',
                            callBack: () => addValue('4'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            margin: 2,
                            text: '5',
                            callBack: () => addValue('5'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            margin: 2,
                            text: '6',
                            callBack: () => addValue('6'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            margin: 2,
                            color: Colors.orange,
                            icon: Icons.backspace,
                            callBack: () => backspace(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            margin: 2,
                            text: '1',
                            callBack: () => addValue('1'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            margin: 2,
                            text: '2',
                            callBack: () => addValue('2'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            margin: 2,
                            text: '3',
                            callBack: () => addValue('3'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            margin: 2,
                            color: Colors.orange,
                            text: 'C',
                            callBack: () => clear(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: NumPadButton(
                            margin: 2,
                            text: '0',
                            callBack: () => addValue('0'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            margin: 2,
                            text: '.',
                            callBack: () => addValue('.'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            margin: 2,
                            color: Colors.orange,
                            icon: Icons.check,
                            callBack: () {
                              widget.onSubmit(number);
                              setState(() {
                                number = '';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
