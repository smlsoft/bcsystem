import 'dart:convert';
import 'dart:io';

import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/model/trans_model.dart';
import 'package:dedekiosk/objectbox/objectbox.g.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/service/bill_ledger_service.dart';
import 'package:dedekiosk/service/bill_ledger_sync_service.dart';
import 'package:dedekiosk/util/client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('bill_ledger_conflict_');
    global.objectBoxStore = Store(getObjectBoxModel(), directory: tempDir.path);
  });

  tearDown(() {
    BillLedgerSyncService().clearTestOverrides();
    global.objectBoxStore.close();
    tempDir.deleteSync(recursive: true);
  });

  test('duplicate doc_no conflict retries with suffix and records change',
      () async {
    const printedDocNo = '97-2605190002';
    final trans = _transactionFixture(printedDocNo);
    final now = DateTime(2026, 5, 19, 12);
    final ledger = BillLedgerModel(
      localBillId: 'local-bill-conflict-1',
      printedDocNo: printedDocNo,
      serverDocNo: printedDocNo,
      syncStatus: BillLedgerStatus.paidSyncPending,
      idempotencyKey: 'KIOSK_LOCAL_BILL_ID=local-bill-conflict-1',
      payloadChecksum: BillLedgerService.checksumPayload(trans.toJson()),
      payloadJson: jsonEncode(trans.toJson()),
      paymentJson: '[]',
      itemsJson: '[]',
      shopId: 'shop-demo',
      branchId: 'branch-demo',
      orderStationCode: '97',
      deviceCode: '97',
      pinHistoryId: 'pin-demo',
      docDateKey: '2026-05-19',
      runningPrefix: '97-260519',
      runningNumber: 2,
      totalAmount: 358,
      totalQty: 1,
      createdAt: now,
      updatedAt: now,
      retentionUntil: now.add(const Duration(days: 365)),
    );
    ledger.id = global.objectBoxStore.box<BillLedgerModel>().put(ledger);

    final submittedDocNos = <String>[];
    final postSyncDocNos = <String>[];
    BillLedgerSyncService().configureTestOverrides(
      serverHasSameBill: (_) async => false,
      postSyncSuccess: (ledger, serverDocNo) async {
        postSyncDocNos.add('${ledger.printedDocNo}->$serverDocNo');
      },
      saveTransaction: (submitted) async {
        submittedDocNos.add(submitted.docno);
        if (submitted.docno == printedDocNo) {
          return ApiResponse(
            success: false,
            error: true,
            data: {},
            message: 'duplicate docno',
          );
        }
        if (submitted.docno == '$printedDocNo-1') {
          return ApiResponse(success: true, error: false, data: {});
        }
        return ApiResponse(
          success: false,
          error: true,
          data: {},
          message: 'unexpected docno ${submitted.docno}',
        );
      },
    );

    final result =
        await BillLedgerSyncService().syncLedger(ledger, force: true);
    final saved = global.objectBoxStore.box<BillLedgerModel>().get(ledger.id)!;
    final savedPayload = jsonDecode(saved.payloadJson) as Map<String, dynamic>;

    expect(result, BillLedgerSingleSyncResult.changedDocNo);
    expect(submittedDocNos, [printedDocNo, '$printedDocNo-1']);
    expect(postSyncDocNos, ['$printedDocNo->$printedDocNo-1']);
    expect(saved.syncStatus, BillLedgerStatus.syncSuccessDocNoChanged);
    expect(saved.docNoChanged, isTrue);
    expect(saved.serverDocNo, '$printedDocNo-1');
    expect(saved.docNoChangeFrom, printedDocNo);
    expect(saved.docNoChangeTo, '$printedDocNo-1');
    expect(saved.docNoChangeReason, 'duplicate_conflict');
    expect(saved.docNoChangeCount, 1);
    expect(saved.lastError, isEmpty);
    expect(savedPayload['docno'], '$printedDocNo-1');
    expect(savedPayload['taxdocno'], '$printedDocNo-1');
  });
}

TransactionModel _transactionFixture(String docNo) {
  final name = TransNameInfoModel(code: 'th', name: 'Test item');
  return TransactionModel(
    cashiercode: 'cashier-demo',
    custcode: '',
    custnames: const [],
    description: 'ORDERSTATION KIOSK_LOCAL_BILL_ID=local-bill-conflict-1',
    details: [
      TransDetailModel(
        averagecost: 0,
        barcode: 'TEST',
        calcflag: 1,
        discount: '',
        discountamount: 0,
        dividevalue: 1,
        docdatetime: '2026-05-19T12:00:00.000',
        docref: '',
        docrefdatetime: null,
        inquirytype: 0,
        ispos: 1,
        itemcode: 'TEST',
        itemguid: 'item-guid',
        itemnames: [name],
        itemtype: 0,
        laststatus: 0,
        linenumber: 1,
        locationcode: '',
        locationnames: const [],
        multiunit: false,
        price: 358,
        priceexcludevat: 358,
        qty: 1,
        remark: '',
        shelfcode: '',
        standvalue: 1,
        sumamount: 358,
        sumamountexcludevat: 358,
        sumofcost: 0,
        taxtype: 0,
        tolocationcode: '',
        tolocationnames: const [],
        totalqty: 1,
        totalvaluevat: 0,
        towhcode: '',
        towhnames: const [],
        unitcode: '',
        unitnames: const [],
        vatcal: 0,
        vattype: 0,
        whcode: '',
        whnames: const [],
      ),
    ],
    discountword: '',
    docdatetime: '2026-05-19T12:00:00.000',
    docno: docNo,
    docrefdate: null,
    docrefno: '',
    docreftype: 0,
    doctype: 0,
    guidref: 'local-bill-conflict-1',
    inquirytype: 0,
    iscancel: false,
    ismanualamount: false,
    ispos: true,
    membercode: '',
    salecode: '',
    salename: '',
    status: 0,
    taxdocdate: '2026-05-19',
    taxdocno: docNo,
    totalaftervat: 358,
    totalamount: 358,
    totalbeforevat: 358,
    totalcost: 0,
    totaldiscount: 0,
    totalexceptvat: 358,
    totalvalue: 358,
    totalvatvalue: 0,
    transflag: 44,
    vatrate: 0,
    vattype: 0,
    paymentdetail: TransPaymentDetailModel(
      cashamount: 358,
      cashamounttext: '358.00',
      paymentcreditcards: const [],
      paymenttransfers: const [],
    ),
    paymentdetailraw: '{}',
    paycashamount: 358,
    totalqty: 1,
  );
}
