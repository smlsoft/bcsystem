import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedekiosk/bloc/order_temp_bloc.dart';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:dedekiosk/objectbox/objectbox.g.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/order/order_standard/order_standard_product_option_page.dart';
import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/order/order_util.dart' as util;
import 'package:dedekiosk/order/order_save.dart' as util;
import 'package:badges/badges.dart' as badges;
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderStandardCartPage extends StatefulWidget {
  const OrderStandardCartPage({
    Key? key,
  }) : super(key: key);

  @override
  _OrderStandardCartPageState createState() => _OrderStandardCartPageState();
}

class _OrderStandardCartPageState extends State<OrderStandardCartPage> {
  double sumOrderAmount = 0;
  double sumOrderQty = 0;
  List<OrderTempDetailModel> orderTempDetailList = [];
  BillCalcAmount bill = BillCalcAmount();
  bool _isPaying =
      false; // ป้องกันกดปุ่มจ่ายซ้ำระหว่างที่ payAndSave กำลังทำงาน
  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    context
        .read<OrderTempBloc>()
        .add(OrderTempLoadStart(barcode: "", isTakeAway: global.orderType));
  }

  Future<void> orderRemoveByOrderGuid(
      {required String orderGuid, required Function refresh}) async {
    int id = -1;
    var getId = global.objectBoxStore
        .box<OrderTempObjectBoxModel>()
        .query(
          OrderTempObjectBoxModel_.orderguid.equals(orderGuid),
        )
        .build()
        .find();
    if (getId.isNotEmpty) {
      id = getId[0].id;
    }
    if (id != -1) {
      global.objectBoxStore.box<OrderTempObjectBoxModel>().remove(id);
    }
    /*await api.clickHouseExecute(
        "alter table ordertemp delete where shopid='${global.deviceConfig.shopId}' and orderguid='$orderGuid';");*/
    refresh();
  }

  Future<void> orderEdit(
      {required BuildContext context,
      required OrderTempDetailModel orderTemp,
      required Function refresh}) async {
    int findProductIndex = global.productList
        .indexWhere((element) => element.barcode == orderTemp.barcode);
    var product = global.productList[findProductIndex];
    if (orderTemp.optionselected.isNotEmpty) {
      List<ProductProcessOptionModel> optionList =
          (jsonDecode(orderTemp.optionselected) as List)
              .map((e) => ProductProcessOptionModel.fromJson(e))
              .toList();
      product.options = optionList;
    }
    var result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => OrderStandardProductOptionPage(
                product: product,
                qty: orderTemp.qty,
                remark: orderTemp.remark,
              )),
    );
    if (result != null) {
      String remark = result['remark'];
      double qty = result['qty'];
      bool confirm = result['flag'];
      remark = result['remark'];
      if (confirm) {
        // อัพเดทรายการเก่า
        /*await api.clickHouseExecute(
            "alter table ordertemp update qty=$qty,optionselected='$jsonOptions',remark='$remark' where shopid='${global.deviceConfig.shopId}' and orderguid='${orderTemp.orderguid}';");*/
        var getId = global.objectBoxStore // อัพเดทรายการเก่า
            .box<OrderTempObjectBoxModel>()
            .query(
              OrderTempObjectBoxModel_.orderguid.equals(orderTemp.orderguid),
            )
            .build()
            .find();
        if (getId.isNotEmpty) {
          OrderTempObjectBoxModel orderTempObjectBoxModel = getId[0];
          orderTempObjectBoxModel.qty = qty;
          orderTempObjectBoxModel.optionselected =
              jsonEncode(product.options.map((e) => e.toJson()).toList());
          orderTempObjectBoxModel.remark = remark;
          global.objectBoxStore
              .box<OrderTempObjectBoxModel>()
              .put(orderTempObjectBoxModel, mode: PutMode.update);
        }
      }
    }
    refresh();
  }

  Widget orderTempBody(
      {required BuildContext context,
      required OrderTempDetailModel order,
      required Function refresh}) {
    int productIndex = global.productList
        .indexWhere((element) => element.barcode == order.barcode);
    List<ProductProcessOptionModel> optionList =
        (order.optionselected.isNotEmpty)
            ? (jsonDecode(order.optionselected) as List)
                .map((e) => ProductProcessOptionModel.fromJson(e))
                .toList()
            : [];
    return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        width: 150,
        child: Column(
          children: [
            if (global.orderShowImage &&
                global.productList[productIndex].imageuri.isNotEmpty)
              Image.network(
                global.productList[productIndex].imageuri,
                cacheWidth: 300,
              ),
            Text(
                global.getNameFromLanguage(
                    global.productList[productIndex].names,
                    global.languageForCustomer),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                )),
            for (var option in optionList)
              for (var choice in option.choices)
                if (choice.selected)
                  Row(
                    children: [
                      Expanded(
                          child: Text(
                              "*${global.getNameFromLanguage(choice.names, global.languageForCustomer)}",
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.blue))),
                      if (choice.priceValue > 0)
                        Text(
                            "+${choice.priceValue} ${global.language("money_baht")}",
                            style: const TextStyle(
                                fontSize: 10, color: Colors.blue)),
                    ],
                  ),
            if (order.remark.isNotEmpty)
              Container(
                  width: double.infinity,
                  child: Text("${global.language("note")} : ${order.remark}",
                      style: const TextStyle(fontSize: 10))),
            Row(
              children: [
                Text(
                    "${global.moneyFormat.format(order.qty)} ${global.getNameFromLanguage(global.productList[productIndex].unitnames, global.languageForCustomer)}${(order.qty == 1) ? "" : "/@${global.moneyFormat.format(order.price)}"}",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    )),
                const Spacer(),
                Text(
                    "${global.language("total")} ${global.moneyFormat.format(order.amount)} ${global.language("money_baht")}",
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold))
              ],
            ),
            Row(
              children: [
                InkWell(
                    splashColor: Colors.blue,
                    onTap: () async {
                      await orderEdit(
                          context: context, orderTemp: order, refresh: refresh);
                    },
                    child: const Icon(
                      Icons.edit,
                      color: Colors.blue,
                      size: 32,
                    )),
                const Spacer(),
                InkWell(
                    splashColor: Colors.blue,
                    onTap: () async {
                      await orderRemoveByOrderGuid(
                          orderGuid: order.orderguid, refresh: refresh);
                    },
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 32,
                    )),
              ],
            ),
          ],
        ));
  }

  Widget orderNowList(
      {required List<OrderTempDetailModel> orderTempList,
      required BuildContext context,
      required Function refresh}) {
    List<Widget> orderList = [];
    var headerStyle =
        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
    var detailStyle = const TextStyle(fontSize: 14);
    List<int> expandedFlex = [2, 1, 1, 1];
    orderList.add(Row(children: [
      Expanded(
        flex: expandedFlex[0],
        child: Text(global.language("product_name"), style: headerStyle),
      ),
      Expanded(
        flex: expandedFlex[1],
        child: Text(global.language("qty"),
            style: headerStyle, textAlign: TextAlign.right),
      ),
      Expanded(
        flex: expandedFlex[2],
        child: Text(global.language("price"),
            style: headerStyle, textAlign: TextAlign.right),
      ),
      Expanded(
        flex: expandedFlex[3],
        child: Text(global.language("total_amount)"),
            style: headerStyle, textAlign: TextAlign.right),
      ),
    ]));
    for (var order in orderTempList) {
      var optionList = (order.optionselected.isNotEmpty)
          ? (jsonDecode(order.optionselected) as List)
              .map((e) => ProductProcessOptionModel.fromJson(e))
              .toList()
          : [];
      orderList.add(Row(children: [
        Expanded(
            flex: expandedFlex[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    global.getNameFromLanguage(
                        global
                            .productList[global.productList.indexWhere(
                                (element) => element.barcode == order.barcode)]
                            .names,
                        global.languageForCustomer),
                    style: detailStyle),
                if (optionList.isNotEmpty)
                  for (var option in optionList)
                    for (var choice in option.choices)
                      if (choice.selected)
                        Text(
                            "*${global.getNameFromLanguage(choice.names, global.languageForCustomer)}${(choice.priceValue > 0) ? " ${global.language("add_money")} ${global.moneyFormat.format(choice.priceValue)} ${global.language("money_baht")}" : ""}",
                            style: detailStyle.apply(color: Colors.blue)),
                if (order.remark.isNotEmpty)
                  Text("${global.language("note")} : ${order.remark}",
                      style: detailStyle),
              ],
            )),
        Expanded(
            flex: expandedFlex[1],
            child: Text(
                "${global.moneyFormat.format(order.qty)} ${global.getNameFromLanguage(global.productList[global.productList.indexWhere((element) => element.barcode == order.barcode)].unitnames, global.languageForCustomer)}",
                style: detailStyle,
                textAlign: TextAlign.right)),
        Expanded(
          flex: expandedFlex[2],
          child: Text(
              "${global.moneyFormat.format(order.price)} ${global.language("money_baht")}",
              style: detailStyle,
              textAlign: TextAlign.right),
        ),
        Expanded(
          flex: expandedFlex[3],
          child: Text(
              "${global.moneyFormat.format(order.amount)} ${global.language("money_baht")}",
              style: detailStyle,
              textAlign: TextAlign.right),
        ),
      ]));
    }
    orderList.add(Row(children: [
      Expanded(
        flex: expandedFlex[0],
        child: Container(),
      ),
      Expanded(
        flex: expandedFlex[1],
        child: Container(),
      ),
      Expanded(
        flex: expandedFlex[2],
        child: Text(global.language("total_amount"),
            style: headerStyle, textAlign: TextAlign.right),
      ),
      Expanded(
        flex: expandedFlex[3],
        child: Text(
            "${global.moneyFormat.format(sumOrderAmount)} ${global.language("money_baht")}",
            style: headerStyle,
            textAlign: TextAlign.right),
      ),
    ]));

    return SingleChildScrollView(
        child: Container(
            margin: const EdgeInsets.only(top: 10),
            width: double.infinity,
            color: Colors.white,
            child: Column(
              children: [
                Wrap(
                    children: orderTempList
                        .map((e) => orderTempBody(
                            context: context, order: e, refresh: refresh))
                        .toList()),
                Container(
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.only(
                        bottom: 10, top: 10, left: 10, right: 10),
                    child: Column(
                      children: orderList,
                    )),
                ElevatedButton(
                    onPressed: () {}, child: Text(global.language("discount")))
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderTempBloc, OrderTempState>(
        listener: (orderTempContext, orderTempState) {
          if (orderTempState is OrderTempLoadSuccess) {
            orderTempDetailList = orderTempState.orderTemp;
            sumOrderQty = 0;
            sumOrderAmount = 0;
            for (var order in orderTempDetailList) {
              sumOrderQty += order.qty;
              sumOrderAmount += order.amount;

              if (order.is_except_vat == false) {
                bill.totalItemVatAmount += order.amount;
              } else {
                bill.totalItemExceptVatAmount += order.amount;
              }
              bill.detailTotalAmount += order.amount;
              bill.detailTotalAmountBeforeDiscount += order.amount;

              if (order.optionselected.isNotEmpty) {
                List<ProductProcessOptionModel> optionList =
                    (jsonDecode(order.optionselected) as List)
                        .map((e) => ProductProcessOptionModel.fromJson(e))
                        .toList();
                for (var option in optionList) {
                  for (var choice in option.choices) {
                    if (choice.selected) {
                      sumOrderAmount += (choice.priceValue * order.qty);
                    }
                  }
                }
              }
            }
            for (var category in global.categoryList) {
              for (var product in category.codelist) {
                product.orderqty = 0;
                for (var order in orderTempDetailList) {
                  if (product.barcode == order.barcode) {
                    product.orderqty = product.orderqty! + order.qty;
                  }
                }
              }
            }
            context.read<OrderTempBloc>().add(OrderTempLoadFinish());
            setState(() {});
          }
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                Text(global.language("order_list")),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: orderNowList(
                    context: context,
                    orderTempList: orderTempDetailList,
                    refresh: reload),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                height: 70,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        margin: const EdgeInsets.only(right: 5),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6B7280),
                            side: const BorderSide(
                              color: Color(0xFF9CA3AF),
                              width: 2,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.close, color: Color(0xFF6B7280)),
                              const SizedBox(width: 8),
                              Text(
                                global.language("cancel"),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: _isPaying
                            ? null
                            : () async {
                                // ป้องกันกดจ่ายซ้ำระหว่าง payAndSave ทำงานอยู่
                                setState(() => _isPaying = true);
                                try {
                                  await util.payAndSave(
                                      totalAmount: sumOrderAmount,
                                      diffAmount: 0,
                                      discountAmount: 0,
                                      discountWord: "",
                                      vatAmount: 0,
                                      saveAmount: 0,
                                      orderTagNumber: "",
                                      context: context,
                                      payNow: true,
                                      orderTempDetailList: orderTempDetailList,
                                      bill: bill);
                                } finally {
                                  if (mounted) {
                                    setState(() => _isPaying = false);
                                  }
                                }
                              },
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              badges.Badge(
                                position: badges.BadgePosition.topEnd(
                                    top: -10, end: -10),
                                badgeContent: Text(
                                  global.moneyFormat.format(sumOrderQty),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ),
                                child: const Icon(
                                  Icons.payment,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Text(
                                '${global.language("payment_amount")} : ${global.moneyFormat.format(sumOrderAmount)} ${global.language("money_baht")}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
