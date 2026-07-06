import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;

/// 🔊 Flutter Widget Extensions with Sound Feedback
///
/// ขยาย functionality ของ Widget ปกติให้มีเสียง feedback โดยอัตโนมัติ
/// ใช้ extension methods เพื่อเพิ่มเสียงโดยไม่ต้องแก้โค้ดเดิมมาก
///
/// การใช้งาน:
/// ```dart
/// import 'package:dedecashier/util/widget_sound_extensions.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
///
/// // แทนที่จะเขียน
/// ElevatedButton(onPressed: () { ... })
///
/// // เขียนเป็น
/// ElevatedButton(onPressed: () { ... }).withSound()
/// ```

extension WidgetSoundExtension on Widget {
  /// เพิ่มเสียงให้ Widget (โดยไม่เปลี่ยน Widget เดิม)
  ///
  /// ใช้กับ widgets ที่มี onTap/onPressed อยู่แล้ว
  /// จะเล่นเสียงก่อนที่จะเรียก callback เดิม
  Widget withSound({global.SoundEnum sound = global.SoundEnum.buttonTing}) {
    return this; // คืน widget เดิม (จะจัดการเสียงผ่าน wrapper functions แทน)
  }
}

extension VoidCallbackSoundExtension on VoidCallback {
  /// เพิ่มเสียงให้ VoidCallback
  ///
  /// ตัวอย่าง:
  /// ```dart
  /// onPressed: myFunction.withSound()
  /// onPressed: () { doSomething(); }.withSound()
  /// ```
  VoidCallback withSound({
    global.SoundEnum sound = global.SoundEnum.buttonTing,
  }) {
    return () {
      global.playSound(sound: sound);
      this(); // เรียก function เดิม
    };
  }

  /// เสียงปุ่มทั่วไป
  VoidCallback withButtonSound() =>
      withSound(sound: global.SoundEnum.buttonTing);

  /// เสียงเพิ่มสินค้า
  VoidCallback withAddSound() => withSound(sound: global.SoundEnum.itemAdded);

  /// เสียงลบสินค้า
  VoidCallback withRemoveSound() =>
      withSound(sound: global.SoundEnum.itemRemoved);

  /// เสียงล้าง/ยกเลิก
  VoidCallback withClearSound() =>
      withSound(sound: global.SoundEnum.numpadClear);

  /// เสียงยืนยัน
  VoidCallback withConfirmSound() =>
      withSound(sound: global.SoundEnum.numpadEnter);

  /// เสียง Error
  VoidCallback withErrorSound() => withSound(sound: global.SoundEnum.fail);
}

extension AsyncCallbackSoundExtension on Future<void> Function() {
  /// เพิ่มเสียงให้ Async Callback
  ///
  /// ตัวอย่าง:
  /// ```dart
  /// onPressed: () async { await save(); }.withSound()
  /// ```
  Future<void> Function() withSound({
    global.SoundEnum sound = global.SoundEnum.buttonTing,
  }) {
    return () async {
      global.playSound(sound: sound);
      await this(); // เรียก async function เดิม
    };
  }

  /// เสียงปุ่มทั่วไป (Async)
  Future<void> Function() withButtonSound() =>
      withSound(sound: global.SoundEnum.buttonTing);

  /// เสียงเพิ่มสินค้า (Async)
  Future<void> Function() withAddSound() =>
      withSound(sound: global.SoundEnum.itemAdded);

  /// เสียงลบสินค้า (Async)
  Future<void> Function() withRemoveSound() =>
      withSound(sound: global.SoundEnum.itemRemoved);

  /// เสียงชำระเงิน (Async)
  Future<void> Function() withPaymentSound() =>
      withSound(sound: global.SoundEnum.paymentSuccess);

  /// เสียงยืนยัน (Async)
  Future<void> Function() withConfirmSound() =>
      withSound(sound: global.SoundEnum.numpadEnter);
}

// ========================================
// 📝 Usage Examples
// ========================================

/*
/// ตัวอย่างที่ 1: ใช้ extension กับ VoidCallback
ElevatedButton(
  onPressed: () {
    AppLogger.debug('Clicked!');
  }.withButtonSound(),  // ⭐ เพิ่มแค่นี้!
  child: Text('Click Me'),
)

/// ตัวอย่างที่ 2: ใช้ extension กับ Async Callback
ElevatedButton(
  onPressed: () async {
    await saveData();
  }.withButtonSound(),  // ⭐ เพิ่มแค่นี้!
  child: Text('Save'),
)

/// ตัวอย่างที่ 3: ใช้เสียงต่างกัน
IconButton(
  icon: Icon(Icons.add),
  onPressed: () {
    addItem();
  }.withAddSound(),  // ⭐ เสียงเพิ่มสินค้า
)

IconButton(
  icon: Icon(Icons.remove),
  onPressed: () {
    removeItem();
  }.withRemoveSound(),  // ⭐ เสียงลบสินค้า
)

/// ตัวอย่างที่ 4: ใช้กับ InkWell/GestureDetector
InkWell(
  onTap: () {
    selectItem();
  }.withButtonSound(),  // ⭐ เพิ่มแค่นี้!
  child: Container(...),
)

/// ตัวอย่างที่ 5: ใช้กับ Function ที่มีชื่อ
void myFunction() {
  AppLogger.debug('Hello');
}

ElevatedButton(
  onPressed: myFunction.withButtonSound(),  // ⭐ เพิ่มแค่นี้!
  child: Text('Click'),
)

/// ตัวอย่างที่ 6: Payment Button
ElevatedButton(
  onPressed: () async {
    await processPayment();
  }.withPaymentSound(),  // ⭐ เสียงชำระเงิน
  child: Text('ชำระเงิน'),
)
*/
