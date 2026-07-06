import 'dart:io';
import 'dart:async';
import 'package:dedecashier/api/clickhouse/clickhouse_api.dart';
import 'package:dedecashier/db/shift_helper.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/form_design_struct.dart';
import 'package:dedecashier/model/objectbox/shift_struct.dart';
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:dedecashier/services/print_process.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/features/pos/presentation/screens/pos_print.dart';
import 'package:dedecashier/features/pos/presentation/models/shift_report_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class PrinterClass {
  int printerIndex;
  DateTime docDate;
  String docNo;
  String qrCode;
  bool printPaySLip;
  List<String> productNames; // ⭐ ชื่อสินค้าสำหรับ kitchen prints

  PrinterClass({required this.printerIndex, required this.qrCode, required this.docNo, required this.docDate, this.printPaySLip = false, this.productNames = const []});

  List<PosPrintBillCommandModel> commandList = [];

  void addCommand(PosPrintBillCommandModel command) {
    commandList.add(command);
  }

  Future<void> printByIpImageMode() async {
    var imageBytes = await global.ticketCreateImage(
      printerData: global.printerLocalStrongData[printerIndex],
      docDate: DateTime.now(),
      docNumber: docNo,
      printLogo: false,
      printMaxHeight: 200,
      saveToFile: false,
      commandList: commandList,
      qrCodeBottom: qrCode,
      printPaySlip: printPaySLip,
    );
    global.savePrintQueueToFile(global.printerLocalStrongData[printerIndex].deviceName, imageBytes, false, docNo, false, productNames: productNames);
  }

  Future<void> printByBluetoothImageMode() async {
    /*String macAddress = global.printerLocalStrongData[printerIndex].ipAddress;
    await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    bool connectStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectStatus) {
      await createImage(
        printerData: global.printerLocalStrongData[printerIndex],
        docNumber: "",
        printLogo: false,
      );
      await PrintBluetoothThermal.writeBytes(imageBytes);
    }*/
  }

  Future<void> printByWindowsImageMode() async {
    var imageBytes = await global.ticketCreateImage(
      printerData: global.printerLocalStrongData[printerIndex],
      docDate: DateTime.now(),
      docNumber: docNo,
      printLogo: false,
      printMaxHeight: 200,
      saveToFile: false,
      commandList: commandList,
      qrCodeBottom: qrCode,
      printPaySlip: printPaySLip,
    );

    global.savePrintQueueToFile(global.printerLocalStrongData[printerIndex].deviceName, imageBytes, false, docNo, false, productNames: productNames);
    //   String printerName = global.printerLocalStrongData[printerIndex].deviceName;
    // global.windowsPrintRawData(printerName, imageBytes);
  }

  Future<void> sendToPrinter({required int printerIndex}) async {
    // if (global.printerLocalStrongData[printerIndex].isConfigConnectSuccess) {
    switch (global.printerLocalStrongData[printerIndex].printerConnectType) {
      case global.PrinterConnectEnum.ip:
        await printByIpImageMode();
        break;
      case global.PrinterConnectEnum.bluetooth:
        await printByBluetoothImageMode();
        break;
      case global.PrinterConnectEnum.usb:
        break;
      case global.PrinterConnectEnum.windows:
        await printByWindowsImageMode();
        break;
      case global.PrinterConnectEnum.sunmi1:
        break;
    }
  }

  // }
}

Future<void> printTableInformationAndQrCode({
  required global.TableManagerEnum tableManagerMode,
  required TableProcessObjectBoxStruct table,
  bool fullDetail = true,
  String qrCode = "",
  String fromTable = "",
  String toTable = "",
}) async {
  // printerIndex 1 = Ticket Printer
  PrinterClass printer = PrinterClass(printerIndex: 1, qrCode: qrCode, docDate: DateTime.now(), docNo: "");
  AppLogger.debug(printer.qrCode);
  // Reset Printer
  printer.addCommand(PosPrintBillCommandModel(mode: 0));
  try {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          FormDesignColumnModel(
            font_size: 40,
            width: 1,
            text: (global.profileSetting.company.names.isEmpty) ? "Error" : global.profileSetting.company.names[0].name,
            text_align: PrintColumnAlign.center,
          ),
        ],
      ),
    );
  } catch (e, s) {
    global.sendErrorToDevTeam("print.dart->printTableInformationAndQrCode", "printTableInformationAndQrCode : $e : $s");
  }
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 24, width: 1, text: DateFormat("dd/MM/yyyy - HH:mm").format(DateTime.now()), text_align: PrintColumnAlign.center)],
    ),
  );
  String tableTitle = "";
  switch (tableManagerMode) {
    case global.TableManagerEnum.openTable:
      tableTitle = "${global.findLanguageFromCountryCode("table_open", table.customer_nationality_code)} : ${table.number}";
      break;
    case global.TableManagerEnum.closeTable:
      tableTitle = "ปิดโต๊ะ : ${table.number}";
      break;
    case global.TableManagerEnum.moveTable:
      tableTitle += "ย้ายโต๊ะ จาก $fromTable ไปยัง : $toTable";
      break;
    case global.TableManagerEnum.mergeTable:
      break;
    case global.TableManagerEnum.informationTable:
      break;
    case global.TableManagerEnum.splitTable:
      break;
  }
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 40, width: 1, text: tableTitle, text_align: PrintColumnAlign.center)],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        FormDesignColumnModel(
          font_size: 30,
          width: 1,
          text: "${global.findLanguageFromCountryCode("table_open_time", table.customer_nationality_code)} : ${DateFormat("HH:mm").format(table.table_open_datetime)}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );
  if (table.table_al_la_crate_mode == false) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          FormDesignColumnModel(font_size: 30, width: 1, text: "จำนวนนาที : ${global.moneyFormat.format(global.buffetMaxMinute)} นาที", text_align: PrintColumnAlign.center),
        ],
      ),
    );
    String endTime = DateFormat("HH:mm").format(table.table_open_datetime.add(Duration(minutes: global.buffetMaxMinute)));
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [FormDesignColumnModel(font_size: 30, width: 1, text: "เวลาปิดโต๊ะ : $endTime", text_align: PrintColumnAlign.center)],
      ),
    );
  }
  if (fullDetail) {
    String countPeople = "";
    int sumPeople = table.man_count + table.woman_count;
    if (sumPeople > 1) {
      countPeople =
          "${global.findLanguageFromCountryCode("adult_count", table.customer_nationality_code)} $sumPeople ${global.findLanguageFromCountryCode("person", table.customer_nationality_code)}";
    }
    if (table.child_count > 0) {
      if (countPeople.isNotEmpty) {
        countPeople += " : ";
      }
      countPeople +=
          "${global.findLanguageFromCountryCode("child_count", table.customer_nationality_code)} ${table.child_count} ${global.findLanguageFromCountryCode("person", table.customer_nationality_code)}";
    }
    if (countPeople.isNotEmpty) {
      printer.addCommand(
        PosPrintBillCommandModel(
          mode: 2,
          posStyles: const PosStyles(bold: true),
          columns: [FormDesignColumnModel(font_size: 30, width: 1, text: countPeople, text_align: PrintColumnAlign.center)],
        ),
      );
    }
  }
  String orderType = "";
  if (table.table_al_la_crate_mode) {
    orderType = global.findLanguageFromCountryCode("alacarte", table.customer_nationality_code);
  } else {
    int buffetIndex = global.buffetModeLists.indexWhere((element) => element.code == table.buffet_code);
    if (buffetIndex != -1) {
      orderType = global.buffetModeLists[buffetIndex].names[0];
    }
  }
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        FormDesignColumnModel(
          font_size: 30,
          width: 1,
          text: "${global.findLanguageFromCountryCode("condition", table.customer_nationality_code)} : $orderType",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );
  //
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 30, width: 1, text: "Scan เพื่อตรวจสอบรายการอาหาร", text_align: PrintColumnAlign.center)],
    ),
  );
  /*printer.addCommand(PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        FormDesignColumnModel(
            font_size: 30,
            width: 1,
            text: "Scan เพื่อสั่งอาหาร",
            text_align: PrintColumnAlign.center)
      ]));*/
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 30, width: 1, text: "Scan เพื่อเรียกพนักงาน", text_align: PrintColumnAlign.center)],
    ),
  );
  //
  printer.addCommand(PosPrintBillCommandModel(mode: 4, value: 40));
  await printer.sendToPrinter(printerIndex: 1);
  {
    // update clickhouse โต๊ะ
    String query = "select tablenumber from dedeorderonline.tableinfo where tablenumber='${table.number}' and shopid='${global.shopId}'";
    var value = await clickHouseSelect(query);
    ResponseDataModel responseData = ResponseDataModel.fromJson(value);
    if (responseData.data.isNotEmpty) {
      // ถ้ามีโต๊ะแล้ว ให้ update qr code
      query = "alter table dedeorderonline.tableinfo update tablestatus=1 where tablenumber='${table.number}' and shopid='${global.shopId}'";
      await clickHouseExecute(query);
    }
  }
}

Future<void> shiftAndMoneyPrint(String guid) async {
  var data = ShiftHelper().getByGuid(guid);

  // ตรวจสอบเครื่องพิมพ์ที่พร้อมใช้งาน
  int printerIndex = -1;
  for (int i = 0; i < global.printerLocalStrongData.length; i++) {
    if (global.printerLocalStrongData[i].isConfigConnectSuccess) {
      printerIndex = i;
      break;
    }
  }

  if (printerIndex == -1) {
    AppLogger.debug("No printer available for shift money print");
    return;
  }

  PrinterClass printer = PrinterClass(printerIndex: printerIndex, qrCode: "", docNo: "", docDate: DateTime.now());

  AppLogger.debug("Shift money print started");

  // สร้างคำสั่งพิมพ์
  printer.addCommand(PosPrintBillCommandModel(mode: 0)); // Reset Printer

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 40, width: 1, text: global.profileSetting.company.names[0].name, text_align: PrintColumnAlign.center)],
    ),
  );
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        FormDesignColumnModel(
          font_size: 24,
          width: 1,
          text: "${global.language("printed_on")} : ${DateFormat("dd/MM/yyyy - HH:mm").format(DateTime.now())}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  String tableTitle = "";
  switch (data.doctype) {
    case 1:
      tableTitle = global.language("open_shift_receive_change");
      break;
    case 2:
      tableTitle = global.language("close_shift_send_money");
      break;
    case 3:
      tableTitle = global.language("add_change_money");
      break;
    case 4:
      tableTitle = global.language("withdraw_money");
      break;
  }

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 40, width: 1, text: tableTitle, text_align: PrintColumnAlign.center)],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        FormDesignColumnModel(
          font_size: 32,
          width: 1,
          text: "${global.language("datetime_label")} : ${DateFormat("dd/MM/yyyy - HH:mm").format(data.docdate)}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [FormDesignColumnModel(font_size: 32, width: 1, text: "${global.language("employee")} : ${data.username} (${data.usercode})", text_align: PrintColumnAlign.center)],
    ),
  );

  if (data.remark.isNotEmpty) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [FormDesignColumnModel(font_size: 32, width: 1, text: "${global.language("remark")} : ${data.remark}", text_align: PrintColumnAlign.center)],
      ),
    );
  }
  if (data.doctype != 1 && data.doctype != 2) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          FormDesignColumnModel(
            font_size: 32,
            width: 1,
            text: "${global.language("amount")} ${global.moneyFormat.format(data.amount)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.center,
          ),
        ],
      ),
    );
  }
  printer.addCommand(PosPrintBillCommandModel(mode: 4, value: 80));

  // พิมพ์ตามประเภทเครื่องพิมพ์
  await shiftAndMoneyPrintByPrinterType(printer: printer, printerData: global.printerLocalStrongData[printerIndex]);
}

Future<void> shiftAndMoneyPrintByPrinterType({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  if (!printerData.isConfigConnectSuccess) {
    AppLogger.debug("Printer not ready: ${printerData.deviceName}");
    return;
  }

  try {
    switch (printerData.printerConnectType) {
      case global.PrinterConnectEnum.ip:
        await shiftAndMoneyPrintByIp(printer: printer, printerData: printerData);
        break;

      case global.PrinterConnectEnum.bluetooth:
        await shiftAndMoneyPrintByBluetooth(printer: printer, printerData: printerData);
        break;

      case global.PrinterConnectEnum.usb:
        await shiftAndMoneyPrintByUsb(printer: printer, printerData: printerData);
        break;

      case global.PrinterConnectEnum.windows:
        await shiftAndMoneyPrintByWindows(printer: printer, printerData: printerData);
        break;

      case global.PrinterConnectEnum.sunmi1:
        // TODO: Implement Sunmi printing
        break;
    }
  } catch (e, s) {
    if (kDebugMode) {
      AppLogger.error('Shift money print error: $e');
      AppLogger.debug('Stack trace: $s');
    }
    global.sendErrorToDevTeam("printer.dart->shiftAndMoneyPrint", "${printerData.deviceName} : $e : $s");
  }
}

Future<void> shiftAndMoneyPrintByIp({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  // ✅ Performance monitoring (Debug mode only)
  Stopwatch? stopwatch;
  if (kDebugMode) {
    stopwatch = Stopwatch()..start();
  }

  var imageBytes = await global.ticketCreateImage(
    printerData: printerData,
    docDate: DateTime.now(),
    docNumber: printer.docNo,
    printLogo: false,
    printMaxHeight: 200,
    saveToFile: false,
    commandList: printer.commandList,
    qrCodeBottom: printer.qrCode,
    printPaySlip: printer.printPaySLip,
  );

  PaperSize paper = (printerData.paperType == 1) ? PaperSize.mm58 : PaperSize.mm80;
  CapabilityProfile profile = await CapabilityProfile.load();

  try {
    List<int> bytes = [];
    Socket socket = await Socket.connect(printerData.ipAddress, printerData.ipPort);
    final generator = Generator(paper, profile);

    // ✅ Removed Future.delayed(100ms) - not needed, socket is already connected
    bytes += generator.reset();

    img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes.toList()));
    if (image != null) {
      int printMaxHeight = 1000;
      int calcLoop = image.height ~/ printMaxHeight;

      for (int i = 0; i <= calcLoop; i++) {
        try {
          img.Image croppedImage = img.copyCrop(image, x: 0, y: i * printMaxHeight, width: image.width, height: printMaxHeight);
          bytes += generator.imageRaster(croppedImage);
        } catch (e) {
          AppLogger.error("Image crop error: $e");
        }
      }
    }

    bytes += generator.feed(3);
    bytes += generator.cut();

    socket.add(bytes);
    // ✅ Use timeout instead of Future.delayed (saves ~2,000ms)
    await socket.flush().timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        AppLogger.warning('⚠️ Socket flush timeout');
      },
    );
    await socket.close();

    // ✅ Log performance (Debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.debug('🖨️ IP print took ${stopwatch.elapsedMilliseconds}ms');
      if (stopwatch.elapsedMilliseconds > 2000) {
        AppLogger.warning('⚠️ Slow IP print detected!');
      }
    }
  } catch (e, s) {
    AppLogger.error("IP print error: $e");
    global.sendErrorToDevTeam("printer.dart->shiftAndMoneyPrintByIp", "${printerData.deviceName} : $e : $s");
  }
}

Future<void> shiftAndMoneyPrintByUsb({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  // ✅ Performance monitoring (Debug mode only)
  Stopwatch? stopwatch;
  if (kDebugMode) {
    stopwatch = Stopwatch()..start();
  }

  try {
    FlutterThermalPrinter flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
    _cachedProfile ??= await CapabilityProfile.load();

    final generator = Generator(PaperSize.mm80, _cachedProfile!);

    // สร้าง image จากคำสั่งพิมพ์
    var imageBytes = await global.ticketCreateImage(
      printerData: printerData,
      docDate: DateTime.now(),
      docNumber: printer.docNo,
      printLogo: false,
      printMaxHeight: 200,
      saveToFile: false,
      commandList: printer.commandList,
      qrCodeBottom: printer.qrCode,
      printPaySlip: printer.printPaySLip,
    );

    final imageDecode = img.decodeImage(imageBytes);
    if (imageDecode == null) {
      throw Exception('Failed to decode image');
    }

    final List<int> bytesUsb = [];
    bytesUsb.addAll(generator.reset());
    bytesUsb.addAll(generator.imageRaster(imageDecode));
    bytesUsb.addAll(generator.feed(2));
    bytesUsb.addAll(generator.cut());

    Printer printerObj = Printer(
      address: printerData.ipAddress,
      name: printerData.deviceName,
      vendorId: printerData.vendorId,
      productId: printerData.productId,
      connectionType: ConnectionType.USB,
      isConnected: false,
    );

    // Disconnect first for clean state
    // ✅ Use timeout instead of Future.delayed
    try {
      await flutterThermalPrinterPlugin
          .disconnect(printerObj)
          .timeout(
            const Duration(milliseconds: 500),
            onTimeout: () {
              AppLogger.warning('⚠️ USB disconnect timeout (ignorable)');
            },
          );
    } catch (e) {
      // Ignore disconnect errors
    }

    // Connect and print
    // ✅ Use timeout for safety (replaces 500ms delay)
    await flutterThermalPrinterPlugin
        .connect(printerObj)
        .timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            AppLogger.warning('⚠️ USB connect timeout');
            throw TimeoutException('USB connection timeout');
          },
        );

    // ✅ Use timeout for safety (replaces 800ms delay)
    await flutterThermalPrinterPlugin
        .printData(printerObj, bytesUsb)
        .timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            AppLogger.warning('⚠️ USB print data timeout');
            throw TimeoutException('USB print timeout');
          },
        );

    // ✅ Use timeout instead of Future.delayed
    await flutterThermalPrinterPlugin
        .disconnect(printerObj)
        .timeout(
          const Duration(milliseconds: 500),
          onTimeout: () {
            AppLogger.warning('⚠️ USB final disconnect timeout');
          },
        );

    // ✅ Log performance (Debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.debug('🖨️ USB print took ${stopwatch.elapsedMilliseconds}ms');
      if (stopwatch.elapsedMilliseconds > 3000) {
        AppLogger.warning('⚠️ Slow USB print detected!');
      }
    }
  } catch (e, s) {
    AppLogger.error("USB print error: $e");
    global.sendErrorToDevTeam("printer.dart->shiftAndMoneyPrintByUsb", "${printerData.deviceName} : $e : $s");
  }
}

Future<void> shiftAndMoneyPrintByBluetooth({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  // ✅ Performance monitoring (Debug mode only)
  Stopwatch? stopwatch;
  if (kDebugMode) {
    stopwatch = Stopwatch()..start();
  }

  try {
    FlutterThermalPrinter flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
    _cachedProfile ??= await CapabilityProfile.load();

    final generator = Generator(PaperSize.mm80, _cachedProfile!);

    // สร้าง image จากคำสั่งพิมพ์
    var imageBytes = await global.ticketCreateImage(
      printerData: printerData,
      docDate: DateTime.now(),
      docNumber: printer.docNo,
      printLogo: false,
      printMaxHeight: 200,
      saveToFile: false,
      commandList: printer.commandList,
      qrCodeBottom: printer.qrCode,
      printPaySlip: printer.printPaySLip,
    );

    final imageDecode = img.decodeImage(imageBytes);
    if (imageDecode == null) {
      throw Exception('Failed to decode image');
    }
    final List<int> bytesBt = [];
    bytesBt.addAll(generator.reset());
    bytesBt.addAll(generator.imageRaster(imageDecode));
    bytesBt.addAll(generator.feed(2));
    bytesBt.addAll(generator.cut());

    Printer printerObj = Printer(
      address: printerData.ipAddress,
      name: printerData.deviceName,
      vendorId: printerData.vendorId,
      productId: printerData.productId,
      connectionType: ConnectionType.BLE,
      isConnected: false,
    );

    // ✅ Use timeout for safety
    await flutterThermalPrinterPlugin
        .connect(printerObj)
        .timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            AppLogger.warning('⚠️ Bluetooth connect timeout');
            throw TimeoutException('Bluetooth connection timeout');
          },
        );

    // ✅ Use longData and chunkSize for iOS BLE compatibility
    // iOS BLE has smaller MTU (~150 bytes) than Android (~500 bytes)
    final int iosChunkSize = Platform.isIOS ? 100 : 500;
    await flutterThermalPrinterPlugin
        .printData(printerObj, bytesBt, longData: true, chunkSize: iosChunkSize)
        .timeout(
          const Duration(seconds: 10), // Increased timeout for chunked data
          onTimeout: () {
            AppLogger.warning('⚠️ Bluetooth print data timeout');
            throw TimeoutException('Bluetooth print timeout');
          },
        );

    // ✅ Use timeout instead of Future.delayed (saves ~300ms)
    await flutterThermalPrinterPlugin
        .disconnect(printerObj)
        .timeout(
          const Duration(milliseconds: 500),
          onTimeout: () {
            AppLogger.warning('⚠️ Bluetooth disconnect timeout');
          },
        );

    // ✅ Log performance (Debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.success('[Printer] 🖨️ Bluetooth print took ${stopwatch.elapsedMilliseconds}ms');
      if (stopwatch.elapsedMilliseconds > 3000) {
        AppLogger.warning('⚠️ Slow Bluetooth print detected!');
      }
    }
  } catch (e, s) {
    AppLogger.error("Bluetooth print error: $e");
    global.sendErrorToDevTeam("printer.dart->shiftAndMoneyPrintByBluetooth", "${printerData.deviceName} : $e : $s");
  }
}

Future<void> shiftAndMoneyPrintByWindows({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  try {
    var imageBytes = await global.ticketCreateImage(
      printerData: printerData,
      docDate: DateTime.now(),
      docNumber: printer.docNo,
      printLogo: false,
      printMaxHeight: 200,
      saveToFile: false,
      commandList: printer.commandList,
      qrCodeBottom: printer.qrCode,
      printPaySlip: printer.printPaySLip,
    );

    String printerName = printerData.deviceName;
    List<int> byteImg = await global.createWindowsByte(printerData, imageBytes);

    // สำหรับ shift และ money print ไม่ต้องใช้ pathName
    global.windowsPrintRawData(printerName, byteImg, "");
  } catch (e, s) {
    AppLogger.error("Windows print error: $e");
    global.sendErrorToDevTeam("printer.dart->shiftAndMoneyPrintByWindows", "${printerData.deviceName} : $e : $s");
  }
}

CapabilityProfile? _cachedProfile;

/// พิมพ์จากไฟล์ PNG
///
/// Returns: true = พิมพ์สำเร็จ, false = พิมพ์ไม่สำเร็จ
Future<bool> printFromFile({required PrinterLocalStrongDataModel printerData, required String pathName}) async {
  if (kDebugMode) {
    AppLogger.debug('🖨️ printFromFile called');
    AppLogger.debug('[Printer]    File: ${pathName.split('\\').last}');
    AppLogger.debug('Printer: ${printerData.deviceName}');
    AppLogger.debug('Connection: ${printerData.printerConnectType}');
    AppLogger.success('Config success: ${printerData.isConfigConnectSuccess}');
  }

  if (printerData.isConfigConnectSuccess) {
    AppLogger.debug('[Printer]    ✅ Printer config is valid, proceeding...');

    File file = File(pathName);

    if (!file.existsSync()) {
      AppLogger.debug('[Printer]    ❌ File does not exist: $pathName');
      return false; // ⭐ ไฟล์ไม่มี = พิมพ์ไม่สำเร็จ
    }

    AppLogger.debug('[Printer]    📄 File exists, reading bytes...');

    var bytes = file.readAsBytesSync();

    AppLogger.debug('[Printer]    📦 Read ${bytes.length} bytes');

    switch (printerData.printerConnectType) {
      case global.PrinterConnectEnum.ip:
        AppLogger.debug('[Printer]    🌐 Using IP connection');
        // ⭐ ตรวจสอบผลลัพธ์จาก printFromFileByIpImageMode
        final success = await printFromFileByIpImageMode(pathName: pathName, printerData: printerData, imageBytes: bytes);
        return success; // ส่งผลลัพธ์กลับ
      case global.PrinterConnectEnum.bluetooth:
        AppLogger.debug('[Printer]    📱 Bluetooth not implemented');
        //await printFromFileByBluetoothImageMode();
        return false; // ⭐ Bluetooth ยังไม่ implement
      case global.PrinterConnectEnum.usb:
        AppLogger.debug('[Printer]    🔌 Using USB connection');
        try {
          FlutterThermalPrinter flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
          // Load capability profile only once to prevent "Capability already load" error
          _cachedProfile ??= await CapabilityProfile.load();

          // Initialize printer settings
          final generator = Generator(PaperSize.mm80, _cachedProfile!);

          // Decode the image
          final imageDecode = img.decodeImage(bytes);
          if (imageDecode == null) {
            throw Exception('Failed to decode image from file');
          }

          // Add printer commands
          final List<int> bytesUsb = [];
          bytesUsb.addAll(generator.reset());
          bytesUsb.addAll(generator.imageRaster(imageDecode));
          bytesUsb.addAll(generator.feed(2));
          bytesUsb.addAll(generator.cut());
          bytesUsb.addAll(generator.drawer());

          // Create printer object
          Printer printer = Printer(
            address: printerData.ipAddress,
            name: printerData.deviceName,
            vendorId: printerData.vendorId,
            productId: printerData.productId,
            connectionType: ConnectionType.USB,
            isConnected: false,
          );

          // Get printer plugin instance

          // Use a safer approach with disconnect-first pattern
          try {
            // First try to disconnect to ensure clean state
            await flutterThermalPrinterPlugin.disconnect(printer);
            await Future.delayed(const Duration(milliseconds: 300));
          } catch (e) {
            // Ignore disconnect errors - it might not be connected
            AppLogger.debug("Disconnect error (ignorable): $e");
          }

          // Now connect fresh
          await flutterThermalPrinterPlugin.connect(printer);
          await Future.delayed(const Duration(milliseconds: 500));

          // Print data
          await flutterThermalPrinterPlugin.printData(printer, bytesUsb);
          await Future.delayed(const Duration(milliseconds: 800)); // Longer delay to ensure printing completes

          AppLogger.debug('[Printer]    ✅ USB print completed');

          // Always disconnect after printing
          await flutterThermalPrinterPlugin.disconnect(printer);
          await Future.delayed(const Duration(milliseconds: 300));

          // ⭐ ลบไฟล์ PNG ทันที (ไฟล์พิมพ์ใน Temp)
          // หมายเหตุ: ไฟล์ JPG สำหรับ upload/bill_list อยู่ที่ Documents/posbill/ (เก็บ 7 วัน)
          await deleteFile(pathName);

          AppLogger.debug('[Printer]    🗑️ Deleted print file: ${pathName.split('\\').last}');
          return true; // ⭐ USB พิมพ์สำเร็จ
        } catch (e, s) {
          if (kDebugMode) {
            AppLogger.error('❌ USB Printer error: $e');
            AppLogger.debug('Stack: $s');
          }

          // Try to safely disconnect if an error occurred
          try {
            Printer printer = Printer(
              address: printerData.ipAddress,
              name: printerData.deviceName,
              vendorId: printerData.vendorId,
              productId: printerData.productId,
              connectionType: ConnectionType.USB,
              isConnected: false,
            );
            await FlutterThermalPrinter.instance.disconnect(printer);
          } catch (e) {
            AppLogger.debug("Intentionally ignored: `$e");
            // errors during cleanup
          }
          // global.sendErrorToDevTeam("print.dart->printFromFile", "${printerData.deviceName} : $e : $s");
          return false; // ⭐ USB พิมพ์ไม่สำเร็จ
        }
      case global.PrinterConnectEnum.windows:
        AppLogger.debug('[Printer]    🪟 Using Windows printer');
        String printerName = printerData.deviceName;
        List<int> byteImg = await global.createWindowsByte(printerData, bytes);

        AppLogger.debug('[Printer]    📦 Created ${byteImg.length} bytes for Windows printer');

        global.windowsPrintRawData(printerName, byteImg, pathName);

        AppLogger.debug('[Printer]    ✅ Windows print job sent');
        return true; // ⭐ Windows พิมพ์สำเร็จ (fire-and-forget)
      case global.PrinterConnectEnum.sunmi1:
        AppLogger.debug('[Printer]    📱 Sunmi printer not implemented');
        return false; // ⭐ Sunmi ยังไม่ implement
    }
  } else {
    if (kDebugMode) {
      AppLogger.error('[Printer]    ❌ Printer config not ready: ${printerData.deviceName}');
      AppLogger.success('[Printer]       isConfigConnectSuccess: ${printerData.isConfigConnectSuccess}');
    }
    return false; // ⭐ Config ไม่พร้อม = พิมพ์ไม่สำเร็จ
  }
}

// ✅ Converted to async to prevent UI blocking
Future<void> deleteFile(String pathName) async {
  try {
    final file = File(pathName);
    if (await file.exists()) {
      await file.delete(recursive: true);
    }
  } catch (e) {
    AppLogger.error('⚠️ File delete error: $e');
  }
}

Future<bool> printFromFileByIpImageMode({required PrinterLocalStrongDataModel printerData, required String pathName, required Uint8List imageBytes}) async {
  if (kDebugMode) {
    AppLogger.debug('[Printer IP] 🌐 Starting IP print');
    AppLogger.debug('[Printer IP]    IP: ${printerData.ipAddress}:${printerData.ipPort}');
    AppLogger.debug('[Printer IP]    Paper: ${printerData.paperType == 1 ? "58mm" : "80mm"}');
  }

  PaperSize paper = (printerData.paperType == 1) ? PaperSize.mm58 : PaperSize.mm80;
  CapabilityProfile profile = await CapabilityProfile.load();

  try {
    List<int> bytes = [];

    AppLogger.debug('[Printer IP]    📡 Connecting to ${printerData.ipAddress}:${printerData.ipPort}');

    Socket socket = await Socket.connect(printerData.ipAddress, printerData.ipPort);

    AppLogger.debug('[Printer IP]    ✅ Socket connected');

    final generator = Generator(paper, profile);
    await Future.delayed(const Duration(milliseconds: 100));
    bytes += generator.reset();
    img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes.toList()));

    if (image == null) {
      AppLogger.debug('[Printer IP]    ❌ Failed to decode image');
      await socket.close();
      return false;
    }

    AppLogger.debug('[Printer IP]    🖼️ Image decoded: ${image.width}x${image.height}');

    // คำนวณความสูงของรูป เพื่อ delay ให้เสร็จ
    int printMaxHeight = 1000;
    int calcLoop = image.height ~/ printMaxHeight;

    AppLogger.debug('[Printer IP]    📄 Splitting into ${calcLoop + 1} chunks');

    for (int i = 0; i <= calcLoop; i++) {
      try {
        img.Image croppedImage = img.copyCrop(image, x: 0, y: i * printMaxHeight, width: image.width, height: printMaxHeight);
        bytes += generator.imageRaster(croppedImage);

        AppLogger.debug('[Printer IP]       Chunk ${i + 1}/${calcLoop + 1} processed');
      } catch (e, s) {
        AppLogger.error('[Printer IP]       ⚠️ Chunk ${i + 1} error: $e');
      }
    }
    bytes += generator.feed(3);
    bytes += generator.cut();
    bytes += generator.drawer();

    AppLogger.debug('[Printer IP]    📤 Sending ${bytes.length} bytes to printer');

    socket.add(bytes);
    await Future.delayed(const Duration(seconds: 1));
    await socket.flush();

    AppLogger.debug('[Printer IP]    ✅ Data sent, flushing...');

    await Future.delayed(const Duration(seconds: 1));
    await socket.close();

    AppLogger.debug('[Printer IP]    🔌 Socket closed');

    await Future.delayed(const Duration(seconds: 1));

    // ⭐ ลบไฟล์ PNG ทันที (ไฟล์พิมพ์ใน Temp)
    // หมายเหตุ: ไฟล์ JPG สำหรับ upload/bill_list อยู่ที่ Documents/posbill/ (เก็บ 7 วัน)
    await deleteFile(pathName);

    if (kDebugMode) {
      AppLogger.debug('[Printer IP]    🗑️ Deleted print file: ${pathName.split('\\').last}');
      AppLogger.success('[Printer IP]    🎉 Print completed successfully');
    }

    return true;
  } catch (e, s) {
    if (kDebugMode) {
      AppLogger.error('[Printer IP]    ❌ Error: $e');
      AppLogger.debug('[Printer IP]    Stack: $s');
    }
    global.sendErrorToDevTeam("print.dart->printFromFileByIpImageMode", "${printerData.deviceName} : $e : $s");
    return false;
  }
}

Future<void> printMoneyTransferReportList({required List<ShiftObjectBoxStruct> moneyTransferReports, required DateTime startDate, required DateTime endDate}) async {
  // ตรวจสอบเครื่องพิมพ์ที่พร้อมใช้งาน
  int printerIndex = -1;
  for (int i = 0; i < global.printerLocalStrongData.length; i++) {
    if (global.printerLocalStrongData[i].isConfigConnectSuccess) {
      printerIndex = i;
      break;
    }
  }

  if (printerIndex == -1) {
    AppLogger.debug("No printer available for money transfer report print");
    return;
  }

  PrinterClass printer = PrinterClass(printerIndex: printerIndex, qrCode: "", docNo: "", docDate: DateTime.now());

  AppLogger.debug("Money transfer report print started");

  // สร้างคำสั่งพิมพ์
  printer.addCommand(PosPrintBillCommandModel(mode: 0)); // Reset Printer

  // หัวเรื่อง
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 40, width: 1, text: global.profileSetting.company.names[0].name, text_align: PrintColumnAlign.center)],
    ),
  );
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 32, width: 1, text: global.language("money_transfer_list"), text_align: PrintColumnAlign.center)],
    ),
  );

  // ช่วงวันที่
  String dateRange = "${global.language("from_date")} ${DateFormat("dd/MM/yyyy").format(startDate)} - ${global.language("to_date")} ${DateFormat("dd/MM/yyyy").format(endDate)}";
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [FormDesignColumnModel(font_size: 24, width: 1, text: dateRange, text_align: PrintColumnAlign.center)],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        FormDesignColumnModel(
          font_size: 20,
          width: 1,
          text: "${global.language("printed_on")} : ${DateFormat("dd/MM/yyyy - HH:mm").format(DateTime.now())}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  // เส้นแบ่ง
  printer.addCommand(PosPrintBillCommandModel(mode: 3));

  // รายการส่งเงิน
  double totalAmount = 0;
  for (var data in moneyTransferReports) {
    totalAmount += data.amount;

    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("datetime_label")} : ${DateFormat("dd/MM/yyyy - HH:mm").format(data.docdate)}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );

    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [FormDesignColumnModel(font_size: 24, width: 1, text: "${global.language("employee")} : ${data.username} (${data.usercode})", text_align: PrintColumnAlign.left)],
      ),
    );

    if (data.remark.isNotEmpty) {
      printer.addCommand(
        PosPrintBillCommandModel(
          mode: 2,
          posStyles: const PosStyles(bold: false),
          columns: [FormDesignColumnModel(font_size: 24, width: 1, text: "${global.language("remark")} : ${data.remark}", text_align: PrintColumnAlign.left)],
        ),
      );
    }

    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [
          FormDesignColumnModel(
            font_size: 26,
            width: 1,
            text: "${global.language("amount")} ${global.moneyFormat.format(data.amount)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );

    // เส้นแบ่งระหว่างรายการ
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [FormDesignColumnModel(font_size: 20, width: 1, text: "----------------------------------------", text_align: PrintColumnAlign.center)],
      ),
    );
  }

  // เส้นแบ่งก่อนสรุป
  printer.addCommand(PosPrintBillCommandModel(mode: 3));

  // สรุปยอดรวม
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        FormDesignColumnModel(
          font_size: 32,
          width: 1,
          text: "${global.language("total_money_transfer")} ${global.moneyFormat.format(totalAmount)} ${global.language("money_symbol")}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [FormDesignColumnModel(font_size: 24, width: 1, text: "${global.language("total_records")} : ${moneyTransferReports.length}", text_align: PrintColumnAlign.center)],
    ),
  );

  printer.addCommand(PosPrintBillCommandModel(mode: 4, value: 80));

  // พิมพ์ตามประเภทเครื่องพิมพ์
  await printMoneyTransferReportByPrinterType(printer: printer, printerData: global.printerLocalStrongData[printerIndex]);
}

Future<void> printMoneyTransferReportByPrinterType({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  if (!printerData.isConfigConnectSuccess) {
    AppLogger.debug("Printer not ready: ${printerData.deviceName}");
    return;
  }

  try {
    switch (printerData.printerConnectType) {
      case global.PrinterConnectEnum.ip:
        await printMoneyTransferReportByIp(printer: printer, printerData: printerData);
        break;

      case global.PrinterConnectEnum.bluetooth:
        await printMoneyTransferReportByBluetooth(printer: printer, printerData: printerData);
        break;

      case global.PrinterConnectEnum.usb:
        await printMoneyTransferReportByUsb(printer: printer, printerData: printerData);
        break;

      case global.PrinterConnectEnum.windows:
        await printMoneyTransferReportByWindows(printer: printer, printerData: printerData);
        break;

      case global.PrinterConnectEnum.sunmi1:
        // TODO: Implement Sunmi printing
        break;
    }
  } catch (e, s) {
    if (kDebugMode) {
      AppLogger.error('Money transfer report print error: $e');
      AppLogger.debug('Stack trace: $s');
    }
    global.sendErrorToDevTeam("printer.dart->printMoneyTransferReportList", "${printerData.deviceName} : $e : $s");
  }
}

Future<void> printMoneyTransferReportByIp({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  var imageBytes = await global.ticketCreateImage(
    printerData: printerData,
    docDate: DateTime.now(),
    docNumber: printer.docNo,
    printLogo: false,
    printMaxHeight: 200,
    saveToFile: false,
    commandList: printer.commandList,
    qrCodeBottom: printer.qrCode,
    printPaySlip: printer.printPaySLip,
  );

  PaperSize paper = (printerData.paperType == 1) ? PaperSize.mm58 : PaperSize.mm80;
  CapabilityProfile profile = await CapabilityProfile.load();

  try {
    List<int> bytes = [];
    Socket socket = await Socket.connect(printerData.ipAddress, printerData.ipPort);
    final generator = Generator(paper, profile);

    await Future.delayed(const Duration(milliseconds: 100));
    bytes += generator.reset();

    img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes.toList()));
    if (image != null) {
      int printMaxHeight = 1000;
      int calcLoop = image.height ~/ printMaxHeight;

      for (int i = 0; i <= calcLoop; i++) {
        try {
          img.Image croppedImage = img.copyCrop(image, x: 0, y: i * printMaxHeight, width: image.width, height: printMaxHeight);
          bytes += generator.imageRaster(croppedImage);
        } catch (e) {
          AppLogger.error("Image crop error: $e");
        }
      }
    }

    bytes += generator.feed(3);
    bytes += generator.cut();

    socket.add(bytes);
    await Future.delayed(const Duration(seconds: 1));
    await socket.flush();
    await Future.delayed(const Duration(seconds: 1));
    await socket.close();
  } catch (e, s) {
    AppLogger.error("IP print error: $e");
    global.sendErrorToDevTeam("printer.dart->printMoneyTransferReportByIp", "${printerData.deviceName} : $e : $s");
  }
}

Future<void> printMoneyTransferReportByUsb({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  try {
    FlutterThermalPrinter flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
    _cachedProfile ??= await CapabilityProfile.load();

    final generator = Generator(PaperSize.mm80, _cachedProfile!);

    // สร้าง image จากคำสั่งพิมพ์
    var imageBytes = await global.ticketCreateImage(
      printerData: printerData,
      docDate: DateTime.now(),
      docNumber: printer.docNo,
      printLogo: false,
      printMaxHeight: 200,
      saveToFile: false,
      commandList: printer.commandList,
      qrCodeBottom: printer.qrCode,
      printPaySlip: printer.printPaySLip,
    );

    final imageDecode = img.decodeImage(imageBytes);
    if (imageDecode == null) {
      throw Exception('Failed to decode image');
    }

    final List<int> bytesUsb = [];
    bytesUsb.addAll(generator.reset());
    bytesUsb.addAll(generator.imageRaster(imageDecode));
    bytesUsb.addAll(generator.feed(2));
    bytesUsb.addAll(generator.cut());

    Printer printerObj = Printer(
      address: printerData.ipAddress,
      name: printerData.deviceName,
      vendorId: printerData.vendorId,
      productId: printerData.productId,
      connectionType: ConnectionType.USB,
      isConnected: false,
    );

    // Disconnect first for clean state
    try {
      await flutterThermalPrinterPlugin.disconnect(printerObj);
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      // Ignore disconnect errors
    }

    // Connect and print
    await flutterThermalPrinterPlugin.connect(printerObj);
    await Future.delayed(const Duration(milliseconds: 500));

    await flutterThermalPrinterPlugin.printData(printerObj, bytesUsb);
    await Future.delayed(const Duration(milliseconds: 800));

    await flutterThermalPrinterPlugin.disconnect(printerObj);
    await Future.delayed(const Duration(milliseconds: 300));
  } catch (e, s) {
    AppLogger.error("USB print error: $e");
    global.sendErrorToDevTeam("printer.dart->printMoneyTransferReportByUsb", "${printerData.deviceName} : $e : $s");
  }
}

Future<void> printMoneyTransferReportByBluetooth({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  try {
    FlutterThermalPrinter flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
    _cachedProfile ??= await CapabilityProfile.load();

    final generator = Generator(PaperSize.mm80, _cachedProfile!);

    // สร้าง image จากคำสั่งพิมพ์
    var imageBytes = await global.ticketCreateImage(
      printerData: printerData,
      docDate: DateTime.now(),
      docNumber: printer.docNo,
      printLogo: false,
      printMaxHeight: 200,
      saveToFile: false,
      commandList: printer.commandList,
      qrCodeBottom: printer.qrCode,
      printPaySlip: printer.printPaySLip,
    );

    final imageDecode = img.decodeImage(imageBytes);
    if (imageDecode == null) {
      throw Exception('Failed to decode image');
    }
    final List<int> bytesBt = [];
    bytesBt.addAll(generator.reset());
    bytesBt.addAll(generator.imageRaster(imageDecode));
    bytesBt.addAll(generator.feed(2));
    bytesBt.addAll(generator.cut());

    Printer printerObj = Printer(
      address: printerData.ipAddress,
      name: printerData.deviceName,
      vendorId: printerData.vendorId,
      productId: printerData.productId,
      connectionType: ConnectionType.BLE,
      isConnected: false,
    );

    // ✅ iOS BLE fix: use longData and appropriate chunkSize
    final int iosChunkSize = Platform.isIOS ? 100 : 500;

    await flutterThermalPrinterPlugin.connect(printerObj);
    await flutterThermalPrinterPlugin.printData(printerObj, bytesBt, longData: true, chunkSize: iosChunkSize);
    await Future.delayed(Duration(milliseconds: Platform.isIOS ? 1500 : 800));

    await flutterThermalPrinterPlugin.disconnect(printerObj);
    await Future.delayed(const Duration(milliseconds: 300));
  } catch (e, s) {
    AppLogger.error("Bluetooth print error: $e");
    global.sendErrorToDevTeam("printer.dart->printMoneyTransferReportByBluetooth", "${printerData.deviceName} : $e : $s");
  }
}

Future<void> printMoneyTransferReportByWindows({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  try {
    var imageBytes = await global.ticketCreateImage(
      printerData: printerData,
      docDate: DateTime.now(),
      docNumber: printer.docNo,
      printLogo: false,
      printMaxHeight: 200,
      saveToFile: false,
      commandList: printer.commandList,
      qrCodeBottom: printer.qrCode,
      printPaySlip: printer.printPaySLip,
    );

    String printerName = printerData.deviceName;
    List<int> byteImg = await global.createWindowsByte(printerData, imageBytes);

    // สำหรับ money transfer report print ไม่ต้องใช้ pathName
    global.windowsPrintRawData(printerName, byteImg, "");
  } catch (e, s) {
    AppLogger.error("Windows print error: $e");
    global.sendErrorToDevTeam("printer.dart->printMoneyTransferReportByWindows", "${printerData.deviceName} : $e : $s");
  }
}

/// Prints a detailed shift report with payment methods and drawer calculation
Future<void> printShiftReportDetailed({required ShiftReportModel shiftReport, required DateTime startDate, required DateTime endDate}) async {
  // Find available printer
  int printerIndex = -1;
  for (int i = 0; i < global.printerLocalStrongData.length; i++) {
    if (global.printerLocalStrongData[i].isConfigConnectSuccess) {
      printerIndex = i;
      break;
    }
  }

  if (printerIndex == -1) {
    AppLogger.debug("No printer available for shift report print");
    return;
  }

  PrinterClass printer = PrinterClass(printerIndex: printerIndex, qrCode: "", docNo: "", docDate: DateTime.now());

  AppLogger.debug("Shift report detailed print started");

  // สร้างคำสั่งพิมพ์
  printer.addCommand(PosPrintBillCommandModel(mode: 0)); // Reset Printer

  // Company Header
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 40, width: 1, text: global.profileSetting.company.names[0].name, text_align: PrintColumnAlign.center)],
    ),
  );

  // Print Date
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        FormDesignColumnModel(
          font_size: 24,
          width: 1,
          text: "${global.language("printed_on")} : ${DateFormat("dd/MM/yyyy - HH:mm").format(DateTime.now())}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  // Report Title
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 40, width: 1, text: global.language("shift_report_print"), text_align: PrintColumnAlign.center)],
    ),
  );

  // Shift Period
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        FormDesignColumnModel(
          font_size: 32,
          width: 1,
          text: "${global.language("from_date")} : ${DateFormat("dd/MM/yyyy HH:mm").format(shiftReport.openShift.docdate)}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        FormDesignColumnModel(
          font_size: 32,
          width: 1,
          text: "${global.language("to_date")} : ${DateFormat("dd/MM/yyyy HH:mm").format(shiftReport.closeShift.docdate)}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  // Employee Information
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        FormDesignColumnModel(
          font_size: 32,
          width: 1,
          text: "${global.language("employee")} : ${shiftReport.openShift.username} (${shiftReport.openShift.usercode})",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  // Add separator line
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [FormDesignColumnModel(font_size: 32, width: 1, text: "----------------------------------------", text_align: PrintColumnAlign.center)],
    ),
  );
  // Total Sales Summary
  final totalSales =
      shiftReport.totalCash +
      shiftReport.totalQr +
      shiftReport.totalCreditCard +
      shiftReport.totalTransfer +
      shiftReport.totalCheque +
      shiftReport.totalCoupon +
      shiftReport.totalCredit +
      shiftReport.totalPoint;

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        FormDesignColumnModel(
          font_size: 32,
          width: 1,
          text: "${global.language("total_sales")} : ${global.moneyFormat.format(totalSales)} ${global.language("money_symbol")}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        FormDesignColumnModel(font_size: 32, width: 1, text: "${global.language("total_transactions")} : ${shiftReport.totalTransactions}", text_align: PrintColumnAlign.center),
      ],
    ),
  );

  // Payment Methods Section
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 32, width: 1, text: global.language("payment_methods"), text_align: PrintColumnAlign.center)],
    ),
  );

  // Cash
  if (shiftReport.totalCash > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 28,
            width: 1,
            text: "${global.language("cash")} : ${global.moneyFormat.format(shiftReport.totalCash)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // QR Code
  if (shiftReport.totalQr > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 28,
            width: 1,
            text: "${global.language("qr_code")} : ${global.moneyFormat.format(shiftReport.totalQr)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Credit Card
  if (shiftReport.totalCreditCard > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 28,
            width: 1,
            text: "${global.language("credit_card")} : ${global.moneyFormat.format(shiftReport.totalCreditCard)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Money Transfer
  if (shiftReport.totalTransfer > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 28,
            width: 1,
            text: "${global.language("money_transfer")} : ${global.moneyFormat.format(shiftReport.totalTransfer)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Cheque
  if (shiftReport.totalCheque > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 28,
            width: 1,
            text: "${global.language("cheque")} : ${global.moneyFormat.format(shiftReport.totalCheque)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Coupon
  if (shiftReport.totalCoupon > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 28,
            width: 1,
            text: "${global.language("coupon")} : ${global.moneyFormat.format(shiftReport.totalCoupon)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }
  // Credit
  if (shiftReport.totalCredit > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 28,
            width: 1,
            text: "${global.language("credit")} : ${global.moneyFormat.format(shiftReport.totalCredit)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Point Payment
  if (shiftReport.totalPoint > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 28,
            width: 1,
            text: "Point Payment : ${global.moneyFormat.format(shiftReport.totalPoint)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Drawer Calculation Section
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [FormDesignColumnModel(font_size: 32, width: 1, text: "----------------------------------------", text_align: PrintColumnAlign.center)],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 32, width: 1, text: global.language("drawer_calculation"), text_align: PrintColumnAlign.center)],
    ),
  );

  // Opening Amount
  // printer.addCommand(PosPrintBillCommandModel(
  //     mode: 2,
  //     posStyles: const PosStyles(bold: false),
  //     columns: [FormDesignColumnModel(font_size: 28, width: 1, text: "${global.language("opening_amount")} : ${global.moneyFormat.format(shiftReport.openShift.amount)} ${global.language("money_symbol")}", text_align: PrintColumnAlign.left)]));

  // Added Money
  if (shiftReport.addedMoney > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 28,
            width: 1,
            text: "+ ${global.language("added_money")} : ${global.moneyFormat.format(shiftReport.addedMoney)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Withdrawn Money
  if (shiftReport.withdrawnMoney > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 28,
            width: 1,
            text: "- ${global.language("withdrawn_money")} : ${global.moneyFormat.format(shiftReport.withdrawnMoney)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }
  // Cash Sales
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        FormDesignColumnModel(
          font_size: 28,
          width: 1,
          text: "+ ${global.language("cash_sales")} : ${global.moneyFormat.format(shiftReport.totalCash + shiftReport.totalChange)} ${global.language("money_symbol")}",
          text_align: PrintColumnAlign.left,
        ),
      ],
    ),
  );

  // Change Given
  if (shiftReport.totalChange > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 28,
            width: 1,
            text: "- ${global.language("change_given")} : ${global.moneyFormat.format(shiftReport.totalChange)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }
  // Expected Drawer Amount
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        FormDesignColumnModel(
          font_size: 28,
          width: 1,
          text: "${global.language("expected_drawer")} : ${global.moneyFormat.format(shiftReport.drawerAmount + shiftReport.totalChange)} ${global.language("money_symbol")}",
          text_align: PrintColumnAlign.left,
        ),
      ],
    ),
  );

  // Closing Shift Amount
  // printer.addCommand(PosPrintBillCommandModel(
  //     mode: 2,
  //     posStyles: const PosStyles(bold: false),
  //     columns: [FormDesignColumnModel(font_size: 28, width: 1, text: "${global.language("closing_shift_amount")} : ${global.moneyFormat.format(shiftReport.closeShift.amount)} ${global.language("money_symbol")}", text_align: PrintColumnAlign.left)]));

  // Difference
  // final difference = (shiftReport.drawerAmount + shiftReport.totalChange) - shiftReport.closeShift.amount;
  // printer.addCommand(PosPrintBillCommandModel(
  //     mode: 2, posStyles: const PosStyles(bold: true), columns: [FormDesignColumnModel(font_size: 28, width: 1, text: "${global.language("difference")} : ${global.moneyFormat.format(difference)} ${global.language("money_symbol")}", text_align: PrintColumnAlign.left)]));

  // Final spacing
  printer.addCommand(PosPrintBillCommandModel(mode: 4, value: 80));

  // พิมพ์ตามประเภทเครื่องพิมพ์
  await shiftAndMoneyPrintByPrinterType(printer: printer, printerData: global.printerLocalStrongData[printerIndex]);
}

/// Prints a detailed payment reports list
Future<void> printPaymentReportsList({required List<ShiftReportModel> paymentReports, required DateTime startDate, required DateTime endDate}) async {
  // Find available printer
  int printerIndex = -1;
  for (int i = 0; i < global.printerLocalStrongData.length; i++) {
    if (global.printerLocalStrongData[i].isConfigConnectSuccess) {
      printerIndex = i;
      break;
    }
  }

  if (printerIndex == -1) {
    AppLogger.debug("No printer available for payment reports print");
    return;
  }

  PrinterClass printer = PrinterClass(printerIndex: printerIndex, qrCode: "", docNo: "", docDate: DateTime.now());

  AppLogger.debug("Payment reports print started");

  // Build print commands
  printer.addCommand(PosPrintBillCommandModel(mode: 0)); // Reset Printer

  // Header
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 40, width: 1, text: global.profileSetting.company.names[0].name, text_align: PrintColumnAlign.center)],
    ),
  );
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 32, width: 1, text: global.language("payment_reports"), text_align: PrintColumnAlign.center)],
    ),
  );

  // Date range
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        FormDesignColumnModel(
          font_size: 24,
          width: 1,
          text: "${global.language("from_date")} : ${DateFormat("dd/MM/yyyy HH:mm").format(startDate)}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        FormDesignColumnModel(
          font_size: 24,
          width: 1,
          text: "${global.language("to_date")} : ${DateFormat("dd/MM/yyyy HH:mm").format(endDate)}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        FormDesignColumnModel(
          font_size: 20,
          width: 1,
          text: "${global.language("printed_on")} : ${DateFormat("dd/MM/yyyy - HH:mm").format(DateTime.now())}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  // Separator line
  printer.addCommand(PosPrintBillCommandModel(mode: 3));
  // Calculate totals
  double totalCash = 0;
  double totalQr = 0;
  double totalCreditCard = 0;
  double totalTransfer = 0;
  double totalCheque = 0;
  double totalCoupon = 0;
  double totalCredit = 0;
  double totalPoint = 0;
  int totalTransactions = 0;

  for (final report in paymentReports) {
    totalCash += report.totalCash;
    totalQr += report.totalQr;
    totalCreditCard += report.totalCreditCard;
    totalTransfer += report.totalTransfer;
    totalCheque += report.totalCheque;
    totalCoupon += report.totalCoupon;
    totalCredit += report.totalCredit;
    totalPoint += report.totalPoint;
    totalTransactions += report.totalTransactions;
  }

  double grandTotal = totalCash + totalQr + totalCreditCard + totalTransfer + totalCheque + totalCoupon + totalCredit + totalPoint;

  // Summary section
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 32, width: 1, text: global.language("payment_summary"), text_align: PrintColumnAlign.center)],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        FormDesignColumnModel(
          font_size: 28,
          width: 1,
          text: "${global.language("total_amount")} : ${global.moneyFormat.format(grandTotal)} ${global.language("money_symbol")}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 28, width: 1, text: "${global.language("total_transactions")} : $totalTransactions", text_align: PrintColumnAlign.center)],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        FormDesignColumnModel(
          font_size: 24,
          width: 1,
          text: "${global.language("total_records")} : ${paymentReports.length} ${global.language("shifts")}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  // Payment methods breakdown
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 32, width: 1, text: global.language("payment_methods"), text_align: PrintColumnAlign.center)],
    ),
  );

  // Cash
  if (totalCash > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("cash")} : ${global.moneyFormat.format(totalCash)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // QR Code
  if (totalQr > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("qr_code")} : ${global.moneyFormat.format(totalQr)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Credit Card
  if (totalCreditCard > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("credit_card")} : ${global.moneyFormat.format(totalCreditCard)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Money Transfer
  if (totalTransfer > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("money_transfer")} : ${global.moneyFormat.format(totalTransfer)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Cheque
  if (totalCheque > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("cheque")} : ${global.moneyFormat.format(totalCheque)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Coupon
  if (totalCoupon > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("coupon")} : ${global.moneyFormat.format(totalCoupon)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }
  // Credit
  if (totalCredit > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("credit")} : ${global.moneyFormat.format(totalCredit)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Point Payment
  if (totalPoint > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "Point Payment : ${global.moneyFormat.format(totalPoint)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Separator line
  printer.addCommand(PosPrintBillCommandModel(mode: 3));

  // Individual shift details
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 28, width: 1, text: global.language("shift_details"), text_align: PrintColumnAlign.center)],
    ),
  );
  for (int i = 0; i < paymentReports.length; i++) {
    final report = paymentReports[i];
    final shiftTotal =
        report.totalCash + report.totalQr + report.totalCreditCard + report.totalTransfer + report.totalCheque + report.totalCoupon + report.totalCredit + report.totalPoint;

    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: true),
        columns: [FormDesignColumnModel(font_size: 24, width: 1, text: "${global.language("shift")} ${i + 1}: ${report.openShift.username}", text_align: PrintColumnAlign.left)],
      ),
    );

    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 20,
            width: 1,
            text: "${DateFormat("dd/MM/yyyy HH:mm").format(report.openShift.docdate)} - ${DateFormat("dd/MM/yyyy HH:mm").format(report.closeShift.docdate)}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );

    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 20,
            width: 1,
            text: "${global.language("total_sales")} : ${global.moneyFormat.format(shiftTotal)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );

    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(font_size: 20, width: 1, text: "${global.language("total_transactions")} : ${report.totalTransactions}", text_align: PrintColumnAlign.left),
        ],
      ),
    );

    if (i < paymentReports.length - 1) {
      printer.addCommand(PosPrintBillCommandModel(mode: 3)); // Separator between shifts
    }
  }

  printer.addCommand(PosPrintBillCommandModel(mode: 4, value: 80));

  // Print using the same pattern as money transfer reports
  await printPaymentReportsByPrinterType(printer: printer, printerData: global.printerLocalStrongData[printerIndex]);
}

Future<void> printPaymentReportsByPrinterType({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  if (!printerData.isConfigConnectSuccess) {
    AppLogger.debug("Printer not ready: ${printerData.deviceName}");
    return;
  }

  try {
    switch (printerData.printerConnectType) {
      case global.PrinterConnectEnum.ip:
        await printPaymentReportsByIp(printer: printer, printerData: printerData);
        break;

      case global.PrinterConnectEnum.bluetooth:
        await printPaymentReportsByBluetooth(printer: printer, printerData: printerData);
        break;

      case global.PrinterConnectEnum.usb:
        await printPaymentReportsByUsb(printer: printer, printerData: printerData);
        break;

      case global.PrinterConnectEnum.windows:
        await printPaymentReportsByWindows(printer: printer, printerData: printerData);
        break;

      case global.PrinterConnectEnum.sunmi1:
        // TODO: Implement Sunmi printing
        break;
    }
  } catch (e, s) {
    if (kDebugMode) {
      AppLogger.error('Payment reports print error: $e');
      AppLogger.debug('Stack trace: $s');
    }
    global.sendErrorToDevTeam("printer.dart->printPaymentReportsList", "${printerData.deviceName} : $e : $s");
  }
}

Future<void> printPaymentReportsByIp({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  var imageBytes = await global.ticketCreateImage(
    printerData: printerData,
    docDate: DateTime.now(),
    docNumber: printer.docNo,
    printLogo: false,
    printMaxHeight: 200,
    saveToFile: false,
    commandList: printer.commandList,
    qrCodeBottom: printer.qrCode,
    printPaySlip: printer.printPaySLip,
  );

  PaperSize paper = (printerData.paperType == 1) ? PaperSize.mm58 : PaperSize.mm80;
  CapabilityProfile profile = await CapabilityProfile.load();

  try {
    List<int> bytes = [];
    Socket socket = await Socket.connect(printerData.ipAddress, printerData.ipPort);
    final generator = Generator(paper, profile);

    await Future.delayed(const Duration(milliseconds: 100));
    bytes += generator.reset();

    img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes.toList()));
    if (image != null) {
      int printMaxHeight = 1000;
      int calcLoop = image.height ~/ printMaxHeight;

      for (int i = 0; i <= calcLoop; i++) {
        try {
          img.Image croppedImage = img.copyCrop(image, x: 0, y: i * printMaxHeight, width: image.width, height: printMaxHeight);
          bytes += generator.imageRaster(croppedImage);
        } catch (e) {
          AppLogger.error("Image crop error: $e");
        }
      }
    }

    bytes += generator.feed(3);
    bytes += generator.cut();

    socket.add(bytes);
    await Future.delayed(const Duration(seconds: 1));
    await socket.flush();
    await Future.delayed(const Duration(seconds: 1));
    await socket.close();
  } catch (e, s) {
    AppLogger.error("IP print error: $e");
    global.sendErrorToDevTeam("printer.dart->printPaymentReportsByIp", "${printerData.deviceName} : $e : $s");
  }
}

Future<void> printPaymentReportsByUsb({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  try {
    FlutterThermalPrinter flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
    _cachedProfile ??= await CapabilityProfile.load();

    final generator = Generator(PaperSize.mm80, _cachedProfile!);

    var imageBytes = await global.ticketCreateImage(
      printerData: printerData,
      docDate: DateTime.now(),
      docNumber: printer.docNo,
      printLogo: false,
      printMaxHeight: 200,
      saveToFile: false,
      commandList: printer.commandList,
      qrCodeBottom: printer.qrCode,
      printPaySlip: printer.printPaySLip,
    );

    final imageDecode = img.decodeImage(imageBytes);
    if (imageDecode == null) {
      throw Exception('Failed to decode image');
    }

    final List<int> bytesUsb = [];
    bytesUsb.addAll(generator.reset());
    bytesUsb.addAll(generator.imageRaster(imageDecode));
    bytesUsb.addAll(generator.feed(2));
    bytesUsb.addAll(generator.cut());

    Printer printerObj = Printer(
      address: printerData.ipAddress,
      name: printerData.deviceName,
      vendorId: printerData.vendorId,
      productId: printerData.productId,
      connectionType: ConnectionType.USB,
      isConnected: false,
    );

    // Disconnect first for clean state
    try {
      await flutterThermalPrinterPlugin.disconnect(printerObj);
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      // Ignore disconnect errors
    }

    // Connect and print
    await flutterThermalPrinterPlugin.connect(printerObj);
    await Future.delayed(const Duration(milliseconds: 500));

    await flutterThermalPrinterPlugin.printData(printerObj, bytesUsb);
    await Future.delayed(const Duration(milliseconds: 800));

    await flutterThermalPrinterPlugin.disconnect(printerObj);
    await Future.delayed(const Duration(milliseconds: 300));
  } catch (e, s) {
    AppLogger.error("USB print error: $e");
    global.sendErrorToDevTeam("printer.dart->printPaymentReportsByUsb", "${printerData.deviceName} : $e : $s");
  }
}

Future<void> printPaymentReportsByBluetooth({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  try {
    FlutterThermalPrinter flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
    _cachedProfile ??= await CapabilityProfile.load();

    final generator = Generator(PaperSize.mm80, _cachedProfile!);

    var imageBytes = await global.ticketCreateImage(
      printerData: printerData,
      docDate: DateTime.now(),
      docNumber: printer.docNo,
      printLogo: false,
      printMaxHeight: 200,
      saveToFile: false,
      commandList: printer.commandList,
      qrCodeBottom: printer.qrCode,
      printPaySlip: printer.printPaySLip,
    );

    final imageDecode = img.decodeImage(imageBytes);
    if (imageDecode == null) {
      throw Exception('Failed to decode image');
    }

    final List<int> bytesBt = [];
    bytesBt.addAll(generator.reset());
    bytesBt.addAll(generator.imageRaster(imageDecode));
    bytesBt.addAll(generator.feed(2));
    bytesBt.addAll(generator.cut());

    Printer printerObj = Printer(
      address: printerData.ipAddress,
      name: printerData.deviceName,
      vendorId: printerData.vendorId,
      productId: printerData.productId,
      connectionType: ConnectionType.BLE,
      isConnected: false,
    );

    // ✅ iOS BLE fix: use longData and appropriate chunkSize
    final int iosChunkSize = Platform.isIOS ? 100 : 500;

    await flutterThermalPrinterPlugin.connect(printerObj);
    await flutterThermalPrinterPlugin.printData(printerObj, bytesBt, longData: true, chunkSize: iosChunkSize);
    await Future.delayed(Duration(milliseconds: Platform.isIOS ? 1500 : 800));

    await flutterThermalPrinterPlugin.disconnect(printerObj);
    await Future.delayed(const Duration(milliseconds: 300));
  } catch (e, s) {
    AppLogger.error("Bluetooth print error: $e");
    global.sendErrorToDevTeam("printer.dart->printPaymentReportsByBluetooth", "${printerData.deviceName} : $e : $s");
  }
}

Future<void> printPaymentReportsByWindows({required PrinterClass printer, required PrinterLocalStrongDataModel printerData}) async {
  try {
    var imageBytes = await global.ticketCreateImage(
      printerData: printerData,
      docDate: DateTime.now(),
      docNumber: printer.docNo,
      printLogo: false,
      printMaxHeight: 200,
      saveToFile: false,
      commandList: printer.commandList,
      qrCodeBottom: printer.qrCode,
      printPaySlip: printer.printPaySLip,
    );

    String printerName = printerData.deviceName;
    List<int> byteImg = await global.createWindowsByte(printerData, imageBytes);

    global.windowsPrintRawData(printerName, byteImg, "");
  } catch (e, s) {
    AppLogger.error("Windows print error: $e");
    global.sendErrorToDevTeam("printer.dart->printPaymentReportsByWindows", "${printerData.deviceName} : $e : $s");
  }
}

/// Prints a simple payment summary for individual transactions (without shift reports)
Future<void> printSimplePaymentSummary({
  required double totalCash,
  required double totalQr,
  required double totalCreditCard,
  required double totalTransfer,
  required double totalCheque,
  required double totalCoupon,
  required double totalCredit,
  double totalPoint = 0,
  required double grandTotal,
  required int totalTransactions,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  // Find available printer
  int printerIndex = -1;
  for (int i = 0; i < global.printerLocalStrongData.length; i++) {
    if (global.printerLocalStrongData[i].isConfigConnectSuccess) {
      printerIndex = i;
      break;
    }
  }

  if (printerIndex == -1) {
    AppLogger.debug("No printer available for simple payment summary print");
    return;
  }

  PrinterClass printer = PrinterClass(printerIndex: printerIndex, qrCode: "", docNo: "", docDate: DateTime.now());

  AppLogger.debug("Simple payment summary print started");

  // Build print commands
  printer.addCommand(PosPrintBillCommandModel(mode: 0)); // Reset Printer

  // Header
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 40, width: 1, text: global.profileSetting.company.names[0].name, text_align: PrintColumnAlign.center)],
    ),
  );
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 32, width: 1, text: global.language("payment_transactions_summary"), text_align: PrintColumnAlign.center)],
    ),
  );

  // Date range
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        FormDesignColumnModel(
          font_size: 24,
          width: 1,
          text: "${global.language("from_date")} : ${DateFormat("dd/MM/yyyy HH:mm").format(startDate)}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        FormDesignColumnModel(
          font_size: 24,
          width: 1,
          text: "${global.language("to_date")} : ${DateFormat("dd/MM/yyyy HH:mm").format(endDate)}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: false),
      columns: [
        FormDesignColumnModel(
          font_size: 20,
          width: 1,
          text: "${global.language("printed_on")} : ${DateFormat("dd/MM/yyyy - HH:mm").format(DateTime.now())}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  // Separator line
  printer.addCommand(PosPrintBillCommandModel(mode: 3));

  // Summary section
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 32, width: 1, text: global.language("payment_summary"), text_align: PrintColumnAlign.center)],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [
        FormDesignColumnModel(
          font_size: 28,
          width: 1,
          text: "${global.language("total_amount")} : ${global.moneyFormat.format(grandTotal)} ${global.language("money_symbol")}",
          text_align: PrintColumnAlign.center,
        ),
      ],
    ),
  );

  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 28, width: 1, text: "${global.language("total_transactions")} : $totalTransactions", text_align: PrintColumnAlign.center)],
    ),
  );

  // Separator line
  printer.addCommand(PosPrintBillCommandModel(mode: 3));

  // Payment methods breakdown
  printer.addCommand(
    PosPrintBillCommandModel(
      mode: 2,
      posStyles: const PosStyles(bold: true),
      columns: [FormDesignColumnModel(font_size: 32, width: 1, text: global.language("payment_methods"), text_align: PrintColumnAlign.center)],
    ),
  );

  // Cash
  if (totalCash > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("cash")} : ${global.moneyFormat.format(totalCash)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // QR Code
  if (totalQr > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("qr_code")} : ${global.moneyFormat.format(totalQr)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Credit Card
  if (totalCreditCard > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("credit_card")} : ${global.moneyFormat.format(totalCreditCard)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Money Transfer
  if (totalTransfer > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("money_transfer")} : ${global.moneyFormat.format(totalTransfer)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Cheque
  if (totalCheque > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("cheque")} : ${global.moneyFormat.format(totalCheque)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Coupon
  if (totalCoupon > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("coupon")} : ${global.moneyFormat.format(totalCoupon)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }
  // Credit
  if (totalCredit > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "${global.language("credit")} : ${global.moneyFormat.format(totalCredit)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Point Payment
  if (totalPoint > 0) {
    printer.addCommand(
      PosPrintBillCommandModel(
        mode: 2,
        posStyles: const PosStyles(bold: false),
        columns: [
          FormDesignColumnModel(
            font_size: 24,
            width: 1,
            text: "Point Payment : ${global.moneyFormat.format(totalPoint)} ${global.language("money_symbol")}",
            text_align: PrintColumnAlign.left,
          ),
        ],
      ),
    );
  }

  // Footer
  printer.addCommand(PosPrintBillCommandModel(mode: 3));
  printer.addCommand(PosPrintBillCommandModel(mode: 4, value: 80));

  await printPaymentReportsByPrinterType(printer: printer, printerData: global.printerLocalStrongData[printerIndex]);
}
