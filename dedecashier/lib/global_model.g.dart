// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LanguageSystemModel _$LanguageSystemModelFromJson(Map<String, dynamic> json) =>
    LanguageSystemModel(
      code: json['code'] as String,
      text: json['text'] as String,
    );

Map<String, dynamic> _$LanguageSystemModelToJson(
  LanguageSystemModel instance,
) => <String, dynamic>{'code': instance.code, 'text': instance.text};

LanguageSystemCodeModel _$LanguageSystemCodeModelFromJson(
  Map<String, dynamic> json,
) => LanguageSystemCodeModel(
  code: json['code'] as String,
  langs: (json['langs'] as List<dynamic>)
      .map((e) => LanguageSystemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LanguageSystemCodeModelToJson(
  LanguageSystemCodeModel instance,
) => <String, dynamic>{
  'code': instance.code,
  'langs': instance.langs.map((e) => e.toJson()).toList(),
};

PrinterLocalStrongDataModel _$PrinterLocalStrongDataModelFromJson(
  Map<String, dynamic> json,
) => PrinterLocalStrongDataModel(
  code: json['code'] as String? ?? "",
  name: json['name'] as String? ?? "",
  ipAddress: json['ipAddress'] as String? ?? "",
  ipPort: (json['ipPort'] as num?)?.toInt() ?? 0,
  productName: json['productName'] as String? ?? "",
  deviceName: json['deviceName'] as String? ?? "",
  deviceId: json['deviceId'] as String? ?? "",
  manufacturer: json['manufacturer'] as String? ?? "",
  vendorId: json['vendorId'] as String? ?? "",
  productId: json['productId'] as String? ?? "",
  paperType: (json['paperType'] as num?)?.toInt() ?? 2,
  isReady: json['isReady'] as bool? ?? false,
  isPaperOut: json['isPaperOut'] as bool? ?? false,
  formSummeryCode: json['formSummeryCode'] as String? ?? "",
  formTaxCode: json['formTaxCode'] as String? ?? "",
  formFullTaxCode: json['formFullTaxCode'] as String? ?? "",
  isConfigConnectSuccess: json['isConfigConnectSuccess'] as bool? ?? false,
  printerType:
      $enumDecodeNullable(_$PrinterTypeEnumEnumMap, json['printerType']) ??
      PrinterTypeEnum.thermal,
  printerConnectType:
      $enumDecodeNullable(
        _$PrinterConnectEnumEnumMap,
        json['printerConnectType'],
      ) ??
      PrinterConnectEnum.ip,
  printBillAuto: json['printBillAuto'] as bool? ?? false,
);

Map<String, dynamic> _$PrinterLocalStrongDataModelToJson(
  PrinterLocalStrongDataModel instance,
) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'ipAddress': instance.ipAddress,
  'ipPort': instance.ipPort,
  'productName': instance.productName,
  'deviceName': instance.deviceName,
  'deviceId': instance.deviceId,
  'manufacturer': instance.manufacturer,
  'vendorId': instance.vendorId,
  'productId': instance.productId,
  'paperType': instance.paperType,
  'printBillAuto': instance.printBillAuto,
  'printerType': _$PrinterTypeEnumEnumMap[instance.printerType]!,
  'printerConnectType':
      _$PrinterConnectEnumEnumMap[instance.printerConnectType]!,
  'isConfigConnectSuccess': instance.isConfigConnectSuccess,
  'isReady': instance.isReady,
  'isPaperOut': instance.isPaperOut,
  'formSummeryCode': instance.formSummeryCode,
  'formTaxCode': instance.formTaxCode,
  'formFullTaxCode': instance.formFullTaxCode,
};

const _$PrinterTypeEnumEnumMap = {
  PrinterTypeEnum.thermal: 'thermal',
  PrinterTypeEnum.dot: 'dot',
  PrinterTypeEnum.laser: 'laser',
  PrinterTypeEnum.inkjet: 'inkjet',
};

const _$PrinterConnectEnumEnumMap = {
  PrinterConnectEnum.ip: 'ip',
  PrinterConnectEnum.bluetooth: 'bluetooth',
  PrinterConnectEnum.usb: 'usb',
  PrinterConnectEnum.windows: 'windows',
  PrinterConnectEnum.sunmi1: 'sunmi1',
};

PosHoldProcessModel _$PosHoldProcessModelFromJson(Map<String, dynamic> json) =>
    PosHoldProcessModel(
        code: json['code'] as String,
        holdType: (json['holdType'] as num?)?.toInt() ?? 1,
        payScreenActive: (json['payScreenActive'] as num?)?.toInt() ?? 0,
        ismember: json['ismember'] as bool?,
        customerGuid: json['customerGuid'] as String?,
        tableNumber: json['tableNumber'] as String? ?? "",
        isDelivery: json['isDelivery'] as bool? ?? false,
        deliveryNumber: json['deliveryNumber'] as String? ?? "",
        customerCode: json['customerCode'] as String? ?? "",
        customerName: json['customerName'] as String? ?? "",
        detailDiscountFormula: json['detailDiscountFormula'] as String? ?? "",
        activeLineGuid: json['activeLineGuid'] as String? ?? "",
        customerPhone: json['customerPhone'] as String? ?? "",
        priceLevel: json['priceLevel'] as String?,
        customerPointsCode: json['customerPointsCode'] as String?,
      )
      ..logCount = (json['logCount'] as num).toInt()
      ..saleCode = json['saleCode'] as String
      ..saleName = json['saleName'] as String
      ..payScreenData = PosPayModel.fromJson(
        json['payScreenData'] as Map<String, dynamic>,
      )
      ..posProcess = PosProcessModel.fromJson(
        json['posProcess'] as Map<String, dynamic>,
      );

Map<String, dynamic> _$PosHoldProcessModelToJson(
  PosHoldProcessModel instance,
) => <String, dynamic>{
  'code': instance.code,
  'holdType': instance.holdType,
  'payScreenActive': instance.payScreenActive,
  'logCount': instance.logCount,
  'saleCode': instance.saleCode,
  'saleName': instance.saleName,
  'customerCode': instance.customerCode,
  'customerPointsCode': instance.customerPointsCode,
  'customerName': instance.customerName,
  'customerPhone': instance.customerPhone,
  'ismember': instance.ismember,
  'priceLevel': instance.priceLevel,
  'customerGuid': instance.customerGuid,
  'payScreenData': instance.payScreenData.toJson(),
  'posProcess': instance.posProcess.toJson(),
  'tableNumber': instance.tableNumber,
  'isDelivery': instance.isDelivery,
  'deliveryNumber': instance.deliveryNumber,
  'detailDiscountFormula': instance.detailDiscountFormula,
  'activeLineGuid': instance.activeLineGuid,
};

HttpGetDataModel _$HttpGetDataModelFromJson(Map<String, dynamic> json) =>
    HttpGetDataModel(
      code: json['code'] as String,
      json: json['json'] as String,
    );

Map<String, dynamic> _$HttpGetDataModelToJson(HttpGetDataModel instance) =>
    <String, dynamic>{'code': instance.code, 'json': instance.json};

HttpParameterModel _$HttpParameterModelFromJson(Map<String, dynamic> json) =>
    HttpParameterModel(
      parentGuid: json['parentGuid'] as String? ?? "",
      guid: json['guid'] as String? ?? "",
      barcode: json['barcode'] as String? ?? "",
      jsonData: json['jsonData'] as String? ?? "",
      holdCode: json['holdCode'] as String? ?? "",
      docMode: (json['docMode'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$HttpParameterModelToJson(HttpParameterModel instance) =>
    <String, dynamic>{
      'parentGuid': instance.parentGuid,
      'guid': instance.guid,
      'barcode': instance.barcode,
      'jsonData': instance.jsonData,
      'holdCode': instance.holdCode,
      'docMode': instance.docMode,
    };

LanguageDataModel _$LanguageDataModelFromJson(Map<String, dynamic> json) =>
    LanguageDataModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$LanguageDataModelToJson(LanguageDataModel instance) =>
    <String, dynamic>{'code': instance.code, 'name': instance.name};

ResponseDataModel _$ResponseDataModelFromJson(Map<String, dynamic> json) =>
    ResponseDataModel(data: json['data'] as List<dynamic>);

Map<String, dynamic> _$ResponseDataModelToJson(ResponseDataModel instance) =>
    <String, dynamic>{'data': instance.data};

OrderHistoryModel _$OrderHistoryModelFromJson(Map<String, dynamic> json) =>
    OrderHistoryModel(
      orderDateTime: DateTime.parse(json['orderDateTime'] as String),
      orderQty: (json['orderQty'] as num).toDouble(),
    );

Map<String, dynamic> _$OrderHistoryModelToJson(OrderHistoryModel instance) =>
    <String, dynamic>{
      'orderDateTime': instance.orderDateTime.toIso8601String(),
      'orderQty': instance.orderQty,
    };

OrderServedHistoryModel _$OrderServedHistoryModelFromJson(
  Map<String, dynamic> json,
) => OrderServedHistoryModel(
  servedDateTime: DateTime.parse(json['servedDateTime'] as String),
  servedQty: (json['servedQty'] as num).toDouble(),
);

Map<String, dynamic> _$OrderServedHistoryModelToJson(
  OrderServedHistoryModel instance,
) => <String, dynamic>{
  'servedDateTime': instance.servedDateTime.toIso8601String(),
  'servedQty': instance.servedQty,
};

OrderCancelHistoryModel _$OrderCancelHistoryModelFromJson(
  Map<String, dynamic> json,
) => OrderCancelHistoryModel(
  cancelDateTime: DateTime.parse(json['cancelDateTime'] as String),
  cancelQty: (json['cancelQty'] as num).toDouble(),
);

Map<String, dynamic> _$OrderCancelHistoryModelToJson(
  OrderCancelHistoryModel instance,
) => <String, dynamic>{
  'cancelDateTime': instance.cancelDateTime.toIso8601String(),
  'cancelQty': instance.cancelQty,
};

OrderProductOptionModel _$OrderProductOptionModelFromJson(
  Map<String, dynamic> json,
) => OrderProductOptionModel(
  guid: json['guid'] as String,
  choicetype: (json['choicetype'] as num).toInt(),
  maxselect: (json['maxselect'] as num).toInt(),
  minselect: (json['minselect'] as num).toInt(),
  names: (json['names'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  choices: (json['choices'] as List<dynamic>)
      .map(
        (e) =>
            OrderProductOptionChoiceModel.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$OrderProductOptionModelToJson(
  OrderProductOptionModel instance,
) => <String, dynamic>{
  'guid': instance.guid,
  'choicetype': instance.choicetype,
  'maxselect': instance.maxselect,
  'minselect': instance.minselect,
  'names': instance.names.map((e) => e.toJson()).toList(),
  'choices': instance.choices.map((e) => e.toJson()).toList(),
};

OrderProductOptionChoiceModel _$OrderProductOptionChoiceModelFromJson(
  Map<String, dynamic> json,
) => OrderProductOptionChoiceModel(
  guid: json['guid'] as String,
  names: (json['names'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  price: json['price'] as String,
  qty: (json['qty'] as num).toDouble(),
  selected: json['selected'] as bool,
  priceValue: (json['priceValue'] as num).toDouble(),
);

Map<String, dynamic> _$OrderProductOptionChoiceModelToJson(
  OrderProductOptionChoiceModel instance,
) => <String, dynamic>{
  'guid': instance.guid,
  'names': instance.names.map((e) => e.toJson()).toList(),
  'price': instance.price,
  'qty': instance.qty,
  'selected': instance.selected,
  'priceValue': instance.priceValue,
};

PriceDataModel _$PriceDataModelFromJson(Map<String, dynamic> json) =>
    PriceDataModel(
      keynumber: (json['keynumber'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
    );

Map<String, dynamic> _$PriceDataModelToJson(PriceDataModel instance) =>
    <String, dynamic>{'keynumber': instance.keynumber, 'price': instance.price};

ProfileSettingModel _$ProfileSettingModelFromJson(Map<String, dynamic> json) =>
    ProfileSettingModel(
      company: ProfileSettingCompanyModel.fromJson(
        json['company'] as Map<String, dynamic>,
      ),
      languagelist: (json['languagelist'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      configsystem: ProfileSettingConfigSystemModel.fromJson(
        json['configsystem'] as Map<String, dynamic>,
      ),
      branch: (json['branch'] as List<dynamic>)
          .map(
            (e) =>
                ProfileSettingBranchModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      center: json['center'] == null
          ? null
          : ProfileCenterModel.fromJson(json['center'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProfileSettingModelToJson(
  ProfileSettingModel instance,
) => <String, dynamic>{
  'company': instance.company.toJson(),
  'languagelist': instance.languagelist,
  'configsystem': instance.configsystem.toJson(),
  'branch': instance.branch.map((e) => e.toJson()).toList(),
  'center': instance.center.toJson(),
};

ProfileSettingBranchModel _$ProfileSettingBranchModelFromJson(
  Map<String, dynamic> json,
) => ProfileSettingBranchModel(
  guidfixed: json['guidfixed'] as String?,
  code: json['code'] as String?,
  names: (json['names'] as List<dynamic>?)
      ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  paymentrounding: json['paymentrounding'] == null
      ? null
      : PaymentRoundingModel.fromJson(
          json['paymentrounding'] as Map<String, dynamic>,
        ),
  companynames: (json['companynames'] as List<dynamic>?)
      ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  contact: json['contact'] == null
      ? null
      : ContactModel.fromJson(json['contact'] as Map<String, dynamic>),
  pos: json['pos'] == null
      ? null
      : PosModel.fromJson(json['pos'] as Map<String, dynamic>),
  pointconfig: json['pointconfig'] == null
      ? null
      : PointConfigModel.fromJson(json['pointconfig'] as Map<String, dynamic>),
  ismainshop: json['ismainshop'] as bool?,
  mainshopid: json['mainshopid'] as String?,
  productcentertype: (json['productcentertype'] as num?)?.toInt(),
  debtorcentertype: (json['debtorcentertype'] as num?)?.toInt(),
);

Map<String, dynamic> _$ProfileSettingBranchModelToJson(
  ProfileSettingBranchModel instance,
) => <String, dynamic>{
  'guidfixed': instance.guidfixed,
  'code': instance.code,
  'names': instance.names.map((e) => e.toJson()).toList(),
  'paymentrounding': instance.paymentrounding.toJson(),
  'companynames': instance.companynames.map((e) => e.toJson()).toList(),
  'contact': instance.contact.toJson(),
  'pos': instance.pos.toJson(),
  'pointconfig': instance.pointconfig.toJson(),
  'ismainshop': instance.ismainshop,
  'mainshopid': instance.mainshopid,
  'productcentertype': instance.productcentertype,
  'debtorcentertype': instance.debtorcentertype,
};

ContactModel _$ContactModelFromJson(Map<String, dynamic> json) => ContactModel(
  address: (json['address'] as List<dynamic>?)
      ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ContactModelToJson(ContactModel instance) =>
    <String, dynamic>{
      'address': instance.address.map((e) => e.toJson()).toList(),
    };

PosModel _$PosModelFromJson(Map<String, dynamic> json) => PosModel(
  taxid: json['taxid'] as String?,
  vatrate: (json['vatrate'] as num?)?.toDouble(),
  vattypesale: (json['vattypesale'] as num?)?.toInt(),
  vattypepurchase: (json['vattypepurchase'] as num?)?.toInt(),
  inquirytypesale: (json['inquirytypesale'] as num?)?.toInt(),
  inquirytypepurchase: (json['inquirytypepurchase'] as num?)?.toInt(),
  headerreceiptpos: json['headerreceiptpos'] as String?,
  footerreceiptpos: json['footerreceiptpos'] as String?,
  isbom: json['isbom'] as bool?,
);

Map<String, dynamic> _$PosModelToJson(PosModel instance) => <String, dynamic>{
  'taxid': instance.taxid,
  'vatrate': instance.vatrate,
  'vattypesale': instance.vattypesale,
  'vattypepurchase': instance.vattypepurchase,
  'inquirytypesale': instance.inquirytypesale,
  'inquirytypepurchase': instance.inquirytypepurchase,
  'headerreceiptpos': instance.headerreceiptpos,
  'footerreceiptpos': instance.footerreceiptpos,
  'isbom': instance.isbom,
};

ProfileCreditCardModel _$ProfileCreditCardModelFromJson(
  Map<String, dynamic> json,
) => ProfileCreditCardModel(
  names: (json['names'] as List<dynamic>?)
      ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  bookbank: ProfileCreditCardBookBankModel.fromJson(
    json['bookbank'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ProfileCreditCardModelToJson(
  ProfileCreditCardModel instance,
) => <String, dynamic>{
  'names': instance.names?.map((e) => e.toJson()).toList(),
  'bookbank': instance.bookbank.toJson(),
};

ProfileTransferModel _$ProfileTransferModelFromJson(
  Map<String, dynamic> json,
) => ProfileTransferModel(
  names: (json['names'] as List<dynamic>?)
      ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  bookbank: ProfileCreditCardBookBankModel.fromJson(
    json['bookbank'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ProfileTransferModelToJson(
  ProfileTransferModel instance,
) => <String, dynamic>{
  'names': instance.names?.map((e) => e.toJson()).toList(),
  'bookbank': instance.bookbank.toJson(),
};

TransOptionsModel _$TransOptionsModelFromJson(Map<String, dynamic> json) =>
    TransOptionsModel(
      barcode: json['barcode'] as String?,
      item_code: json['item_code'] as String?,
      item_name: json['item_name'] as String?,
      unit_code: json['unit_code'] as String?,
      unit_name: json['unit_name'] as String?,
      qty: (json['qty'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      total_amount: (json['total_amount'] as num?)?.toDouble(),
      is_except_vat: json['is_except_vat'] as bool?,
      vat_type: (json['vat_type'] as num?)?.toInt(),
      price_exclude_vat: (json['price_exclude_vat'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TransOptionsModelToJson(TransOptionsModel instance) =>
    <String, dynamic>{
      'barcode': instance.barcode,
      'item_code': instance.item_code,
      'item_name': instance.item_name,
      'unit_code': instance.unit_code,
      'unit_name': instance.unit_name,
      'qty': instance.qty,
      'price': instance.price,
      'total_amount': instance.total_amount,
      'is_except_vat': instance.is_except_vat,
      'vat_type': instance.vat_type,
      'price_exclude_vat': instance.price_exclude_vat,
    };

ProfileCreditCardBookBankModel _$ProfileCreditCardBookBankModelFromJson(
  Map<String, dynamic> json,
) => ProfileCreditCardBookBankModel(
  accountcode: json['accountcode'] as String?,
  accountname: json['accountname'] as String?,
  bankbranch: json['bankbranch'] as String?,
  bankcode: json['bankcode'] as String?,
  banknames: (json['banknames'] as List<dynamic>?)
      ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  bookcode: json['bookcode'] as String?,
  images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
  names: (json['names'] as List<dynamic>?)
      ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  passbook: json['passbook'] as String?,
);

Map<String, dynamic> _$ProfileCreditCardBookBankModelToJson(
  ProfileCreditCardBookBankModel instance,
) => <String, dynamic>{
  'accountcode': instance.accountcode,
  'accountname': instance.accountname,
  'bankbranch': instance.bankbranch,
  'bankcode': instance.bankcode,
  'banknames': instance.banknames?.map((e) => e.toJson()).toList(),
  'bookcode': instance.bookcode,
  'images': instance.images,
  'names': instance.names?.map((e) => e.toJson()).toList(),
  'passbook': instance.passbook,
};

ProfileQrPaymentModel _$ProfileQrPaymentModelFromJson(
  Map<String, dynamic> json,
) => ProfileQrPaymentModel(
  guidfixed: json['guidfixed'] as String?,
  code: json['code'] as String,
  bankcode: json['bankcode'] as String,
  banknames: (json['banknames'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  bookbankcode: json['bookbankcode'] as String,
  bookbanknames: (json['bookbanknames'] as List<dynamic>?)
      ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  bookbankimages: (json['bookbankimages'] as List<dynamic>?)
      ?.map(
        (e) =>
            ProfileSettingCompanyImageModel.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  isactive: json['isactive'] as bool,
  qrtype: (json['qrtype'] as num).toInt(),
  qrnames: (json['qrnames'] as List<dynamic>?)
      ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  qrcode: json['qrcode'] as String,
  logo: json['logo'] as String,
  apikey: json['apikey'] as String?,
  accessCode: json['accessCode'] as String?,
  bankcharge: json['bankcharge'] as String?,
  billerCode: json['billerCode'] as String?,
  billerID: json['billerID'] as String?,
  closeQr: (json['closeQr'] as num?)?.toInt(),
  customercharge: json['customercharge'] as String?,
  merchantName: json['merchantName'] as String?,
  storeID: json['storeID'] as String?,
  terminalID: json['terminalID'] as String?,
  token: json['token'] as String?,
);

Map<String, dynamic> _$ProfileQrPaymentModelToJson(
  ProfileQrPaymentModel instance,
) => <String, dynamic>{
  'code': instance.code,
  'bankcode': instance.bankcode,
  'banknames': instance.banknames.map((e) => e.toJson()).toList(),
  'bookbankcode': instance.bookbankcode,
  'bookbanknames': instance.bookbanknames?.map((e) => e.toJson()).toList(),
  'bookbankimages': instance.bookbankimages?.map((e) => e.toJson()).toList(),
  'isactive': instance.isactive,
  'qrtype': instance.qrtype,
  'qrnames': instance.qrnames?.map((e) => e.toJson()).toList(),
  'qrcode': instance.qrcode,
  'logo': instance.logo,
  'apikey': instance.apikey,
  'accessCode': instance.accessCode,
  'bankcharge': instance.bankcharge,
  'billerCode': instance.billerCode,
  'billerID': instance.billerID,
  'closeQr': instance.closeQr,
  'customercharge': instance.customercharge,
  'guidfixed': instance.guidfixed,
  'merchantName': instance.merchantName,
  'storeID': instance.storeID,
  'terminalID': instance.terminalID,
  'token': instance.token,
};

ProfileSettingConfigSystemModel _$ProfileSettingConfigSystemModelFromJson(
  Map<String, dynamic> json,
) => ProfileSettingConfigSystemModel(
  vatrate: (json['vatrate'] as num).toDouble(),
  vattypesale: (json['vattypesale'] as num).toInt(),
  vattypepurchase: (json['vattypepurchase'] as num).toInt(),
  inquirytypesale: (json['inquirytypesale'] as num).toInt(),
  inquirytypepurchase: (json['inquirytypepurchase'] as num).toInt(),
  headerreceiptpos: json['headerreceiptpos'] as String?,
  footerreciptpos: json['footerreciptpos'] as String?,
);

Map<String, dynamic> _$ProfileSettingConfigSystemModelToJson(
  ProfileSettingConfigSystemModel instance,
) => <String, dynamic>{
  'vatrate': instance.vatrate,
  'vattypesale': instance.vattypesale,
  'vattypepurchase': instance.vattypepurchase,
  'inquirytypesale': instance.inquirytypesale,
  'inquirytypepurchase': instance.inquirytypepurchase,
  'headerreceiptpos': instance.headerreceiptpos,
  'footerreciptpos': instance.footerreciptpos,
};

ProfileSettingCompanyImageModel _$ProfileSettingCompanyImageModelFromJson(
  Map<String, dynamic> json,
) => ProfileSettingCompanyImageModel(
  xorder: (json['xorder'] as num).toInt(),
  uri: json['uri'] as String,
);

Map<String, dynamic> _$ProfileSettingCompanyImageModelToJson(
  ProfileSettingCompanyImageModel instance,
) => <String, dynamic>{'xorder': instance.xorder, 'uri': instance.uri};

ProfileSettingCompanyModel _$ProfileSettingCompanyModelFromJson(
  Map<String, dynamic> json,
) => ProfileSettingCompanyModel(
  names: (json['names'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  taxID: json['taxID'] as String,
  branchNames: (json['branchNames'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  addresses: (json['addresses'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  phones: (json['phones'] as List<dynamic>).map((e) => e as String).toList(),
  emailOwners: (json['emailOwners'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  emailStaffs: (json['emailStaffs'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  latitude: json['latitude'] as String,
  longitude: json['longitude'] as String,
  usebranch: json['usebranch'] as bool,
  usedepartment: json['usedepartment'] as bool,
  images: (json['images'] as List<dynamic>)
      .map(
        (e) =>
            ProfileSettingCompanyImageModel.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  logo: json['logo'] as String?,
  ismainshop: json['ismainshop'] as bool?,
  productcentertype: (json['productcentertype'] as num?)?.toInt(),
  posproductcentertype: (json['posproductcentertype'] as num?)?.toInt(),
  debtorcentertype: (json['debtorcentertype'] as num?)?.toInt(),
  mainshopid: json['mainshopid'] as String?,
);

Map<String, dynamic> _$ProfileSettingCompanyModelToJson(
  ProfileSettingCompanyModel instance,
) => <String, dynamic>{
  'names': instance.names.map((e) => e.toJson()).toList(),
  'taxID': instance.taxID,
  'branchNames': instance.branchNames.map((e) => e.toJson()).toList(),
  'addresses': instance.addresses.map((e) => e.toJson()).toList(),
  'phones': instance.phones,
  'emailOwners': instance.emailOwners,
  'emailStaffs': instance.emailStaffs,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'usebranch': instance.usebranch,
  'usedepartment': instance.usedepartment,
  'images': instance.images.map((e) => e.toJson()).toList(),
  'logo': instance.logo,
  'ismainshop': instance.ismainshop,
  'productcentertype': instance.productcentertype,
  'posproductcentertype': instance.posproductcentertype,
  'debtorcentertype': instance.debtorcentertype,
  'mainshopid': instance.mainshopid,
};

OrderTempUpdateForSplitModel _$OrderTempUpdateForSplitModelFromJson(
  Map<String, dynamic> json,
) => OrderTempUpdateForSplitModel(
  sourceTable: json['sourceTable'] as String,
  targetTable: json['targetTable'] as String,
  sourceGuid: json['sourceGuid'] as String,
);

Map<String, dynamic> _$OrderTempUpdateForSplitModelToJson(
  OrderTempUpdateForSplitModel instance,
) => <String, dynamic>{
  'sourceTable': instance.sourceTable,
  'targetTable': instance.targetTable,
  'sourceGuid': instance.sourceGuid,
};

PosConfigSlipModel _$PosConfigSlipModelFromJson(Map<String, dynamic> json) =>
    PosConfigSlipModel(
      code: json['code'] as String,
      name: json['name'] as String,
      formcode: json['formcode'] as String,
      formnames: (json['formnames'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      headernames: (json['headernames'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PosConfigSlipModelToJson(PosConfigSlipModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'formcode': instance.formcode,
      'formnames': instance.formnames.map((e) => e.toJson()).toList(),
      'headernames': instance.headernames.map((e) => e.toJson()).toList(),
    };

PosConfigBranchModel _$PosConfigBranchModelFromJson(
  Map<String, dynamic> json,
) => PosConfigBranchModel(
  guidfixed: json['guidfixed'] as String,
  code: json['code'] as String,
  names: (json['names'] as List<dynamic>)
      .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  couponusetype: (json['couponusetype'] as num?)?.toInt(),
  pos: json['pos'] == null
      ? null
      : PosModel.fromJson(json['pos'] as Map<String, dynamic>),
  paymentrounding: json['paymentrounding'] == null
      ? null
      : PaymentRoundingModel.fromJson(
          json['paymentrounding'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PosConfigBranchModelToJson(
  PosConfigBranchModel instance,
) => <String, dynamic>{
  'guidfixed': instance.guidfixed,
  'code': instance.code,
  'couponusetype': instance.couponusetype,
  'names': instance.names.map((e) => e.toJson()).toList(),
  'paymentrounding': instance.paymentrounding.toJson(),
  'pos': instance.pos?.toJson(),
};

PaymentRoundingModel _$PaymentRoundingModelFromJson(
  Map<String, dynamic> json,
) => PaymentRoundingModel(
  banktransfer: json['banktransfer'] == null
      ? null
      : PaymentMethodRoundingModel.fromJson(
          json['banktransfer'] as Map<String, dynamic>,
        ),
  cash: json['cash'] == null
      ? null
      : PaymentMethodRoundingModel.fromJson(
          json['cash'] as Map<String, dynamic>,
        ),
  cheque: json['cheque'] == null
      ? null
      : PaymentMethodRoundingModel.fromJson(
          json['cheque'] as Map<String, dynamic>,
        ),
  coupon: json['coupon'] == null
      ? null
      : PaymentMethodRoundingModel.fromJson(
          json['coupon'] as Map<String, dynamic>,
        ),
  creditcard: json['creditcard'] == null
      ? null
      : PaymentMethodRoundingModel.fromJson(
          json['creditcard'] as Map<String, dynamic>,
        ),
  delivery: json['delivery'] == null
      ? null
      : PaymentMethodRoundingModel.fromJson(
          json['delivery'] as Map<String, dynamic>,
        ),
  qrcode: json['qrcode'] == null
      ? null
      : PaymentMethodRoundingModel.fromJson(
          json['qrcode'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PaymentRoundingModelToJson(
  PaymentRoundingModel instance,
) => <String, dynamic>{
  'banktransfer': instance.banktransfer.toJson(),
  'cash': instance.cash.toJson(),
  'cheque': instance.cheque.toJson(),
  'coupon': instance.coupon.toJson(),
  'creditcard': instance.creditcard.toJson(),
  'delivery': instance.delivery.toJson(),
  'qrcode': instance.qrcode.toJson(),
};

PaymentMethodRoundingModel _$PaymentMethodRoundingModelFromJson(
  Map<String, dynamic> json,
) => PaymentMethodRoundingModel(
  enabled: json['enabled'] as bool?,
  rules: (json['rules'] as List<dynamic>?)
      ?.map((e) => RoundingRuleModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaymentMethodRoundingModelToJson(
  PaymentMethodRoundingModel instance,
) => <String, dynamic>{
  'enabled': instance.enabled,
  'rules': instance.rules.map((e) => e.toJson()).toList(),
};

RoundingRuleModel _$RoundingRuleModelFromJson(Map<String, dynamic> json) =>
    RoundingRuleModel(
      lowerbound: (json['lowerbound'] as num?)?.toDouble(),
      roundto: (json['roundto'] as num?)?.toDouble(),
      upperbound: (json['upperbound'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$RoundingRuleModelToJson(RoundingRuleModel instance) =>
    <String, dynamic>{
      'lowerbound': instance.lowerbound,
      'roundto': instance.roundto,
      'upperbound': instance.upperbound,
    };

PosConfigModel _$PosConfigModelFromJson(
  Map<String, dynamic> json,
) => PosConfigModel(
  code: json['code'] as String?,
  doccode: json['doccode'] as String?,
  vattype: (json['vattype'] as num?)?.toInt(),
  zonegroupnumber: (json['zonegroupnumber'] as num?)?.toInt(),
  tablegroupnumber: (json['tablegroupnumber'] as num?)?.toInt(),
  kitchengroupnumber: (json['kitchengroupnumber'] as num?)?.toInt(),
  categorygroupnumber: (json['categorygroupnumber'] as num?)?.toInt(),
  vatrate: (json['vatrate'] as num?)?.toDouble(),
  docformatinv: json['docformatinv'] as String?,
  docformatesalereturn: json['docformatesalereturn'] as String?,
  docformattaxinv: json['docformattaxinv'] as String?,
  mediaguid: json['mediaguid'] as String?,
  billheader: (json['billheader'] as List<dynamic>?)
      ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  billfooter: (json['billfooter'] as List<dynamic>?)
      ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  isvatregister: json['isvatregister'] as bool?,
  isejournal: json['isejournal'] as bool?,
  devicenumber: json['devicenumber'] as String?,
  slips: (json['slips'] as List<dynamic>?)
      ?.map((e) => PosConfigSlipModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  logourl: json['logourl'] as String?,
  qrcodes: (json['qrcodes'] as List<dynamic>?)
      ?.map((e) => ProfileQrPaymentModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  creditcards: (json['creditcards'] as List<dynamic>?)
      ?.map((e) => ProfileCreditCardModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  transfers: (json['transfers'] as List<dynamic>?)
      ?.map((e) => ProfileTransferModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  businesstype: (json['businesstype'] as num?)?.toInt(),
  location: json['location'] == null
      ? null
      : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
  warehouse: json['warehouse'] == null
      ? null
      : WarehouseModel.fromJson(json['warehouse'] as Map<String, dynamic>),
  branch: json['branch'] == null
      ? null
      : PosConfigBranchModel.fromJson(json['branch'] as Map<String, dynamic>),
  employees: (json['employees'] as List<dynamic>?)
      ?.map((e) => PosEmployeeModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  iscopyreceipt: json['iscopyreceipt'] as bool?,
);

Map<String, dynamic> _$PosConfigModelToJson(PosConfigModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'doccode': instance.doccode,
      'vattype': instance.vattype,
      'zonegroupnumber': instance.zonegroupnumber,
      'tablegroupnumber': instance.tablegroupnumber,
      'kitchengroupnumber': instance.kitchengroupnumber,
      'categorygroupnumber': instance.categorygroupnumber,
      'vatrate': instance.vatrate,
      'docformatinv': instance.docformatinv,
      'docformatesalereturn': instance.docformatesalereturn,
      'docformattaxinv': instance.docformattaxinv,
      'billheader': instance.billheader.map((e) => e.toJson()).toList(),
      'billfooter': instance.billfooter.map((e) => e.toJson()).toList(),
      'isejournal': instance.isejournal,
      'devicenumber': instance.devicenumber,
      'isvatregister': instance.isvatregister,
      'slips': instance.slips.map((e) => e.toJson()).toList(),
      'logourl': instance.logourl,
      'qrcodes': instance.qrcodes?.map((e) => e.toJson()).toList(),
      'creditcards': instance.creditcards?.map((e) => e.toJson()).toList(),
      'transfers': instance.transfers?.map((e) => e.toJson()).toList(),
      'mediaguid': instance.mediaguid,
      'employees': instance.employees.map((e) => e.toJson()).toList(),
      'location': instance.location.toJson(),
      'warehouse': instance.warehouse.toJson(),
      'branch': instance.branch.toJson(),
      'businesstype': instance.businesstype,
      'iscopyreceipt': instance.iscopyreceipt,
    };

PosEmployeeModel _$PosEmployeeModelFromJson(Map<String, dynamic> json) =>
    PosEmployeeModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$PosEmployeeModelToJson(PosEmployeeModel instance) =>
    <String, dynamic>{'code': instance.code, 'name': instance.name};

PosMediaDescriptionModel _$PosMediaDescriptionModelFromJson(
  Map<String, dynamic> json,
) => PosMediaDescriptionModel(
  code: json['code'] as String,
  name: json['name'] as String,
  isauto: json['isauto'] as bool,
  isdelete: json['isdelete'] as bool,
);

Map<String, dynamic> _$PosMediaDescriptionModelToJson(
  PosMediaDescriptionModel instance,
) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'isauto': instance.isauto,
  'isdelete': instance.isdelete,
};

PosMediaResourceDescriptionModel _$PosMediaResourceDescriptionModelFromJson(
  Map<String, dynamic> json,
) => PosMediaResourceDescriptionModel(
  code: json['code'] as String,
  name: json['name'] as String,
  isauto: json['isauto'] as bool,
  isdelete: json['isdelete'] as bool,
);

Map<String, dynamic> _$PosMediaResourceDescriptionModelToJson(
  PosMediaResourceDescriptionModel instance,
) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'isauto': instance.isauto,
  'isdelete': instance.isdelete,
};

PosMediaResourceModel _$PosMediaResourceModelFromJson(
  Map<String, dynamic> json,
) => PosMediaResourceModel(
  mediaType: (json['mediaType'] as num).toInt(),
  uri: json['uri'] as String,
  daysofweek: (json['daysofweek'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  fromDate: json['fromDate'] as String,
  toDate: json['toDate'] as String,
  fromTime: json['fromTime'] as String,
  toTime: json['toTime'] as String,
  description: (json['description'] as List<dynamic>)
      .map(
        (e) => PosMediaResourceDescriptionModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  displaytime: (json['displaytime'] as num).toInt(),
);

Map<String, dynamic> _$PosMediaResourceModelToJson(
  PosMediaResourceModel instance,
) => <String, dynamic>{
  'mediaType': instance.mediaType,
  'uri': instance.uri,
  'daysofweek': instance.daysofweek,
  'fromDate': instance.fromDate,
  'toDate': instance.toDate,
  'fromTime': instance.fromTime,
  'toTime': instance.toTime,
  'description': instance.description.map((e) => e.toJson()).toList(),
  'displaytime': instance.displaytime,
};

PosMediaModel _$PosMediaModelFromJson(
  Map<String, dynamic> json,
) => PosMediaModel(
  guidfixed: json['guidfixed'] as String?,
  code: json['code'] as String?,
  description: (json['description'] as List<dynamic>?)
      ?.map((e) => PosMediaDescriptionModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  resources: (json['resources'] as List<dynamic>?)
      ?.map((e) => PosMediaResourceModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PosMediaModelToJson(PosMediaModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'code': instance.code,
      'description': instance.description.map((e) => e.toJson()).toList(),
      'resources': instance.resources.map((e) => e.toJson()).toList(),
    };

PosInformationModel _$PosInformationModelFromJson(Map<String, dynamic> json) =>
    PosInformationModel(
      shop_id: json['shop_id'] as String,
      shop_name: json['shop_name'] as String,
    );

Map<String, dynamic> _$PosInformationModelToJson(
  PosInformationModel instance,
) => <String, dynamic>{
  'shop_id': instance.shop_id,
  'shop_name': instance.shop_name,
};

LocationModel _$LocationModelFromJson(Map<String, dynamic> json) =>
    LocationModel(
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => TransNameInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LocationModelToJson(LocationModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'names': instance.names.map((e) => e.toJson()).toList(),
    };

WarehouseModel _$WarehouseModelFromJson(Map<String, dynamic> json) =>
    WarehouseModel(
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => TransNameInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      guidfixed: json['guidfixed'] as String,
    );

Map<String, dynamic> _$WarehouseModelToJson(WarehouseModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'guidfixed': instance.guidfixed,
      'names': instance.names.map((e) => e.toJson()).toList(),
    };

PrintQueueModel _$PrintQueueModelFromJson(Map<String, dynamic> json) =>
    PrintQueueModel(
      imageBytes: (json['imageBytes'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$PrintQueueModelToJson(PrintQueueModel instance) =>
    <String, dynamic>{'imageBytes': instance.imageBytes};

CallerModel _$CallerModelFromJson(Map<String, dynamic> json) => CallerModel(
  command: json['command'] as String,
  refguid: json['refguid'] as String,
  calldatetime: DateTime.parse(json['calldatetime'] as String),
  actionstatus: (json['actionstatus'] as num).toInt(),
  actiondatetime: DateTime.parse(json['actiondatetime'] as String),
);

Map<String, dynamic> _$CallerModelToJson(CallerModel instance) =>
    <String, dynamic>{
      'command': instance.command,
      'calldatetime': instance.calldatetime.toIso8601String(),
      'actionstatus': instance.actionstatus,
      'actiondatetime': instance.actiondatetime.toIso8601String(),
      'refguid': instance.refguid,
    };

LineNotifyModel _$LineNotifyModelFromJson(Map<String, dynamic> json) =>
    LineNotifyModel(
      guid: json['guid'] as String,
      token: json['token'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$LineNotifyModelToJson(LineNotifyModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'token': instance.token,
      'message': instance.message,
    };

PointConfigModel _$PointConfigModelFromJson(
  Map<String, dynamic> json,
) => PointConfigModel(
  generalrules: (json['generalrules'] as List<dynamic>?)
      ?.map((e) => PointGeneralRuleModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  specialrules: (json['specialrules'] as List<dynamic>?)
      ?.map((e) => PointSpecialRuleModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  pointusagetype: (json['pointusagetype'] as num?)?.toInt(),
);

Map<String, dynamic> _$PointConfigModelToJson(PointConfigModel instance) =>
    <String, dynamic>{
      'generalrules': instance.generalrules.map((e) => e.toJson()).toList(),
      'specialrules': instance.specialrules.map((e) => e.toJson()).toList(),
      'pointusagetype': instance.pointusagetype,
    };

PointGeneralRuleModel _$PointGeneralRuleModelFromJson(
  Map<String, dynamic> json,
) => PointGeneralRuleModel(
  startdate: json['startdate'] as String?,
  enddate: json['enddate'] as String?,
  payperpoint: (json['payperpoint'] as num?)?.toDouble(),
  pointvalue: (json['pointvalue'] as num?)?.toDouble(),
);

Map<String, dynamic> _$PointGeneralRuleModelToJson(
  PointGeneralRuleModel instance,
) => <String, dynamic>{
  'startdate': instance.startdate,
  'enddate': instance.enddate,
  'payperpoint': instance.payperpoint,
  'pointvalue': instance.pointvalue,
};

PointSpecialRuleModel _$PointSpecialRuleModelFromJson(
  Map<String, dynamic> json,
) => PointSpecialRuleModel(
  startdate: json['startdate'] as String?,
  enddate: json['enddate'] as String?,
  multiplier: (json['multiplier'] as num?)?.toDouble(),
  sunday: json['sunday'] as bool?,
  monday: json['monday'] as bool?,
  tuesday: json['tuesday'] as bool?,
  wednesday: json['wednesday'] as bool?,
  thursday: json['thursday'] as bool?,
  friday: json['friday'] as bool?,
  saturday: json['saturday'] as bool?,
  maxpointperbill: (json['maxpointperbill'] as num?)?.toDouble(),
);

Map<String, dynamic> _$PointSpecialRuleModelToJson(
  PointSpecialRuleModel instance,
) => <String, dynamic>{
  'startdate': instance.startdate,
  'enddate': instance.enddate,
  'multiplier': instance.multiplier,
  'sunday': instance.sunday,
  'monday': instance.monday,
  'tuesday': instance.tuesday,
  'wednesday': instance.wednesday,
  'thursday': instance.thursday,
  'friday': instance.friday,
  'saturday': instance.saturday,
  'maxpointperbill': instance.maxpointperbill,
};

ProfileCenterModel _$ProfileCenterModelFromJson(Map<String, dynamic> json) =>
    ProfileCenterModel(
      guidfixed: json['guidfixed'] as String?,
      profilepicture: json['profilepicture'] as String?,
      name1: json['name1'] as String?,
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      telephone: json['telephone'] as String?,
      branchcode: json['branchcode'] as String?,
      ismainshop: json['ismainshop'] as bool?,
      productcentertype: (json['productcentertype'] as num?)?.toInt(),
      posproductcentertype: (json['posproductcentertype'] as num?)?.toInt(),
      debtorcentertype: (json['debtorcentertype'] as num?)?.toInt(),
      mainshopid: json['mainshopid'] as String?,
      address: (json['address'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List<dynamic>?)
          ?.map(
            (e) => ProfileSettingCompanyImageModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      logo: json['logo'] as String?,
      settings: json['settings'] == null
          ? null
          : ProfileCenterSettingsModel.fromJson(
              json['settings'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ProfileCenterModelToJson(ProfileCenterModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'profilepicture': instance.profilepicture,
      'name1': instance.name1,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'telephone': instance.telephone,
      'branchcode': instance.branchcode,
      'ismainshop': instance.ismainshop,
      'productcentertype': instance.productcentertype,
      'posproductcentertype': instance.posproductcentertype,
      'debtorcentertype': instance.debtorcentertype,
      'mainshopid': instance.mainshopid,
      'address': instance.address.map((e) => e.toJson()).toList(),
      'images': instance.images.map((e) => e.toJson()).toList(),
      'logo': instance.logo,
      'settings': instance.settings.toJson(),
    };

ProfileCenterSettingsModel _$ProfileCenterSettingsModelFromJson(
  Map<String, dynamic> json,
) => ProfileCenterSettingsModel(
  taxid: json['taxid'] as String?,
  emailowners: (json['emailowners'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  emailstaffs: (json['emailstaffs'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  isusebranch: json['isusebranch'] as bool?,
  isusedepartment: json['isusedepartment'] as bool?,
  vattypesale: (json['vattypesale'] as num?)?.toInt(),
  vattypepurchase: (json['vattypepurchase'] as num?)?.toInt(),
  inquirytypesale: (json['inquirytypesale'] as num?)?.toInt(),
  inquirytypepurchase: (json['inquirytypepurchase'] as num?)?.toInt(),
  languageconfigs: (json['languageconfigs'] as List<dynamic>?)
      ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProfileCenterSettingsModelToJson(
  ProfileCenterSettingsModel instance,
) => <String, dynamic>{
  'taxid': instance.taxid,
  'emailowners': instance.emailowners,
  'emailstaffs': instance.emailstaffs,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'isusebranch': instance.isusebranch,
  'isusedepartment': instance.isusedepartment,
  'vattypesale': instance.vattypesale,
  'vattypepurchase': instance.vattypepurchase,
  'inquirytypesale': instance.inquirytypesale,
  'inquirytypepurchase': instance.inquirytypepurchase,
  'languageconfigs': instance.languageconfigs.map((e) => e.toJson()).toList(),
};
