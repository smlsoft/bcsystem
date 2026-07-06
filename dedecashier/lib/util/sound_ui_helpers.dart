import 'package:flutter/material.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/global.dart' as global;

/// 🔊 UI Helper Functions with Sound Feedback
///
/// ใช้งาน: แทนที่จะเรียก onPressed/onTap โดยตรง ให้ใช้ wrapper functions เหล่านี้
/// เพื่อให้มีเสียง feedback อัตโนมัติ
///
/// ตัวอย่าง:
/// ```dart
/// // ❌ เดิม (ไม่มีเสียง)
/// onPressed: () { doSomething(); }
///
/// // ✅ ใหม่ (มีเสียง)
/// onPressed: () => withButtonSound(() { doSomething(); })
/// ```

// ========================================
// 🎵 Sound Wrapper Functions
// ========================================

/// เสียงปุ่มทั่วไป (Default Button Click)
void withButtonSound(VoidCallback action) {
  global.playSound(sound: global.SoundEnum.buttonTing);
  action();
}

/// เสียงปุ่มทั่วไป (Async)
Future<void> withButtonSoundAsync(Future<void> Function() action) async {
  global.playSound(sound: global.SoundEnum.buttonTing);
  await action();
}

/// เสียงปุ่มเพิ่มสินค้า
void withAddItemSound(VoidCallback action) {
  global.playSound(sound: global.SoundEnum.itemAdded);
  action();
}

/// เสียงปุ่มเพิ่มสินค้า (Async)
Future<void> withAddItemSoundAsync(Future<void> Function() action) async {
  global.playSound(sound: global.SoundEnum.itemAdded);
  await action();
}

/// เสียงปุ่มลบสินค้า
void withRemoveItemSound(VoidCallback action) {
  global.playSound(sound: global.SoundEnum.itemRemoved);
  action();
}

/// เสียงปุ่มลบสินค้า (Async)
Future<void> withRemoveItemSoundAsync(Future<void> Function() action) async {
  global.playSound(sound: global.SoundEnum.itemRemoved);
  await action();
}

/// เสียงปุ่มล้างข้อมูล/ยกเลิก
void withClearSound(VoidCallback action) {
  global.playSound(sound: global.SoundEnum.numpadClear);
  action();
}

/// เสียงปุ่มล้างข้อมูล/ยกเลิก (Async)
Future<void> withClearSoundAsync(Future<void> Function() action) async {
  global.playSound(sound: global.SoundEnum.numpadClear);
  await action();
}

/// เสียงปุ่มยืนยัน/OK
void withConfirmSound(VoidCallback action) {
  global.playSound(sound: global.SoundEnum.numpadEnter);
  action();
}

/// เสียงปุ่มยืนยัน/OK (Async)
Future<void> withConfirmSoundAsync(Future<void> Function() action) async {
  global.playSound(sound: global.SoundEnum.numpadEnter);
  await action();
}

/// เสียงปุ่มชำระเงิน
Future<void> withPaymentSound(Future<void> Function() action) async {
  global.playSound(sound: global.SoundEnum.paymentSuccess);
  await action();
}

/// เสียงเมื่อมี Error
void withErrorSound(VoidCallback action) {
  global.playSound(sound: global.SoundEnum.fail);
  action();
}

/// เสียงเมื่อมี Error (Async)
Future<void> withErrorSoundAsync(Future<void> Function() action) async {
  global.playSound(sound: global.SoundEnum.fail);
  await action();
}

// ========================================
// 🎨 Enhanced Button Widgets with Sound
// ========================================

/// ปุ่มที่มีเสียงในตัว (ElevatedButton + Sound)
class SoundElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final global.SoundEnum sound;

  const SoundElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.sound = global.SoundEnum.buttonTing,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: onPressed == null
          ? null
          : () {
              global.playSound(sound: sound);
              onPressed!();
            },
      child: child,
    );
  }
}

/// ปุ่ม Icon ที่มีเสียงในตัว (IconButton + Sound)
class SoundIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final global.SoundEnum sound;
  final double? iconSize;
  final Color? color;
  final String? tooltip;

  const SoundIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.sound = global.SoundEnum.buttonTing,
    this.iconSize,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: iconSize,
      color: color,
      tooltip: tooltip,
      onPressed: onPressed == null
          ? null
          : () {
              global.playSound(sound: sound);
              onPressed!();
            },
      icon: icon,
    );
  }
}

/// InkWell ที่มีเสียงในตัว
class SoundInkWell extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final global.SoundEnum sound;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;

  const SoundInkWell({
    super.key,
    required this.onTap,
    required this.child,
    this.sound = global.SoundEnum.buttonTing,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: borderRadius,
      splashColor: splashColor,
      highlightColor: highlightColor,
      onTap: onTap == null
          ? null
          : () {
              global.playSound(sound: sound);
              onTap!();
            },
      child: child,
    );
  }
}

/// GestureDetector ที่มีเสียงในตัว
class SoundGestureDetector extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final global.SoundEnum sound;

  const SoundGestureDetector({
    super.key,
    required this.onTap,
    required this.child,
    this.sound = global.SoundEnum.buttonTing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              global.playSound(sound: sound);
              onTap!();
            },
      child: child,
    );
  }
}

// ========================================
// 📝 Usage Examples (ตัวอย่างการใช้งาน)
// ========================================

/*
/// ตัวอย่างที่ 1: ใช้ wrapper function
ElevatedButton(
  onPressed: () => withButtonSound(() {
    // ทำงานปกติ
    AppLogger.debug('Button clicked!');
  }),
  child: Text('Click Me'),
)

/// ตัวอย่างที่ 2: ใช้ wrapper function (Async)
ElevatedButton(
  onPressed: () => withButtonSoundAsync(() async {
    // ทำงานแบบ async
    await saveData();
  }),
  child: Text('Save'),
)

/// ตัวอย่างที่ 3: ใช้ Enhanced Widget
SoundElevatedButton(
  onPressed: () {
    // ไม่ต้องเรียก playSound เอง - มีในตัวแล้ว
    AppLogger.debug('Button clicked with sound!');
  },
  child: Text('Click Me'),
)

/// ตัวอย่างที่ 4: ปุ่มเพิ่มสินค้า
SoundIconButton(
  icon: Icon(Icons.add),
  sound: global.SoundEnum.itemAdded,
  onPressed: () {
    addItemToCart();
  },
)

/// ตัวอย่างที่ 5: ปุ่มลบสินค้า
SoundIconButton(
  icon: Icon(Icons.remove),
  sound: global.SoundEnum.itemRemoved,
  onPressed: () {
    removeItemFromCart();
  },
)

/// ตัวอย่างที่ 6: ปุ่มชำระเงิน
SoundElevatedButton(
  sound: global.SoundEnum.paymentSuccess,
  onPressed: () async {
    await processPayment();
  },
  child: Text('ชำระเงิน'),
)
*/
