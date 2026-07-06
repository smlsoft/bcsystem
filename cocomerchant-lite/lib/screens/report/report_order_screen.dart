import 'package:cocomerchant_lite/screens/report/components/body_order.dart';
import 'package:flutter/material.dart';

class ReportOrderScreen extends StatelessWidget {
  static String routeName = "/reportorder";

  const ReportOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BodyOrder(),
    );
  }
}
