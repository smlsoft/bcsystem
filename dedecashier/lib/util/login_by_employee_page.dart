import 'dart:convert';
import 'dart:io';
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/bootstrap.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/util/database_checker_dialog.dart';
import 'package:dedecashier/util/employee_change_password_page.dart';
import 'package:dedecashier/util/load_form_design.dart';
import 'package:dedecashier/util/loading_screen.dart';
import 'package:dedecashier/util/menu_screen.dart';
import 'package:dedecashier/util/register_pos_terminal.dart';
import 'package:dedecashier/util/select_language_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:http/http.dart' as http;
import 'package:dedecashier/core/objectbox.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class LoginByEmployeePage extends StatefulWidget {
  const LoginByEmployeePage({super.key});

  @override
  LoginByEmployeeState createState() => LoginByEmployeeState();
}

class LoginByEmployeeState extends State<LoginByEmployeePage> with SingleTickerProviderStateMixin {
  TextEditingController userController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool obscureVisible = true;
  String lastStatus = "";
  // ⭐ Removed: unused AnimationController และ Animation
  // (ประหยัด memory - animation ไม่ได้ใช้งาน)
  bool isLoading = true;
  String appVersion = "";
  int retryCount = 0;
  static const int maxRetries = 3;

  // ⭐ Fix #2: Cache primaryColor
  late final Color primaryColor;

  // ⭐ Fix #3: Debounce login
  bool _isLoggingIn = false;

  // ⭐ Fix #4: ValueNotifier for appVersion
  final ValueNotifier<String> _appVersionNotifier = ValueNotifier('');

  // ⭐ Fix #5: Cache language strings (ใช้ late แทน late final เพื่อให้เปลี่ยนค่าได้เมื่อเปลี่ยนภาษา)
  late String _signInText;
  late String _userCodeText;
  late String _userPasswordText;
  late String _closeText;
  late String _settingsText;
  late String _loadingText;
  late String _retryCountText;
  late String _loggingInText;
  late String _pleaseLoginText; // ⭐ NEW: Cache "กรุณาเข้าสู่ระบบ"

  // ⭐ NEW: PIN Registration State
  String? _registeredPinCode;
  bool _hasPinRegistered = false;

  @override
  void initState() {
    super.initState();
    objectBoxInit();

    // ⭐ NEW: Load registered PIN
    _loadRegisteredPin();

    // ⭐ Fix #2: Initialize primaryColor
    // MARINEPOS = น้ำเงินเข้ม, อื่นๆ = สีอิฐบ้านเชียง (Terracotta)
    primaryColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

    // ⭐ Fix #5: Cache language strings
    _signInText = global.language("sign_in");
    _userCodeText = global.language("user_code");
    _userPasswordText = global.language("user_password");
    _closeText = global.language('close');
    _settingsText = global.language('ลงทะเบียนเครื่องใหม่');
    _loadingText = global.language("กำลังโหลดข้อมูล...");
    _retryCountText = global.language("ครั้งที่");
    _loggingInText = global.language("กำลังเข้าสู่ระบบ...");
    _pleaseLoginText = global.language("กรุณาเข้าสู่ระบบ"); // ⭐ NEW

    // ⭐ Fix: ลบ empty setState - ไม่จำเป็นต้อง rebuild
    global.getProfile();

    // ⭐ Fix #4: Use ValueNotifier for appVersion
    global.getAppVersion().then((value) {
      _appVersionNotifier.value = value;
    });

    loadConfig().then((_) {
      _checkEmployeesWithRetry();
    });

    global.getDeviceModel(context);
    AppLogger.debug("Shop ID : ${global.shopId}");

    global.loginSuccess = false;
    global.syncDataSuccess = false;
    userController.text = '';
    passwordController.text = '';

    // ⭐ Auto-fill credentials in Debug Mode or Demo Mode
    if (kDebugMode || global.isDemoMode) {
      userController.text = '001';
      passwordController.text = '12345';
    }

    // ⭐ Precache logo image สำหรับ loading ที่เร็วขึ้น
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (F.appFlavor == Flavor.MARINEPOS) {
        precacheImage(const AssetImage('assets/marine-logo-app-1.png'), context);
      } else {
        // precacheImage(const AssetImage('assets/icons/bcpos.png'), context);
      }
    });
  }

  Future<void> loadConfig() async {
    // ⭐ ลบ delay 1 วินาที - โหลดทันที!
    AppLogger.debug("[Login] 🚀 Loading config... Shop ID: ${global.shopId}");

    try {
      // ⭐ โหลดแบบ parallel เพื่อความเร็ว
      await Future.wait([
        // 1. Load device config (สำคัญที่สุด)
        _loadDeviceConfig(),

        // 2. Load printer (ไม่จำเป็นต้องรอก่อน login)
        global.loadPrinter().catchError((e) {
          AppLogger.error("⚠️ Printer load failed: $e");
        }),

        // 3. Load employee (สำคัญสำหรับการ login)
        global.loadEmployee().catchError((e) {
          AppLogger.error("❌ Employee load failed: $e");
        }),
      ]);

      // 4. Load form design (ไม่จำเป็นต้องรอ)
      try {
        loadFormDesign();
      } catch (e) {
        AppLogger.error("⚠️ Form design load failed: $e");
      }

      AppLogger.debug("[Login] ✅ Config loaded successfully");
    } catch (e) {
      AppLogger.error("[Login] ❌ Config load error: $e");
    }
  }

  // ⭐ Helper function สำหรับโหลด device config
  Future<void> _loadDeviceConfig() async {
    try {
      if (global.isOnline) {
        await loadDeviceConfigFromServer();
      } else {
        SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
        global.posConfig = PosConfigModel.fromJson(jsonDecode(sharedPreferences.getString('posConfig') ?? "{}"));
        global.branchId = global.posConfig.branch.code;
        AppLogger.debug("[Login] 📱 Loaded offline config");
      }
    } catch (e) {
      AppLogger.error("[Login] ❌ Device config error: $e");
    }
  }

  /// ⭐ NEW: Load registered PIN from SharedPreferences
  Future<void> _loadRegisteredPin() async {
    AppLogger.debug("[Login] 📌 Loading registered PIN...");

    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      final pinCode = sharedPreferences.getString('pos_terminal_pin_code');

      if (mounted) {
        setState(() {
          _registeredPinCode = pinCode;
          _hasPinRegistered = (pinCode != null && pinCode.isNotEmpty);
        });

        AppLogger.debug("[Login] PIN Status: ${_hasPinRegistered ? '✅ Registered' : '❌ Not Registered'}");
      }
    } catch (e) {
      AppLogger.error("[Login] ❌ Load PIN error: $e");
    }
  }

  Future<void> loadDeviceConfigFromServer() async {
    AppLogger.debug("[Login] 🌐 Loading config from server...");

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    global.posTerminalPinCode = sharedPreferences.getString('pos_terminal_pin_code') ?? "";
    global.posTerminalPinTokenId = sharedPreferences.getString('pos_terminal_token') ?? "";
    global.deviceId = sharedPreferences.getString('pos_device_id') ?? "";
    global.shiftAndMoneyMode = sharedPreferences.getInt('shift_and_money_mode') ?? 0;

    ApiRepository apiRepository = ApiRepository();
    try {
      // POS Setting
      var value = await apiRepository.getPosSetting(global.deviceId);
      global.posConfig = PosConfigModel.fromJson(value.data);

      // ดึง logo
      if (global.posConfig.logourl.isNotEmpty) {
        // ⭐ ดาวน์โหลด logo แบบไม่บล็อก
        _downloadLogo(global.posConfig.logourl);
      } else {
        // ⭐ ลบ Logo ร้าน แบบ async
        var file = File(global.getShopLogoPathName());
        if (await file.exists()) {
          await file.delete();
        }
      }

      /// ดึง config สาขา ตาม guid ในกำหนดรหัสเครื่อง pos
      global.branchId = global.posConfig.branch.code;
      AppLogger.debug(global.posConfig.branch);
      var branchValue = await apiRepository.getProfileBranchByGuid(global.posConfig);
      global.posConfig.branch.pos = PosModel.fromJson(branchValue.data['pos']);
      await sharedPreferences.setString('posConfig', jsonEncode(global.posConfig.toJson()));
      await sharedPreferences.setString('mediaguid', global.posConfig.mediaguid);
      initCustomerDisplayBanner();

      AppLogger.debug("[Login] ✅ Server config loaded");
    } catch (e) {
      AppLogger.error("[Login] ❌ Server config error: $e");
    }
  }

  // ⭐ ดาวน์โหลด logo แบบแยก (ไม่บล็อก)
  Future<void> _downloadLogo(String url) async {
    try {
      AppLogger.debug("🖼️ Downloading logo...");

      var response = await http.get(Uri.parse(url));
      var file = File(global.getShopLogoPathName());
      await file.writeAsBytes(response.bodyBytes);

      AppLogger.success("✅ Logo downloaded");
    } catch (e) {
      AppLogger.error("⚠️ Logo download failed: $e");
    }
  }

  Future<void> _checkEmployeesWithRetry() async {
    if (!mounted) return;

    // ⭐ รอแค่ 500ms แรก (ให้ loadConfig() ทำงานก่อน)
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    var employees = global.employeeHelper.getAll();
    if (employees.isEmpty && retryCount < maxRetries) {
      retryCount++;
      AppLogger.debug("[Login] ⚠️ Employees empty, retrying ($retryCount/$maxRetries)");

      setState(() {
        lastStatus = "กำลังโหลดข้อมูลพนักงาน... (ครั้งที่ $retryCount)";
      });

      try {
        // ⭐ ลองโหลด employee อีกครั้ง (ไม่ต้อง loadConfig ทั้งหมดใหม่)
        await global.loadEmployee();

        // ⭐ Retry แบบ exponential backoff (300ms, 600ms, 900ms)
        await Future.delayed(Duration(milliseconds: 300 * retryCount));

        await _checkEmployeesWithRetry();
      } catch (e) {
        AppLogger.error("[Login] ❌ Retry $retryCount failed: $e");
        await _checkEmployeesWithRetry();
      }
    } else {
      setState(() {
        isLoading = false;
        if (employees.isEmpty) {
          lastStatus = "กรุณาเชื่อม pin ใหม่";
        } else {
          lastStatus = "";
        }
      });

      AppLogger.debug("[Login] ✅ Employees loaded: ${employees.length} found");
    }
  }

  @override
  void dispose() {
    userController.dispose();
    passwordController.dispose();
    // ⭐ Removed: animationController.dispose() - ไม่ใช้แล้ว
    _appVersionNotifier.dispose(); // ⭐ Dispose ValueNotifier
    super.dispose();
  }

  /// ⭐ NEW: ปิดโปรแกรมตาม Platform
  Future<void> _exitApp() async {
    AppLogger.debug("[Login] 🚪 Exiting app on platform: ${Platform.operatingSystem}");

    try {
      if (Platform.isAndroid) {
        // Android: ใช้ SystemNavigator.pop() (แนะนำโดย Flutter)
        await SystemNavigator.pop();
      } else if (Platform.isIOS) {
        // iOS: ใช้ exit(0) แต่ Apple อาจจะ reject (ไม่แนะนำให้มีปุ่มออก)
        exit(0);
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: ใช้ window_manager.destroy() สำหรับ graceful shutdown
        AppLogger.debug("[Login] 🪟 Using window_manager to close app");
        await windowManager.destroy();
      } else {
        // Fallback สำหรับ platform อื่นๆ
        exit(0);
      }
    } catch (e) {
      AppLogger.error("[Login] ⚠️ Exit failed: $e, using exit(0) fallback");
      // Fallback: ถ้าทุกวิธีล้มเหลว ใช้ exit(0)
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ Fix #2: ใช้ cached primaryColor (ไม่ต้องคำนวณซ้ำ)
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.login, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                // ⭐ Fix #4: ใช้ ValueListenableBuilder สำหรับ appVersion
                child: ValueListenableBuilder<String>(
                  valueListenable: _appVersionNotifier,
                  builder: (context, version, child) {
                    return Text(
                      "$_signInText ${global.applicationName} v.$version",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            // ⭐ Demo Mode Badge
            if (global.isDemoMode)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.science, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'DEMO MODE',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            // Database Checker Button
            IconButton(
              onPressed: () => _showDatabaseCheckerDialog(context),
              icon: const Icon(Icons.details_sharp, color: Colors.white),
              tooltip: 'Database Checker',
            ),
            const SizedBox(width: 8),
            // EDC Device Button
            IconButton(
              onPressed: () => _showEdcDialog(context),
              icon: Icon(Icons.payment, color: global.edcProductName != '' ? Colors.green.shade300 : Colors.white),
              tooltip: 'EDC Devices',
            ),
            const SizedBox(width: 8),
            // Settings Button
            IconButton(
              onPressed: () => _showRegisterDialog(context),
              icon: const Icon(Icons.settings, color: Colors.white),
              tooltip: 'Settings',
            ),
            const SizedBox(width: 8),
            // Language Button
            IconButton(
              icon: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset('assets/flags/${global.userScreenLanguage}.png', width: 24, height: 18, fit: BoxFit.cover),
              ),
              onPressed: () async {
                // ⭐ Fix #6: Add error handling
                try {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectLanguageScreen()));
                  if (mounted) {
                    // ⭐ Fix: Reload cached strings after language change
                    _signInText = global.language("sign_in");
                    _userCodeText = global.language("user_code");
                    _userPasswordText = global.language("user_password");
                    _closeText = global.language('close');
                    _settingsText = global.language('ลงทะเบียนเครื่องใหม่');
                    _loadingText = global.language("กำลังโหลดข้อมูล...");
                    _retryCountText = global.language("ครั้งที่");
                    _loggingInText = global.language("กำลังเข้าสู่ระบบ...");
                    _pleaseLoginText = global.language("กรุณาเข้าสู่ระบบ"); // ⭐ NEW
                    setState(() {});
                  }
                } catch (e) {
                  AppLogger.error('Navigation error: $e');
                }
              },
              tooltip: 'Language',
            ),
            const SizedBox(width: 8),
          ],
        ),
        // ⭐ Fix: ลบ AnimatedBuilder - ใช้ค่าคงที่แทน (ไม่ต้อง animation)
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryColor, Color.lerp(primaryColor, Colors.white, 0.1)!, Color.lerp(primaryColor, Colors.white, 0.1)!],
            ),
          ),
          child: (isLoading)
              // ⭐ Fix #12: Better loading state
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      const SizedBox(height: 16),
                      Text(
                        lastStatus.isNotEmpty ? lastStatus : _loadingText, // ⭐ Fix: cached string
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      if (retryCount > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '$_retryCountText $retryCount / $maxRetries', // ⭐ Fix: cached string
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final screenHeight = constraints.maxHeight;

                    // Responsive breakpoint
                    final isDesktop = screenWidth > 1200;
                    final isTablet = screenWidth > 600 && screenWidth <= 1200;
                    final isMobile = screenWidth <= 600;

                    return SafeArea(
                      child: _buildResponsiveLayout(
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                        isMobile: isMobile,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        primaryColor: primaryColor,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // ⭐ NEW: Beautiful Responsive Layout
  Widget _buildResponsiveLayout({
    required bool isDesktop,
    required bool isTablet,
    required bool isMobile,
    required double screenWidth,
    required double screenHeight,
    required Color primaryColor,
  }) {
    if (isDesktop) {
      // Desktop: Two-column layout with decorative elements
      return Row(
        children: [
          // Left side: Login area (50%)
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, primaryColor.withOpacity(0.03)]),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [_buildLogoSection(), const SizedBox(height: 32), _buildLoginForm(primaryColor)]),
                ),
              ),
            ),
          ),

          // Right side: Decorative area (50%)
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primaryColor.withOpacity(0.8), primaryColor]),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    left: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                    ),
                  ),

                  // Content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLogoSection(),
                          const SizedBox(height: 20),
                          Icon(Icons.shopping_cart_rounded, size: 120, color: Colors.white.withOpacity(0.9)),
                          const SizedBox(height: 40),
                          Text(
                            'ระบบจุดขายที่ทันสมัย\nรวดเร็ว ใช้งานง่าย',
                            style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9), height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (isTablet) {
      // Tablet: Centered with max width
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, primaryColor.withOpacity(0.05)]),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(mainAxisSize: MainAxisSize.min, children: [_buildLogoSection(), const SizedBox(height: 24), _buildLoginForm(primaryColor)]),
            ),
          ),
        ),
      );
    } else {
      // Mobile: Full width, compact
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [_buildLogoSection(), const SizedBox(height: 16), _buildLoginForm(primaryColor)]),
        ),
      );
    }
  }

  Widget _buildLogoSection() {
    // ⭐ Optimized: ลบ Container ซ้ำซ้อน และใช้ constraints แทน MediaQuery
    return LayoutBuilder(
      builder: (context, constraints) {
        // ⭐ Fix: ใช้ constraints.maxWidth แทน MediaQuery (เร็วกว่า)
        final double logoSize = (constraints.maxWidth * 0.15).clamp(90.0, 250.0);

        return (F.appFlavor == Flavor.MARINEPOS)
            ? SizedBox(
                width: logoSize,
                height: logoSize,
                child: Image.asset('assets/marine-logo-app-1.png', fit: BoxFit.contain),
              )
            : SizedBox();
      },
    );
  }

  Widget _buildInfoCard(String ipAddress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi, color: Colors.white.withOpacity(0.9), size: 20),
          const SizedBox(width: 8),
          Text(
            ipAddress,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPinWidget() {
    if (_hasPinRegistered && _registeredPinCode != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.green.shade200.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // ไอคอนและข้อความ
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.verified, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  "เครื่องนี้ลงทะเบียนแล้ว",
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // PIN แบบเล็ก - ใช้ Expanded
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var pinChar in _registeredPinCode!.split(''))
                  Flexible(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      constraints: const BoxConstraints(minWidth: 28, maxWidth: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 3, offset: const Offset(0, 1))],
                      ),
                      child: Text(
                        pinChar,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
              ],
            ),

            // ⭐ แสดงข้อมูลบริษัท/สาขา (ถ้ามีข้อมูล)
            if (global.posConfig.branch.code.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    // ชื่อบริษัท (จาก profileSetting ถ้ามี)
                    if (global.profileSetting.company.names.isNotEmpty)
                      Text(
                        global.profileSetting.company.names[0].name,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    // รหัสสาขา + ชื่อสาขา
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("สาขา: ${global.posConfig.branch.code}", style: const TextStyle(color: Colors.white, fontSize: 11)),
                        if (global.posConfig.branch.names.isNotEmpty) ...[
                          const Text(" • ", style: TextStyle(color: Colors.white, fontSize: 11)),
                          Flexible(
                            child: Text(
                              global.posConfig.branch.names[0].name,
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildLoginForm(Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ⭐ แสดง PIN ที่ลงทะเบียนแล้ว ที่ด้านบนสุด (แบบกะทัดรัด)

        // Form Title - ทำให้สวยขึ้น
        Text(
          global.language("sign_in"),
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
        ),
        const SizedBox(height: 12),
        Text(
          _pleaseLoginText, // ⭐ Fix: ใช้ cached string แทน hardcoded
          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 36),

        // ⭐ NEW: แสดงข้อความเตือนถ้ายังไม่ลงทะเบียน - ทำให้สวยขึ้น
        if (!_hasPinRegistered) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.orange[50]!, Colors.orange[100]!.withOpacity(0.5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade300, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  "เครื่องนี้ยังไม่ได้ลงทะเบียน",
                  style: TextStyle(color: Colors.orange[900], fontSize: 17, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  "กรุณาลงทะเบียนเครื่องก่อนใช้งาน",
                  style: TextStyle(color: Colors.orange[800], fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],

        // User Code Field
        _buildTextField(
          controller: userController,
          labelText: _userCodeText, // ⭐ Fix #5: cached string
          prefixIcon: Icons.person_outline,
          autofocus: true,
        ),

        const SizedBox(height: 20),

        // Password Field
        _buildPasswordField(),

        const SizedBox(height: 32),

        // Buttons
        _buildButtons(primaryColor),

        // Error Message
        if (lastStatus.isNotEmpty) ...[const SizedBox(height: 16), _buildErrorMessage()],
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String labelText, required IconData prefixIcon, bool autofocus = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        autofocus: autofocus,
        controller: controller,
        enabled: true,
        style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.w400),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            child: Icon(prefixIcon, color: Colors.grey[600], size: 22),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        obscureText: obscureVisible,
        controller: passwordController,
        enabled: true,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87, // ⭐ Fix: ตรงกับ username field
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: _userPasswordText,
          labelStyle: TextStyle(
            color: Colors.grey[600], // ⭐ Fix: ตรงกับ username field
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.lock_outline, color: Colors.grey[600], size: 22), // ⭐ Fix: ตรงกับ username
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600], // ⭐ Fix: consistent color
              size: 22,
            ),
            tooltip: obscureVisible ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน', // ⭐ NEW: Accessibility
            onPressed: () {
              setState(() {
                obscureVisible = !obscureVisible;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            // ⭐ NEW: เพิ่ม enabledBorder ให้ตรงกับ username
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            // ⭐ NEW: เพิ่ม focusedBorder
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          filled: true,
          fillColor: Colors.white, // ⭐ Fix: ตรงกับ username field (เดิมเป็น grey[50])
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildButtons(Color primaryColor) {
    return Column(
      children: [
        // ⭐ ปุ่มลงทะเบียนเครื่อง (แสดงเฉพาะเมื่อยังไม่มี PIN)
        if (!_hasPinRegistered) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPosTerminalPage()));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.app_registration, size: 22),
                    SizedBox(width: 12),
                    Text("ลงทะเบียนเครื่อง", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final shouldExit = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                            SizedBox(width: 12),
                            Text("ยืนยันการออกจากโปรแกรม", style: TextStyle(fontSize: 18)),
                          ],
                        ),
                        content: const Text("ต้องการปิดโปรแกรมใช่หรือไม่?", style: TextStyle(fontSize: 16)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              "ยกเลิก",
                              style: TextStyle(color: Colors.grey[700], fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("ปิดโปรแกรม", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );

                    if (shouldExit == true) {
                      await _exitApp();
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.power_settings_new, size: 22),
                      SizedBox(width: 10),
                      Text("จบโปรแกรม", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              // ⭐ Login button - disabled ถ้ายังไม่มี PIN
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: (_isLoggingIn || !_hasPinRegistered) ? [] : [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isLoggingIn || !_hasPinRegistered) ? Colors.grey[300] : primaryColor,
                    foregroundColor: (_isLoggingIn || !_hasPinRegistered) ? Colors.grey[600] : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: (_isLoggingIn || !_hasPinRegistered) ? null : _handleLogin,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoggingIn) ...[
                        const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                        const SizedBox(width: 12),
                      ] else ...[
                        const Icon(Icons.login, size: 22),
                        const SizedBox(width: 10),
                      ],
                      Text(_isLoggingIn ? _loggingInText : _signInText, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildPinWidget(),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red[50]!, Colors.red[100]!.withOpacity(0.3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red[600], shape: BoxShape.circle),
            child: const Icon(Icons.error_outline, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lastStatus,
              style: TextStyle(color: Colors.red[800], fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEdcDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true, // ⭐ Fix #10: กดนอก dialog เพื่อปิด
      builder: (BuildContext context) {
        return AlertDialog(
          semanticLabel: 'EDC Device Selection', // ⭐ Fix #10: Accessibility
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.payment, color: Colors.blue),
              SizedBox(width: 8),
              Text('EDC Devices'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: global.driversAvailableList.length,
              itemBuilder: (BuildContext context, int index) {
                bool isConnected = global.edcProductName == global.driversAvailableList[index]["productName"];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.blue[50] : Colors.grey[50],
                    border: Border.all(color: isConnected ? Colors.blue : Colors.grey[300]!, width: isConnected ? 2 : 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(
                      global.driversAvailableList[index]['productName'],
                      style: TextStyle(color: isConnected ? Colors.blue[700] : Colors.black87, fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal),
                    ),
                    onTap: () {
                      global.connectToDevice(global.driversAvailableList[index]["productName"]);
                      setState(() {});
                    },
                    trailing: isConnected ? Icon(Icons.check_circle, color: Colors.green[600]) : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(global.language('close')))],
        );
      },
    );
  }

  Future<void> _showRegisterDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true, // ⭐ Fix #10
      builder: (BuildContext context) {
        return AlertDialog(
          semanticLabel: 'Register New Device', // ⭐ Fix #10
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.app_registration, color: Colors.orange),
              const SizedBox(width: 8),
              Text(_settingsText), // ⭐ Fix #5: cached string
            ],
          ),
          content: Text(global.language('ต้องการลงทะเบียนเครื่องใหม่ เพื่อใช้กับฐานข้อมูลอื่นๆ')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ไม่ต้องการ')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // ⭐ Fix #6: Add try-catch
                try {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => const RegisterPosTerminalPage()), (route) => false);
                } catch (e) {
                  AppLogger.error('Navigation error: $e');
                }
              },
              child: const Text('ต้องการ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    // ⭐ Fix #3: Debounce - ป้องกัน double-tap
    if (_isLoggingIn) return;

    setState(() {
      _isLoggingIn = true;
      lastStatus = "";
    });

    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

      // ...existing code...
      var employee = global.employeeHelper.selectByCode(code: userController.text);
      if (employee != null) {
        var getpermission = global.posConfig.employees.firstWhere(
          (element) => element.code == employee.code,
          orElse: () => PosEmployeeModel(code: '', name: ''),
        );

        if (getpermission.code.isEmpty) {
          // ⭐ แสดง dialog แทน lastStatus
          await _showErrorDialog(global.language("user_not_found"));
          return;
        }

        // ⭐ Fix: แยกเงื่อนไขรหัสผ่านและสิทธิ์การใช้งานออกจากกัน
        if (employee.pin_code != passwordController.text) {
          // รหัสผ่านไม่ถูกต้อง - แสดง dialog
          await _showErrorDialog(global.language("user_name_or_password_incorrect"));
          return;
        }

        // รหัสผ่านถูกต้อง - ตรวจสอบสิทธิ์ is_use_pos
        if (employee.is_use_pos != true) {
          // ⭐ แจ้งเตือนว่าไม่มีสิทธิ์เข้าใช้ระบบ POS - แสดง dialog
          await _showErrorDialog(global.language("user_has_no_permission"));
          return;
        }

        // ผ่านทุกเงื่อนไข - เข้าสู่ระบบ
        if (employee.pin_code == "123456") {
          // บังคับให้เปลี่ยนรหัสผ่าน
          global.userLogin = employee;
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(global.language('ต้องเปลี่ยนรหัสผ่าน')),
                  ],
                ),
                content: Text(global.language('เนื่องจากรหัสผ่านเป็นรหัสเริ่มต้น กรุณาเปลี่ยนรหัสผ่านใหม่')),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => const EmployeeChangePasswordPage()), (route) => false);
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          global.userLogin = employee;
          global.loginSuccess = true;
          global.isOnline = await global.hasNetwork();
          if (global.loginSuccess && !global.isOnline) {
            var lastDocNo = sharedPreferences.getString('last_doc_no');
            if (lastDocNo != null) {
              global.last_doc_no = lastDocNo;
            } else {
              global.last_doc_no = "";
            }
            if (mounted) {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => const MenuScreen()), (route) => false);
            }
          } else {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => const LoadingScreen()), (route) => false);
          }
        }
      } else {
        // ไม่พบผู้ใช้ - แสดง dialog
        await _showErrorDialog(global.language("user_not_found"));
      }
    } finally {
      // ⭐ Fix #3: Reset loading state
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  /// ⭐ NEW: แสดง Error Dialog แทนข้อความด้านล่าง
  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red[100], shape: BoxShape.circle),
                child: Icon(Icons.error_outline, color: Colors.red[700], size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  global.language('เข้าสู่ระบบไม่สำเร็จ'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[800]),
                ),
              ),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDatabaseCheckerDialog(BuildContext context) {
    DatabaseCheckerDialog.show(
      context,
      onDatabaseDeleted: () async {
        // ⭐ Callback เมื่อลบ database สำเร็จ
        AppLogger.debug('[Login] Database deleted successfully, closing app...');

        // รอให้ dialog ปิดสมบูรณ์
        await Future.delayed(const Duration(milliseconds: 500));

        // ⭐ ปิด app แบบ graceful สำหรับ Windows Desktop
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          // Desktop platforms - ใช้ ServicesBinding
          WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.detached);
          await Future.delayed(const Duration(milliseconds: 100));
          exit(0);
        } else {
          // Mobile platforms - ใช้ SystemNavigator
          await SystemNavigator.pop();
        }
      },
    );
  }
}
