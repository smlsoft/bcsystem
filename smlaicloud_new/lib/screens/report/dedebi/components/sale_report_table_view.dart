import 'package:flutter/material.dart';
import 'package:smlaicloud/model/bi_report/bi_sale_report_data.dart';
import 'package:smlaicloud/screens/report/dedebi/utils/report_utils.dart';

class SaleReportTableView extends StatelessWidget {
  final List<SaleReportData> data;
  final String Function(List<SaleCreditorName>) getCreditorName;
  final Function(SaleReportData)? onRowTap;

  const SaleReportTableView({
    super.key,
    required this.data,
    required this.getCreditorName,
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
          flex: 1,
          child: _buildHeaderCell('วันที่'),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('เลขที่เอกสาร'),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('ลูกค้า'),
        ),
        Expanded(
          flex: 1,
          child: _buildHeaderCell('สาขา', TextAlign.center),
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
          flex: 1,
          child: _buildHeaderCell('ประเภท', TextAlign.center),
        ),
        Expanded(
          flex: 1,
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

  Widget _buildDataRow(SaleReportData sale, int index) {
    final isEven = index % 2 == 0;
    final backgroundColor = isEven ? Colors.white : Colors.grey.shade50;

    return InkWell(
      onTap: sale.transactions.isNotEmpty
          ? () {
              try {
                onRowTap?.call(sale);
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
              flex: 1,
              child: _buildDataCell(
                ReportUtils.formatDate(sale.docdate),
              ),
            ),
            // เลขที่เอกสาร
            Expanded(
              flex: 2,
              child: _buildDataCell(
                sale.docno,
                fontWeight: FontWeight.w600,
                color: sale.transactions.isNotEmpty ? Colors.indigo.shade700 : Colors.black87,
                decoration: sale.transactions.isNotEmpty ? TextDecoration.underline : null,
              ),
            ),
            // ลูกค้า
            Expanded(
              flex: 2,
              child: _buildDataCell(
                () {
                  try {
                    final creditorName = getCreditorName(sale.creditornames);
                    return creditorName.isEmpty ? 'ลูกค้าทั่วไป' : creditorName;
                  } catch (e) {
                    return 'ลูกค้าทั่วไป';
                  }
                }(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // สาขา
            Expanded(
              flex: 1,
              child: _buildDataCell(
                sale.branchcode,
                textAlign: TextAlign.center,
              ),
            ),
            // มูลค่าสินค้า
            Expanded(
              flex: 2,
              child: _buildDataCell(
                ReportUtils.formatCurrencySafe(sale.totalvalue),
                textAlign: TextAlign.right,
              ),
            ),
            // ก่อน VAT
            Expanded(
              flex: 2,
              child: _buildDataCell(
                ReportUtils.formatCurrencySafe(sale.totalbeforevat),
                textAlign: TextAlign.right,
              ),
            ),
            // VAT
            Expanded(
              flex: 1,
              child: _buildDataCell(
                ReportUtils.formatCurrencySafe(sale.totalvatvalue),
                textAlign: TextAlign.right,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            // ยอดรวม
            Expanded(
              flex: 2,
              child: _buildDataCell(
                ReportUtils.formatCurrencySafe(sale.totalamount),
                textAlign: TextAlign.right,
                fontWeight: FontWeight.bold,
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
                    color: ReportUtils.getStatusColor(sale.inquirytype),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ReportUtils.getStatusText(sale.inquirytype),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: ReportUtils.getStatusTextColor(sale.inquirytype),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // รายการ
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: sale.transactions.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${sale.transactions.length} รายการ',
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
    TextDecoration? decoration,
    TextOverflow? overflow,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize ?? 11,
          fontWeight: fontWeight,
          color: color,
          decoration: decoration,
        ),
        textAlign: textAlign,
        overflow: overflow,
      ),
    );
  }
}
