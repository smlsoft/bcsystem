import 'dart:async';

import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/service/bill_ledger_service.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/util/logger.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KioskStatusReporterService {
  static final KioskStatusReporterService _instance =
      KioskStatusReporterService._internal();
  factory KioskStatusReporterService() => _instance;
  KioskStatusReporterService._internal();

  static const String billStatusTable = 'kiosk_bill_status';
  static const String billStatusLatestView = 'kiosk_bill_status_latest';
  static const String deviceStatusTable = 'kiosk_device_status';
  static const String deviceStatusLatestView = 'kiosk_device_status_latest';

  Timer? _timer;
  bool _isRunning = false;
  bool _missingTableWarningLogged = false;
  int _tick = 0;

  void start() {
    _timer?.cancel();
    unawaited(publishStartupSnapshot());
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_runPeriodic());
    });
    Logger.i('KioskStatusReporterService started', tag: 'KioskStatus');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> publishStartupSnapshot() async {
    await _runExclusive(() async {
      await _publishDeviceStatus();
      await _publishBillStatuses(_todayLedgers(), force: true);
    });
  }

  Future<void> republishBillStatuses({
    DateTime? from,
    DateTime? to,
  }) async {
    await _runExclusive(() async {
      await _publishDeviceStatus();
      await _publishBillStatuses(_ledgersInRange(from: from, to: to),
          force: true);
    });
  }

  Future<void> _runPeriodic() async {
    await _runExclusive(() async {
      await _publishDeviceStatus();
      await _publishBillStatuses(_activeLedgers(), force: false);
      _tick++;
      if (_tick % 15 == 0) {
        await _publishBillStatuses(_todayLedgers(), force: false);
      }
      if (_tick % 360 == 0) {
        await _publishBillStatuses(_todayLedgers(), force: true);
      }
    });
  }

  Future<void> _runExclusive(Future<void> Function() action) async {
    if (_isRunning) return;
    _isRunning = true;
    try {
      if (global.deviceConfig.shopId.isEmpty) return;
      await action();
    } catch (e, s) {
      Logger.e('Kiosk status reporter error',
          error: e, stackTrace: s, tag: 'KioskStatus');
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _publishDeviceStatus() async {
    final ledgers = _allLedgersForCurrentDevice();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final pending = ledgers.where((e) => e.syncStatus == 'paid_sync_pending');
    final failed = ledgers.where((e) =>
        e.syncStatus == 'paid_sync_failed' ||
        e.syncStatus == 'sync_failed_need_attention');
    final syncing = ledgers.where((e) => e.syncStatus == 'syncing');
    final successToday = ledgers.where((e) =>
        e.docDateKey == today &&
        (e.syncStatus == 'paid_sync_success' ||
            e.syncStatus == 'sync_success_docno_changed'));
    final lastBill = ledgers.isEmpty
        ? null
        : (ledgers..sort((a, b) => b.createdAt.compareTo(a.createdAt))).first;
    final lastErrorLedger = ledgers
        .where((e) => e.lastError.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final now = DateTime.now();
    final query = '''
INSERT INTO ${global.clickHouseDatabaseName}.$deviceStatusTable
(shopid, branchid, devicecode, isserver, appversion, status, last_seen_at, pending_bill_count, failed_bill_count, syncing_bill_count, success_bill_count_today, last_bill_doc_no, last_error, updated_at)
VALUES
('${_sql(global.deviceConfig.shopId)}', '${_sql(global.deviceConfig.branchId)}', '${_sql(_deviceCode)}', ${global.deviceConfig.isServer ? 1 : 0}, '${_sql(global.appVersion)}', 'online', ${_dt(now)}, ${pending.length}, ${failed.length}, ${syncing.length}, ${successToday.length}, '${_sql(lastBill?.serverDocNo ?? '')}', '${_sql(lastErrorLedger.isEmpty ? '' : lastErrorLedger.first.lastError)}', ${_dt(now)})
''';
    await _insertStatus(query, 'device status');
  }

  Future<void> _publishBillStatuses(List<BillLedgerModel> ledgers,
      {required bool force}) async {
    if (ledgers.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final values = <String>[];
    final publishedHashes = <String, String>{};
    for (final ledger in ledgers) {
      final statusHash = _statusHash(ledger);
      final hashKey = _publishedHashKey(ledger);
      if (!force && prefs.getString(hashKey) == statusHash) {
        continue;
      }
      values.add(_billStatusValues(ledger, statusHash));
      publishedHashes[hashKey] = statusHash;
    }
    if (values.isEmpty) return;
    await _insertStatus('''
INSERT INTO ${global.clickHouseDatabaseName}.$billStatusTable
(shopid, branchid, devicecode, local_bill_id, printed_doc_no, server_doc_no, sync_status, doc_no_changed, doc_no_change_from, doc_no_change_to, total_amount, total_qty, sync_attempts, last_error, status_hash, created_at, printed_at, synced_at, updated_at, published_at)
VALUES
${values.join(',\n')}
''', 'bill status');
    for (final entry in publishedHashes.entries) {
      await prefs.setString(entry.key, entry.value);
    }
  }

  Future<void> _insertStatus(String query, String label) async {
    final result = await api.clickHouseExecute(query);
    if (result.isEmpty || result['error'] != null) {
      if (!_missingTableWarningLogged) {
        _missingTableWarningLogged = true;
        Logger.w(
          'Cannot publish kiosk $label. Create ClickHouse status tables first. The reporter will retry later.',
          tag: 'KioskStatus',
        );
      }
      throw Exception('ClickHouse insert failed: $label');
    }
    _missingTableWarningLogged = false;
  }

  List<BillLedgerModel> _activeLedgers() {
    final syncStatuses = {
      'paid_sync_pending',
      'paid_sync_failed',
      'syncing',
      'sync_failed_need_attention',
    };
    return _allLedgersForCurrentDevice()
        .where((ledger) => syncStatuses.contains(ledger.syncStatus))
        .toList();
  }

  List<BillLedgerModel> _todayLedgers() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _allLedgersForCurrentDevice()
        .where((ledger) => ledger.docDateKey == today)
        .toList();
  }

  List<BillLedgerModel> _ledgersInRange({DateTime? from, DateTime? to}) {
    final start =
        from == null ? null : DateTime(from.year, from.month, from.day);
    final end = to == null
        ? null
        : DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
    return _allLedgersForCurrentDevice().where((ledger) {
      if (start != null && ledger.createdAt.isBefore(start)) return false;
      if (end != null && !ledger.createdAt.isBefore(end)) return false;
      return true;
    }).toList();
  }

  List<BillLedgerModel> _allLedgersForCurrentDevice() {
    return global.objectBoxStore
        .box<BillLedgerModel>()
        .getAll()
        .where((ledger) {
      return ledger.shopId == global.deviceConfig.shopId &&
          ledger.branchId == global.deviceConfig.branchId &&
          ledger.orderStationCode == global.deviceConfig.orderStationCode;
    }).toList();
  }

  String _billStatusValues(BillLedgerModel ledger, String statusHash) {
    return "('${_sql(ledger.shopId)}', '${_sql(ledger.branchId)}', '${_sql(ledger.orderStationCode)}', '${_sql(ledger.localBillId)}', '${_sql(ledger.printedDocNo)}', '${_sql(ledger.serverDocNo)}', '${_sql(ledger.syncStatus)}', ${ledger.docNoChanged ? 1 : 0}, '${_sql(ledger.docNoChangeFrom)}', '${_sql(ledger.docNoChangeTo)}', ${ledger.totalAmount}, ${ledger.totalQty}, ${ledger.syncAttempts}, '${_sql(ledger.lastError)}', '$statusHash', ${_dt(ledger.createdAt)}, ${_nullableDt(ledger.printedAt)}, ${_nullableDt(ledger.syncedAt)}, ${_dt(ledger.updatedAt)}, ${_dt(DateTime.now())})";
  }

  String _statusHash(BillLedgerModel ledger) {
    return BillLedgerService.checksumPayload({
      'shopid': ledger.shopId,
      'branchid': ledger.branchId,
      'devicecode': ledger.orderStationCode,
      'local_bill_id': ledger.localBillId,
      'printed_doc_no': ledger.printedDocNo,
      'server_doc_no': ledger.serverDocNo,
      'sync_status': ledger.syncStatus,
      'doc_no_changed': ledger.docNoChanged,
      'doc_no_change_from': ledger.docNoChangeFrom,
      'doc_no_change_to': ledger.docNoChangeTo,
      'total_amount': ledger.totalAmount,
      'total_qty': ledger.totalQty,
      'sync_attempts': ledger.syncAttempts,
      'last_error': ledger.lastError,
      'updated_at': ledger.updatedAt.toIso8601String(),
    });
  }

  String _publishedHashKey(BillLedgerModel ledger) {
    return 'kiosk_bill_status_hash|${ledger.shopId}|${ledger.branchId}|${ledger.orderStationCode}|${ledger.localBillId}';
  }

  String get _deviceCode {
    if (global.deviceConfig.orderStationCode.isNotEmpty) {
      return global.deviceConfig.orderStationCode;
    }
    return global.shopProfile?.orderstation.deviceinfo.code ?? '';
  }

  String _sql(String value) => value.replaceAll("'", "''");

  String _dt(DateTime value) {
    return "'${DateFormat('yyyy-MM-dd HH:mm:ss').format(value)}'";
  }

  String _nullableDt(DateTime? value) {
    return value == null ? 'NULL' : _dt(value);
  }
}
