import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

/// Handler สำหรับจัดการ keyboard events และ barcode scanner input
/// แยกออกจาก pos_screen.dart เพื่อลดความซับซ้อน
class PosKeyboardHandler {
  // Buffer timeouts
  static const int _bufferTimeout = 100; // milliseconds
  static const int _clearTimeout = 2000; // 2 seconds

  /// ดึง character จาก KeyEvent
  static String getCharacterFromKeyEvent(KeyEvent event) {
    if (event.character != null && event.character!.isNotEmpty) {
      return event.character!;
    }

    // Fallback: ใช้ keyLabel สำหรับ special keys
    String keyLabel = event.logicalKey.keyLabel;

    // จัดการ numpad keys
    if (keyLabel.contains("NUMPAD")) {
      keyLabel = keyLabel.replaceAll("NUMPAD", "");
      if (keyLabel == "DECIMAL") {
        return ".";
      }
      if (keyLabel == "MULTIPLY") {
        return "*";
      }
      // เช่น NUMPAD1 -> 1
      if (keyLabel.length == 1 && "0123456789".contains(keyLabel)) {
        return keyLabel;
      }
    }

    // จัดการตัวเลขปกติ
    if (keyLabel.length == 1) {
      return keyLabel;
    }

    return "";
  }

  /// ตรวจสอบว่าเป็น Enter key หรือไม่
  static bool isEnterKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
  }

  /// ตรวจสอบว่าเป็น Backspace key หรือไม่
  static bool isBackspaceKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.backspace;
  }

  /// ตรวจสอบว่า input เร็วพอที่จะเป็น barcode scanner หรือไม่
  ///
  /// Returns true ถ้า time difference < 50ms (rapid input from scanner)
  static bool isPossibleScannerInput(int currentTime, int lastKeyTime) {
    return lastKeyTime > 0 && (currentTime - lastKeyTime) < 50;
  }

  /// สร้าง Timer สำหรับประมวลผล barcode buffer
  static Timer createBarcodeTimer({
    required VoidCallback onTimeout,
    bool isScanner = false,
  }) {
    final duration = isScanner
        ? const Duration(milliseconds: _bufferTimeout)
        : const Duration(milliseconds: 0);

    return Timer(duration, onTimeout);
  }

  /// สร้าง Timer สำหรับ clear buffer
  static Timer createClearTimer({required VoidCallback onTimeout}) {
    return Timer(const Duration(milliseconds: _clearTimeout), onTimeout);
  }

  /// จัดการ Backspace - ลบตัวอักษรสุดท้ายจาก buffer
  static String handleBackspace(String currentBuffer) {
    if (currentBuffer.isEmpty) return currentBuffer;

    String newBuffer = currentBuffer.substring(0, currentBuffer.length - 1);

    if (kDebugMode) {
      AppLogger.debug("🔙 [BACKSPACE] Buffer: '$currentBuffer' → '$newBuffer'");
    }

    return newBuffer;
  }

  /// เพิ่ม character เข้า buffer
  static String addCharacterToBuffer(String currentBuffer, String character) {
    String newBuffer = currentBuffer + character;

    if (kDebugMode) {
      AppLogger.debug(
        "➕ Added '$character' to buffer: '$currentBuffer' → '$newBuffer'",
      );
    }

    return newBuffer;
  }

  /// ตรวจสอบว่าควรแสดง overlay หรือไม่
  ///
  /// Returns false ถ้ากำลังพิมพ์ใน TextField (search mode)
  static bool shouldShowOverlay({
    required bool isInSearchMode,
    required bool isPossibleScanner,
    required int desktopWidgetMode,
  }) {
    // Mode 0 (PosNumPad) → แสดง overlay ✅
    // Mode 1 (Product Search) → ไม่แสดงถ้าพิมพ์ช้า (keyboard input)
    // Mode 3 (Member Search) → ไม่แสดงถ้าพิมพ์ช้า (keyboard input)

    bool isTypingInTextField =
        isInSearchMode &&
        !isPossibleScanner &&
        (desktopWidgetMode == 1 || desktopWidgetMode == 3);

    return !isTypingInTextField;
  }

  /// ตรวจสอบว่าควรประมวลผล barcode หรือไม่
  static bool shouldProcessBarcode({
    required int deviceMode,
    required int? tabletTabIndex,
    required int desktopWidgetMode,
    required bool isVisible,
    required bool barcodeScanActive,
  }) {
    if (deviceMode == 1) {
      // Tablet mode
      return (tabletTabIndex == 0);
    } else if (deviceMode == 0) {
      // Desktop mode - รวม search mode ด้วย
      return (desktopWidgetMode == 2 ||
          desktopWidgetMode == 0 ||
          desktopWidgetMode == 1 ||
          desktopWidgetMode == 3);
    } else {
      // Other modes
      return isVisible && barcodeScanActive;
    }
  }

  /// ตรวจสอบว่าอยู่ใน Search Mode หรือไม่
  ///
  /// Search modes:
  /// - Mode 0: Customer Search
  /// - Mode 1: Product Search
  /// - Mode 3: Member Search
  static bool isInSearchMode({
    required int deviceMode,
    required int desktopWidgetMode,
  }) {
    return (deviceMode == 0) &&
        (desktopWidgetMode == 0 ||
            desktopWidgetMode == 1 ||
            desktopWidgetMode == 3);
  }

  /// แปลง key label สำหรับ numpad
  static String convertNumpadKeyLabel(String keyLabel) {
    String result = keyLabel.toUpperCase();

    if (result.contains("NUMPAD")) {
      result = result.replaceAll("NUMPAD", "");
      if (result == "DECIMAL") {
        return ".";
      }
      if (result == "MULTIPLY") {
        return "*";
      }
    }

    return result;
  }

  /// ตรวจสอบว่า key เป็นตัวเลขหรือ operator ที่ใช้ใน numpad ได้
  static bool isValidNumpadKey(String keyLabel) {
    return "01234567890*.".contains(keyLabel);
  }

  /// Log debug information สำหรับ key event
  static void logKeyEvent(KeyEvent event, {String? additionalInfo}) {
    if (!kDebugMode) return;

    AppLogger.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.debug('🔑 Key Event:');
    AppLogger.debug('   Key Label: ${event.logicalKey.keyLabel}');
    AppLogger.debug("   Character: '${event.character ?? '(null)'}'");
    AppLogger.debug('   Logical Key: ${event.logicalKey}');
    if (additionalInfo != null) {
      AppLogger.debug('   Info: $additionalInfo');
    }
    AppLogger.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Log buffer state
  static void logBufferState({
    required String buffer,
    required String cleanBuffer,
    String? action,
  }) {
    if (!kDebugMode) return;

    AppLogger.debug('📋 Buffer State:');
    if (action != null) {
      AppLogger.debug('   Action: $action');
    }
    AppLogger.debug("   Raw: '$buffer'");
    AppLogger.debug("   Clean: '$cleanBuffer'");
    AppLogger.debug('   Length: ${buffer.length}');
    AppLogger.debug('   Code Units: ${buffer.codeUnits}');
  }
}
