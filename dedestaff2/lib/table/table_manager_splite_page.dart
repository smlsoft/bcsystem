import 'package:dedeorder/utility/printer.dart' as printer;
import 'dart:convert';
import 'dart:ui';
import 'package:dedeorder/utility/api.dart' as api;
import 'package:dedeorder/bloc/order_temp_bloc.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:dedeorder/model/order_temp_model.dart';
import 'package:dedeorder/model/product_model.dart';
import 'package:dedeorder/model/table_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TableManagerSplitPage extends StatefulWidget {
  final TableProcessObjectBoxStruct tableProcess;

  const TableManagerSplitPage({Key? key, required this.tableProcess})
      : super(key: key);

  @override
  _TableManagerSplitPageState createState() => _TableManagerSplitPageState();
}

class _TableManagerSplitPageState extends State<TableManagerSplitPage> {
  List<List<OrderTempObjectBoxStruct>> extraTableAndOrderTempList = [];
  List<double> extraTableAndOrderTempQtyList = [];
  List<double> extraTableAndOrderTempAmountList = [];
  List<OrderTempObjectBoxStruct>? orderTemp;
  int tableDisplayIndex = 0;
  int tableSourceIndex = 0;
  int tableTargetIndex = 1;

  @override
  void initState() {
    super.initState();
    extraTableAndOrderTempList.clear();
    extraTableAndOrderTempQtyList.clear();
    extraTableAndOrderTempAmountList.clear();
    for (int loop = 0; loop < 10; loop++) {
      extraTableAndOrderTempList.add([]);
      extraTableAndOrderTempQtyList.add(0);
      extraTableAndOrderTempAmountList.add(0);
    }
    reloadData();
  }

  void reloadData() {
    context.read<OrderTempBloc>().add(OrderTempGetDataByOrderMain(
        orderMainId: widget.tableProcess.number,
        isOrder: false,
        machineId: global.machineId));
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
                    "จำนวน : ${global.moneyFormat.format(order.orderQty - order.cancelQty)} ${global.getNameFromJsonLanguage(order.unitName, global.currentLanguage)}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)),
                Text(
                    "จำนวนเงิน : ${global.moneyFormat.format(order.amount)} บาท",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)),
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
                        maxLines: 2,
                        global.getNameFromJsonLanguage(
                            order.names, global.userLanguage),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
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

  @override
  Widget build(BuildContext context) {
    double menuMinWidth = 140;
    int widgetPerLine = int.parse(
        (MediaQuery.of(context).size.width / menuMinWidth).toStringAsFixed(0));
    return BlocListener<OrderTempBloc, OrderTempState>(
        listener: (context, state) {
          if (state is OrderTempGetDataSuccess) {
            for (int loop = 0; loop < 10; loop++) {
              extraTableAndOrderTempList[loop].clear();
              extraTableAndOrderTempQtyList[loop] = 0;
              extraTableAndOrderTempAmountList[loop] = 0;
            }
            orderTemp = state.result.orderTemp;
            for (int index = 0; index < orderTemp!.length; index++) {
              int tableIndex = 0;
              List<String> splitOrderId = orderTemp![index].orderId.split("#");
              if (splitOrderId.length == 1) {
                tableIndex = 0;
              } else {
                tableIndex = int.parse(splitOrderId[1]);
              }
              extraTableAndOrderTempList[tableIndex].add(orderTemp![index]);
              extraTableAndOrderTempQtyList[tableIndex] +=
                  (orderTemp![index].orderQty - orderTemp![index].cancelQty);
              extraTableAndOrderTempAmountList[tableIndex] +=
                  orderTemp![index].amount;
            }
            context.read<OrderTempBloc>().add(OrderTempGetDataFinish());
            setState(() {});
          }
        },
        child: Scaffold(
            appBar: AppBar(
              title: Text(
                  "${global.language('table_split')} : โต๊ะ : ${widget.tableProcess.number}"),
            ),
            body: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: Column(
                  children: [
                    Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            const Text(
                                "กดเพื่อเลือกโต๊ะต้นทาง (สีน้ำเงิน) : กดค้างเพื่อเลือกโต๊ะปลายทาง (สีเขียว)"),
                            const SizedBox(
                              height: 4,
                            ),
                            SizedBox(
                                width: double.infinity,
                                height: 160,
                                child: ListView(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    for (int index = 0;
                                        index <
                                            extraTableAndOrderTempList.length;
                                        index++)
                                      Container(
                                          padding:
                                              const EdgeInsets.only(right: 2),
                                          child: Column(children: [
                                            ElevatedButton(
                                                onPressed: (index != 0)
                                                    ? () async {
                                                        var table = await api
                                                            .getTableFromTerminal(
                                                                mainNumber: widget
                                                                    .tableProcess
                                                                    .number_main,
                                                                number:
                                                                    "${widget.tableProcess.number_main}#$index");
                                                        await api
                                                            .terminalPrintTableAndQrCode(
                                                                number: table
                                                                    .number);
                                                        if (global
                                                            .printToLocalPrinter) {
                                                          printer
                                                              .printTableQrCode(
                                                            fullDetail: false,
                                                            table: table,
                                                            qrCode:
                                                                table.qr_code,
                                                          );
                                                        }
                                                      }
                                                    : null,
                                                child: const Text("QR Code")),
                                            const SizedBox(
                                              height: 4,
                                            ),
                                            ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: (index ==
                                                            tableSourceIndex)
                                                        ? Colors.blueAccent
                                                        : (index ==
                                                                tableTargetIndex)
                                                            ? Colors.green
                                                            : Colors
                                                                .grey.shade400),
                                                onLongPress: () {
                                                  setState(() {
                                                    if (index !=
                                                        tableSourceIndex) {
                                                      tableTargetIndex = index;
                                                    }
                                                  });
                                                },
                                                onPressed: () {
                                                  setState(() {
                                                    if (index !=
                                                        tableTargetIndex) {
                                                      tableSourceIndex = index;
                                                    }
                                                    tableDisplayIndex = index;
                                                  });
                                                },
                                                child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                          "โต๊ะ : ${widget.tableProcess.number_main}#$index"),
                                                      FittedBox(
                                                          child: Text(
                                                              "ชิ้น : ${global.moneyFormat.format(extraTableAndOrderTempQtyList[index])}")),
                                                      FittedBox(
                                                          child: Text(
                                                              "เงิน : ${global.moneyFormat.format(extraTableAndOrderTempAmountList[index])}")),
                                                      if (index ==
                                                          tableTargetIndex)
                                                        const Icon(Icons
                                                            .arrow_downward),
                                                      if (index ==
                                                          tableSourceIndex)
                                                        const Icon(
                                                            Icons.arrow_upward),
                                                    ])),
                                          ])),
                                  ],
                                )),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                                "ย้ายอาหาร/เครื่องดื่มจาก โต๊ะ : ${widget.tableProcess.number_main}#$tableSourceIndex ไปยัง โต๊ะ : ${widget.tableProcess.number_main}#$tableTargetIndex"),
                          ],
                        )),
                    Expanded(
                        child: GridView.count(
                      shrinkWrap: true,
                      childAspectRatio: (1 / 1.25),
                      padding: EdgeInsets.zero,
                      crossAxisCount: widgetPerLine,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      children: [
                        for (int loop = 0;
                            loop <
                                extraTableAndOrderTempList[tableDisplayIndex]
                                    .length;
                            loop++)
                          InkWell(
                              onTap: () async {
                                if (tableDisplayIndex != tableTargetIndex) {
                                  String targetTable =
                                      "${widget.tableProcess.number_main}#$tableTargetIndex";
                                  await api.orderTempUpdateOrderSplitToTerminal(
                                    sourceTable: extraTableAndOrderTempList[
                                            tableSourceIndex][loop]
                                        .orderId,
                                    sourceGuid: extraTableAndOrderTempList[
                                            tableSourceIndex][loop]
                                        .orderGuid,
                                    targetTable: targetTable,
                                  );
                                  reloadData();
                                  setState(() {});
                                } else {
                                  await showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                            title: const Text("แจ้งเตือน"),
                                            content: const Text(
                                                "ไม่สามารถย้ายอาหารไปยังโต๊ะเดียวกันได้"),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text("ปิด"),
                                              ),
                                            ],
                                          ));
                                }
                              },
                              child: productWidget(
                                  extraTableAndOrderTempList[tableDisplayIndex]
                                      [loop])),
                      ],
                    )),
                  ],
                ))));
  }
}
