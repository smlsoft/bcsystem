import 'package:flutter/material.dart';

class TextFieldInput extends StatelessWidget {
  final String labelText;
  final TextInputType keyboardType;
  final TextEditingController controller;
  const TextFieldInput({
    Key? key,
    required this.labelText,
    required this.keyboardType,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: keyboardType,
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        labelText: labelText,
        isDense: true,
        contentPadding: const EdgeInsets.all(10),
      ),
    );
  }
}
