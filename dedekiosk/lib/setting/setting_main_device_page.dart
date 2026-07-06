import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/setting/register_order_station_page.dart';
import 'package:dedekiosk/setting/select_printer_page.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class SettingMainDevicePage extends StatefulWidget {
  const SettingMainDevicePage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingMainDevicePageState();
}

class _SettingMainDevicePageState extends State<SettingMainDevicePage> {
  TextEditingController pinCodeController = TextEditingController();
  TextEditingController deviceNameController = TextEditingController();
  late TextEditingController itemsPerRowController;
  late TextEditingController orderHereTextController;
  Timer? _debounceTimer;
  bool _isAdvancedSettingsExpanded = false;
  bool _isEditingDeviceName = false;
  static const mcdonaldsRed = Color(0xFFDA291C);

  // Showcase keys for first-time guide
  final GlobalKey _deviceNameKey = GlobalKey();
  final GlobalKey _connectButtonKey = GlobalKey();
  final GlobalKey _takeAwayKey = GlobalKey();
  final GlobalKey _itemsPerRowKey = GlobalKey();
  final GlobalKey _deviceRoleKey = GlobalKey();
  final GlobalKey _printerSectionKey = GlobalKey();
  // Context from ShowCaseWidget builder for starting showcase
  BuildContext? _showcaseContext;
  bool _showcaseShown = false; // Track if showcase has been shown this session

  // ✅ Temporary state for tracking unsaved changes
  bool _hasUnsavedChanges = false;
  late String _tempDeviceId;
  late bool _tempUseOrderEatAtTheRestaurant;
  late bool _tempUseOrderTakeAway;
  late bool _tempOrderOnlineCondition;
  late bool _tempIsServer;
  late int _tempMachineCondition;
  late int _tempCashierKitchenTiming;
  late int _tempItemsPerRow;
  late String _tempOrderHereText;
  late String _tempOrderHereTextColor;
  late String _tempOrderHereTextColor2;
  late String _tempOrderHereShadowColor;
  late int _tempOrderLayoutPreset;
  late String _tempPrimaryThemeColor;
  late String _tempPrimaryTextColor;
  late PrinterLocalConfigModel _tempPrinterForOrderStation;
  late PrinterLocalConfigModel _tempPrinterForOwner;
  late List<KitchenDeviceModel> _tempKitchens;

  Color get primaryThemeColor {
    return _hexToColor(_tempPrimaryThemeColor);
  }

  // Helper function to convert hex string to Color
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  // Helper function to convert Color to hex string
  String _colorToHex(Color color) {
    final a = (color.a * 255).round().toRadixString(16).padLeft(2, '0');
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$a$r$g$b'.toUpperCase();
  }

  // Generate random device name
  String _generateRandomDeviceName() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomPart =
        List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
    return 'KIOSK-$randomPart';
  }

  // ✅ แก้ไข: อัพเดท temp state และ mark dirty เท่านั้น ไม่บันทึกทันที
  void _debouncedUpdate(VoidCallback updateFunction,
      {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      if (mounted) {
        setState(() {
          updateFunction();
          _hasUnsavedChanges = true;
        });
      }
    });
  }

  // ✅ Method สำหรับโหลดค่าจาก saved config
  void _loadSavedConfig() {
    _tempDeviceId = global.deviceConfig.deviceId;
    _tempUseOrderEatAtTheRestaurant =
        global.deviceConfig.useOrderEatAtTheRestaurant;
    _tempUseOrderTakeAway = global.deviceConfig.useOrderTakeAway;
    _tempOrderOnlineCondition = global.deviceConfig.orderOnlineCondition;
    _tempIsServer = global.deviceConfig.isServer;
    _tempMachineCondition = global.deviceConfig.machineCondition;
    _tempCashierKitchenTiming = global.deviceConfig.cashierKitchenTiming;
    _tempItemsPerRow = global.deviceConfig.itemsPerRow;
    _tempOrderHereText = global.deviceConfig.orderHereText;
    _tempOrderHereTextColor = global.deviceConfig.orderHereTextColor;
    _tempOrderHereTextColor2 = global.deviceConfig.orderHereTextColor2;
    _tempOrderHereShadowColor = global.deviceConfig.orderHereShadowColor;
    _tempOrderLayoutPreset = global.deviceConfig.orderLayoutPreset;
    _tempPrimaryThemeColor = global.deviceConfig.primaryThemeColor;
    _tempPrimaryTextColor = global.deviceConfig.primaryTextColor;

    // Copy printer configs
    _tempPrinterForOrderStation = PrinterLocalConfigModel(
      code: global.deviceConfig.printerForOrderStation.code,
      name: global.deviceConfig.printerForOrderStation.name,
      ipAddress: global.deviceConfig.printerForOrderStation.ipAddress,
      ipPort: global.deviceConfig.printerForOrderStation.ipPort,
      productName: global.deviceConfig.printerForOrderStation.productName,
      deviceName: global.deviceConfig.printerForOrderStation.deviceName,
      deviceId: global.deviceConfig.printerForOrderStation.deviceId,
      manufacturer: global.deviceConfig.printerForOrderStation.manufacturer,
      vendorId: global.deviceConfig.printerForOrderStation.vendorId,
      productId: global.deviceConfig.printerForOrderStation.productId,
      paperType: global.deviceConfig.printerForOrderStation.paperType,
      printBillAuto: global.deviceConfig.printerForOrderStation.printBillAuto,
      printerType: global.deviceConfig.printerForOrderStation.printerType,
      printerConnectType:
          global.deviceConfig.printerForOrderStation.printerConnectType,
      isConfigConnectSuccess:
          global.deviceConfig.printerForOrderStation.isConfigConnectSuccess,
      isReady: global.deviceConfig.printerForOrderStation.isReady,
      formSummeryCode:
          global.deviceConfig.printerForOrderStation.formSummeryCode,
      formTaxCode: global.deviceConfig.printerForOrderStation.formTaxCode,
      formFullTaxCode:
          global.deviceConfig.printerForOrderStation.formFullTaxCode,
    );

    _tempPrinterForOwner = PrinterLocalConfigModel(
      code: global.deviceConfig.printerForOwner.code,
      name: global.deviceConfig.printerForOwner.name,
      ipAddress: global.deviceConfig.printerForOwner.ipAddress,
      ipPort: global.deviceConfig.printerForOwner.ipPort,
      productName: global.deviceConfig.printerForOwner.productName,
      deviceName: global.deviceConfig.printerForOwner.deviceName,
      deviceId: global.deviceConfig.printerForOwner.deviceId,
      manufacturer: global.deviceConfig.printerForOwner.manufacturer,
      vendorId: global.deviceConfig.printerForOwner.vendorId,
      productId: global.deviceConfig.printerForOwner.productId,
      paperType: global.deviceConfig.printerForOwner.paperType,
      printBillAuto: global.deviceConfig.printerForOwner.printBillAuto,
      printerType: global.deviceConfig.printerForOwner.printerType,
      printerConnectType:
          global.deviceConfig.printerForOwner.printerConnectType,
      isConfigConnectSuccess:
          global.deviceConfig.printerForOwner.isConfigConnectSuccess,
      isReady: global.deviceConfig.printerForOwner.isReady,
      formSummeryCode: global.deviceConfig.printerForOwner.formSummeryCode,
      formTaxCode: global.deviceConfig.printerForOwner.formTaxCode,
      formFullTaxCode: global.deviceConfig.printerForOwner.formFullTaxCode,
    );

    // Deep copy kitchens list
    _tempKitchens = global.deviceConfig.kitchens.map((kitchen) {
      return KitchenDeviceModel(
        code: kitchen.code,
        names: List.from(kitchen.names),
      )..printer = PrinterLocalConfigModel(
          code: kitchen.printer.code,
          name: kitchen.printer.name,
          ipAddress: kitchen.printer.ipAddress,
          ipPort: kitchen.printer.ipPort,
          productName: kitchen.printer.productName,
          deviceName: kitchen.printer.deviceName,
          deviceId: kitchen.printer.deviceId,
          manufacturer: kitchen.printer.manufacturer,
          vendorId: kitchen.printer.vendorId,
          productId: kitchen.printer.productId,
          paperType: kitchen.printer.paperType,
          printBillAuto: kitchen.printer.printBillAuto,
          printerType: kitchen.printer.printerType,
          printerConnectType: kitchen.printer.printerConnectType,
          isConfigConnectSuccess: kitchen.printer.isConfigConnectSuccess,
          isReady: kitchen.printer.isReady,
          formSummeryCode: kitchen.printer.formSummeryCode,
          formTaxCode: kitchen.printer.formTaxCode,
          formFullTaxCode: kitchen.printer.formFullTaxCode,
        );
    }).toList();

    _hasUnsavedChanges = false;
  }

  void comparePrinter() {
    if (global.shopProfile == null || global.shopProfile!.kitchens == null) {
      return;
    }
    for (int i = 0; i < global.shopProfile!.kitchens!.length; i++) {
      bool found = false;
      for (int j = 0; j < global.deviceConfig.kitchens.length; j++) {
        if (global.shopProfile!.kitchens![i].code ==
            global.deviceConfig.kitchens[j].code) {
          found = true;
          break;
        }
      }
      if (found == false) {
        global.deviceConfig.kitchens.add(KitchenDeviceModel(
          code: global.shopProfile!.kitchens![i].code,
          names: global.shopProfile!.kitchens![i].names,
        ));
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // ✅ โหลดค่าจาก saved config ลงใน temporary state
    _loadSavedConfig();

    // Initialize itemsPerRowController with temp value
    itemsPerRowController =
        TextEditingController(text: _tempItemsPerRow.toString());
    // Initialize orderHereTextController with temp value
    orderHereTextController =
        TextEditingController(text: _tempOrderHereText.replaceAll('\n', '\\n'));

    try {
      if (global.deviceConfig.deviceId.isEmpty) {
        // Generate random device name when empty
        final randomName = _generateRandomDeviceName();
        global.deviceConfig.deviceId = randomName;
        _tempDeviceId = randomName;
        deviceNameController.text = randomName;
        // Save the generated name immediately (special case)
        Future.microtask(() async {
          if (mounted) {
            await global.saveDeviceConfigToStorage(context);
            setState(() {});
          }
        });
      } else {
        deviceNameController.text = _tempDeviceId;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    comparePrinter();

    // Start showcase guide when entering this page for the first time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowShowcase();
    });
  }

  // Check if showcase should be shown (only first time)
  Future<void> _checkAndShowShowcase() async {
    if (_showcaseShown) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenShowcase =
        prefs.getBool('setting_main_device_showcase_seen') ?? false;

    if (!hasSeenShowcase && mounted && _showcaseContext != null) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && _showcaseContext != null) {
        _showcaseShown = true;

        // Build showcase list based on available sections
        List<GlobalKey> showcaseKeys = [
          _deviceNameKey,
          _connectButtonKey,
        ];

        // Add additional keys only if shop is configured
        if (global.deviceConfig.shopId.isNotEmpty) {
          showcaseKeys.addAll([
            _takeAwayKey,
            _itemsPerRowKey,
          ]);

          // Add device role key only if shopPaymentCondition == 0
          if (global.deviceConfig.shopPaymentCondition == 0) {
            showcaseKeys.add(_deviceRoleKey);
          }

          showcaseKeys.add(_printerSectionKey);
        }

        ShowCaseWidget.of(_showcaseContext!).startShowCase(showcaseKeys);
        // Mark showcase as seen after showing
        await prefs.setBool('setting_main_device_showcase_seen', true);
      }
    }
  }

  /// Scroll to the widget being showcased (for small screens)
  /// ใช้ async เพื่อรอให้ scroll เสร็จก่อน แล้ว showcase ค่อย recalculate position
  void _scrollToShowcaseWidget(GlobalKey key) {
    try {
      final keyContext = key.currentContext;
      if (keyContext != null && mounted) {
        // Scroll to widget first, then let showcase recalculate
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: 0.5, // Position widget at center
        ).then((_) {
          // Force rebuild after scroll completes
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) setState(() {});
            });
          }
        });
      }
    } catch (e) {
      // Ignore scroll errors
      if (kDebugMode) {
        print('Showcase scroll error: $e');
      }
    }
  }

  // ✅ Method สำหรับบันทึกค่าทั้งหมด
  Future<void> _saveAllSettings() async {
    try {
      // แสดง loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // คัดลอกค่าจาก temp ไปยัง global.deviceConfig
      global.deviceConfig.deviceId = _tempDeviceId;
      global.deviceConfig.useOrderEatAtTheRestaurant =
          _tempUseOrderEatAtTheRestaurant;
      global.deviceConfig.useOrderTakeAway = _tempUseOrderTakeAway;
      global.deviceConfig.orderOnlineCondition = _tempOrderOnlineCondition;
      if (!_tempOrderOnlineCondition) {
        global.deviceConfig.showQrCodeOrderOnline = false;
      }
      global.deviceConfig.isServer = _tempIsServer;
      global.deviceConfig.machineCondition = _tempMachineCondition;
      global.deviceConfig.cashierKitchenTiming = _tempCashierKitchenTiming;
      global.deviceConfig.itemsPerRow = _tempItemsPerRow;
      global.deviceConfig.orderHereText = _tempOrderHereText;
      global.deviceConfig.orderHereTextColor = _tempOrderHereTextColor;
      global.deviceConfig.orderHereTextColor2 = _tempOrderHereTextColor2;
      global.deviceConfig.orderHereShadowColor = _tempOrderHereShadowColor;
      global.deviceConfig.orderLayoutPreset = _tempOrderLayoutPreset;
      global.deviceConfig.primaryThemeColor = _tempPrimaryThemeColor;
      global.deviceConfig.primaryTextColor = _tempPrimaryTextColor;

      // Copy printer configs
      global.deviceConfig.printerForOrderStation = _tempPrinterForOrderStation;
      global.deviceConfig.printerForOwner = _tempPrinterForOwner;
      global.deviceConfig.kitchens = _tempKitchens;

      // บันทึกลง storage
      await global.saveDeviceConfigToStorage(context);

      // ปิด loading
      if (mounted) Navigator.pop(context);

      // แสดง success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ บันทึกการตั้งค่าเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // รีเซ็ต dirty flag
      setState(() {
        _hasUnsavedChanges = false;
      });
    } catch (e) {
      // ปิด loading
      if (mounted) Navigator.pop(context);

      // แสดง error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Method แสดง dialog เตือนก่อนออกโดยไม่บันทึก
  Future<bool?> _showUnsavedChangesDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('มีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก'),
        content: const Text(
            'คุณต้องการออกจากหน้านี้โดยไม่บันทึกการเปลี่ยนแปลงหรือไม่?\n\n'
            'การเปลี่ยนแปลงทั้งหมดจะสูญหาย'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('ออกโดยไม่บันทึก'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
/*    try {
      // clear database
      api.clickHouseExecute(
          "alter table ordertemp UPDATE isprintkitchensuccess=1 WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}'");
      api.clickHouseExecute(
          "alter table ordertemp update isclose=2 where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and isclose=1");
      // update ordertemodoc isclose=2
      api.clickHouseExecute(
          "alter table ordertempdoc update isclose=2 where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and isclose=1");
    } catch (e,s) {
      print(e);
    }*/
    pinCodeController.dispose();
    deviceNameController.dispose();
    itemsPerRowController.dispose();
    orderHereTextController.dispose();
    _debounceTimer?.cancel();
    _showcaseContext = null; // Clear showcase context reference
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final maxWidth = isTablet ? 800.0 : double.infinity;

    List<Widget> screenList = [];

    // Database Connection Section - Modern gradient button
    screenList.add(
      _buildCard(
        child: Showcase(
          key: _connectButtonKey,
          description:
              'กดปุ่มนี้เพื่อเชื่อมต่อกับระบบ DeDe Merchant และตั้งค่าร้านค้า',
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryThemeColor, primaryThemeColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryThemeColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  // Skip confirmation dialog for first time setup
                  if (global.deviceConfig.isFirstTimeSetup) {
                    // First time setup - proceed directly without confirmation
                    try {
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );

                      // Clear all device configuration data
                      global.deviceConfig.usercode = '';
                      global.deviceConfig.token = '';
                      global.deviceConfig.shopId = '';
                      global.deviceConfig.branchId = '';
                      global.deviceConfig.orderStationCode = '';
                      global.deviceConfig.apikey = '';
                      global.deviceConfig.kitchens.clear();

                      // Reset all device settings to default values
                      // Generate new random device name
                      global.deviceConfig.deviceId =
                          _generateRandomDeviceName();
                      global.deviceConfig.useOrderEatAtTheRestaurant = true;
                      global.deviceConfig.useOrderTakeAway = true;
                      global.deviceConfig.useMember = false;
                      global.deviceConfig.itemsPerRow = 3;
                      global.deviceConfig.shopPaymentCondition = 0;
                      global.deviceConfig.machineCondition = 1;
                      global.deviceConfig.isServer = false;
                      global.deviceConfig.orderHereText = 'Order\nHere!';
                      global.deviceConfig.orderHereTextColor = '#FFFFFFFF';
                      global.deviceConfig.orderHereTextColor2 = '';
                      global.deviceConfig.primaryThemeColor = '#FFB1441B';
                      global.deviceConfig.primaryTextColor = '#FFFFFFFF';
                      global.deviceConfig.isFirstTimeSetup = true;

                      // Clear printer settings
                      global.deviceConfig.printerForOrderStation.ipAddress = '';
                      global.deviceConfig.printerForOrderStation.code = '';
                      global.deviceConfig.printerForOrderStation.deviceName =
                          '';
                      global.deviceConfig.printerForOwner.ipAddress = '';
                      global.deviceConfig.printerForOwner.code = '';
                      global.deviceConfig.printerForOwner.deviceName = '';

                      // Clear shop profile
                      global.shopProfile = null;

                      // Clear saved PIN code
                      global.posTerminalPinCode = '';
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.remove('pos_terminal_pin_code');

                      // Clear ObjectBox transactions
                      global.objectBoxStore
                          .box<TransactionObjModel>()
                          .removeAll();

                      // Save cleared configuration
                      await global.saveDeviceConfigToStorage(context);

                      // Close loading dialog
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }

                      // Navigate to registration page (First Time Setup)
                      if (context.mounted) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const RegisterOrderStationPage()),
                        );
                        comparePrinter();
                        // Update UI controllers after reset
                        deviceNameController.text =
                            global.deviceConfig.deviceId;
                        itemsPerRowController.text =
                            global.deviceConfig.itemsPerRow.toString();
                        orderHereTextController.text = global
                            .deviceConfig.orderHereText
                            .replaceAll('\n', '\\n');
                        setState(() {});
                        if (context.mounted) {
                          await global.saveDeviceConfigToStorage(context);
                        }
                      }
                    } catch (e) {
                      // Close loading dialog if still open
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }

                      // Show error dialog
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(global.language("error")),
                              content: Text(
                                  'เกิดข้อผิดพลาดในการล้างข้อมูล: ${e.toString()}'),
                              actions: [
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
                    }
                    return;
                  }

                  // Not first time - show confirmation dialog
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(global.language("confirm")),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'คุณต้องการเชื่อมต่อใหม่หรือไม่?',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            const Text('การดำเนินการนี้จะ:'),
                            const SizedBox(height: 8),
                            const Text('• ล้างข้อมูลการเชื่อมต่อเดิมทั้งหมด'),
                            const Text('• ล้างข้อมูล Shop และ Kiosk'),
                            const Text('• ล้างข้อมูล Token และ API Key'),
                            const Text('• ต้องขออนุมัติจาก Admin ใหม่'),
                            const SizedBox(height: 16),
                            const Text(
                              '⚠️ คุณแน่ใจหรือไม่?',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: Text(global.language("cancel")),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("ยืนยัน ล้างและเชื่อมต่อใหม่"),
                          ),
                        ],
                      );
                    },
                  );

                  // If user confirmed, proceed with clearing data and registration
                  if (confirmed == true && context.mounted) {
                    try {
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );

                      // Clear all device configuration data
                      global.deviceConfig.usercode = '';
                      global.deviceConfig.token = '';
                      global.deviceConfig.shopId = '';
                      global.deviceConfig.branchId = '';
                      global.deviceConfig.orderStationCode = '';
                      global.deviceConfig.apikey = '';
                      global.deviceConfig.kitchens.clear();
                      global.adminPinCode = '';

                      // Reset all device settings to default values
                      // Generate new random device name
                      global.deviceConfig.deviceId =
                          _generateRandomDeviceName();
                      global.deviceConfig.useOrderEatAtTheRestaurant = true;
                      global.deviceConfig.useOrderTakeAway = true;
                      global.deviceConfig.useMember = false;
                      global.deviceConfig.itemsPerRow = 3;
                      global.deviceConfig.shopPaymentCondition = 0;
                      global.deviceConfig.machineCondition = 1;
                      global.deviceConfig.isServer = false;
                      global.deviceConfig.orderHereText = 'Order\nHere!';
                      global.deviceConfig.orderHereTextColor = '#FFFFFFFF';
                      global.deviceConfig.orderHereTextColor2 = '';
                      global.deviceConfig.primaryThemeColor = '#FFB1441B';
                      global.deviceConfig.primaryTextColor = '#FFFFFFFF';
                      global.deviceConfig.isFirstTimeSetup = true;

                      // Clear printer settings
                      global.deviceConfig.printerForOrderStation.ipAddress = '';
                      global.deviceConfig.printerForOrderStation.code = '';
                      global.deviceConfig.printerForOrderStation.deviceName =
                          '';
                      global.deviceConfig.printerForOwner.ipAddress = '';
                      global.deviceConfig.printerForOwner.code = '';
                      global.deviceConfig.printerForOwner.deviceName = '';

                      // Clear shop profile
                      global.shopProfile = null;

                      // Clear saved PIN code
                      global.posTerminalPinCode = '';
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.remove('pos_terminal_pin_code');

                      // Clear ObjectBox transactions
                      global.objectBoxStore
                          .box<TransactionObjModel>()
                          .removeAll();

                      // Save cleared configuration
                      await global.saveDeviceConfigToStorage(context);

                      // Close loading dialog
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }

                      // Navigate to registration page (Re-connect)
                      if (context.mounted) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const RegisterOrderStationPage()),
                        );
                        comparePrinter();
                        // Update UI controllers after reset
                        deviceNameController.text =
                            global.deviceConfig.deviceId;
                        itemsPerRowController.text =
                            global.deviceConfig.itemsPerRow.toString();
                        orderHereTextController.text = global
                            .deviceConfig.orderHereText
                            .replaceAll('\n', '\\n');
                        setState(() {});
                        if (context.mounted) {
                          await global.saveDeviceConfigToStorage(context);
                        }
                      }
                    } catch (e) {
                      // Close loading dialog if still open
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }

                      // Show error dialog
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(global.language("error")),
                              content: Text(
                                  'เกิดข้อผิดพลาดในการล้างข้อมูล: ${e.toString()}'),
                              actions: [
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
                    }
                  }
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.cloud_sync,
                          color: global.primaryTextColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "เชื่อมต่อฐานข้อมูล อนุมัติด้วยระบบ BC Merchant",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: global.primaryTextColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: global.primaryTextColor,
                        size: 18,
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

    screenList.add(const SizedBox(height: 12));

    // Device Name Section - Modern UI with prominent display and Edit button
    screenList.add(
      _buildCard(
        child: Showcase(
          key: _deviceNameKey,
          description:
              'กรอกชื่อเครื่องของคุณที่นี่ เพื่อระบุตัวตนของเครื่อง Kiosk นี้',
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.devices, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "ชื่อเครื่อง",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_isEditingDeviceName) ...[
                  // Display mode - Show device name prominently
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.blue[200]!, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.tablet_android,
                                    color: Colors.blue[700], size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  deviceNameController.text.isEmpty
                                      ? "ยังไม่ได้ตั้งชื่อเครื่อง"
                                      : deviceNameController.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: deviceNameController.text.isEmpty
                                        ? Colors.grey[400]
                                        : Colors.blue[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Edit button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isEditingDeviceName = true;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Edit mode - Show text field
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: deviceNameController,
                          autofocus: true,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: "กรอกชื่อเครื่อง",
                            prefixIcon: const Icon(Icons.edit, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.blue[300]!, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.blue[200]!, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.blue[600]!, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          onChanged: (value) {
                            _debouncedUpdate(() {
                              _tempDeviceId = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Save button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isEditingDeviceName = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (global.deviceConfig.shopId.isNotEmpty) {
      screenList.add(const SizedBox(height: 12));

      // System Settings Section
      screenList.add(
        _buildSectionHeader("การตั้งค่าระบบ", Icons.settings),
      );
      screenList.add(
        _buildCard(
          child: Column(
            children: [
              // Modern Switch Tile for Eat at Restaurant
              _buildModernSwitchTile(
                value: _tempUseOrderEatAtTheRestaurant,
                icon: Icons.restaurant,
                iconColor: Colors.orange,
                title: global
                    .language("open_system_for_ordering_food_at_restaurant"),
                onChanged: (value) {
                  setState(() {
                    _tempUseOrderEatAtTheRestaurant = value;
                    _hasUnsavedChanges = true;
                  });
                },
              ),
              const Divider(height: 1),
              // Modern Switch Tile for Take Away
              Showcase(
                key: _takeAwayKey,
                description:
                    'เลือกเปิด หรือปิดการใช้งาน ระบบสั่งกลับบ้าน/ทานที่ร้าน',
                child: _buildModernSwitchTile(
                  value: _tempUseOrderTakeAway,
                  icon: Icons.shopping_bag,
                  iconColor: Colors.green,
                  title: global.language("open_takeout_system"),
                  onChanged: (value) {
                    setState(() {
                      _tempUseOrderTakeAway = value;
                      _hasUnsavedChanges = true;
                    });
                  },
                ),
              ),
              // const Divider(height: 1),
              // // Modern Switch Tile for Member System (QR scan for member linking)
              // _buildModernSwitchTile(
              //   value: global.deviceConfig.useMember,
              //   icon: Icons.qr_code_scanner,
              //   iconColor: Colors.purple,
              //   title: "ระบบสมาชิก (แสดง QR สำหรับ LINE)",
              //   subtitle: "เปิดใช้งานระบบสมาชิกผ่าน LINE LIFF - ลูกค้าสแกน QR เพื่อเชื่อมบัญชี",
              //   onChanged: (value) {
              //     _debouncedSave(() {
              //       global.deviceConfig.useMember = value;
              //     });
              //   },
              // ),
              const Divider(height: 1),
              // Items Per Row with Stepper
              Showcase(
                key: _itemsPerRowKey,
                description: 'จำนวนรายการสินค้าที่แสดงต่อแถว',
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.grid_view,
                            color: Colors.blue[700], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          global.language("items_per_row"),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Stepper controls
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            // Minus button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (_tempItemsPerRow > 1) {
                                    _debouncedUpdate(() {
                                      _tempItemsPerRow--;
                                      itemsPerRowController.text =
                                          _tempItemsPerRow.toString();
                                    });
                                  }
                                },
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Icon(
                                    Icons.remove,
                                    size: 20,
                                    color: _tempItemsPerRow > 1
                                        ? Colors.blue[700]
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                            // Value display
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.symmetric(
                                  vertical:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: Text(
                                _tempItemsPerRow.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            // Plus button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (_tempItemsPerRow < 10) {
                                    _debouncedUpdate(() {
                                      _tempItemsPerRow++;
                                      itemsPerRowController.text =
                                          _tempItemsPerRow.toString();
                                    });
                                  }
                                },
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Icon(
                                    Icons.add,
                                    size: 20,
                                    color: _tempItemsPerRow < 10
                                        ? Colors.blue[700]
                                        : Colors.grey[400],
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
            ],
          ),
        ),
      );

      // screenList.add(
      //   _buildModernSwitchTile(
      //     value: _tempOrderOnlineCondition,
      //     icon: Icons.qr_code_2,
      //     iconColor: const Color(0xFF6366F1),
      //     title: "เปิดใช้ระบบ Order Online",
      //     subtitle: "ลูกค้าสั่งอาหารด้วยมือถือตัวเอง",
      //     onChanged: (value) {
      //       setState(() {
      //         _tempOrderOnlineCondition = value;
      //         _hasUnsavedChanges = true;
      //       });
      //     },
      //   ),
      // );
      // screenList.add(
      //   SizedBox(
      //     width: double.infinity,
      //     child: InputDecorator(
      //         decoration: InputDecoration(
      //           label: const Text('เงื่อนไข', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
      //           border: OutlineInputBorder(
      //             borderRadius: BorderRadius.circular(5.0),
      //           ),
      //         ),
      //         child: Column(
      //           children: [
      //             Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
      //               Radio(
      //                 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      //                 groupValue: global.deviceConfig.systemCondition,
      //                 value: 2,
      //                 onChanged: (value) async {
      //                   global.deviceConfig.systemCondition = value as int;
      //                   await global.saveDeviceConfigToStorage(context);
      //                   setState(() {});
      //                 },
      //               ),
      //               Expanded(
      //                   child: RichText(
      //                       text: const TextSpan(style: TextStyle(color: Colors.black, fontSize: 12), children: [
      //                 TextSpan(text: "จ่ายก่อนกิน", style: TextStyle(fontWeight: FontWeight.bold)),
      //                 TextSpan(text: " : "),
      //                 TextSpan(
      //                   text: "สำหรับร้านที่จ่ายเงินก่อนกิน โดยเมื่อจ่ายเงินแล้ว ระบบจะส่งรายการไปยังครัว และพิมพ์ใบเสร็จให้ทันที",
      //                 ),
      //               ]))),
      //             ]),
      //             Row(
      //               children: [
      //                 Radio(
      //                   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      //                   groupValue: global.deviceConfig.systemCondition,
      //                   value: 1,
      //                   onChanged: (value) async {
      //                     global.deviceConfig.systemCondition = value as int;
      //                     await global.saveDeviceConfigToStorage(context);
      //                     setState(() {});
      //                   },
      //                 ),
      //                 Expanded(
      //                     child: RichText(
      //                         text: const TextSpan(style: TextStyle(color: Colors.black, fontSize: 12), children: [
      //                   TextSpan(text: "กินก่อนจ่าย", style: TextStyle(fontWeight: FontWeight.bold)),
      //                   TextSpan(text: " : "),
      //                   TextSpan(
      //                     text: "สำหรับร้านที่กินก่อนจ่าย โดยจะสามารถสั่งรายการเก็บไว้ในหมายเลขโต๊ะ และเก็บเงินในภายหลัง",
      //                   ),
      //                 ]))),
      //               ],
      //             ),
      //           ],
      //         )),
      //   ),
      // );
      screenList.add(const SizedBox(height: 12));
      // Machine Condition Section (Only show when shopPaymentCondition == 0)
      if (global.deviceConfig.shopPaymentCondition == 0) {
        screenList.add(
          _buildSectionHeader("การทำงานเครื่อง Order Kiosk", Icons.computer),
        );

        // Device Role Selection Cards
        screenList.add(
          Showcase(
            key: _deviceRoleKey,
            description: 'เครื่องนี้สำหรับพนักงาน หรือ ลูกค้าบริการตนเอง',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return isWide
                      ? Row(
                          children: [
                            Expanded(child: _buildRoleCard(0)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildRoleCard(1)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildRoleCard(0),
                            const SizedBox(height: 12),
                            _buildRoleCard(1),
                          ],
                        );
                },
              ),
            ),
          ),
        );

        screenList.add(const SizedBox(height: 12));

        // Server Mode Switch - Separated with warning
        screenList.add(
          _buildCard(
            child: Column(
              children: [
                _buildModernSwitchTile(
                  value: _tempIsServer,
                  icon: Icons.dns,
                  iconColor: Colors.purple,
                  title: "เป็นเครื่องประมวลผล (Server)",
                  subtitle:
                      "⚠️ กำหนดได้เครื่องเดียวในแต่ละสาขา - เพื่อประมวลผลส่งข้อมูลไปยังห้องครัว หรือเครื่องพิมพ์กลาง",
                  onChanged: (value) {
                    setState(() {
                      _tempIsServer = value;
                      _hasUnsavedChanges = true;
                    });
                  },
                ),
              ],
            ),
          ),
        );

        // Cashier Kitchen Timing — เฉพาะเครื่อง Server (ครัวอยู่ที่นี่)
        // ค่านี้กำหนดพฤติกรรม stub ที่ origin (เครื่อง server ใน happy path) สร้าง
        if (_tempIsServer) {
          screenList.add(const SizedBox(height: 12));
          screenList.add(
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.soup_kitchen,
                            color: Colors.deepOrange, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("จ่ายที่ Cashier: ส่งครัวเมื่อไหร่",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                "กำหนดพฤติกรรมเมื่อลูกค้าเลือก 'จ่ายที่ Cashier'",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  RadioListTile<int>(
                    value: 0,
                    groupValue: _tempCashierKitchenTiming,
                    title: const Text("ส่งครัวหลังชำระเงิน"),
                    subtitle: const Text(
                        "ปลอดภัยวัตถุดิบ — ครัวทำเมื่อ cashier รับเงินแล้ว\nลูกค้ารออาหารนานขึ้น"),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _tempCashierKitchenTiming = value;
                          _hasUnsavedChanges = true;
                        });
                      }
                    },
                  ),
                  RadioListTile<int>(
                    value: 1,
                    groupValue: _tempCashierKitchenTiming,
                    title: const Text("ส่งครัวทันทีตอนสั่ง"),
                    subtitle: const Text(
                        "ลูกค้าได้อาหารเร็ว — ครัวทำทันทีที่สั่ง\n⚠️ ถ้าลูกค้าไม่มาจ่าย จะเสียวัตถุดิบ"),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _tempCashierKitchenTiming = value;
                          _hasUnsavedChanges = true;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }

        screenList.add(const SizedBox(height: 12));
      }

      // Printer Section
      screenList.add(
        Showcase(
          key: _printerSectionKey,
          description: 'เลือกเครื่องพิมพ์สำหรับพิมพ์ใบเสร็จและใบสั่งอาหาร',
          child: _buildSectionHeader("เครื่องพิมพ์", Icons.print),
        ),
      );

      screenList.add(
        _buildPrinterCard(
          title: "เครื่องพิมพ์หลัก",
          printer: _tempPrinterForOrderStation,
          onSelect: () async {
            var result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SelectPrinterPage()),
            );
            if (result != null) {
              _tempPrinterForOrderStation = result;
              if (_tempPrinterForOrderStation.ipAddress.isEmpty &&
                  _tempPrinterForOrderStation.code.isEmpty) {
                _tempPrinterForOrderStation.code =
                    _tempPrinterForOrderStation.deviceName;
              }
              setState(() {
                _hasUnsavedChanges = true;
              });
            }
          },
          onDelete: () {
            _tempPrinterForOrderStation.ipAddress = "";
            _tempPrinterForOrderStation.code = "";
            setState(() {
              _hasUnsavedChanges = true;
            });
          },
        ),
      );
      if (_tempIsServer) {
        screenList.add(const SizedBox(height: 12));
        screenList.add(
          _buildPrinterCard(
            title: global.language("choose_printer_owner"),
            printer: _tempPrinterForOwner,
            onSelect: () async {
              var result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SelectPrinterPage()),
              );
              if (result != null) {
                _tempPrinterForOwner = result;
                if (_tempPrinterForOwner.ipAddress.isEmpty &&
                    _tempPrinterForOwner.code.isEmpty) {
                  _tempPrinterForOwner.code = _tempPrinterForOwner.deviceName;
                }
                setState(() {
                  _hasUnsavedChanges = true;
                });
              }
            },
            onDelete: () {
              _tempPrinterForOwner.ipAddress = "";
              _tempPrinterForOwner.code = "";
              setState(() {
                _hasUnsavedChanges = true;
              });
            },
          ),
        );
        for (int index = 0; index < _tempKitchens.length; index++) {
          screenList.add(const SizedBox(height: 12));
          screenList.add(
            _buildPrinterCard(
              title:
                  "เครื่องพิมพ์ : ${global.getNameFromLanguage(_tempKitchens[index].names, global.languageForCustomer)}",
              printer: _tempKitchens[index].printer,
              onSelect: () async {
                var result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SelectPrinterPage()),
                );
                if (result != null) {
                  _tempKitchens[index].printer = result;
                  if (_tempKitchens[index].printer.ipAddress.isEmpty &&
                      _tempKitchens[index].printer.code.isEmpty) {
                    _tempKitchens[index].printer.code =
                        _tempKitchens[index].printer.deviceName;
                  }
                  setState(() {
                    _hasUnsavedChanges = true;
                  });
                }
              },
              onDelete: () {
                _tempKitchens[index].printer.ipAddress = "";
                _tempKitchens[index].printer.code = "";
                setState(() {
                  _hasUnsavedChanges = true;
                });
              },
            ),
          );
        }
      }

      screenList.add(const SizedBox(height: 12));

      // EDC Section
      screenList.add(
        _buildSectionHeader("รายการเครื่อง EDC", Icons.credit_card),
      );

      if (global.driversAvailableList.isEmpty) {
        screenList.add(
          _buildCard(
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "ไม่พบเครื่อง EDC",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        screenList.add(
          _buildCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: global.driversAvailableList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final port = global.driversAvailableList[index];
                final isConnected =
                    global.edcProductName == port["productName"];

                return ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Icon(
                    Icons.credit_card,
                    color: isConnected ? Colors.red.shade400 : Colors.grey,
                    size: 20,
                  ),
                  title: Text(
                    "${port["productName"]}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isConnected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isConnected
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'เชื่อมต่อแล้ว',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        )
                      : null,
                  onTap: () {
                    global.connectToDevice(port["productName"]);
                    setState(() {});
                  },
                );
              },
            ),
          ),
        );
      }
    }
    // Advanced Settings Section (Collapsible)
    screenList.add(const SizedBox(height: 12));
    screenList.add(
      _buildCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: _isAdvancedSettingsExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isAdvancedSettingsExpanded = expanded;
              });
            },
            leading:
                Icon(Icons.settings_suggest, color: Colors.blue[700], size: 20),
            title: const Text(
              "ตั้งค่าเพิ่มเติม",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Order Here Text Customization
                    Row(
                      children: [
                        Icon(Icons.text_fields,
                            color: Colors.grey[700], size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          "ตั้งค่าข้อความ Order Here",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Text Input
                    TextField(
                      controller: orderHereTextController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: "Order\\nHere!",
                        labelText: "ข้อความ (ใช้ \\n สำหรับขึ้นบรรทัดใหม่)",
                        labelStyle: const TextStyle(fontSize: 14),
                        prefixIcon: const Icon(Icons.edit, size: 20),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      onChanged: (value) {
                        _debouncedUpdate(() {
                          _tempOrderHereText = value.replaceAll('\\n', '\n');
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Text Color
                    Row(
                      children: [
                        Icon(Icons.color_lens,
                            color: Colors.grey[700], size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text("สีตัวอักษร",
                              style: TextStyle(fontSize: 14)),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final Color currentColor =
                                _hexToColor(_tempOrderHereTextColor);
                            final Color? newColor = await showColorPickerDialog(
                              context,
                              currentColor,
                              title: const Text('เลือกสีตัวอักษร'),
                              pickersEnabled: const <ColorPickerType, bool>{
                                ColorPickerType.both: false,
                                ColorPickerType.primary: true,
                                ColorPickerType.accent: true,
                                ColorPickerType.wheel: true,
                              },
                              enableOpacity: true,
                              enableShadesSelection: true,
                            );
                            if (newColor != null) {
                              _debouncedUpdate(() {
                                _tempOrderHereTextColor = _colorToHex(newColor);
                              });
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _hexToColor(_tempOrderHereTextColor),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Gradient Color 2 (optional)
                    Row(
                      children: [
                        Icon(Icons.gradient, color: Colors.grey[700], size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text("สี Gradient (เว้นว่างถ้าไม่ใช้)",
                              style: TextStyle(fontSize: 14)),
                        ),
                        if (_tempOrderHereTextColor2.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _debouncedUpdate(() {
                                _tempOrderHereTextColor2 = "";
                              });
                            },
                          ),
                        GestureDetector(
                          onTap: () async {
                            final Color currentColor = global
                                    .deviceConfig.orderHereTextColor2.isNotEmpty
                                ? _hexToColor(
                                    global.deviceConfig.orderHereTextColor2)
                                : Colors.yellow;
                            final Color? newColor = await showColorPickerDialog(
                              context,
                              currentColor,
                              title: const Text('เลือกสี Gradient'),
                              pickersEnabled: const <ColorPickerType, bool>{
                                ColorPickerType.both: false,
                                ColorPickerType.primary: true,
                                ColorPickerType.accent: true,
                                ColorPickerType.wheel: true,
                              },
                              enableOpacity: true,
                              enableShadesSelection: true,
                            );
                            if (newColor != null) {
                              _debouncedUpdate(() {
                                _tempOrderHereTextColor2 =
                                    _colorToHex(newColor);
                              });
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _tempOrderHereTextColor2.isNotEmpty
                                  ? _hexToColor(_tempOrderHereTextColor2)
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: _tempOrderHereTextColor2.isEmpty
                                ? const Icon(Icons.add, color: Colors.grey)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Shadow Color
                    Row(
                      children: [
                        Icon(Icons.blur_on, color: Colors.grey[700], size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text("สีเงา (Shadow)",
                              style: TextStyle(fontSize: 14)),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final Color currentColor =
                                _hexToColor(_tempOrderHereShadowColor);
                            final Color? newColor = await showColorPickerDialog(
                              context,
                              currentColor,
                              title: const Text('เลือกสีเงา'),
                              pickersEnabled: const <ColorPickerType, bool>{
                                ColorPickerType.both: false,
                                ColorPickerType.primary: true,
                                ColorPickerType.accent: true,
                                ColorPickerType.wheel: true,
                              },
                              enableOpacity: true,
                              enableShadesSelection: true,
                            );
                            if (newColor != null) {
                              _debouncedUpdate(() {
                                _tempOrderHereShadowColor =
                                    _colorToHex(newColor);
                              });
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _hexToColor(_tempOrderHereShadowColor),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: _buildOrderHerePreview(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reset Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _tempOrderHereText = "Order\nHere!";
                            _tempOrderHereTextColor = "#FFFFFFFF";
                            _tempOrderHereTextColor2 = "";
                            _tempOrderHereShadowColor = "#88000000";
                            orderHereTextController.text = "Order\\nHere!";
                            _hasUnsavedChanges = true;
                          });
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text("รีเซ็ตเป็นค่าเริ่มต้น"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(thickness: 1),
                    const SizedBox(height: 16),

                    // 2. Order Layout Preset Section
                    Row(
                      children: [
                        Icon(Icons.dashboard,
                            color: Colors.grey[700], size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          "รูปแบบหน้าจอสั่งอาหาร",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Preset 0: Default (Category Left)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _tempOrderLayoutPreset = 0;
                          _hasUnsavedChanges = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _tempOrderLayoutPreset == 0
                              ? Colors.blue[50]
                              : null,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: 0,
                              groupValue: _tempOrderLayoutPreset,
                              onChanged: (value) {
                                setState(() {
                                  _tempOrderLayoutPreset = value!;
                                  _hasUnsavedChanges = true;
                                });
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "รูปแบบ 1: Category ด้านซ้าย (Default)",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "หมวดหมู่สินค้าอยู่ด้านซ้าย สินค้าอยู่ด้านขวา",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 15,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[300],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(3),
                                        bottomLeft: Radius.circular(3),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      color: Colors.grey[100],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    // Preset 1: KFC Style (Category Top)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _tempOrderLayoutPreset = 1;
                          _hasUnsavedChanges = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _tempOrderLayoutPreset == 1
                              ? Colors.blue[50]
                              : null,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: 1,
                              groupValue: _tempOrderLayoutPreset,
                              onChanged: (value) {
                                setState(() {
                                  _tempOrderLayoutPreset = value!;
                                  _hasUnsavedChanges = true;
                                });
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "รูปแบบ 2: Category ด้านบน",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "หมวดหมู่สินค้าอยู่ด้านบน scroll แนวนอน สินค้าอยู่ด้านล่าง",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.red[300],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(3),
                                        topRight: Radius.circular(3),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      color: Colors.grey[100],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(thickness: 1),
                    const SizedBox(height: 16),

                    // 3. Theme Color Settings - Modern Design
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryThemeColor.withOpacity(0.05),
                            primaryThemeColor.withOpacity(0.01),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: primaryThemeColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryThemeColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.palette,
                                  color: primaryThemeColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "สีหลักของ Theme",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Primary Background Color
                          _buildColorSelector(
                            title: "สีพื้นหลังหลัก",
                            subtitle: "ปุ่ม, หัวข้อหมวดหมู่ที่เลือก",
                            currentColor: _tempPrimaryThemeColor,
                            icon: Icons.format_paint,
                            onColorSelected: (color) {
                              _debouncedUpdate(() {
                                _tempPrimaryThemeColor = _colorToHex(color);
                              });
                            },
                            onReset: () {
                              _debouncedUpdate(() {
                                _tempPrimaryThemeColor = "#FFB1441B";
                              });
                            },
                          ),

                          const Divider(height: 32),

                          // Primary Text Color
                          _buildColorSelector(
                            title: "สีตัวหนังสือหลัก",
                            subtitle: "ตัวหนังสือบนปุ่ม, ยอดรวม",
                            currentColor: _tempPrimaryTextColor,
                            icon: Icons.text_fields,
                            onColorSelected: (color) {
                              _debouncedUpdate(() {
                                _tempPrimaryTextColor = _colorToHex(color);
                              });
                            },
                            onReset: () {
                              _debouncedUpdate(() {
                                _tempPrimaryTextColor = "#FFFFFFFF";
                              });
                            },
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
      ),
    );
    screenList.add(const SizedBox(height: 12));
    /*screenList.add(Html(
      data: """<h1>การเลือกใช้ระบบให้เหมาะสมกับร้าน</h1>
                    เจ้าของร้านไม่ต้องเสียเวลารับ Order ลูกค้าสามารถสั่ง Order ด้วยมือถือได้ทันที พร้อม Queue การทำอาหาร เหมาะสำหรับร้านอาหารขนาดเล็ก,ร้านฟู้ดทรัค, ร้านอาหารตามตลาดนัด, ร้านอาหารตามสั่ง, ร้านอาหารที่มีลูกค้าสั่งกลับบ้าน<br/><br/>
                <b>ระบบ A (Order Kiosk)</b> 
                เจ้าของร้านต้องการให้เครื่องช่วยในการสั่งอาหาร และพิมพ์ใบสั่งอาหารเท่านั้น โดยให้ลูกค้าสั่งด้วยเครื่อง Order Kiosk และลูกค้าสามารถ Scan Qrcode ของร้าน เพื่อสั่งอาหารได้
                <ul>
                  <li>ถ้าสั่งด้วยเครื่อง Order Kiosk ระบบจะพิมพ์ใบสั่งไปยังเครื่องพิมพ์สำหรับลูกค้า และพิมพ์ใบสรุปไปที่เครื่องพิมพ์สำหรับเจ้าของร้านด้วย หรือจะกำหนดให้พิมพ์ไปเครื่องพิมพ์สำหรับเจ้าของร้านอย่างเดียวก็ได้ โดยการลบเครื่องพิมพ์สำหรับลูกค้าออก</li>
                  <li>ถ้าลูกค้า Scan Qrcode สั่งอาหารได้จาก Qrcode หน้าร้าน หรือที่โต๊ะอาหาร เพื่อสั่งอาหาร ระบบจะพิมพ์ไปยังเครื่องพิมพ์สำหรับเจ้าของร้านอย่างเดียวพร้อมหมายเลข Queue และลูกค้าจะได้หมายเลข Queue ในมือถือของลูกค้าเอง (ลูกค้าจะต้องใส่หมายเลขโทรศัพท์ด้วย)</li>
                  <li>ลูกค้าสามารถสั่งอาหารจากมือถือที่บ้าน หรือที่รถยนต์ระหว่างเดินทางได้ เมื่อกดส่งรายการ Order Kiosk จะพิมพ์รายการมายังเครื่องพิมพ์เจ้าของร้านทันที</li>
                  <li>
                    <b>อุปกรณ์</b>
                    <ul>
                      <li>Android Tablet สำหรับ App DeDe Order Kiosk (สามารถติดตั้งได้หลายเครื่อง)</li>
                      <li>เครื่องพิมพ์ความร้อนสำหรับเจ้าของร้าน</li>
                      <li>เครื่องพิมพ์ความร้อนสำหรับลูกค้า (ถ้าต้องการ)</li>
                    </ul>
                    * เครื่องพิมพ์สามารถใช้ได้ ทั้งแบบ Lan, Bluetooth, Wifi
                  </li>
                </ul><br/>

                <b>ระบบ B (กินก่อนจ่าย)</b> เจ้าของร้านต้องการให้ลูกค้าสั่งอาหารที่โต๊ะด้วยการ Scan Qrcode หรือให้พนักงานไปรับ Order ที่โต๊ะของลูกค้า และทำการพิมพ์ใบสั่งอาหารมายังเครื่องพิมพ์สำหรับเจ้าของร้าน พร้อมทั้งสามารถพิมพ์ใบสรุปรายการสั่งอาหาร เพื่อรอสรุปคิดเงินลูกค้า พร้อม Qrcode สำหรับชำระเงิน โดยมี 2 ทางเลือกคือ
                <ul>
                <li>ระบบนี้จะต้องมีการเปิดโต๊ะก่อนสั่งอาหาร และมีการปิดโต๊ะเพื่อสรุปยอดเก็บเงิน</li>
                <li>การเปิดโต๊ะอาหาร ถ้าต้องการให้ลูกค้าสามารถ Scan Qrcode สั่งอาหารเองด้วยมือถือ พนักงานหรือเจ้าของร้านจะต้องนำใบเปิดโต๊ะที่มี Dynamic Qrcode ไปให้กับลูกค้าที่โต๊ะด้วย</li>
                <li>ลูกค้าสามารถสั่งอาหารได้ที่โต๊ะที่เปิดไว้เท่านั้น โดยผ่านระบบ Dynamic Qrcode</li>
                <li>ลูกค้าสามารถสั่งอาหารด้วยมือถือตัวเอง หรือเรียกพนักงานเพื่อสั่งอาหาร โดยจะไม่สามารถสั่งอาหารที่เครื่อง Order Kiosk ได้</li>
                <li>กรณีสั่งกลับบ้าน ลูกค้าสามารถสั่งอาหารด้วยมือถือตัวเอง หรือสั่งอาหารที่เครื่อง Order Kiosk ได้</li>
                <li><b>ถ้าสั่งด้วย Dynamic Qrcode ที่วางใว้บนโต๊ะอาหาร</b> ระบบจะพิมพ์รายการอาหารไปที่เครื่องพิมพ์สำหรับเจ้าของร้าน และสะสมยอดเพื่อรอสรุปชำระเงิน</li>
                <li><b>ถ้าพนักงานไปรับ Order ที่โต๊ะของลูกค้า</b> ระบบจะพิมพ์รายการอาหารไปยังเครื่องพิมพ์สำหรับเจ้าของร้าน และสะสมยอดเพื่อรอสรุปชำระเงิน</li>
                <li>สามารถติดตั้งระบบ Order Kiosk ได้หลายเครื่อง</li>
                <li>ลูกค้าสามารถสั่งอาหารจากมือถือที่บ้าน หรือที่รถยนต์ระหว่างเดินทางได้ เสร็จแล้ว แจ้งมาทางเจ้าของร้านบอกหมายเลขโทรศัพท์เพื่อพิมพ์ใบสั่งอาหาร หรือมากดหมายเลขโทรศัพท์ที่เครื่อง Order Kiosk ได้พร้อมพิมพ์ใบสั่งอาหาร โดยข้อมูลการสั่งอาหารจะเชื่อมกันโดยอัตโนมัติ
                คือ ระบบที่ลูกค้าสั่งอาหารก่อน แล้วจ่ายเงินที่เคาน์เตอร์ หรือพิมพ์ใบสรุปเพื่อชำระเงิน แต่จำเป็นจะต้องมีระบบเปิดโต๊ะ/ปิดโต๊ะ</ul><br/>

                <b>ระบบ C (จ่ายก่อนกิน)</b> เจ้าของร้านต้องการให้ลูกค้าสั่งอาหารด้วย Order Kiosk พร้อมชำระเงินด้วย Qrcode Prompay หรือ ชำระเงินที่ Cashierโดยมีลักษณะการใช้งานคือ
                <ul>
                  <li>ลูกค้าสั่งอาหารด้วย Order Kiosk และพิมพ์ใบสั่งอาหาร เพื่อชำระเงินที่ Cashier และเมื่อชำระเงินแล้ว Cashier จะพิมพ์ใบเสร็จ พร้อม Queue Number ให้เพื่อรอเรียกรับอาหารต่อไป</li>
                  <li>ลูกค้าสั่งอาหารเองด้วยมือถือ จะไม่พิมพ์ใบสั่งอาหาร แต่จะแสดงหมายเลขใบสั่ง หรือ Qrcode ที่มือถือลูกค้า และนำหมายเลขใบสั่ง หรือ Qrcode ไปแสดงให้กับ Cashier เพื่อดึงข้อมูลไปชำระเงิน และเมื่อชำระเงินแล้ว Cashier จะพิมพ์ใบเสร็จ พร้อม Queue Number ให้เพื่อรอเรียกรับอาหารต่อไป</li> 
                  <li>กรณีร้านค้าใช้ระบบ Kbank API ลูกค้าสั่งอาหารด้วย Order Kiosk พร้อมจ่ายเงินด้วย Qrcode และยืนยันเงินเข้าแบบอัตโนมัติ เสร็จแล้ว Order Kiosk จะส่งข้อมูลไปยัง Cashier เพื่อพิมพ์ใบเสร็จ พร้อม Queue Number ให้เพื่อรอเรียกรับอาหารต่อไป</li>
                </ul>
                """,
    ));*/
    return ShowCaseWidget(
      autoPlay: true,
      autoPlayDelay: const Duration(seconds: 5),
      onStart: (index, key) {
        // Scroll to the widget being showcased
        _scrollToShowcaseWidget(key);
      },
      builder: (context) {
        // Store the showcase context for later use
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showcaseContext = context;
          }
        });

        return SafeArea(
          child: PopScope(
            canPop: !_hasUnsavedChanges,
            onPopInvoked: (bool didPop) async {
              if (didPop) return;

              final shouldPop = await _showUnsavedChangesDialog();
              if (shouldPop == true && context.mounted) {
                _loadSavedConfig();
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              backgroundColor: Colors.grey.shade200,
              appBar: AppBar(
                backgroundColor: global.primaryThemeColor,
                foregroundColor: global.primaryTextColor,
                title:
                    Text(global.language("configure_order_station_equipment")),
                leadingWidth: 56,
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        if (_hasUnsavedChanges) {
                          final shouldPop = await _showUnsavedChangesDialog();
                          if (shouldPop == true && context.mounted) {
                            _loadSavedConfig();
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/', (Route<dynamic> route) => false);
                          }
                        } else {
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/', (Route<dynamic> route) => false);
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Icon(Icons.arrow_back_ios,
                            color: global.primaryTextColor, size: 20),
                      ),
                    ),
                  ),
                ),
                elevation: 0,
                actions: [
                  if (_hasUnsavedChanges)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save, size: 20),
                        label: Text(global.language("save_data")),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: _saveAllSettings,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton.icon(
                        icon: Icon(Icons.check_circle,
                            color: global.primaryTextColor, size: 20),
                        label: Text(
                          'บันทึกแล้ว',
                          style: TextStyle(
                            color: global.primaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: null,
                      ),
                    ),
                ],
              ),
              body: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth > 600 ? 16 : 12),
                      child: Column(children: screenList),
                    ),
                  ),
                ),
              ),
              floatingActionButton: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      if (_showcaseContext != null) {
                        // Build showcase list based on available sections
                        List<GlobalKey> showcaseKeys = [
                          _deviceNameKey,
                          _connectButtonKey,
                        ];

                        if (global.deviceConfig.shopId.isNotEmpty) {
                          showcaseKeys.addAll([
                            _takeAwayKey,
                            _itemsPerRowKey,
                          ]);

                          if (global.deviceConfig.shopPaymentCondition == 0) {
                            showcaseKeys.add(_deviceRoleKey);
                          }

                          showcaseKeys.add(_printerSectionKey);
                        }

                        ShowCaseWidget.of(_showcaseContext!)
                            .startShowCase(showcaseKeys);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.help_outline_rounded,
                        color: Colors.grey.shade600,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ), // Scaffold
          ), // PopScope
        ); // SafeArea
      }, // builder
    ); // ShowCaseWidget
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  // Modern Section Header with gradient accent
  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryThemeColor.withOpacity(0.08),
            primaryThemeColor.withOpacity(0.02),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: primaryThemeColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryThemeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: primaryThemeColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile({
    required bool value,
    required String title,
    String? subtitle,
    required Function(bool?) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Role Selection Card - Modern Card UI for Device Role
  Widget _buildRoleCard(int roleValue) {
    final isSelected = _tempMachineCondition == roleValue;
    final isStaffMode = roleValue == 0;

    // Define role data
    final roleIcon = isStaffMode ? Icons.person : Icons.touch_app;
    final roleColor = isStaffMode ? Colors.blue : Colors.orange;
    final roleTitle = isStaffMode ? "พนักงานขาย" : "ลูกค้าบริการตนเอง";
    final roleSubtitle = isStaffMode
        ? "รับออเดอร์ • รับเงินสด/เครดิต"
        : "สั่งเอง • จ่าย PromptPay";
    final roleDescription = isStaffMode
        ? "สำหรับพนักงานรับออเดอร์จากลูกค้า รับชำระเงินสด บัตรเครดิต หรือวิธีอื่นๆ พร้อมเลือกช่องทางการขาย (Delivery, Line Man, Grab)"
        : "สำหรับลูกค้าสั่งอาหารเอง ชำระด้วย PromptPay, Alipay หรือ EDC พิมพ์ใบเสร็จอัตโนมัติ";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _tempMachineCondition = roleValue;
            _hasUnsavedChanges = true;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? roleColor.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? roleColor : Colors.grey[300]!,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: roleColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and selection indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? roleColor.withOpacity(0.15)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      roleIcon,
                      color: isSelected ? roleColor : Colors.grey[600],
                      size: 32,
                    ),
                  ),
                  const Spacer(),
                  // Selection indicator
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? roleColor : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelected ? Icons.check : Icons.circle_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                roleTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? roleColor : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle with bullet points
              Text(
                roleSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? roleColor.withOpacity(0.8)
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                roleDescription,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern Switch Tile with Icon
  Widget _buildModernSwitchTile({
    required bool value,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Function(bool) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon with background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Modern Switch
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: iconColor,
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile({
    required int value,
    required int groupValue,
    required String title,
    required String description,
    required Function(int?) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<int>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.3,
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

  // Color Selector Widget for Theme Colors
  Widget _buildColorSelector({
    required String title,
    required String subtitle,
    required String currentColor,
    required IconData icon,
    required Function(Color) onColorSelected,
    required VoidCallback onReset,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and subtitle
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Color picker and preview
        Row(
          children: [
            // Color preview button
            Expanded(
              child: InkWell(
                onTap: () {
                  Color tempColor = _hexToColor(currentColor);
                  showDialog<Color>(
                    context: context,
                    builder: (dialogContext) {
                      return StatefulBuilder(
                        builder: (context, setDialogState) {
                          return AlertDialog(
                            title: Text('เลือก$title'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                color: tempColor,
                                onColorChanged: (Color color) {
                                  setDialogState(() {
                                    tempColor = color;
                                  });
                                },
                                pickersEnabled: const <ColorPickerType, bool>{
                                  ColorPickerType.both: false,
                                  ColorPickerType.primary: true,
                                  ColorPickerType.accent: true,
                                  ColorPickerType.custom: true,
                                  ColorPickerType.wheel: true,
                                },
                                enableShadesSelection: true,
                                enableOpacity: true,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('ยกเลิก'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, tempColor);
                                },
                                child: const Text('ตกลง'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ).then((selectedColor) {
                    if (selectedColor != null) {
                      onColorSelected(selectedColor);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _hexToColor(currentColor),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.colorize,
                        color: _getContrastColor(_hexToColor(currentColor)),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentColor,
                        style: TextStyle(
                          color: _getContrastColor(_hexToColor(currentColor)),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Reset button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onReset,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper function to get contrasting text color
  Color _getContrastColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = backgroundColor.computeLuminance();
    // Return black for light backgrounds, white for dark backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // Modern Minimalist Printer Card
  Widget _buildPrinterCard({
    required String title,
    required dynamic printer,
    required VoidCallback onSelect,
    required VoidCallback onDelete,
  }) {
    final hasIP = printer.ipAddress.isNotEmpty;
    final hasCode = printer.code.isNotEmpty;
    final hasPrinter = hasIP || hasCode;

    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasPrinter ? Colors.green[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.print,
                    color: hasPrinter ? Colors.green[700] : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasPrinter ? Colors.green[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          hasPrinter ? Colors.green[200]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasPrinter ? Icons.check_circle : Icons.circle_outlined,
                        color:
                            hasPrinter ? Colors.green[700] : Colors.grey[500],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasPrinter ? "เชื่อมต่อแล้ว" : "ยังไม่เชื่อมต่อ",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              hasPrinter ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Printer info (if connected)
            if (hasPrinter) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[100]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: Colors.green[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasIP
                            ? printer.ipAddress
                            : "${printer.code}:${printer.vendorId}:${printer.productId}",
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    if (hasPrinter) ...[
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(0),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red[700],
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onSelect,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: primaryThemeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: primaryThemeColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasPrinter
                                  ? Icons.swap_horiz
                                  : Icons.add_circle_outline,
                              color: primaryThemeColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hasPrinter
                                  ? "เปลี่ยนเครื่อง"
                                  : "เลือกเครื่องพิมพ์",
                              style: TextStyle(
                                color: primaryThemeColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHerePreview() {
    final text = global.deviceConfig.orderHereText;
    final color1 = _hexToColor(global.deviceConfig.orderHereTextColor);
    final color2Hex = global.deviceConfig.orderHereTextColor2;
    final shadowColor = _hexToColor(global.deviceConfig.orderHereShadowColor);

    final textWidget = Text(
      text,
      style: TextStyle(
        fontFamily: 'Kanit',
        fontSize: 24,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: Colors.white,
        shadows: [
          Shadow(offset: const Offset(2, 2), blurRadius: 4, color: shadowColor),
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
          fontSize: 24,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: color1,
          shadows: [
            Shadow(
                offset: const Offset(2, 2), blurRadius: 4, color: shadowColor),
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
}
