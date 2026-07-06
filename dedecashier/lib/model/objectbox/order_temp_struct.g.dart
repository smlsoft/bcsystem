// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_temp_struct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderTempStruct _$OrderTempStructFromJson(Map<String, dynamic> json) =>
    OrderTempStruct(
      orderQty: (json['orderQty'] as num).toDouble(),
      orderTemp: (json['orderTemp'] as List<dynamic>)
          .map(
            (e) => OrderTempObjectBoxStruct.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$OrderTempStructToJson(OrderTempStruct instance) =>
    <String, dynamic>{
      'orderQty': instance.orderQty,
      'orderTemp': instance.orderTemp.map((e) => e.toJson()).toList(),
    };

OrderTempObjectBoxStruct _$OrderTempObjectBoxStructFromJson(
  Map<String, dynamic> json,
) => OrderTempObjectBoxStruct(
  id: (json['id'] as num).toInt(),
  orderId: json['orderId'] as String?,
  guidPos: json['guidPos'] as String?,
  orderIdMain: json['orderIdMain'] as String?,
  orderGuid: json['orderGuid'] as String?,
  docNo: json['docNo'] as String?,
  machineId: json['machineId'] as String?,
  orderDateTime: json['orderDateTime'] == null
      ? null
      : DateTime.parse(json['orderDateTime'] as String),
  barcode: json['barcode'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  amount: (json['amount'] as num?)?.toDouble(),
  isOrder: json['isOrder'] as bool?,
  isPaySuccess: json['isPaySuccess'] as bool?,
  optionSelected: json['optionSelected'] as String?,
  remark: json['remark'] as String?,
  remarkForCancel: json['remarkForCancel'] as String?,
  names: json['names'] as String?,
  takeAway: json['takeAway'] as bool?,
  unitCode: json['unitCode'] as String?,
  unitName: json['unitName'] as String?,
  imageUri: json['imageUri'] as String?,
  kdsSuccessTime: json['kdsSuccessTime'] == null
      ? null
      : DateTime.parse(json['kdsSuccessTime'] as String),
  kdsSuccess: json['kdsSuccess'] as bool?,
  kdsId: json['kdsId'] as String?,
  servedTime: json['servedTime'] == null
      ? null
      : DateTime.parse(json['servedTime'] as String),
  servedSuccess: json['servedSuccess'] as bool?,
  servedQty: (json['servedQty'] as num?)?.toDouble(),
  servedHistory: json['servedHistory'] as String?,
  orderHistory: json['orderHistory'] as String?,
  cancelQty: (json['cancelQty'] as num?)?.toDouble(),
  cancelHistory: json['cancelHistory'] as String?,
  qtyLastCancel: (json['qtyLastCancel'] as num?)?.toDouble(),
  orderQty: (json['orderQty'] as num?)?.toDouble(),
  deliveryNumber: json['deliveryNumber'] as String?,
  deliveryCode: json['deliveryCode'] as String?,
  isOrderReadySendKds: json['isOrderReadySendKds'] as bool?,
  deliveryName: json['deliveryName'] as String?,
  lastUpdateDateTime: json['lastUpdateDateTime'] == null
      ? null
      : DateTime.parse(json['lastUpdateDateTime'] as String),
  orderType: (json['orderType'] as num?)?.toInt(),
  issumpoint: json['issumpoint'] as bool?,
  orderEmployeeCode: json['orderEmployeeCode'] as String?,
  orderEmployeeDetail: json['orderEmployeeDetail'] as String?,
  isOrderSendDedeTempSuccess: json['isOrderSendDedeTempSuccess'] as bool?,
  isOrderSendKdsSuccess: json['isOrderSendKdsSuccess'] as bool?,
  isOrderSuccess: json['isOrderSuccess'] as bool?,
);

Map<String, dynamic> _$OrderTempObjectBoxStructToJson(
  OrderTempObjectBoxStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'orderGuid': instance.orderGuid,
  'guidPos': instance.guidPos,
  'orderIdMain': instance.orderIdMain,
  'machineId': instance.machineId,
  'docNo': instance.docNo,
  'orderDateTime': instance.orderDateTime.toIso8601String(),
  'barcode': instance.barcode,
  'orderQty': instance.orderQty,
  'orderHistory': instance.orderHistory,
  'cancelQty': instance.cancelQty,
  'cancelHistory': instance.cancelHistory,
  'qtyLastCancel': instance.qtyLastCancel,
  'price': instance.price,
  'amount': instance.amount,
  'isOrder': instance.isOrder,
  'isOrderSuccess': instance.isOrderSuccess,
  'isOrderSendKdsSuccess': instance.isOrderSendKdsSuccess,
  'isOrderReadySendKds': instance.isOrderReadySendKds,
  'isPaySuccess': instance.isPaySuccess,
  'optionSelected': instance.optionSelected,
  'remark': instance.remark,
  'remarkForCancel': instance.remarkForCancel,
  'names': instance.names,
  'unitCode': instance.unitCode,
  'unitName': instance.unitName,
  'imageUri': instance.imageUri,
  'takeAway': instance.takeAway,
  'issumpoint': instance.issumpoint,
  'kdsSuccessTime': instance.kdsSuccessTime.toIso8601String(),
  'kdsSuccess': instance.kdsSuccess,
  'kdsId': instance.kdsId,
  'servedTime': instance.servedTime.toIso8601String(),
  'servedSuccess': instance.servedSuccess,
  'servedQty': instance.servedQty,
  'servedHistory': instance.servedHistory,
  'deliveryNumber': instance.deliveryNumber,
  'deliveryCode': instance.deliveryCode,
  'deliveryName': instance.deliveryName,
  'lastUpdateDateTime': instance.lastUpdateDateTime.toIso8601String(),
  'orderType': instance.orderType,
  'orderEmployeeCode': instance.orderEmployeeCode,
  'orderEmployeeDetail': instance.orderEmployeeDetail,
  'isOrderSendDedeTempSuccess': instance.isOrderSendDedeTempSuccess,
};

OrderTempSyncObjectBoxStruct _$OrderTempSyncObjectBoxStructFromJson(
  Map<String, dynamic> json,
) => OrderTempSyncObjectBoxStruct(
  id: (json['id'] as num).toInt(),
  orderId: json['orderId'] as String?,
  docNo: json['docNo'] as String?,
  guidPos: json['guidPos'] as String?,
  orderGuid: json['orderGuid'] as String?,
  orderIdMain: json['orderIdMain'] as String?,
  machineId: json['machineId'] as String?,
  orderDateTime: json['orderDateTime'] == null
      ? null
      : DateTime.parse(json['orderDateTime'] as String),
  barcode: json['barcode'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  amount: (json['amount'] as num?)?.toDouble(),
  isOrder: json['isOrder'] as bool?,
  isPaySuccess: json['isPaySuccess'] as bool?,
  optionSelected: json['optionSelected'] as String?,
  remark: json['remark'] as String?,
  remarkForCancel: json['remarkForCancel'] as String?,
  names: json['names'] as String?,
  takeAway: json['takeAway'] as bool?,
  unitCode: json['unitCode'] as String?,
  unitName: json['unitName'] as String?,
  imageUri: json['imageUri'] as String?,
  kdsSuccessTime: json['kdsSuccessTime'] == null
      ? null
      : DateTime.parse(json['kdsSuccessTime'] as String),
  kdsSuccess: json['kdsSuccess'] as bool?,
  kdsId: json['kdsId'] as String?,
  servedTime: json['servedTime'] == null
      ? null
      : DateTime.parse(json['servedTime'] as String),
  servedSuccess: json['servedSuccess'] as bool?,
  servedQty: (json['servedQty'] as num?)?.toDouble(),
  servedHistory: json['servedHistory'] as String?,
  orderHistory: json['orderHistory'] as String?,
  cancelQty: (json['cancelQty'] as num?)?.toDouble(),
  cancelHistory: json['cancelHistory'] as String?,
  qtyLastCancel: (json['qtyLastCancel'] as num?)?.toDouble(),
  orderQty: (json['orderQty'] as num?)?.toDouble(),
  deliveryNumber: json['deliveryNumber'] as String?,
  deliveryCode: json['deliveryCode'] as String?,
  isOrderReadySendKds: json['isOrderReadySendKds'] as bool?,
  deliveryName: json['deliveryName'] as String?,
  lastUpdateDateTime: json['lastUpdateDateTime'] == null
      ? null
      : DateTime.parse(json['lastUpdateDateTime'] as String),
  orderType: (json['orderType'] as num?)?.toInt(),
  orderEmployeeCode: json['orderEmployeeCode'] as String?,
  orderEmployeeDetail: json['orderEmployeeDetail'] as String?,
  isOrderSendDedeTempSuccess: json['isOrderSendDedeTempSuccess'] as bool?,
  isOrderSendKdsSuccess: json['isOrderSendKdsSuccess'] as bool?,
  isOrderSuccess: json['isOrderSuccess'] as bool?,
  orderEmtry: json['orderEmtry'] as bool?,
);

Map<String, dynamic> _$OrderTempSyncObjectBoxStructToJson(
  OrderTempSyncObjectBoxStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'docNo': instance.docNo,
  'guidPos': instance.guidPos,
  'orderGuid': instance.orderGuid,
  'orderIdMain': instance.orderIdMain,
  'machineId': instance.machineId,
  'orderDateTime': instance.orderDateTime.toIso8601String(),
  'barcode': instance.barcode,
  'orderQty': instance.orderQty,
  'orderHistory': instance.orderHistory,
  'cancelQty': instance.cancelQty,
  'cancelHistory': instance.cancelHistory,
  'qtyLastCancel': instance.qtyLastCancel,
  'price': instance.price,
  'amount': instance.amount,
  'isOrder': instance.isOrder,
  'isOrderSuccess': instance.isOrderSuccess,
  'isOrderSendKdsSuccess': instance.isOrderSendKdsSuccess,
  'isOrderReadySendKds': instance.isOrderReadySendKds,
  'isPaySuccess': instance.isPaySuccess,
  'optionSelected': instance.optionSelected,
  'remark': instance.remark,
  'remarkForCancel': instance.remarkForCancel,
  'names': instance.names,
  'unitCode': instance.unitCode,
  'unitName': instance.unitName,
  'imageUri': instance.imageUri,
  'takeAway': instance.takeAway,
  'kdsSuccessTime': instance.kdsSuccessTime.toIso8601String(),
  'kdsSuccess': instance.kdsSuccess,
  'kdsId': instance.kdsId,
  'servedTime': instance.servedTime.toIso8601String(),
  'servedSuccess': instance.servedSuccess,
  'servedQty': instance.servedQty,
  'servedHistory': instance.servedHistory,
  'deliveryNumber': instance.deliveryNumber,
  'deliveryCode': instance.deliveryCode,
  'deliveryName': instance.deliveryName,
  'lastUpdateDateTime': instance.lastUpdateDateTime.toIso8601String(),
  'orderType': instance.orderType,
  'orderEmployeeCode': instance.orderEmployeeCode,
  'orderEmployeeDetail': instance.orderEmployeeDetail,
  'isOrderSendDedeTempSuccess': instance.isOrderSendDedeTempSuccess,
  'orderEmtry': instance.orderEmtry,
};
