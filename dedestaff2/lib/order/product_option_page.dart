import 'dart:async';
import 'dart:ui';
import 'package:dedeorder/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:dedeorder/global.dart' as global;

class ProductOptionPage extends StatefulWidget {
  final ProductProcessModel product;
  final double qty;
  final String remark;
  final bool takeAway;

  const ProductOptionPage(
      {super.key,
      required this.product,
      required this.qty,
      required this.remark,
      required this.takeAway});

  @override
  State<ProductOptionPage> createState() => _ProductOptionPageState();
}

class _ProductOptionPageState extends State<ProductOptionPage> {
  late TextEditingController textEditingController;
  late double qty;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
    qty = widget.qty;
    textEditingController.text = widget.remark;
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.deepPurple.shade900,
              title: Text(widget.product.names[0].name),
            ),
            body: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: SingleChildScrollView(
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      width: double.infinity,
                      height: 80,
                      child: Row(children: [
                        (widget.product.imageuri.isEmpty)
                            ? Image.asset("assets/noimage.png")
                            : Image.network(
                                widget.product.imageuri,
                                fit: BoxFit.cover,
                              ),
                        Expanded(
                          child: Text(
                            maxLines: 2,
                            widget.product.names[0].name,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              height: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      child: Wrap(alignment: WrapAlignment.center, children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              if (qty > 1) {
                                setState(() {
                                  qty--;
                                });
                              }
                            },
                            child: const Text("-1")),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                            "จำนวน ${global.moneyFormat.format(qty)} ${global.getNameFromJsonLanguage(widget.product.unitname, global.currentLanguage)}",
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(
                          width: 10,
                        ),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent.shade700,
                            ),
                            onPressed: () async {
                              int findProductBarcodeStatusIndex = global
                                  .productBarcodeStatusLists
                                  .indexWhere((element) =>
                                      element.barcode ==
                                      widget.product.barcode);
                              if (findProductBarcodeStatusIndex == -1 ||
                                  global
                                          .productBarcodeStatusLists[
                                              findProductBarcodeStatusIndex]
                                          .orderAutoStock ==
                                      false) {
                                qty++;
                              } else {
                                if ((qty - widget.qty) <
                                    global
                                        .productBarcodeStatusLists[
                                            findProductBarcodeStatusIndex]
                                        .qtyBalance) {
                                  qty++;
                                } else {
                                  await showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                            title: const Text("สินค้าไม่พอ"),
                                            content: Text(
                                                global.getNameFromLanguage(
                                                    widget.product.names,
                                                    global.userLanguage)),
                                            actions: [
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text("ยกเลิก")),
                                            ],
                                          ));
                                }
                              }
                              setState(() {});
                            },
                            child: const Text("+1")),
                      ]),
                    ),
                    Container(
                        padding: const EdgeInsets.all(10),
                        width: double.infinity,
                        child: Wrap(alignment: WrapAlignment.center, children: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text("ยกเลิก/ไม่สั่งรายการนี้")),
                          const SizedBox(
                            width: 10,
                          ),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent.shade700,
                              ),
                              onPressed: () {
                                Map<String, dynamic> parameters = {
                                  'qty': qty,
                                  'flag': true,
                                  'remark': textEditingController.text,
                                  'options': widget.product.options,
                                  'takeAway': widget.takeAway,
                                };
                                Navigator.pop(context, parameters);
                              },
                              child: const Text("ยืนยัน/สั่งรายการนี้")),
                        ])),
                    Padding(
                        padding: const EdgeInsets.all(10),
                        child: TextField(
                          controller: textEditingController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'หมายเหตุ',
                          ),
                        )),
                    for (int optionIndex = 0;
                        optionIndex < widget.product.options.length;
                        optionIndex++)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(
                                left: 8, right: 8, top: 4, bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.shade400,
                            ),
                            alignment: Alignment.centerLeft,
                            child: RichText(
                                text: TextSpan(children: [
                              TextSpan(
                                  text: global.getNameFromLanguage(
                                      widget.product.options[optionIndex].names,
                                      global.userLanguage),
                                  style: TextStyle(
                                      fontSize: global.orderFontSize,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              TextSpan(text: " "),
                              TextSpan(
                                text: (widget.product.options[optionIndex]
                                                .choicetype ==
                                            1 ||
                                        widget.product.options[optionIndex]
                                                .maxselect ==
                                            1)
                                    ? "เลือกอย่างใดอย่างหนึ่ง"
                                    : "เลือกได้หลายอย่าง สูงสุด ${widget.product.options[optionIndex].maxselect} อย่าง",
                                style: TextStyle(
                                    fontSize: global.orderFontSize / 1.25,
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic),
                              )
                            ])),
                          ),
                          Container(
                            margin: const EdgeInsets.all(4),
                            width: double.infinity,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (int choiceIndex = 0;
                                    choiceIndex <
                                        widget.product.options[optionIndex]
                                            .choices.length;
                                    choiceIndex++)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.only(
                                          left: 8, right: 8, top: 0, bottom: 0),
                                      backgroundColor: widget
                                              .product
                                              .options[optionIndex]
                                              .choices[choiceIndex]
                                              .selected!
                                          ? Colors
                                              .green[200] // สีเข้มเมื่อถูกเลือก
                                          : Colors.grey[
                                              200], // สีพื้นฐานเมื่อไม่ถูกเลือก
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (widget.product.options[optionIndex]
                                                .maxselect ==
                                            1) {
                                          // กรณีเลือกได้อย่างเดียว (radio button)
                                          for (int i = 0;
                                              i <
                                                  widget
                                                      .product
                                                      .options[optionIndex]
                                                      .choices
                                                      .length;
                                              i++) {
                                            widget.product.options[optionIndex]
                                                .choices[i].selected = false;
                                          }
                                          widget
                                              .product
                                              .options[optionIndex]
                                              .choices[choiceIndex]
                                              .selected = true;
                                        } else {
                                          // กรณีเลือกได้หลายอย่าง (checkbox)
                                          if (widget
                                              .product
                                              .options[optionIndex]
                                              .choices[choiceIndex]
                                              .selected!) {
                                            // ยกเลิกการเลือก
                                            widget
                                                .product
                                                .options[optionIndex]
                                                .choices[choiceIndex]
                                                .selected = false;
                                          } else {
                                            int selectedCount = 0;
                                            for (int i = 0;
                                                i <
                                                    widget
                                                        .product
                                                        .options[optionIndex]
                                                        .choices
                                                        .length;
                                                i++) {
                                              if (widget
                                                      .product
                                                      .options[optionIndex]
                                                      .choices[i]
                                                      .selected ==
                                                  true) {
                                                selectedCount++;
                                              }
                                            }
                                            if (selectedCount <
                                                widget
                                                    .product
                                                    .options[optionIndex]
                                                    .maxselect) {
                                              // น้อยกว่า maxselect ที่กำหนดไว้ จึงเลือกได้
                                              widget
                                                  .product
                                                  .options[optionIndex]
                                                  .choices[choiceIndex]
                                                  .selected = true;
                                            }
                                          }
                                        }
                                      });
                                    },
                                    child: RichText(
                                        text: TextSpan(children: [
                                      WidgetSpan(
                                          child: (widget
                                                      .product
                                                      .options[optionIndex]
                                                      .maxselect ==
                                                  1)
                                              ? (widget
                                                          .product
                                                          .options[optionIndex]
                                                          .choices[choiceIndex]
                                                          .selected ==
                                                      true
                                                  ? const Icon(
                                                      Icons
                                                          .radio_button_checked,
                                                      color: Colors.black,
                                                    )
                                                  : const Icon(
                                                      Icons
                                                          .radio_button_unchecked,
                                                      color: Colors.black))
                                              : (widget
                                                          .product
                                                          .options[optionIndex]
                                                          .choices[choiceIndex]
                                                          .selected ==
                                                      true
                                                  ? const Icon(
                                                      Icons.check_box,
                                                      color: Colors.black,
                                                    )
                                                  : const Icon(
                                                      Icons
                                                          .check_box_outline_blank,
                                                      color: Colors.black))),
                                      const TextSpan(text: " "),
                                      TextSpan(
                                          text: global.getNameFromLanguage(
                                              widget
                                                  .product
                                                  .options[optionIndex]
                                                  .choices[choiceIndex]
                                                  .names,
                                              global.userLanguage),
                                          style: TextStyle(
                                              fontSize: global.orderFontSize,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold)),
                                      TextSpan(
                                          text: (widget
                                                      .product
                                                      .options[optionIndex]
                                                      .choices[choiceIndex]
                                                      .priceValue ==
                                                  0)
                                              ? ""
                                              : " +${global.moneyFormat.format(widget.product.options[optionIndex].choices[choiceIndex].priceValue)}",
                                          style: TextStyle(
                                              fontSize: global.orderFontSize,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold))
                                    ])),
                                  )
                              ],
                            ),
                          ),

                          /*for (int choiceIndex = 0; choiceIndex < widget.product.options[optionIndex].choices.length; choiceIndex++)
                            Padding(
                                padding: const EdgeInsets.only(left: 8, right: 8, top: 0, bottom: 0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.only(left: 8, right: 8, top: 0, bottom: 0),
                                    backgroundColor: Colors.grey[200],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (widget.product.options[optionIndex].choices[choiceIndex].selected!) {
                                        // ยกเลิกการเลือก
                                        widget.product.options[optionIndex].choices[choiceIndex].selected = false;
                                      } else {
                                        int selectedCount = 0;
                                        for (int choiceIndex = 0; choiceIndex < widget.product.options[optionIndex].choices.length; choiceIndex++) {
                                          if (widget.product.options[optionIndex].choices[choiceIndex].selected == true) {
                                            selectedCount++;
                                          }
                                        }
                                        if (selectedCount < widget.product.options[optionIndex].maxselect) {
                                          // น้อยกว่า maxselect ที่กำหนดไว้ จึงเลือกได้
                                          widget.product.options[optionIndex].choices[choiceIndex].selected = !widget.product.options[optionIndex].choices[choiceIndex].selected!;
                                        }
                                      }
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      (widget.product.options[optionIndex].choices[choiceIndex].selected == true)
                                          ? const Icon(
                                              Icons.check_box,
                                              color: Colors.black,
                                            )
                                          : const Icon(Icons.check_box_outline_blank, color: Colors.black),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(widget.product.options[optionIndex].choices[choiceIndex].names[0].name, style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
                                      const Spacer(),
                                      (widget.product.options[optionIndex].choices[choiceIndex].priceValue == 0)
                                          ? Container()
                                          : Text(
                                              global.moneyFormat.format(
                                                widget.product.options[optionIndex].choices[choiceIndex].priceValue,
                                              ),
                                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                                    ],
                                  ),
                                ))*/
                        ],
                      ),
                  ]),
                ))));
  }
}
