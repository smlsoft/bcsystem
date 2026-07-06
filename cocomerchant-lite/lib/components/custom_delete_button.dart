import 'package:cocomerchant_lite/constants.dart';
import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/global.dart' as global;

class CustomDeleteButton extends StatelessWidget {
  final VoidCallback onDelete;

  const CustomDeleteButton({
    Key? key,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showDeleteConfirmationDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryLightColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Text(
          global.language('delete'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(global.language('delete_data')),
        content: Text(global.language('are_you_sure_you_want_to_delete')),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryLightColor,
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(global.language('no'), style: const TextStyle(color: kTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
            ),
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: Text(global.language('confirm'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
