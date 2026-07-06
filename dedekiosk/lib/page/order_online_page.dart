import 'package:dedekiosk/app_constant.dart';
import 'package:dedekiosk/bloc/click_house_order_temp_table_bloc.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/util/logger.dart';
import 'package:dedekiosk/util/print_queue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class OrderOnlinePage extends StatefulWidget {
  const OrderOnlinePage({super.key});

  @override
  OrderOnlinePageState createState() => OrderOnlinePageState();
}

class OrderOnlinePageState extends State<OrderOnlinePage> {
  List<TableModel> tableList = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    tableList.clear();
    for (var table in global.orderTagNumbers) {
      tableList.add(TableModel(table, 0));
    }
    context.read<ClickHouseOrderTempTableBloc>().add(ClickHouseOrderTempTableLoadStart());
  }

  int get _occupiedTableCount => tableList.where((t) => t.totalAmount > 0).length;

  Future<void> _onTableTapped(TableModel table) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.qr_code_2, color: Color(0xFF6366F1), size: 28),
            const SizedBox(width: 10),
            const Text(
              "เปิดโต๊ะ Order Online",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.table_restaurant, size: 48, color: Color(0xFF6366F1)),
                  const SizedBox(height: 8),
                  Text(
                    "โต๊ะ ${table.tableNumber}",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "ระบบจะสร้าง QR Code และพิมพ์ใบเปิดโต๊ะ\nเพื่อให้ลูกค้าสแกนสั่งอาหารจากมือถือ",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("ยกเลิก", style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.print, size: 18),
            label: const Text("ยืนยัน / พิมพ์"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);

    try {
      final uuid = const Uuid().v4();
      final now = DateTime.now();
      final qrUrl = "${AppConstant.orderOnlineUrl}/?uuid=$uuid";

      // ✅ Log printer config ก่อนพิมพ์เพื่อ debug
      final printerConfig = global.deviceConfig.printerForOwner;
      Logger.i('📋 Open table: table=${table.tableNumber}, uuid=$uuid', tag: 'OrderOnline');
      Logger.i('🖨️ Printer config: connectType=${printerConfig.printerConnectType}, ip=${printerConfig.ipAddress}:${printerConfig.ipPort}, vendorId=${printerConfig.vendorId}', tag: 'OrderOnline');

      // INSERT session เข้า ClickHouse
      await api.insertOrderTableSession(
        uuid: uuid,
        tableNumber: table.tableNumber,
      );
      Logger.i('✅ ClickHouse session inserted successfully', tag: 'OrderOnline');

      // เพิ่มงานพิมพ์ใบเปิดโต๊ะเข้า print queue (printType=2)
      global.printQueue.add(PrintTicketClass(
        docDate: now,
        docNumber: "OPEN_TABLE_${table.tableNumber}_${now.millisecondsSinceEpoch}",
        orderTagNumber: table.tableNumber,
        orderId: uuid,
        printType: 2,
        printLogo: false,
        printHeader: false,
        orderType: 0,
        queueNumber: 0,
        footer: "",
        saveToFile: false,
        openCashDrawer: false,
        orderList: [],
        orderTempDetails: [],
        printerLocalConfig: printerConfig,
        payResult: PayResultModel(),
        qrCode: qrUrl,
      ));
      Logger.i('📝 Added to print queue (printType=2, queueSize=${global.printQueue.length})', tag: 'OrderOnline');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เปิดโต๊ะ ${table.tableNumber} สำเร็จ — กำลังพิมพ์ใบ QR"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClickHouseOrderTempTableBloc, ClickHouseOrderTempTableState>(
      listener: (_, state) {
        if (state is ClickHouseOrderTempTableLoadSuccess) {
          context.read<ClickHouseOrderTempTableBloc>().add(ClickHouseOrderTempTableLoadFinish());
          for (var order in state.clickHouseOrderTempTable) {
            if (order.totalamount != 0) {
              for (var table in tableList) {
                if (table.tableNumber == order.ordertagnumber) {
                  table.totalAmount = order.totalamount;
                  break;
                }
              }
            }
          }
          _isLoading = false;
          if (mounted) setState(() {});
        }
      },
      child: Stack(
        children: [
          SafeArea(
            child: Scaffold(
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E293B),
                title: const Row(
                  children: [
                    Icon(Icons.qr_code_2, color: Color(0xFF6366F1)),
                    SizedBox(width: 8),
                    Text(
                      "Order Online — เลือกโต๊ะ",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              backgroundColor: const Color(0xFFF1F5F9),
              body: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))) : _buildTableGrid(),
            ),
          ),
          // Overlay loading เมื่อกำลังบันทึก/พิมพ์
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF6366F1)),
                        SizedBox(height: 16),
                        Text("กำลังบันทึกและพิมพ์...", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      int maxColumn = 4;
      if (constraints.maxWidth < 600) maxColumn = 3;
      if (constraints.maxWidth > 1000) maxColumn = 5;
      if (constraints.maxWidth > 1400) maxColumn = 6;

      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: maxColumn,
            childAspectRatio: 1.0,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 12.0,
          ),
          itemCount: tableList.length,
          itemBuilder: (context, index) => _buildTableCard(tableList[index]),
        ),
      );
    });
  }

  Widget _buildTableCard(TableModel table) {
    bool isOccupied = table.totalAmount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSaving ? null : () => _onTableTapped(table),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOccupied ? const Color(0xFFFBBF24) : const Color(0xFF6366F1),
              width: isOccupied ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isOccupied ? const Color(0xFFFBBF24).withValues(alpha: 0.2) : const Color(0xFF6366F1).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOccupied ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_2,
                  size: 28,
                  color: isOccupied ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                table.tableNumber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              if (isOccupied)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${global.moneyFormat.format(table.totalAmount)} ฿",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "กด เปิด QR",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
