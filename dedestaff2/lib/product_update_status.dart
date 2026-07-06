import 'dart:ui';
import 'package:dedeorder/bloc/product_barcode_status_bloc.dart';
import 'package:dedeorder/model/category_model.dart';
import 'package:dedeorder/model/global_model.dart';
import 'package:dedeorder/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedeorder/utility/api.dart' as api;

class ProductUpdateStatusPage extends StatefulWidget {
  /// 0=update, 1=เพิ่มจำนวน
  ///
  final int updateMode;

  const ProductUpdateStatusPage({super.key, required this.updateMode});

  @override
  _ProductUpdateStatusPageState createState() =>
      _ProductUpdateStatusPageState();
}

class _ProductUpdateStatusPageState extends State<ProductUpdateStatusPage> {
  int categoryIndex = 0;
  List<StaffCategoryModel> cloneCategoryLists = [];
  List<ProductBarcodeStatusObjectBoxStruct> barcodeStatusLists = [];
  List<Widget> productSelectList = [];
  double qtyValue = 0;

  @override
  void initState() {
    super.initState();
    for (var category in global.categoryLists) {
      cloneCategoryLists.add(category);
    }
    for (int i = 0; i < global.productLists.length; i++) {
      {
        // ถ้าไม่พบสินค้า ให้ไปลบใน Category ที่เกี่ยวข้องออก (Memory)
        for (int i = 0; i < cloneCategoryLists.length; i++) {
          List<String> removeCodeList = [];
          for (int j = 0; j < cloneCategoryLists[i].products.length; j++) {
            int index = global.findProductByBarcode(
                cloneCategoryLists[i].products[j].barcode);
            if (index == -1) {
              // ถ้าไม่พบสินค้าใน Barcode Master ให้ลบออกจาก Category
              removeCodeList.add(cloneCategoryLists[i].products[j].barcode);
            } else {
              bool isInitSelectTable = false;
              try {
                if (global.selectTable.buffet_code.isNotEmpty) {
                  isInitSelectTable = true;
                }
              } catch (e, s) {
                global.sendErrorToDevTeam("ProductUpdateStatusPage: $e $s");
              }

              if (isInitSelectTable &&
                  global.selectTable.buffet_code.isNotEmpty) {
                // กรณี เป็น Buffet
                if (global.productLists[index].ordertypes.isEmpty) {
                  // ถ้าสินค้าไม่ใช่ Buffet ให้ลบออกจาก Category
                  removeCodeList.add(cloneCategoryLists[i].products[j].barcode);
                } else {
                  bool found = false;
                  for (int k = 0;
                      k < global.productLists[index].ordertypes.length;
                      k++) {
                    if (global.selectTable.buffet_code ==
                        global.productLists[index].ordertypes[k].code) {
                      found = true;
                      break;
                    }
                  }
                  if (found == false) {
                    // ถ้าไม่พบสินค้าใน Barcode Master ให้ลบออกจาก Category
                    removeCodeList
                        .add(cloneCategoryLists[i].products[j].barcode);
                  }
                }
              } else {
                // กรณีเป็น A La Carte แต่สินค้าไม่ได้กำหนดให้เป็น A La Carte ให้ลบออก
                if (global.productLists[index].isAlacarte == false) {
                  removeCodeList.add(cloneCategoryLists[i].products[j].barcode);
                }
              }
            }
          }
          for (int j = 0; j < removeCodeList.length; j++) {
            cloneCategoryLists[i]
                .products
                .removeWhere((element) => element.barcode == removeCodeList[j]);
          }
        }
      }
    }
    // ลบ Category ที่ไม่มีสินค้าออก
    List<String> removeCategoryList = [];
    for (int i = 0; i < cloneCategoryLists.length; i++) {
      if (cloneCategoryLists[i].products.isEmpty) {
        removeCategoryList.add(cloneCategoryLists[i].guidfixed);
      }
    }
    for (int i = 0; i < removeCategoryList.length; i++) {
      cloneCategoryLists
          .removeWhere((element) => element.guidfixed == removeCategoryList[i]);
    }
    refresh();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void refresh() {
    context.read<ProductBarcodeStatusBloc>().add(ProductBarcodeStatusGetData());
  }

  String optionTypeName(ProductProcessOptionModel type) {
    if (type.maxselect > 1) {
      return "เลือกได้สูงสุด ${type.maxselect} หัวข้อ";
    } else {
      return "เลือกได้หนึ่งหัวข้อ";
    }
  }

  Widget productWidget(ProductProcessModel product) {
    int productBarcodeIndex = barcodeStatusLists
        .indexWhere((element) => element.barcode == product.barcode);
    String statusLabel = "Error : ${product.barcode}";
    Color statusColor = Colors.red;
    if (productBarcodeIndex != -1) {
      switch (barcodeStatusLists[productBarcodeIndex].orderStatus) {
        case 0:
          statusLabel = "ปรกติ";
          statusColor = Colors.green.shade400;
          break;
        case 1:
          statusLabel = "สินค้าหมด";
          statusColor = Colors.orange;
          break;
      }
      if (barcodeStatusLists[productBarcodeIndex].orderDisable) {
        statusLabel = "เลิกขาย (ไม่แสดง)";
        statusColor = Colors.pink;
      }
    }
    Widget productOptionWidget = Container();
    if (product.options.isNotEmpty) {
      for (var option in product.options) {
        productOptionWidget = SizedBox(
            width: double.infinity,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${global.getNameFromLanguage(option.names, global.userLanguage)} (${optionTypeName(option)})",
                    overflow: TextOverflow.visible,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  for (var choice in option.choices)
                    (choice.priceValue == 0)
                        ? Text(
                            " - ${global.getNameFromLanguage(choice.names, global.userLanguage)}",
                            overflow: TextOverflow.visible,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          )
                        : Text(
                            " - ${global.getNameFromLanguage(choice.names, global.userLanguage)} + ${global.moneyFormat.format(choice.priceValue)}",
                            overflow: TextOverflow.visible,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                ]));
      }
    }
    return SizedBox(
        width: 110,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: statusColor,
              padding: const EdgeInsets.only(
                  top: 5.0, bottom: 5.0, left: 5.0, right: 5.0),
            ),
            onPressed: () async {
              await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(builder: (context, setState) {
                      return AlertDialog(
                        title: Text(
                            "แก้ไขสถานะสินค้า สถานะปัจจุบัน : $statusLabel"),
                        content: (widget.updateMode == 0)
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    global.getNameFromLanguage(
                                        product.names, global.userLanguage),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: ElevatedButton(
                                        onPressed: () async {
                                          barcodeStatusLists[
                                                  productBarcodeIndex]
                                              .orderStatus = 0;
                                          await api
                                              .productBarcodeStatusUpdateToTerminal(
                                                  barcodeStatusLists[
                                                      productBarcodeIndex]);
                                          Navigator.pop(context);
                                        },
                                        child: const Text("ปรกติ"),
                                      )),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                          child: ElevatedButton(
                                        onPressed: () async {
                                          barcodeStatusLists[
                                                  productBarcodeIndex]
                                              .orderStatus = 1;
                                          await api
                                              .productBarcodeStatusUpdateToTerminal(
                                                  barcodeStatusLists[
                                                      productBarcodeIndex]);
                                          Navigator.pop(context);
                                        },
                                        child: const Text("สินค้าหมด"),
                                      )),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                          value: barcodeStatusLists[
                                                  productBarcodeIndex]
                                              .orderDisable,
                                          onChanged: (value) async {
                                            barcodeStatusLists[
                                                    productBarcodeIndex]
                                                .orderDisable = value!;
                                            await api
                                                .productBarcodeStatusUpdateToTerminal(
                                                    barcodeStatusLists[
                                                        productBarcodeIndex]);

                                            setState(() {});
                                          }),
                                      const Text(
                                        "เลิกขาย (ไม่แสดง)",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                          value: barcodeStatusLists[
                                                  productBarcodeIndex]
                                              .orderAutoStock,
                                          onChanged: (value) async {
                                            barcodeStatusLists[
                                                    productBarcodeIndex]
                                                .orderAutoStock = value!;
                                            await api
                                                .productBarcodeStatusUpdateToTerminal(
                                                    barcodeStatusLists[
                                                        productBarcodeIndex]);

                                            setState(() {});
                                          }),
                                      const Text(
                                        "สินค้าหมดอัตโนมัติ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  (barcodeStatusLists[productBarcodeIndex]
                                          .orderAutoStock)
                                      ? Row(
                                          children: [
                                            const Text("ยอดคงเหลือเริ่มต้น"),
                                            const Spacer(),
                                            ElevatedButton(
                                              onPressed: () async {
                                                if (barcodeStatusLists[
                                                            productBarcodeIndex]
                                                        .qtyStart >
                                                    0) {
                                                  barcodeStatusLists[
                                                          productBarcodeIndex]
                                                      .qtyStart--;
                                                  await api
                                                      .productBarcodeStatusUpdateToTerminal(
                                                          barcodeStatusLists[
                                                              productBarcodeIndex]);
                                                }
                                                setState(() {});
                                              },
                                              child: const Icon(
                                                Icons.exposure_minus_1,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                                overflow: TextOverflow.visible,
                                                "${global.moneyFormat.format(barcodeStatusLists[productBarcodeIndex].qtyStart)} ${global.getNameFromJsonLanguage(product.unitname, global.userLanguage)}"),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                barcodeStatusLists[
                                                        productBarcodeIndex]
                                                    .qtyStart++;
                                                await api
                                                    .productBarcodeStatusUpdateToTerminal(
                                                        barcodeStatusLists[
                                                            productBarcodeIndex]);
                                                setState(() {});
                                              },
                                              child: const Icon(
                                                Icons.plus_one,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Container(),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  (barcodeStatusLists[productBarcodeIndex]
                                          .orderAutoStock)
                                      ? Row(
                                          children: [
                                            const Text("ยอดคงเหลือปัจจุบัน"),
                                            const Spacer(),
                                            ElevatedButton(
                                              onPressed: () async {
                                                if (barcodeStatusLists[
                                                            productBarcodeIndex]
                                                        .qtyBalance >
                                                    0) {
                                                  barcodeStatusLists[
                                                          productBarcodeIndex]
                                                      .qtyBalance--;
                                                }
                                                await api
                                                    .productBarcodeStatusUpdateToTerminal(
                                                        barcodeStatusLists[
                                                            productBarcodeIndex]);
                                                setState(() {});
                                              },
                                              child: const Icon(
                                                Icons.exposure_minus_1,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                                "${global.moneyFormat.format(barcodeStatusLists[productBarcodeIndex].qtyBalance)} ${global.getNameFromJsonLanguage(product.unitname, global.userLanguage)}"),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                barcodeStatusLists[
                                                        productBarcodeIndex]
                                                    .qtyBalance++;
                                                await api
                                                    .productBarcodeStatusUpdateToTerminal(
                                                        barcodeStatusLists[
                                                            productBarcodeIndex]);
                                                setState(() {});
                                              },
                                              child: const Icon(
                                                Icons.plus_one,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Container(),
                                ],
                              )
                            : Column(mainAxisSize: MainAxisSize.min, children: [
                                Text(
                                  "เพิ่ม : ${global.getNameFromLanguage(product.names, global.userLanguage)} (${global.getNameFromJsonLanguage(product.unitname, global.userLanguage)})",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Expanded(
                                      child: ElevatedButton(
                                    onPressed: () async {
                                      qtyValue--;
                                      await api
                                          .productBarcodeStatusUpdateToTerminal(
                                              barcodeStatusLists[
                                                  productBarcodeIndex]);
                                      setState(() {});
                                    },
                                    child: const Icon(
                                      Icons.exposure_minus_1,
                                      size: 20,
                                    ),
                                  )),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                      overflow: TextOverflow.visible,
                                      "${global.moneyFormat.format(qtyValue)} ${global.getNameFromJsonLanguage(product.unitname, global.userLanguage)}"),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                      child: ElevatedButton(
                                    onPressed: () async {
                                      qtyValue++;
                                      setState(() {});
                                    },
                                    child: const Icon(
                                      Icons.plus_one,
                                      size: 20,
                                    ),
                                  )),
                                ]),
                              ]),
                        actions: [
                          TextButton(
                            child: const Text("กลับ"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          (widget.updateMode == 0)
                              ? Container()
                              : TextButton(
                                  child: const Text("บันทึกและปรับปรุงยอด"),
                                  onPressed: () async {
                                    barcodeStatusLists[productBarcodeIndex]
                                        .qtyBalance += qtyValue;
                                    await api
                                        .productBarcodeStatusUpdateToTerminal(
                                            barcodeStatusLists[
                                                productBarcodeIndex]);
                                    qtyValue = 0;
                                    if (mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                        ],
                      );
                    });
                  });
              refresh();
            },
            child: Column(children: [
              Image(
                image: (product.imageuri.isEmpty)
                    ? Image.asset("assets/noimage.png").image
                    : NetworkImage(product.imageuri),
              ),
              Text(global.getNameFromLanguage(
                  product.names, global.userLanguage)),
              productOptionWidget,
              Column(children: [
                Row(
                  children: [
                    const Text("สถานะ"),
                    const Spacer(),
                    Text(
                      overflow: TextOverflow.visible,
                      statusLabel,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
                (productBarcodeIndex != -1 &&
                        barcodeStatusLists[productBarcodeIndex]
                                .orderAutoStock ==
                            true)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "สินค้าหมดอัตโนมัติ",
                            overflow: TextOverflow.visible,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "ยอดคงเหลือเริ่มต้น ${global.moneyFormat.format(barcodeStatusLists[productBarcodeIndex].qtyStart)} ${global.getNameFromJsonLanguage(product.unitname, global.userLanguage)}",
                            overflow: TextOverflow.visible,
                          ),
                          Text(
                            "ยอดคงเหลือปัจจุบัน ${global.moneyFormat.format(barcodeStatusLists[productBarcodeIndex].qtyBalance)} ${global.getNameFromJsonLanguage(product.unitname, global.userLanguage)}",
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      )
                    : Container(),
              ])
            ])));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBarcodeStatusBloc, ProductBarcodeStatusState>(
        listener: (context, state) {
          if (state is ProductBarcodeStatusGetDataSuccess) {
            context
                .read<ProductBarcodeStatusBloc>()
                .add(ProductBarcodeStatusGetDataFinish());
            barcodeStatusLists = state.result;
            productSelectList.clear();
            for (var product in global.productLists) {
              bool foundInCategory = false;
              for (var category in cloneCategoryLists[categoryIndex].products) {
                if (category.barcode == product.barcode) {
                  foundInCategory = true;
                  break;
                }
              }
              if (foundInCategory == false) {
                continue;
              }
              int findIndex = barcodeStatusLists
                  .indexWhere((element) => element.barcode == product.barcode);
              if (findIndex != -1) {
                if (widget.updateMode == 0 ||
                    (widget.updateMode == 1 &&
                        barcodeStatusLists[findIndex].orderAutoStock == true &&
                        barcodeStatusLists[findIndex].orderDisable == false)) {
                  productSelectList.add(productWidget(product));
                }
              }
            }
            setState(() {});
          }
        },
        child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.deepPurple.shade900,
              title: (widget.updateMode == 0)
                  ? const Text('Product Update Status')
                  : const Text('Product Update Qty'),
              leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back)),
            ),
            body: Container(
                padding: const EdgeInsets.all(5),
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: cloneCategoryLists
                              .map((e) => ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.only(
                                          left: 5, right: 5, top: 0, bottom: 0),
                                      foregroundColor: Colors.black,
                                      backgroundColor:
                                          (cloneCategoryLists.indexOf(e) ==
                                                  categoryIndex)
                                              ? Colors.green.shade300
                                              : Colors.cyan.shade200,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        categoryIndex =
                                            cloneCategoryLists.indexOf(e);
                                      });
                                      refresh();
                                    },
                                    child: Text(
                                        global.getNameFromLanguage(
                                            e.names, global.userLanguage),
                                        style: TextStyle(
                                            fontSize: global.orderFontSize,
                                            fontWeight: FontWeight.bold)),
                                  ))
                              .toList())),
                  const SizedBox(
                    height: 5,
                  ),
                  Expanded(
                      child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                            },
                          ),
                          child: SingleChildScrollView(
                              child: Wrap(
                                  spacing: 2,
                                  runSpacing: 2,
                                  children: productSelectList))))
                ]))));
  }
}
