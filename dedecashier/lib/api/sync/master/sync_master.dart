import 'dart:async';
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/api/sync/master/sync_bank.dart';
import 'package:dedecashier/api/sync/master/sync_billrunning.dart';
import 'package:dedecashier/api/sync/master/sync_buffet_mode.dart';
import 'package:dedecashier/api/sync/master/sync_kitchen.dart';
import 'package:dedecashier/api/sync/master/sync_product_barcode.dart';
import 'package:dedecashier/api/sync/master/sync_product_category.dart';
import 'package:dedecashier/api/sync/master/sync_promotion.dart';
import 'package:dedecashier/api/sync/master/sync_table.dart';
import 'package:dedecashier/db/product_barcode_status_helper.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/product_barcode_status_struct.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

Future<void> syncMasterData() async {
  AppLogger.debug("syncMasterData started");

  // ตรวจสอบว่าไม่มีการ sync อยู่แล้ว
  if (global.syncDataProcess) {
    AppLogger.debug("Sync already in progress, skipping");
    return;
  }

  ApiRepository apiRepository = ApiRepository();
  global.syncDataProcess = true;
  global.syncDataSuccess = false; // รีเซ็ตสถานะก่อนเริ่ม sync

  try {
    // ตรวจสอบ network ก่อนเริ่ม sync
    bool networkAvailable = await global.hasNetwork();
    if (!networkAvailable) {
      AppLogger.debug("Network not available during sync");
      global.syncDataSuccess = false;
      return;
    }

    AppLogger.debug("Getting master status from server...");
    List<SyncMasterStatusModel> masterStatus = await apiRepository
        .serverMasterStatus();

    AppLogger.debug("Syncing product categories...");
    await syncProductCategoryCompare(masterStatus);

    AppLogger.debug("Syncing product barcodes...");
    await syncProductBarcodeCompare(masterStatus);

    AppLogger.debug("Syncing banks...");
    await syncBankCompare(masterStatus);

    AppLogger.debug("Syncing tables...");
    await syncTableCompare(masterStatus);

    AppLogger.debug("Syncing buffet modes...");
    await syncBuffetModeCompare(masterStatus);

    AppLogger.debug("Syncing kitchens...");
    await syncKitchenCompare(masterStatus);

    AppLogger.debug("Syncing bill running...");
    await syncBillrunning();

    AppLogger.debug("Syncing promotion data...");
    await getPromotionData();

    // อัพเดท ProductBarcodeStatus สำหรับระบบร้านอาหาร
    await _updateProductBarcodeStatus();

    global.syncDataSuccess = true;
    AppLogger.debug("syncMasterData completed successfully");
  } catch (e, stacktrace) {
    global.syncDataSuccess = false;
    if (kDebugMode) {
      AppLogger.error('syncMasterData failed:');
      AppLogger.error('Error: $e');
      AppLogger.debug('Stack trace: $stacktrace');
    }

    // ตรวจสอบประเภทของ error
    if (e.toString().contains('SocketException') ||
        e.toString().contains('TimeoutException') ||
        e.toString().contains('HttpException')) {
      AppLogger.debug("Network-related error detected during sync");
    }
  } finally {
    // ให้แน่ใจว่า syncDataProcess จะถูกรีเซ็ตเสมอ
    global.syncDataProcess = false;
  }
}

/// อัพเดท ProductBarcodeStatus สำหรับระบบร้านอาหาร
Future<void> _updateProductBarcodeStatus() async {
  if (!global.rebuildProductBarcodeStatus) {
    return;
  }

  try {
    AppLogger.debug("Updating product barcode status...");

    global.rebuildProductBarcodeStatus = false;

    // กรณีเป็นระบบร้านอาหาร จะทำการสร้าง ProductBarcodeStatusObjectBoxStruct
    List<ProductBarcodeObjectBoxStruct> productBarcode = global.objectBoxStore
        .box<ProductBarcodeObjectBoxStruct>()
        .query(ProductBarcodeObjectBoxStruct_.isalacarte.equals(true))
        .build()
        .find();

    List<ProductBarcodeStatusObjectBoxStruct> productBarcodeStatus =
        ProductBarcodeStatusHelper().getAll();

    // สร้าง Set สำหรับการค้นหาที่เร็วขึ้น
    Set<String> existingBarcodes = productBarcodeStatus
        .map((item) => item.barcode)
        .toSet();

    List<ProductBarcodeStatusObjectBoxStruct> productBarcodeStatusInsertMany =
        [];

    // ค้นหา ถ้าไม่มีให้เพิ่ม
    for (ProductBarcodeObjectBoxStruct productBarcodeItem in productBarcode) {
      if (!existingBarcodes.contains(productBarcodeItem.barcode)) {
        productBarcodeStatusInsertMany.add(
          ProductBarcodeStatusObjectBoxStruct(
            barcode: productBarcodeItem.barcode,
            qtyBalance: 0,
            orderAutoStock: productBarcodeItem.is_resterant_use_stock,
            qtyMin: 0,
            orderDisable: false,
            qtyStart: 0,
            orderStatus: 0,
          ),
        );
      }
    }

    if (productBarcodeStatusInsertMany.isNotEmpty) {
      ProductBarcodeStatusHelper().insertMany(productBarcodeStatusInsertMany);
      AppLogger.debug(
        "Added ${productBarcodeStatusInsertMany.length} new product barcode status entries",
      );
    }
  } catch (e) {
    AppLogger.error("Failed to update product barcode status: $e");
    // ไม่ throw error เพื่อไม่ให้กระทบต่อการ sync หลัก
  }
}

Future<void> syncMasterProcess() async {
  try {
    // ตรวจสอบว่าเป็นเครื่อง POS Terminal
    if (global.appMode != global.AppModeEnum.posTerminal) {
      AppLogger.debug("Not a POS terminal, skipping sync");
      return;
    }

    // ตรวจสอบการเชื่อมต่อเครือข่าย
    global.isOnline = await global.hasNetwork();
    if (!global.isOnline) {
      AppLogger.debug(
        "No internet connection, marking sync as successful (offline mode)",
      );
      global.syncDataSuccess = true; // ถ้าไม่มีเน็ต ก็ถือว่าซิงค์สำเร็จ
      return;
    }

    // ตรวจสอบสถานะการเชื่อมต่อ API และการล็อกอิน
    if (!global.apiConnected || !global.loginSuccess) {
      AppLogger.debug("API not connected or user not logged in, cannot sync");
      global.syncDataSuccess = false;
      return;
    }

    // ตรวจสอบว่าไม่มีการ sync อยู่แล้ว
    if (global.syncDataProcess) {
      AppLogger.debug("Sync already in progress, skipping");
      return;
    }

    // เริ่มการ sync พร้อม timeout
    AppLogger.debug("Starting master data sync process...");

    // เพิ่ม timeout 60 วินาที สำหรับการ sync
    await syncMasterData().timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        AppLogger.debug("Sync timeout - marking as failed");
        global.syncDataProcess = false;
        global.syncDataSuccess = false;
        throw TimeoutException(
          'Sync operation timed out',
          const Duration(seconds: 60),
        );
      },
    );
  } catch (e) {
    AppLogger.error("Sync process failed: $e");
    // ให้แน่ใจว่าสถานะจะถูกรีเซ็ตเมื่อเกิดข้อผิดพลาด
    global.syncDataProcess = false;
    global.syncDataSuccess = false;
  }
}
