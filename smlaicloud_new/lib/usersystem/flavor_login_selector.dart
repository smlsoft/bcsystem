import 'package:flutter/material.dart';
import 'package:smlaicloud/flavors.dart';
import 'package:smlaicloud/usersystem/login_google_screen.dart';
import 'package:smlaicloud/usersystem/login_password_screen.dart';

/// Widget สำหรับเลือกแสดง Login screen ตาม flavor
class FlavorLoginSelector extends StatelessWidget {
  const FlavorLoginSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // เลือก screen ตาม flavor
    switch (F.appFlavor) {
      case Flavor.dohomedev:
      case Flavor.dohomeuat:
      case Flavor.dohomeprod:
        return const LoginPasswordScreen(); // DoHome flavors ใช้ username/password

      case Flavor.smlaidev:
      case Flavor.smlaiprod:
      default:
        return const LoginGoogleScreen(); // SMLAI flavors ใช้ Google Sign-In
    }
  }
}
