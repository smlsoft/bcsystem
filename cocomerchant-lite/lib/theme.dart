import 'package:flutter/material.dart';

import 'constants.dart';

class AppTheme {
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      scaffoldBackgroundColor: Colors.white,
      fontFamily: "Sarabun",
      appBarTheme: const AppBarTheme(color: Colors.white, elevation: 0, iconTheme: IconThemeData(color: Colors.black), titleTextStyle: TextStyle(color: Colors.black)),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: kTextColor),
        bodyMedium: TextStyle(color: kTextColor),
        bodySmall: TextStyle(color: kTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(kPrimaryColor),
          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          iconColor: WidgetStateProperty.all<Color>(Colors.white),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
          // floatingLabelBehavior: FloatingLabelBehavior.always,
          // contentPadding: EdgeInsets.symmetric(horizontal: 42, vertical: 20),
          // enabledBorder: outlineInputBorder,
          // focusedBorder: outlineInputBorder,
          // border: outlineInputBorder,
          ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

const OutlineInputBorder outlineInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(28)),
  borderSide: BorderSide(color: kTextColor),
  gapPadding: 10,
);
