// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cocomerchant_lite/components/default_button.dart';
import 'package:cocomerchant_lite/size_config.dart';

class OtpForm extends StatefulWidget {
  const OtpForm({
    super.key,
  });

  @override
  _OtpFormState createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  List<FocusNode> pinFocusNodes = List.generate(8, (index) => FocusNode());
  List<TextEditingController> pinControllers = List.generate(8, (index) => TextEditingController());
  bool isOtpComplete = false;
  bool showError = false;

  @override
  void initState() {
    super.initState();
    for (var controller in pinControllers) {
      controller.addListener(checkOtpCompletion);
    }
  }

  @override
  void dispose() {
    for (var focusNode in pinFocusNodes) {
      focusNode.dispose();
    }
    for (var controller in pinControllers) {
      controller.removeListener(checkOtpCompletion);
      controller.dispose();
    }
    super.dispose();
  }

  void checkOtpCompletion() {
    setState(() {
      isOtpComplete = pinControllers.every((controller) => controller.text.length == 1);
      if (isOtpComplete) {
        showError = false;
      }
    });
  }

  void handleInput(String value, int index) {
    if (value.isEmpty && index > 0) {
      // ถ้าลบตัวเลข ให้ย้ายโฟกัสไปช่องก่อนหน้า
      pinFocusNodes[index - 1].requestFocus();
    } else if (value.length == 1 && index < 7) {
      // ถ้าป้อนตัวเลข ให้ย้ายโฟกัสไปช่องถัดไป
      pinFocusNodes[index + 1].requestFocus();
    }
  }

  void handleKeyPress(KeyEvent event, int index) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace && pinControllers[index].text.isEmpty && index > 0) {
        // ถ้ากดปุ่มลบในช่องว่าง ให้ย้ายโฟกัสไปช่องก่อนหน้าและลบตัวเลขในช่องนั้น
        pinFocusNodes[index - 1].requestFocus();
        pinControllers[index - 1].text = '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          SizedBox(height: SizeConfig.screenHeight * 0.15),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                8,
                (index) => SizedBox(
                  width: getProportionateScreenWidth(35),
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) => handleKeyPress(event, index),
                    child: TextFormField(
                      autofocus: index == 0,
                      focusNode: pinFocusNodes[index],
                      controller: pinControllers[index],
                      obscureText: false,
                      style: TextStyle(fontSize: getProportionateScreenWidth(20)),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: getProportionateScreenWidth(15)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(getProportionateScreenWidth(15)),
                          borderSide: BorderSide(
                            color: showError && pinControllers[index].text.isEmpty ? Colors.red : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(getProportionateScreenWidth(15)),
                          borderSide: BorderSide(
                            color: showError && pinControllers[index].text.isEmpty ? Colors.red : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(getProportionateScreenWidth(15)),
                          borderSide: BorderSide(
                            color: showError && pinControllers[index].text.isEmpty ? Colors.red : Colors.blue,
                            width: 2,
                          ),
                        ),
                        fillColor: Colors.grey[200],
                        filled: true,
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        handleInput(value, index);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.screenHeight * 0.10),
          DefaultButton(
            text: "Continue",
            press: () {
              if (isOtpComplete) {
                String otp = pinControllers.map((controller) => controller.text).join();
                Navigator.pop(context, otp);
              } else {
                setState(() {
                  showError = true;
                });
              }
            },
          )
        ],
      ),
    );
  }
}
