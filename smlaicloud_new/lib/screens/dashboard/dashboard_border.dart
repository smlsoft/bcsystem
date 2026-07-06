import 'package:flutter/material.dart';

class DashBoardBorder extends StatelessWidget {
  const DashBoardBorder({super.key, required this.childWidget});
  final Widget childWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(5),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 2,
          ),
        ],
      ),
      child: childWidget,
    );
  }
}
