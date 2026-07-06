import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dedeorder/model/pos_process_model.dart';
import 'package:dedeorder/model/table_model.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:dedeorder/utility/print_process.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image/image.dart' as im;
import 'package:dedeorder/utility/api.dart' as api;

class PosPrintBillCommandColumnModel {
  double width;
  String text;
  global.PrintColumnAlign align;
  double fontSize;

  PosPrintBillCommandColumnModel(
      {this.width = 0,
      this.text = "",
      this.align = global.PrintColumnAlign.left,
      this.fontSize = 24});
}

class PosPrintBillCommandModel {
  int mode; // 0=Reset,1=Logo Image,2=Text,3=Line
  String? text;
  Uint8List? image;
  PosStyles? posStyles;
  PosTextSize posTextSize;
  List<PosPrintBillCommandColumnModel>? columns;
  double value;

  PosPrintBillCommandModel(
      {required this.mode,
      this.text,
      this.image,
      this.value = 0,
      this.posStyles,
      this.columns,
      this.posTextSize = PosTextSize.size1});
}

class PrinterClass {
  int printerIndex;
  String qrCode;

  PrinterClass({
    required this.printerIndex,
    required this.qrCode,
  });

  double paperMaxWidth() {
    return (global.printerConnectData.paperSize == 1) ? 378.0 : 575.0;
  }

  List<PosPrintBillCommandModel> commandList = [];

  void addCommand(PosPrintBillCommandModel command) {
    commandList.add(command);
  }

  void printImageByBluetooth(Uint8List imageData) async {
    /*String macAddress = global.printerConnectData.ipAddress;
    await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    bool connectStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectStatus) {
      final profile = await CapabilityProfile.load();
      final generator = Generator(
          (global.printerConnectData.paperSize == 1)
              ? PaperSize.mm58
              : PaperSize.mm80,
          profile);
      List<int> bytes = [];

      double maxHeight = 0;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final backgroundPaint = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.fill;

      canvas.drawRect(
          ui.Rect.fromLTWH(0.0, 0.0, global.printerWidthByPixel(0), 20000.0),
          backgroundPaint);

      /*ui.Image? newImage;
      ui.decodeImageFromList(imageData, (result) {
        newImage = result;
      });
      while (newImage == null) {
        await Future.delayed(const Duration(milliseconds: 100));
      }*/
      im.Image? img = im.decodeImage(imageData);
      im.Image resized = im.copyResize(img!,
          width: global.printerWidthByPixel(printerIndex).toInt());
      Uint8List resizedImg = Uint8List.fromList(im.encodePng(resized));
      ui.Image? newImage;
      ui.decodeImageFromList(resizedImg, (result) {
        newImage = result;
      });
      while (newImage == null) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      canvas.drawImage(newImage!, ui.Offset(0, maxHeight), ui.Paint());
      maxHeight += newImage!.height.toDouble();

      final picture = recorder.endRecording();
      final imageBuffer = picture.toImage(
          global.printerWidthByPixel(printerIndex).toInt(), maxHeight.toInt());
      final pngBytes = await imageBuffer
          .then((value) => value.toByteData(format: ui.ImageByteFormat.png));
      im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
      int printMaxHeight = 200;
      int calcLoop = imageDecode!.height ~/ printMaxHeight;
      for (int i = 0; i <= calcLoop; i++) {
        try {
          im.Image croppedImage = im.copyCrop(imageDecode, 0,
              i * printMaxHeight, imageDecode.width, printMaxHeight);
          bytes += generator.imageRaster(croppedImage);
        } catch (e,s) {
          print(e);
        }
      }
      bytes += generator.cut();
      bytes += generator.drawer();
      await PrintBluetoothThermal.writeBytes(bytes);
    }*/
  }

  Future<void> printImageByIp(Uint8List imageData) async {
    PaperSize paper = (global.printerConnectData.paperSize == 1)
        ? PaperSize.mm58
        : PaperSize.mm80;
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(paper, profile);
    String ipAddress = global.printerConnectData.ipAddress;
    int ipPort = global.printerConnectData.ipPort;
    PrinterNetworkManager printer =
        PrinterNetworkManager(ipAddress, port: ipPort);

    PosPrintResult res = await printer.connect();

    if (res == PosPrintResult.success) {
      double maxHeight = 0;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final backgroundPaint = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.fill;

      canvas.drawRect(
          ui.Rect.fromLTWH(
              0.0, 0.0, global.printerWidthByPixel(printerIndex), 20000.0),
          backgroundPaint);

      ui.Image? newImage;
      ui.decodeImageFromList(imageData, (result) {
        newImage = result;
      });
      while (newImage == null) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      canvas.drawImage(newImage!, ui.Offset(0, maxHeight), ui.Paint());
      maxHeight += newImage!.height.toDouble();

      List<int> imageBytes = [];
      final picture = recorder.endRecording();
      final imageBuffer = picture.toImage(
          global.printerWidthByPixel(printerIndex).toInt(), maxHeight.toInt());
      final pngBytes = await imageBuffer
          .then((value) => value.toByteData(format: ui.ImageByteFormat.png));
      im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
      int printMaxHeight = 200;
      int calcLoop = imageDecode!.height ~/ printMaxHeight;
      for (int i = 0; i <= calcLoop; i++) {
        try {
          im.Image croppedImage = im.copyCrop(imageDecode, 0,
              i * printMaxHeight, imageDecode.width, printMaxHeight);
          imageBytes += generator.imageRaster(croppedImage);
        } catch (e, s) {
          print(e);
          global.sendErrorToDevTeam("printImageByIp:$e $s");
        }
      }
      imageBytes += generator.feed(3);
      imageBytes += generator.cut();
      printer.printTicket(imageBytes);
      printer.disconnect();
    }
  }

  void printByIpImageMode() async {
    PaperSize paper = (global.printerConnectData.paperSize == 1)
        ? PaperSize.mm58
        : PaperSize.mm80;
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(paper, profile);
    String ipAddress = global.printerConnectData.ipAddress;
    int ipPort = global.printerConnectData.ipPort;
    PrinterNetworkManager printer =
        PrinterNetworkManager(ipAddress, port: ipPort);
    PosPrintResult res = await printer.connect();

    if (res == PosPrintResult.success) {
      double maxHeight = 0;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final backgroundPaint = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.fill;

      canvas.drawRect(
          ui.Rect.fromLTWH(
              0.0, 0.0, global.printerWidthByPixel(printerIndex), 20000.0),
          backgroundPaint);

      PrintProcess printProcess = PrintProcess(printerIndex: printerIndex);
      for (var command in commandList) {
        // 0=Reset,1=Logo Image,2=Text,3=Line,9=Cut
        switch (command.mode) {
          case 0: // Reset
            break;
          case 1: // Logo Image
            break;
          case 2: // Text
            printProcess.columnWidth.clear();
            printProcess.column.clear();
            for (int index = 0; index < command.columns!.length; index++) {
              printProcess.columnWidth.add(command.columns![index].width);
              printProcess.column.add(PrintColumn(
                text: command.columns![index].text,
                align: command.columns![index].align,
                fontSize: command.columns![index].fontSize,
              ));
            }
            ui.Image result = await printProcess
                .lineFeedImage(command.posStyles ?? const PosStyles());
            canvas.drawImage(result, ui.Offset(0, maxHeight), ui.Paint());
            maxHeight += result.height.toDouble();
            break;
          case 3: // Line
            canvas.drawLine(
                ui.Offset(0, maxHeight),
                ui.Offset(
                    0 + global.printerWidthByPixel(printerIndex), maxHeight),
                ui.Paint());
            maxHeight += 1;
            break;
          case 4: // Line Feed
            maxHeight += command.value;
            break;
        }
      }
      if (qrCode.isNotEmpty) {
        ui.Image result = await QrPainter(
          data: qrCode,
          version: QrVersions.auto,
          gapless: false,
        ).toImage(paperMaxWidth() / 2);
        canvas.drawImage(
            result, ui.Offset(result.width / 2, maxHeight), ui.Paint());
        maxHeight += result.height.toDouble() + 100;
      }
      List<int> imageBytes = [];
      final picture = recorder.endRecording();
      final imageBuffer = picture.toImage(
          global.printerWidthByPixel(printerIndex).toInt(), maxHeight.toInt());
      final pngBytes = await imageBuffer
          .then((value) => value.toByteData(format: ui.ImageByteFormat.png));
      im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
      int printMaxHeight = 200;
      int calcLoop = imageDecode!.height ~/ printMaxHeight;
      for (int i = 0; i <= calcLoop; i++) {
        try {
          im.Image croppedImage = im.copyCrop(imageDecode, 0,
              i * printMaxHeight, imageDecode.width, printMaxHeight);
          imageBytes += generator.imageRaster(croppedImage);
        } catch (e, s) {
          print(e);
          global.sendErrorToDevTeam("printByIpImageMode:$e $s");
        }
      }
      imageBytes += generator.feed(3);
      imageBytes += generator.cut();
      printer.printTicket(imageBytes);
      printer.disconnect();
    }
  }

  void printByBluetoothImageMode() async {
    /*String macAddress = global.printerConnectData.ipAddress;
    await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    bool connectStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectStatus) {
      final profile = await CapabilityProfile.load();
      final generator = Generator(
          (global.printerConnectData.paperSize == 1)
              ? PaperSize.mm58
              : PaperSize.mm80,
          profile);
      List<int> bytes = [];

      double maxHeight = 0;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final backgroundPaint = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.fill;

      canvas.drawRect(
          ui.Rect.fromLTWH(0.0, 0.0, global.printerWidthByPixel(0), 20000.0),
          backgroundPaint);

      PrintProcess printProcess = PrintProcess(printerIndex: printerIndex);
      for (var command in commandList) {
        // 0=Reset,1=Logo Image,2=Text,3=Line,9=Cut
        switch (command.mode) {
          case 0: // Reset
            break;
          case 1: // Logo Image
            break;
          case 2: // Text
            printProcess.columnWidth.clear();
            printProcess.column.clear();
            for (int index = 0; index < command.columns!.length; index++) {
              printProcess.columnWidth.add(command.columns![index].width);
              printProcess.column.add(PrintColumn(
                text: command.columns![index].text,
                align: command.columns![index].align,
                fontSize: command.columns![index].fontSize,
              ));
            }
            ui.Image result = await printProcess
                .lineFeedImage(command.posStyles ?? const PosStyles());
            canvas.drawImage(result, ui.Offset(0, maxHeight), ui.Paint());
            maxHeight += result.height.toDouble();
            break;
          case 3: // Line
            canvas.drawLine(
                ui.Offset(0, maxHeight),
                ui.Offset(
                    0 + global.printerWidthByPixel(printerIndex), maxHeight),
                ui.Paint());
            maxHeight += 1;
            break;
          case 4: // Line Feed
            maxHeight += command.value;
            break;
        }
      }
      if (qrCode.isNotEmpty) {
        ui.Image result = await QrPainter(
          data: qrCode,
          version: QrVersions.auto,
          gapless: false,
        ).toImage(paperMaxWidth() / 2);
        canvas.drawImage(
            result, ui.Offset(result.width / 2, maxHeight), ui.Paint());
        maxHeight += result.height.toDouble() + 100;
      }
      final picture = recorder.endRecording();
      final imageBuffer = picture.toImage(
          global.printerWidthByPixel(printerIndex).toInt(), maxHeight.toInt());
      final pngBytes = await imageBuffer
          .then((value) => value.toByteData(format: ui.ImageByteFormat.png));
      im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
      int printMaxHeight = 200;
      int calcLoop = imageDecode!.height ~/ printMaxHeight;
      for (int i = 0; i <= calcLoop; i++) {
        try {
          im.Image croppedImage = im.copyCrop(imageDecode, 0,
              i * printMaxHeight, imageDecode.width, printMaxHeight);
          bytes += generator.imageRaster(croppedImage);
        } catch (e,s) {
          print(e);
        }
      }
      bytes += generator.cut();
      bytes += generator.drawer();
      await PrintBluetoothThermal.writeBytes(bytes);
    }*/
  }

  void sendToPrinter() {
    switch (global.printerConnectData.printerConnectType) {
      case global.PrinterConnectEnum.ip:
        printByIpImageMode();
        break;
      case global.PrinterConnectEnum.bluetooth:
        printByBluetoothImageMode();
        break;
      case global.PrinterConnectEnum.windows:
        break;
    }
  }
}

void printTableQrCode(
    {required TableProcessObjectBoxStruct table,
    required String qrCode,
    bool fullDetail = true}) {
  // printerIndex 1 = Ticket Printer
  PrinterClass printer = PrinterClass(
      printerIndex: 1,
      qrCode: "https://dedefoodorder.web.app/?q=$qrCode&openExternalBrowser=1");
  // Reset Printer
  printer.addCommand(PosPrintBillCommandModel(mode: 0));
  printer.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 30,
            width: 1,
            text: global.posInformation.shop_name,
            align: global.PrintColumnAlign.center)
      ]));
  printer.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 20,
            width: 1,
            text:
                "Printing time : ${DateFormat("dd/MM/yyyy - HH:mm").format(DateTime.now())}",
            align: global.PrintColumnAlign.center)
      ]));
  String tableTitle = "เปิด";
  tableTitle += "โต๊ะ : ${table.number}";
  printer.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 30,
            width: 1,
            text: tableTitle,
            align: global.PrintColumnAlign.center)
      ]));

  printer.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 30,
            width: 1,
            text:
                "เวลาเปิดโต๊ะ : ${DateFormat("HH:mm").format(table.table_open_datetime)}",
            align: global.PrintColumnAlign.center)
      ]));
  if (table.table_al_la_crate_mode == false) {
    printer.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 30,
              width: 1,
              text: "จำนวนนาที : ${global.moneyFormat.format(120)} นาที",
              align: global.PrintColumnAlign.center)
        ]));
    String endTime = DateFormat("HH:mm")
        .format(table.table_open_datetime.add(const Duration(minutes: 120)));
    printer.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 30,
              width: 1,
              text: "เวลาปิดโต๊ะ : $endTime",
              align: global.PrintColumnAlign.center)
        ]));
  }
  if (fullDetail) {
    String countPeople = "";
    int sumPeople = table.man_count + table.woman_count;
    if (sumPeople > 1) {
      countPeople = "ผู้ใหญ่ $sumPeople คน";
    }
    if (table.child_count > 0) {
      if (countPeople.isNotEmpty) {
        countPeople += " : ";
      }
      countPeople += "เด็ก ${table.child_count} คน";
    }
    if (countPeople.isNotEmpty) {
      printer.addCommand(PosPrintBillCommandModel(
          mode: 2,
          posStyles: const PosStyles(bold: true),
          columns: [
            PosPrintBillCommandColumnModel(
                fontSize: 30,
                width: 1,
                text: "$countPeople",
                align: global.PrintColumnAlign.center)
          ]));
    }
  }
  String orderType = "";
  if (table.table_al_la_crate_mode) {
    orderType = "อาราคัส";
  } else {
    int buffetIndex = global.buffetModeLists
        .indexWhere((element) => element.code == table.buffet_code);
    if (buffetIndex != -1) {
      orderType = global.buffetModeLists[buffetIndex].names[0];
    }
  }
  printer.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 30,
            width: 1,
            text: "เงื่อนไข : $orderType",
            align: global.PrintColumnAlign.center)
      ]));
  printer.addCommand(PosPrintBillCommandModel(
    mode: 4,
    value: 80,
  ));
  printer.sendToPrinter();
}

void printTableSummery(
    {required final TableProcessObjectBoxStruct table,
    required final PosProcessModel processResult,
    bool fullDetail = true}) {
  // printerIndex 1 = Ticket Printer
  PrinterClass printerData = PrinterClass(
      printerIndex: 1,
      qrCode:
          "" /*KplusPayment.generateQRData(global.payQrCode,
          amount: processResult.total_amount.toDouble())) */
      /* qrCode: PromptPay.generateQRData(global.payQrCode,
          amount: processResult.total_amount.toDouble()));*/
      );

  // Reset Printer
  printerData.addCommand(PosPrintBillCommandModel(mode: 0));
  printerData.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 50,
            width: 1,
            text: global.posInformation.shop_name,
            align: global.PrintColumnAlign.center)
      ]));
  printerData.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 24,
            width: 1,
            text:
                "Printing time : ${DateFormat("dd/MM/yyyy - HH:mm").format(DateTime.now())}",
            align: global.PrintColumnAlign.center)
      ]));
  String tableTitle = "ใบสรุปรายการ โต๊ะ : ${table.number}";
  printerData.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 30,
            width: 1,
            text: tableTitle,
            align: global.PrintColumnAlign.center)
      ]));

  printerData.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 30,
            width: 1,
            text:
                "เวลาเปิดโต๊ะ : ${DateFormat("HH:mm").format(table.table_open_datetime)}",
            align: global.PrintColumnAlign.center)
      ]));
  if (table.table_al_la_crate_mode == false) {
    printerData.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 30,
              width: 1,
              text: "จำนวนนาที : ${global.moneyFormat.format(120)} นาที",
              align: global.PrintColumnAlign.center)
        ]));
    String endTime = DateFormat("HH:mm")
        .format(table.table_open_datetime.add(const Duration(minutes: 120)));
    printerData.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 30,
              width: 1,
              text: "เวลาปิดโต๊ะ : $endTime",
              align: global.PrintColumnAlign.center)
        ]));
  }
  if (fullDetail) {
    String countPeople = "";
    int sumPeople = table.man_count + table.woman_count;
    if (sumPeople > 1) {
      countPeople = "ผู้ใหญ่ $sumPeople คน";
    }
    if (table.child_count > 0) {
      if (countPeople.isNotEmpty) {
        countPeople += " : ";
      }
      countPeople += "เด็ก ${table.child_count} คน";
    }
    if (countPeople.isNotEmpty) {
      printerData.addCommand(PosPrintBillCommandModel(
          mode: 2,
          posStyles: const PosStyles(bold: true),
          columns: [
            PosPrintBillCommandColumnModel(
                fontSize: 30,
                width: 1,
                text: countPeople,
                align: global.PrintColumnAlign.center)
          ]));
    }
  }
  String orderType = "";
  if (table.table_al_la_crate_mode) {
    orderType = "อาราคัส";
  } else {
    int buffetIndex = global.buffetModeLists
        .indexWhere((element) => element.code == table.buffet_code);
    if (buffetIndex != -1) {
      orderType = global.buffetModeLists[buffetIndex].names[0];
    }
  }
  printerData.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 30,
            width: 1,
            text: "เงื่อนไข : $orderType",
            align: global.PrintColumnAlign.center)
      ]));
  /*printerData.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 30,
            width: 1,
            text: (processResult.vat_type == 1)
                ? "(ราคารวมภาษีมูลค่าเพิ่มแล้ว)"
                : "(ราคาไม่รวมภาษีมูลค่าเพิ่ม)",
            align: global.PrintColumnAlign.center)
      ]));*/
  // รายละเอียดสินค้า
  List<PosProcessDetailModel> details = [];
  for (var detail in processResult.details) {
    if (detail.qty != 0) {
      details.add(PosProcessDetailModel(
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
          extra: detail.extra,
          vat_type: detail.vat_type,
          price_exclude_vat: detail.price_exclude_vat,
          food_type: detail.food_type));
    }
  }
  // กรณีพิมพ์บิลแบบรวมรายการ
  List<PosProcessDetailModel> detailSum = [];
  for (var detail in details) {
    bool isFound = false;
    for (var billDetailSumItem in detailSum) {
      if (billDetailSumItem.barcode == detail.barcode &&
          jsonEncode(billDetailSumItem.extra) == jsonEncode(detail.extra)) {
        billDetailSumItem.qty += detail.qty;
        billDetailSumItem.total_amount += detail.total_amount;
        isFound = true;
        break;
      }
    }
    if (!isFound) {
      detailSum.add(detail);
    }
  }
  details = detailSum;
  printerData.addCommand(PosPrintBillCommandModel(mode: 3));
  printerData.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 24,
            width: 5,
            text: "รายการ",
            align: global.PrintColumnAlign.left),
        PosPrintBillCommandColumnModel(
            fontSize: 24,
            width: 1,
            text: "จำนวน",
            align: global.PrintColumnAlign.right),
        PosPrintBillCommandColumnModel(
            fontSize: 24,
            width: 2,
            text: "จำนวนเงิน",
            align: global.PrintColumnAlign.right)
      ]));
  printerData.addCommand(PosPrintBillCommandModel(mode: 3));
  // เรียกตามประเภทอาหาร เครื่องดื่ม เครื่องดื่มแอลกอฮอล์ อื่นๆ
  details.sort((a, b) => a.food_type.compareTo(b.food_type));
  for (var detail in details) {
    {
      // รายละเอียดสินค้า
      printerData.addCommand(PosPrintBillCommandModel(
          mode: 2,
          posStyles: const PosStyles(bold: true),
          columns: [
            PosPrintBillCommandColumnModel(
                fontSize: 24,
                width: 5,
                text:
                    "${global.getNameFromJsonLanguage(detail.item_name, global.currentLanguage)}/${global.getNameFromJsonLanguage(detail.unit_name, global.currentLanguage)}",
                align: global.PrintColumnAlign.left),
            PosPrintBillCommandColumnModel(
                fontSize: 24,
                width: 1,
                text: global.moneyFormatAndDot.format(detail.qty),
                align: global.PrintColumnAlign.right),
            PosPrintBillCommandColumnModel(
                fontSize: 24,
                width: 2,
                text: global.moneyFormatAndDot.format(detail.total_amount),
                align: global.PrintColumnAlign.right)
          ]));
    }
    {
      // ส่วนเพิ่มเติม
      for (var extra in detail.extra) {
        printerData.addCommand(PosPrintBillCommandModel(
            mode: 2,
            posStyles: const PosStyles(bold: true),
            columns: [
              PosPrintBillCommandColumnModel(
                  fontSize: 20,
                  width: 5,
                  text:
                      " + ${global.getNameFromJsonLanguage(extra.item_name, global.currentLanguage)}",
                  align: global.PrintColumnAlign.left),
              PosPrintBillCommandColumnModel(
                  fontSize: 20,
                  width: 1,
                  text: (extra.qty == 0)
                      ? ""
                      : global.moneyFormatAndDot.format(extra.qty),
                  align: global.PrintColumnAlign.right),
              PosPrintBillCommandColumnModel(
                  fontSize: 20,
                  width: 2,
                  text: (extra.total_amount == 0)
                      ? ""
                      : global.moneyFormatAndDot.format(extra.total_amount),
                  align: global.PrintColumnAlign.right)
            ]));
      }
    }
  }
  printerData.addCommand(PosPrintBillCommandModel(mode: 3));
  printerData.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 32,
            width: 5,
            text: "ยอดรวมค่าอาหาร",
            align: global.PrintColumnAlign.left),
        PosPrintBillCommandColumnModel(
            fontSize: 32,
            width: 2,
            text: global.moneyFormatAndDot
                .format(processResult.total_food_amount),
            align: global.PrintColumnAlign.right)
      ]));
  if (processResult.detail_total_discount != 0) {
    printerData.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 5,
              text:
                  "ส่วนลดเฉพาะอาหาร : ${processResult.detail_discount_formula}",
              align: global.PrintColumnAlign.left),
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 2,
              text: global.moneyFormatAndDot
                  .format(processResult.detail_total_discount),
              align: global.PrintColumnAlign.right)
        ]));
  }
  if (processResult.total_drink_amount != 0) {
    printerData.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 5,
              text: "ยอดรวมค่าเครื่องดื่ม",
              align: global.PrintColumnAlign.left),
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 2,
              text: global.moneyFormatAndDot
                  .format(processResult.total_drink_amount),
              align: global.PrintColumnAlign.right)
        ]));
  }
  if (processResult.total_alcohol_amount != 0) {
    printerData.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 5,
              text: "ยอดรวมค่าเครื่องดื่มแอลกอฮอล์",
              align: global.PrintColumnAlign.left),
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 2,
              text: global.moneyFormatAndDot
                  .format(processResult.total_alcohol_amount),
              align: global.PrintColumnAlign.right)
        ]));
  }
  if (processResult.total_other_amount != 0) {
    printerData.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 5,
              text: "ยอดรวมอื่นๆ",
              align: global.PrintColumnAlign.left),
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 2,
              text: global.moneyFormatAndDot
                  .format(processResult.total_other_amount),
              align: global.PrintColumnAlign.right)
        ]));
  }
  if (processResult.total_vat_amount != 0) {
    printerData.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 5,
              text: "ยอดก่อนภาษี",
              align: global.PrintColumnAlign.left),
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 2,
              text: global.moneyFormatAndDot
                  .format(processResult.amount_before_calc_vat),
              align: global.PrintColumnAlign.right)
        ]));
    printerData.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 5,
              text:
                  "ภาษีมูลค่าเพิ่ม ${global.moneyFormat.format(processResult.vat_rate)}%",
              align: global.PrintColumnAlign.left),
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 2,
              text: global.moneyFormatAndDot
                  .format(processResult.total_vat_amount),
              align: global.PrintColumnAlign.right)
        ]));
  }
  if (processResult.detail_total_discount != 0) {
    printerData.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 5,
              text: "รวมทั้งสิ้น",
              align: global.PrintColumnAlign.left),
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 2,
              text: global.moneyFormatAndDot.format(processResult.total_amount),
              align: global.PrintColumnAlign.right)
        ]));
  }
  if (processResult.cash_round_amount != 0) {
    printerData.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 5,
              text: "ยอดปัดเศษ",
              align: global.PrintColumnAlign.left),
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 2,
              text: global.moneyFormatAndDot
                  .format(processResult.cash_round_amount),
              align: global.PrintColumnAlign.right)
        ]));
    printerData.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 5,
              text: "ยอดชำระ",
              align: global.PrintColumnAlign.left),
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 2,
              text: global.moneyFormatAndDot
                  .format(processResult.total_amount_pay),
              align: global.PrintColumnAlign.right)
        ]));
  }
  printerData.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 32,
            width: 5,
            text: "ยอดชำระเงิน",
            align: global.PrintColumnAlign.left),
        PosPrintBillCommandColumnModel(
            fontSize: 32,
            width: 2,
            text:
                global.moneyFormatAndDot.format(processResult.total_amount_pay),
            align: global.PrintColumnAlign.right)
      ]));
  printerData.addCommand(PosPrintBillCommandModel(mode: 3));
  printerData.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 30,
            width: 1,
            text: "ใบสรุป ไม่ใช่ใบเสร็จรับเงิน",
            align: global.PrintColumnAlign.center)
      ]));

  printerData.addCommand(PosPrintBillCommandModel(
    mode: 4,
    value: 20,
  ));
  if (1 == 2) {
    printerData.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 24,
              width: 1,
              text: "Prompt Pay : ${global.payQrCodeName}",
              align: global.PrintColumnAlign.center)
        ]));
  }
  printerData.addCommand(PosPrintBillCommandModel(
    mode: 4,
    value: 20,
  ));
  printerData.sendToPrinter();
}

Future<void> printerImageToLocalPrinter(String docNumber) async {
  String data = await api.getPaySlipFromTerminal(docNumber);
  if (data.isNotEmpty) {
    List<int> bytes = base64Decode(data);
    Uint8List imageData = Uint8List.fromList(bytes);
    PrinterClass printer = PrinterClass(printerIndex: 0, qrCode: "");
    switch (global.printerConnectData.printerConnectType) {
      case global.PrinterConnectEnum.ip:
        await printer.printImageByIp(imageData);
        break;
      case global.PrinterConnectEnum.bluetooth:
        printer.printImageByBluetooth(imageData);
        break;
      case global.PrinterConnectEnum.windows:
        break;
    }
  }
}
