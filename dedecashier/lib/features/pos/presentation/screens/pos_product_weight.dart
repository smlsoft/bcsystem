import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_num_pad.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:get/utils.dart';

class PosProductWeightScreen extends StatefulWidget {
  final String name;
  final String imageUrl;

  const PosProductWeightScreen({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  State<PosProductWeightScreen> createState() => _PosProductWeightScreenState();
}

class _PosProductWeightScreenState extends State<PosProductWeightScreen> {
  String textInput = "";
  FocusNode mainFocusNode = FocusNode();
  List<double> weightList = [];
  double totalWeight = 0;

  @override
  void initState() {
    super.initState();
    global.posNumPadProductWeightGlobalKey.currentState?.clear();
  }

  Widget detailData() {
    return ListView.builder(
      itemCount: weightList.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  "${global.language("weighing_count")} ${index + 1}",
                ),
              ),
              Text(
                "${global.moneyFormat.format(weightList[index])} ${global.language("gram")}",
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () {
                  global.playSound(sound: global.SoundEnum.itemRemoved);
                  setState(() {
                    totalWeight -= weightList[index];
                    weightList.removeAt(index);
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget detail() {
    Widget data =
        ((global.deviceMode == global.DeviceModeEnum.androidPhone ||
            global.deviceMode == global.DeviceModeEnum.iphone))
        ? Row(
            children: [
              Image(
                width: 150,
                image: CachedNetworkImageProvider(widget.imageUrl),
              ),
              Expanded(child: detailData()),
            ],
          )
        : Column(
            children: [
              Image(
                height: 200,
                image: CachedNetworkImageProvider(widget.imageUrl),
              ),
              Expanded(child: detailData()),
            ],
          );
    return (weightList.isEmpty)
        ? Center(
            child: (widget.imageUrl.isNotEmpty)
                ? Image(image: CachedNetworkImageProvider(widget.imageUrl))
                : const Icon(
                    Icons.wallet_giftcard,
                    color: Colors.grey,
                    size: 200,
                  ),
          )
        : Column(
            children: [
              Expanded(child: data),
              SizedBox(
                height: 50,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        setState(() {
                          weightList.clear();
                        });
                      },
                      child: Text(global.language("restart")),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.cyan.shade100,
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: Text(global.language("total"))),
                            Text(
                              "${global.moneyFormat.format(totalWeight)} กรัม",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        setState(() {
                          Navigator.pop(context, totalWeight);
                        });
                      },
                      child: Text(global.language("confirm")),
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  Widget numberPad() {
    return PosNumPad(
      key: global.posNumPadProductWeightGlobalKey,
      onChange: (String number) {
        setState(() {
          textInput = number;
        });
      },
      onSubmit: (String number) {
        setState(() {
          double value = double.tryParse(number.replaceAll("¾", ".")) ?? 0;
          if (value != 0) {
            weightList.add(value);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    totalWeight = 0;
    for (double weight in weightList) {
      totalWeight += weight;
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: RawKeyboardListener(
        autofocus: true,
        includeSemantics: true,
        focusNode: mainFocusNode,
        onKey: (RawKeyEvent key) {
          if (key.runtimeType.toString() == 'RawKeyDownEvent') {
            String keyLabel = key.logicalKey.keyLabel.toUpperCase();
            if (keyLabel == "BACKSPACE") {
              if (global.posNumPadProductWeightGlobalKey.currentState != null) {
                global.posNumPadProductWeightGlobalKey.currentState!
                    .backspace();
              }
            }
            if (keyLabel.contains("NUMPAD") || keyLabel.contains("MULTIPLY")) {
              keyLabel = keyLabel.removeAllWhitespace.replaceAll("NUMPAD", "");
              if (keyLabel.contains("DECIMAL")) {
                keyLabel = ".";
              }
              if (keyLabel == "MULTIPLY") {
                keyLabel = "*";
              }
              if ("01234567890*.".contains(keyLabel)) {
                global.posNumPadProductWeightGlobalKey.currentState?.addValue(
                  keyLabel,
                );
              }
            }
          }
        },
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(10),
          child:
              (global.deviceMode == global.DeviceModeEnum.androidPhone ||
                  global.deviceMode == global.DeviceModeEnum.iphone)
              ? Column(
                  children: [
                    Expanded(child: detail()),
                    const SizedBox(height: 10),
                    Expanded(child: numberPad()),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: detail()),
                    const SizedBox(width: 10),
                    Expanded(child: numberPad()),
                  ],
                ),
        ),
      ),
    );
  }
}
