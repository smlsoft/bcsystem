import 'package:dedecashier/edckbank/edc_message.dart';
import 'package:dedecashier/edckbank/edc_response.dart';

import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class PayQREDCPage extends StatefulWidget {
  final double amount;

  const PayQREDCPage({super.key, required this.amount});

  @override
  PayQREDCPageState createState() => PayQREDCPageState();
}

enum EDCStatus { Waiting, Success, Cancel, DuplicateSend, Error, Noting }

class PayQREDCPageState extends State<PayQREDCPage> {
  static const platform = MethodChannel('com.smlsoft.dedecashier/usb');
  EventChannel streamChannel = const EventChannel(
    'com.smlsoft.dedecashier/stream',
  );
  Stream<dynamic>? _stream;
  String _response = 'No response yet';

  EDCResponse? response;

  TextEditingController ref1Controller = TextEditingController();
  TextEditingController ref2Controller = TextEditingController();
  TextEditingController amountController = TextEditingController();
  bool isStoping = false;
  bool steamRuning = false;
  EDCStatus edcStatus = EDCStatus.Noting;
  EDCResponse edcResponse = EDCResponse();
  Future<void> connectToDevice() async {
    try {
      final result = await platform.invokeMethod('connectToDevice', {
        "productName": global.edcProductName,
      });
      setState(() {
        _response = result;
      });

      AppLogger.debug('Connection result: $result');
    } on PlatformException catch (e) {
      setState(() {
        edcStatus = EDCStatus.Error;
        _response = 'Failed to connect to the device: ${e.message}';
      });

      AppLogger.error('Failed to connect to the device: ${e.message}');
    }
  }

  Future<void> disconnect() async {
    try {
      final result = await platform.invokeMethod('disconnect');
      setState(() {
        _response = result;
        isStoping = false;
        steamRuning = false;
      });
      AppLogger.debug('Disconnect result: $result');
    } on PlatformException catch (e) {
      setState(() {
        isStoping = false;
      });
      AppLogger.error('Failed to connect to the device: ${e.message}');
    }
  }

  Future<void> sendDataToDevice() async {
    if (global.edcProductName == "") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select device')));
      return;
    }
    if (ref1Controller.text.isEmpty ||
        ref2Controller.text.isEmpty ||
        amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    try {
      EdcMessage message = EdcMessage();
      List<int> datas = message.createSaleQRMessage(
        double.parse(amountController.text),
        ref1Controller.text,
        ref2Controller.text,
      );

      Uint8List saleData = Uint8List.fromList(datas);
      platform.invokeMethod('sendData', {"dataToSend": saleData});
    } on PlatformException catch (e) {
      AppLogger.error('Failed to connect to the device: ${e.message}');
    }
  }

  Future<void> initDevice() async {
    await global.getListOfAvailableDrivers();
    Future.delayed(const Duration(seconds: 1), () async {
      await connectToDevice();
      await _startDataStreaming();
    });
    ref1Controller.text = DateTime.now().toString().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    ref2Controller.text =
        const Uuid().v4().split('-')[0] + const Uuid().v4().split('-')[1];
    amountController.text = widget.amount.toString();
    Future.delayed(const Duration(seconds: 1), () {
      sendDataToDevice();
    });
  }

  Future<void> backToPayScreen() async {
    await _stopDataStreaming();
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }

  @override
  void initState() {
    super.initState();
    initDevice();

    streamChannel.receiveBroadcastStream().listen((dynamic data) {
      AppLogger.debug(data);
      edcResponse.loadResponseBytes(stringToBytes(data));
      if (edcResponse.isResponseSuccess()) {
        edcStatus = EDCStatus.Success;
        Future.delayed(const Duration(seconds: 5), () async {
          await _stopDataStreaming();
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pop(context, widget.amount);
          });
        });
      }
      if (edcResponse.isResponseCancel()) {
        edcStatus = EDCStatus.Cancel;
        backToPayScreen();
      }
      if (edcResponse.isMessageSuccessACK()) {
        edcStatus = EDCStatus.Waiting;
      }
      if (edcResponse.isDuplicateSend()) {
        edcStatus = EDCStatus.DuplicateSend;
        backToPayScreen();
      }

      setState(() {});
    });
  }

  Uint8List stringToBytes(String input) {
    var parts = input.substring(1, input.length - 1).split(', ');
    var intList = parts.map(int.parse).toList();
    return Uint8List.fromList(intList);
  }

  Future<void> _startDataStreaming() async {
    try {
      // Call the receiveDataFromDevice method on the native side
      final String message = await platform.invokeMethod('startDataStreaming');
      setState(() {
        steamRuning = true;
      });
      AppLogger.debug('Data streaming started: $message');
    } on PlatformException catch (e) {
      AppLogger.error('Error starting data streaming: ${e.message}');
    }
  }

  Future<void> _stopDataStreaming() async {
    if (isStoping) {
      return;
    }
    setState(() {
      isStoping = true;
    });
    try {
      // Call the stopDataStreaming method on the native side
      final String message = await platform.invokeMethod('stopDataStreaming');
      AppLogger.debug('Data streaming stopped: $message');
      Future.delayed(const Duration(seconds: 1), () {
        disconnect();
      });
    } on PlatformException catch (e) {
      setState(() {
        isStoping = false;
      });
      AppLogger.error('Error stopping data streaming: ${e.message}');
    }
  }

  Widget _getEDCMessage() {
    Widget message = Container();
    if (edcStatus == EDCStatus.Waiting) {
      message = const Text(
        "รอรับชำระ",
        style: TextStyle(fontSize: 16, color: Colors.blue),
      );
    } else if (edcStatus == EDCStatus.Success) {
      message = const Text(
        "ชำระเงินสำเร็จ",
        style: TextStyle(fontSize: 16, color: Colors.green),
      );
    } else if (edcStatus == EDCStatus.Cancel) {
      message = const Text(
        "ยกเลิกการชำระ",
        style: TextStyle(fontSize: 16, color: Colors.red),
      );
    } else if (edcStatus == EDCStatus.DuplicateSend) {
      message = const Text(
        "ส่งข้อมูลซ้ำ",
        style: TextStyle(fontSize: 16, color: Colors.red),
      );
    } else if (edcStatus == EDCStatus.Error) {
      message = const Text(
        "เกิดข้อผิดพลาด",
        style: TextStyle(fontSize: 16, color: Colors.red),
      );
    } else if (edcStatus == EDCStatus.Noting) {
      message = const Text(
        "รอส่งชำระ",
        style: TextStyle(fontSize: 16, color: Colors.orange),
      );
    } else {
      message = const Text(
        "ไม่พบข้อมูล",
        style: TextStyle(fontSize: 16, color: Colors.red),
      );
    }
    return message;
  }

  @override
  void dispose() {
    if (steamRuning) {
      _stopDataStreaming();
    }
    super.dispose();
  }

  Widget initScreen() {
    Widget returnWidget = Container();
    returnWidget = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        const Text(
          "ชำระด้วยบัตรเครดิต",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Text('รายการเครื่อง EDC ที่เชื่อมต่อ'),
        const SizedBox(height: 20),
        ...global.driversAvailableList.map((port) {
          return Container(
            margin: const EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
              color: (global.edcProductName == port["productName"])
                  ? Colors.green
                  : Colors.grey[200],
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: ListTile(
              title: Text(
                "${port["productName"]}",
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                global.playSound(sound: global.SoundEnum.buttonTing);
                setState(() {
                  global.edcProductName = port["productName"];
                });
              },
              trailing: (global.edcProductName == port["productName"])
                  ? const Text(
                      'Connected',
                      style: TextStyle(color: Colors.white),
                    )
                  : Container(),
            ),
          );
        }),
        const SizedBox(height: 20),
        Text("สถานะเครื่องEDC :$_response"),
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.only(top: 20),
          width: 300,
          child: TextField(
            controller: ref1Controller,
            decoration: const InputDecoration(
              label: Text("Ref 1"),
              border: OutlineInputBorder(),
              hintText: 'Ref 1',
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 20),
          width: 300,
          child: TextField(
            controller: ref2Controller,
            decoration: const InputDecoration(
              label: Text("Ref 2"),
              border: OutlineInputBorder(),
              hintText: 'Ref 2',
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 20),
          width: 300,
          child: TextField(
            readOnly: true,
            controller: amountController,
            decoration: const InputDecoration(
              label: Text("จำนวนเงิน"),
              border: OutlineInputBorder(),
              hintText: 'Amount',
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            global.playSound(sound: global.SoundEnum.qrScanned);
            sendDataToDevice();
          },
          child: const Text('ชำระเงิน'),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("ข้อความตอบกลับ EDC : ", style: TextStyle(fontSize: 16)),
            _getEDCMessage(),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            global.playSound(sound: global.SoundEnum.buttonTing);
            await _stopDataStreaming();
            Future.delayed(const Duration(seconds: 1), () {
              Navigator.pop(context);
            });
          },
          child: const Text('ยกเลิก'),
        ),
      ],
    );
    return returnWidget;
  }

  Widget waitingScreen() {
    Widget returnWidget = Container();
    returnWidget = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/edcpay.gif',
            width: 350,
            height: 300,
            fit: BoxFit.cover,
          ),
          const Text(
            "กรุณาทำรายที่เครื่องรูดบัตร",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            "Ref 1 : ${ref1Controller.text}",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "Ref 2 : ${ref2Controller.text}",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "จำนวนเงิน : ${amountController.text}",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
    return returnWidget;
  }

  Widget successScreen() {
    Widget returnWidget = Container();
    returnWidget = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          const Text(
            "ชำระเงินสำเร็จ",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            "Ref 1 : ${ref1Controller.text}",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "Ref 2 : ${ref2Controller.text}",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "Card Number : ${edcResponse.cardNumber}",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "Card Type : ${edcResponse.cardIssuerName}",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "Card HolderName : ${edcResponse.cardHolderName}",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "TerminalInvoiceNumber : ${edcResponse.terminalInvoiceNumber}",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "จำนวนเงิน : ${amountController.text}",
            style: const TextStyle(fontSize: 16),
          ),
          const CircularProgressIndicator(),
          // ElevatedButton(
          //     onPressed: () async {
          //       await _stopDataStreaming();
          //       Future.delayed(const Duration(seconds: 2), () {
          //         Navigator.pop(context, widget.amount);
          //       });
          //     },
          //     child: const Text('ชำระเงินสำเร็จ')),
        ],
      ),
    );
    return returnWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: (edcStatus == EDCStatus.Waiting)
            ? waitingScreen()
            : (edcStatus == EDCStatus.Success)
            ? successScreen()
            : (edcStatus == EDCStatus.Error)
            ? SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Error",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "สถานะเครื่องEDC :$_response",
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        await _stopDataStreaming();
                        Future.delayed(const Duration(seconds: 1), () {
                          Navigator.pop(context);
                        });
                      },
                      child: const Text('ยกเลิก'),
                    ),
                  ],
                ),
              )
            : Container(),
      ),
    );
  }
}
