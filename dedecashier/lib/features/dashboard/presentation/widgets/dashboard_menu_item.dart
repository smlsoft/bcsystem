import 'package:dedecashier/app/app.dart';
import 'package:flutter/material.dart';

class ItemMenuDashboard extends StatelessWidget {
  final VoidCallback callBack;
  final IconData icon;
  final String title;
  final Color color;
  final Color iconColor;

  const ItemMenuDashboard({super.key, required this.icon, required this.title, this.color = Colors.white, this.iconColor = AppColors.primaryColor, required this.callBack});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () {
        callBack();
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 130,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 48,
                color: iconColor, // const Color(0xFFF56045),
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                // overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
