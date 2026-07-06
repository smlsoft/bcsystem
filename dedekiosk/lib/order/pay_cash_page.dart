import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;

class PayCashPage extends StatefulWidget {
  final double amount;

  const PayCashPage({super.key, required this.amount});

  @override
  PayCashPageState createState() => PayCashPageState();
}

class PayCashPageState extends State<PayCashPage> {
  double payAmountTotal = 0;
  String payAmountText = "";

  @override
  void initState() {
    super.initState();
  }

  void setPayAmount(double payAmount) {
    payAmountTotal = payAmount;
    setState(() {});
  }

  void textInputAdd(String word) {
    payAmountText = payAmountText + word;
    setPayAmount(global.calcTextToNumber(payAmountText));
  }

  // Minimalist Number Pad Button
  Widget _buildNumButton({
    required String text,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    required VoidCallback onTap,
    required double fontSize,
    required double iconSize,
  }) {
    final bgColor = backgroundColor ?? Colors.white;
    final fgColor = textColor ?? Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: iconSize, color: fgColor)
                  : Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: fgColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget numberPad({required double fontSize, required double iconSize}) {
    return Column(
      children: [
        // Row 1: 7, 8, 9
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildNumButton(text: '7', onTap: () => textInputAdd("7"), fontSize: fontSize, iconSize: iconSize)),
              Expanded(child: _buildNumButton(text: '8', onTap: () => textInputAdd("8"), fontSize: fontSize, iconSize: iconSize)),
              Expanded(child: _buildNumButton(text: '9', onTap: () => textInputAdd("9"), fontSize: fontSize, iconSize: iconSize)),
            ],
          ),
        ),
        // Row 2: 4, 5, 6
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildNumButton(text: '4', onTap: () => textInputAdd("4"), fontSize: fontSize, iconSize: iconSize)),
              Expanded(child: _buildNumButton(text: '5', onTap: () => textInputAdd("5"), fontSize: fontSize, iconSize: iconSize)),
              Expanded(child: _buildNumButton(text: '6', onTap: () => textInputAdd("6"), fontSize: fontSize, iconSize: iconSize)),
            ],
          ),
        ),
        // Row 3: 1, 2, 3
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildNumButton(text: '1', onTap: () => textInputAdd("1"), fontSize: fontSize, iconSize: iconSize)),
              Expanded(child: _buildNumButton(text: '2', onTap: () => textInputAdd("2"), fontSize: fontSize, iconSize: iconSize)),
              Expanded(child: _buildNumButton(text: '3', onTap: () => textInputAdd("3"), fontSize: fontSize, iconSize: iconSize)),
            ],
          ),
        ),
        // Row 4: 0, .
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _buildNumButton(text: '0', onTap: () => textInputAdd("0"), fontSize: fontSize, iconSize: iconSize),
              ),
              Expanded(
                child: _buildNumButton(
                  text: '.',
                  onTap: () {
                    if (!payAmountText.contains('.')) {
                      textInputAdd(payAmountText.isEmpty ? "0." : ".");
                    }
                  },
                  fontSize: fontSize,
                  iconSize: iconSize,
                ),
              ),
            ],
          ),
        ),
        // Row 5: Backspace, Clear
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildNumButton(
                  text: '',
                  icon: Icons.backspace_outlined,
                  backgroundColor: Colors.red.shade50,
                  textColor: const Color(0xFFDA291C),
                  onTap: () {
                    if (payAmountText.isNotEmpty) {
                      payAmountText = payAmountText.substring(0, payAmountText.length - 1);
                      setPayAmount(global.calcTextToNumber(payAmountText));
                    }
                  },
                  fontSize: fontSize,
                  iconSize: iconSize,
                ),
              ),
              Expanded(
                child: _buildNumButton(
                  text: 'C',
                  backgroundColor: Colors.grey.shade100,
                  textColor: Colors.grey.shade700,
                  onTap: () {
                    payAmountText = "";
                    setPayAmount(global.calcTextToNumber(payAmountText));
                  },
                  fontSize: fontSize,
                  iconSize: iconSize,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget moneyButton({required double value, required bool isMobile, required bool isTablet}) {
    final buttonPadding = isMobile ? 4.0 : 6.0;
    final labelSize = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);

    return Padding(
      padding: EdgeInsets.all(buttonPadding / 2),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            payAmountText = (global.calcTextToNumber(payAmountText) + value).toString();
            setPayAmount(global.calcTextToNumber(payAmountText));
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200, width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Money image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/moneythai${value.toStringAsFixed(0)}.gif',
                    fit: BoxFit.contain,
                  ),
                ),
                // Label overlay
                Positioned(
                  bottom: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "+${value.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: labelSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive breakpoints
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    // Responsive sizing - ปรับให้เหมาะกับมือถือมากขึ้น
    final padding = isMobile ? 8.0 : 16.0;
    final displayHeight = isMobile ? 60.0 : (isTablet ? 80.0 : 90.0);
    final amountFontSize = isMobile ? 20.0 : (isTablet ? 32.0 : 40.0);
    final inputFontSize = isMobile ? 24.0 : (isTablet ? 36.0 : 44.0);
    final numPadFontSize = isMobile ? 20.0 : (isTablet ? 32.0 : 40.0);
    final numPadIconSize = isMobile ? 20.0 : (isTablet ? 28.0 : 32.0);
    final moneyRowHeight = isMobile ? 50.0 : (isTablet ? 70.0 : 80.0);
    final buttonHeight = isMobile ? 44.0 : (isTablet ? 54.0 : 60.0);
    final buttonFontSize = isMobile ? 12.0 : (isTablet ? 16.0 : 18.0);

    // Calculate change amount
    final changeAmount = payAmountTotal - widget.amount;
    final isEnoughPayment = payAmountTotal >= widget.amount;

    return Container(
      constraints: BoxConstraints(
        // บนมือถือใช้พื้นที่มากขึ้น
        maxWidth: isMobile ? screenWidth * 0.95 : screenWidth * 0.80,
        maxHeight: isMobile ? screenHeight * 0.90 : screenHeight * 0.70,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
      ),
      child: Column(
        children: [
          // Header - Amount Display Section
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMobile ? 16 : 20),
                topRight: Radius.circular(isMobile ? 16 : 20),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Total Amount Button & Input Display
                // บนมือถือแสดงเป็น Column, บน tablet/desktop แสดงเป็น Row
                if (isMobile) ...[
                  // Mobile: Column layout
                  GestureDetector(
                    onTap: () {
                      payAmountText = global.moneyFormat.format(widget.amount);
                      setPayAmount(global.calcTextToNumber(payAmountText));
                    },
                    child: Container(
                      width: double.infinity,
                      height: displayHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${global.language("total_amount")}: ",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "${global.moneyFormat.format(widget.amount)} ฿",
                            style: TextStyle(
                              fontSize: amountFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Input Display
                  Container(
                    width: double.infinity,
                    height: displayHeight,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${global.language("receive_money")}: ",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          payAmountText.isEmpty ? "0" : payAmountText,
                          style: TextStyle(
                            fontSize: inputFontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDA291C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Desktop/Tablet: Row layout
                  Row(
                    children: [
                      // Quick Fill Button (Total Amount)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            payAmountText = global.moneyFormat.format(widget.amount);
                            setPayAmount(global.calcTextToNumber(payAmountText));
                          },
                          child: Container(
                            height: displayHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade400, Colors.green.shade600],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  global.language("total_amount"),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${global.moneyFormat.format(widget.amount)} ฿",
                                  style: TextStyle(
                                    fontSize: amountFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Input Display
                      Expanded(
                        child: Container(
                          height: displayHeight,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                global.language("receive_money"),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                payAmountText.isEmpty ? "0" : payAmountText,
                                style: TextStyle(
                                  fontSize: inputFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFDA291C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ], // Change Amount Display (if payment entered)
                if (payAmountTotal > 0) ...[
                  SizedBox(height: isMobile ? 6 : 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 16,
                      vertical: isMobile ? 6 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: isEnoughPayment ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isEnoughPayment ? Colors.green.shade200 : Colors.orange.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isEnoughPayment ? Icons.check_circle_outline : Icons.info_outline,
                              size: isMobile ? 16 : 22,
                              color: isEnoughPayment ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                            SizedBox(width: isMobile ? 4 : 8),
                            Text(
                              isEnoughPayment ? global.language("money_change") : global.language("remaining_amount"),
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 15,
                                color: isEnoughPayment ? Colors.green.shade700 : Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "${global.moneyFormat.format(changeAmount.abs())} ฿",
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 22,
                            fontWeight: FontWeight.bold,
                            color: isEnoughPayment ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Number Pad Section
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: numberPad(fontSize: numPadFontSize, iconSize: numPadIconSize),
            ),
          ), // Money Quick Add Section
          // บนมือถือแสดง 2 แถว, บน tablet/desktop แสดงแถวเดียว
          if (isMobile) ...[
            // Mobile: 2 rows
            Container(
              margin: EdgeInsets.symmetric(horizontal: padding),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                children: [
                  // Row 1: 1000, 500, 100
                  SizedBox(
                    height: moneyRowHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: moneyButton(value: 1000, isMobile: isMobile, isTablet: isTablet)),
                        Expanded(child: moneyButton(value: 500, isMobile: isMobile, isTablet: isTablet)),
                        Expanded(child: moneyButton(value: 100, isMobile: isMobile, isTablet: isTablet)),
                      ],
                    ),
                  ),
                  // Row 2: 50, 20, 10
                  SizedBox(
                    height: moneyRowHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: moneyButton(value: 50, isMobile: isMobile, isTablet: isTablet)),
                        Expanded(child: moneyButton(value: 20, isMobile: isMobile, isTablet: isTablet)),
                        Expanded(child: moneyButton(value: 10, isMobile: isMobile, isTablet: isTablet)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Desktop/Tablet: Single row
            Container(
              height: moneyRowHeight,
              margin: EdgeInsets.symmetric(horizontal: padding),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: moneyButton(value: 1000, isMobile: isMobile, isTablet: isTablet)),
                  Expanded(child: moneyButton(value: 500, isMobile: isMobile, isTablet: isTablet)),
                  Expanded(child: moneyButton(value: 100, isMobile: isMobile, isTablet: isTablet)),
                  Expanded(child: moneyButton(value: 50, isMobile: isMobile, isTablet: isTablet)),
                  Expanded(child: moneyButton(value: 20, isMobile: isMobile, isTablet: isTablet)),
                ],
              ),
            ),
          ], // Action Buttons Section
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(isMobile ? 16 : 20),
                bottomRight: Radius.circular(isMobile ? 16 : 20),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: isMobile
                // Mobile: Column layout
                ? Column(
                    children: [
                      // Confirm Button (แสดงก่อนบนมือถือ)
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, payAmountTotal),
                          icon: Icon(
                            payAmountTotal == 0 ? Icons.cancel_outlined : (isEnoughPayment ? Icons.check_circle : Icons.savings_outlined),
                            size: 18,
                          ),
                          label: Text(
                            global.language(
                              payAmountTotal == 0 ? "cancel_cash_payment" : (isEnoughPayment ? "instant_cash_payment" : "partial_cash_payment"),
                            ),
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: payAmountTotal == 0 ? Colors.grey.shade400 : (isEnoughPayment ? Colors.green.shade600 : Colors.orange.shade600),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context, 0.0),
                          icon: const Icon(Icons.close, size: 18),
                          label: Text(
                            global.language("cancel"),
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                // Desktop/Tablet: Row layout
                : Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: SizedBox(
                          height: buttonHeight,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context, 0.0),
                            icon: const Icon(Icons.close, size: 20),
                            label: Text(
                              global.language("cancel"),
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Confirm Button
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: buttonHeight,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context, payAmountTotal),
                            icon: Icon(
                              payAmountTotal == 0 ? Icons.cancel_outlined : (isEnoughPayment ? Icons.check_circle : Icons.savings_outlined),
                              size: 20,
                            ),
                            label: Text(
                              global.language(
                                payAmountTotal == 0 ? "cancel_cash_payment" : (isEnoughPayment ? "instant_cash_payment" : "partial_cash_payment"),
                              ),
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: payAmountTotal == 0 ? Colors.grey.shade400 : (isEnoughPayment ? Colors.green.shade600 : Colors.orange.shade600),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
