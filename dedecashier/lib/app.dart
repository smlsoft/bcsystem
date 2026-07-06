import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'flavors.dart';
import 'pages/my_home_page.dart';

// ⭐ Theme Colors: MARINEPOS = น้ำเงินเข้ม, อื่นๆ = อิฐบ้านเชียง (Terracotta)
final MaterialColor _themeSwatch = (F.appFlavor == Flavor.MARINEPOS)
    ? Colors.blue
    : MaterialColor(0xFFB5651D, const <int, Color>{
        50: Color(0xFFFBF5F0),
        100: Color(0xFFF5E6D8),
        200: Color(0xFFEAC9AC),
        300: Color(0xFFDEAB7F),
        400: Color(0xFFD18D52),
        500: Color(0xFFB5651D),
        600: Color(0xFF9A5518),
        700: Color(0xFF7F4513),
        800: Color(0xFF64350E),
        900: Color(0xFF4A2509),
      });

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: F.title,
      theme: ThemeData(primarySwatch: _themeSwatch),
      home: _flavorBanner(child: MyHomePage(), show: kDebugMode),
    );
  }

  Widget _flavorBanner({required Widget child, bool show = true}) => show
      ? Banner(
          location: BannerLocation.topStart,
          message: F.name,
          color: Colors.green.withValues(alpha: 0.6),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.0, letterSpacing: 1.0),
          textDirection: TextDirection.ltr,
          child: child,
        )
      : Container(child: child);
}
