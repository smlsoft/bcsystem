// import 'dart:async';
// import 'dart:convert';
// import 'package:dedecashier/api/client.dart';
// import 'package:dedecashier/api/sync/model/shift_model.dart';
// import 'package:dedecashier/api/sync/model/trans_model.dart';
// import 'package:dedecashier/api/user_repository.dart';
// import 'package:dedecashier/core/logger/logger.dart';
// import 'package:dedecashier/core/service_locator.dart';
// import 'package:dedecashier/db/bill_helper.dart';
// import 'package:dedecashier/global_model.dart';
// import 'package:dedecashier/model/objectbox/bill_struct.dart';
// import 'package:dedecashier/global.dart' as global;
// import 'package:dedecashier/model/objectbox/shift_struct.dart';
// import 'package:dedecashier/objectbox.g.dart';
// import 'package:dio/dio.dart';
// import 'package:uuid/uuid.dart';

// class SyncBill {
//   Timer? _syncBillTimer;

//   void startSync() {
//     _syncBillTimer = Timer.periodic(Duration(minutes: 30), (timer) {
//       syncBillProcess();
//     });
//   }

//   void stopSync() {
//     _syncBillTimer?.cancel();
//   }

//   Future syncBillData() async {
//     List<BillObjectBoxStruct> bills = (global.billHelper.selectSyncIsFalse());
//     for (int index = 0; index < bills.length; index++) {
//       BillObjectBoxStruct bill = bills[index];
//       List<TransNameInfoModel> custNames = [];

//       if (bill.customer_name != '') {
//         custNames.add(TransNameInfoModel(
//           code: "th",
//           isauto: false,
//           isdelete: false,
//           name: bill.customer_name,
//         ));
//       }

//       List<BillDetailObjectBoxStruct> billDetails = global.objectBoxStore
//           .box<BillDetailObjectBoxStruct>()
//           .query(BillDetailObjectBoxStruct_.doc_number.equals(bill.doc_number))
//           .order(BillDetailObjectBoxStruct_.line_number)
//           .build()
//           .find();

//       List<TransDetailModel> details = [];
//       double total_qty = 0;
//       for (var detail in billDetails) {
//         int linenumber = 0;

//         String optionSelected = detail.extra_json;
//         String refGuidCode = const Uuid().v4();
//         double sumamountchoice = 0;

//         List<TransOptionsModel> transOptions = [];
//         if (optionSelected.isNotEmpty) {
//           detail.refguid = refGuidCode;
//           List<BillDetailExtraObjectBoxStruct> optionList = (await jsonDecode(optionSelected) as List).map((e) => BillDetailExtraObjectBoxStruct.fromJson(e)).toList();
//           for (var option in optionList) {
//             // sumamountchoice += option.price;
//             String refBarcodex = (option.refbarcode.isNotEmpty) ? option.refbarcode : "";
//             if (option.price == 0) {
//               TransOptionsModel optionModel = TransOptionsModel(
//                 barcode: refBarcodex,
//                 qty: detail.qty,
//                 price: option.price,
//                 item_code: "",
//                 item_name: option.item_name,
//                 unit_code: "",
//                 unit_name: "",
//                 total_amount: option.price * option.qty,
//                 is_except_vat: false,
//                 vat_type: global.posConfig.vattype,
//                 price_exclude_vat: option.price,
//               );
//               sumamountchoice += (option.price * detail.qty);
//               transOptions.add(optionModel);
//             }
//           }
//         }

//         double priceExcludeVat = 0;
//         if (!detail.is_except_vat) {
//           if (bill.vat_type == 0) {
//             priceExcludeVat = ((detail.price + (sumamountchoice / detail.qty)) * 100) / (100 + bill.vat_rate);
//           } else {
//             priceExcludeVat = detail.price + (sumamountchoice / detail.qty);
//           }
//         } else {
//           priceExcludeVat = detail.price + (sumamountchoice / detail.qty);
//         }

//         detail.price - (detail.price * (bill.vat_rate / 100));
//         details.add(TransDetailModel(
//           refguid: refGuidCode,
//           averagecost: 0,
//           barcode: detail.barcode,
//           calcflag: -1,
//           discount: detail.discount_text,
//           discountamount: detail.discount,
//           standvalue: 1,
//           dividevalue: 1,
//           docdatetime: bill.date_time.toUtc().toIso8601String(),
//           docref: "",
//           docrefdatetime: null,
//           inquirytype: (bill.doc_mode == 1) ? 1 : 2,
//           ispos: 1,
//           itemcode: detail.item_code,
//           itemguid: "",
//           itemnames: (await jsonDecode(detail.item_name) as List).map((e) => TransNameInfoModel.fromJson(e)).toList(),
//           itemtype: 0,
//           laststatus: 0,
//           linenumber: detail.line_number,
//           locationcode: global.posConfig.location.code,
//           locationnames: global.posConfig.location.names,
//           multiunit: false,
//           price: detail.price,
//           priceexcludevat: priceExcludeVat,
//           qty: detail.qty,
//           remark: "",
//           shelfcode: "",
//           sumamount: (detail.price * detail.qty),
//           sumamountexcludevat: priceExcludeVat * detail.qty,
//           sumamountchoice: sumamountchoice,
//           sumofcost: 0,
//           taxtype: bill.bill_tax_type,
//           tolocationcode: "",
//           tolocationnames: [],
//           totalqty: detail.qty,
//           totalvaluevat: ((detail.price * detail.qty) + sumamountchoice) - (priceExcludeVat * detail.qty),
//           towhcode: "",
//           towhnames: [],
//           unitcode: detail.unit_code,
//           unitnames: (await jsonDecode(detail.unit_name) as List).map((e) => TransNameInfoModel.fromJson(e)).toList(),
//           vatcal: (detail.is_except_vat) ? 1 : 0,
//           vattype: detail.vat_type,
//           whcode: global.posConfig.warehouse.code,
//           whnames: global.posConfig.warehouse.names,
//           sku: detail.sku,
//           extrajson: (transOptions.isNotEmpty) ? jsonEncode(transOptions) : "",
//         ));

//         if (optionSelected.isNotEmpty) {
//           detail.refguid = refGuidCode;
//           List<BillDetailExtraObjectBoxStruct> optionList = (await jsonDecode(optionSelected) as List).map((e) => BillDetailExtraObjectBoxStruct.fromJson(e)).toList();

//           for (var option in optionList) {
//             // sumamountchoice += option.price;
//             String refBarcodex = (option.refbarcode.isNotEmpty) ? option.refbarcode : "";

//             double priceChoiceExcludeVat = 0;
//             if (!detail.is_except_vat) {
//               if (global.posConfig.vattype == 0) {
//                 priceChoiceExcludeVat = (option.price * 100) / (100 + global.posConfig.vatrate);
//               } else {
//                 priceChoiceExcludeVat = option.price;
//               }
//             } else {
//               priceChoiceExcludeVat = option.price;
//             }
//             if (option.price > 0) {
//               details.add(TransDetailModel(
//                   ischoice: 1,
//                   refguid: refGuidCode,
//                   averagecost: 0,
//                   barcode: refBarcodex,
//                   calcflag: -1,
//                   discount: "",
//                   discountamount: 0,
//                   standvalue: 1,
//                   dividevalue: 1,
//                   docdatetime: bill.date_time.toUtc().toIso8601String(),
//                   docref: "",
//                   docrefdatetime: null,
//                   inquirytype: (bill.doc_mode == 1) ? 1 : 2,
//                   ispos: 1,
//                   itemcode: refBarcodex,
//                   itemguid: "",
//                   itemnames: (await jsonDecode(option.item_name) as List).map((e) => TransNameInfoModel.fromJson(e)).toList(),
//                   itemtype: 0,
//                   laststatus: 0,
//                   linenumber: linenumber,
//                   locationcode: global.posConfig.location.code,
//                   locationnames: global.posConfig.location.names,
//                   multiunit: false,
//                   price: option.price,
//                   priceexcludevat: priceChoiceExcludeVat,
//                   qty: detail.qty,
//                   remark: "",
//                   shelfcode: "",
//                   sumamount: option.total_amount,
//                   sumamountexcludevat: priceChoiceExcludeVat * detail.qty,
//                   sumofcost: 0,
//                   taxtype: bill.bill_tax_type,
//                   tolocationcode: "",
//                   tolocationnames: [],
//                   totalqty: option.qty,
//                   totalvaluevat: (option.price * detail.qty) - (priceChoiceExcludeVat * detail.qty),
//                   towhcode: "",
//                   towhnames: [],
//                   unitcode: option.unit_code,
//                   unitnames: (await jsonDecode(detail.unit_name) as List).map((e) => TransNameInfoModel.fromJson(e)).toList(),
//                   vatcal: (detail.is_except_vat) ? 1 : 0,
//                   vattype: detail.vat_type,
//                   whcode: global.posConfig.warehouse.code,
//                   whnames: global.posConfig.warehouse.names,
//                   sku: detail.sku,
//                   extrajson: ""));
//               linenumber++;
//               total_qty += detail.qty;
//             }
//           }
//         }

//         total_qty += detail.qty;
//       }
//       List<BillPayObjectBoxStruct> payDetails = (await jsonDecode(bill.pay_json) as List).map((e) => BillPayObjectBoxStruct.fromJson(e)).toList();
//       List<TransPaymentCreditCardModel> paymentCreditCards = [];
//       List<TransPaymentTransferModel> paymentTransfers = [];
//       for (var payDetail in payDetails) {
//         // 1=บัตรเครดิต,2=เงินโอน,3=เช็ค,4=คูปอง,5=QR
//         switch (payDetail.trans_flag) {
//           case 1: // 1=บัตรเครดิต
//             paymentCreditCards.add(TransPaymentCreditCardModel(
//                 amount: payDetail.amount,
//                 cardnumber: payDetail.card_number,
//                 chargevalue: 0,
//                 chargeword: "",
//                 docdatetime: payDetail.doc_date_time.toString(),
//                 totalnetworth: payDetail.amount));
//             break;
//           case 2: // 2=เงินโอน
//             paymentTransfers.add(TransPaymentTransferModel(
//               accountnumber: payDetail.book_bank_code,
//               amount: payDetail.amount,
//               bankcode: payDetail.bank_code,
//               banknames: [
//                 TransNameInfoModel(
//                   code: "th",
//                   isauto: false,
//                   isdelete: false,
//                   name: payDetail.bank_name,
//                 )
//               ],
//               docdatetime: payDetail.doc_date_time.toString(),
//             ));
//             break;
//           case 3: // 3=เช็ค
//             break;
//           case 4: // 4=คูปอง
//             break;
//           case 5: // 5=QR
//             break;
//         }
//       }

//       TransPaymentDetailModel paymentDetail = TransPaymentDetailModel(
//         cashamount: 0,
//         cashamounttext: "",
//         paymentcreditcards: [],
//         paymenttransfers: [],
//       );
//       int trans_vat_type = 0;
//       if (!global.posConfig.isvatregister) {
//         trans_vat_type = 3;
//       } else if (global.posConfig.isvatregister && global.posConfig.vattype == 0) {
//         trans_vat_type = 1;
//       } else if (global.posConfig.isvatregister && global.posConfig.vattype == 1) {
//         trans_vat_type = 0;
//       }
//       // ส่งข้อมูล ขึ้น cloud
//       TransactionModel trans = TransactionModel(
//         cashiercode: bill.cashier_code,
//         custcode: bill.customer_code,
//         custnames: custNames,
//         description: "POS",
//         branch: global.posConfig.branch,
//         discountword: bill.discount_formula,
//         docdatetime: bill.date_time.toUtc().toIso8601String(),
//         docno: bill.doc_number,
//         docrefdate: bill.date_time.toUtc().toIso8601String(),
//         docrefno: "",
//         docreftype: 0,
//         doctype: 0,
//         guidref: "",
//         inquirytype: (bill.doc_mode == 1) ? 1 : 2,
//         iscancel: bill.is_cancel,
//         ismanualamount: false,
//         ispos: true,
//         posid: global.posConfig.code,
//         membercode: bill.customer_code,
//         salecode: bill.sale_code,
//         salename: bill.sale_name,
//         status: 0,
//         taxdocdate: bill.date_time.toUtc().toIso8601String(),
//         taxdocno: bill.doc_number,
//         totalaftervat: double.parse(bill.amount_after_calc_vat.toStringAsFixed(2)),
//         totalamount: double.parse(((bill.amount_after_calc_vat + bill.amount_except_vat) - bill.total_discount).toStringAsFixed(2)),
//         totalbeforevat: double.parse(bill.amount_before_calc_vat.toStringAsFixed(2)),
//         totalcost: 0,
//         totaldiscount: double.parse(bill.total_discount.toStringAsFixed(2)),
//         totalexceptvat: double.parse(bill.amount_except_vat.toStringAsFixed(2)),
//         totalvalue: double.parse(bill.detail_total_amount_before_discount.toStringAsFixed(2)),
//         totalvatvalue: double.parse(bill.total_vat_amount.toStringAsFixed(2)),
//         transflag: 0,
//         vatrate: bill.vat_rate,
//         vattype: trans_vat_type,
//         details: details,
//         paycashamount: bill.pay_cash_amount - bill.pay_cash_change,
//         paymentdetail: paymentDetail,
//         paymentdetailraw: bill.pay_json,
//         billtaxtype: bill.bill_tax_type,
//         buffetcode: bill.buffet_code,
//         canceldatetime: bill.cancel_date_time,
//         canceldescription: bill.cancel_description,
//         cancelusercode: bill.cancel_user_code,
//         cancelusername: bill.cancel_user_name,
//         cancelreason: bill.cancel_reason,
//         cashiername: bill.cashier_name,
//         childcount: bill.child_count,
//         customertelephone: bill.customer_telephone,
//         detaildiscountformula: bill.detail_discount_formula,
//         detailtotalamount: bill.detail_total_amount,
//         detailtotalamountbeforediscount: bill.detail_total_amount_before_discount,
//         detailtotaldiscount: bill.detail_total_discount,
//         fullvataddress: bill.full_vat_address,
//         fullvatname: bill.full_vat_name,
//         fullvatbranchnumber: bill.full_vat_branch_number,
//         fullvatdocnumber: bill.full_vat_doc_number,
//         fullvatprint: bill.full_vat_print,
//         fullvattaxid: bill.full_vat_tax_id,
//         isvatregister: bill.is_vat_register,
//         mancount: bill.man_count,
//         paycashchange: double.parse(bill.pay_cash_change.toStringAsFixed(2)),
//         printcopybilldatetime: bill.print_copy_bill_date_time,
//         roundamount: bill.round_amount,
//         sumcheque: double.parse(bill.sum_cheque.toStringAsFixed(2)),
//         sumcoupon: double.parse(bill.sum_coupon.toStringAsFixed(2)),
//         sumcreditcard: double.parse(bill.sum_credit_card.toStringAsFixed(2)),
//         summoneytransfer: double.parse(bill.sum_money_transfer.toStringAsFixed(2)),
//         sumqrcode: double.parse(bill.sum_qr_code.toStringAsFixed(2)),
//         sumcredit: double.parse(bill.sum_credit.toStringAsFixed(2)),
//         istableallacratemode: bill.table_al_la_crate_mode,
//         tableclosedatetime: bill.table_close_date_time.toUtc().toIso8601String(),
//         tablenumber: bill.table_number,
//         tableopendatetime: bill.table_open_date_time.toUtc().toIso8601String(),
//         totalamountafterdiscount: bill.total_amount_after_discount,
//         totaldiscountexceptvatamount: bill.total_discount_except_vat_amount,
//         totaldiscountvatamount: bill.total_discount_vat_amount,
//         totalqty: total_qty,
//         womancount: bill.woman_count,
//         isbom: global.posConfig.branch.pos!.isbom,
//       );

//       try {
//         if (bill.doc_mode == 1) {
//           await checkAndSaveTransaction(trans);
//         } else {
//           await checkAndSaveReturn(trans);
//         }
//       } catch (e) {
//         AppLogger.error(e);
//       }

//       // BillHelper().updatesSyncSuccess(docNumber: bill.doc_number);
//     }
//   }

//   Future syncShift() async {
//     List<ShiftObjectBoxStruct> shifts = (global.shiftHelper.selectSyncIsFalse());

//     for (int index = 0; index < shifts.length; index++) {
//       ShiftObjectBoxStruct shift = shifts[index];

//       ShiftModel postShift = ShiftModel(
//         guidfixed: shift.guidfixed,
//         doctype: shift.doctype,
//         amount: shift.amount,
//         creditcard: shift.creditcard,
//         promptpay: shift.promptpay,
//         transfer: shift.transfer,
//         cheque: shift.cheque,
//         coupon: shift.coupon,
//         docdate: shift.docdate.toUtc().toIso8601String(),
//         remark: shift.remark,
//         usercode: shift.usercode,
//         username: shift.username,
//         posid: shift.posid,
//         docno: shift.docno,
//       );
//       await saveShift(postShift);
//       global.shiftHelper.updatesSyncSuccess(docNumber: shift.guidfixed);
//     }
//   }

//   Future<ApiResponse> checkAndSaveTransaction(TransactionModel trx) async {
//     Dio client = Client().init();

//     try {
//       // Check if transaction exists
//       final checkResponse = await client.get('/transaction/sale-invoice/code/${trx.docno}');
//       final checkRawData = json.decode(checkResponse.toString());

//       if (checkRawData['error'] == null) {
//         BillHelper().updatesSyncSuccess(docNumber: trx.docno);
//         return ApiResponse.fromMap(checkRawData);
//       } else {
//         String errorMessage = '${checkRawData['code']}: ${checkRawData['message']}';
//         AppLogger.error(errorMessage);
//         throw Exception(errorMessage);
//       }
//     } on DioException catch (checkEx) {
//       final errorData = checkEx.response?.data;
//       if (errorData != null && errorData['message'] == "document not found") {
//         // If the document is not found (in the DioException response), proceed to save it
//         try {
//           final saveResponse = await client.post('/transaction/sale-invoice', data: trx.toJson());
//           final saveRawData = json.decode(saveResponse.toString());

//           if (saveRawData['error'] != null) {
//             String errorMessage = '${saveRawData['code']}: ${saveRawData['message']}';
//             AppLogger.error(errorMessage);
//             throw Exception(errorMessage);
//           }

//           // Save successful, update sync status
//           BillHelper().updatesSyncSuccess(docNumber: trx.docno);
//           return ApiResponse.fromMap(saveRawData);
//         } catch (saveEx) {
//           global.syncDataProcess = false;
//           AppLogger.error(saveEx);
//           throw Exception(saveEx);
//         }
//       } else {
//         global.syncDataProcess = false;
//         String errorMessage = checkEx.response.toString();
//         AppLogger.error(errorMessage);
//         throw Exception(errorMessage);
//       }
//     }
//   }

//   Future<ApiResponse> saveTransaction(TransactionModel trx) async {
//     Dio client = Client().init();

//     //String jsonPayload = jsonEncode(trx.toJson());
//     try {
//       final response = await client.post('/transaction/sale-invoice', data: trx.toJson());
//       try {
//         final rawData = json.decode(response.toString());

//         //   print(rawData);

//         if (rawData['error'] != null) {
//           String errorMessage = '${rawData['code']}: ${rawData['message']}';
//           AppLogger.error(errorMessage);
//           throw Exception('${rawData['code']}: ${rawData['message']}');
//         }

//         return ApiResponse.fromMap(rawData);
//       } catch (ex) {
//         global.syncDataProcess = false;
//         AppLogger.error(ex);
//         throw Exception(ex);
//       }
//     } on DioException catch (ex) {
//       global.syncDataProcess = false;
//       String errorMessage = ex.response.toString();
//       AppLogger.error(errorMessage);
//       throw Exception(errorMessage);
//     }
//   }

//   Future<ApiResponse> saveShift(ShiftModel tran) async {
//     Dio client = Client().init();
//     //String jsonPayload = jsonEncode(trx.toJson());
//     try {
//       final response = await client.post('/pos/shift', data: tran.toJson());
//       try {
//         final rawData = json.decode(response.toString());

//         //   print(rawData);

//         if (rawData['error'] != null) {
//           String errorMessage = '${rawData['code']}: ${rawData['message']}';
//           AppLogger.error(errorMessage);
//           throw Exception('${rawData['code']}: ${rawData['message']}');
//         }

//         return ApiResponse.fromMap(rawData);
//       } catch (ex) {
//         global.syncDataProcess = false;
//         AppLogger.error(ex);
//         throw Exception(ex);
//       }
//     } on DioException catch (ex) {
//       global.syncDataProcess = false;
//       String errorMessage = ex.response.toString();
//       AppLogger.error(errorMessage);
//       throw Exception(errorMessage);
//     }
//   }

//   Future<ApiResponse> checkAndSaveReturn(TransactionModel trx) async {
//     Dio client = Client().init();

//     try {
//       // Check if transaction exists
//       final checkResponse = await client.get('/transaction/sale-invoice-return/code/${trx.docno}');
//       final checkRawData = json.decode(checkResponse.toString());

//       if (checkRawData['error'] == null) {
//         BillHelper().updatesSyncSuccess(docNumber: trx.docno);
//         return ApiResponse.fromMap(checkRawData);
//       } else {
//         String errorMessage = '${checkRawData['code']}: ${checkRawData['message']}';
//         AppLogger.error(errorMessage);
//         throw Exception(errorMessage);
//       }
//     } on DioException catch (checkEx) {
//       final errorData = checkEx.response?.data;
//       if (errorData != null && errorData['message'] == "document not found") {
//         // If the document is not found (in the DioException response), proceed to save it
//         try {
//           final saveResponse = await client.post('/transaction/sale-invoice-return', data: trx.toJson());
//           final saveRawData = json.decode(saveResponse.toString());

//           if (saveRawData['error'] != null) {
//             String errorMessage = '${saveRawData['code']}: ${saveRawData['message']}';
//             AppLogger.error(errorMessage);
//             throw Exception(errorMessage);
//           }

//           // Save successful, update sync status
//           BillHelper().updatesSyncSuccess(docNumber: trx.docno);
//           return ApiResponse.fromMap(saveRawData);
//         } catch (saveEx) {
//           global.syncDataProcess = false;
//           AppLogger.error(saveEx);
//           throw Exception(saveEx);
//         }
//       } else {
//         global.syncDataProcess = false;
//         String errorMessage = checkEx.response.toString();
//         AppLogger.error(errorMessage);
//         throw Exception(errorMessage);
//       }
//     }
//   }

//   Future<ApiResponse> saveReturn(TransactionModel trx) async {
//     Dio client = Client().init();
//     //String jsonPayload = jsonEncode(trx.toJson());
//     try {
//       final response = await client.post('/transaction/sale-invoice-return', data: trx.toJson());
//       try {
//         final rawData = json.decode(response.toString());

//         //   print(rawData);

//         if (rawData['error'] != null) {
//           String errorMessage = '${rawData['code']}: ${rawData['message']}';
//           AppLogger.error(errorMessage);
//           throw Exception('${rawData['code']}: ${rawData['message']}');
//         }

//         return ApiResponse.fromMap(rawData);
//       } catch (ex) {
//         global.syncDataProcess = false;
//         AppLogger.error(ex);
//         throw Exception(ex);
//       }
//     } on DioException catch (ex) {
//       global.syncDataProcess = false;
//       String errorMessage = ex.response.toString();
//       AppLogger.error(errorMessage);
//       throw Exception(errorMessage);
//     }
//   }

//   /// ส่งข้อมูลขึ้น cloud
//   Future syncBillProcess() async {
//     if (global.syncDataProcess == false) {
//       global.syncDataProcess = true;
//       try {
//         global.isOnline = await global.hasNetwork();
//         if (global.isOnline) {
//           if (global.apiConnected == false) {
//             if (!global.loginProcess) {
//               global.loginProcess = true;
//               UserRepository userRepository = UserRepository();
//               await userRepository.authenUser(global.apiUserName, global.apiUserPassword).then((result) async {
//                 if (result.success) {
//                   global.apiConnected = true;
//                   global.appStorage.write("token", result.data["token"]);
//                   serviceLocator<Log>().debug("Login Success");
//                   ApiResponse selectShop = await userRepository.selectShop(global.apiShopID);
//                   if (selectShop.success) {
//                     serviceLocator<Log>().debug("Select Shop Success");
//                   }
//                 }
//               }).catchError((e) {
//                 AppLogger.error(e);
//               }).whenComplete(() async {
//                 global.loginProcess = false;
//                 await syncBillData();
//                 await syncShift();
//               });
//             }
//           } else {
//             await syncBillData();
//             await syncShift();
//           }
//         }
//       } catch (e) {
//         AppLogger.error(e);
//         global.sendErrorToDevTeam("syncBillProcess", e.toString());
//       }
//       global.syncDataProcess = false;
//     }
//   }
// }
