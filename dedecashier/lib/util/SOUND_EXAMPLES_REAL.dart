/// 🎯 ตัวอย่างการเพิ่มเสียงในหน้าจอ POS ที่สำคัญ
///
/// ไฟล์นี้แสดงตัวอย่างการแก้ไขจริง ๆ ในหน้าจอต่าง ๆ
///
/// ========================================
/// 1. POS SCREEN (หน้าจอขายหลัก)
/// ========================================

// ❌ เดิม (ไม่มีเสียง)
/*
ElevatedButton(
  onPressed: () async {
    await addToCart(product);
  },
  child: Text('เพิ่มสินค้า'),
)
*/

// ✅ ใหม่ (มีเสียง)
/*
import 'package:dedecashier/util/widget_sound_extensions.dart';

ElevatedButton(
  onPressed: () async {
    await addToCart(product);
  }.withAddSound(),  // ⭐ เพิ่มแค่นี้!
  child: Text('เพิ่มสินค้า'),
)
*/

/// ========================================
/// 2. PAY SCREEN (หน้าจอชำระเงิน)
/// ========================================

// ปุ่มชำระเงินสด
/*
import 'package:dedecashier/util/widget_sound_extensions.dart';

ElevatedButton(
  onPressed: () async {
    await processCashPayment();
  }.withPaymentSound(),  // ⭐ เสียงชำระเงิน
  child: Text('ชำระเงินสด'),
)
*/

// ปุ่มชำระด้วยบัตร
/*
ElevatedButton(
  onPressed: () async {
    await processCardPayment();
  }.withPaymentSound(),  // ⭐ เสียงชำระเงิน
  child: Text('ชำระบัตร'),
)
*/

/// ========================================
/// 3. MENU SCREEN (เมนูหลัก)
/// ========================================

// ปุ่มเมนูต่าง ๆ
/*
import 'package:dedecashier/util/widget_sound_extensions.dart';

// ปุ่มขายสินค้า
InkWell(
  onTap: () {
    navigateToSales();
  }.withButtonSound(),  // ⭐ เสียงปุ่มทั่วไป
  child: MenuCard(...),
)

// ปุ่มรายงาน
InkWell(
  onTap: () {
    navigateToReports();
  }.withButtonSound(),
  child: MenuCard(...),
)
*/

/// ========================================
/// 4. POS LOGIN SCREEN
/// ========================================

/*
import 'package:dedecashier/util/widget_sound_extensions.dart';

// ปุ่ม Login
ElevatedButton(
  onPressed: () async {
    await login();
  }.withConfirmSound(),  // ⭐ เสียงยืนยัน
  child: Text('เข้าสู่ระบบ'),
)

// ปุ่ม Logout
IconButton(
  icon: Icon(Icons.logout),
  onPressed: () {
    logout();
  }.withButtonSound(),
  child: Text('ออกจากระบบ'),
)
*/

/// ========================================
/// 5. QR PAYMENT SCREEN
/// ========================================

/*
import 'package:dedecashier/util/widget_sound_extensions.dart';

// ปุ่มสร้าง QR
ElevatedButton(
  onPressed: () async {
    await generateQR();
  }.withButtonSound(),
  child: Text('สร้าง QR Code'),
)

// เมื่อชำระเงินสำเร็จ
void onQRPaymentSuccess() {
  global.playSound(sound: global.SoundEnum.qrPaymentSuccess);
  // ... handle success
}
*/

/// ========================================
/// 6. PRODUCT LIST (รายการสินค้า)
/// ========================================

/*
import 'package:dedecashier/util/widget_sound_extensions.dart';

// ปุ่มเลือกสินค้า
GestureDetector(
  onTap: () {
    selectProduct(product);
  }.withButtonSound(),
  child: ProductCard(...),
)

// ปุ่มเพิ่มจำนวน
IconButton(
  icon: Icon(Icons.add),
  onPressed: () {
    increaseQuantity();
  }.withAddSound(),  // ⭐ เสียงเพิ่ม
)

// ปุ่มลดจำนวน
IconButton(
  icon: Icon(Icons.remove),
  onPressed: () {
    decreaseQuantity();
  }.withRemoveSound(),  // ⭐ เสียงลบ
)
*/

/// ========================================
/// 7. BILL MANAGEMENT
/// ========================================

/*
import 'package:dedecashier/util/widget_sound_extensions.dart';

// ปุ่มพิมพ์ใบเสร็จ
ElevatedButton(
  onPressed: () async {
    await printBill();
  }.withConfirmSound(),  // ⭐ เสียงยืนยัน
  child: Text('พิมพ์ใบเสร็จ'),
)

// ปุ่มยกเลิกบิล
ElevatedButton(
  onPressed: () async {
    await cancelBill();
  }.withClearSound(),  // ⭐ เสียงยกเลิก
  child: Text('ยกเลิก'),
)

// ปุ่มพักบิล
ElevatedButton(
  onPressed: () async {
    await holdBill();
  }.withButtonSound(),
  child: Text('พักบิล'),
)
*/

/// ========================================
/// 8. DIALOG BUTTONS
/// ========================================

/*
import 'package:dedecashier/util/widget_sound_extensions.dart';

// Dialog ยืนยัน
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('ยืนยันการลบ?'),
    actions: [
      // ปุ่มยกเลิก
      TextButton(
        onPressed: () {
          Navigator.pop(context);
        }.withButtonSound(),
        child: Text('ยกเลิก'),
      ),
      // ปุ่มยืนยัน
      TextButton(
        onPressed: () async {
          await confirmDelete();
          Navigator.pop(context);
        }.withConfirmSound(),  // ⭐ เสียงยืนยัน
        child: Text('ยืนยัน'),
      ),
    ],
  ),
)
*/

/// ========================================
/// 9. ERROR HANDLING
/// ========================================

/*
import 'package:dedecashier/global.dart' as global;

// เมื่อเกิด Error
void showError(String message) {
  global.playSound(sound: global.SoundEnum.fail);  // ⭐ เสียง Error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

// เมื่อสแกนบาร์โค้ดสำเร็จ
void onBarcodeScanned(String barcode) {
  global.playSound(sound: global.SoundEnum.beep);  // ⭐ เสียง Beep
  // ... process barcode
}

// เมื่อสแกนบาร์โค้ดล้มเหลว
void onBarcodeScanFailed() {
  global.playSound(sound: global.SoundEnum.fail);  // ⭐ เสียง Fail
  // ... show error
}
*/

/// ========================================
/// 10. ADVANCED: Custom Sound Logic
/// ========================================

/*
import 'package:dedecashier/global.dart' as global;

// เล่นเสียงต่างกันตาม condition
void handleAction(ActionType type) {
  switch (type) {
    case ActionType.add:
      global.playSound(sound: global.SoundEnum.itemAdded);
      break;
    case ActionType.remove:
      global.playSound(sound: global.SoundEnum.itemRemoved);
      break;
    case ActionType.payment:
      global.playSound(sound: global.SoundEnum.paymentSuccess);
      break;
    default:
      global.playSound(sound: global.SoundEnum.buttonTing);
  }
  
  // ... do the actual action
}

// เสียงตามสถานะการชำระเงิน
void onPaymentStatusChanged(PaymentStatus status) {
  if (status == PaymentStatus.success) {
    global.playSound(sound: global.SoundEnum.paymentSuccess);
  } else if (status == PaymentStatus.timeout) {
    global.playSound(sound: global.SoundEnum.qrPaymentTimeout);
  } else if (status == PaymentStatus.failed) {
    global.playSound(sound: global.SoundEnum.fail);
  }
}
*/

/// ========================================
/// 📊 สรุป Pattern ที่ใช้บ่อย
/// ========================================

/*
1. ปุ่มทั่วไป:
   .withButtonSound()

2. เพิ่มสินค้า:
   .withAddSound()

3. ลบสินค้า:
   .withRemoveSound()

4. ชำระเงิน:
   .withPaymentSound()

5. ยืนยัน:
   .withConfirmSound()

6. ยกเลิก/ล้าง:
   .withClearSound()

7. Error:
   .withErrorSound()

8. Custom:
   global.playSound(sound: global.SoundEnum.xxx)
*/

library; // Empty library - เป็นเฉพาะตัวอย่าง
