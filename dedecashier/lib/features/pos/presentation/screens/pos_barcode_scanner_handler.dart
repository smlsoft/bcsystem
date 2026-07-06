import 'dart:async';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 🎯 Barcode Scanner Handler
///
/// **หน้าที่:** จัดการ keyboard input, barcode scanning, และ validation
///
/// **Features:**
/// - Keyboard event handling (รองรับ barcode scanner)
/// - Thai keyboard to number conversion
/// - Unicode barcode conversion (Zebra Scanner)
/// - Barcode validation and format checking
/// - Auto-search functionality
/// - Quantity*Barcode format support
///
/// **Performance:**
/// - Optimized barcode processing
/// - Debug mode performance logging
/// - Prevents duplicate processing
class BarcodeScannerHandler {
  // ========== State Variables ==========
  String _barcodeBuffer = '';
  int _lastKeyTime = 0;
  bool _isProcessing = false;
  Timer? _barcodeTimer;
  Timer? _barcodeClearTimer;

  // ========== Constants ==========
  static const int _bufferTimeout = 100; // ms - รอให้ scanner พิมพ์เสร็จ
  static const int _clearTimeout = 2000; // ms - clear buffer ถ้าไม่มี input

  // ========== Callbacks ==========
  final Future<void> Function(String barcode) onBarcodeScanned;
  final void Function(String buffer, bool? success) onUpdateOverlay;
  final Future<ProductBarcodeObjectBoxStruct?> Function(String barcode)
  onSearchBarcode;
  final void Function() onRequestFocus;
  final void Function(String value) onNumPadAddValue;
  final void Function() onNumPadBackspace;
  final bool Function() checkIfMounted;
  final bool Function() checkIfInSearchMode;
  final bool Function() checkShouldProcessBarcode;
  final bool Function() checkKeyboardFocus;

  BarcodeScannerHandler({
    required this.onBarcodeScanned,
    required this.onUpdateOverlay,
    required this.onSearchBarcode,
    required this.onRequestFocus,
    required this.onNumPadAddValue,
    required this.onNumPadBackspace,
    required this.checkIfMounted,
    required this.checkIfInSearchMode,
    required this.checkShouldProcessBarcode,
    required this.checkKeyboardFocus,
  });

  // ========== Public Methods ==========

  /// Dispose timers
  void dispose() {
    _barcodeTimer?.cancel();
    _barcodeClearTimer?.cancel();
  }

  /// Get current buffer
  String get buffer => _barcodeBuffer;

  /// Clear buffer
  void clearBuffer() {
    _barcodeBuffer = '';
    onUpdateOverlay('', null);
  }

  /// Handle keyboard event
  void handleKeyEvent(KeyEvent event) {
    try {
      if (event is! KeyDownEvent) return;
      if (!checkIfMounted()) return;

      final isInSearchMode = checkIfInSearchMode();

      // ตรวจสอบ focus
      if (!checkKeyboardFocus() && !isInSearchMode) {
        AppLogger.debug("Keyboard focus lost, attempting to refocus");
        onRequestFocus();
        return;
      }

      // Debug log
      if (kDebugMode) {
        AppLogger.debug('Key Event: ${event.logicalKey.keyLabel}');
        AppLogger.debug("Event character: '${event.character}'");
      }

      // 🔥 Enter key - force search
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        if (_barcodeBuffer.isNotEmpty) {
          AppLogger.debug(
            "🎯 Enter pressed - force searching buffer: '$_barcodeBuffer'",
          );
          _cancelTimers();

          if (isInSearchMode) {
            _processBarcodeInSearchMode();
          } else {
            _processBarcode();
          }
          return;
        }
      }

      // 🔙 Backspace - ลบตัวอักษร
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        _handleBackspace();
        return;
      }

      // ตรวจสอบว่าควรประมวลผล barcode หรือไม่
      if (!checkShouldProcessBarcode()) return;

      // Get character
      String character = _getCharacterFromKeyEvent(event);
      if (character.isEmpty) {
        AppLogger.debug("No character extracted from key event");
        return;
      }

      AppLogger.debug(
        "Character from key: '$character' (${character.codeUnits})",
      );

      int currentTime = DateTime.now().millisecondsSinceEpoch;
      bool isPossibleScanner =
          (_lastKeyTime > 0 && (currentTime - _lastKeyTime) < 50);
      _lastKeyTime = currentTime;

      if (isPossibleScanner && kDebugMode) {
        AppLogger.debug("Rapid input detected - possible scanner");
      }

      // 🔥 Scanner input ใน search mode
      if (isPossibleScanner && isInSearchMode) {
        AppLogger.debug(
          "🎯 Scanner detected in search mode - intercepting barcode",
        );
        _barcodeBuffer += character;
        onUpdateOverlay(_barcodeBuffer, null);

        _barcodeTimer?.cancel();
        _barcodeTimer = Timer(const Duration(milliseconds: _bufferTimeout), () {
          AppLogger.debug("🔍 Scanner complete - searching");
          _processBarcodeInSearchMode();
        });

        _barcodeClearTimer?.cancel();
        return;
      }

      // เพิ่มตัวอักษรเข้า buffer
      _barcodeBuffer += character;

      // อัปเดต overlay
      bool isTypingInTextField = isInSearchMode && !isPossibleScanner;
      bool shouldUpdateOverlay = !isTypingInTextField;

      if (shouldUpdateOverlay) {
        onUpdateOverlay(_barcodeBuffer, null);
        AppLogger.debug("✅ Overlay updated: '$_barcodeBuffer'");
      } else {
        AppLogger.debug("❌ Overlay NOT updated (typing in search TextField)");
      }

      // รีเซ็ต clear timer
      _barcodeClearTimer?.cancel();
      _barcodeClearTimer = Timer(
        const Duration(milliseconds: _clearTimeout),
        () {
          AppLogger.debug("No input for 2 seconds - clearing buffer");
          clearBuffer();
        },
      );

      // รีเซ็ต scanner timer
      _barcodeTimer?.cancel();

      if (isPossibleScanner) {
        // Scanner - รอให้ scan เสร็จ
        _barcodeTimer = Timer(const Duration(milliseconds: _bufferTimeout), () {
          AppLogger.debug("Scanner input complete - processing barcode");
          _processBarcode();
        });
      } else {
        // Keyboard - ค้นหาทันที
        AppLogger.debug("Keyboard input - searching immediately");
        _searchBarcodeImmediately();
      }

      // Handle numpad
      _handleNumpadInput(event);
    } catch (e) {
      AppLogger.error("Error in handleKeyEvent: $e");
    }
  }

  // ========== Private Methods ==========

  void _cancelTimers() {
    _barcodeTimer?.cancel();
    _barcodeClearTimer?.cancel();
    _barcodeTimer = null;
    _barcodeClearTimer = null;
  }

  void _handleBackspace() {
    if (_barcodeBuffer.isNotEmpty) {
      _barcodeBuffer = _barcodeBuffer.substring(0, _barcodeBuffer.length - 1);
      onUpdateOverlay(_barcodeBuffer, null);

      AppLogger.debug("🔙 [BACKSPACE] Buffer updated: '$_barcodeBuffer'");

      _cancelTimers();

      if (_barcodeBuffer.isEmpty) {
        clearBuffer();
      } else {
        _barcodeClearTimer = Timer(const Duration(seconds: 5), () {
          clearBuffer();
        });
      }
    }

    onNumPadBackspace();
  }

  void _handleNumpadInput(KeyEvent event) {
    String keyLabel = event.logicalKey.keyLabel.toUpperCase();

    if (keyLabel == "BACKSPACE") {
      onNumPadBackspace();
      return;
    }

    if (keyLabel.contains("NUMPAD") || keyLabel.contains("MULTIPLY")) {
      keyLabel = keyLabel.replaceAll("NUMPAD", "");
      if (keyLabel.contains("DECIMAL")) {
        keyLabel = ".";
      }
      if (keyLabel == "MULTIPLY") {
        keyLabel = "*";
      }
      if ("01234567890*.".contains(keyLabel)) {
        onNumPadAddValue(keyLabel);
      }
    }
  }

  Future<void> _searchBarcodeImmediately() async {
    // ✅ Performance monitoring (Debug mode only)
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
      AppLogger.debug('🔔 _searchBarcodeImmediately called');
      AppLogger.debug("   Buffer: '$_barcodeBuffer'");
    }

    if (_barcodeBuffer.isEmpty) return;

    String cleanBarcode = _cleanBarcode(_barcodeBuffer);

    if (kDebugMode) {
      AppLogger.debug("🔍 Searching immediately for: '$cleanBarcode'");
      AppLogger.debug("   Raw buffer: '$_barcodeBuffer'");
      AppLogger.debug('Clean barcode length: ${cleanBarcode.length}');
    }

    if (cleanBarcode.isEmpty) {
      AppLogger.debug("⚠️ Clean barcode is empty - keeping buffer");
      return;
    }

    if (!_isValidBarcode(cleanBarcode)) {
      AppLogger.debug("⚠️ Invalid barcode format - waiting for more digits");
      return;
    }

    // แยก quantity*barcode
    String searchBarcode = cleanBarcode;
    if (cleanBarcode.contains('*')) {
      List<String> parts = cleanBarcode.split('*');
      if (parts.length == 2) {
        String qtyPart = parts[0].trim();
        String barcodePart = parts[1].trim();

        if (kDebugMode) {
          AppLogger.debug('🔍 Detected * in barcode, analyzing:');
          AppLogger.debug('   Left part (qty?): "$qtyPart"');
          AppLogger.debug('   Right part (barcode?): "$barcodePart"');
        }

        // ✅ Validation เข้มงวด
        bool isValidQtyFormat =
            qtyPart.isNotEmpty &&
            qtyPart.length <= 6 &&
            RegExp(r'^\d+(\.\d+)?$').hasMatch(qtyPart);
        bool isValidBarcodeFormat =
            barcodePart.isNotEmpty && barcodePart.length >= 3;

        if (isValidQtyFormat && isValidBarcodeFormat) {
          searchBarcode = barcodePart;
          if (kDebugMode) {
            AppLogger.success('✅ Valid quantity*barcode format');
            AppLogger.debug("   Searching for: '$searchBarcode'");
          }
        } else {
          if (kDebugMode) {
            AppLogger.warning(
              '⚠️ Invalid quantity*barcode format, using full barcode',
            );
          }
        }
      }
    }

    // Query database
    ProductBarcodeObjectBoxStruct? productBarcodeSelect = await onSearchBarcode(
      searchBarcode,
    );

    if (productBarcodeSelect != null) {
      // ✅ เจอสินค้า
      if (kDebugMode) {
        AppLogger.success('✅ Product found! Adding to bill');
        AppLogger.debug('Product: ${productBarcodeSelect.names}');
      }

      await onBarcodeScanned(cleanBarcode);
      _barcodeBuffer = '';

      // แสดง overlay 5 วิ
      Future.delayed(const Duration(seconds: 5), () {
        if (checkIfMounted()) {
          clearBuffer();
        }
      });

      _barcodeClearTimer?.cancel();
    } else {
      // ❌ ไม่เจอสินค้า
      if (kDebugMode) {
        AppLogger.error(
          "❌ Product not found - keeping buffer '$_barcodeBuffer'",
        );
      }
    }

    // ✅ Log performance (Debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.debug(
        '[BarcodeScannerHandler] 🔍 Search took ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  Future<void> _processBarcodeInSearchMode() async {
    // ✅ Performance monitoring (Debug mode only)
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
    }

    if (_barcodeBuffer.isEmpty) {
      AppLogger.debug("⚠️ Buffer is empty - skipping duplicate call");
      return;
    }

    String cleanBarcode = _cleanBarcode(_barcodeBuffer);

    if (kDebugMode) {
      AppLogger.debug("🔍 Processing barcode in search mode: '$cleanBarcode'");
    }

    _barcodeBuffer = '';
    onUpdateOverlay(cleanBarcode, null);

    if (cleanBarcode.isEmpty || !_isValidBarcode(cleanBarcode)) {
      AppLogger.debug("⚠️ Invalid barcode in search mode");
      clearBuffer();
      return;
    }

    // แยก quantity*barcode
    String searchBarcode = cleanBarcode;
    if (cleanBarcode.contains('*')) {
      List<String> parts = cleanBarcode.split('*');
      if (parts.length == 2) {
        String qtyPart = parts[0].trim();
        String barcodePart = parts[1].trim();

        // ✅ Validation เข้มงวด
        bool isValidQtyFormat =
            qtyPart.isNotEmpty &&
            qtyPart.length <= 6 &&
            RegExp(r'^\d+(\.\d+)?$').hasMatch(qtyPart);
        bool isValidBarcodeFormat = barcodePart.length >= 3;

        if (isValidQtyFormat && isValidBarcodeFormat) {
          searchBarcode = barcodePart;
          if (kDebugMode) {
            AppLogger.debug('🔢 Detected quantity*barcode in search mode:');
            AppLogger.debug('Quantity: $qtyPart');
            AppLogger.debug('Barcode: $searchBarcode');
          }
        } else {
          if (kDebugMode) {
            AppLogger.warning('⚠️ Invalid quantity*barcode in search mode');
          }
        }
      }
    }

    // ค้นหาสินค้า
    ProductBarcodeObjectBoxStruct? productBarcodeSelect = await onSearchBarcode(
      searchBarcode,
    );

    if (productBarcodeSelect != null) {
      // ✅ เจอสินค้า
      if (kDebugMode) {
        AppLogger.success('✅ Product found in search mode!');
        AppLogger.debug('Product: ${productBarcodeSelect.names}');
      }

      onUpdateOverlay('', true);
      await onBarcodeScanned(cleanBarcode);

      // ปิด overlay ทันที
      if (checkIfMounted()) {
        clearBuffer();
      }
    } else {
      // ❌ ไม่เจอสินค้า
      if (kDebugMode) {
        AppLogger.error('❌ Product not found in search mode');
      }

      onUpdateOverlay(cleanBarcode, false);
      await onBarcodeScanned(cleanBarcode);

      // แสดง overlay สีแดง 5 วิ
      Future.delayed(const Duration(seconds: 5), () {
        if (checkIfMounted()) {
          clearBuffer();
        }
      });
    }

    // ✅ Log performance (Debug mode only)
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.debug(
        '[BarcodeScannerHandler] 🔍 Search mode took ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  void _processBarcode() {
    // ✅ Performance monitoring (Debug mode only)
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
      AppLogger.debug(
        '🔔 _processBarcode called (isProcessing: $_isProcessing)',
      );
    }

    if (_isProcessing) {
      AppLogger.debug("⚠️ Already processing - skipping duplicate call");
      return;
    }

    _barcodeTimer?.cancel();

    if (_barcodeBuffer.trim().isEmpty) {
      AppLogger.debug("⚠️ Buffer is empty - skipping");
      return;
    }

    _isProcessing = true;

    if (kDebugMode) {
      AppLogger.debug('=== Processing barcode buffer ===');
      AppLogger.debug("Raw buffer: '$_barcodeBuffer'");
    }

    String cleanBarcode = _cleanBarcode(_barcodeBuffer);

    _barcodeBuffer = '';

    // แสดง overlay 5 วิ
    Future.delayed(const Duration(seconds: 5), () {
      if (checkIfMounted()) {
        clearBuffer();
      }
    });

    if (kDebugMode) {
      AppLogger.debug("Clean barcode: '$cleanBarcode'");
      AppLogger.debug('Is valid: ${_isValidBarcode(cleanBarcode)}');
    }

    if (_isValidBarcode(cleanBarcode)) {
      onBarcodeScanned(cleanBarcode).then((_) {
        _isProcessing = false;
        AppLogger.debug("✅ Processing complete");

        // ✅ Log performance (Debug mode only)
        if (kDebugMode && stopwatch != null) {
          stopwatch.stop();
          AppLogger.debug(
            '[BarcodeScannerHandler] 📱 Process took ${stopwatch.elapsedMilliseconds}ms',
          );
        }
      });
    } else {
      AppLogger.debug("Barcode validation failed: '$cleanBarcode'");
      _isProcessing = false;
    }
  }

  String _getCharacterFromKeyEvent(KeyEvent event) {
    final logicalKey = event.logicalKey;

    if (kDebugMode) {
      AppLogger.debug('=== _getCharacterFromKeyEvent Debug ===');
      AppLogger.debug('Logical key: ${logicalKey.keyLabel}');
      AppLogger.debug("Event character: '${event.character}'");
    }

    // ตรวจสอบ Unicode
    if (event.character != null && event.character!.isNotEmpty) {
      String char = event.character!;
      AppLogger.debug("Unicode character: '$char' (${char.codeUnits})");

      int charCode = char.codeUnitAt(0);
      if (charCode < 32) {
        AppLogger.debug("Filtered control character: code=$charCode");
        return '';
      }

      AppLogger.debug("✅ Valid character: '$char'");
      return char;
    }

    String result = '';

    // Handle numbers
    if (logicalKey == LogicalKeyboardKey.digit0)
      result = '0';
    else if (logicalKey == LogicalKeyboardKey.digit1)
      result = '1';
    else if (logicalKey == LogicalKeyboardKey.digit2)
      result = '2';
    else if (logicalKey == LogicalKeyboardKey.digit3)
      result = '3';
    else if (logicalKey == LogicalKeyboardKey.digit4)
      result = '4';
    else if (logicalKey == LogicalKeyboardKey.digit5)
      result = '5';
    else if (logicalKey == LogicalKeyboardKey.digit6)
      result = '6';
    else if (logicalKey == LogicalKeyboardKey.digit7)
      result = '7';
    else if (logicalKey == LogicalKeyboardKey.digit8)
      result = '8';
    else if (logicalKey == LogicalKeyboardKey.digit9)
      result = '9';
    // Numpad
    else if (logicalKey == LogicalKeyboardKey.numpad0)
      result = '0';
    else if (logicalKey == LogicalKeyboardKey.numpad1)
      result = '1';
    else if (logicalKey == LogicalKeyboardKey.numpad2)
      result = '2';
    else if (logicalKey == LogicalKeyboardKey.numpad3)
      result = '3';
    else if (logicalKey == LogicalKeyboardKey.numpad4)
      result = '4';
    else if (logicalKey == LogicalKeyboardKey.numpad5)
      result = '5';
    else if (logicalKey == LogicalKeyboardKey.numpad6)
      result = '6';
    else if (logicalKey == LogicalKeyboardKey.numpad7)
      result = '7';
    else if (logicalKey == LogicalKeyboardKey.numpad8)
      result = '8';
    else if (logicalKey == LogicalKeyboardKey.numpad9)
      result = '9';
    // Letters
    else {
      bool isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      if (logicalKey == LogicalKeyboardKey.keyA)
        result = isShiftPressed ? 'A' : 'a';
      else if (logicalKey == LogicalKeyboardKey.keyB)
        result = isShiftPressed ? 'B' : 'b';
      else if (logicalKey == LogicalKeyboardKey.keyC)
        result = isShiftPressed ? 'C' : 'c';
      else if (logicalKey == LogicalKeyboardKey.keyD)
        result = isShiftPressed ? 'D' : 'd';
      else if (logicalKey == LogicalKeyboardKey.keyE)
        result = isShiftPressed ? 'E' : 'e';
      else if (logicalKey == LogicalKeyboardKey.keyF)
        result = isShiftPressed ? 'F' : 'f';
      else if (logicalKey == LogicalKeyboardKey.keyG)
        result = isShiftPressed ? 'G' : 'g';
      else if (logicalKey == LogicalKeyboardKey.keyH)
        result = isShiftPressed ? 'H' : 'h';
      else if (logicalKey == LogicalKeyboardKey.keyI)
        result = isShiftPressed ? 'I' : 'i';
      else if (logicalKey == LogicalKeyboardKey.keyJ)
        result = isShiftPressed ? 'J' : 'j';
      else if (logicalKey == LogicalKeyboardKey.keyK)
        result = isShiftPressed ? 'K' : 'k';
      else if (logicalKey == LogicalKeyboardKey.keyL)
        result = isShiftPressed ? 'L' : 'l';
      else if (logicalKey == LogicalKeyboardKey.keyM)
        result = isShiftPressed ? 'M' : 'm';
      else if (logicalKey == LogicalKeyboardKey.keyN)
        result = isShiftPressed ? 'N' : 'n';
      else if (logicalKey == LogicalKeyboardKey.keyO)
        result = isShiftPressed ? 'O' : 'o';
      else if (logicalKey == LogicalKeyboardKey.keyP)
        result = isShiftPressed ? 'P' : 'p';
      else if (logicalKey == LogicalKeyboardKey.keyQ)
        result = isShiftPressed ? 'Q' : 'q';
      else if (logicalKey == LogicalKeyboardKey.keyR)
        result = isShiftPressed ? 'R' : 'r';
      else if (logicalKey == LogicalKeyboardKey.keyS)
        result = isShiftPressed ? 'S' : 's';
      else if (logicalKey == LogicalKeyboardKey.keyT)
        result = isShiftPressed ? 'T' : 't';
      else if (logicalKey == LogicalKeyboardKey.keyU)
        result = isShiftPressed ? 'U' : 'u';
      else if (logicalKey == LogicalKeyboardKey.keyV)
        result = isShiftPressed ? 'V' : 'v';
      else if (logicalKey == LogicalKeyboardKey.keyW)
        result = isShiftPressed ? 'W' : 'w';
      else if (logicalKey == LogicalKeyboardKey.keyX)
        result = isShiftPressed ? 'X' : 'x';
      else if (logicalKey == LogicalKeyboardKey.keyY)
        result = isShiftPressed ? 'Y' : 'y';
      else if (logicalKey == LogicalKeyboardKey.keyZ)
        result = isShiftPressed ? 'Z' : 'z';
      // Special characters
      else if (logicalKey == LogicalKeyboardKey.minus)
        result = '-';
      else if (logicalKey == LogicalKeyboardKey.period ||
          logicalKey == LogicalKeyboardKey.numpadDecimal)
        result = '.';
      else if (logicalKey == LogicalKeyboardKey.slash)
        result = '/';
      else if (logicalKey == LogicalKeyboardKey.asterisk ||
          logicalKey == LogicalKeyboardKey.numpadMultiply)
        result = '*';
      else if (logicalKey == LogicalKeyboardKey.space)
        result = ' ';
    }

    if (kDebugMode) {
      AppLogger.debug("Final result: '$result'");
    }

    // กรองอีกครั้ง
    if (result.isNotEmpty &&
        !RegExp(r'^[A-Za-z0-9\-\.\/\*\s]$').hasMatch(result)) {
      AppLogger.debug("⚠️ Filtered invalid result: '$result'");
      return '';
    }

    return result;
  }

  String _convertThaiToNumbers(String input) {
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

    bool hasThaiCharacters = input.codeUnits.any(
      (unit) => (unit >= 0x0E00 && unit <= 0x0E7F),
    );
    bool hasSpecialChars = input.contains('/') || input.contains('-');

    if (!hasThaiCharacters && !hasSpecialChars) return input;

    if (kDebugMode) {
      AppLogger.debug("Thai characters detected: '$input'");
    }

    StringBuffer result = StringBuffer();
    bool hasConversion = false;

    for (int i = 0; i < input.length; i++) {
      String char = input[i];
      if (thaiToNumber.containsKey(char)) {
        result.write(thaiToNumber[char]);
        hasConversion = true;
      } else {
        result.write(char);
      }
    }

    String converted = result.toString();
    if (kDebugMode && hasConversion) {
      AppLogger.debug("Thai conversion result: '$converted'");
    }

    return converted;
  }

  String _cleanBarcode(String barcode) {
    if (kDebugMode) {
      AppLogger.debug("Raw barcode before cleaning: '$barcode'");
    }

    // แปลงภาษาไทย
    barcode = _convertThaiToNumbers(barcode);

    // ตรวจสอบ Unicode
    if (_isUnicodeCodePoints(barcode)) {
      barcode = _convertUnicodeCodePointsToString(barcode);
      AppLogger.debug("Converted from Unicode: '$barcode'");
    }

    // ลบ whitespace และ control characters
    String cleaned = barcode.replaceAll(RegExp(r'[\s\r\n\t\x00-\x1F\x7F]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[^\x20-\x7E]'), '');

    AppLogger.debug("Final cleaned barcode: '$cleaned'");
    return cleaned.trim();
  }

  bool _isUnicodeCodePoints(String input) {
    if (input.length > 10 && input.codeUnits.any((unit) => unit > 127)) {
      return true;
    }

    // 4 หลัก: '0056005600530048...'
    if (RegExp(r'^\d{4,}$').hasMatch(input) &&
        input.length > 20 &&
        input.length % 4 == 0) {
      return true;
    }

    // 3 หลัก: '056056053048...'
    if (RegExp(r'^\d{3,}$').hasMatch(input) &&
        input.length > 30 &&
        input.length % 3 == 0) {
      return true;
    }

    return false;
  }

  String _convertUnicodeCodePointsToString(String unicodeString) {
    try {
      String result = '';

      if (kDebugMode) {
        AppLogger.debug("Converting Unicode: '$unicodeString'");
      }

      // 4 หลัก format
      if (RegExp(r'^\d{4,}$').hasMatch(unicodeString) &&
          unicodeString.length % 4 == 0) {
        AppLogger.debug("Processing 4-digit Unicode");

        for (int i = 0; i < unicodeString.length; i += 4) {
          String codePointStr = unicodeString.substring(i, i + 4);
          int codePoint = int.tryParse(codePointStr) ?? 0;

          if (codePoint > 0 && codePoint < 65536) {
            String char = String.fromCharCode(codePoint);
            if (RegExp(r'^[A-Za-z0-9\-\.\/\s]$').hasMatch(char)) {
              result += char;
            }
          }
        }
      }

      // 3 หลัก format
      if (result.isEmpty &&
          RegExp(r'^\d{3,}$').hasMatch(unicodeString) &&
          unicodeString.length % 3 == 0) {
        AppLogger.debug("Processing 3-digit ASCII");

        for (int i = 0; i < unicodeString.length; i += 3) {
          String codePointStr = unicodeString.substring(i, i + 3);
          int codePoint = int.tryParse(codePointStr) ?? 0;

          if (codePoint >= 32 && codePoint <= 126) {
            String char = String.fromCharCode(codePoint);
            if (RegExp(r'^[A-Za-z0-9\-\.\/\s]$').hasMatch(char)) {
              result += char;
            }
          }
        }
      }

      // UTF-16
      if (result.isEmpty) {
        AppLogger.debug("Processing UTF-16");

        for (int i = 0; i < unicodeString.length; i++) {
          int codeUnit = unicodeString.codeUnitAt(i);

          if ((codeUnit >= 48 && codeUnit <= 57) ||
              (codeUnit >= 65 && codeUnit <= 90) ||
              (codeUnit >= 97 && codeUnit <= 122)) {
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

  bool _isValidBarcode(String barcode) {
    if (barcode.length < 3 || barcode.length > 50) return false;
    if (!RegExp(r'^[A-Za-z0-9\-\.\/\*\s]+$').hasMatch(barcode)) return false;
    return _isCommonBarcodeFormat(barcode);
  }

  bool _isCommonBarcodeFormat(String barcode) {
    // จำนวน*barcode
    if (barcode.contains('*')) {
      List<String> parts = barcode.split('*');
      if (parts.length == 2) {
        String qtyPart = parts[0].trim();
        String barcodePart = parts[1].trim();

        // ✅ Validation เข้มงวด (เหมือนไฟล์อื่น)
        bool isValidQtyFormat =
            qtyPart.isNotEmpty &&
            qtyPart.length <= 6 &&
            RegExp(r'^\d+(\.\d+)?$').hasMatch(qtyPart);
        bool isValidBarcodeFormat = barcodePart.length >= 3;

        if (isValidQtyFormat && isValidBarcodeFormat) {
          return _isCommonBarcodeFormat(barcodePart);
        }
      }
      return false;
    }

    // EAN-13
    if (RegExp(r'^\d{13}$').hasMatch(barcode)) return true;
    // EAN-8
    if (RegExp(r'^\d{8}$').hasMatch(barcode)) return true;
    // UPC-A
    if (RegExp(r'^\d{12}$').hasMatch(barcode)) return true;
    // Code 128
    if (RegExp(r'^[A-Za-z0-9\-\.\/]{4,}$').hasMatch(barcode)) return true;
    // Custom (P/S prefix)
    if (RegExp(r'^[PS]\d{6,}$').hasMatch(barcode)) return true;

    // Custom barcode อื่นๆ (3-20 หลัก)
    if (barcode.length >= 3 && barcode.length <= 20) return true;

    return false;
  }
}
