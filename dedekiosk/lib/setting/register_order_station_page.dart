import 'dart:async';
import 'dart:io' show Platform;

import 'package:dedekiosk/bloc/list_kiosk/list_kiosk_bloc.dart';
import 'package:dedekiosk/bloc/list_shop/list_shop_bloc.dart';
import 'package:dedekiosk/bloc/login_bloc/login_bloc.dart';
import 'package:dedekiosk/bloc/shop_select/shop_select_bloc.dart';
import 'package:dedekiosk/model/kiosk_list_model.dart';
import 'package:dedekiosk/model/shop_list_model.dart';
import 'package:dedekiosk/model/user_login_model.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/util/client.dart';
import 'package:dedekiosk/service/auth_service.dart';
import 'package:dedekiosk/util/environment.dart';
import 'package:dedekiosk/model/global_model.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';

class RegisterOrderStationPage extends StatefulWidget {
  const RegisterOrderStationPage({Key? key}) : super(key: key);
  @override
  _RegisterOrderStationPageState createState() => _RegisterOrderStationPageState();
}

class _RegisterOrderStationPageState extends State<RegisterOrderStationPage> {
  late Timer findTerminalTimer;
  final AuthService _auth = AuthService();
  int tabCount = 0;
  bool showSelectShop = false;
  List<ShopListModel> shopList = [];
  List<KioskListModel> kioskList = [];
  bool showKioskList = false;
  bool isloading = false;
  bool _isGoogleLoading = false; // Loading state for Google login
  bool _isChecking = false; // Prevent concurrent recheck() calls
  bool _isPinInitialized = false; // Track if PIN is successfully initialized
  int _recheckAttempts = 0; // Track recheck attempts
  static const int _maxRecheckAttempts = 720; // 1 hour (720 * 5 seconds)

  // Demo PIN for Apple App Store Review (Guideline 2.1)
  static const String _demoPinCode = 'DEMODEMO';
  bool _isDemoMode = false;

  // Showcase keys for first-time guide
  final GlobalKey _pinCodeKey = GlobalKey();
  final GlobalKey _googleLoginKey = GlobalKey();
  BuildContext? _showcaseContext;
  bool _showcaseShown = false; // Track if showcase has been shown this session

  Color get primaryThemeColor {
    return _hexToColor(global.deviceConfig.primaryThemeColor);
  }

  // Helper function to convert hex string to Color
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  void initState() {
    super.initState();
    initPinCode();
    findTerminalTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      recheck();
    });

    // Start showcase guide when entering this page for the first time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowShowcase();
    });
  }

  // Check if showcase should be shown (only first time)
  Future<void> _checkAndShowShowcase() async {
    if (_showcaseShown) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenShowcase = prefs.getBool('register_page_showcase_seen') ?? false;

    if (!hasSeenShowcase && mounted && _showcaseContext != null) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && _showcaseContext != null) {
        _showcaseShown = true;
        ShowCaseWidget.of(_showcaseContext!).startShowCase([
          _pinCodeKey,
          _googleLoginKey,
        ]);
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

  @override
  void dispose() {
    super.dispose();
    findTerminalTimer.cancel();
    _showcaseContext = null;
  }

  Future<void> recheck() async {
    // Prevent concurrent calls
    if (_isChecking) return;

    // Check if max attempts reached
    _recheckAttempts++;
    if (_recheckAttempts > _maxRecheckAttempts) {
      if (mounted) {
        findTerminalTimer.cancel();
        _showErrorDialog(
          'Registration Timeout',
          'The registration has timed out. Please try again or contact the administrator.',
        );
      }
      return;
    }

    _isChecking = true;

    try {
      if (!_isPinInitialized) {
        // Skip check if PIN not initialized
        return;
      }

      var responseData = await api.clickHouseSelect("SELECT status,token,deviceid,access_token,shipid,isdev,apikey,username,user FROM poscenter.pinlist WHERE pincode='${global.posTerminalPinCode}'");
      print("Recheck responseData: $responseData");
      if (responseData.isNotEmpty) {
        ResponseDataModel result = ResponseDataModel.fromJson(responseData);
        if (result.data.isNotEmpty) {
          if (result.data[0]['status'] == 1) {
            // Cancel timer immediately when approved
            findTerminalTimer.cancel();

            try {
              // Null safety checks
              final username = result.data[0]['username']?.toString() ?? '';
              final shopId = result.data[0]['shipid']?.toString() ?? '';
              final deviceId = result.data[0]['deviceid']?.toString() ?? '';
              final apikey = result.data[0]['apikey']?.toString() ?? '';
              final isdev = result.data[0]['isdev']?.toString() ?? '0';

              if (username.isEmpty || shopId.isEmpty || deviceId.isEmpty) {
                throw Exception('Incomplete device configuration from server');
              }

              global.deviceConfig.usercode = username;
              global.deviceConfig.shopId = shopId;
              global.deviceConfig.orderStationCode = deviceId;
              global.deviceConfig.apikey = apikey;
              global.deviceConfig.isdev = isdev;

              // Set environment
              if (result.data[0]['isdev'] == 1) {
                Environment().initConfig("DEV");
              } else if (result.data[0]['isdev'] == 2) {
                Environment().initConfig("STAGING");
              } else {
                Environment().initConfig("PROD");
              }

              if (mounted) {
                // Authenticate user with retry
                final authResult = await _authenticateWithRetry(username, shopId);

                if (authResult.success) {
                  global.deviceConfig.token = authResult.data['token'];
                  global.deviceConfig.kitchens.clear();
                  await global.saveDeviceConfigToStorage(context);
                  try {
                    await global.loadConfig();
                    var profile = await api.getShopProfileFromServer(deviceConfig: global.deviceConfig, shopId: global.deviceConfig.shopId, orderStationCode: global.deviceConfig.orderStationCode);
                    if (profile["data"] != null) {
                      global.shopProfile = ShopProfileModel.fromJson(profile["data"]);
                      // global.objectBoxStore.box<TransactionObjModel>().removeAll();

                      if (mounted) {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('register_page_showcase_seen', true);
                        _showRegistrationSuccessDialog();
                      }
                    } else {
                      throw Exception('Failed to load shop profile');
                    }
                  } catch (e, s) {
                    if (kDebugMode) {
                      print('Error loading config: $e');
                      print(s);
                    }
                    if (mounted) {
                      _showErrorDialog('Configuration Error', 'Failed to load shop configuration: ${e.toString()}');
                    }
                  }
                } else {
                  if (kDebugMode) {
                    print('Authentication failed: ${authResult.error}');
                  }
                  if (mounted) {
                    _showErrorDialog('Authentication Failed', authResult.message ?? 'Failed to authenticate. Please try again.');
                  }
                }
              }
            } catch (e, s) {
              if (kDebugMode) {
                print('Error in recheck: $e');
                print(s);
              }
              if (mounted) {
                _showErrorDialog('Registration Error', e.toString());
              }
            }
          }
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('Network error in recheck: $e');
        print(s);
      }
      // Don't show error for network issues, just log and retry next time
    } finally {
      _isChecking = false;
    }
  }

  // Helper method to authenticate with retry logic
  Future<ApiResponse> _authenticateWithRetry(String username, String shopId, {int maxRetries = 3}) async {
    int attempt = 0;
    ApiResponse? lastResult;

    while (attempt < maxRetries) {
      try {
        final result = await api.authenUser(username, shopId);
        if (result.success) {
          return result;
        }
        lastResult = result;
        attempt++;
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
        }
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          return ApiResponse(
            success: false,
            error: true,
            message: 'Authentication failed after $maxRetries attempts: ${e.toString()}',
            data: {},
          );
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    return lastResult ?? ApiResponse(success: false, error: true, message: 'Authentication failed', data: {});
  }

  // Helper method to show error dialogs
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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

  // Show success dialog after registration with navigation options
  void _showRegistrationSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              // Success Title
              Text(
                global.language("registration_success"),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Device Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      global.deviceConfig.orderStationCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      global.shopProfile?.name1 ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Buttons Row
              Row(
                children: [
                  // Settings Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/setting_main',
                          (Route<dynamic> route) => false,
                        );
                      },
                      icon: const Icon(Icons.settings, size: 20),
                      label: Text(
                        global.language("ok"),
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /*Future<void> checkPinCode() async {
    // ตรวจสอบว่า ClickHouse ไม่มี PinCode เพิ่มให้ใหม่
    var responseData = await api.clickHouseSelect(
        "SELECT status,token,deviceid FROM poscenter.pinlist WHERE pincode='${global.posTerminalPinCode}'");
    ResponseDataModel result = ResponseDataModel.fromJson(responseData);
    if (result.data.isEmpty) {
      try {
        await api.clickHouseExecute(
            "INSERT INTO poscenter.pinlist (pincode,status) VALUES ('${global.posTerminalPinCode}',0)");
      } catch (e,s) {
        print(e);
      }
    }
  }*/

  Future<void> initPinCode() async {
    // Cancel old PIN if exists
    if (global.posTerminalPinCode.isNotEmpty) {
      try {
        await api.clickHouseExecute("DELETE FROM poscenter.pinlist WHERE pincode='${global.posTerminalPinCode}'");
      } catch (e) {
        if (kDebugMode) {
          print('Failed to delete old PIN: $e');
        }
      }
    }

    // Reset state
    _isPinInitialized = false;
    _recheckAttempts = 0;

    // Generate unique PIN with retry
    int maxAttempts = 5;
    int attempt = 0;
    bool pinInserted = false;

    while (attempt < maxAttempts && !pinInserted) {
      try {
        // Generate new random PIN
        global.posTerminalPinCode = global.generateRandomPin(8);

        // Save to SharedPreferences
        SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
        await sharedPreferences.setString('pos_terminal_pin_code', global.posTerminalPinCode);

        // Try to insert into database
        var result = await api.clickHouseExecute("INSERT INTO poscenter.pinlist (pincode,status) VALUES ('${global.posTerminalPinCode}',0)");

        // Check if insertion was successful
        if (result.isNotEmpty && result['error'] == null) {
          pinInserted = true;
          _isPinInitialized = true;
          if (mounted) {
            setState(() {});
          }
          break;
        } else {
          attempt++;
          if (kDebugMode) {
            print('PIN insertion attempt $attempt failed, retrying...');
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e, s) {
        attempt++;
        if (kDebugMode) {
          print('Error inserting PIN (attempt $attempt): $e');
          print(s);
        }

        if (attempt >= maxAttempts) {
          // Failed after all retries
          if (mounted) {
            _showErrorDialog(
              'Registration Failed',
              'Failed to initialize registration code. Please check your internet connection and try again.',
            );
            setState(() {});
          }
          return;
        }

        await Future.delayed(Duration(seconds: attempt)); // Exponential backoff
      }
    }

    if (!pinInserted && mounted) {
      _showErrorDialog(
        'Registration Failed',
        'Unable to generate registration code after multiple attempts. Please try again later.',
      );
    }
  }

  /// Demo Mode สำหรับ Apple App Store Review (Guideline 2.1)
  /// ใช้ PIN: DEMODEMO เพื่อเข้าสู่ Demo Mode
  Future<void> _activateDemoMode() async {
    if (kDebugMode) {
      print('🎮 Activating Demo Mode for Apple Review...');
    }

    // Cancel the timer
    findTerminalTimer.cancel();

    // Demo data (simulated server response)
    const demoData = {
      'access_token': 'f7203518adcd7e53202e3af4fa3cbf792244f5186defa05b0f15c4a3612cae5b',
      'apikey': '8248437094e11a0e007bc181702eea9083a591ec5e0764a1e585ee5e40a0e15f',
      'deviceid': '97',
      'isdev': 1,
      'shipid': '2QoilMQkX9i6vtAE88ilEubnrhz69PJN',
      'status': 1,
      'username': const String.fromEnvironment('REGISTER_CONTACT_EMAIL', defaultValue: 'developer@example.com'),
    };

    try {
      // Set demo configuration
      global.deviceConfig.usercode = demoData['username'] as String;
      global.deviceConfig.shopId = demoData['shipid'] as String;
      global.deviceConfig.orderStationCode = demoData['deviceid'] as String;
      global.deviceConfig.apikey = demoData['apikey'] as String;
      global.deviceConfig.isdev = (demoData['isdev'] as int).toString();

      // Set DEV environment for demo
      Environment().initConfig("DEV");

      if (mounted) {
        // Authenticate with demo credentials
        final authResult = await _authenticateWithRetry(
          demoData['username'] as String,
          demoData['shipid'] as String,
        );

        if (authResult.success) {
          global.deviceConfig.token = authResult.data['token'];
          global.deviceConfig.kitchens.clear();
          await global.saveDeviceConfigToStorage(context);

          try {
            await global.loadConfig();
            var profile = await api.getShopProfileFromServer(
              deviceConfig: global.deviceConfig,
              shopId: global.deviceConfig.shopId,
              orderStationCode: global.deviceConfig.orderStationCode,
            );

            if (profile["data"] != null) {
              global.shopProfile = ShopProfileModel.fromJson(profile["data"]);
              // global.objectBoxStore.box<TransactionObjModel>().removeAll();

              if (mounted) {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('register_page_showcase_seen', true);
                _showRegistrationSuccessDialog();
              }
            } else {
              throw Exception('Failed to load shop profile in demo mode');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Demo mode config error: $e');
            }
            if (mounted) {
              _showErrorDialog('Demo Mode Error', 'Failed to load demo configuration: ${e.toString()}');
            }
          }
        } else {
          if (mounted) {
            _showErrorDialog('Demo Mode Error', 'Authentication failed: ${authResult.message}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Demo mode error: $e');
      }
      if (mounted) {
        _showErrorDialog('Demo Mode Error', 'Failed to activate demo mode: ${e.toString()}');
      }
    }
  }

  /// แสดง Dialog ยืนยันเข้า Demo Mode (สำหรับ App Review)
  void _showDemoModeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.play_circle_outline, color: Colors.blueGrey, size: 28),
              const SizedBox(width: 8),
              const Text('Demo Mode'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Demo Mode allows you to explore the app with sample data.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                'This will connect to a demo restaurant for testing purposes.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Activate demo mode directly
                _isDemoMode = true;
                _activateDemoMode();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
              ),
              child: const Text('Enter Demo Mode'),
            ),
          ],
        );
      },
    );
  }

  Widget logInForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final maxWidth = constraints.maxWidth > 700 ? 500.0 : constraints.maxWidth * 0.9;
        final horizontalPadding = isSmallScreen ? 10.0 : 24.0;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFFE8D5C4), const Color(0xFFF5EBE0)], // สีอิฐบ้านเชียง
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: isSmallScreen ? 12 : 20),
                      // Title Card
                      Card(
                        elevation: 0,
                        color: Colors.transparent,
                        child: InkWell(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 16 : 24,
                                vertical: isSmallScreen ? 10 : 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [const Color(0xFFB85C38), const Color(0xFF8B4513)], // สีอิฐแดง-น้ำตาล
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB85C38).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                global.language("register_order_station_machine") + (global.deviceConfig.isdev == '1' ? " (Dev)" : ""),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            onTap: () {
                              //tab 5 ทีเพื่อสลับโหมด dev prod
                              if (tabCount == 5) {
                                //showdialoog select mode dev prod staging
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(global.language("เลือกโหมด")),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ElevatedButton(
                                                onPressed: () async {
                                                  global.deviceConfig.isdev = "1";
                                                  Environment().initConfig("DEV");
                                                  global.saveDeviceConfigToStorage(context);
                                                  setState(() {});
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text(global.language("dev"))),
                                            ElevatedButton(
                                                onPressed: () async {
                                                  global.deviceConfig.isdev = "2";
                                                  Environment().initConfig("STAGING");
                                                  global.saveDeviceConfigToStorage(context);
                                                  setState(() {});
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text(global.language("staging"))),
                                            ElevatedButton(
                                                onPressed: () async {
                                                  global.deviceConfig.isdev = "0";
                                                  Environment().initConfig("PROD");
                                                  global.saveDeviceConfigToStorage(context);
                                                  setState(() {});
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text(global.language("prod"))),
                                          ],
                                        ),
                                      );
                                    });
                                tabCount = 0;
                              }
                              tabCount++;
                            }),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 30),
                      // Info Card
                      Card(
                        elevation: 2,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          child: Column(
                            children: [
                              Icon(Icons.qr_code_scanner, size: isSmallScreen ? 40 : 48, color: const Color(0xFFB85C38)),
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              Text(
                                global.language("please_inform_code_below_to_admin_and_wait_for_response"),
                                style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.grey.shade700),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                global.language("when_approval_program_automatically_enter_login"),
                                style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.grey.shade700),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      // PIN Code Display
                      Showcase(
                        key: _pinCodeKey,
                        description: 'แจ้งหมายเลขนี้ให้ Admin หรือ Scan QR Code นี้ด้วย BC Merchant Lite',
                        child: Card(
                          elevation: 4,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Container(
                            padding: EdgeInsets.all(isSmallScreen ? 8 : 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, const Color(0xFFF5EBE0)], // สีอิฐอ่อน
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Registration Code',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                LayoutBuilder(
                                  builder: (context, boxConstraints) {
                                    final availableWidth = boxConstraints.maxWidth;
                                    final pinLength = global.posTerminalPinCode.length;
                                    final spacing = isSmallScreen ? 2.0 : 4.0;
                                    final totalSpacing = spacing * (pinLength - 1) * 2;
                                    final boxWidth = ((availableWidth - totalSpacing) / pinLength).clamp(30.0, 45.0);
                                    final boxHeight = isSmallScreen ? 50.0 : 60.0;

                                    return Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: spacing,
                                      runSpacing: spacing,
                                      children: [
                                        for (var pinChar in global.posTerminalPinCode.split(''))
                                          Container(
                                            width: boxWidth,
                                            height: boxHeight,
                                            margin: EdgeInsets.symmetric(horizontal: spacing),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(color: const Color(0xFFD4A373), width: 2), // สีอิฐอ่อน
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFE8D5C4).withOpacity(0.5),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                pinChar,
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 20 : 28,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFFB85C38), // สีอิฐแดง
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 20),
                                LayoutBuilder(
                                  builder: (context, boxConstraints) {
                                    final qrSize = (boxConstraints.maxWidth * 0.8).clamp(180.0, 240.0);
                                    return Container(
                                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.shade300,
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: QrImageView(
                                        data: global.posTerminalPinCode,
                                        size: qrSize,
                                        backgroundColor: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      // Instructions Card
                      Card(
                        elevation: 1,
                        color: Colors.orange.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: isSmallScreen ? 18 : 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Change Device',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 13 : 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 6 : 8),
                              Text(
                                global.language("in_case_wanting_change_device_another_data"),
                                style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey.shade700),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                global.language("press_registration_button_and_notify_admin"),
                                style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey.shade700),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                global.language("wait_approve_new_registration"),
                                style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey.shade700),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(global.language("confirm_new_registration")),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(global.language("cancel")),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await initPinCode().then((value) {
                                          Navigator.of(context).pop();
                                        });
                                      },
                                      child: Text(global.language("confirm")),
                                    ),
                                  ],
                                );
                              });
                        },
                        icon: Icon(Icons.refresh, size: isSmallScreen ? 18 : 24),
                        label: Text(
                          global.language("new_registration"),
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 24 : 32,
                            vertical: isSmallScreen ? 12 : 16,
                          ),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      // Demo Mode สำหรับ App Store Review
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Show Demo Mode input dialog
                          _showDemoModeDialog();
                        },
                        icon: Icon(Icons.play_circle_outline, size: isSmallScreen ? 18 : 24),
                        label: Text(
                          'Demo Mode',
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 24 : 32,
                            vertical: isSmallScreen ? 12 : 16,
                          ),
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                      // ซ่อน Google Sign-In บน iOS เพื่อให้ผ่าน Apple Guideline 4.8.0
                      // iOS ใช้ PIN code login แทน
                      // if (!Platform.isIOS) ...[
                      //   SizedBox(height: isSmallScreen ? 16 : 24),
                      //   Showcase(
                      //     key: _googleLoginKey,
                      //     description: 'หรือเข้าสู่ระบบด้วย Google',
                      //     child: buttonLoginWithGoogle(),
                      //   ),
                      // ],
                      SizedBox(height: isSmallScreen ? 16 : 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void registerDevice(KioskListModel divice) async {
    if (isloading) return; // Prevent double-tap

    setState(() {
      isloading = true;
    });

    try {
      // Ensure we have shopId before proceeding
      if (global.deviceConfig.shopId.isEmpty) {
        throw Exception('Shop ID is empty. Please select a shop first.');
      }

      global.deviceConfig.orderStationCode = divice.code;

      // Step 1: Update PIN status in database
      var updateResult = await api.clickHouseExecute(
          "ALTER TABLE poscenter.pinlist UPDATE status='1',username='${global.deviceConfig.usercode}',shipid='${global.deviceConfig.shopId}',deviceid='${global.deviceConfig.orderStationCode}',access_token='${global.deviceConfig.token}',isdev='${global.deviceConfig.isdev}',apikey='${global.deviceConfig.apikey}' WHERE pincode='${global.posTerminalPinCode}'");

      if (updateResult.isEmpty || updateResult['error'] != null) {
        throw Exception('Failed to update PIN status in database');
      }

      // Step 2: Update Kiosk model
      try {
        KioskListModel kioskUpdate = kioskList.firstWhere((element) => element.code == global.deviceConfig.orderStationCode);
        kioskUpdate.isposactive = true;
        kioskUpdate.activepin = global.posTerminalPinCode;
        await api.updateDevice(kioskUpdate);
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Failed to update kiosk model: $e');
        }
        // Continue even if this fails - not critical
      }

      // Step 3: Get shop profile (BEFORE loadConfig to avoid overriding shopId)
      var profile = await api.getShopProfileFromServer(deviceConfig: global.deviceConfig, shopId: global.deviceConfig.shopId, orderStationCode: global.deviceConfig.orderStationCode);

      if (profile["data"] == null) {
        global.sendErrorToDevTeam("Error registerDevice() Shop profile data is empty");
        throw Exception('Shop profile data is empty');
      }

      global.shopProfile = ShopProfileModel.fromJson(profile["data"]);

      // Step 4: Clear old transactions
      // global.objectBoxStore.box<TransactionObjModel>().removeAll();

      // Step 5: Save configuration to storage (after all values are set)
      if (mounted) {
        await global.saveDeviceConfigToStorage(context);
      }

      // Step 6: Load config from storage to ensure consistency
      await global.loadConfig();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('register_page_showcase_seen', true);
      // Step 7: Cancel timer and show success dialog
      if (mounted) {
        findTerminalTimer.cancel();
        setState(() {
          isloading = false;
        });
        _showRegistrationSuccessDialog();
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('Error in registerDevice: $e');
        print(s);
      }
      global.sendErrorToDevTeam("Error registerDevice() $e");

      if (mounted) {
        setState(() {
          isloading = false;
        });

        _showErrorDialog(
          global.language("error"),
          '${global.language("error occurred please try again")}\n\nDetails: ${e.toString()}',
        );
      }
    }
  }

  Widget showKioskListForm() {
    String mode = (global.deviceConfig.isdev == "0") ? "" : " (Dev)";
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        final isLargeScreen = constraints.maxWidth >= 900;

        // Calculate grid columns based on screen size
        int crossAxisCount = 1;
        if (isLargeScreen) {
          crossAxisCount = 3;
        } else if (isMediumScreen) {
          crossAxisCount = 2;
        }
        final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
        final maxWidth = isLargeScreen ? 1200.0 : (isMediumScreen ? 900.0 : constraints.maxWidth * 0.9);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFFE8D5C4), const Color(0xFFF5EBE0)], // สีอิฐบ้านเชียง
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      // Header Section - Compact
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFD4A373), Color(0xFFB85C38)], // สีอิฐ
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.point_of_sale, size: 20, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        global.language("select_pos") + mode,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 18 : 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Choose a POS device to register',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EBE0), // สีอิฐอ่อน
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD4A373)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.devices, size: 14, color: const Color(0xFFB85C38)),
                                const SizedBox(width: 4),
                                Text(
                                  '${kioskList.length}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB85C38),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      // Grid View for POS devices
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: isSmallScreen ? 2.5 : (isMediumScreen ? 2.2 : 2.0),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: kioskList.length,
                        itemBuilder: (context, index) {
                          final device = kioskList[index];
                          final colors = [
                            [const Color(0xFFB85C38), const Color(0xFF8B4513)], // สีอิฐแดง-น้ำตาล
                            [const Color(0xFFCD7F32), const Color(0xFFB8733B)], // สีทองแดง
                            [const Color(0xFFD4A373), const Color(0xFFBC8A5F)], // สีอิฐอ่อน
                            [const Color(0xFFC19A6B), const Color(0xFFA98656)], // สีทรายทอง
                            [const Color(0xFF9C6644), const Color(0xFF7F4F3D)], // สีน้ำตาลแดง
                            [const Color(0xFFCC8866), const Color(0xFFB47555)], // สีอิฐส้ม
                          ];
                          final colorPair = colors[index % colors.length];

                          return Card(
                            elevation: 3,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: InkWell(
                              onTap: () async {
                                registerDevice(device);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: colorPair,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Stack(
                                  children: [
                                    // Background pattern
                                    Positioned(
                                      right: -20,
                                      bottom: -20,
                                      child: Icon(
                                        Icons.desktop_windows,
                                        size: 100,
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    // Content
                                    Padding(
                                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.25),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.3),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.computer,
                                                  color: Colors.white,
                                                  size: isSmallScreen ? 24 : 28,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.arrow_forward,
                                                  color: Colors.white,
                                                  size: isSmallScreen ? 18 : 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  device.code,
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 16 : 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    height: 1.2,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Tap to register',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 12 : 13,
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontWeight: FontWeight.w500,
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
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget shopListForm() {
    // List Shop
    String mode = (global.deviceConfig.isdev == "0") ? "" : " (Dev)";
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        final isLargeScreen = constraints.maxWidth >= 900;

        // Calculate grid columns based on screen size
        int crossAxisCount = 1;
        if (isLargeScreen) {
          crossAxisCount = 3;
        } else if (isMediumScreen) {
          crossAxisCount = 2;
        }
        final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
        final maxWidth = isLargeScreen ? 1200.0 : (isMediumScreen ? 900.0 : constraints.maxWidth * 0.9);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFFE8D5C4), const Color(0xFFF5EBE0)], // สีอิฐบ้านเชียง
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      // Header Section - Compact
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.green.shade400, Colors.green.shade600],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.storefront, size: 20, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        global.language("select_shop") + mode,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 18 : 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Select your shop to continue',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.store, size: 14, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  '${shopList.length}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      // Grid View for shops
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: isSmallScreen ? 2.5 : (isMediumScreen ? 2.2 : 2.0),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: shopList.length,
                        itemBuilder: (context, index) {
                          final shop = shopList[index];
                          final colors = [
                            [const Color(0xFFB85C38), const Color(0xFF8B4513)], // สีอิฐแดง-น้ำตาล
                            [const Color(0xFFCD7F32), const Color(0xFFB8733B)], // สีทองแดง
                            [const Color(0xFFD4A373), const Color(0xFFBC8A5F)], // สีอิฐอ่อน
                            [const Color(0xFFC19A6B), const Color(0xFFA98656)], // สีทรายทอง
                            [const Color(0xFF9C6644), const Color(0xFF7F4F3D)], // สีน้ำตาลแดง
                            [const Color(0xFFCC8866), const Color(0xFFB47555)], // สีอิฐส้ม
                          ];
                          final colorPair = colors[index % colors.length];

                          return Card(
                            elevation: 3,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: InkWell(
                              onTap: () {
                                context.read<ShopSelectBloc>().add(ShopSelect(shop: shop));
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: colorPair,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Stack(
                                  children: [
                                    // Background pattern
                                    Positioned(
                                      right: -20,
                                      bottom: -20,
                                      child: Icon(
                                        Icons.store_mall_directory,
                                        size: 100,
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    // Content
                                    Padding(
                                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.25),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.3),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.shopping_bag_outlined,
                                                  color: Colors.white,
                                                  size: isSmallScreen ? 24 : 28,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.arrow_forward,
                                                  color: Colors.white,
                                                  size: isSmallScreen ? 18 : 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  global.getNameFromLanguage(shop.names, global.languageForCustomer),
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 16 : 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    height: 1.2,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Tap to select',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 12 : 13,
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontWeight: FontWeight.w500,
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
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget buttonLoginWithGoogle() {
  //   return Card(
  //     elevation: 3,
  //     shadowColor: Colors.black26,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //     child: InkWell(
  //       onTap: _isGoogleLoading
  //           ? null
  //           : () async {
  //               setState(() {
  //                 _isGoogleLoading = true;
  //               });
  //               try {
  //                 final user = await _auth.signInWithGoogle();
  //                 if (user != null) {
  //                   print('Logged in: ${user.displayName}');
  //                   String? userIdToken = await _auth.getCurrentUserIdToken();
  //                   if (userIdToken != null) {
  //                     print('userIdToken: $userIdToken');
  //                     context.read<LoginBloc>().add(TokenLogin(user: user.email!, token: userIdToken));
  //                   } else {
  //                     if (mounted) {
  //                       setState(() {
  //                         _isGoogleLoading = false;
  //                       });
  //                     }
  //                   }
  //                 } else {
  //                   if (mounted) {
  //                     setState(() {
  //                       _isGoogleLoading = false;
  //                     });
  //                   }
  //                 }
  //               } catch (e) {
  //                 if (mounted) {
  //                   setState(() {
  //                     _isGoogleLoading = false;
  //                   });
  //                   _showErrorDialog('Login Error', e.toString());
  //                 }
  //               }
  //             },
  //       borderRadius: BorderRadius.circular(16),
  //       child: Container(
  //         width: double.infinity,
  //         padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             colors: [Colors.white, Colors.grey.shade50],
  //           ),
  //           borderRadius: BorderRadius.circular(16),
  //           border: Border.all(color: _isGoogleLoading ? Colors.grey.shade200 : Colors.grey.shade300, width: 2),
  //         ),
  //         child: _isGoogleLoading
  //             ? Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   SizedBox(
  //                     width: 24,
  //                     height: 24,
  //                     child: CircularProgressIndicator(
  //                       strokeWidth: 2.5,
  //                       valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade600),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 12),
  //                   Text(
  //                     'Signing in...',
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.grey.shade600,
  //                     ),
  //                   ),
  //                 ],
  //               )
  //             : Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Container(
  //                     padding: const EdgeInsets.all(8),
  //                     decoration: BoxDecoration(
  //                       color: Colors.red.shade50,
  //                       borderRadius: BorderRadius.circular(8),
  //                     ),
  //                     child: Icon(Icons.mail_outline, color: Colors.red.shade600),
  //                   ),
  //                   const SizedBox(width: 12),
  //                   const Text(
  //                     'Login with Google',
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.black87,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
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

        return MultiBlocListener(
          listeners: [
            BlocListener<LoginBloc, LoginState>(
              listener: (context, state) {
                if (state is TokenLoginSuccess) {
                  global.deviceConfig.usercode = state.userLogin.userName;
                  global.deviceConfig.token = state.userLogin.token;

                  setState(() {
                    _isGoogleLoading = false;
                  });
                  //load shop
                  context.read<ListShopBloc>().add(const ListShopLoad());
                } else if (state is TokenLoginFailed) {
                  setState(() {
                    _isGoogleLoading = false;
                  });
                  _showErrorDialog(
                    global.language("login_failed"),
                    '${global.language("error occurred please try again")}\n\nDetails: ${state.message}',
                  );
                  global.sendErrorToDevTeam("Token login failed: ${state.message}");
                }
              },
            ),
            BlocListener<ListShopBloc, ListShopState>(
              listener: (context, state) {
                if (state is ListShopLoadSuccess) {
                  if (state.shop.isNotEmpty) {
                    if (state.shop.length == 1) {
                      context.read<ShopSelectBloc>().add(ShopSelect(shop: state.shop[0]));
                    } else {
                      shopList = state.shop;
                      showSelectShop = true;
                    }
                    setState(() {});
                  }
                }
              },
            ),
            BlocListener<ShopSelectBloc, ShopSelectState>(
              listener: (context, state) {
                if (state is ShopSelectLoadSuccess) {
                  global.deviceConfig.shopId = state.shop.shopid;

                  context.read<ListKioskBloc>().add(const ListKioskLoad());
                  setState(() {});
                }
              },
            ),
            BlocListener<ListKioskBloc, ListKioskState>(
              listener: (context, state) {
                if (state is ListKioskLoadSuccess) {
                  if (state.kiosk.isNotEmpty) {
                    kioskList = state.kiosk.where((kiosk) {
                      return kiosk.emails.isEmpty || kiosk.emails.contains(global.deviceConfig.usercode);
                    }).toList();

                    if (kioskList.isNotEmpty) {
                      if (kioskList.length == 1) {
                        registerDevice(kioskList[0]);
                      } else {
                        showKioskList = true;
                      }
                    }
                    setState(() {});
                  } else {
                    //show no pos available dialog
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("No POS Available"),
                            content: Text("There are no POS devices available for registration. Please contact the administrator."),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("OK"),
                              ),
                            ],
                          );
                        });
                  }
                }
              },
            ),
          ],
          child: Scaffold(
            backgroundColor: Colors.white,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: primaryThemeColor,
              foregroundColor: global.primaryTextColor,
              title: Text(
                global.language("register_order_station_machine"),
                style: TextStyle(
                  color: global.primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: IconThemeData(color: global.primaryTextColor),
            ),
            body: (isloading)
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFFE8D5C4), const Color(0xFFF5EBE0)], // สีอิฐบ้านเชียง
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFB85C38)),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Registering device...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : (showKioskList)
                    ? showKioskListForm()
                    : (showSelectShop)
                        ? shopListForm()
                        : logInForm(),
            floatingActionButton: (!isloading && !showKioskList && !showSelectShop)
                ? Container(
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
                            ShowCaseWidget.of(_showcaseContext!).startShowCase([
                              _pinCodeKey,
                              _googleLoginKey,
                            ]);
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
                  )
                : null,
          ),
        );
      },
    );
  }
}
