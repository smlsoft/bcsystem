import 'package:cocomerchant_lite/components/custom_bottom_nav_bar.dart';
import 'package:cocomerchant_lite/enums.dart';
import 'package:cocomerchant_lite/screens/report/components/body_dashboard.dart';
import 'package:flutter/material.dart';

class ReportDashBoardScreen extends StatelessWidget {
  static String routeName = "/reportdashboard";

  const ReportDashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Dashboard(),
      bottomNavigationBar: CustomBottomNavBar(selectedMenu: MenuState.dashboard),
    );
  }
}
