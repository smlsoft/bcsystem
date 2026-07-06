import 'dart:convert';

import 'package:dedeorder/bloc/order_temp_bloc.dart';
import 'package:dedeorder/utility/api.dart' as api;
import 'package:animated_icon/animated_icon.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:dedeorder/model/order_temp_model.dart';
import 'package:dedeorder/model/product_model.dart';
import 'package:dedeorder/order/product_option_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetOrderSelectResultType {
  List<ProductProcessModel> orderSelected = [];
  double orderQty = 0.0;
  double orderAmount = 0.0;
}

GetOrderSelectResultType getOrderSelect(
    {required BuildContext context,
    required List<OrderTempObjectBoxStruct> orderTemp}) {
  GetOrderSelectResultType result = GetOrderSelectResultType();
  for (int index = 0; index < orderTemp.length; index++) {
    if (orderTemp[index].orderQty - orderTemp[index].cancelQty > 0) {
      ProductProcessModel product = ProductProcessModel(
        names: global.languageJsonDecode(orderTemp[index].names),
        unitcode: orderTemp[index].unitCode,
        unitname: orderTemp[index].unitName,
        orderguid: orderTemp[index].orderGuid,
        barcode: orderTemp[index].barcode,
        qty: orderTemp[index].orderQty - orderTemp[index].cancelQty,
        price: orderTemp[index].price,
        imageuri: orderTemp[index].imageUri,
        remark: orderTemp[index].remark,
        takeAway: orderTemp[index].takeAway,
        options: [],
        totalAmount: 0,
        refcategoryguid: "",
        code: "",
        isAlacarte: false,
        ordertypes: [],
        type: 0,
        sumOrderQty: 0,
      );
      result.orderQty += orderTemp[index].orderQty - orderTemp[index].cancelQty;
      result.orderAmount +=
          ((orderTemp[index].orderQty - orderTemp[index].cancelQty) *
              orderTemp[index].price);
      double sumChoiceAmount = 0;
      if (orderTemp[index].optionSelected.isNotEmpty) {
        var jsonList = jsonDecode(orderTemp[index].optionSelected);
        List<ProductProcessOptionModel> options = [];
        for (var json in jsonList) {
          ProductProcessOptionModel option =
              ProductProcessOptionModel.fromJson(json);
          options.add(option);
        }
        for (var option in options) {
          for (var choice in option.choices) {
            if (choice.selected == true) {
              result.orderAmount +=
                  (orderTemp[index].orderQty - orderTemp[index].cancelQty) *
                      choice.priceValue!;
              sumChoiceAmount +=
                  (orderTemp[index].orderQty - orderTemp[index].cancelQty) *
                      choice.priceValue!;
            }
          }
        }
        product.options = options;
      } else {
        product.options = [];
      }
      product.totalAmount = sumChoiceAmount +
          ((orderTemp[index].orderQty - orderTemp[index].cancelQty) *
              orderTemp[index].price);
      result.orderSelected.add(product);
    }
  }
  context.read<OrderTempBloc>().add(OrderTempGetDataFinish());
  return result;
}

Widget productPackOption(
    {required List<ProductProcessOptionModel> options, required double qty}) {
  List<Widget> result = [];
  for (int optionIndex = 0; optionIndex < options.length; optionIndex++) {
    bool isSelected = false;
    for (int choiceIndex = 0;
        choiceIndex < options[optionIndex].choices.length;
        choiceIndex++) {
      if (options[optionIndex].choices[choiceIndex].selected!) {
        isSelected = true;
        break;
      }
    }
    if (isSelected) {
      result.add(
        Text(
            global.getNameFromLanguage(
                options[optionIndex].names, global.currentLanguage),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
      for (int choiceIndex = 0;
          choiceIndex < options[optionIndex].choices.length;
          choiceIndex++) {
        String choiceName = global.getNameFromLanguage(
            options[optionIndex].choices[choiceIndex].names,
            global.currentLanguage);
        if (qty != 0) {
          choiceName += " x $qty";
        }
        if (options[optionIndex].choices[choiceIndex].selected!) {
          double amount =
              qty * options[optionIndex].choices[choiceIndex].priceValue!;
          result.add((amount == 0)
              ? Text(
                  choiceName,
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.clip,
                )
              : Row(
                  children: [
                    Expanded(
                        child: Text(
                      choiceName,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.clip,
                    )),
                    const Spacer(),
                    Text(global.moneyFormat.format(amount),
                        style: const TextStyle(fontSize: 10)),
                  ],
                ));
        }
      }
    }
  }
  return Container(
      padding: const EdgeInsets.only(left: 4, right: 4),
      width: double.infinity,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: result));
}

Widget orderSummery({
  required BuildContext context,
  required List<ProductProcessModel> orderSelected,
  required double orderAmount,
  required double orderQty,
  required Function refresh,
  required double widgetWidth,
}) {
  return Column(
    children: [
      Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.green.shade300,
                      border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.shade300, width: 1.0))),
                  child: Text("ทวนรายการที่กำลังสั่งให้ลูกค้าก่อนส่ง Order",
                      style: TextStyle(
                          fontSize: global.orderFontSize * 1.2,
                          fontWeight: FontWeight.bold))),
              Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.shade300, width: 1.0))),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text('รายการที่กำลังสั่ง',
                            style: TextStyle(
                                fontSize: global.orderFontSize,
                                fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'จำนวน',
                          style: TextStyle(
                              fontSize: global.orderFontSize,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'ราคา',
                          style: TextStyle(
                              fontSize: global.orderFontSize,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'รวม',
                          style: TextStyle(
                              fontSize: global.orderFontSize,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  )),
              for (ProductProcessModel order in orderSelected)
                Container(
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    width: double.infinity,
                    child: Column(children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: (order.takeAway == false)
                                ? Text(
                                    (order.remark.trim().isEmpty)
                                        ? global.getNameFromLanguage(
                                            order.names, global.userLanguage)
                                        : "${global.getNameFromLanguage(order.names, global.userLanguage)} (${order.remark})",
                                    style: TextStyle(
                                        fontSize: global.orderFontSize),
                                  )
                                : Row(children: [
                                    AnimateIcon(
                                      key: UniqueKey(),
                                      onTap: () {},
                                      iconType: IconType.continueAnimation,
                                      color: Colors.green,
                                      height: 15,
                                      width: 15,
                                      animateIcon: AnimateIcons.home,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      global.getNameFromLanguage(
                                          order.names, global.userLanguage),
                                      style: TextStyle(
                                          fontSize: global.orderFontSize),
                                    ),
                                  ]),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              global.moneyFormat.format(order.qty),
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: global.orderFontSize),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              global.moneyFormat.format(order.price),
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: global.orderFontSize),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              global.moneyFormat
                                  .format(order.qty * order.price),
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: global.orderFontSize),
                            ),
                          ),
                        ],
                      ),
                      if (order.options.isNotEmpty)
                        for (var option in order.options)
                          for (var choice in option.choices)
                            if (choice.selected == true)
                              Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 10),
                                        child: Text(
                                          "${global.getNameFromLanguage(option.names, global.currentLanguage)} > ${global.getNameFromLanguage(choice.names, global.currentLanguage)}",
                                          style: TextStyle(
                                              fontSize:
                                                  global.orderFontSize * 0.8),
                                        )),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: (choice.priceValue! == 0)
                                        ? Container()
                                        : Text(
                                            global.moneyFormat
                                                .format(order.qty),
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                                fontSize:
                                                    global.orderFontSize * 0.8),
                                          ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: (choice.priceValue! == 0)
                                        ? Container()
                                        : Text(
                                            global.moneyFormat
                                                .format(choice.priceValue!),
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                                fontSize:
                                                    global.orderFontSize * 0.8),
                                          ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: (choice.priceValue! == 0)
                                        ? Container()
                                        : Text(
                                            "+${global.moneyFormat.format(order.qty * choice.priceValue!)}",
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                                fontSize:
                                                    global.orderFontSize * 0.8),
                                          ),
                                  ),
                                ],
                              )
                    ])),
              Container(
                  padding: const EdgeInsets.only(left: 4, right: 4),
                  decoration: BoxDecoration(
                      color: Colors.green.shade200,
                      border: Border(
                          top: BorderSide(
                              color: Colors.grey.shade300, width: 1.0),
                          bottom: BorderSide(
                              color: Colors.grey.shade300, width: 1.0))),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text('รวมเงินรายการที่กำลังสั่ง',
                            style: TextStyle(
                                fontSize: global.orderFontSize,
                                fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          global.moneyFormat.format(orderQty),
                          style: TextStyle(
                              fontSize: global.orderFontSize,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          global.moneyFormat.format(orderAmount),
                          style: TextStyle(
                              fontSize: global.orderFontSize,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  )),
            ],
          )),
      Wrap(children: [
        for (ProductProcessModel product in orderSelected)
          Container(
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              width: (widgetWidth == 0) ? 110 : widgetWidth,
              child: Column(
                children: [
                  (product.imageuri.isEmpty)
                      ? Image.asset('assets/noimage.png')
                      : Image.network(
                          product.imageuri,
                          fit: BoxFit.cover,
                        ),
                  if (product.remark.trim().isNotEmpty)
                    Text(product.remark, style: const TextStyle(fontSize: 12)),
                  productPackOption(qty: product.qty, options: product.options),
                  Container(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: Column(children: [
                        if (product.takeAway)
                          AnimateIcon(
                            key: UniqueKey(),
                            onTap: () {},
                            iconType: IconType.continueAnimation,
                            color: Colors.green,
                            height: 15,
                            width: 15,
                            animateIcon: AnimateIcons.home,
                          ),
                        Text(
                            "${global.getNameFromLanguage(product.names, global.currentLanguage)} x ${global.moneyFormat.format(product.qty)}",
                            style: TextStyle(
                                fontSize: global.orderFontSize,
                                fontWeight: FontWeight.bold)),
                        Text(
                            "ราคา : ${global.moneyFormat.format(product.price)} บาท",
                            style: TextStyle(
                              fontSize: global.orderFontSize,
                            )),
                        Text(
                            "รวม : ${global.moneyFormat.format(product.totalAmount)} บาท",
                            style: TextStyle(
                                fontSize: global.orderFontSize,
                                fontWeight: FontWeight.bold))
                      ])),
                  Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit),
                          color: Colors.blue,
                          onPressed: () async {
                            var result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ProductOptionPage(
                                        product: product,
                                        remark: product.remark,
                                        qty: product.qty,
                                        takeAway: product.takeAway)));
                            if (result != null) {
                              double qty = result['qty'];
                              bool confirm = result['flag'];
                              String remark = result['remark'];
                              bool takeAway = result['takeAway'];
                              List<ProductProcessOptionModel> optionSelected =
                                  result['options'];
                              if (confirm) {
                                OrderTempObjectBoxStruct? order = await api
                                    .getOrderTempByOrderGuidFromTerminal(
                                        product.orderguid);
                                if (order != null) {
                                  OrderTempObjectBoxStruct newOrder =
                                      OrderTempObjectBoxStruct(
                                          id: order.id,
                                          orderId: order.orderId,
                                          orderIdMain: order.orderIdMain,
                                          docNo: order.docNo,
                                          orderGuid: order.orderGuid,
                                          orderDateTime: order.orderDateTime,
                                          barcode: order.barcode,
                                          isOrder: order.isOrder,
                                          isPaySuccess: order.isPaySuccess,
                                          isOrderSendKdsSuccess:
                                              order.isOrderSendKdsSuccess,
                                          isOrderSuccess: order.isOrderSuccess,
                                          lastUpdateDateTime:
                                              order.lastUpdateDateTime,
                                          qtyLastCancel: order.qtyLastCancel,
                                          optionSelected:
                                              jsonEncode(optionSelected),
                                          remark: remark,
                                          remarkForCancel: "",
                                          price: order.price,
                                          amount: order.amount,
                                          names: order.names,
                                          unitCode: order.unitCode,
                                          unitName: order.unitName,
                                          imageUri: order.imageUri,
                                          kdsId: order.kdsId,
                                          kdsSuccess: order.kdsSuccess,
                                          kdsSuccessTime: order.kdsSuccessTime,
                                          takeAway: takeAway,
                                          deliveryCode: order.deliveryCode,
                                          deliveryName: order.deliveryName,
                                          deliveryNumber: order.deliveryNumber,
                                          cancelQty: order.cancelQty,
                                          cancelHistory: order.cancelHistory,
                                          orderHistory: order.orderHistory,
                                          orderQty: qty,
                                          isOrderReadySendKds:
                                              order.isOrderReadySendKds,
                                          servedSuccess: order.servedSuccess,
                                          servedTime: order.servedTime,
                                          servedQty: order.servedQty,
                                          servedHistory: order.servedHistory,
                                          orderType: order.orderType,
                                          orderEmployeeCode:
                                              order.orderEmployeeCode,
                                          orderEmployeeDetail:
                                              order.orderEmployeeDetail,
                                          isOrderSendDedeTempSuccess:
                                              order.isOrderSendDedeTempSuccess,
                                          machineId: order.machineId);
                                  await api.orderTempUpdateToTerminal(newOrder);
                                  refresh();
                                }
                              }
                            }
                            refresh();
                          }),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                    title: const Text("ลบรายการที่เลือก"),
                                    content: Text(
                                        "ต้องการลบ${global.getNameFromLanguage(product.names, global.userLanguage)} จำนวน ${global.moneyFormat.format(product.qty)} ${global.getNameFromJsonLanguage(product.unitname, global.userLanguage)} หรือไม่?",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        )),
                                    actions: [
                                      TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text("ยกเลิก")),
                                      TextButton(
                                          onPressed: () async {
                                            String orderId = (global
                                                    .selectTableNumber.isEmpty)
                                                ? global.phoneNumber
                                                : global.selectTableNumber;
                                            await api
                                                .orderTempDeleteByOrderGuid(
                                                    orderId, product.orderguid);
                                            if (context.mounted) {
                                              Navigator.of(context).pop();
                                            }
                                            refresh();
                                          },
                                          child: const Text("ลบ")),
                                    ]);
                              });
                        },
                      )
                    ],
                  )
                ],
              ))
      ]),
    ],
  );
}
