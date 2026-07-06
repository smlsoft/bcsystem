import 'dart:async';
import 'package:dedecashier/api/sync/master/sync_master.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/util/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  Timer? timerSwitchToMenu;
  int syncTimeoutCounter = 0;
  int networkCheckCounter = 0;
  final int maxSyncTimeoutSeconds = 90; // 90 วินาที timeout

  void init() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var last_doc_no = sharedPreferences.getString('last_doc_no');
    if (last_doc_no != null) {
      global.last_doc_no = last_doc_no;
    } else {
      global.last_doc_no = "";
    }

    if (global.appMode == global.AppModeEnum.posRemote) {
      Timer(const Duration(seconds: 1), () {
        Navigator.of(context).pushReplacementNamed('client');
      });
    } else {
      // ⭐ OPTIMIZATION: Merge 2 Timers (2s + 5s) → Single Timer 2s
      // เดิม: Timer 2s สำหรับ menu switch + Timer 5s สำหรับ network check
      // ใหม่: Timer 2s เดียว ทำทั้งสองอย่าง (network check ทุก 3 รอบ = 6วิ)
      timerSwitchToMenu = Timer.periodic(const Duration(seconds: 2), (timer) async {
        syncTimeoutCounter += 2;
        networkCheckCounter += 2;

        // ตรวจสอบ timeout
        if (syncTimeoutCounter >= maxSyncTimeoutSeconds) {
          if (mounted) {
            timerSwitchToMenu?.cancel();
            _handleSyncTimeout();
          }
          return;
        }

        // ⭐ Network check ทุก 6 วิ (3 รอบ)
        if (networkCheckCounter >= 6) {
          networkCheckCounter = 0;
          bool isConnected = await global.hasNetwork();
          if (!isConnected && global.syncDataProcess) {
            // อินเทอร์เน็ตหลุดระหว่าง sync
            global.syncDataProcess = false;
            global.syncDataSuccess = false;
            if (mounted) {
              timerSwitchToMenu?.cancel();
              _handleNetworkLoss();
            }
            return;
          }
        }

        if (global.loginSuccess && global.syncDataSuccess) {
          if (mounted) {
            timerSwitchToMenu?.cancel();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => const MenuScreen()), (route) => false);
          }
        }
        setState(() {});
      });

      syncMasterProcess();
    }
  }

  void _handleSyncTimeout() {
    global.syncDataProcess = false;
    global.syncDataSuccess = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(global.language("sync_timeout")),
          content: Text("การซิงค์ข้อมูลใช้เวลานานเกินไป กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retrySyncProcess();
              },
              child: Text(global.language("retry")),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => const MenuScreen()), (route) => false);
              },
              child: Text(global.language("continue_offline")),
            ),
          ],
        );
      },
    );
  }

  void _handleNetworkLoss() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(global.language("network_lost")),
          content: Text("การเชื่อมต่ออินเทอร์เน็ตหลุดระหว่างการซิงค์ข้อมูล"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retrySyncProcess();
              },
              child: Text(global.language("retry")),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => const MenuScreen()), (route) => false);
              },
              child: Text(global.language("continue_offline")),
            ),
          ],
        );
      },
    );
  }

  void _retrySyncProcess() {
    syncTimeoutCounter = 0;
    global.syncDataProcess = false;
    global.syncDataSuccess = false;

    // เริ่มใหม่
    init();
  }

  @override
  void dispose() {
    timerSwitchToMenu?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    global.getDeviceModel(context);
    // MARINEPOS = น้ำเงินเข้ม, อื่นๆ = สีอิฐบ้านเชียง (Terracotta)
    final primaryColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05), Colors.white]),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Logo/Icon Section
                _buildLogoSection(),

                const SizedBox(height: 40),

                // Loading Animation
                _buildLoadingAnimation(),

                const SizedBox(height: 30),

                // Status Text
                _buildStatusText(),

                const SizedBox(height: 20),

                // Progress Indicator
                _buildProgressIndicator(),

                const SizedBox(height: 40),

                // App Info
                _buildAppInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    final primaryColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Icon(Icons.sync, size: 64, color: primaryColor),
    );
  }

  Widget _buildLoadingAnimation() {
    final primaryColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

    return Container(
      padding: const EdgeInsets.all(20),
      child: LoadingAnimationWidget.staggeredDotsWave(color: primaryColor, size: 80),
    );
  }

  Widget _buildStatusText() {
    String statusMessage = "กรุณารอสักครู่...";

    if (global.syncDataProcess) {
      statusMessage = "กำลังซิงค์ข้อมูล... (${syncTimeoutCounter}s)";
    } else if (!global.isOnline) {
      statusMessage = "ไม่มีการเชื่อมต่ออินเทอร์เน็ต";
    } else if (!global.loginSuccess) {
      statusMessage = "กำลังเข้าสู่ระบบ...";
    } else if (global.syncDataSuccess) {
      statusMessage = "ซิงค์ข้อมูลสำเร็จ";
    }

    return Column(
      children: [
        Text(
          global.language("Data Synchronization"),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          statusMessage,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        if (syncTimeoutCounter > 30) // แสดงคำเตือนหลัง 30 วินาที
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "หากใช้เวลานาน กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต",
              style: TextStyle(fontSize: 14, color: Colors.orange[600], fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final primaryColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

    double progress = 0.0;
    Color progressColor = primaryColor;

    if (global.syncDataProcess) {
      // คำนวณ progress จาก timeout counter
      progress = (syncTimeoutCounter / maxSyncTimeoutSeconds).clamp(0.0, 1.0);
      if (syncTimeoutCounter > 60) {
        progressColor = Colors.orange; // เปลี่ยนเป็นสีส้มเมื่อใช้เวลานาน
      }
    } else if (global.syncDataSuccess) {
      progress = 1.0;
      progressColor = Colors.green;
    }

    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          value: global.syncDataProcess || global.syncDataSuccess ? progress : null,
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                global.userLogin?.name ?? 'User',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.business, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(global.applicationName, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}
