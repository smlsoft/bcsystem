import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/api/sync/sync_customer.dart';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class CustomerSyncService {
  static CustomerSyncService? _instance;
  static CustomerSyncService get instance =>
      _instance ??= CustomerSyncService._();

  CustomerSyncService._();

  bool _isSyncing = false;

  // Manual sync (สำหรับเรียกใช้เมื่อต้องการ)
  Future<bool> manualSync() async {
    if (_isSyncing) {
      AppLogger.debug('Customer sync already in progress');
      return false;
    }

    try {
      _isSyncing = true;

      if (!global.isOnline) {
        AppLogger.debug('Manual customer sync failed - offline mode');
        return false;
      }
      AppLogger.debug('Manual customer sync started...');
      final success = await SyncCustomer.syncCustomersFromAPI();

      if (success) {
        AppLogger.debug('Manual customer sync completed successfully');
      }

      return success;
    } catch (e) {
      AppLogger.error('Manual customer sync error: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // เช็คสถานะ
  bool get isSyncing => _isSyncing; // เช็คจำนวนลูกค้าใน local database
  int getLocalCustomerCount() {
    try {
      // ใช้ SyncCustomer.getLocalCustomerCount() สำหรับความสม่ำเสมอ
      return SyncCustomer.getLocalCustomerCount();
    } catch (e) {
      AppLogger.error('Error getting local customer count: $e');
      return 0;
    }
  }

  /// อัปเดตยอดแต้มลูกค้า
  Future<bool> updateCustomerPointBalance(
    String customerCode,
    double newBalance,
  ) async {
    try {
      return await SyncCustomer.updateCustomerPointBalance(
        customerCode,
        newBalance,
      );
    } catch (e) {
      AppLogger.error('Error updating customer point balance: $e');
      return false;
    }
  }

  /// ล้างข้อมูลลูกค้าทั้งหมด
  void clearAllCustomers() {
    try {
      SyncCustomer.clearAllCustomers();
    } catch (e) {
      AppLogger.error('Error clearing customer data: $e');
    }
  }
}
