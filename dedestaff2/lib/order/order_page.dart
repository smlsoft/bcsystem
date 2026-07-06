import 'package:dedeorder/order/order_utils.dart' as util;
import 'dart:convert';
import 'dart:ui';
import 'package:animated_icon/animated_icon.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedeorder/bloc/order_temp_bloc.dart';
import 'package:dedeorder/order/cart_page.dart';
import 'package:dedeorder/model/category_model.dart';
import 'package:dedeorder/model/order_temp_model.dart';
import 'package:dedeorder/model/product_model.dart';
import 'package:dedeorder/model/table_model.dart';
import 'package:dedeorder/order/product_option_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:dedeorder/utility/api.dart' as api;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  int categoryIndex = 0;
  double sumOrderQty = 0;
  double orderQty = 0.0;
  double orderAmount = 0.0;

  /// False=รับประทานที่ร้าน,True=สั่งกลับบ้าน
  bool currentOrderTakeAway = false;

  @override
  void initState() {
    super.initState();
    global.loadCategoryData();
    refresh();
  }

  Future<void> refresh() async {
    global.productBarcodeStatusLists =
        await api.getProductBarcodeStatusFromTerminal();
    if (mounted) {
      context.read<OrderTempBloc>().add(OrderTempGetData(
          orderId: global.selectTableNumber,
          isOrder: true,
          machineId: global.machineId));
      context.read<OrderTempBloc>().add(OrderTempLoadStart(
          orderId: global.selectTableNumber,
          barcode: "",
          isOrder: true,
          machineId: global.machineId));
    }
  }

  Widget categoryListWidget(orientation) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Container(
          color: Colors.white,
          width: double.infinity,
          height: orientation == Orientation.landscape ? 100 : 130,
          child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  for (var category in global.orderPageCloneCategoryLists)
                    Card(
                        color: Colors.yellowAccent.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: orientation == Orientation.landscape
                                ? (constraints.maxWidth ~/ 7).toDouble()
                                : (constraints.maxWidth / 3.5).toDouble(),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(0),
                              onTap: () {
                                setState(() {
                                  categoryIndex = global
                                      .orderPageCloneCategoryLists
                                      .indexOf(category);
                                });
                              },
                              child: Column(children: [
                                Expanded(
                                    child: Ink.image(
                                  fit: BoxFit.fill,
                                  image: (category.imageuri.isEmpty)
                                      ? Image.asset("assets/noimage.png").image
                                      : NetworkImage(
                                          category.imageuri,
                                        ),
                                )),
                                Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      maxLines: 2,
                                      global.getNameFromLanguage(
                                          category.names, global.userLanguage),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                              ]),
                            ),
                          ),
                        )),
                ],
              )));
    });
  }

  Future<void> orderError() async {
    // ผิดพลาด ให้แจ้งเตือน
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text("เกิดข้อผิดพลาด"),
              content: const Text("ไม่สามารถทำรายการได้ กรุณาลองใหม่อีกครั้ง"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("ปิด")),
              ]);
        });
  }

  Future<void> stockBalanceError(ProductProcessModel product) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: const Text("สินค้าไม่พอ"),
              content: Text(global.getNameFromLanguage(
                  product.names, global.userLanguage)),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("ยกเลิก")),
              ],
            ));
  }

  Widget productWidget(
      ProductProcessModel product, bool newOrder, double width) {
    int findProductStatusIndex = global.productBarcodeStatusLists
        .indexWhere((element) => element.barcode == product.barcode);
    bool isCancel = (findProductStatusIndex != -1 &&
        global.productBarcodeStatusLists[findProductStatusIndex].orderDisable);
    bool outOfStock = (findProductStatusIndex != -1 &&
        (global.productBarcodeStatusLists[findProductStatusIndex]
                    .orderAutoStock &&
                global.productBarcodeStatusLists[findProductStatusIndex]
                        .qtyBalance <=
                    0 ||
            global.productBarcodeStatusLists[findProductStatusIndex]
                    .orderStatus ==
                1));

    return Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 7,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Column(children: [
          if (isCancel)
            Container(
                padding: const EdgeInsets.all(4),
                color: Colors.grey.withOpacity(0.5),
                width: double.infinity,
                child: const FittedBox(
                    child: Text("เลิกขาย",
                        style: TextStyle(
                            shadows: [
                              Shadow(
                                blurRadius: 5.0,
                                color: Colors.white,
                                offset: Offset(0, 0),
                              ),
                            ],
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)))),
          if (outOfStock)
            Container(
                padding: const EdgeInsets.all(4),
                color: Colors.grey.withOpacity(0.5),
                width: double.infinity,
                child: const Center(
                    child: Text("หมด",
                        style: TextStyle(
                            shadows: [
                              Shadow(
                                blurRadius: 5.0,
                                color: Colors.white,
                                offset: Offset(0, 0),
                              ),
                            ],
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)))),
          InkWell(
            onTap: () async {
              if (isCancel || outOfStock) {
                return;
              }
              if (newOrder) {
                if (product.type == 0) {
                  String orderId = (global.selectTableNumber.isEmpty)
                      ? global.phoneNumber
                      : global.selectTableNumber;
                  // clear option
                  for (var option in product.options) {
                    for (var choice in option.choices) {
                      choice.selected = false;
                    }
                  }
                  //
                  OrderTempObjectBoxStruct data = OrderTempObjectBoxStruct(
                      id: 0,
                      orderId: orderId,
                      orderIdMain: global.selectTableMainNumber,
                      orderGuid: const Uuid().v4(),
                      orderDateTime: DateTime.now(),
                      docNo: "",
                      barcode: product.barcode,
                      isOrder: true,
                      isOrderSendKdsSuccess: false,
                      isOrderSuccess: false,
                      isPaySuccess: false,
                      lastUpdateDateTime: DateTime.now(),
                      qtyLastCancel: 0,
                      orderQty: 1,
                      optionSelected: product.options.isNotEmpty
                          ? jsonEncode(
                              product.options.map((e) => e.toJson()).toList())
                          : "",
                      remark: "",
                      remarkForCancel: "",
                      price: product.price,
                      amount: product.price,
                      names: jsonEncode(product.names),
                      unitCode: product.unitcode,
                      unitName: product.unitname,
                      imageUri: product.imageuri,
                      kdsSuccess: false,
                      isOrderReadySendKds:
                          global.selectTable.make_food_immediately,
                      kdsId: "",
                      cancelQty: 0,
                      cancelHistory: "",
                      orderHistory: "",
                      takeAway: currentOrderTakeAway,
                      deliveryCode: global.selectTable.delivery_code,
                      deliveryName: global.getDeliveryName(
                          code: global.selectTable.delivery_code),
                      deliveryNumber: global.selectTable.delivery_number,
                      kdsSuccessTime: DateTime.now(),
                      orderType: 0,
                      orderEmployeeCode: global.staffCode,
                      orderEmployeeDetail: global.staffName,
                      servedSuccess: false,
                      servedQty: 0,
                      servedHistory: "",
                      isOrderSendDedeTempSuccess: false,
                      servedTime: DateTime.now(),
                      machineId: global.machineId);
                  var result = await api.orderTempInsertToTerminal(data);
                  if (result == 1) {
                    await stockBalanceError(product);
                  } else if (result == 999) {
                    await orderError();
                  }
                  refresh();
                } else {
                  for (int index = 0;
                      index < global.orderPageCloneCategoryLists.length;
                      index++) {
                    if (global.orderPageCloneCategoryLists[index].guidfixed ==
                        product.refcategoryguid) {
                      categoryIndex = index;
                      break;
                    }
                  }
                }
                setState(() {});
              }
            },
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, top: 4),
                  child: Text(
                    maxLines: 2,
                    global.getNameFromLanguage(
                        product.names, global.userLanguage),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: global.orderFontSize,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
              (product.type == 0)
                  ? Padding(
                      padding:
                          const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            maxLines: 2,
                            global.getNameFromJsonLanguage(
                                product.unitname, global.currentLanguage),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: global.orderFontSize / 1.25,
                              height: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            maxLines: 2,
                            global.moneyFormat.format(product.price),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: global.orderFontSize / 1.25,
                              height: 1.2,
                            ),
                          )
                        ],
                      ))
                  : Container(),
              if (findProductStatusIndex != -1 &&
                  global.productBarcodeStatusLists[findProductStatusIndex]
                      .orderAutoStock)
                Text(
                  "เหลือ ${global.moneyFormat.format(global.productBarcodeStatusLists[findProductStatusIndex].qtyBalance)} ${global.getNameFromJsonLanguage(product.unitname, global.currentLanguage)}",
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                ),
              if (global.orderShowImage)
                Padding(
                    padding: const EdgeInsets.all(2),
                    child: (product.imageuri.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: product.imageuri,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          )
                        : Image.asset(
                            "assets/images/food.webp",
                            height: 80,
                          )),
            ]),
          ),
          if (product.options.isNotEmpty)
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0.0),
                      ),
                    ),
                    onPressed: () async {
                      if (isCancel || outOfStock) {
                        return;
                      }
                      String orderId = (global.selectTableNumber.isEmpty)
                          ? global.phoneNumber
                          : global.selectTableNumber;
                      for (var option in product.options) {
                        for (var choice in option.choices) {
                          choice.selected = false;
                        }
                      }
                      var result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProductOptionPage(
                                  product: product,
                                  qty: 1,
                                  remark: "",
                                  takeAway: currentOrderTakeAway,
                                )),
                      );
                      if (result != null) {
                        double qty = result['qty'];
                        bool confirm = result['flag'];
                        String remark = result['remark'];
                        if (confirm) {
                          var json = jsonEncode(
                              product.options.map((e) => e.toJson()).toList());
                          String orderGuid = const Uuid().v4();
                          OrderTempObjectBoxStruct data =
                              OrderTempObjectBoxStruct(
                                  id: 0,
                                  orderId: orderId,
                                  orderIdMain: global.selectTableMainNumber,
                                  orderGuid: orderGuid,
                                  docNo: "",
                                  orderDateTime: DateTime.now(),
                                  barcode: product.barcode,
                                  isOrder: true,
                                  isOrderSendKdsSuccess: false,
                                  isOrderSuccess: false,
                                  isPaySuccess: false,
                                  lastUpdateDateTime: DateTime.now(),
                                  qtyLastCancel: 0,
                                  orderQty: qty,
                                  optionSelected: json,
                                  remark: remark,
                                  remarkForCancel: "",
                                  price: product.price,
                                  amount: product.price * qty,
                                  names: jsonEncode(product.names),
                                  unitCode: product.unitcode,
                                  unitName: product.unitname,
                                  imageUri: product.imageuri,
                                  takeAway: currentOrderTakeAway,
                                  isOrderReadySendKds:
                                      global.selectTable.make_food_immediately,
                                  kdsSuccess: false,
                                  kdsId: "",
                                  deliveryCode:
                                      global.selectTable.delivery_code,
                                  deliveryName: global.getDeliveryName(
                                      code: global.selectTable.delivery_code),
                                  deliveryNumber:
                                      global.selectTable.delivery_number,
                                  kdsSuccessTime: DateTime.now(),
                                  orderType: 0,
                                  orderEmployeeCode: global.staffCode,
                                  orderEmployeeDetail: global.staffName,
                                  cancelQty: 0,
                                  cancelHistory: "",
                                  orderHistory: "",
                                  servedSuccess: false,
                                  servedQty: 0,
                                  servedHistory: "",
                                  isOrderSendDedeTempSuccess: false,
                                  servedTime: DateTime.now(),
                                  machineId: global.machineId);
                          int result =
                              await api.orderTempInsertToTerminal(data);
                          if (result == 1) {
                            await stockBalanceError(product);
                          } else if (result == 999) {
                            await orderError();
                          }
                          refresh();
                        }
                      }
                    },
                    child: const Text("มีเงื่อนไข"))),
          if (product.qty != 0)
            Container(
                width: double.infinity,
                color: Colors.blue.shade100,
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                          "${global.moneyFormat.format(product.qty)} ${global.getNameFromJsonLanguage(product.unitname, global.currentLanguage)}",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 5.0,
                                  color: Colors.grey,
                                  offset: Offset(2.0, 2.0),
                                ),
                              ]))),
                  Row(
                    children: [
                      IconButton(
                          onPressed: () async {
                            List<OrderTempObjectBoxStruct>? getOrder = await api
                                .getOrderTempByOrderIdAndBarcodeFromTerminal(
                                    orderId: global.selectTableNumber,
                                    barcode: product.barcode,
                                    isOrder: true,
                                    machineId: global.machineId);
                            if (getOrder?.length == 1) {
                              OrderTempObjectBoxStruct order = getOrder![0];
                              if (mounted) {
                                var result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ProductOptionPage(
                                            product: product,
                                            remark: order.remark,
                                            takeAway: order.takeAway,
                                            qty: order.orderQty -
                                                order.cancelQty)));
                                if (result != null) {
                                  double qty = result['qty'];
                                  bool confirm = result['flag'];
                                  String remark = result['remark'];
                                  List<ProductProcessOptionModel> options =
                                      result['options'];
                                  var optionSelected = jsonEncode(
                                      options.map((e) => e.toJson()).toList());

                                  if (confirm) {
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
                                            isOrderSuccess:
                                                order.isOrderSuccess,
                                            lastUpdateDateTime: DateTime.now(),
                                            qtyLastCancel: order.qtyLastCancel,
                                            orderQty: qty,
                                            cancelQty: order.cancelQty,
                                            cancelHistory: order.cancelHistory,
                                            optionSelected: optionSelected,
                                            remark: remark,
                                            remarkForCancel: "",
                                            price: order.price,
                                            amount: order.amount,
                                            names: order.names,
                                            unitCode: order.unitCode,
                                            unitName: order.unitName,
                                            imageUri: order.imageUri,
                                            kdsId: order.kdsId,
                                            takeAway: order.takeAway,
                                            isOrderReadySendKds:
                                                order.isOrderReadySendKds,
                                            kdsSuccess: order.kdsSuccess,
                                            kdsSuccessTime:
                                                order.kdsSuccessTime,
                                            deliveryCode: order.deliveryCode,
                                            deliveryName: order.deliveryName,
                                            deliveryNumber:
                                                order.deliveryNumber,
                                            servedSuccess: order.servedSuccess,
                                            servedTime: order.servedTime,
                                            servedQty: order.servedQty,
                                            servedHistory: order.servedHistory,
                                            orderHistory: order.orderHistory,
                                            orderType: order.orderType,
                                            orderEmployeeCode:
                                                order.orderEmployeeCode,
                                            orderEmployeeDetail:
                                                order.orderEmployeeDetail,
                                            machineId: order.machineId,
                                            isOrderSendDedeTempSuccess: order
                                                .isOrderSendDedeTempSuccess);
                                    int result = await api
                                        .orderTempUpdateToTerminal(newOrder);
                                    if (result == 1) {
                                      await stockBalanceError(product);
                                    }
                                    refresh();
                                  }
                                }
                              }
                            } else {
                              if (mounted) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CartPage(
                                          orderId: global.selectTableNumber,
                                          barcode: product.barcode)),
                                );
                                refresh();
                              }
                            }
                          },
                          icon: const Icon(Icons.edit)),
                      const Spacer(),
                      IconButton(
                        onPressed: () async {
                          await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                    title: const Text("ลบรายการที่เลือก"),
                                    content: Text(
                                        "ต้องการลบ${global.getNameFromLanguage(product.names, global.currentLanguage)} จำนวน ${global.moneyFormat.format(product.qty)} ${global.getNameFromJsonLanguage(product.unitname, global.currentLanguage)} หรือไม่?",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        )),
                                    actions: [
                                      TextButton(
                                          onPressed: () async {
                                            await api.orderTempDeleteByBarcode(
                                                global.selectTableNumber,
                                                product.barcode);
                                            if (mounted) {
                                              Navigator.pop(context);
                                            }
                                            refresh();
                                          },
                                          child: const Text("ลบ")),
                                    ]);
                              });
                        },
                        icon: const Icon(Icons.delete),
                      )
                    ],
                  )
                ])),
        ]));
    /*return Card(
        margin: const EdgeInsets.all(2),
        color: (product.type == 0) ? Colors.white : Colors.yellow[100],
        child: ClipRRect(
          child: InkWell(
            borderRadius: BorderRadius.circular(0),
            onTap: () async {
              if (newOrder) {
                if (product.type == 0) {
                  String orderId = (global.selectTableNumber.isEmpty) ? global.phoneNumber : global.selectTableNumber;
                  if (product.options.isNotEmpty) {
                    for (var option in product.options) {
                      for (var choice in option.choices) {
                        choice.selected = false;
                      }
                    }
                    var result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProductOptionPage(
                                product: product,
                                qty: 1,
                                remark: "",
                                takeAway: currentOrderTakeAway,
                              )),
                    );
                    if (result != null) {
                      double qty = result['qty'];
                      bool confirm = result['flag'];
                      String remark = result['remark'];
                      if (confirm) {
                        var json = jsonEncode(product.options.map((e) => e.toJson()).toList());
                        String orderGuid = const Uuid().v4();
                        OrderTempObjectBoxStruct data = OrderTempObjectBoxStruct(id: 0, orderId: orderId, orderIdMain: global.selectTableMainNumber, orderGuid: orderGuid, orderDateTime: DateTime.now(), barcode: product.barcode, isOrder: true, isOrderSendKdsSuccess: false, isOrderSuccess: false, isPaySuccess: false, lastUpdateDateTime: DateTime.now(), qty: qty, orderQty: qty, optionSelected: json, remark: remark, price: product.price, amount: product.price * qty, names: jsonEncode(product.names), unitCode: product.unitcode, unitName: product.unitname, imageUri: product.imageuri, takeAway: currentOrderTakeAway, isOrderReadySendKds: global.selectTable.make_food_immediately, kdsSuccess: false, kdsId: "", deliveryCode: global.selectTable.delivery_code, deliveryName: global.getDeliveryName(code: global.selectTable.delivery_code), deliveryNumber: global.selectTable.delivery_number, kdsSuccessTime: DateTime.now(), cancelQty: 0, machineId: global.machineId);
                        int result = await api.orderTempInsertToTerminal(data);
                        if (result == 1) {
                          await stockBalanceError(product);
                        }
                        refresh();
                      }
                    }
                  } else {
                    OrderTempObjectBoxStruct data = OrderTempObjectBoxStruct(id: 0, orderId: orderId, orderIdMain: global.selectTableMainNumber, orderGuid: const Uuid().v4(), orderDateTime: DateTime.now(), barcode: product.barcode, isOrder: true, isOrderSendKdsSuccess: false, isOrderSuccess: false, isPaySuccess: false, lastUpdateDateTime: DateTime.now(), qty: 1, orderQty: 1, optionSelected: "", remark: "", price: product.price, amount: product.price, names: jsonEncode(product.names), unitCode: product.unitcode, unitName: product.unitname, imageUri: product.imageuri, kdsSuccess: false, isOrderReadySendKds: global.selectTable.make_food_immediately, kdsId: "", cancelQty: 0, takeAway: currentOrderTakeAway, deliveryCode: global.selectTable.delivery_code, deliveryName: global.getDeliveryName(code: global.selectTable.delivery_code), deliveryNumber: global.selectTable.delivery_number, kdsSuccessTime: DateTime.now(), machineId: global.machineId);
                    await api.orderTempInsertToTerminal(data);
                    refresh();
                  }
                } else {
                  for (int index = 0; index < cloneCategoryLists.length; index++) {
                    if (cloneCategoryLists[index].guidfixed == product.refcategoryguid) {
                      categoryIndex = index;
                      break;
                    }
                  }
                }
                setState(() {});
              }
            },
            child: Column(children: [
              if (product.qty != 0)
                Container(
                    width: double.infinity,
                    color: Colors.blue.shade100,
                    child: Row(
                      children: [
                        IconButton(
                            onPressed: () async {
                              List<OrderTempObjectBoxStruct>? getOrder = await api.getOrderTempByOrderIdAndBarcodeFromTerminal(orderId: global.selectTableNumber, barcode: product.barcode, isOrder: true);
                              if (getOrder?.length == 1) {
                                OrderTempObjectBoxStruct order = getOrder![0];
                                if (mounted) {
                                  var result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ProductOptionPage(product: product, remark: order.remark, takeAway: order.takeAway, qty: order.qty)));
                                  if (result != null) {
                                    double qty = result['qty'];
                                    bool confirm = result['flag'];
                                    String remark = result['remark'];
                                    if (confirm) {
                                      OrderTempObjectBoxStruct newOrder = OrderTempObjectBoxStruct(id: order.id, orderId: order.orderId, orderIdMain: order.orderIdMain, orderGuid: order.orderGuid, orderDateTime: order.orderDateTime, barcode: order.barcode, isOrder: order.isOrder, isPaySuccess: order.isPaySuccess, isOrderSendKdsSuccess: order.isOrderSendKdsSuccess, isOrderSuccess: order.isOrderSuccess, lastUpdateDateTime: DateTime.now(), qty: qty, orderQty: qty, cancelQty: order.cancelQty, optionSelected: order.optionSelected, remark: remark, price: order.price, amount: order.amount, names: order.names, unitCode: order.unitCode, unitName: order.unitName, imageUri: order.imageUri, kdsId: order.kdsId, takeAway: order.takeAway, isOrderReadySendKds: order.isOrderReadySendKds, kdsSuccess: order.kdsSuccess, kdsSuccessTime: order.kdsSuccessTime, deliveryCode: order.deliveryCode, deliveryName: order.deliveryName, deliveryNumber: order.deliveryNumber, machineId: order.machineId);
                                      int result = await api.orderTempUpdateToTerminal(newOrder);
                                      if (result == 1) {
                                        await stockBalanceError(product);
                                      }
                                      refresh();
                                    }
                                  }
                                }
                              } else {
                                if (mounted) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => CartPage(orderId: global.selectTableNumber, barcode: product.barcode)),
                                  );
                                  refresh();
                                }
                              }
                            },
                            icon: const Icon(Icons.edit)),
                        const Spacer(),
                        Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(global.moneyFormat.format(product.qty),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, shadows: [
                                  Shadow(
                                    blurRadius: 5.0,
                                    color: Colors.grey,
                                    offset: Offset(2.0, 2.0),
                                  ),
                                ]))),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                      title: const Text("ลบรายการที่เลือก"),
                                      content: Text("ต้องการลบ${global.getNameFromLanguage(product.names, global.currentLanguage)} จำนวน ${global.moneyFormat.format(product.qty)} ${global.getNameFromJsonLanguage(product.unitname, global.currentLanguage)} หรือไม่?",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      actions: [
                                        TextButton(
                                            onPressed: () async {
                                              await api.orderTempDeleteByBarcode(global.selectTableNumber, product.barcode);
                                              if (mounted) {
                                                Navigator.pop(context);
                                              }
                                              refresh();
                                            },
                                            child: const Text("ลบ")),
                                      ]);
                                });
                          },
                          icon: const Icon(Icons.delete),
                        )
                      ],
                    )),
              if (global.orderShowImage)
                Expanded(
                    child: Ink.image(
                  fit: BoxFit.cover,
                  image: (product.imageuri.isEmpty) ? Image.asset("assets/noimage.png").image : NetworkImage(product.imageuri),
                )),
              Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, top: 4),
                  child: Text(
                    maxLines: 2,
                    global.getNameFromLanguage(product.names, global.userLanguage),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: global.orderFontSize,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
              (product.type == 0)
                  ? Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            maxLines: 2,
                            global.getNameFromJsonLanguage(product.unitname, global.currentLanguage),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: global.orderFontSize / 1.25,
                              height: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            maxLines: 2,
                            "${global.moneyFormat.format(product.price)} บาท",
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: global.orderFontSize / 1.25,
                              height: 1.2,
                            ),
                          )
                        ],
                      ))
                  : Container(),
              if (findProductStatusIndex != -1 && global.productBarcodeStatusLists[findProductStatusIndex].orderAutoStock)
                Text(
                  "เหลือ ${global.moneyFormat.format(global.productBarcodeStatusLists[findProductStatusIndex].qtyBalance)} ${global.getNameFromJsonLanguage(product.unitname, global.currentLanguage)}",
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                )
            ]),
          ),
        ));*/
  }

  Widget productListWidget({required bool showCategory}) {
    double spacing = 4;
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      try {
        double maxWidth = constraints.maxWidth;
        int calcCount = (maxWidth / 120).floor();
        double widthProduct = (maxWidth - (calcCount * spacing)) / calcCount;

        List<ProductProcessModel> categoryProducts = [];
        for (ProductProcessModel product
            in global.orderPageCloneCategoryLists[categoryIndex].products) {
          int index = global.findProductByBarcode(product.barcode);
          if (index != -1) {
            categoryProducts.add(global.productLists[index]);
          }
        }
        // sort by sum_order_qty
        categoryProducts.sort((a, b) => b.sumOrderQty.compareTo(a.sumOrderQty));
        List<Widget> products = [];
        for (ProductProcessModel product in categoryProducts) {
          int index = global.findProductByBarcode(product.barcode);
          if (index != -1) {
            products.add(
                productWidget(global.productLists[index], true, widthProduct));
          }
        }
        return SingleChildScrollView(
            child: Column(
          children: [
            (showCategory)
                ? Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 0),
                    child: Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        children: global.orderPageCloneCategoryLists
                            .map((e) => ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.only(
                                        left: 2, right: 2, top: 0, bottom: 0),
                                    foregroundColor: Colors.black,
                                    backgroundColor: (global
                                                .orderPageCloneCategoryLists
                                                .indexOf(e) ==
                                            categoryIndex)
                                        ? Colors.green.shade300
                                        : Colors.cyan.shade200,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      categoryIndex = global
                                          .orderPageCloneCategoryLists
                                          .indexOf(e);
                                    });
                                  },
                                  child: Text(
                                      global.getNameFromLanguage(
                                          e.names, global.userLanguage),
                                      style: TextStyle(
                                          fontSize: global.orderFontSize,
                                          fontWeight: FontWeight.bold)),
                                ))
                            .toList()))
                : Container(),
            const SizedBox(
              height: 4,
            ),
            Container(
                decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    border: const Border(
                      top: BorderSide(width: 1.0, color: Colors.grey),
                      bottom: BorderSide(width: 1.0, color: Colors.grey),
                    )),
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                child: Text(
                    global.getNameFromLanguage(
                        global.orderPageCloneCategoryLists[categoryIndex].names,
                        global.userLanguage),
                    style: TextStyle(
                        fontSize: global.orderFontSize * 1.5,
                        fontWeight: FontWeight.bold))),
            const SizedBox(
              height: 4,
            ),
            Wrap(
                alignment: WrapAlignment.start,
                spacing: spacing,
                runSpacing: spacing,
                children: products),
            util.orderSummery(
                context: context,
                orderSelected: global.orderPageOrderSelected,
                orderAmount: orderAmount,
                orderQty: orderQty,
                widgetWidth: widthProduct,
                refresh: refresh)
          ],
        ));
      } catch (e, s) {
        global.sendErrorToDevTeam("productListWidget(): $e $s");
        return Container();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String tableInfo = "โต๊ : ";

    if (global.selectTableNumber.isNotEmpty) {
      tableInfo = tableInfo + global.selectTableNumber;
    }
    if (global.selectTable.is_delivery) {
      tableInfo =
          "Delivery : ${global.getDeliveryName(code: global.selectTable.delivery_code)} : ${global.selectTable.delivery_number}";
      currentOrderTakeAway = true;
    }
    if (global.selectTable.buffet_code.isNotEmpty) {
      tableInfo = "$tableInfo บุฟเฟต์ : ${global.selectTable.buffet_code}";
    }

    return OrientationBuilder(builder: (context, orientation) {
      return BlocListener<OrderTempBloc, OrderTempState>(
          listener: (context, state) {
            if (state is OrderTempLoadSuccess) {
              var result = util.getOrderSelect(
                  context: context, orderTemp: state.orderTemp);
              orderAmount = result.orderAmount;
              orderQty = result.orderQty;
              global.orderPageOrderSelected = result.orderSelected;
              setState(() {});
            }
            if (state is OrderTempGetDataSuccess) {
              context.read<OrderTempBloc>().add(OrderTempGetDataFinish());
              sumOrderQty = state.result.orderQty;
              for (var category in global.orderPageCloneCategoryLists) {
                for (var product in category.products) {
                  product.qty = 0;
                  for (var order in state.result.orderTemp) {
                    if (order.barcode == product.barcode) {
                      product.qty += order.orderQty - order.cancelQty;
                    }
                  }
                }
              }
              setState(() {});
            }
          },
          child: SafeArea(
              child: Scaffold(
            backgroundColor: (currentOrderTakeAway == false)
                ? Colors.deepPurple.shade100
                : Colors.green.shade100,
            appBar: AppBar(
              backgroundColor: (currentOrderTakeAway == false)
                  ? Colors.deepPurple.shade900
                  : Colors.green.shade900,
              leading: (sumOrderQty == 0)
                  ? IconButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (route) => false);
                      },
                      icon: const Icon(Icons.arrow_back),
                    )
                  : null,
              actions: [
                Row(
                  children: [
                    IconButton(
                        onPressed: () {
                          setState(() {
                            global.orderShowImage = !global.orderShowImage;
                          });
                        },
                        icon: Icon((global.orderShowImage)
                            ? Icons.image
                            : Icons.image_not_supported)),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            global.orderFontSize += 1;
                            if (global.orderFontSize > 20) {
                              global.orderFontSize = 12;
                            }
                          });
                        },
                        icon: const Icon(Icons.font_download)),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            global.orderStyle =
                                (global.orderStyle == 0) ? 1 : 0;
                          });
                        },
                        icon: const Icon(Icons.table_chart)),
                    (global.selectTable.buffet_code.isEmpty)
                        ? (currentOrderTakeAway == true)
                            ? AnimateIcon(
                                key: UniqueKey(),
                                onTap: () {
                                  setState(() {
                                    currentOrderTakeAway = false;
                                  });
                                },
                                iconType: IconType.continueAnimation,
                                height: 25,
                                width: 25,
                                color: Colors.white,
                                animateIcon: AnimateIcons.home,
                              )
                            : Container()
                        : Container(),
                    (global.selectTable.buffet_code.isEmpty)
                        ? (currentOrderTakeAway == false)
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    currentOrderTakeAway = true;
                                  });
                                },
                                icon: const Icon(
                                  Icons.table_bar,
                                  size: 25,
                                ))
                            : Container()
                        : Container(),
                    badges.Badge(
                      position: badges.BadgePosition.topEnd(top: 0, end: 3),
                      badgeContent: Text(
                        global.moneyFormat.format(sumOrderQty),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.shopping_cart),
                        onPressed: () async {
                          if (sumOrderQty != 0) {
                            var result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CartPage(
                                      orderId: global.selectTableNumber,
                                      barcode: "")),
                            );
                            if (result == true) {
                              if (mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                    context, '/home', (route) => false);
                              }
                            } else {
                              refresh();
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                  ],
                )
              ],
            ),
            body: Column(
              children: [
                Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: const Border(
                          bottom: BorderSide(width: 1.0, color: Colors.black),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(
                                0, 3), // changes position of shadow
                          ),
                        ]),
                    padding: const EdgeInsets.all(4),
                    width: double.infinity,
                    child: Text(
                        "$tableInfo : ${(currentOrderTakeAway == false) ? "รับประทานที่ร้าน" : "สั่งกลับบ้าน"}",
                        style: TextStyle(
                            fontSize: global.orderFontSize,
                            fontWeight: FontWeight.bold))),
                Expanded(
                    child: (global.orderStyle == 0)
                        ? productListWidget(showCategory: true)
                        : Column(children: [
                            Expanded(
                              child:
                                  (global.orderPageCloneCategoryLists.isEmpty)
                                      ? Container()
                                      : productListWidget(showCategory: false),
                            ),
                            categoryListWidget(orientation),
                          ])),
              ],
            ),
          )));
    });
  }
}
