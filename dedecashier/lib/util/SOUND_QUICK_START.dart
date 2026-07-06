/// 🔊 SOUND INTEGRATION QUICK START GUIDE
///
/// คู่มือเร่งด่วนสำหรับการเพิ่มเสียงให้ทุกหน้าจอ
///
/// ========================================
/// 📚 สิ่งที่ต้องรู้:
/// ========================================
///
/// 1. มี 2 วิธีในการเพิ่มเสียง:
///    - วิธีที่ 1: ใช้ Extensions (แนะนำ - แก้โค้ดเดิมง่าย)
///    - วิธีที่ 2: ใช้ Sound UI Helpers (แนะนำ - widgets ใหม่)
///
/// 2. เสียงทั้งหมดที่มี:
///    - buttonTing: ปุ่มทั่วไป
///    - itemAdded: เพิ่มสินค้า
///    - itemRemoved: ลบสินค้า
///    - numpadClear: ล้าง/ยกเลิก
///    - numpadEnter: ยืนยัน/OK
///    - paymentSuccess: ชำระเงินสำเร็จ
///    - fail: Error
///    - num0-num9: ตัวเลข
///    - และอื่น ๆ (ดูใน global.dart)
///
/// ========================================
/// ⚡ วิธีที่ 1: ใช้ Extensions (ง่ายที่สุด!)
/// ========================================
///
/// Step 1: เพิ่ม import
/// ```dart
/// import 'package:dedecashier/util/widget_sound_extensions.dart';
/// ```
///
/// Step 2: เพิ่ม .withXXXSound() ท้าย callback
///
/// ตัวอย่าง:
///
/// // ❌ เดิม
/// ElevatedButton(
///   onPressed: () {
///     doSomething();
///   },
///   child: Text('Click'),
/// )
///
/// // ✅ ใหม่ (แค่เพิ่ม .withButtonSound())
/// ElevatedButton(
///   onPressed: () {
///     doSomething();
///   }.withButtonSound(),  // ⭐ เพิ่มแค่นี้!
///   child: Text('Click'),
/// )
///
/// // สำหรับ async functions
/// ElevatedButton(
///   onPressed: () async {
///     await saveData();
///   }.withButtonSound(),  // ⭐ ใช้ได้กับ async ด้วย!
///   child: Text('Save'),
/// )
///
/// // ใช้เสียงอื่น ๆ
/// IconButton(
///   icon: Icon(Icons.add),
///   onPressed: () { addItem(); }.withAddSound(),  // เสียงเพิ่มสินค้า
/// )
///
/// IconButton(
///   icon: Icon(Icons.remove),
///   onPressed: () { removeItem(); }.withRemoveSound(),  // เสียงลบ
/// )
///
/// ElevatedButton(
///   onPressed: () async {
///     await processPayment();
///   }.withPaymentSound(),  // เสียงชำระเงิน
///   child: Text('ชำระเงิน'),
/// )
///
/// ========================================
/// 🎨 วิธีที่ 2: ใช้ Sound UI Helpers
/// ========================================
///
/// Step 1: เพิ่ม import
/// ```dart
/// import 'package:dedecashier/util/sound_ui_helpers.dart';
/// ```
///
/// Step 2: แทนที่ Widget ปกติด้วย Sound Widget
///
/// ตัวอย่าง:
///
/// // แทนที่ ElevatedButton → SoundElevatedButton
/// SoundElevatedButton(
///   sound: global.SoundEnum.buttonTing,
///   onPressed: () { doSomething(); },
///   child: Text('Click'),
/// )
///
/// // แทนที่ IconButton → SoundIconButton
/// SoundIconButton(
///   icon: Icon(Icons.add),
///   sound: global.SoundEnum.itemAdded,
///   onPressed: () { addItem(); },
/// )
///
/// // แทนที่ InkWell → SoundInkWell
/// SoundInkWell(
///   sound: global.SoundEnum.buttonTing,
///   onTap: () { selectItem(); },
///   child: Container(...),
/// )
///
/// ========================================
/// 📋 Checklist: หน้าจอที่ต้องแก้
/// ========================================
///
/// POS Core Screens:
/// □ pos_screen.dart (หน้าจอหลัก - สำคัญที่สุด!)
/// □ pay_screen.dart (หน้าจอชำระเงิน)
/// □ pay_qr_screen.dart (QR Payment)
/// □ pos_num_pad.dart (✅ แก้แล้ว)
///
/// POS Management:
/// □ pos_login_screen.dart
/// □ menu_screen.dart
/// □ loading_screen.dart
/// □ pos_reprint_bill.dart
/// □ pos_cancel_bill.dart
/// □ pos_bill_vat.dart
///
/// Product Management:
/// □ pos_product_weight.dart
/// □ pos_sale_channel.dart
///
/// Settings:
/// □ select_language_screen.dart
/// □ select_mode_screen.dart
///
/// ========================================
/// 🎯 Priority Order (ลำดับความสำคัญ)
/// ========================================
///
/// 1. 🔥 สูงสุด (ต้องแก้ก่อน):
///    - pos_screen.dart (หน้าจอขายหลัก)
///    - pay_screen.dart (ชำระเงิน)
///    - pos_num_pad.dart (✅ เสร็จแล้ว)
///
/// 2. ⚡ สูง:
///    - pay_qr_screen.dart (QR Payment)
///    - menu_screen.dart (เมนูหลัก)
///    - pos_login_screen.dart (Login)
///
/// 3. 📊 ปานกลาง:
///    - pos_reprint_bill.dart
///    - pos_cancel_bill.dart
///    - pos_product_weight.dart
///
/// 4. 💡 ต่ำ (แก้ทีหลัง):
///    - loading_screen.dart
///    - select_language_screen.dart
///    - settings screens อื่น ๆ
///
/// ========================================
/// 🚀 Quick Commands
/// ========================================
///
/// 1. ค้นหาปุ่มทั้งหมดในไฟล์:
///    grep -n "onPressed\|onTap" lib/features/pos/presentation/screens/pos_screen.dart
///
/// 2. นับจำนวนปุ่ม:
///    grep -c "ElevatedButton\|IconButton\|InkWell" pos_screen.dart
///
/// 3. ทดสอบเสียง:
///    global.playSound(sound: global.SoundEnum.buttonTing);
///
/// ========================================
/// 💡 Tips & Best Practices
/// ========================================
///
/// 1. ใช้เสียงให้เหมาะสม:
///    - ปุ่มทั่วไป → buttonTing
///    - เพิ่มสินค้า → itemAdded
///    - ลบสินค้า → itemRemoved
///    - ชำระเงิน → paymentSuccess
///    - Error → fail
///
/// 2. อย่าใช้เสียงมากเกินไป:
///    - เล่นเสียงเฉพาะปุ่มที่สำคัญ
///    - ไม่ใช่ทุก onTap/onPressed ต้องมีเสียง
///
/// 3. Test ให้มาก:
///    - ทดสอบว่าเสียงเล่นไหลลื่น
///    - ไม่มี delay หรือสะดุด
///    - ทำงานได้บนทุก platform
///
/// 4. Performance:
///    - เสียงถูก preload แล้วตอนเริ่ม app
///    - ไม่มี delay ตอนเล่น
///    - Fire-and-forget (ไม่ block UI)
///
/// ========================================
/// ❓ FAQ
/// ========================================
///
/// Q: จะรู้ได้ยังไงว่าเสียงเล่นแล้ว?
/// A: ดูใน Debug Console จะมี log [Sound] Playing ...
///
/// Q: เสียงไม่ออก?
/// A: ตรวจสอบว่า:
///    1. เรียก preloadAllSounds() แล้วหรือยัง (ใน bootstrap.dart)
///    2. ไฟล์เสียงมีอยู่ใน assets/audios/
///    3. pubspec.yaml มี asset paths ครบ
///
/// Q: จะเปลี่ยนเสียงได้ไหม?
/// A: ได้! แค่แทนที่ไฟล์ .wav ในโฟลเดอร์ assets/audios/
///
/// Q: ต้องแก้โค้ดเยอะไหม?
/// A: ไม่! ใช้ .withButtonSound() แค่เพิ่มท้าย callback
///
/// ========================================
/// 📞 Support
/// ========================================
///
/// ถ้ามีปัญหา ดูที่:
/// - lib/util/sound_ui_helpers.dart
/// - lib/util/widget_sound_extensions.dart
/// - lib/util/sound_examples.dart
/// - lib/global.dart (SoundEnum)
///
/// ========================================

library; // Empty library - เป็นเฉพาะเอกสาร
