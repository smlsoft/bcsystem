// ignore_for_file: deprecated_member_use
import 'package:cocomerchant_lite/screens/menu/full_menu_screen.dart';
import 'package:cocomerchant_lite/screens/menu/menu_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_dashboard_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cocomerchant_lite/screens/home/home_screen.dart';
import 'package:cocomerchant_lite/screens/profile/profile_screen.dart';

import 'package:cocomerchant_lite/global.dart' as global;

import '../constants.dart';
import '../enums.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    Key? key,
    required this.selectedMenu,
  }) : super(key: key);

  final MenuState selectedMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 3,
            color: Colors.orange.shade200,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home,
              label: global.language("home"),
              isSelected: selectedMenu == MenuState.menu,
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, MenuScreen.routeName, (route) => false),
            ),
            _buildNavItem(
              icon: Icons.pie_chart,
              label: global.language("dashboard"),
              isSelected: selectedMenu == MenuState.dashboard,
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, ReportDashBoardScreen.routeName, (route) => false),
            ),
            _buildNavItem(
              icon: Icons.dashboard,
              label: global.language("menu"),
              isSelected: selectedMenu == MenuState.fullmenu,
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, FullMenuScreen.routeName, (route) => false),
            ),
            _buildNavItem(
              icon: Icons.store_outlined,
              label: global.language("shop"),
              isSelected: selectedMenu == MenuState.profile,
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, ProfileScreen.routeName, (route) => false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
    String? badge,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.orange : Colors.grey,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.orange : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
