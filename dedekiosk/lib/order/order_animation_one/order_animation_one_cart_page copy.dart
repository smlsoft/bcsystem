// import 'dart:async';
// import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:dedekiosk/bloc/category_bloc.dart';
// import 'package:dedekiosk/bloc/click_house_order_temp_bloc.dart';
// import 'package:dedekiosk/model/global_model.dart';
// import 'package:dedekiosk/model/product_model.dart';
// import 'package:dedekiosk/objectbox/objectbox.g.dart';
// import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
// import 'package:dedekiosk/order/order_animation_one/order_animation_one_util.dart';
// import 'package:dedekiosk/order/order_save.dart';
// import 'package:dedekiosk/order/order_standard/order_standard_product_option_page.dart';
// import 'package:dedekiosk/order/pay_discount.dart';
// import 'package:dedekiosk/util/print_queue.dart';
// import 'package:flutter/material.dart';
// import 'package:dedekiosk/global.dart' as global;
// import 'package:dedekiosk/order/order_util.dart' as util;
// import 'package:dedekiosk/util/api.dart' as api;
// import 'package:badges/badges.dart' as badges;
// import 'package:flutter/widgets.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class OrderAnimationOneCartPage extends StatefulWidget {
//   /// รหัสบาร์โค้ด โต๊ะ
//   final String barcode;

//   /// 0=จ่ายก่อนกิน,1=กินก่อนจ่าย,9=สรุปยอดกินก่อนจ่าย
//   final int mode;

//   const OrderAnimationOneCartPage({
//     super.key,
//     required this.barcode,
//     required this.mode,
//   });

//   @override
//   OrderAnimationOneCartPageState createState() => OrderAnimationOneCartPageState();
// }

// class OrderAnimationOneCartPageState extends State<OrderAnimationOneCartPage> {
//   double sumOrderAmount = 0;
//   double sumOrderQty = 0;
//   List<OrderTempDetailModel> orderTempDetailList = [];
//   late ProductProcessModel product;
//   late Timer screenTimer;
//   String discountWord = "";
//   double discountAmount = 0;
//   double roundAmount = 0;
//   double diffAmount = 0;
//   double vatAmount = 0;
//   double saveAmount = 0;
//   BillCalcAmount bill = BillCalcAmount();

//   @override
//   void initState() {
//     super.initState();
//     if (widget.barcode.isNotEmpty) {
//       product = global.productList[global.productList.indexWhere((element) => element.barcode == widget.barcode)];
//     }
//     reload();
//     screenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {});
//     });
//     global.textToSpeech(global.findLanguage(code: "order_in_cart_detail", languageCode: global.languageForCustomer));
//   }

//   @override
//   void dispose() {
//     screenTimer.cancel();
//     super.dispose();
//   }

//   void recalc() {
//     sumOrderQty = 0;
//     sumOrderAmount = 0;
//     saveAmount = 0;
//     for (var order in orderTempDetailList) {
//       sumOrderQty += order.qty;
//       sumOrderAmount += order.amount;
//       saveAmount += order.discountamount ?? 0;

//       if (order.is_except_vat == false) {
//         bill.totalItemVatAmount += order.amount;
//       } else {
//         bill.totalItemExceptVatAmount += order.amount;
//       }
//       bill.detailTotalAmount += order.amount;
//       bill.detailTotalAmountBeforeDiscount += order.amount;
//     }
//     for (var category in global.categoryList) {
//       for (var product in category.codelist) {
//         product.orderqty = 0;
//         for (var order in orderTempDetailList) {
//           if (product.barcode == order.barcode) {
//             product.orderqty = product.orderqty! + order.qty;
//           }
//         }
//       }
//     }
//     // ถ้าไม่มีรายการให้กลับ
//     var orderTempListWhere = (widget.barcode.isEmpty) ? orderTempDetailList : orderTempDetailList.where((element) => element.barcode == widget.barcode);
//     if (orderTempListWhere.isEmpty) {
//       if (mounted) {
//         Navigator.pop(context);
//       }
//     }
//     // discount
//     discountAmount = global.calcDiscount(amount: sumOrderAmount, discountWord: discountWord);
//     saveAmount += discountAmount;
//     // ปัดเศษ
//     roundAmount = global.roundMoneyForPay(sumOrderAmount - discountAmount);
//     diffAmount = roundAmount - (sumOrderAmount - discountAmount);
//     // vat
//     vatAmount = ((sumOrderAmount - (discountAmount - diffAmount)) * 7) / (7 + 100);

//     if (global.shopProfile!.orderstation.isvatregister) {
//       // จดทะเบียนภาษีมูลค่าเพิ่ม
//       if (global.shopProfile!.orderstation.vattype == 0) {
//         bill.amountAfterCalcVat = 0.0;
//         bill.detailTotalDiscount = 0.0;
//         bill.discountVatAmount = 0;
//         bill.totalDiscount = discountAmount;
//         // สินค้ามีภาษี (คำนวณภาษี)
//         double calcVatAmount = global.roundDouble((bill.discountVatAmount * global.shopProfile!.orderstation.vatrate) / (100 + global.shopProfile!.orderstation.vatrate), 2);
//         double calcDiscountVatAmount = bill.discountVatAmount - calcVatAmount;
//         // ยอดรวมสินค้ามีภาษีสุทธิ (หลังหักส่วนลด)
//         double amountAfterCalcVat = bill.totalItemVatAmount - (calcVatAmount + calcDiscountVatAmount);
//         // ส่วนลดสินค้ามีภาษี
//         bill.totalDiscountVatAmount = calcDiscountVatAmount + calcVatAmount;
//         // สินค้ายกเว้นภาษี
//         // ส่วนลดสินค้ายกเว้นภาษี
//         double calcDiscountExceptVatAmount = bill.detailTotalDiscount - (calcDiscountVatAmount + calcVatAmount);
//         double totalVatAmount = global.roundDouble((amountAfterCalcVat * global.shopProfile!.orderstation.vatrate) / (100 + global.shopProfile!.orderstation.vatrate), 2);
//         bill.shippingAmount = 0;
//         // ส่วนลดสินค้ายกเว้นภาษี
//         bill.totalDiscountExceptVatAmount = calcDiscountExceptVatAmount;
//         // สินค้ายกเว้นภาษีสุทธิ
//         bill.amountExceptVat = bill.totalItemExceptVatAmount - calcDiscountExceptVatAmount;
//         // มูลค่าก่อนคิดภาษี
//         bill.amountBeforeCalcVat = amountAfterCalcVat - totalVatAmount;
//         // คำนวณยอดภาษี
//         bill.totalVatAmount = totalVatAmount;
//         bill.amountAfterCalcVat = amountAfterCalcVat;
//         bill.totalAmountBeforeDiscount = (bill.amountAfterCalcVat + bill.amountExceptVat);
//         bill.totalAmountAfterDiscount = bill.totalAmountBeforeDiscount - bill.totalDiscount;
//         bill.roundAmount = global.roundDouble(global.roundMoneyForPay((bill.totalAmountBeforeDiscount + bill.shippingAmount) - bill.totalDiscount) - ((bill.totalAmountBeforeDiscount + bill.shippingAmount) - bill.totalDiscount), 2);
//         double total_after_round = (bill.totalAmountBeforeDiscount + bill.shippingAmount) - bill.totalDiscount + bill.roundAmount;
//         bill.diffAmount = total_after_round - ((bill.totalAmountBeforeDiscount + bill.shippingAmount) - bill.totalDiscount);

//         bill.saveAmount += bill.totalDiscount;
//         bill.saveAmount -= bill.diffAmount;

//         // รวมทั้งสิ้น
//         bill.totalAmount = (bill.totalAmountBeforeDiscount + bill.shippingAmount) + bill.diffAmount - bill.totalDiscount;
//       } else if (global.shopProfile!.orderstation.vattype == 1) {
//         bill.amountAfterCalcVat = 0.0;
//         bill.detailTotalDiscount = 0.0;
//         bill.discountVatAmount = 0;

//         double discountVatAmount = bill.detailTotalDiscount;
//         // ยอดรวมสินค้ามีภาษีสุทธิ (หลังหักส่วนลด)
//         double amountAfterCalcVat = bill.totalItemVatAmount - discountVatAmount;
//         // ส่วนลดสินค้ามีภาษี
//         bill.totalDiscountVatAmount = discountVatAmount;
//         // สินค้ายกเว้นภาษี
//         // ส่วนลดสินค้ายกเว้นภาษี
//         double calcDiscountExceptVatAmount = bill.detailTotalAmount - discountVatAmount;
//         double totalVatAmount = global.roundDouble((amountAfterCalcVat * (global.shopProfile!.orderstation.vatrate / 100)), 2);
//         // ส่วนลดสินค้ายกเว้นภาษี
//         bill.totalDiscountExceptVatAmount = 0;
//         // สินค้ายกเว้นภาษีสุทธิ
//         bill.amountExceptVat = bill.totalItemExceptVatAmount;
//         // มูลค่าก่อนคิดภาษี
//         bill.amountBeforeCalcVat = amountAfterCalcVat;
//         // คำนวณยอดภาษี
//         bill.shippingAmount = 0;
//         bill.totalVatAmount = totalVatAmount;
//         bill.amountAfterCalcVat = amountAfterCalcVat + totalVatAmount;

//         bill.totalAmountBeforeDiscount = (bill.amountAfterCalcVat + bill.amountExceptVat);
//         bill.totalDiscount = global.calcDiscount(amount: bill.totalAmountBeforeDiscount, discountWord: discountWord);
//         bill.roundAmount = global.roundDouble(global.roundMoneyForPay((bill.totalAmountBeforeDiscount + bill.shippingAmount) - bill.totalDiscount) - ((bill.totalAmountBeforeDiscount + bill.shippingAmount) - bill.totalDiscount), 2);
//         bill.totalAmountAfterDiscount = bill.totalAmountBeforeDiscount - bill.totalDiscount;
//         double total_after_round = (bill.totalAmountBeforeDiscount + bill.shippingAmount) - bill.totalDiscount + bill.roundAmount;

//         bill.diffAmount = total_after_round - ((bill.totalAmountBeforeDiscount + bill.shippingAmount) - bill.totalDiscount);

//         bill.saveAmount += bill.totalDiscount;
//         bill.saveAmount -= bill.diffAmount;
//         // รวมทั้งสิ้น
//         bill.totalAmount = (bill.totalAmountBeforeDiscount + bill.shippingAmount) + bill.diffAmount - bill.totalDiscount;
//       }
//     } else {
//       // ไม่จดทะเบียนภาษีมูลค่าเพิ่ม
//       bill.amountAfterCalcVat = 0.0;
//       bill.detailTotalDiscount = 0.0;
//       bill.discountVatAmount = 0;
//       bill.totalDiscount = discountAmount;
//       // สินค้ามีภาษี (คำนวณภาษี)
//       double calcVatAmount = 0;
//       double calcDiscountVatAmount = bill.discountVatAmount - calcVatAmount;
//       // ยอดรวมสินค้ามีภาษีสุทธิ (หลังหักส่วนลด)
//       double amountAfterCalcVat = bill.totalItemVatAmount - (calcVatAmount + calcDiscountVatAmount);
//       // ส่วนลดสินค้ามีภาษี
//       bill.totalDiscountVatAmount = calcDiscountVatAmount + calcVatAmount;
//       // สินค้ายกเว้นภาษี
//       // ส่วนลดสินค้ายกเว้นภาษี
//       double calcDiscountExceptVatAmount = bill.detailTotalDiscount - (calcDiscountVatAmount + calcVatAmount);
//       double totalVatAmount = 0;
//       bill.shippingAmount = 0;
//       // ส่วนลดสินค้ายกเว้นภาษี
//       bill.totalDiscountExceptVatAmount = calcDiscountExceptVatAmount;
//       // สินค้ายกเว้นภาษีสุทธิ
//       bill.amountExceptVat = bill.totalItemExceptVatAmount - calcDiscountExceptVatAmount;
//       // มูลค่าก่อนคิดภาษี
//       bill.amountBeforeCalcVat = amountAfterCalcVat - totalVatAmount;
//       // คำนวณยอดภาษี
//       bill.totalVatAmount = 0;
//       bill.amountAfterCalcVat = amountAfterCalcVat;
//       bill.totalAmountBeforeDiscount = (bill.amountAfterCalcVat + bill.amountExceptVat);

//       bill.roundAmount = global.roundDouble(global.roundMoneyForPay((bill.totalAmountBeforeDiscount + bill.shippingAmount) - bill.totalDiscount) - ((bill.totalAmountBeforeDiscount + bill.shippingAmount) - bill.totalDiscount), 2);
//       bill.totalAmountAfterDiscount = bill.totalAmountBeforeDiscount - bill.totalDiscount;
//       double total_after_round = (bill.totalAmountBeforeDiscount + bill.shippingAmount) - bill.totalDiscount + bill.roundAmount;
//       bill.diffAmount = total_after_round - ((bill.totalAmountBeforeDiscount + bill.shippingAmount) - bill.totalDiscount);

//       bill.saveAmount += bill.totalDiscount;
//       bill.saveAmount -= bill.diffAmount;

//       // รวมทั้งสิ้น
//       bill.totalAmount = (bill.totalAmountBeforeDiscount + bill.shippingAmount) + bill.diffAmount - bill.totalDiscount;
//     }
//   }

//   void reload() {
//     if (widget.mode == 9) {
//       // กินก่อนจ่าย ให้ไปดึงข้อมูลมาจาก server
//       // bloc
//       bill = BillCalcAmount();
//       context.read<ClickHouseOrderTempBloc>().add(ClickHouseOrderTempLoadStart(tableNumber: global.tableNumberSelected.ordertagnumber));
//     } else {
//       // จ่ายก่อนกินให้ดึงจาก objectbox
//       bill = BillCalcAmount();
//       api.getOrderTempFromObjectBox(barcode: "", isTakeAway: global.orderType).then((value) {
//         orderTempDetailList = value;
//         recalc();
//         setState(() {});
//       });
//     }
//   }

//   Future<void> updateDoc() async {
//     // update มูลค่าใหม่
//     String query = "SELECT * FROM ${global.orderTempTableName()} WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and ordertagnumber='${global.tableNumberSelected.ordertagnumber}' order by orderdatetime";
//     var result = await api.clickHouseSelect(query);
//     ResponseDataModel responseData = ResponseDataModel.fromJson(result);
//     double totalAmount = 0;
//     for (var data in responseData.data) {
//       totalAmount += double.tryParse(data["amount"].toString()) ?? 0;
//     }
//     await api.clickHouseExecute(
//         "alter table ${global.orderTempDocTableName()} update totalamount=$totalAmount where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and ordertagnumber='${global.tableNumberSelected.ordertagnumber}'");
//   }

//   Future<void> orderRemoveByOrderGuid({required String orderGuid, required Function refresh}) async {
//     if (widget.mode == 9) {
//       // สรุปยอดกินก่อนจ่าย
//       await api.clickHouseExecute("alter table ${global.orderTempTableName()} delete where shopid='${global.deviceConfig.shopId}' and orderguid='$orderGuid';");
//       await updateDoc();
//     } else {
//       int id = -1;
//       var getId = global.objectBoxStore
//           .box<OrderTempObjectBoxModel>()
//           .query(
//             OrderTempObjectBoxModel_.orderguid.equals(orderGuid),
//           )
//           .build()
//           .find();
//       if (getId.isNotEmpty) {
//         id = getId[0].id;
//       }
//       if (id != -1) {
//         if (widget.mode == 0) {
//           // จ่ายก่อนกิน
//           global.objectBoxStore.box<OrderTempObjectBoxModel>().remove(id);
//         }
//       }
//       // remove qty to server
//       api.clickHouseExecute("alter table ${global.clickHouseDatabaseName}.ordertempcalcqty delete where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderguid='$orderGuid'");
//     }
//     refresh();
//   }

//   /*Future<void> orderEdit(
//       {required BuildContext context,
//       required OrderTempDetailModel orderTemp,
//       required bool calcStockQty,
//       required Function refresh}) async {
//     int findProductIndex = global.productList
//         .indexWhere((element) => element.barcode == orderTemp.barcode);
//     var product = global.productList[findProductIndex];
//     if (orderTemp.optionselected.isNotEmpty) {
//       List<ProductProcessOptionModel> optionList =
//           (jsonDecode(orderTemp.optionselected) as List)
//               .map((e) => ProductProcessOptionModel.fromJson(e))
//               .toList();
//       product.options = optionList;
//     }
//     var result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//           builder: (context) => OrderStandardProductOptionPage(
//                 product: product,
//                 qty: orderTemp.qty,
//                 remark: orderTemp.remark,
//               )),
//     );
//     if (result != null) {
//       String remark = result['remark'];
//       double qty = result['qty'];
//       bool confirm = result['flag'];
//       remark = result['remark'];
//       if (confirm) {
//         // อัพเดทรายการเก่า
//         /*await api.clickHouseExecute(
//             "alter table ordertemp update qty=$qty,optionselected='$jsonOptions',remark='$remark' where shopid='${global.deviceConfig.shopId}' and orderguid='${orderTemp.orderguid}';");*/
//         var getId = global.objectBoxStore // อัพเดทรายการเก่า
//             .box<OrderTempObjectBoxModel>()
//             .query(
//               OrderTempObjectBoxModel_.orderguid.equals(orderTemp.orderguid),
//             )
//             .build()
//             .find();
//         if (getId.isNotEmpty) {
//           bool calcStockPass = true;
//           if (calcStockQty) {
//             // ตรวจสอบยอดคงเหลือ
//             double oldQty = orderTemp.qty;
//             var getStockQty = await api.clickHouseSelect(
//                 "select (sum(qty)+$oldQty)-$qty as qty from ordertempcalcqty where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and barcode='${orderTemp.barcode}'");
//             ResponseDataModel responseData =
//                 ResponseDataModel.fromJson(getStockQty);
//             if (responseData.data.isNotEmpty) {
//               double stockQty =
//                   double.tryParse(responseData.data[0]["qty"].toString()) ?? 0;
//               if (stockQty < 0) {
//                 if (context.mounted) {
//                   calcStockPass = false;
//                   await showDialog(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return AlertDialog(
//                           title: Text(global
//                               .language("unable_to_complete_transaction")),
//                           content:
//                               Text(global.language("inventory_is_not_enough")),
//                           actions: [
//                             TextButton(
//                               onPressed: () {
//                                 Navigator.pop(context);
//                               },
//                               child: Text(global.language("confirm")),
//                             ),
//                           ],
//                         );
//                       });
//                 }
//               }
//             }
//           }
//           if (calcStockPass) {
//             OrderTempObjectBoxModel orderTempData = getId[0];
//             orderTempData.qty = qty;
//             orderTempData.optionselected =
//                 jsonEncode(product.options.map((e) => e.toJson()).toList());
//             orderTempData.remark = remark;
//             // คำนวณใหม่
//             double amount = qty * product.setprice;
//             if (findProductIndex != -1) {
//               // discount
//               amount = amount -
//                   global.calcDiscount(
//                       amount: amount,
//                       discountWord:
//                           global.productList[findProductIndex].discountword);
//             }
//             if (product.options.isNotEmpty) {
//               for (var option in product.options) {
//                 for (var choice in option.choices) {
//                   if (choice.selected) {
//                     double calcAmount = choice.priceValue * qty;
//                     double discount = global.calcDiscount(
//                         amount: calcAmount, discountWord: choice.discountWord);
//                     amount += (calcAmount - discount);
//                   }
//                 }
//               }
//             }
//             orderTempData.amount = amount;
//             global.objectBoxStore
//                 .box<OrderTempObjectBoxModel>()
//                 .put(orderTempData, mode: PutMode.update);
//             if (calcStockQty) {
//               // update qty to server
//               api.clickHouseExecute(
//                   "alter table ${global.clickHouseDatabaseName}.ordertempcalcqty update qty=${qty * -1} where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderguid='${orderTempData.orderguid}'");
//             }
//           }
//         }
//       }
//       setState(() {});
//       refresh();
//     }
//   }*/

//   Widget orderTempBody({required BuildContext context, required OrderTempDetailModel order, required Function refresh}) {
//     int productIndex = global.productList.indexWhere((element) => element.barcode == order.barcode);
//     List<ProductProcessOptionModel> optionList = (order.optionselected.isNotEmpty) ? (jsonDecode(order.optionselected) as List).map((e) => ProductProcessOptionModel.fromJson(e)).toList() : [];
//     return Container(
//         padding: const EdgeInsets.all(4),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(
//             color: Colors.grey,
//             width: 1,
//           ),
//           borderRadius: BorderRadius.circular(4),
//         ),
//         width: 150,
//         child: Column(
//           children: [
//             if (global.orderShowImage && global.productList[productIndex].imageuri.isNotEmpty)
//               Image.network(
//                 global.productList[productIndex].imageuri,
//                 cacheWidth: 400,
//               ),
//             Text(global.getNameFromLanguage(global.productList[productIndex].names, global.languageForCustomer),
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 )),
//             for (var option in optionList)
//               for (var choice in option.choices)
//                 if (choice.selected)
//                   Row(
//                     children: [
//                       Expanded(child: Text("*${global.getNameFromLanguage(choice.names, global.languageForCustomer)}", style: const TextStyle(fontSize: 10, color: Colors.blue))),
//                       if (choice.priceValue > 0) Text("+${choice.amount} ${global.language("money_baht")}", style: const TextStyle(fontSize: 10, color: Colors.blue)),
//                     ],
//                   ),
//             if (order.remark.isNotEmpty) SizedBox(width: double.infinity, child: Text("${global.language("note")} : ${order.remark}", style: const TextStyle(fontSize: 10))),
//             RichText(
//               textAlign: TextAlign.center,
//               text: TextSpan(
//                 text: "${global.moneyFormat.format(order.qty)} ${global.getNameFromLanguage(global.productList[productIndex].unitnames, global.languageForCustomer)}${"/@${global.moneyFormat.format(order.price)}"}",
//                 style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
//                 children: <TextSpan>[
//                   TextSpan(text: "\n${global.language("total")} ${global.moneyFormat.format(order.amount)} ${global.language("money_baht")}", style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
//                 ],
//               ),
//             ),
//             Row(
//               children: [
//                 InkWell(
//                     splashColor: Colors.blue,
//                     onTap: () async {
//                       // แก้ไขรายการเดิม
//                       int findProductIndex = global.productList.indexWhere((element) => element.barcode == order.barcode);
//                       var product = global.productList[findProductIndex];
//                       product.qty = order.qty;
//                       product.remark = order.remark;
//                       product.options = [];
//                       if (order.optionselected.isNotEmpty) {
//                         List<dynamic> jsonOptions = jsonDecode(order.optionselected);
//                         for (var jsonOption in jsonOptions) {
//                           product.options.add(ProductProcessOptionModel.fromJson(jsonOption));
//                         }
//                       }
//                       await showDialog(
//                           barrierDismissible: false,
//                           context: context,
//                           builder: (BuildContext context) {
//                             return StatefulBuilder(builder: (context, StateSetter setState) {
//                               return AlertDialog(
//                                 contentPadding: const EdgeInsets.all(8),
//                                 content: StatefulBuilder(builder: (context, StateSetter setState) {
//                                   return orderAnimationOneProductOptionWidget(
//                                     orderGuid: order.orderguid,
//                                     orderTemp: order,
//                                     calcStockQty: product.isstockforrestaurant,
//                                     isAppend: false,
//                                     context: context,
//                                     product: product,
//                                     refresh: () {
//                                       if (widget.mode == 9) {
//                                         updateDoc();
//                                       }
//                                       setState(() {});
//                                     },
//                                     onClose: () async {
//                                       Navigator.pop(context);
//                                       refresh();
//                                     },
//                                   );
//                                 }),
//                               );
//                             });
//                           });
//                       /*await orderEdit(
//                           calcStockQty: global
//                               .productList[productIndex].isstockforrestaurant,
//                           context: context,
//                           orderTemp: order,
//                           refresh: refresh);*/
//                     },
//                     child: const Icon(
//                       Icons.edit,
//                       color: Colors.blue,
//                       size: 32,
//                     )),
//                 const Spacer(),
//                 InkWell(
//                     splashColor: Colors.blue,
//                     onTap: () async {
//                       await orderRemoveByOrderGuid(orderGuid: order.orderguid, refresh: refresh);
//                       int findProductIndex = global.productList.indexWhere((element) => element.barcode == order.barcode);
//                       if (findProductIndex != -1) {
//                         var product = global.productList[findProductIndex];
//                         String message = global.getNameFromLanguage(product.names, global.languageForCustomer);
//                         message += " ";
//                         message += global.findLanguage(code: "order_in_cart_remove_success", languageCode: global.languageForCustomer);
//                         global.textToSpeech(message);
//                       }
//                     },
//                     child: const Icon(
//                       Icons.delete,
//                       color: Colors.red,
//                       size: 32,
//                     )),
//               ],
//             ),
//           ],
//         ));
//   }

//   Widget orderNowList({required List<OrderTempDetailModel> orderTempList, required BuildContext context, required Function refresh}) {
//     List<Widget> orderList = [];
//     var headerStyle = TextStyle(fontSize: (global.isMobileScreen) ? 12 : 18, fontWeight: FontWeight.bold);
//     var detailStyle = TextStyle(fontSize: (global.isMobileScreen) ? 10 : 14);
//     List<int> expandedFlex = [2, 1, 1, 1];
//     orderList.add(Row(children: [
//       Expanded(
//         flex: expandedFlex[0],
//         child: Text(global.language("product_name"), style: headerStyle),
//       ),
//       Expanded(
//         flex: expandedFlex[1],
//         child: Text(global.language("qty"), style: headerStyle, textAlign: TextAlign.right),
//       ),
//       Expanded(
//         flex: expandedFlex[2],
//         child: Text(global.language("price"), style: headerStyle, textAlign: TextAlign.right),
//       ),
//       Expanded(
//         flex: expandedFlex[3],
//         child: Text(global.language("total_amount"), style: headerStyle, textAlign: TextAlign.right),
//       ),
//     ]));
//     for (var order in orderTempList) {
//       var optionList = (order.optionselected.isNotEmpty) ? (jsonDecode(order.optionselected) as List).map((e) => ProductProcessOptionModel.fromJson(e)).toList() : [];
//       orderList.add(Row(children: [
//         Expanded(
//             flex: expandedFlex[0],
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(global.getNameFromLanguage(global.productList[global.productList.indexWhere((element) => element.barcode == order.barcode)].names, global.languageForCustomer), style: detailStyle),
//                 if (optionList.isNotEmpty)
//                   for (var option in optionList)
//                     for (var choice in option.choices)
//                       if (choice.selected)
//                         Text(
//                             "*${global.getNameFromLanguage(choice.names, global.languageForCustomer)}${(choice.priceValue > 0) ? " ${global.language("add_money")} ${global.moneyFormat.format(choice.priceValue - global.calcDiscount(amount: choice.priceValue, discountWord: choice.discountWord))} ${global.language("money_baht")}" : ""}",
//                             style: detailStyle.apply(color: Colors.blue)),
//                 if (order.remark.isNotEmpty) Text("${global.language("note")} : ${order.remark}", style: detailStyle),
//               ],
//             )),
//         Expanded(
//             flex: expandedFlex[1],
//             child: Text("${global.moneyFormat.format(order.qty)} ${global.getNameFromLanguage(global.productList[global.productList.indexWhere((element) => element.barcode == order.barcode)].unitnames, global.languageForCustomer)}",
//                 style: detailStyle, textAlign: TextAlign.right)),
//         Expanded(
//           flex: expandedFlex[2],
//           child: Text(global.moneyFormatAndDot.format(order.price), style: detailStyle, textAlign: TextAlign.right),
//         ),
//         Expanded(
//           flex: expandedFlex[3],
//           child: (order.optionamount == 0)
//               ? Text(global.moneyFormatAndDot.format(order.amount), style: detailStyle, textAlign: TextAlign.right)
//               : RichText(
//                   textAlign: TextAlign.right,
//                   text: TextSpan(
//                     text: global.moneyFormatAndDot.format(order.amount),
//                     style: detailStyle,
//                     children: <TextSpan>[
//                       TextSpan(text: "+${global.moneyFormatAndDot.format(order.optionamount)}", style: detailStyle.apply(color: Colors.red)),
//                       TextSpan(text: "\n=${global.moneyFormatAndDot.format(order.amount)}", style: detailStyle.apply(color: Colors.blue))
//                     ],
//                   ),
//                 ),
//         ),
//       ]));
//     }
//     orderList.add(Row(children: [
//       Expanded(
//         flex: expandedFlex[0],
//         child: Container(),
//       ),
//       Expanded(
//         flex: expandedFlex[1],
//         child: Container(),
//       ),
//       Expanded(
//         flex: expandedFlex[2],
//         child: Text(global.language("total_amount"), style: headerStyle, textAlign: TextAlign.right),
//       ),
//       Expanded(
//         flex: expandedFlex[3],
//         child: Text("${global.moneyFormatAndDot.format(sumOrderAmount)} ${global.language("money_baht")}", style: headerStyle, textAlign: TextAlign.right),
//       ),
//     ]));
//     if (widget.mode == 0 || widget.mode == 9) {
//       if (global.shopProfile!.orderstation.isvatregister) {
//         // จดทะเบียนภาษีมูลค่าเพิ่ม
//         if (bill.totalItemVatAmount != 0) {
//           orderList.add(Row(children: [
//             Expanded(
//               flex: expandedFlex[0],
//               child: Container(),
//             ),
//             Expanded(
//               flex: expandedFlex[1] + expandedFlex[2],
//               child: Text("${global.language("total_item_vat_amount")} ", style: headerStyle, textAlign: TextAlign.right),
//             ),
//             Expanded(
//               flex: expandedFlex[3],
//               child: Text("${global.moneyFormatAndDot.format(bill.totalItemVatAmount)} ${global.language("money_baht")}", style: headerStyle, textAlign: TextAlign.right),
//             ),
//           ]));
//         }

//         if (bill.amountBeforeCalcVat != 0) {
//           orderList.add(Row(children: [
//             Expanded(
//               flex: expandedFlex[0],
//               child: Container(),
//             ),
//             Expanded(
//               flex: expandedFlex[1] + expandedFlex[2],
//               child: Text("${global.language("before_vat")} ", style: headerStyle, textAlign: TextAlign.right),
//             ),
//             Expanded(
//               flex: expandedFlex[3],
//               child: Text("${global.moneyFormatAndDot.format(bill.amountBeforeCalcVat)} ${global.language("money_baht")}", style: headerStyle, textAlign: TextAlign.right),
//             ),
//           ]));
//         }

//         if (bill.totalItemExceptVatAmount != 0) {
//           orderList.add(Row(children: [
//             Expanded(
//               flex: expandedFlex[0],
//               child: Container(),
//             ),
//             Expanded(
//               flex: expandedFlex[1] + expandedFlex[2],
//               child: Text("${global.language("total_item_except_vat_amount")} ", style: headerStyle, textAlign: TextAlign.right),
//             ),
//             Expanded(
//               flex: expandedFlex[3],
//               child: Text("${global.moneyFormatAndDot.format(bill.totalItemExceptVatAmount)} ${global.language("money_baht")}", style: headerStyle, textAlign: TextAlign.right),
//             ),
//           ]));
//         }
//         if (bill.totalVatAmount != 0) {
//           orderList.add(Row(children: [
//             Expanded(
//               flex: expandedFlex[0],
//               child: Container(),
//             ),
//             Expanded(
//               flex: expandedFlex[1] + expandedFlex[2],
//               child: Text("${global.language("vat")} : ${global.moneyFormat.format(global.shopProfile!.orderstation.vatrate)}%", style: headerStyle, textAlign: TextAlign.right),
//             ),
//             Expanded(
//               flex: expandedFlex[3],
//               child: Text("${global.moneyFormatAndDot.format(bill.totalVatAmount)} ${global.language("money_baht")}", style: headerStyle, textAlign: TextAlign.right),
//             ),
//           ]));
//         }
//         if (bill.amountAfterCalcVat != 0) {
//           orderList.add(Row(children: [
//             Expanded(
//               flex: expandedFlex[0],
//               child: Container(),
//             ),
//             Expanded(
//               flex: expandedFlex[1] + expandedFlex[2],
//               child: Text(global.language("after_vat"), style: headerStyle, textAlign: TextAlign.right),
//             ),
//             Expanded(
//               flex: expandedFlex[3],
//               child: Text("${global.moneyFormatAndDot.format(bill.amountAfterCalcVat)} ${global.language("money_baht")}", style: headerStyle, textAlign: TextAlign.right),
//             ),
//           ]));
//         }
//       }
//       if (bill.totalDiscount != 0) {
//         orderList.add(Row(children: [
//           Expanded(
//             flex: expandedFlex[0],
//             child: Container(),
//           ),
//           Expanded(
//             flex: expandedFlex[1] + expandedFlex[2],
//             child: Text("${global.language("discount")} : $discountWord", style: headerStyle, textAlign: TextAlign.right),
//           ),
//           Expanded(
//             flex: expandedFlex[3],
//             child: Text("${global.moneyFormatAndDot.format(bill.totalDiscount)} ${global.language("money_baht")}", style: headerStyle, textAlign: TextAlign.right),
//           ),
//         ]));
//         orderList.add(Row(children: [
//           Expanded(
//             flex: expandedFlex[0],
//             child: Container(),
//           ),
//           Expanded(
//             flex: expandedFlex[1] + expandedFlex[2],
//             child: Text("ยอดรวมหลังหักส่วนลด", style: headerStyle, textAlign: TextAlign.right),
//           ),
//           Expanded(
//             flex: expandedFlex[3],
//             child: Text("${global.moneyFormatAndDot.format(bill.totalAmountBeforeDiscount - bill.totalDiscount)} ${global.language("money_baht")}", style: headerStyle, textAlign: TextAlign.right),
//           ),
//         ]));
//       }
//       if (bill.shippingAmount != 0) {
//         orderList.add(Row(children: [
//           Expanded(
//             flex: expandedFlex[0],
//             child: Container(),
//           ),
//           Expanded(
//             flex: expandedFlex[1] + expandedFlex[2],
//             child: Text(global.language("shipping_cost"), style: headerStyle, textAlign: TextAlign.right),
//           ),
//           Expanded(
//             flex: expandedFlex[3],
//             child: Text("${global.moneyFormatAndDot.format(bill.shippingAmount)} ${global.language("money_baht")}", style: headerStyle, textAlign: TextAlign.right),
//           ),
//         ]));
//       }
//       if (bill.diffAmount != 0) {
//         orderList.add(Row(children: [
//           Expanded(
//             flex: expandedFlex[0],
//             child: Container(),
//           ),
//           Expanded(
//             flex: expandedFlex[1] + expandedFlex[2],
//             child: Text(global.language("round_money"), style: headerStyle, textAlign: TextAlign.right),
//           ),
//           Expanded(
//             flex: expandedFlex[3],
//             child: Text("${global.moneyFormatAndDot.format(bill.diffAmount)} ${global.language("money_baht")}", style: headerStyle, textAlign: TextAlign.right),
//           ),
//         ]));
//       }
//       orderList.add(Container(
//           width: double.infinity,
//           decoration: const BoxDecoration(
//             border: Border(
//               top: BorderSide(color: Colors.grey, width: 1),
//               bottom: BorderSide(color: Colors.grey, width: 1),
//             ),
//           ),
//           child: Row(children: [
//             Expanded(
//               flex: expandedFlex[0],
//               child: Container(),
//             ),
//             Expanded(
//               flex: expandedFlex[1] + expandedFlex[2],
//               child: Text(global.language("ยอดชำระเงิน"), style: headerStyle, textAlign: TextAlign.right),
//             ),
//             Expanded(
//               flex: expandedFlex[3],
//               child: Text("${global.moneyFormatAndDot.format(bill.totalAmount)} ${global.language("money_baht")}", style: headerStyle, textAlign: TextAlign.right),
//             ),
//           ])));
//       if (bill.saveAmount != 0) {
//         orderList.add(Row(children: [
//           Expanded(
//             flex: expandedFlex[0],
//             child: Container(),
//           ),
//           Expanded(
//             flex: expandedFlex[1] + expandedFlex[2],
//             child: Text(global.language("save_amount"), style: headerStyle, textAlign: TextAlign.right),
//           ),
//           Expanded(
//             flex: expandedFlex[3],
//             child: Text("${global.moneyFormatAndDot.format(bill.saveAmount)} ${global.language("money_baht")}", style: headerStyle, textAlign: TextAlign.right),
//           ),
//         ]));
//       }
//     }
//     var orderTempListWhere = (widget.barcode.isEmpty) ? orderTempList : orderTempList.where((element) => element.barcode == widget.barcode);
//     return SingleChildScrollView(
//         child: Container(
//             margin: const EdgeInsets.only(top: 10),
//             width: double.infinity,
//             color: Colors.white,
//             child: Column(
//               children: [
//                 (orderTempListWhere.isEmpty)
//                     ? Text("ไม่มีรายการ${(widget.barcode.isEmpty) ? "" : " ${global.getNameFromLanguage(product.names, global.languageForCustomer)}"}")
//                     : Wrap(children: orderTempListWhere.map((e) => orderTempBody(context: context, order: e, refresh: refresh)).toList()),
//                 Container(
//                     color: Colors.white,
//                     margin: const EdgeInsets.only(top: 10),
//                     padding: const EdgeInsets.only(bottom: 10, top: 10, left: 10, right: 10),
//                     child: Column(
//                       children: orderList,
//                     )),
//                 if (global.deviceConfig.machineCondition == 0 && widget.barcode.isEmpty && (widget.mode == 0 || widget.mode == 9))
//                   Container(
//                       width: double.infinity,
//                       color: Colors.cyan.shade100,
//                       padding: const EdgeInsets.only(left: 10, right: 10),
//                       child: Row(
//                         children: [
//                           ElevatedButton(
//                             onPressed: () async {
//                               var result = await showDialog(
//                                   context: context,
//                                   builder: (BuildContext context) {
//                                     return AlertDialog(title: Text("${global.language("total_money")} ${global.moneyFormatAndDot.format(bill.totalAmount)} ${global.language("money_baht")}"), content: PayDiscountWidget(amount: sumOrderAmount));
//                                   });
//                               if (result != null) {
//                                 discountWord = result;
//                               }
//                               reload();
//                             },
//                             child: (discountWord.isEmpty) ? Text(global.language("discount")) : Text("${global.language("discount")} : $discountWord"),
//                           ),
//                           const Spacer(),
//                           ElevatedButton(
//                             onPressed: () async {
//                               // พิมพ์ที่เครื่องตัวเอง
//                               PayResultModel payResult = PayResultModel();
//                               payResult.discountAmount = discountAmount;
//                               payResult.diffAmount = diffAmount;
//                               payResult.discountWord = discountWord;
//                               payResult.saveAmount = saveAmount;
//                               payResult.vatAmount = vatAmount;
//                               payResult.totalAmount = sumOrderAmount - (discountAmount - diffAmount);
//                               global.printQueue.add(PrintTicketClass(
//                                   docDate: DateTime.now(),
//                                   docNumber: "สรุป",
//                                   orderTagNumber: "",
//                                   orderId: "",
//                                   printType: 0,
//                                   printLogo: false,
//                                   orderType: global.orderType,
//                                   printHeader: false,
//                                   orderTempDetails: [],
//                                   queueNumber: 0,
//                                   saveToFile: true,
//                                   footer: "",
//                                   orderList: orderTempDetailList,
//                                   printerLocalConfig: global.deviceConfig.printerForOrderStation,
//                                   payResult: payResult,
//                                   openCashDrawer: false,
//                                   qrCode: ""));
//                               // พิมพ์เลย
//                               printQueueWorker();
//                             },
//                             child: const Text("พิมพ์ใบสรุป"),
//                           ),
//                         ],
//                       ))
//               ],
//             )));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<ClickHouseOrderTempBloc, ClickHouseOrderTempState>(
//       listener: (context, state) {
//         if (state is ClickHouseOrderTempLoadSuccess) {
//           context.read<ClickHouseOrderTempBloc>().add(ClickHouseOrderTempLoadFinish());
//           orderTempDetailList.clear();
//           for (var order in state.clickHouseOrderTemp) {
//             for (var detail in order.orderDetails) {
//               orderTempDetailList.add(detail);
//             }
//           }
//           recalc();
//           setState(() {});
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           title: Row(
//             children: [
//               IconButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 icon: const Icon(Icons.arrow_back_ios),
//               ),
//               Text((widget.barcode.isEmpty) ? global.language("order_list") : global.getNameFromLanguage(product.names, global.languageForCustomer)),
//             ],
//           ),
//         ),
//         body: Column(
//           children: [
//             Expanded(
//               child: orderNowList(context: context, orderTempList: orderTempDetailList, refresh: reload),
//             ),
//             Container(
//               padding: const EdgeInsets.all(8),
//               width: double.infinity,
//               height: 70,
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Expanded(
//                     flex: 1,
//                     child: ElevatedButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(Icons.arrow_back_ios),
//                             Text(global.language("back"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                           ],
//                         )),
//                   ),
//                   const SizedBox(
//                     width: 10,
//                   ),
//                   if (widget.barcode.isEmpty)
//                     Expanded(
//                         flex: 2,
//                         child: ElevatedButton(
//                             onPressed: () async {
//                               if (widget.mode == 0 || widget.mode == 9) {
//                                 // จ่ายก่อนกิน หรือ กินก่อนจ่าย (ชำระเงิน)
//                                 global.textToSpeech(global.findLanguage(code: "please_select_serve_number_service", languageCode: global.languageForCustomer));
//                                 String orderTagNumber = "";
//                                 if (widget.mode == 0) {
//                                   // เลือก โต๊ะ หรือ ป้ายบริการ
//                                   orderTagNumber = await global.selectOrderTagNumberOrTableNumber(context: context);
//                                 } else {
//                                   orderTagNumber = global.tableNumberSelected.ordertagnumber;
//                                 }
//                                 String message = "";
//                                 if (orderTagNumber.isNotEmpty) {
//                                   message = "${global.findLanguage(code: "select_serve_number", languageCode: global.languageForCustomer)} $orderTagNumber";
//                                 }
//                                 message += " ";
//                                 message += global.findLanguage(code: "total_money", languageCode: global.languageForCustomer);
//                                 message += " ";
//                                 message += global.moneyFormat.format(sumOrderAmount - (discountAmount - diffAmount));
//                                 message += " ";
//                                 message += global.findLanguage(code: "money_baht", languageCode: global.languageForCustomer);
//                                 message += " ";
//                                 message += global.findLanguage(code: "select_pay_type", languageCode: global.languageForCustomer);
//                                 global.textToSpeech(message);
//                                 if (context.mounted && (orderTagNumber.isNotEmpty || global.orderTagNumbers.isEmpty)) {
//                                   await payAndSave(
//                                       totalAmount: sumOrderAmount - (discountAmount - diffAmount),
//                                       vatAmount: vatAmount,
//                                       saveAmount: saveAmount,
//                                       discountAmount: discountAmount,
//                                       discountWord: discountWord,
//                                       diffAmount: diffAmount,
//                                       orderTagNumber: orderTagNumber,
//                                       context: context,
//                                       payNow: true,
//                                       orderTempDetailList: orderTempDetailList,
//                                       bill: bill);
//                                 }
//                               }
//                               if (widget.mode == 1) {
//                                 // กินก่อนจ่าย (Hold รายการ) ไม่แสดงหน้าจ่ายเงิน
//                                 if (context.mounted) {
//                                   await payAndSave(
//                                       totalAmount: sumOrderAmount - (discountAmount - diffAmount),
//                                       vatAmount: vatAmount,
//                                       saveAmount: saveAmount,
//                                       discountAmount: discountAmount,
//                                       discountWord: discountWord,
//                                       diffAmount: diffAmount,
//                                       orderTagNumber: global.tableNumberSelected.ordertagnumber,
//                                       context: context,
//                                       payNow: false,
//                                       orderTempDetailList: orderTempDetailList,
//                                       bill: bill);
//                                 }
//                               }
//                             },
//                             child: Container(
//                               width: double.infinity,
//                               padding: const EdgeInsets.all(4),
//                               child: FittedBox(
//                                 fit: BoxFit.fitWidth,
//                                 child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//                                   badges.Badge(
//                                     position: badges.BadgePosition.topEnd(top: -2, end: -2),
//                                     badgeContent: Text(
//                                       global.moneyFormat.format(sumOrderQty),
//                                       style: const TextStyle(color: Colors.white, fontSize: 12),
//                                     ),
//                                     child: const Icon(
//                                       Icons.payment,
//                                       size: 32,
//                                     ),
//                                   ),
//                                   const SizedBox(
//                                     width: 15,
//                                   ),
//                                   (widget.mode == 0 || widget.mode == 9)
//                                       ? Text(
//                                           '${global.language("payment_amount")} : ${global.moneyFormatAndDot.format(bill.totalAmount)} ${global.language("money_baht")}',
//                                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                                         )
//                                       : Text(
//                                           '${global.language("total_amount")} : ${global.moneyFormatAndDot.format(bill.totalAmount)} ${global.language("money_baht")}',
//                                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                                         ),
//                                 ]),
//                               ),
//                             ))),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
