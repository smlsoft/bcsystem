import 'package:cocomerchant_lite/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';

import 'components/body.dart';

class SignInScreen extends StatelessWidget {
  static String routeName = "/sign_in";

  const SignInScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pushNamed(context, SplashScreen.routeName);
          },
        ),
        title: Semantics(label: 'Sign In', child: Text("Sign In", style: Theme.of(context).textTheme.bodyMedium)),
      ),
      body: const Body(),
    );
  }
}
