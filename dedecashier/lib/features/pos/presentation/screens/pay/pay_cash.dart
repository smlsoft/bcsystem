import 'package:dedecashier/bloc/pay_screen_bloc.dart';
import 'package:dedecashier/flavors.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';

// ⭐ Theme Colors: MARINEPOS = น้ำเงินเข้ม, อื่นๆ = อิฐบ้านเชียง (Terracotta)
final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

class PayCashWidget extends StatefulWidget {
  final BuildContext blocContext;

  const PayCashWidget({super.key, required this.blocContext});

  @override
  PayCashWidgetState createState() => PayCashWidgetState();
}

class PayCashWidgetState extends State<PayCashWidget> {
  double diffAmount = 0;

  @override
  void initState() {
    refreshEvent();
    super.initState();
  }

  void setPayAmount(double payAmount) {
    setState(() {
      diffAmount = payAmount + global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount;
      if (diffAmount < 0) {
        diffAmount = 0;
      }
    });
  }

  void refreshEvent() {
    widget.blocContext.read<PayScreenBloc>().add(PayScreenRefresh());
  }

  // Blue button widget for number pad
  Widget _vintageNumPadButton({required String text, IconData? icon, Color? backgroundColor, Color? textColor, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? _themeColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _themeColor, width: 1),
        boxShadow: [BoxShadow(offset: const Offset(0, 1), blurRadius: 3, color: Colors.black.withOpacity(0.25))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 40, // More compact
            child: Center(
              child: icon != null
                  ? Icon(icon, color: textColor ?? Colors.white, size: 20) // White icon
                  : Text(
                      text,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? Colors.white, // White text
                        fontFamily: 'serif', // More traditional look
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void textInputAdd(String word) {
    global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount_text =
        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount_text + word;
    global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount = global.calcTextToNumber(
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount_text,
    );
    refreshEvent();
  }

  Widget numberPad() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(8), // Less rounded
        border: Border.all(color: const Color(0xFF005598), width: 2), // Blue border
        boxShadow: [BoxShadow(offset: const Offset(0, 2), blurRadius: 6, color: Colors.black.withOpacity(0.1))],
      ),
      padding: const EdgeInsets.all(8), // Reduced padding
      child: Column(
        children: [
          // Row 1: 7, 8, 9
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _vintageNumPadButton(
                    text: '7',
                    onTap: () {
                      global.playSound(sound: global.SoundEnum.num7);
                      textInputAdd("7");
                    },
                  ),
                ),
                const SizedBox(width: 6), // Reduced spacing
                Expanded(
                  child: _vintageNumPadButton(
                    text: '8',
                    onTap: () {
                      global.playSound(sound: global.SoundEnum.num8);
                      textInputAdd("8");
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _vintageNumPadButton(
                    text: '9',
                    onTap: () {
                      global.playSound(sound: global.SoundEnum.num9);
                      textInputAdd("9");
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6), // Reduced spacing
          // Row 2: 4, 5, 6
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _vintageNumPadButton(
                    text: '4',
                    onTap: () {
                      global.playSound(sound: global.SoundEnum.num4);
                      textInputAdd("4");
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _vintageNumPadButton(
                    text: '5',
                    onTap: () {
                      global.playSound(sound: global.SoundEnum.num5);
                      textInputAdd("5");
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _vintageNumPadButton(
                    text: '6',
                    onTap: () {
                      global.playSound(sound: global.SoundEnum.num6);
                      textInputAdd("6");
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Row 3: 1, 2, 3
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _vintageNumPadButton(
                    text: '1',
                    onTap: () {
                      global.playSound(sound: global.SoundEnum.num1);
                      textInputAdd("1");
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _vintageNumPadButton(
                    text: '2',
                    onTap: () {
                      global.playSound(sound: global.SoundEnum.num2);
                      textInputAdd("2");
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _vintageNumPadButton(
                    text: '3',
                    onTap: () {
                      global.playSound(sound: global.SoundEnum.num3);
                      textInputAdd("3");
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Row 4: 0, .
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _vintageNumPadButton(
                    text: '0',
                    onTap: () {
                      global.playSound(sound: global.SoundEnum.num0);
                      textInputAdd("0");
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _vintageNumPadButton(
                    text: '.',
                    onTap: () {
                      global.playSound(sound: global.SoundEnum.numDot);
                      if (!global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount_text.contains('.')) {
                        textInputAdd((global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount_text.isNotEmpty) ? "." : "0.");
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Row 5: Backspace, Clear
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _vintageNumPadButton(
                    text: '',
                    icon: Icons.backspace_outlined,
                    backgroundColor: Colors.red[600], // Red for backspace
                    textColor: Colors.white, // White color
                    onTap: () {
                      global.playSound(sound: global.SoundEnum.numpadDelete);
                      if (global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount_text.isNotEmpty) {
                        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount_text = global
                            .posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)]
                            .payScreenData
                            .cash_amount_text
                            .substring(0, global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount_text.length - 1);
                        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount = global.calcTextToNumber(
                          global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount_text,
                        );
                        refreshEvent();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _vintageNumPadButton(
                    text: 'C',
                    backgroundColor: Colors.grey, // Orange for clear
                    textColor: Colors.white, // White color
                    onTap: () {
                      global.playSound(sound: global.SoundEnum.numpadClear);
                      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount_text = "";
                      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount = 0;
                      refreshEvent();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget moneyButton(double value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2), // Reduced margin
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6), // Less rounded
        boxShadow: [BoxShadow(offset: const Offset(0, 2), blurRadius: 4, color: Colors.black.withOpacity(0.15))],
      ),
      child: Material(
        elevation: 0,
        clipBehavior: Clip.hardEdge,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background with blue gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                // color: const Color(0xFF005598), // Blue background
                border: Border.all(color: const Color(0xFF005598), width: 1), // Blue border
              ),
            ),
            // Money image with reduced opacity
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Opacity(
                  opacity: 0.4, // More subtle
                  child: Image.asset('assets/images/moneythai${value.toStringAsFixed(0)}.gif', fit: BoxFit.fill),
                ),
              ),
            ), // Button text overlay - more prominent
            Positioned(
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Reduced padding
                decoration: BoxDecoration(
                  color: const Color(0xFF005598).withOpacity(0.9), // Blue background
                  borderRadius: BorderRadius.circular(3), // Less rounded
                  border: Border.all(color: const Color(0xFF005598), width: 1), // Blue border
                ),
                child: Text(
                  "+${value.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 12, // Smaller font
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),
            // Invisible button for tap
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    global.playSound(sound: global.SoundEnum.buttonTing);
                    global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount =
                        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount + value;
                    global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount_text = global
                        .posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)]
                        .payScreenData
                        .cash_amount
                        .toString();
                    refreshEvent();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white, // White background
            Color(0xFFF5F5F5), // Very light gray
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6), // Reduced padding
        child: Column(
          children: [
            // Top section with quick amount and amount display
            Padding(
              padding: const EdgeInsets.only(bottom: 6), // Reduced padding
              child: Row(
                children: [
                  // Quick amount button
                  Container(
                    height: 80, // More compact
                    width: 180, // Slightly smaller
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6), // Less rounded
                      border: Border.all(color: (F.appFlavor == Flavor.MARINEPOS) ? Color(0xFF005598) : _themeColor, width: 2),
                      boxShadow: [BoxShadow(offset: const Offset(0, 2), color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 4)],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (F.appFlavor == Flavor.MARINEPOS) ? Color(0xFF005598) : _themeColor, // Blue background
                        foregroundColor: Colors.white, // White text
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount = diffAmount;
                        global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount_text = "";
                        refreshEvent();
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.fitHeight,
                          child: Text(
                            global.moneyFormat.format(diffAmount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                              shadows: [
                                Shadow(offset: Offset(-0.5, -0.5), color: Colors.black26),
                                Shadow(offset: Offset(0.5, -0.5), color: Colors.black26),
                                Shadow(offset: Offset(0.5, 0.5), color: Colors.black26),
                                Shadow(offset: Offset(-0.5, 0.5), color: Colors.black26),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // Amount display
                  Expanded(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white, // White background
                        borderRadius: BorderRadius.circular(6), // Less rounded
                        border: Border.all(color: (F.appFlavor == Flavor.MARINEPOS) ? Color(0xFF005598) : _themeColor, width: 2),
                        boxShadow: [BoxShadow(offset: const Offset(0, 2), color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 4)],
                      ),
                      padding: const EdgeInsets.only(right: 12), // Reduced padding
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          global.moneyFormat.format(global.posHoldProcessResult[global.findPosHoldProcessResultIndex(global.posHoldActiveCode)].payScreenData.cash_amount),
                          style: TextStyle(
                            color: (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : _themeColor, // Blue text or theme color
                            fontSize: (global.isDesktopScreen() || global.isTabletScreen()) ? 40 : 20, // Smaller font
                            fontWeight: FontWeight.bold,
                            fontFamily: 'serif',
                            shadows: const [
                              Shadow(offset: Offset(-0.5, -0.5), color: Colors.black12),
                              Shadow(offset: Offset(0.5, -0.5), color: Colors.black12),
                              Shadow(offset: Offset(0.5, 0.5), color: Colors.black12),
                              Shadow(offset: Offset(-0.5, 0.5), color: Colors.black12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main content area
            Expanded(
              child: Column(
                children: [
                  // Number pad
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6), // Reduced padding
                      child: numberPad(),
                    ),
                  ), // Money buttons
                  Container(
                    height: 75, // More compact
                    margin: const EdgeInsets.only(bottom: 2), // Reduced margin
                    padding: const EdgeInsets.all(4), // Reduced padding
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white, // White background
                      borderRadius: BorderRadius.circular(6), // Less rounded
                      border: Border.all(color: const Color(0xFF005598), width: 2),
                      boxShadow: [BoxShadow(offset: const Offset(0, 2), color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 3)],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(child: moneyButton(1000)),
                        Expanded(child: moneyButton(500)),
                        Expanded(child: moneyButton(100)),
                        Expanded(child: moneyButton(50)),
                        Expanded(child: moneyButton(20)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
