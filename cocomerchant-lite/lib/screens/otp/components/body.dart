import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/size_config.dart';

import 'otp_form.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: SizeConfig.screenHeight * 0.05),
              Text(
                "PIN Verification",
                style: headingStyle,
              ),
              const Text("หมายเลข PIN 8 หลัก จากเครื่อง Order Station"),
              const OtpForm(),
            ],
          ),
        ),
      ),
    );
  }
}
