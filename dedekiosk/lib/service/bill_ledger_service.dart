import 'dart:convert';
import 'dart:math';

import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/util/logger.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class BillLedgerStatus {
  static const created = 'created';
  static const printed = 'printed';
  static const paidSyncPending = 'paid_sync_pending';
  static const paidSyncFailed = 'paid_sync_failed';
  static const paidSyncSuccess = 'paid_sync_success';
  static const syncSuccessDocNoChanged = 'sync_success_docno_changed';
  static const syncFailedNeedAttention = 'sync_failed_need_attention';
  // ===== Pay-at-Cashier: order ถูกพิมพ์ QR slip แล้ว รอ cashier รับชำระ =====
  static const pendingCashier = 'pending_cashier';
}

class BillLedgerService {
  static final BillLedgerService _instance = BillLedgerService._internal();
  factory BillLedgerService() => _instance;
  BillLedgerService._internal();

  static const _idempotencyPrefix = 'KIOSK_LOCAL_BILL_ID=';

  Future<String> reserveNextDocNo(
      {Duration serverTimeout = const Duration(seconds: 3)}) async {
    final docParts = _buildDocFormatParts();
    final localRunning = _getLocalLatestRunning(docParts);
    final serverRunning =
        await _getServerLatestRunning(docParts, serverTimeout);
    final nextRunning = max(localRunning, serverRunning) + 1;
    return '${docParts.prefix}${NumberFormat(docParts.digitFormat).format(nextRunning)}';
  }

  BillLedgerModel createPaidLedger({
    required String printedDocNo,
    required int queueNumber,
    required String orderTagNumber,
    required int orderType,
    required DateTime docDateTime,
    required BillCalcAmount bill,
    required List<OrderTempDetailModel> orderTempDetailList,
    required List<PayConditionModel> payCondition,
    required String orderId,
    required String saleChannelCode,
    required String pinHistoryId,
  }) {
    final now = DateTime.now();
    final docParts = _buildDocFormatParts();
    final localBillId = const Uuid().v4();
    final paymentJson =
        jsonEncode(payCondition.map(_payConditionToJson).toList());
    final itemsJson =
        jsonEncode(orderTempDetailList.map(_orderDetailToJson).toList());
    final totalQty =
        orderTempDetailList.fold<double>(0, (sum, item) => sum + item.qty);
    final payload = <String, dynamic>{
      'localBillId': localBillId,
      'idempotencyKey': '$_idempotencyPrefix$localBillId',
      'printedDocNo': printedDocNo,
      'serverDocNo': printedDocNo,
      'orderId': orderId,
      'queueNumber': queueNumber,
      'orderTagNumber': orderTagNumber,
      'orderType': orderType,
      'docDateTime': docDateTime.toUtc().toIso8601String(),
      'shopId': global.deviceConfig.shopId,
      'branchId': global.deviceConfig.branchId,
      'orderStationCode': global.deviceConfig.orderStationCode,
      'deviceCode': global.shopProfile?.orderstation.deviceinfo.code ?? '',
      'saleChannelCode': saleChannelCode,
      'totalAmount': bill.totalAmount,
      'totalVatAmount': bill.totalVatAmount,
      'totalDiscount': bill.totalDiscount,
      'totalQty': totalQty,
      'payment': payCondition.map(_payConditionToJson).toList(),
      'items': orderTempDetailList.map(_orderDetailToJson).toList(),
    };
    final payloadJson = jsonEncode(payload);
    final checksum = checksumPayload(payload);
    final ledger = BillLedgerModel(
      localBillId: localBillId,
      printedDocNo: printedDocNo,
      serverDocNo: printedDocNo,
      syncStatus: BillLedgerStatus.created,
      idempotencyKey: '$_idempotencyPrefix$localBillId',
      payloadChecksum: checksum,
      payloadJson: payloadJson,
      paymentJson: paymentJson,
      itemsJson: itemsJson,
      shopId: global.deviceConfig.shopId,
      branchId: global.deviceConfig.branchId,
      orderStationCode: global.deviceConfig.orderStationCode,
      deviceCode: global.shopProfile?.orderstation.deviceinfo.code ?? '',
      pinHistoryId: pinHistoryId,
      docDateKey: docParts.dateKey,
      runningPrefix: docParts.prefix,
      runningNumber: _extractRunning(printedDocNo, docParts) ?? 0,
      totalAmount: bill.totalAmount,
      totalQty: totalQty,
      createdAt: now,
      updatedAt: now,
      retentionUntil: now.add(const Duration(days: 365)),
    );
    final id = global.objectBoxStore.box<BillLedgerModel>().put(ledger);
    ledger.id = id;
    Logger.i('BillLedger created: $printedDocNo localBillId=$localBillId',
        tag: 'BillLedger');
    return ledger;
  }

  void updatePayload({
    required String localBillId,
    required Map<String, dynamic> payload,
  }) {
    final ledger = _findByLocalBillId(localBillId);
    if (ledger == null) return;
    ledger.payloadJson = jsonEncode(payload);
    ledger.payloadChecksum = checksumPayload(payload);
    ledger.updatedAt = DateTime.now();
    global.objectBoxStore.box<BillLedgerModel>().put(ledger);
  }

  void updatePayloadForServerDocNo({
    required BillLedgerModel ledger,
    required Map<String, dynamic> payload,
    required String serverDocNo,
  }) {
    ledger.serverDocNo = serverDocNo;
    ledger.payloadJson = jsonEncode(payload);
    ledger.payloadChecksum = checksumPayload(payload);
    ledger.updatedAt = DateTime.now();
    global.objectBoxStore.box<BillLedgerModel>().put(ledger);
  }

  void markPrinted(BillLedgerModel ledger) {
    ledger.printedAt = DateTime.now();
    ledger.updatedAt = ledger.printedAt!;
    ledger.syncStatus = BillLedgerStatus.paidSyncPending;
    global.objectBoxStore.box<BillLedgerModel>().put(ledger);
  }

  // ===== Pay-at-Cashier methods =====

  // NOTE: pending-cashier ledger methods (createPendingCashierLedger, markCashierSlipPrinted,
  // findPendingCashierByDocNo, markCashierPaid) ถูกลบออกใน re-architect ใหม่
  // เพราะ origin device ไม่สร้าง ledger pendingCashier อีกต่อไป — pending-cashier = "ใบแจ้งยอด stub"
  // ใน ClickHouse paylater tables เท่านั้น; cashier settle = เข้า payAndSave(payNow:true) เต็มรูปแบบ
  // ซึ่งสร้าง ledger ปกติผ่าน createPaidLedger อยู่แล้ว

  void markSyncing(String localBillId) {
    final ledger = _findByLocalBillId(localBillId);
    if (ledger == null) return;
    ledger.syncStatus = 'syncing';
    ledger.updatedAt = DateTime.now();
    global.objectBoxStore.box<BillLedgerModel>().put(ledger);
  }

  void markSyncSuccess({
    required String localBillId,
    required String serverDocNo,
    bool docNoChanged = false,
  }) {
    final ledger = _findByLocalBillId(localBillId);
    if (ledger == null) return;
    final now = DateTime.now();
    ledger.serverDocNo = serverDocNo;
    ledger.syncedAt = now;
    ledger.updatedAt = now;
    ledger.lastError = '';
    ledger.docNoChanged = docNoChanged;
    if (docNoChanged) {
      ledger.docNoChangeFrom = ledger.printedDocNo;
      ledger.docNoChangeTo = serverDocNo;
      ledger.docNoChangeReason = 'duplicate_conflict';
      ledger.docNoChangeCount += 1;
      ledger.syncStatus = BillLedgerStatus.syncSuccessDocNoChanged;
    } else {
      ledger.syncStatus = BillLedgerStatus.paidSyncSuccess;
    }
    global.objectBoxStore.box<BillLedgerModel>().put(ledger);
  }

  void markSyncFailed({
    required String localBillId,
    required String error,
  }) {
    final ledger = _findByLocalBillId(localBillId);
    if (ledger == null) return;
    ledger.syncAttempts += 1;
    ledger.lastError = error;
    ledger.updatedAt = DateTime.now();
    ledger.syncStatus = BillLedgerStatus.paidSyncFailed;
    global.objectBoxStore.box<BillLedgerModel>().put(ledger);
  }

  void markReprinted(String localBillId) {
    final ledger = _findByLocalBillId(localBillId);
    if (ledger == null) return;
    final now = DateTime.now();
    ledger.reprintCount += 1;
    ledger.lastReprintAt = now;
    ledger.updatedAt = now;
    global.objectBoxStore.box<BillLedgerModel>().put(ledger);
  }

  int recoverInterruptedSyncs(
      {Duration staleAfter = const Duration(minutes: 3)}) {
    final now = DateTime.now();
    int recovered = 0;
    final box = global.objectBoxStore.box<BillLedgerModel>();
    for (final ledger in box.getAll()) {
      if (ledger.syncStatus != 'syncing') continue;
      if (now.difference(ledger.updatedAt) < staleAfter) continue;
      ledger.syncStatus = BillLedgerStatus.paidSyncFailed;
      ledger.lastError = 'Recovered from interrupted sync';
      ledger.updatedAt = now;
      box.put(ledger);
      recovered++;
    }
    return recovered;
  }

  int cleanupExpiredSyncedLedgers({DateTime? now}) {
    final cutoffNow = now ?? DateTime.now();
    final box = global.objectBoxStore.box<BillLedgerModel>();
    final removable = box
        .getAll()
        .where((ledger) {
          final isSynced =
              ledger.syncStatus == BillLedgerStatus.paidSyncSuccess ||
                  ledger.syncStatus == BillLedgerStatus.syncSuccessDocNoChanged;
          return isSynced && ledger.retentionUntil.isBefore(cutoffNow);
        })
        .map((ledger) => ledger.id)
        .toList();
    if (removable.isEmpty) return 0;
    box.removeMany(removable);
    return removable.length;
  }

  static String checksumPayload(Map<String, dynamic> payload) {
    final canonical = jsonEncode(_sortJson(payload));
    const int fnvPrime = 0x01000193;
    int hash = 0x811c9dc5;
    for (final unit in utf8.encode(canonical)) {
      hash ^= unit;
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  BillLedgerModel? _findByLocalBillId(String localBillId) {
    if (localBillId.isEmpty) return null;
    final box = global.objectBoxStore.box<BillLedgerModel>();
    for (final ledger in box.getAll()) {
      if (ledger.localBillId == localBillId) {
        return ledger;
      }
    }
    return null;
  }

  int _getLocalLatestRunning(_DocFormatParts parts) {
    int latest = 0;
    final box = global.objectBoxStore.box<BillLedgerModel>();
    for (final ledger in box.getAll()) {
      if (ledger.shopId != global.deviceConfig.shopId ||
          ledger.branchId != global.deviceConfig.branchId ||
          ledger.orderStationCode != global.deviceConfig.orderStationCode ||
          ledger.docDateKey != parts.dateKey) {
        continue;
      }
      latest = max(latest, _extractRunning(ledger.printedDocNo, parts) ?? 0);
      latest = max(latest, _extractRunning(ledger.serverDocNo, parts) ?? 0);
    }
    return latest;
  }

  Future<int> _getServerLatestRunning(
      _DocFormatParts parts, Duration timeout) async {
    try {
      final response = await api
          .serverGetLastDocNumber(
              docNumber: '${parts.prefix}${parts.lastDigit}')
          .timeout(timeout);
      final docNo = (response['data'] ?? '').toString();
      return _extractRunning(docNo, parts) ?? 0;
    } catch (e) {
      Logger.w(
          'BillLedger server latest doc no unavailable, using local running: $e',
          tag: 'BillLedger');
      return 0;
    }
  }

  _DocFormatParts _buildDocFormatParts() {
    final shopProfile = global.shopProfile;
    if (shopProfile == null) {
      throw StateError('shopProfile is required to reserve doc no');
    }
    final orderFormat =
        '${shopProfile.orderstation.deviceinfo.code}-${shopProfile.orderstation.deviceinfo.docformat}';
    final now = DateTime.now();
    final dateCompact = DateFormat('yyyyMMdd').format(now);
    String digitFormat = '';
    String lastDigit = '';
    for (final item in orderFormat.split('')) {
      if (item == '#') {
        digitFormat += '0';
        lastDigit += '9';
      }
    }
    String prefix = orderFormat.replaceAll('#', '');
    prefix = prefix.replaceAll('YYYY', dateCompact.substring(0, 4));
    prefix = prefix.replaceAll('YY', dateCompact.substring(2, 4));
    prefix = prefix.replaceAll('MM', dateCompact.substring(4, 6));
    prefix = prefix.replaceAll('DD', dateCompact.substring(6, 8));
    return _DocFormatParts(
      prefix: prefix,
      digitFormat: digitFormat,
      lastDigit: lastDigit,
      dateKey: DateFormat('yyyy-MM-dd').format(now),
    );
  }

  int? _extractRunning(String docNo, _DocFormatParts parts) {
    if (docNo.isEmpty ||
        !docNo.startsWith(parts.prefix) ||
        parts.digitFormat.isEmpty) {
      return null;
    }
    final start = parts.prefix.length;
    final end = start + parts.digitFormat.length;
    if (docNo.length < end) return null;
    return int.tryParse(docNo.substring(start, end));
  }

  static dynamic _sortJson(dynamic value) {
    if (value is Map) {
      final sorted = <String, dynamic>{};
      final keys = value.keys.map((e) => e.toString()).toList()..sort();
      for (final key in keys) {
        sorted[key] = _sortJson(value[key]);
      }
      return sorted;
    }
    if (value is List) {
      return value.map(_sortJson).toList();
    }
    return value;
  }

  Map<String, dynamic> _payConditionToJson(PayConditionModel pay) {
    return {
      'payType': pay.payType,
      'payTypeName': pay.payTypeName,
      'amount': pay.amount,
      'payAmount': pay.payAmount,
      'changeAmount': pay.changeAmount,
      'roundAmount': pay.roundAmount,
      'approvalCode': pay.approvalCode,
      'cardNumber': pay.cardNumber,
    };
  }

  Map<String, dynamic> _orderDetailToJson(OrderTempDetailModel item) {
    return {
      'orderguid': item.orderguid,
      'barcode': item.barcode,
      'qty': item.qty,
      'price': item.price,
      'amount': item.amount,
      'optionamount': item.optionamount,
      'discountamount': item.discountamount,
      'optionselected': item.optionselected,
      'remark': item.remark,
      'istakeaway': item.istakeaway,
      'salechannelcode': item.salechannelcode,
    };
  }
}

class _DocFormatParts {
  final String prefix;
  final String digitFormat;
  final String lastDigit;
  final String dateKey;

  _DocFormatParts({
    required this.prefix,
    required this.digitFormat,
    required this.lastDigit,
    required this.dateKey,
  });
}
