import 'package:cocomerchant_lite/screens/report/components/body_receivemoney.dart';
import 'package:flutter/material.dart';

class ReportReceivemoneyScreen extends StatelessWidget {
  static String routeName = "/reportreceivemoney";

  const ReportReceivemoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BodyReceiveMoney(),
    );
  }
}
