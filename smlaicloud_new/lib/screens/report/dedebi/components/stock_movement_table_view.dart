import 'package:flutter/material.dart';
import 'package:smlaicloud/model/bi_report/stock_movment_model.dart';
import 'package:smlaicloud/screens/report/dedebi/utils/report_utils.dart';

class StockMovementTableView extends StatelessWidget {
  final List<StockMovementModel> data;
  final Function(StockMovementModel)? onRowTap;

  const StockMovementTableView({
    super.key,
    required this.data,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'ไม่มีข้อมูลที่จะแสดง',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: _buildHeaderRow(),
        ),
        // Data Rows
        Expanded(
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) => _buildDataRow(data[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildHeaderCell('วันที่'),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('เลขที่เอกสาร'),
        ),
        Expanded(
          flex: 1,
          child: _buildHeaderCell('ประเภท', TextAlign.center),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('ยอดเข้า', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('ราคาเข้า', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('มูลค่าเข้า', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('ยอดออก', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('ราคาออก', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('มูลค่าออก', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('ยอดคงเหลือ', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('ราคาเฉลี่ย', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('มูลค่าคงเหลือ', TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, [TextAlign? textAlign]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.indigo.shade700,
        ),
        textAlign: textAlign ?? TextAlign.left,
      ),
    );
  }

  Widget _buildDataRow(StockMovementModel stockMovement, int index) {
    final isEven = index % 2 == 0;
    final backgroundColor = isEven ? Colors.white : Colors.grey.shade50;

    return InkWell(
      onTap: () {
        try {
          onRowTap?.call(stockMovement);
        } catch (e) {
          debugPrint('Error in stock movement row tap: $e');
        }
      },
      hoverColor: Colors.indigo.shade50,
      highlightColor: Colors.indigo.shade100,
      splashColor: Colors.indigo.shade200,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // วันที่
            Expanded(
              flex: 2,
              child: _buildDataCell(
                ReportUtils.formatDate(stockMovement.docdate),
                fontSize: 11,
              ),
            ),
            // เลขที่เอกสาร
            Expanded(
              flex: 2,
              child: _buildDataCell(
                stockMovement.docno,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade700,
              ),
            ),
            // ประเภท
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTransactionFlagColor(stockMovement.transFlag),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTransactionFlagText(stockMovement.transFlag),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _getTransactionFlagTextColor(stockMovement.transFlag),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // ยอดเข้า
            Expanded(
              flex: 2,
              child: _buildDataCell(
                stockMovement.qtyIn > 0 ? stockMovement.qtyIn.toStringAsFixed(2) : '-',
                textAlign: TextAlign.right,
                color: stockMovement.qtyIn > 0 ? Colors.green.shade700 : Colors.grey.shade500,
                fontWeight: stockMovement.qtyIn > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // ราคาเข้า
            Expanded(
              flex: 2,
              child: _buildDataCell(
                stockMovement.averageCostIn > 0 ? ReportUtils.formatCurrencySafe(stockMovement.averageCostIn) : '-',
                textAlign: TextAlign.right,
                color: stockMovement.averageCostIn > 0 ? Colors.green.shade600 : Colors.grey.shade500,
              ),
            ),
            // มูลค่าเข้า
            Expanded(
              flex: 2,
              child: _buildDataCell(
                stockMovement.balanceIn > 0 ? ReportUtils.formatCurrencySafe(stockMovement.balanceIn) : '-',
                textAlign: TextAlign.right,
                color: stockMovement.balanceIn > 0 ? Colors.green.shade700 : Colors.grey.shade500,
                fontWeight: stockMovement.balanceIn > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // ยอดออก
            Expanded(
              flex: 2,
              child: _buildDataCell(
                stockMovement.qtyOut > 0 ? stockMovement.qtyOut.toStringAsFixed(2) : '-',
                textAlign: TextAlign.right,
                color: stockMovement.qtyOut > 0 ? Colors.red.shade700 : Colors.grey.shade500,
                fontWeight: stockMovement.qtyOut > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // ราคาออก
            Expanded(
              flex: 2,
              child: _buildDataCell(
                stockMovement.averageCostOut > 0 ? ReportUtils.formatCurrencySafe(stockMovement.averageCostOut) : '-',
                textAlign: TextAlign.right,
                color: stockMovement.averageCostOut > 0 ? Colors.red.shade600 : Colors.grey.shade500,
              ),
            ),
            // มูลค่าออก
            Expanded(
              flex: 2,
              child: _buildDataCell(
                stockMovement.balanceOut > 0 ? ReportUtils.formatCurrencySafe(stockMovement.balanceOut) : '-',
                textAlign: TextAlign.right,
                color: stockMovement.balanceOut > 0 ? Colors.red.shade700 : Colors.grey.shade500,
                fontWeight: stockMovement.balanceOut > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // ยอดคงเหลือ
            Expanded(
              flex: 2,
              child: _buildDataCell(
                stockMovement.balanceQty.toStringAsFixed(2),
                textAlign: TextAlign.right,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade700,
              ),
            ),
            // ราคาเฉลี่ย
            Expanded(
              flex: 2,
              child: _buildDataCell(
                ReportUtils.formatCurrencySafe(stockMovement.averageCost),
                textAlign: TextAlign.right,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            // มูลค่าคงเหลือ
            Expanded(
              flex: 2,
              child: _buildDataCell(
                ReportUtils.formatCurrencySafe(stockMovement.balanceAmount),
                textAlign: TextAlign.right,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    TextAlign? textAlign,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize ?? 11,
          fontWeight: fontWeight,
          color: color,
        ),
        textAlign: textAlign,
      ),
    );
  }

  // Helper methods for Stock Movement
  Color _getTransactionFlagColor(String transFlag) {
    switch (transFlag) {
      case 'ซื้อสินค้า': // transflag = 12
      case 'รับสินค้าแบบทะยอยรับ': // transflag = 310
      case 'รับคืนสินค้า': // transflag = 48
      case 'โอนเข้า': // transflag = 72 and calcflag = 1
      case 'สินค้ายกมา': // transflag = 54
      case 'รับคืนจากการเบิก': // transflag = 58
      case 'รับสินค้า': // transflag = 60
      case 'ปรับปรุงเพิ่ม': // transflag in (66,866)
        return Colors.green.shade100;
      case 'ส่งคืนสินค้า': // transflag = 16
      case 'ขายสินค้า': // transflag = 44
      case 'โอนออก': // transflag = 72 and calcflag = -1
      case 'เบิกสินค้า': // transflag = 56
      case 'ปรับปรุงลด': // transflag in (68,868)
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getTransactionFlagTextColor(String transFlag) {
    switch (transFlag) {
      case 'ซื้อสินค้า': // transflag = 12
      case 'รับสินค้าแบบทะยอยรับ': // transflag = 310
      case 'รับคืนสินค้า': // transflag = 48
      case 'โอนเข้า': // transflag = 72 and calcflag = 1
      case 'สินค้ายกมา': // transflag = 54
      case 'รับคืนจากการเบิก': // transflag = 58
      case 'รับสินค้า': // transflag = 60
      case 'ปรับปรุงเพิ่ม': // transflag in (66,866)
        return Colors.green.shade700;
      case 'ส่งคืนสินค้า': // transflag = 16
      case 'ขายสินค้า': // transflag = 44
      case 'โอนออก': // transflag = 72 and calcflag = -1
      case 'เบิกสินค้า': // transflag = 56
      case 'ปรับปรุงลด': // transflag in (68,868)
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getTransactionFlagText(String transFlag) {
    // transFlag ที่ส่งมาจากระบบจะเป็นข้อความภาษาไทยแล้ว
    // ตามเงื่อนไข SQL case when ที่กำหนด
    return transFlag;
  }
}
