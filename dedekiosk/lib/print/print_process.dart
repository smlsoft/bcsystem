import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/print/print.dart' as print;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:collection/collection.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';

class PrintColumn {
  late String text;
  late global.PrintColumnAlign align;
  late double fontSize;
  late bool bold;

  PrintColumn(
      {required this.text,
      this.align = global.PrintColumnAlign.left,
      this.fontSize = 24,
      this.bold = false});
}

class PrintProcess {
  final int printerIndex;
  final PrinterLocalConfigModel printerData;
  List<PrintColumn> column = [];
  List<double> columnWidth = [];

  PrintProcess({
    required this.printerIndex,
    required this.printerData,
  });

  Future<ui.Image> lineFeedImage(PosStyles style) async {
    List<List<PrintColumn>> rowList = [];
    List<double> columnPositionList = [];
    List<double> columnWidthList = [];
    int sumColumnWidth = columnWidth.sum.toInt();
    double position = 0;
    int maxHeight = 0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(
        Rect.fromLTWH(0.0, 0.0,
            print.printerWidthByPixel(printerIndex, printerData), 10000.0),
        backgroundPaint);

    for (int loop = 0; loop < columnWidth.length; loop++) {
      columnPositionList.add(position);
      double calc = (print.printerWidthByPixel(printerIndex, printerData) *
              columnWidth[loop]) /
          sumColumnWidth;
      calc = calc / style.width.value;
      columnWidthList.add(calc);
      position += columnWidthList[loop];
    }
    // Build Row
    for (int rowIndex = 0; rowIndex < 20; rowIndex++) {
      List<PrintColumn> columnList = [];
      for (int columnIndex = 0;
          columnIndex < columnWidth.length;
          columnIndex++) {
        columnList.add(PrintColumn(
            text: (rowIndex == 0) ? column[columnIndex].text : "",
            align: column[columnIndex].align,
            fontSize: column[columnIndex].fontSize));
      }
      rowList.add(columnList);
    }
    // Cut
    for (int rowIndex = 0; rowIndex < 20; rowIndex++) {
      for (int columnIndex = 0;
          columnIndex < columnWidth.length;
          columnIndex++) {
        String textColumn = rowList[rowIndex][columnIndex].text.trim();
        if (textColumn.isNotEmpty) {
          TextSpan span = TextSpan(
              style: TextStyle(
                  color: Colors.black,
                  fontSize: column[columnIndex].fontSize,
                  fontFamily: 'Prompt'),
              text: textColumn);
          TextPainter tp =
              TextPainter(text: span, textDirection: ui.TextDirection.ltr);
          tp.layout();
          double textWidth = tp.width;
          if (textWidth > columnWidthList[columnIndex]) {
            int textLength = textColumn.length;
            int cut = (textLength * columnWidthList[columnIndex] / textWidth)
                    .floor() -
                1;
            rowList[rowIndex][columnIndex].text = textColumn.substring(0, cut);
            rowList[rowIndex + 1][columnIndex].text = textColumn.substring(cut);
          }
        }
      }
    }
    // Process
    for (int rowIndex = 19; rowIndex > 0; rowIndex--) {
      bool remove = true;
      for (int columnIndex = 0;
          columnIndex < column.length && remove;
          columnIndex++) {
        while (rowList[rowIndex][columnIndex].text.isNotEmpty &&
            rowList[rowIndex][columnIndex].text[0] == " ") {
          rowList[rowIndex][columnIndex].text =
              rowList[rowIndex][columnIndex].text.substring(1);
        }
        if (rowList[rowIndex][columnIndex].text.trim().isNotEmpty) {
          remove = false;
          break;
        }
      }
      if (remove) {
        rowList.removeAt(rowIndex);
      }
    }
    for (int rowIndex = 0; rowIndex < rowList.length; rowIndex++) {
      double dx = 0;
      int rowHeight = 0;
      for (int columnIndex = 0; columnIndex < column.length; columnIndex++) {
        String text = rowList[rowIndex][columnIndex].text;
        TextSpan span = TextSpan(
            style: TextStyle(
                color: Colors.black,
                fontSize: column[columnIndex].fontSize,
                fontWeight: (column[columnIndex].bold) ? FontWeight.bold : null,
                fontFamily: 'Prompt'),
            text: text);
        TextPainter tp = TextPainter(
            text: span,
            textAlign:
                (column[columnIndex].align == global.PrintColumnAlign.right)
                    ? TextAlign.right
                    : ((column[columnIndex].align ==
                            global.PrintColumnAlign.center))
                        ? TextAlign.center
                        : TextAlign.left,
            textDirection: TextDirection.ltr);
        tp.layout(
          minWidth: columnWidthList[columnIndex],
        );
        tp.paint(canvas, Offset(dx, maxHeight.toDouble()));
        dx += columnWidthList[columnIndex];
        if (tp.height > rowHeight) {
          rowHeight = tp.height.toInt();
        }
      }
      maxHeight += rowHeight;
    }
    column.clear();
    return await recorder.endRecording().toImage(
        print.printerWidthByPixel(printerIndex, printerData).toInt(),
        maxHeight + 1);
  }
}
