import 'dart:ui';
import 'package:dedekiosk/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;

class OrderStandardProductOptionPage extends StatefulWidget {
  final ProductProcessModel product;
  final double qty;
  final String remark;

  const OrderStandardProductOptionPage(
      {super.key,
      required this.product,
      required this.qty,
      required this.remark});

  @override
  State<OrderStandardProductOptionPage> createState() =>
      _OrderStandardProductOptionPageState();
}

class _OrderStandardProductOptionPageState
    extends State<OrderStandardProductOptionPage> {
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(global.getNameFromLanguage(
            widget.product.names, global.languageForCustomer)),
      ),
      body: Column(mainAxisSize: MainAxisSize.min, children: [
        Expanded(
            child: SingleChildScrollView(
                child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              color: Colors.blue.shade100,
              width: double.infinity,
              height: 100,
              child: Row(children: [
                InkWell(
                    onTap: () async {
                      await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(global.getNameFromLanguage(
                                  widget.product.names,
                                  global.languageForCustomer)),
                              content: Image.network(
                                widget.product.imageuri,
                                fit: BoxFit.cover,
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(global.language("close"))),
                              ],
                            );
                          });
                    },
                    child: Container(
                        child: (widget.product.imageuri.isEmpty)
                            ? Container()
                            : Image.network(
                                widget.product.imageuri,
                                fit: BoxFit.cover,
                              ))),
                Expanded(
                    child: Text(
                  maxLines: 2,
                  global.getNameFromLanguage(
                      widget.product.names, global.languageForCustomer),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ]),
            ),
            Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  autofocus: false,
                  controller: textEditingController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: global.language("note"),
                  ),
                )),
            for (int optionIndex = 0;
                optionIndex < widget.product.options.length;
                optionIndex++)
              Column(
                children: [
                  Container(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                      ),
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white),
                          children: [
                            TextSpan(
                              text: global.getNameFromLanguage(
                                widget.product.options[optionIndex].names,
                                global.languageForCustomer,
                              ),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: (widget.product.options[optionIndex]
                                          .choicetype ==
                                      1)
                                  ? global.language("choose_one")
                                  : "${global.language("many_choices")} ${global.language("maximum")} ${widget.product.options[optionIndex].maxselect} ${global.language("choice")}",
                            ),
                          ],
                        ),
                      )),
                  Container(
                      margin: const EdgeInsets.all(4),
                      width: double.infinity,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (int choiceIndex = 0;
                              choiceIndex <
                                  widget.product.options[optionIndex].choices
                                      .length;
                              choiceIndex++)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8, top: 0, bottom: 0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(0),
                                  ),
                                  backgroundColor: Colors.grey[200],
                                  elevation: 0.0,
                                  shadowColor: Colors.transparent,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                              onPressed: () {
                                if (widget.product.options[optionIndex]
                                    .choices[choiceIndex].selected) {
                                  // ยกเลิกการเลือก
                                  widget.product.options[optionIndex]
                                      .choices[choiceIndex].selected = false;
                                  widget.product.options[optionIndex]
                                      .choices[choiceIndex].amount = 0;
                                } else {
                                  int selectedCount = 0;
                                  for (int choiceIndex = 0;
                                      choiceIndex <
                                          widget.product.options[optionIndex]
                                              .choices.length;
                                      choiceIndex++) {
                                    if (widget.product.options[optionIndex]
                                            .choices[choiceIndex].selected ==
                                        true) {
                                      selectedCount++;
                                    }
                                  }
                                  int maxSelect = (widget
                                              .product
                                              .options[optionIndex]
                                              .choicetype ==
                                          1)
                                      ? 1
                                      : widget.product.options[optionIndex]
                                          .maxselect;
                                  if (selectedCount < maxSelect) {
                                    // น้อยกว่า maxselect ที่กำหนดไว้ จึงเลือกได้
                                    widget.product.options[optionIndex]
                                            .choices[choiceIndex].selected = true;
                                    // คำนวณ amount สำหรับ choice นี้โดยเฉพาะ (ไม่ใช่ยอดรวมทุก choice)
                                    double choiceAmount = widget.product.options[optionIndex]
                                            .choices[choiceIndex].priceValue * widget.product.qty;
                                    double choiceDiscount = global.calcDiscount(
                                        amount: choiceAmount,
                                        discountWord: widget.product.options[optionIndex]
                                            .choices[choiceIndex].discountWord);
                                    widget.product.options[optionIndex]
                                            .choices[choiceIndex].amount = choiceAmount - choiceDiscount;
                                  }
                                }
                                setState(() {});
                              },
                              child: RichText(
                                  text: TextSpan(children: [
                                WidgetSpan(
                                    child: (widget
                                                .product
                                                .options[optionIndex]
                                                .choices[choiceIndex]
                                                .selected ==
                                            true)
                                        ? const Icon(
                                            size: 16,
                                            Icons.check_box,
                                            color: Colors.black,
                                          )
                                        : const Icon(
                                            size: 16,
                                            Icons.check_box_outline_blank,
                                            color: Colors.black)),
                                TextSpan(
                                    text:
                                        " ${global.getNameFromLanguage(widget.product.options[optionIndex].choices[choiceIndex].names, global.languageForCustomer)}",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                                if (widget.product.options[optionIndex]
                                        .choices[choiceIndex].priceValue !=
                                    0)
                                  TextSpan(
                                      text: " +${global.moneyFormat.format(
                                        widget.product.options[optionIndex]
                                            .choices[choiceIndex].priceValue,
                                      )} ${global.language("money_baht")}",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold))
                              ])),
                            )
                        ],
                      ))
                ],
              )
          ],
        ))),
        Container(
          padding: const EdgeInsets.all(4),
          width: double.infinity,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                "${global.language("qty")} ${global.moneyFormat.format(qty)} ${global.getNameFromLanguage(widget.product.unitnames, global.languageForCustomer)}",
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(
              width: 10,
            ),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    qty++;
                  });
                },
                child: const Text("+1")),
          ]),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          child: Row(children: [
            Expanded(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Map<String, dynamic> parameters = {
                        'qty': 0,
                        'flag': false,
                        'remark': textEditingController.text,
                      };
                      Navigator.pop(context, parameters);
                    },
                    child: Text(global.language("cancel")))),
            const SizedBox(
              width: 10,
            ),
            Expanded(
                child: ElevatedButton(
                    onPressed: () {
                      Map<String, dynamic> parameters = {
                        'qty': qty,
                        'flag': true,
                        'remark': textEditingController.text,
                      };
                      Navigator.pop(context, parameters);
                    },
                    child: Text(global.language("confirm")))),
          ]),
        ),
      ]),
    );
  }
}
