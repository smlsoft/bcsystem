import 'dart:async';
import 'dart:io';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/print/print_process.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io' as io;
import 'package:image/image.dart' as im;
import 'package:dedekiosk/global.dart' as global;
// import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dedekiosk/util/logger.dart';

double printerWidthByPixel(
    int printerIndex, PrinterLocalConfigModel printerData) {
  if (printerData.paperType == 1) {
    return 384;
  } else {
    return 576;
  }
}

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
  List<int> imageBytes = [];
  bool openCashDrawer;

  PrinterClass({
    required this.printerIndex,
    required this.qrCode,
    required this.openCashDrawer,
  });

  double paperMaxWidth(PrinterLocalConfigModel printerData) {
    return (printerData.paperType == 1) ? 378.0 : 575.0;
  }

  List<PosPrintBillCommandModel> commandList = [];

  void addCommand(PosPrintBillCommandModel command) {
    commandList.add(command);
  }

  Future<void> createImage(
      {required PrinterLocalConfigModel printerData,
      required String docNumber,
      required bool printLogo,
      required bool saveToFile,
      String memberPinCode = "",
      bool isBCMember = false}) async {
    PaperSize paper =
        (printerData.paperType == 1) ? PaperSize.mm58 : PaperSize.mm80;
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(paper, profile);
    double width = printerWidthByPixel(printerIndex, printerData);
    try {
      double maxHeight = 0;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final backgroundPaint = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.fill;

      canvas.drawRect(
          ui.Rect.fromLTWH(0.0, 0.0, width, 20000.0), backgroundPaint);

      PrintProcess printCommand =
          PrintProcess(printerIndex: printerIndex, printerData: printerData);
      if (qrCode.isNotEmpty) {
        double width = paperMaxWidth(printerData);
        ui.Image result = await QrPainter(
          data: qrCode,
          version: QrVersions.auto,
          gapless: false,
        ).toImage(width / 3);
        maxHeight += 20;
        canvas.drawImage(
            result,
            ui.Offset(
                (width / 2.0) - (result.width.toDouble() / 2.0), maxHeight),
            ui.Paint());
        maxHeight += result.height.toDouble() + 20;
      }
      for (var command in commandList) {
        // 0=Reset,1=Logo Image,2=Text,3=Line,9=Cut
        switch (command.mode) {
          case 0: // Reset
            break;
          case 1: // Logo Image
            if (printLogo) {
              if (command.image != null) {
                ui.Image? logo;
                ui.decodeImageFromList(command.image!, (result) {
                  logo = result;
                });
                while (logo == null) {
                  await Future.delayed(
                      Duration(milliseconds: global.printerDelayMilliseconds));
                }
                canvas.drawImage(logo!,
                    Offset((width - logo!.width) / 2, maxHeight), ui.Paint());
                maxHeight += logo!.height.toDouble();
              }
            }
            break;
          case 2: // Text
            printCommand.columnWidth.clear();
            printCommand.column.clear();
            for (int index = 0; index < command.columns!.length; index++) {
              printCommand.columnWidth.add(command.columns![index].width);
              printCommand.column.add(PrintColumn(
                text: command.columns![index].text,
                align: command.columns![index].align,
                fontSize: command.columns![index].fontSize,
              ));
            }
            ui.Image result = await printCommand
                .lineFeedImage(command.posStyles ?? const PosStyles());
            canvas.drawImage(result, ui.Offset(0, maxHeight), ui.Paint());
            maxHeight += result.height.toDouble();
            break;
          case 3: // Line
            canvas.drawLine(ui.Offset(0, maxHeight),
                ui.Offset(width, maxHeight), ui.Paint());
            maxHeight += 1;
            break;
          case 4: // Line Feed
            maxHeight += command.value;
            break;
        }
      }
      imageBytes = [];
      final picture = recorder.endRecording();
      final imageBuffer = picture.toImage(width.toInt(), maxHeight.toInt());
      final pngBytes = await imageBuffer
          .then((value) => value.toByteData(format: ui.ImageByteFormat.png));
      im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
      int printMaxHeight = 200;
      int calcLoop = imageDecode!.height ~/ printMaxHeight;
      for (int i = 0; i <= calcLoop; i++) {
        try {
          im.Image croppedImage = im.copyCrop(imageDecode,
              x: 0,
              y: i * printMaxHeight,
              width: imageDecode.width,
              height: printMaxHeight);
          imageBytes += generator.imageRaster(croppedImage);
        } catch (e, s) {
          Logger.e('Error occurred', error: e, stackTrace: s);
        }
      }
      imageBytes += generator.feed(1);
      imageBytes += generator.cut();
      if (openCashDrawer) {
        imageBytes += generator.drawer();
      } // ✅ FIX: บันทึกไฟล์ก่อน (ใช้ imageDecode ที่มีอยู่แล้ว แทนที่จะสร้างใหม่จาก imageBuffer)
      // เพื่อหลีกเลี่ยง race condition ใน release mode
      if (saveToFile) {
        Logger.i("🔵 START: Saving slip to file", tag: 'SlipSave');
        Logger.d("🔵 docNumber: $docNumber", tag: 'SlipSave');
        Logger.d("🔵 memberPinCode: $memberPinCode", tag: 'SlipSave');

        try {
          final dateDirectory = await global.createPath(global.billImagePath);
          Logger.d("🔵 Directory path: ${dateDirectory.path}", tag: 'SlipSave');
          Logger.d("🔵 Directory exists: ${await dateDirectory.exists()}",
              tag:
                  'SlipSave'); // ✅ FIX 1: ใช้ timestamp เพื่อป้องกันชื่อไฟล์ซ้ำ
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          String fileName;
          if (memberPinCode.isNotEmpty) {
            // Format: docNo_memberPinCode_BC_timestamp.jpg (ถ้าเป็น BC Member)
            // Format: docNo_memberPinCode_timestamp.jpg (ถ้าเป็นระบบเดิม)
            if (isBCMember) {
              fileName = "${docNumber}_${memberPinCode}_BC_${timestamp}.jpg";
            } else {
              fileName = "${docNumber}_${memberPinCode}_${timestamp}.jpg";
            }
          } else {
            fileName = "${docNumber}_${timestamp}.jpg";
          }

          // ✅ FIX 2: ใช้ PENDING prefix เพื่อบอกว่ายังไม่พร้อม upload
          // uploadSlipWorker จะข้ามไฟล์ที่มี PENDING_ prefix
          // หลังจาก saveTransaction สำเร็จ จะเรียก renameSlipFile() เพื่อเปลี่ยนชื่อ
          final pendingFileName = "PENDING_$fileName";
          final tempPath = '${dateDirectory.path}/$pendingFileName.tmp';
          final finalPath = '${dateDirectory.path}/$pendingFileName';

          Logger.d("🔵 Temp file path: $tempPath", tag: 'SlipSave');
          Logger.d("🔵 Final file path: $finalPath", tag: 'SlipSave');

          // ✅ FIX: ใช้ imageDecode ที่มีอยู่แล้ว แทนการ decode จาก imageBuffer อีกรอบ
          // เพราะ imageBuffer อาจถูก dispose ไปแล้วใน release mode
          Logger.d("🔵 Using existing decoded image", tag: 'SlipSave');

          Logger.d(
              "🔵 Image dimensions: ${imageDecode.width}x${imageDecode.height}",
              tag: 'SlipSave');

          final jpg = im.encodeJpg(imageDecode, quality: 25);
          Logger.d(
              "🔵 Image encoded to JPG (quality: 25, size: ${jpg.length} bytes)",
              tag: 'SlipSave');

          // ✅ FIX 3: ตรวจสอบว่า encode สำเร็จ
          if (jpg.isEmpty) {
            throw Exception("JPG encoding failed - empty data");
          }

          if (jpg.length < 100) {
            throw Exception(
                "JPG encoding failed - data too small (${jpg.length} bytes)");
          }

          // ✅ FIX 4: เขียนไปยังไฟล์ชั่วคราวก่อน
          final tempFile = io.File(tempPath);
          await tempFile.writeAsBytes(jpg,
              flush: true); // flush: true = เขียนทันที
          Logger.d("🔵 Temp file written", tag: 'SlipSave');

          // ✅ FIX 5: ตรวจสอบไฟล์ชั่วคราว
          if (!await tempFile.exists()) {
            throw Exception("Temp file not created");
          }

          final tempFileSize = await tempFile.length();
          if (tempFileSize != jpg.length) {
            throw Exception(
                "Temp file size mismatch: written=${tempFileSize}, expected=${jpg.length}");
          }

          Logger.d("🔵 Temp file verified (${tempFileSize} bytes)",
              tag: 'SlipSave');

          // ✅ FIX 6: Rename เป็น Atomic operation (ป้องกัน corruption)
          final finalFile = await tempFile.rename(finalPath);

          // ✅ FIX 7: ตรวจสอบไฟล์สุดท้าย
          final finalFileSize = await finalFile.length();
          if (finalFileSize != jpg.length) {
            throw Exception(
                "Final file size mismatch: size=${finalFileSize}, expected=${jpg.length}");
          }

          Logger.i(
              "✅ Slip saved successfully: ${finalFile.path} (${finalFileSize} bytes)",
              tag: 'SlipSave');
        } catch (e, s) {
          Logger.e("❌ Failed to save slip",
              error: e, stackTrace: s, tag: 'SlipSave');

          // ✅ FIX 8: ลบไฟล์ชั่วคราวถ้ามี error
          try {
            final dateDirectory = await global.createPath(global.billImagePath);
            final tempFiles = io.Directory(dateDirectory.path)
                .listSync()
                .where((file) => file.path.endsWith('.tmp'));

            for (var tempFile in tempFiles) {
              try {
                await tempFile.delete();
                Logger.d("🔵 Cleaned up temp file: ${tempFile.path}",
                    tag: 'SlipSave');
              } catch (_) {}
            }
          } catch (_) {}
        }
      }
    } catch (e, s) {
      Logger.e('Error occurred', error: e, stackTrace: s);
    }
  }

  /// Rename slip file จาก PENDING_ prefix เป็นชื่อปกติ
  /// เรียกฟังก์ชันนี้หลังจาก saveTransaction สำเร็จแล้ว
  ///
  /// docNumber: เลขที่เอกสาร
  /// returns: true ถ้า rename สำเร็จ, false ถ้าไม่สำเร็จหรือไม่พบไฟล์
  static Future<bool> renameSlipFile(String docNumber) async {
    Logger.i("🔵 START: Renaming slip file for docNumber: $docNumber",
        tag: 'SlipRename');

    try {
      final dateDirectory = await global.createPath(global.billImagePath);
      final dir = io.Directory(dateDirectory.path);

      if (!await dir.exists()) {
        Logger.w("❌ Directory not found: ${dir.path}", tag: 'SlipRename');
        return false;
      }

      // ค้นหาไฟล์ที่ขึ้นต้นด้วย PENDING_{docNumber}_
      final files = dir.listSync();
      bool renamed = false;

      for (var file in files) {
        if (file is io.File) {
          final fileName = file.path.replaceAll("\\", "/").split("/").last;

          // ตรวจสอบว่าเป็นไฟล์ของเอกสารนี้หรือไม่
          if (fileName.startsWith("PENDING_${docNumber}_") &&
              fileName.endsWith(".jpg")) {
            // เอา PENDING_ ออก
            final newFileName = fileName.replaceFirst("PENDING_", "");
            final newPath = '${dateDirectory.path}/$newFileName';

            Logger.d("🔵 Renaming: $fileName → $newFileName",
                tag: 'SlipRename');

            try {
              await file.rename(newPath);
              Logger.i("✅ Slip file renamed successfully: $newFileName",
                  tag: 'SlipRename');
              renamed = true;
            } catch (e) {
              Logger.e("❌ Failed to rename slip file",
                  error: e, tag: 'SlipRename');
            }
          }
        }
      }

      if (!renamed) {
        Logger.w("⚠️ No PENDING slip file found for docNumber: $docNumber",
            tag: 'SlipRename');
      }

      return renamed;
    } catch (e, s) {
      Logger.e("❌ Error renaming slip file",
          error: e, stackTrace: s, tag: 'SlipRename');
      return false;
    }
  }

  /// Rename QR payment proof file จาก PENDING_QR_ prefix เป็น QR_
  /// เรียกฟังก์ชันนี้หลังจาก saveTransaction สำเร็จแล้ว
  ///
  /// orderId: orderId ที่ใช้ตอนบันทึกรูป (ก่อนได้ docNumber)
  /// returns: true ถ้า rename สำเร็จ, false ถ้าไม่สำเร็จหรือไม่พบไฟล์
  /// Rename QR proof file จาก PENDING_QR_{orderId}_ เป็น {orderDocNumber}_{timestamp}.jpg
  /// เพื่อให้ uploadQrPaymentProofWorker สามารถ upload ด้วย docNo ที่ถูกต้อง (เลข invoice)
  static Future<bool> renameSlipFileForServerDocNo({
    required String printedDocNo,
    required String serverDocNo,
  }) async {
    final searchDocNo = printedDocNo.trim();
    final finalDocNo =
        serverDocNo.trim().isEmpty ? searchDocNo : serverDocNo.trim();
    if (searchDocNo.isEmpty) return false;
    Logger.i(
        "START: Renaming slip file for printedDocNo: $searchDocNo, serverDocNo: $finalDocNo",
        tag: 'SlipRename');

    try {
      final dateDirectory = await global.createPath(global.billImagePath);
      final dir = io.Directory(dateDirectory.path);

      if (!await dir.exists()) {
        Logger.w("Directory not found: ${dir.path}", tag: 'SlipRename');
        return false;
      }

      final files = dir.listSync();
      bool renamed = false;

      for (var file in files) {
        if (file is! io.File) continue;
        final fileName = file.path.replaceAll("\\", "/").split("/").last;
        String? newFileName;

        if (fileName.startsWith("PENDING_${searchDocNo}_") &&
            fileName.endsWith(".jpg")) {
          final suffix = fileName.substring("PENDING_$searchDocNo".length);
          newFileName = "$finalDocNo$suffix";
        } else if (finalDocNo != searchDocNo &&
            fileName.startsWith("${searchDocNo}_") &&
            fileName.endsWith(".jpg")) {
          final suffix = fileName.substring(searchDocNo.length);
          newFileName = "$finalDocNo$suffix";
        }

        if (newFileName == null || newFileName == fileName) continue;

        final newPath = '${dateDirectory.path}/$newFileName';
        Logger.d("Renaming slip: $fileName -> $newFileName", tag: 'SlipRename');

        try {
          await file.rename(newPath);
          Logger.i("Slip file renamed successfully: $newFileName",
              tag: 'SlipRename');
          renamed = true;
        } catch (e) {
          Logger.e("Failed to rename slip file", error: e, tag: 'SlipRename');
        }
      }

      if (!renamed) {
        Logger.w(
            "No slip file found for printedDocNo: $searchDocNo, serverDocNo: $finalDocNo",
            tag: 'SlipRename');
      }

      return renamed;
    } catch (e, s) {
      Logger.e("Error renaming slip file",
          error: e, stackTrace: s, tag: 'SlipRename');
      return false;
    }
  }

  static Future<bool> renameQrProofFile(
      String orderId, String orderDocNumber) async {
    Logger.i(
        "🟢 START: Renaming QR proof file for orderId: $orderId, orderDocNumber: $orderDocNumber",
        tag: 'QrProofRename');

    try {
      final directory = await getApplicationDocumentsDirectory();
      final qrProofDir =
          io.Directory('${directory.path}/${global.qrPaymentProofPath}');

      Logger.d("🟢 QR proof directory: ${qrProofDir.path}",
          tag: 'QrProofRename');

      if (!await qrProofDir.exists()) {
        Logger.w("❌ QR proof directory not found: ${qrProofDir.path}",
            tag: 'QrProofRename');
        return false;
      }

      // ค้นหาไฟล์ที่ขึ้นต้นด้วย PENDING_QR_{orderId}_
      final files = qrProofDir.listSync();
      Logger.d("🟢 Total files in QR proof dir: ${files.length}",
          tag: 'QrProofRename');

      bool renamed = false;
      final String searchPattern = "PENDING_QR_${orderId}_";
      Logger.d("🟢 Searching for files matching pattern: $searchPattern*.jpg",
          tag: 'QrProofRename');

      for (var file in files) {
        if (file is io.File) {
          final fileName = file.path.replaceAll("\\", "/").split("/").last;
          Logger.d("🟢 Checking file: $fileName", tag: 'QrProofRename');

          // ตรวจสอบว่าเป็นไฟล์ของ order นี้หรือไม่
          if (fileName.startsWith(searchPattern) && fileName.endsWith(".jpg")) {
            // ดึง timestamp จากชื่อไฟล์เดิม: PENDING_QR_{orderId}_{timestamp}.jpg
            final timestamp = fileName
                .replaceFirst(searchPattern, "")
                .replaceFirst(".jpg", "");

            // ใช้ชื่อไฟล์ใหม่เป็น {orderDocNumber}_{timestamp}.jpg (เหมือน slip)
            final newFileName = "${orderDocNumber}_$timestamp.jpg";
            final newPath = '${qrProofDir.path}/$newFileName';

            Logger.d("🟢 Renaming: $fileName → $newFileName",
                tag: 'QrProofRename');

            try {
              await file.rename(newPath);
              Logger.i("✅ QR proof file renamed successfully: $newFileName",
                  tag: 'QrProofRename');
              renamed = true;
            } catch (e) {
              Logger.e("❌ Failed to rename QR proof file",
                  error: e, tag: 'QrProofRename');
            }
          }
        }
      }

      if (!renamed) {
        Logger.d(
            "ℹ️ No PENDING QR proof file found for orderId: $orderId (this is normal if isslipsave=false)",
            tag: 'QrProofRename');
      }

      return renamed;
    } catch (e, s) {
      Logger.e("❌ Error renaming QR proof file",
          error: e, stackTrace: s, tag: 'QrProofRename');
      return false;
    }
  }

  /*Future<void> printByBluetoothImageMode({required PrinterLocalConfigModel printerData}) async {
    String macAddress = printerData.ipAddress;
    bool connectStatus = false;
    try {
      int count = 0;
      while (connectStatus == false) {
        await Future.delayed(const Duration(seconds: 1));
        count++;
        if (count > 5) {
          break;
        }
        await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
        connectStatus = await PrintBluetoothThermal.connectionStatus;
        if (connectStatus) {
          break;
        }
      }
      if (connectStatus == true) {
        int count = 0;
        while (true) {
          await Future.delayed(const Duration(seconds: 1));
          count++;
          if (count > 10) {
            break;
          }
          var result = await PrintBluetoothThermal.writeBytes(imageBytes);
          if (result) {
            break;
          }
        }
        // reset command
        await Future.delayed(const Duration(seconds: 2));
        await PrintBluetoothThermal.disconnect;
      }
    } catch (e, s) {
      Logger.e('Error occurred', error: e, stackTrace: s);
    }
  }*/

  Future<void> printByUsbImageMode(
      {required PrinterLocalConfigModel printerData}) async {
    final flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
    Printer printer = Printer(
      name: printerData.deviceName,
      address: printerData.ipAddress,
      productId: printerData.productId,
      vendorId: printerData.vendorId,
      connectionType: ConnectionType.USB,
    );

    try {
      await flutterThermalPrinterPlugin.printData(printer, imageBytes,
          longData: true);
    } catch (e, s) {
      Logger.e('USB printer error: ${printerData.deviceName}',
          error: e, stackTrace: s);
      rethrow; // ส่ง exception ออกไปให้ caller จัดการ
    }
  }

  Future<void> printByIpImageMode({
    required PrinterLocalConfigModel printerData,
  }) async {
    try {
      Socket socket = await Socket.connect(
        printerData.ipAddress,
        printerData.ipPort,
        timeout: const Duration(seconds: 5),
      );
      socket.add(imageBytes);
      await Future.delayed(const Duration(seconds: 1));
      await socket.flush();
      await Future.delayed(const Duration(seconds: 1));
      await socket.close();
      await Future.delayed(const Duration(seconds: 1));
    } catch (e, s) {
      Logger.e(
          'Printer connection error: ${printerData.ipAddress}:${printerData.ipPort}',
          error: e,
          stackTrace: s);
      rethrow; // ส่ง exception ออกไปให้ caller จัดการ
    }
  }

  Future<void> sendToPrinter(
      {required PrinterLocalConfigModel printerData,
      required bool saveToFile,
      required bool printLogo,
      required docNumber,
      String memberPinCode = "",
      bool isBCMember = false}) async {
    // ✅ FIX: แยกการสร้างรูปออกจากการพิมพ์ - สร้างรูปเสมอ
    // เพื่อให้ได้รูปใบเสร็จสำหรับ upload แม้เครื่องพิมพ์ offline
    try {
      await createImage(
          printerData: printerData,
          docNumber: docNumber,
          saveToFile: saveToFile,
          printLogo: printLogo,
          memberPinCode: memberPinCode,
          isBCMember: isBCMember);
      Logger.i('✅ Receipt image created successfully for docNo: $docNumber',
          tag: 'PrintReceipt');
    } catch (e) {
      Logger.e('❌ Failed to create receipt image for docNo: $docNumber',
          error: e, tag: 'PrintReceipt');
      // ไม่ return เพื่อให้พยายามพิมพ์ต่อ (ถ้าเป็น error แปลกๆ)
    }

    // พยายามพิมพ์ (ถ้าทำได้) - แยกออกจากการสร้างรูป
    try {
      // ✅ เพิ่ม timeout protection เพื่อไม่ให้ค้างที่เครื่องพิมพ์ offline
      await _attemptToPrint(printerData).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Printer connection timeout (10s)');
        },
      );
      Logger.i('✅ Printing completed successfully', tag: 'PrintReceipt');
    } catch (e) {
      Logger.w('⚠️ Printer offline or failed for docNo: $docNumber - $e',
          tag: 'PrintReceipt');
      // ไม่ throw error เพราะรูปใบเสร็จสร้างแล้ว (สำคัญสำหรับ upload)
    }
  }

  /// แยกส่วนการพิมพ์ออกมาเป็นฟังก์ชันแยก
  /// แยกส่วนการพิมพ์ออกมาเป็นฟังก์ชันแยก
  Future<void> _attemptToPrint(PrinterLocalConfigModel printerData) async {
    // ตรวจสอบ printerData ตาม connection type
    switch (global.printerConnectToEnum(printerData.printerConnectType)) {
      case global.PrinterConnectEnum.ip:
        // IP mode: ต้องมี ipAddress และ ipPort
        if (printerData.ipAddress.isNotEmpty && printerData.ipPort > 0) {
          await printByIpImageMode(printerData: printerData);
        } else {
          Logger.w(
              'Printer IP not configured: ipAddress="${printerData.ipAddress}", ipPort=${printerData.ipPort}');
        }
        break;
      case global.PrinterConnectEnum.bluetooth:
        // await printByBluetoothImageMode(printerData: printerData);
        break;
      case global.PrinterConnectEnum.windows:
        break;
      case global.PrinterConnectEnum.usb:
        // USB mode: ต้องมี vendorId หรือ productId (code/deviceId อาจเป็น "" ใน saved config)
        if (printerData.vendorId.isNotEmpty ||
            printerData.productId.isNotEmpty ||
            printerData.code.isNotEmpty ||
            printerData.deviceId.isNotEmpty) {
          await printByUsbImageMode(printerData: printerData);
        } else {
          Logger.w(
              'Printer USB not configured: vendorId="${printerData.vendorId}", productId="${printerData.productId}"');
        }
        break;
    }
  }

  Future<void> createImageFromUrl(
      {required PrinterLocalConfigModel printerData,
      required String imageUrl}) async {
    Uint8List? getBytes = await global.loadImageFromUrl(imageUrl);
    if (getBytes == null) {
      return;
    }
    imageBytes = getBytes;
    PaperSize paper =
        (printerData.paperType == 1) ? PaperSize.mm58 : PaperSize.mm80;
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(paper, profile);
    double width = printerWidthByPixel(printerIndex, printerData);
    try {
      double maxHeight = 0;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final backgroundPaint = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.fill;

      canvas.drawRect(
          ui.Rect.fromLTWH(0.0, 0.0, width, 20000.0), backgroundPaint);

      ui.Image? genImage;
      ui.decodeImageFromList(getBytes, (result) {
        genImage = result;
      });
      while (genImage == null) {
        await Future.delayed(
            Duration(milliseconds: global.printerDelayMilliseconds));
      }
      canvas.drawImage(genImage!,
          Offset((width - genImage!.width) / 2, maxHeight), ui.Paint());
      maxHeight += genImage!.height.toDouble();

      imageBytes = [];
      final picture = recorder.endRecording();
      final imageBuffer = picture.toImage(width.toInt(), maxHeight.toInt());
      final pngBytes = await imageBuffer
          .then((value) => value.toByteData(format: ui.ImageByteFormat.png));
      im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
      int printMaxHeight = 200;
      int calcLoop = imageDecode!.height ~/ printMaxHeight;
      for (int i = 0; i <= calcLoop; i++) {
        try {
          im.Image croppedImage = im.copyCrop(imageDecode,
              x: 0,
              y: i * printMaxHeight,
              width: imageDecode.width,
              height: printMaxHeight);
          imageBytes += generator.imageRaster(croppedImage);
        } catch (e, s) {
          Logger.e('Error occurred', error: e, stackTrace: s);
        }
      }
      imageBytes += generator.feed(1);
      imageBytes += generator.cut();
    } catch (e, s) {
      Logger.e('Error occurred', error: e, stackTrace: s);
    }
  }

  Future<void> sendToPrinterByImageUrl({
    required PrinterLocalConfigModel printerData,
    required String imageUrl,
  }) async {
    await createImageFromUrl(printerData: printerData, imageUrl: imageUrl);
    switch (global.printerConnectToEnum(printerData.printerConnectType)) {
      case global.PrinterConnectEnum.ip:
        await printByIpImageMode(printerData: printerData);
        break;
      case global.PrinterConnectEnum.bluetooth:
        // await printByBluetoothImageMode(printerData: printerData);
        break;
      case global.PrinterConnectEnum.windows:
        break;
      case global.PrinterConnectEnum.usb:
        await printByUsbImageMode(printerData: printerData);
        break;
    }
  }
}
