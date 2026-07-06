import 'package:smlaicloud/screens/dashboard/dialy_sale.dart';
import 'package:smlaicloud/screens/dashboard/dialy_sale_chart.dart';
import 'package:flutter/material.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  _DashBoardScreenState createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  List<Widget> widgetList = [
    const DashBoardDailySale(),
    const DashBoardDailySaleChart(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: widgetList),
      ),
    );
  }
}
