import 'dart:async';
import 'dart:convert';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/trans_model.dart';
import 'package:dedekiosk/objectbox/objectbox.g.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/util/logger.dart';
import 'package:flutter/material.dart';

/// Service สำหรับจัดการ transaction ที่ save offline เมื่อ connection มีปัญหา
class OfflineTransactionService {
  static final OfflineTransactionService _instance = OfflineTransactionService._internal();
  factory OfflineTransactionService() => _instance;
  OfflineTransactionService._internal();

  Timer? _syncTimer;
  bool _isSyncing = false;

  /// เริ่ม background sync timer
  void startBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      syncPendingTransactions();
    });
    Logger.d('OfflineTransactionService: Background sync started');
  }

  /// หยุด background sync timer
  void stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    Logger.d('OfflineTransactionService: Background sync stopped');
  }

  /// บันทึก transaction ลง local storage (ObjectBox)
  /// BC Member data จะถูกส่งแยกเพราะไม่ได้เก็บใน TransactionModel
  Future<int> saveTransactionOffline(
    TransactionModel trans, {
    // BC Member optional parameters
    String memberPinCode = '',
    bool isBCMember = false,
    double getPoint = 0,
    double usePoint = 0,
    String shopName = '',
  }) async {
    try {
      final box = global.objectBoxStore.box<TransactionObjModel>();

      final offlineTrans = TransactionObjModel(
        cashiercode: trans.cashiercode,
        custcode: trans.custcode,
        custnamesJson: jsonEncode(trans.custnames.map((e) => e.toJson()).toList()),
        branchJson: jsonEncode(trans.branch.toJson()),
        detailsJson: jsonEncode(trans.details.map((e) => e.toJson()).toList()),
        paymentdetailJson: jsonEncode(trans.paymentdetail.toJson()),
        issync: false,
        description: trans.description,
        discountword: trans.discountword,
        docdatetime: trans.docdatetime,
        docno: trans.docno,
        docrefdate: trans.docrefdate,
        docrefno: trans.docrefno,
        docreftype: trans.docreftype,
        doctype: trans.doctype,
        guidref: trans.guidref,
        inquirytype: trans.inquirytype,
        iscancel: trans.iscancel,
        ismanualamount: trans.ismanualamount,
        ispos: trans.ispos,
        posid: trans.posid,
        membercode: trans.membercode,
        salecode: trans.salecode,
        salename: trans.salename,
        status: trans.status,
        taxdocdate: trans.taxdocdate,
        taxdocno: trans.taxdocno,
        totalaftervat: trans.totalaftervat,
        totalamount: trans.totalamount,
        totalbeforevat: trans.totalbeforevat,
        totalcost: trans.totalcost,
        totaldiscount: trans.totaldiscount,
        totalexceptvat: trans.totalexceptvat,
        totalvalue: trans.totalvalue,
        totalvatvalue: trans.totalvatvalue,
        paycashamount: trans.paycashamount,
        transflag: trans.transflag,
        vatrate: trans.vatrate,
        vattype: trans.vattype,
        paymentdetailraw: trans.paymentdetailraw,
        billtaxtype: trans.billtaxtype,
        buffetcode: trans.buffetcode,
        detaildiscountformula: trans.detaildiscountformula,
        detailtotalamount: trans.detailtotalamount,
        detailtotalamountbeforediscount: trans.detailtotalamountbeforediscount,
        detailtotaldiscount: trans.detailtotaldiscount,
        isvatregister: trans.isvatregister,
        paycashchange: trans.paycashchange,
        roundamount: trans.roundamount,
        sumcheque: trans.sumcheque,
        sumcoupon: trans.sumcoupon,
        sumcreditcard: trans.sumcreditcard,
        summoneytransfer: trans.summoneytransfer,
        sumqrcode: trans.sumqrcode,
        sumcredit: trans.sumcredit,
        totalamountafterdiscount: trans.totalamountafterdiscount,
        totaldiscountexceptvatamount: trans.totaldiscountexceptvatamount,
        totaldiscountvatamount: trans.totaldiscountvatamount,
        totalqty: trans.totalqty,
        takeaway: trans.takeaway,
        salechannelcode: trans.salechannelcode,
        salechannelgp: trans.salechannelgp, salechannelgptype: trans.salechannelgptype,
        isdelivery: trans.isdelivery,
        deliveryamount: trans.deliveryamount,
        // BC Member fields
        memberPinCode: memberPinCode,
        isBCMember: isBCMember,
        getPoint: getPoint,
        usePoint: usePoint,
        shopName: shopName,
      );

      final id = box.put(offlineTrans);
      Logger.d('OfflineTransactionService: Saved transaction offline - ID: $id, DocNo: ${trans.docno}');
      return id;
    } catch (e, s) {
      Logger.e('OfflineTransactionService: Failed to save offline', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// แปลง TransactionObjModel กลับเป็น TransactionModel
  TransactionModel _convertToTransactionModel(TransactionObjModel obj) {
    return TransactionModel(
      cashiercode: obj.cashiercode,
      custcode: obj.custcode,
      custnames: obj.custnames,
      branch: obj.branch,
      details: obj.details,
      paymentdetail: obj.paymentdetail,
      description: obj.description,
      discountword: obj.discountword,
      docdatetime: obj.docdatetime,
      docno: obj.docno,
      docrefdate: obj.docrefdate,
      docrefno: obj.docrefno,
      docreftype: obj.docreftype,
      doctype: obj.doctype,
      guidref: obj.guidref,
      inquirytype: obj.inquirytype,
      iscancel: obj.iscancel,
      ismanualamount: obj.ismanualamount,
      ispos: obj.ispos,
      posid: obj.posid,
      membercode: obj.membercode,
      salecode: obj.salecode,
      salename: obj.salename,
      status: obj.status,
      taxdocdate: obj.taxdocdate,
      taxdocno: obj.taxdocno,
      totalaftervat: obj.totalaftervat,
      totalamount: obj.totalamount,
      totalbeforevat: obj.totalbeforevat,
      totalcost: obj.totalcost,
      totaldiscount: obj.totaldiscount,
      totalexceptvat: obj.totalexceptvat,
      totalvalue: obj.totalvalue,
      totalvatvalue: obj.totalvatvalue,
      paycashamount: obj.paycashamount,
      transflag: obj.transflag,
      vatrate: obj.vatrate,
      vattype: obj.vattype,
      paymentdetailraw: obj.paymentdetailraw,
      billtaxtype: obj.billtaxtype,
      buffetcode: obj.buffetcode,
      detaildiscountformula: obj.detaildiscountformula,
      detailtotalamount: obj.detailtotalamount,
      detailtotalamountbeforediscount: obj.detailtotalamountbeforediscount,
      detailtotaldiscount: obj.detailtotaldiscount,
      isvatregister: obj.isvatregister,
      paycashchange: obj.paycashchange,
      roundamount: obj.roundamount,
      sumcheque: obj.sumcheque,
      sumcoupon: obj.sumcoupon,
      sumcreditcard: obj.sumcreditcard,
      summoneytransfer: obj.summoneytransfer,
      sumqrcode: obj.sumqrcode,
      sumcredit: obj.sumcredit,
      totalamountafterdiscount: obj.totalamountafterdiscount,
      totaldiscountexceptvatamount: obj.totaldiscountexceptvatamount,
      totaldiscountvatamount: obj.totaldiscountvatamount,
      totalqty: obj.totalqty,
      takeaway: obj.takeaway,
      salechannelcode: obj.salechannelcode,
      salechannelgp: obj.salechannelgp,
      salechannelgptype: obj.salechannelgptype,
      isdelivery: obj.isdelivery,
      deliveryamount: obj.deliveryamount,
    );
  }

  /// ดึง pending transactions ที่ยังไม่ได้ sync
  List<TransactionObjModel> getPendingTransactions() {
    try {
      final box = global.objectBoxStore.box<TransactionObjModel>();
      final query = box.query(TransactionObjModel_.issync.equals(false)).build();
      final results = query.find();
      query.close();
      return results;
    } catch (e, s) {
      Logger.e('OfflineTransactionService: Failed to get pending transactions', error: e, stackTrace: s);
      return [];
    }
  }

  /// นับจำนวน pending transactions
  int getPendingCount() {
    try {
      final box = global.objectBoxStore.box<TransactionObjModel>();
      final query = box.query(TransactionObjModel_.issync.equals(false)).build();
      final count = query.count();
      query.close();
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Sync pending transactions ไปยัง server
  Future<SyncResult> syncPendingTransactions() async {
    if (_isSyncing) {
      Logger.d('OfflineTransactionService: Already syncing, skipping...');
      return SyncResult(success: 0, failed: 0, pending: getPendingCount());
    }

    _isSyncing = true;
    int successCount = 0;
    int failedCount = 0;

    try {
      final pendingList = getPendingTransactions();

      if (pendingList.isEmpty) {
        Logger.d('OfflineTransactionService: No pending transactions to sync');
        return SyncResult(success: 0, failed: 0, pending: 0);
      }

      Logger.d('OfflineTransactionService: Syncing ${pendingList.length} pending transactions...');

      for (var offlineTrans in pendingList) {
        try {
          final trans = _convertToTransactionModel(offlineTrans);
          final apiResult = await api.saveTransaction(trans).timeout(
                const Duration(seconds: 30),
                onTimeout: () => throw TimeoutException('Sync timeout'),
              );
          if (apiResult.success) {
            // Mark as synced
            offlineTrans.issync = true;
            global.objectBoxStore.box<TransactionObjModel>().put(offlineTrans);
            successCount++;
            Logger.d('OfflineTransactionService: Synced transaction - DocNo: ${offlineTrans.docno}'); // ✅ BC Member: ส่ง Sale Invoice หลังจาก sync สำเร็จ
            if (offlineTrans.isBCMember && offlineTrans.memberPinCode.isNotEmpty) {
              try {
                Logger.i('🔵 BC Member (Offline Sync): Sending sale invoice for docNo=${offlineTrans.docno}, amount=${offlineTrans.totalamount}', tag: 'BCMember');
                final saleInvoiceResult = await api.sendBCMemberSaleInvoice(
                  lineUid: offlineTrans.memberPinCode,
                  docNo: offlineTrans.docno,
                  amount: offlineTrans.totalamount,
                  usePoint: offlineTrans.usePoint,
                );
                if (saleInvoiceResult['success'] == true) {
                  Logger.i('✅ BC Member sale invoice sent (offline sync): ${offlineTrans.docno}', tag: 'BCMember');
                } else {
                  Logger.w('⚠️ BC Member sale invoice failed (offline sync): ${saleInvoiceResult['message']}', tag: 'BCMember');
                }
              } catch (bcError) {
                Logger.e('❌ BC Member sale invoice error (offline sync)', error: bcError, tag: 'BCMember');
              }
            }
          } else {
            failedCount++;
            Logger.w('OfflineTransactionService: Failed to sync - DocNo: ${offlineTrans.docno}, Error: ${apiResult.message}');
          }
        } catch (e, s) {
          failedCount++;
          Logger.e('OfflineTransactionService: Error syncing transaction', error: e, stackTrace: s);
        }
      }

      Logger.d('OfflineTransactionService: Sync completed - Success: $successCount, Failed: $failedCount');
      return SyncResult(success: successCount, failed: failedCount, pending: getPendingCount());
    } finally {
      _isSyncing = false;
    }
  }

  /// ลบ transactions ที่ sync แล้ว (เก็บไว้ 7 วัน)
  Future<int> cleanupSyncedTransactions({int daysToKeep = 7}) async {
    try {
      final box = global.objectBoxStore.box<TransactionObjModel>();
      final query = box.query(TransactionObjModel_.issync.equals(true)).build();
      final syncedList = query.find();
      query.close();

      int removedCount = 0;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      for (var trans in syncedList) {
        try {
          final transDate = DateTime.parse(trans.docdatetime);
          if (transDate.isBefore(cutoffDate)) {
            box.remove(trans.id);
            removedCount++;
          }
        } catch (e) {
          // Skip if date parse fails
        }
      }

      Logger.d('OfflineTransactionService: Cleaned up $removedCount old synced transactions');
      return removedCount;
    } catch (e, s) {
      Logger.e('OfflineTransactionService: Cleanup failed', error: e, stackTrace: s);
      return 0;
    }
  }
}

/// ผลลัพธ์การ sync
class SyncResult {
  final int success;
  final int failed;
  final int pending;

  SyncResult({required this.success, required this.failed, required this.pending});

  bool get hasFailures => failed > 0;
  bool get hasPending => pending > 0;
  int get total => success + failed;
}

/// Widget สำหรับแสดงสถานะ pending transactions
class PendingSyncIndicator extends StatefulWidget {
  const PendingSyncIndicator({super.key});

  @override
  State<PendingSyncIndicator> createState() => _PendingSyncIndicatorState();
}

class _PendingSyncIndicatorState extends State<PendingSyncIndicator> {
  int _pendingCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _updateCount();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateCount();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _updateCount() {
    if (mounted) {
      setState(() {
        _pendingCount = OfflineTransactionService().getPendingCount();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingCount == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        // Manual sync
        final result = await OfflineTransactionService().syncPendingTransactions();
        _updateCount();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.success > 0 ? 'Synced ${result.success} transactions${result.hasPending ? ", ${result.pending} pending" : ""}' : 'Sync failed, ${result.pending} pending',
              ),
              backgroundColor: result.success > 0 ? Colors.green : Colors.orange,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_upload, size: 16, color: Colors.orange.shade700),
            const SizedBox(width: 6),
            Text(
              '$_pendingCount pending',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
