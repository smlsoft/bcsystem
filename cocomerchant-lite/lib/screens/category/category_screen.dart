import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/components/custom_bottom_nav_bar.dart';
import 'package:cocomerchant_lite/enums.dart';

class CategoryScreen extends StatelessWidget {
  static String routeName = "/category";

  const CategoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("หมวดหมู่สินค้า"),
      ),
      body: Container(
        child: const Text("หมวดหมู่สินค้า"),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedMenu: MenuState.profile),
    );
  }
}
