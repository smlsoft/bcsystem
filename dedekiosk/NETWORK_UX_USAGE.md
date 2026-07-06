# Network UX Components - Usage Guide

คู่มือการใช้งาน Network UX Components สำหรับ DeDe Kiosk

## 📦 Components ที่มี

1. **NetworkLoadingOverlay** - Loading indicator แบบเต็มจอ
2. **NetworkErrorDialog** - Error dialog พร้อม retry/cancel
3. **NetworkStatusWidget** - แสดงสถานะ network
4. **NetworkErrorSnackbar** - Snackbar แจ้งเตือนแบบเบา
5. **withLoadingIndicator** - Helper function สำหรับห่อ operation

---

## 🔄 1. Loading Indicator

### วิธีใช้แบบ Basic

```dart
import 'package:dedekiosk/widget/network_loading_indicator.dart';

// แสดง loading
NetworkLoadingOverlay.show(
  context,
  message: global.language("checking_stock"),
);

// ซ่อน loading
NetworkLoadingOverlay.hide(context);
```

### วิธีใช้แบบ Auto (แนะนำ)

```dart
// ห่อ operation ด้วย withLoadingIndicator
final result = await withLoadingIndicator<Map>(
  context: context,
  message: global.language("checking_stock"),
  operation: () => api.clickHouseSelect(query),
);
```

### ตัวอย่างในโค้ดจริง

```dart
// ใน order_util.dart
Future<void> orderAdd({...}) async {
  if (calcStockQty) {
    // แสดง loading ขณะเช็คสต็อก
    final stockResult = await withLoadingIndicator<Map>(
      context: context,
      message: global.language("checking_stock"),
      operation: () => api.clickHouseSelect(stockQuery),
    );

    if (stockResult != null) {
      // ประมวลผล...
    }
  }
}
```

---

## ❌ 2. Error Dialogs

### Timeout Error

```dart
import 'package:dedekiosk/widget/network_error_dialog.dart';

NetworkErrorDialog.showTimeoutError(
  context,
  customMessage: "การตรวจสอบสต็อกใช้เวลานานเกินไป",
  showContinue: true,
  onRetry: () {
    // ลองอีกครั้ง
    _retryStockCheck();
  },
  onContinue: () {
    // ข้ามการเช็คสต็อก
    _skipStockCheck();
  },
  onCancel: () {
    // ยกเลิก
    Navigator.pop(context);
  },
);
```

### Connection Error

```dart
NetworkErrorDialog.showConnectionError(
  context,
  customMessage: "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้",
  onRetry: () => _retryConnection(),
  onCancel: () => Navigator.pop(context),
);
```

### Server Error

```dart
NetworkErrorDialog.showServerError(
  context,
  onRetry: () => _retryRequest(),
);
```

### Generic Error

```dart
NetworkErrorDialog.showGenericError(
  context,
  title: "เกิดข้อผิดพลาด",
  message: "กรุณาลองใหม่อีกครั้ง",
  onRetry: () => _retry(),
);
```

---

## 🔔 3. Error Snackbar (สำหรับ non-critical errors)

```dart
import 'package:dedekiosk/widget/network_error_dialog.dart';

// แสดง snackbar
NetworkErrorSnackbar.show(
  context,
  message: "การซิงค์ล้มเหลว",
  errorType: NetworkErrorType.timeout,
  onRetry: () => _retrySync(),
);
```

---

## 📶 4. Network Status Widget

### วางที่ MainPage

```dart
// ใน main_page.dart หรือ order_page.dart

import 'package:dedekiosk/widget/network_status_widget.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("DeDe Kiosk"),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(30),
        child: NetworkStatusWidget(),
      ),
    ),
    body: // ... your content
  );
}
```

---

## 📋 5. ตัวอย่างการใช้งานจริง

### ตัวอย่างที่ 1: Stock Check with Timeout Handling

```dart
Future<void> _checkStock(String barcode, double qty) async {
  try {
    // แสดง loading
    final stockQty = await withLoadingIndicator<double>(
      context: context,
      message: global.language("checking_stock"),
      operation: () async {
        final result = await api
            .clickHouseSelect(stockQuery)
            .timeout(NetworkTimeouts.quick);

        return _parseStockQty(result);
      },
    );

    if (stockQty != null && stockQty < 0) {
      // สต็อกไม่พอ
      await _showInsufficientStockDialog();
    }

  } on TimeoutException {
    // Timeout - แสดง error dialog พร้อม options
    await NetworkErrorDialog.showTimeoutError(
      context,
      customMessage: "การตรวจสอบสต็อกใช้เวลานานเกินไป",
      showContinue: true,
      onRetry: () => _checkStock(barcode, qty),
      onContinue: () => _proceedWithoutStockCheck(),
      onCancel: () => Navigator.pop(context),
    );

  } catch (e) {
    // Error อื่นๆ
    NetworkErrorSnackbar.show(
      context,
      message: "เกิดข้อผิดพลาดในการตรวจสอบสต็อก",
      errorType: NetworkErrorType.unknown,
    );
  }
}
```

### ตัวอย่างที่ 2: Payment Processing

```dart
Future<void> _processPayment(TransactionModel trans) async {
  try {
    // แสดง loading
    NetworkLoadingOverlay.show(
      context,
      message: global.language("processing_payment"),
    );

    final result = await api
        .saveTransaction(trans)
        .timeout(NetworkTimeouts.long);

    // ซ่อน loading
    NetworkLoadingOverlay.hide(context);

    if (result.success) {
      // สำเร็จ
      _showSuccessAnimation();
    } else {
      // ล้มเหลว
      NetworkErrorDialog.showGenericError(
        context,
        message: result.message,
        onRetry: () => _processPayment(trans),
      );
    }

  } on TimeoutException {
    NetworkLoadingOverlay.hide(context);

    await NetworkErrorDialog.showTimeoutError(
      context,
      customMessage: "การชำระเงินใช้เวลานานเกินไป",
      onRetry: () => _processPayment(trans),
      onCancel: () => _saveOffline(trans),
    );

  } catch (e) {
    NetworkLoadingOverlay.hide(context);

    // บันทึก offline
    await _saveOffline(trans);

    NetworkErrorSnackbar.show(
      context,
      message: global.language("transaction_saved_offline"),
      errorType: NetworkErrorType.noConnection,
    );
  }
}
```

### ตัวอย่างที่ 3: Member Login

```dart
Future<void> _loginWithPin(String pin) async {
  final result = await withLoadingIndicator<Map>(
    context: context,
    message: "กำลังตรวจสอบ PIN...",
    operation: () => api.getMemberPin(pin).timeout(
      NetworkTimeouts.standard,
    ),
  );

  if (result != null && result.isNotEmpty) {
    // Login สำเร็จ
    _proceedWithMember(result);
  } else {
    // Login ล้มเหลว
    NetworkErrorDialog.showGenericError(
      context,
      title: "PIN ไม่ถูกต้อง",
      message: "กรุณาตรวจสอบ PIN และลองใหม่อีกครั้ง",
      onRetry: () => _showPinDialog(),
    );
  }
}
```

---

## 🎨 Customization

### ปรับแต่ง Loading Message

```dart
// ใช้ language keys ที่เพิ่มไว้ใน language.json
final messages = [
  global.language("checking_stock"),      // "กำลังตรวจสอบสต็อก..."
  global.language("processing_payment"),  // "กำลังประมวลผลการชำระเงิน..."
  global.language("saving_order"),        // "กำลังบันทึกรายการ..."
  global.language("generating_queue"),    // "กำลังสร้างคิวรายการ..."
];
```

### ปรับแต่ง Error Messages

```dart
NetworkErrorDialog.showTimeoutError(
  context,
  customMessage: "ข้อความ error ที่คุณต้องการ",
  showContinue: true, // แสดงปุ่ม "ดำเนินการต่อ"
);
```

---

## ✅ Best Practices

### 1. ใช้ withLoadingIndicator สำหรับ operations ที่ใช้เวลา > 1 วินาที

```dart
// ✅ GOOD
final result = await withLoadingIndicator(
  context: context,
  message: global.language("checking_stock"),
  operation: () => api.clickHouseSelect(query),
);

// ❌ BAD - ไม่มี loading indicator
final result = await api.clickHouseSelect(query);
```

### 2. ใช้ Error Dialog สำหรับ critical errors

```dart
// ✅ GOOD - สำหรับ critical error ที่ต้อง retry
NetworkErrorDialog.showTimeoutError(context, onRetry: _retry);

// ✅ GOOD - สำหรับ non-critical error
NetworkErrorSnackbar.show(context, message: "Sync failed");
```

### 3. ให้ option "Continue Anyway" สำหรับ non-critical operations

```dart
// ✅ GOOD - Stock check ไม่สำเร็จ แต่ให้ option ดำเนินการต่อได้
NetworkErrorDialog.showTimeoutError(
  context,
  showContinue: true,  // ✅
  onContinue: () => _proceedAnyway(),
);
```

### 4. แสดง Network Status Widget ในหน้าสำคัญ

```dart
// ✅ GOOD - แสดงที่ MainPage, OrderPage
Scaffold(
  appBar: AppBar(
    bottom: PreferredSize(
      preferredSize: Size.fromHeight(30),
      child: NetworkStatusWidget(),
    ),
  ),
)
```

---

## 🐛 Troubleshooting

### Loading ไม่หาย

```dart
// ตรวจสอบว่า hide ถูกเรียกใน finally block
try {
  NetworkLoadingOverlay.show(context);
  await doSomething();
} finally {
  NetworkLoadingOverlay.hide(context);  // ✅
}
```

### Error Dialog ไม่แสดง

```dart
// ตรวจสอบว่า context.mounted
if (context.mounted) {
  NetworkErrorDialog.showTimeoutError(context);
}
```

### Network Status ไม่ update

```dart
// ตรวจสอบว่า widget ถูก mount
@override
void dispose() {
  _refreshTimer?.cancel();  // ✅ ต้อง cancel timer
  super.dispose();
}
```

---

## 📚 Language Keys ที่ใช้

ทั้งหมดอยู่ใน `assets/language.json`:

- `network_timeout` - "การเชื่อมต่อหมดเวลา"
- `network_error` - "ข้อผิดพลาดเครือข่าย"
- `checking_stock` - "กำลังตรวจสอบสต็อก..."
- `processing_payment` - "กำลังประมวลผลการชำระเงิน..."
- `saving_order` - "กำลังบันทึกรายการ..."
- `operation_timeout` - "การดำเนินการใช้เวลานานเกินไป"
- `retry_question` - "ต้องการลองอีกครั้งหรือไม่?"
- `continue_anyway` - "ดำเนินการต่อ"
- `offline_mode` - "โหมดออฟไลน์"
- `pending_sync` - "รอการซิงค์"
- `cancel` - "ยกเลิก"
- `confirm` - "ยืนยัน"
- `retry` - "ลองใหม่"

---

## 🚀 Migration Guide

### แก้ไข Code เดิมให้ใช้ Network UX Components

#### Before (โค้ดเดิม):
```dart
// ไม่มี loading indicator
var result = await api.clickHouseSelect(query);

// ไม่มี error handling
if (result.isEmpty) {
  // Silent failure
  return;
}
```

#### After (โค้ดใหม่):
```dart
try {
  // มี loading indicator
  final result = await withLoadingIndicator<Map>(
    context: context,
    message: global.language("checking_stock"),
    operation: () => api.clickHouseSelect(query).timeout(
      NetworkTimeouts.quick,
    ),
  );

  if (result == null || result.isEmpty) {
    // มี error dialog
    NetworkErrorDialog.showGenericError(
      context,
      message: "ไม่พบข้อมูล",
    );
    return;
  }

} on TimeoutException {
  // มี timeout handling
  NetworkErrorDialog.showTimeoutError(
    context,
    onRetry: () => _retry(),
  );
}
```

---

เอกสารนี้จะช่วยให้ทีมพัฒนาใช้งาน Network UX Components ได้อย่างถูกต้องและสม่ำเสมอทั่วทั้งแอพ
