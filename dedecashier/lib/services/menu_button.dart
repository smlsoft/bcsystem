import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onTap;
  final double size;
  final Color backgroundColor;
  final Color labelColor;

  const MenuButton({super.key, required this.label, required this.onTap, required this.size, this.backgroundColor = Colors.white, this.labelColor = Colors.black});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(6),
        child: Ink(
          padding: const EdgeInsets.all(4),
          width: size,
          height: 40,
          decoration: BoxDecoration(boxShadow: const [
            BoxShadow(color: Colors.grey, offset: Offset(1, 1), blurRadius: 2),
          ], borderRadius: BorderRadius.all(Radius.circular(size / 8)), color: backgroundColor),
          child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(size / 2)),
              ),
              onTap: onTap,
              child: Column(
                children: [
                  const Spacer(),
                  Center(
                      child: Text(
                    label!,
                    style: TextStyle(fontSize: 12, color: labelColor),
                  )),
                ],
              )),
        ));
  }
}
