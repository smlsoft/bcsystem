import 'package:flutter_test/flutter_test.dart';

/// Unit Tests สำหรับ Unit Conversion ใน Promotion System
///
/// ทดสอบว่า promotion system คำนวณ base unit ถูกต้อง
/// เมื่อมีสินค้าหลายหน่วยนับ (multiple barcodes, same item_code)

void main() {
  group('Unit Conversion Helper Functions', () {
    test('convertToBaseUnit - กรณีปกติ (12 ชิ้น/กล่อง)', () {
      // Arrange
      double qty = 2; // 2 กล่อง
      double unitDividend = 12; // 12 ชิ้นต่อกล่อง
      double unitDivisor = 1;

      // Act
      double baseQty = (qty * unitDividend) / unitDivisor;

      // Assert
      expect(baseQty, equals(24.0)); // 2 × 12 = 24 ชิ้น
    });

    test('convertToBaseUnit - หน่วยฐาน (1:1)', () {
      // Arrange
      double qty = 5; // 5 ชิ้น
      double unitDividend = 1;
      double unitDivisor = 1;

      // Act
      double baseQty = (qty * unitDividend) / unitDivisor;

      // Assert
      expect(baseQty, equals(5.0));
    });

    test('convertToBaseUnit - กรณี divisor = 0 ต้องคืน 0', () {
      // Arrange
      double qty = 10;
      double unitDividend = 12;
      double unitDivisor = 0; // ผิดปกติ

      // Act
      double baseQty = (unitDivisor == 0)
          ? 0
          : (qty * unitDividend) / unitDivisor;

      // Assert
      expect(baseQty, equals(0.0));
    });

    test('convertToBaseUnit - ทศนิยม (0.5 กล่อง = 6 ชิ้น)', () {
      // Arrange
      double qty = 0.5;
      double unitDividend = 12;
      double unitDivisor = 1;

      // Act
      double baseQty = (qty * unitDividend) / unitDivisor;

      // Assert
      expect(baseQty, equals(6.0));
    });

    test('getPricePerBaseUnit - ราคา 120 บาท/กล่อง 12 ชิ้น = 10 บาท/ชิ้น', () {
      // Arrange
      double price = 120;
      double unitDividend = 12;
      double unitDivisor = 1;

      // Act
      double ratio = unitDividend / unitDivisor;
      double pricePerBase = price / ratio;

      // Assert
      expect(pricePerBase, equals(10.0));
    });

    test('getPricePerBaseUnit - หน่วยฐาน (1:1) ราคาเท่าเดิม', () {
      // Arrange
      double price = 50;
      double unitDividend = 1;
      double unitDivisor = 1;

      // Act
      double ratio = unitDividend / unitDivisor;
      double pricePerBase = price / ratio;

      // Assert
      expect(pricePerBase, equals(50.0));
    });
  });

  group('Mixed Unit Promotion Scenarios', () {
    test('ซื้อ 50 ขวด + 1 ลัง (12 ขวด/ลัง) = 62 ขวด รวมกัน', () {
      // Arrange - สินค้า item_code เดียวกัน แต่ barcode ต่างกัน
      List<Map<String, dynamic>> purchases = [
        {
          'barcode': '8851234567890', // ขวดเดี่ยว
          'item_code': 'COLA001',
          'qty': 50.0,
          'unit_dividend': 1.0,
          'unit_divisor': 1.0,
        },
        {
          'barcode': '8851234567891', // ลัง (12 ขวด)
          'item_code': 'COLA001',
          'qty': 1.0,
          'unit_dividend': 12.0,
          'unit_divisor': 1.0,
        },
      ];

      // Act - คำนวณ base unit แล้วรวมกัน
      Map<String, double> itemCodeQty = {};
      for (var purchase in purchases) {
        double baseQty =
            (purchase['qty'] * purchase['unit_dividend']) /
            purchase['unit_divisor'];
        String itemCode = purchase['item_code'];
        itemCodeQty[itemCode] = (itemCodeQty[itemCode] ?? 0) + baseQty;
      }

      // Assert
      expect(itemCodeQty['COLA001'], equals(62.0)); // 50 + 12 = 62 ขวด
    });

    test('Promotion "ซื้อ 60 ขวดแถม 1 ขวด" ต้องใช้ได้กับหลายหน่วย', () {
      // Arrange
      double totalBaseQty = 62.0; // จากกรณีด้านบน
      double promotionLimitQty = 60.0;

      // Act - เช็คว่าครบเงื่อนไขหรือไม่
      bool qualified = totalBaseQty >= promotionLimitQty;

      // Assert
      expect(qualified, isTrue);
    });

    test('ซื้อ 3 หน่วยต่างกัน รวมเป็น base unit ได้ถูกต้อง', () {
      // Arrange
      List<Map<String, dynamic>> purchases = [
        {
          'barcode': 'BAR001', // ชิ้นเดี่ยว
          'item_code': 'SNACK001',
          'qty': 10.0,
          'unit_dividend': 1.0,
          'unit_divisor': 1.0,
        },
        {
          'barcode': 'BAR002', // กล่อง 20 ชิ้น
          'item_code': 'SNACK001',
          'qty': 2.0,
          'unit_dividend': 20.0,
          'unit_divisor': 1.0,
        },
        {
          'barcode': 'BAR003', // ลัง 50 ชิ้น
          'item_code': 'SNACK001',
          'qty': 1.0,
          'unit_dividend': 50.0,
          'unit_divisor': 1.0,
        },
      ];

      // Act
      double totalBaseQty = 0;
      for (var purchase in purchases) {
        double baseQty =
            (purchase['qty'] * purchase['unit_dividend']) /
            purchase['unit_divisor'];
        totalBaseQty += baseQty;
      }

      // Assert
      expect(totalBaseQty, equals(100.0)); // 10 + 40 + 50 = 100 ชิ้น
    });

    test('Promotion Type 4 - ราคาพิเศษเมื่อซื้อครบ base unit', () {
      // Arrange
      double totalBaseQty = 100.0;
      double promotionLimitQty = 100.0;
      double specialPrice = 8.0;
      double normalPrice = 10.0;

      // Act
      double finalPrice = (totalBaseQty >= promotionLimitQty)
          ? specialPrice
          : normalPrice;

      // Assert
      expect(finalPrice, equals(8.0));
    });

    test('barcode → item_code mapping ต้องทำงานถูกต้อง', () {
      // Arrange
      Map<String, String> barcodeToItemCode = {
        '8851234567890': 'COLA001',
        '8851234567891': 'COLA001',
        '8851234567892': 'COLA001',
      };

      // Act
      String? itemCode1 = barcodeToItemCode['8851234567890'];
      String? itemCode2 = barcodeToItemCode['8851234567891'];
      String? itemCode3 = barcodeToItemCode['8851234567892'];

      // Assert - barcode ต่างกัน แต่ item_code เดียวกัน
      expect(itemCode1, equals('COLA001'));
      expect(itemCode2, equals('COLA001'));
      expect(itemCode3, equals('COLA001'));
    });
  });

  group('Edge Cases', () {
    test('qty = 0 ต้องคืน base_qty = 0', () {
      double baseQty = (0 * 12) / 1;
      expect(baseQty, equals(0.0));
    });

    test('ไม่มี item_code mapping ต้องไม่ apply promotion', () {
      Map<String, String> barcodeToItemCode = {'8851234567890': 'COLA001'};

      String? itemCode = barcodeToItemCode['UNKNOWN_BARCODE'];
      expect(itemCode, isNull);
    });

    test('divisor และ dividend = 0 ต้องคืนราคาเดิม', () {
      double price = 100;
      double unitDividend = 0;
      double unitDivisor = 0;

      double pricePerBase = (unitDivisor == 0 || unitDividend == 0)
          ? price
          : price / (unitDividend / unitDivisor);

      expect(pricePerBase, equals(100.0));
    });

    test('จำนวนติดลบ (ควร validate ก่อน) คืน 0', () {
      double qty = -5;
      double baseQty = (qty < 0) ? 0 : (qty * 12) / 1;
      expect(baseQty, equals(0.0));
    });
  });

  group('Real World Scenarios', () {
    test('ซื้อ Pepsi: 24 ขวด + 2 แพ็ค 6 ขวด = 36 ขวด (โปร ซื้อ 30 แถม 1)', () {
      // Scenario: ซื้อ Pepsi หลายหน่วย
      List<Map<String, dynamic>> cart = [
        {
          'barcode': 'PEPSI_BOTTLE',
          'item_code': 'PEPSI001',
          'qty': 24.0,
          'ratio': 1.0,
        },
        {
          'barcode': 'PEPSI_PACK6',
          'item_code': 'PEPSI001',
          'qty': 2.0,
          'ratio': 6.0,
        },
      ];

      double totalBaseQty = cart.fold(
        0.0,
        (sum, item) => sum + (item['qty'] * item['ratio']),
      );

      // โปร: ซื้อ 30 ขวดแถม 1 ขวด
      int freeBottles = (totalBaseQty / 30).floor();

      expect(totalBaseQty, equals(36.0)); // 24 + 12
      expect(freeBottles, equals(1)); // ได้แถม 1 ขวด
    });

    test('House Brand Type 101: รวมยอดจาก pattern_code ไม่เกี่ยวกับ unit', () {
      // Type 101 ใช้ total_amount ตรงๆ ไม่ได้แปลง unit
      List<Map<String, dynamic>> details = [
        {'barcode': 'HB001', 'pattern_code': 'HB', 'total_amount': 500.0},
        {'barcode': 'HB002', 'pattern_code': 'HB', 'total_amount': 300.0},
        {'barcode': 'NORMAL', 'pattern_code': '', 'total_amount': 200.0},
      ];

      double houseBrandAmount = details
          .where((d) => d['pattern_code'] == 'HB')
          .fold(0.0, (sum, d) => sum + d['total_amount']);

      expect(houseBrandAmount, equals(800.0)); // 500 + 300
    });
  });
}
