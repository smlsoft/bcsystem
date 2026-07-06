import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/size_config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesCard extends StatelessWidget {
  final String cardName;
  final double sales;
  final IconData icon;

  const SalesCard({
    Key? key,
    required this.cardName,
    required this.sales,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat('#,##0.00', 'en_US');
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(getProportionateScreenWidth(15)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cardName,
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(14),
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(5)),
                Text(
                  '\$${currencyFormat.format(sales)}',
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(
              icon,
              size: getProportionateScreenWidth(30),
              color: kPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
