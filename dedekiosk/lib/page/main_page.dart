import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedekiosk/objectbox/objectbox.g.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/order/services/background_task_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/util/client.dart';
import 'package:dedekiosk/bloc/category_bloc.dart';
import 'package:dedekiosk/model/global_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:dedekiosk/global.dart' as global;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  VideoPlayerController?
      _videoController; // เปลี่ยนเป็น nullable เพื่อป้องกัน crash
  int countDownImageSecond = 0;
  Timer? _mediaTimer; // รวม Timer เหลือตัวเดียว
  Timer? _configReloadTimer;
  Timer? _tokenHealthTimer;
  bool _isTokenWarningShown = false;
  bool playVideo = false;
  bool _isInitializingVideo = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // Animation controller for blinking text
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void reassemble() {
    super.reassemble();
  }

  Future<void> gotoOrderByQrcode(String? barcode) async {
    if (barcode == null) return;

    try {
      String query =
          "select tablenumber,istakeaway,userlanguage,orderid from ${global.clickHouseDatabaseName}.ordertempbarcode where shopid='${global.deviceConfig.shopId}' and barcode='$barcode'";
      var value = await api.clickHouseSelect(query);
      ResponseDataModel barcodeResponseData = ResponseDataModel.fromJson(value);
      if (barcodeResponseData.data.isNotEmpty) {
        global.objectBoxStore.box<OrderTempObjectBoxModel>().removeAll();
        global.saleChannelCode = "";
        String isTakeAway =
            barcodeResponseData.data[0]["istakeaway"].toString();
        if (isTakeAway == "1") {
          global.orderType = 1;
        } else {
          global.orderType = 0;
        }
        global.languageForCustomer =
            barcodeResponseData.data[0]["userlanguage"];
        global.languageSelect(global.languageForCustomer);
        global.tableNumber = barcodeResponseData.data[0]["tablenumber"];
        global.orderId = barcodeResponseData.data[0]["orderid"];
        // load order
        String orderQuery =
            "SELECT orderguid,barcode,qty,optionselected,remark,istakeaway,orderdatetime,isserved,price,amount,machineid,queuenumber FROM ${global.clickHouseDatabaseName}.ordertemp WHERE shopid='${global.deviceConfig.shopId}' and orderid='${global.orderId}' and isclose=0 order by orderdatetime";
        if (kDebugMode) {
          print('gotoOrderByQrcode: Loading order data');
        }
        var orderValue = await api.clickHouseSelect(orderQuery);
        ResponseDataModel responseData = ResponseDataModel.fromJson(orderValue);
        List<OrderTempDetailModel> orderTempList = [];
        for (int i = 0; i < responseData.data.length; i++) {
          orderTempList
              .add(OrderTempDetailModel.fromJson(responseData.data[i]));
        }
        for (var orderTemp in orderTempList) {
          global.objectBoxStore.box<OrderTempObjectBoxModel>().put(
              OrderTempObjectBoxModel(
                orderid: global.orderId,
                barcode: orderTemp.barcode,
                orderguid: orderTemp.orderguid,
                qty: orderTemp.qty,
                optionamount: orderTemp.optionamount ?? 0,
                discountamount: orderTemp.discountamount ?? 0,
                optionselected: orderTemp.optionselected,
                salechannelcode: orderTemp.salechannelcode,
                remark: orderTemp.remark,
                orderdatetime: orderTemp.orderdatetime,
                price: orderTemp.price,
                amount: orderTemp.amount,
                istakeaway: orderTemp.istakeaway,
                queuenumber: orderTemp.queuenumber,
                manufacturerguid: orderTemp.manufacturerguid,
                isexceptvat: orderTemp.is_except_vat,
              ),
              mode: PutMode.insert);
        }
        // delete order on clickhouse
        await api.clickHouseExecute(
            "alter table ${global.clickHouseDatabaseName}.ordertemp delete where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderid='${global.orderId}';");

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, "/order_animation_one", (Route<dynamic> route) => false);
        }
      } else {
        // update เสริฟ
        await global.updateServedQty(orderDetailGuid: barcode, reload: () {});
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('gotoOrderByQrcode error: $e');
        print('Stack trace: $stackTrace');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(global.language("error_occurred")),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> gotoOrder() async {
    // ===== ช่องโหว่ B: บล็อกเริ่ม order ใหม่ขณะ background task ยังทำงาน =====
    // หลังจ่ายเงิน backToHome พากลับมาหน้านี้ แต่ background saveTransaction
    // ยังทำงานอยู่และอ่าน global.productList/categoryList สดๆ ถ้าเริ่ม order
    // ใหม่ตอนนี้จะ regenerate orderId + ล้าง ObjectBox ที่อาจกระทบ task เดิม
    if (BackgroundTaskManager().activeTaskCount > 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("กำลังบันทึก order ก่อนหน้า กรุณารอสักครู่..."),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Check if device is connected first
    if (global.deviceConfig.shopId.isEmpty) {
      await _showConnectionRequiredDialog();
      return;
    }

    // Check if categories and products are loaded
    if (global.categoryList.isEmpty || global.productList.isEmpty) {
      await _showErrorDialog();
      return;
    }

    // ล้างข้อมูลเก่าทิ้ง
    global.objectBoxStore.box<OrderTempObjectBoxModel>().removeAll();

    if (mounted) {
      stopTimer();
      Navigator.pushNamedAndRemoveUntil(
          context, "/order_select", (Route<dynamic> route) => false);
      /*if (global.deviceConfig.machineCondition == 1 &&
          global.deviceConfig.useOrderEatAtTheRestaurant == false &&
          global.deviceConfig.useOrderTakeAway == true) {
        // ถ้าเป็นเครื่องฝั่งลูกค้า และมีแค่สั่งกลับบ้าน ให้เปิดหน้า Order ได้เลย
        global.saleChannelCode = "";
        global.orderType = 1;
        global.priceIndex = 1;
        global.isTakeAway = 1;
        Navigator.pushNamedAndRemoveUntil(
            context, "/order_animation_one", (Route<dynamic> route) => false);
      } else if (global.deviceConfig.machineCondition == 1 &&
          global.deviceConfig.useOrderEatAtTheRestaurant == true &&
          global.deviceConfig.useOrderTakeAway == false) {
        // ถ้าเป็นเครื่องฝั่งลูกค้า และมีแค่สั่งกินที่ร้าน ให้เปิดหน้า Order ได้เลย
        global.saleChannelCode = "";
        global.orderType = 0;
        global.priceIndex = 1;
        global.isTakeAway = 0;
        Navigator.pushNamedAndRemoveUntil(
            context, "/order_animation_one", (Route<dynamic> route) => false);
      } else {
        // ถ้าเป็นเครื่องฝั่งลูกค้า มีทั้งกลับบ้านน และ ทานที่ร้าน
        Navigator.pushNamedAndRemoveUntil(
            context, "/order_select", (Route<dynamic> route) => false);
      }*/
    }
  }

  void randomVideoIndex() {
    if (global.shopProfile == null ||
        global.shopProfile!.orderstation.media.resources.isEmpty) {
      global.videoIndex = -1;
    } else {
      final index = Random()
          .nextInt(global.shopProfile!.orderstation.media.resources.length);
      global.videoIndex = index;
    }
  }

  /// Initialize video when page starts - with retry logic for when shopProfile is not yet loaded
  Future<void> _initializeVideoOnStart() async {
    // If shopProfile is already loaded, initialize immediately
    if (global.shopProfile != null &&
        global.shopProfile!.orderstation.media.resources.isNotEmpty) {
      await initializeAndPlay();
      return;
    }

    // If shopProfile is not loaded yet, wait and retry
    int retryCount = 0;
    const maxRetries = 10;
    const retryDelay = Duration(milliseconds: 500);

    while (retryCount < maxRetries && mounted) {
      await Future.delayed(retryDelay);
      retryCount++;

      if (global.shopProfile != null &&
          global.shopProfile!.orderstation.media.resources.isNotEmpty) {
        randomVideoIndex();
        await initializeAndPlay();
        return;
      }
    }

    if (kDebugMode) {
      print(
          'Video initialization: shopProfile not available after $maxRetries retries');
    }
  }

  int getNextVideoIndex() {
    countDownImageSecond = 0;
    if (global.shopProfile == null ||
        global.shopProfile!.orderstation.media.resources.isEmpty) {
      return -1;
    }
    return Random()
        .nextInt(global.shopProfile!.orderstation.media.resources.length);
  }

  Future<void> _disposeVideoController() async {
    final controller = _videoController;
    if (controller == null) return;

    _videoController = null; // ตั้งเป็น null ก่อน dispose

    try {
      controller.removeListener(checkIfVideoFinished);
    } catch (e) {
      if (kDebugMode) debugPrint('Error removing video listener: $e');
    }

    try {
      if (controller.value.isInitialized) {
        await controller.pause();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error pausing video: $e');
    }

    try {
      await controller.dispose();
    } catch (e) {
      if (kDebugMode) debugPrint('Error disposing video: $e');
    }
  }

  Future<void> initializeAndPlay() async {
    if (_isInitializingVideo || !mounted) return;

    _isInitializingVideo = true;

    try {
      global.videoIndex = getNextVideoIndex();
      await _disposeVideoController();

      if (global.videoIndex == -1 || global.shopProfile == null) {
        playVideo = false;
        if (mounted) setState(() {});
        return;
      }

      final resource =
          global.shopProfile!.orderstation.media.resources[global.videoIndex];

      // ถ้าเป็นรูปภาพ (mediaType == 0) ไม่ต้องสร้าง video controller
      if (resource.mediaType == 0) {
        playVideo = false;
        if (mounted) setState(() {});
        return;
      }

      // เป็นวิดีโอ (mediaType == 1 หรือ 2)
      try {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(resource.uri),
        );

        await controller.initialize().timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw Exception('Video init timeout'),
            );

        // ตรวจสอบอีกครั้งว่ายังอยู่ใน widget tree
        if (!mounted) {
          await controller.dispose();
          return;
        }

        controller.setVolume(0);
        controller.setLooping(false);
        controller.addListener(checkIfVideoFinished);

        _videoController = controller;
        await controller.play();
        playVideo = true;

        setState(() {});
      } catch (e) {
        if (kDebugMode) print('Error initializing video: $e');
        playVideo = false;
        if (mounted) setState(() {});
      }
    } finally {
      _isInitializingVideo = false;
    }
  }

  void checkIfVideoFinished() {
    final controller = _videoController;
    if (!mounted || _isInitializingVideo || controller == null) return;

    try {
      final position = controller.value.position;
      final duration = controller.value.duration;

      if (duration > Duration.zero && position >= duration) {
        initializeAndPlay();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking video position: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize blink animation
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    _blinkController.repeat(reverse: true);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    global.orderId = const Uuid().v4();
    global.registerDeviceToServer();
    global.removeCalcQty();
    global.languageForCustomer = global.countryCodes[0];
    global.languageSelect(global.languageForCustomer);
    WakelockPlus.enable();
    try {
      ScreenBrightness().setScreenBrightness(1.0);
    } catch (e) {
      if (kDebugMode) {
        print('ScreenBrightness error: $e');
      }
    }
    randomVideoIndex(); // Initialize video immediately when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initializeVideoOnStart();
      // Show network error dialog if needed
      if (global.isNetworkError) {
        _showNetworkErrorDialog();
      }
      // ตรวจสอบ token ทันทีเมื่อเข้าหน้า
      await _checkTokenAndNotify();
    });

    // ตรวจสอบ token ทุก 5 นาที (กรณี kiosk ทำงานค้างไว้)
    _tokenHealthTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _checkTokenAndNotify();
    });

    // ✅ รวม Timer เป็นตัวเดียว - ทุก 10 วินาที (เพิ่มประสิทธิภาพ)
    _mediaTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted || global.shopProfile == null) return;

      if (global.videoIndex != -1) {
        final resource =
            global.shopProfile!.orderstation.media.resources[global.videoIndex];
        // รูปภาพ: เปลี่ยนทุก 5 รอบ (50 วินาที), วิดีโอ: รอจบเอง (ไม่ต้องนับ)
        final maxCountDown = resource.mediaType == 0 ? 5 : 60;

        countDownImageSecond++;
        if (countDownImageSecond >= maxCountDown) {
          countDownImageSecond = 0;
          await initializeAndPlay();
        }
      } else if (!playVideo) {
        await initializeAndPlay();
      }
    });

    // ✅ Config reload - ทุก 1 นาที (ลดจาก 30 วินาที เพื่อลด network calls)
    _configReloadTimer =
        Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (!mounted) return;
      try {
        await global.loadConfig();
        if (mounted) setState(() {});
      } catch (e) {
        if (kDebugMode) print('Config reload error: $e');
      }
    });

    global.categoryIndex = -1;
    context.read<CategoryBloc>().add(CategoryLoadStart());
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void stopTimer() {
    _mediaTimer?.cancel();
    _configReloadTimer?.cancel();
    _tokenHealthTimer?.cancel();
    _mediaTimer = null;
    _configReloadTimer = null;
    _tokenHealthTimer = null;

    _disposeVideoController();
  }

  Future<void> _checkTokenAndNotify() async {
    if (!mounted) return;
    final isValid = await api.checkTokenHealth();
    if (!mounted || isValid) return;
    if (_isTokenWarningShown) return;

    _isTokenWarningShown = true;

    // พยายาม re-auth ก่อน
    final reauthed = await ApiAuthManager.reauthenticate();
    if (!mounted) return;

    if (reauthed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('เชื่อมต่อ session ใหม่เรียบร้อย'),
          ]),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      await _showTokenInvalidDialog();
    }

    _isTokenWarningShown = false;
  }

  Future<void> _showTokenInvalidDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            const Text('Session หมดอายุ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'ไม่สามารถเชื่อมต่อ session ได้ กรุณาตั้งค่าอุปกรณ์ใหม่',
                  style: TextStyle(fontSize: 15)),
              const SizedBox(height: 8),
              Text('Token Invalid — ติดต่อผู้ดูแลระบบ',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('ปิด'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                stopTimer();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/setting', (route) => false);
              },
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('ไปที่ Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    stopTimer();
    _blinkController.dispose();
    try {
      WakelockPlus.disable();
    } catch (e) {
      if (kDebugMode) {
        print('WakelockPlus disable error: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String timeCompare =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    global.isMobileScreen = MediaQuery.of(context).size.width < 600;
    return BlocListener<CategoryBloc, CategoryState>(
        listener: (context, categoryState) {
          if (categoryState is CategoryLoadSuccess) {
            global.categoryList = [];
            for (int i = 0; i < categoryState.category.length; i++) {
              bool isTimeForSales = false;
              for (int j = 0;
                  j < categoryState.category[i].timeforsales.length;
                  j++) {
                if (categoryState
                        .category[i].timeforsales[j].fromtime.isNotEmpty &&
                    categoryState
                        .category[i].timeforsales[j].totime.isNotEmpty) {
                  if (timeCompare.compareTo(categoryState
                              .category[i].timeforsales[j].fromtime) >=
                          0 &&
                      timeCompare.compareTo(categoryState
                              .category[i].timeforsales[j].totime) <=
                          0) {
                    isTimeForSales = true;
                    break;
                  }
                }
              }
              if (categoryState.category[i].timeforsales.isEmpty ||
                  isTimeForSales) {
                global.categoryList.add(categoryState.category[i]);
              }
            }

            context.read<CategoryBloc>().add(CategoryLoadFinish());
            global.categoryIndex = 0;
            setState(() {});
          }
        },
        child: Scaffold(
            body: BarcodeKeyboardListener(
                bufferDuration: const Duration(milliseconds: 200),
                onBarcodeScanned: (barcode) async {
                  gotoOrderByQrcode(barcode);
                },
                child: Stack(
                  children: [
                    // Background with gradient overlay
                    InkWell(
                        onTap: () {
                          gotoOrder();
                        },
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: Stack(
                            children: [
                              // Background content (video/image)
                              (global.videoIndex == -1 ||
                                      global.shopProfile == null)
                                  ? Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF1a1a2e),
                                            Color(0xFF16213e),
                                            Color(0xFF0f3460),
                                          ],
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: (global
                                                  .shopProfile!
                                                  .orderstation
                                                  .media
                                                  .resources[global.videoIndex]
                                                  .mediaType ==
                                              0)
                                          ? CachedNetworkImage(
                                              imageUrl: global
                                                  .shopProfile!
                                                  .orderstation
                                                  .media
                                                  .resources[global.videoIndex]
                                                  .uri,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.error),
                                              ),
                                            )
                                          : (playVideo &&
                                                  _videoController != null &&
                                                  _videoController!
                                                      .value.isInitialized)
                                              ? VideoPlayer(_videoController!)
                                              : const SizedBox.shrink()),
                              // Gradient overlay for better text readability
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.5),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),

                    // Top navigation bar
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Container(
                            margin:
                                const EdgeInsets.only(left: 15.0, right: 15.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: IconButton(
                                    onPressed: () {
                                      stopTimer();
                                      Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          '/bill_list',
                                          (Route<dynamic> route) => false);
                                    },
                                    icon: const Icon(
                                      Icons.receipt_long,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: IconButton(
                                    onPressed: () {
                                      stopTimer();
                                      Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          '/bill_ledger',
                                          (Route<dynamic> route) => false);
                                    },
                                    icon: const Icon(
                                      Icons.cloud_done,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: IconButton(
                                    onPressed: () {
                                      stopTimer();
                                      Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          '/setting',
                                          (Route<dynamic> route) => false);
                                    },
                                    icon: const Icon(
                                      Icons.settings,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ), // Bottom black bar with tap to start text
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: SafeArea(
                          top: false,
                          child: Center(
                            child: FadeTransition(
                              opacity: _blinkAnimation,
                              child: Text(
                                global.language("tap_screen_to_start"),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ))));
  }

  Future<void> _showConnectionRequiredDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange[700], size: 28),
              const SizedBox(width: 12),
              const Text(
                "Device Not Connected",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Please connect device with PIN code",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Text(
                "กรุณาเชื่อมต่ออุปกรณ์ด้วย PIN Code ก่อนใช้งาน",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Go to Settings to connect your device",
                        style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                global.language("cancel"),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                stopTimer();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/setting', (Route<dynamic> route) => false);
              },
              icon: const Icon(Icons.settings, size: 18),
              label: const Text("Go to Settings"),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showErrorDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(global.language("error")),
          content: Text(global.language("error_occurred")),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(global.language("ok")),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNetworkErrorDialog() async {
    if (!mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิดได้จนกว่าจะเชื่อมต่อสำเร็จ
      builder: (BuildContext dialogContext) {
        bool isRetrying = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.red[700], size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "เชื่อมต่อ Internet ไม่ได้",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "กรุณาตรวจสอบการเชื่อมต่อ Internet แล้วกดลองใหม่",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "ระบบต้องการ Internet เพื่อทำงาน",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isRetrying) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text("กำลังเชื่อมต่อ...",
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: <Widget>[
                if (!isRetrying)
                  ElevatedButton.icon(
                    onPressed: () async {
                      setDialogState(() => isRetrying = true);

                      try {
                        await global.loadConfig();
                        global.isNetworkError = false;

                        if (mounted && dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                          // Reload categories after successful connection
                          context.read<CategoryBloc>().add(CategoryLoadStart());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('เชื่อมต่อสำเร็จ'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isRetrying = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('ยังไม่สามารถเชื่อมต่อได้: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("ลองใหม่"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
