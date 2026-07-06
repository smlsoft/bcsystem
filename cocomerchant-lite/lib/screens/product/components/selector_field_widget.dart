import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/model/global_model.dart';

class SelectorFieldWidget extends StatelessWidget {
  final String selectedCode;
  final List<LanguageDataModel> selectedNames;
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const SelectorFieldWidget({
    Key? key,
    required this.selectedCode,
    required this.selectedNames,
    required this.onTap,
    required this.icon,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: kSecondaryColor),
          suffixIcon: const Icon(Icons.search, color: kPrimaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kPrimaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        child: selectedCode.isEmpty
            ? Text(
                '${global.language('please_select')} $label',
                style: const TextStyle(color: kTextColor, fontSize: 16),
              )
            : Text(
                global.activeLangName(selectedNames),
                style: const TextStyle(color: kTextColor, fontSize: 16),
              ),
      ),
    );
  }
}
