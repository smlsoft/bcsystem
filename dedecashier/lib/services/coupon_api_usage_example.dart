// Example usage of the new coupon availability check API
// This file shows how to use the updated checkCouponAvailability method

import 'package:dedecashier/model/coupon/coupon_model.dart';
import 'package:dedecashier/services/coupon_api_service.dart';
import 'package:dedecashier/services/coupon_manager.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class CouponApiUsageExample {
  static final CouponApiService _apiService = CouponApiService();
  static final CouponManager _couponManager = CouponManager();

  /// Example 1: ใช้ API ใหม่ที่รองรับ items
  static Future<void> exampleNewApiWithItems() async {
    // สร้าง items จากข้อมูลสินค้าในตะกร้า
    final items = [CouponAvailabilityItem(barcode: "58002384", price: 1250, qty: 2, sumamount: 2500), CouponAvailabilityItem(barcode: "58002385", price: 500, qty: 1, sumamount: 500)];

    // เรียกใช้ API ใหม่
    final response = await _apiService.checkCouponAvailabilityWithItems(
      "COUPON_CODE",
      "00000", // branch_code
      "T001", // customer_id
      items,
    );

    if (response != null) {
      AppLogger.debug('Coupon available: ${response.available}');
      AppLogger.debug('Usage count: ${response.usage_count}');
      AppLogger.debug('Max usage count: ${response.max_usage_count}');
      AppLogger.debug('Remaining usage: ${response.remaining_usage}');
      AppLogger.debug('Total amount: ${response.total_amount}');
      AppLogger.debug('Eligible amount: ${response.eligible_amount}');
      AppLogger.debug('Total discount: ${response.total_discount}');
      AppLogger.debug('Eligible item count: ${response.eligible_item_count}');
      AppLogger.debug('Message: ${response.message}');

      // แสดงผลลัพธ์ของแต่ละ item
      for (final itemResult in response.item_results) {
        AppLogger.debug('Item ${itemResult.barcode}: eligible=${itemResult.is_eligible}, discount=${itemResult.discount_amount}');
      }
    }
  }

  /// Example 2: ใช้ API ผ่าน CouponManager (วิธีใหม่)
  static Future<void> exampleWithCouponManager() async {
    // สร้าง items จาก POS items (สมมติว่ามีข้อมูล posItems)
    final posItems = [
      {'barcode': '58002384', 'price': 1250.0, 'qty': 2, 'amount': 2500.0},
      {'barcode': '58002385', 'price': 500.0, 'qty': 1, 'amount': 500.0},
    ];

    // แปลงเป็น CouponAvailabilityItem
    final items = CouponApiService.createAvailabilityItemsFromPos(posItems);

    // เพิ่มคูปองพร้อมส่ง items เพื่อตรวจสอบความเข้ากันได้
    final success = await _couponManager.addCoupon(
      "COUPON_CODE",
      orderAmount: 3000.0, // ยอดรวมของออเดอร์
      items: items, // รายการสินค้าเพื่อตรวจสอบ
      branchCode: "00000", // รหัสสาขา
    );

    if (success) {
      AppLogger.success('Coupon added successfully!');
      AppLogger.debug('Total discount: ${_couponManager.totalDiscount}');
      AppLogger.debug('Final amount: ${_couponManager.finalAmount}');
    } else {
      AppLogger.error('Failed to add coupon: ${_couponManager.errorMessage}');
    }
  }

  /// Example 3: ใช้ API แบบเดิม (backward compatibility)
  static Future<void> exampleOldApi() async {
    // API แบบเดิมยังคงใช้ได้
    final response = await _apiService.checkCouponAvailability("COUPON_ID", "CUSTOMER_ID");

    if (response != null) {
      AppLogger.debug('Coupon available: ${response.available}');
      AppLogger.debug('Usage count: ${response.usage_count}');
      AppLogger.debug('Remaining usage: ${response.remaining_usage}');
      AppLogger.debug('Message: ${response.message}');
    }
  }

  /// Example 4: สร้าง items จาก PosProcessDetailModel (ถ้ามี)
  static List<CouponAvailabilityItem> createItemsFromPosDetails(List<dynamic> posDetails) {
    return CouponApiService.createAvailabilityItemsFromPosDetails(posDetails);
  }

  /// Example response ที่คาดหวัง:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "available": true,
  ///     "usage_count": 0,
  ///     "max_usage_count": 1,
  ///     "remaining_usage": 1,
  ///     "status": 0,
  ///     "is_expired": false,
  ///     "branch_allowed": true,
  ///     "total_amount": 2500,
  ///     "eligible_amount": 2500,
  ///     "total_discount": 0,
  ///     "eligible_item_count": 1,
  ///     "item_results": [
  ///       {
  ///         "barcode": "58002384",
  ///         "qty": 2,
  ///         "price": 1250,
  ///         "sumamount": 2500,
  ///         "is_eligible": true,
  ///         "discount_amount": 0,
  ///         "matched_category": "pattern_code"
  ///       }
  ///     ],
  ///     "message": "คูปองสามารถใช้งานได้"
  ///   }
  /// }
}
