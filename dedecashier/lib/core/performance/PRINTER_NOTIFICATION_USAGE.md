# 🔔 Printer Notification System - วิธีใช้งาน

## ภาพรวม
ระบบเตือนเครื่องพิมพ์แบบ **Non-Intrusive** (ไม่รบกวนการทำงาน)

---

## 🎯 Features

### 1. **Floating Notification Card**
- ขึ้นด้านล่างจอ (ไม่บังเนื้อหา)
- Animation เลื่อนขึ้นแบบนุ่มนวล
- สีแยกตามประเภท: แดง (error), เขียว (success)
- หายอัตโนมัติหลัง 5 วินาที
- แตะเพื่อปิดได้

### 2. **Persistent Status Indicator**
- ไอคอนเครื่องพิมพ์มุมจอ
- สีเขียว = ปกติ, สีแดง = มีปัญหา
- แสดงจำนวนเครื่องที่ offline

### 3. **Smart Cooldown**
- ไม่ส่ง notification บ่อยเกินไป (30 วินาที/ครั้ง)
- ส่งเฉพาะเมื่อสถานะเปลี่ยน

---

## 📦 การติดตั้ง

### Step 1: วางใน MaterialApp (แนะนำ)

```dart
import 'package:dedecashier/core/performance/app_performance_manager.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          YourMainContent(),
          
          // 🔔 วาง notification overlay ไว้นี่
          PrinterNotificationOverlay(),
        ],
      ),
    );
  }
}
```

### Step 2: เพิ่ม Status Indicator ใน AppBar (ทางเลือก)

```dart
AppBar(
  title: Text('POS System'),
  actions: [
    // 🔴 แสดงสถานะเครื่องพิมพ์
    PrinterStatusIndicator(),
    SizedBox(width: 16),
  ],
)
```

---

## 🎨 การ Customize

### ปรับขนาด Status Indicator

```dart
PrinterStatusIndicator(
  size: 28,  // ขนาดไอคอน
  padding: EdgeInsets.all(12),
)
```

### ปรับ Notification Cooldown

```dart
// ใน app_performance_manager.dart
static const Duration _notificationCooldown = Duration(seconds: 60); // เปลี่ยนเป็น 60 วินาที
```

### ปรับระยะเวลาแสดง Notification

```dart
// ใน _sendPrinterNotification() method
Future.delayed(const Duration(seconds: 10), () { // เปลี่ยนเป็น 10 วินาที
  if (printerNotificationNotifier.value == notification) {
    printerNotificationNotifier.value = null;
  }
});
```

---

## 📊 การทำงาน

### 1. เครื่องพิมพ์ Offline
```
[07:51:05] ตรวจพบ printer offline
           ↓
[07:51:05] แสดง notification สีแดง
           "เครื่องพิมพ์ PRINTER_HOST ไม่พร้อมใช้งาน"
           ↓
[07:51:10] หาย notification อัตโนมัติ (5 วินาที)
           ↓
[07:51:35] ไม่ส่ง notification ซ้ำ (cooldown 30 วินาที)
```

### 2. เครื่องพิมพ์กลับมา Online
```
[08:00:00] ตรวจพบ printer กลับมา
           ↓
[08:00:00] แสดง notification สีเขียว
           "เครื่องพิมพ์พร้อมใช้งานแล้ว"
           ↓
[08:00:05] หาย notification อัตโนมัติ
```

---

## 🔍 Debug

### ดู Notification Events (kDebugMode)

```
[08:00:00] 🔔 Printer offline notification: เครื่องพิมพ์ PRINTER_HOST ไม่พร้อมใช้งาน
[08:05:00] 🔔 Printer online notification: เครื่องพิมพ์พร้อมใช้งานแล้ว
```

### Manual Test

```dart
// ใน developer tools
AppPerformanceManager.printerNotificationNotifier.value = _PrinterNotification(
  message: 'Test Notification',
  type: _PrinterNotificationType.error,
  affectedPrinters: ['Test Printer'],
);
```

---

## 🎯 Best Practices

### ✅ DO
- วาง `PrinterNotificationOverlay()` ใน root Stack
- ใช้ `PrinterStatusIndicator()` ใน AppBar
- ปล่อยให้ auto-dismiss (5 วินาที)
- เก็บ cooldown ไว้ (30 วินาที)

### ❌ DON'T
- อย่าวาง overlay ซ้อนกัน
- อย่าปิด notification ด้วย code (ให้ user แตะ)
- อย่าลด cooldown ต่ำกว่า 15 วินาที (spam)
- อย่าใช้ alert dialog (รบกวน workflow)

---

## 📱 UI/UX Guidelines

### Positioning
- **Bottom** (แนะนำ): ไม่บังเนื้อหาหลัก
- **Top**: เฉพาะ critical errors
- **Center**: ❌ ห้ามใช้ (บังหน้าจอ)

### Duration
- **Error**: 5 วินาที (ยาวพอจะอ่าน)
- **Success**: 3 วินาที (อ่านเร็ว)
- **Warning**: 4 วินาที (กลางๆ)

### Colors
- 🔴 Red (#C62828): Offline/Error
- 🟢 Green (#2E7D32): Online/Success
- 🟡 Orange (#EF6C00): Warning

---

## 🚀 Advanced Usage

### Listen เองใน Custom Widget

```dart
ValueListenableBuilder<_PrinterNotification?>(
  valueListenable: AppPerformanceManager.printerNotificationNotifier,
  builder: (context, notification, child) {
    if (notification != null) {
      // แสดง custom UI ของคุณเอง
      return YourCustomNotification(notification);
    }
    return SizedBox.shrink();
  },
)
```

### Integration กับ SnackBar

```dart
AppPerformanceManager.printerNotificationNotifier.addListener(() {
  final notification = AppPerformanceManager.printerNotificationNotifier.value;
  if (notification != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(notification.message)),
    );
  }
});
```

---

## 🔧 Troubleshooting

### ไม่เห็น Notification
1. เช็คว่าวาง `PrinterNotificationOverlay()` แล้ว
2. เช็คว่า Stack อยู่ level ที่ถูกต้อง
3. เช็ค cooldown (อาจจะยังไม่หมดเวลา)

### Notification ซ้อนกัน
1. วาง overlay เพียงจุดเดียว (root level)
2. ใช้ SafeArea ให้ถูกต้อง

### ปิดช้า/เร็วเกินไป
1. ปรับ `Future.delayed` duration
2. ปรับ animation speed

---

## 📄 License & Credits

Part of DedeCashier POS System  
© 2025 SML Soft
