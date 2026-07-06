import 'dart:async';
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/api/clickhouse/clickhouse_api.dart';
import 'package:dedecashier/core/objectbox.dart';
import 'package:dedecashier/core/request.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/db/bank_helper.dart';
import 'package:dedecashier/db/customer_helper.dart';
import 'package:dedecashier/db/employee_helper.dart';
import 'package:dedecashier/db/kitchen_helper.dart';
import 'package:dedecashier/db/product_barcode_helper.dart';
import 'package:dedecashier/db/product_category_helper.dart';
import 'package:dedecashier/db/table_process_helper.dart';
import 'package:dedecashier/features/authentication/auth.dart';
import 'package:dedecashier/features/shop/shop.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/services/user_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/environment.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class RegisterPosTerminalPage extends StatefulWidget {
  const RegisterPosTerminalPage({super.key});

  @override
  RegisterPosTerminalPageState createState() => RegisterPosTerminalPageState();
}

class RegisterPosTerminalPageState extends State<RegisterPosTerminalPage> {
  // 🔄 Timer Management
  Timer? _recheckTimer;

  // 📊 State Variables
  bool _isChecking = false;

  // 🔑 PIN Management
  String _currentPinCode = ''; // เลขปัจจุบัน

  /// ✅ เริ่ม timer สำหรับ recheck status
  void startTimers() {
    // Timer: Recheck status ทุก 2 วินาที
    _recheckTimer = Timer.periodic(const Duration(seconds: 2), (_) => _performRecheck());
  }

  /// ✅ Sync wrapper สำหรับ recheck - ป้องกัน concurrent calls
  void _performRecheck() {
    if (_isChecking || !mounted) return;

    setState(() {
      _isChecking = true;
    });

    recheck()
        .then((_) {
          if (mounted) {
            setState(() {
              _isChecking = false;
            });
          }
        })
        .catchError((e) {
          AppLogger.debug('[RegisterPOS] ❌ Recheck error: $e');
          if (mounted) {
            setState(() {
              _isChecking = false;
            });
          }
        })
        .whenComplete(() {
          // ✅ ให้แน่ใจว่า _isChecking จะกลับเป็น false เสมอ
          if (mounted && _isChecking) {
            setState(() {
              _isChecking = false;
            });
          }
        });
  }

  @override
  void initState() {
    super.initState();
    objectBoxDeleteAll();
    // ⭐ ล้างข้อมูลและสร้าง PIN ใหม่แบบ sequential (รอให้เสร็จก่อน)
    _initializeRegistration();

    // ⭐ เริ่ม unified timers
    startTimers();
  }

  /// ⭐ Initialize registration: ล้างข้อมูลเก่าและสร้าง PIN ใหม่
  Future<void> _initializeRegistration() async {
    // 1. ล้างข้อมูลการลงทะเบียนเดิมทั้งหมด (รอให้เสร็จ)
    await _clearRegistrationData();

    // 2. สร้าง PIN ใหม่
    await _initializePins();

    AppLogger.debug('[RegisterPOS] ✅ Registration initialization complete');
  }

  /// ⭐ ล้างข้อมูลการลงทะเบียนทั้งหมดที่เก็บใน SharedPreferences และ Storage
  Future<void> _clearRegistrationData() async {
    try {
      AppLogger.debug('[RegisterPOS] 🗑️ Clearing all registration data...');

      SharedPreferences prefs = await SharedPreferences.getInstance();

      // ⭐ Log ค่าก่อนลบ
      String? oldPin = prefs.getString('pos_terminal_pin_code');
      AppLogger.debug('[RegisterPOS] 📌 Old PIN before clear: $oldPin');

      // ล้างข้อมูลทั้งหมดที่เกี่ยวกับการลงทะเบียน
      await prefs.remove('pos_terminal_pin_code');
      await prefs.remove('pos_terminal_token');
      await prefs.remove('pos_device_id');
      await prefs.remove('cache_shopid');
      await prefs.remove('apikey');
      await prefs.remove('token');
      await prefs.remove('mediaguid');
      await prefs.remove('last_doc_no');
      await prefs.remove('posConfig');

      // ⭐ ล้าง User Cache (สำคัญมาก! ไม่งั้น Splash จะเห็น user cache แล้วไปหน้า Select IP แทน Register)
      await prefs.remove('usercache');

      // ⭐ ล้าง UserCacheService instance
      await serviceLocator<UserCacheService>().deleteUser();

      // ⭐ ตรวจสอบว่าลบสำเร็จหรือไม่
      String? pinAfterClear = prefs.getString('pos_terminal_pin_code');
      String? userCacheAfterClear = prefs.getString('usercache');
      AppLogger.debug('[RegisterPOS] 📌 PIN after clear: $pinAfterClear (should be null)');
      AppLogger.debug('[RegisterPOS] 📌 User cache after clear: $userCacheAfterClear (should be null)');

      // ล้าง global.appStorage (GetStorage)
      global.appStorage.remove("apikey");
      global.appStorage.remove("cache_shopid");
      global.appStorage.remove("token");

      // รีเซ็ต global variables
      global.posTerminalPinCode = '';
      global.posTerminalPinTokenId = '';
      global.deviceId = '';
      global.shopId = '';
      global.username = '';
      global.apiConnected = false;
      global.loginProcess = false;
      global.loginSuccess = false;
      global.isDemoMode = false;

      AppLogger.debug('[RegisterPOS] ✅ All registration data cleared successfully');
    } catch (e) {
      AppLogger.error('[RegisterPOS] ❌ Error clearing registration data: $e');
    }
  }

  /// 🔑 สร้าง PIN ใหม่สำหรับการลงทะเบียน
  Future<void> _initializePins() async {
    try {
      // ⭐ เนื่องจากล้างข้อมูลเดิมไปหมดแล้ว ไม่ต้อง load PIN เก่า
      // แค่สร้างเลขใหม่เลย
      AppLogger.debug('[RegisterPOS] 🆕 Generating new PIN for registration...');
      await initPinCode();
    } catch (e) {
      AppLogger.error('[RegisterPOS] ❌ Error initializing PINs: $e');
      // ถ้า error ก็ยังสร้างเลขใหม่
      await initPinCode();
    }
  }

  @override
  void dispose() {
    _recheckTimer?.cancel();
    super.dispose();
  }

  Future<void> recheck() async {
    AppLogger.debug('[RegisterPOS] 🔄 Checking approval status...');

    try {
      // ✅ เพิ่ม timeout 5 วินาที
      var responseData =
          await clickHouseSelect(
            "SELECT status,token,deviceid,access_token,shipid,isdev,apikey,username "
            "FROM poscenter.pinlist WHERE pincode='${global.posTerminalPinCode}'",
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              AppLogger.debug('[RegisterPOS] ⏱️ Recheck timeout');
              return {};
            },
          );

      if (!mounted) return; // ✅ Check mounted หลัง async

      if (responseData.isEmpty) return;

      ResponseDataModel result = ResponseDataModel.fromJson(responseData);
      AppLogger.warning('[RegisterPOS] Response data: ${result.data}');
      if (result.data.isEmpty) return;

      if (result.data[0]['status'] == 1) {
        // ✅ Cancel timer ทันทีเมื่อ approved
        _recheckTimer?.cancel();

        AppLogger.debug('[RegisterPOS] ✅ PIN approved! Logging in...');

        // ✅ แยก login logic ออกมา
        await _handleApprovedPin(result.data[0]);
      }
    } catch (e) {
      AppLogger.error('[RegisterPOS] ❌ Recheck error: $e');
    }
  }

  /// ✅ แยก approved login logic เพื่อ maintainability
  Future<void> _handleApprovedPin(Map<String, dynamic> data) async {
    if (!mounted) return;

    try {
      global.posTerminalPinTokenId = data['token'] ?? '';
      global.deviceId = data['deviceid'] ?? '';
      global.shopId = data['shipid'] ?? '';
      global.username = data['username'] ?? '';

      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

      // ✅ บันทึก PIN ที่ลงทะเบียนสำเร็จแล้ว
      await sharedPreferences.setString('pos_terminal_pin_code', global.posTerminalPinCode);
      AppLogger.debug('[RegisterPOS] 💾 PIN saved to SharedPreferences after successful registration');

      await sharedPreferences.setString('pos_terminal_token', global.posTerminalPinTokenId);
      await sharedPreferences.setString('pos_device_id', global.deviceId);
      await sharedPreferences.setString('cache_shopid', global.shopId);
      await sharedPreferences.setString('apikey', data['apikey'] ?? '');
      await sharedPreferences.setString('mediaguid', "");
      await sharedPreferences.setString('last_doc_no', "");

      global.appStorage.write("apikey", data['apikey']);
      global.appStorage.write("cache_shopid", global.shopId);
      global.informationList.clear();
      global.apiConnected = true;
      global.loginProcess = true;

      // ✅ Setup environment
      int isDev = data['isdev'] ?? 0;
      if (isDev == 1) {
        Environment().initConfig("DEV");
      } else if (isDev == 2) {
        Environment().initConfig("STAGING");
      } else {
        Environment().initConfig("PROD");
      }
      serviceLocator<Request>().updateEndpoint();

      // ✅ Clear data in parallel
      await Future.wait([
        Future(() => ProductCategoryHelper().deleteAll()),
        Future(() => ProductBarcodeHelper().deleteAll()),
        Future(() => EmployeeHelper().deleteAll()),
        Future(() => BankHelper().deleteAll()),
        Future(() => TableProcessHelper().deleteAll()),
        Future(() => KitchenHelper().deleteAll()),
        Future(() => CustomerHelper().deleteAll()),
      ]);

      if (!mounted) return;

      // ✅ Authenticate
      ApiRepository apiRepository = ApiRepository();
      final res = await apiRepository.authenUser(global.username, global.shopId, isDev);

      if (!mounted) return;

      if (res.success) {
        String accessToken = res.data['token'];
        global.appStorage.write("token", accessToken);
        await sharedPreferences.setString('token', accessToken);

        serviceLocator<Request>().updateAuthorization(accessToken);

        final profileResponse = await serviceLocator<LoginUserRepository>().profile();

        if (!mounted) return;

        if (profileResponse.isRight()) {
          User remoteUser = profileResponse.getOrElse(() => User());
          remoteUser = remoteUser.copyWith(token: accessToken, isDev: isDev);

          await serviceLocator<UserCacheService>().saveUser(remoteUser);

          final selectShopResponse = await serviceLocator<ShopAuthenticationRepository>().selectShop(shopid: global.shopId);

          if (!mounted) return;

          if (selectShopResponse.isRight()) {
            global.loginSuccess = true;

            if (mounted) {
              context.read<AuthenticationBloc>().add(AuthenticationEvent.authenticated(user: remoteUser));
            }

            await global.getProfile();

            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, global.selectIpServerPageName, (route) => false);
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ ไม่สามารถเลือก Shop ได้"), backgroundColor: Colors.red));
            }
          }
        }
      } else {
        AppLogger.debug('[RegisterPOS] ❌ Authentication failed: ${res.error}');
      }
    } catch (e) {
      AppLogger.error('[RegisterPOS] ❌ Handle approved PIN error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ เกิดข้อผิดพลาด: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> checkPinCode() async {
    // ตรวจสอบว่า ClickHouse ไม่มี PinCode เพิ่มให้ใหม่
    global.isOnline = await global.hasNetwork();
    var responseData = await clickHouseSelect("SELECT status,token,deviceid FROM poscenter.pinlist WHERE pincode='${global.posTerminalPinCode}'");
    ResponseDataModel result = ResponseDataModel.fromJson(responseData);
    if (result.data.isEmpty) {
      await clickHouseExecute("INSERT INTO poscenter.pinlist (pincode,status) VALUES ('${global.posTerminalPinCode}',0)");
    }
  }

  /// 🎮 Demo Mode - Mock response และ bypass การเชื่อม PIN
  Future<void> _activateDemoMode() async {
    AppLogger.debug('[RegisterPOS] 🎮 Demo Mode activated!');

    // ✅ Cancel timer ทันทีเมื่อเข้า Demo Mode
    _recheckTimer?.cancel();

    // ✅ Set global.isDemoMode = true
    global.isDemoMode = true;

    // ✅ Mock response data ตามที่ระบุ
    final Map<String, dynamic> mockData = {
      'access_token': '53c74bb7281972f02e3be08412d168cb382d2e1f9a9e80a3cb20df8b4f15f20e',
      'apikey': '4590045f934410a7194aa5ef9399c65542fc829d7a25ef3acb3b38600e28ab16',
      'deviceid': 'ADMIN001',
      'isdev': 1,
      'shipid': '2V6bwaTAjO5Uz9DYDWxiihHjpQw',
      'status': 1,
      'token': null,
      'username': const String.fromEnvironment('REGISTER_CONTACT_EMAIL', defaultValue: 'developer@example.com'),
    };

    final Map<String, dynamic> mockDataRestaurant = {
      'access_token': 'fc0a0867a6d25c7d171b807cf8c9811ab58ffa4f27693bee28651f548bf569c7',
      'apikey': '778cb103ad80d62c83d584b31acf35b77d07ff078ee4c09abde688317cf6e6a8',
      'deviceid': 'RES01',
      'isdev': 1,
      'shipid': '2OJMVIo1Qi81NqYos3oDPoASziyMNNK2',
      'status': 1,
      'token': null,
      'username': const String.fromEnvironment('REGISTER_CONTACT_EMAIL', defaultValue: 'developer@example.com'),
    };

    AppLogger.warning('[RegisterPOS] 🎮 Mock Data: $mockData');

    // ✅ เรียก _handleApprovedPin เหมือน flow ปกติ
    if (F.appFlavor == Flavor.CASHIER) {
      await _handleApprovedPin(mockDataRestaurant);
    } else {
      await _handleApprovedPin(mockData);
    }
  }

  Future<void> initPinCode() async {
    global.isOnline = await global.hasNetwork();

    // ✅ สร้างเลขใหม่ (memory only - ยังไม่บันทึก SharedPreferences)
    global.posTerminalPinCode = global.generateRandomPin(8);
    _currentPinCode = global.posTerminalPinCode;

    if (kDebugMode) {
      AppLogger.debug('[RegisterPOS] 🆕 New PIN generated: $_currentPinCode');
      AppLogger.warning('[RegisterPOS] ⚠️ Not saved to SharedPreferences yet (waiting for approval)');
    }

    // ❌ ห้ามแก้ไข SharedPreferences ตอนนี้ - รอให้ลงทะเบียนสำเร็จก่อน
    // await sharedPreferences.setString('pos_terminal_pin_code', global.posTerminalPinCode);

    // ✅ Insert เลขใหม่ไปที่ ClickHouse (เพื่อรอการอนุมัติ)
    await clickHouseExecute("INSERT INTO poscenter.pinlist (pincode,status) VALUES ('${global.posTerminalPinCode}',0)");

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("ลงทะเบียนเครื่อง POS Terminal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text("กรุณาแจ้ง รหัสด้านล่างไปยัง Admin แล้วรอการตอบกลับ", style: TextStyle(fontSize: 12)),
                const Text("เมื่อได้รับอนุมติ โปรแกรมจะเข้าสู่ระบบ Login อัตโนมัติ", style: TextStyle(fontSize: 12)),
                const SizedBox(height: 20),

                // 🆕 รหัส PIN ใหม่
                const Text(
                  "🆕 รหัส PIN ใหม่:",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var pinChar in _currentPinCode.split(''))
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(5),
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.green.shade200, blurRadius: 5, offset: const Offset(0, 3))],
                          ),
                          child: Text(
                            pinChar,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 30),

                // 🎮 ปุ่ม Demo Mode
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _activateDemoMode,
                    icon: const Icon(Icons.play_circle_outline, size: 24),
                    label: const Text("Demo Mode", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // ✅ Animation หมุนต่อเนื่อง
                LoadingAnimationWidget.threeArchedCircle(color: Colors.blue, size: 50),
                const SizedBox(height: 10),
                const Text("⏳ รอการอนุมัติจาก Admin", style: TextStyle(fontSize: 12, color: Colors.blue)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
