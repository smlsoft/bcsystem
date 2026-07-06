import 'dart:convert';
import 'dart:ui';
import 'package:badges/badges.dart' as badges;
import 'package:dedeorder/bloc/order_temp_bloc.dart';
import 'package:dedeorder/order/cart_page.dart';
import 'package:dedeorder/model/category_model.dart';
import 'package:dedeorder/model/order_temp_model.dart';
import 'package:dedeorder/model/product_model.dart';
import 'package:dedeorder/model/table_model.dart';
import 'package:dedeorder/order/product_option_page.dart';
import 'package:flutter/material.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:dedeorder/utility/api.dart' as api;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class OrderCancelPage extends StatefulWidget {
  const OrderCancelPage({super.key});

  @override
  State<OrderCancelPage> createState() => _OrderCancelPageState();
}

class _OrderCancelPageState extends State<OrderCancelPage> {
  List<OrderTempObjectBoxStruct>? orderTemp;
  TextEditingController remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    remarkController.dispose();
    super.dispose();
  }

  void refresh() {
    context.read<OrderTempBloc>().add(OrderTempGetData(
        orderId: global.selectTableNumber, isOrder: false, machineId: ""));
  }

  Widget optionWidget(String option) {
    if (option.isEmpty) {
      return Container();
    }
    TextStyle choiceTextStyle = const TextStyle(fontSize: 12);
    List<Widget> optionWidgetList = [];
    var optionList = jsonDecode(option);
    List<ProductProcessOptionModel> productOptionList = (optionList as List)
        .map((data) => ProductProcessOptionModel.fromJson(data))
        .toList();
    for (var option in productOptionList) {
      for (var choice in option.choices) {
        if (choice.selected == true) {
          optionWidgetList.add(Container(
              padding: const EdgeInsets.all(2),
              child: Row(children: [
                Text(
                  global.getNameFromLanguage(choice.names, global.userLanguage),
                  style: choiceTextStyle,
                ),
                const Spacer(),
                (choice.priceValue == 0)
                    ? Container()
                    : Text(global.moneyFormat.format(choice.priceValue),
                        style: choiceTextStyle)
              ])));
        }
      }
    }
    return Column(children: optionWidgetList);
  }

  Widget productWidget(OrderTempObjectBoxStruct order) {
    String itemName =
        global.getNameFromJsonLanguage(order.names, global.userLanguage);
    if (order.remark.isNotEmpty) {
      itemName += "\n${order.remark}";
    }
    if (order.optionSelected.isNotEmpty) {
      var jsonList = jsonDecode(order.optionSelected);
      for (var json in jsonList) {
        var option = ProductProcessOptionModel.fromJson(json);
        for (var choice in option.choices) {
          if (choice.selected == true) {
            itemName +=
                "\n${global.getNameFromLanguage(choice.names, global.userLanguage)}";
            if (choice.priceValue! > 0) {
              itemName +=
                  " ${global.moneyFormat.format(choice.priceValue)} บาท";
            }
          }
        }
      }
    }
    return Column(
      children: [
        Container(
            padding: const EdgeInsets.all(2),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blueAccent.shade700,
            ),
            child: Column(
              children: [
                Text(
                    "จำนวนที่สั่ง : ${global.moneyFormat.format(order.orderQty)} ${global.getNameFromJsonLanguage(order.unitName, global.currentLanguage)}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                if (order.cancelQty > 0)
                  Text(
                      "ยกเลิกแล้ว : ${global.moneyFormat.format(order.cancelQty)} ${global.getNameFromJsonLanguage(order.unitName, global.currentLanguage)}",
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.orange, fontSize: 12)),
                if (order.orderQty != (order.orderQty - order.cancelQty))
                  Text(
                      (order.orderQty - order.cancelQty == 0)
                          ? "ยกเลิกทั้งหมดแล้ว"
                          : "เหลือจำนวน : ${global.moneyFormat.format(order.orderQty - order.cancelQty)} ${global.getNameFromJsonLanguage(order.unitName, global.currentLanguage)}",
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                if (order.amount != 0)
                  Text(
                      "รวมเงิน : ${global.moneyFormat.format(order.amount)} บาท",
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                Text("${order.orderEmployeeCode}/${order.orderEmployeeDetail}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ],
            )),
        Expanded(
            child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyan, width: 1)),
                child: Column(children: [
                  Expanded(
                      child: Ink.image(
                    fit: BoxFit.fill,
                    image: (order.imageUri.isEmpty)
                        ? Image.asset("assets/noimage.png").image
                        : NetworkImage(order.imageUri),
                  )),
                  optionWidget(order.optionSelected),
                  Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4, top: 4),
                      child: Text(
                        maxLines: 4,
                        itemName,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.2,
                        ),
                      )),
                  Padding(
                      padding:
                          const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            maxLines: 2,
                            global.getNameFromJsonLanguage(
                                order.unitName, global.currentLanguage),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              height: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            maxLines: 2,
                            "${global.moneyFormat.format(order.price)} บาท",
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              height: 1.2,
                            ),
                          )
                        ],
                      ))
                ])))
      ],
    );
  }

  Future<void> confirmDialog(OrderTempObjectBoxStruct order) {
    double qty = 1;
    remarkController.text = order.remark;

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              scrollable: true,
              title: const Text("ยืนยันการลบรายการ"),
              content: Column(children: [
                SizedBox(height: 300, child: productWidget(order)),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          if (qty > 1) {
                            setState(() {
                              qty--;
                            });
                          }
                        },
                        child: const Text("-")),
                    Expanded(
                        child: Text(
                      global.moneyFormat.format(qty),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    )),
                    ElevatedButton(
                        onPressed: () {
                          if (qty < order.orderQty - order.cancelQty) {
                            setState(() {
                              qty++;
                            });
                          }
                        },
                        child: const Text("+")),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Wrap(
                  spacing: 2,
                  runSpacing: 0,
                  children: [
                    ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all(Colors.red.shade900)),
                        onPressed: () {
                          setState(() {
                            remarkController.text = "สินค้าหมด";
                          });
                        },
                        child: const Text("สินค้าหมด")),
                    ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all(Colors.red.shade900)),
                        onPressed: () {
                          setState(() {
                            remarkController.text = "ลูกค้ายกเลิก";
                          });
                        },
                        child: const Text("ลูกค้ายกเลิก")),
                    ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all(Colors.red.shade900)),
                        onPressed: () {
                          setState(() {
                            remarkController.text = "อาหารช้า";
                          });
                        },
                        child: const Text("อาหารช้า")),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: "เหตุผลการยกเลิก",
                      border: OutlineInputBorder()),
                  maxLines: 2,
                  controller: remarkController,
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text("คุณต้องการลบรายการนี้ใช่หรือไม่")
              ]),
              actions: [
                ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.red)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("ยกเลิก")),
                ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.green)),
                    onPressed: () {
                      api
                          .orderTempCancelByGuid(
                              order.orderGuid, qty, remarkController.text)
                          .then((_) {
                        refresh();
                      });
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("ตกลง"))
              ],
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    double menuMinWidth = 140;
    int widgetPerLine = int.parse(
        (MediaQuery.of(context).size.width / menuMinWidth).toStringAsFixed(0));
    return BlocListener<OrderTempBloc, OrderTempState>(
        listener: (context, state) {
          if (state is OrderTempGetDataSuccess) {
            orderTemp = state.result.orderTemp;
            // sort by table number
            context.read<OrderTempBloc>().add(OrderTempGetDataFinish());
            setState(() {});
          }
        },
        child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.deepPurple.shade900,
              title: const Text('ยกเลิกรายการ'),
              leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (route) => false);
                  }),
            ),
            body: Container(
                padding: const EdgeInsets.all(10),
                child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: GridView.count(
                        childAspectRatio: (1 / 2),
                        padding: EdgeInsets.zero,
                        crossAxisCount: widgetPerLine,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        children: [
                          if (orderTemp != null)
                            for (var order in orderTemp!)
                              InkWell(
                                  borderRadius: BorderRadius.circular(0),
                                  onTap: () async {
                                    if (order.orderQty - order.cancelQty > 0) {
                                      await confirmDialog(order);
                                      refresh();
                                    }
                                  },
                                  child: productWidget(order))
                        ])))));
  }
}
