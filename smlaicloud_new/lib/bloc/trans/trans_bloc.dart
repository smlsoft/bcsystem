import 'dart:convert';

import 'package:smlaicloud/global.dart';
import 'package:smlaicloud/model/global_model.dart';
import 'package:smlaicloud/model/transaction_model.dart';
import 'package:smlaicloud/repositories/client.dart';
import 'package:smlaicloud/repositories/trans_repository.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:smlaicloud/global.dart' as global;

part 'trans_event.dart';
part 'trans_state.dart';

class TransBloc extends Bloc<TransEvent, TransState> {
  final TransRepository _transRepository;

  TransBloc({required TransRepository transRepository})
      : _transRepository = transRepository,
        super(TransInitial()) {
    on<TransLoad>(onTransLoad);
    on<TransSave>(onTransSave);
    on<TransUpdate>(onTransUpdate);
    on<TransDelete>(onTransDelete);
    on<TransCreateFullInvoice>(onTransCreateFullInvoice);
  }

  void onTransLoad(TransLoad event, Emitter<TransState> emit) async {
    emit(TransInProgress());

    try {
      late ApiResponse<dynamic> results;
      if (event.type == TransactionTypeEnum.purchase) {
        results = await _transRepository.getPurchaseList(limit: event.limit, offset: event.offset, search: event.search, custcode: event.custcode);
      } else if (event.type == TransactionTypeEnum.purchasereturn) {
        results = await _transRepository.getPurchaseReturnList(limit: event.limit, offset: event.offset, search: event.search, custcode: event.custcode);
      } else if (event.type == TransactionTypeEnum.sale) {
        results = await _transRepository.getSaleList(limit: event.limit, offset: event.offset, search: event.search, custcode: event.custcode, ispos: event.ispos!);
      } else if (event.type == TransactionTypeEnum.salereturn) {
        results = await _transRepository.getSaleReturnList(limit: event.limit, offset: event.offset, search: event.search, custcode: event.custcode);
      } else if (event.type == TransactionTypeEnum.adjust) {
        results = await _transRepository.getAdjustList(limit: event.limit, offset: event.offset, search: event.search);
      } else if (event.type == TransactionTypeEnum.stockpickupproduct) {
        results = await _transRepository.getStockPickupList(limit: event.limit, offset: event.offset, search: event.search);
      } else if (event.type == TransactionTypeEnum.stockreceiveproduct) {
        results = await _transRepository.getStockReceiveList(limit: event.limit, offset: event.offset, search: event.search);
      } else if (event.type == TransactionTypeEnum.stockreturnproduct) {
        results = await _transRepository.getStockReturnList(limit: event.limit, offset: event.offset, search: event.search);
      } else if (event.type == TransactionTypeEnum.stocktransfer) {
        results = await _transRepository.getTransferList(limit: event.limit, offset: event.offset, search: event.search);
      } else if (event.type == TransactionTypeEnum.paid) {
        results = await _transRepository.getSaleByCode(limit: event.limit, offset: event.offset, custcode: event.search);
      } else if (event.type == TransactionTypeEnum.pay) {
        results = await _transRepository.getPurchaseByCode(limit: event.limit, offset: event.offset, custcode: event.search);
      } else if (event.type == TransactionTypeEnum.stockbalance) {
        results = await _transRepository.getStockBalanceList(limit: event.limit, offset: event.offset, search: event.search, custcode: event.custcode);
      } else if (event.type == TransactionTypeEnum.saleorder) {
        results = await _transRepository.getSaleOrderList(limit: event.limit, offset: event.offset, search: event.search, custcode: event.custcode);
      } else if (event.type == TransactionTypeEnum.purchaseorder) {
        results = await _transRepository.getPurchaseOrderList(limit: event.limit, offset: event.offset, search: event.search, custcode: event.custcode);
      } else if (event.type == TransactionTypeEnum.quotation) {
        results = await _transRepository.getQuotationList(limit: event.limit, offset: event.offset, search: event.search, custcode: event.custcode);
      } else if (event.type == TransactionTypeEnum.purchasepartial) {
        results = await _transRepository.getPurchasePartialList(limit: event.limit, offset: event.offset, search: event.search, custcode: event.custcode);
      } else if (event.type == TransactionTypeEnum.accrualreceive) {
        results = await _transRepository.getAccrualReceiveList(limit: event.limit, offset: event.offset, search: event.search, custcode: event.custcode);
      } else {
        emit(const TransLoadFailed(message: 'Trans Not Found'));
      }
      // // print(results.data);
      if (results.success) {
        List<TransactionModel> trans = (results.data as List).map((trans) => TransactionModel.fromJson(trans)).toList();

        for (var element in trans) {
          if (element.paymentdetailraw != "") {
            try {
              final List<dynamic> jsonStr = jsonDecode(element.paymentdetailraw!);
              element.billpayobjectboxstruct = (jsonStr).map((e) => BillPayObjectBoxStruct.fromJson(e)).toList();
            } catch (e) {
              print('Error paymentdetailraw JSON: $e');
            }
          }

          for (var detail in element.details!) {
            if (detail.extrajson != null && detail.extrajson! != "[]" && detail.extrajson! != "") {
              try {
                List<dynamic> jsonData = jsonDecode(detail.extrajson!);
                detail.extrajsonlist = jsonData.map((e) => ExtraJsonListModel.fromJson(e)).toList();

                for (var extra in detail.extrajsonlist!) {
                  if (extra.item_name != null && extra.item_name! != "[]" && extra.item_name! != "") {
                    try {
                      List<dynamic> jsonData = jsonDecode(extra.item_name!);
                      extra.itemnames = jsonData.map((e) => LanguageDataModel.fromJson(e)).toList();
                    } catch (e) {
                      print('Error item_name JSON: $e');
                    }
                  }
                }
              } catch (e) {
                print('Error extrajson JSON: $e');
              }
            }
          }
        }

        if (event.type == TransactionTypeEnum.stocktransfer) {
          for (var tran in trans) {
            tran.details!.removeWhere((ele) => ele.calcflag == 1);
          }
        }
        emit(TransLoadSuccess(trans: trans));
      } else {
        emit(const TransLoadFailed(message: 'Trans Not Found'));
      }
    } catch (e) {
      emit(TransLoadFailed(message: e.toString()));
    }
  }

  void onTransSave(TransSave event, Emitter<TransState> emit) async {
    emit(TransSaveInProgress());
    try {
      late ApiResponse<dynamic> results;
      if (event.type == TransactionTypeEnum.purchase) {
        results = await _transRepository.savePurchase(event.trans);
      } else if (event.type == TransactionTypeEnum.purchasereturn) {
        results = await _transRepository.savePurchaseReturn(event.trans);
      } else if (event.type == TransactionTypeEnum.sale) {
        results = await _transRepository.saveSale(event.trans);
      } else if (event.type == TransactionTypeEnum.salereturn) {
        results = await _transRepository.saveSaleReturn(event.trans);
      } else if (event.type == TransactionTypeEnum.adjust) {
        if (event.trans.transflag == 66 || event.trans.transflag == 866) {
          for (var data in event.trans.details!) {
            data.calcflag = 1;
          }
        } else if (event.trans.transflag == 68 || event.trans.transflag == 868) {
          for (var data in event.trans.details!) {
            data.calcflag = -1;
          }
        }
        results = await _transRepository.saveAdjust(event.trans);
      } else if (event.type == TransactionTypeEnum.stockpickupproduct) {
        results = await _transRepository.saveStockPickup(event.trans);
      } else if (event.type == TransactionTypeEnum.stockreceiveproduct) {
        results = await _transRepository.saveStockReceive(event.trans);
      } else if (event.type == TransactionTypeEnum.stockreturnproduct) {
        results = await _transRepository.saveStockReturn(event.trans);
      } else if (event.type == TransactionTypeEnum.stocktransfer) {
        event.trans.transflag = 72;
        List<TransactionDetailModel> detailsOut = [];
        for (var data in event.trans.details!) {
          data.calcflag = -1;
          TransactionDetailModel newData = TransactionDetailModel(
            docdatetime: data.docdatetime,
            docrefdatetime: data.docrefdatetime,
            itemguid: data.itemguid,
            barcode: data.barcode,
            itemcode: data.itemcode,
            itemnames: data.itemnames,
            unitcode: data.unitcode,
            unitnames: data.unitnames,
            qty: data.qty,
            price: data.price,
            discount: data.discount,
            sumofcost: data.sumofcost,
            remark: data.remark,
            linenumber: data.linenumber,
            whcode: data.whcode,
            shelfcode: data.shelfcode,
            sumamount: data.sumamount,
            locationcode: data.locationcode,
            totalvaluevat: data.totalvaluevat,
            totalqty: data.totalqty,
            sumamountexcludevat: data.sumamountexcludevat,
            priceexcludevat: data.priceexcludevat,
            discountamount: data.discountamount,
            standvalue: data.standvalue,
            dividevalue: data.dividevalue,
            calcflag: 1,
            vattype: data.vattype,
            averagecost: data.averagecost,
            ispos: data.ispos,
            laststatus: data.laststatus,
            itemtype: data.itemtype,
            taxtype: data.taxtype,
            inquirytype: data.inquirytype,
            multiunit: data.multiunit,
          );

          newData.whcode = data.towhcode ?? '';
          newData.whnames = data.towhnames ?? [];
          newData.locationcode = data.tolocationcode ?? '';
          newData.locationnames = data.tolocationnames ?? [];

          detailsOut.add(newData);
        }
        event.trans.details!.addAll(detailsOut);
        results = await _transRepository.saveTransfer(event.trans);
      } else if (event.type == TransactionTypeEnum.quotation) {
        results = await _transRepository.saveQuotation(event.trans);
      } else if (event.type == TransactionTypeEnum.saleorder) {
        results = await _transRepository.saveSaleOrder(event.trans);
      } else if (event.type == TransactionTypeEnum.purchaseorder) {
        results = await _transRepository.savePurchaseOrder(event.trans);
      } else if (event.type == TransactionTypeEnum.purchasepartial) {
        results = await _transRepository.savePurchasePartial(event.trans);
      } else if (event.type == TransactionTypeEnum.accrualreceive) {
        results = await _transRepository.saveAccrualReceive(event.trans);
      } else {
        emit(const TransSaveFailed(message: "No type"));
      }
      if (results.success) {
        emit(TransSaveSuccess(docno: results.data));
      } else {
        emit(TransSaveFailed(message: results.message));
      }
    } catch (e) {
      emit(TransSaveFailed(message: e.toString()));
    }
  }

  void onTransDelete(TransDelete event, Emitter<TransState> emit) async {
    emit(TransDeleteInProgress());
    try {
      if (event.type == TransactionTypeEnum.purchase) {
        await _transRepository.deletePurchase(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.purchasereturn) {
        await _transRepository.deletePurchaseReturn(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.sale) {
        await _transRepository.deleteSale(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.salereturn) {
        await _transRepository.deleteSaleReturn(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.adjust) {
        await _transRepository.deleteAdjust(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.stockpickupproduct) {
        await _transRepository.deleteStockPickup(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.stockreceiveproduct) {
        await _transRepository.deleteReceive(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.stockreturnproduct) {
        await _transRepository.deleteReturn(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.stocktransfer) {
        await _transRepository.deleteTransfer(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.stockbalance) {
        await _transRepository.deleteStockBalance(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.saleorder) {
        await _transRepository.deleteSaleOrder(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.purchaseorder) {
        await _transRepository.deletePurchaseOrder(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.quotation) {
        await _transRepository.deleteQuotation(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.purchasepartial) {
        await _transRepository.deletePurchasePartial(event.guid);
        emit(TransDeleteSuccess());
      } else if (event.type == TransactionTypeEnum.accrualreceive) {
        await _transRepository.deleteAccrualReceive(event.guid);
        emit(TransDeleteSuccess());
      } else {
        emit(const TransDeleteFailed(message: "No type"));
      }
    } catch (e) {
      emit(TransDeleteFailed(message: e.toString()));
    }
  }

  void onTransUpdate(TransUpdate event, Emitter<TransState> emit) async {
    emit(TransUpdateInProgress());
    try {
      if (event.type == TransactionTypeEnum.purchase) {
        await _transRepository.updatePurchase(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else if (event.type == TransactionTypeEnum.purchasereturn) {
        await _transRepository.updatePurchaseReturn(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else if (event.type == TransactionTypeEnum.sale) {
        await _transRepository.updateSale(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else if (event.type == TransactionTypeEnum.salereturn) {
        await _transRepository.updateSaleReturn(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else if (event.type == TransactionTypeEnum.adjust) {
        if (event.trans.transflag == 66 || event.trans.transflag == 866) {
          for (var data in event.trans.details!) {
            data.calcflag = 1;
          }
        } else if (event.trans.transflag == 68 || event.trans.transflag == 868) {
          for (var data in event.trans.details!) {
            data.calcflag = -1;
          }
        }
        await _transRepository.updateAdjust(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else if (event.type == TransactionTypeEnum.stockpickupproduct) {
        await _transRepository.updateStockPickup(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else if (event.type == TransactionTypeEnum.stockreceiveproduct) {
        await _transRepository.updateStockReceive(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else if (event.type == TransactionTypeEnum.stockreturnproduct) {
        await _transRepository.updateStockReturn(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else if (event.type == TransactionTypeEnum.stocktransfer) {
        event.trans.transflag = 72;
        List<TransactionDetailModel> detailsOut = [];
        for (var data in event.trans.details!) {
          data.calcflag = -1;
          TransactionDetailModel newData = TransactionDetailModel(
              docdatetime: data.docdatetime,
              docrefdatetime: data.docrefdatetime,
              itemguid: data.itemguid,
              barcode: data.barcode,
              itemcode: data.itemcode,
              itemnames: data.itemnames,
              unitcode: data.unitcode,
              unitnames: data.unitnames,
              qty: data.qty,
              price: data.price,
              discount: data.discount,
              sumofcost: data.sumofcost,
              remark: data.remark,
              linenumber: data.linenumber,
              whcode: data.whcode,
              shelfcode: data.shelfcode,
              sumamount: data.sumamount,
              locationcode: data.locationcode,
              totalvaluevat: data.totalvaluevat,
              totalqty: data.totalqty,
              sumamountexcludevat: data.sumamountexcludevat,
              priceexcludevat: data.priceexcludevat,
              discountamount: data.discountamount,
              standvalue: data.standvalue,
              dividevalue: data.dividevalue,
              calcflag: 1,
              vattype: data.vattype,
              averagecost: data.averagecost,
              ispos: data.ispos,
              laststatus: data.laststatus,
              itemtype: data.itemtype,
              taxtype: data.taxtype,
              inquirytype: data.inquirytype,
              multiunit: data.multiunit);

          newData.whcode = data.towhcode ?? '';
          newData.whnames = data.towhnames ?? [];
          newData.locationcode = data.tolocationcode ?? '';
          newData.locationnames = data.tolocationnames ?? [];

          detailsOut.add(newData);
        }
        event.trans.details!.addAll(detailsOut);

        await _transRepository.updateTransfer(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else if (event.type == TransactionTypeEnum.quotation) {
        await _transRepository.updateQuotation(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else if (event.type == TransactionTypeEnum.saleorder) {
        await _transRepository.updateSaleOrder(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else if (event.type == TransactionTypeEnum.purchaseorder) {
        await _transRepository.updatePurchaseOrder(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else if (event.type == TransactionTypeEnum.purchasepartial) {
        await _transRepository.updatePurchasePartial(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else if (event.type == TransactionTypeEnum.accrualreceive) {
        await _transRepository.updateAccrualReceive(event.guid, event.trans);
        emit(TransUpdateSuccess());
      } else {
        emit(const TransUpdateFailed(message: "No type"));
      }
    } catch (e) {
      emit(TransUpdateFailed(message: e.toString()));
    }
  }

  void onTransCreateFullInvoice(TransCreateFullInvoice event, Emitter<TransState> emit) async {
    emit(TransFullInvoiceInProgress());

    try {
      // ตรวจสอบข้อมูลก่อนดำเนินการ
      if (event.trans.guidfixed?.isEmpty ?? true) {
        emit(TransFullInvoiceFailed(message: 'ไม่พบข้อมูลเอกสาร'));
        return;
      }

      // แก้ไขเฉพาะส่วนการยกเลิก
      event.trans.iscancel = true;
      event.trans.cancelreason = 'ใบกำกับภาษีแบบเต็มออกแทน';
      event.trans.cancelusercode = global.profileData.username;
      event.trans.cancelusername = global.profileData.name;
      event.trans.canceldatetime = DateTime.now().toLocal().toIso8601String();
      event.trans.canceltime = DateTime.now().toLocal().toIso8601String();

      // Update เอกสารเดิมให้เป็น cancelled
      late ApiResponse<dynamic> updateResult;
      if (event.type == TransactionTypeEnum.sale) {
        updateResult = await _transRepository.updateSale(event.guid, event.trans);
      }

      // ตรวจสอบการ update สำเร็จ
      if (!updateResult.success) {
        emit(TransFullInvoiceFailed(message: 'Failed to cancel original document: ${updateResult.message}'));
        return;
      }

      // Step 2: สร้างเอกสารใหม่สำหรับใบกำกับภาษีแบบเต็ม - คงข้อมูลเดิมทุกส่วน
      await Future.delayed(const Duration(milliseconds: 500));

      // แก้ไขเฉพาะส่วนที่จำเป็นสำหรับใบกำกับภาษีแบบเต็ม
      event.trans.guidfixed = ''; // Clear guid เพื่อสร้างใหม่
      event.trans.taxdocno = event.trans.docno;
      event.trans.taxdocdate = event.trans.docdatetime;
      event.trans.docno = global.randomDocNo('SI', DateTime.now());
      // Reset cancel status สำหรับเอกสารใหม่
      event.trans.iscancel = false;
      event.trans.cancelreason = null;
      event.trans.cancelusercode = null;
      event.trans.cancelusername = null;
      event.trans.canceldatetime = null;
      event.trans.canceltime = null;

      late ApiResponse<dynamic> saveResult;
      if (event.type == TransactionTypeEnum.sale) {
        saveResult = await _transRepository.saveSale(event.trans);
      }

      if (saveResult.success) {
        emit(TransFullInvoiceSuccess(docno: saveResult.data));
      } else {
        emit(TransFullInvoiceFailed(message: 'Failed to create full tax invoice: ${saveResult.message}'));
      }
    } catch (e) {
      emit(TransFullInvoiceFailed(message: e.toString()));
    }
  }
}
