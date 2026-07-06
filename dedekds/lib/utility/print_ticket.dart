import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dedekds/model/order_temp_model.dart';
import 'package:dedekds/model/product_model.dart';
import 'package:dedekds/utility/print_process.dart';
import 'package:image/image.dart' as im;
import 'dart:ui' as ui;
import 'package:dedekds/global.dart' as global;
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

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
  int? mode; // 0=Reset,1=Logo Image,2=Text,3=Line
  String? text;
  Uint8List? image;
  PosStyles? posStyles;
  PosTextSize? posTextSize;
  List<PosPrintBillCommandColumnModel> columns;
  double value;

  PosPrintBillCommandModel(
      {required this.mode,
      this.text,
      this.image,
      this.value = 0,
      this.posStyles = const PosStyles(bold: false),
      this.columns = const [],
      this.posTextSize = PosTextSize.size1});
}

class PrinterClass {
  double paperMaxWidth() {
    return (global.printerConnectData.paperSize == 1) ? 378.0 : 575.0;
  }

  List<PosPrintBillCommandModel> commandList = [];

  void addCommand(PosPrintBillCommandModel command) {
    commandList.add(command);
  }

  void printByIpImageMode() async {
    PaperSize paper = (global.printerConnectData.paperSize == 1)
        ? PaperSize.mm58
        : PaperSize.mm80;
    CapabilityProfile profile = await CapabilityProfile.load();
    NetworkPrinter printer = NetworkPrinter(paper, profile);
    String ipAddress = global.printerConnectData.ipAddress;
    int ipPort = global.printerConnectData.ipPort;
    PosPrintResult res = await printer.connect(ipAddress, port: ipPort);

    if (res == PosPrintResult.success) {
      double maxHeight = 0;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final backgroundPaint = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.fill;

      canvas.drawRect(
          ui.Rect.fromLTWH(0.0, 0.0, global.printerWidthByPixel(), 20000.0),
          backgroundPaint);

      PrintProcess printProcess = PrintProcess();
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
            for (int index = 0; index < command.columns.length; index++) {
              printProcess.columnWidth.add(command.columns[index].width);
              printProcess.column.add(PrintColumn(
                text: command.columns[index].text,
                align: command.columns[index].align,
                fontSize: command.columns[index].fontSize,
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
                ui.Offset(0 + global.printerWidthByPixel(), maxHeight),
                ui.Paint());
            maxHeight += 1;
            break;
          case 4: // Line Feed
            maxHeight += command.value;
            break;
        }
      }
      final picture = recorder.endRecording();
      final imageBuffer = picture.toImage(
          global.printerWidthByPixel().toInt(), maxHeight.toInt());
      final pngBytes = await imageBuffer
          .then((value) => value.toByteData(format: ui.ImageByteFormat.png));
      im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
      int printMaxHeight = 200;
      int calcLoop = imageDecode!.height ~/ printMaxHeight;
      for (int i = 0; i <= calcLoop; i++) {
        try {
          im.Image croppedImage = im.copyCrop(imageDecode, 0,
              i * printMaxHeight, imageDecode.width, printMaxHeight);
          printer.imageRaster(croppedImage);
          sleep(const Duration(milliseconds: 100));
        } catch (e) {
          print(e);
        }
      }
      sleep(const Duration(milliseconds: 100));
      printer.cut();
      printer.disconnect();
    }
  }

  void printByBluetoothImageMode() async {
    String macAddress = global.printerConnectData.ipAddress;
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
          ui.Rect.fromLTWH(0.0, 0.0, global.printerWidthByPixel(), 20000.0),
          backgroundPaint);

      PrintProcess printProcess = PrintProcess();
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
            for (int index = 0; index < command.columns.length; index++) {
              printProcess.columnWidth.add(command.columns[index].width);
              printProcess.column.add(PrintColumn(
                text: command.columns[index].text,
                align: command.columns[index].align,
                fontSize: command.columns[index].fontSize,
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
                ui.Offset(0 + global.printerWidthByPixel(), maxHeight),
                ui.Paint());
            maxHeight += 1;
            break;
          case 4: // Line Feed
            maxHeight += command.value;
            break;
        }
      }
      final picture = recorder.endRecording();
      final imageBuffer = picture.toImage(
          global.printerWidthByPixel().toInt(), maxHeight.toInt());
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
        } catch (e) {
          print(e);
        }
      }
      bytes += generator.cut();
      bytes += generator.drawer();
      await PrintBluetoothThermal.writeBytes(bytes);
    }
  }

  void sendToPrinter() {
    switch (global.printerConnectData.printerConnectType) {
      case global.PrinterConnectEnum.ip:
        printByIpImageMode();
        break;
      case global.PrinterConnectEnum.bluetooth:
        printByBluetoothImageMode();
        break;
      case global.PrinterConnectEnum.usb:
        // TODO: Handle this case.
        break;
      case global.PrinterConnectEnum.windows:
        break;
      case global.PrinterConnectEnum.sunmi1:
        break;
    }
  }
}

void printOrderSuccess({required OrderTempObjectBoxStruct order}) {
  PrinterClass printer = PrinterClass();
  // Reset Printer
  printer.addCommand(PosPrintBillCommandModel(mode: 0));
  printer.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 24,
            width: 1,
            text: "Printing time : " +
                DateFormat("dd/MM/yyyy - HH:mm").format(DateTime.now()),
            align: global.PrintColumnAlign.center)
      ]));
  printer.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 80,
            width: 1,
            text: "นำส่งโต๊ะ : " + order.orderId,
            align: global.PrintColumnAlign.center)
      ]));
  printer.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        PosPrintBillCommandColumnModel(
            fontSize: 32,
            width: 4,
            text:
                "${global.getNameFromJsonLanguage(order.names, global.userLanguage)}-${global.getNameFromJsonLanguage(order.unitName, global.userLanguage)}",
            align: global.PrintColumnAlign.left),
        PosPrintBillCommandColumnModel(
            fontSize: 24,
            width: 1,
            text: global.moneyFormat.format(order.orderQty),
            align: global.PrintColumnAlign.right),
      ]));
  if (order.remark.trim().isNotEmpty) {
    printer.addCommand(PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          PosPrintBillCommandColumnModel(
              fontSize: 32,
              width: 1,
              text: "x หมายเหตุ x : ${order.remark}",
              align: global.PrintColumnAlign.left),
        ]));
  }
  if (order.optionSelected.isNotEmpty) {
    List<ProductProcessOptionModel> options =
        (jsonDecode(order.optionSelected) as List)
            .map((data) => ProductProcessOptionModel.fromJson(data))
            .toList();
    for (var option in options) {
      bool optionPrint = false;
      for (var choice in option.choices) {
        if (choice.selected!) {
          if (optionPrint == false) {
            printer.addCommand(PosPrintBillCommandModel(
                mode: 2,
                posStyles: const PosStyles(bold: false),
                columns: [
                  PosPrintBillCommandColumnModel(
                      fontSize: 32,
                      width: 1,
                      text: " * ${option.names[0].name}",
                      align: global.PrintColumnAlign.left),
                ]));
            optionPrint = true;
          }
          printer.addCommand(PosPrintBillCommandModel(
              mode: 2,
              posStyles: const PosStyles(bold: false),
              columns: [
                PosPrintBillCommandColumnModel(
                    fontSize: 32,
                    width: 1,
                    text: "   - ${choice.names[0].name}",
                    align: global.PrintColumnAlign.left),
              ]));
        }
      }
    }
  }

  printer.addCommand(PosPrintBillCommandModel(
    mode: 4,
    value: 80,
  ));
  printer.sendToPrinter();
}
