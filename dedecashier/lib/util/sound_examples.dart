// 🔊 ตัวอย่างการใช้งานระบบเสียงใน POS
// ไฟล์นี้แสดงตัวอย่างวิธีการเรียกใช้เสียงในแต่ละสถานการณ์

import 'package:dedecashier/global.dart' as global;

// ========================================
// 1. เสียงสำหรับธุรกรรม (Transaction)
// ========================================

/// เรียกเมื่อชำระเงินสำเร็จ
void onPaymentSuccess() {
  global.playSound(sound: global.SoundEnum.paymentSuccess);
  // จากนั้นทำ business logic ต่อ...
}

/// เรียกเมื่อเปิดลิ้นชักเงิน
void onOpenCashDrawer() {
  global.playSound(sound: global.SoundEnum.cashDrawerOpen);
  // จากนั้นเปิดลิ้นชักจริง...
}

// ========================================
// 2. เสียงสำหรับออเดอร์ (Order)
// ========================================

/// เรียกเมื่อมีออเดอร์ใหม่เข้ามา
void onNewOrderReceived() {
  global.playSound(sound: global.SoundEnum.newOrder);
  // แจ้งครัว...
}

/// เรียกเมื่ออาหารพร้อมเสิร์ฟ
void onOrderReady() {
  global.playSound(sound: global.SoundEnum.orderReady);
  // แจ้งพนักงานเสิร์ฟ...
}

/// เรียกเมื่อยกเลิกออเดอร์
void onOrderCancelled() {
  global.playSound(sound: global.SoundEnum.orderCancelled);
  // ทำการยกเลิก...
}

/// เรียกเมื่อแจ้งเตือนครัว (มีออเดอร์ด่วน)
void onKitchenAlertUrgent() {
  global.playSound(sound: global.SoundEnum.kitchenAlert);
  // ส่งไปครัว...
}

// ========================================
// 3. เสียงสำหรับ QR Payment
// ========================================

/// เรียกเมื่อสแกน QR สำเร็จ
void onQrCodeScanned() {
  global.playSound(sound: global.SoundEnum.qrScanned);
  // ประมวลผล QR...
}

/// เรียกเมื่อชำระผ่าน QR สำเร็จ
void onQrPaymentSuccess() {
  global.playSound(sound: global.SoundEnum.qrPaymentSuccess);
  // บันทึกการชำระเงิน...
}

/// เรียกเมื่อ QR หมดอายุ
void onQrPaymentTimeout() {
  global.playSound(sound: global.SoundEnum.qrPaymentTimeout);
  // แจ้งเตือนให้สร้าง QR ใหม่...
}

// ========================================
// 4. เสียงสำหรับระบบ (System)
// ========================================

/// เรียกเมื่อเครื่องพิมพ์ขัดข้อง
void onPrinterError() {
  global.playSound(sound: global.SoundEnum.printerError);
  // แสดง error dialog...
}

/// เรียกเมื่อมีปัญหาเครือข่าย
void onNetworkError() {
  global.playSound(sound: global.SoundEnum.networkError);
  // แจ้งเตือนพนักงาน...
}

/// เรียกเมื่อซิงค์ข้อมูลสำเร็จ
void onSyncComplete() {
  global.playSound(sound: global.SoundEnum.syncComplete);
  // อัพเดท UI...
}

// ========================================
// 5. เสียงสำหรับ Customer Display
// ========================================

/// เรียกเมื่อเชื่อมต่อหน้าจอลูกค้าสำเร็จ
void onCustomerDisplayConnected() {
  global.playSound(sound: global.SoundEnum.customerDisplayConnected);
  // เริ่มแสดงผลบนหน้าจอลูกค้า...
}

/// เรียกเมื่อเพิ่มสินค้า
void onItemAdded() {
  global.playSound(sound: global.SoundEnum.itemAdded);
  // อัพเดท UI...
}

/// เรียกเมื่อลบสินค้า
void onItemRemoved() {
  global.playSound(sound: global.SoundEnum.itemRemoved);
  // อัพเดท UI...
}

// ========================================
// 6. เสียงเดิมที่มีอยู่แล้ว
// ========================================

/// สแกนบาร์โค้ดสำเร็จ
void onBarcodeScanned() {
  global.playSound(sound: global.SoundEnum.beep);
  // ดึงข้อมูลสินค้า...
}

/// สแกนบาร์โค้ดล้มเหลว
void onBarcodeFailed() {
  global.playSound(sound: global.SoundEnum.fail);
  // แสดง error...
}

/// กดปุ่ม
void onButtonPressed() {
  global.playSound(sound: global.SoundEnum.buttonTing);
  // ทำงานตามปุ่มที่กด...
}

// ========================================
// 7. เสียงสำหรับ NumPad (ตัวเลข 0-9)
// ========================================

/// กดปุ่มตัวเลขใน NumPad
void onNumPadNumberPressed(String number) {
  switch (number) {
    case '0':
      global.playSound(sound: global.SoundEnum.num0);
      break;
    case '1':
      global.playSound(sound: global.SoundEnum.num1);
      break;
    case '2':
      global.playSound(sound: global.SoundEnum.num2);
      break;
    case '3':
      global.playSound(sound: global.SoundEnum.num3);
      break;
    case '4':
      global.playSound(sound: global.SoundEnum.num4);
      break;
    case '5':
      global.playSound(sound: global.SoundEnum.num5);
      break;
    case '6':
      global.playSound(sound: global.SoundEnum.num6);
      break;
    case '7':
      global.playSound(sound: global.SoundEnum.num7);
      break;
    case '8':
      global.playSound(sound: global.SoundEnum.num8);
      break;
    case '9':
      global.playSound(sound: global.SoundEnum.num9);
      break;
    case '.':
      global.playSound(sound: global.SoundEnum.numDot);
      break;
  }
}

/// กด Delete ใน NumPad
void onNumPadDelete() {
  global.playSound(sound: global.SoundEnum.numpadDelete);
  // ลบตัวเลขล่าสุด...
}

/// กด Clear ใน NumPad
void onNumPadClear() {
  global.playSound(sound: global.SoundEnum.numpadClear);
  // ล้างตัวเลขทั้งหมด...
}

/// กด Enter ใน NumPad
void onNumPadEnter() {
  global.playSound(sound: global.SoundEnum.numpadEnter);
  // ยืนยันค่าที่กรอก...
}

// ========================================
// 📝 หมายเหตุการใช้งาน
// ========================================
/*
✅ การใช้งาน:
  - เรียก playSound() ก่อนทำ business logic
  - ไม่ต้องรอให้เสียงเล่นเสร็จ (fire-and-forget)
  - ใช้งานได้บน Windows, Android, iOS

⚠️ ข้อควรระวัง:
  - อย่าเล่นเสียงบ่อยเกินไป (spam)
  - ควรมีการตั้งค่าเปิด/ปิดเสียงให้ผู้ใช้
  - ปริมาณเสียงควรปรับได้

🎯 แนะนำการใช้งาน:
  1. Payment Success - เล่นทุกครั้งที่ชำระเงินสำเร็จ
  2. New Order - เล่นเมื่อมีออเดอร์ใหม่ (ครัวจะได้ยิน)
  3. Printer Error - เล่นเมื่อเครื่องพิมพ์เสีย (แจ้งเตือนทันที)
  4. Order Ready - เล่นเมื่ออาหารพร้อม (พนักงานเสิร์ฟจะได้ยิน)
  
🔧 ปรับแต่งในอนาคต:
  - เพิ่มการตั้งค่า volume แยกตามประเภทเสียง
  - เพิ่มการเลือกเสียงที่ชอบ (sound theme)
  - เพิ่มการสั่นเครื่อง (vibration) สำหรับ mobile
*/
