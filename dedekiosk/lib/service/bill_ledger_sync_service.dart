import 'dart:async';
import 'dart:convert';

import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/model/trans_model.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/order/order_util.dart' as order_util;
import 'package:dedekiosk/print/print.dart';
import 'package:dedekiosk/service/bill_ledger_service.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/util/client.dart';
import 'package:dedekiosk/util/logger.dart';

typedef SaveTransactionHandler = Future<ApiResponse> Function(
    TransactionModel trans);
typedef ServerHasSameBillHandler = Future<bool> Function(
    BillLedgerModel ledger);
typedef PostSyncSuccessHandler = Future<void> Function(
    BillLedgerModel ledger, String serverDocNo);

class BillLedgerSyncResult {
  final int success;
  final int failed;
  final int skipped;
  final int changedDocNo;

  const BillLedgerSyncResult({
    required this.success,
    required this.failed,
    required this.skipped,
    required this.changedDocNo,
  });
}

class BillLedgerSyncService {
  static final BillLedgerSyncService _instance =
      BillLedgerSyncService._internal();
  factory BillLedgerSyncService() => _instance;
  BillLedgerSyncService._internal();

  final Set<String> _syncingBillIds = {};
  Timer? _timer;
  bool _isRunningBatch = false;
  SaveTransactionHandler? _saveTransactionOverride;
  ServerHasSameBillHandler? _serverHasSameBillOverride;
  PostSyncSuccessHandler? _postSyncSuccessOverride;

  void configureTestOverrides({
    SaveTransactionHandler? saveTransaction,
    ServerHasSameBillHandler? serverHasSameBill,
    PostSyncSuccessHandler? postSyncSuccess,
  }) {
    _saveTransactionOverride = saveTransaction;
    _serverHasSameBillOverride = serverHasSameBill;
    _postSyncSuccessOverride = postSyncSuccess;
  }

  void clearTestOverrides() {
    _saveTransactionOverride = null;
    _serverHasSameBillOverride = null;
    _postSyncSuccessOverride = null;
  }

  void startBackgroundSync() {
    _timer?.cancel();
    final recovered = BillLedgerService().recoverInterruptedSyncs();
    if (recovered > 0) {
      Logger.w('Recovered $recovered interrupted bill ledger syncs',
          tag: 'BillLedger');
    }
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      syncPendingLedgers();
    });
    Logger.i('BillLedgerSyncService started', tag: 'BillLedger');
  }

  void stopBackgroundSync() {
    _timer?.cancel();
    _timer = null;
  }

  Future<BillLedgerSyncResult> syncPendingLedgers({bool force = false}) async {
    if (_isRunningBatch) {
      return const BillLedgerSyncResult(
          success: 0, failed: 0, skipped: 0, changedDocNo: 0);
    }
    _isRunningBatch = true;
    int success = 0;
    int failed = 0;
    int skipped = 0;
    int changedDocNo = 0;
    try {
      final ledgers = global.objectBoxStore.box<BillLedgerModel>().getAll()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (final ledger in ledgers) {
        if (!_shouldSync(ledger, force: force)) {
          skipped++;
          continue;
        }
        final result = await syncLedger(ledger, force: force);
        if (result == BillLedgerSingleSyncResult.success) success++;
        if (result == BillLedgerSingleSyncResult.changedDocNo) {
          success++;
          changedDocNo++;
        }
        if (result == BillLedgerSingleSyncResult.failed) failed++;
        if (result == BillLedgerSingleSyncResult.skipped) skipped++;
      }
      return BillLedgerSyncResult(
          success: success,
          failed: failed,
          skipped: skipped,
          changedDocNo: changedDocNo);
    } finally {
      _isRunningBatch = false;
    }
  }

  Future<BillLedgerSingleSyncResult> syncLedger(BillLedgerModel ledger,
      {bool force = false}) async {
    if (_syncingBillIds.contains(ledger.localBillId)) {
      return BillLedgerSingleSyncResult.skipped;
    }
    if (!_shouldSync(ledger, force: force)) {
      return BillLedgerSingleSyncResult.skipped;
    }

    _syncingBillIds.add(ledger.localBillId);
    final box = global.objectBoxStore.box<BillLedgerModel>();
    try {
      ledger.syncStatus = 'syncing';
      ledger.updatedAt = DateTime.now();
      box.put(ledger);

      final trans = _transactionFromLedger(ledger);
      if (trans == null) {
        _markFailed(
            ledger, 'Ledger payload is not a full saveTransaction payload');
        return BillLedgerSingleSyncResult.failed;
      }

      try {
        final result =
            await _saveTransaction(trans).timeout(const Duration(seconds: 30));
        if (result.success) {
          BillLedgerService().markSyncSuccess(
            localBillId: ledger.localBillId,
            serverDocNo: trans.docno,
            docNoChanged: trans.docno != ledger.printedDocNo,
          );
          await _handlePostSyncSuccess(ledger, trans.docno);
          return trans.docno == ledger.printedDocNo
              ? BillLedgerSingleSyncResult.success
              : BillLedgerSingleSyncResult.changedDocNo;
        }
        final message = result.message ?? 'saveTransaction failed';
        if (_isDuplicateError(message)) {
          return await _resolveDuplicate(ledger, trans);
        }
        _markFailed(ledger, message);
        return BillLedgerSingleSyncResult.failed;
      } catch (e) {
        final message = e.toString();
        if (_isDuplicateError(message)) {
          return await _resolveDuplicate(ledger, trans);
        }
        _markFailed(ledger, message);
        return BillLedgerSingleSyncResult.failed;
      }
    } finally {
      _syncingBillIds.remove(ledger.localBillId);
    }
  }

  bool _shouldSync(BillLedgerModel ledger, {required bool force}) {
    const syncable = {
      BillLedgerStatus.paidSyncPending,
      BillLedgerStatus.paidSyncFailed,
      'syncing',
    };
    if (!syncable.contains(ledger.syncStatus)) return false;
    if (ledger.payloadJson.isEmpty) return false;
    if (force) return true;
    final delay = _retryDelay(ledger.syncAttempts);
    return DateTime.now().difference(ledger.updatedAt) >= delay;
  }

  Duration _retryDelay(int attempts) {
    if (attempts <= 0) return Duration.zero;
    if (attempts == 1) return const Duration(minutes: 1);
    if (attempts == 2) return const Duration(minutes: 3);
    if (attempts == 3) return const Duration(minutes: 5);
    return const Duration(minutes: 10);
  }

  TransactionModel? _transactionFromLedger(BillLedgerModel ledger) {
    try {
      final jsonMap = jsonDecode(ledger.payloadJson);
      if (jsonMap is! Map<String, dynamic>) return null;
      if (!jsonMap.containsKey('details') || !jsonMap.containsKey('docno')) {
        return null;
      }
      return TransactionModel.fromJson(jsonMap);
    } catch (e) {
      Logger.w('Cannot parse ledger payload for ${ledger.printedDocNo}: $e',
          tag: 'BillLedger');
      return null;
    }
  }

  Future<BillLedgerSingleSyncResult> _resolveDuplicate(
      BillLedgerModel ledger, TransactionModel trans) async {
    final sameBill = await _serverHasSameBill(ledger);
    if (sameBill) {
      BillLedgerService().markSyncSuccess(
          localBillId: ledger.localBillId, serverDocNo: ledger.serverDocNo);
      await _handlePostSyncSuccess(ledger, ledger.serverDocNo);
      return BillLedgerSingleSyncResult.success;
    }

    for (int i = ledger.docNoChangeCount + 1; i <= 9; i++) {
      final candidateDocNo = '${ledger.printedDocNo}-$i';
      trans.docno = candidateDocNo;
      trans.taxdocno = candidateDocNo;
      final payload = trans.toJson();
      BillLedgerService().updatePayloadForServerDocNo(
        ledger: ledger,
        payload: payload,
        serverDocNo: candidateDocNo,
      );
      try {
        final result =
            await _saveTransaction(trans).timeout(const Duration(seconds: 30));
        if (result.success) {
          BillLedgerService().markSyncSuccess(
            localBillId: ledger.localBillId,
            serverDocNo: candidateDocNo,
            docNoChanged: true,
          );
          await _handlePostSyncSuccess(ledger, candidateDocNo);
          return BillLedgerSingleSyncResult.changedDocNo;
        }
        if (!_isDuplicateError(result.message ?? '')) {
          _markFailed(ledger, result.message ?? 'saveTransaction failed');
          return BillLedgerSingleSyncResult.failed;
        }
      } catch (e) {
        if (!_isDuplicateError(e.toString())) {
          _markFailed(ledger, e.toString());
          return BillLedgerSingleSyncResult.failed;
        }
      }
    }

    ledger.syncStatus = BillLedgerStatus.syncFailedNeedAttention;
    ledger.lastError =
        'Duplicate conflict could not be resolved after suffix -9';
    ledger.conflictAt = DateTime.now();
    ledger.updatedAt = ledger.conflictAt!;
    global.objectBoxStore.box<BillLedgerModel>().put(ledger);
    return BillLedgerSingleSyncResult.failed;
  }

  Future<bool> _serverHasSameBill(BillLedgerModel ledger) async {
    final override = _serverHasSameBillOverride;
    if (override != null) {
      return override(ledger);
    }
    try {
      final result =
          await api.getTransactionList(limit: 10, search: ledger.serverDocNo);
      final data = result.data;
      if (data is! List) return false;
      for (final item in data) {
        final text = jsonEncode(item);
        if (text.contains(ledger.localBillId) ||
            text.contains(ledger.idempotencyKey)) {
          return true;
        }
        if (item is Map) {
          final docNo = (item['docno'] ?? item['doc_no'] ?? '').toString();
          final totalAmount = double.tryParse(
              (item['totalamount'] ?? item['total_amount'] ?? '').toString());
          if (docNo == ledger.serverDocNo &&
              totalAmount != null &&
              (totalAmount - ledger.totalAmount).abs() <= 0.01) {
            return true;
          }
        }
      }
    } catch (e) {
      Logger.w('Duplicate verification failed for ${ledger.serverDocNo}: $e',
          tag: 'BillLedger');
    }
    return false;
  }

  Future<ApiResponse> _saveTransaction(TransactionModel trans) {
    final override = _saveTransactionOverride;
    if (override != null) {
      return override(trans);
    }
    return api.saveTransaction(trans);
  }

  Future<void> _handlePostSyncSuccess(
      BillLedgerModel ledger, String serverDocNo) async {
    final override = _postSyncSuccessOverride;
    if (override != null) {
      await override(ledger, serverDocNo);
      return;
    }

    try {
      final renamed = await PrinterClass.renameSlipFileForServerDocNo(
        printedDocNo: ledger.printedDocNo,
        serverDocNo: serverDocNo,
      );
      if (renamed) {
        await order_util.uploadSlipWorker();
      } else {
        Logger.w(
            'BillLedger post-sync slip file not found for ${ledger.printedDocNo} -> $serverDocNo',
            tag: 'BillLedger');
      }
    } catch (e, s) {
      Logger.e('BillLedger post-sync slip upload failed',
          error: e, stackTrace: s, tag: 'BillLedger');
    }
  }

  bool _isDuplicateError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('duplicate') ||
        lower.contains('already') ||
        lower.contains('exists') ||
        lower.contains('e11000') ||
        lower.contains('docno') && lower.contains('ซ้ำ');
  }

  void _markFailed(BillLedgerModel ledger, String error) {
    ledger.syncAttempts += 1;
    ledger.lastError = error;
    ledger.syncStatus = BillLedgerStatus.paidSyncFailed;
    ledger.updatedAt = DateTime.now();
    global.objectBoxStore.box<BillLedgerModel>().put(ledger);
  }
}

enum BillLedgerSingleSyncResult {
  success,
  changedDocNo,
  failed,
  skipped,
}
