import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/screens/menu/components/body.dart';
import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/components/custom_bottom_nav_bar.dart';
import 'package:cocomerchant_lite/enums.dart';
import 'package:cocomerchant_lite/global.dart' as global;

class MenuScreen extends StatelessWidget {
  static String routeName = "/menu";

  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Body(),
      bottomNavigationBar: CustomBottomNavBar(selectedMenu: MenuState.menu),
    );
  }
}
