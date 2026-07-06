import 'dart:convert';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:dedekiosk/objectbox/objectbox.g.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/order/order_util.dart' as util;
import 'package:flutter/services.dart';

Widget orderAnimationOneProductOptionWidget({
  required BuildContext context,
  required Function refresh,
  required ProductProcessModel product,
  required bool isAppend,
  required bool calcStockQty,
  required String orderGuid,
  OrderTempDetailModel? orderTemp,
  required Function() onClose,
}) {
  // คงลอจิกเดิมไว้ทั้งหมด
  TextEditingController textEditingController = TextEditingController()..text = product.remark;
  TotalCalculateModel totalCalc = global.calcProductAndOption(product);

  // สร้างรูปแบบปุ่มเพิ่ม/ลด
  final quantityButtonStyle = ElevatedButton.styleFrom(
    shape: const CircleBorder(),
    padding: const EdgeInsets.all(8),
    elevation: 2,
  );

  List<Widget> optionList = [];

  List<Widget> MainList = [];

  // ส่วนข้อมูลสินค้าและราคา
  optionList.add(
    Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ข้อมูลสินค้าและราคา
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ชื่อสินค้า
                Text(
                  global.getNameFromLanguage(product.names, global.languageForCustomer),
                  style: TextStyle(
                    fontSize: (global.isMobileScreen) ? 16 : 24,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // ราคา
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                  // decoration: BoxDecoration(
                  //   color: Colors.blue.shade50,
                  //   borderRadius: BorderRadius.circular(20),
                  // ),
                  child: Text(
                    "${global.language("price")} ${global.moneyFormatAndDot.format(product.setprice)} ${global.language("money_baht")}",
                    style: TextStyle(
                      fontSize: (global.isMobileScreen) ? 14 : 18,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // ส่วนลด (ถ้ามี)
                if (product.discountword.isNotEmpty && global.priceIndex == 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                    // decoration: BoxDecoration(
                    //   color: Colors.red.shade50,
                    //   borderRadius: BorderRadius.circular(20),
                    // ),
                    child: Text(
                      "${global.language("discount")} ${product.discountword} = -${global.moneyFormatAndDot.format(global.calcDiscount(amount: product.setprice, discountWord: product.discountword))} ${global.language("money_baht")}",
                      style: TextStyle(
                        fontSize: (global.isMobileScreen) ? 12 : 16,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // ราคาหลังส่วนลด
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                    // decoration: BoxDecoration(
                    //   color: Colors.green.shade50,
                    //   borderRadius: BorderRadius.circular(20),
                    // ),
                    child: Text(
                      "${global.language("price_after_discount")} ${global.moneyFormatAndDot.format(product.setprice - global.calcDiscount(amount: product.setprice, discountWord: product.discountword))} ${global.language("money_baht")}",
                      style: TextStyle(
                        fontSize: (global.isMobileScreen) ? 14 : 18,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // รูปภาพสินค้า
          if (product.imageuri.isNotEmpty)
            Container(
              width: (global.isMobileScreen) ? 100 : 150,
              height: (global.isMobileScreen) ? 100 : 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  product.imageuri,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.image_not_supported,
                    size: 14,
                    color: Colors.grey.shade200,
                  ),
                  cacheWidth: 400,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  // ตัวเลือกสินค้า
  for (int optionIndex = 0; optionIndex < product.options.length; optionIndex++) {
    bool isOneChoice = (product.options[optionIndex].choicetype == 1 || product.options[optionIndex].maxselect == 1);

    optionList.add(
      Container(
        margin: const EdgeInsets.only(bottom: 3),
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            // หัวข้อตัวเลือก
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    isOneChoice ? Icons.radio_button_checked : Icons.check_box,
                    color: Colors.blue.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: global.getNameFromLanguage(
                              product.options[optionIndex].names,
                              global.languageForCustomer,
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: (product.options[optionIndex].choicetype == 1)
                                ? global.language("choose_one")
                                : "${global.language("many_choices")} ${global.language("maximum")} ${product.options[optionIndex].maxselect} ${global.language("choice")}",
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // รายการตัวเลือก
            Container(
              margin: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (int choiceIndex = 0; choiceIndex < product.options[optionIndex].choices.length; choiceIndex++)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        backgroundColor: (product.options[optionIndex].choices[choiceIndex].selected) ? Colors.blue.shade50 : Colors.white,
                        elevation: (product.options[optionIndex].choices[choiceIndex].selected) ? 1 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                          side: BorderSide(
                            color: (product.options[optionIndex].choices[choiceIndex].selected) ? Colors.blue.shade300 : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      onPressed: () {
                        // คงลอจิกการเลือกตัวเลือกสินค้าไว้เหมือนเดิม
                        if (isOneChoice) {
                          // ยกเลิกการเลือกทั้งหมด
                          if (product.options[optionIndex].choices[choiceIndex].selected) {
                            product.options[optionIndex].choices[choiceIndex].selected = false;
                            product.options[optionIndex].choices[choiceIndex].amount = 0;
                          } else {
                            for (int choiceIndex = 0; choiceIndex < product.options[optionIndex].choices.length; choiceIndex++) {
                              product.options[optionIndex].choices[choiceIndex].selected = false;
                              product.options[optionIndex].choices[choiceIndex].amount = 0;
                            }
                            product.options[optionIndex].choices[choiceIndex].selected = true;
                            product.options[optionIndex].choices[choiceIndex].amount =
                                global.calcProductOptionAmount(choices: product.options[optionIndex].choices, qty: product.qty);
                            global.textToSpeech(global.getNameFromLanguage(product.options[optionIndex].choices[choiceIndex].names, global.languageForCustomer));
                          }
                        } else {
                          if (product.options[optionIndex].choices[choiceIndex].selected) {
                            // ยกเลิกการเลือก
                            product.options[optionIndex].choices[choiceIndex].selected = false;
                            product.options[optionIndex].choices[choiceIndex].amount = 0;
                          } else {
                            int selectedCount = 0;
                            for (int choiceIndex = 0; choiceIndex < product.options[optionIndex].choices.length; choiceIndex++) {
                              if (product.options[optionIndex].choices[choiceIndex].selected == true) {
                                selectedCount++;
                              }
                            }
                            int maxSelect = (product.options[optionIndex].choicetype == 1) ? 1 : product.options[optionIndex].maxselect;
                            if (selectedCount < maxSelect) {
                              // น้อยกว่า maxselect ที่กำหนดไว้ จึงเลือกได้
                              product.options[optionIndex].choices[choiceIndex].selected = true;
                              // คำนวณ amount สำหรับ choice นี้โดยเฉพาะ (ไม่ใช่ยอดรวมทุก choice)
                              double choiceAmount = product.options[optionIndex].choices[choiceIndex].priceValue * product.qty;
                              print("choiceAmount=$choiceAmount");
                              double choiceDiscount = global.calcDiscount(amount: choiceAmount, discountWord: product.options[optionIndex].choices[choiceIndex].discountWord);
                              product.options[optionIndex].choices[choiceIndex].amount = choiceAmount - choiceDiscount;
                              global.textToSpeech(global.getNameFromLanguage(product.options[optionIndex].choices[choiceIndex].names, global.languageForCustomer));
                            }
                          }
                        }
                        refresh();
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // รูปภาพของตัวเลือก (ถ้ามี)
                          if (product.options[optionIndex].choices[choiceIndex].imageuri != "")
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(bottom: 8),
                              // decoration: BoxDecoration(
                              //   borderRadius: BorderRadius.circular(8),
                              //   border: Border.all(
                              //     color: (product.options[optionIndex].choices[choiceIndex].selected) ? Colors.blue.shade300 : Colors.grey.shade300,
                              //   ),
                              // ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  product.options[optionIndex].choices[choiceIndex].imageuri,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ),

                          // ข้อมูลตัวเลือก
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ไอคอนแสดงการเลือก
                              Icon(
                                (product.options[optionIndex].choices[choiceIndex].selected == true)
                                    ? (isOneChoice ? Icons.radio_button_checked : Icons.check_box)
                                    : (isOneChoice ? Icons.radio_button_unchecked : Icons.check_box_outline_blank),
                                size: 16,
                                color: (product.options[optionIndex].choices[choiceIndex].selected == true) ? Colors.blue.shade700 : Colors.grey.shade700,
                              ),

                              const SizedBox(width: 4),

                              // ชื่อและราคาของตัวเลือก
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    global.getNameFromLanguage(product.options[optionIndex].choices[choiceIndex].names, global.languageForCustomer),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                      fontWeight: (product.options[optionIndex].choices[choiceIndex].selected == true) ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),

                                  // ราคาเพิ่มเติม (ถ้ามี)
                                  if (product.options[optionIndex].choices[choiceIndex].priceValue != 0)
                                    Text(
                                      "+${global.moneyFormat.format(product.options[optionIndex].choices[choiceIndex].priceValue)} ${global.language("money_baht")}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                  // ส่วนลดของตัวเลือก (ถ้ามี)
                                  if (product.options[optionIndex].choices[choiceIndex].priceValue != 0 &&
                                      product.options[optionIndex].choices[choiceIndex].discountWord.isNotEmpty &&
                                      global.priceIndex == 1)
                                    Text(
                                      "${global.language("discount")} ${product.options[optionIndex].choices[choiceIndex].discountWord} = ${global.moneyFormat.format(product.options[optionIndex].choices[choiceIndex].priceValue - global.calcDiscount(amount: product.options[optionIndex].choices[choiceIndex].priceValue, discountWord: product.options[optionIndex].choices[choiceIndex].discountWord))} ${global.language("money_baht")}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ช่องหมายเหตุ
  optionList.add(
    Container(
      padding: const EdgeInsets.all(2),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note_alt, size: 18),
              const SizedBox(width: 8),
              Text(
                global.language("note"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (value) => product.remark = value,
            autofocus: false,
            controller: textEditingController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              hintText: global.language("add_note_here"),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            maxLines: 3,
          ),
        ],
      ),
    ),
  );

  MainList.add(
    Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: optionList,
        ),
      ),
    ),
  );

  // สรุปยอด
  Widget summaryWidget = Card(
    elevation: 2,
    margin: EdgeInsets.only(bottom: (global.isMobileScreen) ? 8 : 16),
    color: Colors.green.shade50,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: BorderSide(color: Colors.green.shade200),
    ),
    child: Padding(
      padding: EdgeInsets.all((global.isMobileScreen) ? 10 : 15),
      child: Column(
        children: [
          // หัวข้อ
          Row(
            children: [
              Icon(Icons.receipt_long, size: (global.isMobileScreen) ? 18 : 20, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                global.language("order_summary"),
                style: TextStyle(
                  fontSize: (global.isMobileScreen) ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),

          SizedBox(height: (global.isMobileScreen) ? 8 : 12),

          // รายละเอียดสรุป
          Container(
            padding: EdgeInsets.all((global.isMobileScreen) ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                // จำนวนสินค้า
                if (totalCalc.qty > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${global.language("qty")}:",
                        style: TextStyle(
                          fontSize: (global.isMobileScreen) ? 12 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${global.moneyFormat.format(totalCalc.qty)} ${global.getNameFromLanguage(product.unitnames, global.languageForCustomer)}",
                        style: TextStyle(
                          fontSize: (global.isMobileScreen) ? 12 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),

                // ยอดรวม
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${global.language("total")}:",
                      style: TextStyle(
                        fontSize: (global.isMobileScreen) ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${global.moneyFormatAndDot.format(totalCalc.totalAmount)} ${global.language("money_baht")}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),

                // ส่วนลด (ถ้ามี)
                if (product.discountword.isNotEmpty && global.priceIndex == 1) ...[
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${global.language("discount")} ${product.discountword}:",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "-${global.moneyFormatAndDot.format(totalCalc.totalDiscount)} ${global.language("money_baht")}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${global.language("amount_after_discount")}:",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${global.moneyFormatAndDot.format(totalCalc.totalAmount - totalCalc.totalDiscount)} ${global.language("money_baht")}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
  // ปุ่มปรับจำนวน
  Widget quantityWidget = Card(
    elevation: 0,
    margin: EdgeInsets.only(bottom: (global.isMobileScreen) ? 8 : 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: EdgeInsets.all((global.isMobileScreen) ? 10 : 16),
      child: Row(
        children: [
          // ข้อความแสดงจำนวน (ซ่อนบนมือถือ)
          if (!global.isMobileScreen)
            Text(
              global.language("qty"),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ปุ่มลด
                ElevatedButton(
                  style: quantityButtonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey.shade300;
                      }
                      return Colors.red.shade600;
                    }),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    padding: MaterialStateProperty.all(EdgeInsets.all((global.isMobileScreen) ? 8 : 12)),
                  ),
                  onPressed: product.qty > 1
                      ? () {
                          product.qty--;
                          refresh();
                          String message = global.findLanguage(code: "reduce", languageCode: global.languageForCustomer);
                          message += " ";
                          message += global.findLanguage(code: "is", languageCode: global.languageForCustomer);
                          message += " ";
                          message += global.findLanguage(code: "qty", languageCode: global.languageForCustomer);
                          message += " ";
                          message += "${global.moneyFormat.format(product.qty)} ${global.getNameFromLanguage(product.unitnames, global.languageForCustomer)}";
                          global.textToSpeech(message);
                        }
                      : null,
                  child: Icon(Icons.remove, size: (global.isMobileScreen) ? 20 : 24),
                ),

                // แสดงจำนวน
                Container(
                  margin: EdgeInsets.symmetric(horizontal: (global.isMobileScreen) ? 8 : 16),
                  padding: EdgeInsets.symmetric(
                    horizontal: (global.isMobileScreen) ? 14 : 20,
                    vertical: (global.isMobileScreen) ? 8 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    global.moneyFormat.format(product.qty),
                    style: TextStyle(
                      fontSize: (global.isMobileScreen) ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // ปุ่มเพิ่ม
                ElevatedButton(
                  style: quantityButtonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(Colors.green.shade600),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    padding: MaterialStateProperty.all(EdgeInsets.all((global.isMobileScreen) ? 8 : 12)),
                  ),
                  onPressed: () {
                    product.qty++;
                    refresh();
                    String message = global.findLanguage(code: "more", languageCode: global.languageForCustomer);
                    message += " ";
                    message += global.findLanguage(code: "is", languageCode: global.languageForCustomer);
                    message += " ";
                    message += global.findLanguage(code: "qty", languageCode: global.languageForCustomer);
                    message += " ";
                    message += "${global.moneyFormat.format(product.qty)} ${global.getNameFromLanguage(product.unitnames, global.languageForCustomer)}";
                    global.textToSpeech(message);
                  },
                  child: Icon(Icons.add, size: (global.isMobileScreen) ? 20 : 24),
                ),
              ],
            ),
          ),

          // ข้อความหน่วย (ซ่อนบนมือถือ)
          if (!global.isMobileScreen)
            Text(
              global.getNameFromLanguage(product.unitnames, global.languageForCustomer),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    ),
  );

  // ปุ่มยกเลิก/ยืนยัน
  Widget actionButtons = Row(
    children: [
      // ปุ่มยกเลิก
      Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: (global.isMobileScreen) ? 12 : 16),
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            global.textToSpeech(global.findLanguage(code: "cancel", languageCode: global.languageForCustomer));
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
            onClose();
          },
          icon: const Icon(Icons.cancel),
          label: Text(
            global.language("cancel"),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      const SizedBox(width: 16),

      // ปุ่มยืนยัน
      Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: (global.isMobileScreen) ? 12 : 16),
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            try {
              // คงลอจิกการประมวลผลเมื่อกดปุ่มยืนยันไว้เหมือนเดิม
              double calcOptionAmount = 0;
              double calcDiscountAmount = totalCalc.totalDiscount;

              for (int optionIndex = 0; optionIndex < product.options.length; optionIndex++) {
                for (int choiceIndex = 0; choiceIndex < product.options[optionIndex].choices.length; choiceIndex++) {
                  if (product.options[optionIndex].choices[choiceIndex].selected == true) {
                    calcOptionAmount += (product.options[optionIndex].choices[choiceIndex].amount);
                  }
                }
              }

              if (isAppend) {
                // เพิ่มรายการใหม่
                await util.orderAdd(
                    calcStockQty: product.isstockforrestaurant,
                    context: context,
                    barcode: product.barcode,
                    qty: product.qty,
                    optionamount: calcOptionAmount,
                    discountamount: calcDiscountAmount,
                    remark: product.remark,
                    price: global.findProductPrice(
                      prices: product.prices,
                    ),
                    jsonOptions: jsonEncode(product.options),
                    isexceptvat: product.isexceptvat,
                    manufacturerguid: product.manufacturerguid);
              } else {
                // แก้ไขรายการเดิม
                // if (global.deviceConfig.systemCondition == 1) {
                //   // กินก่อนจ่าย
                //   String querySelect = "select * from ${global.orderTempTableName()} where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderguid='$orderGuid'";
                //   var getOrderTemp = await api.clickHouseSelect(querySelect);
                //   ResponseDataModel responseData = ResponseDataModel.fromJson(getOrderTemp);

                //   if (responseData.data.isNotEmpty) {
                //     var optionselected = jsonEncode(product.options.map((e) => e.toJson()).toList());

                //     // คำนวณใหม่
                //     double amount = product.qty * product.setprice;

                //     // discount
                //     double discount = global.calcDiscount(amount: amount, discountWord: product.discountword) * product.qty;
                //     amount = amount - discount;
                //     double optionAmount = 0;
                //     double discountAmount = discount;

                //     if (product.options.isNotEmpty) {
                //       for (var option in product.options) {
                //         for (var choice in option.choices) {
                //           if (choice.selected) {
                //             double calcAmount = choice.priceValue * product.qty;
                //             double discount = global.calcDiscount(amount: calcAmount, discountWord: choice.discountWord);
                //             choice.discountAmount = discount;
                //             choice.amount = calcAmount - discount;
                //             optionAmount += (choice.amount * product.qty);
                //             discountAmount += choice.discountAmount;
                //           } else {
                //             choice.amount = 0;
                //             choice.discountAmount = 0;
                //           }
                //         }
                //       }
                //     }

                //     amount += optionAmount;
                //     String query =
                //         "alter table ${global.orderTempTableName()} update qty=${product.qty}, amount=$amount, optionamount=$optionAmount, discountamount=$discountAmount, remark='${product.remark}',optionselected='$optionselected' where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderguid='$orderGuid'";
                //     await api.clickHouseExecute(query);
                //   }
                // }

                if (global.deviceConfig.systemCondition == 2) {
                  var getId = global.objectBoxStore
                      .box<OrderTempObjectBoxModel>()
                      .query(
                        OrderTempObjectBoxModel_.orderguid.equals(orderTemp!.orderguid),
                      )
                      .build()
                      .find();

                  if (getId.isNotEmpty) {
                    bool calcStockPass = true;

                    if (calcStockQty) {
                      // ตรวจสอบยอดคงเหลือ
                      try {
                        double oldQty = orderTemp.qty;
                        var getStockQty = await api.clickHouseSelect(
                            "select (sum(qty)+$oldQty)-${product.qty} as qty from ${global.clickHouseDatabaseName}.ordertempcalcqty where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and barcode='${orderTemp.barcode}'");
                        ResponseDataModel responseData = ResponseDataModel.fromJson(getStockQty);

                        if (responseData.data.isNotEmpty) {
                          double stockQty = double.tryParse(responseData.data[0]["qty"].toString()) ?? 0;
                          if (stockQty < 0) {
                            if (context.mounted) {
                              calcStockPass = false;
                              await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(global.language("unable_to_complete_transaction")),
                                      content: Text(global.language("inventory_is_not_enough")),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(global.language("confirm")),
                                        ),
                                      ],
                                    );
                                  });
                            }
                          }
                        }
                      } catch (e, s) {
                        Logger.e('Stock check error', error: e, stackTrace: s);
                        global.sendErrorToDevTeam("Stock check error: $e");
                        calcStockPass = false;
                      }
                    }
                    if (calcStockPass) {
                      try {
                        OrderTempObjectBoxModel orderTempData = getId[0];
                        orderTempData.qty = product.qty;
                        orderTempData.optionselected = jsonEncode(product.options.map((e) => e.toJson()).toList());
                        orderTempData.remark = product.remark;

                        // คำนวณใหม่ - ใช้ findProductPrice เพื่อรองรับ priceIndex (ราคาสมาชิก)
                        double productPrice = global.findProductPrice(prices: product.prices);
                        double amount = product.qty * productPrice;

                        // discount
                        double discount = global.calcDiscount(amount: amount, discountWord: product.discountword) * product.qty;
                        amount = amount - discount;
                        double optionAmount = 0;
                        double discountAmount = discount;

                        if (product.options.isNotEmpty) {
                          for (var option in product.options) {
                            for (var choice in option.choices) {
                              if (choice.selected) {
                                double calcAmount = choice.priceValue * product.qty;
                                double discount = global.calcDiscount(amount: calcAmount, discountWord: choice.discountWord);
                                choice.discountAmount = discount;
                                choice.amount = calcAmount - discount;
                                optionAmount += choice.amount;
                                discountAmount += choice.discountAmount;
                              } else {
                                choice.amount = 0;
                                choice.discountAmount = 0;
                              }
                            }
                          }
                        }

                        amount += optionAmount;
                        orderTempData.amount = amount;
                        orderTempData.optionamount = optionAmount;
                        orderTempData.discountamount = discountAmount;

                        // จ่ายก่อนกิน
                        global.objectBoxStore.box<OrderTempObjectBoxModel>().put(orderTempData, mode: PutMode.update);

                        if (calcStockQty) {
                          // update qty to server
                          await api.clickHouseExecute(
                              "alter table ${global.clickHouseDatabaseName}.ordertempcalcqty update qty=${product.qty * -1} where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderguid='${orderTempData.orderguid}'");
                        }
                      } catch (e, s) {
                        Logger.e('Order update error', error: e, stackTrace: s);
                        global.sendErrorToDevTeam("Order update error: $e");
                      }
                    }
                  }
                }
              }

              global.textToSpeech(global.findLanguage(code: "confirm", languageCode: global.languageForCustomer));
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
              onClose();
            } catch (e, s) {
              Logger.e('Order confirm error', error: e, stackTrace: s);
              global.sendErrorToDevTeam("Order confirm error: $e");
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(global.language("error")),
                    content: Text(global.language("order_failed")),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(global.language("ok")),
                      ),
                    ],
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.check),
          label: Text(
            global.language("confirm"),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );

  return Container(
    width: (global.isMobileScreen) ? double.infinity : 600,
    padding: const EdgeInsets.all(16),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ข้อมูลสินค้าและราคา
          ...MainList,
          // ปุ่มปรับจำนวน
          quantityWidget,
          // สรุปยอด
          summaryWidget,

          // ปุ่มยกเลิก/ยืนยัน
          actionButtons,
        ],
      ),
    ),
  );
}

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
