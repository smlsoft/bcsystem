import 'package:dedecashier/util/print_hold_bill.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/widgets/discount_pad.dart';

/// Widget สำหรับแสดงแผงยอดรวมและปุ่มชำระเงิน
/// แยกออกจาก pos_screen.dart เพื่อลดขนาดไฟล์และเพิ่มความสามารถในการ maintain
class PosTotalPayPanel extends StatelessWidget {
  final global.PosScreenModeEnum posScreenMode;
  final String posHoldActiveCode;
  final bool tableSelected;
  final String tableNumberSelected;
  final dynamic tableProcessSelected; // nullable เพื่อรองรับกรณียังไม่ initialize
  final VoidCallback onPayScreenCash;
  final VoidCallback onPayScreenQR;
  final VoidCallback onPayScreenCredit;
  final VoidCallback onHoldBillTable;
  final Function(String) onBillDiscountChange;

  const PosTotalPayPanel({
    super.key,
    required this.posScreenMode,
    required this.posHoldActiveCode,
    required this.tableSelected,
    required this.tableNumberSelected,
    this.tableProcessSelected, // ไม่ required เพราะอาจยังไม่มี
    required this.onPayScreenCash,
    required this.onPayScreenQR,
    required this.onPayScreenCredit,
    required this.onHoldBillTable,
    required this.onBillDiscountChange,
  });

  @override
  Widget build(BuildContext context) {
    final int holdIndex = global.findPosHoldProcessResultIndex(posHoldActiveCode);
    final double totalAmount = global.posHoldProcessResult[holdIndex].posProcess.total_amount;

    List<Widget> iconMenu = [];

    // ปุ่มส่วนลด
    iconMenu.add(
      _buildIconButton(
        context: context,
        icon: Icons.discount,
        color: Colors.orange.shade600,
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                    contentPadding: const EdgeInsets.all(10),
                    content: SizedBox(
                      height: 500,
                      child: DiscountPad(
                        header: global.language("discount"),
                        title: Text(global.language("discount_last_bill"), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        onChange: onBillDiscountChange,
                        discount: global.discountFormular,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        tooltip: global.language("discount"),
      ),
    );

    if (posScreenMode == global.PosScreenModeEnum.posSale) {
      // ปุ่มบัตรเครดิต
      iconMenu.add(
        _buildIconButton(
          context: context,
          icon: FontAwesomeIcons.creditCard,
          color: Colors.blue.shade600,
          onPressed: (totalAmount <= 0) ? null : onPayScreenCredit,
          tooltip: global.language("credit_card"),
        ),
      );

      // ปุ่ม QR Code
      iconMenu.add(_buildIconButton(context: context, icon: Icons.qr_code, color: Colors.green.shade600, onPressed: (totalAmount <= 0) ? null : onPayScreenQR, tooltip: global.language("qr_payment")));
    }

    // ปุ่มพิมพ์
    iconMenu.add(
      _buildIconButton(
        context: context,
        icon: Icons.print,
        color: Colors.purple.shade600,
        onPressed: (totalAmount <= 0)
            ? null
            : () async {
                printHoldBill(context: context, holdNumber: posHoldActiveCode);
              },
        tooltip: global.language("print"),
      ),
    );

    if (global.posVersion == global.PosVersionEnum.restaurant && posScreenMode == global.PosScreenModeEnum.posSale) {
      // ปุ่มโต๊ะ
      iconMenu.add(_buildIconButton(context: context, icon: Icons.table_restaurant, color: Colors.brown.shade600, onPressed: onHoldBillTable, tooltip: global.language("table")));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // แสดงหมายเลขบิลหรือโต๊ะ
          if (posHoldActiveCode != "0")
            Container(
              height: 70,
              margin: const EdgeInsets.only(right: 3),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: (tableSelected) ? [Colors.red.shade400, Colors.red.shade600] : [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: (tableSelected ? Colors.red : Colors.orange).withOpacity(0.2), blurRadius: 3, offset: const Offset(0, 1))],
              ),
              child: Center(
                child: Text(
                  (tableSelected && tableProcessSelected != null)
                      ? (tableProcessSelected.isDelivery)
                            ? "${global.language("กลับบ้าน")} : ${tableProcessSelected.deliveryNumber}"
                            : "${global.language("โต๊ะ")} : $tableNumberSelected"
                      : posHoldActiveCode.toString(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),

          // ปุ่มรวมเงิน - ขยายให้ใหญ่ขึ้น
          Expanded(
            flex: 4,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    global.playSound(sound: global.SoundEnum.buttonTing);
                    if (totalAmount > 0) {
                      onPayScreenCash();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          global.language("total"),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              global.moneyFormat.format(totalAmount),
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          global.language("money_symbol"),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ปุ่มไอคอนต่างๆ - กระชับขึ้น
          const SizedBox(width: 4),
          Row(mainAxisSize: MainAxisSize.min, children: iconMenu),
        ],
      ),
    );
  }

  /// Helper method สำหรับสร้างปุ่มไอคอน
  Widget _buildIconButton({required BuildContext context, required IconData icon, required VoidCallback? onPressed, required Color color, String? tooltip, bool isPrimary = false}) {
    return Container(
      width: 50,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Material(
        color: isPrimary ? color : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed == null
              ? null
              : () {
                  global.playSound(sound: global.SoundEnum.buttonTing);
                  onPressed();
                },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isPrimary ? Colors.transparent : color.withOpacity(0.25), width: 1),
            ),
            child: Icon(icon, size: 18, color: isPrimary ? Colors.white : color),
          ),
        ),
      ),
    );
  }
}
