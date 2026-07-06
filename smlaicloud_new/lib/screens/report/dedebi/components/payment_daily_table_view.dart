import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../model/bi_report/bi_report_models.dart';
import '../../../../model/bi_report/payment_daily_model.dart';

class PaymentDailyTableView extends StatelessWidget {
  final List<PaymentDailyModel> data;
  final BiReportMeta? meta;
  final VoidCallback? onLoadMore;
  final Function(PaymentDailyModel)? onRowTap;

  const PaymentDailyTableView({
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
              Icons.payment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'ไม่พบข้อมูลการชำระเงิน',
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
          flex: 2,
          child: _buildHeaderCell('วันที่'),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('ยอดรวม', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('เงินสด', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('โอนเงิน', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('บัตรเครดิต', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('เช็ค', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('คูปอง', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('QR Code', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('เครดิต', TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: _buildHeaderCell('รวมชำระ', TextAlign.right),
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

  Widget _buildDataRow(PaymentDailyModel item, int index) {
    final isEven = index % 2 == 0;
    final backgroundColor = isEven ? Colors.white : Colors.grey.shade50;

    return InkWell(
      onTap: () {
        try {
          onRowTap?.call(item);
        } catch (e) {
          debugPrint('Error in payment daily row tap: $e');
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
                _formatDate(item.docDate),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade700,
              ),
            ),
            // ยอดรวม
            Expanded(
              flex: 2,
              child: _buildDataCell(
                _formatCurrency(item.totalAmount),
                textAlign: TextAlign.right,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade700,
              ),
            ),
            // เงินสด
            Expanded(
              flex: 2,
              child: _buildDataCell(
                _formatCurrency(item.payCashAmount),
                textAlign: TextAlign.right,
                color: item.payCashAmount > 0 ? Colors.green.shade700 : Colors.grey.shade500,
                fontWeight: item.payCashAmount > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // โอนเงิน
            Expanded(
              flex: 2,
              child: _buildDataCell(
                _formatCurrency(item.sumTransfer),
                textAlign: TextAlign.right,
                color: item.sumTransfer > 0 ? Colors.blue.shade700 : Colors.grey.shade500,
                fontWeight: item.sumTransfer > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // บัตรเครดิต
            Expanded(
              flex: 2,
              child: _buildDataCell(
                _formatCurrency(item.sumCreditCard),
                textAlign: TextAlign.right,
                color: item.sumCreditCard > 0 ? Colors.purple.shade700 : Colors.grey.shade500,
                fontWeight: item.sumCreditCard > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // เช็ค
            Expanded(
              flex: 2,
              child: _buildDataCell(
                _formatCurrency(item.sumCheque),
                textAlign: TextAlign.right,
                color: item.sumCheque > 0 ? Colors.orange.shade700 : Colors.grey.shade500,
                fontWeight: item.sumCheque > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // คูปอง
            Expanded(
              flex: 2,
              child: _buildDataCell(
                _formatCurrency(item.sumCoupon),
                textAlign: TextAlign.right,
                color: item.sumCoupon > 0 ? Colors.red.shade700 : Colors.grey.shade500,
                fontWeight: item.sumCoupon > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // QR Code
            Expanded(
              flex: 2,
              child: _buildDataCell(
                _formatCurrency(item.sumQRCode),
                textAlign: TextAlign.right,
                color: item.sumQRCode > 0 ? Colors.teal.shade700 : Colors.grey.shade500,
                fontWeight: item.sumQRCode > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // เครดิต
            Expanded(
              flex: 2,
              child: _buildDataCell(
                _formatCurrency(item.sumCredit),
                textAlign: TextAlign.right,
                color: item.sumCredit > 0 ? Colors.brown.shade700 : Colors.grey.shade500,
                fontWeight: item.sumCredit > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            // รวมชำระ
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatCurrency(item.totalPayment),
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

  String _formatCurrency(double amount) {
    if (amount == 0) return '-';
    return NumberFormat('#,##0.00').format(amount);
  }
}
