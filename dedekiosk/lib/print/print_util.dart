import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:dedekiosk/print/print.dart' as print;
import 'package:dedekiosk/global.dart' as global;
import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:intl/intl.dart';

Future<void> printTicket(
    {required String docNumber,
    required DateTime docDate,
    required int queueNumber,
    required String orderTagNumber,
    required String header,
    required bool printLogo,
    required bool saveToFile,
    required bool printHeader,
    required List<OrderTempDetailModel> orderList,
    required PrinterLocalConfigModel printerConfig,
    required PayResultModel payResult,
    required bool openCashDrawer,
    required String qrCode,
    String memberPinCode = "",
    bool isBCMember = false}) async {
  // Guard: Check if shopProfile is available for printing header
  if (printHeader && global.shopProfile == null) {
    global.sendErrorToDevTeam("printTicket error: shopProfile is null");
    return;
  }

  double totalFoodAmount = 0;
  double totalDrinkAmount = 0;
  double fontSizeScale = (printerConfig.paperType == 2) ? 1.0 : 0.75;

  // printerIndex 1 = Ticket Printer
  print.PrinterClass printerData = print.PrinterClass(printerIndex: 1, qrCode: qrCode, openCashDrawer: openCashDrawer);

  // Reset Printer
  printerData.addCommand(print.PosPrintBillCommandModel(mode: 0));
  if (printHeader) {
    if (global.logoUrl.isNotEmpty) {
      // พิมพ์ Logo
      io.File file = io.File(global.getPosLogoPathName());
      if (file.existsSync()) {
        Uint8List bytes = file.readAsBytesSync();
        ui.Image getImage = await decodeImageFromList(bytes);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
          targetHeight: (getImage.height).toInt(),
          targetWidth: (getImage.width).toInt(),
        );
        final frame = await codec.getNextFrame();
        final image = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        bytes = image!.buffer.asUint8List();
        printerData.addCommand(print.PosPrintBillCommandModel(mode: 1, image: bytes));
      }
    }
    if (global.shopProfile!.orderstation.isvatregister) {
      // หัวเอกสาร
      if (global.shopProfile!.orderstation.branch.pos.headerreceiptpos.isNotEmpty) {
        printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: false), columns: [
          print.PosPrintBillCommandColumnModel(
              fontSize: 24 * fontSizeScale, width: 1, text: global.shopProfile!.orderstation.branch.pos.headerreceiptpos, align: global.PrintColumnAlign.center)
        ]));
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(
            fontSize: 18 * fontSizeScale,
            width: 1,
            text:
                "${global.shopProfile!.orderstation.branch.companynames![0].name} (${global.shopProfile!.orderstation.branch.names![0].name}:${global.shopProfile!.orderstation.branch.code})",
            align: global.PrintColumnAlign.center)
      ]));
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(
            fontSize: 18 * fontSizeScale,
            width: 1,
            text: (global.shopProfile!.orderstation.branch.contact!.address!.isNotEmpty) ? global.shopProfile!.orderstation.branch.contact!.address![0].name : "",
            align: global.PrintColumnAlign.center)
      ]));
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(
            fontSize: 24 * fontSizeScale,
            width: 1,
            text: global.findLanguage(code: "receipt_tax_invoice", languageCode: global.countryCodes[0]),
            align: global.PrintColumnAlign.center)
      ]));
      // กรณีภาษีที่สั่ง ไม่ตรงกับภาษา แรกของระบบ ให้พิมพ์ภาษาที่ลูกค้าเลือกด้วย
      if (global.languageForCustomer != global.countryCodes[0]) {
        printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
          print.PosPrintBillCommandColumnModel(
              fontSize: 24 * fontSizeScale,
              width: 1,
              text: global.findLanguage(code: "receipt_tax_invoice", languageCode: global.languageForCustomer),
              align: global.PrintColumnAlign.center)
        ]));
      }

      printerData.addCommand(
        print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
          print.PosPrintBillCommandColumnModel(
              fontSize: 16 * fontSizeScale,
              width: 1,
              text: (global.shopProfile!.orderstation.vattype == 0)
                  ? global.findLanguage(code: "price_includes_vat", languageCode: global.countryCodes[0])
                  : global.findLanguage(code: "price_non_vat", languageCode: global.countryCodes[0]),
              align: global.PrintColumnAlign.left),
          print.PosPrintBillCommandColumnModel(fontSize: 16 * fontSizeScale, width: 1, text: "POS : ${global.deviceConfig.orderStationCode}", align: global.PrintColumnAlign.right)
        ]),
      );
      // กรณีภาษีที่สั่ง ไม่ตรงกับภาษา แรกของระบบ ให้พิมพ์ภาษาที่ลูกค้าเลือกด้วย
      if (global.languageForCustomer != global.countryCodes[0]) {
        printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
          print.PosPrintBillCommandColumnModel(
              fontSize: 16 * fontSizeScale,
              width: 1,
              text: (global.shopProfile!.orderstation.vattype == 0)
                  ? global.findLanguage(code: "price_includes_vat", languageCode: global.languageForCustomer)
                  : global.findLanguage(code: "price_non_vat", languageCode: global.languageForCustomer),
              align: global.PrintColumnAlign.left),
          print.PosPrintBillCommandColumnModel(fontSize: 16 * fontSizeScale, width: 1, text: "POS : ${global.deviceConfig.orderStationCode}", align: global.PrintColumnAlign.right)
        ]));
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(
            fontSize: 16 * fontSizeScale,
            width: 1,
            text: (global.shopProfile!.orderstation.branch.pos.taxid.isEmpty) ? "" : "TAX#${global.shopProfile!.orderstation.branch.pos.taxid}",
            align: global.PrintColumnAlign.left),
        print.PosPrintBillCommandColumnModel(fontSize: 16 * fontSizeScale, width: 1, text: "", align: global.PrintColumnAlign.right)
      ]));
    }
  }
  printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
    print.PosPrintBillCommandColumnModel(fontSize: 18 * fontSizeScale, width: 1, text: docNumber, align: global.PrintColumnAlign.left),
    print.PosPrintBillCommandColumnModel(fontSize: 18 * fontSizeScale, width: 1, text: DateFormat("dd/MM/yyyy - HH:mm").format(docDate), align: global.PrintColumnAlign.right)
  ]));
  // รายละเอียดสินค้า
  printerData.addCommand(print.PosPrintBillCommandModel(mode: 3));
  printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
    print.PosPrintBillCommandColumnModel(
        fontSize: 24 * fontSizeScale, width: 5, text: global.findLanguage(code: "product_name", languageCode: global.countryCodes[0]), align: global.PrintColumnAlign.left),
    print.PosPrintBillCommandColumnModel(
        fontSize: 24 * fontSizeScale, width: 2, text: global.findLanguage(code: "qty", languageCode: global.countryCodes[0]), align: global.PrintColumnAlign.right),
    print.PosPrintBillCommandColumnModel(
        fontSize: 24 * fontSizeScale, width: 2, text: global.findLanguage(code: "money_amount", languageCode: global.countryCodes[0]), align: global.PrintColumnAlign.right)
  ]));
  // กรณีภาษีที่สั่ง ไม่ตรงกับภาษา แรกของระบบ ให้พิมพ์ภาษาที่ลูกค้าเลือกด้วย
  if (global.languageForCustomer != global.countryCodes[0]) {
    printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
      print.PosPrintBillCommandColumnModel(
          fontSize: 24 * fontSizeScale, width: 5, text: global.findLanguage(code: "product_name", languageCode: global.languageForCustomer), align: global.PrintColumnAlign.left),
      print.PosPrintBillCommandColumnModel(
          fontSize: 24 * fontSizeScale, width: 2, text: global.findLanguage(code: "qty", languageCode: global.languageForCustomer), align: global.PrintColumnAlign.right),
      print.PosPrintBillCommandColumnModel(
          fontSize: 24 * fontSizeScale, width: 2, text: global.findLanguage(code: "money_amount", languageCode: global.languageForCustomer), align: global.PrintColumnAlign.right)
    ]));
  }
  //
  printerData.addCommand(print.PosPrintBillCommandModel(mode: 3));
  //
  for (var detail in orderList) {
    int productIndex = global.productList.indexWhere((element) => element.barcode == detail.barcode);
    var product = global.productList[productIndex];
    {
      // รายละเอียดสินค้า
      if (product.foodtype == 0) {
        totalFoodAmount += detail.amount;
      } else {
        totalDrinkAmount += detail.amount;
      }
      String productName = "${global.getNameFromLanguage(product.names, global.countryCodes[0])}/${global.getNameFromLanguage(product.unitnames, global.countryCodes[0])}";
      if (global.languageForCustomer != global.countryCodes[0]) {
        productName =
            "$productName - ${global.getNameFromLanguage(product.names, global.languageForCustomer)}/${global.getNameFromLanguage(product.unitnames, global.languageForCustomer)}";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 32 * fontSizeScale, width: 5, text: productName, align: global.PrintColumnAlign.left),
        print.PosPrintBillCommandColumnModel(fontSize: 32 * fontSizeScale, width: 1, text: global.moneyFormatAndDot.format(detail.qty), align: global.PrintColumnAlign.right),
        print.PosPrintBillCommandColumnModel(
            fontSize: 32 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(detail.qty * detail.price), align: global.PrintColumnAlign.right)
      ]));
    }
    {
      if (detail.remark.isNotEmpty) {
        printerData.addCommand(print.PosPrintBillCommandModel(
            mode: 2,
            posStyles: const PosStyles(bold: true),
            columns: [print.PosPrintBillCommandColumnModel(fontSize: 24 * fontSizeScale, width: 5, text: " * ${detail.remark}", align: global.PrintColumnAlign.left)]));
      }
      // ส่วนเพิ่มเติม
      List<ProductProcessOptionModel> optionList =
          (detail.optionselected.isNotEmpty) ? (jsonDecode(detail.optionselected) as List).map((e) => ProductProcessOptionModel.fromJson(e)).toList() : [];

      for (var option in optionList) {
        for (var choice in option.choices) {
          if (choice.selected) {
            String choiceName = global.getNameFromLanguage(choice.names, global.countryCodes[0]);
            if (global.languageForCustomer != global.countryCodes[0]) {
              choiceName = "$choiceName - ${global.getNameFromLanguage(choice.names, global.languageForCustomer)}";
            }
            printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
              print.PosPrintBillCommandColumnModel(
                  fontSize: 24 * fontSizeScale,
                  width: 5,
                  align: global.PrintColumnAlign.left,
                  text:
                      " + $choiceName ${(choice.priceValue == 0) ? "" : " @(${global.moneyFormatAndDot.format(choice.priceValue - global.calcDiscount(amount: choice.priceValue, discountWord: choice.discountWord))})"}"),
              print.PosPrintBillCommandColumnModel(
                  fontSize: 24 * fontSizeScale, width: 1, text: (choice.qty == 0) ? "" : global.moneyFormatAndDot.format(detail.qty), align: global.PrintColumnAlign.right),
              print.PosPrintBillCommandColumnModel(
                  fontSize: 24 * fontSizeScale,
                  width: 2,
                  text: (choice.priceValue == 0)
                      ? ""
                      : global.moneyFormatAndDot.format(detail.qty * (choice.priceValue - global.calcDiscount(amount: choice.priceValue, discountWord: choice.discountWord))),
                  align: global.PrintColumnAlign.right)
            ]));
          }
        }
      }
    }
  }
  printerData.addCommand(print.PosPrintBillCommandModel(mode: 3));
  if (totalFoodAmount != 0 && totalDrinkAmount != 0) {
    String totalAmountOfFoodWord = global.findLanguage(code: "total_amount_of_food", languageCode: global.countryCodes[0]);
    String totalAmountOfDrinkWord = global.findLanguage(code: "total_amount_of_beverage", languageCode: global.countryCodes[0]);
    if (global.languageForCustomer != global.countryCodes[0]) {
      totalAmountOfFoodWord = "$totalAmountOfFoodWord/${global.findLanguage(code: "total_amount_of_food", languageCode: global.languageForCustomer)}";
      totalAmountOfDrinkWord = "$totalAmountOfDrinkWord/${global.findLanguage(code: "total_amount_of_beverage", languageCode: global.languageForCustomer)}";
    }
    // พิมพ์แยกบรรทัด อาหาร/เครื่องดื่ม
    printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
      print.PosPrintBillCommandColumnModel(fontSize: 32 * fontSizeScale, width: 5, text: totalAmountOfFoodWord, align: global.PrintColumnAlign.left),
      print.PosPrintBillCommandColumnModel(fontSize: 32 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(totalFoodAmount), align: global.PrintColumnAlign.right)
    ]));
    printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
      print.PosPrintBillCommandColumnModel(fontSize: 32 * fontSizeScale, width: 5, text: totalAmountOfDrinkWord, align: global.PrintColumnAlign.left),
      print.PosPrintBillCommandColumnModel(fontSize: 32 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(totalDrinkAmount), align: global.PrintColumnAlign.right)
    ]));
  }
  if (payResult.discountAmount != 0 || payResult.diffAmount != 0) {
    String totalAmountWord = global.findLanguage(code: "total_amount", languageCode: global.countryCodes[0]);
    if (global.languageForCustomer != global.countryCodes[0]) {
      totalAmountWord = "$totalAmountWord/${global.findLanguage(code: "total_amount", languageCode: global.languageForCustomer)}";
    }
    printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
      print.PosPrintBillCommandColumnModel(fontSize: 32 * fontSizeScale, width: 5, text: totalAmountWord, align: global.PrintColumnAlign.left),
      print.PosPrintBillCommandColumnModel(
          fontSize: 32 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(totalDrinkAmount + totalFoodAmount), align: global.PrintColumnAlign.right)
    ]));
  }

  printerData.addCommand(print.PosPrintBillCommandModel(mode: 3));
  if (payResult.discountAmount != 0) {
    String discountWord = global.findLanguage(code: "discount", languageCode: global.countryCodes[0]);
    if (global.languageForCustomer != global.countryCodes[0]) {
      discountWord = "$discountWord/${global.findLanguage(code: "discount", languageCode: global.languageForCustomer)}";
    }
    printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
      print.PosPrintBillCommandColumnModel(fontSize: 32 * fontSizeScale, width: 5, text: "$discountWord ${payResult.discountWord}", align: global.PrintColumnAlign.left),
      print.PosPrintBillCommandColumnModel(
          fontSize: 32 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(payResult.discountAmount), align: global.PrintColumnAlign.right)
    ]));
  }
  if (global.shopProfile!.orderstation.isvatregister == false) {
    // ไม่จดทะเบียนภาษีมูลค่าเพิ่ม
    String summaryIsNotReceipt = global.findLanguage(code: "summary_is_not_receipt", languageCode: global.countryCodes[0]);
    if (global.languageForCustomer != global.countryCodes[0]) {
      summaryIsNotReceipt = "$summaryIsNotReceipt/${global.findLanguage(code: "summary_is_not_receipt", languageCode: global.languageForCustomer)}";
    }
    printerData.addCommand(print.PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [print.PosPrintBillCommandColumnModel(fontSize: 30 * fontSizeScale, width: 1, text: summaryIsNotReceipt, align: global.PrintColumnAlign.center)]));
  } else {
    if (payResult.totalAmountBeforeVat > 0) {
      String totalAmountBeforeVatWord = global.findLanguage(code: "before_vat", languageCode: global.countryCodes[0]);
      if (global.languageForCustomer != global.countryCodes[0]) {
        totalAmountBeforeVatWord = "$totalAmountBeforeVatWord/${global.findLanguage(code: "total_amount_before_vat", languageCode: global.languageForCustomer)}";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 30 * fontSizeScale, width: 5, text: totalAmountBeforeVatWord, align: global.PrintColumnAlign.left),
        print.PosPrintBillCommandColumnModel(
            fontSize: 30 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(payResult.totalAmountBeforeVat), align: global.PrintColumnAlign.right)
      ]));
    }
    if (payResult.totalAmountExceptVat > 0) {
      String totalAmountExceptVatWord = global.findLanguage(code: "total_item_except_vat_amount", languageCode: global.countryCodes[0]);
      if (global.languageForCustomer != global.countryCodes[0]) {
        totalAmountExceptVatWord = "$totalAmountExceptVatWord/${global.findLanguage(code: "total_item_except_vat_amount", languageCode: global.languageForCustomer)}";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 30 * fontSizeScale, width: 5, text: totalAmountExceptVatWord, align: global.PrintColumnAlign.left),
        print.PosPrintBillCommandColumnModel(
            fontSize: 30 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(payResult.totalAmountExceptVat), align: global.PrintColumnAlign.right)
      ]));
    }
    if (payResult.vatrate > 0) {
      String vatAmountWord = global.findLanguage(code: "vat", languageCode: global.countryCodes[0]);
      if (global.languageForCustomer != global.countryCodes[0]) {
        vatAmountWord = "$vatAmountWord";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 30 * fontSizeScale, width: 5, text: "$vatAmountWord: ${payResult.vatrate}%", align: global.PrintColumnAlign.left),
        print.PosPrintBillCommandColumnModel(
            fontSize: 30 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(payResult.vatAmount), align: global.PrintColumnAlign.right)
      ]));
    }
  }

  if (payResult.diffAmount != 0) {
    String roundOffFractionsWord = global.findLanguage(code: "round_off_fractions", languageCode: global.countryCodes[0]);
    if (global.languageForCustomer != global.countryCodes[0]) {
      roundOffFractionsWord = "$roundOffFractionsWord/${global.findLanguage(code: "round_off_fractions", languageCode: global.languageForCustomer)}";
    }
    printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
      print.PosPrintBillCommandColumnModel(fontSize: 32 * fontSizeScale, width: 5, text: roundOffFractionsWord, align: global.PrintColumnAlign.left),
      print.PosPrintBillCommandColumnModel(
          fontSize: 32 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(payResult.diffAmount), align: global.PrintColumnAlign.right)
    ]));
  }
  if (payResult.totalAmount > 0) {
    String totalAmountWord = global.findLanguage(code: "total_amount_pay", languageCode: global.countryCodes[0]);
    if (global.languageForCustomer != global.countryCodes[0]) {
      totalAmountWord = "$totalAmountWord/${global.findLanguage(code: "total_amount_pay", languageCode: global.languageForCustomer)}";
    }
    printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
      print.PosPrintBillCommandColumnModel(fontSize: 30 * fontSizeScale, width: 5, text: totalAmountWord, align: global.PrintColumnAlign.left),
      print.PosPrintBillCommandColumnModel(
          fontSize: 30 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(payResult.totalAmount + payResult.diffAmount), align: global.PrintColumnAlign.right)
    ]));
  }
  printerData.addCommand(print.PosPrintBillCommandModel(mode: 3));
  for (var pay in payResult.payCondition) {
    if (pay.payType == 0) {
      // เงินสด
      String payByCashWord = global.findLanguage(code: "pay_by_cash", languageCode: global.countryCodes[0]);
      if (global.languageForCustomer != global.countryCodes[0]) {
        payByCashWord = "$payByCashWord/${global.findLanguage(code: "pay_by_cash", languageCode: global.languageForCustomer)}";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 30 * fontSizeScale, width: 5, text: payByCashWord, align: global.PrintColumnAlign.left),
        print.PosPrintBillCommandColumnModel(fontSize: 30 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(pay.payAmount), align: global.PrintColumnAlign.right)
      ]));
      if ((pay.payAmount - pay.amount) != 0) {
        // มีเงินทอน
        String moneyChangeWord = global.findLanguage(code: "money_change", languageCode: global.countryCodes[0]);
        if (global.languageForCustomer != global.countryCodes[0]) {
          moneyChangeWord = "$moneyChangeWord/${global.findLanguage(code: "money_change", languageCode: global.languageForCustomer)}";
        }
        printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
          print.PosPrintBillCommandColumnModel(fontSize: 30 * fontSizeScale, width: 5, text: moneyChangeWord, align: global.PrintColumnAlign.left),
          print.PosPrintBillCommandColumnModel(
              fontSize: 30 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(pay.payAmount - pay.amount), align: global.PrintColumnAlign.right)
        ]));
      }
    } else {
      // ชำระด้วย อื่นๆ
      String payWithWord = global.findLanguage(code: "pay_with", languageCode: global.countryCodes[0]);
      if (global.languageForCustomer != global.countryCodes[0]) {
        payWithWord = "$payWithWord/${global.findLanguage(code: "pay_with", languageCode: global.languageForCustomer)}";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 30 * fontSizeScale, width: 5, text: "$payWithWord ${pay.payTypeName}", align: global.PrintColumnAlign.left),
        print.PosPrintBillCommandColumnModel(fontSize: 30 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(pay.payAmount), align: global.PrintColumnAlign.right)
      ]));
    }
  }

  // ==========================================
  // แสดงข้อมูลแต้มสะสม
  // ==========================================
  bool hasPointInfo = payResult.usePoint > 0 || payResult.getPoint > 0 || payResult.memberName.isNotEmpty;
  if (hasPointInfo) {
    printerData.addCommand(print.PosPrintBillCommandModel(mode: 3)); // Separator line

    // แสดงชื่อสมาชิก (ถ้ามี)
    if (payResult.memberName.isNotEmpty) {
      String memberWord = global.findLanguage(code: "member", languageCode: global.countryCodes[0]);
      if (global.languageForCustomer != global.countryCodes[0]) {
        memberWord = "$memberWord/${global.findLanguage(code: "member", languageCode: global.languageForCustomer)}";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 24 * fontSizeScale, width: 1, text: "$memberWord: ${payResult.memberName}", align: global.PrintColumnAlign.left)
      ]));
    }

    // แสดงเบอร์โทรสมาชิก (ถ้ามี)
    if (payResult.memberPhone.isNotEmpty) {
      String phoneWord = global.findLanguage(code: "phone_number", languageCode: global.countryCodes[0]);
      if (global.languageForCustomer != global.countryCodes[0]) {
        phoneWord = "$phoneWord/${global.findLanguage(code: "phone_number", languageCode: global.languageForCustomer)}";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 24 * fontSizeScale, width: 1, text: "$phoneWord: ${payResult.memberPhone}", align: global.PrintColumnAlign.left)
      ]));
    }

    // แสดงส่วนลดจากแต้ม (pointusagetype = 1)
    if (payResult.pointDiscountAmount > 0) {
      String pointDiscountWord = global.findLanguage(code: "point_discount", languageCode: global.countryCodes[0]);
      if (global.languageForCustomer != global.countryCodes[0]) {
        pointDiscountWord = "$pointDiscountWord/${global.findLanguage(code: "point_discount", languageCode: global.languageForCustomer)}";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 24 * fontSizeScale, width: 5, text: pointDiscountWord, align: global.PrintColumnAlign.left),
        print.PosPrintBillCommandColumnModel(
            fontSize: 24 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(payResult.pointDiscountAmount), align: global.PrintColumnAlign.right)
      ]));
    }

    // แสดงยอดชำระจากแต้ม (pointusagetype = 2)
    if (payResult.payPointAmount > 0) {
      String payByPointWord = global.findLanguage(code: "pay_by_point", languageCode: global.countryCodes[0]);
      if (global.languageForCustomer != global.countryCodes[0]) {
        payByPointWord = "$payByPointWord/${global.findLanguage(code: "pay_by_point", languageCode: global.languageForCustomer)}";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 24 * fontSizeScale, width: 5, text: payByPointWord, align: global.PrintColumnAlign.left),
        print.PosPrintBillCommandColumnModel(
            fontSize: 24 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(payResult.payPointAmount), align: global.PrintColumnAlign.right)
      ]));
    }

    // แสดงแต้มก่อนใช้ (แต้มเดิม)
    if (payResult.previousPointBalance > 0 && payResult.usePoint > 0) {
      String previousPointWord = global.findLanguage(code: "previous_points", languageCode: global.countryCodes[0]);
      if (global.languageForCustomer != global.countryCodes[0]) {
        previousPointWord = "$previousPointWord/${global.findLanguage(code: "previous_points", languageCode: global.languageForCustomer)}";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 24 * fontSizeScale, width: 5, text: previousPointWord, align: global.PrintColumnAlign.left),
        print.PosPrintBillCommandColumnModel(
            fontSize: 24 * fontSizeScale, width: 2, text: global.moneyFormat.format(payResult.previousPointBalance), align: global.PrintColumnAlign.right)
      ]));
    }

    // แสดงแต้มที่ใช้
    if (payResult.usePoint > 0) {
      String usedPointWord = global.findLanguage(code: "used_points", languageCode: global.countryCodes[0]);
      if (global.languageForCustomer != global.countryCodes[0]) {
        usedPointWord = "$usedPointWord/${global.findLanguage(code: "used_points", languageCode: global.languageForCustomer)}";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 24 * fontSizeScale, width: 5, text: usedPointWord, align: global.PrintColumnAlign.left),
        print.PosPrintBillCommandColumnModel(fontSize: 24 * fontSizeScale, width: 2, text: global.moneyFormat.format(payResult.usePoint), align: global.PrintColumnAlign.right)
      ]));
    }

    // แสดงแต้มที่จะได้รับ
    if (payResult.getPoint > 0) {
      String earnedPointWord = global.findLanguage(code: "earned_points", languageCode: global.countryCodes[0]);
      if (global.languageForCustomer != global.countryCodes[0]) {
        earnedPointWord = "$earnedPointWord/${global.findLanguage(code: "earned_points", languageCode: global.languageForCustomer)}";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 24 * fontSizeScale, width: 5, text: earnedPointWord, align: global.PrintColumnAlign.left),
        print.PosPrintBillCommandColumnModel(fontSize: 24 * fontSizeScale, width: 2, text: global.moneyFormat.format(payResult.getPoint), align: global.PrintColumnAlign.right)
      ]));

      String remainingPointWord = global.findLanguage(code: "remaining_points", languageCode: global.countryCodes[0]);
      if (global.languageForCustomer != global.countryCodes[0]) {
        remainingPointWord = "$remainingPointWord/${global.findLanguage(code: "remaining_points", languageCode: global.languageForCustomer)}";
      }
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
        print.PosPrintBillCommandColumnModel(fontSize: 24 * fontSizeScale, width: 5, text: remainingPointWord, align: global.PrintColumnAlign.left),
        print.PosPrintBillCommandColumnModel(
            fontSize: 24 * fontSizeScale,
            width: 2,
            text: global.moneyFormat.format((payResult.previousPointBalance + payResult.getPoint) - payResult.usePoint),
            align: global.PrintColumnAlign.right)
      ]));
    }
  }

  if (payResult.saveAmount != 0) {
    // ประหยัด
    String saveAmountWord = global.findLanguage(code: "save_amount", languageCode: global.countryCodes[0]);
    if (global.languageForCustomer != global.countryCodes[0]) {
      saveAmountWord = "$saveAmountWord/${global.findLanguage(code: "save_amount", languageCode: global.languageForCustomer)}";
    }
    printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: true), columns: [
      print.PosPrintBillCommandColumnModel(fontSize: 30 * fontSizeScale, width: 5, text: saveAmountWord, align: global.PrintColumnAlign.left),
      print.PosPrintBillCommandColumnModel(
          fontSize: 30 * fontSizeScale, width: 2, text: global.moneyFormatAndDot.format(payResult.saveAmount), align: global.PrintColumnAlign.right)
    ]));
  }

  printerData.addCommand(print.PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [print.PosPrintBillCommandColumnModel(fontSize: 32 * fontSizeScale, width: 1, text: header, align: global.PrintColumnAlign.center)]));
  if (orderTagNumber.isNotEmpty) {
    String tagLabelWord = global.findLanguage(code: "tag_label", languageCode: global.countryCodes[0]);
    if (global.languageForCustomer != global.countryCodes[0]) {
      tagLabelWord = "$tagLabelWord/${global.findLanguage(code: "tag_label", languageCode: global.languageForCustomer)}";
    }
    printerData.addCommand(print.PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [print.PosPrintBillCommandColumnModel(fontSize: 32 * fontSizeScale, width: 1, text: "$tagLabelWord : $orderTagNumber", align: global.PrintColumnAlign.center)]));
  }
  if (queueNumber != 0) {
    printerData.addCommand(print.PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [print.PosPrintBillCommandColumnModel(fontSize: 32 * fontSizeScale, width: 1, text: "Queue : $queueNumber", align: global.PrintColumnAlign.center)]));
  }
  if (printHeader) {
    if (global.shopProfile!.orderstation.branch.pos.footerreceiptpos.trim().isNotEmpty) {
      printerData.addCommand(print.PosPrintBillCommandModel(mode: 2, posStyles: const PosStyles(bold: false), columns: [
        print.PosPrintBillCommandColumnModel(
            fontSize: 24 * fontSizeScale, width: 1, text: global.shopProfile!.orderstation.branch.pos.footerreceiptpos, align: global.PrintColumnAlign.center)
      ]));
    }
  }
  const receiptFooterText = String.fromEnvironment('RECEIPT_FOOTER_TEXT', defaultValue: 'Powered by example.com');
  printerData.addCommand(print.PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [print.PosPrintBillCommandColumnModel(fontSize: 24 * fontSizeScale, width: 1, text: receiptFooterText, align: global.PrintColumnAlign.center)]));

  printerData.addCommand(print.PosPrintBillCommandModel(
    mode: 4,
    value: 100,
  ));
  await printerData.sendToPrinter(
      printerData: printerConfig, docNumber: docNumber, saveToFile: saveToFile, printLogo: printLogo, memberPinCode: memberPinCode, isBCMember: isBCMember);
}
