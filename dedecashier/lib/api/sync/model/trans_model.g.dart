// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trans_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CouponItemModel _$CouponItemModelFromJson(Map<String, dynamic> json) =>
    CouponItemModel(
      couponamount: (json['couponamount'] as num).toDouble(),
      coupondescription: json['coupondescription'] as String,
      couponno: json['couponno'] as String,
      coupontype: json['coupontype'] as String,
      reservationid: json['reservationid'] as String,
      transactionid: json['transactionid'] as String,
      couponid: json['couponid'] as String,
    );

Map<String, dynamic> _$CouponItemModelToJson(CouponItemModel instance) =>
    <String, dynamic>{
      'couponamount': instance.couponamount,
      'coupondescription': instance.coupondescription,
      'couponno': instance.couponno,
      'coupontype': instance.coupontype,
      'reservationid': instance.reservationid,
      'transactionid': instance.transactionid,
      'couponid': instance.couponid,
    };

TransactionModel _$TransactionModelFromJson(
  Map<String, dynamic> json,
) => TransactionModel(
  cashiercode: json['cashiercode'] as String,
  custcode: json['custcode'] as String,
  custnames: (json['custnames'] as List<dynamic>)
      .map((e) => TransNameInfoModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  description: json['description'] as String,
  details: (json['details'] as List<dynamic>)
      .map((e) => TransDetailModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  discountword: json['discountword'] as String,
  docdatetime: json['docdatetime'] as String,
  docno: json['docno'] as String,
  docrefdate: json['docrefdate'] as String?,
  docrefno: json['docrefno'] as String,
  docreftype: (json['docreftype'] as num).toInt(),
  doctype: (json['doctype'] as num).toInt(),
  guidref: json['guidref'] as String,
  inquirytype: (json['inquirytype'] as num).toInt(),
  iscancel: json['iscancel'] as bool,
  ismanualamount: json['ismanualamount'] as bool,
  ispos: json['ispos'] as bool,
  membercode: json['membercode'] as String,
  salecode: json['salecode'] as String,
  salename: json['salename'] as String,
  status: (json['status'] as num).toInt(),
  taxdocdate: json['taxdocdate'] as String,
  taxdocno: json['taxdocno'] as String,
  totalaftervat: (json['totalaftervat'] as num).toDouble(),
  totalamount: (json['totalamount'] as num).toDouble(),
  totalbeforevat: (json['totalbeforevat'] as num).toDouble(),
  totalcost: (json['totalcost'] as num).toDouble(),
  totaldiscount: (json['totaldiscount'] as num).toDouble(),
  totalexceptvat: (json['totalexceptvat'] as num).toDouble(),
  totalvalue: (json['totalvalue'] as num).toDouble(),
  totalvatvalue: (json['totalvatvalue'] as num).toDouble(),
  transflag: (json['transflag'] as num).toInt(),
  vatrate: (json['vatrate'] as num).toDouble(),
  vattype: (json['vattype'] as num).toInt(),
  paymentdetail: TransPaymentDetailModel.fromJson(
    json['paymentdetail'] as Map<String, dynamic>,
  ),
  paymentdetailraw: json['paymentdetailraw'] as String,
  guidpos: json['guidpos'] as String?,
  devicename: json['devicename'] as String?,
  branch: json['branch'] == null
      ? null
      : PosConfigBranchModel.fromJson(json['branch'] as Map<String, dynamic>),
  paycashamount: (json['paycashamount'] as num?)?.toDouble(),
  billtaxtype: (json['billtaxtype'] as num?)?.toInt(),
  canceldatetime: json['canceldatetime'] as String?,
  cancelusercode: json['cancelusercode'] as String?,
  cancelusername: json['cancelusername'] as String?,
  canceldescription: json['canceldescription'] as String?,
  cancelreason: json['cancelreason'] as String?,
  fullvataddress: json['fullvataddress'] as String?,
  fullvatbranchnumber: json['fullvatbranchnumber'] as String?,
  fullvatname: json['fullvatname'] as String?,
  fullvatdocnumber: json['fullvatdocnumber'] as String?,
  fullvattaxid: json['fullvattaxid'] as String?,
  fullvatprint: json['fullvatprint'] as bool?,
  isvatregister: json['isvatregister'] as bool?,
  printcopybilldatetime: (json['printcopybilldatetime'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  tablenumber: json['tablenumber'] as String?,
  tableopendatetime: json['tableopendatetime'] as String?,
  tableclosedatetime: json['tableclosedatetime'] as String?,
  mancount: (json['mancount'] as num?)?.toInt(),
  womancount: (json['womancount'] as num?)?.toInt(),
  childcount: (json['childcount'] as num?)?.toInt(),
  posid: json['posid'] as String?,
  paypointamount: (json['paypointamount'] as num?)?.toDouble(),
  istableallacratemode: json['istableallacratemode'] as bool?,
  buffetcode: json['buffetcode'] as String?,
  customertelephone: json['customertelephone'] as String?,
  totalqty: (json['totalqty'] as num?)?.toDouble(),
  totaldiscountvatamount: (json['totaldiscountvatamount'] as num?)?.toDouble(),
  totaldiscountexceptvatamount: (json['totaldiscountexceptvatamount'] as num?)
      ?.toDouble(),
  cashiername: json['cashiername'] as String?,
  paycashchange: (json['paycashchange'] as num?)?.toDouble(),
  sumqrcode: (json['sumqrcode'] as num?)?.toDouble(),
  sumcreditcard: (json['sumcreditcard'] as num?)?.toDouble(),
  summoneytransfer: (json['summoneytransfer'] as num?)?.toDouble(),
  sumcheque: (json['sumcheque'] as num?)?.toDouble(),
  sumcoupon: (json['sumcoupon'] as num?)?.toDouble(),
  sumcredit: (json['sumcredit'] as num?)?.toDouble(),
  detaildiscountformula: json['detaildiscountformula'] as String?,
  detailtotalamount: (json['detailtotalamount'] as num?)?.toDouble(),
  detailtotaldiscount: (json['detailtotaldiscount'] as num?)?.toDouble(),
  roundamount: (json['roundamount'] as num?)?.toDouble(),
  totalamountafterdiscount: (json['totalamountafterdiscount'] as num?)
      ?.toDouble(),
  detailtotalamountbeforediscount:
      (json['detailtotalamountbeforediscount'] as num?)?.toDouble(),
  isbom: json['isbom'] as bool?,
  shiftdocno: json['shiftdocno'] as String?,
  getpoint: (json['getpoint'] as num?)?.toDouble(),
  usepoint: (json['usepoint'] as num?)?.toDouble(),
  pointdiscountamount: (json['pointdiscountamount'] as num?)?.toDouble(),
  pointscode: json['pointscode'] as String?,
  couponcashamount: (json['couponcashamount'] as num?)?.toDouble(),
  coupondiscountamount: (json['coupondiscountamount'] as num?)?.toDouble(),
  coupons: (json['coupons'] as List<dynamic>?)
      ?.map((e) => CouponItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TransactionModelToJson(
  TransactionModel instance,
) => <String, dynamic>{
  'cashiercode': instance.cashiercode,
  'devicename': instance.devicename,
  'guidpos': instance.guidpos,
  'custcode': instance.custcode,
  'custnames': instance.custnames.map((e) => e.toJson()).toList(),
  'branch': instance.branch.toJson(),
  'description': instance.description,
  'details': instance.details.map((e) => e.toJson()).toList(),
  'discountword': instance.discountword,
  'docdatetime': instance.docdatetime,
  'docno': instance.docno,
  'docrefdate': instance.docrefdate,
  'docrefno': instance.docrefno,
  'docreftype': instance.docreftype,
  'doctype': instance.doctype,
  'guidref': instance.guidref,
  'inquirytype': instance.inquirytype,
  'iscancel': instance.iscancel,
  'ismanualamount': instance.ismanualamount,
  'ispos': instance.ispos,
  'posid': instance.posid,
  'membercode': instance.membercode,
  'salecode': instance.salecode,
  'salename': instance.salename,
  'status': instance.status,
  'taxdocdate': instance.taxdocdate,
  'taxdocno': instance.taxdocno,
  'totalaftervat': instance.totalaftervat,
  'totalamount': instance.totalamount,
  'totalbeforevat': instance.totalbeforevat,
  'totalcost': instance.totalcost,
  'totaldiscount': instance.totaldiscount,
  'totalexceptvat': instance.totalexceptvat,
  'totalvalue': instance.totalvalue,
  'totalvatvalue': instance.totalvatvalue,
  'paycashamount': instance.paycashamount,
  'paypointamount': instance.paypointamount,
  'transflag': instance.transflag,
  'vatrate': instance.vatrate,
  'vattype': instance.vattype,
  'paymentdetail': instance.paymentdetail.toJson(),
  'paymentdetailraw': instance.paymentdetailraw,
  'billtaxtype': instance.billtaxtype,
  'canceldatetime': instance.canceldatetime,
  'cancelusercode': instance.cancelusercode,
  'cancelusername': instance.cancelusername,
  'canceldescription': instance.canceldescription,
  'cancelreason': instance.cancelreason,
  'fullvataddress': instance.fullvataddress,
  'fullvatbranchnumber': instance.fullvatbranchnumber,
  'fullvatname': instance.fullvatname,
  'fullvatdocnumber': instance.fullvatdocnumber,
  'fullvattaxid': instance.fullvattaxid,
  'fullvatprint': instance.fullvatprint,
  'isvatregister': instance.isvatregister,
  'printcopybilldatetime': instance.printcopybilldatetime,
  'tablenumber': instance.tablenumber,
  'tableopendatetime': instance.tableopendatetime,
  'tableclosedatetime': instance.tableclosedatetime,
  'mancount': instance.mancount,
  'womancount': instance.womancount,
  'childcount': instance.childcount,
  'istableallacratemode': instance.istableallacratemode,
  'buffetcode': instance.buffetcode,
  'customertelephone': instance.customertelephone,
  'totalqty': instance.totalqty,
  'totaldiscountvatamount': instance.totaldiscountvatamount,
  'totaldiscountexceptvatamount': instance.totaldiscountexceptvatamount,
  'cashiername': instance.cashiername,
  'paycashchange': instance.paycashchange,
  'sumqrcode': instance.sumqrcode,
  'sumcreditcard': instance.sumcreditcard,
  'summoneytransfer': instance.summoneytransfer,
  'sumcheque': instance.sumcheque,
  'sumcoupon': instance.sumcoupon,
  'sumcredit': instance.sumcredit,
  'detaildiscountformula': instance.detaildiscountformula,
  'detailtotalamount': instance.detailtotalamount,
  'detailtotaldiscount': instance.detailtotaldiscount,
  'shiftdocno': instance.shiftdocno,
  'roundamount': instance.roundamount,
  'totalamountafterdiscount': instance.totalamountafterdiscount,
  'detailtotalamountbeforediscount': instance.detailtotalamountbeforediscount,
  'isbom': instance.isbom,
  'getpoint': instance.getpoint,
  'usepoint': instance.usepoint,
  'pointdiscountamount': instance.pointdiscountamount,
  'pointscode': instance.pointscode,
  'couponcashamount': instance.couponcashamount,
  'coupondiscountamount': instance.coupondiscountamount,
  'coupons': instance.coupons.map((e) => e.toJson()).toList(),
};

TransNameInfoModel _$TransNameInfoModelFromJson(Map<String, dynamic> json) =>
    TransNameInfoModel(
      code: json['code'] as String?,
      isauto: json['isauto'] as bool?,
      isdelete: json['isdelete'] as bool?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$TransNameInfoModelToJson(TransNameInfoModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'isauto': instance.isauto,
      'isdelete': instance.isdelete,
      'name': instance.name,
    };

TransDetailModel _$TransDetailModelFromJson(Map<String, dynamic> json) =>
    TransDetailModel(
      averagecost: (json['averagecost'] as num).toDouble(),
      barcode: json['barcode'] as String,
      calcflag: (json['calcflag'] as num).toInt(),
      discount: json['discount'] as String,
      discountamount: (json['discountamount'] as num).toDouble(),
      dividevalue: (json['dividevalue'] as num).toDouble(),
      docdatetime: json['docdatetime'] as String,
      docref: json['docref'] as String,
      docrefdatetime: json['docrefdatetime'] as String?,
      inquirytype: (json['inquirytype'] as num).toInt(),
      ispos: (json['ispos'] as num).toInt(),
      itemcode: json['itemcode'] as String,
      itemguid: json['itemguid'] as String,
      itemnames: (json['itemnames'] as List<dynamic>)
          .map((e) => TransNameInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemtype: (json['itemtype'] as num).toInt(),
      laststatus: (json['laststatus'] as num).toInt(),
      linenumber: (json['linenumber'] as num).toInt(),
      locationcode: json['locationcode'] as String,
      locationnames: (json['locationnames'] as List<dynamic>)
          .map((e) => TransNameInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      multiunit: json['multiunit'] as bool,
      price: (json['price'] as num).toDouble(),
      priceexcludevat: (json['priceexcludevat'] as num).toDouble(),
      qty: (json['qty'] as num).toDouble(),
      remark: json['remark'] as String,
      shelfcode: json['shelfcode'] as String,
      standvalue: (json['standvalue'] as num).toDouble(),
      sumamount: (json['sumamount'] as num).toDouble(),
      sumamountexcludevat: (json['sumamountexcludevat'] as num).toDouble(),
      sumofcost: (json['sumofcost'] as num).toDouble(),
      taxtype: (json['taxtype'] as num).toInt(),
      tolocationcode: json['tolocationcode'] as String,
      tolocationnames: (json['tolocationnames'] as List<dynamic>)
          .map((e) => TransNameInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalqty: (json['totalqty'] as num).toDouble(),
      totalvaluevat: (json['totalvaluevat'] as num).toDouble(),
      towhcode: json['towhcode'] as String,
      towhnames: (json['towhnames'] as List<dynamic>)
          .map((e) => TransNameInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      unitcode: json['unitcode'] as String,
      unitnames: (json['unitnames'] as List<dynamic>)
          .map((e) => TransNameInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      vatcal: (json['vatcal'] as num).toInt(),
      vattype: (json['vattype'] as num).toInt(),
      whcode: json['whcode'] as String,
      whnames: (json['whnames'] as List<dynamic>)
          .map((e) => TransNameInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      sku: json['sku'] as String?,
      extrajson: json['extrajson'] as String?,
      sumamountchoice: (json['sumamountchoice'] as num?)?.toDouble(),
      refguid: json['refguid'] as String?,
      ischoice: (json['ischoice'] as num?)?.toInt(),
      description: json['description'] as String?,
      issumpoint: json['issumpoint'] as bool?,
    );

Map<String, dynamic> _$TransDetailModelToJson(
  TransDetailModel instance,
) => <String, dynamic>{
  'averagecost': instance.averagecost,
  'barcode': instance.barcode,
  'calcflag': instance.calcflag,
  'discount': instance.discount,
  'discountamount': instance.discountamount,
  'dividevalue': instance.dividevalue,
  'docdatetime': instance.docdatetime,
  'docref': instance.docref,
  'docrefdatetime': instance.docrefdatetime,
  'inquirytype': instance.inquirytype,
  'ispos': instance.ispos,
  'itemcode': instance.itemcode,
  'itemguid': instance.itemguid,
  'itemnames': instance.itemnames.map((e) => e.toJson()).toList(),
  'itemtype': instance.itemtype,
  'laststatus': instance.laststatus,
  'linenumber': instance.linenumber,
  'locationcode': instance.locationcode,
  'locationnames': instance.locationnames.map((e) => e.toJson()).toList(),
  'multiunit': instance.multiunit,
  'price': instance.price,
  'priceexcludevat': instance.priceexcludevat,
  'qty': instance.qty,
  'remark': instance.remark,
  'shelfcode': instance.shelfcode,
  'standvalue': instance.standvalue,
  'sumamount': instance.sumamount,
  'sumamountexcludevat': instance.sumamountexcludevat,
  'sumofcost': instance.sumofcost,
  'taxtype': instance.taxtype,
  'tolocationcode': instance.tolocationcode,
  'tolocationnames': instance.tolocationnames.map((e) => e.toJson()).toList(),
  'totalqty': instance.totalqty,
  'totalvaluevat': instance.totalvaluevat,
  'towhcode': instance.towhcode,
  'towhnames': instance.towhnames.map((e) => e.toJson()).toList(),
  'unitcode': instance.unitcode,
  'unitnames': instance.unitnames.map((e) => e.toJson()).toList(),
  'vatcal': instance.vatcal,
  'vattype': instance.vattype,
  'whcode': instance.whcode,
  'whnames': instance.whnames.map((e) => e.toJson()).toList(),
  'sumamountchoice': instance.sumamountchoice,
  'refguid': instance.refguid,
  'ischoice': instance.ischoice,
  'description': instance.description,
  'sku': instance.sku,
  'extrajson': instance.extrajson,
  'issumpoint': instance.issumpoint,
};

PaymentTransferModel _$PaymentTransferModelFromJson(
  Map<String, dynamic> json,
) => PaymentTransferModel(
  accountNumber: json['accountNumber'] as String,
  amount: (json['amount'] as num).toInt(),
  bankCode: json['bankCode'] as String,
  bankNames: (json['bankNames'] as List<dynamic>)
      .map((e) => TransNameInfoModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  docDateTime: json['docDateTime'] as String,
);

Map<String, dynamic> _$PaymentTransferModelToJson(
  PaymentTransferModel instance,
) => <String, dynamic>{
  'accountNumber': instance.accountNumber,
  'amount': instance.amount,
  'bankCode': instance.bankCode,
  'bankNames': instance.bankNames.map((e) => e.toJson()).toList(),
  'docDateTime': instance.docDateTime,
};

TransLocationInfoModel _$TransLocationInfoModelFromJson(
  Map<String, dynamic> json,
) => TransLocationInfoModel(
  code: json['code'] as String,
  isauto: json['isauto'] as bool,
  isdelete: json['isdelete'] as bool,
  name: json['name'] as String,
);

Map<String, dynamic> _$TransLocationInfoModelToJson(
  TransLocationInfoModel instance,
) => <String, dynamic>{
  'code': instance.code,
  'isauto': instance.isauto,
  'isdelete': instance.isdelete,
  'name': instance.name,
};

TransPaymentDetailModel _$TransPaymentDetailModelFromJson(
  Map<String, dynamic> json,
) => TransPaymentDetailModel(
  cashamount: (json['cashamount'] as num).toDouble(),
  cashamounttext: json['cashamounttext'] as String,
  paymentcreditcards: (json['paymentcreditcards'] as List<dynamic>)
      .map(
        (e) => TransPaymentCreditCardModel.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  paymenttransfers: (json['paymenttransfers'] as List<dynamic>)
      .map((e) => TransPaymentTransferModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TransPaymentDetailModelToJson(
  TransPaymentDetailModel instance,
) => <String, dynamic>{
  'cashamount': instance.cashamount,
  'cashamounttext': instance.cashamounttext,
  'paymentcreditcards': instance.paymentcreditcards
      .map((e) => e.toJson())
      .toList(),
  'paymenttransfers': instance.paymenttransfers.map((e) => e.toJson()).toList(),
};

TransPaymentCreditCardModel _$TransPaymentCreditCardModelFromJson(
  Map<String, dynamic> json,
) => TransPaymentCreditCardModel(
  amount: (json['amount'] as num).toDouble(),
  cardnumber: json['cardnumber'] as String,
  chargevalue: (json['chargevalue'] as num).toDouble(),
  chargeword: json['chargeword'] as String,
  docdatetime: json['docdatetime'] as String,
  totalnetworth: (json['totalnetworth'] as num).toDouble(),
);

Map<String, dynamic> _$TransPaymentCreditCardModelToJson(
  TransPaymentCreditCardModel instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'cardnumber': instance.cardnumber,
  'chargevalue': instance.chargevalue,
  'chargeword': instance.chargeword,
  'docdatetime': instance.docdatetime,
  'totalnetworth': instance.totalnetworth,
};

TransPaymentTransferModel _$TransPaymentTransferModelFromJson(
  Map<String, dynamic> json,
) => TransPaymentTransferModel(
  accountnumber: json['accountnumber'] as String,
  amount: (json['amount'] as num).toDouble(),
  bankcode: json['bankcode'] as String,
  banknames: (json['banknames'] as List<dynamic>)
      .map((e) => TransNameInfoModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  docdatetime: json['docdatetime'] as String,
);

Map<String, dynamic> _$TransPaymentTransferModelToJson(
  TransPaymentTransferModel instance,
) => <String, dynamic>{
  'accountnumber': instance.accountnumber,
  'amount': instance.amount,
  'bankcode': instance.bankcode,
  'banknames': instance.banknames.map((e) => e.toJson()).toList(),
  'docdatetime': instance.docdatetime,
};
