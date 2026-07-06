import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/size_config.dart';

import 'components/body.dart';

class OtpScreen extends StatelessWidget {
  static String routeName = "/otp";
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("PIN Verification"),
      ),
      body: Body(),
    );
  }
}
