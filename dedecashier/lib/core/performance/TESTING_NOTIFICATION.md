# 🔔 วิธีทดสอบ Printer Notification

## ✅ การติดตั้งเสร็จสิ้นแล้ว!

Notification overlay ได้ถูกเพิ่มเข้าไปใน `lib/app/app_view.dart` แล้ว

---

## 🧪 วิธีทดสอบ

### 1. **Run แอป**
```bash
flutter run -d windows --flavor marine
```

### 2. **สถานการณ์ที่จะเห็น Notification**

#### ✅ **เมื่อเครื่องพิมพ์ Offline**
```
เงื่อนไข:
- เครื่องพิมพ์ออนไลน์อยู่ → offline

ผลลัพธ์:
🔔 Notification สีแดงขึ้นด้านล่างจอ
   "เครื่องพิมพ์ PRINTER_HOST ไม่พร้อมใช้งาน"

Log:
[08:03:53] 🔔 Printer offline notification: เครื่องพิมพ์ ...
```

#### ✅ **เมื่อเครื่องพิมพ์กลับมา Online**
```
เงื่อนไข:
- เครื่องพิมพ์ offline → กลับมา online

ผลลัพธ์:
🔔 Notification สีเขียวขึ้นด้านล่างจอ
   "เครื่องพิมพ์พร้อมใช้งานแล้ว"

Log:
[08:05:00] 🔔 Printer online notification: เครื่องพิมพ์พร้อมใช้งานแล้ว
```

---

## 🔍 Debug: ถ้าไม่เห็น Notification

### 1. **เช็ค Log**
ดูใน console ว่ามี log นี้หรือไม่:
```
🔔 Printer offline notification: ...
```

ถ้า **มี log แต่ไม่เห็น notification** = UI ไม่ render

### 2. **เช็ค Performance Manager ทำงานหรือไม่**
```
[08:03:38] Printer status check completed - Any ready: false
```

ถ้า **ไม่มี log นี้** = Performance Manager ยังไม่ start

### 3. **เช็ค Cooldown**
Notification จะไม่ส่งซ้ำภายใน 30 วินาที

ถ้าเพิ่ง offline ไป รอ 30 วินาทีแล้วลองอีกครั้ง

---

## 🎯 วิธีบังคับให้เห็น Notification (Development)

### วิธีที่ 1: ปิด/เปิดเครื่องพิมพ์
```
1. ปิดเครื่องพิมพ์
2. รอ 15 วินาที (timer check)
3. เห็น notification สีแดง
4. เปิดเครื่องพิมพ์
5. รอ 15 วินาที
6. เห็น notification สีเขียว
```

### วิธีที่ 2: ใช้ Code ทดสอบ (เฉพาะ development)
เพิ่มใน debug menu:
```dart
// ทดสอบ offline notification
AppPerformanceManager.printerNotificationNotifier.value = 
  _PrinterNotification(
    message: 'เครื่องพิมพ์ Test ไม่พร้อมใช้งาน',
    type: _PrinterNotificationType.error,
    affectedPrinters: ['Test Printer'],
  );

// ทดสอบ online notification
AppPerformanceManager.printerNotificationNotifier.value = 
  _PrinterNotification(
    message: 'เครื่องพิมพ์พร้อมใช้งานแล้ว',
    type: _PrinterNotificationType.success,
    affectedPrinters: [],
  );
```

---

## 📊 Timeline การทำงาน

```
[00:00] Start Performance Manager
        ↓
[00:15] Check printer #1 (every 15s)
        ├─ PRINTER_HOST:9100 timeout
        ├─ Retry #1 failed
        ├─ Retry #2 failed
        └─ Mark as offline
        ↓
[00:15] Detect status change (online → offline)
        └─ 🔔 Send notification
        ↓
[00:20] Auto dismiss notification
        ↓
[00:30] Check printer #2
        └─ Still offline, skip notification (cooldown)
        ↓
[01:00] Printer back online
        └─ 🔔 Send notification (success)
```

---

## ⚠️ สิ่งที่ต้องระวัง

### 1. **Cooldown 30 วินาที**
ถ้าเครื่องพิมพ์ offline แล้ว notification จะไม่ส่งซ้ำภายใน 30 วินาที

**วิธีแก้ (ถ้าต้องการทดสอบ):**
```dart
// ใน app_performance_manager.dart (บรรทัด 43)
static const Duration _notificationCooldown = Duration(seconds: 5); // ลดเหลือ 5 วินาที
```

### 2. **Auto Dismiss 5 วินาที**
Notification จะหายเองหลัง 5 วินาที

**วิธีแก้ (ถ้าต้องการให้อยู่นาน):**
```dart
// ใน _sendPrinterNotification() method
Future.delayed(const Duration(seconds: 15), () { // เพิ่มเป็น 15 วินาที
  ...
});
```

### 3. **Material App Builder**
Notification ทำงานผ่าน `MaterialApp.builder`

ถ้าแก้ไข app structure อาจต้องปรับตำแหน่ง `PrinterNotificationOverlay()`

---

## 🎨 การ Customize

### เปลี่ยนตำแหน่ง Notification
```dart
// ใน PrinterNotificationOverlay (app_performance_manager.dart)
return Positioned(
  bottom: 20,  // เปลี่ยนเป็น 20px (ใกล้ขอบมากขึ้น)
  left: 16,
  right: 16,
  child: ...
);
```

### เปลี่ยนสี
```dart
// ใน _PrinterNotification class
Color get color {
  switch (type) {
    case _PrinterNotificationType.error:
      return Colors.deepOrange; // เปลี่ยนจากแดงเป็นส้ม
    ...
  }
}
```

---

## 📱 Production Checklist

เมื่อ deploy จริง ควรเช็ค:

- ✅ Cooldown = 30 วินาที (ไม่ spam)
- ✅ Auto dismiss = 5 วินาที (ไม่รบกวน)
- ✅ Performance Manager start ใน bootstrap
- ✅ Log ใน production = warning/error only
- ✅ Debug logs = kDebugMode only

---

## 🆘 Troubleshooting

### ปัญหา: "ไม่เห็น notification เลย"
```
เช็คตามลำดับ:
1. ✅ MaterialApp.builder มี Stack + PrinterNotificationOverlay
2. ✅ AppPerformanceManager.instance.start() ถูกเรียกแล้ว
3. ✅ Printer มีการเปลี่ยนสถานะ (online → offline หรือกลับกัน)
4. ✅ ไม่อยู่ใน cooldown period
5. ✅ Log แสดง "🔔 Printer ... notification"
```

### ปัญหา: "Notification ไม่หาย"
```
เช็ค:
- Auto dismiss timer (ควรเป็น 5 วินาที)
- Widget ไม่ได้ถูก rebuild ตลอดเวลา
```

### ปัญหา: "Notification แสดงบ่อยเกินไป"
```
เช็ค:
- Cooldown duration (ควรเป็น 30 วินาที)
- Performance Manager ไม่ได้ start หลายครั้ง
```

---

## 📞 Support

ถ้ามีปัญหา ให้ดู log pattern นี้:
```
[TIME] [Printer] ✅/❌ Status
[TIME] 🔔 Notification sent
[TIME] Printer status check completed
```

ถ้า log ไม่ตรง pattern นี้ = มีปัญหาที่ Performance Manager
