import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:async';

class SelectLanguageScreen extends StatefulWidget {
  const SelectLanguageScreen({super.key});

  @override
  State<SelectLanguageScreen> createState() => _SelectLanguageScreenState();
}

class _SelectLanguageScreenState extends State<SelectLanguageScreen> {
  final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text(global.language("select_language")), backgroundColor: _themeColor),
        body: Container(
          padding: const EdgeInsets.all(4),
          color: Colors.white,
          child: ListView.builder(
            itemCount: global.countryNames.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(2),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(12),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: _themeColor, width: 2),
                    ),
                  ),
                  onPressed: () async {
                    global.userScreenLanguage = global.countryCodes[index];
                    await GetStorage().write('language', global.userScreenLanguage).then((value) {
                      global.languageSelect(global.userScreenLanguage);
                      Navigator.pop(context);
                    });
                  },
                  child: Row(children: [Image.asset('assets/flags/${global.countryCodes[index]}.png', width: 100, height: 100), const SizedBox(width: 10), Text(global.countryNames[index])]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
