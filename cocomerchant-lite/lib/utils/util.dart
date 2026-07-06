import 'package:flutter/material.dart';

class Util {
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
}

class ReconnectingOverlay extends StatelessWidget {
  const ReconnectingOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
          ],
        ),
      );
}
