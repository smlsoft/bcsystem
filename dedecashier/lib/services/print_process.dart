import 'package:dedecashier/global_model.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:dedecashier/global.dart' as global;
import 'package:collection/collection.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';

enum PrintColumnAlign { left, right, center }

class PrintColumn {
  late String text;
  late PrintColumnAlign align;
  late double fontSize;
  late bool bold;

  PrintColumn({required this.text, this.align = PrintColumnAlign.left, this.fontSize = 24, this.bold = false});
}

class PrintProcess {
  final PrinterLocalStrongDataModel printerData;
  List<PrintColumn> column = [];
  List<double> columnWidth = [];

  PrintProcess({required this.printerData});

  /*Future<int> thaiCount(String word) async {
    int result = 0;
    await global.thaiEncode(word).then((value) {
      Uint8List ascii = Uint8List.fromList(value);
      for (int index = 0; index < ascii.length; index++) {
        int char = ascii[index];
        if (char != 209 &&
            !(char >= 212 && char <= 217) &&
            !(char >= 231 && char <= 237)) {
          result++;
        }
      }
    });
    return result;
  }*/

  /*Future<void> lineFeedText(NetworkPrinter printer, PosStyles style) async {
    List<List<PrintColumn>> rowList = [];
    int lastChar = 0;
    List<int> columnPositionList = [];
    List<int> columnWidthList = [];

    // Calc Width
    int sumColumnWidth = columnWidth.sum.toInt();
    int position = 0;
    for (int loop = 0; loop < columnWidth.length; loop++) {
      columnPositionList.add(position);
      double calc = (global.printerWidthByCharacter() * columnWidth[loop]) /
          sumColumnWidth;
      calc = calc / style.width.value;
      columnWidthList.add(calc.toInt());
      position += columnWidthList[loop];
    }
    if (columnWidthList.length > 1) {
      columnWidthList[columnWidthList.length - 1] +=
          global.printerWidthByCharacter() - columnWidthList.sum.toInt();
    }
    // Build Row
    for (int loop1 = 0; loop1 < 10; loop1++) {
      List<PrintColumn> columnList = [];
      for (int loop2 = 0; loop2 < columnWidth.length; loop2++) {
        columnList.add(PrintColumn(text: "", align: column[loop2].align));
      }
      rowList.add(columnList);
    }
    String firstBreak = "ใโไเแ";
    String endBreak = "ๆฯะ";
    for (int columnIndex = 0; columnIndex < column.length; columnIndex++) {
      String word = column[columnIndex].text.replaceAll(" ", "๛");
      //String word = column[columnIndex].text;
      for (int loop2 = 0; loop2 < firstBreak.length; loop2++) {
        word = word.replaceAll(firstBreak[loop2], " ${firstBreak[loop2]}");
      }
      for (int loop2 = 0; loop2 < endBreak.length; loop2++) {
        word = word.replaceAll(endBreak[loop2], "${endBreak[loop2]} ");
      }
      List<String> splitList = word.split(" ");
      int rowNumber = 0;
      int loopIndex = 0;
      while (loopIndex < splitList.length) {
        if (await thaiCount(splitList[loopIndex]) >
            columnWidthList[columnIndex] - 1) {
          rowList[rowNumber][columnIndex].text = splitList[loopIndex]
              .substring(0, columnWidthList[columnIndex] + 1);
          splitList[loopIndex] =
              splitList[loopIndex].substring(columnWidthList[columnIndex]);
          rowNumber++;
        } else {
          if (await thaiCount(
                  rowList[rowNumber][columnIndex].text + splitList[loopIndex]) >
              columnWidthList[columnIndex] - 1) {
            rowNumber++;
          }
          rowList[rowNumber][columnIndex].text =
              rowList[rowNumber][columnIndex].text +
                  splitList[loopIndex].replaceAll("๛", " ");
          loopIndex++;
        }
      }
    }
    // Process
    for (int line = 9; line > 0; line--) {
      bool remove = true;
      for (int loop = 0; loop < column.length && remove; loop++) {
        while (rowList[line][loop].text.isNotEmpty &&
            rowList[line][loop].text[0] == " ") {
          rowList[line][loop].text = rowList[line][loop].text.substring(1);
        }
        if (rowList[line][loop].text.trim().isNotEmpty) {
          remove = false;
        }
      }
      if (remove) {
        rowList.removeAt(line);
      }
    }
    for (int rowIndex = 0; rowIndex < rowList.length; rowIndex++) {
      for (int columnIndex = 0; columnIndex < column.length; columnIndex++) {
        if (column[columnIndex].align == PrintColumnAlign.right) {
          StringBuffer space = StringBuffer();
          int thaiLength = await thaiCount(rowList[rowIndex][columnIndex].text);
          for (int loop = 0;
              loop < columnWidthList[columnIndex] - thaiLength;
              loop++) {
            space.write(" ");
          }
          rowList[rowIndex][columnIndex].text =
              space.toString() + rowList[rowIndex][columnIndex].text;
        } else if (column[columnIndex].align == PrintColumnAlign.center) {
          StringBuffer space = StringBuffer();
          int thaiLength = await thaiCount(rowList[rowIndex][columnIndex].text);
          for (int loop = 0;
              loop < (columnWidthList[columnIndex] - thaiLength) / 2;
              loop++) {
            space.write(" ");
          }
          rowList[rowIndex][columnIndex].text =
              space.toString() + rowList[rowIndex][columnIndex].text;
        }
      }
    }
    for (int rowIndex = 0; rowIndex < rowList.length; rowIndex++) {
      List<List<int>> row = [];
      for (int lineIndex = 0; lineIndex < 10; lineIndex++) {
        for (int loopRow = 0; loopRow < 4; loopRow++) {
          List<int> lineList = [];
          for (int loopColumn = 0;
              loopColumn < global.printerWidthByCharacter();
              loopColumn++) {
            lineList.add((loopRow == 0) ? 32 : 0);
          }
          row.add(lineList);
        }
      }
      for (int loop = 0; loop < column.length; loop++) {
        String word = rowList[rowIndex][loop].text;
        int pos = columnPositionList[loop] - 1;
        int columnLength = 0;
        Uint8List asciiCode = Uint8List.fromList(await global.thaiEncode(word));
        for (int index = 0; index < word.length; index++) {
          int char = asciiCode[index];
          if (pos < global.printerWidthByCharacter() - 1 &&
              columnLength < columnWidthList[loop]) {
            if (char == 216 || char == 217) {
              row[1][pos] = char;
            } else if (char == 209 ||
                (char >= 212 && char <= 215) ||
                (char >= 231 && char <= 237)) {
              if (lastChar == 209 || (char >= 212 && char <= 215)) {
                row[3][pos] = char;
              } else {
                row[2][pos] = char;
              }
            } else {
              pos++;
              row[0][pos] = char;
              columnLength++;
            }
            lastChar = char;
          }
        }
      }
      List<int> packList = [];
      for (int loop = 0; loop < global.printerWidthByCharacter(); loop++) {
        for (int loopRow = 0; loopRow < 4; loopRow++) {
          if (row[loopRow][loop] != 0) {
            packList.add(row[loopRow][loop]);
          }
        }
      }
      var dataPrint = await global.thaiEncode((await CharsetConverter.decode(
              "TIS620", Uint8List.fromList(packList)))
          .toString());
      printer.textEncoded(dataPrint, styles: style);
    }
    column.clear();
  }*/

  /*Future<void> drawLine(NetworkPrinter printer) async {
    StringBuffer line = StringBuffer();
    for (int loop = 0; loop < global.printerWidthByCharacter(); loop++) {
      line.write("-");
    }
    printer.text(line.toString());
  }*/

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

    canvas.drawRect(Rect.fromLTWH(0.0, 0.0, global.printerWidthByPixel(printerData), 10000.0), backgroundPaint);

    for (int loop = 0; loop < columnWidth.length; loop++) {
      columnPositionList.add(position);
      double calc = (global.printerWidthByPixel(printerData) * columnWidth[loop]) / sumColumnWidth;
      calc = calc / style.width.value;
      columnWidthList.add(calc);
      position += columnWidthList[loop];
    }
    // Build Row
    for (int rowIndex = 0; rowIndex < 20; rowIndex++) {
      List<PrintColumn> columnList = [];
      for (int columnIndex = 0; columnIndex < columnWidth.length; columnIndex++) {
        columnList.add(PrintColumn(text: (rowIndex == 0) ? column[columnIndex].text : "", align: column[columnIndex].align, fontSize: column[columnIndex].fontSize));
      }
      rowList.add(columnList);
    }
    // Cut
    for (int rowIndex = 0; rowIndex < 20; rowIndex++) {
      for (int columnIndex = 0; columnIndex < columnWidth.length; columnIndex++) {
        String textColumn = rowList[rowIndex][columnIndex].text.trim();
        if (textColumn.isNotEmpty) {
          TextSpan span = TextSpan(
            style: TextStyle(
              color: Colors.black,
              fontSize: column[columnIndex].fontSize,
              //  fontFamily: 'nato'
            ),
            text: textColumn,
          );
          TextPainter tp = TextPainter(text: span, textDirection: ui.TextDirection.ltr);
          tp.layout();
          double textWidth = tp.width;
          if (textWidth > columnWidthList[columnIndex]) {
            int textLength = textColumn.length;
            int cut = (textLength * columnWidthList[columnIndex] / textWidth).floor() - 1;
            rowList[rowIndex][columnIndex].text = textColumn.substring(0, cut);
            rowList[rowIndex + 1][columnIndex].text = textColumn.substring(cut);
          }
        }
      }
    }
    // Process
    for (int rowIndex = 19; rowIndex > 0; rowIndex--) {
      bool remove = true;
      for (int columnIndex = 0; columnIndex < column.length && remove; columnIndex++) {
        while (rowList[rowIndex][columnIndex].text.isNotEmpty && rowList[rowIndex][columnIndex].text[0] == " ") {
          rowList[rowIndex][columnIndex].text = rowList[rowIndex][columnIndex].text.substring(1);
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
            // fontFamily: 'nato'
          ),
          text: text,
        );
        TextPainter tp = TextPainter(
          text: span,
          textAlign: (column[columnIndex].align == PrintColumnAlign.right)
              ? TextAlign.right
              : ((column[columnIndex].align == PrintColumnAlign.center))
              ? TextAlign.center
              : TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        tp.layout(minWidth: columnWidthList[columnIndex]);
        tp.paint(canvas, Offset(dx, maxHeight.toDouble()));
        dx += columnWidthList[columnIndex];
        if (tp.height > rowHeight) {
          rowHeight = tp.height.toInt();
        }
      }
      maxHeight += rowHeight;
    }
    column.clear();
    return await recorder.endRecording().toImage(global.printerWidthByPixel(printerData).toInt(), maxHeight + 1);
  }
}
