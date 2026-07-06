import 'dart:async';

import 'package:cocomerchant_lite/bloc/report/sale_daily_bloc.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/screens/menu/full_menu_screen.dart';
import 'package:cocomerchant_lite/screens/order_setting/order_setting_screen.dart';
import 'package:cocomerchant_lite/screens/product/list_product_barcode_screen.dart';
import 'package:cocomerchant_lite/screens/product/product_barcode_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_order_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_product_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_receivemoney_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_screen.dart';
import 'package:cocomerchant_lite/select_language_screen.dart';
import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  BodyState createState() => BodyState();
}

class BodyState extends State<Body> {
  Timer? _timer;

  String totalAmount = "฿0.00";
  String docCount = "0";

  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);
  }

  @override
  void initState() {
    super.initState();
    setSystemLanguageList();
    loadData();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      loadData();
    });
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void loadData() {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    context.read<SaleDailyBloc>().add(SaleDailyLoadStart(
          startDateTime: startDate,
          endDateTime: endDate,
        ));
  }

  Widget _buildHighlightCard() {
    return BlocBuilder<SaleDailyBloc, SaleDailyState>(
      builder: (context, state) {
        if (state is SaleDailyLoadSuccess && state.data.isNotEmpty) {
          totalAmount = "฿${NumberFormat('###,###,##0.00').format(state.data.first.totalamount)}";
          docCount = NumberFormat('###,###,##0').format(state.data.first.doccount);
        }
        return Semantics(
          label: global.language("Today's sales summary"),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 13),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: global.language("View payment report"),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamedAndRemoveUntil(context, ReportReceivemoneyScreen.routeName, (route) => false);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  label: global.language("Today's Sales"),
                                  child: Text(
                                    global.language("Today's Sales"),
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Semantics(
                                  label: totalAmount,
                                  child: Text(
                                    totalAmount,
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                            Semantics(
                              label: global.language("Go to more details"),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 0),
                    Divider(color: Colors.grey[300]),
                    Semantics(
                      label: global.language("Order count") + docCount,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            "$docCount ${global.language("Orders")}",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
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
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Semantics(
      label: title,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              color: Colors.deepOrange[400],
              margin: const EdgeInsets.only(right: 8),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      onTapHint: global.language("Tap to navigate to") + label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                elevation: 0,
                shape: const CircleBorder(),
                child: CircleAvatar(
                  backgroundColor: Colors.grey[100],
                  radius: 30,
                  child: Icon(
                    icon,
                    color: color,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductMenu() {
    final actions = [
      {'icon': Icons.inventory, 'label': global.language("Products"), 'route': ListProductBarcodeScreen.routeName, 'color': Colors.purple[300]},
      {'icon': Icons.category_sharp, 'label': global.language("Product Categories"), 'route': '/productcategorylist', 'color': Colors.orange[300]},
      {'icon': Icons.qr_code, 'label': global.language("QR Provider"), 'route': '/qrprovider', 'color': Colors.blue[300]},
      {'icon': Icons.send, 'label': global.language("Sales Channels"), 'route': '/salechannel', 'color': Colors.red[300]},
      {'icon': Icons.display_settings, 'label': global.language("POS Media"), 'route': '/posmedia', 'color': Colors.pink[300]},
      {'icon': Icons.monitor_weight_outlined, 'label': global.language("Order Settings"), 'route': OrderSettingScreen.routeName, 'color': Colors.blueAccent.shade200},
      {'icon': Icons.print, 'label': global.language("Add Products to Kitchen"), 'route': '/addproducttokitchen', 'color': Colors.cyan[300]},
      {'icon': Icons.more_horiz, 'label': global.language("Full Menu"), 'route': FullMenuScreen.routeName, 'color': Colors.redAccent.shade200},
    ];

    return _buildIconList(actions);
  }

  int _getCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    Orientation orientation = MediaQuery.of(context).orientation;

    bool isTablet = screenWidth > 600;

    if (isTablet) {
      if (orientation == Orientation.landscape) {
        return screenWidth ~/ 180;
      } else {
        return screenWidth ~/ 160;
      }
    } else {
      if (orientation == Orientation.landscape) {
        return screenWidth ~/ 120;
      } else {
        return screenWidth ~/ 100;
      }
    }
  }

  void _handleNavigation(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  void _handleNavigationRemoveUntil(BuildContext context, String route) {
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  Widget _buildIconList(actions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = _getCrossAxisCount(context);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _buildActionItem(
              actions[index]['icon'] as IconData,
              actions[index]['label'] as String,
              actions[index]['color'] as Color,
              () => _handleNavigation(context, actions[index]['route'] as String),
            );
          },
        );
      },
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 10),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 15, top: 5),
              child: Semantics(
                label: global.language("Change Language"),
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SelectLanguageScreen()),
                      );
                    },
                    child: ClipOval(
                      child: Image.asset(
                        'assets/flags/${global.userLanguage}.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            label: global.activeLangName((global.shopSelectData.names != null) ? global.shopSelectData.names! : []),
            child: Text(
              global.activeLangName((global.shopSelectData.names != null) ? global.shopSelectData.names! : []),
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.pie_chart, 'label': global.language("Sales"), 'route': ReportScreen.routeName},
      {'icon': Icons.list_outlined, 'label': global.language("Best Selling Products"), 'route': ReportProductScreen.routeName},
      {'icon': Icons.attach_money_rounded, 'label': global.language("Orders"), 'route': ReportOrderScreen.routeName},
    ];

    return Semantics(
      label: global.language("Quick Actions"),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: actions
              .map((action) => _buildQuickActionItem(action['icon'] as IconData, action['label'] as String, () => _handleNavigationRemoveUntil(context, action['route'] as String)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      onTapHint: global.language("Tap to navigate to") + label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.orange[200]!,
                    Colors.orange[300]!,
                    kPrimaryColor!,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kPrimaryColor!,
                  kPrimaryColor!,
                  Colors.orange[200]!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTitle(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 46),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHighlightCard(),
                        const SizedBox(height: 26),
                        _buildQuickActions(),
                        const SizedBox(height: 26),
                        _buildProductMenu(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
