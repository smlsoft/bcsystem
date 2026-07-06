import 'dart:convert';

import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/trans_model.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class BillLedgerModel {
  @Id()
  int id;

  @Index()
  String localBillId;
  @Index()
  String printedDocNo;
  @Index()
  String serverDocNo;
  @Index()
  String syncStatus;

  String idempotencyKey;
  String payloadChecksum;
  String payloadJson;
  String paymentJson;
  String itemsJson;

  String shopId;
  String branchId;
  String orderStationCode;
  String deviceCode;
  String pinHistoryId;
  String docDateKey;
  String runningPrefix;
  int runningNumber;

  double totalAmount;
  double totalQty;

  bool docNoChanged;
  String docNoChangeFrom;
  String docNoChangeTo;
  String docNoChangeReason;
  int docNoChangeCount;

  String paymentStatus;
  int syncAttempts;
  String lastError;
  int reprintCount;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;
  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;
  @Property(type: PropertyType.dateNano)
  DateTime? printedAt;
  @Property(type: PropertyType.dateNano)
  DateTime? syncedAt;
  @Property(type: PropertyType.dateNano)
  DateTime? conflictAt;
  @Property(type: PropertyType.dateNano)
  DateTime? lastReprintAt;
  @Property(type: PropertyType.dateNano)
  DateTime retentionUntil;

  // ===== Pay-at-Cashier extension =====
  // '' = regular bill, 'cashier' = order pending cashier payment
  String payMode;
  // JSON payload ที่ encode ลง QR slip (null ถ้าไม่ใช่ cashier bill)
  String? cashierQrPayload;
  // เวลาที่พิมพ์ QR slip ให้ลูกค้า
  @Property(type: PropertyType.dateNano)
  DateTime? cashierPrintedAt;
  // โต๊ะ/ป้ายบริการ ของ order นี้ (สำหรับ cashier ค้นหา/แสดง)
  String orderTagNumber;

  BillLedgerModel({
    this.id = 0,
    required this.localBillId,
    required this.printedDocNo,
    required this.serverDocNo,
    required this.syncStatus,
    required this.idempotencyKey,
    required this.payloadChecksum,
    required this.payloadJson,
    required this.paymentJson,
    required this.itemsJson,
    required this.shopId,
    required this.branchId,
    required this.orderStationCode,
    required this.deviceCode,
    required this.pinHistoryId,
    required this.docDateKey,
    required this.runningPrefix,
    required this.runningNumber,
    required this.totalAmount,
    required this.totalQty,
    this.docNoChanged = false,
    this.docNoChangeFrom = "",
    this.docNoChangeTo = "",
    this.docNoChangeReason = "",
    this.docNoChangeCount = 0,
    this.paymentStatus = "paid",
    this.syncAttempts = 0,
    this.lastError = "",
    this.reprintCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.printedAt,
    this.syncedAt,
    this.conflictAt,
    this.lastReprintAt,
    required this.retentionUntil,
    this.payMode = "",
    this.cashierQrPayload,
    this.cashierPrintedAt,
    this.orderTagNumber = "",
  });
}

@Entity()
class OrderTempObjectBoxModel {
  @Id()
  int id;
  String orderid;
  @Index()
  String orderguid;
  @Index()
  String barcode;
  double qty;
  String optionselected;
  String salechannelcode;
  String remark;
  String manufacturerguid;

  @Property(type: PropertyType.dateNano)
  DateTime orderdatetime;

  double price;
  double amount;
  int istakeaway;
  int queuenumber;
  double optionamount;
  double discountamount;
  bool isexceptvat;

  OrderTempObjectBoxModel({
    this.id = 0,
    required this.orderid,
    required this.orderguid,
    required this.barcode,
    required this.qty,
    required this.remark,
    required this.optionselected,
    required this.salechannelcode,
    required this.orderdatetime,
    required this.price,
    required this.amount,
    required this.optionamount,
    required this.discountamount,
    required this.istakeaway,
    required this.queuenumber,
    required this.manufacturerguid,
    required this.isexceptvat,
  });
}

@Entity()
class TransactionObjModel {
  @Id()
  int id = 0;

  String cashiercode;
  String custcode;

  // รับค่า String โดยตรง
  String custnamesJson; // ใช้ String แทน List<TransNameInfoModel> JSON
  String branchJson; // ใช้ String แทน PosConfigBranchModel JSON
  String detailsJson; // ใช้ String แทน List<TransDetailModel> JSON
  String paymentdetailJson; // ใช้ String แทน TransPaymentDetailModel JSON

  bool issync;
  String description;
  String discountword;
  String docdatetime;
  String docno;
  String? docrefdate;
  String docrefno;
  int docreftype;
  int doctype;
  String guidref;
  int inquirytype;
  bool iscancel;
  bool ismanualamount;
  bool ispos;
  String posid;
  String membercode;
  String salecode;
  String salename;
  int status;
  String taxdocdate;
  String taxdocno;
  double totalaftervat;
  double totalamount;
  double totalbeforevat;
  double totalcost;
  double totaldiscount;
  double totalexceptvat;
  double totalvalue;
  double totalvatvalue;
  double paycashamount;
  int transflag;
  double vatrate;
  int vattype;
  String paymentdetailraw;
  int billtaxtype;
  String buffetcode;
  String detaildiscountformula;
  double detailtotalamount;
  double detailtotalamountbeforediscount;
  double detailtotaldiscount;
  bool isvatregister;
  double paycashchange;
  double roundamount;
  double sumcheque;
  double sumcoupon;
  double sumcreditcard;
  double summoneytransfer;
  double sumqrcode;
  double sumcredit;
  double totalamountafterdiscount;
  double totaldiscountexceptvatamount;
  double totaldiscountvatamount;
  double totalqty;
  int takeaway;
  String salechannelcode;
  double salechannelgp;
  int salechannelgptype;
  bool isdelivery;
  double deliveryamount;

  // BC Member fields for offline storage
  String memberPinCode;
  bool isBCMember;
  double getPoint;
  double usePoint;
  String shopName;

  // Constructor ที่รับค่า String โดยตรง
  TransactionObjModel({
    this.id = 0,
    required this.cashiercode,
    required this.custcode,
    required this.custnamesJson, // รับ String แทน List
    required this.branchJson, // รับ String แทนโมเดล
    required this.detailsJson, // รับ String แทน List
    required this.paymentdetailJson, // รับ String แทนโมเดล
    required this.issync,
    required this.description,
    required this.discountword,
    required this.docdatetime,
    required this.docno,
    required this.docrefdate,
    required this.docrefno,
    required this.docreftype,
    required this.doctype,
    required this.guidref,
    required this.inquirytype,
    required this.iscancel,
    required this.ismanualamount,
    required this.ispos,
    required this.posid,
    required this.membercode,
    required this.salecode,
    required this.salename,
    required this.status,
    required this.taxdocdate,
    required this.taxdocno,
    required this.totalaftervat,
    required this.totalamount,
    required this.totalbeforevat,
    required this.totalcost,
    required this.totaldiscount,
    required this.totalexceptvat,
    required this.totalvalue,
    required this.totalvatvalue,
    required this.paycashamount,
    required this.transflag,
    required this.vatrate,
    required this.vattype,
    required this.paymentdetailraw,
    required this.billtaxtype,
    required this.buffetcode,
    required this.detaildiscountformula,
    required this.detailtotalamount,
    required this.detailtotalamountbeforediscount,
    required this.detailtotaldiscount,
    required this.isvatregister,
    required this.paycashchange,
    required this.roundamount,
    required this.sumcheque,
    required this.sumcoupon,
    required this.sumcreditcard,
    required this.summoneytransfer,
    required this.sumqrcode,
    required this.sumcredit,
    required this.totalamountafterdiscount,
    required this.totaldiscountexceptvatamount,
    required this.totaldiscountvatamount,
    required this.totalqty,
    required this.takeaway,
    required this.salechannelcode,
    required this.salechannelgp,
    required this.salechannelgptype,
    required this.isdelivery,
    required this.deliveryamount,
    // BC Member parameters
    this.memberPinCode = '',
    this.isBCMember = false,
    this.getPoint = 0,
    this.usePoint = 0,
    this.shopName = '',
  });

  // Getter เพื่อแปลง JSON string กลับเป็น List<TransNameInfoModel>
  List<TransNameInfoModel> get custnames => (jsonDecode(custnamesJson) as List)
      .map((item) => TransNameInfoModel.fromJson(item))
      .toList();

  // Getter เพื่อแปลง JSON string กลับเป็น PosConfigBranchModel
  PosConfigBranchModel get branch =>
      PosConfigBranchModel.fromJson(jsonDecode(branchJson));

  // Getter เพื่อแปลง JSON string กลับเป็น List<TransDetailModel>
  List<TransDetailModel> get details => (jsonDecode(detailsJson) as List)
      .map((item) => TransDetailModel.fromJson(item))
      .toList();

  // Getter เพื่อแปลง JSON string กลับเป็น TransPaymentDetailModel
  TransPaymentDetailModel get paymentdetail =>
      TransPaymentDetailModel.fromJson(jsonDecode(paymentdetailJson));
}
