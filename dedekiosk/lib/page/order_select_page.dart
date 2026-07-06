import 'package:dedekiosk/order/order_animation_one/order_animation_one_cart_page.dart';
import 'package:dedekiosk/order/order_save.dart';
import 'package:dedekiosk/order/pay_page.dart';
import 'package:dedekiosk/page/order_online_page.dart';
import 'package:dedekiosk/page/order_table_page.dart';
import 'package:dedekiosk/util/print_queue.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/order/services/background_task_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

class OrderSelectPage extends StatefulWidget {
  const OrderSelectPage({super.key});

  @override
  OrderSelectPageState createState() => OrderSelectPageState();
}

class OrderSelectPageState extends State<OrderSelectPage> {
  String oldQrCode = "";
  String orderOnlineQrCode = "";
  late Timer checkQrCodeTimer;
  bool checkOrderQrCode = false;

  // Helper function to convert hex string to Color
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  // Build Order Here text widget with optional gradient
  Widget _buildOrderHereText() {
    final text = global.deviceConfig.orderHereText;
    final color1 = _hexToColor(global.deviceConfig.orderHereTextColor);
    final color2Hex = global.deviceConfig.orderHereTextColor2;
    final shadowColor = _hexToColor(global.deviceConfig.orderHereShadowColor);

    final textWidget = Text(
      text,
      style: TextStyle(
        fontFamily: 'Kanit',
        fontSize: 250,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: Colors.white,
        shadows: [
          Shadow(
            offset: const Offset(4, 4),
            blurRadius: 8,
            color: shadowColor,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );

    if (color2Hex.isEmpty) {
      // Single color
      return Text(
        text,
        style: TextStyle(
          fontFamily: 'Kanit',
          fontSize: 250,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: color1,
          shadows: [
            Shadow(
              offset: const Offset(4, 4),
              blurRadius: 8,
              color: shadowColor,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      );
    } else {
      // Gradient
      final color2 = _hexToColor(color2Hex);
      return ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
        child: textWidget,
      );
    }
  }

  void openPageOrder() {
    if (global.orderType == 0) {
      global.textToSpeech(global.findLanguage(
          code: "speech_order_type_eat_at_restaurant",
          languageCode: global.languageForCustomer));
    } else {
      global.textToSpeech(global.findLanguage(
          code: "speech_order_type_take_away",
          languageCode: global.languageForCustomer));
    }
    // ไปหน้า order_animation_one ตรงๆ (ไม่ต้องไป select_member)
    // ถ้าเปิด useMember จะแสดง FloatingMemberQrWidget ที่หน้า order
    Navigator.pushNamedAndRemoveUntil(
        context, "/order_animation_one", (Route<dynamic> route) => false);
  }

  void openPageOrderSaleChannel() {
    if (global.orderType == 0) {
      global.textToSpeech(global.findLanguage(
          code: "speech_order_type_eat_at_restaurant",
          languageCode: global.languageForCustomer));
    } else {
      global.textToSpeech(global.findLanguage(
          code: "speech_order_type_take_away",
          languageCode: global.languageForCustomer));
    }
    Navigator.pushNamedAndRemoveUntil(
        context, "/order_animation_one", (Route<dynamic> route) => false);
  }

  TextStyle textStyleBorderWhite = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        blurRadius: 2.0,
        color: Colors.white,
        offset: Offset(1.0, 1.0),
      ),
      Shadow(
        blurRadius: 2.0,
        color: Colors.white,
        offset: Offset(-1.0, 1.0),
      ),
      Shadow(
        blurRadius: 2.0,
        color: Colors.white,
        offset: Offset(1.0, -1.0),
      ),
      Shadow(
        blurRadius: 2.0,
        color: Colors.white,
        offset: Offset(-1.0, -1.0),
      ),
    ],
  );

  String createQrcode(String qrcode) {
    OrderOnlineParameterModel orderOnline = OrderOnlineParameterModel(
        shopid: global.deviceConfig.shopId, table: "", qrcode: qrcode);
    var base64 =
        "https://dedefoodorder.web.app/?q=${base64Encode(utf8.encode(jsonEncode(orderOnline.toJson())))}";
    return (global.deviceConfig.shopId.isNotEmpty) ? base64 : "";
  }

  void textToSpeech() {
    global.textToSpeech(global.findLanguage(
        code: "speech_order_type", languageCode: global.languageForCustomer));
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    // ===== ช่องโหว่ B: หน่วงการ regenerate orderId ถ้า background task ยังทำงาน =====
    // เมื่อกลับมาหน้านี้หลังจ่ายเงิน ถ้า regenerate orderId/removeCalcQty ทันที
    // อาจกระทบ background saveTransaction ของ order เดิมที่ยังอ้าง orderId เดิมอยู่
    // จึงรอจนกว่า task ทั้งหมดจะเสร็จก่อนค่อย regenerate
    if (BackgroundTaskManager().activeTaskCount == 0) {
      global.orderId = const Uuid().v4();
      global.removeCalcQty();
    } else {
      // ฟังจนกว่า task จะเสร็จ แล้วค่อย regenerate
      BackgroundTaskManager()
          .activeTaskCountNotifier
          .addListener(_onBackgroundTasksDone);
    }
    // global.startSyncTransaction();
    textToSpeech();
    api.reloadProductProcessFromServer().then((_) {
      //reloadProductList();
    });
    if (global.deviceConfig.showQrCodeOrderOnline) {
      checkQrCodeTimer =
          Timer.periodic(const Duration(seconds: 5), (Timer t) async {
        try {
          if (global.deviceConfig.shopId.isNotEmpty &&
              checkOrderQrCode == false) {
            String query =
                "select qrcode from ${global.clickHouseDatabaseName}.ordertempqrcode where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and status=0";
            checkOrderQrCode = true;
            // ตรวจสอบ Qrcode สั่งอาหาร
            var value = await api.clickHouseSelect(query);
            ResponseDataModel responseData = ResponseDataModel.fromJson(value);
            if (responseData.data.isNotEmpty) {
              // กรณี Qrcode ยังไม่ได้ใช้
              String qrcode = responseData.data[0]["qrcode"];
              if (oldQrCode != qrcode) {
                oldQrCode = qrcode;
                orderOnlineQrCode = createQrcode(qrcode);
                setState(() {});
              }
            } else {
              // กรณี Qrcode ใช้แล้ว สร้าง Qrcode ใหม่ และเป็นเครื่องที่เชื่อมกับ Order Online
              oldQrCode = const Uuid().v4();
              await api.clickHouseExecute(
                  "insert into ${global.clickHouseDatabaseName}.ordertempqrcode (shopid,branchid,qrcode,status) values ('${global.deviceConfig.shopId}', '${global.deviceConfig.branchId}', '${oldQrCode}',0)");
              orderOnlineQrCode = createQrcode(oldQrCode);
              setState(() {});
            }
            checkOrderQrCode = false;
          }
        } catch (e, s) {
          if (kDebugMode) {
            print(e);
            print(s);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    try {
      checkQrCodeTimer.cancel();
    } catch (_) {}
    // ถอน listener เมื่อออกจากหน้า (กัน leak)
    BackgroundTaskManager()
        .activeTaskCountNotifier
        .removeListener(_onBackgroundTasksDone);
    super.dispose();
  }

  /// เรียกเมื่อ background task ทั้งหมดเสร็จ — ค่อย regenerate orderId/removeCalcQty
  /// ที่หน่วงไว้ตอน initState (ช่องโหว่ B)
  void _onBackgroundTasksDone() {
    if (BackgroundTaskManager().activeTaskCount == 0 && mounted) {
      BackgroundTaskManager()
          .activeTaskCountNotifier
          .removeListener(_onBackgroundTasksDone);
      global.orderId = const Uuid().v4();
      global.removeCalcQty();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget qrCodeWidget = (global.deviceConfig.showQrCodeOrderOnline)
        ? Container(
            height: 200,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(children: [
              Expanded(
                  child: QrImageView(
                padding: const EdgeInsets.all(8),
                data: "$orderOnlineQrCode&openExternalBrowser=1",
              )),
              const SizedBox(height: 8),
              Text(
                global.language("scan_for_order"),
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600),
              ),
              Text(
                global.language("your_mobile_phone"),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              )
            ]))
        : Container();

    return SafeArea(
        child: Scaffold(
            backgroundColor: Colors.grey.shade200,
            body: BarcodeKeyboardListener(
              bufferDuration: const Duration(milliseconds: 200),
              onBarcodeScanned: (barcode) async {
                await global.updateServedQty(
                    orderDetailGuid: barcode, reload: () {});
              },
              child: Stack(
                children: [
                  // Background Image - Full Screen
                  Positioned.fill(
                    child: (global.shopProfile?.orderstation.backgroundurl !=
                                null &&
                            global.shopProfile!.orderstation.backgroundurl
                                .isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl:
                                global.shopProfile!.orderstation.backgroundurl,
                            fit: BoxFit.fill,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/bgkiosk.jpg',
                              fit: BoxFit.fill,
                            ),
                          )
                        : Image.asset(
                            'assets/images/bgkiosk.jpg',
                            fit: BoxFit.fill,
                          ),
                  ),
                  Column(
                    children: [
                      // ช่องว่างด้านบน (10% ของหน้าจอ)
                      Spacer(flex: 8),

                      // ส่วนบน: Order Here! (20% ของหน้าจอ) - Hide on mobile
                      if (MediaQuery.of(context).size.width > 600)
                        Expanded(
                          flex: 30,
                          child: Center(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                child: _buildOrderHereText(),
                              ),
                            ),
                          ),
                        ),

                      // ส่วนกลาง: ปุ่มเลือกประเภท (60% ของหน้าจอ)
                      Expanded(
                        flex: 60,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Main Order Selection Section
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.8,
                                      maxHeight: ((global.deviceConfig
                                              .showQrCodeOrderOnline))
                                          ? 350
                                          : 300),
                                  child: Column(
                                    children: [
                                      // Title
                                      // Container(
                                      //   margin: const EdgeInsets.only(bottom: 24),
                                      //   child: Text(
                                      //     global.language("order_select_type"),
                                      //     style: const TextStyle(
                                      //       fontSize: 28,
                                      //       fontWeight: FontWeight.w700,
                                      //       color: Color(0xFF1F2937),
                                      //     ),
                                      //     textAlign: TextAlign.center,
                                      //   ),
                                      // ),                                      // Order Type Buttons - Row on desktop, Column on mobile
                                      Expanded(
                                        child:
                                            MediaQuery.of(context).size.width >
                                                    600
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      // Eat Here Button
                                                      if (global.deviceConfig
                                                          .useOrderEatAtTheRestaurant)
                                                        Expanded(
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(7),
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              child: InkWell(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                onTap:
                                                                    () async {
                                                                  global.saleChannelCode =
                                                                      "";
                                                                  global.saleChannelName =
                                                                      "";
                                                                  global.orderType =
                                                                      0;
                                                                  global.priceIndex =
                                                                      1;
                                                                  global.isTakeAway =
                                                                      0;
                                                                  global.tableNumberSelected = OrderTempTableModel(
                                                                      ordertagnumber:
                                                                          "",
                                                                      totalamount:
                                                                          0.0);
                                                                  if (global
                                                                          .deviceConfig
                                                                          .systemCondition ==
                                                                      1) {
                                                                    // Eat first, pay later
                                                                    global.tableNumberSelected =
                                                                        await Navigator
                                                                            .push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              const OrderTablePage()),
                                                                    );
                                                                    if (global
                                                                        .tableNumberSelected
                                                                        .ordertagnumber
                                                                        .isNotEmpty) {
                                                                      openPageOrder();
                                                                    }
                                                                  } else {
                                                                    // Pay first, eat later
                                                                    openPageOrder();
                                                                  }
                                                                },
                                                                child:
                                                                    Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .white,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10),
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.08),
                                                                        blurRadius:
                                                                            24,
                                                                        offset: const Offset(
                                                                            0,
                                                                            8),
                                                                        spreadRadius:
                                                                            0,
                                                                      ),
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.04),
                                                                        blurRadius:
                                                                            8,
                                                                        offset: const Offset(
                                                                            0,
                                                                            2),
                                                                        spreadRadius:
                                                                            0,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            18),
                                                                    child:
                                                                        Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Expanded(
                                                                          flex:
                                                                              3,
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                const EdgeInsets.all(5),
                                                                            child:
                                                                                Image.asset(
                                                                              "assets/images/eathere.jpg",
                                                                              fit: BoxFit.cover,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                5),
                                                                        Text(
                                                                          global
                                                                              .language("order_eat_here"),
                                                                          style:
                                                                              const TextStyle(
                                                                            fontFamily:
                                                                                'Kanit',
                                                                            fontSize:
                                                                                24,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                            color:
                                                                                Color(0xFF1F2937),
                                                                            letterSpacing:
                                                                                -0.5,
                                                                          ),
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          maxLines:
                                                                              2,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                      // Take Away Button
                                                      if (global.deviceConfig
                                                          .useOrderTakeAway)
                                                        Expanded(
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(7),
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              child: InkWell(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                onTap:
                                                                    () async {
                                                                  global.saleChannelCode =
                                                                      "";
                                                                  global.saleChannelName =
                                                                      "";
                                                                  global.orderType =
                                                                      1;
                                                                  global.isTakeAway =
                                                                      1;
                                                                  global.priceIndex =
                                                                      1;
                                                                  global.tableNumberSelected = OrderTempTableModel(
                                                                      ordertagnumber:
                                                                          "",
                                                                      totalamount:
                                                                          0.0);
                                                                  if (global
                                                                          .deviceConfig
                                                                          .systemCondition ==
                                                                      1) {
                                                                    // Eat first, pay later
                                                                    global.tableNumberSelected = await Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: (context) =>
                                                                                const OrderTablePage()));
                                                                    if (global
                                                                        .tableNumberSelected
                                                                        .ordertagnumber
                                                                        .isNotEmpty) {
                                                                      openPageOrder();
                                                                    }
                                                                  } else {
                                                                    // Pay first, eat later
                                                                    openPageOrder();
                                                                  }
                                                                },
                                                                child:
                                                                    Container(
                                                                  height: double
                                                                      .infinity,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .white,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10),
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.08),
                                                                        blurRadius:
                                                                            24,
                                                                        offset: const Offset(
                                                                            0,
                                                                            8),
                                                                        spreadRadius:
                                                                            0,
                                                                      ),
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.04),
                                                                        blurRadius:
                                                                            8,
                                                                        offset: const Offset(
                                                                            0,
                                                                            2),
                                                                        spreadRadius:
                                                                            0,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            18),
                                                                    child:
                                                                        Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Expanded(
                                                                          flex:
                                                                              3,
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                const EdgeInsets.all(5),
                                                                            child:
                                                                                Image.asset(
                                                                              "assets/images/takeaway.jpg",
                                                                              fit: BoxFit.cover,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                5),
                                                                        Text(
                                                                          global
                                                                              .language("order_take_away"),
                                                                          style:
                                                                              const TextStyle(
                                                                            fontFamily:
                                                                                'Kanit',
                                                                            fontSize:
                                                                                24,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                            color:
                                                                                Color(0xFF1F2937),
                                                                            letterSpacing:
                                                                                -0.5,
                                                                          ),
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          maxLines:
                                                                              2,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                      // QR Code for landscape
                                                      // if (MediaQuery.of(context).orientation == Orientation.landscape) SizedBox(width: 220, child: qrCodeWidget),
                                                    ],
                                                  )
                                                // Mobile Layout - Column
                                                : Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      // Eat Here Button
                                                      if (global.deviceConfig
                                                          .useOrderEatAtTheRestaurant)
                                                        Expanded(
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(7),
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              child: InkWell(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                onTap:
                                                                    () async {
                                                                  global.saleChannelCode =
                                                                      "";
                                                                  global.saleChannelName =
                                                                      "";
                                                                  global.orderType =
                                                                      0;
                                                                  global.priceIndex =
                                                                      1;
                                                                  global.isTakeAway =
                                                                      0;
                                                                  global.tableNumberSelected = OrderTempTableModel(
                                                                      ordertagnumber:
                                                                          "",
                                                                      totalamount:
                                                                          0.0);
                                                                  if (global
                                                                          .deviceConfig
                                                                          .systemCondition ==
                                                                      1) {
                                                                    // Eat first, pay later
                                                                    global.tableNumberSelected =
                                                                        await Navigator
                                                                            .push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              const OrderTablePage()),
                                                                    );
                                                                    if (global
                                                                        .tableNumberSelected
                                                                        .ordertagnumber
                                                                        .isNotEmpty) {
                                                                      openPageOrder();
                                                                    }
                                                                  } else {
                                                                    // Pay first, eat later
                                                                    openPageOrder();
                                                                  }
                                                                },
                                                                child:
                                                                    Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .white,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10),
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.08),
                                                                        blurRadius:
                                                                            24,
                                                                        offset: const Offset(
                                                                            0,
                                                                            8),
                                                                        spreadRadius:
                                                                            0,
                                                                      ),
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.04),
                                                                        blurRadius:
                                                                            8,
                                                                        offset: const Offset(
                                                                            0,
                                                                            2),
                                                                        spreadRadius:
                                                                            0,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            18),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Expanded(
                                                                          flex:
                                                                              2,
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                const EdgeInsets.all(5),
                                                                            child:
                                                                                Image.asset(
                                                                              "assets/images/eathere.jpg",
                                                                              fit: BoxFit.contain,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                10),
                                                                        Expanded(
                                                                          flex:
                                                                              3,
                                                                          child:
                                                                              Text(
                                                                            global.language("order_eat_here"),
                                                                            style:
                                                                                const TextStyle(
                                                                              fontFamily: 'Kanit',
                                                                              fontSize: 25,
                                                                              fontWeight: FontWeight.w700,
                                                                              color: Color(0xFF1F2937),
                                                                              letterSpacing: -0.5,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            maxLines:
                                                                                2,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                      // Take Away Button
                                                      if (global.deviceConfig
                                                          .useOrderTakeAway)
                                                        Expanded(
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(7),
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              child: InkWell(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                onTap:
                                                                    () async {
                                                                  global.saleChannelCode =
                                                                      "";
                                                                  global.saleChannelName =
                                                                      "";
                                                                  global.orderType =
                                                                      1;
                                                                  global.isTakeAway =
                                                                      1;
                                                                  global.priceIndex =
                                                                      1;
                                                                  global.tableNumberSelected = OrderTempTableModel(
                                                                      ordertagnumber:
                                                                          "",
                                                                      totalamount:
                                                                          0.0);
                                                                  if (global
                                                                          .deviceConfig
                                                                          .systemCondition ==
                                                                      1) {
                                                                    // Eat first, pay later
                                                                    global.tableNumberSelected = await Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: (context) =>
                                                                                const OrderTablePage()));
                                                                    if (global
                                                                        .tableNumberSelected
                                                                        .ordertagnumber
                                                                        .isNotEmpty) {
                                                                      openPageOrder();
                                                                    }
                                                                  } else {
                                                                    // Pay first, eat later
                                                                    openPageOrder();
                                                                  }
                                                                },
                                                                child:
                                                                    Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .white,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10),
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.08),
                                                                        blurRadius:
                                                                            24,
                                                                        offset: const Offset(
                                                                            0,
                                                                            8),
                                                                        spreadRadius:
                                                                            0,
                                                                      ),
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.04),
                                                                        blurRadius:
                                                                            8,
                                                                        offset: const Offset(
                                                                            0,
                                                                            2),
                                                                        spreadRadius:
                                                                            0,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            18),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Expanded(
                                                                          flex:
                                                                              2,
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                const EdgeInsets.all(5),
                                                                            child:
                                                                                Image.asset(
                                                                              "assets/images/takeaway.jpg",
                                                                              fit: BoxFit.contain,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                10),
                                                                        Expanded(
                                                                          flex:
                                                                              3,
                                                                          child:
                                                                              Text(
                                                                            global.language("order_take_away"),
                                                                            style:
                                                                                const TextStyle(
                                                                              fontFamily: 'Kanit',
                                                                              fontSize: 25,
                                                                              fontWeight: FontWeight.w700,
                                                                              color: Color(0xFF1F2937),
                                                                              letterSpacing: -0.5,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            maxLines:
                                                                                2,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                      ),

                                      // QR Code for portrait
                                      if (MediaQuery.of(context).orientation ==
                                          Orientation.portrait)
                                        qrCodeWidget,
                                    ],
                                  ),
                                ),

                                // Staff Functions Section (Admin only)
                                if (global.deviceConfig.machineCondition == 0)
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    padding: const EdgeInsets.all(20),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Sale Channels Section
                                        if (global.shopProfile != null &&
                                            global.shopProfile!.orderstation
                                                .salechannels!.isNotEmpty)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                              0xFF38B2AC)
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: const Icon(
                                                      Icons.delivery_dining,
                                                      color: Color(0xFF38B2AC),
                                                      size: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    global.language(
                                                        "sales_channel"),
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF2D3748),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  for (var i = 0;
                                                      i <
                                                          global
                                                              .shopProfile!
                                                              .orderstation
                                                              .salechannels!
                                                              .length;
                                                      i++) ...[
                                                    Expanded(
                                                      child: _buildStaffButton(
                                                        icon: Icons
                                                            .delivery_dining,
                                                        title: global
                                                            .shopProfile!
                                                            .orderstation
                                                            .salechannels![i]
                                                            .name,
                                                        imageUrl: global
                                                            .shopProfile!
                                                            .orderstation
                                                            .salechannels![i]
                                                            .imageuri,
                                                        color: const Color(
                                                            0xFF38B2AC),
                                                        onPressed: () {
                                                          global.isTakeAway = 1;
                                                          global.orderType = 1;
                                                          global.priceIndex =
                                                              global
                                                                  .shopProfile!
                                                                  .orderstation
                                                                  .salechannels![
                                                                      i]
                                                                  .price;
                                                          global.saleChannelCode =
                                                              global
                                                                  .shopProfile!
                                                                  .orderstation
                                                                  .salechannels![
                                                                      i]
                                                                  .code;
                                                          global.saleChannelName =
                                                              global
                                                                  .shopProfile!
                                                                  .orderstation
                                                                  .salechannels![
                                                                      i]
                                                                  .name;
                                                          global.saleChannelgptype =
                                                              global
                                                                  .shopProfile!
                                                                  .orderstation
                                                                  .salechannels![
                                                                      i]
                                                                  .gptype;
                                                          global.saleChannelgp =
                                                              global
                                                                  .shopProfile!
                                                                  .orderstation
                                                                  .salechannels![
                                                                      i]
                                                                  .gp;
                                                          global.memberPinCode =
                                                              "";
                                                          global.memberCode =
                                                              "";
                                                          global.custNames = [];
                                                          global.memberPicture =
                                                              "";
                                                          global.memberEmail =
                                                              "";
                                                          global.isMember =
                                                              false;
                                                          openPageOrderSaleChannel();
                                                        },
                                                      ),
                                                    ),
                                                    if (i <
                                                        global
                                                                .shopProfile!
                                                                .orderstation
                                                                .salechannels!
                                                                .length -
                                                            1)
                                                      const SizedBox(width: 12),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                          ),

                                        // Management Functions Section
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4299E1)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.admin_panel_settings,
                                                color: Color(0xFF4299E1),
                                                size: 17,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              global
                                                  .language("management_tools"),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2D3748),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // const SizedBox(height: 12),
                                        // // Management Functions - Row 0: Order Online
                                        // if (global.orderTagNumbers.isNotEmpty && global.deviceConfig.orderOnlineCondition) ...[
                                        //   Row(
                                        //     children: [
                                        //       Expanded(
                                        //         child: _buildStaffButton(
                                        //           icon: Icons.qr_code_2,
                                        //           title: "Order Online",
                                        //           color: const Color(0xFF6366F1),
                                        //           onPressed: () {
                                        //             Navigator.pushNamed(context, '/order_online');
                                        //           },
                                        //         ),
                                        //       ),
                                        //     ],
                                        //   ),
                                        //   const SizedBox(height: 8),
                                        // ],
                                        // Management Functions - Row 1: Core Functions
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildStaffButton(
                                                icon: Icons.edit_note,
                                                title: global.language(
                                                    "product_management"),
                                                color: const Color(0xFF4299E1),
                                                onPressed: () {
                                                  global.orderType = 5;
                                                  global.priceIndex = 1;
                                                  openPageOrder();
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildStaffButton(
                                                icon: Icons.inventory_2,
                                                title: global
                                                    .language("adjust_stock"),
                                                color: const Color(0xFF9F7AEA),
                                                onPressed: () {
                                                  global.orderType = 6;
                                                  global.priceIndex = 1;
                                                  openPageOrder();
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Management Functions - Row 2: Service Functions
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildStaffButton(
                                                icon:
                                                    Icons.room_service_outlined,
                                                title: global
                                                    .language("serve_food"),
                                                color: const Color(0xFF48BB78),
                                                onPressed: () {
                                                  Navigator.pushNamedAndRemoveUntil(
                                                      context,
                                                      "/order_served_by_waiter",
                                                      (Route<dynamic> route) =>
                                                          false);
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildStaffButton(
                                                icon: Icons.monitor_outlined,
                                                title: global
                                                    .language("kitchen_screen"),
                                                color: const Color(0xFFED8936),
                                                onPressed: () {
                                                  Navigator
                                                      .pushNamedAndRemoveUntil(
                                                          context,
                                                          "/kds",
                                                          (Route<dynamic>
                                                                  route) =>
                                                              false);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Management Functions - Row 3: Copy Print Queue & Pending Kitchen Print
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildStaffButton(
                                                icon: Icons.content_copy,
                                                title: global.language(
                                                    "copy_print_queue"),
                                                color: const Color(0xFF6366F1),
                                                onPressed: () {
                                                  Navigator.pushNamed(context,
                                                      "/copy_print_queue");
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // รายการพิมพ์ครัวค้าง
                                            Expanded(
                                              child: _buildStaffButton(
                                                icon: Icons.print_disabled,
                                                title: "พิมพ์ครัวค้าง",
                                                color: const Color(0xFFE53E3E),
                                                onPressed: () {
                                                  _showPendingKitchenPrintDialog();
                                                },
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Cashier: รับชำระจาก QR (staff เท่านั้น)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(top: 16),
                                          width: double.infinity,
                                          child: _buildStaffButton(
                                            icon: Icons.receipt_long,
                                            title: "รับชำระจาก QR",
                                            color: const Color(0xFFDD6B20),
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                  context, '/cashier_scan');
                                            },
                                          ),
                                        ),

                                        // Payment Button for Eat First Pay Later System
                                        if (global
                                                .deviceConfig.systemCondition ==
                                            1)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 16),
                                            width: double.infinity,
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                onTap: () async {
                                                  global.tableNumberSelected =
                                                      await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const OrderTablePage()),
                                                  );
                                                  if (global
                                                      .tableNumberSelected
                                                      .ordertagnumber
                                                      .isNotEmpty) {
                                                    if (context.mounted) {
                                                      if (global
                                                              .tableNumberSelected
                                                              .totalamount ==
                                                          0) {
                                                        await showDialog(
                                                          context: context,
                                                          builder: (BuildContext
                                                                  context) =>
                                                              AlertDialog(
                                                            title: Text(
                                                                global.language(
                                                                    "warning")),
                                                            content: Text(
                                                                global.language(
                                                                    "no_order")),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                                child: Text(global
                                                                    .language(
                                                                        "ok")),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      } else {
                                                        await Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const OrderAnimationOneCartPage(
                                                                          barcode:
                                                                              "",
                                                                          mode:
                                                                              9,
                                                                        )));
                                                      }
                                                    }
                                                  }
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                      colors: [
                                                        Color(0xFFE8A87C),
                                                        Color(0xFFD27D2D)
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFFE8A87C)
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                        Icons.payment,
                                                        color: Colors.white,
                                                        size: 24,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        global.language(
                                                            "payment"),
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Language Selection Section
                      if (global.deviceConfig.machineCondition == 1)
                        Container(
                          margin: const EdgeInsets.only(bottom: 30),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              for (var index = 0;
                                  index < global.countryNames.length;
                                  index++)
                                InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: () {
                                    global.languageForCustomer =
                                        global.countryCodes[index];
                                    global.languageSelect(
                                        global.languageForCustomer);
                                    setState(() {});
                                    textToSpeech();
                                  },
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: (global.languageForCustomer ==
                                                global.countryCodes[index])
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.4),
                                        width: (global.languageForCustomer ==
                                                global.countryCodes[index])
                                            ? 3
                                            : 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Stack(
                                        children: [
                                          Image.asset(
                                            'assets/flags/${global.countryCodes[index]}.png',
                                            fit: BoxFit.cover,
                                            width: 60,
                                            height: 60,
                                          ),
                                          if (global.languageForCustomer ==
                                              global.countryCodes[index])
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // ส่วนล่าง: ปุ่มยกเลิก (10% ของหน้าจอ)
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(context, '/',
                                  (Route<dynamic> route) => false);
                            },
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: Text(
                              global.language("cancel"),
                              style: TextStyle(
                                fontFamily: 'Kanit',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 32),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )));
  }

  /// แสดง Dialog รายการพิมพ์ครัวที่ค้างอยู่
  void _showPendingKitchenPrintDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _PendingKitchenPrintDialog();
      },
    );
  }

  Widget _buildStaffButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
    String? imageUrl,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          height: 130,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? SizedBox(
                        height: 65,
                        width: 65,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => Icon(
                            icon,
                            color: color,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        color: color,
                        size: 60,
                      ),
              ),
              const SizedBox(height: 4),
              // Text Section
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog แสดงรายการพิมพ์ครัวที่ค้างอยู่
class _PendingKitchenPrintDialog extends StatefulWidget {
  @override
  _PendingKitchenPrintDialogState createState() =>
      _PendingKitchenPrintDialogState();
}

class _PendingKitchenPrintDialogState
    extends State<_PendingKitchenPrintDialog> {
  List<Map<String, dynamic>> pendingOrders = [];
  bool isLoading = true;
  bool isMarkingAll = false;
  Timer? _refreshTimer;

  /// รายการที่รอพิมพ์ใน printQueue (printType == 1 คือพิมพ์ครัว)
  List<PrintTicketClass> get kitchenPrintQueue =>
      global.printQueue.where((item) => item.printType == 1).toList();

  @override
  void initState() {
    super.initState();
    _loadPendingOrders();
    // Timer รีเฟรชทุก 5 วินาที
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !isLoading && !isMarkingAll) {
        _loadPendingOrders();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPendingOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      String tableNameOrderTemp = (global.deviceConfig.systemCondition == 1)
          ? "${global.clickHouseDatabaseName}.ordertemppaylater"
          : "${global.clickHouseDatabaseName}.ordertemp";

      // Query รายการที่ยังไม่ได้พิมพ์ครัว (isprintkitchensuccess = 0, isclose = 2)
      String query = """
        SELECT orderid, ordertagnumber, queuenumber, MAX(orderdatetime) as orderdatetime, COUNT(*) as item_count
        FROM (
          SELECT orderid, ordertagnumber, queuenumber, orderdatetime, isprintkitchensuccess, isclose,
                 ROW_NUMBER() OVER (PARTITION BY orderguid ORDER BY orderdatetime DESC) as rn
          FROM $tableNameOrderTemp
          WHERE shopid='${global.deviceConfig.shopId}'
            AND branchid='${global.deviceConfig.branchId}'
        )
        WHERE rn = 1 AND isprintkitchensuccess = 0 AND isclose = 2
        GROUP BY orderid, ordertagnumber, queuenumber
        ORDER BY orderdatetime DESC
        LIMIT 100
      """;

      var response = await api.clickHouseSelect(query).timeout(
            const Duration(seconds: 10),
            onTimeout: () => <String, dynamic>{},
          );

      if (response.isNotEmpty) {
        ResponseDataModel result = ResponseDataModel.fromJson(response);
        setState(() {
          pendingOrders = List<Map<String, dynamic>>.from(result.data);
          isLoading = false;
        });
      } else {
        setState(() {
          pendingOrders = [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading pending orders: $e");
      }
      setState(() {
        pendingOrders = [];
        isLoading = false;
      });
    }
  }

  /// Mark ว่าพิมพ์ครัวแล้วทั้งหมด
  Future<void> _markAllAsPrinted() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยัน"),
        content: Text(
            "ต้องการ Mark ว่าพิมพ์ครัวแล้วทั้งหมด ${pendingOrders.length} รายการ?\n\nรายการเหล่านี้จะไม่ถูกพิมพ์อีก"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ยืนยัน", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isMarkingAll = true;
    });

    try {
      String tableNameOrderTemp = (global.deviceConfig.systemCondition == 1)
          ? "${global.clickHouseDatabaseName}.ordertemppaylater"
          : "${global.clickHouseDatabaseName}.ordertemp";

      // Update isprintkitchensuccess = 1 สำหรับทุก order ที่ค้างอยู่
      for (var order in pendingOrders) {
        String orderId = order['orderid'];
        await api.clickHouseExecute(
            "alter table $tableNameOrderTemp UPDATE isprintkitchensuccess=1 WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderid='$orderId' and isprintkitchensuccess=0");

        // ลบออกจาก memory tracking sets ด้วย
        global.kitchenPrintProcessingOrderIds.remove(orderId);
        global.kitchenPrintedOrderIds.add(orderId);
      }

      // รอให้ ClickHouse mutation เสร็จ
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Mark ว่าพิมพ์แล้ว ${pendingOrders.length} รายการสำเร็จ"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error marking all as printed: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isMarkingAll = false;
        });
      }
    }
  }

  /// จำนวนคิวพิมพ์บิล (printType == 0)
  int get billPrintQueueCount =>
      global.printQueue.where((item) => item.printType == 0).length;

  /// เคลียคิวพิมพ์ทั้งหมด (ครัว + บิล) และ Mark ว่าพิมพ์แล้ว
  Future<void> _clearPrintQueueAndMarkAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันเคลียคิวพิมพ์"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ต้องการเคลียคิวพิมพ์ทั้งหมด?\n"),
            Text("• คิวพิมพ์ครัว: ${kitchenPrintQueue.length} รายการ"),
            Text("• คิวพิมพ์บิล: $billPrintQueueCount รายการ"),
            Text("• รายการค้างใน DB: ${pendingOrders.length} รายการ"),
            const SizedBox(height: 12),
            const Text(
              "คิวพิมพ์ทั้งหมดจะถูกลบและ Mark ว่าพิมพ์แล้ว",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ยืนยันเคลียคิว",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isMarkingAll = true;
    });

    try {
      // 1. ปิด kitchen print ชั่วคราว
      global.kitchenPrintDisabled = true;

      // 2. เคลียคิวพิมพ์ทั้งหมดใน memory (ทั้งครัวและบิล)
      global.printQueue.clear();
      global.printQueueProcessing = false;

      // 3. เคลีย tracking sets
      global.kitchenPrintProcessingOrderIds.clear();
      global.kitchenPrintedOrderGuids.clear();
      global.kitchenPrintQueueProcessing = false;

      // 4. อัพเดท DB ให้เป็นพิมพ์แล้วทั้งหมด
      String tableNameOrderTemp = (global.deviceConfig.systemCondition == 1)
          ? "${global.clickHouseDatabaseName}.ordertemppaylater"
          : "${global.clickHouseDatabaseName}.ordertemp";

      for (var order in pendingOrders) {
        String orderId = order['orderid'];
        await api.clickHouseExecute(
            "alter table $tableNameOrderTemp UPDATE isprintkitchensuccess=1 WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderid='$orderId' and isprintkitchensuccess=0");
        global.kitchenPrintedOrderIds.add(orderId);
      }

      // รอให้ ClickHouse mutation เสร็จ
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("เคลียคิวพิมพ์ทั้งหมดสำเร็จ (ปิดพิมพ์ครัวชั่วคราว)"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error clearing print queue: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isMarkingAll = false;
        });
      }
    }
  }

  /// Mark รายการเดียวว่าพิมพ์แล้ว
  Future<void> _markSingleAsPrinted(String orderId) async {
    try {
      String tableNameOrderTemp = (global.deviceConfig.systemCondition == 1)
          ? "${global.clickHouseDatabaseName}.ordertemppaylater"
          : "${global.clickHouseDatabaseName}.ordertemp";

      await api.clickHouseExecute(
          "alter table $tableNameOrderTemp UPDATE isprintkitchensuccess=1 WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderid='$orderId' and isprintkitchensuccess=0");

      global.kitchenPrintProcessingOrderIds.remove(orderId);
      global.kitchenPrintedOrderIds.add(orderId);

      // Reload list
      await _loadPendingOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mark ว่าพิมพ์แล้วสำเร็จ"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error marking single as printed: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueItems = kitchenPrintQueue;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.print_disabled,
                        color: Color(0xFFE53E3E), size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      "รายการพิมพ์ครัวค้าง",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Toggle เปิด/ปิดพิมพ์ครัว
            // Container(
            //   margin: const EdgeInsets.only(bottom: 12),
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //   decoration: BoxDecoration(
            //     color: global.kitchenPrintDisabled ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
            //     borderRadius: BorderRadius.circular(8),
            //     border: Border.all(
            //       color: global.kitchenPrintDisabled ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
            //     ),
            //   ),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Row(
            //         children: [
            //           Icon(
            //             global.kitchenPrintDisabled ? Icons.print_disabled : Icons.print,
            //             color: global.kitchenPrintDisabled ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
            //             size: 20,
            //           ),
            //           const SizedBox(width: 8),
            //           Text(
            //             global.kitchenPrintDisabled ? "พิมพ์ครัว: ปิดอยู่" : "พิมพ์ครัว: เปิดอยู่",
            //             style: TextStyle(
            //               fontWeight: FontWeight.w600,
            //               color: global.kitchenPrintDisabled ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
            //             ),
            //           ),
            //         ],
            //       ),
            //       Switch(
            //         value: !global.kitchenPrintDisabled,
            //         activeTrackColor: const Color(0xFF86EFAC),
            //         activeThumbColor: const Color(0xFF16A34A),
            //         onChanged: (value) {
            //           setState(() {
            //             global.kitchenPrintDisabled = !value;
            //           });
            //         },
            //       ),
            //     ],
            //   ),
            // ),

            // Print Queue Section (รายการรอพิมพ์ใน Memory)
            if (queueItems.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD93D), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hourglass_empty,
                            color: Color(0xFFB8860B), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "รอพิมพ์ในคิว: ${queueItems.length} รายการ",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB8860B)),
                        ),
                        const Spacer(),
                        if (global.kitchenPrintQueueProcessing)
                          Row(
                            children: const [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFFB8860B)),
                              ),
                              SizedBox(width: 8),
                              Text("กำลังพิมพ์...",
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFFB8860B))),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: queueItems.length,
                        itemBuilder: (context, index) {
                          final item = queueItems[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor:
                                      const Color(0xFFFFD93D).withOpacity(0.3),
                                  child: Text(
                                    item.queueNumber.toString(),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB8860B)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.orderTempDetails.isNotEmpty
                                            ? "ป้าย: ${item.orderTempDetails[0].orderTagNumber} คิว: ${item.orderTempDetails.isNotEmpty ? item.orderTempDetails[0].queueNumber : ''}"
                                            : "",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        "รายการ: ${item.orderTempDetails.length} ชิ้น",
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD93D)
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "รอคิว",
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFB8860B)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Summary (รายการค้างจาก DB)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "รายการค้าง (DB): ${pendingOrders.length} รายการ",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE53E3E)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: isLoading
                        ? null
                        : () {
                            _loadPendingOrders();
                            setState(() {}); // refresh print queue too
                          },
                    tooltip: "รีเฟรช",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : pendingOrders.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 64, color: Colors.green),
                              SizedBox(height: 16),
                              Text("ไม่มีรายการพิมพ์ครัวค้าง",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: pendingOrders.length,
                          itemBuilder: (context, index) {
                            final order = pendingOrders[index];
                            final orderId = order['orderid'] ?? '';
                            final orderTag = order['ordertagnumber'] ?? '';
                            final queueNumber =
                                order['queuenumber']?.toString() ?? '';
                            final itemCount =
                                order['item_count']?.toString() ?? '0';
                            final orderDateTime = order['orderdatetime'] ?? '';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      const Color(0xFFE53E3E).withOpacity(0.1),
                                  child: Text(
                                    queueNumber.isNotEmpty
                                        ? queueNumber
                                        : (index + 1).toString(),
                                    style: const TextStyle(
                                        color: Color(0xFFE53E3E),
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  orderTag.isNotEmpty
                                      ? "ป้าย: $orderTag"
                                      : "คิว: $queueNumber",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("รายการ: $itemCount ชิ้น",
                                        style: const TextStyle(fontSize: 12)),
                                    Text("เวลา: $orderDateTime",
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.check_circle,
                                      color: Colors.green),
                                  tooltip: "Mark ว่าพิมพ์แล้ว",
                                  onPressed: () =>
                                      _markSingleAsPrinted(orderId),
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Footer buttons
            const SizedBox(height: 12),
            if (pendingOrders.isNotEmpty || kitchenPrintQueue.isNotEmpty)
              Row(
                children: [
                  // ปุ่มเคลียคิวพิมพ์
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed:
                          isMarkingAll ? null : _clearPrintQueueAndMarkAll,
                      icon: isMarkingAll
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.clear_all, color: Colors.white),
                      label: const Text(
                        "เคลียคิวพิมพ์",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ปุ่ม Mark ว่าพิมพ์แล้วทั้งหมด
                  if (pendingOrders.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53E3E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: isMarkingAll ? null : _markAllAsPrinted,
                        icon: isMarkingAll
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.done_all, color: Colors.white),
                        label: const Text(
                          "Mark พิมพ์แล้ว",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
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
}
