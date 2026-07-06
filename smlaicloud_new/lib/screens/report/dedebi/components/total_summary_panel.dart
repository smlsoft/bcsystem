import 'package:flutter/material.dart';
import 'package:smlaicloud/model/bi_report/bi_report_models.dart';
import 'package:smlaicloud/model/bi_report/payment_daily_model.dart';
import 'package:smlaicloud/model/bi_report/sale_daily_report_summary.dart';
import 'package:smlaicloud/model/bi_report/sale_report_summary.dart';
import 'package:smlaicloud/model/bi_report/sale_return_model.dart';
import 'package:smlaicloud/model/bi_report/stock_balance_model.dart';
import 'package:smlaicloud/model/bi_report/stock_movment_summary_model.dart';
import 'package:smlaicloud/screens/report/dedebi/utils/report_utils.dart';

class TotalSummaryPanel extends StatelessWidget {
  final SaleReportSummary? totalSummary;
  final SaleDailyReportSummary? dailySummary;
  final StockMovmentSummaryModel? stockSummary;
  final PaymentDailySummaryModel? paymentSummary;
  final SaleReturnSummaryModel? saleReturnSummary;
  final StockBalanceSummaryModel? stockBalanceSummary;
  final bool isLoading;
  final BiReportType reportType;

  const TotalSummaryPanel({
    super.key,
    this.totalSummary,
    this.isLoading = false,
    this.dailySummary,
    this.stockSummary,
    this.paymentSummary,
    this.saleReturnSummary,
    this.stockBalanceSummary,
    required this.reportType,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingWidget();
    }

    // แยกการตรวจสอบตาม reportType
    if (reportType == BiReportType.sale) {
      if (totalSummary == null) {
        return _buildEmptyWidget();
      }
    } else if (reportType == BiReportType.saleDaily) {
      if (dailySummary == null) {
        return _buildEmptyWidget();
      }
    } else if (reportType == BiReportType.stockMovement) {
      if (stockSummary == null) {
        return _buildEmptyWidget();
      }
    } else if (reportType == BiReportType.paymentDaily) {
      if (paymentSummary == null) {
        return _buildEmptyWidget();
      }
    } else if (reportType == BiReportType.saleReturn) {
      if (saleReturnSummary == null) {
        return _buildEmptyWidget();
      }
    } else if (reportType == BiReportType.stockBalance) {
      if (stockBalanceSummary == null) {
        return _buildEmptyWidget();
      }
    } else {
      return _buildEmptyWidget();
    }

    return _buildSummaryContent();
  }

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize_outlined,
                color: Colors.indigo.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ยอดรวม',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'กำลังโหลดยอดรวม...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ยอดรวม',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'ไม่มีข้อมูลยอดรวม',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.summarize_outlined,
                color: Colors.indigo.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ยอดรวม',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // แยกการแสดงผลตาม reportType
          if (reportType == BiReportType.sale && totalSummary != null) ...[
            // Sale Report Summary
            _buildSummaryRow(
              'จำนวนรายการ',
              '${totalSummary!.totalRecords ?? 0} รายการ',
              Colors.blue.shade600,
              Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'ยอดขายรวม',
              ReportUtils.formatCurrency(totalSummary!.totalAmount ?? 0),
              Colors.green.shade600,
              Icons.payments_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'มูลค่ารวม',
              ReportUtils.formatCurrency(totalSummary!.totalValue ?? 0),
              Colors.purple.shade600,
              Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'ก่อน VAT',
              ReportUtils.formatCurrency(totalSummary!.totalBeforeVat ?? 0),
              Colors.orange.shade600,
              Icons.calculate_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'VAT',
              ReportUtils.formatCurrency(totalSummary!.totalVatValue ?? 0),
              Colors.red.shade600,
              Icons.percent_outlined,
            ),

            // Branch breakdown สำหรับ Sale Report
            if (totalSummary!.totalByBranch != null && totalSummary!.totalByBranch!.length > 1) ...[
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'แยกตามสาขา',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...totalSummary!.totalByBranch!.map((branch) => _buildBranchRow(branch)),
            ],
          ] else if (reportType == BiReportType.saleDaily && dailySummary != null) ...[
            // Sale Daily Report Summary
            _buildSummaryRow(
              'จำนวนรายการ',
              '${dailySummary!.totalDays ?? 0} รายการ',
              Colors.blue.shade600,
              Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'ยอดขายรวม',
              ReportUtils.formatCurrency(dailySummary!.totalAmount ?? 0),
              Colors.green.shade600,
              Icons.payments_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'เฉลี่ยต่อวัน',
              ReportUtils.formatCurrency(dailySummary!.averageDailyAmount ?? 0),
              Colors.purple.shade600,
              Icons.account_balance_wallet_outlined,
            ),
          ] else if (reportType == BiReportType.stockMovement && stockSummary != null) ...[
            // Stock Movement Report Summary
            _buildSummaryRow(
              'บาร์โค้ด',
              stockSummary!.barcode!,
              Colors.purple.shade600,
              Icons.qr_code,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'จำนวนรายการ',
              '${stockSummary!.totalRecords} รายการ',
              Colors.blue.shade600,
              Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'ยอดเข้า',
              '${stockSummary!.totalQtyIn!.toStringAsFixed(2)} หน่วย',
              Colors.green.shade600,
              Icons.add_box_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'ยอดออก',
              '${stockSummary!.totalQtyOut!.toStringAsFixed(2)} หน่วย',
              Colors.red.shade600,
              Icons.remove_circle_outline,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'ยอดคงเหลือ',
              '${stockSummary!.finalBalanceQty!.toStringAsFixed(2)} หน่วย',
              Colors.orange.shade600,
              Icons.inventory_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'มูลค่าคงเหลือ',
              ReportUtils.formatCurrency(stockSummary!.finalBalanceAmount!),
              Colors.indigo.shade600,
              Icons.account_balance_wallet_outlined,
            ),
          ] else if (reportType == BiReportType.paymentDaily && paymentSummary != null) ...[
            // Payment Daily Report Summary
            _buildSummaryRow(
              'ช่วงวันที่',
              '${ReportUtils.formatDate(paymentSummary!.fromDate)} - ${ReportUtils.formatDate(paymentSummary!.toDate)}',
              Colors.blue.shade600,
              Icons.date_range,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'ยอดขายรวม',
              ReportUtils.formatCurrency(paymentSummary!.totalAmount),
              Colors.green.shade600,
              Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'ยอดชำระรวม',
              ReportUtils.formatCurrency(paymentSummary!.totalPayment),
              Colors.purple.shade600,
              Icons.payments_outlined,
            ),
          ] else if (reportType == BiReportType.saleReturn && saleReturnSummary != null) ...[
            // Sale Return Report Summary
            _buildSummaryRow(
              'ช่วงวันที่',
              '${ReportUtils.formatDate(saleReturnSummary!.fromDate)} - ${ReportUtils.formatDate(saleReturnSummary!.toDate)}',
              Colors.blue.shade600,
              Icons.date_range,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'จำนวนรายการ',
              '${saleReturnSummary!.totalRecords} รายการ',
              Colors.orange.shade600,
              Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'ยอดคืนรวม',
              ReportUtils.formatCurrency(saleReturnSummary!.totalAmount),
              Colors.red.shade600,
              Icons.assignment_return_outlined,
            ),
          ] else if (reportType == BiReportType.stockBalance && stockBalanceSummary != null) ...[
            // Stock Balance Report Summary
            _buildSummaryRow(
              'วันที่',
              ReportUtils.formatDate(stockBalanceSummary!.toDate),
              Colors.blue.shade600,
              Icons.date_range,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'จำนวนรายการ',
              '${stockBalanceSummary!.totalRecords} รายการ',
              Colors.purple.shade600,
              Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'ยอดคงเหลือรวม',
              '${stockBalanceSummary!.totalBalanceQty.toStringAsFixed(2)} หน่วย',
              Colors.orange.shade600,
              Icons.inventory_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'ต้นทุนเฉลี่ย',
              stockBalanceSummary!.averageCost != null ? ReportUtils.formatCurrency(stockBalanceSummary!.averageCost!) : 'ไม่มีข้อมูล',
              Colors.green.shade600,
              Icons.calculate_outlined,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'มูลค่าคงเหลือรวม',
              stockBalanceSummary!.totalBalanceAmount != null ? ReportUtils.formatCurrency(stockBalanceSummary!.totalBalanceAmount!) : 'ไม่มีข้อมูล',
              Colors.indigo.shade600,
              Icons.account_balance_wallet_outlined,
            ),
          ] else ...[
            // Fallback - No data
            Center(
              child: Text(
                'ไม่มีข้อมูลยอดรวม',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBranchRow(SaleReportSummaryByBranch branch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.store_outlined,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'สาขา ${branch.branchcode ?? '-'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${branch.totalRecords ?? 0} รายการ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                ReportUtils.formatCurrency(branch.totalAmount ?? 0),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
