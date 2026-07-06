import 'package:dedecashier/global_model.dart';
import 'package:json_annotation/json_annotation.dart';
part 'trans_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CouponItemModel {
  double couponamount;
  String coupondescription;
  String couponno;
  String coupontype;
  String reservationid;
  String transactionid;
  String couponid;

  CouponItemModel({
    required this.couponamount,
    required this.coupondescription,
    required this.couponno,
    required this.coupontype,
    required this.reservationid,
    required this.transactionid,
    required this.couponid,
  });

  factory CouponItemModel.fromJson(Map<String, dynamic> json) => _$CouponItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$CouponItemModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransactionModel {
  String cashiercode;
  String devicename;
  String guidpos;
  String custcode;
  List<TransNameInfoModel> custnames;
  PosConfigBranchModel branch;
  String description;
  List<TransDetailModel> details;
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
  double paypointamount;
  int transflag;
  double vatrate;
  //1=ภาษีมูลค่าเพิ่มรวมใน,2=ภาษีมูลค่าเพิ่มแยกนอก
  int vattype;
  TransPaymentDetailModel paymentdetail;
  String paymentdetailraw;

  //0=บิลทั่วไปไม่มีภาษี,1=ใบเสร็จรับเงิน/ใบกำกับภาษีอย่างย่อ,2=ใบเสร็จรับเงิน/ใบกำกับภาษีอย่างเต็ม
  int billtaxtype;

  String canceldatetime;
  String cancelusercode;
  String cancelusername;
  String canceldescription;
  String cancelreason;
  String fullvataddress;
  //เลขสาขาใบกำกับภาษีแบบเต็ม
  String fullvatbranchnumber;
  //ชื่อลูกค้าใบกำกับภาษีแบบเต็ม
  String fullvatname;
  //เลขที่ใบกำกับภาษีแบบเต็ม
  String fullvatdocnumber;
  //ชื่อลูกค้าใบกำกับภาษีแบบเต็ม
  String fullvattaxid;
  //พิมพ์ใบกำกับภาษีแบบเต็มแล้ว
  bool fullvatprint;

  bool isvatregister;

  /// วันที่พิมพ์ใบเสร็จ (สำเนา)
  List<String> printcopybilldatetime;

  // หมายเลขโต๊ะ
  String tablenumber;

  String tableopendatetime;
  String tableclosedatetime;

  /// จำนวนคน ชาย
  int mancount;

  /// จำนวนคน หญิง
  int womancount;

  /// จำนวนเด็ก
  int childcount;

  //False=สั่งแบบอลาคาร์ทไม่ได้,True=สั่งแบบอลาคาร์ทได้
  bool istableallacratemode;

  String buffetcode;

  /// เบอร์โทรลูกค้า (สะสมแต้ม)
  String customertelephone;

  /// จำนวนชิ้น
  double totalqty;

  /// ส่วนลดสินค้ามีภาษี
  double totaldiscountvatamount;

  /// ส่วนลดสินค้ายกเว้นภาษี
  double totaldiscountexceptvatamount;

  /// ชื่อพนักงาน Cashier
  String cashiername;

  /// เงินทอน
  double paycashchange;

  /// ชำระเงินโดย QR Code
  double sumqrcode;

  /// ชำระเงินโดย Credit Card
  double sumcreditcard;

  /// ชำระเงินโดยเงินโอน
  double summoneytransfer;

  /// ชำระเงินโดยเช็ค
  double sumcheque;

  /// ชำระเงินโดย Coupon
  double sumcoupon;

  /// ชำระเงินโดย เงินเชื่อ
  double sumcredit;

  /// สูตรส่วนลดรายการสินค้า (ก่อนคิดเงิน)
  String detaildiscountformula;
  double detailtotalamount;
  double detailtotaldiscount;

  String shiftdocno;

  /// ยอดปัดเศษ
  double roundamount;

  /// ยอดรวมหลังหักส่วนลดท้ายบิล
  double totalamountafterdiscount;

  // ยอดรวมสินค้าก่อนหักส่วนลดสินค้า
  double detailtotalamountbeforediscount;

  /// ตัดสต๊อกตามสูตรผลิด (BOM)
  bool? isbom;

  /// จำนวนแต้มที่ได้รับ
  double getpoint;

  /// จำนวนแต้มที่ใช้
  double usepoint;

  /// จำนวนเงินส่วนลดจากการใช้แต้ม
  double pointdiscountamount;

  String pointscode;

  /// จำนวนเงินคูปองแทนเงินสด
  double couponcashamount;

  /// จำนวนเงินส่วนลดจากคูปอง
  double coupondiscountamount;

  /// รายการคูปองที่ใช้
  List<CouponItemModel> coupons;

  TransactionModel({
    required this.cashiercode,
    required this.custcode,
    required this.custnames,
    required this.description,
    required this.details,
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
    required this.transflag,
    required this.vatrate,
    required this.vattype,
    required this.paymentdetail,
    required this.paymentdetailraw,
    String? guidpos,
    String? devicename,
    PosConfigBranchModel? branch,
    double? paycashamount,
    int? billtaxtype,
    String? canceldatetime,
    String? cancelusercode,
    String? cancelusername,
    String? canceldescription,
    String? cancelreason,
    String? fullvataddress,
    String? fullvatbranchnumber,
    String? fullvatname,
    String? fullvatdocnumber,
    String? fullvattaxid,
    bool? fullvatprint,
    bool? isvatregister,
    List<String>? printcopybilldatetime,
    String? tablenumber,
    String? tableopendatetime,
    String? tableclosedatetime,
    int? mancount,
    int? womancount,
    int? childcount,
    String? posid,
    double? paypointamount,
    bool? istableallacratemode,
    String? buffetcode,
    String? customertelephone,
    double? totalqty,
    double? totaldiscountvatamount,
    double? totaldiscountexceptvatamount,
    String? cashiername,
    double? paycashchange,
    double? sumqrcode,
    double? sumcreditcard,
    double? summoneytransfer,
    double? sumcheque,
    double? sumcoupon,
    double? sumcredit,
    String? detaildiscountformula,
    double? detailtotalamount,
    double? detailtotaldiscount,
    double? roundamount,
    double? totalamountafterdiscount,
    double? detailtotalamountbeforediscount,
    bool? isbom,
    String? shiftdocno,
    double? getpoint,
    double? usepoint,
    double? pointdiscountamount,
    String? pointscode,
    double? couponcashamount,
    double? coupondiscountamount,
    List<CouponItemModel>? coupons,
  })  : paycashamount = paycashamount ?? 0.0,
        paypointamount = paypointamount ?? 0.0,
        branch = branch ?? PosConfigBranchModel(guidfixed: "", code: "", names: []),
        guidpos = guidpos ?? "",
        devicename = devicename ?? "",
        billtaxtype = billtaxtype ?? 0,
        canceldatetime = canceldatetime ?? "",
        cancelusercode = cancelusercode ?? "",
        cancelusername = cancelusername ?? "",
        canceldescription = canceldescription ?? "",
        cancelreason = cancelreason ?? "",
        fullvataddress = fullvataddress ?? "",
        fullvatbranchnumber = fullvatbranchnumber ?? "",
        fullvatname = fullvatname ?? "",
        fullvatdocnumber = fullvatdocnumber ?? "",
        fullvattaxid = fullvattaxid ?? "",
        fullvatprint = fullvatprint ?? false,
        isvatregister = isvatregister ?? false,
        printcopybilldatetime = printcopybilldatetime ?? [],
        tablenumber = tablenumber ?? "",
        tableopendatetime = tableopendatetime ?? "",
        tableclosedatetime = tableclosedatetime ?? "",
        posid = posid ?? "",
        mancount = mancount ?? 0,
        womancount = womancount ?? 0,
        childcount = childcount ?? 0,
        istableallacratemode = istableallacratemode ?? false,
        buffetcode = buffetcode ?? "",
        customertelephone = customertelephone ?? "",
        totalqty = totalqty ?? 0.0,
        totaldiscountvatamount = totaldiscountvatamount ?? 0.0,
        totaldiscountexceptvatamount = totaldiscountexceptvatamount ?? 0.0,
        cashiername = cashiername ?? "",
        paycashchange = paycashchange ?? 0.0,
        sumqrcode = sumqrcode ?? 0.0,
        sumcreditcard = sumcreditcard ?? 0.0,
        summoneytransfer = summoneytransfer ?? 0.0,
        sumcheque = sumcheque ?? 0.0,
        sumcoupon = sumcoupon ?? 0.0,
        sumcredit = sumcredit ?? 0.0,
        detaildiscountformula = detaildiscountformula ?? "",
        detailtotalamount = detailtotalamount ?? 0.0,
        detailtotaldiscount = detailtotaldiscount ?? 0.0,
        roundamount = roundamount ?? 0.0,
        totalamountafterdiscount = totalamountafterdiscount ?? 0.0,
        detailtotalamountbeforediscount = detailtotalamountbeforediscount ?? 0.0,
        isbom = isbom ?? false,
        shiftdocno = shiftdocno ?? "",
        getpoint = getpoint ?? 0.0,
        usepoint = usepoint ?? 0.0,
        pointdiscountamount = pointdiscountamount ?? 0.0,
        pointscode = pointscode ?? "",
        couponcashamount = couponcashamount ?? 0.0,
        coupondiscountamount = coupondiscountamount ?? 0.0,
        coupons = coupons ?? [];

  factory TransactionModel.fromJson(Map<String, dynamic> json) => _$TransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransNameInfoModel {
  String code;
  bool isauto;
  bool isdelete;
  String name;

  TransNameInfoModel({
    String? code,
    bool? isauto,
    bool? isdelete,
    String? name,
  })  : code = code ?? "",
        isauto = isauto ?? false,
        isdelete = isdelete ?? false,
        name = name ?? "";

  factory TransNameInfoModel.fromJson(Map<String, dynamic> json) => _$TransNameInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransNameInfoModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransDetailModel {
  double averagecost;
  String barcode;
  int calcflag;
  String discount;
  double discountamount;
  double dividevalue;
  String docdatetime;
  String docref;
  String? docrefdatetime;
  int inquirytype;
  int ispos;
  String itemcode;
  String itemguid;
  List<TransNameInfoModel> itemnames;
  int itemtype;
  int laststatus;
  int linenumber;
  String locationcode;
  List<TransNameInfoModel> locationnames;
  bool multiunit;
  double price;
  double priceexcludevat;
  double qty;
  String remark;
  String shelfcode;
  double standvalue;
  double sumamount;
  double sumamountexcludevat;
  double sumofcost;
  int taxtype;
  String tolocationcode;
  List<TransNameInfoModel> tolocationnames;
  double totalqty;
  double totalvaluevat;
  String towhcode;
  List<TransNameInfoModel> towhnames;
  String unitcode;
  List<TransNameInfoModel> unitnames;
  int vatcal;
  int vattype;
  String whcode;
  List<TransNameInfoModel> whnames;
  double sumamountchoice;
  String refguid;
  int ischoice;
  String description;

  /// SKU สินค้า
  String sku;
  String extrajson;
  bool issumpoint;

  TransDetailModel({
    required this.averagecost,
    required this.barcode,
    required this.calcflag,
    required this.discount,
    required this.discountamount,
    required this.dividevalue,
    required this.docdatetime,
    required this.docref,
    required this.docrefdatetime,
    required this.inquirytype,
    required this.ispos,
    required this.itemcode,
    required this.itemguid,
    required this.itemnames,
    required this.itemtype,
    required this.laststatus,
    required this.linenumber,
    required this.locationcode,
    required this.locationnames,
    required this.multiunit,
    required this.price,
    required this.priceexcludevat,
    required this.qty,
    required this.remark,
    required this.shelfcode,
    required this.standvalue,
    required this.sumamount,
    required this.sumamountexcludevat,
    required this.sumofcost,
    required this.taxtype,
    required this.tolocationcode,
    required this.tolocationnames,
    required this.totalqty,
    required this.totalvaluevat,
    required this.towhcode,
    required this.towhnames,
    required this.unitcode,
    required this.unitnames,
    required this.vatcal,
    required this.vattype,
    required this.whcode,
    required this.whnames,
    String? sku,
    String? extrajson,
    double? sumamountchoice,
    String? refguid,
    int? ischoice,
    String? description,
    bool? issumpoint,
  })  : sku = sku ?? "",
        extrajson = extrajson ?? "",
        sumamountchoice = sumamountchoice ?? 0.0,
        refguid = refguid ?? "",
        ischoice = ischoice ?? 0,
        description = description ?? "",
        issumpoint = issumpoint ?? false;

  factory TransDetailModel.fromJson(Map<String, dynamic> json) => _$TransDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransDetailModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PaymentTransferModel {
  String accountNumber;
  int amount;
  String bankCode;
  List<TransNameInfoModel> bankNames;
  String docDateTime;

  PaymentTransferModel({
    required this.accountNumber,
    required this.amount,
    required this.bankCode,
    required this.bankNames,
    required this.docDateTime,
  });

  factory PaymentTransferModel.fromJson(Map<String, dynamic> json) => _$PaymentTransferModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentTransferModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransLocationInfoModel {
  String code;
  bool isauto;
  bool isdelete;
  String name;

  TransLocationInfoModel({
    required this.code,
    required this.isauto,
    required this.isdelete,
    required this.name,
  });

  factory TransLocationInfoModel.fromJson(Map<String, dynamic> json) => _$TransLocationInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransLocationInfoModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransPaymentDetailModel {
  double cashamount;
  String cashamounttext;
  List<TransPaymentCreditCardModel> paymentcreditcards;
  List<TransPaymentTransferModel> paymenttransfers;

  TransPaymentDetailModel({
    required this.cashamount,
    required this.cashamounttext,
    required this.paymentcreditcards,
    required this.paymenttransfers,
  });

  factory TransPaymentDetailModel.fromJson(Map<String, dynamic> json) => _$TransPaymentDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransPaymentDetailModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransPaymentCreditCardModel {
  double amount;
  String cardnumber;
  double chargevalue;
  String chargeword;
  String docdatetime;
  double totalnetworth;

  TransPaymentCreditCardModel({
    required this.amount,
    required this.cardnumber,
    required this.chargevalue,
    required this.chargeword,
    required this.docdatetime,
    required this.totalnetworth,
  });

  factory TransPaymentCreditCardModel.fromJson(Map<String, dynamic> json) => _$TransPaymentCreditCardModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransPaymentCreditCardModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransPaymentTransferModel {
  String accountnumber;
  double amount;
  String bankcode;
  List<TransNameInfoModel> banknames;
  String docdatetime;

  TransPaymentTransferModel({
    required this.accountnumber,
    required this.amount,
    required this.bankcode,
    required this.banknames,
    required this.docdatetime,
  });

  factory TransPaymentTransferModel.fromJson(Map<String, dynamic> json) => _$TransPaymentTransferModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransPaymentTransferModelToJson(this);
}
