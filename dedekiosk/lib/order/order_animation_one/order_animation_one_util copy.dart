// import 'dart:convert';
// import 'package:badges/badges.dart' as badges;
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:dedekiosk/model/global_model.dart';
// import 'package:dedekiosk/model/product_model.dart';
// import 'package:dedekiosk/objectbox/objectbox.g.dart';
// import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
// import 'package:flutter/material.dart';
// import 'package:dedekiosk/util/api.dart' as api;
// import 'package:dedekiosk/global.dart' as global;
// import 'package:dedekiosk/order/order_util.dart' as util;
// import 'package:flutter/services.dart';

// Widget orderAnimationOneProductOptionWidget({
//   required BuildContext context,
//   required Function refresh,
//   required ProductProcessModel product,
//   required bool isAppend,
//   required bool calcStockQty,
//   required String orderGuid,
//   OrderTempDetailModel? orderTemp,
//   required Function() onClose,
// }) {
//   TextEditingController textEditingController = TextEditingController()..text = product.remark;
//   TotalCalculateModel totalCalc = global.calcProductAndOption(product);

//   List<Widget> optionList = [];
//   optionList.add(Row(children: [
//     Expanded(
//         child: Padding(
//             padding: const EdgeInsets.only(right: 10),
//             child: RichText(
//                 text: TextSpan(children: [
//               TextSpan(text: global.getNameFromLanguage(product.names, global.languageForCustomer), style: TextStyle(fontSize: (global.isMobileScreen) ? 14 : 24, color: Colors.black, fontWeight: FontWeight.bold)),
//               TextSpan(text: "\n${global.language("price")} ${global.moneyFormatAndDot.format(product.setprice)} ${global.language("money_baht")}", style: TextStyle(fontSize: (global.isMobileScreen) ? 14 : 24, color: Colors.blue, fontWeight: FontWeight.bold)),
//               if (product.discountword.isNotEmpty && global.priceIndex == 1)
//                 TextSpan(
//                     text: "\n${global.language("discount")} ${product.discountword} = -${global.moneyFormatAndDot.format(global.calcDiscount(amount: product.setprice, discountWord: product.discountword))} ${global.language("money_baht")}",
//                     style: TextStyle(fontSize: (global.isMobileScreen) ? 12 : 18, color: Colors.red, fontWeight: FontWeight.bold)),
//               if (product.discountword.isNotEmpty && global.priceIndex == 1)
//                 TextSpan(
//                     text: "\n${global.language("price_after_discount")} ${global.moneyFormatAndDot.format(product.setprice - global.calcDiscount(amount: product.setprice, discountWord: product.discountword))} ${global.language("money_baht")}",
//                     style: TextStyle(fontSize: (global.isMobileScreen) ? 12 : 18, color: Colors.blue, fontWeight: FontWeight.bold)),
//             ])))),
//     if (product.imageuri.isNotEmpty)
//       Expanded(
//           child: Container(
//               width: 150,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.black),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.5),
//                     spreadRadius: 1,
//                     blurRadius: 1,
//                     offset: const Offset(0, 1), // changes position of shadow
//                   ),
//                 ],
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: ClipRRect(
//                   borderRadius: BorderRadius.circular(10.0),
//                   child: CachedNetworkImage(
//                     imageUrl: product.imageuri,
//                     placeholder: (context, url) => const CircularProgressIndicator(),
//                     errorWidget: (context, url, error) => const Icon(Icons.error),
//                     fit: BoxFit.cover,
//                     imageBuilder: (context, imageProvider) => Container(
//                       width: 300,
//                       height: 300,
//                       decoration: BoxDecoration(
//                         image: DecorationImage(
//                           image: imageProvider,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                   )))),
//   ]));
//   optionList.add(const SizedBox(
//     height: 10,
//   ));
//   for (int optionIndex = 0; optionIndex < product.options.length; optionIndex++) {
//     bool isOneChoice = (product.options[optionIndex].choicetype == 1 || product.options[optionIndex].maxselect == 1);
//     optionList.add(Container(
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey),
//       ),
//       child: Column(
//         children: [
//           Container(
//               padding: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade100,
//                 border: const Border(
//                   bottom: BorderSide(color: Colors.grey),
//                 ),
//               ),
//               alignment: Alignment.centerLeft,
//               child: RichText(
//                 overflow: TextOverflow.ellipsis,
//                 text: TextSpan(
//                   children: [
//                     TextSpan(
//                       text: global.getNameFromLanguage(
//                         product.options[optionIndex].names,
//                         global.languageForCustomer,
//                       ),
//                       style: const TextStyle(
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const TextSpan(text: ' '),
//                     TextSpan(
//                       text: (product.options[optionIndex].choicetype == 1) ? global.language("choose_one") : "${global.language("many_choices")} ${global.language("maximum")} ${product.options[optionIndex].maxselect} ${global.language("choice")}",
//                       style: const TextStyle(
//                         color: Colors.black54,
//                       ),
//                     ),
//                   ],
//                 ),
//               )),
//           Container(
//               margin: const EdgeInsets.all(4),
//               width: double.infinity,
//               child: Wrap(
//                 spacing: 4,
//                 runSpacing: 4,
//                 children: [
//                   for (int choiceIndex = 0; choiceIndex < product.options[optionIndex].choices.length; choiceIndex++)
//                     ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.only(left: 4, right: 4, top: 0, bottom: 0),
//                           backgroundColor: (product.options[optionIndex].choices[choiceIndex].selected) ? Colors.blue.shade100 : Colors.white,
//                         ),
//                         onPressed: () {
//                           if (isOneChoice) {
//                             // ยกเลิกการเลือกทั้งหมด
//                             if (product.options[optionIndex].choices[choiceIndex].selected) {
//                               product.options[optionIndex].choices[choiceIndex].selected = false;
//                               product.options[optionIndex].choices[choiceIndex].amount = 0;
//                             } else {
//                               for (int choiceIndex = 0; choiceIndex < product.options[optionIndex].choices.length; choiceIndex++) {
//                                 product.options[optionIndex].choices[choiceIndex].selected = false;
//                                 product.options[optionIndex].choices[choiceIndex].amount = 0;
//                               }
//                               product.options[optionIndex].choices[choiceIndex].selected = true;
//                               product.options[optionIndex].choices[choiceIndex].amount = global.calcProductOptionAmount(choices: product.options[optionIndex].choices, qty: product.qty);
//                               global.textToSpeech(global.getNameFromLanguage(product.options[optionIndex].choices[choiceIndex].names, global.languageForCustomer));
//                             }
//                           } else {
//                             if (product.options[optionIndex].choices[choiceIndex].selected) {
//                               // ยกเลิกการเลือก
//                               product.options[optionIndex].choices[choiceIndex].selected = false;
//                               product.options[optionIndex].choices[choiceIndex].amount = 0;
//                             } else {
//                               int selectedCount = 0;
//                               for (int choiceIndex = 0; choiceIndex < product.options[optionIndex].choices.length; choiceIndex++) {
//                                 if (product.options[optionIndex].choices[choiceIndex].selected == true) {
//                                   selectedCount++;
//                                 }
//                               }
//                               int maxSelect = (product.options[optionIndex].choicetype == 1) ? 1 : product.options[optionIndex].maxselect;
//                               if (selectedCount < maxSelect) {
//                                 // น้อยกว่า maxselect ที่กำหนดไว้ จึงเลือกได้
//                                 product.options[optionIndex].choices[choiceIndex].selected = !product.options[optionIndex].choices[choiceIndex].selected;
//                                 if (product.options[optionIndex].choices[choiceIndex].selected) {
//                                   global.textToSpeech(global.getNameFromLanguage(product.options[optionIndex].choices[choiceIndex].names, global.languageForCustomer));
//                                 }
//                               }
//                             }
//                           }
//                           refresh();
//                         },
//                         child: Column(
//                           children: [
//                             if (product.options[optionIndex].choices[choiceIndex].imageuri != "")
//                               Container(
//                                 width: 80,
//                                 height: 80,
//                                 decoration: BoxDecoration(
//                                   image: DecorationImage(
//                                     image: NetworkImage(product.options[optionIndex].choices[choiceIndex].imageuri),
//                                     fit: BoxFit.cover,
//                                   ),
//                                 ),
//                               ),
//                             RichText(
//                                 text: TextSpan(children: [
//                               WidgetSpan(
//                                   child: (product.options[optionIndex].choices[choiceIndex].selected == true)
//                                       ? const Icon(
//                                           size: 16,
//                                           Icons.check_box,
//                                           color: Colors.black,
//                                         )
//                                       : const Icon(size: 16, Icons.check_box_outline_blank, color: Colors.black)),
//                               TextSpan(text: " ${global.getNameFromLanguage(product.options[optionIndex].choices[choiceIndex].names, global.languageForCustomer)}", style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
//                               if (product.options[optionIndex].choices[choiceIndex].priceValue != 0)
//                                 TextSpan(
//                                     text: " +${global.moneyFormat.format(
//                                       product.options[optionIndex].choices[choiceIndex].priceValue,
//                                     )} ${global.language("money_baht")}",
//                                     style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
//                               if (product.options[optionIndex].choices[choiceIndex].priceValue != 0 && product.options[optionIndex].choices[choiceIndex].discountWord.isNotEmpty && global.priceIndex == 1)
//                                 TextSpan(
//                                     text:
//                                         "\nลด ${product.options[optionIndex].choices[choiceIndex].discountWord} เหลือ +${global.moneyFormat.format(product.options[optionIndex].choices[choiceIndex].priceValue - global.calcDiscount(amount: product.options[optionIndex].choices[choiceIndex].priceValue, discountWord: product.options[optionIndex].choices[choiceIndex].discountWord))} ${global.language("money_baht")}",
//                                     style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
//                             ])),
//                           ],
//                         ))
//                 ],
//               )),
//         ],
//       ),
//     ));
//   }

//   optionList.add(
//     TextField(
//       onChanged: (value) => product.remark = value,
//       autofocus: false,
//       controller: textEditingController,
//       decoration: InputDecoration(
//         border: const OutlineInputBorder(),
//         labelText: global.language("note"),
//       ),
//     ),
//   );

//   return SizedBox(
//     width: (global.isMobileScreen) ? double.infinity : 600,
//     child: SingleChildScrollView(
//       child: Column(mainAxisSize: MainAxisSize.min, children: [
//         Column(mainAxisSize: MainAxisSize.min, children: optionList),
//         SizedBox(
//           width: double.infinity,
//           child: FittedBox(
//               child: RichText(
//                   text: TextSpan(children: [
//             TextSpan(
//               children: [
//                 if (totalCalc.qty > 1)
//                   TextSpan(
//                     text: "${global.moneyFormat.format(totalCalc.qty)} ${global.getNameFromLanguage(product.unitnames, global.languageForCustomer)} ",
//                     style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
//                   ),
//                 TextSpan(
//                   text: "${global.language("total")} ",
//                   style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
//                 ),
//                 TextSpan(
//                   text: "${global.moneyFormatAndDot.format(totalCalc.totalAmount)} ",
//                   style: const TextStyle(
//                       fontSize: 18,
//                       color: Colors.blue, // Set the amount to blue
//                       fontWeight: FontWeight.bold),
//                 ),
//                 TextSpan(
//                   text: global.language("money_baht"),
//                   style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             if (product.discountword.isNotEmpty && global.priceIndex == 1)
//               TextSpan(
//                   text: " ${global.language("discount")} ${product.discountword} = -${global.moneyFormatAndDot.format(totalCalc.totalDiscount)} ${global.language("money_baht")}",
//                   style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
//             if (product.discountword.isNotEmpty && global.priceIndex == 1)
//               TextSpan(
//                   text: " ${global.language("amount_after_discount")} ${global.moneyFormatAndDot.format(totalCalc.totalAmount - totalCalc.totalDiscount)} ${global.language("money_baht")}",
//                   style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
//           ]))),
//         ),
//         SizedBox(
//           width: double.infinity,
//           height: (global.isMobileScreen) ? 30 : 50,
//           child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
//             ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   padding: const EdgeInsets.all(0),
//                 ),
//                 onPressed: () {
//                   if (product.qty > 1) {
//                     product.qty--;
//                     refresh();
//                     String message = global.findLanguage(code: "reduce", languageCode: global.languageForCustomer);
//                     message += " ";
//                     message += global.findLanguage(code: "is", languageCode: global.languageForCustomer);
//                     message += " ";
//                     message += global.findLanguage(code: "qty", languageCode: global.languageForCustomer);
//                     message += " ";
//                     message += "${global.moneyFormat.format(product.qty)} ${global.getNameFromLanguage(product.unitnames, global.languageForCustomer)}";
//                     global.textToSpeech(message);
//                   }
//                 },
//                 child: const Text("-1")),
//             Expanded(
//                 child: Center(
//                     child: Text("${global.language("qty")} ${global.moneyFormat.format(product.qty)} ${global.getNameFromLanguage(product.unitnames, global.languageForCustomer)}",
//                         style: TextStyle(fontSize: (global.isMobileScreen) ? 14 : 24, fontWeight: FontWeight.bold)))),
//             ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   padding: const EdgeInsets.all(0),
//                 ),
//                 onPressed: () {
//                   product.qty++;
//                   refresh();
//                   String message = global.findLanguage(code: "more", languageCode: global.languageForCustomer);
//                   message += " ";
//                   message += global.findLanguage(code: "is", languageCode: global.languageForCustomer);
//                   message += " ";
//                   message += global.findLanguage(code: "qty", languageCode: global.languageForCustomer);
//                   message += " ";
//                   message += "${global.moneyFormat.format(product.qty)} ${global.getNameFromLanguage(product.unitnames, global.languageForCustomer)}";
//                   global.textToSpeech(message);
//                 },
//                 child: const Text("+1")),
//           ]),
//         ),
//         const SizedBox(
//           height: 4,
//         ),
//         SizedBox(
//             width: double.infinity,
//             height: (global.isMobileScreen) ? 30 : 50,
//             child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
//               Expanded(
//                   child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.all(0),
//                         backgroundColor: Colors.red,
//                       ),
//                       onPressed: () {
//                         global.textToSpeech(global.findLanguage(code: "cancel", languageCode: global.languageForCustomer));
//                         SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
//                         onClose();
//                       },
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.cancel),
//                           const SizedBox(
//                             width: 10,
//                           ),
//                           Text(global.language("cancel"))
//                         ],
//                       ))),
//               const SizedBox(
//                 width: 10,
//               ),
//               Expanded(
//                   child: ElevatedButton(
//                       onPressed: () async {
//                         double calcOptionAmount = 0;
//                         double calcDiscountAmount = totalCalc.totalDiscount;

//                         for (int optionIndex = 0; optionIndex < product.options.length; optionIndex++) {
//                           for (int choiceIndex = 0; choiceIndex < product.options[optionIndex].choices.length; choiceIndex++) {
//                             if (product.options[optionIndex].choices[choiceIndex].selected == true) {
//                               calcOptionAmount += product.options[optionIndex].choices[choiceIndex].amount;
//                             }
//                           }
//                         }
//                         if (isAppend) {
//                           // เพิ่มรายการใหม่
//                           await util.orderAdd(
//                               calcStockQty: product.isstockforrestaurant,
//                               context: context,
//                               barcode: product.barcode,
//                               qty: product.qty,
//                               optionamount: calcOptionAmount,
//                               discountamount: calcDiscountAmount,
//                               remark: product.remark,
//                               price: global.findProductPrice(
//                                 prices: product.prices,
//                               ),
//                               jsonOptions: jsonEncode(product.options),
//                               isexceptvat: product.isexceptvat,
//                               manufacturerguid: product.manufacturerguid);
//                         } else {
//                           // แก้ไขรายการเดิม
//                           if (global.deviceConfig.systemCondition == 1) {
//                             // กินก่อนจ่าย
//                             String querySelect = "select * from ${global.orderTempTableName()} where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderguid='$orderGuid'";
//                             var getOrderTemp = await api.clickHouseSelect(querySelect);
//                             ResponseDataModel responseData = ResponseDataModel.fromJson(getOrderTemp);
//                             if (responseData.data.isNotEmpty) {
//                               var optionselected = jsonEncode(product.options.map((e) => e.toJson()).toList());
//                               // คำนวณใหม่
//                               double amount = product.qty * product.setprice;
//                               // discount
//                               double discount = global.calcDiscount(amount: amount, discountWord: product.discountword);
//                               amount = amount - discount;
//                               double optionAmount = 0;
//                               double discountAmount = discount;
//                               if (product.options.isNotEmpty) {
//                                 for (var option in product.options) {
//                                   for (var choice in option.choices) {
//                                     if (choice.selected) {
//                                       double calcAmount = choice.priceValue * product.qty;
//                                       double discount = global.calcDiscount(amount: calcAmount, discountWord: choice.discountWord);
//                                       choice.discountAmount = discount;
//                                       choice.amount = calcAmount - discount;
//                                       optionAmount += choice.amount;
//                                       discountAmount += choice.discountAmount;
//                                     } else {
//                                       choice.amount = 0;
//                                       choice.discountAmount = 0;
//                                     }
//                                   }
//                                 }
//                               }
//                               amount += optionAmount;
//                               String query =
//                                   "alter table ${global.orderTempTableName()} update qty=${product.qty}, amount=$amount, optionamount=$optionAmount,  discountamount=$discountAmount, remark='${product.remark}',optionselected='$optionselected' where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderguid='$orderGuid'";
//                               await api.clickHouseExecute(query);
//                             }
//                           }
//                           if (global.deviceConfig.systemCondition == 2) {
//                             var getId = global.objectBoxStore // อัพเดทรายการเก่า
//                                 .box<OrderTempObjectBoxModel>()
//                                 .query(
//                                   OrderTempObjectBoxModel_.orderguid.equals(orderTemp!.orderguid),
//                                 )
//                                 .build()
//                                 .find();
//                             if (getId.isNotEmpty) {
//                               bool calcStockPass = true;
//                               if (calcStockQty) {
//                                 // ตรวจสอบยอดคงเหลือ
//                                 double oldQty = orderTemp.qty;
//                                 var getStockQty = await api.clickHouseSelect(
//                                     "select (sum(qty)+$oldQty)-${product.qty} as qty from ${global.clickHouseDatabaseName}.ordertempcalcqty where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and barcode='${orderTemp.barcode}'");
//                                 ResponseDataModel responseData = ResponseDataModel.fromJson(getStockQty);
//                                 if (responseData.data.isNotEmpty) {
//                                   double stockQty = double.tryParse(responseData.data[0]["qty"].toString()) ?? 0;
//                                   if (stockQty < 0) {
//                                     if (context.mounted) {
//                                       calcStockPass = false;
//                                       await showDialog(
//                                           context: context,
//                                           builder: (BuildContext context) {
//                                             return AlertDialog(
//                                               title: Text(global.language("unable_to_complete_transaction")),
//                                               content: Text(global.language("inventory_is_not_enough")),
//                                               actions: [
//                                                 TextButton(
//                                                   onPressed: () {
//                                                     Navigator.pop(context);
//                                                   },
//                                                   child: Text(global.language("confirm")),
//                                                 ),
//                                               ],
//                                             );
//                                           });
//                                     }
//                                   }
//                                 }
//                               }
//                               if (calcStockPass) {
//                                 OrderTempObjectBoxModel orderTempData = getId[0];
//                                 orderTempData.qty = product.qty;
//                                 orderTempData.optionselected = jsonEncode(product.options.map((e) => e.toJson()).toList());
//                                 orderTempData.remark = product.remark;
//                                 // คำนวณใหม่
//                                 double amount = product.qty * product.setprice;
//                                 // discount
//                                 double discount = global.calcDiscount(amount: amount, discountWord: product.discountword);
//                                 amount = amount - discount;
//                                 double optionAmount = 0;
//                                 double discountAmount = discount;
//                                 if (product.options.isNotEmpty) {
//                                   for (var option in product.options) {
//                                     for (var choice in option.choices) {
//                                       if (choice.selected) {
//                                         double calcAmount = choice.priceValue * product.qty;
//                                         double discount = global.calcDiscount(amount: calcAmount, discountWord: choice.discountWord);
//                                         choice.discountAmount = discount;
//                                         choice.amount = calcAmount - discount;
//                                         optionAmount += choice.amount;
//                                         discountAmount += choice.discountAmount;
//                                       } else {
//                                         choice.amount = 0;
//                                         choice.discountAmount = 0;
//                                       }
//                                     }
//                                   }
//                                 }
//                                 amount += optionAmount;
//                                 orderTempData.amount = amount;
//                                 orderTempData.optionamount = optionAmount;
//                                 orderTempData.discountamount = discountAmount;
//                                 // จ่ายก่อนกิน
//                                 global.objectBoxStore.box<OrderTempObjectBoxModel>().put(orderTempData, mode: PutMode.update);
//                                 if (calcStockQty) {
//                                   // update qty to server
//                                   await api.clickHouseExecute(
//                                       "alter table ${global.clickHouseDatabaseName}.ordertempcalcqty update qty=${product.qty * -1} where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderguid='${orderTempData.orderguid}'");
//                                 }
//                               }
//                             }
//                           }
//                         }
//                         global.textToSpeech(global.findLanguage(code: "confirm", languageCode: global.languageForCustomer));
//                         SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
//                         onClose();
//                       },
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.check),
//                           const SizedBox(
//                             width: 10,
//                           ),
//                           Text(global.language("confirm"))
//                         ],
//                       ))),
//             ])),
//       ]),
//     ),
//   );
// }

// Widget orderAnimationOneTempBody({required BuildContext context, required OrderTempDetailModel order, required Function onTab}) {
//   var product = global.productList.firstWhere((element) => element.barcode == order.barcode);
//   return Stack(children: [
//     SizedBox(
//         width: 100,
//         height: 100,
//         child: ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.all(4),
//               backgroundColor: Colors.white,
//               foregroundColor: Colors.black,
//             ),
//             onPressed: () {
//               onTab();
//             },
//             child: (product.imageuri.isNotEmpty)
//                 ? Column(
//                     children: [
//                       Expanded(child: CachedNetworkImage(fit: BoxFit.cover, imageUrl: product.imageuri)),
//                       Text(
//                         global.getNameFromLanguage(product.names, global.languageForCustomer),
//                         style: const TextStyle(fontSize: 12),
//                       ),
//                     ],
//                   )
//                 : Center(
//                     child: Text(
//                     global.getNameFromLanguage(product.names, global.languageForCustomer),
//                     style: const TextStyle(fontSize: 12),
//                   )))),
//     if (order.qty > 1)
//       Positioned(
//           top: 5,
//           right: 5,
//           child: SizedBox(
//             width: 25,
//             height: 25,
//             child: badges.Badge(
//                 badgeStyle: const badges.BadgeStyle(
//                   borderSide: BorderSide(color: Colors.white, width: 2),
//                 ),
//                 badgeContent: Center(
//                   child: Text(
//                     global.moneyFormat.format(order.qty),
//                     style: const TextStyle(color: Colors.white, fontSize: 10),
//                   ),
//                 )),
//           ))
//   ]);
// }
