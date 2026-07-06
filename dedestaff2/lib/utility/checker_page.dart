import 'dart:convert';
import 'dart:io';
import 'package:dedeorder/model/product_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:async';
import 'package:dedeorder/model/global_model.dart';
import 'package:intl/intl.dart';
import 'package:dedeorder/bloc/order_temp_bloc.dart';
import 'package:dedeorder/model/order_temp_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:dedeorder/utility/api.dart' as api;

class CheckerPage extends StatefulWidget {
  const CheckerPage({super.key});

  @override
  _CheckerPageState createState() => _CheckerPageState();
}

class _CheckerPageState extends State<CheckerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool showCamera = false;
  double textFontSize = 10;
  late Timer timeRefesh;
  List<String> tableNumberList = [];
  List<TableInfoModel> tableInfo = [];
  bool visible = false;
  String barcode = "";
  bool isCamera = false;
  List<CheckerHistoryModel> checkerHistory = [];

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void initState() {
    super.initState();
    timeRefesh = Timer.periodic(const Duration(seconds: 10), (Timer t) {
      if (kDebugMode) {
        print('Timer');
      }
      reload();
    });
    global.checkForCamera().then((value) {
      setState(() {
        isCamera = value;
      });
    });
    reload();
  }

  void reload() {
    context.read<OrderTempBloc>().add(OrderTempCheckerGetData());
  }

  @override
  void dispose() {
    timeRefesh.cancel();
    controller?.dispose();
    super.dispose();
  }

  Widget orderTempWidget({required TableInfoModel table, required OrderTempObjectBoxStruct orderTemp}) {
    String orderTimeStr = DateFormat('HH:mm').format(orderTemp.orderDateTime);
    int diffMinutes = DateTime.now().difference(orderTemp.orderDateTime).inMinutes;
    bool isServedSuccess = (orderTemp.orderQty - orderTemp.cancelQty) == orderTemp.servedQty;
    Color backgroundColor = Colors.white;
    String orderName = global.getNameFromJsonLanguage(orderTemp.names, global.userLanguage);

    if (orderTemp.remark.isNotEmpty) {
      orderName += ' (${orderTemp.remark})';
    }
    if (orderTemp.optionSelected.isNotEmpty) {
      var jsonList = jsonDecode(orderTemp.optionSelected);
      for (var json in jsonList) {
        var option = ProductProcessOptionModel.fromJson(json);
        for (var choice in option.choices) {
          if (choice.selected == true) {
            orderName += " ${global.getNameFromLanguage(choice.names, global.userLanguage)}";
            if (choice.priceValue! > 0) {
              orderName += " ${global.moneyFormat.format(choice.priceValue)} บาท";
            }
          }
        }
      }
    }
    if (isServedSuccess == false) {
      if (diffMinutes > 20) {
        backgroundColor = Colors.red.shade200;
      } else if (diffMinutes > 10) {
        backgroundColor = Colors.orange.shade200;
      }
    }

    return InkWell(
        // สำหรับเปิดหน้าจอแสดงรายการอาหาร
        onTap: () async {
          // ถามว่าจะเปิดหน้าจอแสดงรายการอาหารหรือไม่
          double servedQty = (orderTemp.orderQty - orderTemp.cancelQty) - orderTemp.servedQty;
          if (servedQty > 0) {
            double confirmServedQty = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: Text('จำนวนเสริฟท์ ${global.getNameFromJsonLanguage(orderTemp.names, global.userLanguage)}'),
                      actions: [
                        Column(
                          children: [
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.blue[100],
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text("จำนวนที่ต้องการ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.cyan,
                                          ),
                                          onPressed: () {
                                            if (servedQty > 1) {
                                              setState(() {
                                                servedQty--;
                                              });
                                            }
                                          },
                                          child: Text("-", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                                      Spacer(),
                                      Text(global.moneyFormat.format(servedQty), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                      Spacer(),
                                      ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.cyan,
                                          ),
                                          onPressed: () {
                                            if (servedQty + 1 < (orderTemp.orderQty - orderTemp.cancelQty)) {
                                              setState(() {
                                                servedQty++;
                                              });
                                            }
                                          },
                                          child: Text("+", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                                    ],
                                  )
                                ])),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context, 0.0);
                                    },
                                    child: const Text('ยกเลิก')),
                                Spacer(),
                                ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context, servedQty);
                                    },
                                    child: const Text('บันทึก')),
                              ],
                            ),
                          ],
                        )
                      ],
                    );
                  },
                );
              },
            );
            if (confirmServedQty != 0) {
              await gotoOrderByQrcode(qrCode: orderTemp.orderGuid, confirmServedQty: confirmServedQty);
            }
            setState(() {});
          }
        },
        child: Container(
          padding: const EdgeInsets.all(5),
          color: isServedSuccess ? Colors.green.shade200 : backgroundColor,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(orderTimeStr, style: TextStyle(fontSize: textFontSize)),
              ),
              Expanded(
                flex: 6,
                child: Text(orderName, style: TextStyle(fontSize: textFontSize)),
              ),
              Expanded(
                flex: 2,
                child: Text(global.moneyFormat.format(orderTemp.price), style: TextStyle(fontSize: textFontSize), textAlign: TextAlign.right),
              ),
              Expanded(
                flex: 2,
                child: Text(global.moneyFormat.format(orderTemp.orderQty), style: TextStyle(fontSize: textFontSize), textAlign: TextAlign.right),
              ),
              Expanded(
                flex: 2,
                child: (orderTemp.servedQty == 0) ? Container() : Text(global.moneyFormat.format(orderTemp.servedQty), style: TextStyle(fontSize: textFontSize), textAlign: TextAlign.right),
              ),
              Expanded(
                flex: 2,
                child: (orderTemp.cancelQty == 0) ? Container() : Text(global.moneyFormat.format(orderTemp.cancelQty), style: TextStyle(fontSize: textFontSize), textAlign: TextAlign.right),
              ),
              Expanded(
                flex: 1,
                child: Text(global.moneyFormat.format(diffMinutes), style: TextStyle(fontSize: textFontSize), textAlign: TextAlign.right),
              ),
            ],
          ),
        ));
  }

  Widget tableWidget(TableInfoModel table) {
    return Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(2),
          color: Colors.blue[100],
        ),
        child: Column(
          children: [
            Container(
                padding: const EdgeInsets.only(left: 5, right: 5),
                decoration: BoxDecoration(
                  color: Colors.blue[200],
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text("โต๊ะ : ${table.number}", style: TextStyle(fontSize: textFontSize * 1.5, color: Colors.black, fontWeight: FontWeight.bold)),
                    Expanded(
                        child: Text("เปิดโต๊ะ : ${DateFormat('HH:mm').format(table.openDateTime)}",
                            textAlign: TextAlign.right, style: TextStyle(fontSize: textFontSize * 1.5, color: Colors.black, fontWeight: FontWeight.bold))),
                  ],
                )),
            Container(
                padding: EdgeInsets.only(left: 5, right: 5),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text("เวลาสั่ง", style: TextStyle(fontSize: textFontSize, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text("รายละเอียด", style: TextStyle(fontSize: textFontSize, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text("ราคา", style: TextStyle(fontSize: textFontSize, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text("สั่ง", style: TextStyle(fontSize: textFontSize, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text("เสริฟท์", style: TextStyle(fontSize: textFontSize, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text("ยกเลิก", style: TextStyle(fontSize: textFontSize, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text("นาที", style: TextStyle(fontSize: textFontSize, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    ),
                  ],
                )),
            for (var order in table.orders) orderTempWidget(table: table, orderTemp: order),
          ],
        ));
  }

  Future<void> gotoOrderByQrcode({required String qrCode, double confirmServedQty = 1}) async {
    await api.orderTempServedStatusByGuid(guid: qrCode, servedQty: confirmServedQty);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(qrCode),
          backgroundColor: Colors.deepOrange,
        ),
      );
    }
    int tableIndex = -1;
    for (var i = 0; i < tableInfo.length; i++) {
      for (var order in tableInfo[i].orders) {
        if (order.orderGuid == qrCode) {
          tableIndex = i;
          break;
        }
      }
    }
    if (tableIndex != -1) {
      int orderIndex = -1;
      for (var i = 0; i < tableInfo[tableIndex].orders.length; i++) {
        if (tableInfo[tableIndex].orders[i].orderGuid == qrCode) {
          orderIndex = i;
          break;
        }
      }
      if (orderIndex != -1) {
        checkerHistory.insert(
            0,
            CheckerHistoryModel(
                servedDateTime: DateTime.now(),
                tableNumber: tableInfo[tableIndex].number,
                productName: global.getNameFromJsonLanguage(tableInfo[tableIndex].orders[orderIndex].names, global.userLanguage),
                productUnitName: global.getNameFromJsonLanguage(tableInfo[tableIndex].orders[orderIndex].unitName, global.userLanguage),
                orderQty: confirmServedQty));
        // ถ้าเกิน 10 รายการ ให้ลบออก
        if (checkerHistory.length > 10) {
          checkerHistory.removeLast();
        }
      }
    }
    setState(() {});
    reload();
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        // Process barcode
        gotoOrderByQrcode(qrCode: barcode);
        setState(() {
          barcode = '';
        });
      } else {
        if (event.character != null) {
          setState(() {
            barcode += event.character!;
          });
        }
      }
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera();
      if (await Vibration.hasVibrator() != null) {
        Vibration.vibrate(duration: 1000);
      }
      gotoOrderByQrcode(qrCode: scanData.code!);
      reload();
      controller.resumeCamera();
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400) ? 200.0 : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(borderColor: Colors.red, borderRadius: 10, borderLength: 30, borderWidth: 10, cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget detailWidget = LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      double width = constraints.maxWidth;
      int columnCount = width ~/ 300;
      if (columnCount == 0) {
        columnCount = 1;
      }
      return Wrap(
        children: [
          for (var item in tableInfo)
            SizedBox(
              width: width / columnCount,
              child: tableWidget(item),
            ),
        ],
      );
    });
    Widget historyWidget = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(2),
          color: Colors.blue[100],
        ),
        child: Wrap(
          children: checkerHistory.map((item) {
            int diffSeconds = DateTime.now().difference(item.servedDateTime).inSeconds;
            Color backgoundColor = Colors.white;
            if (diffSeconds > 60) {
              backgoundColor = Colors.green.shade100;
            } else if (diffSeconds > 30) {
              backgoundColor = Colors.orange.shade100;
            }
            return Container(
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: backgoundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: const Offset(0, 1), // เปลี่ยนตำแหน่งของเงา
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text('โต๊ะ : ${item.tableNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(DateFormat('HH:mm').format(item.servedDateTime), style: const TextStyle(fontSize: 12)),
                  Text(item.productName, style: const TextStyle(fontSize: 12)),
                  Text("${global.moneyFormat.format(item.orderQty)} ${item.productUnitName}", style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }).toList(),
        ));
    return BlocListener<OrderTempBloc, OrderTempState>(
        listener: (context, state) {
          if (state is OrderTempCheckerGetDataSuccess) {
            tableNumberList = [];
            tableInfo = [];
            for (var item in state.result) {
              if (!tableNumberList.contains(item.orderIdMain)) {
                if (item.isOrderSuccess) {
                  tableNumberList.add(item.orderIdMain);
                }
              }
            }
            // pack
            for (var tableNumber in tableNumberList) {
              List<OrderTempObjectBoxStruct> orderTemp = [];
              DateTime openDateTime = DateTime.now();
              for (var item in state.result) {
                if (item.orderIdMain == tableNumber) {
                  if (item.isOrderSuccess) {
                    orderTemp.add(item);
                    if (openDateTime.isAfter(item.orderDateTime)) {
                      openDateTime = item.orderDateTime;
                    }
                  }
                }
              }
              tableInfo.add(TableInfoModel(number: tableNumber, openDateTime: openDateTime, orders: orderTemp));
            }
            // sort by table number
            bool allTableIsDigit = true;
            for (var item in tableInfo) {
              if (int.tryParse(item.number) == null) {
                allTableIsDigit = false;
                break;
              }
            }
            if (allTableIsDigit) {
              tableInfo.sort((a, b) => (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));
            } else {
              tableInfo.sort((a, b) => a.number.compareTo(b.number));
            }
            setState(() {});
          }
        },
        child: RawKeyboardListener(
            focusNode: FocusNode(),
            autofocus: true,
            onKey: _handleKey,
            child: SafeArea(
                child: Scaffold(
              backgroundColor: Colors.grey.shade400,
              appBar: AppBar(
                title: const Text('Checker'),
                actions: [
                  IconButton(
                      onPressed: () {
                        setState(() {
                          textFontSize += 2;
                          if (textFontSize > 24) {
                            textFontSize = 10;
                          }
                        });
                      },
                      icon: const Icon(Icons.font_download)),
                  if (isCamera)
                    IconButton(
                        onPressed: () {
                          setState(() {
                            showCamera = !showCamera;
                          });
                        },
                        icon: const Icon(Icons.camera_alt)),
                ],
              ),
              body: (showCamera && isCamera)
                  ? VisibilityDetector(
                      key: const Key('camera'),
                      onVisibilityChanged: (VisibilityInfo info) {
                        visible = info.visibleFraction > 0.5;
                        if (visible) {
                          if (kDebugMode) {
                            print('camera visible');
                          }
                        } else {
                          if (kDebugMode) {
                            print('camera not visible');
                          }
                        }
                      },
                      child: Column(
                        children: [
                          SizedBox(
                              width: double.infinity,
                              child: Center(
                                  child: Container(
                                      margin: const EdgeInsets.all(5),
                                      padding: const EdgeInsets.all(2),
                                      constraints: const BoxConstraints(maxWidth: 350, maxHeight: 300),
                                      color: Colors.green,
                                      child: _buildQrView(context)))),
                          historyWidget,
                          Expanded(child: detailWidget)
                        ],
                      ))
                  : SingleChildScrollView(
                      child: Column(
                        children: [historyWidget, detailWidget],
                      ),
                    ),
            ))));
  }
}
