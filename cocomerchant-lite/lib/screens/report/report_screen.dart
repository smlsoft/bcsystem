import 'package:cocomerchant_lite/screens/report/components/body_sale.dart';
import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  static String routeName = "/report";

  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Body(),
    );
  }
}
