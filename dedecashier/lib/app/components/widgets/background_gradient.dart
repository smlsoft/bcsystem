import 'package:dedecashier/app/components/values/colors.dart';
import 'package:flutter/material.dart';

import 'clipper.dart';

class BackgroundGradientWidget extends StatelessWidget {
  const BackgroundGradientWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color.fromRGBO(0, 123, 255, 0.55),
          Color.fromRGBO(0, 123, 255, 1),
        ],
      ))),
    );
  }
}

class BackgroundClipperWidget extends StatelessWidget {
  const BackgroundClipperWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var heightOfScreen = MediaQuery.of(context).size.height;
    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      child: ClipPath(
        clipper: VFPosLoginShapeClipper(),
        child: Container(
          height: 900,
          decoration: const BoxDecoration(color: AppColors.primaryColor),
        ),
      ),
    );
  }
}
