import 'package:flutter/material.dart';

class ButtonBill extends StatelessWidget {
  final String label;
  final Function()? onPressed;
  final Color color;

  const ButtonBill({
    Key? key,
    required this.label,
    required this.onPressed,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(color),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
        ),
        onPressed: onPressed,
        child: Text('$label'),
      ),
    );
  }
}
