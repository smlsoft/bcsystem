import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/screens/menu/components/fullmenubody.dart';
import 'package:cocomerchant_lite/screens/menu/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/components/custom_bottom_nav_bar.dart';
import 'package:cocomerchant_lite/enums.dart';
import 'package:cocomerchant_lite/global.dart' as global;

class FullMenuScreen extends StatelessWidget {
  static String routeName = "/fullmenu";

  const FullMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text("เมนูทั้งหมด", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.white,
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, MenuScreen.routeName, (route) => false);
          },
        ),
      ),
      body: const Fullmenubody(),
      bottomNavigationBar: const CustomBottomNavBar(selectedMenu: MenuState.fullmenu),
    );
  }
}
