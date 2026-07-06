import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;

class PayDiscountWidget extends StatefulWidget {
  final double amount;

  const PayDiscountWidget({super.key, required this.amount});

  @override
  State<PayDiscountWidget> createState() => _PayDiscountWidgetState();
}

class _PayDiscountWidgetState extends State<PayDiscountWidget> with SingleTickerProviderStateMixin {
  double discountResult = 0;
  String textInputFormula = "";
  bool isError = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void calcDiscount() {
    discountResult = global.calcDiscount(amount: widget.amount, discountWord: textInputFormula);
    // Trigger animation when discount changes
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    setState(() {});
  }

  void textInputAdd(String word) {
    textInputFormula = textInputFormula + word;
    calcDiscount();
  }

  Widget numberPad() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: 7, 8, 9, %
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(child: _buildNumberButton('7', () => textInputAdd("7"))),
                Expanded(child: _buildNumberButton('8', () => textInputAdd("8"))),
                Expanded(child: _buildNumberButton('9', () => textInputAdd("9"))),
                Expanded(child: _buildSpecialButton('%', Colors.purple, () => textInputAdd("%"))),
              ],
            ),
          ),
          // Row 2: 4, 5, 6, ,
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(child: _buildNumberButton('4', () => textInputAdd("4"))),
                Expanded(child: _buildNumberButton('5', () => textInputAdd("5"))),
                Expanded(child: _buildNumberButton('6', () => textInputAdd("6"))),
                Expanded(child: _buildSpecialButton(',', Colors.orange, () => textInputAdd(","))),
              ],
            ),
          ),
          // Row 3: 1, 2, 3, Backspace
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(child: _buildNumberButton('1', () => textInputAdd("1"))),
                Expanded(child: _buildNumberButton('2', () => textInputAdd("2"))),
                Expanded(child: _buildNumberButton('3', () => textInputAdd("3"))),
                Expanded(
                    child: _buildIconButton(Icons.backspace, Colors.red.shade400, () {
                  if (textInputFormula.isNotEmpty) {
                    textInputFormula = textInputFormula.substring(0, textInputFormula.length - 1);
                    calcDiscount();
                  }
                })),
              ],
            ),
          ),
          // Row 4: 0, ., C
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(child: _buildNumberButton('0', () => textInputAdd("0"))),
                Expanded(
                    child: _buildNumberButton('.', () {
                  if (!textInputFormula.contains('.')) {
                    textInputAdd((textInputFormula.isNotEmpty) ? "." : "0.");
                  }
                  calcDiscount();
                })),
                Expanded(
                    child: _buildSpecialButton('C', Colors.grey.shade500, () {
                  textInputFormula = "";
                  calcDiscount();
                })),
                const Expanded(child: SizedBox()), // Empty space
              ],
            ),
          ),
          // Row 5: Cancel, OK (wider buttons)
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: _buildActionButton(
                    'ยกเลิก',
                    Colors.red.shade400,
                    Icons.close,
                    () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildActionButton(
                    'ตกลง',
                    Colors.green.shade400,
                    Icons.check,
                    () async {
                      var discountCalc = global.calcDiscount(amount: widget.amount, discountWord: textInputFormula);
                      if (discountCalc > widget.amount) {
                        setState(() {
                          isError = true;
                        });
                      } else {
                        setState(() {
                          isError = false;
                        });
                        Navigator.pop(context, textInputFormula);
                      }
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

  Widget _buildNumberButton(String text, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.7), color],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.7), color],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(4),
      height: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.8), color],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 600, maxWidth: 700),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.purple.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.discount, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'กรอกส่วนลด',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'ยอดเงิน: ${global.moneyFormat.format(widget.amount)} ฿',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Formula Input Display
            Container(
              height: 80,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade50, Colors.white],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16),
                    child: Text(
                      'สูตรส่วนลด',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          textInputFormula.isEmpty ? 'ใส่สูตรส่วนลด เช่น 10% หรือ 50' : textInputFormula,
                          style: TextStyle(
                            color: textInputFormula.isEmpty ? Colors.grey.shade400 : Colors.blue.shade700,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Discount Result Display
            Container(
              height: 80,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16),
                    child: Row(
                      children: [
                        Icon(Icons.savings, color: Colors.green.shade600, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'ยอดส่วนลด',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${global.moneyFormat.format(discountResult)} ฿',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Error Message
            if (isError)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "ไม่สามารถใส่สูตรที่ทำให้มูลค่าส่วนลดมากกว่ายอดเงินที่ต้องชำระได้",
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Number Pad
            Expanded(
              child: numberPad(),
            ),
          ],
        ),
      ),
    );
  }
}
