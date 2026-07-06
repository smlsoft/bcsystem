import 'package:dedecashier/db/table_process_helper.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:intl/intl.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

// ⭐ Theme Colors: MARINEPOS = น้ำเงินเข้ม, อื่นๆ = อิฐบ้านเชียง (Terracotta)
final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);
final List<Color> _themeGradient = (F.appFlavor == Flavor.MARINEPOS) ? [const Color(0xFF005598), const Color(0xFF003366)] : [const Color(0xFFD18D52), const Color(0xFF9A5518)];

class PosHoldBill extends StatefulWidget {
  final int holdType;

  const PosHoldBill({super.key, required this.holdType});

  @override
  State<PosHoldBill> createState() => _PosHoldBillState();
}

class _PosHoldBillState extends State<PosHoldBill> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    for (int index = 0; index < global.posHoldProcessResult.length; index++) {
      global.posLogHelper.holdCount(global.posHoldProcessResult[index].code).then((value) {
        global.posHoldProcessResult[index].logCount = value;
      });
    }
  }

  Widget holdBillContent() {
    List<PosHoldProcessModel> holds = [];
    if (widget.holdType == 1) {
      // ระบบ POS
      for (int index = 0; index < global.posHoldProcessResult.length; index++) {
        if (global.posHoldProcessResult[index].holdType == widget.holdType) {
          holds.add(global.posHoldProcessResult[index]);
        }
      }
    }
    if (widget.holdType == 2) {
      if (global.tempIsRestaurantSystem == true) {
        // ระบบร้านอาหาร
        List<TableProcessObjectBoxStruct> tableInfo = TableProcessHelper().getAll();
        for (var table in tableInfo) {
          if (table.table_status == 2) {
            PosHoldProcessModel hold = PosHoldProcessModel(code: "T-${table.number}", tableNumber: table.number);
            hold.holdType = 2;
            hold.isDelivery = table.is_delivery;
            hold.deliveryNumber = table.delivery_number;
            hold.detailDiscountFormula = table.detail_discount_formula;
            holds.add(hold);
          }
        }
      }
    }

    return holds.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(50)),
                  child: Icon((widget.holdType == 1) ? Icons.receipt_long_outlined : Icons.table_restaurant_outlined, size: 64, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 24),
                Text(
                  (widget.holdType == 1) ? 'ยังไม่มีบิลที่พักไว้' : 'ยังไม่มีโต๊ะที่เปิดใช้งาน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  (widget.holdType == 1) ? 'สร้างการขายใหม่แล้วพักบิลเพื่อดูรายการที่นี่' : 'เปิดโต๊ะใหม่เพื่อดูรายการที่นี่',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: MediaQuery.of(context).size.width > 600 ? 300 : 250,
              childAspectRatio: MediaQuery.of(context).size.width > 600 ? 3 / 2.2 : 3 / 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: holds.length,
            itemBuilder: (BuildContext ctx, index) {
              return holdButton(holds[index]);
            },
          );
  }

  Widget holdButton(PosHoldProcessModel hold) {
    Color primaryColor;
    Color accentColor;
    IconData statusIcon;

    AppLogger.debug("hold : ${hold.code} : ${hold.logCount}");
    for (var i = 0; i < global.posHoldProcessResult.length; i++) {
      AppLogger.debug("global.posHoldProcessResult[$i] : ${global.posHoldProcessResult[i].code} : ${global.posHoldProcessResult[i].logCount}");
    }
    {
      // test
      List<TableProcessObjectBoxStruct> tableInfo = global.objectBoxStore.box<TableProcessObjectBoxStruct>().query().build().find();
      for (var table in tableInfo) {
        AppLogger.debug("table : ${table.number} : ${table.table_status}");
      }
    }

    int index = global.findPosHoldProcessResultIndex(hold.code);
    if (index != -1) {
      if (global.posHoldProcessResult[index].logCount != 0) {
        primaryColor = Colors.orange;
        accentColor = Colors.orange.shade700;
        statusIcon = Icons.shopping_cart;
      } else {
        primaryColor = Colors.green;
        accentColor = Colors.green.shade700;
        statusIcon = Icons.check_circle_outline;
      }
    } else {
      primaryColor = Colors.red;
      accentColor = Colors.red.shade700;
      statusIcon = Icons.error_outline;
    }

    Widget tableStatus = Container();
    if (widget.holdType == 1) {
      // POS
      int holdIndex = global.findPosHoldProcessResultIndex(hold.code);
      tableStatus = Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              (global.posHoldProcessResult[holdIndex].logCount == 0)
                  ? global.language("blank")
                  : "${global.language('qty')} ${global.posHoldProcessResult[holdIndex].logCount} ${global.language("รายการ")}",
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (widget.holdType == 2) {
      // ร้านอาหาร
      TableProcessObjectBoxStruct? tableInfo = global.objectBoxStore
          .box<TableProcessObjectBoxStruct>()
          .query(TableProcessObjectBoxStruct_.number.equals(hold.code.replaceAll("T-", "")))
          .build()
          .findFirst();
      String orderType = "";
      if (tableInfo != null) {
        if (tableInfo.table_al_la_crate_mode) {
          orderType = global.language("อาราคัส");
        } else {
          int findBuffetIndex = global.findBuffetModeIndex(tableInfo.buffet_code);
          if (findBuffetIndex != -1) {
            orderType = global.buffetModeLists[findBuffetIndex].names[0];
          }
        }
      }

      tableStatus = (tableInfo != null)
          ? Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (tableInfo.is_delivery)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delivery_dining, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          global.language("สั่งกลับบ้าน"),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  _buildInfoRow("ประเภท", orderType),
                  if (tableInfo.man_count != 0) _buildInfoRow("ผู้ชาย", "${global.moneyFormat.format(tableInfo.man_count.toDouble())} คน"),
                  if (tableInfo.woman_count != 0) _buildInfoRow("ผู้หญิง", "${global.moneyFormat.format(tableInfo.woman_count.toDouble())} คน"),
                  if (tableInfo.child_count != 0) _buildInfoRow("เด็ก", "${global.moneyFormat.format(tableInfo.child_count.toDouble())} คน"),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(DateFormat('dd/MM HH:mm').format(tableInfo.table_open_datetime), style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            )
          : Container();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            global.playSound(sound: global.SoundEnum.buttonTing);
            HapticFeedback.lightImpact();
            Navigator.pop(context, hold);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primaryColor, accentColor]),
            ),
            child: Column(
              children: [
                // Header section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon((widget.holdType == 1) ? Icons.receipt : Icons.table_restaurant, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          (hold.isDelivery)
                              ? hold.deliveryNumber
                              : (hold.code.contains("T-"))
                              ? "${global.language("โต๊ะ")} ${hold.code.replaceAll("T-", "")}"
                              : "${global.language("พักบิล")} ${hold.code}",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content section
                Expanded(child: Center(child: tableStatus)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("${global.language(label)}: ", style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
        backgroundColor: _themeColor,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _themeGradient),
          ),
        ),
        title: Text(
          (widget.holdType == 1) ? global.language("pos_hold_bill") : global.language("pos_hold_table"),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 6.0, color: Colors.black45, offset: Offset(1.0, 1.0))],
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () {
            global.playSound(sound: global.SoundEnum.buttonTing);
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.grey.shade50, Colors.grey.shade100]),
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: holdBillContent()),
      ),
    );
  }
}
