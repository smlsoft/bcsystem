import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/screens/menu/components/section_title.dart';
import 'package:cocomerchant_lite/screens/order_setting/order_setting_screen.dart';
import 'package:cocomerchant_lite/screens/product/product_barcode_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_product_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_screen.dart';
import 'package:cocomerchant_lite/screens/unit/unit_screen.dart';
import 'package:cocomerchant_lite/size_config.dart';
import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/screens/menu/components/menu_button.dart';

class Fullmenubody extends StatefulWidget {
  const Fullmenubody({super.key});

  @override
  FullmenubodyState createState() => FullmenubodyState();
}

class FullmenubodyState extends State<Fullmenubody> {
  List<Widget> masterMenuList = [];
  List<Widget> configMenuList = [];
  List<Widget> configCompanyMenuList = [];

  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);
  }

  @override
  void initState() {
    super.initState();
    buildMenuLite();
    setSystemLanguageList();
  }

  void buildMenuLite() {
    masterMenuList = [];
    configMenuList = [];
    configCompanyMenuList = [];

    masterMenuList.add(
      MenuButton(
          label: global.language("product"),
          icon: Icons.barcode_reader,
          callback: () {
            Navigator.pushNamed(context, ProductBarcodeScreen.routeName);
          }),
    );
    masterMenuList.add(
      MenuButton(
          label: global.language("product_unit"),
          icon: Icons.format_list_numbered,
          callback: () {
            Navigator.pushNamed(context, UnitScreen.routeName);
          }),
    );
    masterMenuList.add(
      MenuButton(
          label: global.language("product_category"),
          icon: Icons.category,
          callback: () {
            Navigator.pushNamed(context, '/product_category_group_select_screen');
          }),
    );

    masterMenuList.add(
      MenuButton(
          label: global.language("product_category_list"),
          icon: Icons.category_sharp,
          callback: () {
            Navigator.pushNamed(context, '/productcategorylist');
          }),
    );

    configMenuList.add(
      MenuButton(
          label: global.language("table"),
          color: Colors.cyan.shade100,
          icon: Icons.table_bar,
          callback: () {
            Navigator.pushNamed(context, '/table_group_select_screen');
          }),
    );
    configMenuList.add(
      MenuButton(
          label: global.language("sale_channel"),
          color: Colors.cyan.shade100,
          icon: Icons.send,
          callback: () {
            Navigator.pushNamed(context, '/salechannel');
          }),
    );

    configMenuList.add(
      MenuButton(
          label: global.language("pos_media"),
          color: Colors.cyan.shade100,
          icon: Icons.display_settings,
          callback: () {
            Navigator.pushNamed(context, '/posmedia');
          }),
    );

    configMenuList.add(
      MenuButton(
        label: global.language("qr_provider"),
        color: Colors.cyan.shade100,
        icon: Icons.qr_code,
        callback: () {
          Navigator.pushNamed(context, '/qrprovider');
        },
      ),
    );
    configMenuList.add(
      MenuButton(
          label: global.language("order_template_setting"),
          color: Colors.cyan.shade100,
          icon: Icons.monitor_weight_outlined,
          callback: () {
            Navigator.pushNamed(context, '/ordertemplatsetting');
          }),
    );

    configMenuList.add(
      MenuButton(
        label: global.language("order_setting"),
        color: Colors.cyan.shade100,
        icon: Icons.monitor_weight_outlined,
        callback: () {
          Navigator.pushNamed(context, OrderSettingScreen.routeName);
        },
      ),
    );

    configMenuList.add(
      MenuButton(
          label: global.language("qr_code_order"),
          color: Colors.cyan.shade100,
          icon: Icons.add,
          callback: () {
            Navigator.pushNamed(context, '/qrcodeorder_group_select_screen');
          }),
    );

    configMenuList.add(
      MenuButton(
          label: global.language("kitchen"),
          color: Colors.cyan.shade100,
          icon: Icons.kitchen,
          callback: () {
            Navigator.pushNamed(context, '/kitchen_group_select_screen');
          }),
    );

    configMenuList.add(
      MenuButton(
          label: global.language("add_product_to_kitchen"),
          color: Colors.cyan.shade100,
          icon: Icons.add,
          callback: () {
            Navigator.pushNamed(context, '/addproducttokitchen');
          }),
    );

    configCompanyMenuList.add(
      MenuButton(
        label: global.language("system_config"),
        color: Colors.orange.shade100,
        icon: Icons.business,
        callback: () {
          Navigator.pushNamed(context, '/config_system');
        },
      ),
    );
    configCompanyMenuList.add(MenuButton(
        label: global.language("company"),
        color: Colors.orange.shade100,
        icon: Icons.business,
        callback: () {
          Navigator.pushNamed(context, '/company');
        }));
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
              color: kPrimaryColor,
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
      onTapHint: global.language("แตะเพื่อไปยัง") + label,
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
      {'icon': Icons.inventory, 'label': global.language("product"), 'route': ProductBarcodeScreen.routeName, 'color': Colors.blueAccent},
      {'icon': Icons.format_list_numbered, 'label': global.language("product_unit"), 'route': UnitScreen.routeName, 'color': Colors.blueAccent},
      {'icon': Icons.category, 'label': global.language("product_category"), 'route': '/product_category_group_select_screen', 'color': Colors.blueAccent},
      {'icon': Icons.category_sharp, 'label': global.language("product_category_list"), 'route': '/productcategorylist', 'color': Colors.blueAccent},
    ];

    return _buildIconList(actions);
  }

  Widget _buildFullProductMenu() {
    final actions = [
      {'icon': Icons.point_of_sale, 'label': global.language("การรับเงิน"), 'route': ReportScreen.routeName, 'color': kPrimaryColor},
      {'icon': Icons.pie_chart, 'label': global.language("ยอดขาย"), 'route': ReportScreen.routeName, 'color': kPrimaryColor},
      {'icon': Icons.list_outlined, 'label': global.language("สินค้าขายดี"), 'route': ReportProductScreen.routeName, 'color': kPrimaryColor},
      {'icon': Icons.attach_money_rounded, 'label': global.language("คำสั่งซื้อ"), 'route': '/addproducttokitchen', 'color': kPrimaryColor},
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
        return screenWidth ~/ 80;
      }
    }
  }

  Widget _buildConfigMenu() {
    final actions = [
      {'icon': Icons.table_bar, 'label': global.language("table"), 'route': '/table_group_select_screen', 'color': Colors.pinkAccent},
      {'icon': Icons.send, 'label': global.language("sale_channel"), 'route': '/salechannel', 'color': Colors.pinkAccent},
      {'icon': Icons.display_settings, 'label': global.language("pos_media"), 'route': '/posmedia', 'color': Colors.pinkAccent},
      {'icon': Icons.qr_code, 'label': global.language("qr_provider"), 'route': '/qrprovider', 'color': Colors.pinkAccent},
      {'icon': Icons.monitor_weight_outlined, 'label': global.language("order_template_setting"), 'route': '/ordertemplatsetting', 'color': Colors.pinkAccent},
      {'icon': Icons.monitor_weight_outlined, 'label': global.language("order_setting"), 'route': OrderSettingScreen.routeName, 'color': Colors.pinkAccent},
      {'icon': Icons.add, 'label': global.language("qr_code_order"), 'route': '/qrcodeorder_group_select_screen', 'color': Colors.pinkAccent},
      {'icon': Icons.kitchen, 'label': global.language("kitchen"), 'route': '/kitchen_group_select_screen', 'color': Colors.pinkAccent},
      {'icon': Icons.add, 'label': global.language("add_product_to_kitchen"), 'route': '/addproducttokitchen', 'color': Colors.pinkAccent},
    ];

    return _buildIconList(actions);
  }

  Widget _buildSettingMenu() {
    final actions = [
      {'icon': Icons.business, 'label': global.language("system_config"), 'route': '/config_system', 'color': Colors.purpleAccent},
      {'icon': Icons.business, 'label': global.language("company"), 'route': '/company', 'color': Colors.purpleAccent},
    ];

    return _buildIconList(actions);
  }

  void _handleNavigation(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(global.language("Products")),
            _buildProductMenu(),
            _buildSectionTitle(global.language("Order Station")),
            _buildConfigMenu(),
            _buildSectionTitle(global.language("Report")),
            _buildFullProductMenu(),
            _buildSectionTitle(global.language("Settings")),
            _buildSettingMenu(),
          ],
        ),
      ),
    );
  }
}
