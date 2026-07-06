import 'package:cocomerchant_lite/bloc/login_bloc/login_bloc.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/screens/login_success/login_success_screen.dart';
import 'package:cocomerchant_lite/screens/sign_in/sign_in_screen.dart';
import 'package:cocomerchant_lite/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'profile_menu.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        /// Logout
        if (state is LogoutSuccess) {
          Navigator.pushNamed(context, SignInScreen.routeName);
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // const ProfilePic(),
            Text(
              (global.appConfig.read("name") != "")
                  ? global.appConfig.read("name")
                  : global.activeLangName(
                      global.shopSelectData.names!,
                    ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              " (${global.activeLangName(global.companyBranchSelectData.names)})",
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: getProportionateScreenHeight(5)),
            Text(
              global.appConfig.read("user"),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 20),
            ProfileMenu(
              text: "ร้านค้า : ${global.activeLangName(global.shopSelectData.names!)}",
              icon: "assets/icons/company-icon.svg",
              press: () {
                Navigator.pushNamed(context, LoginSuccessScreen.routeName);
              },
            ),
            ProfileMenu(
              text: "สาขา : ${global.activeLangName(global.companyBranchSelectData.names)}",
              icon: "assets/icons/shop-icon.svg",
              press: () {
                Navigator.pushNamed(context, LoginSuccessScreen.routeName, arguments: true);
              },
            ),
            ProfileMenu(
              text: "ออกจากระบบ",
              icon: "assets/icons/Log out.svg",
              press: () {
                context.read<LoginBloc>().add(const Logout());
              },
            ),
          ],
        ),
      ),
    );
  }
}
