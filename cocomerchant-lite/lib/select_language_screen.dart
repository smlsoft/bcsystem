import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:get_storage/get_storage.dart';

class SelectLanguageScreen extends StatefulWidget {
  const SelectLanguageScreen({Key? key}) : super(key: key);

  @override
  SelectLanguageScreenState createState() => SelectLanguageScreenState();
}

class SelectLanguageScreenState extends State<SelectLanguageScreen> {
  List<String> countryNames = ["English", "Thai", "Laos", "Chinese", "Japan", "Korea"];
  List<String> countryCodes = ["en", "th", "lo", "zh", "ja", "ko"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(global.language('select_language'), style: const TextStyle(fontSize: 16, color: Colors.white)),
        backgroundColor: global.theme.appBarColor,
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // Adjust based on your screen size
            childAspectRatio: 3 / 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: countryNames.length,
          itemBuilder: (context, index) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: LanguageCard(
                countryName: countryNames[index],
                countryCode: countryCodes[index],
                onTap: () {
                  setState(() {
                    global.userLanguage = countryCodes[index];
                    GetStorage().write('language', global.userLanguage);
                    global.languageSelect(global.userLanguage);
                    Navigator.of(context).pushReplacementNamed('/menu');
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class LanguageCard extends StatelessWidget {
  final String countryName;
  final String countryCode;
  final VoidCallback onTap;

  const LanguageCard({
    Key? key,
    required this.countryName,
    required this.countryCode,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/flags/$countryCode.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Text(
              countryName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
