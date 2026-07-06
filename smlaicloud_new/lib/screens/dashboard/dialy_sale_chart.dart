import 'dart:math';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dashboard_border.dart';

class _ChartData {
  _ChartData(this.x, this.y);

  final String x;
  final double y;
}

class DashBoardDailySaleChart extends StatefulWidget {
  const DashBoardDailySaleChart({super.key});

  @override
  _DashBoardDailySaleChartState createState() =>
      _DashBoardDailySaleChartState();
}

class _DashBoardDailySaleChartState extends State<DashBoardDailySaleChart> {
  late List<_ChartData> summeryDay;
  late List<_ChartData> summeryMonth;
  late List<_ChartData> summeryYear;

  @override
  void initState() {
    loadData();
    super.initState();
  }

  void loadData() {
    double min = 110.0;
    double max = 111210.0;
    {
      // ตามวันที่
      DateTime dateTimeNow = DateTime.now().subtract(const Duration(days: 7));
      var thaiBuddhist = new DateFormat('dd/mm/yy', 'th_TH');
      summeryDay = [];
      for (int i = 0; i < 7; i++) {
        double randomDouble = min + Random().nextDouble() * (max - min);
        String fullDate = thaiBuddhist.format(dateTimeNow);
        summeryDay.add(_ChartData(fullDate, randomDouble));
        dateTimeNow = dateTimeNow.add(const Duration(days: 1));
      }
    }
    {
      // ตามเดือน
      summeryMonth = [];
      DateTime dateTime = DateTime.now();
      int year = dateTime.year;
      int month = dateTime.month;
      var thaiBuddhist = new DateFormat('MMMM yy', 'th_TH');
      for (int i = 0; i < 12; i++) {
        double randomDouble = min + Random().nextDouble() * (max - min);
        String name = thaiBuddhist.format(dateTime);
        summeryMonth.add(_ChartData(name, randomDouble));
        month--;
        if (month == 0) {
          month = 12;
          year--;
        }
        dateTime = DateTime(year, month);
      }
    }
    {
      // ตามปี
      DateTime dateTime = DateTime.now();
      int year = dateTime.year;
      summeryYear = [];
      for (int i = 0; i < 7; i++) {
        double randomDouble = min + Random().nextDouble() * (max - min);
        String fullDate = year.toString();
        for (int i = 0; i < 5; i++) {
          double randomDouble = min + Random().nextDouble() * (max - min);
          summeryYear.add(_ChartData(fullDate, randomDouble));
          year--;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
    /* XXXX
    Column(children: [
      DashBoardBorder(
          childWidget: SfCartesianChart(
              title: ChartTitle(text: 'ยอดขายสินค้า 7 วันล่าสุด'),
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.simpleCurrency(
                      locale: 'th_TH', decimalDigits: 0)),
              series: <ChartSeries<_ChartData, String>>[
            ColumnSeries<_ChartData, String>(
                dataSource: summeryDay,
                xValueMapper: (_ChartData data, _) => data.x,
                yValueMapper: (_ChartData data, _) => data.y,
                name: 'Day',
                color: const Color.fromRGBO(8, 142, 255, 1))
          ])),
      DashBoardBorder(
          childWidget: SfCartesianChart(
              title: ChartTitle(text: 'ยอดขายสินค้า 12 เดือนล่าสุด'),
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.simpleCurrency(
                      locale: 'th_TH', decimalDigits: 0)),
              series: <ChartSeries<_ChartData, String>>[
            ColumnSeries<_ChartData, String>(
                dataSource: summeryMonth,
                xValueMapper: (_ChartData data, _) => data.x,
                yValueMapper: (_ChartData data, _) => data.y,
                name: 'Month',
                color: const Color.fromRGBO(8, 142, 255, 1)),
          ])),
      DashBoardBorder(
          childWidget: SfCartesianChart(
              title: ChartTitle(text: 'ยอดขายสินค้า 5 ปีล่าสุด'),
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.simpleCurrency(
                      locale: 'th_TH', decimalDigits: 0)),
              series: <ChartSeries<_ChartData, String>>[
            ColumnSeries<_ChartData, String>(
                dataSource: summeryYear,
                xValueMapper: (_ChartData data, _) => data.x,
                yValueMapper: (_ChartData data, _) => data.y,
                name: 'Month',
                color: const Color.fromRGBO(8, 142, 255, 1)),
          ])),
    ]);*/
  }
}
