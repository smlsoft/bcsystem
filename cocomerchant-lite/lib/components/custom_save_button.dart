import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/global.dart' as global;

Widget buildSaveButton({
  required GlobalKey<FormState> formKey,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () {
        if (formKey.currentState!.validate()) {
          onPressed();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
      ),
      child: Text(
        global.language('save'),
        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
