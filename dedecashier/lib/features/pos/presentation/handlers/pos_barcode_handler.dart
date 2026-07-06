import 'package:flutter/foundation.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/db/product_barcode_helper.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_screen_util.dart';

/// Handler สำหรับจัดการ barcode scanning และ processing
/// แยกออกจาก pos_screen.dart เพื่อลดความซับซ้อนและเพิ่มความสามารถในการ maintain
class PosBarcodeHandler {
  /// จัดการ barcode ที่สแกนได้
  ///
  /// รองรับ format:
  /// - ปกติ: "barcode"
  /// - มี quantity: "10*barcode"
  ///
  /// Returns: Map<String, String> with keys 'barcode' and 'quantity'
  static Future<Map<String, String>> handleBarcodeScanned({
    required String barcode,
    required String numericPadTextInput,
  }) async {
    // ✅ Performance monitoring (Debug mode only)
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
      AppLogger.debug("Original barcode: '$barcode'");
    }

    // 🔥 แยก quantity จาก barcode (รูปแบบ: 10*barcode)
    String actualBarcode = barcode;
    String quantity = "1.0"; // ✅ Default = 1, ไม่ใช้ numericPad ยกเว้นมี *

    if (kDebugMode) {
      AppLogger.info("📝 numericPadTextInput: '$numericPadTextInput'");
      AppLogger.info("📝 Initial quantity: '$quantity' (default)");
    }

    if (barcode.contains('*')) {
      List<String> parts = barcode.split('*');
      if (parts.length == 2) {
        String qtyPart = parts[0].trim();
        String barcodePart = parts[1].trim();

        if (kDebugMode) {
          AppLogger.debug('🔍 Detected * in barcode, analyzing:');
          AppLogger.debug('   Left part (qty?): "$qtyPart"');
          AppLogger.debug('   Right part (barcode?): "$barcodePart"');
        }

        // ✅ Validation เข้มงวด:
        // 1. จำนวนต้องเป็นตัวเลข
        // 2. จำนวนต้องไม่เกิน 6 หลัก (ป้องกัน 8859616 ถูกตีความเป็นจำนวน)
        // 3. Barcode ต้องมีอย่างน้อย 3 หลัก (รองรับ custom barcode)
        // 4. Barcode ต้องเป็น format ที่ถูกต้อง (ตรวจสอบด้วย IsValidBarcode)
        bool isValidQtyFormat =
            qtyPart.isNotEmpty &&
            qtyPart.length <= 6 &&
            RegExp(r'^\d+(\.\d+)?$').hasMatch(qtyPart);
        bool isValidBarcodeFormat = barcodePart.length >= 3;

        if (kDebugMode) {
          AppLogger.debug(
            '   Qty valid: $isValidQtyFormat (length: ${qtyPart.length})',
          );
          AppLogger.debug(
            '   Barcode valid: $isValidBarcodeFormat (length: ${barcodePart.length})',
          );
        }

        if (isValidQtyFormat && isValidBarcodeFormat) {
          // ✅ ทั้งสองส่วน valid → ใช้เป็น quantity*barcode
          quantity = qtyPart;
          actualBarcode = barcodePart;

          if (kDebugMode) {
            AppLogger.success('✅ Parsed as quantity*barcode format:');
            AppLogger.debug(
              '   Quantity from *: $quantity (overriding numericPad)',
            );
            AppLogger.debug('   Barcode: $actualBarcode');
          }
        } else {
          // ❌ Format ไม่ถูกต้อง → ถือว่าเป็น barcode ทั้งหมด
          if (kDebugMode) {
            AppLogger.warning(
              '⚠️ Invalid quantity*barcode format, treating as normal barcode',
            );
            if (!isValidQtyFormat) {
              AppLogger.warning(
                '   Reason: Quantity part invalid (too long or not a number)',
              );
            }
            if (!isValidBarcodeFormat) {
              AppLogger.warning(
                '   Reason: Barcode part too short (< 3 chars)',
              );
            }
          }
          // ไม่แปลง actualBarcode (ใช้ barcode เต็ม)
        }
      }
    }

    if (kDebugMode) {
      AppLogger.debug("Final barcode: '$actualBarcode'");
      AppLogger.debug("Final quantity: '$quantity'");
      AppLogger.debug(
        "Source: ${barcode.contains('*') ? "from * operator" : (numericPadTextInput.isEmpty ? "default 1.0" : "from numpad '$numericPadTextInput'")}",
      );
    }

    serviceLocator<Log>().debug(
      '------------------------ Scan Barcode : $actualBarcode (Qty: $quantity)',
    );

    // ✅ Log performance (Debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.debug(
        '[PosBarcodeHandler] 📱 Barcode parsed in ${stopwatch.elapsedMilliseconds}ms',
      );
      if (stopwatch.elapsedMilliseconds > 100) {
        AppLogger.warning('⚠️ Slow barcode parsing!');
      }
    }

    return {'barcode': actualBarcode, 'quantity': quantity};
  }

  /// ค้นหาสินค้าจาก barcode ทันที
  ///
  /// Returns: ProductBarcodeObjectBoxStruct? - null ถ้าไม่เจอ
  static Future<ProductBarcodeObjectBoxStruct?> searchProductByBarcode(
    String barcode,
  ) async {
    if (kDebugMode) {
      AppLogger.debug('🔍 Searching for product: $barcode');
    }

    // แยก quantity*barcode ถ้ามี
    String searchBarcode = barcode;
    if (barcode.contains('*')) {
      List<String> parts = barcode.split('*');
      if (parts.length == 2) {
        String barcodePart = parts[1].trim();
        if (barcodePart.isNotEmpty) {
          searchBarcode = barcodePart;
          if (kDebugMode) {
            AppLogger.debug('🔍 Detected quantity*barcode format');
            AppLogger.debug(
              "   Searching for: '$searchBarcode' (from '$barcode')",
            );
          }
        }
      }
    }

    // Query database
    ProductBarcodeObjectBoxStruct? product = await ProductBarcodeHelper()
        .selectByBarcodeFirst(searchBarcode);

    if (kDebugMode) {
      if (product != null) {
        AppLogger.success('✅ Product found: ${product.names}');
      } else {
        AppLogger.error("❌ Product not found for barcode: '$searchBarcode'");
      }
    }

    return product;
  }

  /// ทำความสะอาด barcode string
  static String cleanBarcode(String barcode) {
    return CleanBarcode(barcode);
  }

  /// ตรวจสอบว่า barcode ถูกต้องหรือไม่
  static bool isValidBarcode(String barcode) {
    return IsValidBarcode(barcode);
  }

  /// แยก quantity และ barcode จาก string format "qty*barcode"
  ///
  /// Returns: Map with 'quantity' and 'barcode' keys
  static Map<String, String> parseQuantityBarcode(String input) {
    String quantity = "1.0";
    String barcode = input;

    if (input.contains('*')) {
      List<String> parts = input.split('*');
      if (parts.length == 2) {
        String qtyPart = parts[0].trim();
        String barcodePart = parts[1].trim();

        // ✅ Validation เข้มงวด (เหมือน handleBarcodeScanned)
        bool isValidQtyFormat =
            qtyPart.isNotEmpty &&
            qtyPart.length <= 6 &&
            RegExp(r'^\d+(\.\d+)?$').hasMatch(qtyPart);
        bool isValidBarcodeFormat = barcodePart.length >= 3;

        if (isValidQtyFormat && isValidBarcodeFormat) {
          quantity = qtyPart;
          barcode = barcodePart;
        }
      }
    }

    return {'quantity': quantity, 'barcode': barcode};
  }

  /// ตรวจสอบว่า string เป็นตัวเลขหรือไม่
  static bool isNumeric(String str) {
    if (str.isEmpty) return false;
    return RegExp(r'^\d+(\.\d+)?$').hasMatch(str);
  }

  /// Format barcode สำหรับแสดงผล (ตัดให้สั้นถ้ายาวเกิน)
  static String formatBarcodeForDisplay(String barcode, {int maxLength = 20}) {
    if (barcode.length <= maxLength) {
      return barcode;
    }
    return '${barcode.substring(0, maxLength - 3)}...';
  }
}
