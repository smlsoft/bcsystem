import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/objectbox/objectbox.g.dart';
import 'package:dedekiosk/order/order_save.dart';
import 'package:dedekiosk/order/pay_page.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/util/logger.dart';
import 'package:dedekiosk/widget/network_loading_indicator.dart';
import 'package:uuid/uuid.dart';

/// หน้า Cashier รับชำระจาก QR / doc no
///
/// Staff device (machineCondition==0) เปิดหน้านี้จาก order_select_page
/// - พิมพ์ doc no ใน TextField หรือ
/// - สแกน QR ผ่าน hardware barcode scanner
///
/// พอได้ doc no / QR payload → query ordertempdocpaylater WHERE ordernumber=...
/// → แสดงรายการ + ยอด → ปุ่ม "รับชำระ" → เปิด PayPage → หลังจ่ายเสร็จ flip ledger + migration
class CashierScanPage extends StatefulWidget {
  const CashierScanPage({super.key});

  @override
  State<CashierScanPage> createState() => _CashierScanPageState();
}

class _CashierScanPageState extends State<CashierScanPage> {
  final TextEditingController _docNoController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _foundBill;
  String? _errorMessage;

  @override
  void dispose() {
    _docNoController.dispose();
    super.dispose();
  }

  /// ค้นหา pending bill จาก doc no หรือ QR payload
  Future<void> _lookupBill(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foundBill = null;
    });

    try {
      String stubId;
      String? expectedAmount;

      // ถ้าเป็น QR payload (JSON) ให้ parse เอา stubid + amount
      if (trimmed.startsWith('{')) {
        try {
          final payload = jsonDecode(trimmed) as Map<String, dynamic>;
          stubId = payload['stubid'] as String? ?? '';
          expectedAmount = payload['amount']?.toString();
          if (stubId.isEmpty) {
            setState(() {
              _isLoading = false;
              _errorMessage = "QR ไม่ถูกต้อง: ไม่พบ stubid";
            });
            return;
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
            _errorMessage = "QR format ไม่ถูกต้อง";
          });
          return;
        }
      } else {
        // พิมพ์ stubId เปล่าๆ (cashier อาจจำแค่ท้าย 8 ตัว — reconstruct full stubId)
        // ถ้า input สั้น ให้ค้นด้วย LIKE
        stubId = trimmed;
      }

      Logger.i('CashierScan: looking up stubId=$stubId', tag: 'CashierScan');

      // ถ้า input สั้น (8 ตัวท้ายที่พิมพ์ใน slip) ให้ค้นด้วย LIKE
      Map<String, dynamic>? orderData;
      if (stubId.length < 20) {
        // ค้นด้วย suffix
        final shopId = global.deviceConfig.shopId;
        final branchId = global.deviceConfig.branchId;
        final db = global.clickHouseDatabaseName;
        final escapedSuffix = stubId.replaceAll("'", "''");
        final suffixQuery =
            "SELECT ordernumber FROM $db.ordertempdocpaylater WHERE shopid='$shopId' AND branchid='$branchId' AND orderpaysuccess=0 AND ordernumber LIKE '%$escapedSuffix' ORDER BY orderdatetime DESC LIMIT 1";
        final suffixResult = await api.clickHouseSelect(suffixQuery);
        final suffixData = suffixResult['data'] as List<dynamic>?;
        if (suffixData != null && suffixData.isNotEmpty) {
          final fullStubId =
              (suffixData[0] as Map<String, dynamic>)['ordernumber'].toString();
          orderData = await api.loadCashierStub(stubId: fullStubId);
        }
      } else {
        orderData = await api.loadCashierStub(stubId: stubId);
      }

      if (orderData == null) {
        // ตรวจว่าเคยมี stub นี้ถูก settle แล้วหรือไม่ (แยก "จ่ายแล้ว" จาก "ไม่มีอยู่")
        final alreadySettled =
            await api.isCashierStubAlreadySettled(stubId: stubId);
        setState(() {
          _isLoading = false;
          _errorMessage = alreadySettled
              ? "รายการนี้ถูกรับชำระแล้ว (stub: $stubId)"
              : "ไม่พบรายการรอชำระสำหรับรหัส $stubId";
        });
        return;
      }

      final doc = orderData['doc'] as Map<String, dynamic>;
      // ถ้ามี expectedAmount จาก QR ตรวจความตรง (advisory only)
      if (expectedAmount != null) {
        final billAmount = double.tryParse(doc['totalamount'].toString()) ?? -1;
        final expected = double.tryParse(expectedAmount) ?? -2;
        if (billAmount != expected) {
          Logger.w(
              'CashierScan: amount mismatch bill=$billAmount expected=$expected',
              tag: 'CashierScan');
        }
      }

      setState(() {
        _isLoading = false;
        _foundBill =
            doc; // header row (มี orderid, ordertagnumber, totalamount, ordernumber=stubId)
        _docNoController.clear();
      });
    } catch (e, s) {
      Logger.e('CashierScan lookup error', error: e, stackTrace: s);
      setState(() {
        _isLoading = false;
        _errorMessage = "เกิดข้อผิดพลาดในการค้นหา: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รับชำระจาก QR / เลขที่บิล"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BarcodeKeyboardListener(
        bufferDuration: const Duration(milliseconds: 200),
        onBarcodeScanned: (barcode) {
          // hardware scanner สแกน QR/docno แล้วค้นหาเลย
          _lookupBill(barcode);
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ช่องพิมพ์ doc no
                TextField(
                  controller: _docNoController,
                  decoration: InputDecoration(
                    labelText: "เลขที่บิล / สแกน QR",
                    hintText: "เช่น 001-250705-0001",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () => _lookupBill(_docNoController.text),
                          ),
                  ),
                  onSubmitted: (value) => _lookupBill(value),
                  textInputAction: TextInputAction.search,
                ),
                const SizedBox(height: 8),
                Text(
                  "💡 พิมพ์เลขที่บิล หรือสแกน QR จากใบแจ้งยอด",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: TextStyle(color: Colors.red.shade700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // แสดง bill ที่เจอ
                if (_foundBill != null) ...[
                  Expanded(
                    child: _BillDetailCard(
                      bill: _foundBill!,
                      onReceivePayment: () => _receivePayment(_foundBill!),
                    ),
                  ),
                ] else if (!_isLoading) ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            "ยังไม่มีรายการที่ค้นหา",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// เมื่อ cashier กดรับชำระ — SETTLE FLOW (เข้า logic สั่งเต็มรูปแบบผ่าน payAndSave):
  /// 1. Load cart snapshot จาก paylater (loadCashierStub)
  /// 2. เปิด PayPage (รับเงิน)
  /// 3. หลังจ่าย: setup globals + INSERT cart ลง ObjectBox + reserve stock + deleteCashierStub
  /// 4. เรียก payAndSave(payNow: true) — มัน terminal (backToHome เอง + ทำ stock commit/kitchen/saveTransaction/receipt)
  Future<void> _receivePayment(Map<String, dynamic> bill) async {
    final stubId = bill['ordernumber']?.toString() ?? '';
    final orderTagNumber = bill['ordertagnumber']?.toString() ?? '';
    final totalAmount =
        double.tryParse(bill['totalamount']?.toString() ?? '0') ?? 0;

    Logger.i('CashierScan: receive payment stubId=$stubId amount=$totalAmount',
        tag: 'CashierScan');

    // ===== STEP 1: Load cart snapshot จาก paylater =====
    if (context.mounted) {
      NetworkLoadingOverlay.show(context, message: "กำลังโหลดรายการ...");
    }
    Map<String, dynamic>? orderData;
    try {
      orderData = await api.loadCashierStub(stubId: stubId);
    } catch (e, s) {
      Logger.e('CashierScan load stub error', error: e, stackTrace: s);
    }
    if (!mounted) return;
    NetworkLoadingOverlay.hide(context);

    if (orderData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "โหลดรายการไม่สำเร็จ (stub=$stubId) — อาจถูก settle แล้ว")),
      );
      setState(() => _foundBill = null);
      return;
    }

    final details = orderData['details'] as List<OrderTempDetailModel>;
    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("รายการว่าง ไม่สามารถรับชำระได้")),
      );
      return;
    }

    // stubMode: 0 = โหมด A (ส่งครัวหลัง settle), 2 = โหมด B (ส่งครัวทันที — stock ถูก reserve แล้ว)
    final int stubMode = (orderData['stubMode'] as int?) ?? 0;
    final bool modeSendKitchenNow = (stubMode == 2);
    final String originOrderId =
        (orderData['doc'] as Map<String, dynamic>)['orderid']?.toString() ?? '';

    // ===== STEP 2: เปิด PayPage (รับเงิน) =====
    global.payCondition = [];
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PayPage(
          context: ctx,
          amount: totalAmount,
          orderTagNumber: orderTagNumber,
        ),
      ),
    );

    // user cancel → payCondition ว่าง
    if (global.payCondition.isEmpty) {
      Logger.d('CashierScan: user cancelled payment', tag: 'CashierScan');
      setState(() => _foundBill = null);
      return;
    }

    // ===== STEP 3: Setup globals + INSERT ObjectBox + reserve stock + delete stub =====
    // สร้าง orderId ใหม่สำหรับ order นี้ (cashier device เป็น origin ของ order จริง)
    final newOrderId = const Uuid().v4();
    global.orderId = newOrderId;
    global.tableNumberSelected = OrderTempTableModel(
        ordertagnumber: orderTagNumber, totalamount: totalAmount);
    global.orderType = 1; // ordered by staff (cashier)
    global.isTakeAway =
        int.tryParse(bill['istakeaway']?.toString() ?? '0') ?? 0;
    if ((bill['salechannelcode']?.toString() ?? '').isNotEmpty) {
      global.saleChannelCode = bill['salechannelcode'].toString();
    }

    // Wipe + INSERT cart ลง ObjectBox (เหมือน gotoOrderByQrcode pattern)
    global.objectBoxStore.box<OrderTempObjectBoxModel>().removeAll();
    for (final item in details) {
      global.objectBoxStore.box<OrderTempObjectBoxModel>().put(
            OrderTempObjectBoxModel(
              orderid: newOrderId,
              orderguid: item.orderguid,
              barcode: item.barcode,
              qty: item.qty,
              optionamount: item.optionamount ?? 0,
              discountamount: item.discountamount ?? 0,
              optionselected: item.optionselected,
              salechannelcode: item.salechannelcode,
              remark: item.remark,
              orderdatetime: item.orderdatetime,
              price: item.price,
              amount: item.amount,
              istakeaway: item.istakeaway,
              queuenumber: item.queuenumber,
              manufacturerguid: item.manufacturerguid,
              isexceptvat: item.is_except_vat,
            ),
            mode: PutMode.insert,
          );
    }

    // Reserve stock ตามโหมด:
    // โหมด A (stubMode=0): stock ถูก release ตอนสร้าง stub → reserve ใหม่ด้วย newOrderId
    // โหมด B (stubMode=2): stock ถูก reserve ใน originOrderId ตอนสั่ง
    //   → ไม่สามารถ UPDATE orderid ได้ (orderid เป็น key column ของ ClickHouse)
    //   → ต้อง release เก่า + reserve ใหม่ (เหมือนโหมด A)
    try {
      if (modeSendKitchenNow && originOrderId.isNotEmpty) {
        await api.releaseCartStock(orderId: originOrderId);
      }
      await api.reserveCartStock(orderId: newOrderId, items: details);
    } catch (e) {
      Logger.w('CashierScan: stock reservation failed (continuing): $e',
          tag: 'CashierScan');
    }

    // Consume stub (delete paylater rows) — ทำก่อน payAndSave เพื่อกัน double-settle
    // ถ้า payAndSave fail ข้อมูล stub หาย แต่ PayPage ผ่าน = ได้เงินแล้ว = ต้องมี order
    // (recovery: ดู log + manual reconcile)
    try {
      await api.deleteCashierStub(stubId: stubId);
    } catch (e) {
      Logger.w('CashierScan: deleteCashierStub failed: $e', tag: 'CashierScan');
    }

    // ===== STEP 4: เรียก payAndSave(payNow: true) — เข้า logic สั่งเต็มรูปแบบ =====
    // มันจะ: reserve doc no, commit stock, ส่งครัว, saveTransaction, พิมพ์ใบเสร็จ, backToHome
    // สร้าง BillCalcAmount จากข้อมูล stub (payAndSave ต้องการ bill object)
    final billCalc = BillCalcAmount();
    billCalc.totalAmount = totalAmount;
    billCalc.totalVatAmount =
        double.tryParse(bill['vatamount']?.toString() ?? '0') ?? 0;
    billCalc.totalDiscount =
        double.tryParse(bill['discountamount']?.toString() ?? '0') ?? 0;

    // เรียก payAndSave (มัน terminal — กลับ home เอง)
    await payAndSave(
      totalAmount: totalAmount,
      vatAmount: billCalc.totalVatAmount,
      saveAmount: 0,
      discountAmount: billCalc.totalDiscount,
      discountWord: bill['discountword']?.toString() ?? '',
      diffAmount: 0,
      orderTagNumber: orderTagNumber,
      context: context,
      payNow: true,
      orderTempDetailList: details,
      bill: billCalc,
    );
    // payAndSave เป็น terminal — หลังจากนี้ context อาจไม่ valid แล้ว (backToHome แล้ว)
  }
}

/// Card แสดงรายละเอียด bill ที่ค้นพบ + ปุ่มรับชำระ
class _BillDetailCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final VoidCallback onReceivePayment;

  const _BillDetailCard({required this.bill, required this.onReceivePayment});

  @override
  Widget build(BuildContext context) {
    final docNo = bill['ordernumber']?.toString() ?? '';
    final orderTagNumber = bill['ordertagnumber']?.toString() ?? '';
    final totalAmount =
        double.tryParse(bill['totalamount']?.toString() ?? '0') ?? 0;
    final vatAmount =
        double.tryParse(bill['vatamount']?.toString() ?? '0') ?? 0;
    final discountAmount =
        double.tryParse(bill['discountamount']?.toString() ?? '0') ?? 0;
    final queueNumber = bill['queuenumber']?.toString() ?? '';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.orange, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "รายการรอชำระ",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _InfoRow(label: "เลขที่", value: docNo, bold: true),
            if (orderTagNumber.isNotEmpty)
              _InfoRow(label: "โต๊ะ/ป้าย", value: orderTagNumber),
            if (queueNumber.isNotEmpty)
              _InfoRow(label: "คิวที่", value: queueNumber),
            _InfoRow(
                label: "ส่วนลด",
                value: "${global.moneyFormat.format(discountAmount)} บาท"),
            _InfoRow(
                label: "VAT",
                value: "${global.moneyFormat.format(vatAmount)} บาท"),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("ยอดรวมชำระ",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    "${global.moneyFormat.format(totalAmount)} บาท",
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: onReceivePayment,
              icon: const Icon(Icons.payment),
              label: const Text("รับชำระเงิน",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _InfoRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
