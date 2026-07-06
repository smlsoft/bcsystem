import 'package:dedecashier/db/product_barcode_helper.dart';
import 'package:dedecashier/flavors.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:loading_animation_widget/loading_animation_widget.dart';

class InitShopScreen extends StatefulWidget {
  const InitShopScreen({super.key});

  @override
  State<InitShopScreen> createState() => _InitShopScreenState();
}

class _InitShopScreenState extends State<InitShopScreen> {
  int loadtime = 3;
  @override
  void initState() {
    super.initState();
    if (ProductBarcodeHelper().count() == 0) {
      loadtime = 8;
    }

    Future.delayed(const Duration(seconds: 1), () {
      global.apiUserName = global.appStorage.read("apiUserName") ?? "";
      global.apiUserPassword = global.appStorage.read("apiUserPassword") ?? "";

      preparePosScreen().then((_) {
        if (global.appMode == global.AppModeEnum.posRemote) {
          Navigator.of(context).pushReplacementNamed('client');
        } else {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => const PosScreen(
          //         posScreenMode: global.PosScreenModeEnum.posSale),
          //   ),
          // );

          Future.delayed(Duration(seconds: loadtime), () {
            if (F.appFlavor == Flavor.BCPOS || F.appFlavor == Flavor.SMLSUPERPOS) {
              /*context.router.pushAndPopUntil(const MenuRoute(),
                  predicate: (route) => false);*/
            } else {
              /*context.router.pushAndPopUntil(const DashboardRoute(),
                  predicate: (route) => false);*/
            }
          });
        }
      });
    });
  }

  /// เตรียมข้อมูล
  Future<void> preparePosScreen() async {}

  @override
  Widget build(BuildContext context) {
    global.getDeviceModel(context);
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LoadingAnimationWidget.staggeredDotsWave(color: Colors.blue, size: 200),
              const SizedBox(height: 10),
              Text("Data Synchronization"),
            ],
          ),
        ),
      ),
    );
  }
}
