// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileSettingCompanyImageModel _$ProfileSettingCompanyImageModelFromJson(
        Map<String, dynamic> json) =>
    ProfileSettingCompanyImageModel(
      xorder: (json['xorder'] as num).toInt(),
      uri: json['uri'] as String,
    );

Map<String, dynamic> _$ProfileSettingCompanyImageModelToJson(
        ProfileSettingCompanyImageModel instance) =>
    <String, dynamic>{
      'xorder': instance.xorder,
      'uri': instance.uri,
    };

ProfileQrPaymentModel _$ProfileQrPaymentModelFromJson(
        Map<String, dynamic> json) =>
    ProfileQrPaymentModel(
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
          ?.map((e) => ProfileSettingCompanyImageModel.fromJson(
              e as Map<String, dynamic>))
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
        ProfileQrPaymentModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'bankcode': instance.bankcode,
      'banknames': instance.banknames.map((e) => e.toJson()).toList(),
      'bookbankcode': instance.bookbankcode,
      'bookbanknames': instance.bookbanknames?.map((e) => e.toJson()).toList(),
      'bookbankimages':
          instance.bookbankimages?.map((e) => e.toJson()).toList(),
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

LanguageNameModel _$LanguageNameModelFromJson(Map<String, dynamic> json) =>
    LanguageNameModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$LanguageNameModelToJson(LanguageNameModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };

LanguageSystemModel _$LanguageSystemModelFromJson(Map<String, dynamic> json) =>
    LanguageSystemModel(
      code: json['code'] as String,
      text: json['text'] as String,
    );

Map<String, dynamic> _$LanguageSystemModelToJson(
        LanguageSystemModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'text': instance.text,
    };

LanguageSystemCodeModel _$LanguageSystemCodeModelFromJson(
        Map<String, dynamic> json) =>
    LanguageSystemCodeModel(
      code: json['code'] as String,
      langs: (json['langs'] as List<dynamic>)
          .map((e) => LanguageSystemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LanguageSystemCodeModelToJson(
        LanguageSystemCodeModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'langs': instance.langs.map((e) => e.toJson()).toList(),
    };

ResponseDataModel _$ResponseDataModelFromJson(Map<String, dynamic> json) =>
    ResponseDataModel(
      data: json['data'] as List<dynamic>,
    );

Map<String, dynamic> _$ResponseDataModelToJson(ResponseDataModel instance) =>
    <String, dynamic>{
      'data': instance.data,
    };

HttpGetDataModel _$HttpGetDataModelFromJson(Map<String, dynamic> json) =>
    HttpGetDataModel(
      code: json['code'] as String,
      json: json['json'] as String,
    );

Map<String, dynamic> _$HttpGetDataModelToJson(HttpGetDataModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'json': instance.json,
    };

SyncStaffDeviceModel _$SyncStaffDeviceModelFromJson(
        Map<String, dynamic> json) =>
    SyncStaffDeviceModel(
      clientGuid: json['clientGuid'] as String,
      clientName: json['clientName'] as String,
      clientIp: json['clientIp'] as String,
      securityCode: json['securityCode'] as String,
    );

Map<String, dynamic> _$SyncStaffDeviceModelToJson(
        SyncStaffDeviceModel instance) =>
    <String, dynamic>{
      'clientGuid': instance.clientGuid,
      'clientName': instance.clientName,
      'clientIp': instance.clientIp,
      'securityCode': instance.securityCode,
    };

StaffOrderModel _$StaffOrderModelFromJson(Map<String, dynamic> json) =>
    StaffOrderModel(
      tableNumber: json['tableNumber'] as String,
      barcode: json['barcode'] as String,
      qty: json['qty'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$StaffOrderModelToJson(StaffOrderModel instance) =>
    <String, dynamic>{
      'tableNumber': instance.tableNumber,
      'barcode': instance.barcode,
      'qty': instance.qty,
      'amount': instance.amount,
    };

ProductBarcodeStatusObjectBoxStruct
    _$ProductBarcodeStatusObjectBoxStructFromJson(Map<String, dynamic> json) =>
        ProductBarcodeStatusObjectBoxStruct(
          barcode: json['barcode'] as String,
          orderAutoStock: json['orderAutoStock'] as bool,
          orderStatus: (json['orderStatus'] as num).toInt(),
          orderDisable: json['orderDisable'] as bool,
          qtyStart: (json['qtyStart'] as num).toDouble(),
          qtyBalance: (json['qtyBalance'] as num).toDouble(),
          qtyMin: (json['qtyMin'] as num).toDouble(),
        )..id = (json['id'] as num).toInt();

Map<String, dynamic> _$ProductBarcodeStatusObjectBoxStructToJson(
        ProductBarcodeStatusObjectBoxStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'barcode': instance.barcode,
      'orderStatus': instance.orderStatus,
      'orderAutoStock': instance.orderAutoStock,
      'orderDisable': instance.orderDisable,
      'qtyStart': instance.qtyStart,
      'qtyBalance': instance.qtyBalance,
      'qtyMin': instance.qtyMin,
    };

StaffModel _$StaffModelFromJson(Map<String, dynamic> json) => StaffModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$StaffModelToJson(StaffModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };
