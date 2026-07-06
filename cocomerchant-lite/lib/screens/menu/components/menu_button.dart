import 'package:cocomerchant_lite/constants.dart';
import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback callback;

  const MenuButton({
    required this.label,
    this.color = kPrimaryLightColor,
    this.icon,
    required this.callback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget textWidget = Center(
      child: Text(
        label,
        maxLines: 3,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(4),
        foregroundColor: Colors.black,
        backgroundColor: color,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      onPressed: callback,
      child: (icon == null)
          ? textWidget
          : Stack(
              children: [
                textWidget,
              ],
            ),
    );
  }
}
