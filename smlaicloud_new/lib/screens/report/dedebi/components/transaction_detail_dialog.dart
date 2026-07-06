import 'package:flutter/material.dart';
import 'package:smlaicloud/model/bi_report/bi_sale_report_data.dart';
import 'package:smlaicloud/model/bi_report/sale_return_model.dart';
import 'package:smlaicloud/screens/report/dedebi/utils/report_utils.dart';

class TransactionDetailDialog extends StatelessWidget {
  final SaleReportData? sale;
  final SaleReturnModel? saleReturn;
  final String Function(double) formatCurrency;
  final String Function(List<SaleCreditorName>) getCreditorName;

  const TransactionDetailDialog({
    super.key,
    this.sale,
    this.saleReturn,
    required this.formatCurrency,
    required this.getCreditorName,
  });

  @override
  Widget build(BuildContext context) {
    // ตรวจสอบว่ามีข้อมูลอะไรบ้าง
    if (sale == null && saleReturn == null) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('ไม่มีข้อมูลให้แสดง'),
        ),
      );
    }

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
            // 1. ข้อมูลลูกค้า
            _buildCustomerInfoSection(),
            const SizedBox(height: 16),
            // 2. ยอดสรุป
            _buildSummarySection(),
            const SizedBox(height: 16),
            // 3. รายการสินค้า
            _buildTransactionSection(),
            const SizedBox(height: 16),
            _buildCloseButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final docno = sale?.docno ?? saleReturn?.docno ?? '';
    final docdate = sale?.docdate ?? saleReturn?.docDate ?? '';
    final docTime = sale?.docTime ?? '';
    final branchcode = sale?.branchcode ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              saleReturn != null ? Icons.assignment_return_outlined : Icons.receipt_outlined,
              color: Colors.indigo.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'รายละเอียด $docno',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                Text(
                  '${ReportUtils.formatDate(docdate)}${docTime.isNotEmpty ? ' • $docTime' : ''}${branchcode.isNotEmpty ? ' • สาขา $branchcode' : ''}',
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

  // 1. ข้อมูลลูกค้า
  Widget _buildCustomerInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.business, color: Colors.indigo.shade600, size: 18),
            const SizedBox(width: 8),
            const Text(
              '1. ข้อมูลลูกค้า',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const Spacer(),
            // แสดง status badge เฉพาะ sale report เท่านั้น
            if (sale != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ReportUtils.getStatusColor(sale!.inquirytype),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ReportUtils.getStatusText(sale!.inquirytype),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ReportUtils.getStatusTextColor(sale!.inquirytype),
                  ),
                ),
              ),
            ],
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
                          'ชื่อลูกค้า',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCustomerName(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                          'รหัสลูกค้า',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCustomerCode(),
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

  // 3. รายการสินค้า
  Widget _buildTransactionSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart_outlined, color: Colors.indigo.shade600, size: 18),
              const SizedBox(width: 8),
              Text(
                '3. รายการสินค้า (${_getTransactionCount()} รายการ)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
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
                            'สินค้า',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'จำนวน',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'ราคา',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade700,
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
                              color: Colors.indigo.shade700,
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
                      itemCount: _getTransactionCount(),
                      itemBuilder: (context, index) {
                        if (sale != null) {
                          final transaction = sale!.transactions[index];
                          return _buildSaleTransactionItem(transaction, index);
                        } else if (saleReturn != null) {
                          final transaction = saleReturn!.transactions[index];
                          return _buildSaleReturnTransactionItem(transaction, index);
                        }
                        return const SizedBox.shrink();
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

  // 2. ยอดสรุป
  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calculate_outlined, color: Colors.indigo.shade600, size: 16),
            const SizedBox(width: 6),
            const Text(
              '2. ยอดสรุป',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.indigo.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildCompactSummaryItem('มูลค่าสินค้า', ReportUtils.formatCurrencySafe(_getTotalValue())),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactSummaryItem('ก่อน VAT', ReportUtils.formatCurrencySafe(_getTotalBeforeVat())),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactSummaryItem('VAT', ReportUtils.formatCurrencySafe(_getTotalVatValue()), isVat: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildCompactSummaryItem('ยอดรวมทั้งสิ้น', ReportUtils.formatCurrencySafe(_getTotalAmount()), isTotal: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSummaryItem(String label, String value, {bool isVat = false, bool isTotal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isTotal ? Colors.indigo.shade700 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal
                ? Colors.indigo.shade700
                : isVat
                    ? Colors.orange.shade700
                    : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSaleTransactionItem(SaleTransaction transaction, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: index < _getTransactionCount() - 1 ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null,
      ),
      child: Row(
        children: [
          // Item number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Item name and barcode
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ReportUtils.getItemNameSafe(transaction.itemnames),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.barcode,
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
          // Quantity
          Expanded(
            child: Column(
              children: [
                Text(
                  '${transaction.qty}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  ReportUtils.getUnitNameSafe(transaction.unitnames),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Price
          Expanded(
            child: Text(
              formatCurrency(transaction.price),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Total amount
          Expanded(
            child: Text(
              formatCurrency(transaction.sumamount),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleReturnTransactionItem(SaleReturnTransactionModel transaction, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: index < _getTransactionCount() - 1 ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null,
      ),
      child: Row(
        children: [
          // Item number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Item name and barcode
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSaleReturnItemName(transaction.itemNames),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.barcode,
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
          // Quantity
          Expanded(
            child: Column(
              children: [
                Text(
                  '${transaction.qty}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  _getSaleReturnUnitName(transaction.unitNames),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Price
          Expanded(
            child: Text(
              formatCurrency(transaction.price),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Total amount
          Expanded(
            child: Text(
              formatCurrency(transaction.sumAmount),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700, // สีแดงสำหรับการคืนสินค้า
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _getSaleReturnItemName(List<NameModel> itemNames) {
    if (itemNames.isEmpty) return '-';

    // ให้ความสำคัญกับภาษาไทย
    final thName = itemNames.where((name) => name.code == 'th').firstOrNull;
    if (thName != null && thName.name.isNotEmpty) {
      return thName.name;
    }

    // ถ้าไม่มีภาษาไทย ใช้ตัวแรก
    return itemNames.first.getDisplayName();
  }

  String _getSaleReturnUnitName(List<NameModel> unitNames) {
    if (unitNames.isEmpty) return '-';

    // ให้ความสำคัญกับภาษาไทย
    final thName = unitNames.where((name) => name.code == 'th').firstOrNull;
    if (thName != null && thName.name.isNotEmpty) {
      return thName.name;
    }

    // ถ้าไม่มีภาษาไทย ใช้ตัวแรก
    return unitNames.first.getDisplayName();
  }

  Widget _buildCloseButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo.shade600,
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

  // Helper methods
  String _getCustomerName() {
    if (sale != null) {
      return getCreditorName(sale!.creditornames).isEmpty ? 'ลูกค้าทั่วไป' : getCreditorName(sale!.creditornames);
    } else if (saleReturn != null) {
      return _getSaleReturnCreditorName(saleReturn!.creditorNames);
    }
    return 'ลูกค้าทั่วไป';
  }

  String _getCustomerCode() {
    if (sale != null) {
      return sale!.creditorcode.isEmpty ? '-' : sale!.creditorcode;
    } else if (saleReturn != null) {
      // SaleReturn ไม่มี creditorcode field ใน JSON ที่ให้มา
      return '-';
    }
    return '-';
  }

  String _getSaleReturnCreditorName(List<NameModel> creditorNames) {
    if (creditorNames.isEmpty) return 'ลูกค้าทั่วไป';

    // ให้ความสำคัญกับภาษาไทย
    final thName = creditorNames.where((name) => name.code == 'th').firstOrNull;
    if (thName != null && thName.name.isNotEmpty) {
      return thName.name;
    }

    // ถ้าไม่มีภาษาไทย ใช้ตัวแรก
    return creditorNames.first.getDisplayName();
  }

  int _getTransactionCount() {
    if (sale != null) {
      return sale!.transactions.length;
    } else if (saleReturn != null) {
      return saleReturn!.transactions.length;
    }
    return 0;
  }

  double _getTotalValue() {
    if (sale != null) {
      return sale!.totalvalue;
    } else if (saleReturn != null) {
      return saleReturn!.totalValue;
    }
    return 0;
  }

  double _getTotalBeforeVat() {
    if (sale != null) {
      return sale!.totalbeforevat;
    } else if (saleReturn != null) {
      return saleReturn!.totalBeforeVat;
    }
    return 0;
  }

  double _getTotalVatValue() {
    if (sale != null) {
      return sale!.totalvatvalue;
    } else if (saleReturn != null) {
      return saleReturn!.totalVatValue;
    }
    return 0;
  }

  double _getTotalAmount() {
    if (sale != null) {
      return sale!.totalamount;
    } else if (saleReturn != null) {
      return saleReturn!.totalAmount;
    }
    return 0;
  }
}
