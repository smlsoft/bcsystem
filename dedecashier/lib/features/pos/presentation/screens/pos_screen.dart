import 'package:dedecashier/features/pos/presentation/screens/pos_screen_util.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_util.dart';
import 'package:dedecashier/features/pos/presentation/widgets/tier_stock_edit_dialog.dart';
import 'package:dedecashier/features/pos/presentation/widgets/pos_total_pay_panel.dart';
import 'package:dedecashier/features/pos/presentation/widgets/pos_member_search_widgets.dart';
import 'package:dedecashier/features/pos/presentation/widgets/pos_ui_helpers.dart';
import 'package:dedecashier/features/pos/presentation/widgets/pos_app_bar.dart';
import 'package:dedecashier/features/pos/presentation/handlers/pos_barcode_handler.dart';
import 'package:dedecashier/features/pos/presentation/handlers/pos_keyboard_handler.dart';
import 'package:dedecashier/services/coupon_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:dedecashier/model/json/member_model.dart';
import 'package:dedecashier/model/system/pos_pay_model.dart';
import 'package:dedecashier/util/menu_screen.dart';
import 'package:dedecashier/core/performance/app_performance_manager.dart';
import 'dart:ui';
import 'package:dedecashier/bloc/find_member_by_tel_name_bloc.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_bill_vat.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_cancel_bill.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_product_weight.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_reprint_bill.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_sale_channel.dart';
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:dedecashier/model/objectbox/promotion_struct.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:dedecashier/bloc/product_category_bloc.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:dedecashier/model/objectbox/product_category_struct.dart';
import 'package:dedecashier/model/json/product_option_model.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_num_pad.dart';
import 'package:dedecashier/widgets/product_card.dart';
import 'package:dedecashier/util/pos_compile_process.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:split_view/split_view.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dedecashier/services/find_employee.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_hold_bill.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:dedecashier/db/product_category_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dedecashier/widgets/numpad.dart';
import 'package:dedecashier/widgets/discount_pad.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dedecashier/services/find_item.dart';
import 'pay/pay_screen.dart';
import 'package:dedecashier/widgets/button.dart';
import 'package:dedecashier/db/pos_log_helper.dart';
import 'package:dedecashier/model/objectbox/pos_log_struct.dart';
import 'package:dedecashier/db/product_barcode_helper.dart';
import 'pos_process.dart';
import 'package:dedecashier/model/json/pos_process_model.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/model/find/find_item_model.dart';
import 'package:dedecashier/bloc/find_item_by_code_name_barcode_bloc.dart';
import 'package:dedecashier/util/widget_sound_extensions.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class PosScreen extends StatefulWidget {
  final global.PosScreenModeEnum posScreenMode;

  const PosScreen({super.key, required this.posScreenMode});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  // ⭐ Theme Colors: MARINEPOS = น้ำเงินเข้ม, อื่นๆ = อิฐบ้านเชียง (Terracotta)
  static final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);
  static final MaterialColor _themeSwatch = (F.appFlavor == Flavor.MARINEPOS)
      ? const MaterialColor(0xFF005598, <int, Color>{
          50: Color(0xFFE6EFF5),
          100: Color(0xFFB3D1E6),
          200: Color(0xFF80B3D7),
          300: Color(0xFF4D95C8),
          400: Color(0xFF2677B9),
          500: Color(0xFF005598),
          600: Color(0xFF004A85),
          700: Color(0xFF003D6E),
          800: Color(0xFF003057),
          900: Color(0xFF002340),
        })
      : const MaterialColor(0xFFB5651D, <int, Color>{
          50: Color(0xFFFBF5F0),
          100: Color(0xFFF5E6D8),
          200: Color(0xFFEAC9AC),
          300: Color(0xFFDEAB7F),
          400: Color(0xFFD18D52),
          500: Color(0xFFB5651D),
          600: Color(0xFF9A5518),
          700: Color(0xFF7F4513),
          800: Color(0xFF64350E),
          900: Color(0xFF4A2509),
        });

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool showDetail = false;
  final ScrollController groupSelectListScrollController = ScrollController();
  bool isVisible = true;
  late AutoScrollController autoScrollController;
  FocusNode mainFocusNode = FocusNode();
  // ValueNotifiers for optimized state management - reduces setState calls
  final ValueNotifier<String> qrCodeBarcodeScannerResultNotifier = ValueNotifier<String>("");
  final ValueNotifier<double> qrCodeBarcodeScannerQtyResultNotifier = ValueNotifier<double>(0);
  final ValueNotifier<bool> barcodeScanActiveNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<String> numericPadTextInputNotifier = ValueNotifier<String>("");
  final ValueNotifier<bool> qrCodeBarcodeScannerStartNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> qrCodeBarcodeScannerSuccessNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<String>> qrCodeBarcodeScannerHistoryNotifier = ValueNotifier<List<String>>([]);
  final ValueNotifier<bool> showButtonMenuNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<String> categoryGuidSelectedNotifier = ValueNotifier<String>("");
  final ValueNotifier<bool> displayDetailByBarcodeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> showNumericPadNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> showNumericPadTopNotifier = ValueNotifier<double>(100);
  final ValueNotifier<double> showNumericPadLeftNotifier = ValueNotifier<double>(100);
  final ValueNotifier<List<Widget>> widgetMessageNotifier = ValueNotifier<List<Widget>>([]);
  final ValueNotifier<String> widgetMessageImageUrlNotifier = ValueNotifier<String>("");
  final ValueNotifier<List<MemberModel>> findMemberResultNotifier = ValueNotifier<List<MemberModel>>([]);
  // 🔢 ValueNotifier สำหรับแสดง barcode buffer แบบ real-time
  final ValueNotifier<String> barcodeBufferNotifier = ValueNotifier<String>("");

  // 🎨 ValueNotifier สำหรับเก็บสถานะการค้นหาสินค้า (true = เจอ, false = ไม่เจอ)
  final ValueNotifier<bool?> barcodeSearchSuccess = ValueNotifier<bool?>(null);

  // Keep original variables for backward compatibility where needed
  String get qrCodeBarcodeScannerResult => qrCodeBarcodeScannerResultNotifier.value;
  set qrCodeBarcodeScannerResult(String value) => qrCodeBarcodeScannerResultNotifier.value = value;

  double get qrCodeBarcodeScannerQtyResult => qrCodeBarcodeScannerQtyResultNotifier.value;
  set qrCodeBarcodeScannerQtyResult(double value) => qrCodeBarcodeScannerQtyResultNotifier.value = value;

  bool get barcodeScanActive => barcodeScanActiveNotifier.value;
  set barcodeScanActive(bool value) => barcodeScanActiveNotifier.value = value;

  String get numericPadTextInput => numericPadTextInputNotifier.value;
  set numericPadTextInput(String value) => numericPadTextInputNotifier.value = value;

  bool get qrCodeBarcodeScannerStart => qrCodeBarcodeScannerStartNotifier.value;
  set qrCodeBarcodeScannerStart(bool value) => qrCodeBarcodeScannerStartNotifier.value = value;

  bool get qrCodeBarcodeScannerSuccess => qrCodeBarcodeScannerSuccessNotifier.value;
  set qrCodeBarcodeScannerSuccess(bool value) => qrCodeBarcodeScannerSuccessNotifier.value = value;

  List<String> get qrCodeBarcodeScannerHistory => qrCodeBarcodeScannerHistoryNotifier.value;
  set qrCodeBarcodeScannerHistory(List<String> value) => qrCodeBarcodeScannerHistoryNotifier.value = value;

  bool get showButtonMenu => showButtonMenuNotifier.value;
  set showButtonMenu(bool value) => showButtonMenuNotifier.value = value;

  String get categoryGuidSelected => categoryGuidSelectedNotifier.value;
  set categoryGuidSelected(String value) => categoryGuidSelectedNotifier.value = value;

  bool get displayDetailByBarcode => displayDetailByBarcodeNotifier.value;
  set displayDetailByBarcode(bool value) => displayDetailByBarcodeNotifier.value = value;

  bool get showNumericPad => showNumericPadNotifier.value;
  set showNumericPad(bool value) => showNumericPadNotifier.value = value;

  double get showNumericPadTop => showNumericPadTopNotifier.value;
  set showNumericPadTop(double value) => showNumericPadTopNotifier.value = value;

  double get showNumericPadLeft => showNumericPadLeftNotifier.value;
  set showNumericPadLeft(double value) => showNumericPadLeftNotifier.value = value;

  List<Widget> get widgetMessage => widgetMessageNotifier.value;
  set widgetMessage(List<Widget> value) => widgetMessageNotifier.value = value;

  String get widgetMessageImageUrl => widgetMessageImageUrlNotifier.value;
  set widgetMessageImageUrl(String value) => widgetMessageImageUrlNotifier.value = value;
  final TextEditingController empCode = TextEditingController();
  final FindItem findItemScreen = const FindItem();
  final debounce = global.Debounce(500);
  final List<FindItemModel> findItemByCodeNameLastResult = [];
  final List<MemberModel> findMemberByNameTelephoneLastResult = [];
  final TextEditingController textFindByTextController = TextEditingController();
  FocusNode? textFindByTextFocus;
  late TabController tabletTabController;
  SplitViewController splitViewController = SplitViewController(weights: [0.55, 0.45], limits: [WeightLimit(min: 0.1, max: 0.9)]);
  QRViewController? scanController;
  int splitViewMode = 1;
  double gridItemSize = 1;
  GlobalKey<PosNumPadState> posNumPadGlobalKey = GlobalKey();
  late double listTextHeight = global.posScreenListHeightGet();
  late TabController phoneTabController;
  int cashierPrinterIndex = -1;
  String detailDiscountFormula = "";
  final FlutterThermalPrinter _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
  late FocusNode _keyboardFocusNode;

  // เพิ่มตัวแปรสำหรับจัดการ barcode input
  String _barcodeBuffer = '';
  Timer? _barcodeTimer;
  Timer? _barcodeClearTimer; // Timer สำหรับเคลียร์ buffer หลัง 5 วินาที
  int _lastKeyTime = 0;
  bool _isProcessing = false; // 🔥 Flag ป้องกันการประมวลผลซ้ำ
  // ✅ Constants moved to PosKeyboardHandler

  /// Button size level (0=Default, 1=Small, 2=Medium, 3=Large)
  int buttonSizeLevel = 0;

  /// 0=Desktop,1=Tablet,2=Phone
  int deviceMode = 0;

  /// 0=Number,1=ค้นหาสินค้า,2=หมวดสินค้า,3=ค้นหาลูกค้า
  int desktopWidgetMode = 0;

  // 🎭 Animation controllers สำหรับ emoji
  late AnimationController _emojiScaleController;
  late AnimationController _emojiPulseController;
  late Animation<double> _emojiScaleAnimation;
  late Animation<double> _emojiPulseAnimation;

  // 📊 State variables สำหรับย่อ/ขยาย promotion sections
  bool _isPromotionWidgetCollapsed = false; // ซ่อน/แสดง promotionWidget ทั้งหมด
  bool _isPromotionProductExpanded = true; // ส่วนลดในรายการ
  bool _isPromotionBottomExpanded = true; // ส่วนลดท้ายบิล
  bool _isPromotionBonusExpanded = true; // ของแถม
  bool _isPromotionCouponExpanded = true; // คูปอง

  ProductBarcodeObjectBoxStruct product = ProductBarcodeObjectBoxStruct(
    barcode: "",
    color_select: "",
    image_or_color: true,
    color_select_hex: "",
    names: "",
    name_all: "",
    prices: "",
    images_url: "",
    unit_code: "",
    unit_stand: 1,
    unit_divide: 1,
    unit_names: "",
    new_line: 0,
    guid_fixed: "",
    item_code: "",
    item_guid: "",
    descriptions: "",
    options_json: "",
    isalacarte: true,
    ordertypes: "",
    vat_type: 1,
    product_count: 0,
    is_except_vat: false,
    issplitunitprint: false,
    is_resterant_use_stock: false,
    ref_barcode_json: "",
    food_type: 0,
    patterncode: "",
  );
  List<ProductOptionModel> productOptions = [];

  Future<void> checkSync() async {
    if (global.syncRefreshProductCategory) {
      AppLogger.info("syncRefreshProductCategory");
      global.syncRefreshProductCategory = false;
      context.read<ProductCategoryBloc>().add(ProductCategoryLoadStart(parentCategoryGuid: categoryGuidSelected));
    }
    if (global.syncRefreshProductBarcode) {
      AppLogger.info("syncRefreshProductBarcode");
      global.syncRefreshProductBarcode = false;
      await loadProductByCategory(categoryGuidSelected);
      processEvent(barcode: "", holdCode: global.posHoldActiveCode);
    }
  }

  void getPrinter() async {
    try {
      await _flutterThermalPrinterPlugin.getPrinters(connectionTypes: [ConnectionType.USB]);
      if (mounted) {
        setState(() {});
      }
    } on PlatformException {
      if (mounted) {
        setState(() {});
      }
    }
  }

  // ✅ Performance Cache - precache images to reduce loading time
  bool _imagesPrecached = false;

  // ✅ Precache images to reduce loading time
  Future<void> _precacheProductImages() async {
    if (_imagesPrecached || !mounted) return;
    _imagesPrecached = true;

    try {
      // Precache first 20 product images
      final productsToCache = global.productListByCategory.take(20);
      for (var product in productsToCache) {
        if (!mounted) break;
        if (product.images_url.isNotEmpty) {
          try {
            await precacheImage(AppImageCacheManager.getCachedNetwork(product.images_url), context);
          } catch (e) {
            // Silently ignore image precache errors
            AppLogger.debug('[PosScreen] Image precache failed: ${product.images_url}');
          }
        }
      }
      AppLogger.debug('[PosScreen] ✅ Precached ${productsToCache.length} product images');
    } catch (e) {
      AppLogger.error('[PosScreen] ⚠️ Image precaching error: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    // 🎭 Initialize emoji animation controllers
    _emojiScaleController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);

    _emojiPulseController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat(reverse: true);

    _emojiScaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _emojiScaleController, curve: Curves.easeInOut));

    _emojiPulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _emojiPulseController, curve: Curves.easeInOut));

    // 🐛 Debug: ตรวจสอบว่า animation ทำงานหรือไม่
    if (kDebugMode) {
      _emojiScaleAnimation.addListener(() {
        // AppLogger.debug('[Emoji] Scale: ${_emojiScaleAnimation.value}');
      });
      AppLogger.debug('🎭 Emoji animations initialized');
    }

    // ✅ Performance monitoring (Debug mode only)
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
      AppLogger.debug('🚀 Initializing...');
    }

    restartClearData();
    if (F.appFlavor == Flavor.MARINEPOS) {
      if (global.isDesktopScreen()) {
        deviceMode = 0;
      } else if (global.isTabletScreen()) {
        deviceMode = 0;
      } else {
        deviceMode = 2;
      }
      global.tempIsRestaurantSystem = false;
    } else if (F.appFlavor == Flavor.BCPOS) {
      global.tempIsRestaurantSystem = false;
      if (global.isDesktopScreen()) {
        deviceMode = 0;
      } else if (global.isTabletScreen()) {
        deviceMode = 0;
      } else {
        deviceMode = 2;
      }
    } else {
      global.tempIsRestaurantSystem = true;
      if (global.isDesktopScreen()) {
        deviceMode = 1;
      } else if (global.isTabletScreen()) {
        deviceMode = 1;
      } else {
        deviceMode = 2;
      }
    }

    _loadButtonSize();
    phoneTabController = TabController(length: 4, vsync: this);
    phoneTabController.addListener(() {
      global.playSound(sound: global.SoundEnum.buttonTing);
    });
    _keyboardFocusNode = FocusNode(); // เพิ่ม WidgetsBindingObserver เพื่อตรวจจับการเปลี่ยนแปลงสถานะแอป
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestKeyboardFocus();
    });

    context.read<ProductCategoryBloc>().add(ProductCategoryLoadStart(parentCategoryGuid: ''));
    checkOnline();
    // เรียกรายการประกอบการขายจาก Hold
    // global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData;
    //
    global.productCategoryCodeSelected.clear();
    autoScrollController = AutoScrollController(viewportBoundaryGetter: () => Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom), axis: Axis.vertical);
    processPromotionTemp();
    loadCategory();
    loadProductByCategory(categoryGuidSelected);

    tabletTabController = TabController(length: 5, vsync: this);
    tabletTabController.addListener(() {
      global.playSound(sound: global.SoundEnum.buttonTing);
      if (tabletTabController.index == 2) {
        textFindByTextController.text = "";
        findMemberByNameTelephoneLastResult.clear();
      }
    });

    // Performance Manager handles device and error checking automatically
    // No need for separate timers - they are consolidated in AppPerformanceManager
    global.syncRefreshProductCategory = true;
    processEvent(barcode: "", holdCode: global.posHoldActiveCode);
    checkSync();
    global.functionPosScreenRefresh = () {
      processEventRefresh(holdCode: global.posHoldActiveCode);
    };
    Timer(const Duration(seconds: 1), () async {
      await getProcessFromTerminal();
      // จอแสดงผล POS
      if (Platform.isAndroid) {
        if (global.isInternalCustomerDisplayConnected) {
          global.displayManager.showSecondaryDisplay(displayId: 1, routerName: global.internalCustomerDisplayPageName);
        }
      }
    });
    if (global.printerLocalStrongData.where((e) => e.printerConnectType == global.PrinterConnectEnum.usb).isNotEmpty) {
      getPrinter();
    }
    global.testPrinterConnect();
    for (int index = 0; index < global.printerLocalStrongData.length; index++) {
      if (index == 0) {
        // 0=Cashier พิมพ์ใบเสร็จ
        cashierPrinterIndex = index;
        break;
      }
    }

    // ✅ Precache images after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 🎁 โหลด Tier Promotions จาก CSV ตอนเข้าหน้า POS
      try {
        await _precacheProductImages();
        // await global.loadTierPromotions();
        if (kDebugMode) {
          AppLogger.success('✅ [PosScreen] Tier promotions loaded');
        }
      } catch (e) {
        AppLogger.error('[PosScreen] ⚠️ Failed to load tier promotions: $e');
      }
    });

    // ✅ Log initialization time (Debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.success('✅ Initialized in ${stopwatch.elapsedMilliseconds}ms');
      if (stopwatch.elapsedMilliseconds > 500) {
        AppLogger.warning('⚠️ Slow initialization! Consider lazy loading.');
      }
    }
  }

  void _requestKeyboardFocus() {
    if (mounted) {
      _keyboardFocusNode.requestFocus();
    }
  }

  void _removeKeyboardFocus() {
    if (mounted) {
      _keyboardFocusNode.unfocus();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    AppLogger.debug("App lifecycle changed: $state");

    switch (state) {
      case AppLifecycleState.resumed: // แอพกลับมาทำงาน - เริ่ม focus ใหม่
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _requestKeyboardFocus();
        });
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // แอพหยุดทำงาน - ยกเลิก focus
        _removeKeyboardFocus();
        // ยกเลิก barcode timer ด้วย
        _barcodeTimer?.cancel();
        _barcodeBuffer = '';
        break;
      case AppLifecycleState.hidden:
        // แอพถูกซ่อน - ยกเลิก focus
        _removeKeyboardFocus();
        break;
    }
  }

  @override
  void dispose() {
    // ⚡ Performance: Cancel timer เพื่อป้องกัน memory leak
    _barcodeTimer?.cancel();

    // 🎭 Dispose emoji animation controllers
    _emojiScaleController.dispose();
    _emojiPulseController.dispose();

    // ลบ WidgetsBindingObserver
    WidgetsBinding.instance.removeObserver(this);

    // Dispose QR Scanner
    try {
      scanController?.dispose();
    } catch (e) {
      AppLogger.error("QR Scanner dispose error: $e");
    }

    // ⚡ Performance: Dispose ValueNotifiers เพื่อป้องกัน memory leaks
    qrCodeBarcodeScannerResultNotifier.dispose();
    qrCodeBarcodeScannerQtyResultNotifier.dispose();
    barcodeScanActiveNotifier.dispose();
    numericPadTextInputNotifier.dispose();
    qrCodeBarcodeScannerStartNotifier.dispose();
    qrCodeBarcodeScannerSuccessNotifier.dispose();
    qrCodeBarcodeScannerHistoryNotifier.dispose();
    showButtonMenuNotifier.dispose();
    categoryGuidSelectedNotifier.dispose();
    displayDetailByBarcodeNotifier.dispose();
    showNumericPadNotifier.dispose();
    showNumericPadTopNotifier.dispose();
    showNumericPadLeftNotifier.dispose();
    widgetMessageNotifier.dispose();
    widgetMessageImageUrlNotifier.dispose();
    findMemberResultNotifier.dispose();
    barcodeBufferNotifier.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
    global.functionPosScreenRefresh = null;
    if (global.isTabletScreen() || global.isDesktopScreen()) {
      tabletTabController.dispose();
    }

    global.sendProcessToCustomerDisplay(mode: global.secondScreenCommandInformation);
    if (Platform.isAndroid) {
      if (global.isInternalCustomerDisplayConnected) {}
    }
    phoneTabController.dispose();
  }

  // ฟังก์ชันจัดการ KeyEvent (ใหม่)
  void _handleKeyEvent(KeyEvent event) {
    // ใช้ try-catch เพื่อป้องกันการ crash
    try {
      if (event is! KeyDownEvent) return;

      // ตรวจสอบว่าแอพยังมี focus และพร้อมรับ input หรือไม่
      if (!mounted) return;

      // ✅ ใช้ PosKeyboardHandler
      bool isInSearchMode = PosKeyboardHandler.isInSearchMode(deviceMode: deviceMode, desktopWidgetMode: desktopWidgetMode);

      // ตรวจสอบว่า keyboard focus node ยังใช้งานได้
      // 🔥 ถ้าอยู่ใน search mode → อนุญาตให้ TextField รับ input
      if (!_keyboardFocusNode.hasFocus && !isInSearchMode) {
        AppLogger.debug("Keyboard focus lost, attempting to refocus");
        // ลองขอ focus ใหม่
        _requestKeyboardFocus();
        return;
      }

      // Debug log สำหรับ Zebra Scanner
      if (kDebugMode) {
        AppLogger.debug('Key Event: ${event.logicalKey.keyLabel}');
        AppLogger.debug("Event character: '${event.character}'");
        AppLogger.debug('Event logical key: ${event.logicalKey}');
      }

      // ✅ ใช้ PosKeyboardHandler
      if (PosKeyboardHandler.isEnterKey(event.logicalKey)) {
        if (_barcodeBuffer.isNotEmpty) {
          AppLogger.debug("🎯 Enter pressed - force searching buffer: '$_barcodeBuffer'");

          // 🔥 ยกเลิก timers ทั้งหมด เพื่อป้องกันการเรียกซ้ำ
          _barcodeTimer?.cancel();
          _barcodeClearTimer?.cancel();
          _barcodeTimer = null; // 🔥 เซ็ต null เพื่อไม่ให้ timer เก่าทำงาน
          _barcodeClearTimer = null;

          // ค้นหาทันที
          if (isInSearchMode) {
            _processBarcodeInSearchMode();
          } else {
            _processBarcode();
          }
          return;
        }
      }

      // ✅ ใช้ PosKeyboardHandler
      if (PosKeyboardHandler.isBackspaceKey(event.logicalKey)) {
        if (_barcodeBuffer.isNotEmpty) {
          _barcodeBuffer = PosKeyboardHandler.handleBackspace(_barcodeBuffer);

          // อัปเดต overlay
          barcodeBufferNotifier.value = _barcodeBuffer;

          // ยกเลิก timers และรีเซ็ต
          _barcodeTimer?.cancel();
          _barcodeClearTimer?.cancel();

          // ถ้า buffer ว่างเปล่า ให้ปิด overlay
          if (_barcodeBuffer.isEmpty) {
            barcodeBufferNotifier.value = '';
            barcodeSearchSuccess.value = null;
          } else {
            // ตั้ง clear timer ใหม่ (5 วินาทีหลังจากไม่มีการพิมพ์)
            _barcodeClearTimer = Timer(const Duration(seconds: 5), () {
              _barcodeBuffer = '';
              barcodeBufferNotifier.value = '';
              barcodeSearchSuccess.value = null;
            });
          }
        }
        return; // ไม่ให้ไปประมวลผลต่อ
      }
      // ✅ ใช้ PosKeyboardHandler
      bool shouldProcessBarcode = PosKeyboardHandler.shouldProcessBarcode(deviceMode: deviceMode, tabletTabIndex: (deviceMode == 1) ? tabletTabController.index : null, desktopWidgetMode: desktopWidgetMode, isVisible: isVisible, barcodeScanActive: barcodeScanActive);

      AppLogger.debug("Should process barcode: $shouldProcessBarcode, deviceMode: $deviceMode, desktopWidgetMode: $desktopWidgetMode");
      if (!shouldProcessBarcode) return;

      // ✅ ใช้ PosKeyboardHandler
      String character = PosKeyboardHandler.getCharacterFromKeyEvent(event);
      if (character.isEmpty) {
        AppLogger.debug("No character extracted from key event");
        return;
      }

      AppLogger.debug("Character from key: '$character' (${character.codeUnits})");

      int currentTime = DateTime.now().millisecondsSinceEpoch;

      // ✅ ใช้ PosKeyboardHandler
      bool isPossibleScanner = PosKeyboardHandler.isPossibleScannerInput(currentTime, _lastKeyTime);
      _lastKeyTime = currentTime;

      // ใช้ isPossibleScanner เพื่อ debug หรือจัดการ logic เพิ่มเติม
      if (isPossibleScanner && kDebugMode) {
        // This indicates rapid input, likely from a barcode scanner
        AppLogger.debug("Rapid input detected - possible scanner");
      }

      // 🔥 NEW: ถ้าเป็น Scanner (rapid input) และอยู่ใน Search TextField
      // → Intercept barcode และค้นหาสินค้าทันที
      if (isPossibleScanner && isInSearchMode) {
        AppLogger.debug("🎯 Scanner detected in search mode - intercepting barcode");

        // 🚨 FIX: Clear numericPadTextInput ทันที เพื่อป้องกันตัวเลขแรกถูกใช้เป็น quantity!
        if (numericPadTextInput.isNotEmpty) {
          if (kDebugMode) {
            AppLogger.warning("⚠️ Clearing numericPadTextInput '$numericPadTextInput' (scanner detected)");
          }
          numericPadTextInput = '';
          // Clear UI ด้วย
          if (posNumPadGlobalKey.currentState != null) {
            posNumPadGlobalKey.currentState!.clear(silent: true);
          }
        }

        // เพิ่มตัวอักษรเข้า buffer
        _barcodeBuffer += character;
        barcodeBufferNotifier.value = _barcodeBuffer;

        AppLogger.debug("Barcode buffer: '$_barcodeBuffer'");

        // ✅ ใช้ PosKeyboardHandler
        _barcodeTimer?.cancel();
        _barcodeTimer = PosKeyboardHandler.createBarcodeTimer(
          onTimeout: () {
            AppLogger.debug("🔍 Scanner complete - searching and closing search mode");
            _processBarcodeInSearchMode();
          },
          isScanner: true,
        );

        // ยกเลิก clear timer
        _barcodeClearTimer?.cancel();

        return; // ไม่ให้ไปต่อที่ TextField
      }

      // ✅ ใช้ PosKeyboardHandler
      _barcodeBuffer = PosKeyboardHandler.addCharacterToBuffer(_barcodeBuffer, character);

      // 🔢 อัพเดท UI แบบ real-time
      // 🔥 NEW: แสดง overlay ยกเว้นตอนพิมพ์ใน TextField ค้นหา (mode 1, 3)
      // ✅ ใช้ PosKeyboardHandler
      bool shouldUpdateOverlay = PosKeyboardHandler.shouldShowOverlay(isInSearchMode: isInSearchMode, isPossibleScanner: isPossibleScanner, desktopWidgetMode: desktopWidgetMode);

      if (shouldUpdateOverlay) {
        barcodeBufferNotifier.value = _barcodeBuffer;
        AppLogger.debug("✅ Overlay updated: '$_barcodeBuffer'");
      } else {
        AppLogger.debug("❌ Overlay NOT updated (typing in search TextField)");
      }

      if (kDebugMode) {
        AppLogger.debug("Barcode buffer: '$_barcodeBuffer'");
        AppLogger.debug('Buffer length: ${_barcodeBuffer.length}');
        AppLogger.debug("Added character: '$character' (code: ${character.codeUnits})");
        AppLogger.debug("isInSearchMode: $isInSearchMode, isPossibleScanner: $isPossibleScanner");
        AppLogger.debug('shouldUpdateOverlay: $shouldUpdateOverlay');
      }

      // ✅ ใช้ PosKeyboardHandler
      _barcodeClearTimer?.cancel();
      _barcodeClearTimer = PosKeyboardHandler.createClearTimer(
        onTimeout: () {
          AppLogger.debug("No input for 2 seconds - clearing buffer");
          _barcodeBuffer = '';
          barcodeBufferNotifier.value = '';
        },
      );

      // รีเซ็ต scanner timer (สำหรับ rapid input จาก barcode scanner)
      _barcodeTimer?.cancel();

      // 🔥 ถ้าเป็น rapid input (barcode scanner) → ใช้ timer เดิม
      // 🔥 ถ้าเป็น keyboard → ค้นหาทันที
      if (isPossibleScanner) {
        // ✅ ใช้ PosKeyboardHandler
        _barcodeTimer = PosKeyboardHandler.createBarcodeTimer(
          onTimeout: () {
            AppLogger.debug("Scanner input complete - processing barcode");
            _processBarcode();
          },
          isScanner: true,
        );
      } else {
        // Keyboard input - ค้นหาทันที!
        AppLogger.debug("Keyboard input - searching immediately");
        _searchBarcodeImmediately();
      }

      // Handle numpad for desktop mode
      if (deviceMode == 0) {
        _handleNumpadInputKeyEvent(event);
      }
    } catch (e) {
      // จัดการ error ให้ไม่ crash
      AppLogger.error("Error in _handleKeyEvent: $e");
    }
  }

  // 🆕 ค้นหาสินค้าทันที (สำหรับ keyboard input)
  Future<void> _searchBarcodeImmediately() async {
    if (kDebugMode) {
      AppLogger.debug('🔔 _searchBarcodeImmediately called');
      AppLogger.debug("   Buffer: '$_barcodeBuffer'");
    }

    if (_barcodeBuffer.isEmpty) return;

    String cleanBarcode = PosBarcodeHandler.cleanBarcode(_barcodeBuffer);

    if (kDebugMode) {
      AppLogger.debug("🔍 Searching immediately for: '$cleanBarcode'");
      AppLogger.debug("   Raw buffer: '$_barcodeBuffer'");
      AppLogger.debug("   Clean barcode: '$cleanBarcode'");
      AppLogger.debug('Clean barcode length: ${cleanBarcode.length}');
    }

    // 🐛 FIX: ถ้า cleanBarcode ว่างเปล่า → ไม่ค้นหา, ไม่ clear buffer
    // รอตัวเลขถัดไป หรือ รอ 2 วิเพื่อ clear
    if (cleanBarcode.isEmpty) {
      AppLogger.debug("⚠️ Clean barcode is empty - keeping buffer, waiting for more input");
      return;
    }

    // 🔥 เช็ค format ก่อน (ต้องผ่าน basic validation)
    if (!PosBarcodeHandler.isValidBarcode(cleanBarcode)) {
      AppLogger.debug("⚠️ Invalid barcode format - keeping buffer, waiting for more digits");
      return;
    }

    // 🔥 แยก quantity*barcode ก่อนค้นหา
    String searchBarcode = cleanBarcode;
    if (cleanBarcode.contains('*')) {
      List<String> parts = cleanBarcode.split('*');
      if (parts.length == 2) {
        String qtyPart = parts[0].trim();
        String barcodePart = parts[1].trim();

        if (kDebugMode) {
          AppLogger.debug('🔍 Detected * in barcode, analyzing:');
          AppLogger.debug('   Left part (qty?): "$qtyPart"');
          AppLogger.debug('   Right part (barcode?): "$barcodePart"');
        }

        // ✅ Validation เข้มงวด
        bool isValidQtyFormat = qtyPart.isNotEmpty && qtyPart.length <= 6 && RegExp(r'^\d+(\.\d+)?$').hasMatch(qtyPart);
        bool isValidBarcodeFormat = barcodePart.isNotEmpty && barcodePart.length >= 3;

        if (isValidQtyFormat && isValidBarcodeFormat) {
          searchBarcode = barcodePart; // ใช้ส่วนบาร์โค้ดค้นหา
          if (kDebugMode) {
            AppLogger.success('✅ Valid quantity*barcode format');
            AppLogger.debug("   Searching for: '$searchBarcode' (from '$cleanBarcode')");
          }
        } else {
          if (kDebugMode) {
            AppLogger.warning('⚠️ Invalid quantity*barcode format, using full barcode');
          }
        }
      }
    }

    // 🔥 Query database เพื่อเช็กว่ามีสินค้าจริงหรือไม่
    ProductBarcodeObjectBoxStruct? productBarcodeSelect = await PosBarcodeHandler.searchProductByBarcode(searchBarcode);

    if (productBarcodeSelect != null) {
      // ✅ เจอสินค้า → เพิ่มเข้าบิล, เคลียร์ buffer
      if (kDebugMode) {
        AppLogger.success('✅ Product found! Adding to bill and clearing buffer');
        AppLogger.debug('Product: ${productBarcodeSelect.names}');
      }

      // ส่ง barcode เดิม (พร้อม quantity*) ให้ _handleBarcodeScanned แยก quantity
      await _handleBarcodeScanned(cleanBarcode);

      // เคลียร์ buffer ทันทีหลังเจอสินค้า
      _barcodeBuffer = '';

      // เคลียร์ overlay หลัง 5 วิ (แสดงบาร์โค้ดที่เจอก่อนหาย - เพิ่มเวลาสำหรับคนแก่)
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          barcodeBufferNotifier.value = '';
        }
      });

      // ยกเลิก clear timer เพราะเจอสินค้าแล้ว
      _barcodeClearTimer?.cancel();
    } else {
      // ❌ ไม่เจอสินค้า → เก็บ buffer, รอตัวเลขต่อไป
      // buffer จะถูก clear โดย _barcodeClearTimer เมื่อไม่กดอะไร 2 วิ
      if (kDebugMode) {
        AppLogger.error("❌ Product not found in database - keeping buffer '$_barcodeBuffer', waiting for more digits");
        AppLogger.debug('Clear timer will reset buffer in 2 seconds if no input');
      }
    }
  }

  // 🆕 ค้นหาสินค้าเมื่อสแกน barcode ขณะอยู่ใน Search TextField
  Future<void> _processBarcodeInSearchMode() async {
    // 🔥 เช็คว่า buffer ว่างหรือไม่ (ป้องกันการเรียกซ้ำ)
    if (_barcodeBuffer.isEmpty) {
      AppLogger.debug("⚠️ Buffer is empty - skipping duplicate _processBarcodeInSearchMode call");
      return;
    }

    String cleanBarcode = PosBarcodeHandler.cleanBarcode(_barcodeBuffer);

    if (kDebugMode) {
      AppLogger.debug("🔍 Processing barcode in search mode: '$cleanBarcode'");
      AppLogger.debug('Current mode: desktopWidgetMode=$desktopWidgetMode');
    }

    // เคลียร์ TextField
    textFindByTextController.clear();
    findItemByCodeNameLastResult.clear();

    // 🔥 เคลียร์ buffer ทันที เพื่อป้องกันการเรียกซ้ำ
    _barcodeBuffer = '';

    // แสดง overlay ชั่วคราว (จะปิดทันทีหลังประมวลผลเสร็จ)
    barcodeBufferNotifier.value = cleanBarcode;

    if (cleanBarcode.isEmpty || !PosBarcodeHandler.isValidBarcode(cleanBarcode)) {
      AppLogger.debug("⚠️ Invalid barcode in search mode");
      // ปิด overlay ทันที เพราะบาร์โค้ดไม่ถูกต้อง
      barcodeBufferNotifier.value = '';
      return;
    }

    // 🔥 แยก quantity*barcode ก่อนค้นหา (เหมือน _handleBarcodeScanned)
    String searchBarcode = cleanBarcode;
    if (cleanBarcode.contains('*')) {
      List<String> parts = cleanBarcode.split('*');
      if (parts.length == 2) {
        String qtyPart = parts[0].trim();
        String barcodePart = parts[1].trim();

        if (kDebugMode) {
          AppLogger.debug('🔍 Detected * in search mode, analyzing:');
          AppLogger.debug('   Left part (qty?): "$qtyPart"');
          AppLogger.debug('   Right part (barcode?): "$barcodePart"');
        }

        // ✅ Validation เข้มงวด
        bool isValidQtyFormat = qtyPart.isNotEmpty && qtyPart.length <= 6 && RegExp(r'^\d+(\.\d+)?$').hasMatch(qtyPart);
        bool isValidBarcodeFormat = barcodePart.length >= 3;

        if (isValidQtyFormat && isValidBarcodeFormat) {
          searchBarcode = barcodePart; // ใช้แค่ส่วน barcode ค้นหา
          if (kDebugMode) {
            AppLogger.success('✅ Valid quantity*barcode in search mode');
            AppLogger.debug('   Quantity: $qtyPart');
            AppLogger.debug('   Barcode: $searchBarcode');
          }
        } else {
          if (kDebugMode) {
            AppLogger.warning('⚠️ Invalid quantity*barcode format in search mode');
          }
        }
      }
    }

    // ค้นหาสินค้าด้วย barcode ที่แยกแล้ว
    ProductBarcodeObjectBoxStruct? productBarcodeSelect = await ProductBarcodeHelper().selectByBarcodeFirst(searchBarcode);

    if (productBarcodeSelect != null) {
      // ✅ เจอสินค้า → เพิ่มเข้าบิล
      if (kDebugMode) {
        AppLogger.success('✅ Product found in search mode! Adding to bill');
        AppLogger.debug('Product: ${productBarcodeSelect.names}');
        AppLogger.debug("🔊 [BARCODE FLOW] _processBarcodeInSearchMode calling _handleBarcodeScanned (product found)");
        AppLogger.debug('Barcode: $cleanBarcode');
      }

      // ตั้งค่าสถานะ: เจอสินค้า (สีน้ำเงิน)
      barcodeSearchSuccess.value = true;

      // ส่ง cleanBarcode เดิม (พร้อม quantity*) ให้ _handleBarcodeScanned แยก quantity
      await _handleBarcodeScanned(cleanBarcode);

      // ✅ ปิด overlay ทันทีหลังประมวลผลเสร็จ (กรณีเจอสินค้า)
      if (mounted) {
        barcodeBufferNotifier.value = '';
        barcodeSearchSuccess.value = null; // รีเซ็ตสถานะ
      }

      // 🏠 กลับไปหน้า # (PosNumPad) เหมือนกดปุ่ม #
      if (mounted) {
        setState(() {
          desktopWidgetMode = 0; // กลับไปหน้า # (PosNumPad)
        });

        // Request focus กลับมาที่ keyboard
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _requestKeyboardFocus();
        });
      }
    } else {
      // ❌ ไม่เจอสินค้า → ส่งต่อให้ _handleBarcodeScanned จัดการ
      // (ลบการเล่นเสียงออก เพราะ logInsert จะเล่นให้อยู่แล้ว)
      if (kDebugMode) {
        AppLogger.error('❌ Product not found in search mode - delegating to logInsert');
        AppLogger.debug("🔊 [BARCODE FLOW] _processBarcodeInSearchMode calling _handleBarcodeScanned (product not found)");
        AppLogger.debug('Barcode: $cleanBarcode');
      }

      // ตั้งค่าสถานะ: ไม่เจอสินค้า (สีแดง)
      barcodeSearchSuccess.value = false;

      // ส่งให้ _handleBarcodeScanned → logInsert → เล่นเสียง fail
      await _handleBarcodeScanned(cleanBarcode);

      // ❌ แสดง overlay สีแดงนาน 5 วินาที (กรณีไม่เจอสินค้า)
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          barcodeBufferNotifier.value = '';
          barcodeSearchSuccess.value = null; // รีเซ็ตสถานะ
        }
      });

      // 🏠 กลับไปหน้า # (PosNumPad) แม้ไม่เจอสินค้า
      if (mounted) {
        setState(() {
          desktopWidgetMode = 0; // กลับไปหน้า # (PosNumPad)
        });

        // Request focus กลับมาที่ keyboard
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _requestKeyboardFocus();
        });
      }
    }
  }

  // ❌ ลบ _isEnterKeyEvent ออก - ไม่ใช้แล้ว (auto-search แทน)

  // จัดการ numpad input สำหรับ desktop (KeyEvent)
  void _handleNumpadInputKeyEvent(KeyEvent event) {
    // ✅ ใช้ PosKeyboardHandler
    if (PosKeyboardHandler.isBackspaceKey(event.logicalKey)) {
      if (posNumPadGlobalKey.currentState != null) {
        posNumPadGlobalKey.currentState!.backspace();
      }

      // ✅ ใช้ PosKeyboardHandler
      _barcodeBuffer = PosKeyboardHandler.handleBackspace(_barcodeBuffer);

      // อัปเดต overlay
      barcodeBufferNotifier.value = _barcodeBuffer;

      AppLogger.debug("🔙 [BACKSPACE] Buffer updated: '$_barcodeBuffer'");

      // ยกเลิก timers และรีเซ็ต
      _barcodeTimer?.cancel();
      _barcodeClearTimer?.cancel();

      // ถ้า buffer ว่างเปล่า ให้ปิด overlay
      if (_barcodeBuffer.isEmpty) {
        barcodeBufferNotifier.value = '';
        barcodeSearchSuccess.value = null;
      } else {
        // ✅ ใช้ PosKeyboardHandler
        _barcodeClearTimer = PosKeyboardHandler.createClearTimer(
          onTimeout: () {
            _barcodeBuffer = '';
            barcodeBufferNotifier.value = '';
            barcodeSearchSuccess.value = null;
          },
        );
      }
    }

    // ✅ ใช้ PosKeyboardHandler
    String keyLabel = event.logicalKey.keyLabel;
    String numpadValue = PosKeyboardHandler.convertNumpadKeyLabel(keyLabel);
    if (PosKeyboardHandler.isValidNumpadKey(numpadValue)) {
      posNumPadGlobalKey.currentState?.addValue(numpadValue);
    }
  }

  // ประมวลผล barcode ที่สะสมใน buffer
  void _processBarcode() {
    if (kDebugMode) {
      AppLogger.debug('🔔 _processBarcode called (isProcessing: $_isProcessing)');
      AppLogger.debug('Stack trace: ${StackTrace.current}');
    }

    // 🔥 ป้องกันการประมวลผลซ้ำภายใน 500ms
    if (_isProcessing) {
      AppLogger.debug("⚠️ Already processing - skipping duplicate call");
      return;
    }

    _barcodeTimer?.cancel();

    // 🔥 เช็คว่า buffer ว่างหรือไม่ (ป้องกันการเรียกซ้ำ)
    if (_barcodeBuffer.trim().isEmpty) {
      AppLogger.debug("⚠️ Buffer is empty - skipping duplicate _processBarcode call");
      return;
    }

    // 🔥 ตั้ง flag เพื่อป้องกันการเรียกซ้ำ
    _isProcessing = true;

    if (kDebugMode) {
      AppLogger.debug('=== Processing barcode buffer ===');
      AppLogger.debug("Raw buffer: '$_barcodeBuffer'");
      AppLogger.debug('Buffer length: ${_barcodeBuffer.length}');
      AppLogger.debug('Buffer code units: ${_barcodeBuffer.codeUnits}');
    }

    String cleanBarcode = PosBarcodeHandler.cleanBarcode(_barcodeBuffer);

    // 🔢 เก็บค่าสุดท้ายไว้แสดงใน overlay อีก 5 วินาที (เพิ่มเวลาสำหรับคนแก่)
    final String displayBarcode = _barcodeBuffer;

    // 🔥 เคลียร์ buffer ทันที เพื่อป้องกันการเรียกซ้ำ
    _barcodeBuffer = '';

    // 🔢 เคลียร์ UI overlay หลังจาก 5 วินาที (ให้เห็นบาร์โค้ดก่อนหาย)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && barcodeBufferNotifier.value == displayBarcode) {
        barcodeBufferNotifier.value = '';
      }
    });

    if (kDebugMode) {
      AppLogger.debug("Clean barcode: '$cleanBarcode'");
      AppLogger.debug('Clean barcode length: ${cleanBarcode.length}');
      AppLogger.debug('Is valid barcode: ${PosBarcodeHandler.isValidBarcode(cleanBarcode)}');
    }

    if (PosBarcodeHandler.isValidBarcode(cleanBarcode)) {
      if (kDebugMode) {
        AppLogger.debug("🔊 [BARCODE FLOW] _processBarcode calling _handleBarcodeScanned");
        AppLogger.debug('Barcode: $cleanBarcode');
      }

      _handleBarcodeScanned(cleanBarcode).then((_) {
        // 🔥 เคลียร์ flag หลังประมวลผลเสร็จ
        _isProcessing = false;
        AppLogger.debug("✅ Processing complete - flag cleared");
      });
    } else {
      AppLogger.debug("Barcode validation failed for: '$cleanBarcode'");
      // เคลียร์ flag ทันที
      _isProcessing = false;
    }
  } // แปลงอักษรไทยเป็นตัวเลข (สำหรับ keyboard ภาษาไทย)

  // จัดการ barcode ที่สแกนได้
  Future<void> _handleBarcodeScanned(String barcode) async {
    // ✅ ใช้ PosBarcodeHandler แทนการประมวลผลเอง
    final result = await PosBarcodeHandler.handleBarcodeScanned(barcode: barcode, numericPadTextInput: numericPadTextInput);

    final String actualBarcode = result['barcode']!;
    final String quantity = result['quantity']!;

    if (global.posNumPadProductWeightGlobalKey.currentState != null) {
      // เปิดหน้าจอน้ำหนัก
      serviceLocator<Log>().debug('------------------------ Pass Barcode : $actualBarcode');
      global.posNumPadProductWeightGlobalKey.currentState!.passValue(actualBarcode);
    } else {
      if (isVisible == true || barcodeScanActive == true) {
        if (kDebugMode) {
          AppLogger.debug('🔊 [BARCODE FLOW] Calling logInsert from _handleBarcodeScanned');
          AppLogger.debug('Barcode: $actualBarcode');
          AppLogger.debug('Quantity: $quantity');
        }

        await logInsert(guid: "", commandCode: 1, barcode: actualBarcode, qty: quantity);
        numericPadTextInput = "";
      }
    }
  }

  Future<void> onSubmit(String number) async {
    number = number.trim().replaceAll("*", "X");
    String qty = "1.0";

    if (number.trim().isNotEmpty) {
      if (number.indexOf("X") > 0) {
        List<String> numberList = number.split("X");
        qty = numberList[0].trim();
        number = numberList[1].trim();
      }

      if (kDebugMode) {
        AppLogger.debug('🔊 [BARCODE FLOW] Calling logInsert from onSubmit');
        AppLogger.debug('Barcode: $number');
        AppLogger.debug('Quantity: $qty');
        AppLogger.debug('   Stack: ${StackTrace.current.toString().split('\n').take(5).join('\n')}');
      }

      await logInsert(guid: "", commandCode: 1, barcode: number, qty: qty);
    }
  }

  void loadCategory() {
    // ignore: unused_local_variable
    String categoryGuid = (global.productCategoryCodeSelected.isEmpty) ? "" : global.productCategoryCodeSelected[global.productCategoryCodeSelected.length - 1].guid_fixed;
  }

  Future<void> loadProductByCategory(String categoryGuid) async {
    // ✅ Performance monitoring (Debug mode only)
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
    }

    if (categoryGuid.isNotEmpty) {
      global.productCategoryChildList = await ProductCategoryHelper().selectByParentCategoryGuidOrderByXorder(parentGuid: categoryGuid);
      var selectCodeList = await ProductCategoryHelper().selectByCategoryGuidFindFirst(categoryGuid);
      global.productListByCategory = [];
      if (selectCodeList != null) {
        List<String> barcodeList = [];
        ProductCategoryObjectBoxStruct category = selectCodeList;
        for (var item in await jsonDecode(category.codelist)) {
          barcodeList.add(item["barcode"]);
        }
        var selectProductByBarcodeList = await ProductBarcodeHelper().selectByBarcodeList(barcodeList);
        for (var item in await jsonDecode(category.codelist)) {
          for (var product in selectProductByBarcodeList) {
            if (product.barcode == item["barcode"]) {
              global.productListByCategory.add(product);
              break;
            }
          }
        }
      }
    }

    // ✅ Log performance (Debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.success('[PosScreen] 📦 loadProductByCategory took ${stopwatch.elapsedMilliseconds}ms');
      if (stopwatch.elapsedMilliseconds > 100) {
        AppLogger.warning('[PosScreen] ⚠️ Slow category loading! Products: ${global.productListByCategory.length}');
      }
    }
  }

  Future<void> logInsert({
    /**  
      -- command
      1=เพิ่มสินค้า
      2=เพิ่มจำนวน + 1
      3=ลดจำนวน - 1
      4=แก้จำนวน
      5=แก้ราคา
      6=แก้ส่วนลด
      8=หมายเหตุ
      9=ลบรายการสินค้า
      80=เปิดลิ้นชัก
      99=เริ่มใหม่
      101=Check Box Extra
      **/
    required int commandCode,

    /// GUID ในระบบ ป้องกันการซ้ำกัน
    required String guid,

    /// รหัสอ้างอิงที่ถูกสร้างอัตโนมัติ
    String guidCodeRef = "",

    /// GUID Ref อ้างอิง (ส่วนหัวของรายการ)
    String guidRef = "",

    /// จำนวน
    String qty = "",

    /// ราคา
    double price = 0,

    /// ส่วนลด (Text)
    String discount = "",

    /// รหัสพิเศษ
    String extraCode = "",

    /// ?
    bool closeExtra = true,

    /// Barcode (กรณีมีการตัดสต๊อก)
    String barcode = "",

    /// รหัสสินค้า (กรณีมีการตัดสต๊อก)
    String code = "",

    /// ชื่อสินค้า
    String name = "",

    /// ?
    bool selected = false,

    /// ?
    String codeDefault = "",

    /// หมายเหตุ (อธิบายรายการ)
    String remark = "",

    /// รหัสหน่วยนับ
    String unitCode = "",

    /// ชื่อหน่วยนับ
    String unitName = "",
  }) async {
    // 🔥 LOG: เพิ่ม log เพื่อติดตามการเรียก
    if (kDebugMode) {
      AppLogger.debug('🎯 logInsert called:');
      AppLogger.debug('commandCode: $commandCode');
      AppLogger.debug('barcode: $barcode');
      AppLogger.debug("   Stack trace: ${StackTrace.current.toString().split('\n').take(5).join('\n')}");
    }

    int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
    double qtyForCalc = 0;
    double priceForCalc = price;

    // ถ้าไม่มีรหัสสินค้า ให้ใช้ Barcode แทน
    if (code.isEmpty) {
      code = barcode;
    }
    AppLogger.debug("**Log* Insert : Code=$code, barcode=$barcode ");
    if (closeExtra) {
      //selectProductExtraList.clear();
    }

    // 🔇 เรียก clear() แบบ silent (ไม่เล่นเสียง) เพราะ logInsert จะเล่นเสียงเองแล้ว
    AppLogger.debug('🔇 [logInsert] Calling posNumPad.clear(silent: true)');
    posNumPadGlobalKey.currentState?.clear(silent: true);

    if (qty.isNotEmpty) {
      qtyForCalc = global.calcTextToNumber(qty);
    }
    PosLogHelper logHelper = PosLogHelper();
    switch (commandCode) {
      case 101:
        {
          // 101=ส่วนขยาย (Check Box)
          // เพิ่มรายการใหม่ (Extra Check Box)
          List<PosLogObjectBoxStruct> posLogSelect = await logHelper.selectByGuidFixed(guid);
          if (posLogSelect.isNotEmpty) {
            await logHelper.insert(
              PosLogObjectBoxStruct(
                guid_code_ref: guidCodeRef,
                doc_mode: global.posScreenToInt(widget.posScreenMode),
                guid_ref: guidRef,
                log_date_time: DateTime.now(),
                hold_code: global.posHoldActiveCode,
                command_code: commandCode,
                extra_code: extraCode,
                code: code,
                price: price,
                barcode: barcode,
                refbarcode: barcode,
                unit_code: unitCode,
                name: name,
                qty_fixed: qtyForCalc,
                qty: qtyForCalc,
                selected: selected,
                is_except_vat: false,
              ),
            );
          }
        }
        break;
      case 1:
        {
          // 1=เพิ่มสินค้า
          // Get Item Name
          ProductBarcodeObjectBoxStruct? productBarcodeSelect = await ProductBarcodeHelper().selectByBarcodeFirst(barcode);
          String productNameStr = '';
          if (productBarcodeSelect != null) {
            if (1 == 0) {
              // สินค้าชั่งน้ำหนัก
              qtyForCalc = await productWeightScreen(productBarcodeSelect.barcode, productBarcodeSelect.images_url);
            }
            if (qtyForCalc != 0) {
              productNameStr = productBarcodeSelect.names;
              var priceLevel = (global.posHoldProcessResult[holdIndex].priceLevel != "") ? int.parse(global.posHoldProcessResult[holdIndex].priceLevel) : (global.posHoldProcessResult[holdIndex].ismember ? 2 : 1);

              double price = global.getProductPrice(productBarcodeSelect.prices, priceLevel);

              // 💰 เก็บราคาเต็ม (price level 1) สำหรับแสดงเปรียบเทียบ
              double priceOriginal = global.getProductPrice(
                productBarcodeSelect.prices,
                1, // ราคาเต็ม (price level 1)
              );

              PosLogObjectBoxStruct data = PosLogObjectBoxStruct(
                log_date_time: DateTime.now(),
                doc_mode: global.posScreenToInt(widget.posScreenMode),
                hold_code: global.posHoldActiveCode,
                command_code: commandCode,
                barcode: barcode,
                code: productBarcodeSelect.item_code,
                name: productNameStr,
                unit_code: productBarcodeSelect.unit_code,
                unit_stand: productBarcodeSelect.unit_stand,
                unit_divide: productBarcodeSelect.unit_divide,
                unit_name: productBarcodeSelect.unit_names,
                qty: qtyForCalc,
                price: price,
                issumpoint: productBarcodeSelect.issumpoint,
                is_except_vat: productBarcodeSelect.is_except_vat,
              );
              global.posHoldProcessResult[holdIndex].activeLineGuid = data.guid_auto_fixed;
              await logHelper.insert(data);

              // 🎨 สร้าง Widget Message ที่สวยงามและมีข้อมูลครบ
              final List<Widget> messageWidgets = [];

              // ✅ ชื่อสินค้า (ใหญ่สุด)
              messageWidgets.add(
                Text(
                  global.getNameFromJsonLanguage(productNameStr, global.userScreenLanguage),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                ),
              );
              messageWidgets.add(const SizedBox(height: 8));

              // ✅ รหัสสินค้า + Barcode + อัตราส่วน (Row แรก)
              messageWidgets.add(
                Row(
                  children: [
                    // รหัสสินค้า
                    Expanded(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13),
                          children: [
                            const TextSpan(
                              text: '📦 รหัส: ',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF757575)),
                            ),
                            TextSpan(
                              text: productBarcodeSelect.item_code,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF424242)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // อัตราส่วน (ถ้ามี)
                    if (productBarcodeSelect.unit_stand != 1.0 || productBarcodeSelect.unit_divide != 1.0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF2196F3), width: 1.5),
                        ),
                        child: Text(
                          '${productBarcodeSelect.unit_stand.toStringAsFixed(0)}:${productBarcodeSelect.unit_divide.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                        ),
                      ),
                  ],
                ),
              );
              messageWidgets.add(const SizedBox(height: 4));

              // ✅ Barcode (Row ที่สอง)
              messageWidgets.add(
                RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12),
                    children: [
                      const TextSpan(
                        text: '🏷️ Barcode: ',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF757575)),
                      ),
                      TextSpan(
                        text: barcode,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF616161)),
                      ),
                    ],
                  ),
                ),
              );
              messageWidgets.add(const SizedBox(height: 8));

              // ✅ ราคา + จำนวน (Row ที่สาม - แยกเป็น 2 คอลัมน์)
              messageWidgets.add(
                Row(
                  children: [
                    // ราคาต่อหน่วย
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00ACC1), width: 1.5),
                        ),
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: const TextStyle(fontSize: 14),
                            children: [
                              const TextSpan(
                                text: '💰 ราคา: ',
                                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00838F)),
                              ),
                              // 🔥 แสดงราคาเต็มขีดทับ (ถ้ามีส่วนลด)
                              if (priceOriginal > price && price > 0) ...[
                                TextSpan(
                                  text: '${global.moneyFormat.format(priceOriginal)} ',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), decoration: TextDecoration.lineThrough, decorationColor: Color(0xFF9E9E9E)),
                                ),
                                const TextSpan(
                                  text: '→ ',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF00ACC1)),
                                ),
                                TextSpan(
                                  text: '${global.moneyFormat.format(price)} ${global.language("money_symbol")}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFFD32F2F), // สีแดงสำหรับราคาพิเศษ
                                  ),
                                ),
                              ] else ...[
                                // ราคาปกติ (ไม่มีส่วนลด)
                                TextSpan(
                                  text: '${global.moneyFormat.format(price)} ${global.language("money_symbol")}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF006064)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // จำนวน
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF1F8E9), Color(0xFFDCEDC8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF689F38), width: 1.5),
                        ),
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: const TextStyle(fontSize: 14),
                            children: [
                              const TextSpan(
                                text: '📊 จำนวน: ',
                                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF558B2F)),
                              ),
                              TextSpan(
                                text: '${global.moneyFormat.format(qtyForCalc)} ${global.getNameFromJsonLanguage(productBarcodeSelect.unit_names, global.userScreenLanguage)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF33691E)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
              messageWidgets.add(const SizedBox(height: 8));

              // ✅ รวมเป็นเงิน (ใหญ่เด่นชัด)
              messageWidgets.add(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF2196F3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: const Color(0xFF2196F3).withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🎯 รวมเป็นเงิน',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        '${global.moneyFormat.format(qtyForCalc * price)} ${global.language("money_symbol")}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              );

              // ✅ House Brand Badge (ถ้ามี)
              if (productBarcodeSelect.patterncode.toUpperCase() == 'HB') {
                messageWidgets.add(const SizedBox(height: 6));
                messageWidgets.add(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFCA28)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: const Color(0xFFFFC107).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('⭐', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 6),
                        Text(
                          'HOUSE BRAND',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF57F17), letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),
                );
              }

              widgetMessage = messageWidgets;
              widgetMessageImageUrl = productBarcodeSelect.images_url;

              // 🔊 LOG: เล่นเสียงสำเร็จ
              if (kDebugMode) {
                AppLogger.success('🔊 [SOUND] Playing beep - Product added successfully');
                AppLogger.debug('Product: $productNameStr');
                AppLogger.debug('Barcode: $barcode');
                AppLogger.debug('   Stack: ${StackTrace.current.toString().split('\n').take(3).join('\n')}');
              }

              global.playSound(sound: global.SoundEnum.beep, word: productNameStr);
              qrCodeBarcodeScannerHistory.add(qrCodeBarcodeScannerResult);
              if (qrCodeBarcodeScannerHistory.length > 5) {
                qrCodeBarcodeScannerHistory.removeAt(0);
              }
              if (global.isPhoneDevice()) {
                // Vibration.vibrate(duration: 200);
              }
            }
          } else {
            widgetMessage = [
              Center(
                child: Text(
                  "${global.language("item_not_found")} $barcode",
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ];
            widgetMessageImageUrl = "";

            // 🔊 LOG: เล่นเสียงไม่เจอสินค้า
            if (kDebugMode) {
              AppLogger.debug('🔊 [SOUND] Playing fail - Product not found');
              AppLogger.debug('Barcode: $barcode');
              AppLogger.debug('   Stack: ${StackTrace.current.toString().split('\n').take(3).join('\n')}');
            }

            global.playSound(sound: global.SoundEnum.fail, word: global.language("item_not_found"));
            qrCodeBarcodeScannerHistory.add("* $qrCodeBarcodeScannerResult *");
            if (qrCodeBarcodeScannerHistory.length > 5) {
              qrCodeBarcodeScannerHistory.removeAt(0);
            }
            if (global.isPhoneDevice()) {
              /*Vibration.vibrate(pattern: [
                500,
                1000,
              ]);*/
            }
          }
        }
        break;
      case 2:
        // 2=เพิ่ม จำนวน + 1
        List<PosLogObjectBoxStruct> posLogSelect = await logHelper.selectByGuidFixed(guid);
        if (posLogSelect.isNotEmpty) {
          await logHelper.insert(
            PosLogObjectBoxStruct(doc_mode: global.posScreenToInt(widget.posScreenMode), guid_ref: global.posHoldProcessResult[holdIndex].activeLineGuid, log_date_time: DateTime.now(), hold_code: global.posHoldActiveCode, command_code: commandCode),
          );

          AppLogger.debug('🔊 [SOUND] Playing beep - Quantity +1');

          global.playSound(sound: global.SoundEnum.beep, word: global.language("plus") + global.language("one") + unitName);
        } else {
          AppLogger.debug('🔊 [SOUND] Playing fail - Item not found (qty +1)');

          global.playSound(sound: global.SoundEnum.fail, word: global.language("item_not_found"));
        }
        break;
      case 3:
        // 3=ลดจำนวน - 1
        List<PosLogObjectBoxStruct> posLogSelect = await logHelper.selectByGuidFixed(global.posHoldProcessResult[holdIndex].activeLineGuid);
        if (posLogSelect.isNotEmpty) {
          await logHelper.insert(
            PosLogObjectBoxStruct(doc_mode: global.posScreenToInt(widget.posScreenMode), guid_ref: global.posHoldProcessResult[holdIndex].activeLineGuid, log_date_time: DateTime.now(), hold_code: global.posHoldActiveCode, command_code: commandCode, qty: qtyForCalc),
          );

          AppLogger.debug('🔊 [SOUND] Playing beep - Quantity -1');

          global.playSound(sound: global.SoundEnum.beep, word: global.language("minus") + global.language("one") + unitName);
        } else {
          AppLogger.debug('🔊 [SOUND] Playing fail - Item not found (qty -1)');

          global.playSound(sound: global.SoundEnum.fail, word: global.language("item_not_found"));
        }
        break;
      case 4:
        // 4=แก้จำนวน
        await logHelper.insert(
          PosLogObjectBoxStruct(doc_mode: global.posScreenToInt(widget.posScreenMode), guid_ref: global.posHoldProcessResult[holdIndex].activeLineGuid, log_date_time: DateTime.now(), hold_code: global.posHoldActiveCode, command_code: commandCode, qty: qtyForCalc),
        );
        break;
      case 5:
        // 5=แก้ราคา
        await logHelper.insert(
          PosLogObjectBoxStruct(doc_mode: global.posScreenToInt(widget.posScreenMode), guid_ref: global.posHoldProcessResult[holdIndex].activeLineGuid, log_date_time: DateTime.now(), hold_code: global.posHoldActiveCode, command_code: commandCode, price: priceForCalc),
        );
        break;
      case 6:
        // 6=แก้ส่วนลด
        await logHelper.insert(
          PosLogObjectBoxStruct(
            doc_mode: global.posScreenToInt(widget.posScreenMode),
            guid_ref: global.posHoldProcessResult[holdIndex].activeLineGuid,
            log_date_time: DateTime.now(),
            hold_code: global.posHoldActiveCode,
            command_code: commandCode,
            discount_text: discount,
          ),
        );
        break;
      case 8:
        // 8=แก้หมายเหตุ
        await logHelper.insert(
          PosLogObjectBoxStruct(doc_mode: global.posScreenToInt(widget.posScreenMode), guid_ref: global.posHoldProcessResult[holdIndex].activeLineGuid, log_date_time: DateTime.now(), hold_code: global.posHoldActiveCode, command_code: commandCode, remark: remark),
        );
        break;
      case 9:
        // 9=ลบรายการ
        await logHelper.insert(PosLogObjectBoxStruct(doc_mode: global.posScreenToInt(widget.posScreenMode), log_date_time: DateTime.now(), hold_code: global.posHoldActiveCode, command_code: commandCode, guid_ref: global.posHoldProcessResult[holdIndex].activeLineGuid));

        AppLogger.debug('🔊 [SOUND] Playing beep - Delete line');

        global.playSound(sound: global.SoundEnum.beep, word: global.language("delete") + global.language("line"));
        productOptions.clear();
        break;
      case 99:
        // เริ่มใหม่
        await logHelper.deleteByHoldCode(holdCode: global.posHoldActiveCode);

        AppLogger.debug('🔊 [SOUND] Playing beep - Restart');

        global.playSound(sound: global.SoundEnum.beep, word: global.language("restart"));
        productOptions.clear();
        global.posHoldProcessResult[holdIndex].activeLineGuid = "";
        break;
      default:
        AppLogger.info("commandCode=$commandCode");
        break;
    }
    for (int index = 0; index < global.posRemoteDeviceList.length; index++) {
      if (global.posRemoteDeviceList[index].holdCodeActive == global.posHoldActiveCode) {
        global.posRemoteDeviceList[index].processSuccess = false;
      }
    }
    // update พักบิล
    if (holdIndex != -1) {
      global.posLogHelper.holdCount(global.posHoldProcessResult[holdIndex].code).then((value) {
        global.posHoldProcessResult[holdIndex].logCount = value;
      });
    }

    // ⏰ รอให้ processEvent() เสร็จก่อน (เพื่อให้โปรโมชั่นมีผล)
    await processEvent(barcode: barcode, holdCode: global.posHoldActiveCode);

    // 🔥 อัพเดท Widget Message ด้วยราคาที่ถูกต้องหลังโปรโมชั่น (เฉพาะ command_code = 1)
    if (commandCode == 1 && barcode.isNotEmpty) {
      await _updateWidgetMessageWithFinalPrice(barcode, qtyForCalc);
    }

    global.systemInfoSendToServer();
  }

  /// 🔥 อัพเดท Widget Message ด้วยราคาสุดท้ายหลังโปรโมชั่น
  Future<void> _updateWidgetMessageWithFinalPrice(String barcode, double qty) async {
    try {
      int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);

      // ดึงข้อมูลสินค้าจาก details (รายการสินค้าหลังโปรโมชั่น)
      final details = global.posHoldProcessResult[holdIndex].posProcess.details;
      if (details.isEmpty) return;

      // หารายการล่าสุดที่ barcode ตรงกัน
      final latestItem = details.lastWhere((item) => item.barcode == barcode, orElse: () => details.last);

      // ดึงข้อมูลสินค้าเพื่อแสดงผล
      ProductBarcodeObjectBoxStruct? productBarcodeSelect = await ProductBarcodeHelper().selectByBarcodeFirst(barcode);

      if (productBarcodeSelect == null) return;

      String productNameStr = productBarcodeSelect.names;
      double priceFinal = latestItem.price; // ราคาหลังโปรโมชั่น
      double priceOriginal = global.getProductPrice(
        productBarcodeSelect.prices,
        1, // ราคาเต็ม
      );

      // 🐛 DEBUG: Log ราคาสุดท้าย
      if (kDebugMode) {
        AppLogger.debug('💰 [FINAL PRICE] Product: ${productBarcodeSelect.item_code}');
        AppLogger.debug('   priceOriginal: $priceOriginal');
        AppLogger.debug('   priceFinal (after promo): $priceFinal');
        AppLogger.debug('   Has special price: ${priceOriginal > priceFinal}');
      }

      // 🎨 สร้าง Widget Message ใหม่
      final List<Widget> messageWidgets = [];

      // ✅ ชื่อสินค้า
      messageWidgets.add(
        Text(
          global.getNameFromJsonLanguage(productNameStr, global.userScreenLanguage),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
        ),
      );
      messageWidgets.add(const SizedBox(height: 8));

      // ✅ รหัสสินค้า + อัตราส่วน
      messageWidgets.add(
        Row(
          children: [
            Expanded(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(fontSize: 13),
                  children: [
                    const TextSpan(
                      text: '📦 รหัส: ',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF757575)),
                    ),
                    TextSpan(
                      text: productBarcodeSelect.item_code,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF424242)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (productBarcodeSelect.unit_stand != 1.0 || productBarcodeSelect.unit_divide != 1.0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF2196F3), width: 1.5),
                ),
                child: Text(
                  '${productBarcodeSelect.unit_stand.toStringAsFixed(0)}:${productBarcodeSelect.unit_divide.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                ),
              ),
          ],
        ),
      );
      messageWidgets.add(const SizedBox(height: 4));

      // ✅ Barcode
      messageWidgets.add(
        RichText(
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: const TextStyle(fontSize: 12),
            children: [
              const TextSpan(
                text: '🏷️ Barcode: ',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF757575)),
              ),
              TextSpan(
                text: barcode,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF616161)),
              ),
            ],
          ),
        ),
      );
      messageWidgets.add(const SizedBox(height: 8));

      // ✅ ราคา + จำนวน
      messageWidgets.add(
        Row(
          children: [
            // ราคาต่อหน่วย
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00ACC1), width: 1.5),
                ),
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14),
                    children: [
                      const TextSpan(
                        text: '💰 ราคา: ',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00838F)),
                      ),
                      // 🔥 แสดงราคาเต็มขีดทับ + ราคาพิเศษ (ถ้ามี)
                      if (priceOriginal > priceFinal && priceFinal > 0) ...[
                        TextSpan(
                          text: '${global.moneyFormat.format(priceOriginal)} ',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), decoration: TextDecoration.lineThrough, decorationColor: Color(0xFF9E9E9E)),
                        ),
                        const TextSpan(
                          text: '→ ',
                          style: TextStyle(fontSize: 12, color: Color(0xFF00ACC1)),
                        ),
                        TextSpan(
                          text: '${global.moneyFormat.format(priceFinal)} ${global.language("money_symbol")}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFFD32F2F), // สีแดงสำหรับราคาพิเศษ
                          ),
                        ),
                      ] else ...[
                        // ราคาปกติ
                        TextSpan(
                          text: '${global.moneyFormat.format(priceFinal)} ${global.language("money_symbol")}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF006064)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // จำนวน
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF1F8E9), Color(0xFFDCEDC8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF689F38), width: 1.5),
                ),
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14),
                    children: [
                      const TextSpan(
                        text: '📊 จำนวน: ',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF558B2F)),
                      ),
                      TextSpan(
                        text: '${global.moneyFormat.format(qty)} ${global.getNameFromJsonLanguage(productBarcodeSelect.unit_names, global.userScreenLanguage)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF33691E)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      messageWidgets.add(const SizedBox(height: 8));

      // ✅ รวมเป็นเงิน
      messageWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF2196F3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFF2196F3).withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 3))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎯 รวมเป็นเงิน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                '${global.moneyFormat.format(qty * priceFinal)} ${global.language("money_symbol")}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      );

      // ✅ House Brand Badge
      if (productBarcodeSelect.patterncode.toUpperCase() == 'HB') {
        messageWidgets.add(const SizedBox(height: 6));
        messageWidgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFCA28)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: const Color(0xFFFFC107).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('⭐', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text(
                  'HOUSE BRAND',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF57F17), letterSpacing: 1.2),
                ),
              ],
            ),
          ),
        );
      }

      // อัพเดท widget message
      if (mounted) {
        setState(() {
          widgetMessage = messageWidgets;
          widgetMessageImageUrl = productBarcodeSelect.images_url;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error updating widget message: $e');
      }
    }
  }

  Widget findMemberByText() {
    return BlocBuilder<FindMemberByTelNameBloc, FindMemberByTelNameState>(
      builder: (context, state) {
        if (state is FindMemberByTelNameLoadSuccess) {
          findMemberByNameTelephoneLastResult.clear();
          findMemberByNameTelephoneLastResult.addAll(state.result);
          context.read<FindMemberByTelNameBloc>().add(FindMemberByTelNameLoadFinish());
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_themeSwatch[50]!, Colors.white]),
            borderRadius: BorderRadius.circular(6),
          ),
          margin: const EdgeInsets.all(2),
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(2),
                child: TextField(
                  autofocus: true,
                  focusNode: textFindByTextFocus,
                  controller: textFindByTextController,
                  onChanged: (string) {
                    debounce.run(() {
                      findItemByCodeNameLastResult.clear();
                      context.read<FindMemberByTelNameBloc>().add(FindMemberByTelNameLoadStart(words: textFindByTextController.text, offset: 0, limit: 50));
                    });
                  },
                  decoration: InputDecoration(
                    hintText: global.language("search_by_name_code_phone"),
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: _themeSwatch[600]!),
                    suffixIcon: IconButton(
                      onPressed: () {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        findMemberResultNotifier.value = [];
                        textFindByTextController.clear();
                      },
                      icon: Icon(Icons.clear, color: Colors.grey.shade600),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _themeSwatch[600]!, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              // Results List Section
              Expanded(child: findMemberByNameTelephoneLastResult.isEmpty ? _buildEmptyState() : _buildMembersList()),
            ],
          ),
        );
      },
    );
  }

  // ✅ ใช้ PosMemberSearchWidgets
  Widget _buildEmptyState() {
    return PosMemberSearchWidgets.buildEmptyState(searchText: textFindByTextController.text);
  }

  // ✅ ใช้ PosMemberSearchWidgets
  Widget _buildMembersList() {
    return PosMemberSearchWidgets.buildMembersList(members: findMemberByNameTelephoneLastResult, onMemberTap: _handleMemberSelection);
  }

  /// จัดการเมื่อเลือกสมาชิก
  Future<void> _handleMemberSelection(MemberModel member, String phoneNumber) async {
    int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);

    // Clear point values when customer is changed
    global.posHoldProcessResult[holdIndex].posProcess.usepoint = 0.0;
    global.posHoldProcessResult[holdIndex].posProcess.pointdiscountamount = 0.0;

    // อัพเดทข้อมูลลูกค้าใหม่
    global.posHoldProcessResult[holdIndex].customerPointsCode = member.pointscode;
    global.posHoldProcessResult[holdIndex].customerCode = member.code;
    global.posHoldProcessResult[holdIndex].ismember = member.ismember;
    global.posHoldProcessResult[holdIndex].priceLevel = member.pricelevel;
    global.posHoldProcessResult[holdIndex].customerGuid = member.guidfixed;
    global.posHoldProcessResult[holdIndex].customerName = global.getNameFromLanguage(member.names, global.userScreenLanguage);
    global.posHoldProcessResult[holdIndex].customerPhone = phoneNumber;

    await _recalculatePricesForMemberStatus(holdIndex);

    // Recalculate process to update all values including point calculations
    await posCompileProcess(
      holdCode: global.posHoldActiveCode,
      docMode: global.posScreenToInt(widget.posScreenMode),
      detailDiscountFormula: "",
      cashRoundAmount: false,
      discountFoodOnly: global.tempIsRestaurantSystem,
      customermode: global.secondScreenCommandProcessDetail,
    );

    if (global.isTabletScreen() || global.isDesktopScreen()) {
      tabletTabController.index = 0;
    }
    setState(() {});

    // Request keyboard focus back after customer selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestKeyboardFocus();
    });
  }

  Future<void> _recalculatePricesForMemberStatus(int holdIndex) async {
    PosLogHelper logHelper = PosLogHelper();

    // ดึงรายการสินค้าทั้งหมดที่มีอยู่ในบิล
    List<PosLogObjectBoxStruct> allLogs = await logHelper.selectByHoldCode(global.posHoldActiveCode);

    // กรองเฉพาะรายการเพิ่มสินค้า (command_code = 1)
    List<PosLogObjectBoxStruct> productLogs = allLogs.where((log) => log.command_code == 1).toList();

    for (PosLogObjectBoxStruct productLog in productLogs) {
      // ดึงข้อมูลสินค้าจาก barcode
      ProductBarcodeObjectBoxStruct? productData = await ProductBarcodeHelper().selectByBarcodeFirst(productLog.barcode);

      if (productData != null) {
        // คำนวณราคาใหม่ตามสถานะสมาชิก
        var priceLevel = (global.posHoldProcessResult[holdIndex].priceLevel != "") ? int.parse(global.posHoldProcessResult[holdIndex].priceLevel) : (global.posHoldProcessResult[holdIndex].ismember ? 2 : 1);
        double newPrice = global.getProductPrice(productData.prices, priceLevel);

        await logHelper.insert(
          PosLogObjectBoxStruct(
            doc_mode: global.posScreenToInt(widget.posScreenMode),
            guid_ref: productLog.guid_auto_fixed,
            log_date_time: DateTime.now(),
            hold_code: global.posHoldActiveCode,
            command_code: 5, // 5 = แก้ราคา
            price: newPrice,
          ),
        );
      }
    }

    // คำนวณผลรวมใหม่
    await processEvent(barcode: "", holdCode: global.posHoldActiveCode);
  }

  Widget findProductByText() {
    int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
    return BlocBuilder<FindItemByCodeNameBarcodeBloc, FindItemByCodeNameBarcodeState>(
      builder: (context, state) {
        if (state is FindItemByCodeNameBarcodeLoadSuccess) {
          findItemByCodeNameLastResult.addAll(state.result);
          context.read<FindItemByCodeNameBarcodeBloc>().add(FindItemByCodeNameBarcodeLoadFinish());
        }
        var priceLevel = (global.posHoldProcessResult[holdIndex].priceLevel != "") ? int.parse(global.posHoldProcessResult[holdIndex].priceLevel) : (global.posHoldProcessResult[holdIndex].ismember ? 2 : 1);
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(5),
          child: Column(
            children: <Widget>[
              // Search TextField
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  autofocus: true,
                  focusNode: textFindByTextFocus,
                  controller: textFindByTextController,
                  onChanged: (string) {
                    debounce.run(() {
                      findItemByCodeNameLastResult.clear();
                      context.read<FindItemByCodeNameBarcodeBloc>().add(FindItemByCodeNameBarcodeLoadStart(words: textFindByTextController.text, offset: 0, limit: 50));
                    });
                  },
                  style: TextStyle(fontSize: _getDynamicFontSize(14.0)),
                  decoration: InputDecoration(
                    hintText: "ค้นหาสินค้า (ชื่อ, รหัส, บาร์โค้ด)",
                    hintStyle: TextStyle(fontSize: _getDynamicFontSize(14.0), color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: Colors.green.shade600, size: _getDynamicFontSize(20.0)),
                    suffixIcon: IconButton(
                      onPressed: () {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        setState(() {
                          findItemByCodeNameLastResult.clear();
                          textFindByTextController.clear();
                        });
                      },
                      icon: Icon(Icons.clear, size: _getDynamicFontSize(20.0), color: Colors.grey.shade600),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        global.language("item_name"),
                        style: TextStyle(fontSize: _getDynamicFontSize(13.0), fontWeight: FontWeight.w600, color: Colors.green.shade800),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          "อัตราส่วน",
                          style: TextStyle(fontSize: _getDynamicFontSize(11.0), fontWeight: FontWeight.w600, color: Colors.green.shade800),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          global.language("price"),
                          style: TextStyle(fontSize: _getDynamicFontSize(13.0), fontWeight: FontWeight.w600, color: Colors.green.shade800),
                        ),
                      ),
                    ),
                    Expanded(flex: 1, child: Container()),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          global.language("qty"),
                          style: TextStyle(fontSize: _getDynamicFontSize(13.0), fontWeight: FontWeight.w600, color: Colors.green.shade800),
                        ),
                      ),
                    ),
                    Expanded(flex: 1, child: Container()),
                    Expanded(flex: 1, child: Container()),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Results List
              Expanded(
                child: findItemByCodeNameLastResult.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              "ค้นหาสินค้าที่ต้องการ",
                              style: TextStyle(fontSize: _getDynamicFontSize(16.0), color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: findItemByCodeNameLastResult.map((value) {
                            var index = findItemByCodeNameLastResult.indexOf(value);
                            var detail = findItemByCodeNameLastResult[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 1),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 4, left: 7, right: 7),
                                child: Row(
                                  children: [
                                    // Product Info
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            global.getNameFromJsonLanguage(detail.item_names, global.userScreenLanguage),
                                            style: TextStyle(fontSize: _getDynamicFontSize(12.0), fontWeight: FontWeight.w600, color: Colors.black87),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${global.getNameFromJsonLanguage(detail.unit_names, global.userScreenLanguage)} • ${detail.item_code} • ${detail.barcode}",
                                            style: TextStyle(fontSize: _getDynamicFontSize(8.0), color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Ratio (อัตราส่วน)
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: (detail.unit_stand != 1.0 || detail.unit_divide != 1.0)
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _themeSwatch[50]!,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: _themeSwatch[200]!, width: 0.5),
                                                ),
                                                child: Text(
                                                  "${global.formatDoubleTrailingZero(detail.unit_stand)}:${global.formatDoubleTrailingZero(detail.unit_divide)}",
                                                  style: TextStyle(fontSize: _getDynamicFontSize(10.0), fontWeight: FontWeight.w600, color: _themeSwatch[700]!),
                                                ),
                                              )
                                            : Text(
                                                "-",
                                                style: TextStyle(fontSize: _getDynamicFontSize(10.0), color: Colors.grey.shade400),
                                              ),
                                      ),
                                    ),

                                    // Price
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          global.moneyFormat.format(global.getProductPrice(detail.prices, priceLevel)),
                                          style: TextStyle(fontSize: _getDynamicFontSize(12.0), fontWeight: FontWeight.w600, color: Colors.green.shade700),
                                        ),
                                      ),
                                    ),

                                    // Quantity Controls
                                    Expanded(
                                      flex: 1,
                                      child: IconButton(
                                        onPressed: () {
                                          global.playSound(sound: global.SoundEnum.buttonTing);
                                          setState(() {
                                            if (detail.qty > 0.0) {
                                              detail.qty -= 1.0;
                                            }
                                          });
                                        },
                                        icon: Icon(Icons.remove_circle_outline, size: _getDynamicFontSize(20.0), color: Colors.red.shade600),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                        onTap: () async {
                                          await showDialog(
                                            context: context,
                                            builder: (context) {
                                              return StatefulBuilder(
                                                builder: (context, setDialogState) {
                                                  return AlertDialog(
                                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                                                    contentPadding: const EdgeInsets.all(10),
                                                    content: SizedBox(
                                                      height: 500,
                                                      child: NumberPad(
                                                        header: global.language("qty"),
                                                        title: Text(
                                                          '${global.getNameFromJsonLanguage(detail.item_names, global.userScreenLanguage)} ${global.language("qty")} ${global.moneyFormat.format(detail.qty)} ${global.getNameFromJsonLanguage(detail.unit_names, global.userScreenLanguage)}',
                                                          style: TextStyle(fontSize: _getDynamicFontSize(20.0), fontWeight: FontWeight.bold),
                                                        ),
                                                        onChange: (qtyStr) => {
                                                          if (qtyStr.isNotEmpty && (double.tryParse(qtyStr) ?? 0) > 0)
                                                            {
                                                              detail.qty = double.tryParse(qtyStr) ?? 0.0,
                                                              setDialogState(() {}), // อัปเดต dialog
                                                            },
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                          // อัปเดต widget หลักหลังจากปิด dialog
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _themeSwatch[50]!,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: _themeSwatch[200]!),
                                          ),
                                          child: Text(
                                            global.qtyShortFormat.format(detail.qty),
                                            style: TextStyle(fontSize: _getDynamicFontSize(12.0), fontWeight: FontWeight.w600, color: _themeSwatch[700]!),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: IconButton(
                                        onPressed: () {
                                          global.playSound(sound: global.SoundEnum.buttonTing);
                                          setState(() {
                                            detail.qty += 1.0;
                                          });
                                        },
                                        icon: Icon(Icons.add_circle_outline, size: _getDynamicFontSize(20.0), color: Colors.green.shade600),
                                      ),
                                    ),

                                    // Add Button
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 4),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade600,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () async {
                                            await logInsert(guid: "", commandCode: 1, barcode: detail.barcode, code: detail.item_code, qty: detail.qty.toString());
                                            await processEvent(barcode: detail.barcode, holdCode: global.posHoldActiveCode);
                                            detail.qty = 1;
                                            setState(() {}); // รีเฟรช UI หลังเพิ่มสินค้า
                                          },
                                          child: Icon(Icons.add_shopping_cart, size: _getDynamicFontSize(16.0)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    try {
      if (scanController != null && qrCodeBarcodeScannerStart) {
        if (Platform.isAndroid) {
          scanController!.pauseCamera();
        } else if (Platform.isIOS) {
          scanController!.resumeCamera();
        }
      }
    } catch (e) {
      AppLogger.error("Reassemble camera error: $e");
    }
  }

  Future<void> processEvent({required String barcode, required String holdCode}) async {
    // ✅ Performance monitoring (Debug mode only)
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
    }

    if (barcode.isNotEmpty) {
      product =
          await ProductBarcodeHelper().selectByBarcodeFirst(barcode) ??
          ProductBarcodeObjectBoxStruct(
            barcode: "",
            names: "",
            name_all: "",
            prices: "",
            unit_code: "",
            unit_stand: 1,
            unit_divide: 1,
            unit_names: "",
            vat_type: 1,
            new_line: 0,
            images_url: "",
            guid_fixed: "",
            item_code: "",
            item_guid: "",
            descriptions: "",
            color_select: "",
            image_or_color: true,
            color_select_hex: "",
            options_json: "",
            isalacarte: true,
            ordertypes: "",
            product_count: 0,
            issplitunitprint: false,
            is_except_vat: false,
            is_resterant_use_stock: false,
            ref_barcode_json: "",
            food_type: 0,
            patterncode: "",
          );
      try {
        productOptions = (product.options_json.isEmpty) ? [] : (await jsonDecode(product.options_json) as List).map((e) => ProductOptionModel.fromJson(e)).toList();
      } catch (e) {
        productOptions = [];
      }
    }
    await posCompileProcess(
      holdCode: holdCode,
      docMode: global.posScreenToInt(widget.posScreenMode),
      detailDiscountFormula: detailDiscountFormula,
      cashRoundAmount: false,
      discountFoodOnly: global.tempIsRestaurantSystem,
      customermode: global.secondScreenCommandProcessDetail,
    ).then((value) {
      if (value.lineGuid.isNotEmpty && value.lastCommandCode == 1) {
        int holdIndex = global.findPosHoldProcessResultIndex(holdCode);
        global.posHoldProcessResult[holdIndex].activeLineGuid = value.lineGuid;
      }
      processEventRefresh(holdCode: holdCode);
    });

    // ✅ Log performance (Debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.success('[PosScreen] ⚙️ processEvent took ${stopwatch.elapsedMilliseconds}ms (barcode: ${barcode.isEmpty ? "empty" : "scanned"})');
      if (stopwatch.elapsedMilliseconds > 200) {
        AppLogger.warning('⚠️ Slow processEvent! Consider optimization.');
      }
    }
  }

  void processEventRefresh({required String holdCode}) {
    int activeLineIndex = global.findActiveLineIndex(holdCode: global.posHoldActiveCode);
    // ✅ ใช้ scheduleMicrotask แทน Future.delayed เพื่อไม่ block UI
    scheduleMicrotask(() {
      if (mounted && autoScrollController.hasClients) {
        // เช็คว่า ListView มีเนื้อหาเกินกว่าขนาดที่แสดงได้หรือไม่
        final position = autoScrollController.position;
        if (position.maxScrollExtent > 0) {
          // มี scroll ได้จริง ถึงค่อย scroll
          autoScrollController.scrollToIndex((activeLineIndex < 0) ? 0 : activeLineIndex, preferPosition: AutoScrollPosition.begin);
        }
      }
    });
    for (int index = 0; index < global.posRemoteDeviceList.length; index++) {
      if (global.posRemoteDeviceList[index].holdCodeActive == global.posHoldActiveCode) {
        global.posRemoteDeviceList[index].processSuccess = false;
      }
    }
    if (mounted) setState(() {});
  }

  void numPadChangeQty(String qty, String unitName) async {
    if (qty.isNotEmpty && (double.tryParse(qty) ?? 0) > 0) {
      global.playSound(sound: global.SoundEnum.buttonTing, word: global.language("qty_update") + global.language("is") + qty.toString() + unitName);
      int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
      if (holdIndex != -1) {
        await logInsert(commandCode: 4, guid: global.posHoldProcessResult[holdIndex].activeLineGuid, qty: qty, closeExtra: false);
        await processEvent(barcode: "", holdCode: global.posHoldActiveCode);
      }
    }
  }

  void numPadChangePrice(String priceStr) async {
    double price = double.tryParse(priceStr) ?? 0.0;
    if (price > 0) {
      global.playSound(sound: global.SoundEnum.buttonTing, word: global.language("price_update") + global.language("is") + price.toString() + global.language("money_symbol"));
      int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
      if (holdIndex != -1) {
        await logInsert(commandCode: 5, guid: global.posHoldProcessResult[holdIndex].activeLineGuid, price: price, closeExtra: false);
      }
    }
  }

  Future<void> selectProductLevelExtraListCheck(int groupIndex, int detailIndex, bool value) async {
    if (value == true) {
      // ถ้าเลือกแล้ว ให้ทำการลบข้อมูลที่มีอยู่แล้วออก (ลบของเก่า)
      PosLogHelper().deleteByGuidCodeRefHoldCodeCommandCode(guidCode: productOptions[groupIndex].choices[detailIndex].guid, commandCode: 101, holdCode: global.posHoldActiveCode);
      global.playSound(sound: global.SoundEnum.beep);
    } else {
      /// ถ้าไม่ได้เลือก เพิ่มข้อมูลเพื่อให้ระบบประมวลผล
      /// ตรวจสอบว่ามีการเลือกมากกว่าที่กำหนดหรือไม่ (เช่น ไม่เกิน 2 รายการ)
      int count = 0;
      for (int index = 0; index < productOptions[groupIndex].choices.length; index++) {
        if (productOptions[groupIndex].choices[index].selected!) {
          count++;
        }
      }

      if (count < productOptions[groupIndex].maxselect) {
        productOptions[groupIndex].choices[detailIndex].selected = value;
        ProductChoiceModel detail = productOptions[groupIndex].choices[detailIndex];
        // เพิ่ม Log รายการที่เลือก
        int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
        if (holdIndex != -1) {
          await logInsert(
            guid: global.posHoldProcessResult[holdIndex].activeLineGuid,
            guidCodeRef: detail.guid,
            commandCode: 101,
            guidRef: global.posHoldProcessResult[holdIndex].activeLineGuid,
            barcode: detail.refbarcode ?? "",
            unitCode: detail.refunitcode ?? "",
            price: double.tryParse(detail.price) ?? 0.0,
            qty: detail.qty.toString(),
            extraCode: "",
            closeExtra: false,
            name: jsonEncode(detail.names),
            codeDefault: "",
            selected: detail.selected ?? false,
          );
          global.playSound(sound: global.SoundEnum.beep, word: global.getNameFromLanguage(detail.names, global.userScreenLanguage));
          await processEvent(barcode: "", holdCode: global.posHoldActiveCode);
        }
      } else {
        global.playSound(sound: global.SoundEnum.fail);
      }
    }
  }

  void discountPadChange(String discount) async {
    int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
    if (holdIndex != -1) {
      if (discount.isNotEmpty) {
        if (double.tryParse(discount) != null) {
          global.playSound(word: global.language("discount") + discount + global.language("money_symbol"));
        } else {
          List<String> discountList = discount.split(",");
          StringBuffer discountSpeech = StringBuffer();
          for (var index = 0; index < discountList.length; index++) {
            if (discountSpeech.isNotEmpty) {
              discountSpeech.write(global.language("discount_plus"));
            }
            if (double.tryParse(discountList[index]) != null) {
              discountSpeech.write(discountList[index] + global.language("money_symbol"));
            } else {
              discountSpeech.write(discountList[index]);
            }
          }
          global.playSound(word: global.language("discount") + discountSpeech.toString());
        }
        await logInsert(commandCode: 6, guid: global.posHoldProcessResult[holdIndex].activeLineGuid, discount: discount, closeExtra: false);
      } else {
        global.playSound(word: global.language("discount_cancel"));
        await logInsert(commandCode: 6, guid: global.posHoldProcessResult[holdIndex].activeLineGuid, discount: '', closeExtra: false);
      }
    }
  }

  void billDiscountPadChange(String discount) async {
    detailDiscountFormula = discount;
    global.discountFormular = discount;

    await posCompileProcess(
      holdCode: global.posHoldActiveCode,
      docMode: global.posScreenToInt(widget.posScreenMode),
      detailDiscountFormula: detailDiscountFormula,
      cashRoundAmount: false,
      discountFoodOnly: global.tempIsRestaurantSystem,
      customermode: global.secondScreenCommandProcessDetail,
    ).then((value) {
      processEventRefresh(holdCode: global.posHoldActiveCode);
    });
    // ⚡ Performance: ลบ .then() และ setState() - ไม่จำเป็นต้อง rebuild
  }

  void checkOnline() async {
    global.isOnline = await global.hasNetwork();
  }

  void onQRViewCreated(QRViewController controller) {
    scanController = controller;

    controller.scannedDataStream.listen((scanData) async {
      if (!qrCodeBarcodeScannerStart) return; // ไม่ทำงานถ้า scanner ถูกปิดแล้ว

      qrCodeBarcodeScannerResult = scanData.code.toString();
      await logInsert(guid: "", commandCode: 1, barcode: qrCodeBarcodeScannerResult, qty: (qrCodeBarcodeScannerQtyResult == 0) ? "1.0" : qrCodeBarcodeScannerQtyResult.toString());
      await processEvent(barcode: qrCodeBarcodeScannerResult, holdCode: global.posHoldActiveCode);

      try {
        if (qrCodeBarcodeScannerStart && scanController != null) {
          await controller.pauseCamera();
          // ⚡ Performance: ใช้ ValueNotifier แทน setState() - ไม่ rebuild ทั้งหน้า
          qrCodeBarcodeScannerSuccessNotifier.value = true;
          // ⚡ Performance: ลบ delay 300ms - ใช้ microtask แทน
          await Future.microtask(() {});
          qrCodeBarcodeScannerSuccessNotifier.value = false;
          if (qrCodeBarcodeScannerStart && scanController != null) {
            await controller.resumeCamera();
          }
        }
      } catch (e) {
        AppLogger.error("Camera control error: $e");
      }

      qrCodeBarcodeScannerQtyResult = 1;
      // ⚡ Performance: ไม่ต้อง setState เพราะไม่มีการเปลี่ยน UI
    });
  }

  Widget productLevelLabelWidget({required String name, String imageUrl = "", String unitName = "", double price = 0, bool withOpacity = true}) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: (imageUrl.trim().isNotEmpty)
                ? Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(image: AppImageCacheManager.getCachedNetwork(imageUrl), fit: BoxFit.cover, width: double.infinity),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: _getDynamicFontSize(13), color: Colors.black87, fontWeight: FontWeight.w600, height: 1.2),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 4,
                      ),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageUrl.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      name,
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: _getDynamicFontSize(12), color: Colors.black87, fontWeight: FontWeight.w600, height: 1.1),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (unitName.isNotEmpty)
                      Flexible(
                        child: Text(
                          unitName,
                          style: TextStyle(fontSize: _getDynamicFontSize(10), color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_themeSwatch[600]!, _themeSwatch[700]!]),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [BoxShadow(color: _themeSwatch.withOpacity(0.3), spreadRadius: 1, blurRadius: 2, offset: const Offset(0, 1))],
                      ),
                      child: Text(
                        global.moneyFormat.format(price),
                        style: TextStyle(fontSize: _getDynamicFontSize(11), color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget productLevelWidget(ProductBarcodeObjectBoxStruct product) {
    int holdIndexw = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
    bool hasStock = product.product_count != 0;

    BoxDecoration boxDecoration = (product.image_or_color == false)
        ? BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [global.colorFromHex(product.color_select_hex.replaceAll("#", "")).withOpacity(0.3), global.colorFromHex(product.color_select_hex.replaceAll("#", "")).withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(12),
          )
        : BoxDecoration(borderRadius: BorderRadius.circular(12));
    var priceLevel = (global.posHoldProcessResult[holdIndexw].priceLevel != "") ? int.parse(global.posHoldProcessResult[holdIndexw].priceLevel) : (global.posHoldProcessResult[holdIndexw].ismember ? 2 : 1);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: hasStock ? _themeSwatch.withOpacity(0.15) : Colors.black.withOpacity(0.08), spreadRadius: 1, blurRadius: hasStock ? 8 : 6, offset: const Offset(0, 3))],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            // เพิ่ม haptic feedback
            HapticFeedback.lightImpact();
            displayDetailByBarcode = false;
            await logInsert(guid: "", commandCode: 1, barcode: product.barcode, code: product.item_code, closeExtra: false, qty: "1.0");
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(color: hasStock ? _themeSwatch[200]! : Colors.grey.shade200, width: hasStock ? 2 : 1),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: double.infinity,
                    width: double.infinity,
                    decoration: boxDecoration,
                    child: productLevelLabelWidget(
                      imageUrl: product.images_url,
                      name: global.getNameFromJsonLanguage(product.names, global.userScreenLanguage),
                      unitName: global.getNameFromJsonLanguage(product.unit_names, global.userScreenLanguage),
                      price: global.getProductPrice(product.prices, priceLevel),
                    ),
                  ),
                ),
                if (hasStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        // เพิ่ม haptic feedback
                        HapticFeedback.selectionClick();
                        displayDetailByBarcode = false;
                        int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
                        for (int index = 0; index < global.posHoldProcessResult[holdIndex].posProcess.details.length && displayDetailByBarcode == false; index++) {
                          if (product.barcode == global.posHoldProcessResult[holdIndex].posProcess.details[index].barcode) {
                            displayDetailByBarcode = true;
                            global.posHoldProcessResult[holdIndex].activeLineGuid = global.posHoldProcessResult[holdIndex].posProcess.details[index].guid;
                          }
                        }
                        setState(() {});
                        int activeLineIndex = global.findActiveLineIndex(holdCode: global.posHoldActiveCode);
                        // เช็คว่าต้อง scroll จริงหรือไม่
                        if (autoScrollController.hasClients && autoScrollController.position.maxScrollExtent > 0) {
                          autoScrollController.scrollToIndex((activeLineIndex < 0) ? 0 : activeLineIndex, preferPosition: AutoScrollPosition.begin);
                        }
                      },
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.red.shade400, Colors.red.shade600]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), spreadRadius: 1, blurRadius: 6, offset: const Offset(0, 3))],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ เพิ่ม const เพื่อ performance
                            const Icon(Icons.shopping_cart, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              global.formatDoubleTrailingZero(product.product_count),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: (12 * listTextHeight).clamp(10.0, 16.0), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget selectProductLevelListScreenWidget() {
    double menuMinWidth = (global.isTabletScreen() || global.isDesktopScreen()) ? (gridItemSize * 180) : (gridItemSize * 170); // เพิ่มขนาดกล่องสินค้า
    int widgetPerLine = int.parse((MediaQuery.of(context).size.width / menuMinWidth).toStringAsFixed(0));
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > menuMinWidth) {
          widgetPerLine = int.parse((constraints.maxWidth / menuMinWidth).toStringAsFixed(0));
        } else {
          widgetPerLine = 1;
        }
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.grey.shade100, Colors.grey.shade200]),
          ),
          child: (global.productListByCategory.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 120),
                      const SizedBox(height: 16),
                      Text(
                        'ไม่พบสินค้าในหมวดหมู่นี้',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : GridView.count(
                  padding: const EdgeInsets.all(8), // เพิ่ม padding รอบ grid
                  crossAxisCount: widgetPerLine,
                  childAspectRatio: 1.1, // เพิ่มความสูงเล็กน้อยเพื่อให้พอดี
                  mainAxisSpacing: 3, // เพิ่มระยะห่างระหว่างแถว
                  crossAxisSpacing: 3, // เพิ่มระยะห่างระหว่างคอลัมน์
                  children: [
                    for (final detail in global.productListByCategory)
                      // ✅ RepaintBoundary prevents unnecessary repaints of product cards
                      RepaintBoundary(
                        child: ProductCard(
                          product: detail,
                          isMember: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].ismember,
                          listTextHeight: listTextHeight,
                          onTap: () async {
                            displayDetailByBarcode = false;
                            await logInsert(guid: "", commandCode: 1, barcode: detail.barcode, code: detail.item_code, closeExtra: false, qty: "1.0");
                          }.withAddSound(),
                          onCountTap: detail.product_count > 0
                              ? () {
                                  // Handle count tap if needed
                                }
                              : null,
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget selectProductLevelExtraListCheckWidget(int groupIndex) {
    int activeLineIndex = global.findActiveLineIndex(holdCode: global.posHoldActiveCode);
    if (activeLineIndex != -1) {
      PosProcessDetailModel data = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess.details[activeLineIndex];
      for (var checkBoxIndex = 0; checkBoxIndex < productOptions[groupIndex].choices.length; checkBoxIndex++) {
        productOptions[groupIndex].choices[checkBoxIndex].selected = false;
      }
      for (var detailIndex = 0; detailIndex < data.extra.length; detailIndex++) {
        for (var checkBoxIndex = 0; checkBoxIndex < productOptions[groupIndex].choices.length; checkBoxIndex++) {
          if (data.extra[detailIndex].guid_code_or_ref == productOptions[groupIndex].choices[checkBoxIndex].guid) {
            productOptions[groupIndex].choices[checkBoxIndex].selected = true;
          }
        }
      }
    }
    return Column(
      children: [
        for (var detailIndex = 0; detailIndex < productOptions[groupIndex].choices.length; detailIndex++)
          Material(
            // color: global.posTheme.background,
            child: InkWell(
              onTap: () async {
                var value = productOptions[groupIndex].choices[detailIndex].selected;
                await selectProductLevelExtraListCheck(groupIndex, detailIndex, value!);
                processEvent(barcode: "", holdCode: global.posHoldActiveCode);
              }.withButtonSound(),
              child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: Theme(
                              data: ThemeData(primarySwatch: _themeSwatch),
                              child: Checkbox(onChanged: null, fillColor: WidgetStateProperty.all((productOptions[groupIndex].choices[detailIndex].selected!) ? _themeSwatch : Colors.white), value: productOptions[groupIndex].choices[detailIndex].selected),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(global.getNameFromLanguage(productOptions[groupIndex].choices[detailIndex].names, global.userScreenLanguage), style: const TextStyle(fontSize: 12, color: Colors.black)),
                          ),
                        ],
                      ),
                    ),
                    ((double.tryParse(productOptions[groupIndex].choices[detailIndex].price) ?? 0) == 0)
                        ? Container()
                        : Text(
                            "+${productOptions[groupIndex].choices[detailIndex].price}",
                            style: TextStyle(fontSize: 12, color: _themeSwatch, fontWeight: FontWeight.bold),
                          ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget selectProductLevelExtraWidget() {
    int activeLineIndex = global.findActiveLineIndex(holdCode: global.posHoldActiveCode);
    return (productOptions.isEmpty)
        ? Container()
        : SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                // color: global.posTheme.background,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
              width: 200,
              child: Column(
                children: [
                  if (activeLineIndex != -1)
                    Row(
                      children: [
                        if (product.images_url.isNotEmpty && global.isOnline)
                          Container(
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                            child: Image(width: 80, height: 60, image: AppImageCacheManager.getCachedNetwork(product.images_url), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error)),
                          ),
                        Flexible(
                          child: Text(
                            "${global.getNameFromJsonLanguage(product.names, global.userScreenLanguage)}/${global.getNameFromJsonLanguage(product.unit_names, global.userScreenLanguage)}",
                            maxLines: 2,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: _getDynamicFontSize(13)),
                          ),
                        ),
                      ],
                    ),
                  for (var groupIndex = 0; groupIndex < productOptions.length; groupIndex++)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                global.getNameFromLanguage(productOptions[groupIndex].names, global.userScreenLanguage),
                                style: TextStyle(fontSize: 14, color: _themeSwatch, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10, height: 10),
                            (productOptions[groupIndex].maxselect > 1)
                                ? Flexible(
                                    child: Text("${global.language("max")} ${productOptions[groupIndex].maxselect} ${global.language("list")}", style: const TextStyle(fontSize: 10, color: Colors.red)),
                                  )
                                : Flexible(
                                    child: Text(global.language("choose_one_option"), style: const TextStyle(fontSize: 10, color: Colors.red)),
                                  ),
                          ],
                        ),
                        selectProductLevelExtraListCheckWidget(groupIndex),
                      ],
                    ),
                ],
              ),
            ),
          );
  }

  void productCategorySelectedAdd(ProductCategoryObjectBoxStruct value) {
    bool found = false;
    for (var find in global.productCategoryCodeSelected) {
      if (find.guid_fixed == categoryGuidSelected) {
        found = true;
      }
    }
    if (found == false) {
      global.productCategoryCodeSelected.add(value);
    }
  }

  Widget selectProductLevelCardWidget(ProductCategoryObjectBoxStruct value, double boxSize, bool append, double widthHeight) {
    double round = 8;
    String name = global.getNameFromJsonLanguage(value.names, global.userScreenLanguage);
    bool isSelected = categoryGuidSelected == value.guid_fixed;

    return Container(
      padding: const EdgeInsets.all(3),
      width: widthHeight,
      height: widthHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(round),
          boxShadow: [BoxShadow(color: isSelected ? _themeSwatch.withOpacity(0.3) : Colors.black.withOpacity(0.1), blurRadius: isSelected ? 8 : 4, offset: isSelected ? const Offset(0, 4) : const Offset(0, 2))],
        ),
        child: Material(
          borderRadius: BorderRadius.circular(round),
          child: InkWell(
            borderRadius: BorderRadius.circular(round),
            onTap: () async {
              // เพิ่มการ feedback แบบ haptic
              HapticFeedback.lightImpact();

              categoryGuidSelected = value.guid_fixed;
              if (append == true) {
                // กรณีมีลูกให้เพิ่มการเลือก
                if (value.category_count > 0) {
                  productCategorySelectedAdd(value);
                } else {
                  // กรณีเลือกกลุ่มลูกให้เพิ่มการเลือก
                  if (value.parent_guid_fixed.isNotEmpty) {
                    productCategorySelectedAdd(value);
                  }
                }
              }
              await loadProductByCategory(categoryGuidSelected);
              productOptions.clear();
              setState(() {
                PosProcess().sumCategoryCount(value: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(round),
                gradient: isSelected
                    ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_themeSwatch[400]!, _themeSwatch[600]!])
                    : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.grey.shade50]),
                border: Border.all(color: isSelected ? _themeSwatch[700]! : Colors.grey.shade300, width: isSelected ? 2.5 : 1),
              ),
              child: (value.use_image_or_color == true && value.image_url.isNotEmpty)
                  ? Column(
                      children: [
                        Expanded(
                          flex: 7,
                          child: Container(
                            margin: const EdgeInsets.all(0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(round - 2),
                              image: DecorationImage(image: AppImageCacheManager.getCachedNetwork(value.image_url), fit: BoxFit.cover, onError: (error, stackTrace) {}),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                            child: Center(
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: (13 * listTextHeight).clamp(9.0, 15.0),
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.black87,
                                  shadows: isSelected ? [const Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54)] : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(round), color: (value.use_image_or_color == false) ? global.colorFromHex(value.colorselecthex.replaceAll("#", "")).withOpacity(0.2) : null),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (value.category_count > 0)
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.2) : _themeSwatch[100]!, borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.folder, size: 14, color: isSelected ? Colors.white : _themeSwatch[700]!),
                              ),
                            Flexible(
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: (11 * listTextHeight).clamp(9.0, 14.0),
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.black87,
                                  shadows: isSelected ? [const Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54)] : null,
                                ),
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
    );
  }

  Widget selectProductLevelSelectWidget() {
    double widthHeight = (global.isDesktopScreen() || global.isTabletScreen()) ? 95 : 85;
    List<Widget> categorySelectedList = [];

    if (global.productCategoryCodeSelected.isNotEmpty) {
      categorySelectedList.add(
        Container(
          width: widthHeight,
          height: widthHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [BoxShadow(color: _themeSwatch.withOpacity(0.2), spreadRadius: 2, blurRadius: 4, offset: const Offset(0, 2))],
            border: Border.all(color: _themeSwatch[300]!, width: 2),
          ),
          child: Material(
            borderRadius: BorderRadius.circular(3),
            child: InkWell(
              borderRadius: BorderRadius.circular(3),
              onTap: () {
                HapticFeedback.lightImpact();
                global.productCategoryChildList.clear();
                global.productCategoryCodeSelected.clear();
                categoryGuidSelected = "";
                productOptions.clear();
                loadCategory();
                setState(() {
                  PosProcess().sumCategoryCount(value: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess);
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_themeSwatch[400]!, _themeSwatch[600]!]),
                ),
                child: const Center(child: Icon(Icons.restart_alt, color: Colors.white, size: 28)),
              ),
            ),
          ),
        ),
      );
      for (var categoryList in global.productCategoryCodeSelected) {
        categorySelectedList.add(selectProductLevelCardWidget(categoryList, gridItemSize, false, widthHeight));
      }
    } else {
      categorySelectedList.add(Container());
    }
    List<ProductCategoryObjectBoxStruct> categoryList = (global.productCategoryChildList.isEmpty) ? global.productCategoryList : global.productCategoryChildList;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        (global.productCategoryCodeSelected.isEmpty)
            ? Container()
            : Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: _themeSwatch[50]!,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _themeSwatch[200]!, width: 1),
                    ),
                    width: double.infinity,
                    height: 90,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}),
                      child: ListView(scrollDirection: Axis.horizontal, physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 8), children: categorySelectedList),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          width: double.infinity,
          height: 100,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              children: [for (final value in categoryList) selectProductLevelCardWidget(value, gridItemSize, true, widthHeight)],
            ),
          ),
        ),
      ],
    );
  }

  Widget selectProductLevelWidget() {
    int activeLineIndex = global.findActiveLineIndex(holdCode: global.posHoldActiveCode);
    return Column(
      children: [
        Expanded(child: selectProductLevelListScreenWidget()),
        if (displayDetailByBarcode && activeLineIndex > -1)
          SizedBox(
            height: 250,
            width: double.infinity,
            child: transScreen(mode: 1, barcode: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess.details[activeLineIndex].barcode),
          ),
        selectProductLevelSelectWidget(),
      ],
    );
  }

  Widget selectProductExtraListWidget() {
    return Align(
      alignment: Alignment.topLeft,
      child: Card(
        child: Container(
          margin: const EdgeInsets.all(2),
          height: double.infinity,
          // decoration: BoxDecoration(
          //   color: global.posTheme.background,
          //   border: Border.all(color: Colors.black, width: 1.0),
          //   borderRadius: BorderRadius.all(Radius.circular(4)),
          // ),
          child: selectProductLevelExtraWidget(),
        ),
      ),
    );
  }

  Widget selectProductByQrCodeOrBarcode() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // QR Code Scanner View
          if (qrCodeBarcodeScannerStart)
            Container(
              decoration: BoxDecoration(color: _themeSwatch),
              child: QRView(
                key: qrKey,
                onQRViewCreated: onQRViewCreated,
                formatsAllowed: const [BarcodeFormat.code128, BarcodeFormat.code39, BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.itf, BarcodeFormat.upcA, BarcodeFormat.upcE, BarcodeFormat.aztec, BarcodeFormat.dataMatrix, BarcodeFormat.pdf417],
              ),
            ),

          // History text overlay
          if (qrCodeBarcodeScannerStart)
            Positioned(
              top: 8,
              left: 8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: qrCodeBarcodeScannerHistory
                    .map(
                      (e) => Text(
                        e,
                        style: TextStyle(
                          color: ((e.contains('*')) ? Colors.orange : Colors.white),
                          fontSize: 18,
                          shadows: const [
                            Shadow(offset: Offset(-1, -1), color: Colors.black),
                            Shadow(offset: Offset(1, -1), color: Colors.black),
                            Shadow(offset: Offset(1, 1), color: Colors.black),
                            Shadow(offset: Offset(-1, 1), color: Colors.black),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          // Control buttons overlay
          if (qrCodeBarcodeScannerStart)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      setState(() {
                        if (qrCodeBarcodeScannerQtyResult > 1) {
                          qrCodeBarcodeScannerQtyResult--;
                        }
                      });
                    },
                    child: const Icon(Icons.exposure_minus_1),
                  ),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      setState(() {
                        qrCodeBarcodeScannerQtyResult = 1;
                      });
                    },
                    child: Text(
                      global.moneyFormat.format(qrCodeBarcodeScannerQtyResult),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(offset: Offset(-1, -1), color: Colors.white),
                          Shadow(offset: Offset(1, -1), color: Colors.white),
                          Shadow(offset: Offset(1, 1), color: Colors.white),
                          Shadow(offset: Offset(-1, 1), color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      setState(() {
                        if (qrCodeBarcodeScannerQtyResult < 999) {
                          qrCodeBarcodeScannerQtyResult++;
                        }
                      });
                    },
                    child: const Icon(Icons.exposure_plus_1),
                  ),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      setState(() {
                        scanController!.toggleFlash();
                      });
                    },
                    child: const Icon(Icons.flash_on),
                  ),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () async {
                      try {
                        // ปิด camera ก่อนแล้วค่อยปิด scanner
                        if (scanController != null) {
                          await scanController!.pauseCamera();
                        }
                      } catch (e) {
                        AppLogger.error("Error pausing camera before close: $e");
                      }
                      setState(() {
                        qrCodeBarcodeScannerStart = false;
                      });
                    },
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget detailHeaderWidget() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double fontSize = (constraints.maxWidth / 50) * listTextHeight;
        TextStyle textStyle = TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: fontSize);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: const Border(bottom: BorderSide(color: Colors.black, width: 1)),
            color: _themeSwatch[100]!,
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: Text(
                  global.language("item_grid_description"),
                  style: textStyle.copyWith(fontSize: fontSize),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  global.language("item_grid_total"),
                  textAlign: TextAlign.right,
                  style: textStyle.copyWith(fontSize: fontSize),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> detailFooterDetailVat({required PosProcessModel process, required double fontSize, required TextStyle textStyle}) {
    // ภาษีรวมใน
    List<Widget> footer = [];
    footer.add(
      Row(
        children: [
          Expanded(
            flex: 10,
            child: Text(
              "${global.language("total")} ${process.details.length} ${global.language("line")} ${global.moneyFormat.format(process.total_piece)} ${global.language("piece")}",
              style: textStyle.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              global.moneyFormatAndDot.format(process.detail_total_amount_before_discount),
              textAlign: TextAlign.right,
              style: textStyle.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (global.tempIsRestaurantSystem) {
      if (process.total_food_amount != 0) {
        footer.add(
          Row(
            children: [
              Expanded(
                flex: 10,
                child: Text(global.language("total_food_cost"), style: textStyle.copyWith(fontSize: fontSize)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  global.moneyFormatAndDot.format(process.total_food_amount),
                  textAlign: TextAlign.right,
                  style: textStyle.copyWith(fontSize: fontSize),
                ),
              ),
            ],
          ),
        );
      }
      if (process.total_drink_amount + process.total_alcohol_amount + process.total_other_amount != 0) {
        footer.add(
          Row(
            children: [
              Expanded(
                flex: 10,
                child: Text(global.language("total_drink_snack_cost"), style: textStyle.copyWith(fontSize: fontSize)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  global.moneyFormatAndDot.format(process.total_drink_amount + process.total_alcohol_amount + process.total_other_amount),
                  textAlign: TextAlign.right,
                  style: textStyle.copyWith(fontSize: fontSize),
                ),
              ),
            ],
          ),
        );
      }
    }
    if (process.total_piece != process.total_piece_vat) {
      // กรณีมีสินค้าทั้งประเภทภาษี และยกเว้นภาษี ให้แสดงรายละเอียด
      footer.add(
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Text("${global.language("product_has_tax")} : ${global.moneyFormat.format(process.total_piece_vat)} ${global.language("piece")}", style: textStyle.copyWith(fontSize: fontSize)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                global.moneyFormatAndDot.format(process.total_item_vat_amount),
                textAlign: TextAlign.right,
                style: textStyle.copyWith(fontSize: fontSize),
              ),
            ),
          ],
        ),
      );
      footer.add(
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Text("${global.language("product_tax_exempt")} : ${global.moneyFormat.format(process.total_piece_except_vat)} ${global.language("piece")}", style: textStyle.copyWith(fontSize: fontSize)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                global.moneyFormatAndDot.format(process.total_item_except_vat_amount),
                textAlign: TextAlign.right,
                style: textStyle.copyWith(fontSize: fontSize),
              ),
            ),
          ],
        ),
      );
    }
    if (process.total_discount_from_promotion + process.total_discount_from_promotion_bottom != 0) {
      footer.add(
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Text(global.language("promotion_discount"), style: textStyle.copyWith(fontSize: fontSize)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                global.moneyFormatAndDot.format(process.total_discount_from_promotion + process.total_discount_from_promotion_bottom),
                textAlign: TextAlign.right,
                style: textStyle.copyWith(fontSize: fontSize),
              ),
            ),
          ],
        ),
      );
    }
    if (process.pointdiscountamount > 0) {
      footer.add(
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Text(
                "${global.language("used_points")} ${process.usepoint} ",
                style: textStyle.copyWith(fontSize: fontSize, color: Colors.red),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "- ${global.moneyFormat.format(process.pointdiscountamount)}",
                textAlign: TextAlign.right,
                style: textStyle.copyWith(fontSize: fontSize, color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
    if (process.detail_total_discount != 0) {
      // มีส่วนลดสินค้า
      String beforeWord = (process.total_discount_vat_amount != 0 && process.total_discount_except_vat_amount != 0) ? global.language("average") : "";
      footer.add(
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Text(
                "${global.language("discount_product")} : ${process.detail_discount_formula}",
                style: textStyle.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                global.moneyFormatAndDot.format(process.detail_total_discount - (process.total_discount_from_promotion + process.total_discount_from_promotion_bottom)),
                textAlign: TextAlign.right,
                style: textStyle.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (process.total_discount_vat_amount != 0) {
        // มีส่วนลดสินค้ามีภาษี
        footer.add(
          Row(
            children: [
              Expanded(
                flex: 10,
                child: Text(beforeWord + global.language("discount_product_vat"), style: textStyle.copyWith(fontSize: fontSize)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  global.moneyFormatAndDot.format(process.total_discount_vat_amount),
                  textAlign: TextAlign.right,
                  style: textStyle.copyWith(fontSize: fontSize),
                ),
              ),
            ],
          ),
        );
      }
      if (process.total_discount_except_vat_amount != 0) {
        // มีส่วนลดสินค้ายกเว้นภาษี
        footer.add(
          Row(
            children: [
              Expanded(
                flex: 10,
                child: Text("$beforeWord${global.language("discount_prtoduct_no_vat")}", style: textStyle.copyWith(fontSize: fontSize)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  global.moneyFormatAndDot.format(process.total_discount_except_vat_amount),
                  textAlign: TextAlign.right,
                  style: textStyle.copyWith(fontSize: fontSize),
                ),
              ),
            ],
          ),
        );
      }
    }
    if (process.amount_before_calc_vat != 0) {
      footer.add(
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Text(global.language("pre_tax_value"), style: textStyle.copyWith(fontSize: fontSize)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                global.moneyFormatAndDot.format(process.amount_before_calc_vat),
                textAlign: TextAlign.right,
                style: textStyle.copyWith(fontSize: fontSize),
              ),
            ),
          ],
        ),
      );
    }
    if (process.total_vat_amount != 0) {
      footer.add(
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Text(
                global.language("value_added_tax"),
                style: textStyle.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                global.moneyFormatAndDot.format(process.total_vat_amount),
                textAlign: TextAlign.right,
                style: textStyle.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
    if (process.amount_after_calc_vat != 0 && process.amount_after_calc_vat != process.total_amount) {
      // มูลค่าหลังคิดภาษี (สินค้ามีภาษี)
      footer.add(
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Text(global.language("value_after_tax"), style: textStyle.copyWith(fontSize: fontSize)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                global.moneyFormatAndDot.format(process.amount_after_calc_vat),
                textAlign: TextAlign.right,
                style: textStyle.copyWith(fontSize: fontSize),
              ),
            ),
          ],
        ),
      );
    }
    if (process.amount_except_vat != 0 && process.amount_except_vat != process.total_amount) {
      // มูลค่าสินค้ายกเว้นภาษี
      footer.add(
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Text(global.language("value_tax_exempt"), style: textStyle.copyWith(fontSize: fontSize)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                global.moneyFormatAndDot.format(process.amount_except_vat),
                textAlign: TextAlign.right,
                style: textStyle.copyWith(fontSize: fontSize),
              ),
            ),
          ],
        ),
      );
    }

    footer.add(
      Row(
        children: [
          Expanded(
            flex: 10,
            child: Text(
              global.language("total"),
              style: textStyle.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              global.moneyFormatAndDot.format(process.total_amount),
              textAlign: TextAlign.right,
              style: textStyle.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // if (process.getpoint > 0) {
    //   footer.add(Row(
    //     children: [
    //       Expanded(
    //         flex: 10,
    //         child: Text(global.language("earned_points"), style: textStyle.copyWith(fontSize: fontSize, color: Colors.green)),
    //       ),
    //       Expanded(
    //           flex: 2,
    //           child: Text("+ ${global.moneyFormat.format(process.getpoint)}",
    //               textAlign: TextAlign.right, style: textStyle.copyWith(fontSize: fontSize, color: Colors.green, fontWeight: FontWeight.bold))),
    //     ],
    //   ));
    // }

    return footer;
  }

  List<Widget> detailFooterDetail({required PosProcessModel process, required double fontSize, required TextStyle textStyle, required bool showVatAmount}) {
    // ภาษีรวมใน
    List<Widget> footer = [];
    // กรณีไม่แสดงรายละเอียด ให้แสดงแบบคร่าวๆ
    footer.add(
      Row(
        children: [
          Expanded(
            flex: 10,
            child: Text("${global.language("total")} ${process.details.length} ${global.language("line")} ${global.moneyFormat.format(process.total_piece)} ${global.language("piece")}", style: textStyle.copyWith(fontSize: fontSize)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              global.moneyFormatAndDot.format(process.detail_total_amount_before_discount),
              textAlign: TextAlign.right,
              style: textStyle.copyWith(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
    if (global.tempIsRestaurantSystem) {
      if (process.total_food_amount != 0) {
        footer.add(
          Row(
            children: [
              Expanded(
                flex: 10,
                child: Text(global.language("total_food_cost"), style: textStyle.copyWith(fontSize: fontSize)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  global.moneyFormatAndDot.format(process.total_food_amount),
                  textAlign: TextAlign.right,
                  style: textStyle.copyWith(fontSize: fontSize),
                ),
              ),
            ],
          ),
        );
      }
      if (process.total_drink_amount + process.total_alcohol_amount + process.total_other_amount != 0) {
        footer.add(
          Row(
            children: [
              Expanded(
                flex: 10,
                child: Text(global.language("total_drink_snack_cost"), style: textStyle.copyWith(fontSize: fontSize)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  global.moneyFormatAndDot.format(process.total_drink_amount + process.total_alcohol_amount + process.total_other_amount),
                  textAlign: TextAlign.right,
                  style: textStyle.copyWith(fontSize: fontSize),
                ),
              ),
            ],
          ),
        );
      }
    }
    if (process.total_discount_from_promotion + process.total_discount_from_promotion_bottom != 0) {
      footer.add(
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Text(global.language("ส่วนลดโปรโมชั่น"), style: textStyle.copyWith(fontSize: fontSize)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                global.moneyFormatAndDot.format(process.total_discount_from_promotion + process.total_discount_from_promotion_bottom),
                textAlign: TextAlign.right,
                style: textStyle.copyWith(fontSize: fontSize),
              ),
            ),
          ],
        ),
      );
    }
    if (process.pointdiscountamount > 0) {
      footer.add(
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Text(
                "${global.language("used_points")} ${process.usepoint} ",
                style: textStyle.copyWith(fontSize: fontSize, color: Colors.red),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "- ${global.moneyFormat.format(process.pointdiscountamount)}",
                textAlign: TextAlign.right,
                style: textStyle.copyWith(fontSize: fontSize, color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
    if (process.detail_total_discount != 0) {
      footer.add(
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Text("${global.language("ส่วนลด")} : ${process.detail_discount_formula}", style: textStyle.copyWith(fontSize: fontSize)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                global.moneyFormatAndDot.format(process.detail_total_discount),
                textAlign: TextAlign.right,
                style: textStyle.copyWith(fontSize: fontSize),
              ),
            ),
          ],
        ),
      );

      if (showVatAmount) {
        footer.add(
          Row(
            children: [
              Expanded(
                flex: 10,
                child: Text(global.language("value_added_tax"), style: textStyle.copyWith(fontSize: fontSize)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  global.moneyFormatAndDot.format(process.total_vat_amount),
                  textAlign: TextAlign.right,
                  style: textStyle.copyWith(fontSize: fontSize),
                ),
              ),
            ],
          ),
        );
      }
    }

    footer.add(
      Row(
        children: [
          Expanded(
            flex: 10,
            child: Text(
              global.language("amount_of_money"),
              style: textStyle.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              global.moneyFormatAndDot.format(process.total_amount),
              textAlign: TextAlign.right,
              style: textStyle.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // if (process.getpoint > 0) {
    //   footer.add(Row(
    //     children: [
    //       Expanded(
    //         flex: 10,
    //         child: Text(global.language("earned_points"), style: textStyle.copyWith(fontSize: fontSize, color: Colors.green)),
    //       ),
    //       Expanded(
    //           flex: 2,
    //           child: Text("+ ${global.moneyFormat.format(process.getpoint)}",
    //               textAlign: TextAlign.right, style: textStyle.copyWith(fontSize: fontSize, color: Colors.green, fontWeight: FontWeight.bold))),
    //     ],
    //   ));
    // }

    return footer;
  }

  Widget detailFooterWidget() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double fontSize = (constraints.maxWidth / 50) * listTextHeight;
        TextStyle textStyle = TextStyle(color: Colors.black, fontSize: fontSize);
        int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
        PosProcessModel process = global.posHoldProcessResult[holdIndex].posProcess;
        List<Widget> footer = [];
        if (showDetail) {
          if (global.posConfig.isvatregister) {
            // จดทะเบียนภาษี
            footer.addAll(detailFooterDetailVat(process: process, fontSize: fontSize, textStyle: textStyle));
          } else {
            // กรณีไม่จดทะเบียน
            footer.addAll(detailFooterDetail(process: process, fontSize: fontSize, textStyle: textStyle, showVatAmount: false));
          }
        } else {
          // กรณีไม่แสดงรายละเอียด ให้แสดงแบบคร่าวๆ
          if (global.posConfig.isvatregister) {
            footer.addAll(detailFooterDetail(process: process, fontSize: fontSize, textStyle: textStyle, showVatAmount: (global.posConfig.vattype == 1) ? true : false));
          } else {
            footer.addAll(detailFooterDetail(process: process, fontSize: fontSize, textStyle: textStyle, showVatAmount: false));
          }
        }
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: const Border(top: BorderSide(color: Colors.black, width: 1)),
            color: _themeSwatch[100]!,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(children: footer),
          ),
        );
      },
    );
  }

  Widget detailWidget({
    required String productName,
    bool fullDetail = false,
    required bool isExtra,
    double qty = 0,
    double price = 0.0,
    double priceOriginal = 0.0,
    bool isActive = false,
    required double totalAmount,
    required TextStyle textStyle,
    required String barcode,
    required String itemCode,
    required String unitName,
    required String imageUrl,
    required String patternCode,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double fontSize = _getDynamicFontSize(15.0); // เพิ่มขนาด default จาก 12.0 เป็น 15.0

        // ปรับ padding สำหรับ extra items
        EdgeInsets itemPadding = isExtra ? const EdgeInsets.only(left: 16, top: 2, bottom: 2, right: 4) : const EdgeInsets.symmetric(horizontal: 4, vertical: 2);

        // สร้าง product name text พร้อม styling
        List<TextSpan> productTextSpan = [];

        // ชื่อสินค้า
        productTextSpan.add(
          TextSpan(
            text: productName,
            style: textStyle.copyWith(fontSize: fontSize, fontWeight: isActive ? FontWeight.w600 : textStyle.fontWeight, color: isExtra ? Colors.grey.shade700 : textStyle.color),
          ),
        );

        if (patternCode.isNotEmpty) {
          productTextSpan.add(
            TextSpan(
              text: " [$patternCode]",
              style: textStyle.copyWith(fontSize: fontSize * 0.85, color: Colors.grey.shade600, fontFamily: 'monospace'),
            ),
          );
        }

        // จำนวนและหน่วย
        if (qty != 0) {
          productTextSpan.add(
            TextSpan(
              text: " × ${global.moneyFormat.format(qty)}",
              style: textStyle.copyWith(fontSize: fontSize * 0.9, color: _themeSwatch[600]!, fontWeight: FontWeight.w500),
            ),
          );

          if (unitName.isNotEmpty) {
            productTextSpan.add(
              TextSpan(
                text: " $unitName",
                style: textStyle.copyWith(fontSize: fontSize * 0.85, color: Colors.grey.shade600),
              ),
            );
          }

          // 🆕 แสดง price breakdown ถ้ามี promotion (price_original > price)
          if (priceOriginal > price && price > 0) {
            productTextSpan.add(
              TextSpan(
                text: " (",
                style: textStyle.copyWith(fontSize: fontSize * 0.8, color: Colors.grey.shade600),
              ),
            );
            // ราคาเดิมรวม (ขีดทับ)
            productTextSpan.add(
              TextSpan(
                text: "จากเดิม ${global.moneyFormat.format(priceOriginal)}",
                style: textStyle.copyWith(fontSize: fontSize * 0.75, color: Colors.grey.shade600, decoration: TextDecoration.lineThrough),
              ),
            );
            // ราคาพิเศษรวม (สีแดง)
            productTextSpan.add(
              TextSpan(
                text: " ราคาพิเศษ ${global.moneyFormat.format(price)}",
                style: textStyle.copyWith(fontSize: fontSize * 0.75, color: Colors.red.shade600, fontWeight: FontWeight.w600),
              ),
            );
            productTextSpan.add(
              TextSpan(
                text: ")",
                style: textStyle.copyWith(fontSize: fontSize * 0.8, color: Colors.grey.shade600),
              ),
            );
          }
          // แสดงราคาต่อหน่วยถ้าไม่มี promotion แต่มีเงื่อนไขอื่น
          else if (price * qty != totalAmount || qty != 1) {
            productTextSpan.add(
              TextSpan(
                text: " @${global.moneyFormat.format(price)}",
                style: textStyle.copyWith(fontSize: fontSize * 0.8, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
              ),
            );
          }
        }

        return Container(
          padding: itemPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // แสดงไอคอนสำหรับ extra items
              if (isExtra)
                Container(
                  margin: const EdgeInsets.only(right: 8, top: 2),
                  child: Icon(Icons.subdirectory_arrow_right, size: fontSize * 0.8, color: Colors.grey.shade500),
                ),

              // ส่วนข้อมูลสินค้า
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: textStyle.copyWith(fontSize: fontSize),
                        children: productTextSpan,
                      ),
                      maxLines: isActive ? null : 2,
                      overflow: isActive ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                    // แสดง barcode เมื่อ active
                    if (isActive && barcode.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          "$barcode/$itemCode",
                          style: textStyle.copyWith(fontSize: fontSize * 0.7, color: Colors.grey.shade600, fontFamily: 'monospace'),
                        ),
                      ),
                  ],
                ),
              ),

              // รูปภาพสินค้า (แสดงเมื่อ active)
              if (isActive && imageUrl.isNotEmpty && !isExtra)
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(left: 8, right: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image(
                      fit: BoxFit.cover,
                      image: AppImageCacheManager.getCachedNetwork(imageUrl),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_themeSwatch[300]!))),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 24),
                    ),
                  ),
                ),

              // ราคารวม
              if (totalAmount != 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 80),
                  child: Text(
                    global.moneyFormat.format(totalAmount),
                    textAlign: TextAlign.right,
                    style: textStyle.copyWith(fontSize: fontSize, fontWeight: FontWeight.w600, color: isExtra ? Colors.grey.shade600 : (totalAmount < 0 ? Colors.red.shade600 : Colors.black)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget detailRow({required int index, required PosProcessDetailModel detail, required TextStyle textStyle, bool isActive = false}) {
    double extraAmount = 0.0;
    TextStyle extraTextStyle = TextStyle(fontSize: _getDynamicFontSize(13.0), fontWeight: textStyle.fontWeight, color: Colors.grey.shade600);

    String description = "${global.getNameFromJsonLanguage(detail.item_name, global.userScreenLanguage)}${(detail.remark.isNotEmpty) ? " (${detail.remark})" : ""}";

    // เพิ่ม badges สำหรับข้อมูลพิเศษ
    List<String> badges = [];
    if (detail.is_except_vat) {
      badges.add("ยกเว้นภาษี");
    }
    if (!detail.issumpoint) {
      badges.add("ไม่สะสมคะแนน");
    }

    // รวม badges เข้ากับ description
    if (badges.isNotEmpty) {
      description = "$description • ${badges.join(" • ")}";
    }

    for (final extra in detail.extra) {
      extraAmount += extra.total_amount;
    }

    List<Widget> columnList = [];

    // Main product item
    columnList.add(
      detailWidget(
        isActive: isActive,
        fullDetail: true,
        isExtra: false,
        productName: description,
        qty: detail.qty,
        price: detail.price,
        priceOriginal: detail.price_original,
        totalAmount: detail.total_amount,
        textStyle: textStyle,
        barcode: detail.barcode,
        itemCode: detail.item_code,
        unitName: global.getNameFromJsonLanguage(detail.unit_name, global.userScreenLanguage),
        imageUrl: detail.image_url,
        patternCode: detail.pattern_code,
      ),
    );

    // Extra items with improved styling
    for (final extra in detail.extra) {
      columnList.add(
        detailWidget(
          isExtra: true,
          productName: global.getNameFromJsonLanguage(extra.item_name, global.userScreenLanguage),
          qty: (extra.qty == 0) ? 0 : extra.qty,
          price: extra.price,
          priceOriginal: extra.price,
          totalAmount: (extra.price == 0) ? 0 : extra.total_amount,
          unitName: "",
          barcode: "",
          itemCode: "",
          textStyle: extraTextStyle,
          imageUrl: "",
          patternCode: "",
        ),
      );
    }

    // Total with extras (only show if there are extras)
    if (extraAmount != 0) {
      columnList.add(
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: _themeSwatch[50]!,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _themeSwatch[200]!, width: 0.5),
          ),
          child: detailWidget(
            isExtra: false,
            productName: "รวม ${global.getNameFromJsonLanguage(detail.item_name, global.userScreenLanguage)}",
            qty: 0,
            price: 0,
            priceOriginal: detail.price_original,
            unitName: "",
            totalAmount: detail.total_amount + extraAmount,
            textStyle: TextStyle(fontSize: _getDynamicFontSize(15.0), fontWeight: FontWeight.w600, color: _themeSwatch[800]!),
            barcode: detail.barcode,
            itemCode: detail.item_code,
            patternCode: detail.pattern_code,
            imageUrl: "",
          ),
        ),
      );
    }

    // Discount information with better styling
    if (detail.discount != 0) {
      columnList.add(
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.red.shade200, width: 0.5),
          ),
          child: detailWidget(
            isExtra: false,
            productName: "ส่วนลด: ${detail.discount_text}",
            qty: 0,
            price: 0,
            priceOriginal: detail.price_original,
            unitName: "",
            totalAmount: detail.discount * -1,
            textStyle: TextStyle(fontSize: _getDynamicFontSize(14.0), fontWeight: FontWeight.w500, color: Colors.red.shade700),
            barcode: detail.barcode,
            itemCode: detail.item_code,
            imageUrl: "",
            patternCode: detail.pattern_code,
          ),
        ),
      );

      columnList.add(
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.shade200, width: 0.5),
          ),
          child: detailWidget(
            isExtra: false,
            productName: "ราคาหลังหักส่วนลด",
            qty: 0,
            price: 0,
            priceOriginal: detail.price_original,
            unitName: "",
            totalAmount: (detail.total_amount + extraAmount) - detail.discount,
            textStyle: TextStyle(fontSize: _getDynamicFontSize(14.0), fontWeight: FontWeight.w600, color: Colors.green.shade700),
            barcode: detail.barcode,
            itemCode: detail.item_code,
            patternCode: detail.pattern_code,
            imageUrl: "",
          ),
        ),
      );
    }

    return Column(children: columnList);
  }

  Widget detailData({required int index, required PosProcessDetailModel detail, required bool active, required TextStyle textStyle}) {
    int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
    int activeLineIndex = global.findActiveLineIndex(holdCode: global.posHoldActiveCode);

    // ปรับปรุงการใช้สีให้ดูสวยและเข้าใจง่าย
    Color backgroundColor;
    Color? borderColor;
    double borderWidth = 0;

    if (detail.is_void) {
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
      borderWidth = 1;
    } else if (index == activeLineIndex) {
      backgroundColor = _themeSwatch[50]!;
      borderColor = _themeSwatch[300]!;
      borderWidth = 1.5;
    } else if (index % 2 == 0) {
      backgroundColor = Colors.white;
    } else {
      backgroundColor = Colors.grey.shade50;
    }

    Widget widget = Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: borderColor != null ? Border.all(color: borderColor, width: borderWidth) : null,
        boxShadow: index == activeLineIndex ? [BoxShadow(color: _themeSwatch.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: detailRow(index: index, detail: detail, textStyle: textStyle, isActive: active),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: (detail.is_void)
          ? widget
          : InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () async {
                activeLineIndex = index;
                global.posHoldProcessResult[holdIndex].activeLineGuid = global.posHoldProcessResult[holdIndex].posProcess.details[index].guid;
                global.posHoldProcessResult[holdIndex].posProcess.select_promotion_temp_list.clear();

                product =
                    await ProductBarcodeHelper().selectByBarcodeFirst(global.posHoldProcessResult[holdIndex].posProcess.details[index].barcode) ??
                    ProductBarcodeObjectBoxStruct(
                      barcode: "",
                      color_select: "",
                      image_or_color: true,
                      color_select_hex: "",
                      names: "",
                      name_all: "",
                      images_url: "",
                      prices: "",
                      unit_code: "",
                      unit_stand: 1,
                      unit_divide: 1,
                      unit_names: "",
                      new_line: 0,
                      guid_fixed: "",
                      item_code: "",
                      item_guid: "",
                      vat_type: 1,
                      descriptions: "",
                      options_json: "",
                      isalacarte: true,
                      ordertypes: "",
                      ref_barcode_json: "",
                      product_count: 0,
                      is_except_vat: false,
                      issplitunitprint: false,
                      is_resterant_use_stock: false,
                      food_type: 0,
                      patterncode: "",
                    );
                try {
                  productOptions = (await jsonDecode(product.options_json) as List).map((e) => ProductOptionModel.fromJson(e)).toList();
                } catch (e) {
                  productOptions = [];
                }
                setState(() {});
              },
              child: widget,
            ),
    );
  }

  Widget detailButton({required int index, required PosProcessDetailModel detail, required bool active, required TextStyle textStyle}) {
    TextEditingController textFieldRemarkController = TextEditingController(text: detail.remark);
    int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);

    // ปรับปรุงให้ดูสวยและกระชับขึ้น
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white, // เปลี่ยนเป็นพื้นหลังสีขาว
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
        border: Border.all(color: _themeSwatch[200]!, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Quantity controls - grouped together
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _buildCompactButton(
                    icon: Icons.remove,
                    label: "-1",
                    color: Colors.red.shade400,
                    onPressed: () async {
                      if (detail.qty > 1) {
                        await logInsert(commandCode: 3, guid: global.posHoldProcessResult[holdIndex].activeLineGuid, closeExtra: false);
                      }
                    }.withRemoveSound(),
                  ),
                  const SizedBox(width: 4),
                  _buildCompactButton(
                    icon: Icons.calculate,
                    label: "จำนวน",
                    color: _themeSwatch[600]!,
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                                contentPadding: const EdgeInsets.all(10),
                                content: SizedBox(
                                  height: 500,
                                  child: NumberPad(
                                    header: global.language("qty"),
                                    title: Text(
                                      '${global.getNameFromJsonLanguage(detail.item_name, global.userScreenLanguage)} ${global.language('qty')} ${global.moneyFormat.format(detail.qty)} ${global.getNameFromJsonLanguage(detail.unit_name, global.userScreenLanguage)}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    unitName: detail.unit_name,
                                    onChange: numPadChangeQty,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }.withButtonSound(),
                  ),
                  const SizedBox(width: 4),
                  _buildCompactButton(
                    icon: Icons.add,
                    label: "+1",
                    color: Colors.green.shade600,
                    onPressed: () async {
                      await logInsert(commandCode: 2, guid: global.posHoldProcessResult[holdIndex].activeLineGuid, closeExtra: false);
                    }.withAddSound(),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Price and discount controls
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _buildCompactButton(
                    icon: Icons.price_change,
                    label: "ราคา",
                    color: Colors.orange.shade600,
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                                contentPadding: const EdgeInsets.all(10),
                                content: SizedBox(
                                  width: double.infinity,
                                  height: 500,
                                  child: NumberPad(
                                    header: global.language("price"),
                                    title: Text(
                                      '${global.getNameFromJsonLanguage(detail.item_name, global.userScreenLanguage)} ${global.language('price')} ${global.moneyFormat.format(detail.price)} ${global.language('money_symbol')}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    onChange: numPadChangePrice,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }.withButtonSound(),
                  ),
                  const SizedBox(width: 4),
                  _buildCompactButton(
                    icon: Icons.discount,
                    label: "ส่วนลด",
                    color: Colors.purple.shade600,
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                                contentPadding: const EdgeInsets.all(10),
                                content: SizedBox(
                                  height: 500,
                                  child: DiscountPad(
                                    header: global.language("discount"),
                                    title: Text(
                                      '${global.getNameFromJsonLanguage(detail.item_name, global.userScreenLanguage)} ${global.language('qty')} ${global.moneyFormat.format(detail.qty)} ${global.getNameFromJsonLanguage(detail.unit_name, global.userScreenLanguage)} ${global.language('price')} ${global.moneyFormat.format(detail.price)} ${global.language('money_symbol')}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    onChange: discountPadChange,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }.withButtonSound(),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Other actions
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _buildCompactButton(
                    icon: Icons.note_add,
                    label: "หมายเหตุ",
                    color: Colors.teal.shade600,
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: Text(global.language('remark')),
                                content: TextFormField(
                                  controller: textFieldRemarkController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: global.language("remark"),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        textFieldRemarkController.clear();
                                      }.withClearSound(),
                                      icon: Icon(Icons.clear, color: _themeSwatch),
                                    ),
                                  ),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                actions: <Widget>[
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await logInsert(commandCode: 8, guid: global.posHoldProcessResult[holdIndex].activeLineGuid, remark: textFieldRemarkController.text, closeExtra: false);
                                      global.playSound(sound: global.SoundEnum.buttonTing);
                                    }.withConfirmSound(),
                                    child: Text(global.language('save')),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    }.withButtonSound(),
                                    child: Text(global.language('cancel')),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    }.withButtonSound(),
                  ),
                  const SizedBox(width: 4),
                  _buildCompactButton(
                    icon: Icons.delete,
                    label: "ลบ",
                    color: Colors.red.shade600,
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: Text(global.language('delete')),
                                content: Text(
                                  '${global.getNameFromJsonLanguage(detail.item_name, global.userScreenLanguage)} ${global.language('qty')} ${global.moneyFormat.format(detail.qty)} ${global.getNameFromJsonLanguage(detail.unit_name, global.userScreenLanguage)} ${global.language('price')} ${global.moneyFormat.format(detail.price)} ${global.language('money_symbol')} ${global.language('delete_confirm')}',
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                actions: <Widget>[
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await logInsert(commandCode: 9, guid: global.posHoldProcessResult[holdIndex].activeLineGuid);
                                      global.playSound(sound: global.SoundEnum.buttonTing);
                                    }.withRemoveSound(),
                                    child: Text(global.language('delete')),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    }.withButtonSound(),
                                    child: Text(global.language('cancel')),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    }.withRemoveSound(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method สำหรับสร้างปุ่มขนาดเล็ก
  // ✅ ใช้ PosUiHelpers
  Widget _buildCompactButton({required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return PosUiHelpers.buildCompactButton(icon: icon, label: label, color: color, onPressed: onPressed, getDynamicFontSize: _getDynamicFontSize);
  }

  Widget detail(PosProcessDetailModel detail, int index) {
    int activeLineIndex = global.findActiveLineIndex(holdCode: global.posHoldActiveCode);

    bool active = (activeLineIndex == -1) ? false : ((activeLineIndex == index) ? true : false);
    TextStyle textStyle = TextStyle(color: Colors.black87, fontSize: _getDynamicFontSize(13.0), fontWeight: (active) ? FontWeight.w600 : FontWeight.normal);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: (active == false || detail.is_void)
          ? detailData(index: index, detail: detail, active: active, textStyle: textStyle)
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: _themeSwatch.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: Column(
                children: [
                  detailData(index: index, detail: detail, active: active, textStyle: textStyle),
                  detailButton(index: index, detail: detail, active: active, textStyle: textStyle),
                ],
              ),
            ),
    );
  }

  void numericPadTextInputAdd(String word) {
    setState(() {
      // ป้องกันการใส่จุดทศนิยมมากกว่า 1 จุด
      if (word == ".") {
        if (!numericPadTextInput.contains(".")) {
          // ถ้าไม่มีตัวเลขใดๆ ให้เพิ่ม 0 ข้างหน้า
          if (numericPadTextInput.isEmpty || numericPadTextInput == "") {
            numericPadTextInput = "0$word";
          } else {
            numericPadTextInput = numericPadTextInput + word;
          }
        }
        // ถ้ามีจุดแล้ว ไม่ต้องทำอะไร (ไม่เพิ่มจุดใหม่)
      } else if (word == "+") {
        // ป้องกันการใส่เครื่องหมาย + มากกว่า 1 ครั้ง และไม่ให้เริ่มต้นด้วย +
        if (!numericPadTextInput.contains("+") && numericPadTextInput.isNotEmpty) {
          numericPadTextInput = numericPadTextInput + word;
        }
      } else if (word == "%" || word == "D" || word == "P") {
        // ตัวอักษรพิเศษเหล่านี้ไม่ควรซ้ำกัน และต้องมีตัวเลขก่อน
        if (!numericPadTextInput.contains(word) && numericPadTextInput.isNotEmpty) {
          numericPadTextInput = numericPadTextInput + word;
        }
      } else {
        // ตัวเลขปกติ
        numericPadTextInput = numericPadTextInput + word;
      }
    });
  }

  Widget numericPadTextBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.all(5),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          numericPadTextInput,
          style: const TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget numericPadWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          numericPadTextBar(),
          SizedBox(
            height: 240,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: NumPadButton(margin: 2, text: '7', callBack: () => {numericPadTextInputAdd("7")}),
                            ),
                            Expanded(
                              flex: 2,
                              child: NumPadButton(margin: 2, text: '8', callBack: () => {numericPadTextInputAdd("8")}),
                            ),
                            Expanded(
                              flex: 2,
                              child: NumPadButton(margin: 2, text: '9', callBack: () => {numericPadTextInputAdd("9")}),
                            ),
                            Expanded(
                              flex: 2,
                              child: NumPadButton(
                                margin: 2,
                                icon: Icons.backspace,
                                textAndIconColor: Colors.black,
                                callBack: () => {
                                  if (numericPadTextInput.isNotEmpty)
                                    {
                                      setState(() {
                                        numericPadTextInput = numericPadTextInput.substring(0, numericPadTextInput.length - 1);
                                      }),
                                    },
                                },
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
                              flex: 2,
                              child: NumPadButton(margin: 2, text: '4', callBack: () => {numericPadTextInputAdd("4")}),
                            ),
                            Expanded(
                              flex: 2,
                              child: NumPadButton(margin: 2, text: '5', callBack: () => {numericPadTextInputAdd("5")}),
                            ),
                            Expanded(
                              flex: 2,
                              child: NumPadButton(margin: 2, text: '6', callBack: () => {numericPadTextInputAdd("6")}),
                            ),
                            Expanded(
                              flex: 2,
                              child: NumPadButton(margin: 2, icon: Icons.add, textAndIconColor: Colors.black, callBack: () => {numericPadTextInputAdd("+")}),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: NumPadButton(margin: 2, text: '1', callBack: () => {numericPadTextInputAdd("1")}),
                            ),
                            Expanded(
                              flex: 2,
                              child: NumPadButton(margin: 2, text: '2', callBack: () => {numericPadTextInputAdd("2")}),
                            ),
                            Expanded(
                              flex: 2,
                              child: NumPadButton(margin: 2, text: '3', callBack: () => {numericPadTextInputAdd("3")}),
                            ),
                            Expanded(
                              flex: 2,
                              child: NumPadButton(margin: 2, text: '?', callBack: () => {}),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: NumPadButton(margin: 2, text: '.', callBack: () => {numericPadTextInputAdd(".")}),
                            ),
                            Expanded(
                              flex: 2,
                              child: NumPadButton(margin: 2, text: '0', callBack: () => {numericPadTextInputAdd("0")}),
                            ),
                            Expanded(
                              flex: 4,
                              child: NumPadButton(
                                margin: 2,
                                text: 'C',
                                color: Colors.red[100],
                                callBack: () => {
                                  setState(() {
                                    numericPadTextInput = "";
                                  }),
                                },
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
                              flex: 2,
                              child: NumPadButton(text: 'D', margin: 2, color: Colors.cyan[100], callBack: () => {numericPadTextInputAdd("D")}),
                            ),
                            Expanded(
                              flex: 2,
                              child: NumPadButton(margin: 2, text: '%', color: Colors.cyan[100], callBack: () => {numericPadTextInputAdd("%")}),
                            ),
                            Expanded(
                              flex: 2,
                              child: NumPadButton(text: 'P', margin: 2, color: Colors.green[100], callBack: () => {numericPadTextInputAdd("P")}),
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
        ],
      ),
    );
  }

  Future<double> productWeightScreen(String barcode, String imageUrl) async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PosProductWeightScreen(name: "หมู : $barcode", imageUrl: imageUrl),
      ),
    );

    // Request keyboard focus back after weight screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestKeyboardFocus();
    });

    return (result == null) ? 0 : result;
  }

  void payScreen(int tabIndex) async {
    // ปิด QR scanner ก่อนเข้าหน้าจ่ายเงิน
    try {
      if (scanController != null && qrCodeBarcodeScannerStart) {
        await scanController!.pauseCamera();
      }
    } catch (e) {
      AppLogger.error("Error pausing camera before pay screen: $e");
    }

    setState(() {
      qrCodeBarcodeScannerStart = false;
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenActive = 1;
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.coupon = [];
    });
    await posCompileProcess(
      holdCode: global.posHoldActiveCode,
      docMode: global.posScreenToInt(widget.posScreenMode),
      detailDiscountFormula: detailDiscountFormula,
      cashRoundAmount: false,
      discountFoodOnly: global.tempIsRestaurantSystem,
      customermode: global.secondScreenCommandPay,
    );
    // ⚡ Performance: ลบ .then() และ setState() - ไม่จำเป็นต้อง rebuild

    dynamic result = await Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: PayScreenPage(posScreenMode: widget.posScreenMode, docMode: global.posScreenToInt(widget.posScreenMode), defaultTabIndex: tabIndex, posProcess: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)]),
      ),
    );
    if (result != null && result == true) {
      PosLogHelper logHelper = PosLogHelper();
      await logHelper.deleteByHoldCode(holdCode: global.posHoldActiveCode);
      // ปรับโต๊ะร้านอาหารให้เป็น 0
      final boxTable = global.objectBoxStore.box<TableProcessObjectBoxStruct>();
      final resultTable = boxTable.query(TableProcessObjectBoxStruct_.number.equals(global.tableNumberSelected)).build().findFirst();
      if (resultTable != null) {
        resultTable.order_count = 0;
        resultTable.amount = 0;
        boxTable.put(resultTable, mode: PutMode.update);
      }
      restartClearData();
      global.sendProcessToCustomerDisplay(mode: global.secondScreenCommandInformation);
    } else {
      await posCompileProcess(
        holdCode: global.posHoldActiveCode,
        docMode: global.posScreenToInt(widget.posScreenMode),
        detailDiscountFormula: global.discountFormular,
        cashRoundAmount: false,
        discountFoodOnly: global.tempIsRestaurantSystem,
        customermode: global.secondScreenCommandProcessDetail,
      );
      // ⚡ Performance: ลบ .then() และ setState() - ไม่จำเป็นต้อง rebuild
    }
    // ⚡ Performance: ใช้ setState เฉพาะเมื่อเปลี่ยนค่าจริงๆ
    setState(() {
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenActive = 0;
    });

    // Request keyboard focus back after pay screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestKeyboardFocus();
    });
  }

  Widget totalAndPayScreen() {
    // ✅ Safe access to late-initialized variable
    dynamic tableProcess;
    try {
      tableProcess = global.tableProcessSelected;
    } catch (e) {
      tableProcess = null; // ยังไม่ได้ initialize
    }

    return PosTotalPayPanel(
      posScreenMode: widget.posScreenMode,
      posHoldActiveCode: global.posHoldActiveCode,
      tableSelected: global.tableSelected,
      tableNumberSelected: global.tableNumberSelected,
      tableProcessSelected: tableProcess,
      onPayScreenCash: () => payScreen(0),
      onPayScreenQR: () => payScreen(2),
      onPayScreenCredit: () => payScreen(3),
      onHoldBillTable: () async => await holdBill(holdType: 2),
      onBillDiscountChange: billDiscountPadChange,
    );
  }

  void restartClearData() {
    int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
    global.discountFormular = "";
    global.posHoldProcessResult[holdIndex].payScreenActive = 0;
    global.posHoldProcessResult[holdIndex].posProcess = PosProcessModel();
    widgetMessageImageUrl = "";
    widgetMessage = [];
    detailDiscountFormula = "";
    global.posSaleChannelCode = "XXX";
    numericPadTextInput = "";
    global.posHoldProcessResult[holdIndex].payScreenData = PosPayModel();
    global.posHoldProcessResult[holdIndex].ismember = false;
    global.posHoldProcessResult[holdIndex].priceLevel = "";
    global.posHoldProcessResult[holdIndex].customerCode = "";
    global.posHoldProcessResult[holdIndex].customerPointsCode = "";
    global.posHoldProcessResult[holdIndex].customerName = "";
    global.posHoldProcessResult[holdIndex].customerPhone = "";
    global.posHoldProcessResult[holdIndex].customerGuid = "";
    findMemberByNameTelephoneLastResult.clear();
    textFindByTextController.text = ""; // เคลียร์คูปองและยกเลิกการจองทั้งหมดเฉพาะเมื่อต้องการรีสตาร์ทจริงๆ

    global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData = PosPayModel();
    processEvent(barcode: "", holdCode: global.posHoldActiveCode);
    // ตรวจสอบมีโต๊ะหรือไม่
    qrCodeBarcodeScannerQtyResult = 1;
    productOptions.clear();
    global.tableSelected = false;
    global.tableNumberSelected = "";

    global.posLogHelper.holdCount(global.posHoldProcessResult[holdIndex].code).then((value) {
      global.posHoldProcessResult[holdIndex].logCount = value;
    });

    if (global.posHoldActiveCode.contains("T-")) {
      global.posHoldActiveCode = "0";
    }
    // ⚡ Performance: setState เฉพาะเมื่อเปลี่ยนค่า - แต่ที่นี่จำเป็นต้อง rebuild
    setState(() {});
  }

  void restart() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.refresh, color: Colors.orange.shade700, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text("${global.language("restart")} ${(global.tableSelected) ? global.language("pos_hold_table") + global.tableNumberSelected : ''}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              content: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text((global.tableSelected) ? global.language("teble_is_selected") : global.language("clear_bill"), style: TextStyle(fontSize: 14, color: Colors.orange.shade800)),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    global.language('cancel'),
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await logInsert(guid: "", commandCode: 99);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                    restartClearData();
                    CouponManager().clearAllCoupons(afterSale: false);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh, size: 18),
                      const SizedBox(width: 8),
                      Text(global.language('restart'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  CapabilityProfile? _cachedProfile;
  Future<void> openCashDrawer() async {
    //   await logInsert(guid: "", commandCode: 98);

    // ✅ Performance monitoring (Debug mode only)
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
    }

    // ส่งคำสั่งเปิด cash drawer ผ่านเครื่องพิมพ์
    try {
      // ตรวจสอบว่ามีเครื่องพิมพ์ที่พร้อมใช้งานหรือไม่
      if (cashierPrinterIndex != -1) {
        switch (global.printerLocalStrongData[cashierPrinterIndex].printerConnectType) {
          case global.PrinterConnectEnum.ip:
            AppLogger.debug("xxx start openDrawer");

            PaperSize paper = (global.printerLocalStrongData[cashierPrinterIndex].paperType == 1) ? PaperSize.mm58 : PaperSize.mm80;
            CapabilityProfile profile = await CapabilityProfile.load();

            try {
              List<int> bytes = [];

              Socket socket = await Socket.connect(global.printerLocalStrongData[cashierPrinterIndex].ipAddress, global.printerLocalStrongData[cashierPrinterIndex].ipPort);
              final generator = Generator(paper, profile);
              // ✅ ลด delay เพื่อความเร็ว
              await Future.delayed(const Duration(milliseconds: 50));
              bytes += generator.reset();
              bytes += generator.drawer();
              socket.add(bytes);
              // ✅ ให้เวลา printer ประมวลผล แต่ลดจาก 1 วินาที
              await Future.delayed(const Duration(milliseconds: 300));
              await socket.close();
              // ✅ ไม่ต้อง delay หลัง close
            } catch (e) {
              AppLogger.error("openCashDrawer$e");
              // global.sendErrorToDevTeam("openCashDrawer", "${global.printerLocalStrongData[cashierPrinterIndex].deviceName} : $e : $s");
            }

            break;
          case global.PrinterConnectEnum.bluetooth:
            try {
              FlutterThermalPrinter flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
              _cachedProfile ??= await CapabilityProfile.load();

              final generator = Generator(PaperSize.mm80, _cachedProfile!);

              // Add printer commands
              final List<int> bytesUsb = [];
              bytesUsb.addAll(generator.reset());
              bytesUsb.addAll(generator.drawer());

              // Create printer object
              Printer printer = Printer(
                address: global.printerLocalStrongData[cashierPrinterIndex].ipAddress,
                name: global.printerLocalStrongData[cashierPrinterIndex].deviceName,
                vendorId: global.printerLocalStrongData[cashierPrinterIndex].vendorId,
                productId: global.printerLocalStrongData[cashierPrinterIndex].productId,
                connectionType: ConnectionType.BLE,
                isConnected: false,
              );

              try {
                // First try to disconnect to ensure clean state
                await flutterThermalPrinterPlugin.disconnect(printer);
                // ✅ ลด delay เพื่อความเร็ว
                await Future.delayed(const Duration(milliseconds: 100));
              } catch (e) {
                // Ignore disconnect errors - it might not be connected
                AppLogger.debug("Disconnect error (ignorable): $e");
              }

              // Now connect fresh
              await flutterThermalPrinterPlugin.connect(printer);
              // ✅ ลด delay เพื่อความเร็ว
              await Future.delayed(const Duration(milliseconds: 200));

              // Print data - ✅ iOS BLE fix: use longData and appropriate chunkSize
              final int iosChunkSize = Platform.isIOS ? 100 : 500;
              await flutterThermalPrinterPlugin.printData(printer, bytesUsb, longData: true, chunkSize: iosChunkSize);
              // ✅ เพิ่ม delay สำหรับ iOS เนื่องจากส่งข้อมูลเป็น chunks
              await Future.delayed(Duration(milliseconds: Platform.isIOS ? 800 : 400));

              // Always disconnect after printing
              await flutterThermalPrinterPlugin.disconnect(printer);
              // ✅ ลด delay
              await Future.delayed(const Duration(milliseconds: 100));
            } catch (e, s) {
              if (kDebugMode) {
                AppLogger.error('Printer error: $e');
                AppLogger.debug(s);
              }

              // Try to safely disconnect if an error occurred
              try {
                // Create printer object
                Printer printer = Printer(
                  address: global.printerLocalStrongData[cashierPrinterIndex].ipAddress,
                  name: global.printerLocalStrongData[cashierPrinterIndex].deviceName,
                  vendorId: global.printerLocalStrongData[cashierPrinterIndex].vendorId,
                  productId: global.printerLocalStrongData[cashierPrinterIndex].productId,
                  connectionType: ConnectionType.BLE,
                  isConnected: false,
                );

                await FlutterThermalPrinter.instance.disconnect(printer);
              } catch (e) {
                AppLogger.debug("Intentionally ignored: `$e");
                // errors during cleanup
              }
              // global.sendErrorToDevTeam("print.dart->printFromFile", "${printerData.deviceName} : $e : $s");
            }
            break;
          case global.PrinterConnectEnum.usb:
            try {
              FlutterThermalPrinter flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
              _cachedProfile ??= await CapabilityProfile.load();

              final generator = Generator(PaperSize.mm80, _cachedProfile!);

              // Add printer commands
              final List<int> bytesUsb = [];
              bytesUsb.addAll(generator.reset());
              bytesUsb.addAll(generator.drawer());

              // Create printer object
              Printer printer = Printer(
                address: global.printerLocalStrongData[cashierPrinterIndex].ipAddress,
                name: global.printerLocalStrongData[cashierPrinterIndex].deviceName,
                vendorId: global.printerLocalStrongData[cashierPrinterIndex].vendorId,
                productId: global.printerLocalStrongData[cashierPrinterIndex].productId,
                connectionType: ConnectionType.USB,
                isConnected: false,
              );

              try {
                // First try to disconnect to ensure clean state
                await flutterThermalPrinterPlugin.disconnect(printer);
                // ✅ ลด delay เพื่อความเร็ว (USB case)
                await Future.delayed(const Duration(milliseconds: 100));
              } catch (e) {
                // Ignore disconnect errors - it might not be connected
                AppLogger.debug("Disconnect error (ignorable): $e");
              }

              // Now connect fresh
              await flutterThermalPrinterPlugin.connect(printer);
              // ✅ ลด delay เพื่อความเร็ว (USB case)
              await Future.delayed(const Duration(milliseconds: 200));

              // Print data
              await flutterThermalPrinterPlugin.printData(printer, bytesUsb);
              // ✅ ลด delay แต่ให้เวลา printer พอสมควร (USB case)
              await Future.delayed(const Duration(milliseconds: 400));

              // Always disconnect after printing
              await flutterThermalPrinterPlugin.disconnect(printer);
              // ✅ ลด delay (USB case)
              await Future.delayed(const Duration(milliseconds: 100));
            } catch (e, s) {
              if (kDebugMode) {
                AppLogger.error('Printer error: $e');
                AppLogger.debug(s);
              }

              // Try to safely disconnect if an error occurred
              try {
                // Create printer object
                Printer printer = Printer(
                  address: global.printerLocalStrongData[cashierPrinterIndex].ipAddress,
                  name: global.printerLocalStrongData[cashierPrinterIndex].deviceName,
                  vendorId: global.printerLocalStrongData[cashierPrinterIndex].vendorId,
                  productId: global.printerLocalStrongData[cashierPrinterIndex].productId,
                  connectionType: ConnectionType.USB,
                  isConnected: false,
                );

                await FlutterThermalPrinter.instance.disconnect(printer);
              } catch (e) {
                AppLogger.debug("Intentionally ignored: `$e");
                // errors during cleanup
              }
              // global.sendErrorToDevTeam("print.dart->printFromFile", "${printerData.deviceName} : $e : $s");
            }
            break;
          case global.PrinterConnectEnum.windows:
            AppLogger.debug("xxx start openCashDrawer windows");
            await global.openCashDrawerWindows(global.printerLocalStrongData[cashierPrinterIndex].deviceName);

            break;
          case global.PrinterConnectEnum.sunmi1:
            break;
        }

        global.playSound(sound: global.SoundEnum.beep, word: global.language("open_cash_drawer"));
      } else {
        global.playSound(sound: global.SoundEnum.fail, word: global.language("printer_not_ready"));
      }
    } catch (e) {
      AppLogger.error("Error opening cash drawer: $e");
      global.playSound(sound: global.SoundEnum.fail, word: global.language("open_cash_drawer_failed"));
    }

    // ✅ Log performance (Debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.success('[PosScreen] 💰 openCashDrawer took ${stopwatch.elapsedMilliseconds}ms');
      if (stopwatch.elapsedMilliseconds > 500) {
        AppLogger.warning('⚠️ Slow cash drawer operation!');
      }
    }
  }

  Widget commandButton({required Function onPressed, String label = "", IconData? icon}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              onPressed();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _themeSwatch[50]!, width: 1),
                gradient: LinearGradient(colors: [_themeSwatch[50]!, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              child: (icon != null)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 15, color: _themeSwatch[700]!),
                        const SizedBox(height: 1),
                        Flexible(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: _getCommandButtonFontSize(), fontWeight: FontWeight.w600, color: _themeSwatch[800]!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _themeSwatch[800]!),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget commandWidget() {
    List<Widget> commands = [
      if (!global.posHoldActiveCode.contains("T-"))
        commandButton(
          icon: Icons.refresh,
          label: global.language('restart'),
          onPressed: () {
            restart();
          },
        ),
      if (global.posUseSaleType)
        if (global.posSaleChannelList.isNotEmpty)
          commandButton(
            icon: Icons.store,
            label: global.language("sale_channel"),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PosSaleChannelScreen())).then((value) => setState(() {}));
            },
          ),
      commandButton(
        icon: FontAwesomeIcons.pause,
        label: global.language("hold_bill"),
        onPressed: () async {
          await holdBill(holdType: 1);
        },
      ),
      commandButton(
        icon: FontAwesomeIcons.user,
        label: global.language('select_employee'),
        onPressed: () {
          findEmployee();
        },
      ),
      commandButton(
        icon: FontAwesomeIcons.cashRegister,
        label: global.language('open_cash_drawer'),
        onPressed: () {
          openCashDrawer();
        },
      ),
      commandButton(
        icon: Icons.print,
        label: global.language('reprint_bill'),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PosReprintBillScreen(posScreenMode: widget.posScreenMode)));
        },
      ),
      commandButton(
        icon: Icons.receipt_long,
        label: global.language('full_bill_vat'),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PosBillVatScreen(posScreenMode: widget.posScreenMode)));
        },
      ),
      commandButton(
        icon: Icons.cancel,
        label: global.language('cancel_bill'),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PosCancelBillScreen(posScreenMode: widget.posScreenMode)));
        },
      ),
      commandButton(
        icon: Icons.home,
        label: global.language('main_screen'),
        onPressed: () {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => const MenuScreen()), (route) => false);
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int rowNumber = 1;
        if (buttonSizeLevel == 1) {
          rowNumber = 2;
        } else if (buttonSizeLevel == 2) {
          rowNumber = 3;
        } else if (buttonSizeLevel == 3) {
          rowNumber = 3;
        } else {
          rowNumber = 1;
        }
        if (constraints.maxWidth < 1200) rowNumber = 2;
        if (constraints.maxWidth < 500) rowNumber = 2;
        if (constraints.maxWidth < 200) rowNumber = 3;

        List<Widget> columns = [];
        int itemCount = 0;
        int itemPerRow = (commands.length / rowNumber).ceil();

        for (int rowIndex = 0; rowIndex < rowNumber; rowIndex++) {
          List<Widget> rows = [];
          for (int columnIndex = 0; columnIndex < itemPerRow; columnIndex++) {
            if (itemCount < commands.length) {
              if (columnIndex != 0) {
                rows.add(const SizedBox(width: 3));
              }
              rows.add(commands[itemCount]);
              itemCount++;
            }
          }
          if (rowIndex != 0) {
            columns.add(const SizedBox(height: 3));
          }
          columns.add(
            SizedBox(
              height: _getButtonHeight() + 10, // เพิ่มความสูงเพื่อรองรับ icon และ text
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 3),
          child: Column(children: columns),
        );
      },
    );
  }

  Widget transScreen({required int mode, String barcode = ""}) {
    late Widget logo;
    var file = File(global.getShopLogoPathName());
    if (file.existsSync()) {
      logo = Image.file(file);
    } else {
      logo = const Icon(Icons.barcode_reader, color: Colors.grey, size: 200);
    }
    int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);

    return (global.posHoldProcessResult[holdIndex].posProcess.details.isEmpty)
        ? Center(child: logo)
        : MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(width: 1, color: Colors.grey),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.5),
                    spreadRadius: 2,
                    blurRadius: 2,
                    offset: const Offset(0, 1), // changes position of shadow
                  ),
                ],
              ),
              child: Column(
                children: [
                  detailHeaderWidget(),
                  Expanded(
                    child: (mode == 0)
                        ? ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                            child: ListView(
                              scrollDirection: Axis.vertical,
                              controller: autoScrollController,
                              children: <Widget>[
                                for (int index = 0; index < global.posHoldProcessResult[holdIndex].posProcess.details.length; index++)
                                  AutoScrollTag(
                                    key: ValueKey(index),
                                    controller: autoScrollController,
                                    index: index,
                                    child: Container(child: detail(global.posHoldProcessResult[holdIndex].posProcess.details[index], index)),
                                  ),
                              ],
                            ),
                          )
                        : ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                            child: ListView(
                              scrollDirection: Axis.vertical,
                              children: <Widget>[
                                for (int index = 0; index < global.posHoldProcessResult[holdIndex].posProcess.details.length; index++)
                                  Container(child: (barcode != global.posHoldProcessResult[holdIndex].posProcess.details[index].barcode) ? Container() : detail(global.posHoldProcessResult[holdIndex].posProcess.details[index], index)),
                              ],
                            ),
                          ),
                  ),
                  promotionWidget(),
                  detailFooterWidget(),
                ],
              ),
            ),
          );
  }

  void showMessageDialog({required String header, required String msg, required String type}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(header),
          content: SingleChildScrollView(child: ListBody(children: <Widget>[Text(msg)])),
          actions: <Widget>[
            TextButton(
              child: Text(global.language('ok')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void findItemByCodeNameBarcode() async {
    barcodeScanActive = false;
    await Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft, child: findItemScreen)).then((value) async {
      if (value != null) {
        await logInsert(guid: "", commandCode: value.command, barcode: value.data.barcode, qty: value.qty.toString(), price: value.priceOrPercent);
      }

      // Request keyboard focus back after item selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestKeyboardFocus();
      });
    });
    barcodeScanActive = true;
  }

  void findEmployee() async {
    await Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft, child: const FindEmployee()))
        .then((value) {
          setState(() {
            int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
            global.posHoldProcessResult[holdIndex].saleCode = value[0];
            global.posHoldProcessResult[holdIndex].saleName = value[1];
          });

          // Request keyboard focus back after employee selection
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _requestKeyboardFocus();
          });
        })
        .onError((error, stackTrace) => null);
  }

  Future<void> holdBill({required int holdType}) async {
    // ✅ Performance monitoring (Debug mode only)
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
    }

    // พักบิล
    if (holdType == 2) {
      var table = global.objectBoxStore.box<TableProcessObjectBoxStruct>().getAll();
      if (table.isEmpty) {
        showMessageDialog(header: "ไม่พบโต๊ะ", msg: "กรุณาเพิ่มโต๊ะก่อน", type: "error");
        return;
      }
    }

    PosHoldProcessModel? result = await Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: PosHoldBill(holdType: holdType),
      ),
    );

    if (result != null) {
      // Handle the result as needed
      // For example:
      AppLogger.debug('Received result: $result');

      if (holdType == 2) {
        // เลือกโต๊ะ (โปรแกรมร้านอาหาร)
        global.tableSelected = true;
        global.tableNumberSelected = result.code.replaceAll("T-", "");
        global.posHoldActiveCode = result.code;
        global.tableProcessSelected = result;
        detailDiscountFormula = result.detailDiscountFormula;
      } else {
        global.tableSelected = false;
        global.posHoldActiveCode = result.code;
      }
      CouponManager().clearAllCoupons(afterSale: false);
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.coupon = [];

      processEvent(barcode: "", holdCode: global.posHoldActiveCode);
      global.playSound(sound: global.SoundEnum.beep);
      int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
      if (global.appMode == global.AppModeEnum.posTerminal) {
        if (holdIndex != -1) {
          await posCompileProcess(
            holdCode: global.posHoldActiveCode,
            docMode: global.posScreenToInt(widget.posScreenMode),
            detailDiscountFormula: detailDiscountFormula,
            cashRoundAmount: false,
            discountFoodOnly: global.tempIsRestaurantSystem,
            customermode: global.secondScreenCommandProcessDetail,
          ).then((_) {
            PosProcess().sumCategoryCount(value: global.posHoldProcessResult[holdIndex].posProcess);
          });
        }
      } else {
        await getProcessFromTerminal();
      }
      if (holdType != 2) {
        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData = global.posHoldProcessResult[holdIndex].payScreenData;
      } else {
        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData = PosPayModel();
      }

      // ⚡ Performance: setState เฉพาะเมื่อเปลี่ยนค่า - ที่นี่จำเป็นเพื่อ update UI
      setState(() {});

      // Request keyboard focus back after hold bill action
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestKeyboardFocus();
      });
    } else {
      // Handle the case when the result is null
      AppLogger.debug('No result received or user cancelled');

      // Request keyboard focus back even when cancelled
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestKeyboardFocus();
      });
    }

    // ✅ Log performance (Debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.success('[PosScreen] 📋 holdBill took ${stopwatch.elapsedMilliseconds}ms (type: $holdType)');
      if (stopwatch.elapsedMilliseconds > 300) {
        AppLogger.warning('⚠️ Slow hold bill operation!');
      }
    }
  }

  // 🎭 Helper widget สำหรับ animated emoji (แบบง่าย ใช้ได้แน่นอน)
  // ✅ ใช้ PosUiHelpers
  Widget _buildAnimatedEmoji(String emoji, {double size = 18}) {
    return PosUiHelpers.buildAnimatedEmoji(emoji: emoji, scaleAnimation: _emojiScaleAnimation, scaleController: _emojiScaleController, size: size);
  }

  // ✅ ใช้ PosUiHelpers
  Widget _buildPulsingEmoji(String emoji, {double size = 18}) {
    return PosUiHelpers.buildPulsingEmoji(emoji: emoji, pulseAnimation: _emojiPulseAnimation, size: size);
  }

  // 📅 Helper: ตรวจสอบว่าโปรโมชั่นยังใช้งานได้หรือไม่ (ตามวันที่)
  bool _isPromotionActive(String promotionCode) {
    try {
      // ค้นหาโปรโมชั่นจาก ObjectBox
      final box = global.objectBoxStore.box<PromotionObjectBoxStruct>();
      final promotion = box.query(PromotionObjectBoxStruct_.promotion_code.equals(promotionCode)).build().findFirst();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (promotion == null) {
        // ไม่เจอใน ObjectBox → หาจาก global.promotionMain (เช่น mock promotions)
        for (var pm in global.promotionMain) {
          for (var p in pm.promotion_list) {
            if (p.promotion_code == promotionCode) {
              final beginDate = DateTime(p.date_begin.year, p.date_begin.month, p.date_begin.day);
              final endDate = DateTime(p.date_end.year, p.date_end.month, p.date_end.day);
              return !today.isBefore(beginDate) && !today.isAfter(endDate);
            }
          }
        }
        return false; // ไม่เจอที่ไหนเลย ถือว่าหมดอายุ
      }

      // ✅ เอาเฉพาะวันที่ (ไม่เอาเวลา) เพื่อเช็คช่วงวันที่
      final beginDate = DateTime(promotion.date_begin.year, promotion.date_begin.month, promotion.date_begin.day);
      final endDate = DateTime(promotion.date_end.year, promotion.date_end.month, promotion.date_end.day);

      // ✅ ใช้ <= และ >= เพื่อรองรับวันเดียวกัน (date_begin = date_end)
      // beginDate <= today <= endDate
      return !today.isBefore(beginDate) && !today.isAfter(endDate);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('[Promotion] Error checking date: $e');
      }
      return true; // กรณี error ให้แสดงไปก่อน
    }
  }

  // ⏰ Helper: คำนวณเวลาที่เหลือของโปรโมชั่น
  String _getPromotionTimeRemaining(String promotionCode) {
    try {
      final box = global.objectBoxStore.box<PromotionObjectBoxStruct>();
      final promotion = box.query(PromotionObjectBoxStruct_.promotion_code.equals(promotionCode)).build().findFirst();

      if (promotion == null) return '';

      final now = DateTime.now();

      // ตรวจสอบว่าหมดอายุแล้วหรือยัง
      if (now.isAfter(promotion.date_end)) {
        return '❌ หมดอายุแล้ว';
      }

      // ตรวจสอบว่ายังไม่ถึงเวลาหรือยัง
      if (now.isBefore(promotion.date_begin)) {
        final daysUntilStart = promotion.date_begin.difference(now).inDays;
        return '🕐 เริ่ม ${daysUntilStart + 1} วัน';
      }

      // คำนวณเวลาที่เหลือ
      final remaining = promotion.date_end.difference(now);

      if (remaining.inDays > 7) {
        return '📅 ${promotion.date_end.day}/${promotion.date_end.month}/${promotion.date_end.year + 543}';
      } else if (remaining.inDays > 0) {
        return '⏳ เหลือ ${remaining.inDays} วัน';
      } else if (remaining.inHours > 0) {
        return '⏰ เหลือ ${remaining.inHours} ชม.';
      } else if (remaining.inMinutes > 0) {
        return '⏱️ เหลือ ${remaining.inMinutes} นาที';
      } else {
        return '⚠️ ใกล้หมดอายุ';
      }
    } catch (e) {
      return '';
    }
  }

  // 📏 Helper: คำนวณจำนวนสินค้าตามหน่วยนับฐาน (ใช้อัตราส่วน)
  Widget promotionWidget() {
    List<Widget> promotionListWidget = [];

    // แยก warning เป็น 2 กลุ่ม
    final warningList = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess.promotion_warning_list;

    final pendingWarnings = warningList.where((w) => !w.isAchieved).toList();
    final achievedWarnings = warningList.where((w) => w.isAchieved).toList();

    // ⏳ กำลังจะได้
    if (pendingWarnings.isNotEmpty) {
      // promotionListWidget.add(
      //   Container(
      //     width: double.infinity,
      //     margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      //     padding: const EdgeInsets.all(1),
      //     decoration: BoxDecoration(
      //       gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF00BCD4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      //       borderRadius: BorderRadius.circular(10),
      //       boxShadow: [BoxShadow(color: const Color(0xFF2196F3).withOpacity(0.4), blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 3))],
      //     ),
      //     child: Container(
      //       padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      //       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      //       child: Row(
      //         children: [
      //           Container(
      //             padding: const EdgeInsets.all(6),
      //             decoration: BoxDecoration(
      //               gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF00BCD4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      //               borderRadius: BorderRadius.circular(8),
      //               boxShadow: [BoxShadow(color: _themeSwatch.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
      //             ),
      //             child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 18),
      //           ),
      //           const SizedBox(width: 10),
      //           const Expanded(
      //             child: Text(
      //               'กำลังจะได้โปรโมชั่น',
      //               style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1976D2), letterSpacing: 0.3),
      //             ),
      //           ),
      //           _buildAnimatedEmoji('⏳', size: 18),
      //         ],
      //       ),
      //     ),
      //   ),
      // );

      for (var promotionWarningDetail in pendingWarnings) {
        // ✅ กรองโปรโมชั่นหมดอายุ
        if (!_isPromotionActive(promotionWarningDetail.promotion_code)) {
          continue;
        }

        // ✅ ดึงข้อมูลเวลาที่เหลือ
        final timeRemaining = _getPromotionTimeRemaining(promotionWarningDetail.promotion_code);

        promotionListWidget.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF2196F3).withOpacity(0.12), const Color(0xFF00BCD4).withOpacity(0.12)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2196F3), width: 2),
              boxShadow: [BoxShadow(color: const Color(0xFF2196F3).withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2196F3), width: 2),
                      boxShadow: [BoxShadow(color: _themeSwatch.withOpacity(0.3), blurRadius: 3, offset: const Offset(0, 1))],
                    ),
                    child: Center(child: _buildAnimatedEmoji('🎯', size: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promotionWarningDetail.description,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: global.hexToColor(promotionWarningDetail.colorHex), height: 1.3),
                        ),
                        // ✅ แสดงเวลาที่เหลือใต้ description
                        if (timeRemaining.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            timeRemaining,
                            style: TextStyle(
                              fontSize: 11,
                              color: timeRemaining.contains('❌')
                                  ? Colors.red
                                  : timeRemaining.contains('⏳') || timeRemaining.contains('⏰')
                                  ? Colors.orange
                                  : timeRemaining.contains('🕐')
                                  ? _themeSwatch[700]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ✅ แสดงเวลาที่เหลือมุมขวาบน
                  if (timeRemaining.isNotEmpty && (timeRemaining.contains('⏳') || timeRemaining.contains('⏰') || timeRemaining.contains('🕐')))
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange.withOpacity(0.15) : _themeSwatch.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange : _themeSwatch, width: 1),
                      ),
                      child: Text(
                        timeRemaining.split(' ')[1], // แสดงแค่ "X วัน" หรือ "X ชม."
                        style: TextStyle(fontSize: 10, color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange[800] : _themeSwatch[800], fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // ⚠️ ได้แล้ว (ต้องแถม)
    if (achievedWarnings.isNotEmpty) {
      promotionListWidget.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF5722), Color(0xFFFF9800)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFFFF5722).withOpacity(0.4), blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 3))],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF5722), Color(0xFFFF9800)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ต้องแถมสินค้า!',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFE64A19), letterSpacing: 0.3),
                  ),
                ),
                _buildPulsingEmoji('⚠️', size: 18),
              ],
            ),
          ),
        ),
      );

      for (var promotionWarningDetail in achievedWarnings) {
        // ✅ กรองโปรโมชั่นหมดอายุ
        if (!_isPromotionActive(promotionWarningDetail.promotion_code)) {
          continue;
        }

        // ✅ ดึงข้อมูลเวลาที่เหลือ
        final timeRemaining = _getPromotionTimeRemaining(promotionWarningDetail.promotion_code);

        promotionListWidget.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFFFF5722).withOpacity(0.12), const Color(0xFFFF9800).withOpacity(0.12)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF5722), width: 2),
              boxShadow: [BoxShadow(color: const Color(0xFFFF5722).withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFF5722), width: 2),
                      boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.3), blurRadius: 3, offset: const Offset(0, 1))],
                    ),
                    child: Center(child: _buildPulsingEmoji('⚠️', size: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promotionWarningDetail.description,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: global.hexToColor(promotionWarningDetail.colorHex), height: 1.3),
                        ),
                        // ✅ แสดงเวลาที่เหลือใต้ description
                        if (timeRemaining.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            timeRemaining,
                            style: TextStyle(
                              fontSize: 11,
                              color: timeRemaining.contains('❌')
                                  ? Colors.red
                                  : timeRemaining.contains('⏳') || timeRemaining.contains('⏰')
                                  ? Colors.orange
                                  : timeRemaining.contains('🕐')
                                  ? _themeSwatch[700]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ✅ แสดงเวลาที่เหลือมุมขวาบน
                  if (timeRemaining.isNotEmpty && (timeRemaining.contains('⏳') || timeRemaining.contains('⏰') || timeRemaining.contains('🕐')))
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange.withOpacity(0.15) : _themeSwatch.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange : _themeSwatch, width: 1),
                      ),
                      child: Text(
                        timeRemaining.split(' ')[1], // แสดงแค่ "X วัน" หรือ "X ชม."
                        style: TextStyle(fontSize: 10, color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange[800] : _themeSwatch[800], fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // 🎯 ส่วนลดในรายการ
    final productPromotions = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess.promotion_product_list;

    if (productPromotions.isNotEmpty) {
      promotionListWidget.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.4), blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 3))],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ส่วนลดในรายการ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF388E3C), letterSpacing: 0.3),
                  ),
                ),
                // ✅ ปุ่มย่อ/ขยาย
                InkWell(
                  onTap: () {
                    setState(() {
                      _isPromotionProductExpanded = !_isPromotionProductExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Icon(_isPromotionProductExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: const Color(0xFF388E3C), size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                _buildAnimatedEmoji('🎯', size: 18),
              ],
            ),
          ),
        ),
      );

      // 🎯 Group promotions by promotion_name เพื่อประหยัด space
      final groupedPromotions = <String, List<PosProcessPromotionModel>>{};
      for (var promo in productPromotions) {
        // กรองโปรโมชั่นหมดอายุ
        if (!_isPromotionActive(promo.promotion_code)) {
          continue;
        }

        final promoName = global.getNameFromJsonLanguage(promo.promotion_name, global.userScreenLanguage);

        if (!groupedPromotions.containsKey(promoName)) {
          groupedPromotions[promoName] = [];
        }
        groupedPromotions[promoName]!.add(promo);
      }

      // ✅ แสดงเนื้อหาเมื่อขยาย + เลื่อนได้
      if (_isPromotionProductExpanded) {
        promotionListWidget.add(
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  children: [
                    // แสดงแต่ละ group
                    ...groupedPromotions.entries.map((entry) {
                      final promoName = entry.key;
                      final promoList = entry.value;

                      // รวม count ทั้งหมด
                      final totalCount = promoList.fold<int>(0, (sum, p) => sum + p.count);

                      // เก็บ descriptions แยกเป็นรายการ (ไม่ซ้ำ)
                      final descriptionList = promoList.where((p) => p.description.isNotEmpty).map((p) => p.description).toSet().toList();

                      // ดึงเวลาที่เหลือจาก promotion แรก
                      final timeRemaining = _getPromotionTimeRemaining(promoList.first.promotion_code);

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [const Color(0xFF4CAF50).withOpacity(0.12), const Color(0xFF8BC34A).withOpacity(0.12)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                          boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 3, offset: const Offset(0, 1))],
                                ),
                                child: Center(child: _buildAnimatedEmoji('💰', size: 18)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      promoName + (totalCount == 1 ? "" : " x $totalCount ครั้ง"),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF388E3C), height: 1.3),
                                    ),
                                    // ✅ แสดงรายละเอียดโปรโมชั่น (แต่ละบรรทัด)
                                    if (descriptionList.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      ...descriptionList.map(
                                        (desc) => Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Text(
                                            '• $desc',
                                            style: TextStyle(fontSize: 11, color: Colors.green[800], fontWeight: FontWeight.w500, height: 1.2),
                                          ),
                                        ),
                                      ),
                                    ],
                                    // ✅ แสดงข้อความประหยัด (สีเขียว)
                                    Builder(
                                      builder: (context) {
                                        // คำนวณยอดประหยัดรวม
                                        final totalDiscount = promoList.fold<double>(0, (sum, p) => sum + p.discount_amount);

                                        if (totalDiscount > 0) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 3),
                                            child: Text(
                                              'ประหยัด ${global.moneyFormat.format(totalDiscount)} บาท',
                                              style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.w600, height: 1.2),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                    // ✅ แสดงเวลาที่เหลือใต้ชื่อโปรโมชั่น
                                    if (timeRemaining.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        timeRemaining,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: timeRemaining.contains('❌')
                                              ? Colors.red
                                              : timeRemaining.contains('⏳') || timeRemaining.contains('⏰')
                                              ? Colors.orange
                                              : timeRemaining.contains('🕐')
                                              ? _themeSwatch[700]
                                              : Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // ✅ แสดงจำนวนเงินส่วนลด (รวมทั้งหมดในกลุ่ม)
                                  Builder(
                                    builder: (context) {
                                      final totalDiscount = promoList.fold<double>(0, (sum, p) => sum + p.discount_amount);
                                      if (totalDiscount != 0) {
                                        return Text(
                                          "-${global.moneyFormat.format(totalDiscount)}",
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                  // ✅ แสดงเวลาที่เหลือมุมขวาบน
                                  if (timeRemaining.isNotEmpty && (timeRemaining.contains('⏳') || timeRemaining.contains('⏰') || timeRemaining.contains('🕐'))) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange.withOpacity(0.15) : _themeSwatch.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange : _themeSwatch, width: 1),
                                      ),
                                      child: Text(
                                        timeRemaining.split(' ')[1],
                                        style: TextStyle(fontSize: 9, color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange[800] : _themeSwatch[800], fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    // 💰 ส่วนลดท้ายบิล
    final bottomPromotions = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess.promotion_bottom_list;

    if (bottomPromotions.isNotEmpty) {
      promotionListWidget.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFE91E63)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFF9C27B0).withOpacity(0.4), blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 3))],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFE91E63)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ส่วนลดท้ายบิล',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF7B1FA2), letterSpacing: 0.3),
                  ),
                ),
                _buildAnimatedEmoji('💸', size: 18),
              ],
            ),
          ),
        ),
      );

      // 💰 Group promotions by promotion_name เพื่อประหยัด space
      final groupedBottomPromotions = <String, List<PosProcessPromotionModel>>{};
      for (var promo in bottomPromotions) {
        // กรองโปรโมชั่นหมดอายุ
        if (!_isPromotionActive(promo.promotion_code)) {
          continue;
        }

        final promoName = global.getNameFromJsonLanguage(promo.promotion_name, global.userScreenLanguage);

        if (!groupedBottomPromotions.containsKey(promoName)) {
          groupedBottomPromotions[promoName] = [];
        }
        groupedBottomPromotions[promoName]!.add(promo);
      }

      // แสดงแต่ละ group
      for (var entry in groupedBottomPromotions.entries) {
        final promoName = entry.key;
        final promoList = entry.value;

        // รวม count ทั้งหมด
        final totalCount = promoList.fold<int>(0, (sum, p) => sum + p.count);

        // รวม discount_amount ทั้งหมด
        final totalDiscount = promoList.fold<double>(0, (sum, p) => sum + p.discount_amount);

        // ดึงเวลาที่เหลือจาก promotion แรก
        final timeRemaining = _getPromotionTimeRemaining(promoList.first.promotion_code);

        promotionListWidget.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF9C27B0).withOpacity(0.12), const Color(0xFFE91E63).withOpacity(0.12)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF9C27B0), width: 2),
              boxShadow: [BoxShadow(color: const Color(0xFF9C27B0).withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF9C27B0), width: 2),
                      boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 3, offset: const Offset(0, 1))],
                    ),
                    child: Center(child: _buildAnimatedEmoji('🎊', size: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promoName + (totalCount == 1 ? "" : " x $totalCount ครั้ง"),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7B1FA2), height: 1.3),
                        ),
                        // ✅ แสดงเวลาที่เหลือใต้ชื่อโปรโมชั่น
                        if (timeRemaining.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            timeRemaining,
                            style: TextStyle(
                              fontSize: 11,
                              color: timeRemaining.contains('❌')
                                  ? Colors.red
                                  : timeRemaining.contains('⏳') || timeRemaining.contains('⏰')
                                  ? Colors.orange
                                  : timeRemaining.contains('🕐')
                                  ? _themeSwatch[700]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "-${global.moneyFormat.format(totalDiscount)}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF6A1B9A)),
                      ),
                      // ✅ แสดงเวลาที่เหลือมุมขวาบน
                      if (timeRemaining.isNotEmpty && (timeRemaining.contains('⏳') || timeRemaining.contains('⏰') || timeRemaining.contains('🕐'))) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange.withOpacity(0.15) : _themeSwatch.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange : _themeSwatch, width: 1),
                          ),
                          child: Text(
                            timeRemaining.split(' ')[1],
                            style: TextStyle(fontSize: 9, color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange[800] : _themeSwatch[800], fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // 🎁 ของแถม
    final bonusPromotions = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess.promotion_bonus_list;

    if (bonusPromotions.isNotEmpty) {
      promotionListWidget.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFFFB300)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFFFF6F00).withOpacity(0.4), blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 3))],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFFFB300)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ของแถม',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFE65100), letterSpacing: 0.3),
                  ),
                ),
                // ✅ ปุ่มย่อ/ขยาย
                InkWell(
                  onTap: () {
                    setState(() {
                      _isPromotionBonusExpanded = !_isPromotionBonusExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFFF6F00).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Icon(_isPromotionBonusExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: const Color(0xFFE65100), size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                _buildAnimatedEmoji('🎁', size: 18),
              ],
            ),
          ),
        ),
      );

      // 🎁 Group promotions by promotion_name เพื่อประหยัด space
      final groupedBonusPromotions = <String, List<PosProcessPromotionModel>>{};
      for (var promo in bonusPromotions) {
        // กรองโปรโมชั่นหมดอายุ
        if (!_isPromotionActive(promo.promotion_code)) {
          continue;
        }

        final promoName = global.getNameFromJsonLanguage(promo.promotion_name, global.userScreenLanguage);

        if (!groupedBonusPromotions.containsKey(promoName)) {
          groupedBonusPromotions[promoName] = [];
        }
        groupedBonusPromotions[promoName]!.add(promo);
      }

      // แสดงแต่ละ group
      for (var entry in groupedBonusPromotions.entries) {
        final promoName = entry.key;
        final promoList = entry.value;

        // รวม count ทั้งหมด
        final totalCount = promoList.fold<int>(0, (sum, p) => sum + p.count);

        // เก็บ descriptions แยกเป็นรายการ (ไม่ซ้ำ)
        final descriptionList = promoList.where((p) => p.description.isNotEmpty).map((p) => p.description).toSet().toList();

        // ดึงเวลาที่เหลือจาก promotion แรก
        final timeRemaining = _getPromotionTimeRemaining(promoList.first.promotion_code);

        // ✅ แสดงเฉพาะเมื่อ expanded
        if (_isPromotionBonusExpanded) {
          promotionListWidget.add(
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              constraints: const BoxConstraints(
                maxHeight: 300, // ⭐ จำกัดความสูงไม่เกิน 300px
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFFFF6F00).withOpacity(0.12), const Color(0xFFFFB300).withOpacity(0.12)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF6F00), width: 2),
                boxShadow: [BoxShadow(color: const Color(0xFFFF6F00).withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: SingleChildScrollView(
                // ⭐ เพิ่ม scroll
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFF6F00), width: 2),
                          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 3, offset: const Offset(0, 1))],
                        ),
                        child: Center(child: _buildAnimatedEmoji('🎉', size: 18)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promoName + (totalCount == 1 ? "" : " x $totalCount ครั้ง"),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE65100), height: 1.3),
                            ),
                            // ✅ แสดงรายละเอียดการซื้อ (แต่ละบรรทัด)
                            if (descriptionList.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ...descriptionList.map(
                                (desc) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '• $desc',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w400, height: 1.3),
                                  ),
                                ),
                              ),
                            ],
                            // ✅ แสดงเวลาที่เหลือใต้ชื่อโปรโมชั่น
                            if (timeRemaining.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                timeRemaining,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: timeRemaining.contains('❌')
                                      ? Colors.red
                                      : timeRemaining.contains('⏳') || timeRemaining.contains('⏰')
                                      ? Colors.orange
                                      : timeRemaining.contains('🕐')
                                      ? _themeSwatch[700]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // ✅ แสดงเวลาที่เหลือมุมขวาบน
                      if (timeRemaining.isNotEmpty && (timeRemaining.contains('⏳') || timeRemaining.contains('⏰') || timeRemaining.contains('🕐')))
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange.withOpacity(0.15) : _themeSwatch.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange : _themeSwatch, width: 1),
                          ),
                          child: Text(
                            timeRemaining.split(' ')[1],
                            style: TextStyle(fontSize: 10, color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange[800] : _themeSwatch[800], fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    // 🎟️ คูปอง/สิทธิพิเศษ (Type 101)
    final couponPromotions = global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess.promotion_coupon_list;

    if (couponPromotions.isNotEmpty) {
      promotionListWidget.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFA000), Color(0xFFFFC107)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFFFFA000).withOpacity(0.4), blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 3))],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFA000), Color(0xFFFFC107)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'คูปอง/สิทธิพิเศษ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFF8F00), letterSpacing: 0.3),
                  ),
                ),
                _buildAnimatedEmoji('🎟️', size: 18),
              ],
            ),
          ),
        ),
      );

      // 🎟️ Group promotions by promotion_name เพื่อประหยัด space
      final groupedCouponPromotions = <String, List<PosProcessPromotionModel>>{};
      for (var promo in couponPromotions) {
        // กรองโปรโมชั่นหมดอายุ
        if (!_isPromotionActive(promo.promotion_code)) {
          continue;
        }

        final promoName = global.getNameFromJsonLanguage(promo.promotion_name, global.userScreenLanguage);

        if (!groupedCouponPromotions.containsKey(promoName)) {
          groupedCouponPromotions[promoName] = [];
        }
        groupedCouponPromotions[promoName]!.add(promo);
      }

      // แสดงแต่ละ group
      for (var entry in groupedCouponPromotions.entries) {
        final promoName = entry.key;
        final promoList = entry.value;

        // รวม count ทั้งหมด
        final totalCount = promoList.fold<int>(0, (sum, p) => sum + p.count);

        // ดึงเวลาที่เหลือจาก promotion แรก
        final timeRemaining = _getPromotionTimeRemaining(promoList.first.promotion_code);

        promotionListWidget.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFFFFA000).withOpacity(0.12), const Color(0xFFFFC107).withOpacity(0.12)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFA000), width: 2),
              boxShadow: [BoxShadow(color: const Color(0xFFFFA000).withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFA000), width: 2),
                      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 3, offset: const Offset(0, 1))],
                    ),
                    child: Center(child: _buildAnimatedEmoji('🎫', size: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promoName + (totalCount == 1 ? "" : " x $totalCount ครั้ง"),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFFF8F00), height: 1.3),
                        ),
                        // ✅ แสดงเวลาที่เหลือใต้ชื่อโปรโมชั่น
                        if (timeRemaining.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            timeRemaining,
                            style: TextStyle(
                              fontSize: 11,
                              color: timeRemaining.contains('❌')
                                  ? Colors.red
                                  : timeRemaining.contains('⏳') || timeRemaining.contains('⏰')
                                  ? Colors.orange
                                  : timeRemaining.contains('🕐')
                                  ? _themeSwatch[700]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ✅ แสดงเวลาที่เหลือมุมขวาบน
                  if (timeRemaining.isNotEmpty && (timeRemaining.contains('⏳') || timeRemaining.contains('⏰') || timeRemaining.contains('🕐')))
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange.withOpacity(0.15) : _themeSwatch.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange : _themeSwatch, width: 1),
                      ),
                      child: Text(
                        timeRemaining.split(' ')[1],
                        style: TextStyle(fontSize: 10, color: timeRemaining.contains('⏳') || timeRemaining.contains('⏰') ? Colors.orange[800] : _themeSwatch[800], fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }
    // ถ้าไม่มีโปรโมชั่น ไม่ต้องแสดงอะไร
    if (promotionListWidget.isEmpty) return Container();

    // คำนวณจำนวนโปรโมชั่นทั้งหมด
    final holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
    final process = global.posHoldProcessResult[holdIndex].posProcess;
    final totalPromotions = process.promotion_warning_list.length + process.promotion_product_list.length + process.promotion_bottom_list.length + process.promotion_bonus_list.length + process.promotion_coupon_list.length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(width: 1.0, color: Colors.black)),
      ),
      child: Column(
        children: [
          // 🎁 Header พร้อมปุ่มซ่อน/แสดงทั้งหมด
          InkWell(
            onTap: () {
              setState(() {
                _isPromotionWidgetCollapsed = !_isPromotionWidgetCollapsed;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _isPromotionWidgetCollapsed ? [Colors.grey.shade400, Colors.grey.shade500] : [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: (_isPromotionWidgetCollapsed ? Colors.grey : const Color(0xFFFF6B6B)).withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Icon(_isPromotionWidgetCollapsed ? Icons.card_giftcard : Icons.local_offer_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isPromotionWidgetCollapsed ? 'โปรโมชั่น ($totalPromotions รายการ) - กดเพื่อแสดง' : 'โปรโมชั่น ($totalPromotions รายการ)',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                    child: Icon(_isPromotionWidgetCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
          // 📋 แสดงรายละเอียดเมื่อไม่ได้ซ่อน
          if (!_isPromotionWidgetCollapsed) ...[const SizedBox(height: 4), ...promotionListWidget],
        ],
      ),
    );
  }

  Widget posButtonShowMenu() {
    return myButton(
      child: Icon((showButtonMenu) ? Icons.arrow_downward : Icons.arrow_upward),
      onPressed: () {
        setState(() {
          showButtonMenu = !showButtonMenu;
        });
      },
    );
  }

  double _getButtonFontSize() {
    switch (buttonSizeLevel) {
      case 0:
        return 17.0;
      case 1:
        return 18.0;
      case 2:
        return 20.0;
      case 3:
        return 22.0;
      default:
        return 17.0;
    }
  }

  double _getCommandButtonFontSize() {
    switch (buttonSizeLevel) {
      case 0:
        return 15.0;
      case 1:
        return 17.0;
      case 2:
        return 19.0;
      case 3:
        return 21.0;
      default:
        return 15.0;
    }
  }

  double _getButtonHeight() {
    switch (buttonSizeLevel) {
      case 0:
        return 40.0;
      case 1:
        return 50.0;
      case 2:
        return 60.0;
      case 3:
        return 70.0;
      default:
        return 40.0;
    }
  }

  double _getDynamicFontSize(double baseFontSize) {
    return baseFontSize * listTextHeight;
  }

  // ✅ _cycleButtonSize และ _saveButtonSize ถูกย้ายไปอยู่ใน PosAppBar แล้ว

  Future<void> _loadButtonSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      buttonSizeLevel = prefs.getInt('button_size_level') ?? 0;
    });
  }

  Widget posLayoutBottomDesktop() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          myButton(
            backgroundColor: (desktopWidgetMode == 0) ? Colors.orange : _themeSwatch,
            child: const Icon(Icons.numbers),
            onPressed: () {
              setState(() {
                desktopWidgetMode = 0;
              });
            },
          ),
          const SizedBox(width: 4),
          myButton(
            flex: 2,
            backgroundColor: (desktopWidgetMode == 2) ? Colors.orange : _themeSwatch,
            child: FittedBox(
              fit: BoxFit.cover,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(Icons.grid_on, size: 16),
                  const SizedBox(width: 4),
                  Text(global.language("category"), textAlign: TextAlign.center, overflow: TextOverflow.clip, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            onPressed: () {
              setState(() {
                desktopWidgetMode = 2;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _requestKeyboardFocus();
                });
              });
            },
          ),
          const SizedBox(width: 4),
          myButton(
            flex: 2,
            backgroundColor: (desktopWidgetMode == 1) ? Colors.orange : _themeSwatch,
            child: FittedBox(
              fit: BoxFit.cover,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(Icons.search, size: 16),
                  const SizedBox(width: 4),
                  Text(global.language("find_item"), textAlign: TextAlign.center, overflow: TextOverflow.clip, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            onPressed: () {
              setState(() {
                desktopWidgetMode = 1;
              });
            },
          ),
          const SizedBox(width: 4),
          myButton(
            flex: 2,
            backgroundColor: (desktopWidgetMode == 3) ? Colors.orange : _themeSwatch,
            child: FittedBox(
              fit: BoxFit.cover,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon((FontAwesomeIcons.addressBook), size: 16),
                  const SizedBox(width: 4),
                  Text(global.language("customer"), textAlign: TextAlign.center, overflow: TextOverflow.clip, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            onPressed: () {
              setState(() {
                desktopWidgetMode = 3;
              });
            },
          ),
          const SizedBox(width: 4),
          posButtonShowMenu(),
          const SizedBox(width: 4),
          posButtonBackHome(),
        ],
      ),
    );
  }

  Widget myButton({required Widget child, required Function onPressed, Color? backgroundColor, int flex = 1}) {
    backgroundColor ??= _themeSwatch;
    // เช็คว่าปุ่มเป็น active (orange) หรือ inactive (blue หรือสีอื่น)
    bool isActive = backgroundColor == Colors.orange;

    return Expanded(
      flex: flex,
      child: Container(
        height: _getButtonHeight(), // Dynamic height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              onPressed();
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: buttonSizeLevel * 2.0 + 10, // Dynamic padding based on size level
                horizontal: 6.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isActive ? Colors.orange.shade500 : _themeSwatch[50]!, width: 1),
                gradient: LinearGradient(colors: isActive ? [Colors.orange.shade50, Colors.white] : [_themeSwatch[50]!, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              child: Center(
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: _getButtonFontSize(), // Dynamic font size
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.orange.shade800 : _themeSwatch[800]!,
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: isActive ? Colors.orange.shade700 : _themeSwatch[800]!, size: 20),
                    child: FittedBox(child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget posLayoutBottomTablet() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          if (Platform.isAndroid || Platform.isIOS)
            myButton(
              child: const FaIcon(FontAwesomeIcons.barcode),
              onPressed: () {
                setState(() {
                  qrCodeBarcodeScannerQtyResult = 1;
                  qrCodeBarcodeScannerStart = !qrCodeBarcodeScannerStart;
                });
              },
            ),
          if (Platform.isAndroid || Platform.isIOS) const SizedBox(width: 4),
          myButton(
            flex: 2,
            backgroundColor: (tabletTabController.index == 0) ? Colors.orange : _themeSwatch,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(Icons.grid_on, size: 16),
                const SizedBox(width: 4),
                Text(
                  global.language("category"),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                tabletTabController.index = 0;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _requestKeyboardFocus();
                });
              });
            },
          ),
          const SizedBox(width: 4),
          myButton(
            flex: 2,
            backgroundColor: (tabletTabController.index == 1) ? Colors.orange : _themeSwatch,
            child: FittedBox(
              fit: BoxFit.cover,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(Icons.search, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    global.language("find_item"),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            onPressed: () {
              setState(() {
                tabletTabController.index = 1;
              });
            },
          ),
          const SizedBox(width: 4),
          myButton(
            flex: 2,
            backgroundColor: (tabletTabController.index == 2) ? Colors.orange : _themeSwatch,
            child: FittedBox(
              fit: BoxFit.cover,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon((FontAwesomeIcons.addressBook), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    global.language("customer"),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            onPressed: () {
              setState(() {
                tabletTabController.index = 2;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _requestKeyboardFocus();
                });
              });
            },
          ),
          const SizedBox(width: 4),
          posButtonShowMenu(),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget posButtonSwitchShowDetail() {
    return myButton(
      backgroundColor: (showDetail) ? Colors.orange : _themeSwatch,
      child: (showDetail) ? const Icon(Icons.remove_red_eye) : const Icon(Icons.remove_red_eye_outlined),
      onPressed: () {
        setState(() {
          showDetail = !showDetail;
        });
      },
    );
  }

  Widget posButtonBackHome() {
    return myButton(
      child: const Icon(Icons.home),
      onPressed: () {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => const MenuScreen()), (route) => false);
      },
    );
  }

  Widget posLayoutBottomPhone() {
    return Container(
      margin: const EdgeInsets.all(2),
      width: double.infinity,
      child: Row(
        children: [
          if (Platform.isAndroid || Platform.isIOS)
            myButton(
              child: const FaIcon(FontAwesomeIcons.barcode),
              onPressed: () {
                setState(() {
                  qrCodeBarcodeScannerQtyResult = 1;
                  qrCodeBarcodeScannerStart = !qrCodeBarcodeScannerStart;
                });
              },
            ),
          if (Platform.isAndroid || Platform.isIOS) const SizedBox(width: 2),
          myButton(
            child: const FaIcon(FontAwesomeIcons.addressBook),
            onPressed: () {
              desktopWidgetMode = 3;
              phoneTabController.index = 3;
            },
          ),
          const SizedBox(width: 2),
          posButtonShowMenu(),
          const SizedBox(width: 2),
          // posButtonSwitchShowDetail(),
        ],
      ),
    );
  }

  Widget posLayoutBottom() {
    late Widget menuList;
    switch (deviceMode) {
      case 0:
        menuList = posLayoutBottomDesktop();
        break;
      case 1:
        menuList = posLayoutBottomTablet();
        break;
      case 2:
        menuList = posLayoutBottomPhone();
        break;
      default:
        menuList = Container();
    }
    return Column(
      children: [
        if (deviceMode != 2) Container(height: 63, margin: const EdgeInsets.only(top: 0), child: totalAndPayScreen()),
        if (deviceMode != 2) const SizedBox(height: 4),
        menuList,
        if (deviceMode != 2) Divider(height: 8, color: Colors.grey.shade300),
        if (showButtonMenu) commandWidget(),
        if (deviceMode != 2) const SizedBox(height: 2),
      ],
    );
  }

  Widget posLayoutTabletScreen() {
    Size size = MediaQuery.of(context).size;
    Widget selectProduct = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(width: 0, color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: DefaultTabController(
                    length: 5,
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        return TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          controller: tabletTabController,
                          children: [
                            selectProductLevelWidget(),
                            findProductByText(),
                            findMemberByText(),
                            const SizedBox(width: double.infinity, child: Text("xxx")),
                            const SizedBox(width: double.infinity, child: Text("xxx")),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                if (productOptions.isNotEmpty) selectProductExtraListWidget(),
              ],
            ),
          ),
        ],
      ),
    );
    String saleCode = "";
    String saleName = "";
    int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
    if (holdIndex != -1) {
      saleCode = global.posHoldProcessResult[holdIndex].saleCode.trim();
      saleName = global.posHoldProcessResult[holdIndex].saleName.trim();
    }
    String customerDetail = "";
    if (global.posHoldProcessResult[holdIndex].customerName.isNotEmpty) {
      customerDetail = global.posHoldProcessResult[holdIndex].customerName;
      if (global.posHoldProcessResult[holdIndex].customerCode.isNotEmpty) {
        customerDetail += " : ${global.posHoldProcessResult[holdIndex].customerCode}";
      }
      // if (global.posHoldProcessResult[holdIndex].priceLevel.isNotEmpty) {
      //   customerDetail += " ลู่ราคา ${global.posHoldProcessResult[holdIndex].priceLevel}";
      // }
    }

    Widget screenSale = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        border: Border.all(width: 0, color: Colors.white),
        color: Colors.white,
      ),
      child: Column(
        children: [
          if ((Platform.isAndroid || Platform.isIOS) && qrCodeBarcodeScannerStart)
            SizedBox(
              width: double.infinity,
              height: 300, // กำหนดความสูงที่ชัดเจน
              child: selectProductByQrCodeOrBarcode(),
            ),
          if (saleCode.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1.0, color: Colors.grey)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${global.language('sale')} : $saleName : $saleCode', style: const TextStyle(fontSize: 14, color: Colors.black)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      global.playSound(sound: global.SoundEnum.buttonTing);
                      setState(() {
                        int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
                        global.posHoldProcessResult[holdIndex].saleCode = "";
                        global.posHoldProcessResult[holdIndex].saleName = "";
                      });
                    },
                  ),
                ],
              ),
            ),
          if (customerDetail.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1.0, color: Colors.grey)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(customerDetail, style: const TextStyle(fontSize: 14, color: Colors.black)),
                  ), // Add Use Points button if customer is a member and has points
                  // if (global.posHoldProcessResult[holdIndex].customerGuid.isNotEmpty)
                  //   ElevatedButton(
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.amber.shade600,
                  //       foregroundColor: Colors.white,
                  //       minimumSize: const Size(80, 32),
                  //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  //     ),
                  //     onPressed: () => _showUsePointsDialog(),
                  //     child: Text(
                  //       global.language('use_points'),
                  //       style: const TextStyle(fontSize: 12),
                  //     ),
                  //   ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      global.playSound(sound: global.SoundEnum.buttonTing);
                      setState(() {
                        global.posHoldProcessResult[holdIndex].customerPhone = "";
                        global.posHoldProcessResult[holdIndex].customerName = "";
                        global.posHoldProcessResult[holdIndex].customerCode = "";
                        global.posHoldProcessResult[holdIndex].ismember = false; // รีเซ็ตเป็นไม่ใช่สมาชิก
                        global.posHoldProcessResult[holdIndex].priceLevel = "";
                        global.posHoldProcessResult[holdIndex].customerGuid = "";

                        // Clear point values when customer is changed
                        global.posHoldProcessResult[holdIndex].posProcess.usepoint = 0.0;
                        global.posHoldProcessResult[holdIndex].posProcess.pointdiscountamount = 0.0;
                      });

                      await _recalculatePricesForMemberStatus(holdIndex);

                      // Recalculate process to update all values including point calculations
                      await posCompileProcess(
                        holdCode: global.posHoldActiveCode,
                        docMode: global.posScreenToInt(widget.posScreenMode),
                        detailDiscountFormula: "",
                        cashRoundAmount: false,
                        discountFoodOnly: global.tempIsRestaurantSystem,
                        customermode: global.secondScreenCommandProcessDetail,
                      );

                      // Request keyboard focus back after clearing customer
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _requestKeyboardFocus();
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(child: transScreen(mode: 0)),
          Padding(padding: const EdgeInsets.only(left: 4, right: 4), child: posLayoutBottom()),
        ],
      ),
    );

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Container(
              color: Colors.white,
              width: size.width,
              child: SplitView(
                gripColor: Colors.blueGrey.shade100,
                controller: splitViewController,
                //onWeightChanged: (w) => print("Horizontal $w"),
                indicator: const SplitIndicator(viewMode: SplitViewMode.Horizontal),
                viewMode: SplitViewMode.Horizontal,
                activeIndicator: const SplitIndicator(viewMode: SplitViewMode.Horizontal, isActive: true),
                children: (splitViewMode == 1) ? [selectProduct, screenSale] : [screenSale, selectProduct],
              ),
            ),
            if (showNumericPad)
              Positioned(
                left: showNumericPadLeft,
                top: showNumericPadTop,
                child: LongPressDraggable(
                  feedback: SizedBox(width: 250, height: 310, child: Center(child: numericPadWidget())),
                  childWhenDragging: Container(),
                  onDraggableCanceled: (Velocity velocity, Offset offset) {
                    setState(() {
                      showNumericPadLeft = offset.dx;
                      showNumericPadTop = offset.dy;
                    });
                  },
                  child: SizedBox(width: 250, height: 310, child: numericPadWidget()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget posLayoutPhoneScreen() {
    String saleCode = "";
    String saleName = "";
    int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
    if (holdIndex != -1) {
      saleCode = global.posHoldProcessResult[holdIndex].saleCode.trim();
      saleName = global.posHoldProcessResult[holdIndex].saleName.trim();
    }
    String customerDetail = "";
    if (global.posHoldProcessResult[holdIndex].customerName.isNotEmpty) {
      customerDetail = global.posHoldProcessResult[holdIndex].customerName;
      if (global.posHoldProcessResult[holdIndex].customerCode.isNotEmpty) {
        customerDetail += " : ${global.posHoldProcessResult[holdIndex].customerCode}";
      }
      // if (global.posHoldProcessResult[holdIndex].customerPhone.isNotEmpty) {
      //   customerDetail += " : ${global.posHoldProcessResult[holdIndex].customerPhone}";
      // }
    }
    return SafeArea(
      child: Column(
        children: [
          if (global.isPhoneDevice())
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1.0, color: Colors.grey),
                  bottom: BorderSide(width: 1.0, color: Colors.grey),
                ),
              ),
              child: Text('${global.userLogin!.name} (${global.userLogin!.code})', style: const TextStyle(fontSize: 14, color: Colors.black)),
            ),
          Container(height: 50, margin: const EdgeInsets.all(2), child: totalAndPayScreen()),
          if (saleCode.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1.0, color: Colors.grey),
                  bottom: BorderSide(width: 1.0, color: Colors.grey),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${global.language('sale')} : $saleName : $saleCode', style: const TextStyle(fontSize: 14, color: Colors.black)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      global.playSound(sound: global.SoundEnum.buttonTing);
                      setState(() {
                        int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
                        global.posHoldProcessResult[holdIndex].saleCode = "";
                        global.posHoldProcessResult[holdIndex].saleName = "";
                      });
                    },
                  ),
                ],
              ),
            ),
          if (customerDetail.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1.0, color: Colors.grey),
                  bottom: BorderSide(width: 1.0, color: Colors.grey),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(customerDetail, style: const TextStyle(fontSize: 14, color: Colors.black)),
                  ), // Add Use Points button if customer is a member and has points
                  // if (global.posHoldProcessResult[holdIndex].customerGuid.isNotEmpty)
                  //   ElevatedButton(
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.amber.shade600,
                  //       foregroundColor: Colors.white,
                  //       minimumSize: const Size(80, 32),
                  //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  //     ),
                  //     onPressed: () => _showUsePointsDialog(),
                  //     child: Text(
                  //       global.language('use_points'),
                  //       style: const TextStyle(fontSize: 12),
                  //     ),
                  //   ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      global.playSound(sound: global.SoundEnum.buttonTing);
                      setState(() {
                        int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
                        global.posHoldProcessResult[holdIndex].customerPhone = "";
                        global.posHoldProcessResult[holdIndex].customerName = "";
                        global.posHoldProcessResult[holdIndex].customerCode = "";
                        global.posHoldProcessResult[holdIndex].ismember = false;
                        global.posHoldProcessResult[holdIndex].priceLevel = "";
                        global.posHoldProcessResult[holdIndex].customerGuid = "";

                        // Clear point values when customer is changed
                        global.posHoldProcessResult[holdIndex].posProcess.usepoint = 0.0;
                        global.posHoldProcessResult[holdIndex].posProcess.pointdiscountamount = 0.0;
                      });

                      // Recalculate process to update all values including point calculations
                      posCompileProcess(
                        holdCode: global.posHoldActiveCode,
                        docMode: global.posScreenToInt(widget.posScreenMode),
                        detailDiscountFormula: "",
                        cashRoundAmount: false,
                        discountFoodOnly: global.tempIsRestaurantSystem,
                        customermode: global.secondScreenCommandProcessDetail,
                      );

                      // Request keyboard focus back after clearing customer
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _requestKeyboardFocus();
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Builder(
                builder: (BuildContext context) {
                  return Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: Container(
                      decoration: const BoxDecoration(color: Colors.black),
                      child: Container(
                        color: Colors.white,
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          children: [
                            Container(
                              color: _themeSwatch,
                              child: TabBar(
                                controller: phoneTabController,
                                indicatorColor: Colors.white,
                                onTap: (value) {
                                  setState(() {
                                    phoneTabController.index = value;
                                  });
                                },
                                tabs: const [
                                  Tab(icon: Icon(Icons.list)),
                                  Tab(icon: Icon(Icons.grid_view)),
                                  Tab(icon: Icon(Icons.search)),
                                  Tab(icon: FaIcon(FontAwesomeIcons.addressBook)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (BuildContext context, BoxConstraints constraints) {
                                  return Column(
                                    children: [
                                      if ((Platform.isAndroid || Platform.isIOS) && qrCodeBarcodeScannerStart) SizedBox(width: double.infinity, height: 200, child: selectProductByQrCodeOrBarcode()),
                                      Expanded(
                                        child: TabBarView(
                                          controller: phoneTabController,
                                          children: [
                                            transScreen(mode: 0),
                                            selectProductLevelWidget(),
                                            findProductByText(),
                                            findMemberByText(),
                                            //commandScreen(),
                                          ],
                                        ),
                                      ),
                                      (phoneTabController.index != 2) ? posLayoutBottom() : Container(),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ _buildButtonSizeIndicator, _buildStatusIndicators, _buildStatusIcon, _buildPrinterStatusDialog, _buildSyncStatusDialog ถูกแทนที่ด้วย PosAppBar

  Widget posLayoutDesktop() {
    Size size = MediaQuery.of(context).size;
    Widget selectProduct = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(width: 0, color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: transScreen(mode: 0)),
                if (productOptions.isNotEmpty) selectProductExtraListWidget(),
              ],
            ),
          ),
        ],
      ),
    );
    int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
    String saleCode = "";
    String saleName = "";
    if (holdIndex != -1) {
      saleCode = global.posHoldProcessResult[holdIndex].saleCode.trim();
      saleName = global.posHoldProcessResult[holdIndex].saleName.trim();
    }
    String customerDetail = "";
    if (global.posHoldProcessResult[holdIndex].customerName.isNotEmpty) {
      customerDetail = global.posHoldProcessResult[holdIndex].customerName;
      if (global.posHoldProcessResult[holdIndex].customerCode.isNotEmpty) {
        customerDetail += " : ${global.posHoldProcessResult[holdIndex].customerCode}";
      }
      // if (global.posHoldProcessResult[holdIndex].customerPhone.isNotEmpty) {
      //   customerDetail += " : ${global.posHoldProcessResult[holdIndex].customerPhone}";
      // }
    }

    Widget screenSale = Column(
      children: [
        if (global.posHoldProcessResult[holdIndex].customerCode.isNotEmpty || global.posHoldProcessResult[holdIndex].customerPhone.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(width: 1.0, color: Colors.grey)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(customerDetail, style: const TextStyle(fontSize: 14, color: Colors.black)),
                ), // Add Use Points button if customer is a member and has points
                // if (global.posHoldProcessResult[holdIndex].customerGuid.isNotEmpty)
                //   ElevatedButton(
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.amber.shade600,
                //       foregroundColor: Colors.white,
                //       minimumSize: const Size(80, 32),
                //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //     ),
                //     onPressed: () => _showUsePointsDialog(),
                //     child: Text(
                //       global.language('use_points'),
                //       style: const TextStyle(fontSize: 12),
                //     ),
                //   ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () async {
                    global.playSound(sound: global.SoundEnum.buttonTing);
                    setState(() {
                      global.posHoldProcessResult[holdIndex].customerCode = "";
                      global.posHoldProcessResult[holdIndex].customerName = "";
                      global.posHoldProcessResult[holdIndex].customerPhone = "";
                      global.posHoldProcessResult[holdIndex].ismember = false;
                      global.posHoldProcessResult[holdIndex].priceLevel = "";
                      global.posHoldProcessResult[holdIndex].customerGuid = "";

                      // Clear point values when customer is changed
                      global.posHoldProcessResult[holdIndex].posProcess.usepoint = 0.0;
                      global.posHoldProcessResult[holdIndex].posProcess.pointdiscountamount = 0.0;
                    });

                    await _recalculatePricesForMemberStatus(holdIndex);

                    // Recalculate process to update all values including point calculations
                    await posCompileProcess(
                      holdCode: global.posHoldActiveCode,
                      docMode: global.posScreenToInt(widget.posScreenMode),
                      detailDiscountFormula: "",
                      cashRoundAmount: false,
                      discountFoodOnly: global.tempIsRestaurantSystem,
                      customermode: global.secondScreenCommandProcessDetail,
                    );

                    // Request keyboard focus back after clearing customer
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _requestKeyboardFocus();
                    });
                  },
                ),
              ],
            ),
          ),
        if (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].saleCode.trim().isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(width: 1.0, color: Colors.grey)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('${global.language('sale')} : $saleName : $saleCode', style: const TextStyle(fontSize: 14, color: Colors.black)),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    global.playSound(sound: global.SoundEnum.buttonTing);
                    setState(() {
                      global.posHoldProcessResult[holdIndex].saleCode = "";
                      global.posHoldProcessResult[holdIndex].saleName = "";
                    });
                  },
                ),
              ],
            ),
          ),
        if (desktopWidgetMode == 0)
          Expanded(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2, bottom: 2),
                  padding: const EdgeInsets.all(6),
                  width: double.infinity,
                  height: 300, // เพิ่มจาก 150 → 300 เพื่อแสดงรายละเอียดเต็ม
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(width: 0, color: _themeSwatch),
                    boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 5.0)],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgetMessage),
                        ),
                      ),
                      if (widgetMessageImageUrl.isNotEmpty) Image(image: AppImageCacheManager.getCachedNetwork(widgetMessageImageUrl)),
                    ],
                  ),
                ),
                Expanded(
                  child: PosNumPad(
                    key: posNumPadGlobalKey,
                    onChange: (String number) {
                      // Use ValueNotifier instead of setState for better performance
                      numericPadTextInput = number;
                    },
                    onSubmit: (String number) async {
                      await onSubmit(number);

                      setState(() {
                        numericPadTextInput = "";
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        if (desktopWidgetMode == 1) Expanded(child: findProductByText()),
        if (desktopWidgetMode == 2)
          Expanded(
            child: Column(
              children: [
                Expanded(child: selectProductLevelListScreenWidget()),
                selectProductLevelSelectWidget(),
              ],
            ),
          ),
        if (desktopWidgetMode == 3) Expanded(child: findMemberByText()),
        Container(width: double.infinity, padding: const EdgeInsets.only(left: 2, right: 2), child: posLayoutBottom()),
      ],
    );

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Container(
              color: Colors.white,
              width: size.width,
              child: SplitView(
                gripColor: Colors.blueGrey.shade100,
                controller: splitViewController,
                //onWeightChanged: (w) => print("Horizontal $w"),
                indicator: const SplitIndicator(viewMode: SplitViewMode.Horizontal),
                viewMode: SplitViewMode.Horizontal,
                activeIndicator: const SplitIndicator(viewMode: SplitViewMode.Horizontal, isActive: true),
                children: (splitViewMode == 1) ? [selectProduct, screenSale] : [screenSale, selectProduct],
              ),
            ),
            if (showNumericPad)
              Positioned(
                left: showNumericPadLeft,
                top: showNumericPadTop,
                child: LongPressDraggable(
                  feedback: SizedBox(width: 250, height: 310, child: Center(child: numericPadWidget())),
                  childWhenDragging: Container(),
                  onDraggableCanceled: (Velocity velocity, Offset offset) {
                    setState(() {
                      showNumericPadLeft = offset.dx;
                      showNumericPadTop = offset.dy;
                    });
                  },
                  child: SizedBox(width: 250, height: 310, child: numericPadWidget()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void productCategoryLoadFinish() {
    PosProcess().sumCategoryCount(value: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess);
    context.read<ProductCategoryBloc>().add(ProductCategoryLoadFinish());
  }

  // ✅ _buildAppBarButton และ _buildPrintQueueButton ถูกแทนที่ด้วย PosAppBar

  @override
  Widget build(BuildContext context) {
    String title = global.posConfig.code;
    if (widget.posScreenMode == global.PosScreenModeEnum.posSale) {
      // 'ขายสินค้า'
      title = "$title ${global.language("pos_screen_sale")}";
    } else {
      // 'รับคืนสินค้า'
      title = "$title ${global.language("pos_screen_return")}";
    }
    if (global.isDesktopScreen() || global.isTabletDevice()) {
      title = "$title ${global.userLogin!.name} (${global.userLogin!.code})";
    }
    global.globalContext = context;
    return MultiBlocListener(
      listeners: [
        BlocListener<ProductCategoryBloc, ProductCategoryState>(
          listener: (context, state) async {
            if (state is ProductCategoryLoadSuccess) {
              loadCategory();
              await loadProductByCategory(categoryGuidSelected);
              PosProcess().sumCategoryCount(value: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].posProcess);
              processEvent(barcode: "", holdCode: global.posHoldActiveCode);
              productCategoryLoadFinish();
            }
          },
        ),
      ],
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(systemNavigationBarColor: _themeSwatch, systemNavigationBarIconBrightness: Brightness.light),
          child: Scaffold(
            // ✅ ใช้ PosAppBar แทน AppBar เดิม
            appBar: PosAppBar(
              title: title,
              posScreenMode: global.posScreenToInt(widget.posScreenMode),
              deviceMode: deviceMode,
              showDetail: showDetail,
              splitViewMode: splitViewMode,
              gridItemSize: gridItemSize,
              listTextHeight: listTextHeight,
              cashierPrinterIndex: cashierPrinterIndex,
              onRefreshPressed: () async {
                await posCompileProcess(
                  holdCode: global.posHoldActiveCode,
                  docMode: global.posScreenToInt(widget.posScreenMode),
                  detailDiscountFormula: detailDiscountFormula,
                  cashRoundAmount: false,
                  discountFoodOnly: global.tempIsRestaurantSystem,
                  customermode: global.secondScreenCommandProcessDetail,
                ).then((value) {
                  if (value.lineGuid.isNotEmpty && value.lastCommandCode == 1) {
                    int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
                    global.posHoldProcessResult[holdIndex].activeLineGuid = value.lineGuid;
                  }
                  processEventRefresh(holdCode: global.posHoldActiveCode);
                  // setState(() {});
                });
              },
              onShowDetailToggle: () {
                setState(() {
                  showDetail = !showDetail;
                });
              },
              onRotatePressed: () {
                setState(() {
                  if (splitViewMode == 1) {
                    splitViewMode = 2;
                    splitViewController = SplitViewController(weights: [0.4, 0.6], limits: [WeightLimit(min: 0.2, max: 0.8)]);
                  } else {
                    splitViewMode = 1;
                    splitViewController = SplitViewController(weights: [0.6, 0.4], limits: [WeightLimit(min: 0.2, max: 0.8)]);
                  }
                });
              },
              onGridSizePressed: () {
                setState(() {
                  gridItemSize += 0.2;
                  if (gridItemSize > 1.75) {
                    gridItemSize = 1;
                  }
                });
              },
              onTextHeightPressed: () {
                setState(() {
                  listTextHeight += 0.1;
                  if (listTextHeight > 2) {
                    listTextHeight = 0.5;
                  }
                  global.posScreenListHeightSet(listTextHeight);
                });
              },
              onDeviceModePressed: () {
                setState(() {
                  if (deviceMode == 0) {
                    deviceMode = 1;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _requestKeyboardFocus();
                    });
                  } else {
                    deviceMode = 0;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _requestKeyboardFocus();
                    });
                  }
                });
              },
              onRequestKeyboardFocus: _requestKeyboardFocus,
              onTierStockPressed: () async {
                final result = await showDialog<bool>(context: context, builder: (context) => const TierStockEditDialog());

                // ถ้าบันทึกสำเร็จ ให้ refresh
                if (result == true) {
                  await posCompileProcess(
                    holdCode: global.posHoldActiveCode,
                    docMode: global.posScreenToInt(widget.posScreenMode),
                    detailDiscountFormula: detailDiscountFormula,
                    cashRoundAmount: false,
                    discountFoodOnly: global.tempIsRestaurantSystem,
                    customermode: global.secondScreenCommandProcessDetail,
                  ).then((value) {
                    if (value.lineGuid.isNotEmpty && value.lastCommandCode == 1) {
                      int holdIndex = global.findPosHoldProcessResultIndex(global.posHoldActiveCode);
                      global.posHoldProcessResult[holdIndex].activeLineGuid = value.lineGuid;
                    }
                    processEventRefresh(holdCode: global.posHoldActiveCode);
                    // setState(() {});
                  });
                }
              },
            ),
            body: Stack(
              children: [
                // Main content
                (deviceMode == 0)
                    ? Container(
                        decoration: BoxDecoration(border: Border.all(width: 1, color: Colors.black)),
                        child: posLayoutDesktop(),
                      )
                    : (deviceMode == 1)
                    ? posLayoutTabletScreen()
                    : posLayoutPhoneScreen(),

                // 🔢 Barcode Buffer Overlay - แสดงตรงด้านล่างกลางจอ
                ValueListenableBuilder<String>(
                  valueListenable: barcodeBufferNotifier,
                  builder: (context, buffer, child) {
                    if (buffer.isEmpty) return const SizedBox.shrink();

                    // 🎨 ดึงสถานะการค้นหา (true=เจอ สีน้ำเงิน, false=ไม่เจอ สีแดง, null=กำลังค้นหา)
                    return ValueListenableBuilder<bool?>(
                      valueListenable: barcodeSearchSuccess,
                      builder: (context, isSuccess, _) {
                        // กำหนดสีตามสถานะ
                        final Color color1;
                        final Color color2;
                        final IconData icon;

                        if (isSuccess == false) {
                          // ❌ ไม่เจอสินค้า - สีแดง
                          color1 = Colors.red.shade600;
                          color2 = Colors.red.shade800;
                          icon = Icons.error_outline;
                        } else {
                          // ✅ เจอสินค้า หรือกำลังค้นหา - สีน้ำเงิน
                          color1 = _themeSwatch[600]!;
                          color2 = _themeSwatch[800]!;
                          icon = Icons.qr_code_scanner;
                        }

                        return Positioned(
                          bottom: 80,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [color1, color2]),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, color: Colors.white, size: 24),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isSuccess == false
                                              ? '❌ ไม่พบสินค้า'
                                              : isSuccess == true
                                              ? '✅ พบสินค้าแล้ว'
                                              : 'กำลังป้อนบาร์โค้ด',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          buffer,
                                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: 'monospace'),
                                        ),
                                        const SizedBox(height: 2),
                                        Text('${buffer.length} ตัวอักษร', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ); // ปิด Positioned
                      }, // ปิด builder ของ ValueListenableBuilder ชั้นใน (barcodeSearchSuccess)
                    ); // ปิด ValueListenableBuilder ชั้นใน
                  }, // ปิด builder ของ ValueListenableBuilder ชั้นนอก (barcodeBufferNotifier)
                ), // ปิด ValueListenableBuilder ชั้นนอก
              ],
            ),
          ),
        ),
      ),
    );
  }
}
