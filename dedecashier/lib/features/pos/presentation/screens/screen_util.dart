import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;

Widget screenBoxShadowLabelAndNumber({String label = "", double value = 0.0, double fontSize = 32.0}) {
  final formattedNumber = (value == global.roundDouble(value, 0)) ? global.moneyFormat.format(value) : global.moneyFormatAndDot.format(value);
  return Container(
    margin: const EdgeInsets.all(5),
    padding: const EdgeInsets.all(5),
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.5),
          spreadRadius: 5,
          blurRadius: 5,
          offset: const Offset(0, 3), // changes position of shadow
        ),
      ],
    ),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          formattedNumber,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
