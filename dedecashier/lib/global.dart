import 'package:dedecashier/api/client.dart';
import 'package:dedecashier/api/network/websocket_server.dart';
import 'package:dedecashier/api/sync/model/promotion_model.dart';
import 'package:dedecashier/api/sync/model/system_info_model.dart';
import 'package:dedecashier/db/product_barcode_status_helper.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_print.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_process.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_mock_promotion.dart';
import 'package:dedecashier/model/json/pos_model.dart';
import 'package:dedecashier/model/objectbox/product_barcode_status_struct.dart';
import 'package:dedecashier/model/sync/clickhouse_server_trans_model.dart';
import 'package:dedecashier/services/print_process.dart';
import 'dart:ffi';
import 'package:decimal/decimal.dart';
import 'package:dedecashier/model/json/pos_process_model.dart';
import 'package:dedecashier/util/printer.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:fullscreen_window/fullscreen_window.dart';
import 'package:gbprimepay/gbprimepay.dart';
import 'package:gbprimepay/models/gb_payment_gen_qr_response.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dedecashier/widgets/displays_manager.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:win32/win32.dart';
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/api/clickhouse/clickhouse_api.dart' as api;
import 'package:dedecashier/api/network/server_post.dart';
import 'package:dedecashier/api/sync/model/employee_model.dart';
import 'package:dedecashier/api/sync/model/wallet_model.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/objectbox.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/db/kitchen_helper.dart';
import 'package:dedecashier/db/shift_helper.dart';
import 'package:dedecashier/model/json/customer_display_model.dart';
import 'package:dedecashier/model/objectbox/buffet_mode_struct.dart';
import 'package:dedecashier/model/objectbox/employees_struct.dart';
import 'package:dedecashier/model/objectbox/kitchen_struct.dart';
import 'package:dedecashier/model/objectbox/order_temp_struct.dart';
import 'package:dedecashier/model/objectbox/pos_ticket_struct.dart';
import 'package:dedecashier/model/objectbox/print_queue_struct.dart';
import 'package:dedecashier/model/objectbox/upload_queue_struct.dart';
import 'package:dedecashier/model/objectbox/tier_stock_struct.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_num_pad.dart';
import 'package:dedecashier/model/objectbox/staff_client_struct.dart';
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:dedecashier/model/objectbox/wallet_struct.dart';
import 'package:dedecashier/util/load_form_design.dart';
import 'package:dedecashier/util/print_kitchen.dart';
import 'package:dedecashier/util/print_order_summery.dart';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/db/bank_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:dedecashier/api/sync/model/sync_model.dart';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:dart_ping_ios/dart_ping_ios.dart';
import 'package:dedecashier/db/employee_helper.dart';
import 'package:dedecashier/db/customer_helper.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/bank_struct.dart';
import 'package:dedecashier/model/json/payment_model.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:dedecashier/model/objectbox/product_category_struct.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:async';
import 'db/product_category_helper.dart';
import 'db/product_barcode_helper.dart';
import 'db/pos_log_helper.dart';
import 'db/bill_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charset_converter/charset_converter.dart';
import 'model/objectbox/form_design_struct.dart';
import 'dart:ui' as ui;
import 'dart:io' as io;
import 'package:image/image.dart' as im;
import 'package:dedecashier/core/logger/app_logger.dart';

String secondScreenCommandInformation = "information";
String secondScreenCommandProcessDetail = "process";
String secondScreenCommandPay = "pay";
String paySlipPath = "payslip";
String applicationName = "";
String objectBoxVersion = "1";
bool tempIsRestaurantSystem = false; // ใช้สำหรับแสดงผลในหน้าจอ POS ว่าเป็นระบบร้านอาหารหรือไม่
late Directory applicationDocumentsDirectory;
late ProfileSettingModel profileSetting;
PosConfigModel posConfig = PosConfigModel();
List<FormDesignObjectBoxStruct> formDesignList = [];
String jsonLanguageFileName = "assets/language.json";
DisplayManager displayManager = DisplayManager();
String billImagePath = "cashierbill";
String discountFormular = "";
bool speechActive = false;
bool callerAlert = true;
bool isSoundEnabled = true; // ⭐ เปิด/ปิดเสียง beep (default: เปิด)

/// โหลดค่า isSoundEnabled จาก SharedPreferences
Future<void> loadSoundSetting() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    isSoundEnabled = prefs.getBool('is_sound_enabled') ?? true;
    AppLogger.debug('🔊 [Sound] Loaded setting: $isSoundEnabled');
  } catch (e) {
    AppLogger.error('❌ [Sound] Failed to load setting: $e');
  }
}

/// บันทึกค่า isSoundEnabled ลง SharedPreferences
Future<void> saveSoundSetting() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_sound_enabled', isSoundEnabled);
    AppLogger.debug('🔊 [Sound] Saved setting: $isSoundEnabled');
  } catch (e) {
    AppLogger.error('❌ [Sound] Failed to save setting: $e');
  }
}

List<String> callerTextToSpeechList = [];
DateTime callerTextToSpeechLastTime = DateTime.now();
String username = "";
List<String> countryNames = ["English", "Thai", "Laos", "Chinese", "Japan", "Korea"];
const String internalCustomerDisplayPageName = "internal_customer_display";
const String selectIpServerPageName = "select_ip_server_page";
const String registerPosTerminalPageName = "register_page";
const String loginByEmployeePageName = "login_by_employee_page";
bool isFullScreen = false;
bool isDemoMode = false;
List<String> countryCodes = ["en", "th", "lo", "zh-cn", "ja", "ko"];
List<String> languageCodes = ["en-US", "th-TH", "lo-LA", "zh-CN", "ja-JP", "ko-KR"];
List<LanguageSystemModel> languageSystemData = [];
List<LanguageSystemCodeModel> languageSystemCode = [];
final Map<String, String> _languageCache = {}; // ⭐ Cache for fast lookup
final Map<String, String> _jsonLanguageCache = {}; // ⭐ Cache for JSON language names
final Map<String, List<LanguageDataModel>> _jsonDecodeCache = {}; // ⭐ Cache for JSON decode
String userScreenLanguage = "th";
bool isInternalCustomerDisplayConnected = false;
var httpClient = http.Client();
late BuildContext globalContext;
bool tableSelected = false;
String tableNumberSelected = "";
late PosHoldProcessModel tableProcessSelected;
void posProcessRefresh = () {};
String last_doc_no = "";
String ipAddress = "";
List<String> errorMessage = [];
List<InformationModel> informationList = <InformationModel>[];
bool initSuccess = false;
List<PosHoldProcessModel> posHoldProcessResult = [];
String posHoldActiveCode = "0";
String orderHoldActiveCode = "0";
//late FlutterTts flutterTts;
bool isPayProcess = false;
String activeCustomerDisplayScreen = "information";
bool isMainShop = false;
String mainShopId = "";
int productCenterType = 0; // 0= ไม่ใช้สินค้ากลาง 1= ใช้สินค้าร้านตัวเองและสินค้ากลาง 2= ไม่ใช้สินค้ากลางและสามารถcopyสินค้ากลางเข้าร้านได้ 3= เหมือน 2 แต่ สามารถเพิ่ม/แก้ไข สินค้าที่ร้านตัวเองและส่งไปยังสินค้ากลาง
int posProductCenterType = 0;
int debtorCenterType = 0;

enum PrintColumnAlign { left, right, center }

ProductCategoryHelper productCategoryHelper = ProductCategoryHelper();
ProductBarcodeHelper productBarcodeHelper = ProductBarcodeHelper();
EmployeeHelper employeeHelper = EmployeeHelper();
CustomerHelper customerHelper = CustomerHelper();
PosLogHelper posLogHelper = PosLogHelper();
BillHelper billHelper = BillHelper();
ShiftHelper shiftHelper = ShiftHelper();
int syncTimeIntervalMaxBySecond = 10;
int syncTimeIntervalSecond = 1;
final moneyFormat = intl.NumberFormat("##,##0.##");
final moneyFormatAndDot = intl.NumberFormat("##,##0.00");
final qtyShortFormat = intl.NumberFormat("##,##0");
String deviceId = "";
String deviceName = "";
List<SyncDeviceModel> customerDisplayDeviceList = [];
List<SyncDeviceModel> posRemoteDeviceList = [];
final kernel32 = DynamicLibrary.open('kernel32.dll');
String webServiceUrl = "http://smltest1.ddnsfree.com:8084";
String webServiceVersion = "/SMLJavaWebService/webresources/rest/";
String providerName = "DATA";
String databaseName = "DEMO"; // "DATA1 or DEMO";
bool speechToTextVisible = true;
bool loginSuccess = false;
late GetStorage appStorage;
List<PrinterLocalStrongDataModel> printerLocalStrongData = [];
bool loginProcess = false;
bool syncDataSuccess = false;
bool syncDataProcess = false;
// PosPayModel payScreenData = PosPayModel();
PayScreenNumberPadWidgetEnum payScreenNumberPadWidget = PayScreenNumberPadWidgetEnum.number;
VoidCallback numberPadCallBack = () {};
late EmployeeObjectBoxStruct? userLogin;
int machineNumber = 1;
String selectTableCode = "";
String selectTableGroup = "";
GlobalKey<PosNumPadState> posNumPadProductWeightGlobalKey = GlobalKey();
bool transDisplayImage = true;
List<ProductCategoryObjectBoxStruct> productCategoryCodeSelected = [];
List<ProductCategoryObjectBoxStruct> productCategoryList = [];
List<ProductBarcodeObjectBoxStruct> productListByCategory = [];
List<ProductCategoryObjectBoxStruct> productCategoryChildList = [];
AppModeEnum appMode = AppModeEnum.posTerminal;
String connectSecureCode = "";
bool apiConnected = false;
String apiUserName = "";
String apiUserPassword = "";
String apiShopID = "";
bool syncRefreshProductCategory = true;
bool syncRefreshProductBarcode = true;
bool syncRefreshPrinter = true;
String syncDateBegin = "2000-01-01T00:00:00";
String syncCategoryTimeName = "lastSyncCategory";
String syncProductBarcodeTimeName = "lastSyncProductBarcode";
String syncInventoryTimeName = "lastSyncInventory";
String syncMemberTimeName = "lastSyncMember";
String syncBankTimeName = "lastSyncBank";
String syncTableTimeName = "lastSyncTable";
String syncBuffetModeTimeName = "lastSyncBuffetMode";
String syncKitchenTimeName = "lastSyncTableZone";
String syncWalletTimeName = "lastSyncWallet";
bool isOnline = true;
String couponCustomerId = "";
PaymentModel? paymentData;
List<PromotionMainModel> promotionMain = [];

// 🎁 Tier Redemption CSV Cache
DateTime? tierCsvLastLoaded;
PromotionMainModel? tierPromotionCache;

late Store objectBoxStore;
WebSocketServer? wsServer; // WebSocket Server instance for KDS communication
bool objectBoxStoreInit = false;
String dateFormatSync = "yyyy-MM-ddTHH:mm:ss";
PosVersionEnum posVersion = PosVersionEnum.restaurant;
bool customerDisplayDesktopMultiScreen = true;
String targetDeviceIpAddress = "";
int targetDeviceIpPort = 4040;
bool targetDeviceConnected = false;
Function? functionPosScreenRefresh;
Function(AppLifecycleState)? handlePrintQueueLifecycle;
VoidCallback? updatePrinterInIsolate; // ⭐ ฟังก์ชันสำหรับอัพเดท printer config ใน isolate
DeviceModeEnum deviceMode = DeviceModeEnum.none;
PosScreenNewDataStyleEnum posScreenNewDataStyle = PosScreenNewDataStyleEnum.addLastLine;
PosTicketObjectBoxStruct posTicket = PosTicketObjectBoxStruct();
bool posUseSaleType = true; // ใช้ประเภทการขายหรือไม่
String posSaleChannelCode = "XXX"; // XXX=หน้า-
String posSaleChannelLogoUrl = "";
List<String> googleLanguageCode = [];
List<PosSaleChannelModel> posSaleChannelList = [];
List<StaffClientObjectBoxStruct> staffClientList = [];
List<BuffetModeObjectBoxStruct> buffetModeLists = [];
int buffetMaxMinute = 120;
String printerConfigCashierCode = "printer_config_cashier";
String printerConfigTicketCode = "printer_config_ticket";
String shopId = "";
String branchId = "";
bool checkOrderFromOnLineActive = false;
bool checkKitchenActive = false;
bool sendTempToServerActive = false;
String posTerminalPinCode = "";
String posTerminalPinTokenId = "";
int shiftAndMoneyMode = 0;
bool useEdc = false; // เชื่อมต่อเครื่อง EDC
bool posScreenAutoRefresh = false;
bool rebuildProductBarcodeStatus = true;
const platform = MethodChannel('com.smlsoft.dedecashier/usb');
String edcProductName = "";
List<dynamic> driversAvailableList = [];
CustomerDisplayQrData customerDisplayQrData = CustomerDisplayQrData(
  ProfileQrPaymentModel(
    guidfixed: '',
    code: '',
    bankcode: '',
    banknames: [],
    bookbankcode: '',
    bookbanknames: [],
    bookbankimages: [],
    isactive: true,
    qrtype: 0,
    qrnames: [],
    qrcode: '',
    logo: '',
    apikey: '',
    accessCode: '',
    bankcharge: '',
    billerCode: '',
    billerID: '',
    closeQr: 0,
    customercharge: '',
    merchantName: '',
    storeID: '',
    terminalID: '',
  ),
  0,
  '',
  '',
  '',
);
String customerDisplayCommand = "";
CustomerDisplayPaySuccessData customerDisplayPaySuccessData = CustomerDisplayPaySuccessData(0, 0, 0, '');

// วิธีการปัดเศษเงินยอดรวม 0=ไม่ปัดเศษ,1=ปัดเศษตามกฏหมาย,2=ปัดเศษขึ้นเป็นจำนวนเต็ม,3=ปัดเศษลงเป็นจำนวนเต็ม
int payTotalMoneyRoundType = 1;
// Step การปัดเศษ ค่าว่าง=จำนวนเต็มอัตโนมัติ,0.25,0.5,0.75
List<MoneyRoundPayModel> payTotalMoneyRoundStep = [
  MoneyRoundPayModel(begin: 0.01, end: 0.12, value: 0),
  MoneyRoundPayModel(begin: 0.13, end: 0.37, value: 0.25),
  MoneyRoundPayModel(begin: 0.38, end: 0.62, value: 0.5),
  MoneyRoundPayModel(begin: 0.63, end: 0.87, value: 0.75),
  MoneyRoundPayModel(begin: 0.88, end: 0.99, value: 1.0),
];

// SoLoud สำหรับเล่นเสียง (fire-and-forget)
SoLoud? _soloud;
bool _soloudInitialized = false;
bool _soundsPreloaded = false; // ⭐ เช็คว่า preload แล้วหรือยัง
final Map<SoundEnum, AudioSource?> _soundSources = {};

/// 🚀 Preload เสียงทั้งหมดตอนเริ่ม app (เรียกใน bootstrap.dart)
///
/// ข้อดี:
/// - ไม่มี delay ตอนเล่นเสียง (โหลดไว้แล้ว)
/// - เล่นเสียงได้ทันทีโดยไม่มีสะดุด
/// - รองรับทุก platform (Windows, Android, iOS)
///
/// การทำงาน:
/// - โหลดเสียงทั้งหมด 34 ไฟล์แบบ background
/// - ใช้เวลาประมาณ 100-300ms (ขึ้นอยู่กับ device)
/// - แสดง progress log ใน debug mode
///
/// ใช้งาน:
/// ```dart
/// await global.preloadAllSounds();
/// ```
Future<void> preloadAllSounds() async {
  if (_soundsPreloaded) {
    AppLogger.success('✅ [Sound] Sounds already preloaded');
    return;
  }

  try {
    AppLogger.debug('🔊 [Sound] Starting preload...');
    final stopwatch = Stopwatch()..start();

    // Initialize SoLoud
    if (!_soloudInitialized) {
      _soloud = SoLoud.instance;
      await _soloud!.init();
      _soloudInitialized = true;
    }

    // โหลดเสียงทั้งหมด
    int loaded = 0;
    int failed = 0;

    for (final sound in SoundEnum.values) {
      try {
        final assetPath = _getSoundAssetPath(sound);
        final source = await _soloud!.loadAsset(assetPath);
        _soundSources[sound] = source;
        loaded++;
      } catch (e) {
        failed++;
        AppLogger.error('⚠️ [Sound] Failed to load ${sound.name}: $e');
      }
    }

    stopwatch.stop();
    _soundsPreloaded = true;

    if (kDebugMode) {
      AppLogger.success('✅ [Sound] Preload complete!');
      AppLogger.debug('✓ Loaded: $loaded sounds');
      if (failed > 0) AppLogger.error('✗ Failed: $failed sounds');
      AppLogger.debug('⏱️ Time: ${stopwatch.elapsedMilliseconds}ms');
    }
  } catch (e) {
    AppLogger.error('❌ [Sound] Preload error: $e');
  }
}

enum PrinterTypeEnum { thermal, dot, laser, inkjet }

enum PrinterConnectEnum { ip, bluetooth, usb, windows, sunmi1 }

enum PosVersionEnum { pos, restaurant, vfpos, smlmobilepos, marinepos }

enum SoundEnum {
  // Existing
  beep,
  fail,
  buttonTing,

  // Phase 1: Critical (ต้องมี!)
  paymentSuccess, // 💰 ชำระเงินสำเร็จ
  newOrder, // 🔔 ออเดอร์ใหม่
  printerError, // 🖨️ เครื่องพิมพ์เสีย
  // Phase 2: Order Management
  orderReady, // ✅ อาหารพร้อม
  orderCancelled, // ❌ ยกเลิก
  kitchenAlert, // 🍳 ครัว
  // Phase 3: QR Payment
  qrScanned, // 📷 สแกน QR
  qrPaymentSuccess, // ✅ QR สำเร็จ
  qrPaymentTimeout, // ⏰ QR หมดอายุ
  // Phase 4: System
  cashDrawerOpen, // 💵 ลิ้นชัก
  networkError, // 🌐 เครือข่าย
  syncComplete, // ♻️ ซิงค์สำเร็จ
  // Phase 5: Customer Display
  customerDisplayConnected,
  itemAdded,
  itemRemoved,

  // Phase 6: NumPad/Calculator
  num0,
  num1,
  num2,
  num3,
  num4,
  num5,
  num6,
  num7,
  num8,
  num9, // 🔢 เสียงตัวเลข 0-9
  numDot, // • จุดทศนิยม
  numpadDelete, // ⌫ กด Backspace
  numpadClear, // 🗑️ กด Clear
  numpadEnter, // ✅ กด Enter/Submit
}

// ⭐ Helper function สำหรับ lazy loading
String _getSoundAssetPath(SoundEnum sound) {
  switch (sound) {
    // Existing
    case SoundEnum.beep:
      return 'assets/audios/scan_success.wav';
    case SoundEnum.fail:
      return 'assets/audios/scan_fail.wav';
    case SoundEnum.buttonTing:
      return 'assets/audios/button_ting.wav';

    // Phase 1: Critical
    case SoundEnum.paymentSuccess:
      return 'assets/audios/transaction/payment_success.wav';
    case SoundEnum.newOrder:
      return 'assets/audios/order/new_order.wav';
    case SoundEnum.printerError:
      return 'assets/audios/system/printer_error.wav';

    // Phase 2: Order
    case SoundEnum.orderReady:
      return 'assets/audios/order/order_ready.wav';
    case SoundEnum.orderCancelled:
      return 'assets/audios/order/order_cancelled.wav';
    case SoundEnum.kitchenAlert:
      return 'assets/audios/order/kitchen_alert.wav';

    // Phase 3: QR Payment
    case SoundEnum.qrScanned:
      return 'assets/audios/payment/qr_scanned.wav';
    case SoundEnum.qrPaymentSuccess:
      return 'assets/audios/payment/qr_success.wav';
    case SoundEnum.qrPaymentTimeout:
      return 'assets/audios/payment/qr_timeout.wav';

    // Phase 4: System
    case SoundEnum.cashDrawerOpen:
      return 'assets/audios/transaction/cash_drawer.wav';
    case SoundEnum.networkError:
      return 'assets/audios/system/network_error.wav';
    case SoundEnum.syncComplete:
      return 'assets/audios/system/sync_complete.wav';

    // Phase 5: Display
    case SoundEnum.customerDisplayConnected:
      return 'assets/audios/display/connected.wav';
    case SoundEnum.itemAdded:
      return 'assets/audios/display/item_added.wav';
    case SoundEnum.itemRemoved:
      return 'assets/audios/display/item_removed.wav';

    // Phase 6: NumPad - Number Sounds (0-9)
    case SoundEnum.num0:
      return 'assets/audios/numpad/0.wav';
    case SoundEnum.num1:
      return 'assets/audios/numpad/1.wav';
    case SoundEnum.num2:
      return 'assets/audios/numpad/2.wav';
    case SoundEnum.num3:
      return 'assets/audios/numpad/3.wav';
    case SoundEnum.num4:
      return 'assets/audios/numpad/4.wav';
    case SoundEnum.num5:
      return 'assets/audios/numpad/5.wav';
    case SoundEnum.num6:
      return 'assets/audios/numpad/6.wav';
    case SoundEnum.num7:
      return 'assets/audios/numpad/7.wav';
    case SoundEnum.num8:
      return 'assets/audios/numpad/8.wav';
    case SoundEnum.num9:
      return 'assets/audios/numpad/9.wav';
    case SoundEnum.numDot:
      return 'assets/audios/numpad/dot.wav';
    case SoundEnum.numpadDelete:
      return 'assets/audios/numpad/delete.wav';
    case SoundEnum.numpadClear:
      return 'assets/audios/numpad/clear.wav';
    case SoundEnum.numpadEnter:
      return 'assets/audios/numpad/enter.wav';
  }
}

enum PosScreenModeEnum { posSale, posReturn }

String formS01 = "S-01"; // ฟอร์มใบสรุปยอด
String formS02 = "S-02"; // ฟอร์มใบเสร็จรับเงิน/ใบกำกับภาษีแบบย่อ
String formS03 = "S-03"; // ฟอร์มใบเสร็จรับเงิน/ใบกำกับภาษีแบบเต็ม
String formS04 = "S-04"; // ฟอร์มใบเสร็จรับเงิน/ใบกำกับภาษีแบบเต็ม
String formReturn = "SLIP005"; // ใบรับคืน

int printerDelayMilliseconds = 200; // รอเครื่องพิมพ์ให้พร้อม Milisecond

enum TableManagerEnum { openTable, closeTable, moveTable, mergeTable, informationTable, splitTable }

enum AppModeEnum {
  // posTerminal = โปรแกรมที่ใช้งานได้เฉพาะเครื่อง POS เท่านั้น
  // posRemote = โปรแกรมที่ใช้งานได้ทุกเครื่อง และสามารถส่งคำสั่งไปยังเครื่อง POS ได้
  posTerminal,
  posRemote,
}

enum PosScreenNewDataStyleEnum {
  // newLineOnly = ขึ้นบรรทัดใหม่เสมอ
  // addLastLine = ถ้า Barcode เดิม ให้เพิ่มในรายการล่าสุด
  // addAllLine = ถ้า Barcode เดิ่ม ให้เพิ่มในรายการทั้งหมด
  newLineOnly,
  addLastLine,
  addAllLine,
}

PrinterConnectEnum printerConnectToEnum(int printerConnect) {
  switch (printerConnect) {
    case 1:
      return PrinterConnectEnum.ip;
    case 2:
      return PrinterConnectEnum.bluetooth;
    case 3:
      return PrinterConnectEnum.usb;
    case 4:
      return PrinterConnectEnum.windows;
    default:
      return PrinterConnectEnum.ip;
  }
}

enum DeviceModeEnum { none, iphone, ipad, windowsDesktop, macosDesktop, linuxDesktop, androidPhone, androidTablet }

int findPosHoldProcessResultIndex(String code) {
  // ⭐ ใช้ indexWhere แทน manual loop
  return posHoldProcessResult.indexWhere((item) => item.code == code);
}

Future<void> loadPrinter() async {
  printerLocalStrongData.clear();
  List<String> printerCodes = [printerConfigCashierCode, printerConfigTicketCode];
  List<String> printerNames = ["Cashier", "Ticket"];
  // Kitchen
  List<KitchenObjectBoxStruct> kitchenList = KitchenHelper().getAll();
  for (var kitchen in kitchenList) {
    printerCodes.add(kitchen.code);
    printerNames.add(getNameFromJsonLanguage(kitchen.names, userScreenLanguage));
  }
  for (var printerCode in printerCodes) {
    try {
      // ดึงข้อมูลจาก Local Storage
      String printerJson = await appStorage.read(printerCode);
      printerLocalStrongData.add(PrinterLocalStrongDataModel.fromJson(await jsonDecode(printerJson)));
    } catch (e) {
      printerLocalStrongData.add(PrinterLocalStrongDataModel(code: printerCode, isReady: false, isConfigConnectSuccess: false, name: printerNames[printerCodes.indexOf(printerCode)]));
    }
  }
}

Future<void> getListOfAvailableDrivers() async {
  try {
    final List<dynamic> drivers = await platform.invokeMethod('listAvailableDrivers');

    driversAvailableList = drivers;
    edcProductName = "";
    if (driversAvailableList.isNotEmpty) {
      connectToDevice(driversAvailableList[0]["productName"]);
    }
    AppLogger.debug("listAvailableDrivers of devices: $drivers");
  } on PlatformException catch (e) {
    edcProductName = "";
    AppLogger.debug("Failed to get drivers: ${e.message}");
  }
}

Future<void> connectToDevice(data) async {
  if (data == "") {
    return;
  }
  try {
    final result = await platform.invokeMethod('connectToDevice', {"productName": data});

    edcProductName = data;
    AppLogger.debug('Connection result: $result');
  } on PlatformException catch (e) {
    edcProductName = "";
    AppLogger.debug('Failed to connect to the device: ${e.message}');
  }
}

int posScreenToInt(PosScreenModeEnum posScreenMode) {
  switch (posScreenMode) {
    case PosScreenModeEnum.posSale:
      return 1;
    case PosScreenModeEnum.posReturn:
      return 2;
  }
}

bool isPhoneDevice() {
  return deviceMode == DeviceModeEnum.iphone || deviceMode == DeviceModeEnum.androidPhone;
}

bool isTabletDevice() {
  return deviceMode == DeviceModeEnum.ipad || deviceMode == DeviceModeEnum.androidTablet || deviceMode == DeviceModeEnum.windowsDesktop || deviceMode == DeviceModeEnum.linuxDesktop || deviceMode == DeviceModeEnum.macosDesktop;
}

Future<void> getDeviceModel(BuildContext context) async {
  final deviceInfo = DeviceInfoPlugin();
  String model = '';

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    model = androidInfo.model;
    var shortestSide = MediaQuery.of(context).size.shortestSide;
    if (shortestSide > 600) {
      deviceMode = DeviceModeEnum.androidTablet;
    } else {
      deviceMode = DeviceModeEnum.androidPhone;
    }
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    model = iosInfo.model;
    model = model.toLowerCase();
    if (model.contains("iphone")) {
      deviceMode = DeviceModeEnum.iphone;
    } else if (model.contains("ipad")) {
      deviceMode = DeviceModeEnum.ipad;
    }
  } else if (Platform.isMacOS) {
    deviceMode = DeviceModeEnum.macosDesktop;
  } else if (Platform.isLinux) {
    deviceMode = DeviceModeEnum.linuxDesktop;
  } else if (Platform.isWindows) {
    deviceMode = DeviceModeEnum.windowsDesktop;
  }
}

String formatDoubleTrailingZero(double value) {
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}

Future<Uint8List> thaiEncode(String word) async {
  if (Platform.isWindows) {
    try {
      if (word == "") {
        word = " ";
      }
      return await CharsetConverter.encode('windows-874', word);
    } catch (e) {
      return await CharsetConverter.encode('windows-874', " ");
    }
  } else {
    return await CharsetConverter.encode('TIS620', word);
  }
}

void playSound({SoundEnum sound = SoundEnum.beep, String word = ""}) async {
  // ⭐ ถ้าปิดเสียง ไม่ต้องทำอะไร
  if (!isSoundEnabled) {
    return;
  }

  // Initialize SoLoud ครั้งแรก (ถ้ายังไม่ได้ init)
  if (!_soloudInitialized) {
    try {
      AppLogger.debug('🔊 [Sound] Initializing SoLoud...');

      _soloud = SoLoud.instance;
      await _soloud!.init();

      _soloudInitialized = true;
      AppLogger.success('✅ [Sound] SoLoud initialized successfully');
    } catch (e) {
      AppLogger.error('❌ [Sound] Init error: $e');
      return;
    }
  }

  // ⭐ ถ้ามีการ preload แล้ว ใช้เสียงที่โหลดไว้เลย (ไม่มี delay)
  // ⭐ ถ้ายังไม่ได้ preload ก็ใช้ lazy loading (โหลดตอนใช้)
  AudioSource? source = _soundSources[sound];
  if (source == null && _soloud != null) {
    try {
      final assetPath = _getSoundAssetPath(sound);
      AppLogger.debug('🔊 [Sound] Lazy loading: $assetPath');
      source = await _soloud!.loadAsset(assetPath);
      _soundSources[sound] = source;
    } catch (e) {
      AppLogger.error('❌ [Sound] Load error: $e');
      return;
    }
  }

  // ⭐ เล่นเสียงแบบ Fire-and-Forget (ไม่รอให้เสียงเล่นจบ)
  if (source != null && _soloud != null) {
    try {
      // ⭐ ไม่ await = ไม่หน่วง UI
      _soloud!
          .play(source)
          .then((handle) {
            if (kDebugMode) {
              // แสดง log เฉพาะตอน debug
              // AppLogger.debug('🔊 [Sound] Playing $sound (handle: $handle)');
            }
          })
          .catchError((e) {
            AppLogger.debug('❌ [Sound] Play error: $e');
          });

      AppLogger.debug('✅ [Sound] Fire-and-forget: $sound');
    } catch (e) {
      AppLogger.error('❌ [Sound] Exception: $e');
    }
  } else {
    AppLogger.debug('⚠️ [Sound] Source not found: $sound');
  }
}

// ฟังก์ชันสำหรับ dispose sound resources
void disposeSoundPlayers() {
  if (_soloud != null) {
    for (var source in _soundSources.values) {
      if (source != null) {
        _soloud!.disposeSource(source);
      }
    }
    _soundSources.clear();
    _soloud!.deinit();
    _soloudInitialized = false;
  }
}

String imageUrl(String guid) {
  return '$webServiceUrl/SMLJavaWebService/webresources/image/$guid?p=$providerName&d=$databaseName';
}

// ⭐ Helper สำหรับ decode JSON ที่มี cache
List<LanguageDataModel> decodeJsonLanguageList(String jsonString) {
  if (jsonString.isEmpty) return [];

  // Check cache
  final cached = _jsonDecodeCache[jsonString];
  if (cached != null) return cached;

  // Decode and cache
  try {
    final decoded = (jsonDecode(jsonString) as List).map((e) => LanguageDataModel.fromJson(e)).toList();
    _jsonDecodeCache[jsonString] = decoded;
    return decoded;
  } catch (e) {
    AppLogger.error('❌ JSON decode error: $e');
    return [];
  }
}

class Debounce {
  final int? milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debounce(this.milliseconds);

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }

    _timer = Timer(Duration(milliseconds: milliseconds!), action);
  }
}

List<String> wordSplit(String word) {
  List<String> split = [];
  String firstBreak = "ใโไเแ";
  String endBreak = "าๆฯะ";

  // ⭐ ใช้ regex แทน loop
  word = word.replaceAllMapped(RegExp('[$firstBreak]'), (match) => ' ${match.group(0)}');
  word = word.replaceAllMapped(RegExp('[$endBreak]'), (match) => '${match.group(0)} ');

  split = word.split(" ");
  return split;
}

double calcTextToNumber(String text) {
  double result = 0;
  String textTrim = text.trim();

  // ⭐ ใช้ regex ครั้งเดียวแทน while loop
  textTrim = textTrim.replaceAll(RegExp(r'\s+'), '');

  if (textTrim.isNotEmpty) {
    textTrim = textTrim.replaceAll("X", "").replaceAll("x", "").replaceAll("+", "").replaceAll("-", "");
    result = double.parse(textTrim);
  }
  return result;
}

// Future<bool> hasNetwork() async {
//   try {
//     final result = await InternetAddress.lookup('example.com');
//     final returnResult = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//     return returnResult;
//   } on SocketException catch (_) {
//     return false;
//   }
// }

Future<bool> hasNetwork({Duration timeoutDuration = const Duration(seconds: 2)}) async {
  try {
    final result = await InternetAddress.lookup('google.com').timeout(timeoutDuration);
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (e) {
    AppLogger.debug("Network check - SocketException: $e");
    return false;
  } on TimeoutException catch (e) {
    AppLogger.debug("Network check - TimeoutException: $e");
    return false;
  }
}

void showAlertDialog({required BuildContext context, required String title, required String message}) {
  Widget okButton = TextButton(
    child: Text(language("OK")),
    onPressed: () {
      Navigator.pop(context);
    },
  );
  AlertDialog alert = AlertDialog(title: Text(title), content: Text(message), actions: [okButton]);
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

Future<void> printQueueStartServer() async {
  var url = "http://$targetDeviceIpAddress:$targetDeviceIpPort";
  var uri = Uri.parse(url);
  try {
    http.Response response = await http
        .post(
          uri,
          headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(HttpPost(command: 'print_queue')),
        )
        .timeout(const Duration(seconds: 2));
    if (response.statusCode == 200) {
      AppLogger.info('Success');
    }
  } catch (e) {
    AppLogger.error('failed : $e');
  }
}

String dateTimeFormatFull(DateTime dateTime, {bool showTime = false}) {
  intl.NumberFormat formatter = intl.NumberFormat("00");
  String day = formatter.format(dateTime.day);
  String month = formatter.format(dateTime.month);
  String year = formatter.format(dateTime.year + 543);
  if (showTime) {
    return "$day/$month/$year ${intl.DateFormat.Hm().format(dateTime)}";
  } else {
    return "$day/$month/$year";
  }
}

String dateTimeFormatShort(DateTime dateTime, {bool showTime = false}) {
  intl.NumberFormat formatter = intl.NumberFormat("00");
  String day = formatter.format(dateTime.day);
  String month = formatter.format(dateTime.month);
  String year = formatter.format(dateTime.year + 543).substring(2, 4);
  if (showTime) {
    return "$day/$month/$year ${intl.DateFormat.Hm().format(dateTime)}";
  } else {
    return "$day/$month/$year";
  }
}

String dateTimeFormatThaiShortMonth2(DateTime dateTime, {bool showTime = false}) {
  const List<String> thaiMonthsShort = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];

  String day = dateTime.day.toString();
  String month = thaiMonthsShort[dateTime.month - 1];
  String year = (dateTime.year + 543).toString().substring(2, 4);

  if (showTime) {
    return "$day $month $year ${intl.DateFormat.Hm().format(dateTime)}";
  } else {
    return "$day $month $year";
  }
}

String dateTimeFormatThaiShortMonth(DateTime dateTime, {bool showTime = false}) {
  // const List<String> thaiMonthsShort = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  const List<String> thaiMonthsShort = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];

  String day = dateTime.day.toString();
  String month = thaiMonthsShort[dateTime.month - 1];
  // String year = (dateTime.year + 543).toString().substring(2, 4);
  String year = (dateTime.year + 543).toString();
  if (showTime) {
    return "$day/$month/$year ${intl.DateFormat.Hm().format(dateTime)}";
  } else {
    return "$day/$month/$year";
  }
}

Future<void> systemProcess() async {
  for (int index = 0; index < customerDisplayDeviceList.length; index++) {
    var url = "${customerDisplayDeviceList[index].ip}:5041";
    SyncDeviceModel info = SyncDeviceModel(deviceId: deviceId, deviceName: deviceName, ip: "", holdCodeActive: "", docModeActive: 0, connected: true, isClient: false, isCashierTerminal: false);
    var jsonData = HttpPost(command: "info", data: jsonEncode(info.toJson()));
    postToServer(
      ip: url,
      jsonData: jsonEncode(jsonData.toJson()),
      callBack: (value) async {
        if (value.isNotEmpty) {
          try {
            SyncDeviceModel getInfo = SyncDeviceModel.fromJson(await jsonDecode(value));
            customerDisplayDeviceList[index].connected = getInfo.connected;
          } catch (e) {
            AppLogger.error(e);
          }
        }
      },
    );
  }
}

Future<void> sendProcessToCustomerDisplay({required String mode}) async {
  for (int index = 0; index < customerDisplayDeviceList.length; index++) {
    if (customerDisplayDeviceList[index].connected) {
      var url = "${customerDisplayDeviceList[index].ip}:5041";
      try {
        var jsonData = HttpPost(command: "process", data: jsonEncode(posHoldProcessResult[findPosHoldProcessResultIndex(posHoldActiveCode)].toJson()));
        AppLogger.info("sendProcessToCustomerDisplay : $url");
        postToServer(ip: url, jsonData: jsonEncode(jsonData.toJson()), callBack: (value) {});
      } catch (e) {
        AppLogger.error("$e : $url");
      }
    }
  }
  if (Platform.isAndroid && isInternalCustomerDisplayConnected == true) {
    displayManager.transferDataToPresentation(<String, dynamic>{
      'posdata': jsonEncode(posHoldProcessResult[findPosHoldProcessResultIndex(posHoldActiveCode)].toJson()),
      'qrdata': jsonEncode(customerDisplayQrData.toJson()),
      'mode': mode,
      'command': customerDisplayCommand,
      'paysuccessdata': jsonEncode(customerDisplayPaySuccessData.toJson()),
      'information': jsonEncode(informationList.map((e) => e.toJson()).toList()),
    });
  }
}

/// ✅ WebSocket ONLY: Send process result to remote devices
/// ใช้ WebSocket broadcast แทน HTTP POST loop
Future<void> sendProcessToRemote() async {
  if (appMode == AppModeEnum.posTerminal) {
    // ✅ WebSocket: Broadcast to all connected remotes
    try {
      for (int index = 0; index < posRemoteDeviceList.length; index++) {
        if (posRemoteDeviceList[index].connected && posRemoteDeviceList[index].holdCodeActive != null) {
          final holdCode = posRemoteDeviceList[index].holdCodeActive!;
          final processResult = posHoldProcessResult[findPosHoldProcessResultIndex(holdCode)];

          // ✅ ส่งผ่าน WebSocket Server เท่านั้น
          WebSocketServer().sendProcessResult(holdCode, processResult.toJson());

          if (kDebugMode) {
            AppLogger.debug('[WebSocket] 📤 Sent process result for $holdCode');
          }
        }
      }
    } catch (e) {
      AppLogger.error("sendProcessToRemote WebSocket error: $e");
    }
  }
}

double calcDiscountFormula({required double totalAmount, required String discountText}) {
  double sumDiscount = 0.0;
  List<String> split = discountText.trim().replaceAll(" ", "").replaceAll(" ", "").split(",");
  for (int index = 0; index < split.length; index++) {
    String discount = split[index];
    double result = 0.0;
    if (discount.contains("%")) {
      // ลด %
      double? percent = double.tryParse(discount.replaceAll("%", ""));
      if (percent != null) {
        result = totalAmount * (percent / 100);
        sumDiscount += result;
        totalAmount -= result;
      }
    } else {
      // ลด จำนวนเงิน
      double? discountMoney = double.tryParse(discount);
      if (discountMoney != null) {
        sumDiscount += discountMoney;
        totalAmount -= discountMoney;
      }
    }
  }
  return sumDiscount;
}

String language(String code) {
  code = code.trim().toLowerCase();

  // ⭐ ใช้ cache O(1) แทน loop O(n)
  final cached = _languageCache[code];
  if (cached != null) {
    return cached;
  }

  // ถ้าไม่มีใน cache ให้หาแบบเดิม (fallback)
  for (int i = 0; i < languageSystemData.length; i++) {
    if (languageSystemData[i].code == code) {
      // เจอแล้ว เก็บใน cache
      _languageCache[code] = languageSystemData[i].text;
      return languageSystemData[i].text;
    }
  }

  AppLogger.debug("language not found : $code");
  return code;
}

Color colorFromHex(String hexColor) {
  if (hexColor.isEmpty) {
    return Colors.white; // Return transparent color if the hexColor is empty
  }
  final hexCode = hexColor.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}

String posScreenListHeightName = "posScreenListHeight";
double posScreenListHeightGet() {
  return appStorage.read(posScreenListHeightName) ?? 1.0;
}

void posScreenListHeightSet(double value) {
  appStorage.write(posScreenListHeightName, value);
}

Future<Uint8List?> loadImageFromUrl(String imageUrl) async {
  try {
    // Fetch the image bytes from the URL
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      // If the request is successful, convert the response body to Uint8List
      return response.bodyBytes;
    } else {
      // If the request is not successful, return null
      AppLogger.debug("Failed to load image: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    // If an error occurs during the request, return null
    AppLogger.error("Error loading image: $e");
    return null;
  }
}

Future<void> loadDeviceConfigFromServer() async {
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  posTerminalPinCode = sharedPreferences.getString('pos_terminal_pin_code') ?? "";
  posTerminalPinTokenId = sharedPreferences.getString('pos_terminal_token') ?? "";
  deviceId = sharedPreferences.getString('pos_device_id') ?? "";
  shiftAndMoneyMode = sharedPreferences.getInt('shift_and_money_mode') ?? 0;

  // ⭐ โหลดค่าเสียง beep
  await loadSoundSetting();

  ApiRepository apiRepository = ApiRepository();
  try {
    // POS Setting
    var value = await apiRepository.getPosSetting(deviceId);
    posConfig = PosConfigModel.fromJson(value.data);
    // ดึง logo
    if (posConfig.logourl.isNotEmpty) {
      // ดึง Logo ร้าน จาก Server มาเก็บไว้ใน Local
      var url = posConfig.logourl;
      var response = await http.get(Uri.parse(url));
      var file = File(getShopLogoPathName());
      await file.writeAsBytes(response.bodyBytes);
      // close the response
    } else {
      // ลบ Logo ร้าน ใน Local ถ้าไม่มี Logo ใน Server
      var file = File(getShopLogoPathName());
      // ⭐ ใช้ async methods แทน sync
      if (await file.exists()) {
        await file.delete();
      }
    }

    /// ดึง config สาขา ตาม guid ในกำหนดรหัสเครื่อง pos
    branchId = posConfig.branch.code;

    AppLogger.debug(posConfig.branch);

    var branchValue = await apiRepository.getProfileBranchByGuid(posConfig);
    posConfig.branch.pos = PosModel.fromJson(branchValue.data['pos']);
    sharedPreferences.setString('posConfig', jsonEncode(posConfig.toJson()));
    sharedPreferences.setString('mediaguid', posConfig.mediaguid);
  } catch (e) {
    AppLogger.error(e);
  }
}

Future<void> loadConfig() async {
  isOnline = await hasNetwork();
  AppLogger.debug("xxx Shop ID : $shopId");
  try {
    if (isOnline) {
      await loadDeviceConfigFromServer();
    } else {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      posConfig = PosConfigModel.fromJson(jsonDecode(sharedPreferences.getString('posConfig') ?? ""));
      branchId = posConfig.branch.code;
    }
  } catch (e) {
    AppLogger.error(e);
  }
  try {
    await loadPrinter();
  } catch (e) {
    AppLogger.error(e);
  }
  try {
    loadFormDesign();
  } catch (e) {
    AppLogger.error(e);
  }
  try {
    if (isOnline) {
      await loadEmployee();
    }
  } catch (e) {
    AppLogger.error(e);
  }
}

Future<void> registerRemoteToTerminal() async {
  if (appMode == AppModeEnum.posRemote) {
    var url = "http://$targetDeviceIpAddress:$targetDeviceIpPort?uuid=${const Uuid().v4()}";
    var uri = Uri.parse(url);
    try {
      SyncDeviceModel sendData = SyncDeviceModel(deviceId: "XXX", deviceName: "XXX", ip: ipAddress, holdCodeActive: posHoldActiveCode, docModeActive: 0, connected: true, isCashierTerminal: false, isClient: true);
      var jsonEncodeStr = jsonEncode(sendData.toJson());
      await http.post(uri, headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'}, body: jsonEncode(<String, String>{'command': 'register_remote_device', 'data': jsonEncodeStr})).timeout(const Duration(seconds: 1)).then((response) {});
    } catch (e) {
      AppLogger.error('failed to register remote device : $e');
    }
  }
}

Future<void> startLoading() async {
  DartPingIOS.register();

  // ⭐ NOTE: System Process และ Sync Master ถูกย้ายไป SystemProcess Isolate แล้ว
  // ดูใน bootstrap.dart -> _systemProcessIsolateWorker()
  // - Timer 10s: Sync Master Counter
  // - Timer 15s: systemProcess(), registerRemoteToTerminal(), compareBarcodeStatus()
  // เหตุผล: ป้องกัน main thread blocking

  initSuccess = true;
}

/// สร้าง Process Result ตามจำนวน Hold บิล
void loadPosHoldProcess() {
  // สร้างรายการพักบิล
  for (int loop = 0; loop < 50; loop++) {
    posHoldProcessResult.add(PosHoldProcessModel(code: loop.toString()));
    posLogHelper.holdCount(posHoldProcessResult[loop].code).then((value) {
      posHoldProcessResult[loop].logCount = value;
    });
  }
  // load Table (ร้านอาหาร)
  var datas = objectBoxStore.box<TableProcessObjectBoxStruct>().getAll();
  for (var data in datas) {
    int findIndex = findPosHoldProcessResultIndex("T-${data.number}");
    if (findIndex != -1) {
      posHoldProcessResult[findIndex].code = data.number;
      posHoldProcessResult[findIndex].customerCode = data.customer_code_or_telephone;
      posHoldProcessResult[findIndex].customerName = data.customer_name;
      posHoldProcessResult[findIndex].customerPhone = data.customer_code_or_telephone;
      posHoldProcessResult[findIndex].holdType = 2;
      posHoldProcessResult[findIndex].tableNumber = data.number;
      posHoldProcessResult[findIndex].isDelivery = data.is_delivery;
    } else {
      posHoldProcessResult.add(
        PosHoldProcessModel(code: "T-${data.number}", customerCode: data.customer_code_or_telephone, customerName: data.customer_name, customerPhone: data.customer_code_or_telephone, holdType: 2, tableNumber: data.number, isDelivery: data.is_delivery),
      );
    }
  }
}

/// ⚠️ DEPRECATED: Use WebSocket instead
/// This function is kept for backward compatibility only
@Deprecated('Use WebSocket Client/Server instead. Will be removed in next version.')
Future<String> getFromServer({required String json}) async {
  throw UnimplementedError(
    '❌ HTTP getFromServer() is deprecated. Use WebSocket Client instead.\n'
    'See: lib/api/network/websocket_client.dart',
  );
}

/// ⚠️ DEPRECATED: Use WebSocket instead
/// This function is kept for backward compatibility only
@Deprecated('Use WebSocket Client/Server instead. Will be removed in next version.')
Future<void> postToServer({required String ip, required String jsonData, required Function callBack}) async {
  throw UnimplementedError(
    '❌ HTTP postToServer() is deprecated. Use WebSocket Client instead.\n'
    'See: lib/api/network/websocket_client.dart',
  );
}

/// ⚠️ DEPRECATED: Use WebSocket instead
/// This function is kept for backward compatibility only
@Deprecated('Use WebSocket Client/Server instead. Will be removed in next version.')
Future<String> postToServerAndWait({required String ip, required String jsonData}) async {
  throw UnimplementedError(
    '❌ HTTP postToServerAndWait() is deprecated. Use WebSocket Client instead.\n'
    'See: lib/api/network/websocket_client.dart',
  );
}

Future<String> getIpAddress() async {
  // Get a list of the network interfaces available on the device
  List<NetworkInterface> interfaces = await NetworkInterface.list();

  // Iterate through the list of interfaces and return the first non-loopback IPv4 address
  for (NetworkInterface interface in interfaces) {
    if (interface.name == 'lo') continue; // Skip the loopback interface
    for (InternetAddress address in interface.addresses) {
      if (address.type == InternetAddressType.IPv4) {
        return address.address;
      }
    }
  }

  // If no non-loopback IPv4 address was found, return null
  return "";
}

Future scanServerById(String name) async {
  AppLogger.debug('🔍 [Scan] Starting network scan for: $name');

  List<SyncDeviceModel> ipList = [];
  String ipAddress = await getIpAddress();
  String subNet = ipAddress.substring(0, ipAddress.lastIndexOf("."));

  for (int i = 1; i < 255; i++) {
    String ip = "$subNet.$i";
    ipList.add(SyncDeviceModel(deviceId: "", deviceName: "", ip: ip, holdCodeActive: "", docModeActive: 0, connected: false, isClient: false, isCashierTerminal: false));
  }

  int countTread = 0;
  int maxAttempts = 100; // ❌ Limit attempts (แทน infinite loop)
  int attemptCount = 0;
  bool loopScan = true;

  while (loopScan && attemptCount < maxAttempts) {
    attemptCount++;

    // ❌ ไม่ await = ไม่ block UI (ignore future)
    Future.delayed(const Duration(seconds: 1)); // ignore: unawaited_futures

    for (int index = 0; index < ipList.length; index++) {
      if (!ipList[index].connected) {
        if (countTread < 10) {
          countTread++;
          String url = "http://${ipList[index].ip}:$targetDeviceIpPort/scan?uuid=${const Uuid().v4()}";

          try {
            // ❌ Fire-and-forget (ไม่ block)
            http
                .post(Uri.parse(url))
                .timeout(const Duration(seconds: 1))
                .then((result) async {
                  countTread--;
                  if (result.statusCode == 200) {
                    if (result.body.isNotEmpty) {
                      serviceLocator<Log>().debug("Connected to ${ipList[index].ip}");
                      SyncDeviceModel server = SyncDeviceModel.fromJson(await jsonDecode(result.body));
                      if (server.deviceId == name && server.isCashierTerminal!) {
                        ipList[index].connected = true;
                        loopScan = false;
                        targetDeviceIpAddress = ipList[index].ip;
                        targetDeviceConnected = true;
                        AppLogger.debug('✅ [Scan] Found server at ${ipList[index].ip}');
                      }
                    }
                  }
                })
                .onError((error, stackTrace) {
                  countTread--;
                })
                .catchError((error) {
                  countTread--;
                });
          } catch (e) {
            AppLogger.debug("Network scan error: $e");
            countTread--;
          }
        } else {
          // ❌ ไม่ await = ไม่ block (ignore future)
          Future.delayed(const Duration(milliseconds: 100)); // ignore: unawaited_futures
        }
      }
    }

    // ❌ Short delay แทน 1 วินาที
    await Future.delayed(const Duration(milliseconds: 100));
  }

  AppLogger.debug('🔍 [Scan] Scan completed after $attemptCount attempts');
}

bool isTabletScreen() {
  return (deviceMode == DeviceModeEnum.androidTablet || deviceMode == DeviceModeEnum.ipad);
}

bool isDesktopScreen() {
  return (deviceMode == DeviceModeEnum.macosDesktop || deviceMode == DeviceModeEnum.linuxDesktop || deviceMode == DeviceModeEnum.windowsDesktop);
}

String syncFindLastUpdate(List<SyncMasterStatusModel> dataList, String tableName) {
  for (var item in dataList) {
    if (item.tableName == tableName) {
      return intl.DateFormat(dateFormatSync).format(DateTime.parse(item.lastUpdate));
    }
  }
  return intl.DateFormat(dateFormatSync).format(DateTime.parse(syncDateBegin));
}

Future<void> testPrinterConnect() async {
  AppLogger.debug("Testing printer connections...");

  for (int i = 0; i < printerLocalStrongData.length; i++) {
    PrinterLocalStrongDataModel printer = printerLocalStrongData[i];

    AppLogger.debug("Testing printer ${i + 1}: ${printer.name} (${printer.deviceName})");

    try {
      switch (printer.printerConnectType) {
        case PrinterConnectEnum.ip:
          await testIpPrinter(printer, i);
          break;

        case PrinterConnectEnum.bluetooth:
          await testBluetoothPrinter(printer, i);
          break;

        case PrinterConnectEnum.usb:
          await testUsbPrinter(printer, i);
          break;

        case PrinterConnectEnum.windows:
          await testWindowsPrinter(printer, i);
          break;

        case PrinterConnectEnum.sunmi1:
          // TODO: Implement Sunmi printer test
          printerLocalStrongData[i].isReady = false;
          printerLocalStrongData[i].isConfigConnectSuccess = false;
          break;
      }
    } catch (e) {
      AppLogger.error("Error testing printer ${printer.name}: $e");
      printerLocalStrongData[i].isReady = false;
      printerLocalStrongData[i].isConfigConnectSuccess = false;
    }
  }

  AppLogger.debug("Printer connection test completed");
}

Future<void> testIpPrinter(PrinterLocalStrongDataModel printer, int index) async {
  try {
    // ⭐ เช็คว่า IP ถูกต้องก่อน test
    if (printer.ipAddress.isEmpty || printer.ipPort <= 0) {
      printerLocalStrongData[index].isReady = false;
      printerLocalStrongData[index].isConfigConnectSuccess = false;
      return;
    }

    // ⭐ ตรวจสอบว่า IP address valid หรือไม่
    final ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipPattern.hasMatch(printer.ipAddress)) {
      printerLocalStrongData[index].isReady = false;
      printerLocalStrongData[index].isConfigConnectSuccess = false;
      return;
    }

    final Socket socket = await Socket.connect(printer.ipAddress, printer.ipPort, timeout: const Duration(seconds: 3));

    // ส่งคำสั่งทดสอบ (ESC/POS status command)
    const List<int> statusCommand = [0x10, 0x04, 0x01]; // DLE EOT n
    socket.add(statusCommand);

    // ⭐ ใช้ Completer แทน hard-coded delay
    final Completer<bool> responseCompleter = Completer<bool>();

    socket.listen(
      (data) {
        if (!responseCompleter.isCompleted) {
          if (data.isNotEmpty) {
            // ตรวจสอบสถานะเครื่องพิมพ์
            if (data[0] == 22) {
              // Printer ready
              printerLocalStrongData[index].isReady = true;
              printerLocalStrongData[index].isPaperOut = false;
              printerLocalStrongData[index].isConfigConnectSuccess = true;
            } else if (data[0] == 30) {
              // Paper out
              printerLocalStrongData[index].isReady = false;
              printerLocalStrongData[index].isPaperOut = true;
              printerLocalStrongData[index].isConfigConnectSuccess = true;
            } else {
              printerLocalStrongData[index].isReady = false;
              printerLocalStrongData[index].isPaperOut = false;
              printerLocalStrongData[index].isConfigConnectSuccess = true;
            }
          }
          responseCompleter.complete(true);
        }
        socket.close();
      },
      onError: (error) {
        if (!responseCompleter.isCompleted) {
          printerLocalStrongData[index].isReady = false;
          printerLocalStrongData[index].isConfigConnectSuccess = false;
          responseCompleter.complete(false);
        }
        socket.close();
      },
      onDone: () {
        if (!responseCompleter.isCompleted) {
          // ถ้าไม่ได้รับ response แต่เชื่อมต่อได้ ถือว่าเครื่องพิมพ์พร้อมใช้งาน
          printerLocalStrongData[index].isReady = true;
          printerLocalStrongData[index].isConfigConnectSuccess = true;
          responseCompleter.complete(true);
        }
      },
    );

    // ⭐ รอ response หรือ timeout (แต่ไม่ block UI)
    await responseCompleter.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        // ถ้า timeout แต่เชื่อมต่อได้ ถือว่าพร้อม
        if (!responseCompleter.isCompleted) {
          printerLocalStrongData[index].isReady = true;
          printerLocalStrongData[index].isConfigConnectSuccess = true;
        }
        socket.close();
        return true;
      },
    );
  } catch (e) {
    printerLocalStrongData[index].isReady = false;
    printerLocalStrongData[index].isConfigConnectSuccess = false;
    // ⭐ ใช้ debug แทน error เพราะไม่ใช่ critical error
    if (kDebugMode) {
      AppLogger.debug("IP printer test failed (${printer.ipAddress}:${printer.ipPort}): $e");
    }
  }
}

Future<void> testBluetoothPrinter(PrinterLocalStrongDataModel printer, int index) async {
  try {
    FlutterThermalPrinter thermalPrinter = FlutterThermalPrinter.instance;

    Printer testPrinter = Printer(address: printer.ipAddress, name: printer.deviceName, vendorId: printer.vendorId, productId: printer.productId, connectionType: ConnectionType.BLE, isConnected: false);

    // ลองเชื่อมต่อ
    await thermalPrinter.connect(testPrinter);
    await Future.delayed(const Duration(milliseconds: 500));

    // ถ้าเชื่อมต่อได้ ถือว่าเครื่องพิมพ์พร้อมใช้งาน
    printerLocalStrongData[index].isReady = true;
    printerLocalStrongData[index].isConfigConnectSuccess = true;

    // ตัดการเชื่อมต่อ
    await thermalPrinter.disconnect(testPrinter);
  } catch (e) {
    printerLocalStrongData[index].isReady = false;
    printerLocalStrongData[index].isConfigConnectSuccess = false;
    AppLogger.debug("Bluetooth printer test failed: $e");
  }
}

Future<void> testUsbPrinter(PrinterLocalStrongDataModel printer, int index) async {
  try {
    FlutterThermalPrinter thermalPrinter = FlutterThermalPrinter.instance;

    await thermalPrinter.getPrinters(connectionTypes: [ConnectionType.USB]);
    Printer testPrinter = Printer(address: printer.ipAddress, name: printer.deviceName, vendorId: printer.vendorId, productId: printer.productId, connectionType: ConnectionType.USB, isConnected: false);

    // ลองเชื่อมต่อ
    await thermalPrinter.connect(testPrinter);
    await Future.delayed(const Duration(milliseconds: 500));

    // ถ้าเชื่อมต่อได้ ถือว่าเครื่องพิมพ์พร้อมใช้งาน
    printerLocalStrongData[index].isReady = true;
    printerLocalStrongData[index].isConfigConnectSuccess = true;

    // ตัดการเชื่อมต่อ
    await thermalPrinter.disconnect(testPrinter);
  } catch (e) {
    printerLocalStrongData[index].isReady = false;
    printerLocalStrongData[index].isConfigConnectSuccess = false;
    AppLogger.debug("USB printer test failed: $e");
  }
}

Future<void> testWindowsPrinter(PrinterLocalStrongDataModel printer, int index) async {
  try {
    String printerName = printer.deviceName;

    // เช็คว่าเครื่องพิมพ์มีอยู่ในระบบ Windows หรือไม่
    List<PrinterDeviceModel> windowsPrinters = windowsListPrinters();
    bool printerExists = windowsPrinters.any((p) => p.deviceName == printerName);

    if (printerExists) {
      printerLocalStrongData[index].isReady = true;
      printerLocalStrongData[index].isConfigConnectSuccess = true;

      AppLogger.debug("Windows printer '$printerName' is available");
    } else {
      printerLocalStrongData[index].isReady = false;
      printerLocalStrongData[index].isConfigConnectSuccess = false;

      AppLogger.debug("Windows printer '$printerName' not found");
    }
  } catch (e) {
    printerLocalStrongData[index].isReady = false;
    printerLocalStrongData[index].isConfigConnectSuccess = false;
    AppLogger.debug("Windows printer test failed: $e");
  }
}

int printerWidthByCharacter(int printerIndex) {
  if (printerLocalStrongData[printerIndex].paperType == 1) {
    return 32;
  } else {
    return 48;
  }
}

double printerWidthByPixel(PrinterLocalStrongDataModel printerData) {
  if (printerData.paperType == 1) {
    return 384;
  } else {
    return 576;
  }
}

String findLanguageFromCountryCode(String code, String countryCode) {
  for (int i = 0; i < languageSystemCode.length; i++) {
    if (languageSystemCode[i].code == code) {
      for (int j = 0; j < languageSystemCode[i].langs.length; j++) {
        if (languageSystemCode[i].langs[j].code == countryCode) {
          return languageSystemCode[i].langs[j].text;
        }
      }
    }
  }
  return code;
}

void languageSelect(String languageCode) {
  languageSystemData = [];
  _languageCache.clear(); // ⭐ Clear cache when language changes

  for (int i = 0; i < languageSystemCode.length; i++) {
    for (int j = 0; j < languageSystemCode[i].langs.length; j++) {
      if (languageSystemCode[i].langs[j].code == userScreenLanguage) {
        final code = languageSystemCode[i].code.trim();
        final text = languageSystemCode[i].langs[j].text.trim();

        languageSystemData.add(LanguageSystemModel(code: code, text: text));

        // ⭐ Build cache immediately
        _languageCache[code.toLowerCase()] = text;
      }
    }
  }
  languageSystemData.sort((a, b) {
    return a.code.compareTo(b.code);
  });
}

int findBuffetModeIndex(String code) {
  // ⭐ ใช้ indexWhere แทน loop + indexOf
  return buffetModeLists.indexWhere((item) => item.code == code);
}

Future<void> sendProcessToServer(String orderId) async {
  // คำนวณรายละเอียดโต๊ะ
  AppLogger.debug("************ sendProcessToServer : $orderId");
  PosProcessModel posProcess = await PosProcess().process(holdCode: "T-$orderId", docMode: 1, detailDiscountFormula: "", discountFormula: "", cashRoundAmount: true, discountFoodOnly: true);
  // ส่งข้อมูลโต๊ะ ที่คำนวณแล้ว
  List<PosProcessDetailClickHouseServerModel> posProcessDetail = [];
  for (var detail in posProcess.details) {
    // ⭐ ใช้ helper function ที่มี cache แทน jsonDecode ตรงๆ
    List<LanguageDataModel> detailItemNames = decodeJsonLanguageList(detail.item_name);
    List<LanguageDataModel> detailUnitNames = decodeJsonLanguageList(detail.unit_name);

    List<PosProcessDetailExtraClickHouseModel> extra = [];
    for (var extraItem in detail.extra) {
      // ⭐ ใช้ helper function ที่มี cache
      List<LanguageDataModel> extraItemNames = decodeJsonLanguageList(extraItem.item_name);
      List<LanguageDataModel> extraUnitNames = decodeJsonLanguageList(extraItem.unit_name);

      extra.add(
        PosProcessDetailExtraClickHouseModel(
          total_amount: extraItem.total_amount,
          barcode: extraItem.barcode,
          qty: extraItem.qty,
          price: extraItem.price,
          index: extraItem.index,
          item_code: extraItem.item_code,
          is_except_vat: extraItem.is_except_vat,
          is_void: extraItem.is_void,
          item_name: extraItemNames,
          unit_code: extraItem.unit_code,
          unit_name: extraUnitNames,
          vat_type: extraItem.vat_type,
          price_exclude_vat: extraItem.price_exclude_vat,
          price_exclude_vat_type: extraItem.price_exclude_vat_type,
          guid_auto_fixed: extraItem.guid_auto_fixed,
          guid_category: extraItem.guid_category,
          guid_code_or_ref: extraItem.guid_code_or_ref,
          qty_fixed: extraItem.qty_fixed,
        ),
      );
    }

    posProcessDetail.add(
      PosProcessDetailClickHouseServerModel(
        total_amount: detail.total_amount,
        total_amount_with_extra: detail.total_amount_with_extra,
        guid: detail.guid,
        barcode: detail.barcode,
        qty: detail.qty,
        price: detail.price,
        index: detail.index,
        item_code: detail.item_code,
        image_url: detail.image_url,
        is_except_vat: detail.is_except_vat,
        is_void: detail.is_void,
        item_name: detailItemNames,
        unit_code: detail.unit_code,
        unit_name: detailUnitNames,
        vat_type: detail.vat_type,
        price_exclude_vat: detail.price_exclude_vat,
        price_exclude_vat_type: detail.price_exclude_vat_type,
        price_original: detail.price_original,
        discount: detail.discount,
        discount_text: detail.discount_text,
        remark: detail.remark,
        extra: extra,
        food_type: detail.food_type,
      ),
    );
  }

  PosProcessClickHouseServerModel posProcessClone = PosProcessClickHouseServerModel(
    details: posProcessDetail,
    total_alcohol_amount: posProcess.total_alcohol_amount,
    total_amount: posProcess.total_amount,
    total_amount_pay: posProcess.total_amount_pay,
    total_cheque_amount: posProcess.total_cheque_amount,
    total_credit_amount: posProcess.total_credit_amount,
    total_coupon_amount: posProcess.total_coupon_amount,
    total_credit_card_amount: posProcess.total_credit_card_amount,
    total_discount_except_vat_amount: posProcess.total_discount_except_vat_amount,
    total_discount_from_promotion: posProcess.total_discount_from_promotion,
    total_discount_vat_amount: posProcess.total_discount_vat_amount,
    total_drink_amount: posProcess.total_drink_amount,
    total_food_amount: posProcess.total_food_amount,
    total_item_except_vat_amount: posProcess.total_item_except_vat_amount,
    total_item_vat_amount: posProcess.total_item_vat_amount,
    total_other_amount: posProcess.total_other_amount,
    total_piece: posProcess.total_piece,
    total_piece_except_vat: posProcess.total_piece_except_vat,
    total_piece_vat: posProcess.total_piece_vat,
    total_qr_code_amount: posProcess.total_qr_code_amount,
    total_transfer_amount: posProcess.total_transfer_amount,
    total_vat_amount: posProcess.total_vat_amount,
    vat_type: posProcess.vat_type,
    vat_rate: posProcess.vat_rate,
    detail_total_amount_before_discount: posProcess.detail_total_amount_before_discount,
    detail_total_discount: posProcess.detail_total_discount,
    amount_after_calc_vat: posProcess.amount_after_calc_vat,
    amount_before_calc_vat: posProcess.amount_before_calc_vat,
    amount_except_vat: posProcess.amount_except_vat,
    cash_round_amount: posProcess.cash_round_amount,
    qr_code: posProcess.qr_code,
    is_vat_register: posProcess.is_vat_register,
    detail_discount_formula: posProcess.detail_discount_formula,
  );
  // ลบรายละเอียดโต๊ะ
  await api.clickHouseExecute("alter table dedetemp.jsoninfo delete where shopid='$shopId' and code='$orderId' and jsoncode=3 and posid = '${posConfig.code}' ");
  if (orderId.isNotEmpty) {
    // เพิ่มรายละเอียดโต๊ะ (เปิด,รอคิดเงิน)
    await api.clickHouseExecute("insert into dedetemp.jsoninfo (branch,shopid,code,jsoncode,jsondata,posid) values ('${posConfig.branch.guidfixed}','$shopId','$orderId',3,'${jsonEncode(posProcessClone.toJson())}','${posConfig.code}')");
  }
}

/// ส่งข้อมูล Temp ขึ้น Server เพื่อแสดงสถานะ
List<SendTableInfoModel> sendTempToServerLastTableCheck = [];
List<SendTableInfoModel> sendTempToServerLastOrderTempCheck = [];
List<SendTableInfoModel> sendTableInfoList = [];

Future<void> sendTempToServer() async {
  sendTempToServerActive = true;
  try {
    // สถานะโต๊ะ
    var tableProcessData = objectBoxStore.box<TableProcessObjectBoxStruct>().getAll();
    for (var item in tableProcessData) {
      String tableNumber = item.number;
      List<LanguageDataModel> names = item.names != "" ? (await jsonDecode(item.names) as List).map((e) => LanguageDataModel.fromJson(e)).toList() : [];

      TableProcessClickHouseServerStruct cloneItem = TableProcessClickHouseServerStruct(
        names: names,
        guidfixed: item.guidfixed,
        number_main: item.number_main,
        make_food_immediately: item.make_food_immediately,
        order_success: item.order_success,
        amount: item.amount,
        table_al_la_crate_mode: item.table_al_la_crate_mode,
        customer_address: item.customer_address,
        buffet_code: item.buffet_code,
        open_by_staff_code: item.open_by_staff_code,
        child_count: item.child_count,
        qr_code: item.qr_code,
        man_count: item.man_count,
        delivery_send_success: item.delivery_send_success,
        delivery_send_success_datetime: item.delivery_send_success_datetime,
        delivery_status: item.delivery_status,
        delivery_cook_success: item.delivery_cook_success,
        delivery_cook_success_datetime: item.delivery_cook_success_datetime,
        number: item.number,
        customer_code_or_telephone: item.customer_code_or_telephone,
        customer_name: item.customer_name,
        is_delivery: item.is_delivery,
        zone: item.zone,
        delivery_code: item.delivery_code,
        delivery_number: item.delivery_number,
        delivery_ticket_number: item.delivery_ticket_number,
        detail_discount_formula: item.detail_discount_formula,
        table_open_datetime: item.table_open_datetime,
        order_count: item.order_count,
        woman_count: item.woman_count,
        table_child_count: item.table_child_count,
        remark: item.remark,
        table_status: item.table_status,
      );
      String jsonStr = jsonEncode(cloneItem);
      bool isFound = false;
      int index = -1;
      for (var item in sendTempToServerLastTableCheck) {
        if (item.code == tableNumber) {
          isFound = true;
          index = sendTempToServerLastTableCheck.indexOf(item);
          break;
        }
      }
      if (!isFound) {
        sendTempToServerLastTableCheck.add(SendTableInfoModel(code: tableNumber, jsonData: ""));
        index = sendTempToServerLastTableCheck.length - 1;
      }
      if (sendTempToServerLastTableCheck[index].jsonData != jsonStr) {
        sendTempToServerLastTableCheck[index].jsonData = jsonStr;
        // ลบรายละเอียดโต๊ะ
        await api.clickHouseExecute("alter table dedetemp.jsoninfo delete where shopid='$shopId' and code='$tableNumber' and jsoncode=1 and posid = '${posConfig.code}' ");
        if (item.table_status == 1 || item.table_status == 2) {
          if (tableNumber.isNotEmpty) {
            // เพิ่มรายละเอียดโต๊ะ (เปิด,รอคิดเงิน)
            await api.clickHouseExecute("insert into dedetemp.jsoninfo (branch,shopid,code,jsoncode,jsondata,posid) values ('${posConfig.branch.guidfixed}','$shopId','$tableNumber',1,'$jsonStr','${posConfig.code}')");
          }
        }
      }
    }

    List<String> tableOpenNumberList = [];
    for (var item in tableProcessData) {
      if (item.table_status == 1 || item.table_status == 2) {
        tableOpenNumberList.add(item.number);
      }
    }
    for (var tableOpenNumber in tableOpenNumberList) {
      // รายละเอียด Order
      List<OrderTempClickHouseServerStruct> orderTempList = [];
      var orderTempData = objectBoxStore.box<OrderTempObjectBoxStruct>().query(OrderTempObjectBoxStruct_.orderId.equals(tableOpenNumber).and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))).build().find();
      for (var orderTemp in orderTempData) {
        List<LanguageDataModel> itemNames = orderTemp.names != "" ? (await jsonDecode(orderTemp.names) as List).map((e) => LanguageDataModel.fromJson(e)).toList() : [];
        List<LanguageDataModel> unitNames = orderTemp.unitName != "" ? (await jsonDecode(orderTemp.unitName) as List).map((e) => LanguageDataModel.fromJson(e)).toList() : [];
        List<OrderProductOptionClickHouseServerModel> optionSelected = orderTemp.optionSelected != "" ? (await jsonDecode(orderTemp.optionSelected) as List).map((e) => OrderProductOptionClickHouseServerModel.fromJson(e)).toList() : [];

        orderTempList.add(
          OrderTempClickHouseServerStruct(
            id: orderTemp.id,
            orderId: orderTemp.orderId,
            orderIdMain: orderTemp.orderIdMain,
            orderGuid: orderTemp.orderGuid,
            machineId: orderTemp.machineId,
            orderDateTime: orderTemp.orderDateTime,
            barcode: orderTemp.barcode,
            qty: orderTemp.orderQty - orderTemp.cancelQty,
            price: orderTemp.price,
            amount: orderTemp.amount,
            isOrder: orderTemp.isOrder,
            isPaySuccess: orderTemp.isPaySuccess,
            optionSelected: optionSelected,
            remark: orderTemp.remark,
            names: itemNames,
            takeAway: orderTemp.takeAway,
            unitCode: orderTemp.unitCode,
            unitName: unitNames,
            imageUri: orderTemp.imageUri,
            kdsSuccessTime: orderTemp.kdsSuccessTime,
            kdsSuccess: orderTemp.kdsSuccess,
            isOrderSuccess: orderTemp.isOrderSuccess,
            isOrderSendKdsSuccess: orderTemp.isOrderSendKdsSuccess,
            kdsId: orderTemp.kdsId,
            cancelQty: orderTemp.cancelQty,
            orderQty: orderTemp.orderQty,
            deliveryNumber: orderTemp.deliveryNumber,
            deliveryCode: orderTemp.deliveryCode,
            isOrderReadySendKds: orderTemp.isOrderReadySendKds,
            deliveryName: orderTemp.deliveryName,
            lastUpdateDateTime: orderTemp.lastUpdateDateTime,
            orderEmployeeCode: orderTemp.orderEmployeeCode,
            orderEmployeeDetail: orderTemp.orderEmployeeDetail,
            orderType: orderTemp.orderType,
            servedSuccess: orderTemp.servedSuccess,
            servedQty: orderTemp.servedQty,
            servedTime: orderTemp.servedTime,
          ),
        );
      }
      String orderTempJson = jsonEncode(orderTempList);
      // Compare
      bool isFound = false;
      int index = -1;
      for (var item in sendTableInfoList) {
        if (item.code == tableOpenNumber) {
          isFound = true;
          index = sendTableInfoList.indexOf(item);
          break;
        }
      }
      if (!isFound) {
        sendTableInfoList.add(SendTableInfoModel(code: tableOpenNumber, jsonData: ""));
        index = sendTableInfoList.length - 1;
      }
      if (sendTableInfoList[index].jsonData != orderTempJson) {
        sendTableInfoList[index].jsonData = orderTempJson;
        if (tableOpenNumber.isNotEmpty) {
          // ลบรายละเอียด Order
          await api.clickHouseExecute("alter table dedetemp.jsoninfo delete where shopid='$shopId' and code='$tableOpenNumber' and jsoncode=2 and posid = '${posConfig.code}'");
          // เพิ่มรายละเอียด Order
          await api.clickHouseExecute("insert into dedetemp.jsoninfo (branch,shopid,code,jsoncode,jsondata,posid) values ('${posConfig.branch.guidfixed}','$shopId','$tableOpenNumber',2,'$orderTempJson','${posConfig.code}')");
        }
      }
    }
  } catch (e) {
    AppLogger.error(e);
  }
  sendTempToServerActive = false;
}

/// ตรวจสอบ Order จากเครื่องลูกค้า สั่งเอง
Future<void> checkOrderOnline() async {
  checkOrderFromOnLineActive = true;
  {
    try {
      // ดึง Order ลูกค้าสั่งเอง (แยกตาม machineid)
      List<String> orderNumberList = [];
      String selectOrderGroupByOrderNumber = "select ordernumber from dedeorderonline.ordertemp where shopid='$shopId' and isclose=1 group by ordernumber";
      var valueselectOrderGroupByOrderNumber = await api.clickHouseSelect(selectOrderGroupByOrderNumber);
      if (valueselectOrderGroupByOrderNumber.isNotEmpty) {
        ResponseDataModel responseData = ResponseDataModel.fromJson(valueselectOrderGroupByOrderNumber);
        for (var orderNumber in responseData.data) {
          orderNumberList.add(orderNumber["ordernumber"].toString().trim());
        }
      }
      for (var orderNumber in orderNumberList) {
        String selectOrderTempQuery =
            "select orderid,orderguid,barcode,qty,qtylastcancel,optionselected,remark,remarkforcancel,orderdatetime,istakeaway,price,amount,tablenumber from dedeorderonline.ordertemp where shopid='$shopId' and isclose=1  and ordernumber='$orderNumber' order by orderdatetime";
        var value = await api.clickHouseSelect(selectOrderTempQuery);
        if (value.isNotEmpty) {
          List<OrderTempDataModel> orderTemp = [];
          List<OrderTempObjectBoxStruct> orderSave = [];
          ResponseDataModel responseData = ResponseDataModel.fromJson(value);
          // Print
          String orderId = "";
          bool updateOrder = false;
          for (var order in responseData.data) {
            orderId = order["orderid"].toString().trim();
            OrderTempDataModel orderData = OrderTempDataModel(
              orderId: orderId,
              orderGuid: order["orderguid"],
              barcode: order["barcode"],
              qty: double.tryParse(order["qty"].toString()) ?? 0,
              qtyLastCancel: double.tryParse(order["qtylastcancel"].toString()) ?? 0,
              optionSelected: order["optionselected"],
              remark: order["remark"],
              remarkForCancel: order["remarkforcancel"],
              orderDateTime: DateTime.parse(order["orderdatetime"]),
              price: double.tryParse(order["price"].toString()) ?? 0,
              amount: double.tryParse(order["amount"].toString()) ?? 0,
              orderType: 1,
              orderEmployeeCode: "SELFORDER",
              orderEmployeeDetail: "ลูกค้าสั่งเอง",
              isTakeAway: order["istakeaway"],
            );
            orderTemp.add(orderData);
            ProductBarcodeObjectBoxStruct? productBarcode = await ProductBarcodeHelper().selectByBarcodeFirst(orderData.barcode);
            orderSave.add(
              OrderTempObjectBoxStruct(
                id: 0,
                guidPos: "xxxxxx",
                orderId: orderData.orderId,
                orderIdMain: orderData.orderId,
                orderGuid: orderData.orderGuid,
                docNo: "",
                machineId: "",
                orderDateTime: orderData.orderDateTime,
                barcode: orderData.barcode,
                qtyLastCancel: orderData.qtyLastCancel,
                price: orderData.price,
                amount: orderData.amount,
                isOrder: false,
                isPaySuccess: false,
                issumpoint: productBarcode?.issumpoint ?? false,
                optionSelected: orderData.optionSelected,
                remark: orderData.remark,
                remarkForCancel: orderData.remarkForCancel,
                names: productBarcode?.names ?? "",
                takeAway: (orderData.isTakeAway == 1) ? true : false,
                unitCode: productBarcode?.unit_code ?? "",
                unitName: productBarcode?.unit_names ?? "",
                imageUri: productBarcode?.images_url ?? "",
                kdsSuccessTime: DateTime.now(),
                kdsSuccess: false,
                isOrderSuccess: true,
                isOrderSendKdsSuccess: false,
                kdsId: "",
                orderHistory: "",
                cancelQty: 0,
                cancelHistory: "",
                orderQty: orderData.qty,
                deliveryNumber: "",
                deliveryCode: "",
                isOrderReadySendKds: true,
                deliveryName: "",
                lastUpdateDateTime: DateTime.now(),
                servedSuccess: false,
                servedQty: 0,
                servedHistory: "",
                servedTime: DateTime.now(),
                orderEmployeeCode: orderData.orderEmployeeCode,
                orderEmployeeDetail: orderData.orderEmployeeDetail,
                orderType: 1,
                isOrderSendDedeTempSuccess: false,
              ),
            );
            // พิมพ์แยกใบ
            // await sendOrderToKitchen(orderId: orderId, orderList: orderTemp);
            updateOrder = true;
            orderTemp.clear();
          }
          if (orderTemp.isNotEmpty) {
            /*await sendOrderToKitchen(
              orderId: orderId, tableNumber: tableNumber, orderList: orderTemp);*/
            updateOrder = true;
          }
          if (updateOrder) {
            // update สถานะ ว่า ส่งไปที่ครัวแล้ว
            String updateQuery = "alter table dedeorderonline.ordertemp update isclose=2 where shopid='$shopId' and orderid='$orderId' and ordernumber='$orderNumber'";
            await api.clickHouseExecute(updateQuery);
          }
          // save to objectbox
          objectBoxStore.box<OrderTempObjectBoxStruct>().putMany(orderSave, mode: PutMode.insert);

          if (orderId.isNotEmpty) {
            // คำนวณยอดใหม่
            await orderSumAndUpdateTable(orderId);
            await saveOrderToHoldBill([orderId]);
            // ส่งไปที่ server
            await sendProcessToServer(orderId);
          }
        }
      }
    } catch (e) {
      AppLogger.error(e.toString());
    }
    // save to holdbill
  }
  checkOrderFromOnLineActive = false;
}

/// จากเครื่อง Staff สั่ง
Future<void> checkOrderFromStaff() async {
  {
    // Order Staff สั่งมา
    List<String> orderIdList = [];
    try {
      // update isOrderSuccess และคำนวนณยอดรวม
      final getData = objectBoxStore.box<OrderTempObjectBoxStruct>().query(OrderTempObjectBoxStruct_.isOrder.equals(false).and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false)).and(OrderTempObjectBoxStruct_.isOrderSuccess.equals(false))).build().find();
      for (var data in getData) {
        if (!orderIdList.contains(data.orderId)) {
          orderIdList.add(data.orderId);
        }
      }

      for (var orderId in orderIdList) {
        var orderTempUpdate = objectBoxStore
            .box<OrderTempObjectBoxStruct>()
            .query(OrderTempObjectBoxStruct_.orderId.equals(orderId).and(OrderTempObjectBoxStruct_.isOrder.equals(false)).and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false)).and(OrderTempObjectBoxStruct_.isOrderSuccess.equals(false)))
            .build()
            .find();
        for (var data in orderTempUpdate) {
          // ปรับปรุง ว่าส่ง order แล้ว จะได้ไม่วนกลับมาสร้างใหม่
          data.isOrderSuccess = true;
          // ถือว่ายังไม่ส่งครัว รอ Step ถัดไป
          data.isOrderSendKdsSuccess = false;
        }
        objectBoxStore.box<OrderTempObjectBoxStruct>().putMany(orderTempUpdate, mode: PutMode.update);
        // คำนวณ
        await orderSumAndUpdateTable(orderId);
      }
      await saveOrderToHoldBill(orderIdList);
    } catch (e) {
      AppLogger.error(e.toString());
    }
  }
}

Future<void> checkKitchenOrder() async {
  checkKitchenActive = true;
  try {
    // ประมวลผลส่งครัว
    List<String> orderIdList = [];

    /// ถ้า isOrderReadySendKds = true คือ ส่ง Order ได้เลย
    /// ถ้า isOrderSendKdsSuccess = false คือ ยังไม่ส่ง Order
    /// ถ้า isOrderSuccess = true คือ ส่ง Order ไปรายการคิดเงินแล้ว
    final getDataOrderId = objectBoxStore
        .box<OrderTempObjectBoxStruct>()
        .query(
          OrderTempObjectBoxStruct_.isOrder
              .equals(false)
              .and(OrderTempObjectBoxStruct_.isOrderReadySendKds.equals(true))
              .and(OrderTempObjectBoxStruct_.isOrderSendKdsSuccess.equals(false))
              .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
              .and(OrderTempObjectBoxStruct_.isOrderSuccess.equals(true)),
        )
        .build()
        .find();
    for (var data in getDataOrderId) {
      if (!orderIdList.contains(data.orderId)) {
        orderIdList.add(data.orderId);
      }
    }
    {
      // พิมพ์ใบสั่งครัว
      for (var orderId in orderIdList) {
        // รายการสรุปยอด
        List<OrderTempDataModel> orderSummeryTemp = [];
        // เลือกรายการ Order ทีละโต๊ะ พิมพ์
        List<OrderTempDataModel> orderTemp = [];
        List<OrderTempObjectBoxStruct> getData = objectBoxStore
            .box<OrderTempObjectBoxStruct>()
            .query(
              OrderTempObjectBoxStruct_.orderId
                  .equals(orderId)
                  .and(
                    OrderTempObjectBoxStruct_.isOrder
                        .equals(false)
                        .and(OrderTempObjectBoxStruct_.isOrderReadySendKds.equals(true))
                        .and(OrderTempObjectBoxStruct_.isOrderSendKdsSuccess.equals(false))
                        .and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))
                        .and(OrderTempObjectBoxStruct_.isOrderSuccess.equals(true)),
                  ),
            )
            .build()
            .find();
        for (var data in getData) {
          var xdata = OrderTempDataModel(
            orderGuid: data.orderGuid,
            barcode: data.barcode,
            qty: data.orderQty - data.cancelQty,
            qtyLastCancel: data.qtyLastCancel,
            optionSelected: data.optionSelected,
            remark: data.remark,
            remarkForCancel: data.remarkForCancel,
            orderId: data.orderId,
            orderDateTime: data.orderDateTime,
            price: data.price,
            amount: data.amount,
            orderType: data.orderType,
            orderEmployeeCode: data.orderEmployeeCode,
            orderEmployeeDetail: data.orderEmployeeDetail,
            isTakeAway: (data.takeAway) ? 1 : 0,
          );
          orderTemp.add(xdata);
          orderSummeryTemp.add(xdata);
          // update สถานะ
          data.isOrderSendKdsSuccess = true;
          objectBoxStore.box<OrderTempObjectBoxStruct>().put(data, mode: PutMode.update);
        }
        // พิมพ์แยกใบ พร้อม update KDS ว่าส่ง order แล้ว
        await sendOrderToKitchen(orderId: orderId, orderList: orderTemp);
        // พิมพ์ใบสรุป
        await printOrderSummery(orderId: orderId, orderList: orderSummeryTemp, bottomWord: "หน้าร้าน", printerIndex: -1);
      }
    }
  } catch (e) {
    AppLogger.error(e.toString());
  }
  checkKitchenActive = false;
}

String getNameFromJsonLanguage(String jsonNames, String languageCode) {
  // ⭐ ใช้ cache key = jsonNames + languageCode
  final cacheKey = '$jsonNames|$languageCode';
  final cached = _jsonLanguageCache[cacheKey];
  if (cached != null) {
    return cached;
  }

  try {
    List<LanguageDataModel> names = (jsonDecode(jsonNames) as List).map<LanguageDataModel>((item) {
      return LanguageDataModel.fromJson(item);
    }).toList();
    for (var item in names) {
      if (item.code == languageCode) {
        final result = item.name.trim();
        // ⭐ เก็บใน cache
        _jsonLanguageCache[cacheKey] = result;
        return result;
      }
    }
  } catch (e) {
    AppLogger.debug("Intentionally ignored: `$e");
  }

  // Cache fallback value too
  _jsonLanguageCache[cacheKey] = jsonNames;
  return jsonNames;
}

String getNameFromLanguage(List<LanguageDataModel> names, String languageCode) {
  for (var item in names) {
    if (item.code == languageCode) {
      return item.name;
    }
  }
  return "*";
}

double getProductPrice(String prices, int keyNumber) {
  List<PriceDataModel> priceList = jsonDecode(prices).map<PriceDataModel>((item) {
    return PriceDataModel.fromJson(item);
  }).toList();
  double price = 0.0;
  for (var item in priceList) {
    if (item.keynumber == keyNumber) {
      price = item.price;
    }
  }
  if (price == 0.0) {
    // ถ้าไม่พบ ให้ใช้ราคาตามลำดับแรก
    if (priceList.isNotEmpty) {
      price = priceList.firstWhere((item) => item.keynumber == 1, orElse: () => PriceDataModel(keynumber: 1, price: 0.0)).price;
    }
  }

  return price;
}

Future<void> orderSumAndUpdateTable(String tableNumber) async {
  double orderCount = 0;
  double orderCancelCount = 0;
  double orderServedCount = 0;
  double amount = 0.0;
  {
    // รวมจาก OrderTemp ส่งรายการแล้ว
    final result = objectBoxStore.box<OrderTempObjectBoxStruct>().query(OrderTempObjectBoxStruct_.orderId.equals(tableNumber).and(OrderTempObjectBoxStruct_.isOrder.equals(false)).and(OrderTempObjectBoxStruct_.isPaySuccess.equals(false))).build().find();
    for (var order in result) {
      AppLogger.debug("order ${order.orderId} order : ${order.orderQty - order.cancelQty} amount : ${order.amount}");
      // update กลับ
      double calcAmount = await orderCalcSumAmount(order);
      if (order.amount != calcAmount) {
        order.amount = calcAmount;
        objectBoxStore.box<OrderTempObjectBoxStruct>().put(order, mode: PutMode.update);
      }
      orderCount += (order.orderQty - order.cancelQty);
      orderCancelCount += order.cancelQty;
      orderServedCount += order.servedQty;
      amount += calcAmount;
    }
  }
  {
    final boxTable = objectBoxStore.box<TableProcessObjectBoxStruct>();
    final resultTable = boxTable.query(TableProcessObjectBoxStruct_.number.equals(tableNumber)).build().findFirst();
    if (resultTable != null) {
      AppLogger.debug("xxxx ${resultTable.number} order : $orderCount amount : $amount");
      resultTable.order_count = orderCount;
      resultTable.order_cancel_count = orderCancelCount;
      resultTable.order_served_count = orderServedCount;
      resultTable.amount = amount;
      boxTable.put(resultTable, mode: PutMode.update);
    }
  }
  {
    // สร้าง Hold Bill สำหรับระบบ POS
    final boxTable = objectBoxStore.box<TableProcessObjectBoxStruct>();
    final resultTable = boxTable.query(TableProcessObjectBoxStruct_.number.equals(tableNumber)).build().find();
    // เพิ่มกรณีไม่มี
    for (var table in resultTable) {
      int foundHoldIndex = -1;
      for (var hold in posHoldProcessResult) {
        if (hold.holdType == 2) {
          if (hold.tableNumber == table.number) {
            foundHoldIndex = posHoldProcessResult.indexOf(hold);
            break;
          }
        }
      }
      if (foundHoldIndex == -1) {
        posHoldProcessResult.add(PosHoldProcessModel(code: "T-${table.number}", tableNumber: table.number, holdType: 2, isDelivery: table.is_delivery, deliveryNumber: table.delivery_number));
      } else {}
    }
  }
}

String generateRandomPin(int pinLength) {
  String pin = "";
  var rnd = Random();
  for (var i = 0; i < pinLength; i++) {
    pin += rnd.nextInt(10).toString();
  }
  return pin;
}

// =====================================================================
// Profile Management Functions - Refactored for better maintainability
// =====================================================================

/// Initialize and load profile settings
Future<void> getProfile() async {
  try {
    AppLogger.debug("🔄 Starting profile initialization...");

    // Initialize core dependencies
    await _initializeCoreDependencies();

    // Load profile based on connectivity
    if (isOnline) {
      await _loadProfileOnline();
    } else {
      await _loadProfileOffline();
    }

    // Apply profile settings to global variables
    _applyProfileSettings();

    AppLogger.success("✅ Profile loaded successfully");
  } catch (e, stackTrace) {
    if (kDebugMode) {
      AppLogger.error('❌ Error loading profile: $e');
      AppLogger.debug('Stack trace: $stackTrace');
    }
    // Try to load from local cache as fallback
    await _loadProfileOffline();
  }
}

/// Initialize core dependencies and check connectivity
Future<void> _initializeCoreDependencies() async {
  isOnline = await hasNetwork();
  objectBoxInit();

  AppLogger.debug("🌐 Network status: ${isOnline ? 'Online' : 'Offline'}");
}

/// Load profile when online - fetch from server and cache locally
Future<void> _loadProfileOnline() async {
  const String profileName = "profilex";
  final apiRepository = ApiRepository();
  final sharedPreferences = await SharedPreferences.getInstance();

  try {
    // Fetch profile from server
    final valueProfileShop = await apiRepository.getProfileShop();
    shopId = valueProfileShop.data["guidfixed"];

    if (kDebugMode) {
      AppLogger.debug('📥 Profile data received from server');
      AppLogger.debug('Shop ID: $shopId');
    }

    // Build profile model from server data
    profileSetting = await _buildProfileFromServerData(valueProfileShop, apiRepository);

    // Check if mainshopid is not empty and fetch center settings
    if (profileSetting.company.mainshopid.isNotEmpty) {
      try {
        AppLogger.debug("🏢 Fetching center settings for mainshopid: ${profileSetting.company.mainshopid}");

        final centerSettingsResponse = await apiRepository.getCenterSetting(profileSetting.company.mainshopid);

        if (centerSettingsResponse.success && centerSettingsResponse.data != null) {
          profileSetting.center = ProfileCenterModel.fromJson(centerSettingsResponse.data);

          if (kDebugMode) {
            AppLogger.success('✅ Center settings loaded successfully');
            AppLogger.debug('Center Name: ${profileSetting.center.name1}');
          }
        }
      } catch (e) {
        AppLogger.error("⚠️ Error loading center settings: $e");
        // Continue without center settings if there's an error
      }
    }

    // Cache profile locally
    await _cacheProfileLocally(profileName, sharedPreferences);

    // Download and cache logo if available
    await _downloadAndCacheLogo();
  } catch (e) {
    AppLogger.error("⚠️ Error loading online profile: $e");
    // Fallback to cached version
    await _loadCachedProfile(profileName, sharedPreferences);
  }
}

/// Load profile when offline - use cached data
Future<void> _loadProfileOffline() async {
  const String profileName = "profilex";
  final sharedPreferences = await SharedPreferences.getInstance();

  AppLogger.debug("💾 Loading profile from local cache");

  // Load device settings from preferences
  _loadDeviceSettings(sharedPreferences);

  // Load cached profile
  await _loadCachedProfile(profileName, sharedPreferences);
}

/// Build ProfileSettingModel from server response data
Future<ProfileSettingModel> _buildProfileFromServerData(ApiResponse valueProfileShop, ApiRepository apiRepository) async {
  // Build company model
  final company = ProfileSettingCompanyModel(
    names: (valueProfileShop.data["names"] as List?)?.map<LanguageDataModel>((item) => LanguageDataModel.fromJson(item)).toList() ?? [],
    taxID: valueProfileShop.data["taxID"] ?? "",
    branchNames: [],
    addresses: [],
    phones: [],
    emailOwners: [],
    emailStaffs: [],
    latitude: valueProfileShop.data["latitude"] ?? "",
    longitude: valueProfileShop.data["longitude"] ?? "",
    usebranch: valueProfileShop.data["usebranch"] ?? false,
    usedepartment: valueProfileShop.data["usedepartment"] ?? false,
    images: [],
    logo: valueProfileShop.data["logo"] ?? "",
    ismainshop: valueProfileShop.data["ismainshop"] ?? false,
    productcentertype: valueProfileShop.data["productcentertype"] ?? 0,
    posproductcentertype: valueProfileShop.data["posproductcentertype"] ?? 0,
    debtorcentertype: valueProfileShop.data["debtorcentertype"] ?? 0,
    mainshopid: valueProfileShop.data["mainshopid"] ?? "",
  );

  // Build config system model
  final configSystem = ProfileSettingConfigSystemModel(
    vatrate: valueProfileShop.data["vatrate"] ?? 0,
    vattypesale: valueProfileShop.data["vattypesale"] ?? 0,
    vattypepurchase: valueProfileShop.data["vattypepurchase"] ?? 0,
    inquirytypesale: valueProfileShop.data["inquirytypesale"] ?? 0,
    inquirytypepurchase: valueProfileShop.data["inquirytypepurchase"] ?? 0,
    headerreceiptpos: valueProfileShop.data["headerreceiptpos"] ?? "",
    footerreciptpos: valueProfileShop.data["footerreciptpos"] ?? "",
  );

  // Fetch branch data
  final branchValue = await apiRepository.getProfileSBranch();
  final branchs = List<ProfileSettingBranchModel>.from(branchValue.data.map((e) => ProfileSettingBranchModel.fromJson(e)));

  return ProfileSettingModel(company: company, languagelist: valueProfileShop.data["languagelist"] ?? <String>[], configsystem: configSystem, branch: branchs);
}

/// Cache profile data locally
Future<void> _cacheProfileLocally(String profileName, SharedPreferences sharedPreferences) async {
  try {
    await appStorage.write(profileName, profileSetting.toJson());
    sharedPreferences.setString(profileName, jsonEncode(profileSetting.toJson()));

    AppLogger.debug("💾 Profile cached locally");
  } catch (e) {
    AppLogger.error("⚠️ Error caching profile: $e");
  }
}

/// Download and cache company logo
Future<void> _downloadAndCacheLogo() async {
  try {
    final logoUrl = profileSetting.company.logo;
    final logoFile = File(getShopLogoPathName());

    if (logoUrl != null && logoUrl.isNotEmpty) {
      AppLogger.debug("📸 Downloading company logo...");

      final response = await http.get(Uri.parse(logoUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await logoFile.writeAsBytes(response.bodyBytes);
        AppLogger.success("✅ Logo downloaded and cached");
      }
    } else {
      // Remove existing logo if no logo URL
      if (logoFile.existsSync()) {
        await logoFile.delete();
        AppLogger.debug("🗑️ Removed existing logo file");
      }
    }
  } catch (e) {
    AppLogger.error("⚠️ Error downloading logo: $e");
  }
}

/// Load device-specific settings from shared preferences
void _loadDeviceSettings(SharedPreferences sharedPreferences) {
  posTerminalPinCode = sharedPreferences.getString('pos_terminal_pin_code') ?? "";
  posTerminalPinTokenId = sharedPreferences.getString('pos_terminal_token') ?? "";
  deviceId = sharedPreferences.getString('pos_device_id') ?? "";
  shiftAndMoneyMode = sharedPreferences.getInt('shift_and_money_mode') ?? 0;

  if (kDebugMode) {
    AppLogger.debug('📱 Device settings loaded:');
    AppLogger.debug("  - Device ID: ${deviceId.isNotEmpty ? deviceId : 'Not set'}");
    AppLogger.debug("  - PIN Code: ${posTerminalPinCode.isNotEmpty ? '***' : 'Not set'}");
  }
}

/// Load cached profile from local storage
Future<void> _loadCachedProfile(String profileName, SharedPreferences sharedPreferences) async {
  try {
    String? profileJson = sharedPreferences.getString(profileName);
    if (profileJson != null) {
      profileSetting = ProfileSettingModel.fromJson(jsonDecode(profileJson));
      AppLogger.success("✅ Loaded profile from cache");
    } else {
      AppLogger.warning("⚠️ No cached profile found");
      // Initialize with empty profile
      _initializeEmptyProfile();
    }
  } catch (e) {
    AppLogger.error("❌ Error loading cached profile: $e");
    _initializeEmptyProfile();
  }
}

/// Initialize empty profile as fallback
void _initializeEmptyProfile() {
  profileSetting = ProfileSettingModel(
    company: ProfileSettingCompanyModel(
      names: [],
      taxID: "",
      branchNames: [],
      addresses: [],
      phones: [],
      emailOwners: [],
      emailStaffs: [],
      latitude: "",
      longitude: "",
      usebranch: false,
      usedepartment: false,
      images: [],
      logo: "",
      ismainshop: false,
      productcentertype: 0,
      posproductcentertype: 0,
      debtorcentertype: 0,
      mainshopid: "",
    ),
    languagelist: [],
    configsystem: ProfileSettingConfigSystemModel(vatrate: 0, vattypesale: 0, vattypepurchase: 0, inquirytypesale: 0, inquirytypepurchase: 0, headerreceiptpos: "", footerreciptpos: ""),
    branch: [],
  );
  AppLogger.debug("🔧 Initialized empty profile");
}

/// Apply profile settings to global variables
void _applyProfileSettings() {
  if (profileSetting.company.mainshopid.isNotEmpty) {
    mainShopId = profileSetting.company.mainshopid;
    isMainShop = profileSetting.company.ismainshop;
    productCenterType = profileSetting.center.productcentertype;
    posProductCenterType = profileSetting.center.posproductcentertype;
    debtorCenterType = profileSetting.center.debtorcentertype;

    if (kDebugMode) {
      AppLogger.debug('🏪 Applied profile settings:');
      AppLogger.debug('- Main Shop ID: $mainShopId');
      AppLogger.debug('- Is Main Shop: $isMainShop');
      AppLogger.debug('- Product Center Type: $productCenterType');
      AppLogger.debug('- POS Product Center Type: $posProductCenterType');
      AppLogger.debug('- Debtor Center Type: $debtorCenterType');
    }
  }
}

Future<void> loadEmployee() async {
  try {
    ApiRepository apiRepository = ApiRepository();
    var value = await apiRepository.getEmployeeList();
    List<EmployeeModel> employeeList = (value.data as List).map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>)).toList();
    if (employeeList.isEmpty) {
      AppLogger.debug("No employee data found from server.");
    } else {
      employeeHelper.deleteAll();
      List<EmployeeObjectBoxStruct> employeeObjectBoxList = [];
      for (var data in employeeList) {
        employeeObjectBoxList.add(EmployeeObjectBoxStruct(guidfixed: data.guidfixed, code: data.code, name: data.name, email: data.email, is_enabled: data.isenabled, is_use_pos: data.isusepos, pin_code: data.pincode, profile_picture: data.profilepicture));
      }
      employeeHelper.insertMany(employeeObjectBoxList);
    }
  } catch (e) {
    AppLogger.error(e);
  }
}

Future<void> loadWalletProvider() async {
  try {
    ApiRepository apiRepository = ApiRepository();
    var value = await apiRepository.getEmployeeList();
    List<WalletModel> walletList = (value.data as List).map((e) => WalletModel.fromJson(e as Map<String, dynamic>)).toList();
    if (walletList.isEmpty) {
      AppLogger.debug("No wallet provider data found from server.");
    } else {
      List<WalletObjectBoxStruct> walletObjectBoxList = [];
      for (var data in walletList) {
        walletObjectBoxList.add(
          WalletObjectBoxStruct(
            code: data.code,
            guid_fixed: const Uuid().v4(),
            bookbankcode: data.bookbankcode,
            bookbankname: jsonEncode(data.names),
            countrycode: "th",
            feerate: 0,
            names: jsonEncode(data.names),
            paymentcode: "",
            paymentlogo: data.paymentlogo,
            paymenttype: data.paymenttype,
            wallettype: data.wallettype,
          ),
        );
      }
      objectBoxStore.box<WalletObjectBoxStruct>().putMany(walletObjectBoxList);
    }
  } catch (e) {
    AppLogger.error(e);
  }
}

String findBankLogo(String code) {
  BankObjectBoxStruct? bankDataList = BankHelper().selectByCode(code: code);
  if (bankDataList != null) {
    return bankDataList.logo;
  }
  return "";
}

double paperWidth(int paperType) {
  switch (paperType) {
    case 1: // 58
      return 378;
    case 2: // 80
      return 575;
    default:
      return 575;
  }
}

String getShopLogoPathName() {
  return "${applicationDocumentsDirectory.path}/logo.png";
}

String qrCodeOrderOnline(String qrCode) {
  return "https://dedefoodorder.web.app/?q=$qrCode&openExternalBrowser=1";
}

Future<Directory> createPath(String mainPath, DateTime docDate) async {
  final directory = await getApplicationDocumentsDirectory();

  // Create a new directory for the main path
  final mainDirectory = Directory('${directory.path}/$mainPath');
  if (!await mainDirectory.exists()) {
    await mainDirectory.create();
  }

  // Create a new directory for the shopId (no date folder)
  final shopDirectory = Directory('${directory.path}/$mainPath/$shopId');
  if (!await shopDirectory.exists()) {
    await shopDirectory.create();
  }

  return shopDirectory;
}

Future<io.Directory> createMainPath(String mainPath) async {
  final directory = await getApplicationDocumentsDirectory();

  // Create a new directory for the main path
  final mainDirectory = io.Directory('${directory.path}/$mainPath');
  if (!await mainDirectory.exists()) {
    await mainDirectory.create();
  }

  return mainDirectory;
}

int findFormByCode(String code) {
  for (var i = 0; i < formDesignList.length; i++) {
    if (formDesignList[i].code == code) {
      return i;
    }
  }
  return -1;
}

String getPosFormCodeByCode(String code) {
  for (var i = 0; i < posConfig.slips.length; i++) {
    if (posConfig.slips[i].code == code) {
      return posConfig.slips[i].formcode;
    }
  }
  return "";
}

String getPosFormHeaderNameByCode(String code) {
  for (var i = 0; i < posConfig.slips.length; i++) {
    if (posConfig.slips[i].code == code) {
      return jsonEncode(posConfig.slips[i].headernames);
    }
  }
  return "[{}]";
}

double roundDouble(double value, int places) {
  num mod = pow(10.0, places);
  return ((value * mod).round().toDouble() / mod);
}

double roundDoubleDown(double value, int precision) {
  final divideBy = pow(10, precision);
  return ((value * divideBy).floorToDouble() / divideBy);
}

double roundMoneyForPay(double value) {
  double result = value;
  if (payTotalMoneyRoundStep.isEmpty) {
    // ถ้าเป็นค่าว่าง ให้ปัดจำนวนเต็มอัตโนมัติ
    result = roundDouble(value, 0);
  } else {
    value = roundDouble(value, 2);
    double calcRound = roundDouble(value - value.floorToDouble(), 2);
    for (int index = 0; index < payTotalMoneyRoundStep.length; index++) {
      if (calcRound >= payTotalMoneyRoundStep[index].begin && calcRound <= payTotalMoneyRoundStep[index].end) {
        result = roundDoubleDown(value, 0) + payTotalMoneyRoundStep[index].value;
        break;
      }
    }
  }
  return result;
}

Widget iconStatus(String pngFileName, bool status) {
  return SizedBox(
    width: 30,
    height: 24,
    child: Stack(
      children: [
        Image.asset("assets/images/$pngFileName.png"),
        Positioned(
          bottom: 0,
          right: 5,
          child: Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              color: (status) ? Colors.greenAccent : Colors.redAccent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1), // changes position of shadow
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

List<PrinterDeviceModel> windowsListPrinters() {
  final pcbNeeded = calloc<DWORD>();
  final pcReturned = calloc<DWORD>();
  List<PrinterDeviceModel> printerNames = [];

  // First, call EnumPrinters to get the buffer size needed
  EnumPrinters(PRINTER_ENUM_LOCAL, nullptr, 2, nullptr, 0, pcbNeeded, pcReturned);

  final bufferSize = pcbNeeded.value;
  if (bufferSize > 0) {
    final pPrinterEnum = calloc<Uint8>(bufferSize);

    // Call EnumPrinters again with the correct buffer size
    if (EnumPrinters(PRINTER_ENUM_LOCAL, nullptr, 2, pPrinterEnum, bufferSize, pcbNeeded, pcReturned) != 0) {
      final int count = pcReturned.value;
      final printerInfoPtr = pPrinterEnum.cast<PRINTER_INFO_2>();

      for (int i = 0; i < count; i++) {
        final printerInfo = printerInfoPtr[i];
        printerNames.add(
          PrinterDeviceModel(
            fullName: printerInfo.pPrinterName.toDartString(),
            productName: printerInfo.pPrinterName.toDartString(),
            deviceId: printerInfo.pPrinterName.toDartString(),
            deviceName: printerInfo.pPrinterName.toDartString(),
            manufacturer: printerInfo.pDriverName.toDartString(),
            vendorId: printerInfo.pDriverName.toDartString(),
            productId: printerInfo.pDriverName.toDartString(),
            ipAddress: printerInfo.pDriverName.toDartString(),
            ipPort: 9100,
            connectType: PrinterConnectEnum.windows,
            printerType: PrinterTypeEnum.thermal,
            paperSize: 0,
          ),
        );
      }
    }

    calloc.free(pPrinterEnum);
  }

  calloc.free(pcbNeeded);
  calloc.free(pcReturned);

  return printerNames;
}

void windowsPrintRawData(String printerName, List<int> data, String pathName) {
  // รอ 1 วิ
  Future.delayed(const Duration(seconds: 1));
  final pPrinterName = TEXT(printerName);
  final pDocName = TEXT("My Document");
  final pDatatype = TEXT("RAW");

  final phPrinter = calloc<HANDLE>();
  final pDocInfo = calloc<DOC_INFO_1>()
    ..ref.pDocName = pDocName
    ..ref.pOutputFile = nullptr
    ..ref.pDatatype = pDatatype;

  // Open a handle to the printer
  if (OpenPrinter(pPrinterName, phPrinter, nullptr) == 0) {
    AppLogger.debug('Error: Unable to open printer');
    return;
  }

  // Start a document
  if (StartDocPrinter(phPrinter.value, 1, pDocInfo) == 0) {
    AppLogger.debug('Error: Unable to start document');
    ClosePrinter(phPrinter.value);
    return;
  }

  // Start a page
  if (StartPagePrinter(phPrinter.value) == 0) {
    AppLogger.debug('Error: Unable to start page');
    EndDocPrinter(phPrinter.value);
    ClosePrinter(phPrinter.value);
    return;
  }

  // Write the data
  final pData = calloc<Uint8>(data.length);
  for (int i = 0; i < data.length; i++) {
    pData[i] = data[i];
  }
  final pWritten = calloc<DWORD>();

  if (WritePrinter(phPrinter.value, pData, data.length, pWritten) == 0) {
    AppLogger.debug('Error: Unable to write data to printer');
  }

  // End the page and document
  EndPagePrinter(phPrinter.value);
  EndDocPrinter(phPrinter.value);

  // Close the printer
  Future.delayed(const Duration(seconds: 1));
  ClosePrinter(phPrinter.value);

  // Free allocated memory
  calloc.free(pPrinterName);
  calloc.free(pDocName);
  calloc.free(pDatatype);
  calloc.free(phPrinter);
  calloc.free(pDocInfo);
  calloc.free(pData);
  calloc.free(pWritten);
  if (pathName.isNotEmpty) {
    deleteFile(pathName);
  }
}

Future<void> openCashDrawerWindows(String printerName) async {
  AppLogger.debug('Opening cash drawer for Windows printer: $printerName');

  try {
    // Method 1: Direct Windows API approach (original method)
    final pPrinterName = TEXT(printerName);
    final phPrinter = calloc<HANDLE>();

    // Open a handle to the printer
    if (OpenPrinter(pPrinterName, phPrinter, nullptr) != 0) {
      AppLogger.debug('Printer opened successfully via Windows API: $printerName');

      // Try multiple ESC/POS commands for cash drawer
      final List<List<int>> drawerCommands = [
        [0x1B, 0x70, 0x00, 0x19, 0xFA], // ESC p 0 25 250 (Standard)
        [0x1B, 0x70, 0x00, 0x0A, 0x0A], // ESC p 0 10 10 (Alternative)
        [0x1B, 0x70, 0x01, 0x19, 0xFA], // ESC p 1 25 250 (Pin 2)
        [0x1D, 0x56, 0x00], // GS V 0 (Cut command - some printers open drawer)
        [0x10, 0x14, 0x01, 0x00, 0x05], // DLE DC4 1 0 5 (Alternative command)
      ];

      bool success = false;

      for (var command in drawerCommands) {
        final pData = calloc<Uint8>(command.length);
        for (int i = 0; i < command.length; i++) {
          pData[i] = command[i];
        }

        final pWritten = calloc<DWORD>();

        // Send the command to printer
        if (WritePrinter(phPrinter.value, pData, command.length, pWritten) != 0) {
          AppLogger.debug('Cash drawer command sent successfully. Command: $command, Bytes written: ${pWritten.value}');
          success = true;

          // Free memory for this iteration
          calloc.free(pData);
          calloc.free(pWritten);

          // Wait a moment between commands
          await Future.delayed(const Duration(milliseconds: 100));
          break; // Exit loop on first success
        } else {
          AppLogger.debug('Failed to send command: $command');
          calloc.free(pData);
          calloc.free(pWritten);
        }
      }

      // Close the printer
      ClosePrinter(phPrinter.value);

      // Free resources
      calloc.free(pPrinterName);
      calloc.free(phPrinter);

      if (success) {
        AppLogger.debug('Cash drawer opened successfully via Windows API');
        return;
      }
    } else {
      calloc.free(pPrinterName);
      calloc.free(phPrinter);
      AppLogger.debug('Failed to open printer via Windows API: $printerName');
    }

    // Method 2: Use the same method as successful print test
    AppLogger.debug('Trying alternative method using createWindowsByte approach');

    // Create a minimal ticket with only drawer command
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    List<int> drawerBytes = [];
    drawerBytes.addAll(generator.reset());
    drawerBytes.addAll(generator.drawer()); // This is the same command that works in print test

    // Send via windowsPrintRawData (same method as print test)
    windowsPrintRawData(printerName, drawerBytes, "");

    AppLogger.debug('Cash drawer command sent via windowsPrintRawData method');
  } catch (e) {
    AppLogger.error('Exception in openCashDrawerWindows: $e');
  }

  AppLogger.debug('Cash drawer operation completed for: $printerName');
}

Future<void> checkTcpIpPrinterStatus() async {
  for (int i = 0; i < printerLocalStrongData.length; i++) {
    if (printerLocalStrongData[i].printerConnectType == PrinterConnectEnum.ip) {
      String printerIp = printerLocalStrongData[i].ipAddress;
      int printerPort = printerLocalStrongData[i].ipPort;

      try {
        final Socket socket = await Socket.connect(printerIp, printerPort, timeout: const Duration(seconds: 1));

        // Example ESC/POS command to request printer status
        const List<int> statusCommand = [0x10, 0x04, 0x01]; // DLE EOT n
        socket.add(statusCommand);

        // ⭐ ใช้ Completer + timeout แทน await for
        final Completer<void> responseCompleter = Completer<void>();

        socket.listen(
          (data) {
            if (!responseCompleter.isCompleted && data.isNotEmpty) {
              if (data[0] == 22) {
                printerLocalStrongData[i].isReady = true;
                printerLocalStrongData[i].isPaperOut = false;
              } else if (data[0] == 30) {
                printerLocalStrongData[i].isReady = false;
                printerLocalStrongData[i].isPaperOut = true;
              } else {
                printerLocalStrongData[i].isReady = false;
                printerLocalStrongData[i].isPaperOut = false;
              }
              responseCompleter.complete();
            }
            socket.close();
          },
          onError: (error) {
            if (!responseCompleter.isCompleted) {
              printerLocalStrongData[i].isReady = false;
              printerLocalStrongData[i].isPaperOut = false;
              responseCompleter.complete();
            }
            socket.close();
          },
          onDone: () {
            if (!responseCompleter.isCompleted) {
              responseCompleter.complete();
            }
          },
        );

        // ⭐ รอ response แต่มี timeout (ไม่ block นาน)
        await responseCompleter.future.timeout(
          const Duration(seconds: 1),
          onTimeout: () {
            printerLocalStrongData[i].isReady = false;
            printerLocalStrongData[i].isPaperOut = false;
            socket.close();
          },
        );
      } catch (e) {
        printerLocalStrongData[i].isReady = false;
        printerLocalStrongData[i].isPaperOut = false;
        AppLogger.debug('❌ [Printer Status] Error checking ${printerLocalStrongData[i].name}: $e');
      }
    }
  }
}

Future<void> checkBluetoothPrinterStatus() async {
  /*for (int i = 0; i < printerLocalStrongData.length; i++) {
    if (printerLocalStrongData[i].printerConnectType ==
        PrinterConnectEnum.bluetooth) {
      String printerAddress = printerLocalStrongData[i].deviceId;

      try {
        // Establish a Bluetooth connection
        BluetoothConnection connection =
            await BluetoothConnection.toAddress(printerAddress);

        // Example ESC/POS command to request printer status
        const List<int> statusCommand = [0x10, 0x04, 0x01]; // DLE EOT n

        connection.output.add(Uint8List.fromList(statusCommand));
        await connection.output.allSent;

        connection.input?.listen((Uint8List data) {
          if (data.isNotEmpty) {
            AppLogger.debug('🖨️ [Printer] Response data: ${data[0]}');
            if (data[0] == 22) {
              printerLocalStrongData[i].isReady = true;
              printerLocalStrongData[i].isPaperOut = false;
            } else if (data[0] == 30) {
              printerLocalStrongData[i].isReady = false;
              printerLocalStrongData[i].isPaperOut = true;
            } else {
              printerLocalStrongData[i].isReady = false;
              printerLocalStrongData[i].isPaperOut = false;
            }
          }
          connection.close();
        }).onDone(() {
          // Handle connection closed
        });
      } catch (e) {
        printerLocalStrongData[i].isReady = false;
        printerLocalStrongData[i].isPaperOut = false;
      }
    }
  }*/
}

Future<String> getAppVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;

  String name = "";
  switch (posVersion) {
    case PosVersionEnum.pos:
      name = "POS";
      break;
    case PosVersionEnum.restaurant:
      name = "Restaurant";
      break;
    case PosVersionEnum.smlmobilepos:
      name = "SML Mobile POS";
      break;
    case PosVersionEnum.vfpos:
      name = "VF POS";
      break;
    case PosVersionEnum.marinepos:
      name = "Marine POS";
      break;
  }

  return version;
}

final class BeepFunction extends Struct {
  @Uint32()
  external int frequency;

  @Uint32()
  external int duration;
}

final BeepFunction Function(int frequency, int duration) xbeep = kernel32.lookupFunction<BeepFunction Function(Int32 frequency, Int32 duration), BeepFunction Function(int frequency, int duration)>('Beep');

Future<void> beep(int frequency, int duration) async {
  Future.delayed(const Duration(milliseconds: 1), () {
    xbeep(frequency, duration);
  });
}

/// ค้นหาตำแหน่งของ Detail ใน PosHoldProcessResult
int findActiveLineIndex({required String holdCode, String lineGuid = ""}) {
  int holdIndex = findPosHoldProcessResultIndex(holdCode);
  if (holdIndex != -1) {
    if (lineGuid.isEmpty) {
      lineGuid = posHoldProcessResult[holdIndex].activeLineGuid;
    }
    for (int i = 0; i < posHoldProcessResult[holdIndex].posProcess.details.length; i++) {
      PosProcessDetailModel detail = posHoldProcessResult[holdIndex].posProcess.details[i];
      if (detail.guid == lineGuid) {
        return i;
      }
    }
  }
  return -1;
}

String generateRandomString(int length) {
  const availableChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();

  return List.generate(length, (index) => availableChars[random.nextInt(availableChars.length)]).join();
}

Future<GBPaymentGenQRResponse> qrGBPrimePayThaiQR({required ProfileQrPaymentModel paymentProfile, required double qrAmount}) async {
  var apiKey = paymentProfile.apikey ?? "";
  var storeId = paymentProfile.storeID ?? "";
  var accessCode = paymentProfile.accessCode ?? "";

  GBPrimePay primePay = GBPrimePay(publicKey: apiKey, accessToken: storeId, secretKey: accessCode);
  String key = generateRandomString(5);
  String refCode = primePay.genRefUnixTimeNow(key);

  return await primePay.generateImageThaiQRPayment(refCode, Decimal.parse((qrAmount).toString()));
}

Future<Uint8List> toQrImageData(String data) async {
  final image = await QrPainter(data: data, version: QrVersions.auto).toImageData(400);
  return image!.buffer.asUint8List();
}

/// สร้างรูปภาพเอกสาร

Future<List<int>> createWindowsByte(PrinterLocalStrongDataModel printerData, Uint8List fileBytes) async {
  try {
    double maxHeight = 0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final backgroundPaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.fill;
    final double width = printerWidthByPixel(printerData);
    final generator = Generator(PaperSize.mm80, await CapabilityProfile.load());

    canvas.drawRect(ui.Rect.fromLTWH(0.0, 0.0, width, 200000.0), backgroundPaint);

    ui.Image? slipImage;
    ui.decodeImageFromList(fileBytes, (result) {
      slipImage = result;
    });
    while (slipImage == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    canvas.drawImage(slipImage!, ui.Offset(0, maxHeight), ui.Paint());
    maxHeight += slipImage!.height.toDouble();
    // Finalize drawing
    final List<int> bytes = [];
    final picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(640, maxHeight.toInt());

    final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes == null) {
      throw Exception('Failed to generate image bytes');
    }

    // Decode image for processing
    final imageDecode = im.decodeImage(pngBytes.buffer.asUint8List());
    if (imageDecode == null) {
      throw Exception('Failed to decode image');
    }

    // Add initial commands
    bytes.addAll(generator.reset());
    // image
    bytes.addAll(generator.imageRaster(imageDecode));

    // Add final commands
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());
    bytes.addAll(generator.drawer());

    return bytes;
  } catch (e) {
    AppLogger.error('Error generating ticket: $e');
    rethrow;
  }
}

Future<List<int>> createTicketWindows(PrinterLocalStrongDataModel printerData, DateTime docDate, String docNumber, List<PosPrintBillCommandModel> commandList, bool printLogo, int printMaxHeight, String qrCodeBottom, bool saveToFile, bool printPaySlip) async {
  try {
    double maxHeight = 0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final backgroundPaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.fill;
    final double width = printerWidthByPixel(printerData);
    final generator = Generator(PaperSize.mm80, await CapabilityProfile.load());

    canvas.drawRect(ui.Rect.fromLTWH(0.0, 0.0, width, 200000.0), backgroundPaint);
    PrintProcess printProcess = PrintProcess(printerData: printerData);

    for (var command in commandList) {
      // 0=Reset,1=Logo Image,2=Text,3=Line,9=Cut
      switch (command.mode) {
        case 0: // Reset
          break;
        case 1: // Logo Image
          if (command.image != null && printLogo) {
            ui.Image? logo;
            ui.decodeImageFromList(command.image!, (result) {
              logo = result;
            });
            while (logo == null) {
              await Future.delayed(Duration(milliseconds: printerDelayMilliseconds));
            }
            canvas.drawImage(logo!, ui.Offset((width - logo!.width) / 2, maxHeight), ui.Paint());
            maxHeight += logo!.height.toDouble();
          }
          break;
        case 2: // Text
          printProcess.columnWidth.clear();
          printProcess.column.clear();
          for (int index = 0; index < command.columns.length; index++) {
            printProcess.columnWidth.add(command.columns[index].width);
            printProcess.column.add(PrintColumn(text: (command.columns[index].text != "[{}]") ? command.columns[index].text : "", align: command.columns[index].text_align, bold: command.columns[index].font_weight_bold, fontSize: command.columns[index].font_size));
          }
          ui.Image result = await printProcess.lineFeedImage(command.posStyles ?? const PosStyles());
          canvas.drawImage(result, ui.Offset(0, maxHeight), ui.Paint());
          maxHeight += result.height.toDouble();
          break;
        case 3: // Line
          canvas.drawLine(ui.Offset(0, maxHeight + 1), ui.Offset(width, maxHeight), ui.Paint()..strokeWidth = 2);
          maxHeight += 4;
          break;
        case 9: // Qrcode
          ui.Image result = await QrPainter(data: command.qrCode, version: QrVersions.auto, gapless: false).toImage(width / 2.5);
          // left
          canvas.drawImage(result, ui.Offset(0, maxHeight), ui.Paint());
          // right
          canvas.drawImage(result, ui.Offset(width - result.width, maxHeight), ui.Paint());
          maxHeight += result.height.toDouble() + 10;
          break;
      }
    }
    if (printPaySlip) {
      try {
        final dateDirectory = await createPath(paySlipPath, DateTime.now());
        final path = "${dateDirectory.path}/$docNumber.jpg";
        final file = File(path);
        if (await file.exists()) {
          ui.Image? slipImage;
          ui.decodeImageFromList(await file.readAsBytes(), (result) {
            slipImage = result;
          });
          while (slipImage == null) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          canvas.drawImage(slipImage!, ui.Offset(0, maxHeight), ui.Paint());
          maxHeight += slipImage!.height.toDouble();
        }
      } catch (e) {
        AppLogger.error(e);
      }
    }
    if (qrCodeBottom.isNotEmpty) {
      double paperWidth = ticketPaperMaxWidth(printerData: printerData);
      maxHeight += 40;
      ui.Image result = await QrPainter(data: qrCodeBottom, version: QrVersions.auto, gapless: false).toImage(paperWidth / 2);

      ui.PictureRecorder recorder = ui.PictureRecorder();
      ui.Canvas newCanvas = ui.Canvas(recorder);

      final rect = ui.Rect.fromLTWH(0, 0, result.width + 20, result.height + 20);
      newCanvas.drawRect(rect, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
      newCanvas.drawRect(
        rect,
        ui.Paint()
          ..color = const ui.Color(0xFF000000)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      newCanvas.drawImage(result, const ui.Offset(10, 10), ui.Paint());

      ui.Image newImage = await recorder.endRecording().toImage((result.width + 20).toInt(), (result.height + 20).toInt());

      canvas.drawImage(newImage, ui.Offset((paperWidth / 2) - (result.width / 2), maxHeight), ui.Paint());

      maxHeight += newImage.height.toDouble() + 10;
    }
    // Finalize drawing
    final List<int> bytes = [];
    final picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(640, maxHeight.toInt());

    final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes == null) {
      throw Exception('Failed to generate image bytes');
    }

    // Decode image for processing
    final imageDecode = im.decodeImage(pngBytes.buffer.asUint8List());
    if (imageDecode == null) {
      throw Exception('Failed to decode image');
    }

    // Add initial commands
    bytes.addAll(generator.reset());
    // image
    bytes.addAll(generator.imageRaster(imageDecode));

    // Add final commands
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());
    bytes.addAll(generator.drawer());

    return bytes;
  } catch (e) {
    AppLogger.error('Error generating ticket: $e');
    rethrow;
  }
}

Future<Uint8List> ticketCreateImage({
  required PrinterLocalStrongDataModel printerData,
  required DateTime docDate,
  required String docNumber,
  required List<PosPrintBillCommandModel> commandList,
  bool printLogo = false,
  int printMaxHeight = 1000,
  String qrCodeBottom = "",
  bool saveToFile = false,
  required bool printPaySlip,
}) async {
  double maxHeight = 0;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final backgroundPaint = ui.Paint()
    ..color = const ui.Color(0xFFFFFFFF)
    ..style = ui.PaintingStyle.fill;
  final double width = printerWidthByPixel(printerData);
  canvas.drawRect(ui.Rect.fromLTWH(0.0, 0.0, width, 200000.0), backgroundPaint);
  PrintProcess printProcess = PrintProcess(printerData: printerData);

  for (var command in commandList) {
    // 0=Reset,1=Logo Image,2=Text,3=Line,9=Cut
    switch (command.mode) {
      case 0: // Reset
        break;
      case 1: // Logo Image
        if (command.image != null && printLogo) {
          ui.Image? logo;
          ui.decodeImageFromList(command.image!, (result) {
            logo = result;
          });
          while (logo == null) {
            await Future.delayed(Duration(milliseconds: printerDelayMilliseconds));
          }
          canvas.drawImage(logo!, ui.Offset((width - logo!.width) / 2, maxHeight), ui.Paint());
          maxHeight += logo!.height.toDouble();
        }
        break;
      case 2: // Text
        printProcess.columnWidth.clear();
        printProcess.column.clear();
        for (int index = 0; index < command.columns.length; index++) {
          printProcess.columnWidth.add(command.columns[index].width);
          printProcess.column.add(PrintColumn(text: (command.columns[index].text != "[{}]") ? command.columns[index].text : "", align: command.columns[index].text_align, bold: command.columns[index].font_weight_bold, fontSize: command.columns[index].font_size));
        }
        ui.Image result = await printProcess.lineFeedImage(command.posStyles ?? const PosStyles());
        canvas.drawImage(result, ui.Offset(0, maxHeight), ui.Paint());
        maxHeight += result.height.toDouble();
        break;
      case 3: // Line
        canvas.drawLine(ui.Offset(0, maxHeight + 1), ui.Offset(width, maxHeight), ui.Paint()..strokeWidth = 2);
        maxHeight += 4;
        break;
      case 9: // Qrcode
        ui.Image result = await QrPainter(data: command.qrCode, version: QrVersions.auto, gapless: false).toImage(width / 2.5);
        // left
        canvas.drawImage(result, ui.Offset(0, maxHeight), ui.Paint());
        // right
        canvas.drawImage(result, ui.Offset(width - result.width, maxHeight), ui.Paint());
        maxHeight += result.height.toDouble() + 10;
        break;
    }
  }
  if (printPaySlip) {
    try {
      final dateDirectory = await createPath(paySlipPath, DateTime.now());
      final path = "${dateDirectory.path}/$docNumber.jpg";
      final file = File(path);
      if (await file.exists()) {
        ui.Image? slipImage;
        ui.decodeImageFromList(await file.readAsBytes(), (result) {
          slipImage = result;
        });
        while (slipImage == null) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        canvas.drawImage(slipImage!, ui.Offset(0, maxHeight), ui.Paint());
        maxHeight += slipImage!.height.toDouble();
      }
    } catch (e) {
      AppLogger.error(e);
    }
  }
  if (qrCodeBottom.isNotEmpty) {
    double paperWidth = ticketPaperMaxWidth(printerData: printerData);
    maxHeight += 40;
    ui.Image result = await QrPainter(data: qrCodeBottom, version: QrVersions.auto, gapless: false).toImage(paperWidth / 2);

    ui.PictureRecorder recorder = ui.PictureRecorder();
    ui.Canvas newCanvas = ui.Canvas(recorder);

    final rect = ui.Rect.fromLTWH(0, 0, result.width + 20, result.height + 20);
    newCanvas.drawRect(rect, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
    newCanvas.drawRect(
      rect,
      ui.Paint()
        ..color = const ui.Color(0xFF000000)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    newCanvas.drawImage(result, const ui.Offset(10, 10), ui.Paint());

    ui.Image newImage = await recorder.endRecording().toImage((result.width + 20).toInt(), (result.height + 20).toInt());

    canvas.drawImage(newImage, ui.Offset((paperWidth / 2) - (result.width / 2), maxHeight), ui.Paint());

    maxHeight += newImage.height.toDouble() + 10;
  }
  // Finalize drawing
  final picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(width.toInt(), maxHeight.toInt());
  // Convert to PNG byte data
  ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  Uint8List pngBytes = byteData!.buffer.asUint8List();
  if (saveToFile) {
    // Save e-Journal
    //ticketSaveImageToJpgFile(docDate, docNumber, ximageBuffer);
  }

  return pngBytes;
}

double ticketPaperMaxWidth({required PrinterLocalStrongDataModel printerData}) {
  return (printerData.paperType == 1) ? 378.0 : 575.0;
}

/// Save รูปภาพใบเสร็จลงในเครื่อง และสร้าง Upload Queue
Future<void> ticketSaveImageToJpgFile(DateTime docDate, String docNo, Future<ui.Image> image) async {
  Stopwatch? stopwatch;
  if (kDebugMode) {
    stopwatch = Stopwatch()..start();
    AppLogger.debug('[SaveBill] 🖼️ Starting to save bill image: $docNo');
    AppLogger.debug('[SaveBill] 📅 Date: ${docDate.toString()}');
    AppLogger.debug('[SaveBill] 🏪 Shop ID: $shopId');
  }

  try {
    // Request storage permission.
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  } catch (e) {
    AppLogger.error(e);
  }

  try {
    String mainPath = "posbill";
    final dateDirectory = await createPath(mainPath, docDate);
    // Save the image to the new directory
    final path = '${dateDirectory.path}/$docNo.jpg';

    if (kDebugMode) {
      AppLogger.debug('[SaveBill] 📁 Full path: $path');
    }

    final img = await image; // Resolve the Future<ui.Image> here.
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();
    final decodedImage = im.decodeImage(pngBytes!);
    final jpg = im.encodeJpg(decodedImage!, quality: 25); // Control the quality of the image.
    final file = io.File(path);
    await file.writeAsBytes(jpg);

    if (kDebugMode) {
      final fileSize = await file.length();
      final sizeKB = (fileSize / 1024).toStringAsFixed(2);
      AppLogger.success('[SaveBill] ✅ Image saved successfully ($sizeKB KB)');
      stopwatch?.stop();
      AppLogger.debug('[SaveBill] ⏱️ Save took ${stopwatch?.elapsedMilliseconds}ms');
    }

    // ⭐ สร้าง Upload Queue สำหรับไฟล์ JPG (เก็บไว้ 7 วัน)
    try {
      final fileName = path.split('/').last;
      await createUploadJob(fileName: fileName, filePath: path, docNumber: docNo, metadata: jsonEncode({'docDate': docDate.toIso8601String()}));

      if (kDebugMode) {
        AppLogger.debug('[UploadQueue] ✅ Created upload job for $fileName');
      }
    } catch (uploadQueueError) {
      // Log but don't fail the image save process
      AppLogger.warning('[UploadQueue] ⚠️ Failed to create upload queue: $uploadQueueError');
    }
  } catch (e) {
    AppLogger.error('Error saving image to file: $e');
  }
}

Future<void> switchFullScreen() async {
  if (isFullScreen) {
    await FullScreenWindow.setFullScreen(false);
    isFullScreen = false;
  } else {
    await FullScreenWindow.setFullScreen(true);
    isFullScreen = true;
  }
}

String getLanguageCode(String code) {
  String languageCode = "th-TH";
  for (int index = 0; index < languageCodes.length; index++) {
    if (languageCodes[index] == code) {
      languageCode = languageCodes[index];
      break;
    }
  }
  return languageCode;
}

Future<void> sendTelegramMessage(String message) async {
  const String token = String.fromEnvironment('TELEGRAM_BOT_TOKEN');
  const String chatId = String.fromEnvironment('TELEGRAM_CHAT_ID');
  if (token.isEmpty || chatId.isEmpty) {
    return;
  }
  const String url = 'https://api.telegram.org/bot$token/sendMessage';

  final response = await http.post(Uri.parse(url), body: {'chat_id': chatId, 'text': message});

  if (response.statusCode == 200) {
    AppLogger.debug('Message sent');
  } else {
    AppLogger.error('Failed to send message');
  }
}

void sendErrorToDevTeam(String functionName, String message) {
  try {
    if (isOnline) {
      // ส่งข้อความไปยัง Dev Team ผ่าน Line Notify
      String myMessage = "DEDEPOS:$shopId : $branchId : $message : $functionName";
      sendTelegramMessage("$shopId:$myMessage");
    }
  } catch (e) {
    AppLogger.error(e);
  }
}

Future<void> createTempFolder(String folderName) async {
  final Directory tempDir = await getTemporaryDirectory();
  final Directory newFolder = Directory('${tempDir.path}/$folderName');

  if (!await newFolder.exists()) {
    await newFolder.create(recursive: true);
  }
}

Future<List<File>> getFilesInFolderSortedByModifiedDate(String folderPath) async {
  // ⭐ แก้ไข: รับ absolute path มาเลย ไม่ต้องเรียก getTemporaryDirectory()
  // เพราะฟังก์ชันนี้อาจถูกเรียกจาก Isolate ซึ่งไม่สามารถเรียก getTemporaryDirectory() ได้

  // Create a directory from the path
  final Directory specificFolder = Directory(folderPath);

  // Check if the folder exists
  if (!await specificFolder.exists()) {
    // If the folder does not exist, return an empty list or handle appropriately
    AppLogger.debug('Folder $folderPath does not exist.');
    return [];
  }

  // List all files in the specified folder
  List<File> files = specificFolder.listSync().whereType<File>().toList();

  // Retrieve and store file stats
  List<Map<String, dynamic>> fileStats = [];
  for (var file in files) {
    var stat = await file.stat();
    fileStats.add({'file': file, 'changed': stat.changed});
  }

  // Sort fileStats by the 'changed' property
  fileStats.sort((a, b) => a['changed'].compareTo(b['changed']));

  // Extract and return sorted files
  return fileStats.map((e) => e['file'] as File).toList();
}

String filePath(String path) {
  return path.trim().toLowerCase().replaceAll(".", "");
}

// Future<void> savePrintQueueToFile(String name, List<int> imageBytes) async {
//   final Directory tempDir = await getTemporaryDirectory();
//   final Directory newFolder = Directory('${tempDir.path}${filePath(name)}');
//   final guid = const Uuid().v4().replaceAll("-", "");
//   String pathName = '${newFolder.path}/${DateTime.now().millisecondsSinceEpoch}$guid.png';
//   await File(pathName).writeAsBytes(imageBytes, mode: FileMode.writeOnly, flush: true);
//   AppLogger.success('Save Print Queue Success : $pathName');
// }
Future<void> savePrintQueueToFile(
  String name,
  List<int> imageBytes,
  bool isPaySlip,
  String docNo,
  bool isMain, {
  int? tierLevel, // ⭐ เพิ่ม parameter สำหรับ Tier Redemption (Type 102)
  List<String> productNames = const [], // ⭐ ชื่อสินค้าสำหรับ kitchen prints
}) async {
  try {
    final Directory tempDir = await getTemporaryDirectory();
    final Directory newFolder = Directory('${tempDir.path}/${filePath(name)}');
    final Directory tempFolder = Directory('${tempDir.path}/${filePath(name)}/temp');

    if (kDebugMode) {
      AppLogger.debug('📄 [SavePrintQueue] Saving print job...');
      AppLogger.debug('🖨️ Printer: $name');
      AppLogger.debug('📄 Doc: $docNo');
      AppLogger.debug('📦 Size: ${imageBytes.length} bytes');
      AppLogger.debug('📂 Folder: ${newFolder.path}');
      AppLogger.debug('💳 PaySlip: $isPaySlip | Main: $isMain');
    }

    // Ensure the directory exists
    if (!await newFolder.exists()) {
      await newFolder.create(recursive: true);
      AppLogger.debug("   ✅ Created folder: ${newFolder.path}");
    }
    if (!await tempFolder.exists()) {
      await tempFolder.create(recursive: true);
      AppLogger.debug("   ✅ Created temp folder: ${tempFolder.path}");
    }
    // ⭐ สร้างชื่อไฟล์สำหรับ Print Queue (random filename)
    String guid = const Uuid().v4().replaceAll("-", "");
    String printFileName = '$docNo${DateTime.now().millisecondsSinceEpoch}$guid.png';
    String printPathName = '/$printFileName';

    final File printFile = File(newFolder.path + printPathName);

    // ⭐ บันทึกไฟล์สำหรับ Print Queue
    await printFile.writeAsBytes(imageBytes, mode: FileMode.writeOnly, flush: true);
    AppLogger.debug("   ✅ Saved print file: ${printFile.path}");

    // ⭐ บันทึกไฟล์สำหรับ Upload (JPG) ใช้ ticketSaveImageToJpgFile
    if (isPaySlip && isMain) {
      try {
        // แปลง PNG bytes เป็น ui.Image
        final codec = await ui.instantiateImageCodec(Uint8List.fromList(imageBytes));
        final frame = await codec.getNextFrame();
        final ui.Image uiImage = frame.image;

        // เรียกใช้ ticketSaveImageToJpgFile ที่จัดการ path ถูกต้อง
        await ticketSaveImageToJpgFile(DateTime.now(), docNo, Future.value(uiImage));

        if (kDebugMode) {
          AppLogger.success('✅ Called ticketSaveImageToJpgFile for $docNo.jpg');
        }
      } catch (e) {
        AppLogger.error("   ⚠️ Failed to save upload file: $e");
        // ไม่ throw error เพื่อไม่ให้กระทบการพิมพ์
      }
    }

    // ⭐ Step 2: Save to ObjectBox after file creation
    final printerData = printerLocalStrongData.firstWhere((p) => p.deviceName == name, orElse: () => PrinterLocalStrongDataModel());
    final printerType = printerData.printerConnectType.name; // ip, usb, windows, bluetooth, sunmi1

    final saved = await savePrintQueueToObjectBox(
      fileName: printFileName,
      printerName: name,
      printerType: printerType,
      filePath: printFile.path,
      docNumber: docNo,
      jobType: isPaySlip ? 'receipt' : 'kitchen',
      priority: isPaySlip ? 1 : 0,
      metadata: jsonEncode({
        'isPaySlip': isPaySlip,
        'isMain': isMain,
        'fileSize': imageBytes.length,
        if (tierLevel != null) 'tierLevel': tierLevel, // ⭐ เพิ่ม tierLevel
        if (productNames.isNotEmpty) 'productNames': productNames, // ⭐ ชื่อสินค้าสำหรับ kitchen prints
      }),
    );

    if (!saved) {
      // ⚠️ ObjectBox save failed, but file is created - Telegram already sent
      AppLogger.debug("   ⚠️ ObjectBox save failed for: $printFileName");
    }

    if (kDebugMode) {
      AppLogger.success('📊 Login Status: global.loginSuccess = $loginSuccess');
      AppLogger.debug('🏪 Shop ID: global.shopId = $shopId');
      AppLogger.debug("   👤 User: global.userLogin = ${userLogin?.code ?? 'null'}");
      AppLogger.success('🎉 Save completed successfully!');
    }
  } catch (e) {
    AppLogger.error("❌ [SavePrintQueue] Error: $e");

    // ⚠️ File creation failed - send Telegram
    try {
      await sendTelegramMessage(
        '❌ Print File Creation Failed\n'
        'Shop: $shopId\n'
        'Printer: $name\n'
        'Doc: $docNo\n'
        'Error: $e',
      );
    } catch (telegramError) {
      AppLogger.debug("   ⚠️ Failed to send Telegram: $telegramError");
    }
  }
}

Future<List<File>> getSavedImages(String folderName) async {
  final Directory tempDir = await getTemporaryDirectory();
  final Directory targetDir = Directory('${tempDir.path}/${filePath(folderName)}/temp');
  AppLogger.debug('${tempDir.path}/${filePath(folderName)}');

  if (!await targetDir.exists()) {
    return [];
  }

  final List<FileSystemEntity> entities = targetDir.listSync();
  List<File> imageFiles = [];

  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.png')) {
      imageFiles.add(entity);
    }
  }

  // Sort files by created date
  imageFiles.sort((a, b) {
    DateTime aModified = a.lastModifiedSync();
    DateTime bModified = b.lastModifiedSync();
    return bModified.compareTo(aModified);
  });

  return imageFiles;
}

/// Get saved JPG images (upload files) from local storage
/// Sorted by filename (latest first)
Future<List<File>> getSavedJpgImages(String folderName) async {
  Stopwatch? stopwatch;
  if (kDebugMode) {
    stopwatch = Stopwatch()..start();
    AppLogger.debug('[BillList] 🔍 Starting getSavedJpgImages for folder: $folderName');
  }

  final Directory tempDir = await getTemporaryDirectory();
  final Directory targetDir = Directory('${tempDir.path}/${filePath(folderName)}/temp');

  if (kDebugMode) {
    AppLogger.debug('[BillList] 📁 Target directory: ${targetDir.path}');
    AppLogger.debug('[BillList] 📂 Directory exists: ${await targetDir.exists()}');
  }

  if (!await targetDir.exists()) {
    if (kDebugMode) {
      AppLogger.debug('[BillList] ⚠️ Directory not found, returning empty list');
    }
    return [];
  }

  final List<FileSystemEntity> entities = targetDir.listSync();
  List<File> imageFiles = [];

  if (kDebugMode) {
    AppLogger.debug('[BillList] 📋 Total entities found: ${entities.length}');
    // แสดงไฟล์ทั้งหมดเพื่อ debug
    if (entities.isNotEmpty) {
      AppLogger.debug('[BillList] 📄 Listing all files:');
      for (var entity in entities) {
        if (entity is File) {
          String fileName = entity.path.split(Platform.pathSeparator).last;
          String ext = fileName.split('.').last;
          AppLogger.debug('[BillList]    - $fileName (.$ext)');
        }
      }
    }
  }

  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.jpg')) {
      imageFiles.add(entity);
      if (kDebugMode) {
        String fileName = entity.path.split(Platform.pathSeparator).last;
        AppLogger.debug('[BillList] ✅ Found JPG: $fileName');
      }
    }
  }

  if (kDebugMode) {
    AppLogger.debug('[BillList] 🖼️ Total JPG files found: ${imageFiles.length}');
  }

  // Sort files by filename (descending - latest first)
  imageFiles.sort((a, b) {
    String aName = a.path.split(Platform.pathSeparator).last;
    String bName = b.path.split(Platform.pathSeparator).last;
    return bName.compareTo(aName);
  });

  if (kDebugMode) {
    stopwatch?.stop();
    AppLogger.debug('[BillList] ⏱️ getSavedJpgImages took ${stopwatch?.elapsedMilliseconds}ms');
    if (imageFiles.isNotEmpty) {
      AppLogger.debug('[BillList] 📊 First file (latest): ${imageFiles.first.path.split(Platform.pathSeparator).last}');
      AppLogger.debug('[BillList] 📊 Last file (oldest): ${imageFiles.last.path.split(Platform.pathSeparator).last}');
    }
  }

  return imageFiles;
}

/// Get saved bill images from posbill directory
/// Scans all date folders and returns JPG files sorted by date (latest first)
Future<List<File>> getSavedBillImages() async {
  Stopwatch? stopwatch;
  if (kDebugMode) {
    stopwatch = Stopwatch()..start();
    AppLogger.debug('[BillList] 🔍 Starting getSavedBillImages from posbill/$shopId/');
  }

  final directory = await getApplicationDocumentsDirectory();
  final shopDirectory = Directory('${directory.path}/posbill/$shopId');

  if (kDebugMode) {
    AppLogger.debug('[BillList] 🏪 Shop ID: $shopId');
    AppLogger.debug('[BillList] 📁 Shop directory: ${shopDirectory.path}');
    AppLogger.debug('[BillList] 📂 Directory exists: ${await shopDirectory.exists()}');
  }

  if (!await shopDirectory.exists()) {
    if (kDebugMode) {
      AppLogger.debug('[BillList] ⚠️ Shop directory not found for shopId: $shopId');
    }
    return [];
  }

  List<File> allImageFiles = [];

  // Scan all files directly in shopId folder (no date subfolders)
  final files = shopDirectory.listSync();

  if (kDebugMode) {
    AppLogger.debug('[BillList] 📋 Found ${files.length} items in shop $shopId folder');
  }

  for (var file in files) {
    if (file is File && file.path.endsWith('.jpg')) {
      allImageFiles.add(file);

      if (kDebugMode) {
        String fileName = file.path.split(Platform.pathSeparator).last;
        AppLogger.debug('[BillList] ✅ Found: $shopId/$fileName');
      }
    }
  }

  if (kDebugMode) {
    AppLogger.debug('[BillList] 🖼️ Total JPG files found: ${allImageFiles.length}');
  }

  // Sort by file modification time (latest first)
  allImageFiles.sort((a, b) {
    DateTime aModified = a.lastModifiedSync();
    DateTime bModified = b.lastModifiedSync();
    return bModified.compareTo(aModified);
  });

  if (kDebugMode) {
    stopwatch?.stop();
    AppLogger.debug('[BillList] ⏱️ getSavedBillImages took ${stopwatch?.elapsedMilliseconds}ms');

    if (allImageFiles.isNotEmpty) {
      String firstFile = allImageFiles.first.path.split(Platform.pathSeparator).last;
      String lastFile = allImageFiles.last.path.split(Platform.pathSeparator).last;
      AppLogger.debug('[BillList] 📊 Latest: $firstFile');
      AppLogger.debug('[BillList] 📊 Oldest: $lastFile');
    }
  }

  return allImageFiles;
}

Future<void> systemInfoSendToServer() async {
  try {
    if (isOnline) {
      SystemInfoModel systemInfo = SystemInfoModel(tableObjectBox: objectBoxStore.box<TableObjectBoxStruct>().getAll().toList(), tableProcessObjectBox: objectBoxStore.box<TableProcessObjectBoxStruct>().getAll().toList());
      ApiRepository api = ApiRepository();
      var jsonData = jsonEncode(systemInfo.toJson());
      api.radisPost(branchCode: posConfig.branch.code, data: jsonData);
    }
  } catch (e) {
    AppLogger.error(e);
  }
}

Future<List<OrderBarcodeStatusModel>> compareBarcodeStatusTeminalAndServerGetData() async {
  List<OrderBarcodeStatusModel> productBarcodeStatusServer = [];
  String query = "SELECT * FROM dedeorderonline.orderbarcodestatus WHERE shopid = '$shopId'";
  var value = await api.clickHouseSelect(query);
  if (value.isNotEmpty) {
    ResponseDataModel responseData = ResponseDataModel.fromJson(value);
    for (var data in responseData.data) {
      productBarcodeStatusServer.add(OrderBarcodeStatusModel.fromJson(data as Map<String, dynamic>));
    }
  }
  return productBarcodeStatusServer;
}

/// ตรวจสอบ Barcode Status กับ server ว่าตรงกันหรือเปล่า ถ้าไม่ตรง ให้ update
bool compareBarcodeStatusTeminalAndServerProcess = false;
Future<void> compareBarcodeStatusTeminalAndServer() async {
  if (compareBarcodeStatusTeminalAndServerProcess == false) {
    compareBarcodeStatusTeminalAndServerProcess = true;
    try {
      // ดึงจาก click house
      List<ProductBarcodeStatusObjectBoxStruct> productBarcodeStatus = ProductBarcodeStatusHelper().getAll();
      // load จาก click house
      List<OrderBarcodeStatusModel> productBarcodeStatusServer = await compareBarcodeStatusTeminalAndServerGetData();

      // ⭐ OPTIMIZATION 1: สร้าง Map สำหรับ O(1) lookup แทน nested loop O(n²)
      final serverBarcodeMap = <String, OrderBarcodeStatusModel>{};
      for (var serverData in productBarcodeStatusServer) {
        serverBarcodeMap[serverData.barcode] = serverData;
      }

      // ตรวจสอบว่าบน server มีข้อมูลหรือไม่ ถ้าไม่มีให้ insert บน server
      String queryInsertClickHouse = "";
      for (var data in productBarcodeStatus) {
        // ⭐ O(1) lookup แทน nested loop
        final serverData = serverBarcodeMap[data.barcode];
        if (serverData == null) {
          // ไม่พบใน server -> ต้อง insert
          if (queryInsertClickHouse.isEmpty) {
            queryInsertClickHouse = "INSERT INTO dedeorderonline.orderbarcodestatus (shopid, barcode, orderstatus, orderautostock, orderdisable, qtybalance, qtymin, qtystart) VALUES";
          }

          // เพิ่มข้อมูลหลาย row
          queryInsertClickHouse += " ('$shopId', '${data.barcode}', 0, 0, 0, 0, 0, 0),";
        }
      }

      if (queryInsertClickHouse.isNotEmpty) {
        // ลบ comma สุดท้ายออกในตอนจบ
        queryInsertClickHouse = queryInsertClickHouse.substring(0, queryInsertClickHouse.length - 1);
        // ส่งข้อมูลไปยัง click house
        await api.clickHouseExecute(queryInsertClickHouse);
      }

      // load จาก click house ใหม่
      productBarcodeStatusServer = await compareBarcodeStatusTeminalAndServerGetData();

      // ⭐ OPTIMIZATION 2: สร้าง Map ใหม่หลัง insert
      final localBarcodeMap = <String, ProductBarcodeStatusObjectBoxStruct>{};
      for (var data in productBarcodeStatus) {
        localBarcodeMap[data.barcode] = data;
      }

      // ตรวจสอบว่าข้อมูลบน terminal มีข้อมูลที่ไม่ตรงกับ server หรือไม่
      for (var serverData in productBarcodeStatusServer) {
        // ⭐ O(1) lookup แทน nested loop
        final data = localBarcodeMap[serverData.barcode];
        if (data != null) {
          // ถ้าเจอให้ตรวจว่าเท่ากันหรือไม่ ถ้าไม่เท่า ให้ update บน server
          if (serverData.orderstatus != data.orderStatus ||
              serverData.orderautostock != ((data.orderAutoStock) ? 1 : 0) ||
              serverData.orderdisable != ((data.orderDisable) ? 1 : 0) ||
              serverData.qtybalance != data.qtyBalance ||
              serverData.qtymin != data.qtyMin ||
              serverData.qtystart != data.qtyStart) {
            // ตรวจสอบว่าข้อมูลเปลี่ยนแปลงหรือไม่
            String queryUpdateClickHouse =
                "alter table dedeorderonline.orderbarcodestatus update orderstatus = ${data.orderStatus}, orderautostock = ${((data.orderAutoStock) ? 1 : 0)}, orderdisable = ${((data.orderDisable) ? 1 : 0)}, qtybalance = ${data.qtyBalance}, qtymin = ${data.qtyMin}, qtystart = ${data.qtyStart} WHERE shopid = '$shopId' AND barcode = '${serverData.barcode}'";
            // ส่งข้อมูลไปยัง click house
            await api.clickHouseExecute(queryUpdateClickHouse);
          }
        }
      }
    } catch (e) {
      AppLogger.error(e);
    }
    compareBarcodeStatusTeminalAndServerProcess = false;
  }
}

Future<void> speak(String word) async {
  /*double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.4;

  if (word.isNotEmpty && (Platform.isAndroid || Platform.isIOS)) {
    AppLogger.debug("Speak : $word");
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    await flutterTts.setLanguage("th-TH");
    await flutterTts.speak(word);
  }*/
}

Future<void> lineNotifyCheck() async {
  try {
    var getData = await api.clickHouseSelect("select * from dedetemp.linenotify");
    ResponseDataModel response = ResponseDataModel.fromJson(getData);
    if (response.data.isNotEmpty) {
      List<LineNotifyModel> lineNotifyData = response.data.map<LineNotifyModel>((item) => LineNotifyModel.fromJson(item)).toList();
      for (var line in lineNotifyData) {
        String guid = line.guid;
        // ลบข้อมูล
        await api.clickHouseExecute("ALTER TABLE dedetemp.linenotify DELETE WHERE guid='$guid'");
        // แจ้งเตือนด้วย Line Notify
        await sendTelegramMessage(line.message);
      }
    }
  } catch (e) {
    AppLogger.error(e);
  }
  callerSpeech();
}

Future<void> callerCheck() async {
  try {
    if (callerTextToSpeechList.isEmpty) {
      var getData = await api.clickHouseSelect("select * from dedetemp.caller where shopid='$shopId' and actionstatus=0 order by calldatetime");
      ResponseDataModel response = ResponseDataModel.fromJson(getData);
      if (response.data.isNotEmpty) {
        List<CallerModel> caller = response.data.map<CallerModel>((item) => CallerModel.fromJson(item)).toList();
        for (var call in caller) {
          if (call.actionstatus == 0) {
            // andoird แจ้งเตือน ด้วยเสียง
            if (Platform.isAndroid) {
              if (callerAlert) {
                // แจ้งเตือนด้วยเสียงพูด
                callerTextToSpeechList.add(call.command);
              }
            }
          }
        }
      }
    }
  } catch (e) {
    AppLogger.error(e);
  }
  callerSpeech();
}

Future<void> callerSpeech() async {
  if (speechActive == false) {
    speechActive = true;
    try {
      // พูดทุก 1 นาที
      if (DateTime.now().difference(callerTextToSpeechLastTime).inSeconds >= 10) {
        callerTextToSpeechLastTime = DateTime.now();
        if (callerTextToSpeechList.isNotEmpty) {
          while (callerTextToSpeechList.isNotEmpty) {
            String word = callerTextToSpeechList[0];
            callerTextToSpeechList.removeAt(0);
            await speak(word);
            await Future.delayed(const Duration(seconds: 10));
          }
        }
      }
    } catch (e) {
      AppLogger.error(e);
    }
    speechActive = false;
  }
}

/// เก็บรายการ OrderTemp ไว้ใน OrderTempSync เพื่อส่งข้อมูลไปยัง dedeorderonline.ordertemplog ต่อไป
Future<void> saveOrderTempToSyncTempLog({required String orderId, required String docNumber, required String guidPos, required orderEmtry}) async {
  try {
    // ดึงข้อมูลจาก ordertemp
    var dataTemp = objectBoxStore.box<OrderTempObjectBoxStruct>().query(OrderTempObjectBoxStruct_.orderId.equals(orderId) & OrderTempObjectBoxStruct_.isOrderSendDedeTempSuccess.equals(false)).build().find();
    if (dataTemp.isNotEmpty) {
      List<OrderTempSyncObjectBoxStruct> orderTempSync = [];
      for (var data in dataTemp) {
        orderTempSync.add(
          OrderTempSyncObjectBoxStruct(
            id: 0,
            guidPos: guidPos,
            orderEmtry: orderEmtry,
            orderIdMain: data.orderIdMain,
            optionSelected: data.optionSelected,
            imageUri: data.imageUri,
            docNo: docNumber,
            orderHistory: data.orderHistory,
            cancelHistory: data.cancelHistory,
            servedHistory: data.servedHistory,
            isOrderSendDedeTempSuccess: data.isOrderSendDedeTempSuccess,
            orderId: data.orderId,
            orderGuid: data.orderGuid,
            machineId: data.machineId,
            orderDateTime: data.orderDateTime,
            barcode: data.barcode,
            orderQty: data.orderQty,
            cancelQty: data.cancelQty,
            qtyLastCancel: data.qtyLastCancel,
            price: data.price,
            amount: data.amount,
            isOrder: data.isOrder,
            isOrderSuccess: data.isOrderSuccess,
            isOrderSendKdsSuccess: data.isOrderSendKdsSuccess,
            isOrderReadySendKds: data.isOrderReadySendKds,
            isPaySuccess: data.isPaySuccess,
            remark: data.remark,
            remarkForCancel: data.remarkForCancel,
            names: data.names,
            unitCode: data.unitCode,
            unitName: data.unitName,
            takeAway: data.takeAway,
            kdsSuccessTime: data.kdsSuccessTime,
            kdsSuccess: data.kdsSuccess,
            kdsId: data.kdsId,
            servedTime: data.servedTime,
            servedSuccess: data.servedSuccess,
            servedQty: data.servedQty,
            deliveryNumber: data.deliveryNumber,
            deliveryCode: data.deliveryCode,
            deliveryName: data.deliveryName,
            lastUpdateDateTime: data.lastUpdateDateTime,
            orderType: data.orderType,
            orderEmployeeCode: data.orderEmployeeCode,
            orderEmployeeDetail: data.orderEmployeeDetail,
          ),
        );
      }
      // insert
      objectBoxStore.box<OrderTempSyncObjectBoxStruct>().putMany(orderTempSync, mode: PutMode.insert);
      // update isOrderSendDedeTempSuccess
      for (var data in dataTemp) {
        data.docNo = docNumber;
        data.guidPos = guidPos;
        data.isOrderSendDedeTempSuccess = true;
      }
      objectBoxStore.box<OrderTempObjectBoxStruct>().putMany(dataTemp, mode: PutMode.update);
    }
  } catch (e, s) {
    AppLogger.error(e);
    sendErrorToDevTeam("saveOrderTempToSyncTempLog", "$e : $s");
  }
}

/// ส่งข้อมูลจาก OrderTempSync ไปยัง dedeorderonline.ordertemplog
Future<void> sendOrderTempToDeDeOrderTempLog() async {
  StringBuffer queryBufferOrderHistoryTemp = StringBuffer();
  StringBuffer queryBufferOrderServedHistoryTemp = StringBuffer();
  StringBuffer queryBufferOrderCancelHistoryTemp = StringBuffer();
  // ส่งข้อมูลไปยัง dedeorderonline.ordertemplog
  try {
    // ดึงข้อมูลจาก ordertemp
    var dataTemp = objectBoxStore.box<OrderTempSyncObjectBoxStruct>().query(OrderTempSyncObjectBoxStruct_.isOrderSendDedeTempSuccess.equals(false)).build().find();
    if (dataTemp.isNotEmpty) {
      // ข้อมูลไปยัง dedeorderonline.ordertemplog
      StringBuffer queryBufferOrderTemp = StringBuffer();
      for (int i = 0; i < dataTemp.length; i++) {
        var dataTempClone = dataTemp[i];

        // Helper function to format DateTime without milliseconds and convert to UTC
        String formatDateTimeUTC(DateTime dateTime) {
          return dateTime.toUtc().toIso8601String().split('.')[0];
        }

        queryBufferOrderTemp.write("(");
        queryBufferOrderTemp.write("'${posConfig.branch.guidfixed}', ");
        queryBufferOrderTemp.write("'${dataTempClone.guidPos}', ");
        queryBufferOrderTemp.write("'$shopId', ");
        queryBufferOrderTemp.write("'${dataTempClone.docNo}', ");
        queryBufferOrderTemp.write("'${dataTempClone.orderId}', ");
        queryBufferOrderTemp.write("'${dataTempClone.orderIdMain}', ");
        queryBufferOrderTemp.write("'${dataTempClone.orderGuid}', ");
        queryBufferOrderTemp.write("'${dataTempClone.machineId}', ");
        queryBufferOrderTemp.write("'${formatDateTimeUTC(dataTempClone.lastUpdateDateTime)}', ");
        queryBufferOrderTemp.write("'${dataTempClone.barcode}', ");
        queryBufferOrderTemp.write("${dataTempClone.orderQty}, ");
        queryBufferOrderTemp.write("${dataTempClone.cancelQty}, ");
        queryBufferOrderTemp.write("${dataTempClone.qtyLastCancel}, ");
        queryBufferOrderTemp.write("${dataTempClone.price}, ");
        queryBufferOrderTemp.write("${dataTempClone.amount}, ");
        queryBufferOrderTemp.write("${dataTempClone.isOrder ? 1 : 0}, ");
        queryBufferOrderTemp.write("${dataTempClone.isOrderSuccess ? 1 : 0}, ");
        queryBufferOrderTemp.write("${dataTempClone.isOrderSendKdsSuccess ? 1 : 0}, ");
        queryBufferOrderTemp.write("${dataTempClone.isOrderReadySendKds ? 1 : 0}, ");
        queryBufferOrderTemp.write("${dataTempClone.isPaySuccess ? 1 : 0}, ");
        queryBufferOrderTemp.write(dataTempClone.remark.isNotEmpty ? "'${dataTempClone.remark}'" : "NULL");
        queryBufferOrderTemp.write(", ");
        queryBufferOrderTemp.write(dataTempClone.remarkForCancel.isNotEmpty ? "'${dataTempClone.remarkForCancel}'" : "NULL");
        queryBufferOrderTemp.write(", ");
        queryBufferOrderTemp.write("'${getNameFromJsonLanguage(dataTempClone.names, userScreenLanguage)}', ");
        queryBufferOrderTemp.write("'${dataTempClone.unitCode}', ");
        queryBufferOrderTemp.write("'${getNameFromJsonLanguage(dataTempClone.unitName, userScreenLanguage)}', ");
        queryBufferOrderTemp.write("${dataTempClone.takeAway ? 1 : 0}, ");
        queryBufferOrderTemp.write("'${formatDateTimeUTC(dataTempClone.kdsSuccessTime)}', ");
        queryBufferOrderTemp.write("${dataTempClone.kdsSuccess ? 1 : 0}, ");
        queryBufferOrderTemp.write("'${dataTempClone.kdsId}', ");
        queryBufferOrderTemp.write("'${formatDateTimeUTC(dataTempClone.servedTime)}', ");
        queryBufferOrderTemp.write("${dataTempClone.servedSuccess ? 1 : 0}, ");
        queryBufferOrderTemp.write("${dataTempClone.servedQty}, ");
        queryBufferOrderTemp.write(dataTempClone.deliveryNumber.isNotEmpty ? "'${dataTempClone.deliveryNumber}'" : "NULL");
        queryBufferOrderTemp.write(", ");
        queryBufferOrderTemp.write(dataTempClone.deliveryCode.isNotEmpty ? "'${dataTempClone.deliveryCode}'" : "NULL");
        queryBufferOrderTemp.write(", ");
        queryBufferOrderTemp.write(dataTempClone.deliveryName.isNotEmpty ? "'${dataTempClone.deliveryName}'" : "NULL");
        queryBufferOrderTemp.write(", ");
        queryBufferOrderTemp.write("'${formatDateTimeUTC(dataTempClone.lastUpdateDateTime)}', ");
        queryBufferOrderTemp.write("${dataTempClone.orderType}, ");
        queryBufferOrderTemp.write("${dataTempClone.orderEmtry ? 1 : 0}, ");
        queryBufferOrderTemp.write("'${dataTempClone.orderEmployeeCode}', ");
        queryBufferOrderTemp.write("'${dataTempClone.orderEmployeeDetail}')");
        if (i < dataTemp.length - 1) {
          queryBufferOrderTemp.write(", ");
        }
        if (dataTempClone.orderHistory.isNotEmpty) {
          // order history
          List<OrderHistoryModel> orderHistory = List<OrderHistoryModel>.from(await jsonDecode(dataTempClone.orderHistory).map((e) => OrderHistoryModel.fromJson(e)));
          if (orderHistory.isNotEmpty) {
            for (var orderData in orderHistory) {
              if (queryBufferOrderHistoryTemp.isNotEmpty) {
                queryBufferOrderHistoryTemp.write(", ");
              }
              queryBufferOrderHistoryTemp.write("(");
              queryBufferOrderHistoryTemp.write("'${posConfig.branch.guidfixed}', ");

              queryBufferOrderHistoryTemp.write("'${dataTempClone.guidPos}', ");
              queryBufferOrderHistoryTemp.write("'$shopId', ");
              queryBufferOrderHistoryTemp.write("'${dataTempClone.docNo}', ");
              queryBufferOrderHistoryTemp.write("'${dataTempClone.orderId}', ");
              queryBufferOrderHistoryTemp.write("'${dataTempClone.orderIdMain}', ");
              queryBufferOrderHistoryTemp.write("'${dataTempClone.orderGuid}', ");
              queryBufferOrderHistoryTemp.write("'${formatDateTimeUTC(orderData.orderDateTime)}', ");
              queryBufferOrderHistoryTemp.write("'${dataTempClone.barcode}', ");
              queryBufferOrderHistoryTemp.write("${orderData.orderQty}) ");
            }
          }
        }
        if (dataTempClone.servedHistory.isNotEmpty) {
          // served history
          List<OrderServedHistoryModel> orderServedHistory = List<OrderServedHistoryModel>.from(await jsonDecode(dataTempClone.servedHistory).map((e) => OrderServedHistoryModel.fromJson(e)));
          if (orderServedHistory.isNotEmpty) {
            for (var servedData in orderServedHistory) {
              if (queryBufferOrderServedHistoryTemp.isNotEmpty) {
                queryBufferOrderServedHistoryTemp.write(", ");
              }
              queryBufferOrderServedHistoryTemp.write("(");
              queryBufferOrderServedHistoryTemp.write("'${posConfig.branch.guidfixed}', ");

              queryBufferOrderServedHistoryTemp.write("'${dataTempClone.guidPos}', ");
              queryBufferOrderServedHistoryTemp.write("'$shopId', ");
              queryBufferOrderServedHistoryTemp.write("'${dataTempClone.docNo}', ");
              queryBufferOrderServedHistoryTemp.write("'${dataTempClone.orderId}', ");
              queryBufferOrderServedHistoryTemp.write("'${dataTempClone.orderIdMain}', ");
              queryBufferOrderServedHistoryTemp.write("'${dataTempClone.orderGuid}', ");
              queryBufferOrderServedHistoryTemp.write("'${formatDateTimeUTC(dataTempClone.orderDateTime)}', ");
              queryBufferOrderServedHistoryTemp.write("'${formatDateTimeUTC(servedData.servedDateTime)}', ");
              queryBufferOrderServedHistoryTemp.write("'${dataTempClone.barcode}', ");
              queryBufferOrderServedHistoryTemp.write("${dataTempClone.orderQty}, ");
              queryBufferOrderServedHistoryTemp.write("${servedData.servedQty}) ");
            }
          }
        }
        if (dataTempClone.cancelHistory.isNotEmpty) {
          // cancel history
          List<OrderCancelHistoryModel> orderCancelHistory = List<OrderCancelHistoryModel>.from(await jsonDecode(dataTempClone.cancelHistory).map((e) => OrderCancelHistoryModel.fromJson(e)));
          if (orderCancelHistory.isNotEmpty) {
            for (var cancelData in orderCancelHistory) {
              if (queryBufferOrderCancelHistoryTemp.isNotEmpty) {
                queryBufferOrderCancelHistoryTemp.write(", ");
              }
              queryBufferOrderCancelHistoryTemp.write("(");
              queryBufferOrderCancelHistoryTemp.write("'${posConfig.branch.guidfixed}', ");

              queryBufferOrderCancelHistoryTemp.write("'${dataTempClone.guidPos}', ");
              queryBufferOrderCancelHistoryTemp.write("'$shopId', ");
              queryBufferOrderCancelHistoryTemp.write("'${dataTempClone.docNo}', ");
              queryBufferOrderCancelHistoryTemp.write("'${dataTempClone.orderId}', ");
              queryBufferOrderCancelHistoryTemp.write("'${dataTempClone.orderIdMain}', ");
              queryBufferOrderCancelHistoryTemp.write("'${dataTempClone.orderGuid}', ");
              queryBufferOrderCancelHistoryTemp.write("'${formatDateTimeUTC(dataTempClone.orderDateTime)}', ");
              queryBufferOrderCancelHistoryTemp.write("'${formatDateTimeUTC(cancelData.cancelDateTime)}', ");
              queryBufferOrderCancelHistoryTemp.write("'${dataTempClone.barcode}', ");
              queryBufferOrderCancelHistoryTemp.write("${dataTempClone.orderQty}, ");
              queryBufferOrderCancelHistoryTemp.write("${cancelData.cancelQty}) ");
            }
          }
        }
      }

      await api.clickHouseExecute(
        "INSERT INTO dedetemp.ordertemplog (branch,guidpos,shopid, docno, orderid, orderidmain, orderguid, machineid, orderdatetime, barcode, orderqty, cancelqty, qtylastcancel, price, amount, isorder, isordersuccess, isordersendkdssuccess, isorderreadysendkds, ispaysuccess, remark, remarkforcancel, names, unitcode, unitname, takeaway, kdssuccesstime, kdssuccess, kdsid, servedtime, servedsuccess, servedqty, deliverynumber, deliverycode, deliveryname, lastupdatedatetime, ordertype, orderemtry, orderemployeecode, orderemployeedetail) VALUES ${queryBufferOrderTemp.toString()};",
      );
    }

    if (queryBufferOrderHistoryTemp.isNotEmpty) {
      await api.clickHouseExecute("INSERT INTO dedetemp.ordertemporderlog (branch,guidpos,shopid, docno, orderid, orderidmain, orderguid, orderdatetime, barcode, orderqty) VALUES ${queryBufferOrderHistoryTemp.toString()};");
    }

    if (queryBufferOrderServedHistoryTemp.isNotEmpty) {
      await api.clickHouseExecute("INSERT INTO dedetemp.ordertempservedlog (branch,guidpos,shopid, docno, orderid, orderidmain, orderguid, orderdatetime, serveddatetime, barcode, orderqty, servedqty) VALUES ${queryBufferOrderServedHistoryTemp.toString()};");
    }

    if (queryBufferOrderCancelHistoryTemp.isNotEmpty) {
      await api.clickHouseExecute("INSERT INTO dedetemp.ordertempcancellog (branch,guidpos,shopid, docno, orderid, orderidmain, orderguid, orderdatetime, canceldatetime, barcode, orderqty, cancelqty) VALUES ${queryBufferOrderCancelHistoryTemp.toString()};");
    }

    // ลบ OrderTempSync ที่ส่งข้อมูลไปยัง dedeorderonline.ordertemplog แล้ว
    objectBoxStore.box<OrderTempSyncObjectBoxStruct>().removeMany(dataTemp.map((e) => e.id).toList());
  } catch (e, s) {
    AppLogger.error(e);
    sendErrorToDevTeam("sendOrderTempToDeDeOrderTempLog", "$e : $s");
  }
}

Color hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

// ============================================================
// 🖨️ PRINT QUEUE MANAGEMENT WITH OBJECTBOX
// ============================================================

/// บันทึกงานพิมพ์ลง ObjectBox
/// Returns: true ถ้าบันทึกสำเร็จ, false ถ้าล้มเหลว
Future<bool> savePrintQueueToObjectBox({required String fileName, required String printerName, required String printerType, required String filePath, required String docNumber, String jobType = 'receipt', int priority = 0, String metadata = ''}) async {
  try {
    if (kDebugMode) {
      AppLogger.debug('💾 Saving to ObjectBox...');
      AppLogger.debug('📄 File: $fileName');
      AppLogger.debug('🖨️ Printer: $printerName ($printerType)');
      AppLogger.info('📋 Doc: $docNumber');
    }
    if (jobType == 'kitchen' && docNumber.isNotEmpty) {
      jobType = 'receipt';
    }

    final queue = PrintQueueObjectBoxStruct(
      fileName: fileName,
      printerName: printerName,
      printerType: printerType,
      filePath: filePath,
      docNumber: docNumber,
      status: PrintQueueStatus.pending.value,
      createdAt: DateTime.now(),
      retryCount: 0,
      errorMessage: '',
      jobType: jobType,
      priority: priority,
      metadata: metadata,
    );

    final box = objectBoxStore.box<PrintQueueObjectBoxStruct>();
    box.put(queue);

    AppLogger.debug('[PrintQueue] ✅ Saved to ObjectBox with ID: ${queue.id}');

    return true;
  } catch (e, stackTrace) {
    if (kDebugMode) {
      AppLogger.error('❌ Failed to save to ObjectBox: $e');
      AppLogger.debug('Stack: $stackTrace');
    }

    // ส่ง Telegram notification on error
    try {
      await sendTelegramMessage(
        '❌ Print Queue Save Failed\n'
        'Shop: $shopId\n'
        'Printer: $printerName\n'
        'Doc: $docNumber\n'
        'Error: $e',
      );
    } catch (telegramError) {
      AppLogger.debug('[PrintQueue] ⚠️ Failed to send Telegram: $telegramError');
    }

    return false;
  }
}

/// ดึงงานพิมพ์ที่รอคิว (status = 0)
/// Returns: List of pending print jobs sorted by priority DESC, createdAt ASC
List<PrintQueueObjectBoxStruct> getPendingPrintJobs({String? printerName, int limit = 100}) {
  try {
    final box = objectBoxStore.box<PrintQueueObjectBoxStruct>();

    // Build query condition
    Condition<PrintQueueObjectBoxStruct> condition = PrintQueueObjectBoxStruct_.status.equals(PrintQueueStatus.pending.value);

    // Filter by printer if specified
    if (printerName != null && printerName.isNotEmpty) {
      condition = condition & PrintQueueObjectBoxStruct_.printerName.equals(printerName);
    }

    final builder = box.query(condition);

    // Order by priority DESC, then createdAt ASC
    builder.order(PrintQueueObjectBoxStruct_.priority, flags: Order.descending).order(PrintQueueObjectBoxStruct_.createdAt);

    final query = builder.build();
    final results = query.find();
    query.close();

    if (kDebugMode && results.isNotEmpty) {
      AppLogger.info('📋 Found ${results.length} pending jobs');
    }

    return results.take(limit).toList();
  } catch (e) {
    AppLogger.error('[PrintQueue] ❌ Error getting pending jobs: $e');
    return [];
  }
}

/// อัพเดทสถานะงานพิมพ์
///
/// [updateLastAttempt] = true จะอัพเดท lastAttemptAt และ retryCount (สำหรับ retry mechanism)
Future<bool> updatePrintJobStatus({required String fileName, required PrintQueueStatus status, String? errorMessage, bool updateLastAttempt = false}) async {
  try {
    final box = objectBoxStore.box<PrintQueueObjectBoxStruct>();
    final query = box.query(PrintQueueObjectBoxStruct_.fileName.equals(fileName)).build();
    final job = query.findFirst();
    query.close();

    if (job == null) {
      AppLogger.debug('[PrintQueue] ⚠️ Job not found: $fileName');
      return false;
    }

    job.status = status.value;
    if (status == PrintQueueStatus.completed) {
      job.printedAt = DateTime.now();
    }
    if (status == PrintQueueStatus.failed) {
      job.retryCount++;
      if (errorMessage != null) {
        job.errorMessage = errorMessage;
      }
    }

    // อัพเดท lastAttemptAt สำหรับ retry mechanism
    if (updateLastAttempt) {
      job.lastAttemptAt = DateTime.now();
      job.retryCount++;
      if (errorMessage != null) {
        job.errorMessage = errorMessage;
      }
    }

    box.put(job);

    if (kDebugMode) {
      AppLogger.success('✅ Updated $fileName → ${status.label}');
      if (job.printedAt != null) {
        final duration = job.printDuration;
        AppLogger.debug('⏱️ Print duration: ${duration}ms');
      }
    }

    return true;
  } catch (e) {
    AppLogger.error('[PrintQueue] ❌ Error updating status: $e');
    return false;
  }
}

/// ดึงงานที่ล้มเหลว (status = 3)
List<PrintQueueObjectBoxStruct> getFailedPrintJobs({int maxRetries = 3, int limit = 50}) {
  try {
    final box = objectBoxStore.box<PrintQueueObjectBoxStruct>();
    final query = box.query(PrintQueueObjectBoxStruct_.status.equals(PrintQueueStatus.failed.value) & PrintQueueObjectBoxStruct_.retryCount.lessThan(maxRetries)).order(PrintQueueObjectBoxStruct_.createdAt).build();

    final results = query.find();
    query.close();

    if (kDebugMode && results.isNotEmpty) {
      AppLogger.error('⚠️ Found ${results.length} failed jobs (can retry)');
    }

    return results.take(limit).toList();
  } catch (e) {
    AppLogger.error('[PrintQueue] ❌ Error getting failed jobs: $e');
    return [];
  }
}

/// ลบงานพิมพ์เก่า (completed/failed) ที่เก่ากว่า X วัน
Future<int> cleanupOldPrintJobs({int daysToKeep = 7}) async {
  try {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final box = objectBoxStore.box<PrintQueueObjectBoxStruct>();

    final query = box
        .query((PrintQueueObjectBoxStruct_.status.equals(PrintQueueStatus.completed.value) | PrintQueueObjectBoxStruct_.status.equals(PrintQueueStatus.failed.value)) & PrintQueueObjectBoxStruct_.createdAt.lessThan(cutoffDate.millisecondsSinceEpoch))
        .build();

    final oldJobs = query.find();
    query.close();

    if (oldJobs.isEmpty) {
      AppLogger.debug('[PrintQueue] 🧹 No old jobs to cleanup');
      return 0;
    }

    // Delete old jobs
    final idsToDelete = oldJobs.map((job) => job.id).toList();
    box.removeMany(idsToDelete);

    AppLogger.debug('[PrintQueue] 🧹 Cleaned up ${idsToDelete.length} old jobs (>$daysToKeep days)');

    return idsToDelete.length;
  } catch (e) {
    // ObjectBox อาจยังไม่ถูก initialize หรือ error อื่นๆ
    if (e.toString().contains('LateInitializationError')) {
      if (kDebugMode) {
        AppLogger.debug('[PrintQueue] ⚠️ ObjectBox not initialized yet, skipping cleanup');
      }
    } else {
      AppLogger.error('[PrintQueue] ❌ Error cleaning up old jobs: $e');
    }
    return 0;
  }
}

/// ดึงข้อมูล print job จาก fileName
PrintQueueObjectBoxStruct? getPrintJobByFileName(String fileName) {
  try {
    final box = objectBoxStore.box<PrintQueueObjectBoxStruct>();
    final query = box.query(PrintQueueObjectBoxStruct_.fileName.equals(fileName)).build();
    final job = query.findFirst();
    query.close();
    return job;
  } catch (e) {
    AppLogger.error('[PrintQueue] ❌ Error getting job by fileName: $e');
    return null;
  }
}

/// Reset job status from "printing" to "pending" (สำหรับกรณี app crash)
Future<int> resetStuckPrintJobs() async {
  try {
    final box = objectBoxStore.box<PrintQueueObjectBoxStruct>();
    final query = box.query(PrintQueueObjectBoxStruct_.status.equals(PrintQueueStatus.printing.value)).build();

    final stuckJobs = query.find();
    query.close();

    if (stuckJobs.isEmpty) {
      return 0;
    }

    for (var job in stuckJobs) {
      job.status = PrintQueueStatus.pending.value;
      job.errorMessage = 'Reset from stuck printing state';
    }

    box.putMany(stuckJobs);

    AppLogger.debug('[PrintQueue] 🔄 Reset ${stuckJobs.length} stuck jobs');

    return stuckJobs.length;
  } catch (e) {
    AppLogger.error('[PrintQueue] ❌ Error resetting stuck jobs: $e');
    return 0;
  }
}

// ============================================================================
// ⭐ Upload Queue Management Functions (for JPG bill images - keep 7 days)
// ============================================================================

/// สร้างงาน upload รูปบิล (JPG) ใหม่
/// ไฟล์จะถูกเก็บไว้ 7 วัน หลังจาก upload สำเร็จ
/// ถ้ามี fileName ซ้ำจะ skip (ไม่ insert ใหม่)
Future<bool> createUploadJob({required String fileName, required String filePath, required String docNumber, String metadata = ''}) async {
  try {
    if (kDebugMode) {
      AppLogger.debug('[UploadQueue] 💾 Creating upload job...');
      AppLogger.debug('[UploadQueue]    📄 File: $fileName');
      AppLogger.debug('[UploadQueue]    📋 Doc: $docNumber');
    }

    final box = objectBoxStore.box<UploadQueueObjectBoxStruct>();

    // ⭐ ตรวจสอบว่ามี fileName ซ้ำหรือไม่ (ป้องกัน Unique constraint violation)
    final existingQuery = box.query(UploadQueueObjectBoxStruct_.fileName.equals(fileName)).build();
    final existing = existingQuery.findFirst();
    existingQuery.close();

    if (existing != null) {
      if (kDebugMode) {
        AppLogger.debug('[UploadQueue] ⏭️ Skip - fileName already exists: $fileName (ID: ${existing.id}, Status: ${existing.statusEnum.label})');
      }
      return true; // ถือว่าสำเร็จ เพราะมีอยู่แล้ว
    }

    // เช็คขนาดไฟล์
    int fileSize = 0;
    final file = File(filePath);
    if (await file.exists()) {
      fileSize = await file.length();
      if (kDebugMode) {
        final sizeKB = (fileSize / 1024).toStringAsFixed(2);
        AppLogger.debug('[UploadQueue]    📦 Size: $sizeKB KB');
      }
    }

    final queue = UploadQueueObjectBoxStruct(fileName: fileName, filePath: filePath, docNumber: docNumber, status: UploadQueueStatus.pending.value, createdAt: DateTime.now(), retryCount: 0, errorMessage: '', fileSize: fileSize, metadata: metadata);

    box.put(queue);

    AppLogger.debug('[UploadQueue] ✅ Created job with ID: ${queue.id}');

    return true;
  } catch (e, stackTrace) {
    if (kDebugMode) {
      AppLogger.error('[UploadQueue] ❌ Failed to create job: $e');
      AppLogger.debug('Stack: $stackTrace');
    }

    sendErrorToDevTeam('createUploadJob', 'Failed to create upload job: $fileName\nError: $e\n$stackTrace');

    return false;
  }
}

/// ดึงงาน upload ที่รอคิว (status = 0)
List<UploadQueueObjectBoxStruct> getPendingUploadJobs({String? docNumber, int limit = 100}) {
  try {
    final box = objectBoxStore.box<UploadQueueObjectBoxStruct>();

    // Build query condition
    Condition<UploadQueueObjectBoxStruct> condition = UploadQueueObjectBoxStruct_.status.equals(UploadQueueStatus.pending.value);

    // Filter by docNumber if specified
    if (docNumber != null && docNumber.isNotEmpty) {
      condition = condition & UploadQueueObjectBoxStruct_.docNumber.equals(docNumber);
    }

    final query = box.query(condition).order(UploadQueueObjectBoxStruct_.createdAt).build();

    final results = query.find();
    query.close();

    if (kDebugMode && results.isNotEmpty) {
      AppLogger.info('[UploadQueue] 📋 Found ${results.length} pending jobs');
    }

    return results.take(limit).toList();
  } catch (e) {
    AppLogger.error('[UploadQueue] ❌ Error getting pending jobs: $e');
    return [];
  }
}

/// อัพเดทสถานะงาน upload
Future<bool> updateUploadJobStatus({required String fileName, required UploadQueueStatus status, String? errorMessage}) async {
  try {
    final box = objectBoxStore.box<UploadQueueObjectBoxStruct>();
    final query = box.query(UploadQueueObjectBoxStruct_.fileName.equals(fileName)).build();
    final job = query.findFirst();
    query.close();

    if (job == null) {
      AppLogger.debug('[UploadQueue] ⚠️ Job not found: $fileName');
      return false;
    }

    job.status = status.value;
    if (status == UploadQueueStatus.completed) {
      job.uploadedAt = DateTime.now();
    }
    if (status == UploadQueueStatus.failed) {
      job.retryCount++;
      if (errorMessage != null) {
        job.errorMessage = errorMessage;
      }
    }

    box.put(job);

    if (kDebugMode) {
      AppLogger.success('[UploadQueue] ✅ Updated $fileName → ${status.label}');
      if (job.uploadedAt != null) {
        final duration = job.uploadDuration;
        AppLogger.debug('[UploadQueue]    ⏱️ Upload duration: ${duration}ms');
      }
    }

    return true;
  } catch (e) {
    AppLogger.error('[UploadQueue] ❌ Error updating status: $e');
    return false;
  }
}

/// ดึงงานที่ upload เสร็จแล้ว และเก่ากว่า X วัน (สำหรับ cleanup)
List<UploadQueueObjectBoxStruct> getCompletedUploadJobsOlderThan({int days = 7, int limit = 100}) {
  try {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final box = objectBoxStore.box<UploadQueueObjectBoxStruct>();

    final query = box.query(UploadQueueObjectBoxStruct_.status.equals(UploadQueueStatus.completed.value) & UploadQueueObjectBoxStruct_.uploadedAt.lessThan(cutoffDate.millisecondsSinceEpoch)).order(UploadQueueObjectBoxStruct_.uploadedAt).build();

    final results = query.find();
    query.close();

    if (kDebugMode && results.isNotEmpty) {
      AppLogger.info('[UploadQueue] 🧹 Found ${results.length} completed jobs older than $days days');
    }

    return results.take(limit).toList();
  } catch (e) {
    // ObjectBox อาจยังไม่ถูก initialize หรือ error อื่นๆ
    if (e.toString().contains('LateInitializationError')) {
      if (kDebugMode) {
        AppLogger.debug('[UploadQueue] ⚠️ ObjectBox not initialized yet, skipping cleanup');
      }
    } else {
      AppLogger.error('[UploadQueue] ❌ Error getting old completed jobs: $e');
    }
    return [];
  }
}

/// ดึงงานที่ล้มเหลว (status = 3) และยังสามารถ retry ได้
List<UploadQueueObjectBoxStruct> getFailedUploadJobs({int maxRetries = 3, int limit = 50}) {
  try {
    final box = objectBoxStore.box<UploadQueueObjectBoxStruct>();
    final query = box.query(UploadQueueObjectBoxStruct_.status.equals(UploadQueueStatus.failed.value) & UploadQueueObjectBoxStruct_.retryCount.lessThan(maxRetries)).order(UploadQueueObjectBoxStruct_.createdAt).build();

    final results = query.find();
    query.close();

    if (kDebugMode && results.isNotEmpty) {
      AppLogger.warning('[UploadQueue] ⚠️ Found ${results.length} failed jobs (can retry)');
    }

    return results.take(limit).toList();
  } catch (e) {
    AppLogger.error('[UploadQueue] ❌ Error getting failed jobs: $e');
    return [];
  }
}

/// ลบงาน upload พร้อมไฟล์ (สำหรับไฟล์ที่เก่ากว่า 7 วัน)
Future<int> cleanupOldUploadJobsAndFiles({int daysToKeep = 7}) async {
  try {
    final oldJobs = getCompletedUploadJobsOlderThan(days: daysToKeep);

    if (oldJobs.isEmpty) {
      AppLogger.debug('[UploadQueue] 🧹 No old jobs to cleanup');
      return 0;
    }

    int filesDeleted = 0;
    int bytesFreed = 0;
    final box = objectBoxStore.box<UploadQueueObjectBoxStruct>();

    for (var job in oldJobs) {
      try {
        // ลบไฟล์จริง
        final file = File(job.filePath);
        if (await file.exists()) {
          final fileSize = await file.length();
          await file.delete();
          filesDeleted++;
          bytesFreed += fileSize;

          if (kDebugMode) {
            final sizeKB = (fileSize / 1024).toStringAsFixed(2);
            AppLogger.debug('[UploadQueue]    🗑️ Deleted: ${job.fileName} ($sizeKB KB)');
          }
        }

        // ลบ record จาก ObjectBox
        box.remove(job.id);
      } catch (e) {
        AppLogger.error('[UploadQueue]    ⚠️ Failed to delete ${job.fileName}: $e');
      }
    }

    if (kDebugMode) {
      final mbFreed = (bytesFreed / (1024 * 1024)).toStringAsFixed(2);
      AppLogger.success('[UploadQueue] 🧹 Cleaned up $filesDeleted files (${mbFreed} MB)');
    }

    return filesDeleted;
  } catch (e) {
    // ObjectBox อาจยังไม่ถูก initialize หรือ error อื่นๆ
    if (e.toString().contains('LateInitializationError')) {
      if (kDebugMode) {
        AppLogger.debug('[UploadQueue] ⚠️ ObjectBox not initialized yet, skipping cleanup');
      }
    } else {
      AppLogger.error('[UploadQueue] ❌ Error cleaning up old jobs: $e');
    }
    return 0;
  }
}

/// ดึงข้อมูล upload job จาก fileName
UploadQueueObjectBoxStruct? getUploadJobByFileName(String fileName) {
  try {
    final box = objectBoxStore.box<UploadQueueObjectBoxStruct>();
    final query = box.query(UploadQueueObjectBoxStruct_.fileName.equals(fileName)).build();
    final job = query.findFirst();
    query.close();
    return job;
  } catch (e) {
    AppLogger.error('[UploadQueue] ❌ Error getting job by fileName: $e');
    return null;
  }
}

/// ดึงข้อมูล upload jobs ตาม docNumber
List<UploadQueueObjectBoxStruct> getUploadJobsByDocNumber(String docNumber) {
  try {
    final box = objectBoxStore.box<UploadQueueObjectBoxStruct>();
    final query = box.query(UploadQueueObjectBoxStruct_.docNumber.equals(docNumber)).order(UploadQueueObjectBoxStruct_.createdAt).build();
    final jobs = query.find();
    query.close();
    return jobs;
  } catch (e) {
    AppLogger.error('[UploadQueue] ❌ Error getting jobs by docNumber: $e');
    return [];
  }
}

/// Reset job status from "uploading" to "pending" (สำหรับกรณี app crash)
Future<int> resetStuckUploadJobs() async {
  try {
    final box = objectBoxStore.box<UploadQueueObjectBoxStruct>();
    final query = box.query(UploadQueueObjectBoxStruct_.status.equals(UploadQueueStatus.uploading.value)).build();

    final stuckJobs = query.find();
    query.close();

    if (stuckJobs.isEmpty) {
      return 0;
    }

    for (var job in stuckJobs) {
      job.status = UploadQueueStatus.pending.value;
      job.errorMessage = 'Reset from stuck uploading state';
    }

    box.putMany(stuckJobs);

    AppLogger.debug('[UploadQueue] 🔄 Reset ${stuckJobs.length} stuck jobs');

    return stuckJobs.length;
  } catch (e) {
    AppLogger.error('[UploadQueue] ❌ Error resetting stuck jobs: $e');
    return 0;
  }
}

// ============================================================
// 🎁 Tier Stock Management Helper Functions
// ============================================================
// สำหรับจัดการจำนวนสินค้าคงเหลือของแต่ละ Tier (Type 102)

/// 📦 ดึงข้อมูล Tier Stock จาก tier_level
///
/// **Returns:** TierStockStruct หรือ null ถ้าไม่เจอ
TierStockStruct? getTierStock(int tierLevel) {
  try {
    final box = objectBoxStore.box<TierStockStruct>();
    final query = box.query(TierStockStruct_.tier_level.equals(tierLevel)).build();
    final result = query.findFirst();
    query.close();

    if (result != null) {
      if (kDebugMode) {
        AppLogger.debug('[TierStock] 📦 Tier $tierLevel: ${result.remaining_stock} items');
      }
    }

    return result;
  } catch (e) {
    AppLogger.error('[TierStock] ❌ Error getting tier stock: $e');
    return null;
  }
}

/// 🔄 สร้างหรืออัปเดต Tier Stock
///
/// **Parameters:**
/// - tierLevel: ระดับ Tier (1-5)
/// - promotionCode: รหัสโปรโมชั่น
/// - remainingStock: จำนวนสินค้าคงเหลือ (default = 0)
///
/// **Returns:** TierStockStruct ที่สร้างหรืออัปเดต
TierStockStruct updateTierStock({required int tierLevel, required String promotionCode, required int remainingStock}) {
  try {
    final box = objectBoxStore.box<TierStockStruct>();

    // ตรวจสอบว่ามีอยู่แล้วหรือไม่
    final query = box.query(TierStockStruct_.tier_level.equals(tierLevel)).build();
    TierStockStruct? existing = query.findFirst();
    query.close();

    if (existing != null) {
      // อัปเดตข้อมูลเดิม
      existing.promotion_code = promotionCode;
      existing.setStock(remainingStock);
      box.put(existing);

      AppLogger.info('[TierStock] ✏️ Updated Tier $tierLevel: $remainingStock items (${existing.promotion_code})');

      return existing;
    } else {
      // สร้างใหม่
      final newStock = TierStockStruct(tier_level: tierLevel, promotion_code: promotionCode, remaining_stock: remainingStock);
      box.put(newStock);

      AppLogger.info('[TierStock] ➕ Created Tier $tierLevel: $remainingStock items ($promotionCode)');

      return newStock;
    }
  } catch (e) {
    AppLogger.error('[TierStock] ❌ Error updating tier stock: $e');
    rethrow;
  }
}

/// ➖ ลดจำนวนสินค้าใน Tier ลง 1 (เรียกหลังพิมพ์บิล)
///
/// **Parameters:**
/// - tierLevel: ระดับ Tier ที่ต้องการลด
///
/// **Returns:** จำนวนสินค้าคงเหลือหลังลด หรือ -1 ถ้าไม่เจอ/error
int decrementTierStock(int tierLevel) {
  try {
    final box = objectBoxStore.box<TierStockStruct>();
    final query = box.query(TierStockStruct_.tier_level.equals(tierLevel)).build();
    TierStockStruct? stock = query.findFirst();
    query.close();

    if (stock == null) {
      AppLogger.warning('[TierStock] ⚠️ Tier $tierLevel not found, cannot decrement');
      return -1;
    }

    if (stock.remaining_stock <= 0) {
      AppLogger.warning('[TierStock] ⚠️ Tier $tierLevel already empty (${stock.remaining_stock})');
      return 0;
    }

    stock.decrementStock();
    box.put(stock);

    if (stock.remaining_stock == 0) {
      AppLogger.info('[TierStock] 🚫 Tier $tierLevel is now EMPTY!');
    } else {
      AppLogger.debug('[TierStock] ➖ Tier $tierLevel: ${stock.remaining_stock} items left');
    }

    return stock.remaining_stock;
  } catch (e) {
    AppLogger.error('[TierStock] ❌ Error decrementing tier stock: $e');
    return -1;
  }
}

/// 🔄 ตั้งค่าจำนวนสินค้าใหม่ (สำหรับเติมของแถม)
///
/// **Parameters:**
/// - tierLevel: ระดับ Tier
/// - newStock: จำนวนสินค้าใหม่
///
/// **Returns:** true ถ้าสำเร็จ
bool setTierStock(int tierLevel, int newStock) {
  try {
    final box = objectBoxStore.box<TierStockStruct>();
    final query = box.query(TierStockStruct_.tier_level.equals(tierLevel)).build();
    TierStockStruct? stock = query.findFirst();
    query.close();

    if (stock == null) {
      AppLogger.warning('[TierStock] ⚠️ Tier $tierLevel not found, cannot set stock');
      return false;
    }

    final oldStock = stock.remaining_stock;
    stock.setStock(newStock);
    box.put(stock);

    AppLogger.info('[TierStock] 🔄 Tier $tierLevel: $oldStock → $newStock items');

    return true;
  } catch (e) {
    AppLogger.error('[TierStock] ❌ Error setting tier stock: $e');
    return false;
  }
}

/// 📊 ดึงข้อมูล Tier Stock ทั้งหมด (เรียงตาม tier_level)
///
/// **Returns:** List ของ TierStockStruct ทั้งหมด
List<TierStockStruct> getAllTierStocks() {
  try {
    final box = objectBoxStore.box<TierStockStruct>();
    final query = box.query().order(TierStockStruct_.tier_level).build();
    final results = query.find();
    query.close();

    if (kDebugMode) {
      AppLogger.debug('[TierStock] 📊 Found ${results.length} tier stocks');
      for (var stock in results) {
        AppLogger.debug('  - Tier ${stock.tier_level}: ${stock.remaining_stock} items');
      }
    }

    return results;
  } catch (e) {
    AppLogger.error('[TierStock] ❌ Error getting all tier stocks: $e');
    return [];
  }
}

/// 🎯 ดึงเฉพาะ Tier ที่ยังมีสินค้า (remaining_stock > 0)
///
/// **Returns:** List ของ TierStockStruct ที่มีสินค้าคงเหลือ
List<TierStockStruct> getAvailableTierStocks() {
  try {
    final box = objectBoxStore.box<TierStockStruct>();
    final query = box.query(TierStockStruct_.remaining_stock.greaterThan(0)).order(TierStockStruct_.tier_level).build();
    final results = query.find();
    query.close();

    if (kDebugMode) {
      AppLogger.debug('[TierStock] 🎯 ${results.length} tiers have stock available');
    }

    return results;
  } catch (e) {
    AppLogger.error('[TierStock] ❌ Error getting available tier stocks: $e');
    return [];
  }
}

/// 🔄 รีเซ็ตจำนวนสินค้าทั้งหมดเป็น 0 (ใช้เมื่อต้องการเริ่มใหม่)
///
/// **Returns:** จำนวน Tier ที่รีเซ็ต
int resetAllTierStocks() {
  try {
    final box = objectBoxStore.box<TierStockStruct>();
    final allStocks = box.getAll();

    for (var stock in allStocks) {
      stock.setStock(0);
    }

    box.putMany(allStocks);

    AppLogger.info('[TierStock] 🔄 Reset ${allStocks.length} tier stocks to 0');

    return allStocks.length;
  } catch (e) {
    AppLogger.error('[TierStock] ❌ Error resetting tier stocks: $e');
    return 0;
  }
}

/// 🗑️ ลบ Tier Stock ทั้งหมด (ใช้เมื่อต้องการลบข้อมูลทิ้ง)
///
/// **Returns:** จำนวน Tier ที่ลบ
int deleteAllTierStocks() {
  try {
    final box = objectBoxStore.box<TierStockStruct>();
    final count = box.count();
    box.removeAll();

    AppLogger.info('[TierStock] 🗑️ Deleted $count tier stocks');

    return count;
  } catch (e) {
    AppLogger.error('[TierStock] ❌ Error deleting tier stocks: $e');
    return 0;
  }
}

/// 🎯 เลือก Tier ที่เหมาะสมตามยอดซื้อและสต็อกคงเหลือ
///
/// **Logic:**
/// 1. ตรวจสอบยอดซื้อ (totalAmount)
/// 2. เริ่มจาก Tier สูงสุดที่คุณสมบัติผ่าน (Tier 5 → 4 → 3 → 2 → 1)
/// 3. ตรวจสอบว่า Tier นั้นมีสต็อกเหลือหรือไม่ (remaining_stock > 0)
/// 4. ถ้าหมดสต็อก → ข้าม → ตรวจสอบ Tier ถัดลง
/// 5. คืนค่า Tier แรกที่มีสต็อกเหลือ
///
/// **Parameters:**
/// - totalAmount: ยอดซื้อรวม (บาท)
///
/// **Returns:**
/// - tier_level (1-5) ถ้าเจอ Tier ที่มีสต็อก
/// - null ถ้าไม่มี Tier ไหนคุณสมบัติผ่าน หรือ ทุก Tier หมดสต็อก
///
/// **Example:**
/// ```dart
/// // ยอดซื้อ 7,500฿
/// int? tier = selectAvailableTier(7500);
/// // tier = 5 (ถ้า Tier 5 มีสต็อก)
/// // tier = 4 (ถ้า Tier 5 หมด แต่ Tier 4 มีสต็อก)
/// ```
int? selectAvailableTier(double totalAmount) {
  if (kDebugMode) {
    AppLogger.debug('[TierStock] 🎯 Selecting tier for amount: ฿${totalAmount.toStringAsFixed(2)}');
  }

  // กำหนด threshold ของแต่ละ Tier (จากสูงไปต่ำ)
  const tierThresholds = [
    {'tier': 5, 'threshold': 7000.0},
    {'tier': 4, 'threshold': 5000.0},
    {'tier': 3, 'threshold': 2000.0},
    {'tier': 2, 'threshold': 1000.0},
    {'tier': 1, 'threshold': 0.0},
  ];

  try {
    // วนตรวจสอบจาก Tier 5 → 1
    for (var tierConfig in tierThresholds) {
      final tierLevel = tierConfig['tier'] as int;
      final threshold = tierConfig['threshold'] as double;

      // ตรวจสอบว่ายอดซื้อถึง threshold หรือไม่
      if (totalAmount >= threshold) {
        // ดึงข้อมูลสต็อก
        final stock = getTierStock(tierLevel);

        if (stock != null && stock.remaining_stock > 0) {
          // เจอ Tier ที่มีสต็อก!
          AppLogger.info('[TierStock] ✅ Selected Tier $tierLevel (฿$threshold+) - Stock: ${stock.remaining_stock} items');
          return tierLevel;
        } else {
          // Tier นี้หมดสต็อก → ข้ามไปต่อ
          if (kDebugMode) {
            AppLogger.debug('[TierStock] ⏭️ Tier $tierLevel out of stock, checking next tier...');
          }
        }
      }
    }

    // ไม่เจอ Tier ไหนเลย (ทุก Tier หมดหรือยอดไม่ถึง)
    AppLogger.warning('[TierStock] ⚠️ No available tier for amount: ฿${totalAmount.toStringAsFixed(2)}');
    return null;
  } catch (e) {
    AppLogger.error('[TierStock] ❌ Error selecting tier: $e');
    return null;
  }
}

/// 🔄 โหลด Tier Promotions จาก CSV (พร้อม Cache 5 นาที)
///
/// **Cache Logic:**
/// - ถ้า cache ยังไม่หมดอายุ (< 5 นาที) → ใช้ cache
/// - ถ้า cache หมดอายุหรือไม่มี → โหลดใหม่จาก CSV
///
/// **Returns:** PromotionMainModel ที่มี Type 102 ทั้งหมด
// Future<PromotionMainModel> loadTierPromotions({bool forceReload = false}) async {
//   try {
//     final now = DateTime.now();

//     // ตรวจสอบ cache (5 นาที = 300 วินาที)
//     if (!forceReload && tierPromotionCache != null && tierCsvLastLoaded != null) {
//       final diff = now.difference(tierCsvLastLoaded!);

//       if (diff.inSeconds < 300) {
//         // Cache ยังใช้ได้
//         if (kDebugMode) {
//           AppLogger.debug('[TierCSV] 📦 Using cache (age: ${diff.inSeconds}s)');
//         }
//         return tierPromotionCache!;
//       }
//     }

//     // โหลดใหม่จาก CSV
//     if (kDebugMode) {
//       AppLogger.info('[TierCSV] 🔄 Loading Tier promotions from CSV...');
//     }

//     final promotion = await PosMockPromotion.getTierRedemptionPromotions();

//     // บันทึก cache
//     tierPromotionCache = promotion;
//     tierCsvLastLoaded = now;

//     AppLogger.info('[TierCSV] ✅ Loaded ${promotion.promotion_list.length} tier promotions');

//     return promotion;
//   } catch (e) {
//     AppLogger.error('[TierCSV] ❌ Error loading tier promotions: $e');

//     // ถ้าเกิด error แต่มี cache เก่า → ใช้ cache เก่า
//     if (tierPromotionCache != null) {
//       AppLogger.warning('[TierCSV] ⚠️ Using old cache due to error');
//       return tierPromotionCache!;
//     }

//     rethrow;
//   }
// }
