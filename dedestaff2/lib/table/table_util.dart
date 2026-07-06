import 'package:dedeorder/global.dart' as global;
import 'package:dedeorder/model/pos_hold_process_model.dart';
import 'package:dedeorder/model/pos_process_model.dart';
import 'package:flutter/material.dart';

/// แยกประเภท 0=อาหาร 1=เครื่องดื่ม
List<Widget> tableProcessByTypeWidget(
    PosProcessModel processResult, type, double totalAmount) {
  TextStyle textStyle = TextStyle(fontSize: global.orderFontSize);
  List<Widget> previewList = [];
  double qtyCount = 0;
  // รวมรายการ
  List<PosProcessDetailModel> detailList = [];
  for (var detail in processResult.details) {
    if (type == detail.food_type) {
      // ค้นหารายการเดิมที่มีอยู่แล้ว
      bool found = false;
      int index = -1;
      for (int i = 0; i < detailList.length; i++) {
        bool compareExtra = true;
        if (detail.extra.length != detailList[i].extra.length) {
          compareExtra = false;
        } else {
          for (int j = 0; j < detail.extra.length; j++) {
            if (detail.extra[j].item_code != detailList[i].extra[j].item_code) {
              compareExtra = false;
              break;
            }
          }
        }
        if (detailList[i].barcode == detail.barcode &&
            detailList[i].unit_code == detail.unit_code &&
            detailList[i].price == detail.price &&
            detailList[i].discount == detail.discount &&
            compareExtra) {
          found = true;
          index = i;
          break;
        }
      }
      if (found) {
        detailList[index].qty += detail.qty;
        detailList[index].total_amount += detail.total_amount;
      } else {
        // clone รายการใหม่
        detailList.add(PosProcessDetailModel(
            guid: detail.guid,
            index: detail.index,
            barcode: detail.barcode,
            item_code: detail.item_code,
            item_name: detail.item_name,
            unit_code: detail.unit_code,
            unit_name: detail.unit_name,
            qty: detail.qty,
            price: detail.price,
            price_original: detail.price_original,
            discount_text: detail.discount_text,
            discount: detail.discount,
            total_amount: detail.total_amount,
            total_amount_with_extra: detail.total_amount_with_extra,
            is_void: detail.is_void,
            remark: detail.remark,
            image_url: detail.image_url,
            price_exclude_vat_type: detail.price_exclude_vat_type,
            is_except_vat: detail.is_except_vat,
            vat_type: detail.vat_type,
            price_exclude_vat: detail.price_exclude_vat,
            food_type: detail.food_type,
            extra: List<PosProcessDetailExtraModel>.from(detail.extra)));
      }
    }
  }
  for (var detail in detailList) {
    double orderQty = detail.qty;
    qtyCount += detail.qty;
    previewList.add(Row(
      children: [
        Expanded(
            flex: 3,
            child: Text(
              "${global.getNameFromJsonLanguage(detail.item_name, global.userLanguage)}/${global.getNameFromJsonLanguage(detail.unit_name, global.userLanguage)}",
              style: textStyle,
            )),
        Expanded(
            flex: 1,
            child: Text(
              global.moneyFormatAndDot.format(detail.qty),
              textAlign: TextAlign.right,
              style: textStyle,
            )),
        Expanded(
            flex: 1,
            child: Text(
              global.moneyFormatAndDot.format(detail.price),
              textAlign: TextAlign.right,
              style: textStyle,
            )),
        Expanded(
            flex: 1,
            child: Text(
              global.moneyFormatAndDot.format(detail.total_amount),
              textAlign: TextAlign.right,
              style: textStyle,
            ))
      ],
    ));
    for (var option in detail.extra) {
      TextStyle textStyle = const TextStyle(
          fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blue);
      previewList.add(Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(
                "  ${global.getNameFromJsonLanguage(option.item_name, global.userLanguage)}",
                style: textStyle,
              )),
          Expanded(
              flex: 1,
              child: (orderQty == 0)
                  ? Container()
                  : Text(
                      global.moneyFormatAndDot.format(orderQty),
                      textAlign: TextAlign.right,
                      style: textStyle,
                    )),
          Expanded(
              flex: 1,
              child: Text(
                global.moneyFormatAndDot.format(option.price),
                textAlign: TextAlign.right,
                style: textStyle,
              )),
          Expanded(
              flex: 1,
              child: Text(
                global.moneyFormatAndDot.format(option.total_amount * orderQty),
                textAlign: TextAlign.right,
                style: textStyle,
              ))
        ],
      ));
    }
  }
  if (qtyCount != 0) {
    previewList.add(Row(children: [
      Expanded(
          flex: 3,
          child: Text(
            global.getNameFromLanguage(
                global.productTypeLists[type].name, "th"),
            style: TextStyle(
                fontSize: global.orderFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.green),
          )),
      Expanded(
          flex: 1,
          child: Text(
            global.moneyFormatAndDot.format(qtyCount),
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: global.orderFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.green),
          )),
      Expanded(
        flex: 1,
        child: Container(),
      ),
      Expanded(
          flex: 1,
          child: Text(
            global.moneyFormatAndDot.format(totalAmount),
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: global.orderFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.green),
          ))
    ]));
    previewList.add(
      const Divider(
        height: 1,
        color: Colors.black,
      ),
    );
  }
  return previewList;
}

Widget tableProcessWidget(PosProcessModel processResult) {
  List<Widget> previewList = [];
  previewList.add(Row(children: [
    Expanded(
        flex: 3,
        child: Text(
          "รายละเอียดอาหาร/เครื่องดื่ม",
          style: TextStyle(
              fontSize: global.orderFontSize * 1.2,
              fontWeight: FontWeight.bold),
        )),
    Expanded(
        flex: 1,
        child: Text(
          "จำนวน",
          textAlign: TextAlign.right,
          style: TextStyle(
              fontSize: global.orderFontSize * 1.2,
              fontWeight: FontWeight.bold),
        )),
    Expanded(
        flex: 1,
        child: Text(
          "ราคา",
          textAlign: TextAlign.right,
          style: TextStyle(
              fontSize: global.orderFontSize * 1.2,
              fontWeight: FontWeight.bold),
        )),
    Expanded(
        flex: 1,
        child: Text(
          "รวมเงิน",
          softWrap: false,
          textAlign: TextAlign.right,
          style: TextStyle(
              fontSize: global.orderFontSize * 1.2,
              fontWeight: FontWeight.bold),
        ))
  ]));
  List<int> typeList = [];
  for (var detail in processResult.details) {
    if (!typeList.contains(detail.food_type)) {
      typeList.add(detail.food_type);
    }
  }
  for (var type in typeList) {
    double totalAmount = 0;
    switch (type) {
      case 0:
        totalAmount = processResult.total_food_amount;
        break;
      case 1:
        totalAmount = processResult.total_drink_amount;
        break;
      case 2:
        totalAmount = processResult.total_alcohol_amount;
        break;
      default:
        totalAmount = processResult.total_other_amount;
        break;
    }
    previewList
        .addAll(tableProcessByTypeWidget(processResult, type, totalAmount));
  }
  if (processResult.detail_total_discount != 0) {
    previewList.add(Row(children: [
      Expanded(
          flex: 5,
          child: Text(
            "ยอดรวมอาหาร (ก่อนส่วนลด)",
            style: TextStyle(
                fontSize: global.orderFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.green),
          )),
      Expanded(flex: 1, child: Container()),
      Expanded(
          flex: 1,
          child: Text(
            global.moneyFormatAndDot.format(processResult.total_food_amount),
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: global.orderFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.green),
          ))
    ]));
    previewList.add(Row(children: [
      Expanded(
          flex: 5,
          child: Text(
            "ส่วนลดเฉพาะอาหาร : ${processResult.detail_discount_formula}",
            style: TextStyle(fontSize: global.orderFontSize),
          )),
      Expanded(flex: 1, child: Container()),
      Expanded(
          flex: 1,
          child: Text(
            global.moneyFormatAndDot
                .format(processResult.detail_total_discount),
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: global.orderFontSize),
          ))
    ]));
  }
  if (processResult.total_vat_amount != 0) {
    previewList.add(Row(children: [
      Expanded(
          flex: 5,
          child: Text(
            "ยอดก่อนภาษี",
            style:
                TextStyle(fontSize: global.orderFontSize, color: Colors.blue),
          )),
      Expanded(flex: 1, child: Container()),
      Expanded(
          flex: 1,
          child: Text(
            global.moneyFormatAndDot
                .format(processResult.amount_before_calc_vat),
            textAlign: TextAlign.right,
            style:
                TextStyle(fontSize: global.orderFontSize, color: Colors.blue),
          ))
    ]));
    previewList.add(Row(children: [
      Expanded(
          flex: 5,
          child: Text(
            "ภาษีมูลค่าเพิ่ม ${global.moneyFormat.format(processResult.vat_rate)}%",
            style:
                TextStyle(fontSize: global.orderFontSize, color: Colors.blue),
          )),
      Expanded(flex: 1, child: Container()),
      Expanded(
          flex: 1,
          child: Text(
            global.moneyFormatAndDot.format(processResult.total_vat_amount),
            textAlign: TextAlign.right,
            style:
                TextStyle(fontSize: global.orderFontSize, color: Colors.blue),
          ))
    ]));
  }
  previewList.add(Row(children: [
    Expanded(
        flex: 5,
        child: Text(
          "รวมทั้งสิ้น",
          style: TextStyle(
              fontSize: global.orderFontSize, fontWeight: FontWeight.bold),
        )),
    Expanded(flex: 1, child: Container()),
    Expanded(
        flex: 1,
        child: Text(
          global.moneyFormatAndDot.format(processResult.total_amount),
          textAlign: TextAlign.right,
          style: TextStyle(
              fontSize: global.orderFontSize, fontWeight: FontWeight.bold),
        ))
  ]));
  if (processResult.cash_round_amount != 0) {
    previewList.add(Row(children: [
      Expanded(
          flex: 5,
          child: Text(
            "ยอดปัดเศษ",
            style:
                TextStyle(fontSize: global.orderFontSize, color: Colors.blue),
          )),
      Expanded(flex: 1, child: Container()),
      Expanded(
          flex: 1,
          child: Text(
            global.moneyFormatAndDot.format(processResult.cash_round_amount),
            textAlign: TextAlign.right,
            style:
                TextStyle(fontSize: global.orderFontSize, color: Colors.blue),
          ))
    ]));
    previewList.add(
      const Divider(
        height: 1,
        color: Colors.black,
      ),
    );
    previewList.add(Row(children: [
      Expanded(
          flex: 5,
          child: Text(
            "ยอดชำระ",
            style: TextStyle(
                fontSize: global.orderFontSize,
                color: Colors.blue,
                fontWeight: FontWeight.bold),
          )),
      Expanded(flex: 1, child: Container()),
      Expanded(
          flex: 1,
          child: Text(
            global.moneyFormatAndDot.format(processResult.total_amount_pay),
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: global.orderFontSize,
                color: Colors.blue,
                fontWeight: FontWeight.bold),
          ))
    ]));
  }
  previewList.add(const SizedBox(height: 10));
  return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: previewList,
      ));
}
