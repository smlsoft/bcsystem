// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LineNotifyFromServerModel _$LineNotifyFromServerModelFromJson(
        Map<String, dynamic> json) =>
    LineNotifyFromServerModel(
      token: json['token'] as String,
    );

Map<String, dynamic> _$LineNotifyFromServerModelToJson(
        LineNotifyFromServerModel instance) =>
    <String, dynamic>{
      'token': instance.token,
    };

ShopProfileModel _$ShopProfileModelFromJson(Map<String, dynamic> json) =>
    ShopProfileModel(
      name1: json['name1'] as String,
      kitchens: (json['kitchens'] as List<dynamic>?)
          ?.map((e) => KitchenModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      orderstation: ShopProfileOrderStationModel.fromJson(
          json['orderstation'] as Map<String, dynamic>),
      shopid: json['shopid'] as String?,
      profilepicture: json['profilepicture'] as String?,
      isbcmember: json['isbcmember'] as bool?,
      apikey: json['apikey'] as String?,
    );

Map<String, dynamic> _$ShopProfileModelToJson(ShopProfileModel instance) =>
    <String, dynamic>{
      'name1': instance.name1,
      'shopid': instance.shopid,
      'profilepicture': instance.profilepicture,
      'isbcmember': instance.isbcmember,
      'apikey': instance.apikey,
      'kitchens': instance.kitchens?.map((e) => e.toJson()).toList(),
      'orderstation': instance.orderstation.toJson(),
    };

ShopProfileOrderStationModel _$ShopProfileOrderStationModelFromJson(
        Map<String, dynamic> json) =>
    ShopProfileOrderStationModel(
      code: json['code'] as String,
      branch: ShopProfileBranchModel.fromJson(
          json['branch'] as Map<String, dynamic>),
      salechannels: (json['salechannels'] as List<dynamic>?)
          ?.map((e) => ShopProfileBranchSaleChannelModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      deviceinfo: ShopProfileDeviceInfoModel.fromJson(
          json['deviceinfo'] as Map<String, dynamic>),
      label: json['label'] as String,
      adminpin: json['adminpin'] as String,
      categorygroupnumber: (json['categorygroupnumber'] as num).toInt(),
      media: json['media'] == null
          ? null
          : ShopProfileMediaModel.fromJson(
              json['media'] as Map<String, dynamic>),
      isvatregister: json['isvatregister'] as bool,
      vattype: (json['vattype'] as num).toInt(),
      vatrate: (json['vatrate'] as num).toDouble(),
      lineoaimg: json['lineoaimg'] as String?,
      backgroundurl: json['backgroundurl'] as String?,
      qrcodes: (json['qrcodes'] as List<dynamic>?)
          ?.map(
              (e) => ProfileQrPaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ShopProfileOrderStationModelToJson(
        ShopProfileOrderStationModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'branch': instance.branch.toJson(),
      'salechannels': instance.salechannels?.map((e) => e.toJson()).toList(),
      'deviceinfo': instance.deviceinfo.toJson(),
      'qrcodes': instance.qrcodes.map((e) => e.toJson()).toList(),
      'label': instance.label,
      'adminpin': instance.adminpin,
      'categorygroupnumber': instance.categorygroupnumber,
      'media': instance.media.toJson(),
      'isvatregister': instance.isvatregister,
      'vattype': instance.vattype,
      'vatrate': instance.vatrate,
      'lineoaimg': instance.lineoaimg,
      'backgroundurl': instance.backgroundurl,
    };

ShopProfileMediaModel _$ShopProfileMediaModelFromJson(
        Map<String, dynamic> json) =>
    ShopProfileMediaModel(
      code: json['code'] as String?,
      resources: (json['resources'] as List<dynamic>?)
          ?.map((e) =>
              ShopProfileMediaResourceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ShopProfileMediaModelToJson(
        ShopProfileMediaModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'resources': instance.resources.map((e) => e.toJson()).toList(),
    };

ShopProfileMediaResourceModel _$ShopProfileMediaResourceModelFromJson(
        Map<String, dynamic> json) =>
    ShopProfileMediaResourceModel(
      mediaType: (json['mediaType'] as num?)?.toInt(),
      uri: json['uri'] as String?,
    );

Map<String, dynamic> _$ShopProfileMediaResourceModelToJson(
        ShopProfileMediaResourceModel instance) =>
    <String, dynamic>{
      'mediaType': instance.mediaType,
      'uri': instance.uri,
    };

ShopProfileDeviceInfoModel _$ShopProfileDeviceInfoModelFromJson(
        Map<String, dynamic> json) =>
    ShopProfileDeviceInfoModel(
      code: json['code'] as String,
      docformat: json['docformat'] as String,
    );

Map<String, dynamic> _$ShopProfileDeviceInfoModelToJson(
        ShopProfileDeviceInfoModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'docformat': instance.docformat,
    };

PointConfigModel _$PointConfigModelFromJson(Map<String, dynamic> json) =>
    PointConfigModel(
      generalrules: (json['generalrules'] as List<dynamic>?)
          ?.map(
              (e) => PointGeneralRuleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      specialrules: (json['specialrules'] as List<dynamic>?)
          ?.map(
              (e) => PointSpecialRuleModel.fromJson(e as Map<String, dynamic>))
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
        Map<String, dynamic> json) =>
    PointGeneralRuleModel(
      startdate: json['startdate'] as String?,
      enddate: json['enddate'] as String?,
      payperpoint: (json['payperpoint'] as num?)?.toDouble(),
      pointvalue: (json['pointvalue'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PointGeneralRuleModelToJson(
        PointGeneralRuleModel instance) =>
    <String, dynamic>{
      'startdate': instance.startdate,
      'enddate': instance.enddate,
      'payperpoint': instance.payperpoint,
      'pointvalue': instance.pointvalue,
    };

PointSpecialRuleModel _$PointSpecialRuleModelFromJson(
        Map<String, dynamic> json) =>
    PointSpecialRuleModel(
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
        PointSpecialRuleModel instance) =>
    <String, dynamic>{
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

ShopProfileBranchModel _$ShopProfileBranchModelFromJson(
        Map<String, dynamic> json) =>
    ShopProfileBranchModel(
      code: json['code'] as String,
      companynames: (json['companynames'] as List<dynamic>?)
          ?.map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pointconfig: json['pointconfig'] == null
          ? null
          : PointConfigModel.fromJson(
              json['pointconfig'] as Map<String, dynamic>),
      contact: json['contact'] == null
          ? null
          : ShopProfileBranchContactModel.fromJson(
              json['contact'] as Map<String, dynamic>),
      pos: ShopProfileBranchPosModel.fromJson(
          json['pos'] as Map<String, dynamic>),
      logouri: json['logouri'] as String,
      paymentrounding: json['paymentrounding'] == null
          ? null
          : PaymentRoundingModel.fromJson(
              json['paymentrounding'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ShopProfileBranchModelToJson(
        ShopProfileBranchModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'names': instance.names?.map((e) => e.toJson()).toList(),
      'companynames': instance.companynames?.map((e) => e.toJson()).toList(),
      'contact': instance.contact?.toJson(),
      'pos': instance.pos.toJson(),
      'logouri': instance.logouri,
      'paymentrounding': instance.paymentrounding.toJson(),
      'pointconfig': instance.pointconfig.toJson(),
    };

PaymentRoundingModel _$PaymentRoundingModelFromJson(
        Map<String, dynamic> json) =>
    PaymentRoundingModel(
      banktransfer: json['banktransfer'] == null
          ? null
          : PaymentMethodRoundingModel.fromJson(
              json['banktransfer'] as Map<String, dynamic>),
      cash: json['cash'] == null
          ? null
          : PaymentMethodRoundingModel.fromJson(
              json['cash'] as Map<String, dynamic>),
      cheque: json['cheque'] == null
          ? null
          : PaymentMethodRoundingModel.fromJson(
              json['cheque'] as Map<String, dynamic>),
      coupon: json['coupon'] == null
          ? null
          : PaymentMethodRoundingModel.fromJson(
              json['coupon'] as Map<String, dynamic>),
      creditcard: json['creditcard'] == null
          ? null
          : PaymentMethodRoundingModel.fromJson(
              json['creditcard'] as Map<String, dynamic>),
      delivery: json['delivery'] == null
          ? null
          : PaymentMethodRoundingModel.fromJson(
              json['delivery'] as Map<String, dynamic>),
      qrcode: json['qrcode'] == null
          ? null
          : PaymentMethodRoundingModel.fromJson(
              json['qrcode'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PaymentRoundingModelToJson(
        PaymentRoundingModel instance) =>
    <String, dynamic>{
      'banktransfer': instance.banktransfer.toJson(),
      'cash': instance.cash.toJson(),
      'cheque': instance.cheque.toJson(),
      'coupon': instance.coupon.toJson(),
      'creditcard': instance.creditcard.toJson(),
      'delivery': instance.delivery.toJson(),
      'qrcode': instance.qrcode.toJson(),
    };

PaymentMethodRoundingModel _$PaymentMethodRoundingModelFromJson(
        Map<String, dynamic> json) =>
    PaymentMethodRoundingModel(
      enabled: json['enabled'] as bool?,
      rules: (json['rules'] as List<dynamic>?)
          ?.map((e) => RoundingRuleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaymentMethodRoundingModelToJson(
        PaymentMethodRoundingModel instance) =>
    <String, dynamic>{
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

PosConfigBranchModel _$PosConfigBranchModelFromJson(
        Map<String, dynamic> json) =>
    PosConfigBranchModel(
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PosConfigBranchModelToJson(
        PosConfigBranchModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'names': instance.names?.map((e) => e.toJson()).toList(),
    };

ShopProfileBranchContactModel _$ShopProfileBranchContactModelFromJson(
        Map<String, dynamic> json) =>
    ShopProfileBranchContactModel(
      address: (json['address'] as List<dynamic>?)
          ?.map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      phonenumber: json['phonenumber'] as String,
    );

Map<String, dynamic> _$ShopProfileBranchContactModelToJson(
        ShopProfileBranchContactModel instance) =>
    <String, dynamic>{
      'address': instance.address?.map((e) => e.toJson()).toList(),
      'phonenumber': instance.phonenumber,
    };

ShopProfileBranchPosModel _$ShopProfileBranchPosModelFromJson(
        Map<String, dynamic> json) =>
    ShopProfileBranchPosModel(
      taxid: json['taxid'] as String,
      headerreceiptpos: json['headerreceiptpos'] as String,
      footerreceiptpos: json['footerreceiptpos'] as String,
    );

Map<String, dynamic> _$ShopProfileBranchPosModelToJson(
        ShopProfileBranchPosModel instance) =>
    <String, dynamic>{
      'taxid': instance.taxid,
      'headerreceiptpos': instance.headerreceiptpos,
      'footerreceiptpos': instance.footerreceiptpos,
    };

ShopProfileBranchSaleChannelModel _$ShopProfileBranchSaleChannelModelFromJson(
        Map<String, dynamic> json) =>
    ShopProfileBranchSaleChannelModel(
      code: json['code'] as String,
      name: json['name'] as String,
      imageuri: json['imageuri'] as String,
      gp: (json['gp'] as num).toDouble(),
      gptype: (json['gptype'] as num).toInt(),
      price: (json['price'] as num).toInt(),
    );

Map<String, dynamic> _$ShopProfileBranchSaleChannelModelToJson(
        ShopProfileBranchSaleChannelModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'imageuri': instance.imageuri,
      'gp': instance.gp,
      'price': instance.price,
      'gptype': instance.gptype,
    };

KitchenModel _$KitchenModelFromJson(Map<String, dynamic> json) => KitchenModel(
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      products:
          (json['products'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$KitchenModelToJson(KitchenModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'products': instance.products,
    };

KitchenDeviceModel _$KitchenDeviceModelFromJson(Map<String, dynamic> json) =>
    KitchenDeviceModel(
      code: json['code'] as String,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    )..printer = PrinterLocalConfigModel.fromJson(
        json['printer'] as Map<String, dynamic>);

Map<String, dynamic> _$KitchenDeviceModelToJson(KitchenDeviceModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'printer': instance.printer.toJson(),
    };

DeviceConfigModel _$DeviceConfigModelFromJson(Map<String, dynamic> json) =>
    DeviceConfigModel(
      shopId: json['shopId'] as String?,
      branchId: json['branchId'] as String?,
      orderStationCode: json['orderStationCode'] as String?,
      printerForOwner: json['printerForOwner'] == null
          ? null
          : PrinterLocalConfigModel.fromJson(
              json['printerForOwner'] as Map<String, dynamic>),
      printerForOrderStation: json['printerForOrderStation'] == null
          ? null
          : PrinterLocalConfigModel.fromJson(
              json['printerForOrderStation'] as Map<String, dynamic>),
      systemCondition: (json['systemCondition'] as num?)?.toInt(),
      machineCondition: (json['machineCondition'] as num?)?.toInt(),
      shopPaymentCondition: (json['shopPaymentCondition'] as num?)?.toInt(),
      orderOnlineCondition: json['orderOnlineCondition'] as bool?,
      showQrCodeOrderOnline: json['showQrCodeOrderOnline'] as bool?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      deviceId: json['deviceId'] as String?,
      useOrderEatAtTheRestaurant: json['useOrderEatAtTheRestaurant'] as bool?,
      useOrderTakeAway: json['useOrderTakeAway'] as bool?,
      isServer: json['isServer'] as bool?,
      cashierKitchenTiming: (json['cashierKitchenTiming'] as num?)?.toInt(),
      kitchens: (json['kitchens'] as List<dynamic>?)
          ?.map((e) => KitchenDeviceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      useMember: json['useMember'] as bool?,
      usercode: json['usercode'] as String?,
      token: json['token'] as String?,
      apikey: json['apikey'] as String?,
      isdev: json['isdev'] as String?,
      paymentrounding: json['paymentrounding'] == null
          ? null
          : PaymentRoundingModel.fromJson(
              json['paymentrounding'] as Map<String, dynamic>),
      itemsPerRow: (json['itemsPerRow'] as num?)?.toInt(),
      orderHereText: json['orderHereText'] as String?,
      orderHereTextColor: json['orderHereTextColor'] as String?,
      orderHereTextColor2: json['orderHereTextColor2'] as String?,
      orderHereShadowColor: json['orderHereShadowColor'] as String?,
      orderLayoutPreset: (json['orderLayoutPreset'] as num?)?.toInt(),
      primaryThemeColor: json['primaryThemeColor'] as String?,
      primaryTextColor: json['primaryTextColor'] as String?,
      isFirstTimeSetup: json['isFirstTimeSetup'] as bool?,
    );

Map<String, dynamic> _$DeviceConfigModelToJson(DeviceConfigModel instance) =>
    <String, dynamic>{
      'usercode': instance.usercode,
      'token': instance.token,
      'shopId': instance.shopId,
      'branchId': instance.branchId,
      'orderStationCode': instance.orderStationCode,
      'apikey': instance.apikey,
      'isdev': instance.isdev,
      'printerForOwner': instance.printerForOwner.toJson(),
      'printerForOrderStation': instance.printerForOrderStation.toJson(),
      'systemCondition': instance.systemCondition,
      'machineCondition': instance.machineCondition,
      'shopPaymentCondition': instance.shopPaymentCondition,
      'orderOnlineCondition': instance.orderOnlineCondition,
      'showQrCodeOrderOnline': instance.showQrCodeOrderOnline,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'deviceId': instance.deviceId,
      'useOrderEatAtTheRestaurant': instance.useOrderEatAtTheRestaurant,
      'useOrderTakeAway': instance.useOrderTakeAway,
      'isServer': instance.isServer,
      'cashierKitchenTiming': instance.cashierKitchenTiming,
      'kitchens': instance.kitchens.map((e) => e.toJson()).toList(),
      'useMember': instance.useMember,
      'itemsPerRow': instance.itemsPerRow,
      'paymentrounding': instance.paymentrounding.toJson(),
      'orderHereText': instance.orderHereText,
      'orderHereTextColor': instance.orderHereTextColor,
      'orderHereTextColor2': instance.orderHereTextColor2,
      'orderHereShadowColor': instance.orderHereShadowColor,
      'orderLayoutPreset': instance.orderLayoutPreset,
      'primaryThemeColor': instance.primaryThemeColor,
      'primaryTextColor': instance.primaryTextColor,
      'isFirstTimeSetup': instance.isFirstTimeSetup,
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

OrderTempDetailModel _$OrderTempDetailModelFromJson(
        Map<String, dynamic> json) =>
    OrderTempDetailModel(
      orderguid: json['orderguid'] as String,
      barcode: json['barcode'] as String,
      qty: (json['qty'] as num).toDouble(),
      optionamount: (json['optionamount'] as num?)?.toDouble(),
      remark: json['remark'] as String,
      optionselected: json['optionselected'] as String,
      orderdatetime: DateTime.parse(json['orderdatetime'] as String),
      isserved: (json['isserved'] as num).toInt(),
      iscooked: (json['iscooked'] as num).toInt(),
      iscookcancel: (json['iscookcancel'] as num).toInt(),
      isservedcancel: (json['isservedcancel'] as num).toInt(),
      ordertagnumber: json['ordertagnumber'] as String,
      price: (json['price'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      discountamount: (json['discountamount'] as num?)?.toDouble(),
      salechannelcode: json['salechannelcode'] as String,
      machineid: json['machineid'] as String,
      queuenumber: (json['queuenumber'] as num).toInt(),
      istakeaway: (json['istakeaway'] as num).toInt(),
      is_except_vat: json['is_except_vat'] as bool?,
      refguid: json['refguid'] as String?,
      manufacturerguid: json['manufacturerguid'] as String?,
    );

Map<String, dynamic> _$OrderTempDetailModelToJson(
        OrderTempDetailModel instance) =>
    <String, dynamic>{
      'orderguid': instance.orderguid,
      'barcode': instance.barcode,
      'optionselected': instance.optionselected,
      'remark': instance.remark,
      'istakeaway': instance.istakeaway,
      'isserved': instance.isserved,
      'isservedcancel': instance.isservedcancel,
      'iscooked': instance.iscooked,
      'iscookcancel': instance.iscookcancel,
      'orderdatetime': instance.orderdatetime.toIso8601String(),
      'price': instance.price,
      'amount': instance.amount,
      'machineid': instance.machineid,
      'ordertagnumber': instance.ordertagnumber,
      'queuenumber': instance.queuenumber,
      'salechannelcode': instance.salechannelcode,
      'manufacturerguid': instance.manufacturerguid,
      'qty': instance.qty,
      'is_except_vat': instance.is_except_vat,
      'refguid': instance.refguid,
      'optionamount': instance.optionamount,
      'discountamount': instance.discountamount,
    };

ResponseDataModel _$ResponseDataModelFromJson(Map<String, dynamic> json) =>
    ResponseDataModel(
      data: json['data'] as List<dynamic>,
    );

Map<String, dynamic> _$ResponseDataModelToJson(ResponseDataModel instance) =>
    <String, dynamic>{
      'data': instance.data,
    };

PrinterLocalConfigModel _$PrinterLocalConfigModelFromJson(
        Map<String, dynamic> json) =>
    PrinterLocalConfigModel(
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
      formSummeryCode: json['formSummeryCode'] as String? ?? "",
      formTaxCode: json['formTaxCode'] as String? ?? "",
      formFullTaxCode: json['formFullTaxCode'] as String? ?? "",
      isConfigConnectSuccess: json['isConfigConnectSuccess'] as bool? ?? false,
      printerType: (json['printerType'] as num?)?.toInt() ?? 0,
      printerConnectType: (json['printerConnectType'] as num?)?.toInt() ?? 0,
      printBillAuto: json['printBillAuto'] as bool? ?? false,
    );

Map<String, dynamic> _$PrinterLocalConfigModelToJson(
        PrinterLocalConfigModel instance) =>
    <String, dynamic>{
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
      'printerType': instance.printerType,
      'printerConnectType': instance.printerConnectType,
      'isConfigConnectSuccess': instance.isConfigConnectSuccess,
      'isReady': instance.isReady,
      'formSummeryCode': instance.formSummeryCode,
      'formTaxCode': instance.formTaxCode,
      'formFullTaxCode': instance.formFullTaxCode,
    };

OrderOnlineParameterModel _$OrderOnlineParameterModelFromJson(
        Map<String, dynamic> json) =>
    OrderOnlineParameterModel(
      shopid: json['shopid'] as String,
      type: (json['type'] as num?)?.toInt() ?? 0,
      table: json['table'] as String? ?? "",
      qrcode: json['qrcode'] as String? ?? "",
      phone: json['phone'] as String? ?? "",
      tablebuffetcode: json['tablebuffetcode'] as String? ?? "",
    );

Map<String, dynamic> _$OrderOnlineParameterModelToJson(
        OrderOnlineParameterModel instance) =>
    <String, dynamic>{
      'shopid': instance.shopid,
      'type': instance.type,
      'table': instance.table,
      'qrcode': instance.qrcode,
      'phone': instance.phone,
      'tablebuffetcode': instance.tablebuffetcode,
    };

ResponseExcludeModel _$ResponseExcludeModelFromJson(
        Map<String, dynamic> json) =>
    ResponseExcludeModel(
      success: json['success'] as bool,
    );

Map<String, dynamic> _$ResponseExcludeModelToJson(
        ResponseExcludeModel instance) =>
    <String, dynamic>{
      'success': instance.success,
    };

ProfileQrPaymentModel _$ProfileQrPaymentModelFromJson(
        Map<String, dynamic> json) =>
    ProfileQrPaymentModel(
      guidfixed: json['guidfixed'] as String?,
      code: json['code'] as String?,
      bankcode: json['bankcode'] as String?,
      banknames: (json['banknames'] as List<dynamic>?)
          ?.map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      bookbankcode: json['bookbankcode'] as String?,
      bookbanknames: (json['bookbanknames'] as List<dynamic>?)
          ?.map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      bookbankimages: (json['bookbankimages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isactive: json['isactive'] as bool?,
      qrtype: (json['qrtype'] as num?)?.toInt(),
      qrnames: (json['qrnames'] as List<dynamic>?)
          ?.map((e) => LanguageNameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      qrcode: json['qrcode'] as String?,
      logo: json['logo'] as String?,
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
      appid: json['appid'] as String?,
      host: json['host'] as String?,
      isslipsave: json['isslipsave'] as bool?,
    );

Map<String, dynamic> _$ProfileQrPaymentModelToJson(
        ProfileQrPaymentModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'bankcode': instance.bankcode,
      'banknames': instance.banknames.map((e) => e.toJson()).toList(),
      'bookbankcode': instance.bookbankcode,
      'bookbanknames': instance.bookbanknames.map((e) => e.toJson()).toList(),
      'bookbankimages': instance.bookbankimages,
      'isactive': instance.isactive,
      'isslipsave': instance.isslipsave,
      'qrtype': instance.qrtype,
      'qrnames': instance.qrnames.map((e) => e.toJson()).toList(),
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
      'appid': instance.appid,
      'host': instance.host,
    };

LanguageDataModel _$LanguageDataModelFromJson(Map<String, dynamic> json) =>
    LanguageDataModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$LanguageDataModelToJson(LanguageDataModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
    };

PayConditionModel _$PayConditionModelFromJson(Map<String, dynamic> json) =>
    PayConditionModel(
      payType: (json['payType'] as num).toInt(),
      payTypeName: json['payTypeName'] as String,
      amount: (json['amount'] as num).toDouble(),
      payAmount: (json['payAmount'] as num).toDouble(),
      changeAmount: (json['changeAmount'] as num).toDouble(),
      cardNumber: json['cardNumber'] as String?,
      approvalCode: json['approvalCode'] as String?,
      roundAmount: (json['roundAmount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PayConditionModelToJson(PayConditionModel instance) =>
    <String, dynamic>{
      'payType': instance.payType,
      'amount': instance.amount,
      'payAmount': instance.payAmount,
      'changeAmount': instance.changeAmount,
      'payTypeName': instance.payTypeName,
      'cardNumber': instance.cardNumber,
      'approvalCode': instance.approvalCode,
      'roundAmount': instance.roundAmount,
    };

OrderTempTableModel _$OrderTempTableModelFromJson(Map<String, dynamic> json) =>
    OrderTempTableModel(
      ordertagnumber: json['ordertagnumber'] as String,
      totalamount: (json['totalamount'] as num).toDouble(),
    );

Map<String, dynamic> _$OrderTempTableModelToJson(
        OrderTempTableModel instance) =>
    <String, dynamic>{
      'ordertagnumber': instance.ordertagnumber,
      'totalamount': instance.totalamount,
    };
