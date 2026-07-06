import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Thai to Number Conversion Tests', () {
    // Simulated conversion function (same logic as in pos_screen.dart)
    String convertThaiToNumbers(String input) {
      const Map<String, String> thaiToNumber = {
        'ๅ': '1',
        '/': '2',
        '-': '3',
        'ภ': '4',
        'ถ': '5',
        'ุ': '6',
        'ึ': '7',
        'ค': '8',
        'ต': '9',
        'จ': '0',
        '๐': '0',
        '๑': '1',
        '๒': '2',
        '๓': '3',
        '๔': '4',
        '๕': '5',
        '๖': '6',
        '๗': '7',
        '๘': '8',
        '๙': '9',
      };

      if (input.isEmpty) return input;

      bool hasThaiCharacters = input.codeUnits.any((unit) {
        return (unit >= 0x0E00 && unit <= 0x0E7F);
      });

      if (!hasThaiCharacters) {
        return input;
      }

      StringBuffer result = StringBuffer();
      for (int i = 0; i < input.length; i++) {
        String char = input[i];
        if (thaiToNumber.containsKey(char)) {
          result.write(thaiToNumber[char]);
        } else {
          result.write(char);
        }
      }

      return result.toString();
    }

    test('Convert simple Thai barcode', () {
      // ๅตจ/จจจภึจถคค
      const input = 'ๅตจ/จจจภึจถคค';
      const expected = '1902000047088';

      final result = convertThaiToNumbers(input);

      print('Input:    "$input"');
      print('Expected: "$expected"');
      print('Result:   "$result"');

      expect(result, equals(expected));
    });

    test('Convert Thai numerals', () {
      const input = '๕๓๘๑๑๔';
      const expected = '538114';

      final result = convertThaiToNumbers(input);
      expect(result, equals(expected));
    });

    test('Convert EAN-13 barcode', () {
      // คคถจ๑๒๓ภถุึคต
      const input = 'คคถจ๑๒๓ภถุึคต';
      const expected = '8850123456789';

      final result = convertThaiToNumbers(input);
      expect(result, equals(expected));
    });

    test('Mixed English and Thai numerals', () {
      const input = 'ABC๑๒๓';
      const expected = 'ABC123';

      final result = convertThaiToNumbers(input);
      expect(result, equals(expected));
    });

    test('English barcode not affected', () {
      const input = '538114';
      const expected = '538114';

      final result = convertThaiToNumbers(input);
      expect(result, equals(expected));
    });

    test('Individual character mapping', () {
      expect(convertThaiToNumbers('ๅ'), equals('1'));
      expect(convertThaiToNumbers('/'), equals('2'));
      expect(convertThaiToNumbers('-'), equals('3'));
      expect(convertThaiToNumbers('ภ'), equals('4'));
      expect(convertThaiToNumbers('ถ'), equals('5'));
      expect(convertThaiToNumbers('ุ'), equals('6'));
      expect(convertThaiToNumbers('ึ'), equals('7'));
      expect(convertThaiToNumbers('ค'), equals('8'));
      expect(convertThaiToNumbers('ต'), equals('9'));
      expect(convertThaiToNumbers('จ'), equals('0'));
    });

    test('Breakdown of ๅตจ/จจจภึจถคค', () {
      print('\n=== Detailed Breakdown ===');
      const input = 'ๅตจ/จจจภึจถคค';
      final chars = input.split('');

      const mapping = {
        'ๅ': '1',
        'ต': '9',
        'จ': '0',
        '/': '2',
        'ภ': '4',
        'ึ': '7',
        'ถ': '5',
        'ค': '8',
      };

      for (var i = 0; i < chars.length; i++) {
        final char = chars[i];
        final converted = mapping[char] ?? char;
        print(
          '[$i] "$char" (U+${char.codeUnitAt(0).toRadixString(16).toUpperCase().padLeft(4, '0')}) → "$converted"',
        );
      }

      final result = convertThaiToNumbers(input);
      print('\nFinal Result: "$result"');
      print('Expected:     "1902000047088"');

      expect(result, equals('1902000047088'));
    });
  });
}
