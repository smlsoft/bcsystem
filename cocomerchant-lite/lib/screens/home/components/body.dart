import 'package:cocomerchant_lite/screens/home/components/sales_card.dart';
import 'package:cocomerchant_lite/screens/home/components/sales_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../size_config.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for 7 days of sales
    final List<Map<String, dynamic>> salesData = [
      {'day': 'Mon', 'sales': 15234.56},
      {'day': 'Tue', 'sales': 18456.78},
      {'day': 'Wed', 'sales': 22345.67},
      {'day': 'Thu', 'sales': 19876.54},
      {'day': 'Fri', 'sales': 25678.90},
      {'day': 'Sat', 'sales': 30123.45},
      {'day': 'Sun', 'sales': 28765.43},
    ];

    final NumberFormat currencyFormat = NumberFormat('#,##0.00', 'en_US');

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: getProportionateScreenHeight(10)),
              Text(
                'Sales Overview',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(24),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: getProportionateScreenHeight(10)),
              SalesCard(
                cardName: 'Today\'s Sales',
                sales: salesData.last['sales'],
                icon: Icons.attach_money,
              ),
              SizedBox(height: getProportionateScreenHeight(10)),
              SalesCard(
                cardName: 'This Week\'s Sales',
                sales: salesData.fold(0.0, (sum, item) => sum + item['sales']),
                icon: Icons.trending_up,
              ),
              SizedBox(height: getProportionateScreenHeight(20)),
              Text(
                'Sales Trend (Last 7 Days)',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: getProportionateScreenHeight(20)),
              SizedBox(
                height: getProportionateScreenHeight(300),
                child: SalesChart(salesData: salesData, currencyFormat: currencyFormat),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
