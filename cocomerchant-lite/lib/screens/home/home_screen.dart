import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/components/custom_bottom_nav_bar.dart';
import 'package:cocomerchant_lite/enums.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'components/body.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = "/home";

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);
  }

  @override
  void initState() {
    setSystemLanguageList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Body(),
      bottomNavigationBar: CustomBottomNavBar(selectedMenu: MenuState.home),
    );
  }
}
