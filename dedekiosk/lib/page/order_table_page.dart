import 'package:dedekiosk/bloc/click_house_order_temp_table_bloc.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/model/global_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderTablePage extends StatefulWidget {
  const OrderTablePage({super.key});

  @override
  OrderTablePageState createState() => OrderTablePageState();
}

class OrderTablePageState extends State<OrderTablePage> {
  List<TableModel> tableList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    tableList.clear();
    for (var table in global.orderTagNumbers) {
      tableList.add(TableModel(table, 0));
    }
    context.read<ClickHouseOrderTempTableBloc>().add(ClickHouseOrderTempTableLoadStart());
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Get count of occupied tables
  int get _occupiedTableCount => tableList.where((t) => t.totalAmount > 0).length;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClickHouseOrderTempTableBloc, ClickHouseOrderTempTableState>(
        listener: (orderTempContext, orderTempState) {
          if (orderTempState is ClickHouseOrderTempTableLoadSuccess) {
            context.read<ClickHouseOrderTempTableBloc>().add(ClickHouseOrderTempTableLoadFinish());
            for (var order in orderTempState.clickHouseOrderTempTable) {
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
        child: SafeArea(
            child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E293B),
            title: Row(
              children: [
                const Icon(Icons.table_restaurant, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  global.language("โต๊ะ"),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () {
                Navigator.pop(context, OrderTempTableModel(ordertagnumber: "", totalamount: 0));
              },
            ),
            actions: [
              // Show occupied/total tables count
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "$_occupiedTableCount/${tableList.length}",
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF1F5F9),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6366F1),
                  ),
                )
              : _buildTableGrid(context),
        )));
  }

  Widget _buildTableGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int maxColumn = 4;
        if (constraints.maxWidth < 600) {
          maxColumn = 3;
        }
        if (constraints.maxWidth > 1000) {
          maxColumn = 5;
        }
        if (constraints.maxWidth > 1400) {
          maxColumn = 6;
        }

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
      },
    );
  }

  Widget _buildTableCard(TableModel table) {
    bool isOccupied = table.totalAmount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(
            context,
            OrderTempTableModel(
              ordertagnumber: table.tableNumber,
              totalamount: table.totalAmount,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOccupied ? const Color(0xFFFBBF24) : const Color(0xFFE2E8F0),
              width: isOccupied ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isOccupied ? const Color(0xFFFBBF24).withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
                blurRadius: isOccupied ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Table Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOccupied ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOccupied ? Icons.restaurant : Icons.table_restaurant,
                  size: 28,
                  color: isOccupied ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 12),
              // Table Number
              Text(
                table.tableNumber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              // Status or Amount
              if (isOccupied)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${global.moneyFormat.format(table.totalAmount)} ฿",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD97706),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "ว่าง",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
