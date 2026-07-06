import 'package:flutter/material.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:smlaicloud/model/bi_report/stock_balance_model.dart';
import 'package:smlaicloud/screens/report/dedebi/utils/report_utils.dart';

class StockBalanceTableView extends StatelessWidget {
  final List<StockBalanceModel> stockBalances;
  final String Function(double) formatCurrency;

  const StockBalanceTableView({
    super.key,
    required this.stockBalances,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Data table
        Expanded(
          child: _buildDataTable(),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    if (stockBalances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'ไม่พบข้อมูลยอดคงเหลือสินค้า',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ลองเปลี่ยนเงื่อนไขการค้นหาใหม่',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          _buildTableHeader(),
          // Table data
          Expanded(
            child: ListView.builder(
              itemCount: stockBalances.length,
              itemBuilder: (context, index) {
                return _buildTableRow(stockBalances[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.purple.shade200),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              'ข้อมูลสินค้า',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'เอกสารล่าสุด',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(
            child: Text(
              'จำนวนคงเหลือ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(
            child: Text(
              'ต้นทุนเฉลี่ย',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(
            child: Text(
              'มูลค่าคงเหลือ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(StockBalanceModel stockBalance, int index) {
    final isNegative = stockBalance.balanceQty < 0;
    final rowColor = index.isEven ? Colors.white : Colors.grey.shade50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rowColor,
        border: index < stockBalances.length - 1 ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null,
      ),
      child: Row(
        children: [
          // Product info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  global.activeLangName(stockBalance.names),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        stockBalance.barcode,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      global.activeLangName(stockBalance.unitNames),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Latest document
          Expanded(
            child: Column(
              children: [
                Text(
                  stockBalance.docNo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  ReportUtils.formatDate(stockBalance.docDate),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Balance quantity
          Expanded(
            child: Column(
              children: [
                Text(
                  stockBalance.balanceQty.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isNegative ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  global.activeLangName(stockBalance.unitNames),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Average cost
          Expanded(
            child: Text(
              stockBalance.averageCost != null ? formatCurrency(stockBalance.averageCost!) : '-',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Balance amount
          Expanded(
            child: Text(
              stockBalance.balanceAmount != null ? formatCurrency(stockBalance.balanceAmount!) : '-',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: stockBalance.balanceAmount != null && stockBalance.balanceAmount! < 0 ? Colors.red.shade700 : Colors.purple.shade700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
