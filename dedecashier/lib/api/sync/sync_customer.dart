import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/customer_struct.dart';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class SyncCustomer {
  // ดึงข้อมูลลูกค้าจาก API และบันทึกใน local database
  static Future<bool> syncCustomersFromAPI() async {
    try {
      AppLogger.debug('Fetching customers from API...');

      // ดึงข้อมูลลูกค้าจาก API (ใช้ method ที่มีอยู่)
      final customers = await ApiRepository().findALlMember("", 0, 50000);

      if (customers.isNotEmpty) {
        if (kDebugMode) {
          AppLogger.debug('Converting ${customers.length} customers to local format...',
          ); // แปลง MemberModel เป็น CustomerObjectBoxStruct
        }
        List<CustomerObjectBoxStruct> customerStructs = [];
        for (var customer in customers) {
          customerStructs.add(
            CustomerObjectBoxStruct(
              guidfixed: customer.guidfixed,
              code: customer.code,
              name: customer.names.isNotEmpty
                  ? customer.names.first.name
                  : 'Unknown',
              tel: customer.addressforbilling.phoneprimary,
              email: customer.email,
              address: customer.addressforbilling.address.isNotEmpty
                  ? customer.addressforbilling.address.join(', ')
                  : '',
              pointbalance: customer.pointbalance,
              pointscode: customer.pointscode,
              pricelevel: customer.pricelevel,
              groups: customer.groups,
            ),
          );
        }

        // ลบข้อมูลเก่าและใส่ข้อมูลใหม่
        AppLogger.debug('Updating local customer database...');
        global.customerHelper.deleteAll();
        global.customerHelper.insertMany(customerStructs);

        AppLogger.debug(
          'Successfully synced ${customerStructs.length} customers to local database',
        );
        return true;
      } else {
        AppLogger.debug('No customers received from API');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error syncing customers from API: $e');
      return false;
    }
  }

  /// อัปเดตยอดแต้มลูกค้าใน local database
  static Future<bool> updateCustomerPointBalance(
    String customerCode,
    double newBalance,
  ) async {
    try {
      // อัปเดตใน local database
      final updated = global.customerHelper.updatePointBalance(
        customerCode,
        newBalance,
      );

      if (updated) {
        AppLogger.debug(
          'Updated point balance for customer $customerCode: $newBalance',
        );
      } else {
        AppLogger.debug('Customer $customerCode not found in local database');
      }

      return updated;
    } catch (e) {
      AppLogger.error('Error updating customer point balance: $e');
      return false;
    }
  }

  /// เช็คจำนวนลูกค้าใน local database
  static int getLocalCustomerCount() {
    try {
      return global.customerHelper.count();
    } catch (e) {
      AppLogger.error('Error getting customer count: $e');
      return 0;
    }
  }

  /// ค้นหาลูกค้าใน local database
  static List<CustomerObjectBoxStruct> findCustomerByTelName(
    String searchText,
  ) {
    try {
      return global.customerHelper.findByTelName(searchText);
    } catch (e) {
      AppLogger.error('Error finding customer by tel/name: $e');
      return [];
    }
  }

  /// ล้างข้อมูลลูกค้าทั้งหมดใน local database
  static void clearAllCustomers() {
    try {
      global.customerHelper.deleteAll();
      AppLogger.debug('All customer data cleared from local database');
    } catch (e) {
      AppLogger.error('Error clearing customer data: $e');
    }
  }

  /// ตรวจสอบการเชื่อมต่อและสถานะข้อมูล
  static Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final localCount = getLocalCustomerCount();
      bool apiAvailable = false;
      int apiCount = 0;
      // ทดสอบการเชื่อมต่อ API
      if (global.isOnline) {
        try {
          await ApiRepository().findALlMember("", 0, 1);
          apiAvailable = true;
          // หาจำนวนลูกค้าทั้งหมดจาก API (ประมาณ)
          final fullResult = await ApiRepository().findALlMember("", 0, 50000);
          apiCount = fullResult.length;
        } catch (e) {
          AppLogger.error('API test failed: $e');
        }
      }

      return {
        'isOnline': global.isOnline,
        'apiAvailable': apiAvailable,
        'localCustomerCount': localCount,
        'apiCustomerCount': apiCount,
        'syncRecommended': localCount == 0 && apiAvailable,
        'status': localCount > 0
            ? 'ready'
            : (apiAvailable ? 'sync_needed' : 'offline_only'),
      };
    } catch (e) {
      AppLogger.error('Error getting system status: $e');
      return {'error': e.toString(), 'status': 'error'};
    }
  }
}
