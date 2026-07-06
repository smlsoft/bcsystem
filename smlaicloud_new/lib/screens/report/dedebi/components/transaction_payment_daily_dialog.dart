import 'package:flutter/material.dart';
import 'package:smlaicloud/model/bi_report/payment_daily_model.dart';
import 'package:smlaicloud/screens/report/dedebi/utils/report_utils.dart';

class TransactionPaymentDailyDialog extends StatelessWidget {
  final PaymentDailyModel payment;
  final String Function(double) formatCurrency;

  const TransactionPaymentDailyDialog({
    super.key,
    required this.payment,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width > 800 ? MediaQuery.of(context).size.width * 0.8 : MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            // 1. ข้อมูลวันที่
            _buildDateInfoSection(),
            const SizedBox(height: 16),
            // 2. ยอดสรุปการชำระเงิน
            _buildPaymentSummarySection(),
            const SizedBox(height: 16),
            // 3. รายการธุรกรรม
            _buildTransactionSection(),
            const SizedBox(height: 16),
            _buildCloseButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.payment_outlined,
              color: Colors.green.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'รายงานการรับชำระเงินประจำวัน',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  ReportUtils.formatDate(payment.docDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'ปิด',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
          ),
        ],
      ),
    );
  }

  // 1. ข้อมูลวันที่
  Widget _buildDateInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.today, color: Colors.green.shade600, size: 18),
            const SizedBox(width: 8),
            const Text(
              '1. ข้อมูลวันที่',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${payment.transactions.length} รายการ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'วันที่ออกรายงาน',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ReportUtils.formatDate(payment.docDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'จำนวนธุรกรรม',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${payment.transactions.length} รายการ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. ยอดสรุปการชำระเงิน
  Widget _buildPaymentSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: Colors.green.shade600, size: 16),
            const SizedBox(width: 6),
            const Text(
              '2. ยอดสรุปการชำระเงิน',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ยอดรวมและยอดชำระในแถวเดียว
        Row(
          children: [
            // ส่วนยอดรวมการขาย
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยอดรวมการขาย',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _buildCompactSummaryItem('มูลค่า', formatCurrency(payment.totalValue))),
                        const SizedBox(width: 4),
                        Expanded(child: _buildCompactSummaryItem('คิดเงิน', formatCurrency(payment.totalAmount))),
                        const SizedBox(width: 4),
                        Expanded(child: _buildCompactSummaryItem('ปัดเศษ', formatCurrency(payment.roundAmount))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ส่วนยอดชำระรวม
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300, width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(Icons.payments, color: Colors.green.shade700, size: 16),
                    const SizedBox(height: 4),
                    Text(
                      'ยอดชำระทั้งสิ้น',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      formatCurrency(payment.totalPayment),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ส่วนรายละเอียดการชำระ (กระชับมากขึ้น)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'รายละเอียดการชำระเงิน',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),

              // แถวแรก
              Row(
                children: [
                  Expanded(child: _buildCompactPaymentMethod('เงินสด', formatCurrency(payment.payCashAmount), Icons.money)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildCompactPaymentMethod('โอนเงิน', formatCurrency(payment.sumTransfer), Icons.account_balance)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildCompactPaymentMethod('บัตรเครดิต', formatCurrency(payment.sumCreditCard), Icons.credit_card)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildCompactPaymentMethod('เช็ค', formatCurrency(payment.sumCheque), Icons.receipt)),
                ],
              ),
              const SizedBox(height: 4),

              // แถวที่สอง
              Row(
                children: [
                  Expanded(child: _buildCompactPaymentMethod('คูปอง', formatCurrency(payment.sumCoupon), Icons.local_offer)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildCompactPaymentMethod('QR Code', formatCurrency(payment.sumQRCode), Icons.qr_code)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildCompactPaymentMethod('เงินเชื่อ', formatCurrency(payment.sumCredit), Icons.account_balance_wallet)),
                  const Expanded(child: SizedBox()), // spacer
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompactPaymentMethod(String method, String amount, IconData icon) {
    bool hasAmount = amount != formatCurrency(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: hasAmount ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasAmount ? Colors.green.shade200 : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 12,
            color: hasAmount ? Colors.green.shade600 : Colors.grey.shade500,
          ),
          const SizedBox(height: 2),
          Text(
            method,
            style: TextStyle(
              fontSize: 8,
              color: hasAmount ? Colors.green.shade700 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 9,
              fontWeight: hasAmount ? FontWeight.bold : FontWeight.w500,
              color: hasAmount ? Colors.green.shade700 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 3. รายการธุรกรรม
  Widget _buildTransactionSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: Colors.green.shade600, size: 18),
              const SizedBox(width: 8),
              Text(
                '3. รายการธุรกรรม (${payment.transactions.length} รายการ)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 30), // space for item number
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'เลขที่เอกสาร',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'ลูกค้า',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'เงินสด',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'ยอดรวม',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // List items
                  Expanded(
                    child: ListView.builder(
                      itemCount: payment.transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = payment.transactions[index];
                        return _buildTransactionItem(transaction, index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: index < payment.transactions.length - 1 ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null,
      ),
      child: Row(
        children: [
          // Item number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Document number and date/time
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.docNo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${ReportUtils.formatDate(transaction.docDate)} • ${transaction.docTime}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Customer name
          Expanded(
            child: Text(
              transaction.custName.isEmpty ? 'ลูกค้าทั่วไป' : transaction.custName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Cash amount
          Expanded(
            child: Text(
              formatCurrency(transaction.payCashAmount),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.green.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Total payment
          Expanded(
            child: Text(
              formatCurrency(transaction.totalPayment),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(100, 40),
        ),
        child: const Text(
          'ปิด',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
