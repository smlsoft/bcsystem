import 'package:cocomerchant_lite/size_config.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesChart extends StatelessWidget {
  final List<Map<String, dynamic>> salesData;
  final NumberFormat currencyFormat;

  const SalesChart({
    super.key,
    required this.salesData,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final maxSales = salesData.map((d) => d['sales']).reduce((a, b) => a > b ? a : b);
    final roundedMaxSales = (maxSales / 5000).ceil() * 5000.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: roundedMaxSales,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${salesData[group.x.toInt()]['day']}\n${currencyFormat.format(salesData[group.x.toInt()]['sales'])}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    salesData[value.toInt()]['day'],
                    style: TextStyle(
                      color: const Color(0xff7589a2),
                      fontWeight: FontWeight.bold,
                      fontSize: getProportionateScreenWidth(10),
                    ),
                  ),
                );
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: roundedMaxSales / 5,
              getTitlesWidget: (double value, TitleMeta meta) {
                // ใช้ค่าย่อสำหรับพัน (K) หรือล้าน (M)
                String formattedValue;
                if (value >= 1000000) {
                  formattedValue = '${(value / 1000000).toStringAsFixed(1)}M';
                } else if (value >= 1000) {
                  formattedValue = '${(value / 1000).toStringAsFixed(1)}K';
                } else {
                  formattedValue = value.toStringAsFixed(0);
                }
                return Text(
                  formattedValue,
                  style: TextStyle(
                    color: const Color(0xff7589a2),
                    fontWeight: FontWeight.bold,
                    fontSize: getProportionateScreenWidth(10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          checkToShowHorizontalLine: (value) => value % (roundedMaxSales / 5) == 0,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Color(0xffe7e8ec),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: salesData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value['sales'],
                color: Colors.blue,
                width: getProportionateScreenWidth(20),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
