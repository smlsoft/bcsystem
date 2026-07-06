import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:animated_icon/animated_icon.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedekds/model/product_model.dart';
import 'package:dedekds/utility/print_ticket.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:dedekds/bloc/order_temp_bloc.dart';
import 'package:dedekds/model/order_temp_model.dart';
import 'package:dedekds/scan_server_page.dart';
import 'package:flutter/material.dart';
import 'package:dedekds/global.dart' as global;
import 'package:dedekds/utility/util.dart' as util;
import 'package:dedekds/utility/api.dart' as api;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class KdsHomePage extends StatefulWidget {
  const KdsHomePage({super.key});

  @override
  State<KdsHomePage> createState() => _KdsHomePageState();
}

class _KdsHomePageState extends State<KdsHomePage> {
  late Timer timerScan;
  late Timer timerRefresh;
  List<OrderTempObjectBoxStruct> orderList = [];
  bool speechActive = false;
  bool warningCookVerySlow = true;
  int warningCookVerySlowCount = 0;
  bool showImage = false;
  double widgetWidth = 125;

  @override
  void initState() {
    super.initState();
    // ตรวจสอบการเชื่อมต่อกับ POS Terminal ทุกๆ 10 วินาที
    timerScan = Timer.periodic(const Duration(seconds: 9), (timer) async {
      util.pingTerminal();
      setState(() {});
    });
    // ตรวจสอบ Order ทุกๆ 10 วินาที
    timerRefresh = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (global.posTerminalConnected) {
        warningCookVerySlowCount++;
        if (warningCookVerySlowCount > (5 * 60)) {
          // เตือนรายการช้า
          warningCookVerySlow = true;
          warningCookVerySlowCount = 0;
        }
        refreshData();
        setState(() {});
      }
      speech();
    });
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    timerScan.cancel();
    timerRefresh.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> speech() async {
    if (speechActive == false) {
      speechActive = true;
      try {
        while (global.orderTextToSpeechList.isNotEmpty) {
          String word = global.orderTextToSpeechList[0];
          global.orderTextToSpeechList.removeAt(0);
          await global.speak(word);
        }
      } catch (e) {
        print(e);
      }
      speechActive = false;
    }
  }

  void refreshData() {
    print("refreshData");
    BlocProvider.of<OrderTempBloc>(context)
        .add(OrderTempGetData(kitchenId: global.posKitchenId));
  }

  Widget orderWidget(OrderTempObjectBoxStruct order, double widthWidget) {
    int calcSeconds = DateTime.now().difference(order.orderDateTime).inSeconds;
    int calcWaitMinutes = calcSeconds ~/ 60;
    int calcWaitSeconds = calcSeconds % 60;
    Color backgroundColor = Colors.green;
    if (calcSeconds >= global.cookingTimeSecond[0]) {
      // เตือน ระดับที่ 1
      backgroundColor = Colors.orange;
    }
    if (calcSeconds >= global.cookingTimeSecond[1]) {
      // เตือน ระดับที่ 2
      backgroundColor = Colors.red;
    }
    if (calcSeconds >= global.cookingTimeSecond[2]) {
      // เตือน ระดับที่ 3
      backgroundColor = Colors.purple;
    }
    if (order.kdsSuccess) {
      // เสร็จแล้ว
      backgroundColor = Colors.grey;
    }
    List<Widget> orderOptionListWidget = [];
    if (order.remark.trim().isNotEmpty) {
      orderOptionListWidget.add(
        Text(
          order.remark.trim(),
          style: const TextStyle(fontSize: 14, color: Colors.red),
        ),
      );
    }
    if (order.optionSelected.isNotEmpty) {
      List<ProductProcessOptionModel> options =
          (jsonDecode(order.optionSelected) as List)
              .map((data) => ProductProcessOptionModel.fromJson(data))
              .toList();
      for (var option in options) {
        for (var choice in option.choices) {
          if (choice.selected == true) {
            orderOptionListWidget.add(
              Text(
                global.getNameFromLanguage(choice.names, global.userLanguage),
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
            );
          }
        }
      }
    }

    return SizedBox(
      width: widthWidget,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.all(4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        onPressed: () async {
          // update สถานะ
          api.orderTempUpdateStatusByGuid(guid: order.orderGuid);
          refreshData();
          if (global.orderSendToPrinter) {
            var getOrder =
                await api.getOrderTempByGuidFromTerminal(guid: order.orderGuid);
            if (getOrder.kdsSuccess) {
              // ส่งไปปริ้น
              printOrderSuccess(order: getOrder);
            }
          }
        },
        child: Column(
          children: [
            Row(children: [
              Expanded(
                  child: Text(
                "${(order.deliveryNumber.isEmpty) ? "โต๊ ${order.orderId}" : "${global.getDeliveryName(code: order.deliveryCode)} : ${order.deliveryNumber}"} : ${DateFormat("HH:mm").format(order.orderDateTime)}",
                style: const TextStyle(fontSize: 12),
              )),
              Expanded(
                  child: (order.kdsSuccess == false)
                      ? Text(
                          "${calcWaitMinutes.toString().padLeft(2, '0')}:${calcWaitSeconds.toString().padLeft(2, '0')}",
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        )
                      : const Text(
                          "เสร็จ",
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12),
                        )),
            ]),
            (order.orderQty - order.cancelQty == 0)
                ? Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.red,
                    ),
                    child: const FittedBox(
                        child: Text(
                      "ยกเลิกทั้งหมด",
                      style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    )),
                  )
                : Container(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.imageUri.isEmpty || showImage == false)
                      SizedBox(
                        height: 20,
                      ),
                    Row(children: [
                      Expanded(
                          child: Text(
                        global.getNameFromJsonLanguage(
                            order.names, global.userLanguage),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      )),
                      Text(
                        global.moneyFormat
                            .format(order.orderQty - order.cancelQty),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ]),
                    if (order.imageUri.isEmpty || showImage == false)
                      SizedBox(
                        height: 20,
                      ),
                    // กรณีมีรายการยกเลิก (จำนวนไม่ตรงกับสั่งครั้งแรก)
                    if (order.cancelQty != 0)
                      Column(children: [
                        Row(children: [
                          const Expanded(
                              child: Text(
                            "จำนวนสั่ง",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          )),
                          Text(
                            global.moneyFormat
                                .format(order.orderQty - order.cancelQty),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                        ]),
                        Row(children: [
                          const Expanded(
                              child: Text(
                            "จำนวนยกเลิก",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red),
                          )),
                          Text(
                            global.moneyFormat.format(order.cancelQty),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red),
                          ),
                        ]),
                      ]),
                    Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: orderOptionListWidget),
                    (order.imageUri.isNotEmpty && showImage)
                        ? Container(
                            margin: const EdgeInsets.only(top: 10),
                            child: CachedNetworkImage(
                              imageUrl: order.imageUri,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          )
                        : Container(),
                    if (order.takeAway == true)
                      Center(
                          child: Image.asset(
                        "assets/takeaway.gif",
                      )),
                  ]),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderTempBloc, OrderTempState>(
        listener: (context, state) {
          if (state is OrderTempGetDataSuccess) {
            orderList = state.result;
            if (global.orderTextToSpeech /*&& Platform.isAndroid*/) {
              // ตัดเอาเฉพาะที่เพิ่มมาใหม่ เพื่อไปอ่านออกเสียง
              DateTime orderCompareTime = global.orderTextToSpeechLastTime;
              for (var order in orderList) {
                if (orderCompareTime.compareTo(order.lastUpdateDateTime) < 0) {
                  global.orderTextToSpeechLastTime = order.lastUpdateDateTime;
                  if (global.orderTextToSpeechList.isEmpty) {
                    global.orderTextToSpeechList.add("กรุณาตั้งใจฟัง");
                    global.orderTextToSpeechList
                        .add("เตือน ${global.posKitchenName} มีคำสั่งใหม่");
                  }
                  String productWord = "";
                  if (order.takeAway == true) {
                    productWord += "รายการนี้สั่งกลับบ้าน";
                  }
                  if (order.cancelQty == 0) {
                    // รายการมาใหม่
                    productWord +=
                        "${global.getNameFromJsonLanguage(order.names, global.userLanguage)} จำนวน ${global.moneyFormat.format(order.orderQty - order.cancelQty)}${global.getNameFromJsonLanguage(order.unitName, global.userLanguage)}";
                    if (order.remark.trim().isNotEmpty) {
                      productWord += "หมายเหตุ ${order.remark.trim()}";
                    }
                    global.orderTextToSpeechList.add(productWord);
                    if (order.optionSelected.isNotEmpty) {
                      List<ProductProcessOptionModel> options =
                          (jsonDecode(order.optionSelected) as List)
                              .map((data) =>
                                  ProductProcessOptionModel.fromJson(data))
                              .toList();
                      for (var option in options) {
                        for (var choice in option.choices) {
                          if (choice.selected == true) {
                            global.orderTextToSpeechList.add(
                                global.getNameFromLanguage(
                                    choice.names, global.userLanguage));
                          }
                        }
                      }
                    }
                  } else {
                    // รายการยกเลิก
                    productWord +=
                        "ยกเลิก ${global.getNameFromJsonLanguage(order.names, global.userLanguage)} จำนวนยกเลิกรวม ${global.moneyFormat.format(order.cancelQty)}${global.getNameFromJsonLanguage(order.unitName, global.userLanguage)}";
                    global.orderTextToSpeechList.add(productWord);
                  }
                }
              }
              // เตือนอาหารช้า
              if (warningCookVerySlow == true) {
                warningCookVerySlow = false;
                double countSlow = 0;
                int maxMinutes = 0;
                for (var order in orderList) {
                  if (order.kdsSuccess == false) {
                    int calcSeconds = DateTime.now()
                        .difference(order.orderDateTime)
                        .inSeconds;
                    if (calcSeconds >= global.cookingTimeSecond[2]) {
                      // เตือน ระดับที่ 3
                      countSlow += (order.orderQty - order.cancelQty);
                      int calcMinutes = DateTime.now()
                          .difference(order.orderDateTime)
                          .inMinutes;
                      if (calcMinutes > maxMinutes) {
                        maxMinutes = calcMinutes;
                      }
                    }
                  }
                }
                if (countSlow > 0) {
                  global.orderTextToSpeechList
                      .add("เตือน${global.posKitchenName} มีรายการช้า");
                  global.orderTextToSpeechList.add(
                      "รายการช้าทั้งหมด ${global.moneyFormat.format(countSlow)} รายการ");
                  global.orderTextToSpeechList.add(
                      "รายการที่ช้าที่สุด ${global.moneyFormat.format(maxMinutes.toDouble())} นาที");
                  int randomIndex = Random().nextInt(global.warningList.length);
                  global.orderTextToSpeechList
                      .add(" ${global.warningList[randomIndex]}");
                }
              }
            }
            setState(() {});
            BlocProvider.of<OrderTempBloc>(context)
                .add(OrderTempGetDataFinish());
          }
        },
        child: SafeArea(
            child: Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  toolbarHeight: 40,
                  backgroundColor: (global.posTerminalConnected)
                      ? Colors.blue[900]
                      : Colors.red[900],
                  title: FittedBox(
                      child: Text(
                          "DEDE KDS : ${global.posTerminalDeviceId} : ${(global.posTerminalConnected) ? global.posTerminalDeviceName : "ไม่พบเครื่อง POS Terminal"} : ${global.posKitchenId} : ${global.posKitchenName}")),
                  actions: [
                    Container(
                        padding: const EdgeInsets.only(left: 4, right: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[900],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.group_work, color: Colors.grey),
                            IconButton(
                                onPressed: () {
                                  widgetWidth -= 25;
                                  if (widgetWidth < 100) {
                                    widgetWidth = 100;
                                  }
                                  setState(() {});
                                },
                                icon: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                )),
                            Text(
                              global.moneyFormat.format(widgetWidth),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                            IconButton(
                                onPressed: () {
                                  widgetWidth += 25;
                                  if (widgetWidth > 300) {
                                    widgetWidth = 300;
                                  }
                                  setState(() {});
                                },
                                icon:
                                    const Icon(Icons.add, color: Colors.white)),
                          ],
                        )),
                    SizedBox(width: 10),
                    (global.orderTextToSpeech)
                        ? Container(
                            padding: const EdgeInsets.only(left: 4, right: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[900],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.volume_up, color: Colors.grey),
                                IconButton(
                                    onPressed: () {
                                      global.flutterTtsRate -= 0.05;
                                      if (global.flutterTtsRate < 0) {
                                        global.flutterTtsRate = 0;
                                      }
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                    )),
                                Text(
                                  global.moneyFormat
                                      .format(global.flutterTtsRate),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                ),
                                IconButton(
                                    onPressed: () {
                                      global.flutterTtsRate += 0.05;
                                      if (global.flutterTtsRate > 1) {
                                        global.flutterTtsRate = 1;
                                      }
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.add,
                                        color: Colors.white)),
                              ],
                            ))
                        : Container(),
                    IconButton(
                      onPressed: () {
                        global.orderTextToSpeech = !global.orderTextToSpeech;
                        global.saveServerData();
                        setState(() {});
                      },
                      icon: (global.orderTextToSpeech)
                          ? const Icon(Icons.volume_up)
                          : const Icon(Icons.volume_off),
                    ),
                    IconButton(
                      onPressed: () {
                        showImage = !showImage;
                        setState(() {});
                      },
                      icon: (showImage)
                          ? const Icon(Icons.image)
                          : const Icon(Icons.image_not_supported),
                    ),
                    IconButton(
                      onPressed: () {
                        global.orderSendToPrinter = !global.orderSendToPrinter;
                        global.saveServerData();
                        setState(() {});
                      },
                      icon: (global.orderSendToPrinter)
                          ? const Icon(Icons.print)
                          : const Icon(Icons.print_disabled),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () async {
                        await showDialog(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                                  scrollable: true,
                                  title: const Text("ตั้งค่า"),
                                  content: Column(
                                    children: [
                                      ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushNamedAndRemoveUntil(
                                                context,
                                                '/scan_server',
                                                (route) => false);
                                          },
                                          child: const Text(
                                              "ค้นหาเครื่อง POS Terminal")),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushNamedAndRemoveUntil(
                                                context,
                                                '/scan_printer',
                                                (route) => false);
                                          },
                                          child:
                                              const Text("ค้นหาเครื่องพิมพ์")),
                                    ],
                                  ),
                                ));
                      },
                    ),
                  ],
                ),
                body: (orderList.isEmpty)
                    ? const Center(
                        child: Text("ยังไม่มี Order",
                            style: TextStyle(
                                fontSize: 60,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)))
                    : Container(
                        color: Colors.black,
                        padding: const EdgeInsets.only(top: 10),
                        child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                              },
                            ),
                            child: SingleChildScrollView(
                              child: LayoutBuilder(
                                builder: (BuildContext context,
                                    BoxConstraints constraints) {
                                  double spacing = 4;
                                  double maxWidth = constraints.maxWidth;
                                  int calcCount =
                                      (maxWidth / widgetWidth).floor();
                                  double widthWidget =
                                      (maxWidth - (calcCount * spacing)) /
                                          calcCount;
                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: orderList.map((e) {
                                      return orderWidget(e, widthWidget);
                                    }).toList(),
                                  );
                                },
                              ),
                            ))))));
  }
}
