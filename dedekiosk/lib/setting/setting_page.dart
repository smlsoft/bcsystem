import 'dart:async';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/page/privacy_policy_page.dart';
import 'package:dedekiosk/setting/esp32_device_page.dart';
import 'package:dedekiosk/setting/setting_main_device_page.dart';
import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/api.dart' as api;

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  TextEditingController pinCodeController = TextEditingController();
  late Timer getDeviceTime;
  List<Widget> deviceList = [];
  static const mcdonaldsRed = Color(0xFFDA291C);
  static const mcdonaldsYellow = Color(0xFFFFBC0D);
  Color get primaryThemeColor {
    return _hexToColor(global.deviceConfig.primaryThemeColor);
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  final FocusNode _pinFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Load immediately on first time
    _loadDeviceList();
    _pinFocusNode.addListener(() {
      setState(() {}); // ให้ build ใหม่เวลาโฟกัสเข้า/ออก
    });
    // Then refresh every 15 seconds
    getDeviceTime = Timer.periodic(const Duration(seconds: 15), (timer) async {
      _loadDeviceList();
    });
  }

  Future<void> _loadDeviceList() async {
    if (!mounted) return;

    try {
      var value = await api.clickHouseSelect("select * from ${global.clickHouseDatabaseName}.orderdevice where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' order by devicename");

      if (value == null || value.isEmpty) {
        return;
      }

      ResponseDataModel result = ResponseDataModel.fromJson(value);

      if (!mounted) return;

      List<Widget> newDeviceList = [];
      if (result.data.isNotEmpty) {
        for (int i = 0; i < result.data.length; i++) {
          bool isServer = (double.tryParse(result.data[i]["isserver"].toString()) == 1) ? true : false;
          newDeviceList.add(Card(
            elevation: 4,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              // Responsive width - fixed on desktop, flexible on mobile
              constraints: BoxConstraints(
                maxWidth: 320,
                minWidth: MediaQuery.of(context).size.width > 600 ? 320 : double.infinity,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isServer
                    ? LinearGradient(
                        colors: [Colors.green.shade50, Colors.green.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isServer ? Colors.green : Colors.red.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            isServer ? Icons.dns : Icons.devices,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.data[i]["devicename"].toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isServer ? Colors.green : Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isServer ? "SERVER" : "CLIENT",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),
                    _buildInfoRow(Icons.router, "IP Address", result.data[i]["ipaddress"].toString()),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.access_time, "Last Seen", result.data[i]["lasttime"].toString()),
                  ],
                ),
              ),
            ),
          ));
        }
      }

      if (mounted) {
        setState(() {
          deviceList = newDeviceList;
        });
      }
    } catch (e) {
      // Silently ignore errors during device list refresh
      if (mounted) {
        setState(() {
          deviceList = [];
        });
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pinFocusNode.dispose();
    getDeviceTime.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = _pinFocusNode.hasFocus;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryThemeColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            getDeviceTime.cancel();
            Future.delayed(const Duration(milliseconds: 500), () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
            });
          },
          icon: Icon(Icons.arrow_back_ios, color: global.primaryTextColor),
        ),
        title: Text(
          global.language("configure_the_device"),
          style: TextStyle(
            color: global.primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width > 600 ? 20 : 16,
          ),
        ),
        actions: [
          // Privacy Policy Button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
              );
            },
            icon: Icon(Icons.privacy_tip_outlined, color: global.primaryTextColor),
            tooltip: global.language("privacy_policy"),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'v${global.appVersion}',
                style: TextStyle(
                  color: global.primaryTextColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 20 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PIN Code Card
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryThemeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.security, color: primaryThemeColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              global.language("pin_code_machine_settings"),
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Responsive layout - Row on desktop, Column on mobile
                      MediaQuery.of(context).size.width > 600
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 240,
                                  child: TextField(
                                    controller: pinCodeController,
                                    focusNode: _pinFocusNode,
                                    autofocus: true,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.red.shade400,
                                        ),
                                      ),
                                      labelStyle: TextStyle(
                                        color: isFocused ? primaryThemeColor : Colors.grey,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: primaryThemeColor,
                                          width: 2,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: primaryThemeColor,
                                        ),
                                      ),
                                      hoverColor: primaryThemeColor.withOpacity(0.1),
                                      iconColor: primaryThemeColor,
                                      focusColor: primaryThemeColor.withOpacity(0.1),
                                      labelText: 'Pin Code',
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: isFocused ? primaryThemeColor : Colors.grey,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (pinCodeController.text == global.adminPinCode) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const SettingMainDevicePage()),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(global.language("pin_code_incorrect")),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: Icon(Icons.login, color: global.primaryTextColor),
                                  label: Text(
                                    global.language("login"),
                                    style: TextStyle(color: global.primaryTextColor),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryThemeColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                TextField(
                                  controller: pinCodeController,
                                  focusNode: _pinFocusNode,
                                  autofocus: true,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                    labelStyle: TextStyle(
                                      color: isFocused ? primaryThemeColor : Colors.grey,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: primaryThemeColor,
                                        width: 2,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: primaryThemeColor,
                                      ),
                                    ),
                                    hoverColor: primaryThemeColor.withOpacity(0.1),
                                    iconColor: primaryThemeColor,
                                    focusColor: primaryThemeColor.withOpacity(0.1),
                                    labelText: 'Pin Code',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: isFocused ? primaryThemeColor : Colors.grey,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (pinCodeController.text == global.adminPinCode) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const SettingMainDevicePage()),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(global.language("pin_code_incorrect")),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: Icon(Icons.login, color: global.primaryTextColor),
                                    label: Text(
                                      global.language("login"),
                                      style: TextStyle(color: global.primaryTextColor),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryThemeColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 12),
                      // Network Test Button - Full width on mobile
                      SizedBox(
                        width: MediaQuery.of(context).size.width > 600 ? null : double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/network_test');
                          },
                          icon: const Icon(Icons.science, color: Colors.white),
                          label: const Text(
                            'Network Test (Dev)',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ESP32 Devices Button
                      SizedBox(
                        width: MediaQuery.of(context).size.width > 600 ? null : double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const Esp32DevicePage()));
                          },
                          icon: const Icon(Icons.developer_board, color: Colors.white),
                          label: const Text(
                            'ESP32 Devices (ผูกโต๊ะ)',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Devices Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.devices_other, color: Colors.grey.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Connected Devices',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${deviceList.length} devices',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Devices Grid - Wrap on desktop, ListView on mobile
              deviceList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.devices_other_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No devices found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : MediaQuery.of(context).size.width > 600
                      ? Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: deviceList,
                        )
                      : Column(
                          children: deviceList.map((device) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: device,
                            );
                          }).toList(),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
