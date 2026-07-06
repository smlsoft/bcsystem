import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/trans_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badges/badges.dart' as badges;
import 'package:dedekiosk/bloc/order_temp_bloc.dart';
import 'package:dedekiosk/model/category_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:dedekiosk/objectbox/objectbox.g.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/order/order_animation_one/order_animation_one_cart_page.dart';
import 'package:dedekiosk/order/order_animation_one/order_animation_one_util.dart';
import 'package:dedekiosk/order/order_animation_one/optimized_product_item_widget.dart';
import 'package:dedekiosk/order/order_animation_one/kitchen_printer_cache.dart';
import 'package:dedekiosk/page/select_language_page.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/util/logger.dart';
import 'package:dedekiosk/widget/floating_member_pin_widget.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OrderAnimationOnePage extends StatefulWidget {
  const OrderAnimationOnePage({super.key});

  @override
  OrderAnimationOnePageState createState() => OrderAnimationOnePageState();
}

class OrderAnimationOnePageState extends State<OrderAnimationOnePage> with TickerProviderStateMixin {
  // Core data
  List<OrderTempDetailModel> orderTempDetailList = [];
  List<OrderTempDetailModel> orderTempSumByBarcodeList = [];
  double sumOrderQty = 0;
  double sumOrderAmount = 0;
  String productSelectedBarcode = "";
  late ProductProcessModel productSelected;

  // UI state variables
  bool loadProductProcessSuccess = false;
  bool isSearch = false;
  bool showCartMode = false;
  bool isLoadingProducts = false;
  // Text scale for entire screen (0.8 to 1.4, default 1.0)
  double _textScale = 1.0;
  static const double _minTextScale = 0.8;
  static const double _maxTextScale = 1.4;
  static const double _textScaleStep = 0.1;

  // Mobile layout - Scaffold key for drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controllers
  final TextEditingController searchController = TextEditingController();
  final ScrollController productScrollController = ScrollController();
  final ScrollController categoryScrollController = ScrollController();

  // Timers
  late Timer timerCountDown;
  late Timer timerLoadProcess;
  Timer? _productReloadDebouncer;
  Timer? _searchDebouncer;

  // PERFORMANCE: Kitchen printer cache for O(1) lookup
  final KitchenPrinterCache _kitchenPrinterCache = KitchenPrinterCache();

  // Showcase keys for first-time guide
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _productKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _cartKey = GlobalKey();
  final GlobalKey _memberKey = GlobalKey();
  BuildContext? _showcaseContext;
  bool _showcaseShown = false;

  /// Get primary theme color from config
  Color get primaryThemeColor {
    return _hexToColor(global.deviceConfig.primaryThemeColor);
  }

  /// Convert hex string to Color
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  void initState() {
    super.initState();
    global.categoryIndex = 0;
    global.countDownForHome = global.countDownForHomeMax;
    _textScale = 1.0;
    // PERFORMANCE: Build kitchen printer cache once
    _kitchenPrinterCache.buildCache();

    // Load initial orders
    context.read<OrderTempBloc>().add(OrderTempLoadStart(barcode: "", isTakeAway: global.orderType)); // PERFORMANCE: Reload stock data only if initial category has stock-managed products
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (!mounted) return;
      if (_categoryHasStockProducts(global.categoryIndex)) {
        await api.reloadProductProcessFromServer();
        if (mounted) reloadProductList();
      }
    });

    // Initialize timers
    _initializeTimers();

    // Add search listener
    searchController.addListener(_onSearchChanged);
  }

  void _initializeTimers() {
    // Timer for auto-return to home screen
    timerCountDown = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      global.countDownForHome--;
      if (global.countDownForHome <= 0) {
        global.countDownForHome = global.countDownForHomeMax;
        backToHome();
      }
    });

    // Timer for reloading products from server
    timerLoadProcess = Timer.periodic(const Duration(seconds: 15), (Timer t) async {
      if (!mounted) return;

      // PERFORMANCE: Reload stock data only if current category has stock-managed products
      if (_categoryHasStockProducts(global.categoryIndex)) {
        try {
          Logger.d('Periodic stock reload: Starting for category ${global.categoryIndex}', tag: 'StockManagement');

          await api.reloadProductProcessFromServer().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              Logger.w('Periodic stock reload: Timeout after 10 seconds', tag: 'StockManagement');
              return; // Skip this cycle
            },
          );

          if (mounted) {
            reloadProductList(); // Rebuild UI with updated stock data
          }

          Logger.d('Periodic stock reload: Success', tag: 'StockManagement');
        } catch (e, s) {
          // Log error but don't show to user - this is background refresh
          Logger.e('Periodic stock reload: Failed', error: e, stackTrace: s, tag: 'StockManagement');
          // Continue silently - data may be slightly stale but app remains functional
        }
      }
    });
  }

  @override
  void dispose() {
    timerCountDown.cancel();
    timerLoadProcess.cancel();
    productScrollController.dispose();
    categoryScrollController.dispose();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _searchDebouncer?.cancel();
    _productReloadDebouncer?.cancel();
    _textScale = 1.0;
    _showcaseContext = null;
    super.dispose();
  }

  /// Start the showcase guide
  void _startShowcase() {
    if (_showcaseContext != null && mounted) {
      ShowCaseWidget.of(_showcaseContext!).startShowCase([
        _categoryKey,
        _productKey,
        _searchKey,
        if (global.deviceConfig.useMember && !global.isMember) _memberKey,
        _cartKey,
      ]);
    }
  }

  /// Check if showcase should be shown (only first time)
  Future<void> _checkAndShowShowcase() async {
    if (_showcaseShown) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenShowcase = prefs.getBool('order_page_showcase_seen') ?? false;

    if (!hasSeenShowcase && mounted && _showcaseContext != null) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && _showcaseContext != null) {
        _showcaseShown = true;
        _startShowcase();
      }
    }
  }

  /// Mark showcase as completed
  Future<void> _markShowcaseCompleted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('order_page_showcase_seen', true);
  }

  void _onSearchChanged() {
    if (_searchDebouncer?.isActive ?? false) {
      _searchDebouncer!.cancel();
    }
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) reloadProductList();
    });
  }

  void backToHome() {
    try {
      Logger.d('backToHome: Clearing order data and resetting session', tag: 'Navigation');

      // Clear old data from ObjectBox
      final removedCount = global.objectBoxStore.box<OrderTempObjectBoxModel>().removeAll();
      Logger.d('backToHome: Removed $removedCount order items from ObjectBox', tag: 'Navigation');

      // Clear member data
      global.isMember = false;
      global.memberCode = "";
      global.memberName = "";
      global.memberPicture = "";
      global.memberEmail = "";
      global.memberPinCode = "";
      global.memberPointsCode = "";
      global.memberPriceLevel = 1;
      global.memberGuidFixed = "";
      global.memberPointBalance = 0;
      global.priceIndex = 1; // Reset to normal price
      global.lineDestination = "";
      global.custNames = [];

      Logger.d('backToHome: Member data cleared, navigating to home', tag: 'Navigation');

      if (global.deviceConfig.machineCondition == 0) {
        Navigator.pushNamedAndRemoveUntil(context, '/order_select', (Route<dynamic> route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
      }
    } catch (e, s) {
      Logger.e('backToHome: Error clearing data', error: e, stackTrace: s, tag: 'Navigation');

      // Try to navigate anyway even if clearing data fails
      try {
        if (global.deviceConfig.machineCondition == 0) {
          Navigator.pushNamedAndRemoveUntil(context, '/order_select', (Route<dynamic> route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
        }
      } catch (navError) {
        Logger.e('backToHome: Critical error - cannot navigate', error: navError, tag: 'Navigation');
      }
    }
  }

  void refresh() {
    context.read<OrderTempBloc>().add(OrderTempLoadStart(barcode: "", isTakeAway: global.orderType));
  }

  /// คำนวณราคาใหม่ตาม priceIndex ปัจจุบัน และอัพเดทใน ObjectBox
  Future<void> _recalcPricesForPriceIndex() async {
    try {
      Logger.d('_recalcPricesForPriceIndex: Start - priceIndex=${global.priceIndex}', tag: 'PriceCalculation');

      // ดึงข้อมูลจาก ObjectBox
      var data = global.objectBoxStore.box<OrderTempObjectBoxModel>().query(OrderTempObjectBoxModel_.istakeaway.equals(global.orderType)).build().find();
      Logger.d('_recalcPricesForPriceIndex: Found ${data.length} items in ObjectBox', tag: 'PriceCalculation');

      int updatedCount = 0;
      int errorCount = 0;

      for (var order in data) {
        try {
          // หา product ที่ตรงกับ barcode
          int productIndex = global.productList.indexWhere((p) => p.barcode == order.barcode);
          if (productIndex != -1) {
            var productData = global.productList[productIndex];
            // คำนวณราคาใหม่ตาม priceIndex ปัจจุบัน
            double newPrice = global.findProductPrice(prices: productData.prices);
            double newAmount = newPrice * order.qty + order.optionamount;

            // อัพเดทใน ObjectBox ถ้าราคาเปลี่ยน
            if (order.price != newPrice || order.amount != newAmount) {
              Logger.d(
                '_recalcPricesForPriceIndex: ${order.barcode} - oldPrice=${order.price}, newPrice=$newPrice, oldAmount=${order.amount}, newAmount=$newAmount',
                tag: 'PriceCalculation',
              );
              order.price = newPrice;
              order.amount = newAmount;
              global.objectBoxStore.box<OrderTempObjectBoxModel>().put(order);
              updatedCount++;
            }
          } else {
            Logger.w('_recalcPricesForPriceIndex: Product not found for barcode ${order.barcode}', tag: 'PriceCalculation');
          }
        } catch (e) {
          errorCount++;
          Logger.e('_recalcPricesForPriceIndex: Error updating item ${order.barcode}', error: e, tag: 'PriceCalculation');
        }
      }

      Logger.d(
        '_recalcPricesForPriceIndex: Completed - updated $updatedCount items, $errorCount errors',
        tag: 'PriceCalculation',
      );
    } catch (e, s) {
      Logger.e('_recalcPricesForPriceIndex: Critical error', error: e, stackTrace: s, tag: 'PriceCalculation');

      // Show error to user if mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ไม่สามารถคำนวณราคาใหม่ได้ กรุณาลองใหม่อีกครั้ง',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// เลือกแสดง Dialog สมาชิกตามประเภท (BC Member หรือ PIN)
  void _showAddMemberDialog() {
    if (global.shopProfile?.isbcmember == true) {
      // BC Member - แสดง code รอยืนยัน
      _showBCMemberDialog();
    } else {
      // แบบเดิม - กรอก PIN
      _showMemberPinDialog();
    }
  }

  /// แสดง Dialog สำหรับ BC Member (แสดง QR Code สำหรับสแกนผ่าน LINE LIFF)
  Future<void> _showBCMemberDialog() async {
    String sessionId = '';
    String liffUrl = '';
    String status = 'loading'; // loading, pending, success, expired, error
    String errorMessage = '';
    DateTime? expiresAt;
    Timer? statusCheckTimer;
    Timer? countdownTimer; // Timer สำหรับ update UI ทุก 1 วินาที
    bool isRequestingSession = false; // ป้องกันการเรียก API ซ้ำ

    // ฟังก์ชันขอ QR Session ใหม่
    Future<void> requestNewSession(StateSetter setDialogState) async {
      if (isRequestingSession) return; // ป้องกันการเรียกซ้ำ
      isRequestingSession = true;

      setDialogState(() {
        status = 'loading';
        errorMessage = '';
      });

      try {
        final response = await api.getBCMemberQRSession(global.deviceConfig.shopId);

        if (response['session_id'] != null && response['liff_url'] != null) {
          setDialogState(() {
            sessionId = response['session_id'].toString();
            liffUrl = response['liff_url'].toString();
            status = 'pending';
            // ตั้งเวลาหมดอายุจาก API หรือ default 5 นาที
            if (response['expires_at'] != null) {
              // expires_at เป็น Unix timestamp (seconds since epoch)
              final expiresAtRaw = response['expires_at'];
              if (expiresAtRaw is int) {
                expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtRaw * 1000);
              } else if (expiresAtRaw is double) {
                expiresAt = DateTime.fromMillisecondsSinceEpoch((expiresAtRaw * 1000).toInt());
              } else {
                // ลองแปลงเป็น int ก่อน ถ้าไม่ได้ให้ลอง parse เป็น DateTime string
                final parsed = int.tryParse(expiresAtRaw.toString());
                if (parsed != null) {
                  expiresAt = DateTime.fromMillisecondsSinceEpoch(parsed * 1000);
                } else {
                  expiresAt = DateTime.tryParse(expiresAtRaw.toString()) ?? DateTime.now().add(const Duration(minutes: 5));
                }
              }
            } else {
              expiresAt = DateTime.now().add(const Duration(minutes: 5));
            }
          });

          // เริ่ม countdown timer สำหรับ update UI ทุก 1 วินาที
          countdownTimer?.cancel();
          countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (status != 'pending') {
              timer.cancel();
              return;
            }
            setDialogState(() {}); // trigger UI rebuild
          });

          // เริ่ม timer เช็ค status ทุก 3 วินาที
          statusCheckTimer?.cancel();
          statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
            if (status != 'pending') {
              timer.cancel();
              return;
            }

            // เช็คว่าหมดเวลาหรือยัง
            if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
              timer.cancel();
              countdownTimer?.cancel();
              setDialogState(() {
                status = 'expired';
              });
              return;
            }

            try {
              final statusResponse = await api.getBCMemberLoginStatus(sessionId);
              if (statusResponse['status'] == 'success') {
                timer.cancel();
                countdownTimer?.cancel();

                // Set member data
                global.isMember = true;
                global.memberCode = statusResponse['line_user_id'] ?? '';
                global.memberName = statusResponse['display_name'] ?? '';
                global.memberPicture = statusResponse['picture_url'] ?? '';
                global.priceIndex = 1;

                // ✅ BC Member: เก็บ line_user_id สำหรับส่ง Sale Invoice
                global.memberPinCode = statusResponse['line_user_id'] ?? '';

                // BC Member: ใช้ข้อมูลจาก API โดยตรง ไม่ต้องดึง debtor
                Logger.d('BCMemberDialog: Using data from BC Member API directly (skip getDebtorByLine)');

                // ดึง point_balance จาก BC Member API
                var bcPointBalanceRaw = statusResponse['point_balance'];
                double bcPointBalance = 0;
                if (bcPointBalanceRaw is double) {
                  bcPointBalance = bcPointBalanceRaw;
                } else if (bcPointBalanceRaw is int) {
                  bcPointBalance = bcPointBalanceRaw.toDouble();
                } else if (bcPointBalanceRaw != null) {
                  bcPointBalance = double.tryParse(bcPointBalanceRaw.toString()) ?? 0;
                }

                // ตั้งค่า default สำหรับ BC Member
                global.custNames = [
                  TransNameInfoModel(name: global.memberName, code: "th", isauto: false, isdelete: false),
                  TransNameInfoModel(name: global.memberName, code: "en", isauto: false, isdelete: false),
                ];
                global.memberPriceLevel = 1;
                global.priceIndex = 1;
                global.memberPointBalance = bcPointBalance;

                Logger.d('BCMemberDialog: point_balance from API = $bcPointBalance');

                setDialogState(() {
                  status = 'success';
                });

                Logger.d('BCMemberDialog: Member linked - ${global.memberName}');
              }
            } catch (e) {
              Logger.e('BCMemberDialog: Error checking status', error: e);
            }
          });
        } else {
          setDialogState(() {
            status = 'error';
            errorMessage = 'ไม่สามารถสร้าง QR Code ได้';
          });
        }
      } catch (e) {
        Logger.e('BCMemberDialog: Error requesting QR session', error: e);
        setDialogState(() {
          status = 'error';
          errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
        });
      } finally {
        isRequestingSession = false; // Reset flag เมื่อเสร็จสิ้น
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // ขอ QR Session เมื่อเปิด dialog ครั้งแรก
            if (status == 'loading' && sessionId.isEmpty) {
              Future.microtask(() => requestNewSession(setDialogState));
            }

            // คำนวณเวลาที่เหลือ
            String remainingTime = '';
            if (status == 'pending' && expiresAt != null) {
              final remaining = expiresAt!.difference(DateTime.now());
              if (remaining.isNegative) {
                Future.microtask(() {
                  setDialogState(() {
                    status = 'expired';
                  });
                });
              } else {
                final minutes = remaining.inMinutes;
                final seconds = remaining.inSeconds % 60;
                remainingTime = '$minutes:${seconds.toString().padLeft(2, '0')}';
              }
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;
                final isSmallScreen = screenWidth < 600;

                final dialogWidth = isSmallScreen ? screenWidth * 0.9 : 450.0;
                final logoSize = isSmallScreen ? 70.0 : 100.0;
                final titleFontSize = isSmallScreen ? 18.0 : 22.0;
                final qrSize = isSmallScreen ? 200.0 : 250.0;
                final padding = isSmallScreen ? 16.0 : 24.0;

                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: dialogWidth,
                    constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header with close button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    statusCheckTimer?.cancel();
                                    countdownTimer?.cancel();
                                    Navigator.of(dialogContext).pop();
                                  },
                                  icon: const Icon(Icons.close),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),

                            // Title
                            Text(
                              global.language("add_friend_collect_points"),
                              style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),

                            // Content based on status
                            if (status == 'loading') ...[
                              const SizedBox(height: 40),
                              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryThemeColor)),
                              const SizedBox(height: 16),
                              Text('กำลังสร้าง QR Code...', style: TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 40),
                            ] else if (status == 'pending') ...[
                              Text(
                                'สแกน QR Code ด้วยแอป LINE',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 20),

                              // QR Code display
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: primaryThemeColor.withAlpha(100), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: QrImageView(
                                  data: liffUrl,
                                  version: QrVersions.auto,
                                  size: qrSize,
                                  backgroundColor: Colors.white,
                                  errorStateBuilder: (cxt, err) {
                                    return Center(
                                      child: Text(
                                        'ไม่สามารถสร้าง QR Code ได้',
                                        style: TextStyle(color: Colors.red.shade600),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Waiting indicator
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'รอการสแกน... (หมดอายุใน $remainingTime)',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ] else if (status == 'success') ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check, color: Colors.green.shade600, size: 48),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ยินดีต้อนรับ!',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                global.memberName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  statusCheckTimer?.cancel();
                                  Navigator.of(dialogContext).pop();

                                  // คำนวณราคาใหม่
                                  await _recalcPricesForPriceIndex();

                                  // แสดง welcome dialog
                                  _showMemberWelcomeDialog();

                                  // Refresh
                                  refresh();
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryThemeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('ตกลง'),
                              ),
                              const SizedBox(height: 20),
                            ] else if (status == 'expired') ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.timer_off, color: Colors.orange.shade600, size: 48),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'QR Code หมดอายุ',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'กรุณาสร้าง QR Code ใหม่',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => requestNewSession(setDialogState),
                                icon: const Icon(Icons.refresh),
                                label: const Text('สร้าง QR ใหม่'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryThemeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ] else if (status == 'error') ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'เกิดข้อผิดพลาด',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                errorMessage,
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => requestNewSession(setDialogState),
                                icon: const Icon(Icons.refresh),
                                label: const Text('ลองใหม่'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryThemeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      statusCheckTimer?.cancel();
    });
  }

  /// Dialog สำหรับแสดง PIN สมาชิก (Shop-initiated PIN)
  /// Flow: ร้านขอ PIN → แสดง PIN ให้ลูกค้ากรอกใน LINE → Polling เช็คสถานะ
  Future<void> _showMemberPinDialog() async {
    String generatedPin = '';
    String status = 'loading'; // loading, pending, success, expired, error
    String errorMessage = '';
    Timer? statusCheckTimer;
    Timer? countdownTimer;
    int remainingSeconds = 0;
    bool isRequestingPin = false;

    // ฟังก์ชันประมวลผลข้อมูลสมาชิก (ประกาศก่อนใช้)
    Future<void> processMemberData(Map<String, dynamic> customerData, String pinCode, StateSetter setDialogState) async {
      setDialogState(() {
        status = 'success';
      });

      // Set member data to global
      global.isMember = true;
      global.memberCode = "";
      global.lineDestination = customerData["destination"] ?? "";
      global.memberName = customerData["displayName"] ?? "";
      global.memberEmail = customerData["email"] ?? "";
      global.memberPicture = customerData["pictureUrl"] ?? "";
      global.memberPinCode = pinCode;
      global.priceIndex = 1;

      String lineUserId = customerData["userId"] ?? "";

      // Get or create debtor
      var memberData = await api.getDebtorByLine(code: lineUserId);
      Logger.d('MemberPinDialog: getDebtorByLine response: success=${memberData.success}, error=${memberData.error}, message=${memberData.message}, data=${memberData.data}');

      String messageStr = (memberData.message ?? "").toString().toLowerCase();
      bool isDocumentNotFound = messageStr.contains("document not found") || messageStr.contains("not found");

      if (!memberData.success) {
        Logger.d('MemberPinDialog: Creating new debtor (success=false, isDocumentNotFound=$isDocumentNotFound)');
        global.custNames = [
          TransNameInfoModel(name: global.memberName, code: "th", isauto: false, isdelete: false),
          TransNameInfoModel(name: global.memberName, code: "en", isauto: false, isdelete: false),
        ];
        try {
          await api.createDebtor(
            code: lineUserId,
            name: global.memberName,
            email: global.memberEmail,
            img: global.memberPicture,
          );
          Logger.d('MemberPinDialog: Debtor created successfully');
        } catch (e) {
          Logger.e('MemberPinDialog: Failed to create debtor', error: e);
        }
        global.memberPriceLevel = 1;
        global.priceIndex = 1;
      } else {
        Logger.d('MemberPinDialog: Using existing debtor data');
        global.memberCode = memberData.data["code"] ?? "";
        String pointsCode = (memberData.data["pointscode"] ?? "").toString();
        global.memberPointsCode = pointsCode.isNotEmpty ? pointsCode : (memberData.data["code"] ?? "").toString();
        var priceLevelRaw = memberData.data["pricelevel"];
        global.memberPriceLevel = (priceLevelRaw is int) ? priceLevelRaw : int.tryParse(priceLevelRaw?.toString() ?? "2") ?? 2;
        if (global.memberPriceLevel == 1) {
          global.memberPriceLevel = 1;
        }
        global.memberGuidFixed = (memberData.data["guidfixed"] ?? "").toString();
        var pointBalanceRaw = memberData.data["pointbalance"];
        if (pointBalanceRaw is double) {
          global.memberPointBalance = pointBalanceRaw;
        } else if (pointBalanceRaw is int) {
          global.memberPointBalance = pointBalanceRaw.toDouble();
        } else {
          global.memberPointBalance = double.tryParse(pointBalanceRaw?.toString() ?? "0") ?? 0;
        }
        global.priceIndex = global.memberPriceLevel;
        List<TransNameInfoModel> names = (memberData.data["names"] as List?)?.map((data) => TransNameInfoModel.fromJson(data)).toList() ?? global.custNames;
        global.custNames = names;
      }

      Logger.d('MemberPinDialog: Final priceIndex=${global.priceIndex}, memberPriceLevel=${global.memberPriceLevel}');

      // Delay เล็กน้อยเพื่อให้เห็น success state
      await Future.delayed(const Duration(milliseconds: 800));

      // ปิด dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // คำนวณราคาใหม่
      await _recalcPricesForPriceIndex();

      // Show welcome dialog
      _showMemberWelcomeDialog();

      // Refresh cart
      refresh();
      setState(() {});

      Logger.d('MemberPinDialog: Member linked successfully - ${global.memberName}');
    }

    // ฟังก์ชันขอ PIN ใหม่
    Future<void> requestNewPin(StateSetter setDialogState) async {
      if (isRequestingPin) return;
      isRequestingPin = true;

      setDialogState(() {
        status = 'loading';
        errorMessage = '';
      });

      try {
        var result = await api.shopRequestMemberPin(global.deviceConfig.shopId);
        Logger.d('shopRequestMemberPin result: $result');

        if (result['success'] == true && result['data'] != null) {
          generatedPin = result['data']['pin'] ?? '';
          remainingSeconds = result['data']['expiresIn'] ?? 300;

          setDialogState(() {
            status = 'pending';
          });

          // เริ่ม countdown timer
          countdownTimer?.cancel();
          countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (remainingSeconds > 0) {
              remainingSeconds--;
              setDialogState(() {});
            } else {
              timer.cancel();
              statusCheckTimer?.cancel();
              setDialogState(() {
                status = 'expired';
              });
            }
          });

          // เริ่ม polling เช็คสถานะทุก 3 วินาที
          statusCheckTimer?.cancel();
          statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
            if (status != 'pending') {
              timer.cancel();
              return;
            }

            try {
              var statusResult = await api.shopCheckMemberPinStatus(generatedPin, global.deviceConfig.shopId);
              Logger.d('shopCheckMemberPinStatus result: $statusResult');

              if (statusResult['success'] == true && statusResult['data'] != null) {
                String pinStatus = statusResult['data']['status'] ?? '';

                if (pinStatus == 'success') {
                  timer.cancel();
                  countdownTimer?.cancel();

                  // ดึงข้อมูลลูกค้า
                  var customerData = statusResult['data']['customer'];
                  if (customerData != null) {
                    await processMemberData(customerData, generatedPin, setDialogState);
                  }
                }
              } else if (statusResult['success'] == false) {
                // PIN หมดอายุหรือไม่พบ
                String error = statusResult['error'] ?? '';
                if (error.contains('expired') || error.contains('not found')) {
                  timer.cancel();
                  countdownTimer?.cancel();
                  setDialogState(() {
                    status = 'expired';
                  });
                }
              }
            } catch (e) {
              Logger.e('Error polling PIN status', error: e);
            }
          });
        } else {
          setDialogState(() {
            status = 'error';
            errorMessage = result['error'] ?? global.language("error_occurred_please_try_again");
          });
        }
      } catch (e) {
        Logger.e('requestNewPin error', error: e);
        setDialogState(() {
          status = 'error';
          errorMessage = global.language("error_occurred_please_try_again");
        });
      } finally {
        isRequestingPin = false;
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // ขอ PIN เมื่อเปิด dialog ครั้งแรก
            if (status == 'loading' && generatedPin.isEmpty && !isRequestingPin) {
              Future.microtask(() => requestNewPin(setDialogState));
            }

            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            final isSmallScreen = screenWidth < 600;
            final isMediumScreen = screenWidth >= 600 && screenWidth < 900;

            final dialogWidth = isSmallScreen
                ? screenWidth * 0.9
                : isMediumScreen
                    ? 400.0
                    : 450.0;
            final logoSize = isSmallScreen ? 100.0 : 120.0;
            final pinBoxSize = isSmallScreen ? 52.0 : 60.0;
            final padding = isSmallScreen ? 16.0 : 24.0;
            final lineOaImg = global.shopProfile?.orderstation.lineoaimg ?? "";

            // Format remaining time
            String formatTime(int seconds) {
              int mins = seconds ~/ 60;
              int secs = seconds % 60;
              return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.85,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              global.language("add_friend_collect_points"),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 17 : 19,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                statusCheckTimer?.cancel();
                                countdownTimer?.cancel();
                                Navigator.of(dialogContext).pop();
                              },
                              icon: Icon(Icons.close, color: Colors.grey.shade400, size: 22),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // LINE OA QR Image
                        if (lineOaImg.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  global.language("add_friend"),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: lineOaImg,
                                    width: logoSize,
                                    height: logoSize,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => Container(
                                      width: logoSize,
                                      height: logoSize,
                                      color: Colors.grey.shade100,
                                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      width: logoSize,
                                      height: logoSize,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.qr_code_2, size: 50, color: Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Content based on status
                        if (status == 'loading') ...[
                          const SizedBox(height: 20),
                          CircularProgressIndicator(color: primaryThemeColor),
                          const SizedBox(height: 16),
                          Text(
                            global.language("loading"),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ] else if (status == 'pending') ...[
                          // PIN Label
                          Text(
                            global.language("enter_pin_in_line"),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // PIN Display
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: generatedPin.split('').map((digit) {
                              return Container(
                                width: pinBoxSize,
                                height: pinBoxSize,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: primaryThemeColor.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: primaryThemeColor.withAlpha(100),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    digit,
                                    style: TextStyle(
                                      fontSize: pinBoxSize * 0.5,
                                      fontWeight: FontWeight.bold,
                                      color: primaryThemeColor,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          // Countdown Timer
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: remainingSeconds <= 60 ? Colors.red.shade50 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 18,
                                  color: remainingSeconds <= 60 ? Colors.red.shade600 : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${global.language("expires_in")} ${formatTime(remainingSeconds)}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    fontWeight: FontWeight.w500,
                                    color: remainingSeconds <= 60 ? Colors.red.shade600 : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Waiting indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                global.language("waiting_for_confirmation"),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Refresh PIN button
                          TextButton.icon(
                            onPressed: () => requestNewPin(setDialogState),
                            icon: Icon(Icons.refresh, size: 18, color: primaryThemeColor),
                            label: Text(
                              global.language("request_new_pin"),
                              style: TextStyle(color: primaryThemeColor),
                            ),
                          ),
                        ] else if (status == 'success') ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              size: 48,
                              color: Colors.green.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            global.language("verification_successful"),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ] else if (status == 'expired') ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.timer_off,
                              size: 48,
                              color: Colors.orange.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            global.language("pin_expired"),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => requestNewPin(setDialogState),
                            icon: const Icon(Icons.refresh),
                            label: Text(global.language("request_new_pin")),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryThemeColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ] else if (status == 'error') ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage.isNotEmpty ? errorMessage : global.language("error_occurred_please_try_again"),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: Colors.red.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => requestNewPin(setDialogState),
                            icon: const Icon(Icons.refresh),
                            label: Text(global.language("try_again")),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryThemeColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      statusCheckTimer?.cancel();
      countdownTimer?.cancel();
    });
  }

  void _showMemberWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Auto close after 3 seconds (increased to show point balance)
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile picture
                if (global.memberPicture.isNotEmpty)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(global.memberPicture),
                    onBackgroundImageError: (_, __) {},
                  )
                else
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: primaryThemeColor.withAlpha(30),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: primaryThemeColor,
                    ),
                  ),
                const SizedBox(height: 16),

                // Welcome text
                Text(
                  '${global.language("welcome")}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),

                // Member name
                Text(
                  global.memberName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Point balance display
                // if (global.memberPointBalance > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade100, Colors.amber.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, size: 20, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '${global.language("point_balance")}: ${global.moneyFormat.format(global.memberPointBalance)} ${global.language("points")}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Success icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 32,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void reloadProductList() {
    // ตรวจสอบ mounted ก่อนทำอะไร
    if (!mounted) return;

    _productReloadDebouncer?.cancel();

    _productReloadDebouncer = Timer(const Duration(milliseconds: 300), () {
      // ตรวจสอบ mounted อีกครั้งหลัง delay
      if (!mounted) return;
      if (isLoadingProducts) return;

      setState(() {
        isLoadingProducts = true;
      });

      try {
        // Set success status and update other necessary states
        loadProductProcessSuccess = true;

        // Force UI rebuild to show latest data
        if (mounted) {
          setState(() {
            // Update UI with existing data
          });
        }
      } catch (e, s) {
        // PERFORMANCE: Use Logger instead of print (debug only)
        Logger.e("Error loading products", tag: 'ProductList', error: e, stackTrace: s);
        loadProductProcessSuccess = false;
      } finally {
        if (mounted) {
          setState(() {
            isLoadingProducts = false;
          });
        }
      }
    });
  }

  /// Update product quantity in stock management
  /// mode: 0=change quantity (absolute), 1=add quantity (relative)
  /// Returns true if operation was completed successfully, false if cancelled or failed
  Future<bool> updateQty(int mode, int productIndex) async {
    // Validate product has stock management enabled
    if (!global.productList[productIndex].isstockforrestaurant) {
      Logger.w('updateQty: Product does not have stock management enabled', tag: 'StockManagement');
      return false;
    }

    final TextEditingController qtyController = TextEditingController();
    final String productName = global.getNameFromLanguage(global.productList[productIndex].names, global.languageForCustomer);
    final String unitName =
        global.getNameFromLanguage(global.productList[productIndex].unitnames, global.languageForCustomer); // Store the text value after dialog - will be populated when dialog closes
    String? inputText;

    // Show input dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                mode == 0 ? Icons.edit : Icons.add_circle_outline,
                color: primaryThemeColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "${mode == 0 ? global.language("qty_change") : global.language("qty_add")} : $productName",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mode == 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          global.language("qty_change_warning") != "qty_change_warning" ? global.language("qty_change_warning") : "This will set the stock to the absolute value you enter",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: '${global.language("qty")} ($unitName)',
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  helperText: mode == 0
                      ? (global.language("enter_absolute_qty") != "enter_absolute_qty" ? global.language("enter_absolute_qty") : "Enter absolute quantity")
                      : (global.language("enter_qty_to_add") != "enter_qty_to_add" ? global.language("enter_qty_to_add") : "Enter quantity to add"),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                global.language("cancel"),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Store text value before closing dialog
                inputText = qtyController.text.trim();
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryThemeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(global.language("confirm")),
            ),
          ],
        );
      },
    );

    // Store the input text before disposing (in case user pressed confirm but we haven't captured it)
    inputText ??= qtyController.text.trim();

    // Dispose controller after dialog is fully closed
    // Use addPostFrameCallback to ensure dialog cleanup is complete
    await Future.delayed(const Duration(milliseconds: 50));
    qtyController.dispose();

    // User cancelled
    if (result != true) {
      return false;
    }

    // Validate input
    if (inputText!.isEmpty) {
      if (mounted) {
        _showStockUpdateErrorDialog(
          global.language("invalid_input") != "invalid_input" ? global.language("invalid_input") : "Invalid Input",
          global.language("please_enter_quantity") != "please_enter_quantity" ? global.language("please_enter_quantity") : "Please enter a quantity",
        );
      }
      return false;
    }

    // Parse and validate quantity
    final double? parsedQty = double.tryParse(inputText!);
    if (parsedQty == null || parsedQty < 0) {
      if (mounted) {
        _showStockUpdateErrorDialog(
          global.language("invalid_quantity") != "invalid_quantity" ? global.language("invalid_quantity") : "Invalid Quantity",
          global.language("qty_must_be_positive") != "qty_must_be_positive" ? global.language("qty_must_be_positive") : "Quantity must be 0 or greater",
        );
      }
      return false;
    }

    // Additional confirmation for Mode 0 (change quantity)
    if (mode == 0) {
      final confirmed = await _showStockChangeConfirmationDialog(
        productName: productName,
        newQty: parsedQty,
        unitName: unitName,
      );

      if (confirmed != true) {
        return false;
      }
    }

    // Show loading dialog
    if (!mounted) {
      return false;
    }

    bool isLoadingDialogShowing = true;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryThemeColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  global.language("updating_stock") != "updating_stock" ? global.language("updating_stock") : "Updating stock...",
                ),
              ),
            ],
          ),
        );
      },
    );

    // Helper to close loading dialog
    void closeLoadingDialog() {
      if (isLoadingDialogShowing && mounted) {
        isLoadingDialogShowing = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    try {
      final String barcode = global.productList[productIndex].barcode;
      final String shopId = global.deviceConfig.shopId;
      final String branchId = global.deviceConfig.branchId;
      final String deviceId = global.deviceConfig.orderStationCode;

      Logger.d('updateQty: Starting - mode=$mode, barcode=$barcode, qty=$parsedQty', tag: 'StockManagement');

      if (mode == 0) {
        // Mode 0: Change quantity (absolute)
        // Step 1: Delete old records
        await api
            .clickHouseExecute("alter table ${global.clickHouseDatabaseName}.ordertempcalcqty "
                "delete where shopid='$shopId' and branchid='$branchId' "
                "and barcode='$barcode' and (isclose=9 or isclose=1)")
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException('Delete operation timeout'),
            );

        // Step 2: Get current balance
        final double currentBalance = await global.getBalanceQtyFromServer(barcode: barcode, isclose: 0).timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException('Get balance timeout'),
            );

        // Step 3: Calculate difference and insert
        final double qtyDiff = parsedQty - currentBalance;

        Logger.d('updateQty: Mode 0 - currentBalance=$currentBalance, targetQty=$parsedQty, diff=$qtyDiff', tag: 'StockManagement');

        await api
            .clickHouseExecute("INSERT INTO ${global.clickHouseDatabaseName}.ordertempcalcqty "
                "(shopid,branchid,deviceid,barcode,qty,isclose,orderdatetime) "
                "VALUES ('$shopId', '$branchId', '$deviceId', '$barcode', $qtyDiff, 9, now())")
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException('Insert operation timeout'),
            );
      } else {
        // Mode 1: Add quantity (relative)
        Logger.d('updateQty: Mode 1 - adding $parsedQty', tag: 'StockManagement');

        await api
            .clickHouseExecute("INSERT INTO ${global.clickHouseDatabaseName}.ordertempcalcqty "
                "(shopid,branchid,deviceid,barcode,qty,isclose,orderdatetime) "
                "VALUES ('$shopId', '$branchId', '$deviceId', '$barcode', $parsedQty, 9, now())")
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException('Insert operation timeout'),
            );
      }

      // Close loading dialog
      closeLoadingDialog();

      // Show success message
      if (mounted) {
        _showStockUpdateSuccessDialog(
          productName: productName,
          mode: mode,
          qty: parsedQty,
          unitName: unitName,
        );
      }

      // Clear selection and refresh
      productSelectedBarcode = "";
      refresh();

      Logger.d('updateQty: Success', tag: 'StockManagement');

      if (mounted) {
        setState(() {});
      }

      return true; // Operation completed successfully
    } catch (e, s) {
      // Close loading dialog
      closeLoadingDialog();

      Logger.e('updateQty error', error: e, stackTrace: s, tag: 'StockManagement');
      global.sendErrorToDevTeam("updateQty error: mode=$mode, product=${global.productList[productIndex].barcode}, error=$e");

      if (mounted) {
        _showStockUpdateErrorDialog(
          global.language("error"),
          e is TimeoutException
              ? (global.language("connection_timeout") != "connection_timeout" ? global.language("connection_timeout") : "Connection timeout. Please check your internet connection.")
              : (global.language("operation_failed") != "operation_failed" ? global.language("operation_failed") : "Operation failed. Please try again."),
        );
      }
      return false; // Operation failed
    }
  }

  /// Show confirmation dialog for changing stock quantity (Mode 0)
  Future<bool?> _showStockChangeConfirmationDialog({
    required String productName,
    required double newQty,
    required String unitName,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  global.language("confirm_change") != "confirm_change" ? global.language("confirm_change") : "Confirm Change",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                global.language("confirm_stock_change_message") != "confirm_stock_change_message"
                    ? global.language("confirm_stock_change_message")
                    : "You are about to set the stock to an absolute value:",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryThemeColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryThemeColor.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.inventory_2, color: primaryThemeColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${global.language("new_stock")}: ${global.moneyFormat.format(newQty)} $unitName',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: primaryThemeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                global.language("this_action_cannot_be_undone") != "this_action_cannot_be_undone" ? global.language("this_action_cannot_be_undone") : "This action cannot be undone.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                global.language("cancel"),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryThemeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(global.language("confirm")),
            ),
          ],
        );
      },
    );
  }

  /// Show error dialog for stock update
  void _showStockUpdateErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryThemeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(global.language("ok")),
            ),
          ],
        );
      },
    );
  }

  /// Show success dialog for stock update
  void _showStockUpdateSuccessDialog({
    required String productName,
    required int mode,
    required double qty,
    required String unitName,
  }) {
    // Track if dialog is still showing
    bool isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        // Auto close after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (isDialogOpen && mounted) {
            try {
              Navigator.of(dialogContext, rootNavigator: true).pop();
            } catch (e) {
              // Dialog already closed, ignore
            }
          }
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                global.language("success") != "success" ? global.language("success") : "Success",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                productName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                mode == 0
                    ? (global.language("stock_changed_to") != "stock_changed_to"
                        ? '${global.language("stock_changed_to")} ${global.moneyFormat.format(qty)} $unitName'
                        : 'Stock changed to ${global.moneyFormat.format(qty)} $unitName')
                    : (global.language("stock_added") != "stock_added"
                        ? '${global.language("stock_added")} ${global.moneyFormat.format(qty)} $unitName'
                        : 'Added ${global.moneyFormat.format(qty)} $unitName'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    ).then((_) {
      isDialogOpen = false;
    });
  }

  /// Check if category has products with stock management enabled
  bool _categoryHasStockProducts(int categoryIndex) {
    if (categoryIndex == -1 || categoryIndex >= global.categoryList.length) {
      return false;
    }

    final category = global.categoryList[categoryIndex];
    for (var product in category.codelist) {
      final productIndex = global.findProductByBarcode(product.barcode);
      if (productIndex != -1) {
        final productData = global.productList[productIndex];
        if (productData.isstockforrestaurant == true) {
          return true; // Found at least one product with stock management
        }
      }
    }
    return false;
  }

  void selectCategory(int index) {
    if (global.categoryIndex == index) return;

    setState(() {
      global.countDownForHome = global.countDownForHomeMax;
      global.categoryIndex = index;
      productSelectedBarcode = "";
      isSearch = false;
      searchController.clear();
      if (productScrollController.hasClients) {
        productScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }); // PERFORMANCE: Reload stock data only if category has stock-managed products
    if (_categoryHasStockProducts(index)) {
      api.reloadProductProcessFromServer().then((_) {
        if (mounted) reloadProductList();
      });
    }

    refresh();
  }

  /// PERFORMANCE: Handle product tap logic (extracted from buildProductItem)
  /// This reduces widget tree rebuilds by separating UI from logic
  Future<void> _handleProductTap(CategoryCodeListModel product, ProductProcessModel productData, int productIndex) async {
    // Handle orderType 5: Toggle product enable/disable status
    if (global.orderType == 5) {
      try {
        if (global.productList[productIndex].issell == true) {
          // Temporarily stop selling
          await api
              .clickHouseExecute(
                  "INSERT INTO ${global.clickHouseDatabaseName}.ordertempbarcodecancel (shopid,branchid,barcode) VALUES ('${global.deviceConfig.shopId}', '${global.deviceConfig.branchId}', '${global.productList[productIndex].barcode}')")
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw TimeoutException('Connection timeout'),
              );
          global.productList[productIndex].issell = false;
        } else {
          // Resume selling
          await api
              .clickHouseExecute(
                  "alter table ${global.clickHouseDatabaseName}.ordertempbarcodecancel delete where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and barcode='${global.productList[productIndex].barcode}'")
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw TimeoutException('Connection timeout'),
              );
          global.productList[productIndex].issell = true;
        }
        setState(() {});
      } catch (e, s) {
        Logger.e('Error toggling product status', error: e, stackTrace: s);
        if (mounted) {
          _showConnectionErrorDialog();
        }
      }
      return;
    }

    // Disabled for orderType 6
    if (global.orderType == 6) return;

    global.countDownForHome = global.countDownForHomeMax;

    // Show loading dialog
    if (!mounted) return;

    // Track if dialog is showing to prevent multiple close attempts
    bool isDialogShowing = true;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(global.language("checking_product_availability")),
            ],
          ),
        );
      },
    );

    // Helper function to safely close dialog
    void closeLoadingDialog() {
      if (isDialogShowing && mounted) {
        isDialogShowing = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    try {
      // Fetch data from server concurrently with timeout
      final results = await Future.wait<dynamic>([
        global.getProductCancelFromServerByItem(product.barcode),
        global.getBalanceQtyAllFromServerByItem(product.barcode),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timeout - please check your internet connection');
        },
      );

      // Close loading dialog
      closeLoadingDialog();

      // Extract values from Future.wait
      bool issellx = results[0] as bool;
      double valuex = results[1] as double;

      if (!mounted) return; // Check if out of stock
      if (productData.isstockforrestaurant == true && valuex <= 0) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(global.language("warning")),
            content: Text(global.language("out_of_stock")),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(global.language("ok")),
              ),
            ],
          ),
        );
        setState(() {});
        return;
      }

      // Check if sale is paused
      if (issellx == false) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(global.language("warning")),
            content: Text(global.language("pause_sale")),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(global.language("ok")),
              ),
            ],
          ),
        );
        setState(() {});
        return;
      }

      // If everything is ready, show order screen
      productSelectedBarcode = product.barcode;
      productSelected = productData;
      productSelected.qty = 1;

      // Reset options
      productSelected.remark = "";
      for (int optionIndex = 0; optionIndex < productSelected.options.length; optionIndex++) {
        for (int choiceIndex = 0; choiceIndex < productSelected.options[optionIndex].choices.length; choiceIndex++) {
          productSelected.options[optionIndex].choices[choiceIndex].selected = false;
        }
      }

      // ✅ FIX: Always set price based on current priceIndex (not just priceIndex == 2)
      // รองรับราคาจากช่องทางการขายทุกประเภท
      setState(() {
        productSelected.setprice = global.findProductPrice(prices: productSelected.prices);
      });
      if (mounted) {
        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              contentPadding: const EdgeInsets.all(8),
              content: StatefulBuilder(
                builder: (builderContext, StateSetter setState) {
                  String message = global.getNameFromLanguage(productSelected.names, global.languageForCustomer);
                  if (productSelected.options.isNotEmpty) {
                    message += " ${global.language('please_select_option')} ${global.language('and')}";
                  }
                  message += " ${global.language('confirm_to_order')}";
                  global.textToSpeech(message);

                  return orderAnimationOneProductOptionWidget(
                    orderGuid: "",
                    calcStockQty: false,
                    isAppend: true,
                    context: dialogContext,
                    product: productSelected,
                    refresh: () {
                      setState(() {});
                    },
                    onClose: () async {
                      Navigator.pop(dialogContext);
                      productSelectedBarcode = "";
                      refresh();
                    },
                  );
                },
              ),
            );
          },
        );
      }
    } catch (e, s) {
      // Close loading dialog if still open
      closeLoadingDialog();

      Logger.e('Error in product tap handler', error: e, stackTrace: s);

      if (mounted) {
        // Show user-friendly error message
        _showConnectionErrorDialog();
      }
    }
  }

  /// Show connection error dialog with retry option
  void _showConnectionErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        // Use fallback text if language key not found
        String errorTitle = global.language("connection_error");
        if (errorTitle == "connection_error") errorTitle = "Connection Error";

        String errorMessage = global.language("connection_error_message");
        if (errorMessage == "connection_error_message") {
          errorMessage = "Unable to connect to server. Please check your internet connection.";
        }

        String tryAgainText = global.language("please_try_again");
        if (tryAgainText == "please_try_again") tryAgainText = "Please try again.";

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Text(
                tryAgainText,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                global.language("ok"),
                style: TextStyle(color: primaryThemeColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildProductItem(CategoryCodeListModel product) {
    int productIndex = global.findProductByBarcode(product.barcode);
    if (productIndex == -1) return const SizedBox.shrink();

    // PERFORMANCE: Use cached kitchen printer lookup (O(1) instead of O(n*m))
    final kitchenPrinterName = _kitchenPrinterCache.getKitchenPrinterName(product.barcode);

    final productData = global.productList[productIndex];
    final bool productIsReady = productData.issell && !(productData.isstockforrestaurant == true && productData.stockqty <= 0) && global.findProductPrice(prices: productData.prices) > 0;

    // Pre-compute stock info
    final bool showStockInfo = productData.isstockforrestaurant == true;
    final double stockQty = productData.stockqty;
    final String unitName = global.getNameFromLanguage(productData.unitnames, global.languageForCustomer);

    // STOCK ADJUSTMENT MODE: orderType = 6 shows stock management buttons instead of normal tap
    if (global.orderType == 6 && productData.isstockforrestaurant == true) {
      return Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                OptimizedProductItemWidget(
                  product: product,
                  productData: productData,
                  productIsReady: productIsReady,
                  kitchenPrinterName: kitchenPrinterName,
                  onTap: () {}, // No tap action in stock adjustment mode
                  showStockInfo: showStockInfo,
                  stockQty: stockQty,
                  unitName: unitName,
                ),
                // Order quantity badge
                if ((product.orderqty ?? 0) > 0)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.deepOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrange.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'x${(product.orderqty ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildStockManagementButtons(context, productIndex),
        ],
      );
    }

    // CHANGE PRODUCT STATUS MODE: orderType = 5 shows enable/disable overlay
    if (global.orderType == 5) {
      return Stack(
        children: [
          OptimizedProductItemWidget(
            product: product,
            productData: productData,
            productIsReady: true, // Always enable tap for orderType 5
            kitchenPrinterName: kitchenPrinterName,
            onTap: () => _handleProductTap(product, productData, productIndex),
            showStockInfo: showStockInfo,
            stockQty: stockQty,
            unitName: unitName,
          ),
          // Status overlay for orderType 5 - clickable
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleProductTap(product, productData, productIndex),
                borderRadius: BorderRadius.circular(12),
                child: productData.issell == true
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              global.language("is_open"),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              global.language("is_closed"),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ), // Transparent when closed, but still clickable
              ),
            ),
          ),
          // Order quantity badge
          if ((product.orderqty ?? 0) > 0)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'x${(product.orderqty ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // PERFORMANCE: Use optimized widget instead of building Card inline
    return Stack(
      children: [
        OptimizedProductItemWidget(
          product: product,
          productData: productData,
          productIsReady: productIsReady,
          kitchenPrinterName: kitchenPrinterName,
          onTap: () => _handleProductTap(product, productData, productIndex),
          showStockInfo: showStockInfo,
          stockQty: stockQty,
          unitName: unitName,
        ),
        // Order quantity badge
        if ((product.orderqty ?? 0) > 0)
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                'x${(product.orderqty ?? 0).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildProductGrid() {
    if (global.categoryIndex == -1 || global.categoryList.isEmpty) {
      return Center(
        child: Text(
          global.language("no_category_selected"),
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final List<CategoryCodeListModel> products = [];
    final searchText = searchController.text.trim().toLowerCase();

    if (searchText.isEmpty) {
      // Show products from selected category
      products.addAll(global.categoryList[global.categoryIndex].codelist);
    } else {
      // Show search results - ค้นหาเฉพาะในหมวด "สินค้าทั้งหมด" (guidfixed = "00000000000000000")
      int allProductCategoryIndex = global.categoryList.indexWhere((c) => c.guidfixed == "00000000000000000");

      if (allProductCategoryIndex != -1) {
        for (var product in global.categoryList[allProductCategoryIndex].codelist) {
          bool matchFound = false;

          // Check if product name contains search text
          for (var name in product.names) {
            if (name.name.toLowerCase().contains(searchText)) {
              matchFound = true;
              break;
            }
          }

          // Check if barcode contains search text
          if (!matchFound && product.barcode.toLowerCase().contains(searchText)) {
            matchFound = true;
          }

          if (matchFound) {
            products.add(product);
          }
        }
      }
    }

    // Sort products: available products first, out-of-stock/paused products last
    products.sort((a, b) {
      int productIndexA = global.findProductByBarcode(a.barcode);
      int productIndexB = global.findProductByBarcode(b.barcode);

      bool aReady = true;
      bool bReady = true;

      if (productIndexA != -1) {
        var productA = global.productList[productIndexA];
        aReady = productA.issell && !(productA.isstockforrestaurant == true && productA.stockqty <= 0) && global.findProductPrice(prices: productA.prices) > 0;
      }

      if (productIndexB != -1) {
        var productB = global.productList[productIndexB];
        bReady = productB.issell && !(productB.isstockforrestaurant == true && productB.stockqty <= 0) && global.findProductPrice(prices: productB.prices) > 0;
      }

      if (aReady && !bReady) return -1; // a available, b not -> a first
      if (!aReady && bReady) return 1; // b available, a not -> b first
      return 0; // same status, keep original order
    });

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              searchText.isEmpty ? "${global.language('no_products_in_category')}" : "${global.language('no_results_for')} \"$searchText\"",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // RESPONSIVE: Calculate items per row based on screen width
        int itemsPerRow;
        if (global.deviceConfig.itemsPerRow > 0) {
          itemsPerRow = global.deviceConfig.itemsPerRow;
        } else {
          double screenWidth = constraints.maxWidth;
          if (screenWidth >= 768) {
            itemsPerRow = 3;
          } else {
            itemsPerRow = 2;
          }
        }

        return GridView.builder(
          controller: productScrollController,
          padding: const EdgeInsets.all(5),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: itemsPerRow,
            childAspectRatio: 0.70,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          cacheExtent: 500, // Increase cache to reduce widget creation when scrolling
          itemCount: products.length,
          itemBuilder: (context, index) {
            // Use RepaintBoundary to reduce repaint
            return RepaintBoundary(
              child: buildProductItem(products[index]),
            );
          },
        );
      },
    );
  }

  Widget buildCategoryItem(int index) {
    final category = global.categoryList[index];
    final isSelected = index == global.categoryIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  const Color(0xFFB85C38), // สีอิฐแดง
                  const Color(0xFF8B4513), // สีน้ำตาลเข้ม
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : const Color(0xFFFFFBF5), // สีครีมอ่อน
        borderRadius: BorderRadius.circular(3),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFB85C38).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => selectCategory(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                // Category image
                Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: category.imageuri.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: category.imageuri,
                            fit: BoxFit.cover,
                            memCacheWidth: 100,
                            memCacheHeight: 100,
                            fadeInDuration: const Duration(milliseconds: 100),
                            placeholder: (context, url) => Container(
                              color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
                              child: Icon(Icons.image_not_supported, color: isSelected ? Colors.white : Colors.grey),
                            ),
                          )
                        : Container(
                            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                            child: Icon(
                              Icons.category,
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                  ),
                ),

                // Category name
                Expanded(
                  child: Text(
                    global.getNameFromLanguage(category.names, global.languageForCustomer),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // // Right indicator for selected item
                // if (isSelected)
                //   Container(
                //     margin: const EdgeInsets.only(left: 8),
                //     padding: const EdgeInsets.all(4),
                //     decoration: BoxDecoration(
                //       color: Colors.white.withOpacity(0.2),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: const Icon(
                //       Icons.arrow_forward_ios,
                //       size: 14,
                //       color: Colors.white,
                //     ),
                //   ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCategorySection() {
    if (global.categoryList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              global.language("no_categories_available"),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Category list
        Expanded(
          child: ListView.builder(
            controller: categoryScrollController,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: global.categoryList.length,
            itemBuilder: (context, index) => buildCategoryItem(index),
          ),
        ),

        // Bottom actions
        Container(
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Add Member button (when not a member and useMember is enabled)
              if (!global.isMember && global.deviceConfig.useMember)
                Showcase(
                  key: _memberKey,
                  description: global.language("showcase_member_desc"),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showAddMemberDialog,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryThemeColor.withAlpha(20), primaryThemeColor.withAlpha(10)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryThemeColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.person_add, size: 18, color: primaryThemeColor),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                global.language("add_member"),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryThemeColor,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 14, color: primaryThemeColor.withAlpha(150)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Member name display
              if (global.isMember && global.memberName.isNotEmpty)
                Text(
                  global.language("welcome"),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              if (global.isMember && global.memberName.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryThemeColor.withAlpha(30), primaryThemeColor.withAlpha(10)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: primaryThemeColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              global.memberName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: primaryThemeColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ), // Clear member button
                          InkWell(
                            onTap: () async {
                              // Clear member data
                              global.isMember = false;
                              global.memberCode = "";
                              global.memberName = "";
                              global.memberPicture = "";
                              global.memberEmail = "";
                              global.memberPinCode = "";
                              global.memberPointsCode = "";
                              global.memberPriceLevel = 1;
                              global.memberGuidFixed = "";
                              global.memberPointBalance = 0;
                              global.priceIndex = 1;
                              global.lineDestination = "";
                              global.custNames = [];

                              // คำนวณราคาใหม่ตาม priceIndex และอัพเดทใน ObjectBox
                              await _recalcPricesForPriceIndex();

                              // Refresh cart
                              refresh();
                              setState(() {});
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                      // แสดงแต้มคงเหลือ
                      // if (global.memberPointBalance > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.stars, size: 14, color: Colors.amber.shade700),
                            const SizedBox(width: 4),
                            Text(
                              '${global.language("point_balance")}: ${global.moneyFormat.format(global.memberPointBalance)} ${global.language("points")}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Text size controls
              Row(
                children: [
                  Expanded(
                    child: IconButton(
                      onPressed: _textScale > _minTextScale
                          ? () {
                              setState(() {
                                _textScale = (_textScale - _textScaleStep).clamp(_minTextScale, _maxTextScale);
                              });
                            }
                          : null,
                      icon: Icon(
                        Icons.text_decrease,
                        color: _textScale > _minTextScale ? Colors.black87 : Colors.grey.shade400,
                      ),
                      tooltip: global.language("zoom_out"),
                    ),
                  ),
                  // Text scale percentage display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '${(_textScale * 100).toInt()}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: _textScale < _maxTextScale
                          ? () {
                              setState(() {
                                _textScale = (_textScale + _textScaleStep).clamp(_minTextScale, _maxTextScale);
                              });
                            }
                          : null,
                      icon: Icon(
                        Icons.text_increase,
                        color: _textScale < _maxTextScale ? Colors.black87 : Colors.grey.shade400,
                      ),
                      tooltip: global.language("zoom_in"),
                    ),
                  ),
                ],
              ),
              // Language selection button
              if (global.orderType == 0 || global.orderType == 1)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SelectLanguagePage()),
                      );
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                'assets/flags/${global.languageForCustomer}.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              global.language("language"),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                ),

              // Search button
              // Showcase(
              //   key: _searchKey,
              //   description: global.language("showcase_search_desc"),
              //   child: Material(
              //     color: Colors.transparent,
              //     child: InkWell(
              //       onTap: () {
              //         global.countDownForHome = global.countDownForHomeMax;
              //         setState(() {
              //           isSearch = !isSearch;
              //         });
              //       },
              //       child: Padding(
              //         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              //         child: Row(
              //           children: [
              //             Container(
              //               padding: const EdgeInsets.all(6),
              //               decoration: BoxDecoration(
              //                 color: isSearch ? primaryThemeColor.withOpacity(0.1) : Colors.white,
              //                 borderRadius: BorderRadius.circular(8),
              //                 border: Border.all(color: isSearch ? primaryThemeColor : Colors.grey.shade300),
              //               ),
              //               child: Icon(
              //                 Icons.search,
              //                 size: 20,
              //                 color: isSearch ? primaryThemeColor : Colors.grey.shade700,
              //               ),
              //             ),
              //             const SizedBox(width: 12),
              //             Expanded(
              //               child: Text(
              //                 global.language("search"),
              //                 style: TextStyle(
              //                   fontSize: 14,
              //                   fontWeight: isSearch ? FontWeight.w600 : FontWeight.w500,
              //                   color: isSearch ? primaryThemeColor : Colors.black87,
              //                 ),
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ),
              //   ),
              // ),

              // How to use button (วิธีใช้?)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    global.countDownForHome = global.countDownForHomeMax;
                    _startShowcase();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Icon(
                            Icons.help_outline,
                            size: 20,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            global.language("how_to_use"),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ),
                        Icon(Icons.play_circle_outline, size: 20, color: Colors.amber.shade400),
                      ],
                    ),
                  ),
                ),
              ),

              // Order type indicator
              if (global.orderType == 0 || global.orderType == 1)
                Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryThemeColor,
                        primaryThemeColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: primaryThemeColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          global.orderType == 0 ? Icons.restaurant : Icons.takeout_dining,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          global.language(global.orderType == 0
                              ? 'order_to_eat_at_the_restaurant'
                              : global.orderType == 5
                                  ? "product_management"
                                  : global.orderType == 6
                                      ? "adjust_stock"
                                      : "order_takeout"),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget orderAnimationOneTempBody({
    required BuildContext context,
    required OrderTempDetailModel order,
    required Function onTab,
    bool useCompactMode = false,
  }) {
    // Find product from global
    var product = global.productList.firstWhere(
      (element) => element.barcode == order.barcode,
      orElse: () => ProductProcessModel(
          amount: 0,
          barcode: '',
          code: '',
          discountword: '',
          foodtype: 0,
          imageuri: '',
          isAlacarte: false,
          isexceptvat: false,
          issplitunitprint: false,
          names: [],
          options: [],
          orderguid: '',
          ordertypes: [],
          prices: [],
          qty: 0,
          refcategoryguid: '',
          remark: '',
          setprice: 0,
          type: 0,
          unitcode: '',
          unitnames: [],
          manufacturerguid: ''),
    );

    // Compact mode (Chip)
    if (useCompactMode) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTab(),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: primaryThemeColor.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryThemeColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Small product image
                if (product.imageuri.isNotEmpty)
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: CachedNetworkImage(
                        imageUrl: product.imageuri,
                        fit: BoxFit.cover,
                        memCacheWidth: 80,
                        memCacheHeight: 80,
                        fadeInDuration: const Duration(milliseconds: 100),
                        errorWidget: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),

                // Product name and quantity
                Flexible(
                  child: Text(
                    '${global.getNameFromLanguage(product.names, global.languageForCustomer)} x${order.qty.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryThemeColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Full mode (not used in this layout, but kept for compatibility)
    return Stack(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onTab(),
            child: SizedBox(
              width: 100,
              height: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: product.imageuri.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageuri,
                            fit: BoxFit.cover,
                            memCacheWidth: 120,
                            memCacheHeight: 120,
                            fadeInDuration: const Duration(milliseconds: 100),
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey.shade400,
                                size: 32,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.fastfood,
                              color: Colors.grey.shade400,
                              size: 32,
                            ),
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    color: Colors.white,
                    child: Text(
                      global.getNameFromLanguage(product.names, global.languageForCustomer),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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
        ),
        if (order.qty > 0)
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                global.moneyFormat.format(order.qty),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildCartSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: (global.orderType == 5 || global.orderType == 6) ? _buildSpecialModeButton() : _buildNormalCartButtons(),
    );
  }

  Widget _buildSpecialModeButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
      ),
      onPressed: () {
        backToHome();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.close,
              color: Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "${global.language("exit_screen")} : ${(global.orderType == 5) ? global.language("change_product_status") : global.language("improve_product_balance")}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalCartButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Row(
          children: [
            // Cancel button (Minimalist)
            Expanded(
              flex: isMobile ? 1 : 1,
              child: ElevatedButton.icon(
                onPressed: () async {
                  global.countDownForHome = global.countDownForHomeMax;
                  if (sumOrderQty == 0) {
                    backToHome();
                    return;
                  }
                  bool confirm = await showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              global.language("delete_all_items"),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: Text(
                              global.language("want_to_delete_all_item"),
                              style: const TextStyle(fontSize: 14),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey.shade600,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  global.language("cancel"),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(dialogContext, true),
                                child: Text(
                                  global.language("confirm"),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          );
                        },
                      ) ??
                      false;

                  if (confirm && mounted) {
                    backToHome();
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
                label: Text(
                  global.language("cancel"),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.grey.shade700,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18, horizontal: isMobile ? 16 : 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Cart button
            Expanded(
              flex: isMobile ? 2 : 2,
              child: Showcase(
                key: _cartKey,
                description: global.language("showcase_cart_desc"),
                child: ElevatedButton.icon(
                  onPressed: sumOrderQty == 0
                      ? null
                      : () async {
                          global.countDownForHome = global.countDownForHomeMax;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderAnimationOneCartPage(
                                barcode: "",
                                mode: (global.deviceConfig.systemCondition == 1) ? 1 : 0,
                              ),
                            ),
                          );
                          setState(() {});
                          refresh();
                        },
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    child: badges.Badge(
                      position: badges.BadgePosition.topEnd(top: -6, end: -6),
                      badgeStyle: badges.BadgeStyle(
                        badgeColor: sumOrderQty == 0 ? Colors.transparent : const Color(0xFFFFBC0D), // McDonald's yellow
                        padding: const EdgeInsets.all(4),
                      ),
                      badgeContent: Text(
                        global.moneyFormat.format(sumOrderQty),
                        style: TextStyle(
                          color: sumOrderQty == 0 ? Colors.transparent : Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${global.language("total_amount")} ${global.moneyFormat.format(sumOrderAmount)} ${global.language("money_baht")}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryThemeColor, // McDonald's red
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18, horizontal: isMobile ? 16 : 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      autoPlay: true,
      autoPlayDelay: const Duration(seconds: 5),
      onComplete: (index, key) {
        // Mark showcase as completed when finished
        if (key == _cartKey || (key == _memberKey && global.deviceConfig.useMember && !global.isMember)) {
          _markShowcaseCompleted();
        }
      },
      builder: (showcaseContext) {
        // Store the showcase context for later use
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showcaseContext = showcaseContext;
          }
        });

        return BlocListener<OrderTempBloc, OrderTempState>(
          listener: (orderTempContext, orderTempState) {
            if (orderTempState is OrderTempLoadSuccess) {
              setState(() {
                orderTempDetailList = orderTempState.orderTemp;
                sumOrderQty = 0;
                sumOrderAmount = 0;

                // Calculate totals
                for (var order in orderTempDetailList) {
                  sumOrderQty += order.qty;
                  sumOrderAmount += order.amount;
                }

                // Update product quantities in categories
                for (var category in global.categoryList) {
                  for (var product in category.codelist) {
                    product.orderqty = 0;
                    for (var order in orderTempDetailList) {
                      if (product.barcode == order.barcode) {
                        product.orderqty = (product.orderqty ?? 0) + order.qty;
                      }
                    }
                  }
                }

                // Summarize by barcode for cart summary
                orderTempSumByBarcodeList = [];
                for (var order in orderTempDetailList) {
                  int index = orderTempSumByBarcodeList.indexWhere((element) => element.barcode == order.barcode);
                  if (index == -1) {
                    orderTempSumByBarcodeList.add(order);
                  } else {
                    orderTempSumByBarcodeList[index].qty += order.qty;
                  }
                }
              });
            }
          },
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(_textScale),
            ),
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: const Color(0xFFF5EBE0), // สีอิฐบ้านเชียง
              // Mobile drawer for categories
              drawer: MediaQuery.of(context).size.width < 600 ? _buildMobileDrawer() : null,
              body: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // MOBILE LAYOUT: Use completely different layout for mobile
                      if (constraints.maxWidth < 600) {
                        return _buildMobileLayout(constraints);
                      }

                      // RESPONSIVE: Calculate category width based on screen size
                      double categoryWidth;
                      if (constraints.maxWidth < 600) {
                        categoryWidth = 80; // Mobile - icon only
                      } else if (constraints.maxWidth < 900) {
                        categoryWidth = 180; // Tablet
                      } else {
                        categoryWidth = 220; // Desktop/Kiosk
                      }

                      // Check layout preset: 0=Default (category left), 1=KFC Style (category top)
                      if (global.deviceConfig.orderLayoutPreset == 1) {
                        return _buildKfcStyleLayout(constraints);
                      }

                      return Column(
                        children: [
                          // Main content area with category and products
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left sidebar - Categories (Minimalist)
                                Showcase(
                                  key: _categoryKey,
                                  description: global.language("showcase_category_desc"),
                                  child: Container(
                                    width: categoryWidth,
                                    margin: const EdgeInsets.all(0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBF5), // สีครีมอ่อนสำหรับ sidebar
                                      borderRadius: BorderRadius.circular(0),
                                      border: Border(
                                        right: BorderSide(color: const Color(0xFFD4A373).withOpacity(0.3), width: 1),
                                      ),
                                    ),
                                    child: buildCategorySection(),
                                  ),
                                ),

                                // Right content - Products
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 0, top: 0, right: 0, bottom: 0),
                                    child: Column(
                                      children: [
                                        // Search bar - Modern
                                        if (isSearch)
                                          Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: searchController,
                                                    autofocus: false,
                                                    decoration: InputDecoration(
                                                      hintText: global.language('search'),
                                                      prefixIcon: const Icon(Icons.search, size: 22),
                                                      suffixIcon: searchController.text.isNotEmpty
                                                          ? IconButton(
                                                              icon: const Icon(Icons.clear, size: 22),
                                                              onPressed: () {
                                                                searchController.clear();
                                                                setState(() {});
                                                              },
                                                            )
                                                          : null,
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                        borderSide: BorderSide(color: const Color(0xFFD4A373).withOpacity(0.5), width: 1.5),
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                        borderSide: BorderSide(color: const Color(0xFFD4A373).withOpacity(0.5), width: 1.5),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                        borderSide: const BorderSide(color: Color(0xFFB85C38), width: 2),
                                                      ),
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                                    ),
                                                    onChanged: (value) {
                                                      setState(() {});
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      isSearch = false;
                                                      searchController.clear();
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.shade50,
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: Colors.red.shade300,
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 24,
                                                      color: Colors.red.shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                        // Category header (when not searching)
                                        if (!isSearch && global.categoryIndex != -1 && global.categoryList.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.all(18),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(4),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                if (global.categoryList[global.categoryIndex].imageuri.isNotEmpty)
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    margin: const EdgeInsets.only(right: 12),
                                                    // decoration: BoxDecoration(
                                                    //   borderRadius: BorderRadius.circular(8),
                                                    //   border: Border.all(
                                                    //     color: primaryThemeColor.withOpacity(0.3),
                                                    //     width: 2,
                                                    //   ),
                                                    // ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(6),
                                                      child: CachedNetworkImage(
                                                        imageUrl: global.categoryList[global.categoryIndex].imageuri,
                                                        fit: BoxFit.cover,
                                                        memCacheWidth: 80,
                                                        memCacheHeight: 80,
                                                        fadeInDuration: const Duration(milliseconds: 100),
                                                        errorWidget: (context, url, error) => Container(
                                                          color: Colors.grey.shade200,
                                                          child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                Expanded(
                                                  child: Text(
                                                    global.getNameFromLanguage(global.categoryList[global.categoryIndex].names, global.languageForCustomer),
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                // Search button
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      isSearch = !isSearch;
                                                      if (!isSearch) {
                                                        searchController.clear();
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    child: Icon(
                                                      Icons.search,
                                                      size: 24,
                                                      color: isSearch ? Colors.white : Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                        // Products grid
                                        Expanded(
                                          child: Showcase(
                                            key: _productKey,
                                            description: global.language("showcase_product_desc"),
                                            child: isLoadingProducts
                                                ? Center(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        CircularProgressIndicator(
                                                          valueColor: AlwaysStoppedAnimation<Color>(primaryThemeColor),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        Text(
                                                          global.language("loading_products"),
                                                          style: TextStyle(
                                                            color: Colors.grey.shade600,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : buildProductGrid(),
                                          ),
                                        ),

                                        // Order summary (if items in cart) - Minimalist
                                        if (orderTempSumByBarcodeList.isNotEmpty)
                                          Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.02),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.shopping_bag_outlined,
                                                      size: 18,
                                                      color: primaryThemeColor,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      global.language("cart_order"),
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: primaryThemeColor,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        '${orderTempSumByBarcodeList.length} ${global.language("items")}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: primaryThemeColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: orderTempSumByBarcodeList.map((order) {
                                                    return orderAnimationOneTempBody(
                                                      context: context,
                                                      order: order,
                                                      onTab: () async {
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => OrderAnimationOneCartPage(
                                                              barcode: order.barcode,
                                                              mode: 0,
                                                            ),
                                                          ),
                                                        );
                                                        refresh();
                                                      },
                                                      useCompactMode: true,
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  // // Floating Member QR Widget (when memberPinMode = false)
                  // if (global.deviceConfig.useMember && !global.isMember && !global.memberPinMode)
                  //   FloatingMemberQrWidget(
                  //     onMemberLinked: () {
                  //       // Refresh cart to recalculate with member prices
                  //       refresh();
                  //       setState(() {});
                  //     },
                  //   ),
                  // // Floating Member PIN Widget (when memberPinMode = true)
                  // if (global.deviceConfig.useMember && !global.isMember && global.memberPinMode)
                  //   FloatingMemberPinWidget(
                  //     onMemberLinked: () {
                  //       // Refresh cart to recalculate with member prices
                  //       refresh();
                  //       setState(() {});
                  //     },
                  //   ),
                ],
              ),
              // Hide bottomNavigationBar on mobile (< 600px) since mobile layout has its own bottom bar
              bottomNavigationBar: MediaQuery.of(context).size.width < 600 ? null : buildCartSummary(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockManagementButtons(BuildContext context, int productIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Change button (Mode 0)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Track if loading dialog is showing
                bool isLoadingDialogShowing = false;

                try {
                  // updateQty already has comprehensive error handling
                  // Returns true if operation was completed, false if cancelled or failed
                  final bool success = await updateQty(0, productIndex);

                  // Only reload if operation was successful
                  if (!success) return;

                  // Show loading for reload
                  if (!mounted) return;

                  isLoadingDialogShowing = true;
                  // showDialog(
                  //   context: context,
                  //   barrierDismissible: false,
                  //   builder: (_) => AlertDialog(
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(16),
                  //     ),
                  //     content: Row(
                  //       children: [
                  //         CircularProgressIndicator(
                  //           valueColor: AlwaysStoppedAnimation<Color>(primaryThemeColor),
                  //         ),
                  //         const SizedBox(width: 20),
                  //         const Expanded(
                  //           child: Text('กำลังโหลดข้อมูลใหม่...'),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // );

                  Logger.d('Stock buttons: Reloading stock data after Mode 0 update', tag: 'StockManagement');

                  await api.reloadProductProcessFromServer().timeout(
                    const Duration(seconds: 10),
                    onTimeout: () {
                      throw TimeoutException('Stock reload timeout');
                    },
                  );

                  if (mounted && isLoadingDialogShowing) {
                    isLoadingDialogShowing = false;
                    // Navigator.of(context).pop(); // Close loading
                    reloadProductList();
                  }

                  Logger.d('Stock buttons: Reload complete', tag: 'StockManagement');
                } catch (e, s) {
                  // Close loading if open
                  if (mounted && isLoadingDialogShowing) {
                    isLoadingDialogShowing = false;
                    try {
                      // Navigator.of(context).pop();
                    } catch (_) {}
                  }

                  Logger.e('Stock buttons: Reload failed', error: e, stackTrace: s, tag: 'StockManagement');

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Colors.white),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text('ไม่สามารถโหลดข้อมูลใหม่ได้ กรุณาลองอีกครั้ง'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.orange,
                        action: SnackBarAction(
                          label: 'ลองอีกครั้ง',
                          textColor: Colors.white,
                          onPressed: () async {
                            try {
                              await api.reloadProductProcessFromServer();
                              if (mounted) reloadProductList();
                            } catch (_) {}
                          },
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.update, size: 16),
              label: Text(
                global.language("change"),
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Add button (Mode 1)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Track if loading dialog is showing
                bool isLoadingDialogShowing = false;

                try {
                  // updateQty already has comprehensive error handling
                  // Returns true if operation was completed, false if cancelled or failed
                  final bool success = await updateQty(1, productIndex);

                  // Only reload if operation was successful
                  if (!success) return;

                  // Show loading for reload
                  if (!mounted) return;

                  isLoadingDialogShowing = true;
                  // showDialog(
                  //   context: context,
                  //   barrierDismissible: false,
                  //   builder: (_) => AlertDialog(
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(16),
                  //     ),
                  //     content: Row(
                  //       children: [
                  //         CircularProgressIndicator(
                  //           valueColor: AlwaysStoppedAnimation<Color>(primaryThemeColor),
                  //         ),
                  //         const SizedBox(width: 20),
                  //         const Expanded(
                  //           child: Text('กำลังโหลดข้อมูลใหม่...'),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // );

                  Logger.d('Stock buttons: Reloading stock data after Mode 1 update', tag: 'StockManagement');

                  await api.reloadProductProcessFromServer().timeout(
                    const Duration(seconds: 10),
                    onTimeout: () {
                      throw TimeoutException('Stock reload timeout');
                    },
                  );

                  if (mounted && isLoadingDialogShowing) {
                    isLoadingDialogShowing = false;
                    // Navigator.of(context).pop(); // Close loading
                    reloadProductList();
                  }

                  Logger.d('Stock buttons: Reload complete', tag: 'StockManagement');
                } catch (e, s) {
                  // Close loading if open
                  if (mounted && isLoadingDialogShowing) {
                    isLoadingDialogShowing = false;
                    try {
                      // Navigator.of(context).pop();
                    } catch (_) {}
                  }

                  Logger.e('Stock buttons: Reload failed', error: e, stackTrace: s, tag: 'StockManagement');

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Colors.white),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text('ไม่สามารถโหลดข้อมูลใหม่ได้ กรุณาลองอีกครั้ง'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.orange,
                        action: SnackBarAction(
                          label: 'ลองอีกครั้ง',
                          textColor: Colors.white,
                          onPressed: () async {
                            try {
                              await api.reloadProductProcessFromServer();
                              if (mounted) reloadProductList();
                            } catch (_) {}
                          },
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                global.language("replenish_products"),
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// KFC Style Layout - Categories at top, products below
  Widget _buildKfcStyleLayout(BoxConstraints constraints) {
    return Stack(
      children: [
        Column(
          children: [
            // Top: Action bar + Horizontal category bar
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action bar (language, search toggle) - MOVED TO TOP
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Text size controls
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                                onPressed: _textScale > _minTextScale
                                    ? () {
                                        setState(() {
                                          _textScale = (_textScale - _textScaleStep).clamp(_minTextScale, _maxTextScale);
                                        });
                                      }
                                    : null,
                                icon: Icon(
                                  Icons.text_decrease,
                                  size: 18,
                                  color: _textScale > _minTextScale ? Colors.black87 : Colors.grey.shade400,
                                ),
                                tooltip: global.language("zoom_out"),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '${(_textScale * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                                onPressed: _textScale < _maxTextScale
                                    ? () {
                                        setState(() {
                                          _textScale = (_textScale + _textScaleStep).clamp(_minTextScale, _maxTextScale);
                                        });
                                      }
                                    : null,
                                icon: Icon(
                                  Icons.text_increase,
                                  size: 18,
                                  color: _textScale < _maxTextScale ? Colors.black87 : Colors.grey.shade400,
                                ),
                                tooltip: global.language("zoom_in"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Language button
                        if (global.orderType == 0 || global.orderType == 1)
                          InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SelectLanguagePage()),
                              );
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.asset(
                                      'assets/flags/${global.languageForCustomer}.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    global.language("select_language"),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ), // Member name display (KFC style)
                        if (global.isMember && global.memberName.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryThemeColor.withAlpha(30), primaryThemeColor.withAlpha(15)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: primaryThemeColor.withAlpha(50)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person, size: 16, color: primaryThemeColor),
                                const SizedBox(width: 4),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 100),
                                      child: Text(
                                        global.memberName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: primaryThemeColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    // แสดงแต้มคงเหลือ
                                    if (global.memberPointBalance > 0)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.stars, size: 10, color: Colors.amber.shade700),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${global.moneyFormat.format(global.memberPointBalance)} ${global.language("points")}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.amber.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                // Clear member button
                                InkWell(
                                  onTap: () async {
                                    // Clear member data
                                    global.isMember = false;
                                    global.memberCode = "";
                                    global.memberName = "";
                                    global.memberPicture = "";
                                    global.memberEmail = "";
                                    global.memberPinCode = "";
                                    global.memberPointsCode = "";
                                    global.memberPriceLevel = 1;
                                    global.memberGuidFixed = "";
                                    global.memberPointBalance = 0;
                                    global.priceIndex = 1;
                                    global.lineDestination = "";
                                    global.custNames = [];

                                    // คำนวณราคาใหม่ตาม priceIndex และอัพเดทใน ObjectBox
                                    await _recalcPricesForPriceIndex();

                                    // Refresh cart
                                    refresh();
                                    setState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withAlpha(20),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.close, size: 14, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Order type badge
                        if (global.orderType == 0 || global.orderType == 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: global.orderType == 0 ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: global.orderType == 0 ? Colors.green.shade300 : Colors.orange.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  global.orderType == 0 ? Icons.restaurant : Icons.shopping_bag,
                                  size: 16,
                                  color: global.orderType == 0 ? Colors.green.shade700 : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  global.orderType == 0 ? global.language("order_eat_here") : global.language("order_take_away"),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: global.orderType == 0 ? Colors.green.shade700 : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 8),
                        // Search toggle
                        InkWell(
                          onTap: () {
                            setState(() {
                              isSearch = !isSearch;
                              if (!isSearch) {
                                searchController.clear();
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSearch ? primaryThemeColor : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSearch ? primaryThemeColor : Colors.grey.shade300,
                              ),
                            ),
                            child: Icon(
                              Icons.search,
                              size: 20,
                              color: isSearch ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search bar row (if searching)
                  if (isSearch)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: TextField(
                        controller: searchController,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: global.language('search'),
                          prefixIcon: const Icon(Icons.search, size: 22),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 22),
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color(0xFFD4A373).withOpacity(0.5), width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color(0xFFD4A373).withOpacity(0.5), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFB85C38), width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFFFBF5),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ), // Horizontal category list - BELOW action bar
                  if (!isSearch)
                    SizedBox(
                      height: 130,
                      child: global.categoryList.isEmpty
                          ? Center(
                              child: Text(
                                global.language("no_categories_available"),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                // Left arrow indicator
                                Container(
                                  width: 24,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.chevron_left,
                                    color: Colors.grey.shade400,
                                    size: 28,
                                  ),
                                ),
                                // Category list
                                Expanded(
                                  child: ListView.builder(
                                    controller: categoryScrollController,
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    itemCount: global.categoryList.length,
                                    itemBuilder: (context, index) {
                                      return _buildHorizontalCategoryItem(index);
                                    },
                                  ),
                                ),
                                // Right arrow indicator
                                Container(
                                  width: 24,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey.shade400,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                    ),
                ],
              ),
            ),
            // Products grid area
            Expanded(
              child: Container(
                color: const Color(0xFFF5F5F5),
                child: Column(
                  children: [
                    // Category header
                    if (!isSearch && global.categoryIndex != -1 && global.categoryList.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            if (global.categoryList[global.categoryIndex].imageuri.isNotEmpty)
                              Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.only(right: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: global.categoryList[global.categoryIndex].imageuri,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 72,
                                    memCacheHeight: 72,
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 18),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                global.getNameFromLanguage(global.categoryList[global.categoryIndex].names, global.languageForCustomer),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (global.categoryList[global.categoryIndex].codelist.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryThemeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${global.categoryList[global.categoryIndex].codelist.length} ${global.language("items")}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: primaryThemeColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    // Products grid
                    Expanded(
                      child: isLoadingProducts
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryThemeColor),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    global.language("loading_products"),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : buildProductGrid(),
                    ),
                    // Order summary (if items in cart)
                    if (orderTempSumByBarcodeList.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 18, color: primaryThemeColor),
                                const SizedBox(width: 8),
                                Text(
                                  global.language("cart_order"),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: primaryThemeColor,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${orderTempSumByBarcodeList.length} ${global.language("items")}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryThemeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: orderTempSumByBarcodeList.map((order) {
                                return orderAnimationOneTempBody(
                                  context: context,
                                  order: order,
                                  onTab: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderAnimationOneCartPage(
                                          barcode: order.barcode,
                                          mode: 0,
                                        ),
                                      ),
                                    );
                                    refresh();
                                  },
                                  useCompactMode: true,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ], // end of Column children
        ), // end of Column
        // Floating Member PIN Widget for KFC layout
        if (global.deviceConfig.useMember && !global.isMember)
          FloatingMemberPinWidget(
            onMemberLinked: () {
              // Refresh cart to recalculate with member prices
              refresh();
              setState(() {});
            },
          ),
      ], // end of Stack children
    ); // end of Stack
  }

  /// Horizontal category item for KFC style layout
  Widget _buildHorizontalCategoryItem(int index) {
    bool isSelected = global.categoryIndex == index;
    var category = global.categoryList[index];

    return GestureDetector(
      onTap: () {
        setState(() {
          global.categoryIndex = index;
          isSearch = false;
          searchController.clear();
        });
        productScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryThemeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryThemeColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryThemeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Category image - use Expanded to take available space
            Expanded(
              flex: 3,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 80, maxHeight: 80),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: category.imageuri.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: category.imageuri,
                          fit: BoxFit.cover,
                          memCacheWidth: 100,
                          memCacheHeight: 100,
                          fadeInDuration: const Duration(milliseconds: 100),
                          errorWidget: (context, url, error) => Icon(
                            Icons.fastfood,
                            color: isSelected ? Colors.white : Colors.grey.shade400,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.fastfood,
                        color: isSelected ? primaryThemeColor : Colors.grey.shade400,
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(height: 4),
            // Category name - use Expanded with FittedBox to prevent overflow
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  global.getNameFromLanguage(category.names, global.languageForCustomer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile Drawer for category selection
  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFFFFBF5),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFB85C38),
                    const Color(0xFF8B4513),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.category, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      global.language("categories"),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Category list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: global.categoryList.length,
                itemBuilder: (context, index) {
                  return _buildMobileDrawerCategoryItem(index);
                },
              ),
            ),
            // Bottom section - Member, Language, etc.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Column(
                children: [
                  // Member button
                  if (!global.isMember && global.deviceConfig.useMember)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _showAddMemberDialog();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: primaryThemeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryThemeColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_add, color: primaryThemeColor, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  global.language("add_member"),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: primaryThemeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Member info display
                  if (global.isMember && global.memberName.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryThemeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: primaryThemeColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  global.memberName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryThemeColor,
                                  ),
                                ),
                                Text(
                                  '${global.language("point_balance")}: ${global.moneyFormat.format(global.memberPointBalance)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              global.isMember = false;
                              global.memberCode = "";
                              global.memberName = "";
                              global.memberPointBalance = 0;
                              global.priceIndex = 1;
                              await _recalcPricesForPriceIndex();
                              refresh();
                              setState(() {});
                              if (mounted) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close, color: Colors.red, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Language selector
                  if (global.orderType == 0 || global.orderType == 1)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SelectLanguagePage()),
                          );
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  'assets/flags/${global.languageForCustomer}.png',
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  global.language("language"),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                            ],
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
    );
  }

  /// Mobile drawer category item
  Widget _buildMobileDrawerCategoryItem(int index) {
    final category = global.categoryList[index];
    final isSelected = index == global.categoryIndex;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          selectCategory(index);
          Navigator.pop(context);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [const Color(0xFFB85C38), const Color(0xFF8B4513)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFB85C38).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Category image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: category.imageuri.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: category.imageuri,
                          fit: BoxFit.cover,
                          memCacheWidth: 100,
                          memCacheHeight: 100,
                          errorWidget: (context, url, error) => Icon(
                            Icons.category,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.category,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
              ),
              const SizedBox(width: 12),
              // Category name
              Expanded(
                child: Text(
                  global.getNameFromLanguage(category.names, global.languageForCustomer),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Product count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : primaryThemeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category.codelist.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : primaryThemeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mobile layout - completely different structure for phones
  Widget _buildMobileLayout(BoxConstraints constraints) {
    return Column(
      children: [
        // Top app bar for mobile
        _buildMobileAppBar(),
        // Search bar (if active)
        if (isSearch)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: searchController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: global.language('search'),
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 22),
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFFD4A373).withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFFD4A373).withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFB85C38), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
        // Category header
        if (!isSearch && global.categoryIndex != -1 && global.categoryList.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (global.categoryList[global.categoryIndex].imageuri.isNotEmpty)
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: global.categoryList[global.categoryIndex].imageuri,
                        fit: BoxFit.cover,
                        memCacheWidth: 64,
                        memCacheHeight: 64,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 16),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    global.getNameFromLanguage(global.categoryList[global.categoryIndex].names, global.languageForCustomer),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryThemeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${global.categoryList[global.categoryIndex].codelist.length} ${global.language("items")}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryThemeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Products grid
        Expanded(
          child: isLoadingProducts
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryThemeColor),
                  ),
                )
              : buildProductGrid(),
        ),
        // Bottom bar with cart button
        _buildMobileBottomBar(),
      ],
    );
  }

  /// Mobile app bar
  Widget _buildMobileAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu button for drawer
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: Icon(Icons.menu, color: primaryThemeColor),
          ),
          // Order type indicator
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryThemeColor, primaryThemeColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    global.orderType == 0 ? Icons.restaurant : Icons.takeout_dining,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      global.language(global.orderType == 0
                          ? 'order_to_eat_at_the_restaurant'
                          : global.orderType == 5
                              ? "product_management"
                              : global.orderType == 6
                                  ? "adjust_stock"
                                  : "order_takeout"),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Search button
          IconButton(
            onPressed: () {
              global.countDownForHome = global.countDownForHomeMax;
              setState(() {
                isSearch = !isSearch;
              });
            },
            icon: Icon(
              Icons.search,
              color: isSearch ? primaryThemeColor : Colors.grey.shade700,
            ),
          ),
          // Cancel/Back button
          IconButton(
            onPressed: () => backToHome(),
            icon: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }

  /// Mobile bottom bar with cart button
  Widget _buildMobileBottomBar() {
    if (global.orderType == 5 || global.orderType == 6) {
      return Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => backToHome(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.close, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                global.language("exit_screen"),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cart preview button
          if (orderTempSumByBarcodeList.isNotEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showMobileCartBottomSheet(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: badges.Badge(
                    position: badges.BadgePosition.topEnd(top: -8, end: -8),
                    badgeStyle: badges.BadgeStyle(
                      badgeColor: const Color(0xFFB85C38),
                      padding: const EdgeInsets.all(5),
                    ),
                    badgeContent: Text(
                      '${orderTempSumByBarcodeList.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Icon(Icons.shopping_bag_outlined, color: primaryThemeColor, size: 24),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),
          // Checkout button
          Expanded(
            child: ElevatedButton(
              onPressed: sumOrderQty == 0
                  ? null
                  : () async {
                      global.countDownForHome = global.countDownForHomeMax;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderAnimationOneCartPage(
                            barcode: "",
                            mode: (global.deviceConfig.systemCondition == 1) ? 1 : 0,
                          ),
                        ),
                      );
                      setState(() {});
                      refresh();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryThemeColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${global.language("total_amount")} ${global.moneyFormat.format(sumOrderAmount)} ${global.language("money_baht")}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show cart items in bottom sheet for mobile
  void _showMobileCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(bottomSheetContext).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag, color: primaryThemeColor),
                    const SizedBox(width: 8),
                    Text(
                      global.language("cart_order"),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryThemeColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryThemeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${orderTempSumByBarcodeList.length} ${global.language("items")}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryThemeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey.shade200),
              // Cart items list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: orderTempSumByBarcodeList.length,
                  itemBuilder: (context, index) {
                    final order = orderTempSumByBarcodeList[index];
                    return _buildMobileCartItem(order);
                  },
                ),
              ),
              // Total and action buttons
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          global.language("total_amount"),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${global.moneyFormat.format(sumOrderAmount)} ${global.language("money_baht")}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryThemeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderAnimationOneCartPage(
                                barcode: "",
                                mode: (global.deviceConfig.systemCondition == 1) ? 1 : 0,
                              ),
                            ),
                          ).then((_) {
                            refresh();
                            setState(() {});
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryThemeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          global.language("proceed_to_checkout"),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Mobile cart item widget
  Widget _buildMobileCartItem(OrderTempDetailModel order) {
    final product = global.productList.firstWhere(
      (p) => p.barcode == order.barcode,
      orElse: () => ProductProcessModel(
        amount: 0,
        barcode: '',
        code: '',
        discountword: '',
        foodtype: 0,
        imageuri: '',
        isAlacarte: false,
        isexceptvat: false,
        issplitunitprint: false,
        names: [],
        options: [],
        orderguid: '',
        ordertypes: [],
        prices: [],
        qty: 0,
        refcategoryguid: '',
        remark: '',
        setprice: 0,
        type: 0,
        unitcode: '',
        unitnames: [],
        manufacturerguid: '',
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          Navigator.pop(context);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderAnimationOneCartPage(
                barcode: order.barcode,
                mode: 0,
              ),
            ),
          );
          refresh();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              // Product image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.imageuri.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: product.imageuri,
                          fit: BoxFit.cover,
                          memCacheWidth: 100,
                          memCacheHeight: 100,
                          errorWidget: (context, url, error) => Icon(
                            Icons.fastfood,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      )
                    : Icon(Icons.fastfood, color: Colors.grey.shade400),
              ),
              const SizedBox(width: 12),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      global.getNameFromLanguage(product.names, global.languageForCustomer),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${global.moneyFormat.format(order.amount)} ${global.language("money_baht")}',
                      style: TextStyle(
                        color: primaryThemeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Quantity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryThemeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'x${global.moneyFormat.format(order.qty)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryThemeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
