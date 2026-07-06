import 'dart:io';
import 'dart:developer' as dev;
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/bank_struct.dart';
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/model/objectbox/buffet_mode_struct.dart';
import 'package:dedecashier/model/objectbox/employees_struct.dart';
import 'package:dedecashier/model/objectbox/form_design_struct.dart';
import 'package:dedecashier/model/objectbox/kitchen_struct.dart';
import 'package:dedecashier/model/objectbox/order_temp_struct.dart';
import 'package:dedecashier/model/objectbox/pos_log_struct.dart';
import 'package:dedecashier/model/objectbox/pos_ticket_struct.dart';
import 'package:dedecashier/model/objectbox/printer_struct.dart';
import 'package:dedecashier/model/objectbox/product_barcode_status_struct.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:dedecashier/model/objectbox/product_category_struct.dart';
import 'package:dedecashier/model/objectbox/shift_struct.dart';
import 'package:dedecashier/model/objectbox/staff_client_struct.dart';
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:dedecashier/model/objectbox/wallet_struct.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

void deletePngFiles() async {
  // ลบไฟล์ .png ใน Temp ทั้งหมด (ทดสอบ)
  final tempDirectory = await getTemporaryDirectory();
  if (await tempDirectory.exists()) {
    try {
      await for (var item in tempDirectory.list(recursive: true)) {
        if (item is File && item.path.endsWith('.png')) {
          try {
            await item.delete();
          } catch (e) {
            AppLogger.error("Error deleting file: ${item.path}, $e");
          }
        }
      }
    } catch (e) {
      AppLogger.error("Error accessing directory: $e");
    }
  }
}

Future<void> objectBoxInit() async {
  if (global.objectBoxStoreInit == false) {
    final appDirectory = await getApplicationDocumentsDirectory();
    final objectBoxDirectory = Directory(
      "${appDirectory.path}/objectbox${global.shopId}${global.objectBoxVersion}",
    );
    if (!objectBoxDirectory.existsSync()) {
      await objectBoxDirectory.create(recursive: true);
    }
    try {
      final isExists = await objectBoxDirectory.exists();
      if (isExists) {
        // ลบทิ้ง เพิ่มทดสอบใหม่
        try {
          if (Platform.isWindows && kDebugMode) {
            const clearDebugObjectBox = bool.fromEnvironment(
              'CLEAR_DEBUG_OBJECTBOX',
              defaultValue: false,
            );
            if (clearDebugObjectBox) {
              await objectBoxDirectory.delete(recursive: true);
              deletePngFiles();
            }
          }
        } catch (e) {
          AppLogger.error(e.toString());
        }
        global.objectBoxStore = Store(
          getObjectBoxModel(),
          directory: objectBoxDirectory.path,
          queriesCaseSensitiveDefault: false,
        );
      } else {
        global.objectBoxStore = Store(
          getObjectBoxModel(),
          directory: objectBoxDirectory.path,
          queriesCaseSensitiveDefault: false,
        );
      }
    } catch (e) {
      AppLogger.error("App Data : $appDirectory");
      AppLogger.error(e.toString());
      // โครงสร้างเปลี่ยน เริ่ม Sync ใหม่ทั้งหมด
      final isExists = await objectBoxDirectory.exists();
      if (isExists) {
        AppLogger.info("===??? $isExists");
        await objectBoxDirectory.delete(recursive: true);
      }
      global.objectBoxStore = Store(
        getObjectBoxModel(),
        directory: objectBoxDirectory.path,
        queriesCaseSensitiveDefault: false,
        macosApplicationGroup: 'objectbox.demo',
      );
    }
    global.objectBoxStoreInit = true;
    global.loadPosHoldProcess();
  }
  global.isOnline = await global.hasNetwork();
}

void objectBoxDeleteAll() {
  try {
    global.objectBoxStore.box<BankObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<BillObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<ShiftObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<BuffetModeObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<EmployeeObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<FormDesignObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<KitchenObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<OrderTempObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<PosLogObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<PosTicketObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<PrinterObjectBoxStruct>().removeAll();
    global.objectBoxStore
        .box<ProductBarcodeStatusObjectBoxStruct>()
        .removeAll();
    global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<ProductCategoryObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<ShiftObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<StaffClientObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<TableObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<TableProcessObjectBoxStruct>().removeAll();
    global.objectBoxStore.box<WalletObjectBoxStruct>().removeAll();

    global.appStorage.remove(global.syncCategoryTimeName);
    global.appStorage.remove(global.syncProductBarcodeTimeName);
    global.appStorage.remove(global.syncInventoryTimeName);
    global.appStorage.remove(global.syncMemberTimeName);
    global.appStorage.remove(global.syncBankTimeName);
    global.appStorage.remove(global.syncTableTimeName);
    global.appStorage.remove(global.syncBuffetModeTimeName);
    global.appStorage.remove(global.syncKitchenTimeName);
    global.appStorage.remove(global.syncWalletTimeName);
  } catch (e, s) {
    AppLogger.error(e.toString());
    global.sendErrorToDevTeam(
      "objectBoxDeleteAll",
      e.toString() + s.toString(),
    );
  }
}
