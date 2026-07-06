import 'package:cocomerchant_lite/constants.dart';
import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/global.dart' as global;

class SwitchFormField extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  const SwitchFormField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(label),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kPrimaryColor,
          ),
        ],
      ),
    );
  }
}

// สำหรับ Switch ที่มี TextField
class SwitchWithTextField extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final TextEditingController textController;

  const SwitchWithTextField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.textController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
          if (value)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: const OutlineInputBorder(),
                  labelText: global.language('description'),
                ),
                controller: textController,
              ),
            ),
        ],
      ),
    );
  }
}
