import 'dart:async';
import 'dart:convert';
import 'package:dedecashier/core/environment.dart';
import 'package:dedecashier/core/request.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/features/authentication/auth.dart';
import 'package:dedecashier/features/shop/presentation/bloc/select_shop_bloc.dart';
import 'package:dedecashier/features/splash/domain/usecase/check_user_login_status.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/services/user_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dedecashier/core/objectbox.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), () {
      reload();
    });
    //reload();
  }

  void reload() async {
    global.isOnline = await global.hasNetwork();
    serviceLocator<CheckUserLoginStatus>().checkIfUserLoggedIn().then((isUserLoggedIn) async {
      if (isUserLoggedIn) {
        final user = await serviceLocator<UserCacheService>().getUser();

        if (user != null) {
          if (user.isDev == 1) {
            Environment().initConfig("DEV");
            serviceLocator<Request>().updateEndpoint();
          } else if (user.isDev == 2) {
            Environment().initConfig("STAGING");
            serviceLocator<Request>().updateEndpoint();
          } else {
            Environment().initConfig("PROD");
            serviceLocator<Request>().updateEndpoint();
          }
        }

        SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
        var pos_terminal_pin_code = sharedPreferences.getString('pos_terminal_pin_code');
        var token_cache = sharedPreferences.getString("token") ?? global.appStorage.read("token");
        var shopid_cache = sharedPreferences.getString("cache_shopid") ?? global.appStorage.read("cache_shopid");

        if (token_cache != null && shopid_cache != null && !global.isOnline) {
          global.apiShopID = shopid_cache ?? "";
          global.shopId = shopid_cache ?? "";

          global.posTerminalPinCode = pos_terminal_pin_code ?? "";

          global.apiConnected = true;
          global.loginSuccess = true;
          global.loginProcess = true;

          await global.getProfile();

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, global.selectIpServerPageName, (route) => false);
          }
          return;
        }

        if (mounted) {
          context.read<AuthenticationBloc>().add(AuthenticationEvent.authenticated(user: user!));
          await global.appStorage.write("token", user.token);
          sharedPreferences.setString('token', user.token);
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, global.selectIpServerPageName, (route) => false);
          }
        }
        global.apiConnected = true;
        global.loginSuccess = true;
        global.loginProcess = true;
        // global.apiConnected = true;

        serviceLocator<CheckUserLoginStatus>().checkIfUserSelectedShop().then((userSelectedShop) async {
          if (userSelectedShop != null && mounted) {
            global.apiShopID = userSelectedShop.guidfixed;
            context.read<SelectShopBloc>().add(SelectShopEvent.onSelectShopRefresh(shop: userSelectedShop));

            try {
              await global.getProfile();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, global.selectIpServerPageName, (route) => false);
              }
            } catch (e) {
              AppLogger.error(e.toString());
            }
          } else {
            // กรณี Load ไม่ผ่าน แสดงว่าติดตั้งใหม่ ให้ไปหน้าจอลงทะเบียน
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, global.registerPosTerminalPageName, (route) => false);
            }
          }
        });
      } else {
        // check flavor is dedepos
        global.isOnline = await global.hasNetwork();

        // ⭐ ตรวจสอบสถานะการลงทะเบียนและ login
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? savedPinCode = prefs.getString('pos_terminal_pin_code');
        String? shopId = prefs.getString('cache_shopid');
        String? apiKey = prefs.getString('apikey');

        // ⭐ เช็คว่าลงทะเบียนและ login สำเร็จหรือยัง
        bool isRegisteredAndLoggedIn = (savedPinCode != null && savedPinCode.isNotEmpty) &&
                                       (shopId != null && shopId.isNotEmpty) &&
                                       (apiKey != null && apiKey.isNotEmpty);

        if (isRegisteredAndLoggedIn) {
          // ✅ ลงทะเบียนและ login สำเร็จแล้ว → ไปหน้า Login
          global.posTerminalPinCode = savedPinCode;
          global.loginSuccess = false;
          global.loginProcess = true;

          AppLogger.debug("[Splash] ✅ Registered & Logged in (PIN: $savedPinCode, Shop: $shopId) → Go to Login");

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, global.loginByEmployeePageName, (route) => false);
          }
        } else {
          // ❌ ยังไม่ได้ลงทะเบียนหรือลงทะเบียนไม่สมบูรณ์ → ไปหน้าลงทะเบียน
          AppLogger.debug("[Splash] ❌ Not registered or incomplete (PIN: $savedPinCode, Shop: $shopId, ApiKey: ${apiKey != null ? 'exists' : 'null'}) → Go to Register");

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, global.registerPosTerminalPageName, (route) => false);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: Image.asset(
            (F.appFlavor == Flavor.MARINEPOS) ? 'assets/icons/marine-logo-app.png' : 'assets/icons/logo_bc_ai_cloud.png', // path to your image asset
          ),
        ),
      ),
    );
  }
}
