import 'package:flutter/material.dart';

import 'colors.dart';

class Styles {
  static ButtonStyle successButtonStyle({
    Color color = AppColors.primaryColor,
    double radius = 6,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius))),
    );
    //   shape:
    //   backgroundColor: Colors.green,
    //   textColor: Colors.white,
    //   borderColor: Colors.green,
    // );
  }
}
