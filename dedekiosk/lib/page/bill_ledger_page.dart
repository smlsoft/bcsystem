import 'dart:convert';

import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/service/bill_ledger_service.dart';
import 'package:dedekiosk/service/bill_ledger_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BillLedgerPage extends StatefulWidget {
  const BillLedgerPage({super.key});

  @override
  State<BillLedgerPage> createState() => _BillLedgerPageState();
}

class _BillLedgerPageState extends State<BillLedgerPage> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<BillLedgerModel> _ledgers = [];
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final search = _searchController.text.trim().toLowerCase();
    final data =
        global.objectBoxStore.box<BillLedgerModel>().getAll().where((ledger) {
      final sameDate = ledger.docDateKey == dateKey;
      if (!sameDate) return false;
      if (search.isEmpty) return true;
      return ledger.printedDocNo.toLowerCase().contains(search) ||
          ledger.serverDocNo.toLowerCase().contains(search) ||
          ledger.localBillId.toLowerCase().contains(search) ||
          ledger.syncStatus.toLowerCase().contains(search);
    }).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _ledgers = data;
    });
  }

  Future<void> _retryAll() async {
    setState(() => _syncing = true);
    final result =
        await BillLedgerSyncService().syncPendingLedgers(force: true);
    setState(() => _syncing = false);
    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Sync success ${result.success}, failed ${result.failed}, changed ${result.changedDocNo}')),
    );
  }

  Future<void> _retryOne(BillLedgerModel ledger) async {
    setState(() => _syncing = true);
    await BillLedgerSyncService().syncLedger(ledger, force: true);
    setState(() => _syncing = false);
    _reload();
  }

  Future<void> _recordReprint(BillLedgerModel ledger) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record reprint'),
        content: Text(
          ledger.serverDocNo == ledger.printedDocNo
              ? 'Doc no ${ledger.printedDocNo}'
              : 'Printed doc no ${ledger.printedDocNo}\nServer doc no ${ledger.serverDocNo}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Record'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    BillLedgerService().markReprinted(ledger.localBillId);
    _reload();
  }

  Future<void> _cleanupExpired() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup old synced bills'),
        content: const Text(
          'This removes only synced local bill ledger records older than the 1 year retention date. Pending, failed, and attention records are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cleanup'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = BillLedgerService().cleanupExpiredSyncedLedgers();
    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cleaned up $removed expired synced bills')),
    );
  }

  void _showBillDetail(BillLedgerModel ledger) {
    showDialog(
      context: context,
      builder: (context) => _BillDetailDialog(ledger: ledger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _Summary.from(_ledgers);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
              return;
            }
            navigator.pushNamedAndRemoveUntil(
                '/', (Route<dynamic> route) => false);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Local Bills'),
        actions: [
          IconButton(
            tooltip: 'Cleanup expired synced bills',
            onPressed: _cleanupExpired,
            icon: const Icon(Icons.cleaning_services),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      hintText: 'Search doc no, server doc no, status',
                    ),
                    onChanged: (_) => _reload(),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      _selectedDate = picked;
                      _reload();
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _syncing ? null : _retryAll,
                  icon: _syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_sync),
                  label: const Text('Retry pending'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _SummaryTile(label: 'Bills', value: summary.count.toString()),
                _SummaryTile(
                    label: 'Total',
                    value:
                        NumberFormat('#,##0.00').format(summary.totalAmount)),
                _SummaryTile(label: 'Synced', value: summary.synced.toString()),
                _SummaryTile(
                    label: 'Pending', value: summary.pending.toString()),
                _SummaryTile(label: 'Failed', value: summary.failed.toString()),
                _SummaryTile(
                    label: 'Changed', value: summary.changed.toString()),
                _SummaryTile(
                    label: 'Reprints', value: summary.reprints.toString()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _ledgers.isEmpty
                ? const Center(child: Text('No local bills'))
                : ListView.separated(
                    itemCount: _ledgers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) => _LedgerTile(
                      ledger: _ledgers[index],
                      onRetry:
                          _syncing ? null : () => _retryOne(_ledgers[index]),
                      onReprint: () => _recordReprint(_ledgers[index]),
                      onOpen: () => _showBillDetail(_ledgers[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  final BillLedgerModel ledger;
  final VoidCallback? onRetry;
  final VoidCallback onReprint;
  final VoidCallback onOpen;

  const _LedgerTile({
    required this.ledger,
    required this.onRetry,
    required this.onReprint,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final canRetry = ledger.syncStatus == BillLedgerStatus.paidSyncPending ||
        ledger.syncStatus == BillLedgerStatus.paidSyncFailed ||
        ledger.syncStatus == 'syncing';
    return ListTile(
      onTap: onOpen,
      leading: Icon(_statusIcon(), color: _statusColor()),
      title: Text(ledger.printedDocNo),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ledger.docNoChanged || ledger.serverDocNo != ledger.printedDocNo)
            Text('Server: ${ledger.serverDocNo} (from ${ledger.printedDocNo})'),
          Text(
              'Status: ${ledger.syncStatus}  Total: ${NumberFormat('#,##0.00').format(ledger.totalAmount)}'),
          SelectableText(
            'LOCAL_BILL_ID=${ledger.localBillId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (ledger.reprintCount > 0)
            Text(
                'Reprint: ${ledger.reprintCount}  Last: ${DateFormat('dd/MM/yyyy HH:mm').format(ledger.lastReprintAt ?? ledger.updatedAt)}'),
          if (ledger.lastError.isNotEmpty)
            Text(
              ledger.lastError,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.red.shade700),
            ),
        ],
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            onPressed: onOpen,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Bill details',
          ),
          IconButton(
            onPressed: onReprint,
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Record reprint',
          ),
          if (canRetry)
            IconButton(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                tooltip: 'Retry'),
        ],
      ),
    );
  }

  IconData _statusIcon() {
    if (ledger.syncStatus == BillLedgerStatus.paidSyncSuccess) {
      return Icons.check_circle;
    }
    if (ledger.syncStatus == BillLedgerStatus.syncSuccessDocNoChanged) {
      return Icons.change_circle;
    }
    if (ledger.syncStatus == BillLedgerStatus.paidSyncFailed ||
        ledger.syncStatus == BillLedgerStatus.syncFailedNeedAttention) {
      return Icons.error;
    }
    return Icons.pending;
  }

  Color _statusColor() {
    if (ledger.syncStatus == BillLedgerStatus.paidSyncSuccess) {
      return Colors.green;
    }
    if (ledger.syncStatus == BillLedgerStatus.syncSuccessDocNoChanged) {
      return Colors.orange;
    }
    if (ledger.syncStatus == BillLedgerStatus.paidSyncFailed ||
        ledger.syncStatus == BillLedgerStatus.syncFailedNeedAttention) {
      return Colors.red;
    }
    return Colors.blueGrey;
  }
}

class _BillDetailDialog extends StatelessWidget {
  final BillLedgerModel ledger;

  const _BillDetailDialog({required this.ledger});

  @override
  Widget build(BuildContext context) {
    final lines = _parseLines();
    return AlertDialog(
      title: Text('Bill ${ledger.printedDocNo}'),
      content: SizedBox(
        width: 760,
        height: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoLine(label: 'Printed doc no', value: ledger.printedDocNo),
            if (ledger.serverDocNo != ledger.printedDocNo)
              _InfoLine(label: 'Server doc no', value: ledger.serverDocNo),
            _InfoLine(label: 'Status', value: ledger.syncStatus),
            _InfoLine(
                label: 'Total',
                value: NumberFormat('#,##0.00').format(ledger.totalAmount)),
            _InfoLine(label: 'LOCAL_BILL_ID', value: ledger.localBillId),
            _InfoLine(label: 'Checksum', value: ledger.payloadChecksum),
            if (ledger.lastError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SelectableText(
                  'Error: ${ledger.lastError}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            const Divider(height: 24),
            Text('Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _BillItemsHeader(),
            const Divider(height: 1),
            Expanded(
              child: lines.isEmpty
                  ? const Center(child: Text('No item detail in local ledger'))
                  : ListView.separated(
                      itemCount: lines.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _BillItemRow(line: lines[index]),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  List<_BillDetailLine> _parseLines() {
    final fromPayload = _parsePayloadLines();
    if (fromPayload.isNotEmpty) return fromPayload;
    return _parseSnapshotLines();
  }

  List<_BillDetailLine> _parsePayloadLines() {
    try {
      final payload = jsonDecode(ledger.payloadJson);
      if (payload is! Map<String, dynamic>) return [];
      final details = payload['details'];
      if (details is! List) return [];
      return details.whereType<Map>().map((item) {
        final map = item.map((key, value) => MapEntry(key.toString(), value));
        final barcode = (map['barcode'] ?? map['itemcode'] ?? '').toString();
        return _BillDetailLine(
          barcode: barcode,
          name: _nameFromPayload(map) ?? _productName(barcode),
          qty: _toDouble(map['qty']),
          price: _toDouble(map['price']),
          amount: _toDouble(map['sumamount']),
          discount: _toDouble(map['discountamount']),
          remark: (map['remark'] ?? '').toString(),
          isChoice: _toInt(map['ischoice']) == 1,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  List<_BillDetailLine> _parseSnapshotLines() {
    try {
      final items = jsonDecode(ledger.itemsJson);
      if (items is! List) return [];
      return items.whereType<Map>().map((item) {
        final map = item.map((key, value) => MapEntry(key.toString(), value));
        final barcode = (map['barcode'] ?? '').toString();
        return _BillDetailLine(
          barcode: barcode,
          name: _productName(barcode),
          qty: _toDouble(map['qty']),
          price: _toDouble(map['price']),
          amount: _toDouble(map['amount']),
          discount: _toDouble(map['discountamount']),
          remark: (map['remark'] ?? '').toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  String? _nameFromPayload(Map<String, dynamic> map) {
    final names = map['itemnames'];
    if (names is! List) return null;
    for (final item in names) {
      if (item is Map && (item['name'] ?? '').toString().trim().isNotEmpty) {
        return item['name'].toString();
      }
    }
    return null;
  }

  String _productName(String barcode) {
    if (barcode.isEmpty) return '';
    try {
      final index = global.findProductByBarcode(barcode);
      if (index != -1) {
        return global.getNameFromLanguage(
          global.productList[index].names,
          global.languageForStaff,
        );
      }
    } catch (_) {}
    return '';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _BillItemsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('Item', style: style)),
          Expanded(flex: 2, child: Text('Qty', style: style)),
          Expanded(flex: 2, child: Text('Price', style: style)),
          Expanded(flex: 2, child: Text('Amount', style: style)),
        ],
      ),
    );
  }
}

class _BillItemRow extends StatelessWidget {
  final _BillDetailLine line;

  const _BillItemRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.00');
    final qty = NumberFormat('#,##0.###');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  [
                    if (line.isChoice) '(choice)',
                    if (line.name.isNotEmpty) line.name,
                    if (line.name.isEmpty) line.barcode,
                  ].join(' '),
                ),
                if (line.name.isNotEmpty)
                  Text(line.barcode,
                      style: Theme.of(context).textTheme.bodySmall),
                if (line.remark.isNotEmpty)
                  Text('Remark: ${line.remark}',
                      style: Theme.of(context).textTheme.bodySmall),
                if (line.discount != 0)
                  Text('Discount: ${money.format(line.discount)}',
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(qty.format(line.qty))),
          Expanded(flex: 2, child: Text(money.format(line.price))),
          Expanded(flex: 2, child: Text(money.format(line.amount))),
        ],
      ),
    );
  }
}

class _BillDetailLine {
  final String barcode;
  final String name;
  final double qty;
  final double price;
  final double amount;
  final double discount;
  final String remark;
  final bool isChoice;

  const _BillDetailLine({
    required this.barcode,
    required this.name,
    required this.qty,
    required this.price,
    required this.amount,
    required this.discount,
    required this.remark,
    this.isChoice = false,
  });
}

class _Summary {
  final int count;
  final int synced;
  final int pending;
  final int failed;
  final int changed;
  final int reprints;
  final double totalAmount;

  const _Summary({
    required this.count,
    required this.synced,
    required this.pending,
    required this.failed,
    required this.changed,
    required this.reprints,
    required this.totalAmount,
  });

  factory _Summary.from(List<BillLedgerModel> ledgers) {
    return _Summary(
      count: ledgers.length,
      totalAmount: ledgers.fold(0, (sum, item) => sum + item.totalAmount),
      synced: ledgers
          .where((e) => e.syncStatus == BillLedgerStatus.paidSyncSuccess)
          .length,
      pending: ledgers
          .where((e) =>
              e.syncStatus == BillLedgerStatus.paidSyncPending ||
              e.syncStatus == 'syncing')
          .length,
      failed: ledgers
          .where((e) =>
              e.syncStatus == BillLedgerStatus.paidSyncFailed ||
              e.syncStatus == BillLedgerStatus.syncFailedNeedAttention)
          .length,
      changed: ledgers
          .where((e) =>
              e.docNoChanged ||
              e.syncStatus == BillLedgerStatus.syncSuccessDocNoChanged)
          .length,
      reprints: ledgers.fold(0, (sum, item) => sum + item.reprintCount),
    );
  }
}
