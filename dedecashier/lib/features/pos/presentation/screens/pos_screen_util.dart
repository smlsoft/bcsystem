import 'dart:convert';

import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_process.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:flutter/foundation.dart';

// ✅ GetCharacterFromKeyEvent() ถูกย้ายไป PosKeyboardHandler แล้ว
// ใช้ PosKeyboardHandler.getCharacterFromKeyEvent() แทน

String _convertThaiToNumbers(String input) {
  // Thai to Number mapping (Kedmanee keyboard layout)
  const Map<String, String> thaiToNumber = {
    'ๅ': '1', // Shift + ๅ = !
    '/': '2', // / key (same position as 2)
    '-': '3', // - key (same position as 3)
    'ภ': '4', // Shift + ภ = $
    'ถ': '5', // Shift + ถ = %
    'ุ': '6', // Shift + ุ = ^
    'ึ': '7', // Shift + ึ = &
    'ค': '8', // Shift + ค = *
    'ต': '9', // Shift + ต = (
    'จ': '0', // Shift + จ = )
    // ตัวเลขไทย (๐-๙)
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

  // ตรวจสอบว่ามีตัวอักษรที่ต้องแปลงหรือไม่
  bool hasThaiCharacters = input.codeUnits.any((unit) {
    return (unit >= 0x0E00 && unit <= 0x0E7F); // Thai Unicode range
  });

  // ตรวจสอบว่ามี special characters ที่ต้องแปลง (/, -)
  bool hasSpecialChars = input.contains('/') || input.contains('-');

  // ถ้าไม่มีอักษรไทยและไม่มี special chars ให้ส่งคืนเหมือนเดิม
  if (!hasThaiCharacters && !hasSpecialChars) {
    return input;
  }

  if (kDebugMode) {
    if (hasThaiCharacters) {
      AppLogger.debug("Thai characters detected in barcode: '$input'");
    }
    if (hasSpecialChars) {
      AppLogger.debug(
        "Special characters (/, -) detected in barcode: '$input'",
      );
    }
    AppLogger.debug('Code units: ${input.codeUnits}');
  }

  // แปลงทีละตัวอักษร
  StringBuffer result = StringBuffer();
  bool hasConversion = false;

  for (int i = 0; i < input.length; i++) {
    String char = input[i];

    if (thaiToNumber.containsKey(char)) {
      result.write(thaiToNumber[char]);
      hasConversion = true;
      AppLogger.debug(
        "Converting: '$char' (U+${char.codeUnitAt(0).toRadixString(16).toUpperCase().padLeft(4, '0')}) → '${thaiToNumber[char]}'",
      );
    } else {
      // ถ้าไม่ใช่ตัวที่รู้จัก ให้เก็บไว้เหมือนเดิม
      result.write(char);
    }
  }

  String converted = result.toString();

  if (kDebugMode) {
    if (hasConversion) {
      AppLogger.debug("Thai/Special to Number conversion result: '$converted'");
    }
  }

  return converted;
}

// ทำความสะอาด barcode - รองรับ Zebra Scanner Unicode
String CleanBarcode(String barcode) {
  if (kDebugMode) {
    AppLogger.debug("Raw barcode before cleaning: '$barcode'");
    AppLogger.debug('Raw barcode code units: ${barcode.codeUnits}');
  }

  // ✅ แปลงภาษาไทยเป็นตัวเลขก่อน (สำหรับ keyboard ภาษาไทย)
  barcode = _convertThaiToNumbers(barcode);

  // ตรวจสอบว่าเป็น Unicode code points หรือไม่
  if (IsUnicodeCodePoints(barcode)) {
    barcode = ConvertUnicodeCodePointsToString(barcode);
    AppLogger.debug("Converted from Unicode code points: '$barcode'");
  }

  // ลบ whitespace และ control characters
  String cleaned = barcode.replaceAll(RegExp(r'[\s\r\n\t\x00-\x1F\x7F]'), '');

  // ลบ non-printable characters
  cleaned = cleaned.replaceAll(RegExp(r'[^\x20-\x7E]'), '');

  AppLogger.debug("Final cleaned barcode: '$cleaned'");

  return cleaned.trim();
}

// ตรวจสอบว่าเป็น Unicode code points หรือไม่
bool IsUnicodeCodePoints(String input) {
  // ถ้า string มี code units ที่มีค่ามากกว่า 127 (ASCII) และมีรูปแบบคล้าย Unicode
  if (input.length > 10 && input.codeUnits.any((unit) => unit > 127)) {
    return true;
  }

  // ✅ ตรวจสอบรูปแบบ Unicode code points ที่ได้จาก Zebra Scanner
  // รูปแบบ 4 หลัก: '0056005600530048004800560054004900530048005100530055'
  // ต้องยาวมาก (มากกว่า 20 หลัก = 5+ ตัวอักษร) และหาร 4 ลงตัว
  // 🐛 FIX: เปลี่ยนจาก >= 16 เป็น > 20 เพื่อป้องกัน barcode 4 หลักถูก clear
  if (RegExp(r'^\d{4,}$').hasMatch(input) &&
      input.length > 20 &&
      input.length % 4 == 0) {
    return true;
  }

  // ✅ รูปแบบ 3 หลัก zero-padded ASCII: '056056053048048056054049053048051053055'
  // ต้องยาวมาก (มากกว่า 30 หลัก = 10+ ตัวอักษร) และหาร 3 ลงตัว
  // เพื่อป้องกัน barcode ธรรมดาถูกตีความผิด เช่น '538114' (6 หลัก)
  if (RegExp(r'^\d{3,}$').hasMatch(input) &&
      input.length > 30 &&
      input.length % 3 == 0) {
    return true;
  }

  return false;
}

// แปลง Unicode code points เป็น string ปกติ
String ConvertUnicodeCodePointsToString(String unicodeString) {
  try {
    String result = '';

    if (kDebugMode) {
      AppLogger.debug("Converting Unicode string: '$unicodeString'");
      AppLogger.debug('Length: ${unicodeString.length}');
    }

    // วิธีที่ 1: ถ้าเป็น format '0056005600530048...' (4 หลักต่อตัวอักษร)
    if (RegExp(r'^\d{4,}$').hasMatch(unicodeString) &&
        unicodeString.length % 4 == 0) {
      AppLogger.debug("Processing as 4-digit Unicode code points");

      for (int i = 0; i < unicodeString.length; i += 4) {
        String codePointStr = unicodeString.substring(i, i + 4);
        int codePoint = int.tryParse(codePointStr) ?? 0;

        AppLogger.debug(
          "Code point: $codePointStr -> $codePoint -> '${String.fromCharCode(codePoint)}'",
        );

        // แปลง code point เป็นตัวอักษร
        if (codePoint > 0 && codePoint < 65536) {
          // Valid Unicode range
          String char = String.fromCharCode(codePoint);
          // ตรวจสอบว่าเป็นตัวอักษรที่ใช้ได้ในบาร์โค้ด
          if (RegExp(r'^[A-Za-z0-9\-\.\/\s]$').hasMatch(char)) {
            result += char;
          }
        }
      }
    }

    // วิธีที่ 1.5: ถ้าเป็น format '056056053048...' (3 หลัก zero-padded ASCII)
    if (result.isEmpty &&
        RegExp(r'^\d{3,}$').hasMatch(unicodeString) &&
        unicodeString.length % 3 == 0) {
      AppLogger.debug("Processing as 3-digit zero-padded ASCII code points");

      for (int i = 0; i < unicodeString.length; i += 3) {
        String codePointStr = unicodeString.substring(i, i + 3);
        int codePoint = int.tryParse(codePointStr) ?? 0;

        AppLogger.debug(
          "ASCII code point: $codePointStr -> $codePoint -> '${String.fromCharCode(codePoint)}'",
        );

        // แปลง ASCII code point เป็นตัวอักษร
        if (codePoint >= 32 && codePoint <= 126) {
          // Valid ASCII printable range
          String char = String.fromCharCode(codePoint);
          // ตรวจสอบว่าเป็นตัวอักษรที่ใช้ได้ในบาร์โค้ด
          if (RegExp(r'^[A-Za-z0-9\-\.\/\s]$').hasMatch(char)) {
            result += char;
          }
        }
      }
    }

    // วิธีที่ 2: ถ้าเป็น UTF-16 code units ปกติ
    if (result.isEmpty) {
      AppLogger.debug("Processing as UTF-16 code units");

      for (int i = 0; i < unicodeString.length; i++) {
        int codeUnit = unicodeString.codeUnitAt(i);
        AppLogger.debug(
          "Code unit at $i: $codeUnit -> '${String.fromCharCode(codeUnit)}'",
        );

        if (codeUnit >= 48 && codeUnit <= 57) {
          // 0-9
          result += String.fromCharCode(codeUnit);
        } else if (codeUnit >= 65 && codeUnit <= 90) {
          // A-Z
          result += String.fromCharCode(codeUnit);
        } else if (codeUnit >= 97 && codeUnit <= 122) {
          // a-z
          result += String.fromCharCode(codeUnit);
        }
      }
    }

    AppLogger.debug("Unicode conversion result: '$result'");

    return result.isNotEmpty ? result : unicodeString;
  } catch (e) {
    AppLogger.error("Unicode conversion error: $e");
    return unicodeString;
  }
}

// ตรวจสอบว่า barcode ถูกต้องหรือไม่
bool IsValidBarcode(String barcode) {
  // ตรวจสอบความยาว
  if (barcode.length < 3 || barcode.length > 50) {
    return false;
  }

  // ตรวจสอบ pattern ของ barcode
  // รองรับ: A-Z, a-z, 0-9, -, ., /, *, space
  // * ใช้สำหรับรูปแบบ จำนวน*barcode
  if (!RegExp(r'^[A-Za-z0-9\-\.\/\*\s]+$').hasMatch(barcode)) {
    return false;
  }

  // ตรวจสอบ format ที่พบบ่อย
  return _isCommonBarcodeFormat(barcode);
}

// ตรวจสอบ format ของ barcode ที่พบบ่อย
bool _isCommonBarcodeFormat(String barcode) {
  // 🆕 รูปแบบ จำนวน*barcode (เช่น 10*8850123456789)
  if (barcode.contains('*')) {
    List<String> parts = barcode.split('*');
    if (parts.length == 2) {
      String qtyPart = parts[0].trim();
      String barcodePart = parts[1].trim();

      // ✅ Validation เข้มงวด:
      // 1. Quantity ต้องเป็นตัวเลข
      // 2. Quantity ไม่เกิน 6 หลัก (ป้องกัน 8859616 ถูกตีความเป็นจำนวน)
      // 3. Barcode ต้องมีอย่างน้อย 3 หลัก
      bool isValidQtyFormat =
          qtyPart.isNotEmpty &&
          qtyPart.length <= 6 &&
          RegExp(r'^\d+(\.\d+)?$').hasMatch(qtyPart);
      bool isValidBarcodeFormat = barcodePart.length >= 3;

      if (isValidQtyFormat && isValidBarcodeFormat) {
        // Recursive check barcode part
        return _isCommonBarcodeFormat(barcodePart);
      }
    }
    return false; // ถ้ามี * แต่ format ไม่ถูกต้อง
  }

  // EAN-13 (13 หลัก)
  if (RegExp(r'^\d{13}$').hasMatch(barcode)) return true;

  // EAN-8 (8 หลัก)
  if (RegExp(r'^\d{8}$').hasMatch(barcode)) return true;

  // UPC-A (12 หลัก)
  if (RegExp(r'^\d{12}$').hasMatch(barcode)) return true;

  // Code 128 (alphanumeric, 4+ ตัวอักษร)
  if (RegExp(r'^[A-Za-z0-9\-\.\/]{4,}$').hasMatch(barcode)) return true;

  // Custom formats - รองรับ barcode ที่สร้างเอง (3-20 ตัวอักษร)
  if (RegExp(r'^[PS]\d{6,}$').hasMatch(barcode)) {
    return true; // เริ่มด้วย P หรือ S
  }

  // Custom barcode อื่นๆ (ตัวอักษรผสม, 3-20 หลัก)
  if (barcode.length >= 3 && barcode.length <= 20) {
    return true; // รองรับ custom barcode ทั่วไป
  }

  return false;
}

Future<void> getProcessFromTerminal() async {
  // ✅ Performance monitoring (Debug mode only)
  Stopwatch? stopwatch;
  if (kDebugMode) {
    stopwatch = Stopwatch()..start();
  }

  int holdIndex = global.findPosHoldProcessResultIndex(
    global.posHoldActiveCode,
  );
  if (global.appMode == global.AppModeEnum.posRemote) {
    HttpParameterModel jsonParameter = HttpParameterModel(
      holdCode: global.posHoldActiveCode,
    );
    HttpGetDataModel json = HttpGetDataModel(
      code: "get_process",
      json: jsonEncode(jsonParameter.toJson()),
    );
    global.posHoldProcessResult[holdIndex] = PosHoldProcessModel.fromJson(
      await jsonDecode(
        await global.getFromServer(json: jsonEncode(json.toJson())),
      ),
    );
    PosProcess().sumCategoryCount(
      value: global.posHoldProcessResult[holdIndex].posProcess,
    );
  }

  // ✅ Log performance (Debug mode only)
  if (kDebugMode && stopwatch != null) {
    stopwatch.stop();
    AppLogger.success(
      '[PosScreen] 🔄 getProcessFromTerminal took ${stopwatch.elapsedMilliseconds}ms',
    );
    if (stopwatch.elapsedMilliseconds > 500) {
      AppLogger.warning('⚠️ Slow terminal process loading!');
    }
  }
}
