import 'package:flutter/material.dart';
import 'package:smlaicloud/global.dart' as global;

class SelectLanguageScreen extends StatefulWidget {
  const SelectLanguageScreen({super.key});

  @override
  SelectLanguageScreenState createState() => SelectLanguageScreenState();
}

class SelectLanguageScreenState extends State<SelectLanguageScreen> {
  List<String> selectLanguageOptionsTranslated = [
    "Select language English", // อังกฤษ: เลือกภาษา English
    "เลือกภาษา ไทย", // ไทย: เลือกภาษา ไทย
    "ເລືອກພາສາ ລາວ", // ลาว: เลือกภาษา ลาว
    "选择语言 中文", // จีน: เลือกภาษา จีน (ตัวย่อ)
    "言語を選択 日本語", // ญี่ปุ่น: เลือกภาษา ญี่ปุ่น
    "언어 선택 한국어" // เกาหลี: เลือกภาษา เกาหลี
  ];
  List<String> countryCodes = ["en", "th", "lo", "zh", "ja", "ko"];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              child: ListView.builder(
                  itemCount: selectLanguageOptionsTranslated.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      title: Row(children: [
                        Image.asset(
                          'assets/flags/${countryCodes[index]}.png',
                          width: 100,
                          height: 100,
                        ),
                        const SizedBox(width: 10),
                        Text(selectLanguageOptionsTranslated[index],
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ]),
                      onTap: () {
                        Navigator.of(context).pop(
                          countryCodes[index],
                        );
                      },
                    );
                  }))),
    );
  }
}
