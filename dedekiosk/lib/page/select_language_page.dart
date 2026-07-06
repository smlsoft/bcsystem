import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;

class SelectLanguagePage extends StatefulWidget {
  const SelectLanguagePage({Key? key}) : super(key: key);

  @override
  SelectLanguagePageState createState() => SelectLanguagePageState();
}

class SelectLanguagePageState extends State<SelectLanguagePage> {
  // McDonald's color scheme
  static const mcdonaldsRed = Color(0xFFDA291C);
  static const mcdonaldsYellow = Color(0xFFFFBC0D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // McDonald's warm grey
      appBar: AppBar(
        elevation: 0,
        backgroundColor: global.primaryThemeColor,
        foregroundColor: global.primaryTextColor,
        title: Text(
          global.language("select_language"),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     gradient: const LinearGradient(
            //       colors: [mcdonaldsRed, Color(0xFFC8102E)],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //     borderRadius: BorderRadius.circular(12),
            //     boxShadow: [
            //       BoxShadow(
            //         color: mcdonaldsRed.withOpacity(0.3),
            //         blurRadius: 8,
            //         offset: const Offset(0, 3),
            //       ),
            //     ],
            //   ),
            //   child: Row(
            //     children: [
            //       Container(
            //         padding: const EdgeInsets.all(12),
            //         decoration: BoxDecoration(
            //           color: Colors.white.withOpacity(0.2),
            //           borderRadius: BorderRadius.circular(10),
            //         ),
            //         child: const Icon(
            //           Icons.language,
            //           size: 32,
            //           color: Colors.white,
            //         ),
            //       ),
            //       const SizedBox(width: 16),
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               global.language("select_language"),
            //               style: const TextStyle(
            //                 fontSize: 22,
            //                 fontWeight: FontWeight.bold,
            //                 color: Colors.white,
            //               ),
            //             ),
            //             const SizedBox(height: 4),
            //             Text(
            //               global.language("choose_preferred_language"),
            //               style: TextStyle(
            //                 fontSize: 14,
            //                 color: Colors.white.withOpacity(0.9),
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 20),

            // Language list
            Expanded(
              child: ListView.builder(
                itemCount: global.countryNames.length,
                itemBuilder: (context, index) {
                  final isSelected = global.languageForCustomer == global.countryCodes[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () {
                          setState(() {
                            global.languageForCustomer = global.countryCodes[index];
                            global.languageSelect(global.languageForCustomer);
                          });
                          // Delay to show animation
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) Navigator.pop(context);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [global.primaryThemeColor, global.primaryThemeColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? global.primaryThemeColor : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Flag with border
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  // border: Border.all(
                                  //   color: isSelected ? Colors.white.withOpacity(0.5) : Colors.grey.shade300,
                                  //   width: 2,
                                  // ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    'assets/flags/${global.countryCodes[index]}.png',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.flag,
                                          color: Colors.grey.shade400,
                                          size: 30,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Language name
                              Expanded(
                                child: Text(
                                  global.countryNames[index],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),

                              // Selected indicator
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: mcdonaldsYellow,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.black87,
                                    size: 24,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
