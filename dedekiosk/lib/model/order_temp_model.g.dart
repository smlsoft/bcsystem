// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_temp_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderTempStruct _$OrderTempStructFromJson(Map<String, dynamic> json) =>
    OrderTempStruct(
      orderQty: (json['orderQty'] as num).toDouble(),
      orderTemp: (json['orderTemp'] as List<dynamic>)
          .map((e) =>
              OrderTempObjectBoxStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OrderTempStructToJson(OrderTempStruct instance) =>
    <String, dynamic>{
      'orderQty': instance.orderQty,
      'orderTemp': instance.orderTemp.map((e) => e.toJson()).toList(),
    };

OrderTempObjectBoxStruct _$OrderTempObjectBoxStructFromJson(
        Map<String, dynamic> json) =>
    OrderTempObjectBoxStruct(
      id: (json['id'] as num).toInt(),
      orderId: json['orderId'] as String,
      orderIdMain: json['orderIdMain'] as String,
      orderGuid: json['orderGuid'] as String,
      machineId: json['machineId'] as String,
      orderDateTime: DateTime.parse(json['orderDateTime'] as String),
      barcode: json['barcode'] as String,
      qty: (json['qty'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      isOrder: json['isOrder'] as bool,
      isPaySuccess: json['isPaySuccess'] as bool,
      optionSelected: json['optionSelected'] as String,
      remark: json['remark'] as String,
      names: json['names'] as String,
      takeAway: json['takeAway'] as bool,
      unitCode: json['unitCode'] as String,
      unitName: json['unitName'] as String,
      imageUri: json['imageUri'] as String,
      kdsSuccessTime: DateTime.parse(json['kdsSuccessTime'] as String),
      kdsSuccess: json['kdsSuccess'] as bool,
      isOrderSuccess: json['isOrderSuccess'] as bool,
      isOrderSendKdsSuccess: json['isOrderSendKdsSuccess'] as bool,
      kdsId: json['kdsId'] as String,
      cancelQty: (json['cancelQty'] as num).toDouble(),
      orderQty: (json['orderQty'] as num).toDouble(),
      deliveryNumber: json['deliveryNumber'] as String,
      deliveryCode: json['deliveryCode'] as String,
      isOrderReadySendKds: json['isOrderReadySendKds'] as bool,
      deliveryName: json['deliveryName'] as String,
      lastUpdateDateTime: DateTime.parse(json['lastUpdateDateTime'] as String),
    );

Map<String, dynamic> _$OrderTempObjectBoxStructToJson(
        OrderTempObjectBoxStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'orderGuid': instance.orderGuid,
      'orderIdMain': instance.orderIdMain,
      'machineId': instance.machineId,
      'orderDateTime': instance.orderDateTime.toIso8601String(),
      'barcode': instance.barcode,
      'orderQty': instance.orderQty,
      'qty': instance.qty,
      'cancelQty': instance.cancelQty,
      'price': instance.price,
      'amount': instance.amount,
      'isOrder': instance.isOrder,
      'isOrderSuccess': instance.isOrderSuccess,
      'isOrderSendKdsSuccess': instance.isOrderSendKdsSuccess,
      'isOrderReadySendKds': instance.isOrderReadySendKds,
      'isPaySuccess': instance.isPaySuccess,
      'optionSelected': instance.optionSelected,
      'remark': instance.remark,
      'names': instance.names,
      'unitCode': instance.unitCode,
      'unitName': instance.unitName,
      'imageUri': instance.imageUri,
      'takeAway': instance.takeAway,
      'kdsSuccessTime': instance.kdsSuccessTime.toIso8601String(),
      'kdsSuccess': instance.kdsSuccess,
      'kdsId': instance.kdsId,
      'deliveryNumber': instance.deliveryNumber,
      'deliveryCode': instance.deliveryCode,
      'deliveryName': instance.deliveryName,
      'lastUpdateDateTime': instance.lastUpdateDateTime.toIso8601String(),
    };
