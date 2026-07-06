import 'package:test/test.dart';

// Helper functions to safely parse ClickHouse string values to numbers
double parseToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed ?? 0.0;
  }
  return 0.0;
}

int parseToInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed ?? 0;
  }
  return 0;
}

void main() {
  group('ClickHouse Type Casting Tests', () {
    test('parseToDouble should handle string numbers correctly', () {
      expect(parseToDouble('123.45'), equals(123.45));
      expect(parseToDouble('0'), equals(0.0));
      expect(parseToDouble(''), equals(0.0));
      expect(parseToDouble(null), equals(0.0));
      expect(parseToDouble(42), equals(42.0));
      expect(parseToDouble(42.5), equals(42.5));
      expect(parseToDouble('invalid'), equals(0.0));
    });

    test('parseToInt should handle string numbers correctly', () {
      expect(parseToInt('123'), equals(123));
      expect(parseToInt('0'), equals(0));
      expect(parseToInt(''), equals(0));
      expect(parseToInt(null), equals(0));
      expect(parseToInt(42), equals(42));
      expect(parseToInt(42.7), equals(42));
      expect(parseToInt('invalid'), equals(0));
    });

    test('should handle ClickHouse response scenario', () {
      // Simulate ClickHouse response data where numbers come as strings
      final mockClickHouseData = {
        'cancelQty': '5.0',
        'orderQty': '10.5',
        'servedQty': '8.25',
        'orderType': '1',
      };

      expect(parseToDouble(mockClickHouseData['cancelQty']), equals(5.0));
      expect(parseToDouble(mockClickHouseData['orderQty']), equals(10.5));
      expect(parseToDouble(mockClickHouseData['servedQty']), equals(8.25));
      expect(parseToInt(mockClickHouseData['orderType']), equals(1));
    });
  });
}
