import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../model/bi_report/bi_report_models.dart';
import '../../../../model/bi_report/sale_return_model.dart';
import '../utils/report_utils.dart';

class SaleReturnTableView extends StatelessWidget {
  final List<SaleReturnModel> data;
  final BiReportMeta? meta;
  final VoidCallback? onLoadMore;
  final Function(SaleReturnModel)? onRowTap;

  const SaleReturnTableView({
    super.key,
    required this.data,
    this.meta,
    this.onLoadMore,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_return_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'ไม่พบข้อมูลการขายคืน',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
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

        // Load more button
        if (meta != null && meta!.page < meta!.totalPage)
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: onLoadMore,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('โหลดข้อมูลเพิ่มเติม'),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildHeaderCell('วันที่'),
        ),
        Expanded(
          flex: 1,
          child: _buildHeaderCell('เลขที่เอกสาร'),
        ),
        Expanded(
          flex: 1,
          child: _buildHeaderCell('ลูกค้า'),
        ),
        Expanded(
          flex: 1,
          child: _buildHeaderCell('มูลค่า', TextAlign.right),
        ),
        Expanded(
          flex: 1,
          child: _buildHeaderCell('ส่วนลด', TextAlign.right),
        ),
        Expanded(
          flex: 1,
          child: _buildHeaderCell('หลังหักส่วนลด', TextAlign.right),
        ),
        Expanded(
          flex: 1,
          child: _buildHeaderCell('ก่อน VAT', TextAlign.right),
        ),
        Expanded(
          flex: 1,
          child: _buildHeaderCell('VAT', TextAlign.right),
        ),
        Expanded(
          flex: 1,
          child: _buildHeaderCell('ยอดรวม', TextAlign.right),
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

  Widget _buildDataRow(SaleReturnModel saleReturn, int index) {
    final isEven = index % 2 == 0;
    final backgroundColor = isEven ? Colors.white : Colors.grey.shade50;

    return InkWell(
      onTap: () {
        try {
          onRowTap?.call(saleReturn);
        } catch (e) {
          debugPrint('Error in sale return row tap: $e');
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
              flex: 1,
              child: _buildDataCell(
                _formatDate(saleReturn.docDate),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade700,
              ),
            ),
            // เลขที่เอกสาร
            Expanded(
              flex: 1,
              child: _buildDataCell(
                saleReturn.docno,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
            // ลูกค้า
            Expanded(
              flex: 1,
              child: _buildDataCell(
                _getCreditorName(saleReturn.creditorNames),
                fontSize: 11,
                color: Colors.green.shade700,
              ),
            ),

            // มูลค่า
            Expanded(
              flex: 1,
              child: _buildDataCell(
                ReportUtils.formatCurrency(saleReturn.totalValue),
                textAlign: TextAlign.right,
                color: Colors.purple.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            // ส่วนลด
            Expanded(
              flex: 1,
              child: _buildDataCell(
                saleReturn.detailTotalDiscount > 0 ? ReportUtils.formatCurrency(saleReturn.detailTotalDiscount) : '-',
                textAlign: TextAlign.right,
                color: saleReturn.detailTotalDiscount > 0 ? Colors.red.shade700 : Colors.grey.shade500,
                fontWeight: saleReturn.detailTotalDiscount > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // หลังหักส่วนลด
            Expanded(
              flex: 1,
              child: _buildDataCell(
                ReportUtils.formatCurrency(saleReturn.totalAfterDiscount),
                textAlign: TextAlign.right,
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            // ก่อน VAT
            Expanded(
              flex: 1,
              child: _buildDataCell(
                ReportUtils.formatCurrency(saleReturn.totalBeforeVat),
                textAlign: TextAlign.right,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            // VAT
            Expanded(
              flex: 1,
              child: _buildDataCell(
                saleReturn.totalVatValue > 0 ? ReportUtils.formatCurrency(saleReturn.totalVatValue) : '-',
                textAlign: TextAlign.right,
                color: saleReturn.totalVatValue > 0 ? Colors.brown.shade700 : Colors.grey.shade500,
                fontWeight: saleReturn.totalVatValue > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            // ยอดรวม
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ReportUtils.formatCurrency(saleReturn.totalAmount),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                  textAlign: TextAlign.right,
                ),
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getCreditorName(List<NameModel> creditorNames) {
    if (creditorNames.isEmpty) return '-';

    // ให้ความสำคัญกับภาษาไทย
    final thName = creditorNames.where((name) => name.code == 'th').firstOrNull;
    if (thName != null && thName.name.isNotEmpty) {
      return thName.name;
    }

    // ถ้าไม่มีภาษาไทย ใช้ตัวแรก
    return creditorNames.first.getDisplayName();
  }
}
