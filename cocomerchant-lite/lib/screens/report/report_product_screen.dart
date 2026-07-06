import 'package:cocomerchant_lite/screens/report/components/body_product.dart';
import 'package:flutter/material.dart';

class ReportProductScreen extends StatelessWidget {
  static String routeName = "/reportproduct";

  const ReportProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BodyProduct(),
    );
  }
}
