import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;

class SelectMemberScreen extends StatefulWidget {
  const SelectMemberScreen({super.key});

  @override
  State<SelectMemberScreen> createState() => _SelectMemberScreenState();
}

class _SelectMemberScreenState extends State<SelectMemberScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orangeAccent.shade100,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width / 1.1,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(width: double.infinity, constraints: const BoxConstraints(maxWidth: 400), child: FittedBox(fit: BoxFit.fitWidth, child: Text(global.language("select_member_type"), style: textStyleBorderWhite, textAlign: TextAlign.center))),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(Colors.blue.shade800),
                            foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
                            elevation: WidgetStateProperty.all<double>(10.0),
                            shadowColor: WidgetStateProperty.all<Color>(Colors.grey),
                            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              global.memberCode = "";
                              global.memberPinCode = "";
                              global.priceIndex = 1;
                              global.custNames = [];
                              global.memberPicture = "";
                              global.memberEmail = "";
                              global.isMember = false;
                            });
                            Future.delayed(const Duration(seconds: 1), () {
                              Navigator.pushNamedAndRemoveUntil(context, "/order_animation_one", (Route<dynamic> route) => false);
                            });
                          },
                          child: Column(
                            children: [
                              FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Image.asset(
                                    "assets/images/ordernow.png",
                                  )),
                              FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text(
                                  global.language('standard'),
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8, left: 8),
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(Colors.orange.shade800),
                            foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
                            elevation: WidgetStateProperty.all<double>(10.0),
                            shadowColor: WidgetStateProperty.all<Color>(Colors.grey),
                            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              global.memberPinCode = "";
                              global.memberCode = "";
                              global.custNames = [];
                              global.memberPicture = "";
                              global.memberEmail = "";
                              global.priceIndex = 1;
                              global.isMember = false;
                            });
                            Future.delayed(const Duration(seconds: 1), () {
                              // ใช้ member_qr flow ใหม่ (QR scan แทน PIN input)
                              Navigator.pushNamedAndRemoveUntil(context, "/member_qr", (Route<dynamic> route) => false);
                            });
                          },
                          child: Column(
                            children: [
                              FittedBox(fit: BoxFit.fitWidth, child: Image.asset("assets/images/member.png")),
                              FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text(
                                  global.language('member'),
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 60,
                ),
                Container(
                  height: 60,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
                      foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
                      elevation: WidgetStateProperty.all<double>(10.0),
                      shadowColor: WidgetStateProperty.all<Color>(Colors.grey),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        global.memberCode = "";
                        global.priceIndex = 1;
                      });
                      Future.delayed(const Duration(seconds: 1), () {
                        Navigator.pushNamedAndRemoveUntil(context, "/order_select", (Route<dynamic> route) => false);
                      });
                    },
                    child: Text(
                      global.language('back'),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle textStyleBorderWhite = const TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        blurRadius: 2.0,
        color: Colors.white,
        offset: Offset(1.0, 1.0),
      ),
      Shadow(
        blurRadius: 2.0,
        color: Colors.white,
        offset: Offset(-1.0, 1.0),
      ),
      Shadow(
        blurRadius: 2.0,
        color: Colors.white,
        offset: Offset(1.0, -1.0),
      ),
      Shadow(
        blurRadius: 2.0,
        color: Colors.white,
        offset: Offset(-1.0, -1.0),
      ),
    ],
  );
}
