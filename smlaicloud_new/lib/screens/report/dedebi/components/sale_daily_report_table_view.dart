import 'package:flutter/material.dart';
import 'package:smlaicloud/model/bi_report/sale_daily_report_models.dart';
import 'package:smlaicloud/screens/report/dedebi/utils/report_utils.dart';

class SaleDailyReportTableView extends StatelessWidget {
  final List<SaleDailyReportData> data;
  final Function(SaleDailyReportData)? onRowTap;

  const SaleDailyReportTableView({
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
          child: _buildHeaderCell('มูลค่าสินค้า', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('ก่อน VAT', TextAlign.right),
        ),
        Expanded(
          flex: 1,
          child: _buildHeaderCell('VAT', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('ยอดรวม', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('รายการ', TextAlign.center),
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

  Widget _buildDataRow(SaleDailyReportData dailySale, int index) {
    final isEven = index % 2 == 0;
    final backgroundColor = isEven ? Colors.white : Colors.grey.shade50;

    return InkWell(
      onTap: dailySale.transactions.isNotEmpty
          ? () {
              try {
                onRowTap?.call(dailySale);
              } catch (e) {
                debugPrint('Error in row tap: $e');
              }
            }
          : null,
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
                ReportUtils.formatDate(dailySale.docDate),
                fontWeight: FontWeight.w600,
              ),
            ),
            // มูลค่าสินค้า
            Expanded(
              flex: 2,
              child: _buildDataCell(
                ReportUtils.formatCurrencySafe(dailySale.totalValue),
                textAlign: TextAlign.right,
              ),
            ),
            // ก่อน VAT
            Expanded(
              flex: 2,
              child: _buildDataCell(
                ReportUtils.formatCurrencySafe(dailySale.totalBeforeVat),
                textAlign: TextAlign.right,
              ),
            ),
            // VAT
            Expanded(
              flex: 1,
              child: _buildDataCell(
                ReportUtils.formatCurrencySafe(dailySale.totalVatValue),
                textAlign: TextAlign.right,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            // ยอดรวม
            Expanded(
              flex: 2,
              child: _buildDataCell(
                ReportUtils.formatCurrencySafe(dailySale.totalAmount),
                textAlign: TextAlign.right,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade700,
              ),
            ),
            // รายการ
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: (dailySale.transactions.isNotEmpty)
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${dailySale.transactions.length} รายการ',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const Text('-', style: TextStyle(fontSize: 11), textAlign: TextAlign.center),
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
}
