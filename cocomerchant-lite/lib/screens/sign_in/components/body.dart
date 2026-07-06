import 'package:flutter/material.dart';
import '../../../size_config.dart';
import 'sign_form.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: SizeConfig.screenHeight * 0.04),
                Semantics(
                  label: 'Welcome Back',
                  child: Text(
                    "Welcome Back",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: getProportionateScreenWidth(28),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Semantics(
                  label: 'Sign in with your google account',
                  child: const Text(
                    "Sign in with your google account",
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: SizeConfig.screenHeight * 0.08),
                const SignForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
